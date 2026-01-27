local ReplicatedStorage = game:GetService("ReplicatedStorage")
export type Multiplier = {
	DisplayName: string?,
	Value: number, -- Bonus percentage: 0.5 = +50%, 1.0 = +100% (2x total), 0.25 = +25%
	Expire: number, -- -1 for permanent, or timestamp when expires
}
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)
local MultiplierService = {}
MultiplierService.isInitialized = false

--[[
	Adds or updates a multiplier bonus for a player.
	@param player Player - The player to add multiplier to
	@param multiplierId string - Unique ID (e.g., "DoubleCash_GamePass", "TempBoost")
	@param value number - Bonus value: 1.0 for +100% (2x total), 0.5 for +50% (1.5x total)
	@param duration number - Duration in seconds (use -1 for permanent)
	@param DisplayName string - Display name for UI (e.g., "+100% Cash Bonus")
	@return boolean - Success status
]]
function MultiplierService.AddMultiplier(
	player: Player,
	multiplierId: string,
	value: number,
	duration: number,
	DisplayName: string
): boolean
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)
	if not playerSession then
		warn("[MultiplierService] No playerSession found for player:", player.Name)
		return false
	end

	local expireTime = duration == -1 and -1 or (workspace:GetServerTimeNow() + duration)

	PlayerSessions.addMultiplier(player, multiplierId, {
		DisplayName = DisplayName or multiplierId,
		Value = value,
		Expire = expireTime,
	})

	print(string.format("[MultiplierService] Added multiplier '%s' for %s", multiplierId, player.Name))
	return true
end

--[[
	Removes a specific multiplier from a player.
	@param player Player
	@param multiplierId string
	@return boolean - Success status
]]
function MultiplierService.RemoveMultiplier(player: Player, multiplierId: string): boolean
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession or not playerSession.Data.Multipliers then
		return false
	end

	if playerSession.Data.Multipliers[multiplierId] then
		PlayerSessions.removeMultiplier(player, multiplierId)
		print(string.format("[MultiplierService] Removed multiplier '%s' for %s", multiplierId, player.Name))
		return true
	end

	return false
end

--[[
	Adds duration to an existing multiplier.
	@param player Player
	@param multiplierId string
	@param additionalDuration number - Duration in seconds to add
	@return boolean - Success status
]]
function MultiplierService.AddDuration(player: Player, multiplierId: string, additionalDuration: number): boolean
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession or not playerSession.Data.Multipliers then
		return false
	end

	local multiplier = playerSession.Data.Multipliers[multiplierId]
	if not multiplier then
		return false
	end

	-- Don't add duration to permanent multipliers
	if multiplier.Expire == -1 then
		warn(string.format("[MultiplierService] Cannot add duration to permanent multiplier '%s'", multiplierId))
		return false
	end

	-- Add the duration using producer action
	PlayerSessions.addMultiplierDuration(player, multiplierId, additionalDuration)

	print(
		string.format(
			"[MultiplierService] Added %.0f seconds to multiplier '%s' for %s",
			additionalDuration,
			multiplierId,
			player.Name
		)
	)

	return true
end

--[[
	Checks if a player has a specific active multiplier.
	Automatically cleans up expired multipliers.
	@param player Player
	@param multiplierId string
	@return boolean - True if player has this active multiplier
]]
function MultiplierService.HasActiveMultiplier(player: Player, multiplierId: string): boolean | Multiplier
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession or not playerSession.Data.Multipliers then
		return false
	end

	local multiplier = playerSession.Data.Multipliers[multiplierId]
	if not multiplier then
		return false
	end

	-- Check if expired
	if multiplier.Expire ~= -1 and workspace:GetServerTimeNow() >= multiplier.Expire then
		-- Expired, remove it
		MultiplierService.RemoveMultiplier(player, multiplierId)
		return false
	end

	return playerSession.Data.Multipliers[multiplierId]
end

--[[
	Gets the final multiplier for a player by summing all active bonus percentages.
	Automatically cleans up expired multipliers.
	
	Formula: 1 + (sum of all multiplier.Value)
	
	Examples:
	- No bonuses: returns 1.0 (base rate)
	- One +50% bonus (0.5): returns 1.5
	- One +100% bonus (1.0): returns 2.0
	- +100% and +50% (1.0 + 0.5): returns 2.5
	
	@param player Player
	@param multiplierType string - Optional type filter (currently unused)
	@return number - Final multiplier value (minimum 1.0)
]]
function MultiplierService.GetFinalMultiplier(player: Player, multiplierType: string?): number
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession or not playerSession.Data.Multipliers then
		return 1
	end

	MultiplierService.CleanupExpired(player)

	local totalBonus = 0
	for multiplierId, multiplier in pairs(playerSession.Data.Multipliers) do
		totalBonus = totalBonus + multiplier.Value
	end

	-- Base (1.0) plus all bonuses, minimum 1.0
	return math.max(1, 1 + totalBonus)
end

--[[
	Cleans up all expired multipliers for a player.
	@param player Player
	@return number - Count of removed multipliers
]]
function MultiplierService.CleanupExpired(player: Player): number
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession or not playerSession.Data.Multipliers then
		return 0
	end

	local currentTime = workspace:GetServerTimeNow()
	local removedCount = 0

	-- Count expired multipliers
	for multiplierId, multiplier in pairs(playerSession.Data.Multipliers) do
		if multiplier.Expire ~= -1 and currentTime >= multiplier.Expire then
			removedCount = removedCount + 1
		end
	end

	-- Remove expired multipliers using producer action
	if removedCount > 0 then
		PlayerSessions.removeExpiredMultipliers(player, currentTime)
	end

	return removedCount
end

--[[
	Gets all active multipliers for a player (after cleanup).
	@param player Player
	@return { [string]: Multiplier } - Table of active multipliers
]]
function MultiplierService.GetMultipliers(player: Player): { [string]: Multiplier }
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession or not playerSession.Data.Multipliers then
		return {}
	end

	MultiplierService.CleanupExpired(player)
	return playerSession.Data.Multipliers
end

--[[
	Initializes the MultiplierService.
	Sets up periodic cleanup loop.
	Note: RemoteEvents are created in RemoteEventsService
]]
function MultiplierService.initialize()
	if MultiplierService.isInitialized then
		return
	end
	MultiplierService.isInitialized = true

	-- Periodic cleanup loop (every 30 seconds)
	task.spawn(function()
		while true do
			task.wait(30)
			for _, player in ipairs(game.Players:GetPlayers()) do
				local removed = MultiplierService.CleanupExpired(player)
				if removed > 0 then
					print(
						string.format(
							"[MultiplierService] Cleaned up %d expired multipliers for %s",
							removed,
							player.Name
						)
					)
				end
			end
		end
	end)

	-- print("[MultiplierService] Initialized")
end

return MultiplierService
