export type PotionConfig = {
	PotionId: string,
	Price: number,
	Duration: number,
	Ingredients: { string },
}

export type PotionInstance = {
	UID: string,
	PotionId: string,
	VariationId: string,
	Size: number,
}
export type CauldronInstance = {
	PotionId: string?,
	StartTime: number?,
	VariationId: string?,
	Size: number?,
}

-- Initialize Tables and Lookup

local PotionConfigs: { PotionConfig } = {
	Table = {},
	Lookup = {},
}
return PotionConfigs
