-- Roulette system configuration with weighted ingredient rewards

local RouletteConfig = {}

-- Cooldown in seconds (4 hours)
RouletteConfig.COOLDOWN_SECONDS = 4 * 60 * 60 -- 14400 seconds

-- Weighted reward pool - higher weight = more likely to win
-- Total weight = sum of all weights, probability = weight / total
RouletteConfig.Rewards = {
	{ ItemId = "glowshroom", Amount = 6, Weight = 2, TierId = "epic" },
	{ ItemId = "spiralaloe", Amount = 3, Weight = 2, TierId = "epic" },
	{ ItemId = "bloodthorn", Amount = 1, Weight = 2, TierId = "epic" },
	{ ItemId = "bloodthorn", Amount = 3, Weight = 2, TierId = "epic" },
	{ ItemId = "waterleaf", Amount = 1, Weight = 2, TierId = "legendary" },
	{ ItemId = "fireblossom", Amount = 1, Weight = 1, TierId = "legendary" },
}

-- Calculate total weight for probability calculations
function RouletteConfig.GetTotalWeight()
	local total = 0
	for _, reward in ipairs(RouletteConfig.Rewards) do
		total = total + reward.Weight
	end
	return total
end

-- Select a random reward based on weights
function RouletteConfig.SelectRandomReward()
	local totalWeight = RouletteConfig.GetTotalWeight()
	local randomValue = math.random() * totalWeight

	local cumulativeWeight = 0
	for _, reward in ipairs(RouletteConfig.Rewards) do
		cumulativeWeight = cumulativeWeight + reward.Weight
		if randomValue <= cumulativeWeight then
			return reward
		end
	end

	-- Fallback (shouldn't happen)
	return RouletteConfig.Rewards[1]
end

-- Check if player can spin based on last spin time
function RouletteConfig.CanSpin(lastSpinTime: number?)
	if not lastSpinTime then
		return true, 0
	end

	local currentTime = workspace:GetServerTimeNow()
	local timeSinceLastSpin = currentTime - lastSpinTime

	if timeSinceLastSpin >= RouletteConfig.COOLDOWN_SECONDS then
		return true, 0
	else
		local timeRemaining = RouletteConfig.COOLDOWN_SECONDS - timeSinceLastSpin
		return false, timeRemaining
	end
end

-- Format time remaining into readable string
function RouletteConfig.FormatTimeRemaining(seconds: number)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

return RouletteConfig
