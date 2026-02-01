local Reflex = require(game.ReplicatedStorage.Packages.Reflex)

export type ThrowPanelState = {
	equippedPotionUID: string?,
	panel: string,
}

local initialState: ThrowPanelState = {
	equippedPotionUID = "none",
	panel = "none",
}

local producer = Reflex.createProducer(initialState, {
	setEquippedPotion = function(state: ThrowPanelState, potionUID: string?)
		return {
			panel = state.panel,
			equippedPotionUID = potionUID,
		}
	end,
	setPanel = function(state: ThrowPanelState, panel: string)
		return {
			panel = panel,
			equippedPotionUID = state.equippedPotionUID,
		}
	end,
})

return producer
