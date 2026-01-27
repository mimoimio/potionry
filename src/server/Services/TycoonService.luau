local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)

local TycoonService = {}

-- Collect
function TycoonService.Collect(player: Player, rackId: string, slotId: string)
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession then
		warn("[TycoonService] No playerSession found for player:", player.Name)
		return false
	end

	local collector = playerSession.Data.Collectors[rackId] and playerSession.Data.Collectors[rackId][slotId]
	if not collector then
		warn("[TycoonService] No collector found for rack:", rackId, "slot:", slotId)
		return false
	end

	if collector.Collected <= 0 then
		return false
	end

	PlayerSessions.addPlayerCash(player, collector.Collected)
	PlayerSessions.emptyCollector(player, rackId, slotId)
	return true
end

--[[
	Attempts to purchase a cauldron for a player.
	@param player Player - The player buying the cauldron
	@param cauldronId string - The ID of the cauldron (e.g., "Cauldron1")
	@param price number - The price of the cauldron
	@return boolean - Success status
]]
function TycoonService.BuyCauldron(player: Player, cauldronId: string, price: number): boolean
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession then
		warn("[TycoonService] No playerSession found for player:", player.Name)
		return false
	end

	-- Validate cauldron ID
	if not string.find(cauldronId, "Cauldron") then
		warn("[TycoonService] Invalid cauldron ID:", cauldronId)
		return false
	end

	-- Check if player has enough money
	if playerSession.Data.Cash < price then
		warn("[TycoonService] Player", player.Name, "doesn't have enough money for cauldron")
		return false
	end

	-- Check if cauldron already owned
	if playerSession.Data.Cauldrons[cauldronId] then
		warn("[TycoonService] Cauldron", cauldronId, "already owned by", player.Name)
		return false
	end

	-- Deduct money and add cauldron
	PlayerSessions.addPlayerCash(player, -price)
	PlayerSessions.addCauldron(player, cauldronId)

	print(string.format("[TycoonService] %s purchased %s for %d", player.Name, cauldronId, price))
	return true
end

--[[
	Attempts to purchase a rack for a player.
	@param player Player - The player buying the rack
	@param rackId string - The ID of the rack (e.g., "Rack1")
	@param price number - The price of the rack
	@return boolean - Success status
]]
function TycoonService.BuyRack(player: Player, rackId: string, price: number): boolean
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession then
		warn("[TycoonService] No playerSession found for player:", player.Name)
		return false
	end

	-- Validate rack ID
	if not string.find(rackId, "Rack") then
		warn("[TycoonService] Invalid rack ID:", rackId)
		return false
	end

	-- Check if rack already owned
	if playerSession.Data.PotionSlots[rackId] then
		warn("[TycoonService] Rack", rackId, "already owned by", player.Name)
		return false
	end

	-- Use producer action to buy rack (handles money check and initialization)
	PlayerSessions.buyRack(player, rackId, price)
	-- Verify purchase was successful by checking if rack now exists
	local updatedSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if updatedSession and updatedSession.Data.PotionSlots[rackId] then
		print(string.format("[TycoonService] %s purchased %s for %d", player.Name, rackId, price))
		return true
	else
		warn("[TycoonService] Failed to purchase rack (likely insufficient funds)")
		return false
	end
end

--[[
	Resets a player's data back to the default template.
	@param player Player - The player to reset
	@return boolean - Success status
]]
function TycoonService.ResetPlayer(player: Player): boolean
	local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
	local PlotService = require(game.ServerScriptService.Server.Services.PlotService)

	-- Get fresh template data
	local newData = {}
	for key, value in pairs(PlayerDataService.PROFILE_TEMPLATE) do
		if type(value) == "table" then
			newData[key] = table.clone(value)
		else
			newData[key] = value
		end
	end

	-- Clear the plot
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if playerSession and playerSession.Plot then
		PlotService.ReturnPlot(playerSession.Plot)
	end
	-- Reset player data in PlayerSessions
	PlayerSessions.removePlayer(player)
	warn("removing")
	task.wait(1)
	PlayerSessions.addPlayer(player, newData, PlotService.GetPlot(player))
	PlayerSessions.setCharacter(player, player.Character)

	print(string.format("[TycoonService] Reset data for %s", player.Name))
	return true
end

function TycoonService.initialize()
	local Click = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	Click.Name = "Click"
	Click.OnServerEvent:Connect(function(player)
		local cash = PlayerSessions:getState(function(state)
			if state.players[player] then
				return state.players[player].Data.Cash
			end
		end)
		PlayerSessions.addPlayerCash(player, cash + 1)
	end)

	-- Reset player data (for playtesting)
	local ResetData = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	ResetData.Name = "ResetData"
	ResetData.OnServerEvent:Connect(function(player)
		TycoonService.ResetPlayer(player)
	end)

	-- Start collector update loop (1 second interval)
	local lastUpdate = os.clock()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastUpdate >= 1 then
			lastUpdate = now
			PlayerSessions.updateAllCollectors()
		end
	end)
end

function TycoonService.start() end

return TycoonService
