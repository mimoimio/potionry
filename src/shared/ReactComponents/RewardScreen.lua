local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
local e = React.createElement

return function(props)
	local open = props.Open
	local potionId = props.PotionId
	local onClose = props.close

	if not open or not potionId then
		return nil
	end

	local recipe = CraftingModule.CraftingLookup[potionId]
	local ingredients = recipe and recipe.Ingredients or {}

	React.useEffect(function()
		local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
		SoundController.Sound("TaDa")
	end, {})
	local playerGui = game.Players.LocalPlayer.PlayerGui

	local content = e("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
		IgnoreGuiInset = true,
	}, {
		e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.4,
			ZIndex = 200,
		}, {
			CloseButton = e("TextButton", {
				Text = "",
				Size = UDim2.new(1, 0, 1, 0),
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(3, 39, 58),
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
				Font = Enum.Font.FredokaOne,
				TextSize = 18,
				ZIndex = 203,
				[React.Event.InputBegan] = function(button: TextButton, io: InputObject, gp)
					if
						io.UserInputType == Enum.UserInputType.MouseButton1
						or io.UserInputType == Enum.UserInputType.Touch
					then
						button.Parent.Visible = false
						if onClose then
							onClose()
						end
					end
				end,
			}, {

				Container = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(420, 260),
					BackgroundTransparency = 1,
					ZIndex = 201,
				}, {
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						VerticalFlex = Enum.UIFlexAlignment.Fill,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Title = e("TextLabel", {
						Text = "New Recipe Discovered! Multipliers increased by 5%!",
						Size = UDim2.new(0, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.XY,
						BackgroundTransparency = 1,
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						LayoutOrder = 1,
						TextSize = 24,
					}),
					PotionName = e("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.XY,
						Text = tostring(props.DisplayName),
						Size = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(170, 255, 120),
						Font = Enum.Font.FredokaOne,
						TextScaled = true,
						ZIndex = 202,
						LayoutOrder = 2,
					}),
					PotionViewport = e(require(script.Parent.PotionViewport), {
						AutomaticSize = Enum.AutomaticSize.XY,
						PotionId = props.PotionId,
						DisplayName = "",
						Size = UDim2.new(1, 0, 1, 0),
						Unlocked = true,
						LayoutOrder = 3,
						BackgroundTransparency = 1,
					}),
				}),
			}),
		}),
	})

	return ReactRoblox.createPortal(content, playerGui)
end
