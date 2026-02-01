local React = require(game.ReplicatedStorage.Packages.React)
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local useState = React.useState
local useEffect = React.useEffect

-- Hook to sync Roblox Inventory with a Slot-based system
local function useRobloxInventory(totalSlots)
	-- The mapping state: { [1] = ToolA, [2] = nil, [3] = ToolB, ... }
	local slotMapping, setSlotMapping = useState(function()
		return table.create(totalSlots, nil)
	end)

	useEffect(function()
		local player = Players.LocalPlayer
		local backpack = player:WaitForChild("Backpack")
		local character = player.Character or player.CharacterAdded:Wait()

		-- Helper: Find first available empty slot in the current mapping
		local function getFreeSlot(currentMapping)
			for i = 1, totalSlots do
				if currentMapping[i] == nil then
					return i
				end
			end
			return nil
		end

		-- Core Sync Function
		local function refreshInventory()
			setSlotMapping(function(prevMapping)
				local newMapping = table.clone(prevMapping)

				-- 1. Identify all valid tools currently owned (Backpack + Character)
				local currentTools = {}

				local function scanContainer(container)
					for _, item in ipairs(container:GetChildren()) do
						if item:IsA("Tool") then
							currentTools[item] = true
						end
					end
				end

				scanContainer(backpack)
				if player.Character then
					scanContainer(player.Character)
				end

				-- 2. Remove "Stale" tools (Tools that were dropped/destroyed)
				for i, tool in pairs(newMapping) do
					if tool and not currentTools[tool] then
						newMapping[i] = nil
					end
				end

				-- 3. Add "New" tools (Tools picked up that aren't in a slot yet)
				for tool, _ in pairs(currentTools) do
					-- Check if this tool is already mapped
					if tool.Name == "Remove Potion" then
						continue
					end
					local isMapped = false
					for _, mappedTool in pairs(newMapping) do
						if mappedTool == tool then
							isMapped = true
							break
						end
					end

					-- If not mapped, find a free slot
					if not isMapped then
						local freeSlot = getFreeSlot(newMapping)
						if freeSlot then
							newMapping[freeSlot] = tool
						else
							warn("Inventory Full! Could not map tool:", tool.Name)
						end
					end
				end

				return newMapping
			end)
		end

		-- Listeners
		local c1 = backpack.ChildAdded:Connect(refreshInventory)
		local c2 = backpack.ChildRemoved:Connect(refreshInventory)

		-- Character Listeners (for Equipping/Unequipping)
		local charAddedConn = player.CharacterAdded:Connect(function(newChar)
			character = newChar
			refreshInventory() -- resync on spawn
			-- Reconnect child listeners for new character
		end)

		local childAddedConn, childRemovedConn

		local function bindCharacter(char)
			if childAddedConn then
				childAddedConn:Disconnect()
			end
			if childRemovedConn then
				childRemovedConn:Disconnect()
			end

			childAddedConn = char.ChildAdded:Connect(refreshInventory)
			childRemovedConn = char.ChildRemoved:Connect(refreshInventory)
		end

		bindCharacter(character)

		-- Also need to handle CharacterAdded dynamically
		local charConn = player.CharacterAdded:Connect(function(newChar)
			character = newChar
			bindCharacter(newChar)
			refreshInventory()
		end)

		-- Initial Run
		refreshInventory()

		return function()
			c1:Disconnect()
			c2:Disconnect()
			charConn:Disconnect()
			if childAddedConn then
				childAddedConn:Disconnect()
			end
			if childRemovedConn then
				childRemovedConn:Disconnect()
			end
		end
	end, {})

	-- Potion Slots: Enable/Disable proximity prompts based on equipped potion
	useEffect(function()
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)

		local function updateSlotProximityPrompts()
			-- Get player's plot from PlayerSessions
			local state = PlayerSessions:getState()
			local playerEntity = state.players[player]
			if not playerEntity or not playerEntity.Plot then
				warn("NOT ENTITY OR PLOT", state)
				return
			end

			local plot = playerEntity.Plot
			local potionSlots = plot:FindFirstChild("PotionSlots")
			if not potionSlots then
				warn("NOT POTIONSLOTS")
				return
			end

			-- Check if player has a potion tool equipped
			local equippedPotion = nil
			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") and tool.Name ~= "Remove Potion" then
					-- Check if it's a potion (has PotionId attribute)
					if tool:GetAttribute("PotionId") then
						equippedPotion = tool
						break
					end
				end
			end

			-- Enable/disable all slot prompts based on equipped potion
			for _, rack in ipairs(potionSlots:GetChildren()) do
				if rack:IsA("Model") then -- is actually a model
					local rackModel = rack:FindFirstChild("Rack")
					if rackModel then
						local rackName = rack.Name
						local rackData = playerEntity.Data.PotionSlots[rackName]

						for i = 1, 6 do
							local slotName = "Slot" .. i
							local slotPart = rackModel:FindFirstChild(slotName)
							if slotPart then
								local prompt = slotPart:FindFirstChild("PlacePrompt")
								if prompt and prompt:IsA("ProximityPrompt") then
									prompt.Enabled = equippedPotion ~= nil

									-- Check if slot is occupied
									local occupied = rackData and rackData[slotName] and rackData[slotName] ~= "none"
									if occupied then
										prompt.ActionText = "Replace"
									else
										prompt.ActionText = "Place Potion"
									end
								end
							end
						end
					end
				end
			end
		end

		local unsubscribe = PlayerSessions:subscribe(function(state: PlayerSessions.PlayersState)
			local session = state.players[player]
			return session and session.Data.Collectors
		end, function(collectors)
			updateSlotProximityPrompts()
		end)

		-- Update when tools are added/removed from character
		local toolAddedConn = character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.wait(0.1) -- Small delay to ensure tool is fully equipped
				updateSlotProximityPrompts()
			end
		end)

		local toolRemovedConn = character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				task.wait(0.1)
				updateSlotProximityPrompts()
			end
		end)

		-- Handle character respawn
		local charConn = player.CharacterAdded:Connect(function(newChar)
			character = newChar
			updateSlotProximityPrompts()
		end)

		-- Initial update
		updateSlotProximityPrompts()

		return function()
			unsubscribe()
			toolAddedConn:Disconnect()
			toolRemovedConn:Disconnect()
			charConn:Disconnect()
		end
	end, {})

	-- Gifting: Enable/Disable proximity prompts based on equipped potion
	useEffect(function()
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")

		local function updateProximityPrompts()
			-- Get all gift proximity prompts
			local giftPrompts = CollectionService:GetTagged("GiftPP")

			-- Check if player has a potion tool equipped
			local equippedPotion = nil
			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") and tool.Name ~= "Remove Potion" then
					-- Check if it's a potion (has PotionId attribute)
					if tool:GetAttribute("PotionId") then
						equippedPotion = tool
						break
					end
				end
			end

			-- Enable/disable all other players' prompts
			for _, prompt in ipairs(giftPrompts) do
				if prompt:IsA("ProximityPrompt") then
					local promptPlayer = prompt.Parent and Players:GetPlayerFromCharacter(prompt.Parent.Parent)

					-- Enable if we have potion equipped and it's not our own prompt
					if promptPlayer and promptPlayer ~= player then
						prompt.Enabled = equippedPotion ~= nil
					end
				end
			end
		end

		-- Update when tools are added/removed from character
		local toolAddedConn = character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.wait(0.1) -- Small delay to ensure tool is fully equipped
				updateProximityPrompts()
			end
		end)

		local toolRemovedConn = character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				task.wait(0.1)
				updateProximityPrompts()
			end
		end)

		-- Listen for proximity prompt triggers
		local promptConnections = {}
		local function connectPrompts()
			-- Disconnect old connections
			for _, conn in ipairs(promptConnections) do
				conn:Disconnect()
			end
			table.clear(promptConnections)

			local giftPrompts = CollectionService:GetTagged("GiftPP")
			for _, prompt in ipairs(giftPrompts) do
				if prompt:IsA("ProximityPrompt") then
					local conn = prompt.Triggered:Connect(function(triggeringPlayer)
						if triggeringPlayer == player then
							-- Get equipped potion
							local equippedPotion = nil
							for _, tool in ipairs(character:GetChildren()) do
								if tool:IsA("Tool") and tool:GetAttribute("PotionId") then
									equippedPotion = tool
									break
								end
							end

							if equippedPotion then
								-- Get target player from prompt's character
								local targetPlayer = Players:GetPlayerFromCharacter(prompt.Parent.Parent)
								if targetPlayer and targetPlayer ~= player then
									-- Fire gift request
									local RequestGift =
										game.ReplicatedStorage.Shared.Events:FindFirstChild("RequestGift")
									if RequestGift then
										RequestGift:FireServer(equippedPotion.Name, targetPlayer)
									end
								end
							end
						end
					end)
					table.insert(promptConnections, conn)
				end
			end
		end

		-- Initial update
		updateProximityPrompts()
		connectPrompts()

		-- Reconnect when new prompts are added
		local tagAddedConn = CollectionService:GetInstanceAddedSignal("GiftPP"):Connect(function()
			updateProximityPrompts()
			connectPrompts()
		end)

		local tagRemovedConn = CollectionService:GetInstanceRemovedSignal("GiftPP"):Connect(function()
			updateProximityPrompts()
		end)

		-- Handle character respawn
		local charConn = player.CharacterAdded:Connect(function(newChar)
			character = newChar
			humanoid = character:WaitForChild("Humanoid")
			updateProximityPrompts()
			connectPrompts()
		end)

		return function()
			toolAddedConn:Disconnect()
			toolRemovedConn:Disconnect()
			tagAddedConn:Disconnect()
			tagRemovedConn:Disconnect()
			charConn:Disconnect()
			for _, conn in ipairs(promptConnections) do
				conn:Disconnect()
			end
		end
	end, {})

	return slotMapping, setSlotMapping
end

return useRobloxInventory
