local Reflex = require(game.ReplicatedStorage.Packages.Reflex)

export type TutorialRefsState = {
	shopButton: GuiObject?,
	baseButton: GuiObject?,
	daybloomCard: GuiObject?,
}

local initialState: TutorialRefsState = {
	shopButton = nil,
	baseButton = nil,
	daybloomCard = nil,
}

local producer = Reflex.createProducer(initialState, {
	setShopButton = function(state: TutorialRefsState, ref: GuiObject?)
		return {
			shopButton = ref,
			baseButton = state.baseButton,
			daybloomCard = state.daybloomCard,
		}
	end,
	setBaseButton = function(state: TutorialRefsState, ref: GuiObject?)
		return {
			shopButton = state.shopButton,
			baseButton = ref,
			daybloomCard = state.daybloomCard,
		}
	end,
	setDaybloomCard = function(state: TutorialRefsState, ref: GuiObject?)
		return {
			shopButton = state.shopButton,
			baseButton = state.baseButton,
			daybloomCard = ref,
		}
	end,
})

return producer
