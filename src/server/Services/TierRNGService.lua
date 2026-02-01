local Probability = require(game.ServerScriptService.Server.Modules.Probability)
local Clock = require(game.ServerScriptService.Server.Services.Clock)
local TiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local TierRNGService = {}
local normalTiers = { "common", "uncommon", "rare", "epic", "legendary", "mythic" }
local itemsByTier = {}

-- Pre-computed quantity ranges based on tier weights
local ITEM_QUANTITY_RANGES = {
	common = { Min = 6, Max = 9 },
	uncommon = { Min = 5, Max = 7 },
	rare = { Min = 4, Max = 5 },
	epic = { Min = 2, Max = 5 },
	legendary = { Min = 1, Max = 4 },
	mythic = { Min = 0, Max = 3 },
}

function TierRNGService.initialize()
	if TierRNGService.isInitialized then
		-- warn("initializing more once")
		return
	end
	TierRNGService.isInitialized = true

	-- Group items by tier for shop generation
	for _, item in ipairs(ItemsConfig) do
		if not itemsByTier[item.TierId] then
			itemsByTier[item.TierId] = {}
		end
		table.insert(itemsByTier[item.TierId], item)
	end

	TierRNGService.Probs = {} :: {}
	for i, tierId in normalTiers do
		local tiercfg = TiersConfig[tierId]
		TierRNGService.Probs[tiercfg.TierId] = Probability.new(tiercfg.Weight)
	end
end

function TierRNGService.getShopItems(seed: number)
	local rng = Random.new(seed)
	local shopItems = {}

	for _, item in ipairs(ItemsConfig) do
		local tierCfg = TiersConfig[item.TierId]
		if not tierCfg then
			continue
		end

		local range = ITEM_QUANTITY_RANGES[item.TierId]
		local total = math.abs(range.Max + 1 - range.Min)

		local bell = math.abs(rng:NextNumber() - rng:NextNumber()) -- from [-1,1] to [0, 1]
		local count = math.floor(range.Min + bell * total)
		shopItems[item.ItemId] = 0 + math.clamp(count, 0, range.Max)
	end

	return shopItems
end

function TierRNGService:roll()
	local tiercfg
	if not TierRNGService.isInitialized then
		warn("NOT YET INITIALIZED")
	end
	for tierId, prob in TierRNGService.Probs do
		if tierId == "common" then
			continue
		end
		local count = prob:getProbability()
		local max = prob.maxProb
		local roll = prob:roll()
		for tierId, probx in TierRNGService.Probs do
			probx:increment()
		end
		if roll then
			tiercfg = TiersConfig[tierId]
			break
		end
	end
	-- warn(tiercfg or TiersConfig["common"])
	return tiercfg or TiersConfig["common"]
end

TierRNGService.initialize()
-- local itemStats = {}
-- for _, item in ipairs(ItemsConfig) do
-- 	itemStats[item.ItemId] = {}
-- end

-- for seed = 1, 10000 do
-- 	local shopItems = TierRNGService.getShopItems(seed)
-- 	for itemId, count in pairs(shopItems) do
-- 		if not itemStats[itemId][count] then
-- 			itemStats[itemId][count] = 0
-- 		end
-- 		itemStats[itemId][count] += 1
-- 	end
-- end

-- print("\n=== SHOP ITEMS QUANTITY DISTRIBUTION (10000 Seeds) ===\n")
-- for _, item in ipairs(ItemsConfig) do
-- 	local itemId = item.ItemId
-- 	local tierId = item.TierId
-- 	print(string.format("\n[%s] %s (Tier: %s)", itemId, item.DisplayName or itemId, tierId))
-- 	print("Quantity | Occurrences | Percentage")
-- 	print("---------|-------------|------------")

-- 	local quantities = {}
-- 	for qty in pairs(itemStats[itemId]) do
-- 		table.insert(quantities, qty)
-- 	end
-- 	table.sort(quantities)

-- 	for _, qty in ipairs(quantities) do
-- 		local occurrences = itemStats[itemId][qty]
-- 		local percentage = (occurrences / 10000) * 100
-- 		print(string.format("   %2d    |    %4d     |   %5.1f%%", qty, occurrences, percentage))
-- 	end
-- end
-- print("\n=== END OF REPORT ===\n")

--[[
local TierRNGService = require(game.ServerScriptService.Server.Services.TierRNGService)
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local iter = 10000
TierRNGService.initialize()
local itemStats = {}
for _, item in ipairs(ItemsConfig) do
	itemStats[item.ItemId] = {}
end
for seed = 1, iter do
	local shopItems = TierRNGService.getShopItems(seed)
	for itemId, count in pairs(shopItems) do
		if not itemStats[itemId][count] then
			itemStats[itemId][count] = 0
		end
		itemStats[itemId][count] += 1
	end
end
print("\n=== SHOP ITEMS QUANTITY DISTRIBUTION (iter Seeds) ===\n")
for _, item in ipairs(ItemsConfig) do
	local itemId = item.ItemId
	local tierId = item.TierId
	print(string.format("\n[%s] %s (Tier: %s)", itemId, item.DisplayName or itemId, tierId))
	print("Quantity | Occurrences | Percentage")
	print("---------|-------------|------------")
	local quantities = {}
	for qty in pairs(itemStats[itemId]) do
		table.insert(quantities, qty)
	end
	table.sort(quantities)
	for _, qty in ipairs(quantities) do
		local occurrences = itemStats[itemId][qty]
		local percentage = (occurrences / iter) * 100
		print(string.format("   %2d    |     %2d      |   %5.1f%%", qty, occurrences, percentage))
	end
end
print("\n=== END OF REPORT ===")]]
return TierRNGService
