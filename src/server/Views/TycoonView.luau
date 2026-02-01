local PotionConfigs = require(game.ReplicatedStorage.Shared.CraftingModule).CraftingLookup
local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local React = require(game.ReplicatedStorage.Packages.React)
local Mionum = require(game.ReplicatedStorage.Packages.Mionum)
local e = React.createElement
local useRef = React.useRef
local useEffect = React.useEffect
local useMemo = React.useMemo
local useState = React.useState

local PotionsConfig = require(game.ReplicatedStorage.Shared.Configs.PotionConfigs).Lookup
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)

local TycoonView = {}
local MultiplierService = require(game.ServerScriptService.Server.Services.MultiplierService)
local TycoonService = require(game.ServerScriptService.Server.Services.TycoonService)
local PotionService = require(game.ServerScriptService.Server.Services.PotionService)

--[[======================================================================================================================================================================================================]]
export type TycoonProps = {
	Player: Player,
	PlayerSession: PlayerSessions.PlayerEntity,
}

-- Helper function to calculate final potion rate with all multipliers
local function calculatePotionRate(potion, playerMultiplier)
	local config = PotionConfigs[potion.PotionId]
	if not config then
		return 0
	end
	local varcfg = VariationsConfig[potion.VariationId] or VariationsConfig.none
	return math.floor(config.Rate * varcfg.Multiplier * (playerMultiplier or 1) * (potion.Size or 1))
end

-- Helper function to create and format potion models
local function createPotionModel(potion)
	local model = game.ReplicatedStorage.Shared.Models.Potions:FindFirstChild(potion.PotionId)
	model = model and model:Clone() or game.ReplicatedStorage.Shared.Models:FindFirstChild("error"):Clone() :: Model

	-- Scale model based on potion size
	if potion.Size then
		model:ScaleTo(1 + (potion.Size - 1) / 3)
	end

	-- Add VFX particles based on variation
	if potion.VariationId and potion.VariationId ~= "none" then
		local vfxFolder = game.ReplicatedStorage.Shared:FindFirstChild("VFX")
		local vconfig = VariationsConfig[potion.VariationId]
		local cf, size = model:GetBoundingBox()

		-- Handle Fill part if it exists
		if model:FindFirstChild("Fill") then
			model.Fill.Color = Color3.new(
				(model.Fill.Color.R + vconfig.ColorPrimary.R) / 2,
				(model.Fill.Color.G + vconfig.ColorPrimary.G) / 2,
				(model.Fill.Color.B + vconfig.ColorPrimary.B) / 2
			)
		end

		-- Handle Bottle part if it exists
		if model:FindFirstChild("Bottle") then
			model.Bottle.Color = vconfig.ColorPrimary
			model.Bottle.Transparency = 0.3
			model.Bottle.Reflectance = 0.6
			model.Bottle.UsePartColor = true
		end

		if vfxFolder then
			local vfxPart = vfxFolder:FindFirstChild(potion.VariationId)
			local vfxClone
			if vfxPart and vfxPart:IsA("BasePart") then
				vfxClone = vfxPart:Clone()
				vfxClone.Anchored = false
				vfxClone.CanCollide = false
				vfxClone.CanQuery = false

				-- Find the primary part or first basepart to weld to
				local basePart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
				if basePart then
					vfxClone:PivotTo(basePart:GetPivot())
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = basePart
					weld.Part1 = vfxClone
					weld.Parent = vfxClone
					vfxClone.Parent = model
				end
			end
			local iconAtt = vfxFolder.Parent.Icons:FindFirstChild(potion.VariationId)
			if vfxClone and iconAtt then
				local iconClone = iconAtt:Clone() :: Attachment
				iconClone.CFrame = CFrame.new(0, size.Y / 2 + 3, 0)
				iconClone.Parent = model:FindFirstChildWhichIsA("BasePart", true)
			end
		end
	end

	return model
end

local function PotionItem(props)
	local toolRef = useRef(nil)
	local potion = props.Potion
	local VariationId = potion and potion.VariationId
	local config = PotionConfigs[potion and potion.PotionId]
	local varcfg = VariationsConfig[VariationId] or VariationsConfig.none
	local rate = math.floor(config.Rate * varcfg.Multiplier * (props.finalMultiplier or 1) * (potion.Size or 1))
	local rateString = Mionum.new(rate):toString() .. "/s"
	useEffect(function()
		-- Don't create tool if potion is placed
		if props.Placed then
			return
		end

		local tool = Instance.new("Tool")
		tool.Name = props.Potion.UID
		tool.TextureId = "rbxassetid://3508248746"
		tool.ToolTip = props.Potion.PotionId
		tool.RequiresHandle = false
		tool.CanBeDropped = false
		tool:SetAttribute("VariationId", potion.VariationId)
		tool:SetAttribute("DisplayName", PotionConfigs[potion.PotionId].DisplayName)
		tool:SetAttribute("PotionId", potion.PotionId)
		tool:SetAttribute("RateString", rateString)
		toolRef.current = tool
		local c = tool.Activated:Connect(function()
			game.ReplicatedStorage.Shared.Events.PotionClicked:FireClient(props.Player, props.Potion.UID)
		end)
		local Handle = Instance.new("Part")
		Handle.Name = "Handle"
		Handle.Transparency = 1
		local model = createPotionModel(potion)
		model:PivotTo(Handle:GetPivot())

		for _, childpart in model:GetDescendants() do
			if childpart:IsA("BasePart") then
				childpart.Anchored = false
				local weld = Instance.new("WeldConstraint", Handle)
				weld.Part0 = Handle
				weld.Part1 = childpart
			end
		end

		model.Parent = Handle

		Handle.Parent = tool
		tool.Parent = props.Player.Backpack
		return function()
			if c then
				c:Disconnect()
			end
			if tool then
				tool:Destroy()
			end
		end
	end, { props.Placed, props.Character })

	useEffect(function()
		if not toolRef.current or not potion then
			return
		end
		local tool = toolRef.current
	end, { potion, VariationId, rateString, props.finalMultiplier })
	return e("StringValue")
end

local function Potions(props)
	local character, setCharacter = useState()
	local children = {}

	-- Track character respawns
	useEffect(function()
		local conn
		task.spawn(function()
			-- Set initial character if available
			if props.Player.Character then
				setCharacter(props.Player.Character)
			else
				setCharacter(props.Player.CharacterAdded:Wait())
			end
			conn = props.Player.CharacterAdded:Connect(function(newCharacter)
				setCharacter(newCharacter)
			end)
		end)

		return function()
			if conn then
				conn:Disconnect()
			end
		end
	end, {})

	if character then
		local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player)

		-- Build a set of placed potion UIDs from PotionSlots
		local placedPotions = {}
		local potionSlots = props.PlayerSession.Data.PotionSlots or {}
		for rackName, rack in pairs(potionSlots) do
			for slotName, uid in pairs(rack) do
				if uid ~= "none" then
					placedPotions[uid] = true
				end
			end
		end
		for i, potion in props.PlayerSession.Data.Potions do
			children[potion.UID] = e(PotionItem, {
				key = potion.UID,
				Potion = potion,
				Player = props.Player,
				Character = character,
				finalMultiplier = finalMultiplier,
				Placed = placedPotions[potion.UID] or false,
			})
		end
	end
	return e("Folder", nil, { children })
end

local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)

local IngredientsColor = {
	daybloom = Color3.new(0.9, 0.8, 0.4),
	blinkroot = Color3.new(0.6, 0.2, 0.1),
	luckyclover = Color3.new(0.2, 0.8, 0.4),
	glowshroom = Color3.new(0.2, 0.2, 0.8),
	bloodthorn = Color3.new(0.8, 0.2, 0.6),
	spiralaloe = Color3.new(0.1, 0.9, 0.2),
	waterleaf = Color3.new(0.2, 0.3, 0.9),
	fireblossom = Color3.new(0.9, 0.2, 0.1),
}

local function CauldronItem(props: {
	CauldronId: string,
	PotionId: string,
	Player: Player,
	owned: boolean,
	Data: any,
	CauldronInstance: Folder,
	VariationId: string,
})
	local cloneRef = useRef()
	local promptRef = useRef()
	local connectionRef = useRef()
	local CMOdel, setCauldronModel = useState(nil)
	local ingredientModelsRef = useRef({})
	local colorTweenRef = useRef(nil)
	local colorThreadRef = useRef(nil)
	local playerSession = props.playerSession
	local cauldronfolder = props.CauldronInstance
	local price = cauldronfolder:GetAttribute("Price")
	local owned, setOwned = useState(props.owned)
	useEffect(function()
		setOwned(props.owned)
	end, { props.owned })

	useEffect(function()
		if not props.CauldronInstance then
			return
		end
		local buyCauldron = function(player)
			if props.Player ~= player then
				return
			end
			local cauldronId = cauldronfolder.Name :: string
			local success = TycoonService.BuyCauldron(player, cauldronId, price)
			if success then
				setOwned(true)
			end
		end

		if price <= 0 and not owned then
			buyCauldron(props.Player)
			setOwned(true)
		end
		if owned then
			-- Find the Cauldron model inside the container
			local cauldronModel = game.ReplicatedStorage.Shared.Models.Cauldron:Clone() :: Model
			cauldronModel:PivotTo(cauldronfolder.Base:GetPivot())
			cauldronModel.Parent = cauldronfolder

			cloneRef.current = cauldronModel
			setCauldronModel(cauldronModel)

			local highlight = Instance.new("Highlight", cauldronModel)
			highlight.FillTransparency = 1
			highlight.OutlineTransparency = 0.4
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		else
			-- Setup ProximityPrompt
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = Mionum.new(price):toString()
			prompt.ActionText = "Buy Caudldron"
			prompt.RequiresLineOfSight = false
			prompt.Triggered:Connect(buyCauldron)
			prompt.Style = "Custom"
			prompt.Parent = cauldronfolder.Base.Hitbox
			promptRef.current = prompt
		end

		return function()
			if cloneRef.current then
				cloneRef.current:Destroy()
				cloneRef.current = nil
			end
			if promptRef.current then
				promptRef.current:Destroy()
			end
		end
	end, { owned })

	-- Render ingredient models based on potionId and variation
	useEffect(function()
		local cauldronModel = cloneRef.current
		local data = props.Data

		-- Clear previous ingredient models
		for _, model in pairs(ingredientModelsRef.current) do
			if model then
				model:Destroy()
			end
		end
		ingredientModelsRef.current = {}

		if not cauldronModel or not data or data == "none" then
			return
		end

		local potionId = data.PotionId
		local variationId = data.VariationId

		-- Get the recipe ingredients
		local recipe = CraftingModule.CraftingLookup[potionId]
		if not recipe or not recipe.Ingredients then
			warn("not recipe")
			return
		end

		-- Tween cauldron inside color through ingredient colors
		local insidePart = cauldronModel:FindFirstChild("Inside", true)
		if insidePart and insidePart:IsA("BasePart") then
			insidePart.Transparency = 0
			local colors = {}
			for _, ingredientId in ipairs(recipe.Ingredients) do
				local c = IngredientsColor[ingredientId]
				if c then
					table.insert(colors, c)
				end
			end

			if #colors == 1 then
				-- Single ingredient: set color once
				insidePart.Color = colors[1]
			elseif #colors > 1 then
				-- Multiple ingredients: cycle through colors
				local TweenService = game:GetService("TweenService")
				local thread = task.spawn(function()
					local idx = 1
					while true do
						local targetColor = colors[idx]
						local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
						local tween = TweenService:Create(insidePart, tweenInfo, { Color = targetColor })
						colorTweenRef.current = tween
						tween:Play()
						tween.Completed:Wait()
						task.wait(0.2)
						idx = (idx % #colors) + 1
					end
				end)
				colorThreadRef.current = thread
			end
		end

		local particles = game.ReplicatedStorage.Shared:FindFirstChild("Particles")
		if particles and variationId and variationId ~= "none" then
			local particleVariation = particles:FindFirstChild(variationId)
			if particleVariation and particleVariation:IsA("BasePart") then
				local particle = particleVariation:Clone()
				particle:PivotTo(cauldronModel:GetPivot() + Vector3.new(0, 6, 0))
				particle.Parent = cauldronModel
				particle.CanQuery = false
				particle.Anchored = true
				particle.CanCollide = false
				for i, p: ParticleEmitter in particle:GetChildren() do
					p.Speed = NumberRange.new(20, 30)
					p.Acceleration = Vector3.new(0, -20, 0)
				end
				table.insert(ingredientModelsRef.current, particle)
			end
		end

		return function()
			-- Cleanup ingredient models
			for _, model in pairs(ingredientModelsRef.current) do
				if model then
					model:Destroy()
				end
			end
			-- Cleanup color tween/thread
			if insidePart then
				insidePart.Transparency = 1
			end
			if colorTweenRef.current then
				colorTweenRef.current:Cancel()
				colorTweenRef.current = nil
			end
			if colorThreadRef.current then
				task.cancel(colorThreadRef.current)
				colorThreadRef.current = nil
			end
			ingredientModelsRef.current = {}
		end
	end, { props.Data, cloneRef.current, CMOdel })

	useEffect(function()
		if not cloneRef.current or not promptRef.current then
			return
		end

		local prompt = promptRef.current
		local data = props.Data

		-- Clear previous connection
		if connectionRef.current then
			connectionRef.current:Disconnect()
			connectionRef.current = nil
		end

		-- warn("")
		if not data or data == "none" then
			-- Empty state
			prompt.ActionText = "Craft"
			prompt.Enabled = true

			-- No timer needed for empty state
		else
			-- Crafting state
			local potionId = data.PotionId
			local startTime = data.StartTime
			local duration = CraftingModule.CraftingLookup[potionId].Duration
			local endTime = startTime + duration

			-- Timer loop
			local running = true
			task.spawn(function()
				while running do
					local timeLeft = endTime - workspace:GetServerTimeNow()

					if timeLeft <= 0 then
						prompt.ActionText = "Pickup Potion"
						prompt.Enabled = true

						-- Handle Pickup
						if not connectionRef.current then
							connectionRef.current = prompt.Triggered:Connect(function(player)
								if player == props.Player then
									local CraftPickup =
										game.ReplicatedStorage.Shared.Events:FindFirstChild("CraftPickup")
									if CraftPickup then
										CraftPickup:FireServer(props.CauldronId)
									end
								end
							end)
						end
					else
						prompt.ActionText = string.format("Brewing... (%ds)", timeLeft)
						prompt.Enabled = false -- Disable interaction while brewing
					end

					task.wait(1)
				end
			end)

			return function()
				running = false
			end
		end
	end, { props.Data })

	return e("Folder")
end

local function CompletionBoard(props: {
	Player: Player,
	PlayerSession: PlayerSessions.PlayerEntity,
})
	local playerSession = props.PlayerSession
	-- Update background colors based on unlocked potions
	useEffect(function()
		local completionBoard = playerSession.Plot:FindFirstChild("CompletionBoard")
		if not completionBoard then
			return
		end

		local surfaceGui = completionBoard:FindFirstChild("CompletionBoardUI")
		if not surfaceGui then
			return
		end

		local grid = surfaceGui:FindFirstChild("Container", true) and surfaceGui.Container:FindFirstChild("PotionGrid")

		if not grid then
			return
		end

		-- Update each potion frame's background color
		-- Three states: locked (dark grey), unlocked (grey), thrown (green)
		for _, frame in ipairs(grid:GetChildren()) do
			if frame:IsA("Frame") and frame.Name ~= "PotionGrid" then
				local potionId = frame.Name
				local isThrown = playerSession.Data.ThrownPotions and playerSession.Data.ThrownPotions[potionId]
				local isUnlocked = playerSession.Data.PotionBook[potionId]

				if isThrown then
					frame.BackgroundColor3 = Color3.fromRGB(80, 200, 100) -- Green for thrown
				elseif isUnlocked then
					frame.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Grey for unlocked
				else
					frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark grey for locked
				end
			end
		end

		return function()
			-- Cleanup: reset all frames to locked color
			for _, frame in ipairs(grid:GetChildren()) do
				if frame:IsA("Frame") and frame.Name ~= "PotionGrid" then
					frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				end
			end
		end
	end, { playerSession.Plot, playerSession.Data.PotionBook, playerSession.Data.ThrownPotions })

	return nil
end

local function PotionSlot(props: {
	SlotNum: string,
	RackId: string,
	Player: Player,
	PlayerSession: PlayerSessions.PlayerEntity,
	rackModel: Model,
})
	local slotNum = props.SlotNum
	local rackId = props.RackId
	local rack = props.PlayerSession.Data.PotionSlots[rackId]
	local UID = rack and rack[slotNum]
	local occupied = UID ~= "none"
	local potionModelRef = useRef(nil)

	useEffect(function()
		if props.rackModel then
			local slotPart = props.rackModel:FindFirstChild(slotNum)
			if not slotPart then
				return
			end
			slotPart.PlacePrompt.RequiresLineOfSight = false
			(slotPart.PlacePrompt :: ProximityPrompt).Enabled = false
			slotPart.PlacePrompt.Style = Enum.ProximityPromptStyle.Custom
			-- Set action text based on slot state
			if occupied then
				(slotPart.PlacePrompt :: ProximityPrompt).ActionText = "Pick Up Potion"
			else
				(slotPart.PlacePrompt :: ProximityPrompt).ActionText = "Place Potion"
			end
			-- Note: Enabled state is controlled by client-side hook based on equipped tool
		end
		return function() end
	end, { props.rackModel, occupied })
	useEffect(function()
		if props.rackModel then
			local slotPart = props.rackModel:FindFirstChild(slotNum)
			local debounce = false

			-- Add touch handler for collection
			local touchConnection = slotPart.Touched:Connect(function(part)
				local player = Players:GetPlayerFromCharacter(part.Parent)
				if not player or player ~= props.Player then
					return
				end

				local state = PlayerSessions:getState()
				local session = state.players[player]
				if not session then
					return
				end

				local collector = session.Data.Collectors[rackId] and session.Data.Collectors[rackId][slotNum]
				if not collector or collector.Collected <= 0 then
					return
				end

				if debounce then
					return
				end
				debounce = true
				local success = TycoonService.Collect(player, rackId, slotNum)

				if success then
					-- Emit particles
					local particleEmitter = slotPart:FindFirstChildOfClass("ParticleEmitter")
					if particleEmitter then
						particleEmitter:Emit(5)
					end
					local ds = potionModelRef.current and potionModelRef.current:GetDescendants()
					if ds then
						for i, d in ds do
							if d:IsA("ParticleEmitter") then
								d:Emit(5)
							end
						end
					end
				end

				task.wait(0.5)
				debounce = false
			end)
			local placedebounce = false

			-- Place prompt handler
			slotPart.PlacePrompt.Triggered:Connect(function(player)
				if placedebounce then
					return
				end
				placedebounce = true
				PotionService.PlacePotion(player, rackId, slotNum)
				task.wait(0.5)
				placedebounce = false
			end)

			return function()
				if touchConnection then
					touchConnection:Disconnect()
				end
			end
		end
		return function() end
	end, { props.rackModel })
	useEffect(function()
		local model, bbgui
		if props.rackModel and not potionModelRef.current and UID ~= "none" then
			local potion
			for i, p in props.PlayerSession.Data.Potions do
				if p.UID == UID then
					potion = p
					break
				end
			end
			if not potion then
				return
			end
			model = createPotionModel(potion)
			model.Name = potion.UID
			local ds = model:GetDescendants()
			if ds then
				for i, d in ds do
					if d:IsA("ParticleEmitter") then
						-- d.Enabled = false
					end
				end
			end

			model.Parent = props.rackModel
			for i, children in model:GetChildren() do
				if children:IsA("BasePart") then
					children:SetAttribute("SlotNum", slotNum)
					children:SetAttribute("RackNum", rackId)
				end
			end
			local slot = props.rackModel:FindFirstChild(slotNum)
			slot:SetAttribute("SlotNum", slotNum)
			slot:SetAttribute("RackNum", rackId)

			model:PivotTo(slot:GetPivot())
			-- props.rackModel:FindFirstChild(slotNum).Transparency = 1
			potionModelRef.current = model
		end
		return function()
			if model then
				model:Destroy()
				potionModelRef.current = nil
			end
			if props.rackModel then
				-- props.rackModel:FindFirstChild(slotNum).Transparency = 0.6
			end
		end
	end, { UID, props.rackModel })

	return e("StringValue")
end
local function Rack(props)
	local playerSession = props.PlayerSession
	local rack: Folder = props.Rack
	local racknum = rack.Name
	local base = rack.Base
	local owned = props.owned
	-- local owned, setOwned = useState(props.owned)
	local modelState, setModelState = useState(nil)
	local modelRef = useRef(nil)
	local price: number = rack:GetAttribute("Price")

	local buyrack = function(player)
		if props.Player ~= player then
			return
		end
		local rackId = rack.Name :: string
		local success = TycoonService.BuyRack(player, rackId, price)
	end

	-- rendering
	useEffect(function()
		if price <= 0 and not owned then
			buyrack(props.Player)
			owned = true
			-- setOwned(true)
		end
		local pp
		local TouchedConnection
		if owned then
			if not modelState then
				local model = game.ReplicatedStorage.Shared.Models:FindFirstChild("Rack"):Clone()
				model:PivotTo(base:GetPivot())
				model.Parent = rack
				setModelState(model)
			end
		else
			pp = Instance.new("ProximityPrompt")
			pp.RequiresLineOfSight = false
			pp.ActionText = "Buy"
			pp.ObjectText = Mionum.new(price):toString()
			pp.Triggered:Connect(function(player)
				buyrack(player)
			end)
			pp.Parent = base
		end
		return function()
			if pp then
				pp:Destroy()
			end
		end
	end, { owned })

	useEffect(function()
		modelRef.current = modelState
	end, { modelState })
	useEffect(function()
		return function()
			if modelRef.current then
				warn("YES modelRef.current, DESTROYING")
				modelRef.current:Destroy()
				modelRef.current = nil
			else
			end
		end
	end, {})

	local children = {}
	for i = 1, 6 do
		local name = "Slot" .. i
		children[name] = e(PotionSlot, {
			key = name,
			RackId = racknum,
			SlotNum = name,
			Player = props.Player,
			PlayerSession = playerSession,
			rackModel = modelState,
		})
	end

	return e("StringValue", nil, children)
end

--[[======================================================================================================================================================================================================]]

local Tycoon = function(props: TycoonProps)
	local playerSession: PlayerSessions.PlayerEntity = props.PlayerSession
	local pd = playerSession.Data
	local isMountedRef = useRef(false)
	local plot = playerSession.Plot

	-- 5. RENDERING
	local children = {
		Potions = e(Potions, {
			PlayerSession = playerSession,
			Player = props.Player,
		}),
		CompletionBoard = e(CompletionBoard, {
			PlayerSession = playerSession,
			Player = props.Player,
		}),
	}
	-- Render Cauldrons
	local cauldronFolder = plot.Cauldrons
	local cauldrons = cauldronFolder:GetChildren()
	for i, cauldronInstance in pairs(cauldrons) do
		local cauldron = playerSession.Data.Cauldrons[cauldronInstance.Name]
		children[i] = e(CauldronItem, {
			key = cauldronInstance.Name,
			owned = cauldron and true or nil,
			Player = props.Player,
			PotionId = cauldron and cauldron.PotionId,
			CauldronId = i,
			Data = type(cauldron) == "table" and cauldron or nil,
			CauldronInstance = cauldronInstance,
			VariationId = cauldron and cauldron.VariationId,
			playerSession = playerSession,
		})
	end

	-- Render Racks
	local Multiplier = MultiplierService.GetFinalMultiplier(playerSession.Player)
	local s = {}
	local ps = plot.PotionSlots:GetChildren()
	for i, rack: Folder in ps do
		local owned = playerSession.Data.PotionSlots[rack.Name]
		children[rack.Name .. "_RACK"] = e(Rack, {
			key = rack.Name,
			Rack = rack,
			owned = owned,
			RackTable = owned,
			Multiplier = Multiplier,
			Player = props.Player,
			PlayerSession = playerSession,
		})
	end

	useEffect(function()
		isMountedRef.current = true
		local plot = props.Plot
		local player = props.Player
		if not plot or not player then
			return
		end

		local ownerBoard = plot:FindFirstChild("CompletionBoard", true)
		local CollectButton: Part = plot:FindFirstChild("CollectButton", true)
		if not ownerBoard or not ownerBoard:IsA("Part") then
			return
		end

		-- Create SurfaceGui
		local surfaceGui = Instance.new("BillboardGui")
		surfaceGui.Name = "OwnerSurfaceGui"
		surfaceGui.Adornee = ownerBoard
		-- surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.Parent = ownerBoard
		surfaceGui.Size = UDim2.fromScale(20, 20)
		surfaceGui.StudsOffsetWorldSpace = Vector3.new(0, 40, 0)

		-- Create ImageLabel
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Size = UDim2.new(1, 0, 1, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.Parent = surfaceGui

		-- Create TextLabel
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(1, 0, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = player.Name
		TextLabel.TextScaled = true
		-- TextLabel.TextSize = 100
		TextLabel.Parent = surfaceGui
		TextLabel.Font = Enum.Font.FredokaOne
		TextLabel.ZIndex = 3

		-- Get player thumbnail
		local Players = game:GetService("Players")
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size420x420
		local thumbUrl, _ = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
		imageLabel.Image = thumbUrl

		return function()
			isMountedRef.current = false
			if surfaceGui then
				surfaceGui:Destroy()
			end
			local textlabel = props.Plot
				and props.Plot.Collector
				and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
				and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
				and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
			if textlabel and textlabel:IsA("TextLabel") then
				textlabel.Text = ""
			else
				warn("No textlabel")
			end
		end
	end, { props.Plot, props.Player, HttpService:JSONEncode(playerSession.Data.Cauldrons) })

	return e("Folder", {
		Name = props.Player.Name .. "'s Tycoon",
	}, children)
end

--[[======================================================================================================================================================================================================]]

-- MANAGES ALL TYCOON
local function TycoonApp(props)
	local tycoons: { [Player]: TycoonProps }, setTycoons = useState({} :: { [Player]: TycoonProps })
	local tycoonsRef = useRef({})

	-- Once Mounted
	useEffect(function()
		local selectPlayers = function(state: PlayerSessions.PlayersState)
			return state.players
		end
		PlayerSessions:observe(selectPlayers, function(session: PlayerSessions.PlayerEntity, player: Player)
			setTycoons(function(prev)
				local tycoon = {
					Player = player,
					PlayerSession = session,
				}
				return { unpack(prev), [player] = tycoon }
			end)
			return function()
				-- cleanup
				setTycoons(function(prev)
					local newTycoons = table.clone(prev or {})
					newTycoons[player] = nil
					return newTycoons
				end)
			end
		end)

		return function() end
	end, {})

	useEffect(function()
		tycoonsRef.current = tycoons
	end, { tycoons })

	local children = {}

	for i, tycoon: TycoonProps in tycoons do
		children[tycoon.Player.Name .. "'s Tycoon"] = e(Tycoon, {
			key = "tycoon" .. tycoon.Player.UserId,
			Player = tycoon.Player,
			PlayerSession = tycoon.PlayerSession,
		})
	end

	return e("Folder", {
		Name = "Tycoon App",
	}, children)
end

--[[======================================================================================================================================================================================================]]

function TycoonView.initialize()
	if TycoonView.isInitialized then
		return
	end
	TycoonView.isInitialized = true
end

function TycoonView.start()
	local rootFolder = Instance.new("Folder", workspace)
	rootFolder.Name = "TycoonServiceRoot"
	TycoonView.Root = ReactRoblox.createRoot(rootFolder)
	TycoonView.Root:render(e(TycoonApp))
end

-- local cb = (workspace.Plots.Plot.CompletionBoard :: Model):GetPivot()
-- local min = math.huge
-- local max = 0
-- local t = game.Selection:Get()
-- for i, d: Model in t do
-- 	local distance = math.round((cb.Position - d:GetPivot().Position).Magnitude)
-- 	if distance <= min then
-- 		min = distance
-- 	end
-- 	if distance >= max then
-- 		max = distance
-- 	end
-- end
-- local range = max - min
-- for i = 1, #t, 1 do
-- 	t[i].Name = "Rack" .. i
-- 	local distance = math.round((cb.Position - t[i]:GetPivot().Position).Magnitude)
-- 	if distance <= min then
-- 		min = distance
-- 		t[i]:SetAttribute("Price", 0)
-- 		continue
-- 	end
-- 	local price = distance - min
-- 	t[i]:SetAttribute("Price", price ^ 4)
-- end
return TycoonView
