-- Shared utility for calculating player multipliers
local MultiplierHelper = {}

function MultiplierHelper.GetFinalMultiplier(multipliers)
	local totalBonus = 0
	local now = workspace:GetServerTimeNow()

	for multiplierId, multiplier in pairs(multipliers or {}) do
		-- Skip expired multipliers
		if multiplier.Expire == -1 or now < multiplier.Expire then
			totalBonus += multiplier.Value
		end
	end

	-- Return final multiplier (1 + bonus percentage)
	-- Example: 0.5 bonus = 1.5x total, 1.0 bonus = 2x total
	return 1 + totalBonus
end

return MultiplierHelper
