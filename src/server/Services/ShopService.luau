local ShopService = {}
local ShopState = require(game.ReplicatedStorage.Shared.Utils.ShopState)

-- Use shared config
ShopService.SMALL_CYCLE_DURATION = ShopState.SMALL_CYCLE_DURATION
ShopService.CYCLES_PER_BIG_CYCLE = ShopState.CYCLES_PER_BIG_CYCLE

function ShopService.getCurrentState()
	return ShopState.getCurrentState()
end

function ShopService.generateItems()
	local state = ShopService.getCurrentState()

	-- Shop Logic
	local TierRNGService = require(game.ServerScriptService.Server.Services.TierRNGService)
	local shopItems = TierRNGService.getShopItems(state.seed)
	warn("creating shopItems",shopItems)

	return shopItems
end

local GetShopItems = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetShopItems.Name = "GetShopItems"

local ShopRefreshed = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ShopRefreshed.Name = "ShopRefreshed"
function ShopService.GetCurrentShopItems(player:Player)
	-- local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
	-- local session = PlayerDataService:GetSession(player)
	local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
	local state = PlayerSessions:getState()
	local session = state.players[player]
	if not session then
		return nil
	end
	local currentState = ShopService.getCurrentState()
	local currentSeed = currentState.seed
	local shopCycles = session.Data.ShopCycles
	local shopitems = shopCycles[tostring(currentSeed)]

	warn(shopCycles)
	-- if not shop items then generate new
	if not shopitems then
		shopitems = ShopService.generateItems()
		warn("no current items. Get new.",currentSeed, shopitems)
		PlayerSessions.setShopCycle(player, tostring(currentSeed), shopitems)
	end
	return shopitems
end
function ShopService.initialize()
	GetShopItems.OnServerInvoke = ShopService.GetCurrentShopItems
end

function ShopService.notifyRefresh()
	ShopRefreshed:FireAllClients()
end

return ShopService
