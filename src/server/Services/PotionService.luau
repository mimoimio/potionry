-- Handles Potion manipulation related requests and potion throwing
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
local VariationRNGService = require(game.ServerScriptService.Server.Services.VariationRNGService)
local PotionService = {}

type PlayersState = PlayerSessions.PlayersState
type PlayerEntity = PlayerSessions.PlayerEntity

local sizes = { 1, 1, 1, 2, 2, 3 }

-- Create RemoteFunction for crafting
local GetIngredients = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetIngredients.Name = "GetIngredients"

-- Create RemoteFunction for getting potions
local GetPotions = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetPotions.Name = "GetPotions"

-- Create RemoteEvent for IngredientChange
local IngredientsChanged = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
IngredientsChanged.Name = "IngredientsChanged"

-- Create RemoteEvent for crafting
local CraftPotion = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
CraftPotion.Name = "CraftPotion"

-- Create RemoteEvent for Potions updates
local PotionsUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
PotionsUpdated.Name = "PotionsUpdated"

-- Create RemoteEvent for resetting ingredients (playtest)
local ResetIngredients = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ResetIngredients.Name = "ResetIngredients"

-- Create RemoteEvent for Pickup
local CraftPickup = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
CraftPickup.Name = "CraftPickup"

-- Create RemoteEvent for Skip (Playtest)
local SkipCraft = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
SkipCraft.Name = "SkipCraft"

-- Generate a unique ID for potions
local potionCounter = 0
local function generatePotionUID(player: Player): string
	potionCounter += 1
	local UID = ("%014X"):format(workspace:GetServerTimeNow() * 1e4)
	UID = UID:sub(8, UID:len()) .. "_POTION_" .. potionCounter
	return UID
end

local function getVariation(): string
	local v = VariationRNGService:roll()
	return v.VariationId
end

local function getPlayerSession(player: Player): (state: PlayersState) -> PlayerEntity
	return PlayerSessions:getState(function(state: PlayersState): PlayersState
		return state.players[player]
	end)
end

function PotionService.CraftPotion(player: Player, potionId: string, cauldronId: string): boolean
	local playerSession = getPlayerSession(player)
	if not playerSession then
		warn("No player session found for", player.Name)
		return false
	end

	local pd = playerSession.Data
	if not pd then
		warn("No player data found for", player.Name)
		return false
	end

	-- Get the craft recipe from CraftingModule
	local craftRecipe = CraftingModule.CraftingLookup[potionId]
	if not craftRecipe then
		warn("Invalid craft ID:", potionId)
		return false
	end

	-- Guard against occupied cauldron
	local cauldronInstance = pd.Cauldrons[cauldronId]
	if cauldronInstance ~= "none" then
		warn("Cauldron already occupied:", cauldronId)
		return false
	end

	-- Check if player has enough ingredients
	local ingredients = craftRecipe.Ingredients
	for _, itemId in ipairs(ingredients) do
		local currentAmount = pd.Ingredients[itemId] or 0
		if currentAmount < 1 then
			warn("Not enough ingredients:", itemId)
			return false
		end
	end

	-- Deduct ingredients using Reflex action
	PlayerSessions.deductIngredients(player, ingredients)

	-- Generate size (1-3) using bell curve probability
	local rng = Random.new(tick() + player.UserId)
	local bell = math.abs(rng:NextNumber() - rng:NextNumber())
	local size = sizes[math.clamp(math.floor(1 + bell * 6), 1, 5)]

	-- Occupy cauldron slot using Reflex action
	PlayerSessions.setCauldron(player, cauldronId, {
		UID = generatePotionUID(player),
		StartTime = workspace:GetServerTimeNow(),
		VariationId = getVariation(),
		PotionId = potionId,
		Size = size,
	})

	return true
end

function PotionService.PickupPotion(player: Player, cauldronId: string)
	local playerSession = getPlayerSession(player)
	if not playerSession then
		warn("No player session found for", player.Name)
		return
	end

	local cauldron = playerSession.Data.Cauldrons[cauldronId]
	if not cauldron or cauldron == "none" then
		warn("No cauldron:", cauldron)
		return
	end

	-- Check if done
	local startTime = cauldron.StartTime
	local duration = CraftingModule.CraftingLookup[cauldron.PotionId].Duration
	local endTime = startTime + duration
	local done = endTime <= workspace:GetServerTimeNow()

	if not done then
		warn(workspace:GetServerTimeNow() - endTime, "time left")
		return
	end

	-- Add potion using Reflex action
	PlayerSessions.addPotion(player, {
		UID = cauldron.UID,
		VariationId = cauldron.VariationId,
		PotionId = cauldron.PotionId,
		Size = cauldron.Size,
	})

	-- Clear cauldron using Reflex action
	PlayerSessions.setCauldron(player, cauldronId, "none")
end

function PotionService.SkipCraft(player: Player, cauldronId: string)
	local playerSession = getPlayerSession(player)
	if not playerSession then
		warn("No player session found for", player.Name)
		return
	end

	local cauldron = playerSession.Data.Cauldrons[cauldronId]
	if not cauldron or cauldron == "none" then
		warn("No cauldron data for:", cauldronId)
		return
	end

	-- Instantly set StartTime to make it done
	local potionId = cauldron.PotionId
	local duration = CraftingModule.CraftingLookup[potionId].Duration
	local newCauldron = table.clone(cauldron)
	newCauldron.StartTime = workspace:GetServerTimeNow() - duration - 1

	PlayerSessions.setCauldron(player, cauldronId, newCauldron)
end

function PotionService.PlacePotion(player: Player, rackId, slotNum): nil
	local playerSession = getPlayerSession(player)
	if not (player and slotNum and rackId and playerSession) then
		return
	end
	if not playerSession.Character then
		warn("NO CHARACTER", playerSession)
		return
	end

	local tool = playerSession.Character:FindFirstChildWhichIsA("Tool") :: Tool?
	local name = tool and tool.Name or "none"
	local potionUID
	if name ~= "none" then
		for i, p in playerSession.Data.Potions do
			if p.UID == name then
				potionUID = name
				break
			end
		end
	end
	potionUID = potionUID or "none"
	PlayerSessions.setPotionSlot(player, rackId, slotNum, potionUID)
end

function PotionService.SetPotionSlot(player: Player, rackId: string, slotNum: string)
	local playerSession = getPlayerSession(player)
	if not (player and slotNum and rackId and playerSession) then
		return
	end

	-- Set slot to "none" to remove potion
	PlayerSessions.setPotionSlot(player, rackId, slotNum, "none")
end

function PotionService.initialize()
	-- Initialize and connect events
	local SetPotionSlot = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	SetPotionSlot.Name = "SetPotionSlot"
	SetPotionSlot.OnServerEvent:Connect(PotionService.SetPotionSlot)

	-- Crafting RemoteEvents
	local CraftPotion = ReplicatedStorage.Shared.Events:FindFirstChild("CraftPotion")
	if CraftPotion then
		CraftPotion.OnServerEvent:Connect(function(player, potionId, cauldronId)
			PotionService.CraftPotion(player, potionId, cauldronId)
		end)
	end

	local CraftPickup = ReplicatedStorage.Shared.Events:FindFirstChild("CraftPickup")
	if CraftPickup then
		CraftPickup.OnServerEvent:Connect(function(player, cauldronId)
			PotionService.PickupPotion(player, cauldronId)
		end)
	end

	local SkipCraft = ReplicatedStorage.Shared.Events:FindFirstChild("SkipCraft")
	if SkipCraft then
		SkipCraft.OnServerEvent:Connect(function(player, cauldronId)
			-- Note: For production, this should check MonetizationService
			-- For now, skip directly (playtest mode)
			PotionService.SkipCraft(player, cauldronId)
		end)
	end

	-- Expose SkipCraft for MonetizationService to call after purchase
	PotionService.OnSkipCraft = PotionService.SkipCraft

	local SellPotion: RemoteEvent = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
	SellPotion.Name = "SellPotion"

	SellPotion.OnServerEvent:Connect(function(player, potionUIDs: { string })
		local playerSession = getPlayerSession(player)
		if not playerSession or not potionUIDs or #potionUIDs == 0 then
			warn("Invalid sell request from", player.Name)
			return
		end

		local pd = playerSession.Data
		if not pd then
			warn("No player data found for", player.Name)
			return
		end

		-- Validate and calculate total sell price
		local validUIDs = {}
		local totalSellPrice = 0

		for _, uid in ipairs(potionUIDs) do
			-- Find the potion in player's inventory
			local foundPotion = nil
			for _, potion in ipairs(pd.Potions) do
				if potion.UID == uid then
					foundPotion = potion
					break
				end
			end

			if foundPotion then
				-- Check if potion is placed on a rack
				local isPlaced = false
				for rackId, rack in pairs(pd.PotionSlots) do
					for slotId, slotUID in pairs(rack) do
						if slotUID == uid then
							isPlaced = true
							break
						end
					end
					if isPlaced then
						break
					end
				end

				-- Only allow selling unplaced potions
				if not isPlaced then
					table.insert(validUIDs, uid)

					-- Calculate sell price
					local craftConfig = CraftingModule.CraftingLookup[foundPotion.PotionId]
					if craftConfig then
						local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
						local variationConfig = VariationsConfig[foundPotion.VariationId]
						local variationMultiplier = variationConfig and variationConfig.Multiplier or 1
						local basePrice = craftConfig.Price or 0
						local sellPrice = math.floor((basePrice * variationMultiplier) / 2)
						totalSellPrice += sellPrice
					end
				else
					warn("Cannot sell placed potion:", uid)
				end
			else
				warn("Potion not found in inventory:", uid)
			end
		end

		-- Remove valid potions and add cash
		if #validUIDs > 0 then
			PlayerSessions.removePotions(player, validUIDs)
			PlayerSessions.addPlayerCash(player, totalSellPrice)
		else
			warn("No valid potions to sell for", player.Name)
		end
	end)

	local PotionClicked = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	PotionClicked.Name = "PotionClicked"

	-- ThrowPotion RemoteEvent
	local ThrowPotion = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	ThrowPotion.Name = "ThrowPotion"
	ThrowPotion.OnServerEvent:Connect(
		function(player: Player, potionUID: string, hitCFrame: CFrame, additionalVelocity: Vector3)
			if not potionUID or not hitCFrame then
				warn("Invalid arguments for ThrowPotion")
				return
			end
			additionalVelocity = additionalVelocity or Vector3.new()

			local playerSession = getPlayerSession(player)
			if not playerSession then
				warn("No player session found")
				return
			end

			local pd = playerSession.Data
			if not pd then
				warn("No player data found for", player.Name)
				return
			end

			-- Throw the potion
			local character = player.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then
				warn("Player character not available for throwing")
				return
			end

			-- Find potion in player data
			local potion = nil
			for _, p in ipairs(pd.Potions) do
				if p.UID == potionUID then
					potion = p
					break
				end
			end

			if not potion then
				warn("Potion not found for throwing:", potionUID)
				return
			end

			-- Remove potion from player inventory
			PlayerSessions.removePotion(player, potionUID)

			-- Get potion model
			local potionModel = game.ReplicatedStorage.Shared.Models.Potions:FindFirstChild(potion.PotionId)
			if not potionModel then
				warn("Potion model not found:", potion.PotionId)
				return
			end

			local thrownModel = potionModel:Clone() :: Model
			-- Make all parts anchored
			for _, part in thrownModel:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			local cf, s = thrownModel:GetBoundingBox()
			thrownModel.WorldPivot = cf

			-- Apply size if exists
			if potion.Size then
				thrownModel:ScaleTo(1 + (potion.Size - 1) / 3)
			end

			-- Set initial position at character pivot
			local startCFrame = character:GetPivot()
			thrownModel:PivotTo(startCFrame)
			thrownModel.Parent = workspace

			-- Calculate trajectory direction
			local direction = (hitCFrame.Position - startCFrame.Position).Unit
			direction += Vector3.new(math.random() * 0.1 - 0.05, math.random() * 0.1 - 0.05, math.random() * 0.1 - 0.05)
			local velocity = direction * 50
				+ direction * (0.8 * additionalVelocity.Magnitude)
				+ additionalVelocity * 0.4
			-- Initial velocity of 50 studs/s
			local speed = velocity.Magnitude
			warn("speed", speed)

			-- Spawn throw score indicator
			local Debris = game:GetService("Debris")
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local puddlefolder = workspace:FindFirstChild("PuddleEffects") or Instance.new("Folder")
			if not puddlefolder.Parent then
				puddlefolder.Name = "PuddleEffects"
				puddlefolder.Parent = workspace
			end
			local indicatorPart = Instance.new("Part")
			indicatorPart.Size = Vector3.new(1, 1, 1)
			indicatorPart.Transparency = 1
			indicatorPart.Anchored = false
			indicatorPart.CanCollide = false
			indicatorPart.Massless = true

			-- Random 3D offset
			local randomOffset = Vector3.new(math.random(-3, 3), math.random(2, 5), math.random(-3, 3))
			indicatorPart.CFrame = hrp.CFrame * CFrame.new(randomOffset)
			indicatorPart.Parent = workspace

			-- Weld to HumanoidRootPart
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp
			weld.Part1 = indicatorPart
			weld.Parent = indicatorPart

			local billboardTemplate = game.ReplicatedStorage.Shared:FindFirstChild("BillboardGui")
			if billboardTemplate then
				local billboard = billboardTemplate:Clone()
				billboard.Parent = indicatorPart
				local textLabel = billboard:FindFirstChild("TextLabel")
				if textLabel then
					-- Determine throw grade based on speed
					local throwGrade = "THROW!"
					local gradeColor = Color3.fromRGB(255, 255, 255)

					if speed >= 130 then
						throwGrade = "PERFECT THROW!"
						gradeColor = Color3.fromRGB(255, 215, 0) -- Gold
					elseif speed >= 90 then
						throwGrade = "GOOD THROW!"
						gradeColor = Color3.fromRGB(50, 255, 50) -- Green
					end

					textLabel.Text = throwGrade
					textLabel.TextColor3 = gradeColor
				end
			end

			Debris:AddItem(indicatorPart, 3)

			local gravity = Vector3.new(0, -50, 0) -- Gravity acceleration
			local currentPosition = startCFrame.Position
			local currentRotation = startCFrame.Rotation

			-- Random rotation speed (degrees per second)
			local r = Random.new()
			local rotationSpeed = Vector3.new(r:NextNumber(-360, 360), r:NextNumber(-360, 360), r:NextNumber(-360, 360))

			-- Setup raycast params
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = { thrownModel, character, puddlefolder }
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			-- Physics simulation
			local RunService = game:GetService("RunService")
			local connection
			local elapsedTime = 0
			local maxTime = 10 -- max flight time

			-- Create trail for thrown potion
			local mainPart = thrownModel.PrimaryPart or thrownModel:FindFirstChildWhichIsA("BasePart")
			local attachment0 = Instance.new("Attachment")
			attachment0.Parent = mainPart
			attachment0.Position = Vector3.new(1, -2, 0)
			local attachment1 = Instance.new("Attachment")
			attachment1.Parent = mainPart
			attachment1.Position = Vector3.new(0, 1, 0)

			local trail = Instance.new("Trail")
			trail.Attachment0 = attachment0
			trail.Attachment1 = attachment1
			trail.Color = ColorSequence.new(thrownModel:FindFirstChild("Fill").Color)
			trail.Transparency = NumberSequence.new(0.3, 1)
			trail.Lifetime = 2
			trail.MinLength = 0
			trail.FaceCamera = true
			trail.Parent = thrownModel

			-- Add ingredient trails
			local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
			local recipe = CraftingModule.CraftingLookup[potion.PotionId]
			if recipe and recipe.Ingredients then
				local ingredientCount = 0
				for _ in pairs(recipe.Ingredients) do
					ingredientCount += 1
				end

				local trailCount = ingredientCount + 1 -- If 1 ingredient = 2 trails, etc.
				local angleStep = (math.pi * 2) / trailCount
				local radius = 2
				local ingredientIndex = 0

				for i, ingredientId in pairs(recipe.Ingredients) do
					ingredientIndex += 1
					local angle = angleStep * ingredientIndex
					local offsetX = math.cos(angle) * radius
					local offsetZ = math.sin(angle) * radius

					-- Get ingredient's potion color
					local ingredientPotionModel =
						game.ReplicatedStorage.Shared.Models.Potions:FindFirstChild(ingredientId)
					local ingredientColor = Color3.fromRGB(255, 255, 255)
					if ingredientPotionModel then
						local fillPart = ingredientPotionModel:FindFirstChild("Fill")
						if fillPart then
							ingredientColor = fillPart.Color
						end
					end

					local att0 = Instance.new("Attachment")
					att0.Parent = mainPart
					att0.Position = Vector3.new(offsetX, -2, offsetZ)
					local att1 = Instance.new("Attachment")
					att1.Parent = mainPart
					att1.Position = Vector3.new(offsetX * 0.5, 1, offsetZ * 0.5)

					local ingredientTrail = Instance.new("Trail")
					ingredientTrail.Attachment0 = att0
					ingredientTrail.Attachment1 = att1
					ingredientTrail.Color = ColorSequence.new(ingredientColor)
					ingredientTrail.Transparency = NumberSequence.new(0.5, 1)
					ingredientTrail.Lifetime = 2
					ingredientTrail.MinLength = 0
					ingredientTrail.FaceCamera = true
					ingredientTrail.Parent = thrownModel
				end
			end

			connection = RunService.Heartbeat:Connect(function(deltaTime)
				elapsedTime = elapsedTime + deltaTime
				if elapsedTime > maxTime then
					connection:Disconnect()
					thrownModel:Destroy()
					return
				end

				-- Update velocity with gravity
				velocity = velocity + gravity * deltaTime
				-- Calculate next position
				local displacement = velocity * deltaTime
				local nextPosition = currentPosition + displacement

				-- Raycast for collision
				local rayResult = workspace:Raycast(currentPosition, displacement, raycastParams)

				if rayResult then
					-- Collision detected - create puddle
					connection:Disconnect()

					local puddle = Instance.new("Part")
					puddle.Material = "Neon"
					puddle.Size = Vector3.new(4, 1, 4)
					puddle.Position = rayResult.Position
					puddle.Anchored = true
					puddle.CanCollide = false
					puddle.Color = thrownModel:FindFirstChild("Fill").Color
					puddle.Transparency = 0.4
					puddle.Name = "PotionPuddle"
					puddle.Parent = puddlefolder

					local additionalSpeed = velocity.Magnitude * 1

					local shattersound = game.ReplicatedStorage.Shared.SFX:FindFirstChild(
						({ "shatter", "shatter2", "shatter3" })[r:NextInteger(1, 3)]
					)
					local sound: Sound
					if shattersound then
						task.spawn(function()
							sound = shattersound:Clone() :: Sound
							sound.Parent = puddle
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							task.wait(1)
							sound:Destroy()
						end)
					end

					local shardEmitter = Instance.new("ParticleEmitter")
					shardEmitter.Texture = "http://www.roblox.com/asset/?id=125738090794255"
					shardEmitter.Transparency = NumberSequence.new(0, 1)
					shardEmitter.Rate = 0
					shardEmitter.Lifetime = NumberRange.new(2, 4)
					shardEmitter.Speed = NumberRange.new(10, 100 + additionalSpeed)
					shardEmitter.SpreadAngle = Vector2.new(40, 40)
					shardEmitter.Acceleration = Vector3.new(0, -100, 0)
					shardEmitter.RotSpeed = NumberRange.new(-90, 90 + additionalSpeed)
					shardEmitter.Rotation = NumberRange.new(-90, 90)
					shardEmitter.Parent = puddle
					shardEmitter.Size = NumberSequence.new(1, math.min(6, (additionalSpeed / 50) ^ 3))
					shardEmitter.ZOffset = 2
					local bubbleEmitter = Instance.new("ParticleEmitter")
					bubbleEmitter.Texture = "http://www.roblox.com/asset/?id=2924164961"
					bubbleEmitter.Transparency = NumberSequence.new(0, 1)
					bubbleEmitter.ZOffset = 2
					bubbleEmitter.Size = NumberSequence.new(1, math.min(6, (additionalSpeed / 50) ^ 3))
					bubbleEmitter.LightEmission = 1
					bubbleEmitter.LightInfluence = 0
					bubbleEmitter.Color = ColorSequence.new(thrownModel:FindFirstChild("Fill").Color)
					bubbleEmitter.Rate = 0
					bubbleEmitter.Lifetime = NumberRange.new(2, 4)
					bubbleEmitter.Speed = NumberRange.new(10, 20 + additionalSpeed / 5)
					bubbleEmitter.SpreadAngle = Vector2.new(40, 40)
					bubbleEmitter.Acceleration = Vector3.new(0, -5, 0)
					bubbleEmitter.Drag = 1
					bubbleEmitter.RotSpeed = NumberRange.new(-90, 90 + additionalSpeed)
					bubbleEmitter.Rotation = NumberRange.new(-90, 90)
					bubbleEmitter.Parent = puddle
					local emitters = {}
					if potion.VariationId and potion.VariationId ~= "none" then
						local vfxFolder = game.ReplicatedStorage.Shared:FindFirstChild("VFX")
						if vfxFolder then
							local vfxAsset = vfxFolder:FindFirstChild(potion.VariationId)
							if vfxAsset then
								local vfxClone = vfxAsset:Clone()
								vfxClone.Parent = puddle
								for _, emitter in ipairs(vfxClone:GetDescendants()) do
									if emitter:IsA("ParticleEmitter") then
										emitter.Parent = puddle
										emitter.Acceleration = Vector3.new(0, 1, 0)
										emitter.Drag = 1
										emitter.Size = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 1),
											NumberSequenceKeypoint.new(1, 3),
										})
										emitter.LightEmission = 1
										emitter.LightInfluence = 0
										emitter.Color = ColorSequence.new(
											thrownModel:FindFirstChild("Fill") and thrownModel.Fill.Color
												or Color3.new(1, 1, 1)
										)
										emitter.Rate = 0
										emitter.Lifetime = NumberRange.new(2, 4)
										emitter.Speed = NumberRange.new(10, 20 + additionalSpeed / 5)
										emitter.SpreadAngle = Vector2.new(40, 40)
										emitter.Acceleration = Vector3.new(0, -5, 0)
										emitter.Drag = 1
										emitter.RotSpeed = NumberRange.new(0)
										emitter.Rotation = NumberRange.new(-15, 15)
										table.insert(emitters, emitter)
									end
								end
							end
						end
					end

					-- VFX for potion variation
					task.delay(0.1, function()
						shardEmitter:Emit(40)
						bubbleEmitter:Emit(40)
						for i, e in emitters do
							e:Emit(40)
						end
					end)
					-- Destroy puddle after 5 seconds
					task.delay(5, function()
						if puddle and puddle.Parent then
							if sound then
								if sound.Playing then
									sound.Ended:Wait()
								end
								thrownModel:Destroy()
								puddle:Destroy()
							end
						end
					end)
					for i, d in thrownModel:GetDescendants() do
						if not d:IsA("BasePart") then
							continue
						end
						d.Transparency = 1
					end
					return
				end

				-- Update position and rotation
				currentPosition = nextPosition
				currentRotation = currentRotation
					* CFrame.Angles(
						math.rad(rotationSpeed.X * deltaTime),
						math.rad(rotationSpeed.Y * deltaTime),
						math.rad(rotationSpeed.Z * deltaTime)
					)
				thrownModel:PivotTo(CFrame.new(currentPosition) * currentRotation)
			end)
		end
	)
end

return PotionService
