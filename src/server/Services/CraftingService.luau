-- local MarketplaceService = game:GetService("MarketplaceService")
-- local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
-- local VariationRNGService = require(game.ServerScriptService.Server.Services.VariationRNGService)

-- local sizes = { 1, 1, 1, 2, 2, 3 }
-- local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
-- local Signal = require(game.ReplicatedStorage.Packages.Signal)

-- local CraftingService = {}
-- local PlotService = require(game.ServerScriptService.Server.Services.PlotService)

-- -- Create RemoteFunction for crafting
-- local GetIngredients = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
-- GetIngredients.Name = "GetIngredients"

-- -- Create RemoteFunction for getting potions
-- local GetPotions = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
-- GetPotions.Name = "GetPotions"

-- -- Create RemoteEvent for IngredientChange
-- local IngredientsChanged = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- IngredientsChanged.Name = "IngredientsChanged"

-- -- Create RemoteEvent for crafting
-- local CraftPotion = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- CraftPotion.Name = "CraftPotion"

-- -- Create RemoteEvent for Potions updates
-- local PotionsUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- PotionsUpdated.Name = "PotionsUpdated"

-- -- Create RemoteEvent for resetting ingredients (playtest)
-- local ResetIngredients = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- ResetIngredients.Name = "ResetIngredients"

-- -- Create RemoteEvent for Pickup
-- local CraftPickup = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- CraftPickup.Name = "CraftPickup"

-- -- Create RemoteEvent for Skip (Playtest)
-- local SkipCraft = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- SkipCraft.Name = "SkipCraft"

-- -- Generate a unique ID for potions
-- local potionCounter = 0
-- local function generatePotionUID(player: Player)
-- 	potionCounter += 1
-- 	local UID = ("%014X"):format(workspace:GetServerTimeNow() * 1e4)
-- 	UID = UID:sub(8, UID:len()) .. "_POTION_" .. potionCounter
-- 	return UID
-- end

-- local function getVariation(): string
-- 	local SpecialEventsService = require(game.ServerScriptService.Server.Services.SpecialEventsService)

-- 	local v = VariationRNGService:roll()
-- 	return v.VariationId
-- end

-- local function OnCraftPickup(player: Player, cauldronId)
-- 	local playerSession = PlayerDataService:GetSession(player)
-- 	local cauldron = playerSession.Profile.Data.Cauldrons[cauldronId]
-- 	if not cauldron or cauldron == "none" then
-- 		warn("no cauldron:", cauldron)
-- 		return
-- 	end

-- 	-- check if done
-- 	local StartTime = cauldron.StartTime
-- 	local UID = cauldron.UID
-- 	local VariationId = cauldron.VariationId
-- 	local PotionId = cauldron.PotionId
-- 	local endtime = StartTime + CraftingModule.CraftingLookup[PotionId].Duration
-- 	local done = endtime <= workspace:GetServerTimeNow()
-- 	if done then
-- 		-- warn("Done!")
-- 	else
-- 		-- warn(workspace:GetServerTimeNow() - endtime, "time left")
-- 		return
-- 	end

-- 	playerSession:AddPotion({
-- 		UID = UID,
-- 		VariationId = VariationId,
-- 		PotionId = PotionId,
-- 		Size = cauldron.Size,
-- 	})

-- 	-- Clear cauldron
-- 	playerSession.Profile.Data.Cauldrons[cauldronId] = "none"

-- 	playerSession:FireChangedEvent()
-- 	PotionsUpdated:FireClient(player, playerSession.Profile.Data.Potions)

-- 	-- Always fire PlayerDataUpdated, but especially important for new recipes
-- 	local PlayerDataUpdated: UnreliableRemoteEvent = game.ReplicatedStorage.Shared.Events.PlayerDataUpdated
-- 	PlayerDataUpdated:FireClient(player, playerSession.Profile.Data)

-- 	-- print(string.format("[CraftingService] Player %s crafted potion %s (UID: %s)", player.Name, PotionId, UID))
-- end

-- local function OnSkipCraft(player: Player, cauldronId: string)
-- 	local playerSession = PlayerDataService:GetSession(player)
-- 	if not playerSession then
-- 		warn("No player session found for", player.Name)
-- 		return
-- 	end

-- 	local cauldron = playerSession.Profile.Data.Cauldrons[cauldronId]
-- 	if not cauldron or cauldron == "none" then
-- 		warn("No cauldron data for:", cauldronId)
-- 		return
-- 	end

-- 	-- Instantly set StartTime to make it done
-- 	local PotionId = cauldron.PotionId
-- 	local duration = CraftingModule.CraftingLookup[PotionId].Duration
-- 	playerSession.Profile.Data.Cauldrons[cauldronId].StartTime = workspace:GetServerTimeNow() - duration - 1
-- 	playerSession:FireChangedEvent()
-- 	-- playerSession.CauldronsChanged:Fire()

-- 	local PlayerDataUpdated: UnreliableRemoteEvent = game.ReplicatedStorage.Shared.Events.PlayerDataUpdated
-- 	PlayerDataUpdated:FireClient(player, playerSession.Profile.Data)
-- 	-- print(string.format("[CraftingService] Player %s skipped crafting for %s", player.Name, cauldronId))
-- end

-- local function OnSkipCraftRequest(player: Player, cauldronId: string)
-- 	local playerSession = PlayerDataService:GetSession(player)
-- 	if not playerSession then
-- 		warn("No player session found for", player.Name)
-- 		return
-- 	end

-- 	local cauldron = playerSession.Profile.Data.Cauldrons[cauldronId]
-- 	if not cauldron or cauldron == "none" then
-- 		warn("No cauldron data for:", cauldronId)
-- 		return
-- 	end

-- 	-- Store the cauldron context and prompt purchase
-- 	local MonetizationService = require(game.ServerScriptService.Server.Services.MonetizationService)
-- 	MonetizationService.PendingSkips[player.UserId] = { cauldronId = cauldronId }
-- 	MonetizationService.PromptProductPurchase(player, 3450086552) -- Skip Brewing product ID
-- end

-- -- Handle player craft request
-- local function OnPlayerCraft(player: Player, potionId: string, cauldronId: string)
-- 	local playerSession = PlayerDataService:GetSession(player)
-- 	if not playerSession then
-- 		warn("No player session found for", player.Name)
-- 		return false
-- 	end

-- 	local pd = playerSession.Profile.Data
-- 	if not pd then
-- 		warn("No player data found for", player.Name)
-- 		return false
-- 	end

-- 	-- Get the craft recipe from CraftingModule
-- 	local craftRecipe = CraftingModule.CraftingLookup[potionId]
-- 	if not craftRecipe then
-- 		warn("Invalid craft ID:", potionId)
-- 		return false
-- 	end

-- 	-- guard againtst occupied cauldron
-- 	local CauldronInstance = playerSession.Profile.Data.Cauldrons[cauldronId]
-- 	if CauldronInstance ~= "none" then
-- 		return
-- 	end

-- 	-- Check if player has enough ingredients
-- 	local ingredients = craftRecipe.Ingredients
-- 	for _, itemId in ipairs(ingredients) do
-- 		local currentAmount = pd.Resources.Ingredients[itemId] or 0
-- 		if currentAmount < 1 then
-- 			warn("Not enough ingredients:", itemId)
-- 			return false
-- 		end
-- 	end

-- 	-- Deduct ingredients
-- 	for _, itemId in ipairs(ingredients) do
-- 		playerSession:_Set({ "Resources", "Ingredients", itemId }, pd.Resources.Ingredients[itemId] - 1)
-- 	end
-- 	IngredientsChanged:FireClient(player, playerSession.Profile.Data.Resources.Ingredients)

-- 	-- Generate size (1-3) using bell curve probability
-- 	local rng = Random.new(tick() + player.UserId)
-- 	local bell = math.abs(rng:NextNumber() - rng:NextNumber())
-- 	local size = sizes[math.clamp(math.floor(1 + bell * 6), 1, 5)]
-- 	-- Occupy cauldron slot
-- 	playerSession.Profile.Data.Cauldrons[cauldronId] = {
-- 		UID = generatePotionUID(player),
-- 		StartTimeW = workspace:GetServerTimeNow(),
-- 		VariationId = getVariation(),
-- 		PotionId = potionId,
-- 		Size = size,
-- 	}

-- 	local PlayerDataUpdated: UnreliableRemoteEvent = game.ReplicatedStorage.Shared.Events.PlayerDataUpdated
-- 	PlayerDataUpdated:FireClient(player, pd)
-- 	playerSession:FireChangedEvent()

-- 	return true
-- end

-- local function OnGetIngredients(player)
-- 	local playerSession = PlayerDataService:GetSession(player)
-- 	if not playerSession then
-- 		warn("No player session found for", player.Name)
-- 		return false
-- 	end

-- 	return playerSession.Profile.Data.Resources.Ingredients
-- end

-- local function OnGetPotions(player)
-- 	local playerSession = PlayerDataService:GetSession(player)
-- 	if not playerSession then
-- 		warn("No player session found for", player.Name)
-- 		return {}
-- 	end

-- 	return playerSession.Profile.Data.Potions or {}
-- end

-- function CraftingService.initialize()
-- 	if CraftingService.isInitialized then
-- 		return
-- 	end
-- 	-- Connect the remote event
-- 	CraftPotion.OnServerEvent:Connect(OnPlayerCraft)

-- 	GetIngredients.OnServerInvoke = OnGetIngredients
-- 	GetPotions.OnServerInvoke = OnGetPotions

-- 	CraftPickup.OnServerEvent:Connect(OnCraftPickup)
-- 	SkipCraft.OnServerEvent:Connect(OnSkipCraftRequest) -- for prod
-- 	-- SkipCraft.OnServerEvent:Connect(OnSkipCraft) -- for test

-- 	CraftingService.OnSkipCraft = OnSkipCraft
-- 	CraftingService.isInitialized = true
-- end

-- return CraftingService
return {}
