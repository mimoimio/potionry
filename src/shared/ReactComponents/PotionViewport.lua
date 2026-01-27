local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useRef = React.useRef
local useEffect = React.useEffect
local useState = React.useState

local function PotionViewport(props: {
	PotionId: string?,
	DisplayName: string?,
	Size: UDim2?,
	Unlocked: boolean?,
	BackgroundTransparency: number?,
})
	local viewportRef = useRef(nil)
	local cameraRef = useRef(nil)
	local modelRef = useRef(nil)
	local modelFound, setModelFound = useState(true)
	local packageId, setPackageId = useState(nil)

	useEffect(function()
		if not props.PotionId then
			return
		end

		-- Get the potion model
		local potionModelsFolder = game.ReplicatedStorage.Shared.Models.Potions
		local potionModel = potionModelsFolder:FindFirstChild(props.PotionId)

		if potionModel then
			setModelFound(true)

			-- Check if model has a PackageLink
			local packageLink = potionModel:FindFirstChildOfClass("PackageLink")
			if packageLink then
				setPackageId(packageLink.PackageId)
				return -- No need to set up viewport
			else
				setPackageId(nil)
			end

			-- Normal viewport setup
			local viewport = viewportRef.current
			if not viewport then
				return
			end

			-- Create camera
			local camera = Instance.new("Camera")
			camera.Name = "ThumbnailCamera"
			camera.Parent = viewport
			viewport.CurrentCamera = camera
			cameraRef.current = camera

			local clone = potionModel:Clone()
			clone.Parent = viewport
			modelRef.current = clone
			camera.FieldOfView = 120

			local cf, size = clone:GetBoundingBox()
			local distance = 3
			camera.CFrame = CFrame.new(cf.Position + Vector3.new(1, 1, 5)) * CFrame.Angles(0, 0, 0)
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, cf.Position)

			-- Get bounding box and zoom camera to extent
			camera:ZoomToExtents(cf, size)
			camera.FieldOfView = 90
		else
			setModelFound(false)
			setPackageId(nil)
		end

		return function()
			if modelRef.current then
				modelRef.current:Destroy()
				modelRef.current = nil
			end
			if cameraRef.current then
				cameraRef.current:Destroy()
				cameraRef.current = nil
			end
		end
	end, { props.PotionId })

	-- If model not found, return TextLabel fallback
	if not modelFound then
		return e("TextLabel", {
			Size = props.Size or UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = props.BackgroundTransparency or 1,
			Text = props.DisplayName or props.PotionId or "Unknown",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.FredokaOne,
			TextSize = 14,
			TextWrapped = true,
			TextStrokeTransparency = 0,
		})
	end

	-- If model has PackageLink, use ImageLabel with thumbnail
	if packageId then
		-- Extract numeric ID from packageId (e.g., "rbxassetid://123" -> "123")
		local numericId = string.match(tostring(packageId), "%d+")
		return e("ImageLabel", {
			Size = props.Size or UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = props.BackgroundTransparency or 1,
			ImageTransparency = props.Unlocked and 0 or props.Unlocked == false and 0.8 or 0,
			Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId),
			ScaleType = Enum.ScaleType.Fit,
		}, {
			RateString = props.RateString and e("TextLabel", {
				Size = props.Size or UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = props.BackgroundTransparency or 1,
				Text = props.RateString or "",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextWrapped = true,
				TextStrokeTransparency = 0,
			}),
		})
	end

	-- No packageId - show ingredients as horizontal list
	local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
	local config = CraftingModule.CraftingLookup[props.PotionId]

	if config and config.Ingredients then
		local ingredientImages = {}

		for i, ingredientId in ipairs(config.Ingredients) do
			local ingredientModel = game.ReplicatedStorage.Shared.Models:FindFirstChild(ingredientId)

			if ingredientModel then
				local ingredientPackageLink = ingredientModel:FindFirstChildOfClass("PackageLink")

				if ingredientPackageLink then
					local numericId = string.match(tostring(ingredientPackageLink.PackageId), "%d+")

					ingredientImages["ingredient" .. i] = e("ImageLabel", {
						Size = UDim2.fromScale(0, 1),
						BackgroundTransparency = 1,
						Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId),
						ScaleType = Enum.ScaleType.Fit,
						LayoutOrder = i,
					})
				else
					-- warn("No ingredient packagelink", ingredientId)
				end
			else
				-- warn("No ingredient model", ingredientId)
			end
		end

		return e("Frame", {
			Size = props.Size or UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = props.BackgroundTransparency or 1,
		}, {
			RateString = props.RateString and e("TextLabel", {
				Size = UDim2.new(1, 0, 0.2, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = props.RateString or "",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextWrapped = true,
				TextStrokeTransparency = 0,
				ZIndex = 2,
			}),

			IngredientsContainer = e("Frame", {
				Size = UDim2.new(1, 0, props.RateString and 0.8 or 1, 0),
				Position = UDim2.new(0, 0, props.RateString and 0.2 or 0, 0),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					VerticalFlex = Enum.UIFlexAlignment.Fill,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Ingredients = e(React.Fragment, nil, ingredientImages),
			}),
		})
	else
		-- warn("No config")
	end

	-- Commented out ViewportFrame (might need later)
	-- return e("ViewportFrame", {
	-- 	Size = props.Size or UDim2.new(1, 0, 1, 0),
	-- 	BackgroundTransparency = props.BackgroundTransparency or 1,
	-- 	ref = viewportRef,
	-- 	LightDirection = Vector3.new(5, -1, 1),
	-- 	LightColor = Color3.new(1, 1, 1),
	-- 	Ambient = Color3.new(1, 1, 1),
	-- }, {
	-- 	RateString = props.RateString and e("TextLabel", {
	-- 		Size = props.Size or UDim2.new(1, 0, 1, 0),
	-- 		BackgroundTransparency = props.BackgroundTransparency or 1,
	-- 		Text = props.RateString or "",
	-- 		TextColor3 = Color3.new(1, 1, 1),
	-- 		Font = Enum.Font.FredokaOne,
	-- 		TextSize = 14,
	-- 		TextWrapped = true,
	-- 		TextStrokeTransparency = 0,
	-- 	}),
	-- })

	-- Fallback if no ingredients found
	return e("TextLabel", {
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Text = props.DisplayName or props.PotionId or "No Preview",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		TextSize = 14,
		TextWrapped = true,
		TextStrokeTransparency = 0,
	})
end

return PotionViewport
