local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped
local peek = Fusion.peek
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local r = Random.new()

-- 1. UPDATE SCOPE: Add Computed and Spring here so we can use them
local scope = scoped({
	New = Fusion.New,
	Value = Fusion.Value,
	Computed = Fusion.Computed,
	Spring = Fusion.Spring,
})

local TextButton = function(props)
	-- 2. LOCAL STATE: Define state inside the function so every button is independent
	local counter = scope:Value(2)
	local isHovering = scope:Value(false)
	local rotationTarget = scope:Value(0)
	local currentRotation = scope:Spring(rotationTarget, 50, 0.4)
	local currentSize = scope:Spring(
		scope:Computed(function(use, action)
			if use(isHovering) then
				return UDim2.new(0, 220, 0, 70) -- Hover Size
			else
				return UDim2.new(0, 200, 0, 50) -- Normal Size
			end
		end),
		25,
		1
	)

	return scope:New("ImageButton")({
		-- Bind the Spring to the Size property
		Size = (currentSize or UDim2.new(0, 200, 0, 50)),
		Parent = props.Parent,
		Rotation = currentRotation,
		BackgroundTransparency = 1,
		Image = "rbxassetid://81158784458537",
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),

		[OnEvent("Activated")] = function(...)
			counter:set(peek(counter) + 1)
			ReplicatedStorage.Shared.Events:WaitForChild("Click"):FireServer()
			rotationTarget:set((r:NextInteger(0, 1) - 0.5) * 2 * r:NextInteger(1, 5))
			task.delay(0.05, function()
				rotationTarget:set(0)
			end)
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://110253665387820"
			sound.Parent = workspace
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end
			sound:Play()
			sound.Ended:Wait()
			sound:Destroy()
		end,

		-- 4. UPDATE STATE ON EVENTS
		[OnEvent("MouseEnter")] = function()
			isHovering:set(true)
		end,

		[OnEvent("MouseLeave")] = function()
			isHovering:set(false)
		end,

		[Children] = {
			scope:New("TextLabel")({
				Text = counter,
				Font = "FredokaOne",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 24,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}),
		},
	})
end

return TextButton
