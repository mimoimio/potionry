local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local PotionConfigs = require(game.ReplicatedStorage.Shared.Configs.PotionConfigs)
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
local VariationRNGService = require(game.ServerScriptService.Server.Services.VariationRNGService)
local PotionService = {}

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
local function generatePotionUID(player: Player)
	potionCounter += 1
	local UID = ("%014X"):format(workspace:GetServerTimeNow() * 1e4)
	UID = UID:sub(8, UID:len()) .. "_POTION_" .. potionCounter
	return UID
end

local function getVariation(): string
	local SpecialEventsService = require(game.ServerScriptService.Server.Services.SpecialEventsService)
	local v = VariationRNGService:roll()
	return v.VariationId
end

local function getPlayerSession(player: Player): PlayerSessions.PlayerEntity
	return PlayerSessions:getState(function(state: PlayerSessions.PlayersState)
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

-- Legacy function kept for compatibility
function PotionService.CraftPotionLegacy(player: Player, potionId: string): nil
	local playerSession = getPlayerSession(player)
	local potionConfig: PotionConfigs.PotionConfig? = PotionConfigs.Lookup[potionId]

	if not (player and potionId and playerSession and potionConfig) then
		return
	end
	if playerSession.Data.Cash >= potionConfig.Price then
	end
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
	warn("rackId", rackId)
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
end

return PotionService
