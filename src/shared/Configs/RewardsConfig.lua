-- Rewards configuration based on number of unlocked potions
-- Each milestone grants ingredient rewards when claimed

local RewardsConfig = {}

RewardsConfig.Milestones = {
	-- First tier (10-40)
	{ UnlocksRequired = 10, Rewards = { glowshroom = 1 } },
	{ UnlocksRequired = 20, Rewards = { glowshroom = 2 } },
	{ UnlocksRequired = 30, Rewards = { glowshroom = 3 } },
	{ UnlocksRequired = 40, Rewards = { glowshroom = 4 } },

	-- Second tier (50-80)
	{ UnlocksRequired = 50, Rewards = { spiralaloe = 1, glowshroom = 2 } },
	{ UnlocksRequired = 60, Rewards = { spiralaloe = 2, glowshroom = 2 } },
	{ UnlocksRequired = 70, Rewards = { spiralaloe = 3, bloodthorn = 1 } },
	{ UnlocksRequired = 80, Rewards = { spiralaloe = 4, bloodthorn = 1 } },

	-- Third tier (90-120)
	{ UnlocksRequired = 90, Rewards = { bloodthorn = 2, spiralaloe = 2 } },
	{ UnlocksRequired = 100, Rewards = { bloodthorn = 3, waterleaf = 1 } },
	{ UnlocksRequired = 110, Rewards = { bloodthorn = 4, waterleaf = 1 } },
	{ UnlocksRequired = 120, Rewards = { waterleaf = 2, bloodthorn = 2 } },

	-- Fourth tier (130-150)
	{ UnlocksRequired = 130, Rewards = { waterleaf = 3, fireblossom = 1 } },
	{ UnlocksRequired = 140, Rewards = { waterleaf = 4, fireblossom = 1 } },
	{ UnlocksRequired = 150, Rewards = { fireblossom = 2, waterleaf = 2, bloodthorn = 2 } },
}

-- Helper function to get total unlocked potions count
function RewardsConfig.GetUnlockedCount(potionBook: { [string]: boolean })
	local count = 0
	for potionId, unlocked in pairs(potionBook) do
		if unlocked then
			count = count + 1
		end
	end
	return count
end

-- Helper function to get claimable rewards based on current unlocks
function RewardsConfig.GetClaimableRewards(potionBook: { [string]: boolean }, claimedRewards: { [number]: boolean })
	local unlockedCount = RewardsConfig.GetUnlockedCount(potionBook)
	local claimable = {}

	for i, milestone in ipairs(RewardsConfig.Milestones) do
		if unlockedCount >= milestone.UnlocksRequired and not claimedRewards[i] then
			table.insert(claimable, i)
		end
	end

	return claimable
end

-- Helper function to check if there are any unclaimed rewards
function RewardsConfig.HasUnclaimedRewards(potionBook: { [string]: boolean }, claimedRewards: { [number]: boolean })
	local claimable = RewardsConfig.GetClaimableRewards(potionBook, claimedRewards)
	return #claimable > 0
end

return RewardsConfig
