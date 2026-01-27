local Clock = require(game.ServerScriptService.Server.Services.Clock)
local ShopService = require(game.ServerScriptService.Server.Services.ShopService)
local SpecialEventsConfig = require(game.ReplicatedStorage.Shared.Configs.SpecialEventsConfig)
local SpecialEventsState = require(game.ReplicatedStorage.Shared.Utils.SpecialEventsState)
local self = {}
local SpecialEvents = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
SpecialEvents.Name = "SpecialEvents"
local GetSpecialEvents = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetSpecialEvents.Name = "GetSpecialEvents"

-- Use shared deterministic event picking
local pickEventForSeed = SpecialEventsState.pickEventForSeed
local eventColors = SpecialEventsState.EVENT_COLORS

local function applyEventState(seed: number, isSpecial: boolean)
	self.Events = self.Events or {}
	-- Clear existing events
	for k in pairs(self.Events) do
		self.Events[k] = nil
	end

	if isSpecial then
		local eventId = pickEventForSeed(seed)
		self.CurrentEvent = eventId
		self.Events[eventId] = true
	else
		self.CurrentEvent = "none"
	end

	-- Apply color tint based on event
	local colorCorrection = game.Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Parent = game.Lighting
	end

	colorCorrection.TintColor = eventColors[self.CurrentEvent] or eventColors.none

	SpecialEvents:FireAllClients(self.Events)
end

function self.initialize()
	if self.isInitialized then
		return
	end
	self.Events = {} :: { [string]: boolean }
	self.CurrentEvent = "none"

	GetSpecialEvents.OnServerInvoke = function()
		return self.Events
	end
	self.isInitialized = true
end

function self.start()
	self.initialize()

	-- Handle current state (covers "server starts during event")
	local currentstate = ShopService.getCurrentState()
	applyEventState(currentstate.seed, currentstate.isSpecial)

	-- React to future changes from Clock
	Clock.initialize()
	Clock.start()
	Clock.StartSpecialEvent:Connect(function(seed: number, isSpecial: boolean)
		applyEventState(seed, isSpecial)
	end)
end
function self:AddEvent(eventId: string)
	self.Events[eventId] = true
	SpecialEvents:FireAllClients(self.Events)
end
function self:RemoveEvent(eventId: string)
	self.Events[eventId] = nil
	SpecialEvents:FireAllClients(self.Events)
end

return self
