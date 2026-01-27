local RunService = game:GetService("RunService")
local Reflex = require(game.ReplicatedStorage.Packages.Reflex)
local PotionConfigs = require(game.ReplicatedStorage.Shared.Configs.PotionConfigs)
local MultiplierHelper = require(game.ReplicatedStorage.Shared.Utils.MultiplierHelper)
local isserver = RunService:IsServer()
export type CauldronInstance = PotionConfigs.CauldronInstance

export type Multiplier = {
	DisplayName: string?,
	Value: number, -- Bonus percentage: 0.5 = +50%, 1.0 = +100% (2x total), 0.25 = +25%
	Expire: number, -- -1 for permanent, or timestamp when expires
}
export type Data = {
	Cash: number,
	Potions: { PotionConfigs.PotionInstance },
	PotionSlots: {
		[string]: { -- rack
			[string]: string, -- slot
		},
	},
	Cauldrons: {
		[string]: CauldronInstance,
	},
	Collectors: {
		[string]: { -- RackId
			[string]: { -- SlotId
				Collected: number,
				LastUpdate: number,
			},
		},
	},
	Ingredients: { [string]: number },
	ThrownPotions: {},
	PotionBook: {},
	ShopCycles: {
		[string]: { [string]: number },
	},
	Multipliers: { [string]: Multiplier },
	TutorialFinished: boolean?,
}

export type PlayerEntity = {
	Data: Data,
	Plot: Model?,
	Character: Model?,
}

export type PlayersActions = {
	addPlayer: (player: Player, data: Data, plot: Model) -> (),
	removePlayer: (player: Player) -> (),
	addPlayerCash: (player: Player, amt: number) -> (),
	setPotionSlot: (player: Player, rackId: string, slotNum: string, potionUID: string?) -> (),
	updateCollector: (player: Player, rackId: string, slotId: string, collected: number) -> (),
	emptyCollector: (player: Player, rackId: string, slotId: string) -> (),
	updateAllCollectors: () -> (),
	setTutorialFinished: (player: Player, finished: boolean) -> (),
	resetPlayer: (player: Player, data: Data) -> (),
}

export type PlayersState = {
	players: { [Player]: PlayerEntity }, -- Renamed 'entities' to 'players' for clarity
}

local initialState: PlayersState = {
	players = {},
}

local producer = Reflex.createProducer(initialState, {
	-- player session add and remove
	addPlayer = function(state: PlayersState, player, data, plot)
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
	removePlayer = function(state: PlayersState, player)
		local players = table.clone(state.players)
		players[player] = nil
		return { unpack(state), players = players }
	end,

	-- cash
	addPlayerCash = function(state: PlayersState, player: Player, amt: number)
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

	-- potion actions
	addPotion = function(state: PlayersState, player: Player, potion: {})
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newPotions = table.clone(entity.Data.Potions)
			table.insert(newPotions, potion)

			local newPotionBook = table.clone(entity.Data.PotionBook)
			if not newPotionBook[potion.PotionId] then
				warn("NEW IN POTIONBOOK!")
				newPotionBook[potion.PotionId] = true
				local newMultipliers = table.clone(newData.Multipliers)

				newMultipliers.unlockBonus = {
					DisplayName = "Unlock Bonus",
					Expire = -1,
					Value = (newMultipliers.unlockBonus and newMultipliers.unlockBonus.Value or 0) + 0.05,
				}
				newData.Multipliers = newMultipliers
				newData.PotionBook = newPotionBook
			else
				warn("NOT NEW")
			end

			newData.Potions = newPotions
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
	removePotions = function(state: PlayersState, player: Player, UIDs: { string })
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(newEntity.Data)
			local newPotions = table.clone(newData.Potions)

			-- Create a set of UIDs for faster lookup
			local UIDSet = {}
			for _, uid in UIDs do
				UIDSet[uid] = true
			end

			-- Filter out potions with matching UIDs
			local filteredPotions = {}
			for _, potion: PotionConfigs.PotionInstance in newPotions do
				if not UIDSet[potion.UID] then
					table.insert(filteredPotions, potion)
				end
			end

			newData.Potions = filteredPotions
			newEntity.Data = newData
			players[player] = newEntity
		end
		return {
			unpack(state),
			players = players,
		}
	end,
	removeBatchPotion = function(state: PlayersState, player: Player, UIDs: { string })
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(newEntity.Data)
			local newPotions = table.clone(newData.Potions)

			-- Create a set of UIDs for faster lookup
			local UIDSet = {}
			for _, uid in UIDs do
				UIDSet[uid] = true
			end

			-- Filter out potions with matching UIDs
			local filteredPotions = {}
			for _, potion: PotionConfigs.PotionInstance in newPotions do
				if not UIDSet[potion.UID] then
					table.insert(filteredPotions, potion)
				end
			end

			newData.Potions = filteredPotions
			newEntity.Data = newData
			players[player] = newEntity
		end
		return {
			unpack(state),
			players = players,
		}
	end,

	-- cauldron actions
	setCauldron = function(
		state: PlayersState,
		player: Player,
		cauldronId: string,
		cauldron: CauldronInstance | "none"
	)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newCauldrons = table.clone(entity.Data.Cauldrons)
			newCauldrons[cauldronId] = cauldron
			newData.Cauldrons = newCauldrons
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
	addCauldron = function(state: PlayersState, player: Player, cauldronId: string)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newCauldrons = table.clone(entity.Data.Cauldrons)
			newCauldrons[cauldronId] = "none"
			newData.Cauldrons = newCauldrons
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,

	-- potion slots actions
	setPotionSlot = function(state: PlayersState, player: Player, rackId: string, slotNum: string, potionUID: string?)
		if not (state and player and rackId and slotNum) then
			return state
		end
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newPotionSlots = table.clone(entity.Data.PotionSlots)

			-- If setting a potion UID (not "none"), remove it from any existing slot first
			if potionUID and potionUID ~= "none" then
				for existingRackId, rack in pairs(newPotionSlots) do
					for slotId, existingUID in pairs(rack) do
						if existingUID == potionUID then
							local newExistingRack
							newExistingRack = table.clone(newPotionSlots[existingRackId])
							newExistingRack[slotId] = "none"
							newPotionSlots[existingRackId] = newExistingRack
						end
					end
				end
			end

			local newRack = table.clone(newPotionSlots[rackId])
			newRack[slotNum] = potionUID or "none"
			newPotionSlots[rackId] = newRack
			newData.PotionSlots = newPotionSlots

			-- Calculate pending earnings before resetting collector
			if newData.Collectors[rackId] and newData.Collectors[rackId][slotNum] then
				local newCollectors = table.clone(newData.Collectors)
				local newCollectorRack = table.clone(newCollectors[rackId])
				local collector = newCollectorRack[slotNum]

				-- Get the old potion UID to calculate final earnings
				local oldPotionUID = entity.Data.PotionSlots[rackId] and entity.Data.PotionSlots[rackId][slotNum]
				if oldPotionUID and oldPotionUID ~= "none" then
					-- Calculate final earnings for the old potion
					local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
					local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
					local now = workspace:GetServerTimeNow()
					local MAX_OFFLINE_TIME = 86400

					for _, potion in ipairs(entity.Data.Potions) do
						if potion.UID == oldPotionUID then
							local craftConfig = CraftingModule.CraftingLookup[potion.PotionId]
							if craftConfig then
								local rate = craftConfig.Rate
								local variationConfig = VariationsConfig[potion.VariationId]
								local variationMultiplier = variationConfig and variationConfig.Multiplier or 1

								local lastUpdate = collector.LastUpdate or now
								local deltaTime = math.min(now - lastUpdate, MAX_OFFLINE_TIME)
								local ratePerSecond = rate * variationMultiplier
								local totalEarnings = ratePerSecond * deltaTime
								local wholeEarnings = math.floor(totalEarnings)

								-- Calculate time consumed for whole earnings to preserve fractional seconds
								local timeConsumed = ratePerSecond > 0 and (wholeEarnings / ratePerSecond) or deltaTime

								-- Add final earnings before reset
								newCollectorRack[slotNum] = {
									Collected = (collector.Collected or 0) + wholeEarnings,
									LastUpdate = lastUpdate + timeConsumed,
								}
							end
							break
						end
					end
				end

				-- If placing a new potion or removing (setting to none), reset to 0
				if not oldPotionUID or oldPotionUID == "none" or potionUID ~= oldPotionUID then
					newCollectorRack[slotNum] = {
						Collected = 0,
						LastUpdate = workspace:GetServerTimeNow(),
					}
				end

				newCollectors[rackId] = newCollectorRack
				newData.Collectors = newCollectors
			end
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,

	-- rack buying action
	buyRack = function(state: PlayersState, player: Player, rackId: string, price: number)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)

			-- Check if player has enough money
			if newData.Cash < price then
				return state
			end

			-- Deduct money
			newData.Cash -= price

			-- Initialize PotionSlots for this rack
			local newPotionSlots = table.clone(newData.PotionSlots)
			newPotionSlots[rackId] = {
				Slot1 = "none",
				Slot2 = "none",
				Slot3 = "none",
				Slot4 = "none",
				Slot5 = "none",
				Slot6 = "none",
			}
			newData.PotionSlots = newPotionSlots

			-- Initialize Collectors for this rack
			local now = workspace:GetServerTimeNow()
			local newCollectors = table.clone(newData.Collectors)
			newCollectors[rackId] = {
				Slot1 = { Collected = 0, LastUpdate = now },
				Slot2 = { Collected = 0, LastUpdate = now },
				Slot3 = { Collected = 0, LastUpdate = now },
				Slot4 = { Collected = 0, LastUpdate = now },
				Slot5 = { Collected = 0, LastUpdate = now },
				Slot6 = { Collected = 0, LastUpdate = now },
			}
			newData.Collectors = newCollectors

			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,

	-- ingredient actions
	deductIngredients = function(state: PlayersState, player: Player, ingredients: { string })
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newIngredients = table.clone(entity.Data.Ingredients)

			for _, itemId in ipairs(ingredients) do
				local currentAmount = newIngredients[itemId] or 0
				if currentAmount >= 1 then
					newIngredients[itemId] = currentAmount - 1
				end
			end

			newData.Ingredients = newIngredients
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
	updateIngredient = function(state: PlayersState, player: Player, itemId: string, delta: number)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newIngredients = table.clone(entity.Data.Ingredients)

			local currentAmount = newIngredients[itemId] or 0
			newIngredients[itemId] = math.max(0, currentAmount + delta)

			newData.Ingredients = newIngredients
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,

	-- collector actions
	updateCollector = function(state: PlayersState, player: Player, rackId: string, slotId: string, collected: number)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newCollectors = table.clone(entity.Data.Collectors)

			if newCollectors[rackId] and newCollectors[rackId][slotId] then
				local newRack = table.clone(newCollectors[rackId])
				local lastUpdate = newRack[slotId].LastUpdate or workspace:GetServerTimeNow()
				newRack[slotId] = {
					Collected = collected,
					LastUpdate = lastUpdate,
				}
				newCollectors[rackId] = newRack
				newData.Collectors = newCollectors
				newEntity.Data = newData
				players[player] = newEntity
			end
		end
		return { unpack(state), players = players }
	end,
	emptyCollector = function(state: PlayersState, player: Player, rackId: string, slotId: string)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newCollectors = table.clone(entity.Data.Collectors)

			if newCollectors[rackId] and newCollectors[rackId][slotId] then
				local newRack = table.clone(newCollectors[rackId])
				newRack[slotId] = {
					Collected = 0,
					LastUpdate = newRack[slotId] and newRack[slotId].LastUpdate or workspace:GetServerTimeNow(),
				}
				newCollectors[rackId] = newRack
				newData.Collectors = newCollectors
				newEntity.Data = newData
				players[player] = newEntity
			end
		end
		if not isserver then
			-- Play sound
			-- local SoundController = require(			)
			shared.SoundController.CashSound()
		end
		return { unpack(state), players = players }
	end,
	updateAllCollectors = function(state: PlayersState)
		local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
		local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
		local players = table.clone(state.players)
		local now = workspace:GetServerTimeNow()
		local MAX_OFFLINE_TIME = 86400 -- 24 hours in seconds

		for player, playerEntity in pairs(players) do
			if playerEntity and playerEntity.Data then
				local newEntity = table.clone(playerEntity)
				local newData = table.clone(playerEntity.Data)
				local newCollectors = table.clone(playerEntity.Data.Collectors)

				-- Create potion lookup table once per player for performance
				local potionLookup = {}
				for _, potion in ipairs(newData.Potions) do
					potionLookup[potion.UID] = potion
				end

				-- Iterate through all racks
				for rackId, rackCollectors in pairs(newCollectors) do
					local rack = newData.PotionSlots[rackId]
					if rack then
						local newRack = table.clone(rackCollectors)

						-- Iterate through all slots in this rack
						for slotId, slotCollector in pairs(newRack) do
							local potionUID = rack[slotId]

							-- Skip empty slots
							if not potionUID or potionUID == "none" then
								continue
							end

							-- Look up potion from lookup table
							local potion = potionLookup[potionUID]
							if not potion then
								continue
							end

							local rate = 0
							local variationMultiplier = 1
							local potionSize = potion.Size or 1

							-- Calculate rate from potion in this slot
							local craftConfig = CraftingModule.CraftingLookup[potion.PotionId]
							if craftConfig then
								rate = craftConfig.Rate
							end

							-- Get variation multiplier
							local variationConfig = VariationsConfig[potion.VariationId]
							if variationConfig then
								variationMultiplier = variationConfig.Multiplier
							end

							-- Calculate earnings based on time delta, variation multiplier, player multiplier, and potion size
							local lastUpdate = slotCollector.LastUpdate or now
							local deltaTime = math.min(now - lastUpdate, MAX_OFFLINE_TIME)
							local currentCollected = slotCollector.Collected or 0
							local ratePerSecond = rate
								* variationMultiplier
								* MultiplierHelper.GetFinalMultiplier(newData.Multipliers)
								* potionSize
							local totalEarnings = ratePerSecond * deltaTime
							local wholeEarnings = math.floor(totalEarnings)

							-- Calculate how much time was actually consumed for whole earnings
							-- This preserves fractional seconds for next update
							local timeConsumed = ratePerSecond > 0 and (wholeEarnings / ratePerSecond) or deltaTime

							newRack[slotId] = {
								Collected = currentCollected + wholeEarnings,
								LastUpdate = lastUpdate + timeConsumed,
							}
						end

						newCollectors[rackId] = newRack
					end
				end

				newData.Collectors = newCollectors
				newEntity.Data = newData
				players[player] = newEntity
			end
		end
		return { unpack(state), players = players }
	end,

	-- multiplier actions
	addMultiplier = function(state: PlayersState, player: Player, multiplierId: string, multiplier: Multiplier)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newMultipliers = table.clone(entity.Data.Multipliers or {})
			newMultipliers[multiplierId] = multiplier
			newData.Multipliers = newMultipliers
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
	removeMultiplier = function(state: PlayersState, player: Player, multiplierId: string)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newMultipliers = table.clone(entity.Data.Multipliers or {})
			newMultipliers[multiplierId] = nil
			newData.Multipliers = newMultipliers
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,
	addMultiplierDuration = function(
		state: PlayersState,
		player: Player,
		multiplierId: string,
		additionalDuration: number
	)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newMultipliers = table.clone(entity.Data.Multipliers or {})
			local multiplier = newMultipliers[multiplierId]
			if multiplier and multiplier.Expire ~= -1 then
				local newMultiplier = table.clone(multiplier)
				newMultiplier.Expire = multiplier.Expire + additionalDuration
				newMultipliers[multiplierId] = newMultiplier
				newData.Multipliers = newMultipliers
				newEntity.Data = newData
				players[player] = newEntity
			end
		end
		return { unpack(state), players = players }
	end,
	removeExpiredMultipliers = function(state: PlayersState, player: Player, currentTime: number)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			local newMultipliers = table.clone(entity.Data.Multipliers or {})
			local hasChanges = false

			for multiplierId, multiplier in pairs(newMultipliers) do
				if multiplier.Expire ~= -1 and currentTime >= multiplier.Expire then
					newMultipliers[multiplierId] = nil
					hasChanges = true
				end
			end

			if hasChanges then
				newData.Multipliers = newMultipliers
				newEntity.Data = newData
				players[player] = newEntity
			end
		end
		return { unpack(state), players = players }
	end,

	setShopCycle = function(state: PlayersState, player: Player, currentSeed: string, shopItems: { [string]: number })
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(newEntity.Data)
			local newShopCycles = table.clone(newData.ShopCycles)

			-- set current items
			newShopCycles[tostring(currentSeed)] = shopItems
			for key, currentCycle in newShopCycles do
				-- delete old items
				-- local success, numKey = pcall(function()
				-- 	return tonumber(key)
				-- end)

				assert(
					typeof(key) == typeof(currentSeed),
					string.format(
						"ERROR: DIFFERENT TYPES COMPARED FOR SEED, %s (%s) ~= %s (%s)",
						key,
						typeof(key),
						currentSeed,
						typeof(currentSeed)
					)
				)
				if key ~= currentSeed then
					newShopCycles[key] = nil
					continue
				end
			end

			newData.ShopCycles = newShopCycles
			newEntity.Data = newData
			players[player] = newEntity
			warn("DONE", players)
		end
		return { unpack(state), players = players }
	end,

	-- tutorial action
	setTutorialFinished = function(state: PlayersState, player: Player, finished: boolean)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			local newData = table.clone(entity.Data)
			newData.TutorialFinished = finished
			newEntity.Data = newData
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,

	-- reset action
	resetPlayer = function(state: PlayersState, player: Player, data: Data)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			newEntity.Data = data
			players[player] = newEntity
		end
		return { unpack(state), players = players }
	end,

	-- character action
	setCharacter = function(state: PlayersState, player: Player, character: Model)
		local players = table.clone(state.players)
		local entity = players[player]
		if entity then
			local newEntity = table.clone(entity)
			newEntity.Character = character
			players[player] = newEntity
		end
		return {
			unpack(state),
			players = players,
		}
	end,
})

return producer :: Reflex.Producer<PlayersState, PlayersActions>
