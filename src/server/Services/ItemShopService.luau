local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)
local IngredientService = require(script.Parent.IngredientService)
local ShopService = require(script.Parent.ShopService)
local ItemsConfig = require(ReplicatedStorage.Shared.Configs.ItemsConfig)

local ItemShopService = {}

--[[
	Attempts to purchase an ingredient item from the shop for a player.
	@param player Player - The player buying the item
	@param itemId string - The ID of the item to purchase
	@return boolean - Success status
]]
function ItemShopService.BuyItem(player: Player, itemId: string): boolean
	-- Get player session
	local playerSession = PlayerSessions:getState(function(state)
		return state.players[player]
	end)

	if not playerSession then
		warn("[ItemShopService] No playerSession found for player:", player.Name)
		return false
	end

	-- Get item config
	local itemConfig = ItemsConfig[itemId]
	if not itemConfig then
		warn("[ItemShopService] Invalid itemId:", itemId)
		return false
	end

	-- Check if player has enough cash
	if playerSession.Data.Cash < itemConfig.Price then
		warn("[ItemShopService] Player", player.Name, "doesn't have enough cash for", itemId)
		return false
	end

	-- Get current shop items to check availability
	local shopItems = ShopService.GetCurrentShopItems(player)
	if not shopItems then
		warn("[ItemShopService] Could not fetch shop items for player:", player.Name)
		return false
	end

	-- Check if item is available in current shop cycle
	local available = shopItems[itemId] or 0
	if available <= 0 then
		warn("[ItemShopService] Item", itemId, "not available in shop for", player.Name)
		return false
	end

	-- Deduct cash
	PlayerSessions.addPlayerCash(player, -itemConfig.Price)

	-- Add ingredient (quantity 1)
	IngredientService.AddIngredient(player, itemId, 1)

	-- Decrement shop item count
	local currentState = ShopService.getCurrentState()
	local currentSeed = tostring(currentState.seed)
	local newShopItems = table.clone(shopItems)
	newShopItems[itemId] = math.max(0, newShopItems[itemId] - 1)
	PlayerSessions.setShopCycle(player, currentSeed, newShopItems)

	print(string.format("[ItemShopService] %s purchased %s for %d", player.Name, itemId, itemConfig.Price))
	return true
end

function ItemShopService.initialize()
	-- Create BuyItem RemoteEvent
	local BuyItem = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	BuyItem.Name = "BuyItem"

	-- Handle purchase requests
	BuyItem.OnServerEvent:Connect(function(player, itemId)
		ItemShopService.BuyItem(player, itemId)
	end)
end

return ItemShopService
