local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local PotionConfigs = require(game.ReplicatedStorage.Shared.Configs.PotionConfigs)
local PotionService = {}

local function getPlayerSession(player: Player): PlayerSessions.PlayerEntity
	return PlayerSessions:getState(function(state: PlayerSessions.PlayersState)
		return state.players[player]
	end)
end

function PotionService.CraftPotion(player: Player, potionId: string): nil
	local playerSession = getPlayerSession(player)
	local potionConfig: PotionConfigs.PotionConfig? = PotionConfigs.Lookup[potionId]

	if not (player and potionId and playerSession and potionConfig) then
		return
	end
	if playerSession.Data.Cash >= potionConfig.Price then
	end

	return
end

function PotionService.initialize()
	-- initialize and connect events
end

return PotionService
