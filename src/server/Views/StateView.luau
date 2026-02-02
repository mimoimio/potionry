local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)

local StateView = {}

local function formatValue(value, indent)
	indent = indent or 0
	local indentStr = string.rep("  ", indent)

	if type(value) == "table" then
		local result = "{\n"
		for key, val in pairs(value) do
			local keyStr = tostring(key)
			if type(key) == "string" then
				keyStr = '"' .. key .. '"'
			end
			result = result .. string.rep("  ", indent + 1) .. keyStr .. " = "
			if type(val) == "table" then
				result = result .. formatValue(val, indent + 1)
			else
				result = result .. formatValue(val, 0)
			end
			result = result .. ",\n"
		end
		result = result .. indentStr .. "}"
		return result
	elseif type(value) == "string" then
		return '"' .. value .. '"'
	elseif type(value) == "number" then
		return tostring(value)
	elseif type(value) == "boolean" then
		return tostring(value)
	elseif typeof(value) == "Instance" then
		return "<Instance: " .. value:GetFullName() .. ">"
	else
		return tostring(value)
	end
end

function StateView.initialize()
	-- Create board in workspace
	local board = Instance.new("Part")
	board.Name = "StateViewBoard"
	board.Size = Vector3.new(20, 15, 0.5)
	board.Position = Vector3.new(0, 10, 0)
	board.Anchored = true
	board.CanCollide = false
	board.BrickColor = BrickColor.new("Dark stone grey")
	board.Parent = workspace

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "StateDisplay"
	surfaceGui.CanvasSize = Vector2.new(2000, 1500)
	surfaceGui.Parent = board

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "StateText"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	textLabel.BackgroundTransparency = 0.3
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.Code
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextWrapped = false
	textLabel.Text = "Waiting for state..."
	textLabel.Parent = surfaceGui

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.fromScale(1, 1)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.CanvasSize = UDim2.fromOffset(2000, 5000)
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.Parent = surfaceGui

	textLabel.Parent = scrollFrame
	textLabel.AutomaticSize = Enum.AutomaticSize.XY

	-- Subscribe to PlayerSessions state
	local function updateDisplay()
		local state = PlayerSessions:getState()
		local formattedState = "PlayerSessions State:\n" .. formatValue(state, 0)
		textLabel.Text = formattedState

		-- Update canvas size based on text bounds
		scrollFrame.CanvasSize =
			UDim2.fromOffset(math.max(2000, textLabel.TextBounds.X + 20), math.max(1500, textLabel.TextBounds.Y + 20))
	end

	-- Initial update
	updateDisplay()

	-- Subscribe to changes
	PlayerSessions:subscribe(function(state)
		updateDisplay()
	end)

	print("[StateView] Initialized - Board created in workspace")
end

return StateView
