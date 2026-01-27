local ClockController = {}

function ClockController.initialize()
	shared.ClockController = ClockController
end

function ClockController.GetFormattedTime()
	local clockTime = game.Lighting.ClockTime
	local hours = math.floor(clockTime)
	local minutes = math.floor((clockTime - hours) * 60)

	-- 12-hour format with AM/PM
	local period = hours >= 12 and "PM" or "AM"
	local displayHours = hours % 12
	if displayHours == 0 then
		displayHours = 12
	end

	return string.format("%d:%02d %s", displayHours, minutes, period)
end

return ClockController
