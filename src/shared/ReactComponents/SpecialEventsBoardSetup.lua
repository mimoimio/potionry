local SpecialEventsConfig = require(game.ReplicatedStorage.Shared.Configs.SpecialEventsConfig)

local eventColors = {
	none = Color3.fromRGB(255, 255, 255), -- White (default)
	copper = Color3.fromRGB(255, 140, 80), -- Copper/orange
	silver = Color3.fromRGB(220, 220, 240), -- Silver/grey-blue
	gold = Color3.fromRGB(255, 230, 120), -- Golden yellow
	diamond = Color3.fromRGB(120, 240, 255), -- Diamond cyan
	strange = Color3.fromRGB(200, 100, 255), -- Purple/magenta
	starlight = Color3.fromRGB(160, 160, 255), -- Deep blue
}
local order = {
	none = 1,
	copper = 2,
	silver = 3,
	gold = 4,
	diamond = 5,
	strange = 6,
	starlight = 7,
}

local function calculatePercentage(weight: number, totalWeight: number): string
	return string.format("%.1f%%", (weight / totalWeight) * 100)
end

local function setupBoard(model: Model, eventName: string, eventConfig: { [string]: number })
	local board = model:FindFirstChild("Board") :: Part
	if not board then
		warn("Board part not found in model")
		return
	end

	local surfaceGui = board:FindFirstChild("SurfaceGui") :: SurfaceGui
	if not surfaceGui then
		warn("SurfaceGui not found in Board")
		return
	end

	-- Clear existing children
	-- for _, child in surfaceGui:GetChildren() do
	-- 	child:Destroy()
	-- end

	-- Create UIListLayout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = surfaceGui
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	-- Create title label for the event
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Parent = surfaceGui
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.BackgroundTransparency = 0.5
	titleLabel.BackgroundColor3 =
		Color3.new(eventColors[eventName].R ^ 2, eventColors[eventName].G ^ 2, eventColors[eventName].B ^ 2)
	titleLabel.Text = eventName == "none" and "NORMAL CHANCES" or string.upper(eventName) .. " EVENT"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.LayoutOrder = 0

	-- Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(eventConfig) do
		totalWeight += weight
	end

	-- Create labels for each variation
	local layoutOrder = 1
	for variationName, weight in pairs(eventConfig) do
		local label = Instance.new("TextLabel")
		label.Name = variationName .. "Label"
		label.Parent = surfaceGui
		label.Size = UDim2.new(1, 0, 0, 80)
		label.BackgroundTransparency = 0.7
		label.BackgroundColor3 = variationName == eventName and eventColors[variationName] or Color3.fromRGB(50, 50, 50)
		label.Text = string.format(
			"%s: %s",
			variationName,
			-- weight,
			-- totalWeight,
			calculatePercentage(weight, totalWeight)
		)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.LayoutOrder = order[variationName]
		surfaceGui.UIPadding:Clone().Parent = label
	end
end

local function initialize()
	local templateModel = workspace:FindFirstChild("SpecialEventsBoard") :: Model
	if not templateModel then
		warn("SpecialEventsBoard template not found in workspace")
		return
	end

	-- Create a folder to hold all the boards
	local boardsFolder = workspace:FindFirstChild("SpecialEventsBoards")
	if not boardsFolder then
		boardsFolder = Instance.new("Folder")
		boardsFolder.Name = "SpecialEventsBoards"
		boardsFolder.Parent = workspace
	end

	-- Clear existing boards
	for _, child in boardsFolder:GetChildren() do
		child:Destroy()
	end

	-- Clone and setup a board for each event
	local index = 0
	for eventName, eventConfig in pairs(SpecialEventsConfig) do
		local clonedModel = templateModel:Clone()
		clonedModel.Name = eventName .. "EventBoard"
		clonedModel.Parent = boardsFolder

		-- Position the boards in a line (adjust spacing as needed)
		local part = workspace:FindFirstChild(eventName .. "part")
		clonedModel:PivotTo(
			part and part:GetPivot() or CFrame.new(index * 20, 5, 0) -- Adjust spacing here
		)

		setupBoard(clonedModel, eventName, eventConfig)
		index += 1
	end

	-- Optionally hide the template
	templateModel.Parent = game.ServerStorage
end

return {
	initialize = initialize,
}
