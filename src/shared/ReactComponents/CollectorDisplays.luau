local React = require(game.ReplicatedStorage.Packages.React)
local Mionum = require(game.ReplicatedStorage.Packages.Mionum)
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local MultiplierService = require(game.ReplicatedStorage.Shared.Utils.MultiplierHelper)
local PotionConfigs = require(game.ReplicatedStorage.Shared.CraftingModule).CraftingLookup
local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

-- Helper function to calculate final potion rate with all multipliers
local function calculatePotionRate(potion, playerMultiplier)
	local config = PotionConfigs[potion.PotionId]
	if not config then
		return 0
	end
	local varcfg = VariationsConfig[potion.VariationId] or VariationsConfig.none
	return math.floor(config.Rate * varcfg.Multiplier * (playerMultiplier or 1) * (potion.Size or 1))
end

local function CollectorDisplay(props: {
	RackId: string,
	SlotId: string,
	PotionUID: string,
	Collected: number,
	Potions: any,
	PlayerMultiplier: number,
})
	local billboardRef = useRef(nil)

	useEffect(function()
		-- Find the slot part in the workspace
		local player = game.Players.LocalPlayer
		local session = PlayerSessions:getState().players[player]
		local plot = session and session.Plot
		if not plot then
			return
		end

		local rackFolder = plot.PotionSlots:FindFirstChild(props.RackId)
		if not rackFolder then
			return
		end
		local rackmodel = rackFolder:FindFirstChild("Rack")
		if not rackmodel then
			return
		end
		local potionModel = rackmodel:FindFirstChild(props.PotionUID)
		if not potionModel then
			return
		end

		local cf, s = potionModel:GetBoundingBox()

		local basePart = potionModel:FindFirstChildWhichIsA("BasePart", true)
		if not basePart then
			warn("NOT BASE PART")
			local success, part = xpcall(function()
				local start = tick()
				while not potionModel:FindFirstChild("Bottle") and (tick() - start < 5) do
					task.wait()
				end
				return potionModel:FindFirstChild("Bottle")
			end, function()
				warn("Waited but no part")
			end)
			if not (success and part) then
				return
			end
			basePart = part
		end

		-- Create attachment
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(0, s.Y / 2, 0)
		attachment.Parent = basePart

		-- Create billboard GUI
		local bbgui = game.ReplicatedStorage.Shared.BillboardGui:Clone()
		bbgui.Parent = attachment
		billboardRef.current = bbgui

		return function()
			if billboardRef.current then
				if billboardRef.current.Parent then
					billboardRef.current.Parent:Destroy()
				end
				billboardRef.current:Destroy()
				billboardRef.current = nil
			end
		end
	end, { props.RackId, props.SlotId, props.PotionUID })

	-- Update billboard text
	useEffect(function()
		if not billboardRef.current then
			-- Find the slot part in the workspace
			local player = game.Players.LocalPlayer
			local session = PlayerSessions:getState().players[player]
			local plot = session and session.Plot
			if not plot then
				return
			end

			local rackFolder = plot.PotionSlots:FindFirstChild(props.RackId)
			if not rackFolder then
				return
			end
			local rackmodel = rackFolder:FindFirstChild("Rack")
			if not rackmodel then
				return
			end
			local potionModel = rackmodel:FindFirstChild(props.PotionUID)
			if not potionModel then
				return
			end
			local cf, s = potionModel:GetBoundingBox()
			local basePart = potionModel:FindFirstChildWhichIsA("BasePart", true)
			if not basePart then
				warn("NOT BASE PART")
				local success, part = xpcall(function()
					local start = tick()
					while not potionModel:FindFirstChild("Bottle") and (tick() - start < 5) do
						task.wait()
					end
					return potionModel:WaitForChild("Bottle")
				end, function()
					warn("Waited but no part")
				end)
				if not success then
					return
				end
				basePart = part
			end

			-- Create attachment
			local attachment = Instance.new("Attachment")
			attachment.Position = Vector3.new(0, s.Y / 2, 0)
			attachment.Parent = basePart

			-- Create billboard GUI
			local bbgui = game.ReplicatedStorage.Shared.BillboardGui:Clone()
			bbgui.Parent = attachment
			billboardRef.current = bbgui

			return
		end

		-- Find the potion
		local potion = nil
		for _, p in props.Potions do
			if p.UID == props.PotionUID then
				potion = p
				break
			end
		end

		if not potion then
			return
		end

		local finalRate = calculatePotionRate(potion, props.PlayerMultiplier)
		billboardRef.current.TextLabel.Text =
			string.format("%s\n%s/s", Mionum.new(props.Collected):toString(), Mionum.new(finalRate):toString())
	end, { props.PlayerSession, props.Collected, props.PotionUID, props.PlayerMultiplier, props.Potions })

	return nil
end

local function CollectorDisplays()
	local playerData, setPlayerData = useState(nil)
	local playerMultiplier, setPlayerMultiplier = useState(1)
	-- Subscribe to player data
	useEffect(function()
		local player = game.Players.LocalPlayer
		local selectPlayer = function(state: PlayerSessions.PlayersState)
			return state.players[player]
		end
		local unsubscribe = PlayerSessions:subscribe(selectPlayer, function(playerEntity: PlayerSessions.PlayerEntity)
			if playerEntity and playerEntity.Data then
				setPlayerData(playerEntity.Data)
			end
		end)

		-- Initial state
		local state = PlayerSessions:getState()
		local playerEntity = state.players[player]
		if playerEntity and playerEntity.Data then
			setPlayerData(playerEntity.Data)
		end

		return function()
			unsubscribe()
		end
	end, {})

	-- Calculate player multiplier
	useEffect(function()
		if not playerData then
			return
		end

		local multiplier = MultiplierService.GetFinalMultiplier(playerData.Multipliers or {})
		setPlayerMultiplier(multiplier)
	end, { playerData and playerData.Multipliers })

	if not playerData then
		return nil
	end

	local children = {}

	-- Iterate through all racks and slots
	for rackId, rack in pairs(playerData.PotionSlots or {}) do
		for slotId, potionUID in pairs(rack) do
			if potionUID and potionUID ~= "none" then
				local collector = playerData.Collectors[rackId] and playerData.Collectors[rackId][slotId]
				if collector then
					local key = rackId .. "_" .. slotId
					children[key] = e(CollectorDisplay, {
						key = key,
						RackId = rackId,
						SlotId = slotId,
						PotionUID = potionUID,
						Collected = collector.Collected or 0,
						Potions = playerData.Potions,
						PlayerMultiplier = playerMultiplier,
						PlayerSession = playerData,
					})
				end
			end
		end
	end

	return e(React.Fragment, nil, children)
end

return CollectorDisplays
