local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function ThrowPanel(props: {
	Open: boolean,
	close: () -> (),
})
	if not props.Open then
		return nil
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Active = false,
		Position = UDim2.fromScale(0, 0),
		ZIndex = 50,
	}, {
		Container = e("Frame", {
			Size = UDim2.new(0, 400, 0, 200),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Active = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),

			-- Header = e("Frame", {
			-- 	Size = UDim2.new(1, 0, 0, 60),
			-- 	BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			-- 	BorderSizePixel = 0,
			-- 	BackgroundTransparency = 1,
			-- 	Active = false,
			-- }, {
			-- 	UICorner = e("UICorner", {
			-- 		CornerRadius = UDim.new(0, 12),
			-- 	}),

			-- 	Title = e("TextLabel", {
			-- 		Size = UDim2.new(1, -60, 1, 0),
			-- 		Position = UDim2.fromOffset(20, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "🎯 THROW POTION",
			-- 		TextColor3 = Color3.new(1, 1, 1),
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 24,
			-- 		TextXAlignment = Enum.TextXAlignment.Left,
			-- 	}),

			-- 	CloseButton = e("TextButton", {
			-- 		Size = UDim2.fromOffset(40, 40),
			-- 		Position = UDim2.new(1, -50, 0.5, -20),
			-- 		BackgroundTransparency = 1,
			-- 		Active = false,
			-- 		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
			-- 		Text = "X",
			-- 		TextColor3 = Color3.new(1, 1, 1),
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 20,
			-- 		[React.Event.Activated] = props.close,
			-- 	}, {
			-- 		UICorner = e("UICorner", {
			-- 			CornerRadius = UDim.new(0, 8),
			-- 		}),
			-- 	}),
			-- }),

			Instructions = props.Open and e("TextLabel", {
				Size = UDim2.new(1, -40, 1, -80),
				Position = UDim2.fromOffset(20, 70),
				Text = "Click anywhere to throw your potion!\n\nThe potion will fly toward your target.",
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.FredokaOne,
				TextSize = 16,
				BackgroundTransparency = 1,
				Active = false,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Top,
                ref = function(this)
                    if not this then
                        return
                    end
                    local TweenService = game:GetService("TweenService")
                    local tween = TweenService:Create(this, TweenInfo.new(5), { TextTransparency = 1 })
                    tween:Play()
                end
			}),
		}),
	})
end

return ThrowPanel
