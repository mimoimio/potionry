local PlotService: {
	Collections: { [Player]: Model },
	PlotLookup: { [Model]: Player },
} = {}
PlotService.Collections = {}
PlotService.PlotLookup = {}

function PlotService.GetPlot(player: Player)
	local plot = PlotService.Collections[player]
	if not plot then
		plot = PlotService.Assign(player)
	end
	return plot
end

function PlotService.Assign(player: Player): Model
	local plots = (workspace.Plots :: Folder):GetChildren()

	-- Randomize plot order for first assignment
	for i = #plots, 2, -1 do
		local j = math.random(i)
		plots[i], plots[j] = plots[j], plots[i]
	end

	-- warn("✨✨plots", plots)
	for i, plot: Model in plots do
		if PlotService.PlotLookup[plot] then
			continue
		end
		PlotService.Collections[player] = plot
		PlotService.PlotLookup[plot] = player
		task.spawn(function()
			local character = player.Character or player.CharacterAdded:Wait()
			character:PivotTo(plot:GetPivot() + Vector3.new(0, 5, 0))
		end)
		return plot
	end
	warn("ERROR NO PLOTS LEFT")
	return nil
end

function PlotService.ReturnPlot(player: Player)
	if not player then
		return
	end
	local plot = PlotService.Collections[player]
	PlotService.Collections[player] = nil
	if not plot then
		return
	end
	PlotService.PlotLookup[plot] = nil
end

function PlotService.initialize()
	if PlotService.isInitialized then
		return
	end

	-- Create RemoteFunction for getting player's plot
	local GetPlot = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
	GetPlot.Name = "GetPlot"
	GetPlot.OnServerInvoke = function(player: Player)
		return PlotService.GetPlot(player)
	end

	-- Create CompletionBoard SurfaceGui template
	local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)

	-- Create SurfaceGui
	local templateSurfaceGui = Instance.new("SurfaceGui")
	templateSurfaceGui.Name = "CompletionBoardUI"
	templateSurfaceGui.Face = Enum.NormalId.Front
	templateSurfaceGui.MaxDistance = 120
	templateSurfaceGui.ZOffset = 1
	templateSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	templateSurfaceGui.PixelsPerStud = 31

	-- Container Frame
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	-- container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = templateSurfaceGui

	-- Title TextLabel
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 60)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "UNLOCKED POTIONS"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Parent = container

	-- Grid Frame
	local grid = Instance.new("Frame")
	grid.Name = "PotionGrid"
	grid.Size = UDim2.new(1, -20, 1, -80)
	grid.Position = UDim2.new(0, 10, 0, 70)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Parent = container

	-- UIGridLayout
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 80, 0, 80)
	layout.CellPadding = UDim2.new(0, 10, 0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = grid

	-- Create potion frames
	for i, potion in ipairs(CraftingModule.CraftingTable) do
		local frame = Instance.new("Frame")
		frame.Name = potion.PotionId
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		frame.LayoutOrder = i
		frame.Parent = grid

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.1, 0)
		corner.Parent = frame

		-- Create ingredient images container
		local ingredientContainer = Instance.new("Frame")
		ingredientContainer.Name = "IngredientContainer"
		ingredientContainer.Size = UDim2.new(1, 0, 1, 0)
		ingredientContainer.BackgroundTransparency = 1
		ingredientContainer.Parent = frame

		local ingredientLayout = Instance.new("UIListLayout")
		ingredientLayout.FillDirection = Enum.FillDirection.Vertical
		ingredientLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ingredientLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ingredientLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ingredientLayout.Parent = ingredientContainer

		-- Check if potion model has PackageLink
		local potionModel = game.ReplicatedStorage.Shared.Models.Potions:FindFirstChild(potion.PotionId)
		local potionPackageLink = potionModel and potionModel:FindFirstChildOfClass("PackageLink")

		if potionPackageLink then
			-- Show potion thumbnail
			local numericId = string.match(tostring(potionPackageLink.PackageId), "%d+")
			if numericId then
				local thumbnailLabel = Instance.new("ImageLabel")
				thumbnailLabel.Name = "Thumbnail"
				thumbnailLabel.Size = UDim2.fromScale(1, 0.66)
				thumbnailLabel.BackgroundTransparency = 1
				thumbnailLabel.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
				thumbnailLabel.ScaleType = Enum.ScaleType.Fit
				thumbnailLabel.LayoutOrder = 1
				thumbnailLabel.Parent = ingredientContainer
			end
		end
	end

	-- Find all CompletionBoard parts using CollectionService
	local CollectionService = game:GetService("CollectionService")
	local completionBoards = CollectionService:GetTagged("CompletionBoard")

	-- Clone the template to each CompletionBoard
	for _, board in ipairs(completionBoards) do
		if board:IsA("BasePart") then
			local clone = templateSurfaceGui:Clone()
			clone.Adornee = board
			clone.Parent = board
		end
	end

	PlotService.isInitialized = true
	-- print("[PlotService] Initialized with CompletionBoard templates")
end
-- local cb = (workspace.Plots.Plot.CompletionBoard :: Model):GetPivot()
-- local min = math.huge
-- local max = 0
-- local t = game.Selection:Get()
-- for i, d: Model in t do
-- 	local distance = math.round((cb.Position - d:GetPivot().Position).Magnitude)
-- 	if distance <= min then
-- 		min = distance
-- 	end
-- 	if distance >= max then
-- 		max = distance
-- 	end
-- end
-- local range = max - min
-- for i = 1, #t, 1 do
-- 	t[i].Name = "Rack" .. i
-- 	local distance = math.round((cb.Position - t[i]:GetPivot().Position).Magnitude)
-- 	if distance <= min then
-- 		min = distance
-- 		t[i]:SetAttribute("Price", 0)
-- 		continue
-- 	end
-- 	local price = distance - min
-- 	t[i]:SetAttribute("Price", price ^ 3)
-- end

return PlotService
