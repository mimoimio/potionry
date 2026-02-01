local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Craft = require(game.ReplicatedStorage.Shared.ReactComponents.Craft)
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)

local function CraftStoryComponent()
	local craftOpen, setCraftOpen = useState(true)
	
	-- Initialize dummy data on mount
	useEffect(function()
		-- In edit mode, LocalPlayer doesn't exist, so create a mock player
		local player = game.Players.LocalPlayer
		if not player then
			-- Create a mock player object for edit mode
			player = {} :: any
			player.Name = "StoryPlayer"
			player.UserId = -1
		end
		
		-- Add dummy player data to PlayerSessions
		local dummyData = {
			Cash = 5000,
			Potions = {},
			PotionSlots = {},
			Cauldrons = {
				Cauldron1 = "none"
			},
			Collectors = {},
			Ingredients = {
				glowshroom = 10,
				fireblossom = 8,
				spiralaloe = 15,
				blinkroot = 5,
				waterleaf = 12,
			},
			ThrownPotions = {},
			PotionBook = {
				BasicPotion = true,
				HealthPotion = true,
			},
			ShopCycles = {},
			Multipliers = {},
			TutorialFinished = true,
		}
		
		-- Create a dummy plot
		local dummyPlot = Instance.new("Model")
		dummyPlot.Name = "DummyPlot"
		local cauldrons = Instance.new("Folder")
		cauldrons.Name = "Cauldrons"
		cauldrons.Parent = dummyPlot
		
		local cauldron1 = Instance.new("Folder")
		cauldron1.Name = "Cauldron1"
		cauldron1.Parent = cauldrons
		
		local cauldronModel = Instance.new("Part")
		cauldronModel.Name = "Cauldron"
		cauldronModel.Size = Vector3.new(4, 3, 4)
		cauldronModel.Position = Vector3.new(0, 3, 0)
		cauldronModel.Anchored = true
		cauldronModel.Parent = cauldron1
		
		dummyPlot.Parent = workspace
		
		-- Add player to state
		PlayerSessions.addPlayer(player, dummyData, dummyPlot)
		
		return function()
			-- Cleanup
			PlayerSessions.removePlayer(player)
			if dummyPlot then
				dummyPlot:Destroy()
			end
		end
	end, {})
	
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	}, {
		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "Craft Component Story",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.FredokaOne,
			TextSize = 24,
		}),
		ToggleButton = e("TextButton", {
			Text = craftOpen and "Close Craft UI" or "Open Craft UI",
			Size = UDim2.new(0, 200, 0, 60),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(56, 120, 90),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.FredokaOne,
			TextSize = 20,
			[React.Event.Activated] = function()
				setCraftOpen(not craftOpen)
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
		}),
		CraftUI = e(Craft, {
			CraftOpen = craftOpen,
			close = function()
				setCraftOpen(false)
			end,
			currentCauldron = "Cauldron1",
			PotionBook = {
				BasicPotion = true,
				HealthPotion = true,
			},
			tutorialHighlight = nil,
			PlayerData = {},
		}),
	})
end

function story(target: Frame)
	local root = ReactRoblox.createRoot(target)
	root:render(e(CraftStoryComponent))
	return function()
		root:unmount()
	end
end

return story
