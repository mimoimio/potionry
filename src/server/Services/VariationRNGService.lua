local Clock = require(game.ServerScriptService.Server.Services.Clock)
local SpecialEventsService = require(game.ServerScriptService.Server.Services.SpecialEventsService)
local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local SpecialEventsConfig = require(game.ReplicatedStorage.Shared.Configs.SpecialEventsConfig)
type VariationConfig = VariationsConfig.VariationsConfig
type VariationId = string

local VariationRNGService = {}

function VariationRNGService.initialize()
	if VariationRNGService.isInitialized then
		return
	end
	VariationRNGService.isInitialized = true
end

function VariationRNGService:roll(): VariationConfig
	-- Determine active event
	local activeEvent = SpecialEventsService.CurrentEvent or "none"
	local weightsTable = SpecialEventsConfig[activeEvent] or SpecialEventsConfig.none

	-- Build weights table from all available variations
	local weights = {}
	local totalWeight = 0

	for varId, weightVal in pairs(weightsTable) do
		local weight = weightVal or 1
		-- Normal weight: higher weight = more common
		weights[varId] = weight
		totalWeight += weight
	end

	-- Weighted random selection
	local rand = math.random() * totalWeight
	local cumulative = 0

	for varId, weight in pairs(weights) do
		cumulative += weight
		if rand <= cumulative then
			local varcfg = VariationsConfig[varId]
			return varcfg
		end
	end

	-- Fallback
	return VariationsConfig["none"]
end

return VariationRNGService
