local Reflex = require(game.ReplicatedStorage.Packages.Reflex)
local PotionConfigs = require(game.ReplicatedStorage.Shared.Configs.PotionConfigs)
export type Data = {
	Cash: number,
	Potions: { PotionConfigs.PotionInstance },
	PotionSlots: {
		[string]: { -- rack
			[string]: string, -- slot
		},
	},
	Cauldrons: {
		[string]: {
			CauldronId: string,
			PotionId: string,
			StartTime: number,
			VariationId: string,
			Size: number,
		},
	},
}

export type PlayersActions = {
	addPlayer: (player: Player, data: Data, plot: Model) -> (),
	removePlayer: (player: Player) -> (),
	addPlayerCash: (player: Player, amt: number) -> (),
}

export type PlayerEntity = {
	Data: Data,
	Plot: Model?,
}

export type PlayersState = {
	players: { [Player]: PlayerEntity }, -- Renamed 'entities' to 'players' for clarity
}

local initialState: PlayersState = {
	players = {},
}

local producer = Reflex.createProducer(initialState, {
	addPlayer = function(state, player, data, plot)
		local newPlayers = table.clone(state.players)
		newPlayers[player] = {
			Data = data,
			Plot = plot,
		}
		return {
			unpack(state),
			players = newPlayers,
		}
	end,
	removePlayer = function(state, player)
		local players = table.clone(state.players)
		players[player] = nil
		return { unpack(state), players = players }
	end,

	addPlayerCash = function(state, player: Player, amt: number)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			newData.Cash += amt
			newEntity.Data = newData
			players[player] = newEntity
		end

		return { unpack(state), players = players }
	end,

	addPotion = function(state, player: Player, potion: {})
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newPotions = table.clone(entity.Data.Potions)
			table.insert(newPotions, potion)
			newData.Potions = newPotions
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
	removePotion = function(state, potionId) end,

	setCauldron = function(state, player: Player, cauldronId: string, cauldron: {})
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newPotions = table.clone(entity.Data.Potions)
			newPotions[cauldronId] = cauldron
			newData.Potions = newPotions
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
})

return producer :: Reflex.Producer<PlayersState, PlayersActions>
