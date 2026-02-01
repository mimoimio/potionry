local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
local MultiplierHelper = require(game.ReplicatedStorage.Shared.Utils.MultiplierHelper)
local SpecialEventsState = require(game.ReplicatedStorage.Shared.Utils.SpecialEventsState)
local ShopState = require(game.ReplicatedStorage.Shared.Utils.ShopState)
local TutorialRefs = require(game.ReplicatedStorage.Shared.producers.TutorialRefs)
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
local SpecialEventBanner = require(script.Parent.SpecialEventBanner)
local ThrowPanel = require(script.Parent.ThrowPanel)
local ThrowPanelProducer = require(game.ReplicatedStorage.Shared.producers.ThrowPanel)

local function Main(props)
	local toast = useToast()
	local activePanel, setActivePanel = React.useState("none")
	local currentCauldron, setCurrentCauldron = React.useState(nil)
	local playerData, setPlayerData = React.useState(nil)
	local currentTime, setCurrentTime = React.useState("12:00 AM")
	local currentSeed, setCurrentSeed = React.useState(nil)
	local InventoryOpen = activePanel == "inventory"
	local RemovePotionOpen = activePanel == "removepotion"
	local rewardQueue, setRewardQueue = useState({})
	local CraftOpen = activePanel == "craft"
	local SellOpen = activePanel == "sell"
	local MusicOpen = activePanel == "music"
	local ThrowOpen = activePanel == "throw"
	local equippedPotionUID, setEquippedPotionUID = useState(nil)
	local currentEvent, setCurrentEvent = useState("none")
	local previousEvent = useRef("none")
	local bannerCloserRef = useRef(nil)
	local previousPotionBookKeys = useRef({})

	local function toggle(panel)
		setActivePanel(function(prev)
			if prev == panel then
				ThrowPanelProducer.setPanel("none")
				return "none"
			else
				ThrowPanelProducer.setPanel(panel)
				return panel
			end
		end)
	end
	-- Subscribe to Reflex state for player data
	local currentSeedRef = useRef(nil)
	useEffect(function()
		local player = game.Players.LocalPlayer

		local unsubscribe = PlayerSessions:subscribe(function(state)
			local playerEntity = state.players[player]
			if playerEntity and playerEntity.Data then
				setPlayerData(playerEntity.Data)
			end
		end)

		PlayerSessions:subscribe(function(state)
			local playerEntity = state.players[player]
			if playerEntity and playerEntity.Data then
				for seed, d in playerEntity.Data and playerEntity.Data.ShopCycles or {} do
					return seed
				end
			end
		end, function(seed)
			if currentSeedRef.current ~= nil then
				toast.open("SHOP REFRESHED")
			end
			setCurrentSeed(seed)
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
	useEffect(function()
		currentSeedRef.current = currentSeed
	end, { currentSeed })

	-- Subscribe to special events
	useEffect(function()
		local SpecialEvents = game.ReplicatedStorage.Shared.Events:WaitForChild("SpecialEvents")
		local GetSpecialEvents = game.ReplicatedStorage.Shared.Events:WaitForChild("GetSpecialEvents")

		-- Get initial event state
		task.spawn(function()
			local events = GetSpecialEvents:InvokeServer()
			if events then
				for eventId, _ in pairs(events) do
					if eventId ~= previousEvent.current then
						previousEvent.current = eventId
						setCurrentEvent(eventId)
					end
					break
				end
			end
		end)

		-- Listen for event changes
		local connection = SpecialEvents.OnClientEvent:Connect(function(events)
			if events and next(events) then
				for eventId, _ in pairs(events) do
					if eventId ~= previousEvent.current then
						-- Close old banner if exists
						if bannerCloserRef.current then
							bannerCloserRef.current()
							bannerCloserRef.current = nil
						end
						previousEvent.current = eventId
						setCurrentEvent(eventId)
					end
					break
				end
			else
				-- Close banner when event ends
				if bannerCloserRef.current then
					bannerCloserRef.current()
					bannerCloserRef.current = nil
				end
				previousEvent.current = "none"
				setCurrentEvent("none")
			end
		end)

		return function()
			connection:Disconnect()
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

		-- Update ref for comparison
		previousPotionBookKeys.current = currentKeys
	end, { playerData and playerData.PotionBook })

	-- Listen for equipped potion changes
	useEffect(function()
		local unsubscribe = ThrowPanelProducer:subscribe(function(state)
			setEquippedPotionUID(state.equippedPotionUID)
		end)

		-- Initial state
		setEquippedPotionUID(ThrowPanelProducer:getState().equippedPotionUID)

		return function()
			unsubscribe()
		end
	end, {})

	useEffect(function()
		UserInputService.InputBegan:Connect(function(io, gp)
			if gp then
				return
			end
			if io.KeyCode == Enum.KeyCode.E then
				toggle("inventory")
			elseif io.KeyCode == Enum.KeyCode.G then
				game.Players.LocalPlayer.Character:PivotTo(workspace.Shops.June:GetPivot())
			elseif io.KeyCode == Enum.KeyCode.N then
				toggle("music")
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
					local clockTime = shared.ClockController.GetFormattedTime()
					local shopState = ShopState.getCurrentState()

					local isSpecialEvent = shopState.timeToSpecial
						> (ShopState.BIG_CYCLE_DURATION - ShopState.SMALL_CYCLE_DURATION)
					local countdownText = ShopState.formatTime(
						math.floor(
							isSpecialEvent
									and shopState.timeToSpecial - (ShopState.BIG_CYCLE_DURATION - ShopState.SMALL_CYCLE_DURATION)
								or shopState.timeToSpecial
						)
					)
					setCurrentTime((isSpecialEvent and "Event ends in :\n⭐ " or "Next Event:\n⭐ ") .. countdownText)
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
			Size = UDim2.new(0, 300, 0, 50),
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderSizePixel = 0,
			ZIndex = 10,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
			BaseButton = e("TextButton", {
				Size = UDim2.new(0, 90, 1, -8),
				BackgroundColor3 = Color3.fromRGB(60, 180, 60),
				BorderSizePixel = 0,
				Text = "Base",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.FredokaOne,
				ZIndex = 11,
				LayoutOrder = 1,
				ref = function(rbx)
					TutorialRefs.setBaseButton(rbx)
				end,
				[React.Event.Activated] = function()
					PlayerSessions:getState(function(state: PlayerSessions.PlayersState)
						local session = state.players[game.Players.LocalPlayer]
						if not (session and session.Plot) then
							return
						end
						toggle("none")
						game.Players.LocalPlayer.Character:PivotTo(session.Plot:GetPivot())
					end)
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
			ShopButton = e("TextButton", {
				Size = UDim2.new(0, 90, 1, -8),
				BackgroundColor3 = Color3.fromRGB(160, 160, 255),
				BorderSizePixel = 0,
				Text = "Shop",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.FredokaOne,
				ZIndex = 11,
				LayoutOrder = 2,
				ref = function(rbx)
					TutorialRefs.setShopButton(rbx)
				end,
				[React.Event.Activated] = function()
					toggle("none")
					game.Players.LocalPlayer.Character:PivotTo(workspace.Shops.June:GetPivot())
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
			SellButton = e("TextButton", {
				Size = UDim2.new(0, 90, 1, -8),
				BackgroundColor3 = Color3.fromRGB(250, 60, 60),
				BorderSizePixel = 0,
				Text = "Sell",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.FredokaOne,
				ZIndex = 11,
				LayoutOrder = 3,
				[React.Event.Activated] = function()
					toggle("none")
					game.Players.LocalPlayer.Character:PivotTo(workspace.Shops.Mitch:GetPivot())
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
			TimeDisplay = e("TextLabel", {
				Size = UDim2.new(0, 120, 0, 60),
				Position = UDim2.new(0.5, 0, 0, 10),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				BorderSizePixel = 0,
				Text = currentTime,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				Font = Enum.Font.FredokaOne,
				ZIndex = 11,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),
		Money = e("TextLabel", {
			Text = "$" .. Mionum.new(playerData and playerData.Cash or 0):toString(),
			Position = UDim2.new(1, -40, 0, 0),
			TextSize = 24,
			BackgroundTransparency = 1,
			TextStrokeTransparency = 0,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			AnchorPoint = Vector2.new(1, 1),
			Font = "FredokaOne",
			AutomaticSize = Enum.AutomaticSize.XY,
		}),
		NothingButton = e(function(nb_props)
			local multext = ("Bonus Multiplier: +%.0f%%"):format(
				(MultiplierHelper.GetFinalMultiplier(nb_props.PlayerData and nb_props.PlayerData.Multipliers) - 1) * 100
			)

			return e("TextButton", {
				-- Size = UDim2.new(0, 200, 0, 50),
				AutomaticSize = Enum.AutomaticSize.XY,
				TextSize = 24,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -40, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				Text = multext,
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.FredokaOne,
				ZIndex = 11,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			})
		end, {
			PlayerData = playerData,
		}),

		SpecialEventBannerDisplay = currentEvent ~= "none" and e(SpecialEventBanner, {
			eventName = SpecialEventsState.getEventName(currentEvent) or "Special Event Active!",
			eventId = currentEvent,
			eventColor = SpecialEventsState.getEventColor(currentEvent),
			onMount = function(startClose)
				if not startClose then
					return
				end
				task.wait(3)
				startClose()
				-- bannerCloserRef.current = startClose
			end,
			onAnimationComplete = function()
				-- Banner finished closing animation
			end,
		}),

		ResetButton = e("TextButton", {
			-- ResetButton = game.Players.LocalPlayer.Name == "Mimoimior" and e("TextButton", {
			-- Size = UDim2.new(0, 120, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(180, 50, 50),
			BorderSizePixel = 0,
			Text = "Reset Data",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			Font = Enum.Font.FredokaOne,
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
		musicbutton = e("TextButton", {
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(134, 220, 131),
			BorderSizePixel = 0,
			Text = "🎵",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 42,
			Font = Enum.Font.FredokaOne,
			ZIndex = 10,
			[React.Event.Activated] = function()
				toggle("music")
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
		}),
		throwpotion = equippedPotionUID ~= "none" and e("TextButton", {
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(1, 0, 0.35, 0),
			BackgroundColor3 = Color3.fromRGB(120, 180, 255),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0.5),
			Text = "🎯 Throw\nPotion",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 24,
			Font = Enum.Font.FredokaOne,
			ZIndex = 10,
			[React.Event.Activated] = function()
				toggle("throw")
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
		}),
		pickupotion = e("TextButton", {
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 120, 131),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0.5),
			Text = "Pick up\nPotion",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 24,
			Font = Enum.Font.FredokaOne,
			ZIndex = 10,
			[React.Event.Activated] = function()
				toggle("removepotion")
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
		}),
		Inventory = e(require(script.Parent.Inventory), {
			InventoryOpen = InventoryOpen,
			close = function()
				toggle("none")
			end,
			panel = activePanel,
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
			activePanel = activePanel,
			currentCauldron = currentCauldron,
			PotionBook = playerData.PotionBook or {},
		}),
		Cauldron = e(require(script.Parent.Cauldron), {
			activePanel = activePanel,
			PlayerData = playerData,
			setCurrentCauldron = function(cauldronId)
				setCurrentCauldron(cauldronId)
				setActivePanel("craft")
			end,
		}),
		Tutorial = playerData and not playerData.TutorialFinished and e(require(script.Parent.Tutorial), {
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
		Music = e(require(script.Parent.Music), {
			MusicOpen = MusicOpen,
			PlayerData = playerData,
			close = function()
				toggle("music")
			end,
		}),
		ThrowPanelComponent = e(ThrowPanel, {
			Open = ThrowOpen,
			close = function()
				toggle("none")
			end,
		}),
	})
end

return Main
