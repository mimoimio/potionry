local React = require(game.ReplicatedStorage.Packages.React)
local Mionum = require(game.ReplicatedStorage.Packages.Mionum)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
local PotionConfigs = CraftingModule.CraftingLookup
local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)

type SellProps = {
	PlayerData: any,
	Open: boolean,
	close: () -> (),
}

local function PotionCard(props: {
	Potion: any,
	OnSell: (string) -> (),
})
	local potion = props.Potion
	local config = PotionConfigs[potion.PotionId]

	if not config then
		return nil
	end

	local varcfg = VariationsConfig[potion.VariationId]
	local price = config.Price or 0
	price = price * (varcfg and varcfg.Multiplier or 1)
	local sellPrice = math.floor(price / 2)

	return e("Frame", {
		Size = UDim2.new(0, 180, 0, 120),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),

		UIStroke = e("UIStroke", {
			Color = Color3.fromRGB(85, 170, 255),
			Thickness = 1,
		}),

		Container = e("Frame", {
			Size = UDim2.new(1, -10, 1, -10),
			Position = UDim2.fromOffset(5, 5),
			BackgroundTransparency = 1,
		}, {
			Name = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				Text = PotionConfigs[potion.PotionId].DisplayName,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),

			Variation = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 22),
				BackgroundTransparency = 1,
				Text = potion.VariationId or "Normal",
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Price = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.fromOffset(0, 42),
				BackgroundTransparency = 1,
				Text = "💰 $" .. Mionum.new(sellPrice):toString(),
				TextColor3 = Color3.fromRGB(85, 255, 127),
				Font = Enum.Font.FredokaOne,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			UID = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 14),
				Position = UDim2.fromOffset(0, 62),
				BackgroundTransparency = 1,
				Text = "ID: " .. potion.UID:sub(1, 8),
				TextColor3 = Color3.fromRGB(120, 120, 120),
				Font = Enum.Font.Gotham,
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			SellButton = e("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				Position = UDim2.new(0, 0, 1, -28),
				BackgroundColor3 = Color3.fromRGB(200, 50, 50),
				Text = "SELL",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 12,
				[React.Event.Activated] = function()
					props.OnSell(potion.UID)
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),
	})
end

local function Sell(props: SellProps)
	local activeTab, setActiveTab = useState("Potions")
	local potions = props.PlayerData and props.PlayerData.Potions or {}
	local potionSlots = props.PlayerData and props.PlayerData.PotionSlots or {}

	-- Filter out placed potions
	local unplacedPotions = {}
	local placedPotionUIDs = {}
	for rackName, rack in pairs(potionSlots) do
		for slotName, uid in pairs(rack) do
			if uid ~= "none" then
				placedPotionUIDs[uid] = true
			end
		end
	end
	for _, potion in ipairs(potions) do
		if not placedPotionUIDs[potion.UID] then
			table.insert(unplacedPotions, potion)
		end
	end

	-- Handle individual sell
	local function handleSellPotion(uid: string)
		local SellPotion: RemoteEvent = game.ReplicatedStorage.Shared.Events.SellPotion
		warn("Fired")
		SellPotion:FireServer({ uid })

		-- Play sound
		local sound: Sound? = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Cash")
		if sound then
			task.spawn(function()
				sound = sound:Clone()
				sound.Parent = game.Players.LocalPlayer
				if not sound.IsLoaded then
					sound.Loaded:Wait()
				end
				sound:Play()
				sound.Ended:Wait()
				sound:Destroy()
			end)
		end
	end

	-- Handle sell all
	local function handleSellAllPotions()
		if #unplacedPotions == 0 then
			warn("No unplaced potions")
			return
		end

		local uids = {}
		for _, potion in ipairs(unplacedPotions) do
			table.insert(uids, potion.UID)
		end

		local SellPotion: RemoteEvent = game.ReplicatedStorage.Shared.Events.SellPotion
		SellPotion:FireServer(uids)
		warn("Fired")

		-- Play sound
		local sound: Sound? = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Cash")
		if sound then
			task.spawn(function()
				sound = sound:Clone()
				sound.Parent = game.Players.LocalPlayer
				if not sound.IsLoaded then
					sound.Loaded:Wait()
				end
				sound:Play()
				sound.Ended:Wait()
				sound:Destroy()
			end)
		end
	end

	-- Build cards
	local totalPrice = 0
	local cards = {}
	if activeTab == "Potions" then
		for i, potion in ipairs(unplacedPotions) do
			cards["Potion_" .. potion.UID] = e(PotionCard, {
				key = "Potion_" .. potion.UID,
				Potion = potion,
				OnSell = handleSellPotion,
			})
			local varcfg = VariationsConfig[potion.VariationId] or VariationsConfig.none
			local mul = varcfg.Multiplier
			totalPrice += PotionConfigs[potion.PotionId].Price * mul
		end
	end

	local itemCount = activeTab == "Potions" and #unplacedPotions

	local totalPriceString = ([[( total: %s)]]):format(Mionum.new(totalPrice):toString())

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0),
		ZIndex = 50,
		Visible = props.Open,
	}, {
		Container = e("Frame", {
			Size = UDim2.new(0, 640, 1, -40),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
			BorderSizePixel = 0,
			ref = function(this)
				if not this then
					return
				end
				local uigradient = game.ReplicatedStorage.Shared.UIGradient:Clone()
				uigradient.Parent = this
			end,
		}, {

			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),

			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
				BorderSizePixel = 0,
				ref = function(this)
					if not this then
						return
					end
					local uigradient = game.ReplicatedStorage.Shared.UIGradient:Clone()
					uigradient.Parent = this
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),

				Title = e("TextLabel", {
					Size = UDim2.new(0.5, -20, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					Text = "SELL POTIONS",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 20,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				CloseButton = e("TextButton", {
					Size = UDim2.fromOffset(40, 40),
					Position = UDim2.new(1, -50, 0.5, -20),
					BackgroundColor3 = Color3.fromRGB(200, 50, 50),
					Text = "X",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 20,
					[React.Event.Activated] = function()
						props.close()
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
				}),
			}),

			SellAllButton = e("TextButton", {
				Size = UDim2.new(1, -20, 0, 45),
				Position = UDim2.new(0, 10, 1, -55),
				BackgroundColor3 = itemCount > 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(80, 80, 80),
				Text = activeTab == "Potions" and "SELL ALL POTIONS" .. totalPriceString,
				TextColor3 = itemCount > 0 and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 150),
				Font = Enum.Font.FredokaOne,
				TextSize = 18,
				AutoButtonColor = itemCount > 0,
				[React.Event.Activated] = function()
					if activeTab == "Potions" then
						handleSellAllPotions()
					end
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),

			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, -20, 1, -130),
				Position = UDim2.fromOffset(10, 80),
				BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				CanvasSize = UDim2.new(0, 0, 0, math.ceil(itemCount / 3) * 130),
				ref = function(this)
					if not this then
						return
					end
					local uigradient = game.ReplicatedStorage.Shared.UIGradient:Clone()
					uigradient.Parent = this
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),

				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				}),

				UIGridLayout = e("UIGridLayout", {
					CellSize = UDim2.new(0, 190, 0, 120),
					CellPadding = UDim2.new(0, 10, 0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Items = e(React.Fragment, nil, cards),
			}),

			EmptyState = itemCount == 0 and e("TextLabel", {
				Size = UDim2.new(1, -40, 0, 100),
				Position = UDim2.new(0.5, 0, 0.5, 20),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = activeTab == "Potions" and "No unplaced potions to sell!",
				TextColor3 = Color3.fromRGB(150, 150, 150),
				Font = Enum.Font.Gotham,
				TextSize = 16,
				TextWrapped = true,
			}) or nil,
		}),
	})
end

return Sell
