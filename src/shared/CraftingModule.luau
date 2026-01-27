local CraftingModule = {}

local ItemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local CraftDurations = {
	common = 5,
	uncommon = 7,
	rare = 18,
	epic = 60,
	legendary = 150,
	mythic = 240,
}

-- The main lookup table
local CraftingLookup = {}
local CraftingTable = {}

-- Store resized ingredient models
local ResizedModels = {}

-- Ingredient naming attributes
local IngredientNames = {
	fireblossom = { Adjective = "Scorched", Prefix = "Ember", Suffix = "bloom" },
	waterleaf = { Adjective = "Tidal", Prefix = "Hydro", Suffix = "frond" },
	bloodthorn = { Adjective = "Vile", Prefix = "Sanguine", Suffix = "barb" },
	spiralaloe = { Adjective = "Twisted", Prefix = "Helix", Suffix = "coil" },
	daybloom = { Adjective = "Dawn", Prefix = "Solar", Suffix = "petal" },
	glowshroom = { Adjective = "Radiant", Prefix = "Neon", Suffix = "cap" },
	moonglow = { Adjective = "Lunar", Prefix = "Astral", Suffix = "gleam" }, -- not yet implemented
	blinkroot = { Adjective = "Flickering", Prefix = "Phase", Suffix = "root" },
	luckyclover = { Adjective = "Gilded", Prefix = "Fortune", Suffix = "luck" },
	deathweed = { Adjective = "Cursed", Prefix = "Necrotic", Suffix = "weed" },
}

-- Helper: Generate key from ingredients (order matters for permutations)
local function GetKey(ingredients: { string })
	-- table.sort(ingredients, function(a, b)
	-- 	return ItemConfigs[a].Rate < ItemConfigs[b].Rate
	-- end)
	return table.concat(ingredients)
end

-- Helper: Generate display name based on ingredient positions
local function GetDisplayName(ingredients)
	local numIngredients = #ingredients

	if numIngredients == 1 then
		local itemId = ingredients[1]
		return ItemConfigs[itemId].DisplayName -- Just return the ingredient name
	elseif numIngredients == 2 then
		-- Slot 1: Adjective, Slot 2: Suffix
		local item1 = IngredientNames[ingredients[1]]
		local item2 = IngredientNames[ingredients[2]]
		if item1 and item2 then
			return item1.Prefix .. item2.Suffix
		else
			return ingredients[1] .. " " .. ingredients[2]
		end
	elseif numIngredients == 3 then
		-- Slot 1: Adjective, Slot 2: Prefix, Slot 3: Suffix
		local item1 = IngredientNames[ingredients[1]] or warn("NOTHING HERE")
		local item2 = IngredientNames[ingredients[2]] or warn("NOTHING HERE")
		local item3 = IngredientNames[ingredients[3]] or warn("NOTHING HERE")
		if item1 and item2 and item3 then
			return item3.Adjective .. " " .. item1.Prefix .. item2.Suffix
		else
			return ingredients[1] .. " " .. ingredients[2] .. " " .. ingredients[3]
		end
	end

	return "Unknown"
end

local SLOT_WEIGHTS = { 2.0, 1.5, 1.0 }
local lvloffset = 1
-- Helper function to create a recipe config with weighted attributes
local function CreateRecipeConfig(ingredientIndices, allItemIds)
	local ingredients = {}
	local totalRate = 0
	local totalPrice = 0
	local totalDuration = 0

	for slot, index in ipairs(ingredientIndices) do
		local itemId = allItemIds[index]
		local weight = (SLOT_WEIGHTS[slot] or 1.0) + lvloffset

		table.insert(ingredients, itemId)

		-- Apply slot weights to each attribute
		totalRate = totalRate + (ItemConfigs[itemId].Rate * weight)
		totalPrice = totalPrice + (ItemConfigs[itemId].Price * (math.log10(weight))) / 10
		totalDuration = totalDuration + CraftDurations[ItemConfigs[itemId].TierId] + lvloffset
	end

	local key = GetKey(ingredients)
	local config = {
		Price = math.floor(totalPrice),
		Rate = math.floor(totalRate),
		Duration = math.floor(totalDuration),
		PotionId = key,
		DisplayName = GetDisplayName(ingredients),
		Ingredients = ingredients,
	}
	lvloffset += 0.1
	return config
end

function CraftingModule:InitProcedural()
	-- 1. Extract and sort all valid Item IDs by Rate (Ascending = Unlock Owrder)
	local allItemIds = {}
	for i, itemconfig in ipairs(ItemConfigs) do
		table.insert(allItemIds, itemconfig.ItemId)
	end

	table.sort(allItemIds, function(a, b)
		return ItemConfigs[a].Rate < ItemConfigs[b].Rate
	end)

	-- 2. Waterfall Generation: Generate recipes incrementally as each ingredient "unlocks"
	for unlocked_idx = 1, #allItemIds do
		-- === LENGTH 1: Single ingredient ===
		local config1 = CreateRecipeConfig({ unlocked_idx }, allItemIds)
		CraftingLookup[config1.PotionId] = config1
		table.insert(CraftingTable, config1)

		-- === LENGTH 2: Pairs (2 Items) ===
		local batch_len2 = {}
		for i = 1, unlocked_idx do
			for j = 1, unlocked_idx do
				if i ~= j and (i == unlocked_idx or j == unlocked_idx) then
					table.insert(batch_len2, { i, j })
				end
			end
		end

		-- Sort by slot indices: Slot 1 (Asc), then Slot 2 (Asc)
		table.sort(batch_len2, function(a, b)
			if a[1] ~= b[1] then
				return a[1] < b[1]
			end
			return a[2] < b[2]
		end)

		for _, combo in ipairs(batch_len2) do
			local config2 = CreateRecipeConfig(combo, allItemIds)
			CraftingLookup[config2.PotionId] = config2
			table.insert(CraftingTable, config2)
		end

		-- === LENGTH 3: Triples (3 Items) ===
		local batch_len3 = {}
		for i = 1, unlocked_idx do
			for j = 1, unlocked_idx do
				for k = 1, unlocked_idx do
					if i ~= j and i ~= k and j ~= k then
						if i == unlocked_idx or j == unlocked_idx or k == unlocked_idx then
							table.insert(batch_len3, { i, j, k })
						end
					end
				end
			end
		end

		-- Sort by slot indices: Slot 1, then Slot 2, then Slot 3
		table.sort(batch_len3, function(a, b)
			if a[1] ~= b[1] then
				return a[1] < b[1]
			end
			if a[2] ~= b[2] then
				return a[2] < b[2]
			end
			return a[3] < b[3]
		end)

		for _, combo in ipairs(batch_len3) do
			local config3 = CreateRecipeConfig(combo, allItemIds)
			CraftingLookup[config3.PotionId] = config3
			table.insert(CraftingTable, config3)
		end
	end
end

function CraftingModule:Craft(ingredients)
	local key = GetKey(ingredients)
	return CraftingLookup[key]
end

-- Run initialization
CraftingModule:InitProcedural()
CraftingModule.CraftingLookup = CraftingLookup
CraftingModule.CraftingTable = CraftingTable

-- Add ThumbnailCamera positioned like in PotionViewport
for itemid, config in CraftingLookup do
	local model = game.ReplicatedStorage.Shared.Models:WaitForChild("Potions"):FindFirstChild(itemid)

	local camera = model:FindFirstChild("ThumbnailCamera") or Instance.new("Camera")
	camera.Name = "ThumbnailCamera"
	camera.Parent = model

	local cf, size = model:GetBoundingBox()
	local distance = 3
	camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, 1, 1)) * CFrame.Angles(0, 0, 0)
	camera.CFrame = CFrame.lookAt(camera.CFrame.Position, cf.Position)
	camera:ZoomToExtents(cf, size)
end

-- Add ThumbnailCamera for each item ingredient model
for i, itemconfig in ipairs(ItemConfigs) do
	local model = game.ReplicatedStorage.Shared.Models:FindFirstChild(itemconfig.ItemId)

	if model then
		local camera = model:FindFirstChild("ThumbnailCamera") or Instance.new("Camera")
		camera.Name = "ThumbnailCamera"
		camera.Parent = model

		local cf, size = model:GetBoundingBox()
		local distance = 3
		camera.CFrame = CFrame.new(cf.Position + Vector3.new(-1, 1, 1)) * CFrame.Angles(0, 0, 0)
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, cf.Position)
		camera:ZoomToExtents(cf, size)
	end
end

return CraftingModule
