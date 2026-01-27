export type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "" | "Copper" | "Silver" | "Gold" | "Diamond",
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}

local VariationsConfig = {
	none = {
		VariationId = "none",
		DisplayName = "None",
		Multiplier = 1,
		ColorPrimary = Color3.new(0, 0, 0),
		Weight = 1,
	},
	copper = {
		VariationId = "copper",
		DisplayName = "Copper",
		Multiplier = 2,
		ColorPrimary = Color3.new(0.639215, 0.388235, 0.388235),
		Weight = 100,
	},
	silver = {
		VariationId = "silver",
		DisplayName = "Silver",
		Multiplier = 3,
		ColorPrimary = Color3.new(0.349019, 0.552941, 0.588235),
		Weight = 200,
	},
	gold = {
		VariationId = "gold",
		DisplayName = "Gold",
		Multiplier = 5,
		ColorPrimary = Color3.new(0.827450, 0.894117, 0.239215),
		Weight = 500,
	},
	diamond = {
		VariationId = "diamond",
		DisplayName = "Diamond",
		Multiplier = 8,
		ColorPrimary = Color3.new(0.015686, 0.592156, 0.858823),
		Weight = 800,
	},
	starlight = {
		VariationId = "starlight",
		DisplayName = "Starlight",
		Multiplier = 6,
		ColorPrimary = Color3.new(0.549019, 0.152941, 1),
		Weight = 200,
	},
	strange = {
		VariationId = "strange",
		DisplayName = "Strange",
		Multiplier = 13,
		ColorPrimary = Color3.new(0.952941, 0.305882, 0.192156),
		Weight = 1500,
	},
}

return VariationsConfig
