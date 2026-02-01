local ShopState = require(script.Parent.ShopState)
local SpecialEventsConfig = require(game.ReplicatedStorage.Shared.Configs.SpecialEventsConfig)

local SpecialEventsState = {}

-- Event display names
SpecialEventsState.EVENT_NAMES = {
	copper = "Copper Event!",
	silver = "Silver Event!",
	gold = "Gold Event!",
	diamond = "Diamond Event!",
	strange = "Strange Event!",
	starlight = "Starlight Event!",
}

-- Event colors
SpecialEventsState.EVENT_COLORS = {
	none = Color3.fromRGB(255, 255, 255), -- White (default)
	copper = Color3.fromRGB(235, 160, 121), -- Copper/orange
	silver = Color3.fromRGB(220, 220, 240), -- Silver/grey-blue
	gold = Color3.fromRGB(255, 230, 120), -- Golden yellow
	diamond = Color3.fromRGB(200, 240, 255), -- Diamond cyan
	strange = Color3.fromRGB(200, 100, 255), -- Purple/magenta
	starlight = Color3.fromRGB(160, 160, 255), -- Deep blue
}

function SpecialEventsState.pickEventForSeed(seed: number): string
	-- Deterministic: same seed -> same event
	local candidates = {}
	for key, _ in pairs(SpecialEventsConfig) do
		if key ~= "none" then -- Exclude "none" from possible events
			table.insert(candidates, key)
		end
	end
	if #candidates == 0 then
		return "none"
	end
	local rng = Random.new(seed)
	local idx = rng:NextInteger(1, #candidates)
	return candidates[idx]
end

function SpecialEventsState.getCurrentEvent()
	local state = ShopState.getCurrentState()

	if state.isSpecial then
		return SpecialEventsState.pickEventForSeed(state.seed)
	else
		return "none"
	end
end

function SpecialEventsState.getEventName(eventId: string): string?
	return SpecialEventsState.EVENT_NAMES[eventId]
end

function SpecialEventsState.getEventColor(eventId: string): Color3
	return SpecialEventsState.EVENT_COLORS[eventId] or SpecialEventsState.EVENT_COLORS.none
end

return SpecialEventsState
