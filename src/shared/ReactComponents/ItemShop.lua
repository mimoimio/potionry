local React = require(game.ReplicatedStorage.Packages.React)
local Mionum = require(game.ReplicatedStorage.Packages.Mionum)
local ShopState = require(game.ReplicatedStorage.Shared.Utils.ShopState)
local TutorialRefs = require(game.ReplicatedStorage.Shared.producers.TutorialRefs)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useCallback = React.useCallback

local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local products = {

	["daybloomQuantity1"] = {
		ProductId = 3502405552,
		Name = "1x Daybloom",
		Price = 1,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["daybloomQuantity10"] = {
		ProductId = 3502405548,
		Name = "10x Daybloom",
		Price = 5,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Blinkroot (common)
	["blinkrootQuantity1"] = {
		ProductId = 3502405539,
		Name = "1x Blinkroot",
		Price = 2,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["blinkrootQuantity10"] = {
		ProductId = 3502405538,
		Name = "10x Blinkroot",
		Price = 9,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Lucky Clover (uncommon)
	["luckycloverQuantity1"] = {
		ProductId = 3502405523,
		Name = "1x Lucky Clover",
		Price = 3,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["luckycloverQuantity10"] = {
		ProductId = 3502405522,
		Name = "10x Lucky Clover",
		Price = 14,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Moonglow (rare)
	["moonglowQuantity1"] = {
		ProductId = 3502405526,
		Name = "1x Moonglow",
		Price = 4,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["moonglowQuantity10"] = {
		ProductId = 3502405529,
		Name = "10x Moonglow",
		Price = 24,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Glowing Mushroom (rare)
	["glowshroomQuantity1"] = {
		ProductId = 3502405524,
		Name = "1x Glowing Mushroom",
		Price = 6,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["glowshroomQuantity10"] = {
		ProductId = 3502405528,
		Name = "10x Glowing Mushroom",
		Price = 30,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Spiral Aloe (epic)
	["spiralaloeQuantity1"] = {
		ProductId = 3502405525,
		Name = "1x Spiral Aloe",
		Price = 8,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["spiralaloeQuantity10"] = {
		ProductId = 3502405531,
		Name = "10x Spiral Aloe",
		Price = 44,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Bloodthorn (epic)
	["bloodthornQuantity1"] = {
		ProductId = 3502405540,
		Name = "1x Bloodthorn",
		Price = 9,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["bloodthornQuantity10"] = {
		ProductId = 3502405545,
		Price = 54,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Waterleaf (legendary)
	["waterleafQuantity1"] = {
		ProductId = 3502405541,
		Name = "1x Waterleaf",
		Price = 12,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["waterleafQuantity10"] = {
		ProductId = 3502405542,
		Name = "10x Waterleaf",
		Price = 79,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},

	-- Fireblossom (mythic)
	["fireblossomQuantity1"] = {
		ProductId = 3502405544,
		Name = "1x Fireblossom",
		Price = 15,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 1 },
	},
	["fireblossomQuantity10"] = {
		ProductId = 3502405543,
		Name = "10x Fireblossom",
		Price = 90,
		Reward = { Type = "Ingredient", ItemId = "", Quantity = 10 },
	},
}

local function ViewportFrame3D(props: {
	ItemId: string,
	Size: UDim2?,
	Position: UDim2?,
})
	local ref = useRef(nil)

	useEffect(function()
		if not ref.current then
			return
		end

		local viewport = ref.current :: ViewportFrame

		-- Create camera
		local camera = viewport:FindFirstChild("Camera") or Instance.new("Camera")
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		-- Try to find and clone the model
		local modelsFolder = game.ReplicatedStorage.Shared.Models
		local modelTemplate = modelsFolder:FindFirstChild(props.ItemId)

		if modelTemplate then
			-- Clear existing models
			for _, child in viewport:GetChildren() do
				if child:IsA("Model") then
					child:Destroy()
				end
			end

			local model = modelTemplate:Clone()
			model.Parent = viewport
			camera.CameraType = Enum.CameraType.Scriptable

			-- Calculate the model's bounding box
			local cf, size = model:GetBoundingBox()

			-- Position camera looking at the center
			local maxSize = math.max(size.X, size.Y, size.Z)
			local distance = 3
			camera.CFrame = CFrame.new(cf.Position + Vector3.new(distance, distance, distance))
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, cf.Position)
			camera.FieldOfView = 70
			camera:ZoomToExtents(cf, size)
		else
			warn("[ItemViewport] Model not found for ItemId:", props.ItemId)
		end
	end, { props.ItemId })

	return e("ViewportFrame", {
		ref = ref,
		Size = props.Size or UDim2.new(1, 0, 0, 100),
		Position = props.Position or UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
	})
end

local function ItemCard(
	props: {
		ItemId: string,
		Config: any,
		Available: number,
		Money: number,
		OnBuy: (string) -> (),
		OnBuyRobux: (number) -> (), -- productId
		LayoutOrder: number,
		TutorialHighlight: boolean?,
		Selected: boolean?,
		OnClick: (string) -> (),
	}
)
	local config = props.Config
	local enough = props.Money and props.Money >= config.Price
	local available = props.Available > 0
	local highlighted = props.TutorialHighlight or false
	local selected = props.Selected or false

	return e("ImageButton", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		ZIndex = highlighted and 999 or 1,
		ref = function(rbx)
			if props.ItemId == "daybloom" and props.TutorialHighlight then
				TutorialRefs.setDaybloomCard(rbx)
			else
				if props.ItemId == "daybloom" then
					TutorialRefs.setDaybloomCard(nil)
				end
			end
		end,
		[React.Event.Activated] = function()
			props.OnClick(props.ItemId)
		end,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),

		UIStroke = e("UIStroke", {
			Color = highlighted and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(70, 70, 70),
			Thickness = highlighted and 4 or 2,
		}),

		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),

		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		-- Viewport Left
		Viewport = e(ViewportFrame3D, {
			ItemId = props.ItemId,
			Size = UDim2.new(0, 150, 0, 150),
			LayoutOrder = 1,
		}),
		Details = e("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			ZIndex = highlighted and 999 or 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- Item name
			Name = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Text = config.DisplayName,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 32,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}),

			-- -- Rate
			-- Rate = e("TextLabel", {
			-- 	Size = UDim2.new(1, 0, 0, 16),
			-- 	BackgroundTransparency = 1,
			-- 	Text = "⚡ " .. Mionum.new(config.Rate):toString() .. "/s",
			-- 	TextColor3 = Color3.fromRGB(150, 255, 150),
			-- Font = Enum.Font.FredokaOne,
			-- 	TextSize = 13,
			-- 	TextXAlignment = Enum.TextXAlignment.Center,
			-- 	LayoutOrder = 3,
			-- }),

			-- Price and stock info
			InfoContainer = e("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 15),
				}),

				Price = e("TextLabel", {
					Size = UDim2.fromScale(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					Text = "$" .. Mionum.new(config.Price):toString(),
					TextColor3 = Color3.fromRGB(255, 215, 0),
					Font = Enum.Font.FredokaOne,
					TextSize = 18,
				}),

				Stock = e("TextLabel", {
					Size = UDim2.fromScale(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					Text = "Stock " .. props.Available .. "x",
					TextColor3 = props.Available > 0 and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 100, 100),
					Font = Enum.Font.FredokaOne,
					TextSize = 16,
				}),
			}),

			-- Buy button (only visible if selected)
			BuyButton = e("TextButton", {
				Visible = selected,
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = enough and available and Color3.fromRGB(80, 200, 80)
					or (not enough and Color3.fromRGB(200, 80, 80))
					or Color3.fromRGB(80, 80, 80),
				Text = available and "$" .. Mionum.new(config.Price):toString() or "SOLD OUT",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				AutoButtonColor = enough and available,
				LayoutOrder = 5,
				[React.Event.Activated] = function()
					if enough and available then
						props.OnBuy(props.ItemId)
					end
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}) or nil,

			-- Robux purchase buttons (only visible if selected and configured)
			RobuxButtons = products[props.ItemId .. "Quantity1"] and e("Frame", {
				Visible = selected,
				Size = UDim2.new(1, 0, 0, 35),
				BackgroundTransparency = 1,
				LayoutOrder = 6,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 8),
				}),

				Buy1 = e("TextButton", {
					Size = UDim2.new(0, 90, 1, 0),
					BackgroundColor3 = Color3.fromRGB(0, 200, 0),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 12,
					AutoButtonColor = true,
					[React.Event.Activated] = function()
						props.OnBuyRobux(products[props.ItemId .. "Quantity1"].ProductId)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),

					Content = e("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
					}, {
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, 4),
						}),

						RobuxIcon = e("ImageLabel", {
							Size = UDim2.fromOffset(20, 20),
							BackgroundTransparency = 1,
							Image = "rbxasset://textures/ui/common/robux_small.png",
							LayoutOrder = 1,
						}),

						Price = e("TextLabel", {
							Size = UDim2.fromScale(0, 1),
							AutomaticSize = Enum.AutomaticSize.X,
							LayoutOrder = 0,
							BackgroundTransparency = 1,
							Text = tostring(products[props.ItemId .. "Quantity1"].Price),
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.FredokaOne,
							TextSize = 13,
						}),
					}),
				}),

				Buy10 = products[props.ItemId .. "Quantity10"] and e("TextButton", {
					Size = UDim2.new(0, 90, 1, 0),
					BackgroundColor3 = Color3.fromRGB(0, 150, 255),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 12,
					AutoButtonColor = true,
					[React.Event.Activated] = function()
						props.OnBuyRobux(products[props.ItemId .. "Quantity10"].ProductId)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),

					Content = e("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
					}, {
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, 4),
						}),

						Label = e("Frame", {
							Size = UDim2.fromScale(0, 0),
							AutomaticSize = Enum.AutomaticSize.XY,
							BackgroundTransparency = 1,
							LayoutOrder = 3,
						}, {
							Text = e("TextLabel", {
								Size = UDim2.fromScale(0, 0),
								AutomaticSize = Enum.AutomaticSize.X,
								Rotation = 35,
								BackgroundTransparency = 1,
								Text = "x10!",
								TextColor3 = Color3.new(1, 1, 0),
								TextStrokeTransparency = 0,
								TextStrokeColor3 = Color3.new(0, 0, 0),
								Font = Enum.Font.FredokaOne,
								TextSize = 20,
							}),
						}),
						RobuxIcon = e("ImageLabel", {
							Size = UDim2.fromOffset(20, 20),
							BackgroundTransparency = 1,
							LayoutOrder = 3,
							Image = "rbxasset://textures/ui/common/robux_small.png",
						}),

						Price = e("TextLabel", {
							Size = UDim2.fromScale(0, 1),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundTransparency = 1,
							Text = tostring(products[props.ItemId .. "Quantity10"].Price),
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.FredokaOne,
							TextSize = 13,
							LayoutOrder = 2,
						}),
					}),
				}) or nil,
			}) or nil,
		}),
	})
end

local debounce = true

local function ItemShop(props: {
	Open: boolean,
	close: () -> (),
	PlayerData: any,
	tutorialHighlight: string?,
})
	local shopItems, setShopItems = useState({} :: { [string]: number })
	local selectedItem, setSelectedItem = useState(nil :: string?)
	local countdown, setCountdown = useState("00:00")

	-- Memoized callback for selecting an item
	local selectItem = useCallback(function(itemId: string)
		if selectedItem == itemId then
			setSelectedItem(nil)
		else
			setSelectedItem(itemId)
		end
	end, { selectedItem })

	-- Fetch shop items
	local function fetchShopItems()
		task.spawn(function()
			local GetShopItems: RemoteFunction = game.ReplicatedStorage.Shared.Events:WaitForChild("GetShopItems")
			local success, result = pcall(function()
				return GetShopItems:InvokeServer()
			end)
			if success and result then
				setShopItems(result or {})
			else
				warn("Failed to fetch shop items:", result)
			end
		end)
	end

	-- Initialize shop data
	useEffect(function()
		if props.Open then
			fetchShopItems()
		end
	end, { props.Open })

	-- Listen to shop refresh
	useEffect(function()
		local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")
		local ShopRefreshed: RemoteEvent = Events:WaitForChild("ShopRefreshed")

		local connection = ShopRefreshed.OnClientEvent:Connect(function()
			if props.Open then
				fetchShopItems()
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { props.Open })

	-- Update countdown every second
	useEffect(function()
		if not props.Open then
			return
		end

		local running = true
		task.spawn(function()
			while running do
				local shopState = ShopState.getCurrentState()
				local timeText = ShopState.formatTime(math.floor(shopState.timeLeft))
				setCountdown(timeText)
				task.wait(1)
			end
		end)

		return function()
			running = false
		end
	end, { props.Open })

	-- Handle in-game currency purchase
	local function handleBuy(itemId: string)
		if not debounce then
			return
		end
		debounce = false

		local BuyItem: RemoteEvent = game.ReplicatedStorage.Shared.Events:FindFirstChild("BuyItem")
		local itemConfig = ItemsConfig[itemId]

		-- Play purchase sound if enough money
		-- local sound: Sound? = game.ReplicatedStorage.Shared.SFX:FindFirstChild("PickUp")
		BuyItem:FireServer(itemId)
		-- if sound and props.PlayerData.Cash >= itemConfig.Price then
		-- 	task.spawn(function()
		-- 		sound = sound:Clone()
		-- 		sound.Parent = game.Players.LocalPlayer
		-- 		if not sound.IsLoaded then
		-- 			sound.Loaded:Wait()
		-- 		end
		-- 		sound:Play()
		-- 		sound.Ended:Wait()
		-- 		sound:Destroy()
		-- 	end)
		-- else
		-- 	-- Play error sound
		-- 	local errorSound: Sound? = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Error")
		-- 	if errorSound then
		-- 		task.spawn(function()
		-- 			errorSound = errorSound:Clone()
		-- 			errorSound.Parent = game.Players.LocalPlayer
		-- 			if not errorSound.IsLoaded then
		-- 				errorSound.Loaded:Wait()
		-- 			end
		-- 			errorSound:Play()
		-- 			errorSound.Ended:Wait()
		-- 			errorSound:Destroy()
		-- 		end)
		-- 	end
		-- end

		-- Refresh shop to update counts
		task.wait(0.1)
		fetchShopItems()
		debounce = true
	end

	-- Handle Robux purchase
	local function handleBuyRobux(productId: number)
		local PurchaseProduct: RemoteEvent = game.ReplicatedStorage.Shared.Events:FindFirstChild("PurchaseProduct")
		if PurchaseProduct then
			PurchaseProduct:FireServer(productId)
		else
			warn("[ItemShop] PurchaseProduct event not found")
		end
	end

	if not props.Open then
		return nil
	end

	-- Build item cards
	local itemCards = {}
	for i, config in ipairs(ItemsConfig) do
		local itemId = config.ItemId
		local available = shopItems[itemId] or 0
		itemCards[itemId] = e(ItemCard, {
			LayoutOrder = -i,
			key = itemId,
			ItemId = itemId,
			OnClick = selectItem,
			Config = config,
			Available = available,
			Money = props.PlayerData.Cash,
			OnBuy = handleBuy,
			OnBuyRobux = handleBuyRobux,
			TutorialHighlight = props.tutorialHighlight == itemId,
			Selected = selectedItem == itemId,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0),
		ZIndex = 50,
	}, {
		Container = e("Frame", {
			Size = UDim2.new(0, 600, 1, -40),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ref = function(this)
				if not this then
					return
				end
				-- game.ReplicatedStorage.Shared.UIGradient:Clone().Parent = this
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),

			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundColor3 = Color3.fromRGB(33, 112, 33),
				BorderSizePixel = 0,
				ref = function(this)
					if not this then
						return
					end
					-- game.ReplicatedStorage.Shared.UIGradient:Clone().Parent = this
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),

				TitleContainer = e("Frame", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.fromOffset(20, 0),
					BackgroundTransparency = 1,
				}, {
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 2),
					}),

					Title = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						Text = "🌿 INGREDIENTS SHOP",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 20,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Countdown = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						Text = "⏱ Refresh in " .. countdown,
						TextColor3 = Color3.fromRGB(200, 255, 200),
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),

				CloseButton = e("TextButton", {
					Size = UDim2.fromOffset(40, 40),
					Position = UDim2.new(1, -50, 0.5, -20),
					BackgroundColor3 = Color3.fromRGB(200, 50, 50),
					Text = "X",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 20,
					[React.Event.Activated] = props.close,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
				}),
			}),

			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, -20, 1, -80),
				Position = UDim2.fromOffset(10, 70),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				VerticalScrollBarInset = "Always",
				ScrollBarThickness = 6,
				CanvasSize = UDim2.new(0, 0, 0, 0), -- Auto-calculated by UIListLayout
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, {
				UIListLayout = e("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),

				Items = e(React.Fragment, nil, itemCards),
			}),
		}),
	})
end

return ItemShop
