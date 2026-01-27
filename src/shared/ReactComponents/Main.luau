local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
local MultiplierHelper = require(game.ReplicatedStorage.Shared.Utils.MultiplierHelper)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Mionum = require(game.ReplicatedStorage.Packages.Mionum)
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState
local useToast = require(script.Parent.Toasts).useToast
local RewardScreen = require(script.Parent.RewardScreen)

local function Main(props)
	local toast = useToast()
	local activePanel, setActivePanel = React.useState("none")
	local currentCauldron, setCurrentCauldron = React.useState(nil)
	local playerData, setPlayerData = React.useState(nil)
	local currentTime, setCurrentTime = React.useState("12:00 AM")
	local InventoryOpen = activePanel == "inventory"
	local RemovePotionOpen = activePanel == "removepotion"
	local rewardQueue, setRewardQueue = useState({})
	local CraftOpen = activePanel == "craft"
	local SellOpen = activePanel == "sell"
	local previousPotionBookKeys = useRef({})

	local function toggle(panel)
		setActivePanel(function(prev)
			if prev == panel then
				return "none"
			else
				return panel
			end
		end)
	end

	-- Subscribe to Reflex state for player data
	useEffect(function()
		local player = game.Players.LocalPlayer

		local unsubscribe = PlayerSessions:subscribe(function(state)
			local playerEntity = state.players[player]
			if playerEntity and playerEntity.Data then
				setPlayerData(playerEntity.Data)
			end
		end)

		-- Initial state
		local state = PlayerSessions:getState()
		local playerEntity = state.players[player]
		if playerEntity and playerEntity.Data then
			setPlayerData(playerEntity.Data)
		end

		return function()
			unsubscribe()
		end
	end, {})

	-- Listen for new PotionBook entries and add to reward queue
	useEffect(function()
		if not playerData or not playerData.PotionBook then
			return
		end

		local currentKeys = {}
		for potionId, _ in pairs(playerData.PotionBook) do
			currentKeys[potionId] = true
		end

		-- Check for new keys
		local previousKeys = previousPotionBookKeys.current

		-- Check if this is the first run (no previous keys tracked)
		local isFirstRun = next(previousKeys) == nil

		if not isFirstRun then
			for potionId, _ in pairs(currentKeys) do
				if not previousKeys[potionId] then
					-- New potion discovered!
					local potionData = CraftingModule.CraftingLookup[potionId]
					if potionData then
						setRewardQueue(function(queue)
							local newQueue = table.clone(queue)
							table.insert(newQueue, {
								PotionId = potionId,
								DisplayName = potionData.DisplayName or potionId,
							})
							return newQueue
						end)
					end
				end
			end
		end

		-- Update ref for next comparison
		previousPotionBookKeys.current = currentKeys
	end, { playerData and playerData.PotionBook })

	useEffect(function()
		UserInputService.InputBegan:Connect(function(io, gp)
			if gp then
				return
			end
			if io.KeyCode == Enum.KeyCode.E then
				toggle("inventory")
			elseif io.KeyCode == Enum.KeyCode.G then
				game.Players.LocalPlayer.Character:PivotTo(workspace.Shops.June:GetPivot())
			elseif io.KeyCode == Enum.KeyCode.B then
				PlayerSessions:getState(function(state: PlayerSessions.PlayersState)
					local session = state.players[game.Players.LocalPlayer]
					if not (session and session.Plot) then
						return
					end
					game.Players.LocalPlayer.Character:PivotTo(session.Plot:GetPivot())
				end)
			elseif io.KeyCode == Enum.KeyCode.R then
				toggle("removepotion")
			end
		end)
		task.spawn(function()
			workspace:WaitForChild("Shops"):WaitForChild("June"):WaitForChild("june").Triggered:Connect(function()
				toggle("shop")
			end)
			workspace:WaitForChild("Shops"):WaitForChild("Mitch"):WaitForChild("mitch").Triggered:Connect(function()
				toggle("sell")
			end)
		end)
	end, {})

	-- Update clock display every second
	useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				if shared.ClockController then
					setCurrentTime(shared.ClockController.GetFormattedTime())
				end
				task.wait(1)
			end
		end)

		return function()
			running = false
		end
	end, {})

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 1,
	}, {
		TopBar = e("Frame", {
			Size = UDim2.new(0, 200, 0, 50),
			Position = UDim2.new(0.5, -100, 0, 10),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderSizePixel = 0,
			ZIndex = 10,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			BaseButton = e("TextButton", {
				Size = UDim2.new(0.48, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				Text = "Base",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				ZIndex = 11,
				[React.Event.Activated] = function()
					PlayerSessions:getState(function(state: PlayerSessions.PlayersState)
						local session = state.players[game.Players.LocalPlayer]
						if not (session and session.Plot) then
							toast({
								title = "No Plot",
								description = "You don't have a plot yet!",
								status = "error",
							})
							return
						end
						game.Players.LocalPlayer.Character:PivotTo(session.Plot:GetPivot())
					end)
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
			Divider = e("Frame", {
				Size = UDim2.new(0, 2, 0.6, 0),
				Position = UDim2.new(0.5, -1, 0.2, 0),
				BackgroundColor3 = Color3.fromRGB(80, 80, 80),
				BorderSizePixel = 0,
				ZIndex = 11,
			}),
			ShopButton = e("TextButton", {
				Size = UDim2.new(0.48, 0, 1, 0),
				Position = UDim2.new(0.52, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				Text = "Shop",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				ZIndex = 11,
				[React.Event.Activated] = function()
					game.Players.LocalPlayer.Character:PivotTo(workspace.Shops.June:GetPivot())
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
			NothingButton = e(function(nb_props)
				local multext = ("Multiplier: %.2fx"):format(
					MultiplierHelper.GetFinalMultiplier(nb_props.PlayerData and nb_props.PlayerData.Multipliers)
				)

				return e("TextButton", {
					Size = UDim2.new(0, 200, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(60, 60, 60),
					BorderSizePixel = 0,
					Text = multext,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
					Font = Enum.Font.GothamBold,
					ZIndex = 11,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				})
			end, {
				PlayerData = playerData,
			}),
			TimeDisplay = e("TextLabel", {
				Size = UDim2.new(0, 120, 0, 40),
				Position = UDim2.new(0, -130, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				BorderSizePixel = 0,
				Text = currentTime,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				ZIndex = 11,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),
		ResetButton = e("TextButton", {
			Size = UDim2.new(0, 120, 0, 40),
			Position = UDim2.new(0.5, -60, 0, 70),
			BackgroundColor3 = Color3.fromRGB(180, 50, 50),
			BorderSizePixel = 0,
			Text = "Reset Data",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			ZIndex = 10,
			[React.Event.Activated] = function()
				local ResetData = game.ReplicatedStorage.Shared.Events:FindFirstChild("ResetData")
				if ResetData then
					ResetData:FireServer()
					toast.open("reset")
				end
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}),
		Inventory = e(require(script.Parent.Inventory), {
			InventoryOpen = InventoryOpen,
			close = function()
				toggle("none")
			end,
			toggle = toggle,
		}),
		RemovePotion = e(require(script.Parent.RemovePotionTool), {
			enabled = RemovePotionOpen,
			toggle = toggle,
		}),
		Craft = playerData and e(require(script.Parent.Craft), {
			CraftOpen = CraftOpen,
			close = function()
				toggle("none")
			end,
			currentCauldron = currentCauldron,
			PotionBook = playerData.PotionBook or {},
		}),
		Cauldron = e(require(script.Parent.Cauldron), {
			PlayerData = playerData,
			setCurrentCauldron = function(cauldronId)
				setCurrentCauldron(cauldronId)
				setActivePanel("craft")
			end,
		}),
		Tutorial = e(require(script.Parent.Tutorial), {
			PlayerData = playerData,
			activePanel = activePanel,
			onHighlightChange = function() end,
		}),
		ItemShopComponent = e(require(script.Parent.ItemShop), {
			Open = activePanel == "shop",
			close = function()
				toggle("none")
			end,
			PlayerData = playerData,
		}),
		Sell = playerData and e(require(script.Parent.Sell), {
			Open = SellOpen,
			close = function()
				toggle("none")
			end,
			PlayerData = playerData,
		}),
		CollectorDisplays = e(require(script.Parent.CollectorDisplays)),
		Reward = e(RewardScreen, {
			Open = rewardQueue and #rewardQueue > 0,
			PotionId = rewardQueue and rewardQueue[1] and rewardQueue[1].PotionId,
			DisplayName = rewardQueue and rewardQueue[1] and rewardQueue[1].DisplayName,
			close = function()
				setRewardQueue(function(q)
					local nextQ = table.clone(q or {})
					if #nextQ > 0 then
						table.remove(nextQ, 1)
					end
					return nextQ
				end)
			end,
		}),
	})
end

return Main
