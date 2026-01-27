local SpecialEventsConfig = {
	-- Default weights (No active event)
	-- Bigger number = More common (normal weight)
	none = {
		none = 1500,
		copper = 250,
		silver = 140,
		gold = 80,
		diamond = 50,
		strange = 10,
	},

	-- Copper Event: Copper is more common
	copper = {
		none = 1500,
		copper = 600,
		silver = 140,
		gold = 80,
		diamond = 50,
		strange = 10,
	},

	-- Silver Event: Silver is more common
	silver = {
		none = 1500,
		copper = 250,
		silver = 580,
		gold = 80,
		diamond = 50,
		strange = 10,
	},

	-- Gold Event: Gold is more common
	gold = {
		none = 1500,
		copper = 250,
		silver = 140,
		gold = 550,
		diamond = 50,
		strange = 10,
	},

	-- Diamond Event: Diamond is more common
	diamond = {
		none = 1500,
		copper = 250,
		silver = 140,
		gold = 80,
		diamond = 520,
		strange = 10,
	},

	-- Starlight Event (Night time)
	starlight = {
		none = 1500,
		copper = 250,
		silver = 140,
		gold = 80,
		diamond = 50,
		strange = 10,
		starlight = 600,
	},
}

return SpecialEventsConfig
