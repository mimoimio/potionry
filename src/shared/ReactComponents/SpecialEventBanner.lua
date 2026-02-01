local React = require(game.ReplicatedStorage.Packages.React)
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local START_POSITION = UDim2.new(1, 320, 0, 10) -- Off-screen to the right
local NORMAL_POSITION = UDim2.new(1, -10, 0, 40) -- Visible at top right
local END_POSITION = UDim2.new(1, 320, 0, 10) -- Back off-screen

local function SpecialEventBanner(props: {
	eventName: string,
	eventColor: Color3,
	onAnimationComplete: (() -> nil)?,
})
	local rootRef = React.useRef()
	local frameRef = React.useRef()
	local textRef = React.useRef()
	local imageRef = React.useRef()
	local closingRef = React.useRef(false)

	local function startClose()
		task.spawn(function()
			if closingRef.current then
				return
			end
			closingRef.current = true

			local closeTime = 2
			if frameRef.current then
				TweenService:Create(
					frameRef.current,
					TweenInfo.new(closeTime, Enum.EasingStyle.Back, Enum.EasingDirection.In),
					{ BackgroundTransparency = 1 }
				):Play()
			end
			if rootRef.current then
				TweenService:Create(
					rootRef.current,
					TweenInfo.new(closeTime, Enum.EasingStyle.Back, Enum.EasingDirection.In),
					{ Position = END_POSITION }
				):Play()
			end
			if textRef.current then
				TweenService:Create(
					textRef.current,
					TweenInfo.new(closeTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
					{ TextTransparency = 1 }
				):Play()
			end
			if imageRef.current then
				TweenService:Create(
					imageRef.current,
					TweenInfo.new(closeTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
					{ ImageTransparency = 1 }
				):Play()
			end

			task.delay(closeTime, function()
				if props.onAnimationComplete then
					props.onAnimationComplete()
				end
			end)
		end)
	end

	React.useEffect(function()
		task.spawn(function()
			-- Opening animation
			local openTime = 0.6
			if frameRef.current then
				TweenService:Create(
					frameRef.current,
					TweenInfo.new(openTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 0.5 }
				):Play()
			end
			if rootRef.current then
				TweenService:Create(
					rootRef.current,
					TweenInfo.new(openTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Position = NORMAL_POSITION }
				):Play()
			end
			if textRef.current then
				TweenService:Create(
					textRef.current,
					TweenInfo.new(openTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()
			end
			if imageRef.current then
				TweenService:Create(
					imageRef.current,
					TweenInfo.new(openTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					{ ImageTransparency = 0.5 } -- Stays transparent (placeholder)
				):Play()
			end
		end)
	end, {})

	-- Expose startClose for parent to trigger
	React.useEffect(function()
		task.spawn(function()
			if props.onMount then
				props.onMount(startClose)
			end
		end)
	end, {})

	return React.createElement("Frame", {
		ref = rootRef,
		Size = UDim2.new(0, 0, 0, 100),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Position = START_POSITION,
	}, {
		Banner = React.createElement("Frame", {
			ref = frameRef,
			Size = UDim2.new(0, 300, 0, 100),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = props.eventColor,
			BorderSizePixel = 0,
			Active = false,
			[React.Event.InputBegan] = function(this, io: InputObject)
				if
					io.UserInputType == Enum.UserInputType.MouseButton1
					or io.UserInputType == Enum.UserInputType.Touch
				then
					if rootRef.current then
						SoundController.Sound("Ping")
						-- Nudge rotation animation
						local nudgeTween = TweenService:Create(
							rootRef.current,
							TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
							{ Rotation = (math.round(math.random()) - 0.5) * 5 }
						)
						local reset = TweenService:Create(
							rootRef.current,
							TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0),
							{ Rotation = 0 }
						)

						task.delay(0.05, function()
							reset:Play()
						end)

						nudgeTween:Play()
					end
				end
			end,
		}, {
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),

			ImagePlaceholder = React.createElement("ImageLabel", {
				Active = false,
				ref = imageRef,
				Size = UDim2.new(0, 120, 0, 120),
				Position = UDim2.new(0, -5, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				ImageTransparency = 1, -- Placeholder, stays transparent
				Image = (function()
					local IconPart = ReplicatedStorage.Shared.Icons:FindFirstChild(props.eventId)
					local bbgui = IconPart and IconPart:FindFirstChild("BillboardGui")
					local ImageLabel = bbgui and bbgui:FindFirstChild("ImageLabel")
					local Image = ImageLabel and ImageLabel.Image
					return Image or ""
				end)(), -- Empty for now
				ImageColor3 = props.eventColor or Color3.new(1, 1, 1),
				ZIndex = 21,
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),

			EventText = React.createElement("TextLabel", {
				ref = textRef,
				Size = UDim2.new(1, -55, 1, -10),
				Position = UDim2.new(0, 50, 0, 5),
				BackgroundTransparency = 1,
				Text = props.eventName,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Active = false,
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextSize = 18,
				Font = Enum.Font.FredokaOne,
				TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 21,
			}),
		}),
	})
end

return SpecialEventBanner
