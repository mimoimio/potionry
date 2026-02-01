local ItemViewport = require(script.Parent.ItemViewport)
local PotionViewport = require(script.Parent.PotionViewport)
local React = require(game.ReplicatedStorage.Packages.React)
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local ItemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)

local function craft(resultId, currentCauldron)
	if not currentCauldron then
		warn("No currentCauldron")
		return
	end
	if not resultId then
		warn("No resultId")
		return
	end
	-- Fire remote to server to craft the potion
	local CraftPotion: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("CraftPotion")
	-- warn(resultId, currentCauldron)
	CraftPotion:FireServer(resultId, currentCauldron)
end

type CraftProps = {
	CraftOpen: boolean,
	close: () -> nil,
	currentCauldron: string?,
	PotionBook: { [string]: boolean }?,
	tutorialHighlight: string?,
}

local function Craft(props: CraftProps)
	local slot1, setSlot1 = useState(nil :: string?)
	local slot2, setSlot2 = useState(nil :: string?)
	local slot3, setSlot3 = useState(nil :: string?)
	local craftResult, setCraftResult = useState(nil)
	local Ingredients: { [string]: number }, setIngredients = useState(nil)
	local potionBook = props.PotionBook or {}

	-- Subscribe to Reflex state for ingredients
	useEffect(function()
		local player = game.Players.LocalPlayer

		-- Subscribe to Reflex state changes
		local unsubscribe = PlayerSessions:subscribe(function(state)
			local playerEntity = state.players[player]
			if playerEntity and playerEntity.Data.Ingredients then
				setIngredients(playerEntity.Data.Ingredients)
			end
		end)

		-- Initial state
		local state = PlayerSessions:getState()
		local playerEntity = state.players[player]
		if playerEntity and playerEntity.Data.Ingredients then
			setIngredients(playerEntity.Data.Ingredients)
		end

		return function()
			unsubscribe()
		end
	end, {})
	-- Whenever slots change, try to craft
	useEffect(function()
		local ingredients = {}
		if slot1 then
			table.insert(ingredients, slot1)
		end
		if slot2 then
			table.insert(ingredients, slot2)
		end
		if slot3 then
			table.insert(ingredients, slot3)
		end

		if #ingredients > 0 then
			local result = CraftingModule:Craft(ingredients)
			setCraftResult(result)
		else
			setCraftResult(nil)
		end
	end, { slot1, slot2, slot3 })
	useEffect(function()
		if slot1 and Ingredients[slot1] <= 0 then
			setSlot1(nil)
		end
		if slot2 and Ingredients[slot2] <= 0 then
			setSlot2(nil)
		end
		if slot3 and Ingredients[slot3] <= 0 then
			setSlot3(nil)
		end
	end, { Ingredients })

	local onclick = function(textbutton, io)
		-- Add to first empty slot
		if not props.CraftOpen then
			return
		end
		local ItemId = textbutton.Name

		-- Check if this ingredient is already in any slot
		if slot1 == ItemId or slot2 == ItemId or slot3 == ItemId then
			return
		end

		if Ingredients[ItemId] <= 0 then
			return
		end

		if not slot1 then
			setSlot1(ItemId)
		elseif not slot2 then
			setSlot2(ItemId)
		elseif not slot3 then
			setSlot3(ItemId)
		end
	end
	useEffect(function()
		if props.CraftOpen then
			return
		end
		setSlot1(nil)
		setSlot2(nil)
		setSlot3(nil)
	end, { props.CraftOpen })
	-- Create list of available items from ItemConfigs
	local itemButtons = {}
	for i, config in ipairs(ItemConfigs) do
		local amt = (Ingredients and Ingredients[config.ItemId] or 0)
		amt = amt <= 0 and 0
			or (
				amt
				- (
					(slot1 == config.ItemId and 1 or 0)
					+ (slot2 == config.ItemId and 1 or 0)
					+ (slot3 == config.ItemId and 1 or 0)
				)
			)
		itemButtons[config.ItemId] = e("TextButton", {
			Size = UDim2.new(1, -10, 0, 40),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			Text = amt,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.FredokaOne,
			TextSize = 14,
			TextWrapped = true,
			Active = props.CraftOpen,
			Interactable = props.CraftOpen,
			LayoutOrder = -i,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			[React.Event.Activated] = onclick,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Viewport = e(ItemViewport, {
				ItemId = config.ItemId,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ImageTransparency = amt <= 0 and 0.8 or 0,
			}),
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = -10,
	}, {
		-- Left panel with items (visible when craft UI is closed)
		LeftPanel = e("ScrollingFrame", {
			Size = UDim2.new(0, 200, 0.5, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Active = false,
			Interactable = false,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			Visible = not props.CraftOpen,
			AutomaticCanvasSize = Enum.AutomaticSize.XY,

			-- CanvasSize = UDim2.new(0, 0, 0, math.ceil(#ItemConfigs / 1) * 55),
			CanvasSize = UDim2.new(0, 0),
			ZIndex = -10,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Layout = e("UIGridLayout", {
				CellSize = UDim2.new(0, 50, 0, 50),
				CellPadding = UDim2.new(0, 5, 0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 30),
				PaddingBottom = UDim.new(0, 30),
			}),
			Items = e(React.Fragment, nil, itemButtons),
		}),

		-- Main crafting overlay (visible when CraftOpen is true)
		Overlay = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = props.CraftOpen,
		}, {
			MainPanel = e("Frame", {
				Size = UDim2.new(0, 600, 1, -40),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),

				-- Close button
				CloseButton = e("TextButton", {
					Size = UDim2.new(0, 40, 0, 40),
					Position = UDim2.new(1, -10, 0, 10),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = Color3.fromRGB(200, 50, 50),
					Text = "X",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 18,
					[React.Event.Activated] = props.close,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),

				-- -- Reset button
				-- ResetButton = e("TextButton", {
				-- 	Size = UDim2.new(0, 120, 0, 40),
				-- 	Position = UDim2.new(1, -160, 0, 10),
				-- 	AnchorPoint = Vector2.new(1, 0),
				-- 	BackgroundColor3 = Color3.fromRGB(100, 100, 200),
				-- 	Text = "Reset (Playtest)",
				-- 	TextColor3 = Color3.new(1, 1, 1),
				-- 	Font = Enum.Font.FredokaOne,
				-- 	TextSize = 14,
				-- 	[React.Event.Activated] = function()
				-- 		local ResetIngredients: RemoteEvent =
				-- 			game.ReplicatedStorage.Shared.Events:WaitForChild("ResetIngredients")
				-- 		ResetIngredients:FireServer()
				-- 	end,
				-- }, {
				-- 	Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				-- }),

				-- Title
				Title = e("TextLabel", {
					Size = UDim2.new(1, -20, 0, 50),
					Position = UDim2.new(0, 10, 0, 10),
					BackgroundTransparency = 1,
					Text = "CRAFTING", -- (" .. (props.currentCauldron and props.currentCauldron or "") .. ")",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 24,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Crafting Area
				CraftingArea = e("Frame", {
					Size = UDim2.new(1, -20, 0, 200),
					Position = UDim2.new(0, 10, 0, 70),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),

					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					-- Ingredient Slot 1
					Slot1 = e("TextButton", {

						Size = UDim2.new(0, 100, 0, 100),
						BackgroundColor3 = slot1 and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(60, 60, 60),
						TextYAlignment = Enum.TextYAlignment.Bottom,
						Text = slot1 or "Empty",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						LayoutOrder = 1,
						[React.Event.Activated] = function()
							if slot1 then
								setSlot1(nil)
							end
						end,
					}, {
						Viewport = slot1 and e(ItemViewport, {
							ItemId = slot1,
							Size = UDim2.new(1, 0, 1, -15),
							BackgroundTransparency = 1,
						}),
						Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
					}),

					-- Plus Sign
					PlusSign = e("TextLabel", {
						Size = UDim2.new(0, 40, 0, 40),
						BackgroundTransparency = 1,
						Text = "+",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 32,
						LayoutOrder = 2,
					}),

					-- Ingredient Slot 2
					Slot2 = e("TextButton", {

						Size = UDim2.new(0, 100, 0, 100),
						BackgroundColor3 = slot2 and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(60, 60, 60),
						TextYAlignment = Enum.TextYAlignment.Bottom,
						Text = slot2 or "Empty",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						LayoutOrder = 3,
						[React.Event.Activated] = function()
							if slot2 then
								setSlot2(nil)
							end
						end,
					}, {
						Viewport = slot2 and e(ItemViewport, {
							ItemId = slot2,
							Size = UDim2.new(1, 0, 1, -15),
							BackgroundTransparency = 1,
						}),
						Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
					}),
					-- Plus Sign
					PlusSign2 = e("TextLabel", {
						Size = UDim2.new(0, 40, 0, 40),
						BackgroundTransparency = 1,
						Text = "+",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 32,
						LayoutOrder = 4,
					}),

					-- Ingredient Slot 3
					Slot3 = e("TextButton", {

						Size = UDim2.new(0, 100, 0, 100),
						BackgroundColor3 = slot3 and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(60, 60, 60),
						TextYAlignment = Enum.TextYAlignment.Bottom,
						Text = slot3 or "Empty",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						LayoutOrder = 5,
						[React.Event.Activated] = function()
							if slot3 then
								setSlot3(nil)
							end
						end,
					}, {
						Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
						Viewport = slot3 and e(ItemViewport, {
							ItemId = slot3,
							Size = UDim2.new(1, 0, 1, -15),
							BackgroundTransparency = 1,
						}),
					}),

					-- Arrow
					Arrow = e("TextLabel", {
						Size = UDim2.new(0, 40, 0, 40),
						BackgroundTransparency = 1,
						Text = "→",
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 32,
						LayoutOrder = 6,
					}),

					-- Result Slot
					ResultSlot = e("Frame", {
						Size = UDim2.new(0, 120, 0, 120),
						BackgroundColor3 = craftResult and Color3.fromRGB(120, 80, 120) or Color3.fromRGB(60, 60, 60),
						LayoutOrder = 7,
					}, {
						Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
						Viewport = craftResult and e(PotionViewport, {
							PotionId = craftResult.PotionId,
							DisplayName = craftResult.DisplayName,
							Size = UDim2.new(1, 0, 1, -30),
							BackgroundTransparency = 1,
						}),
						CraftButton = e("TextButton", {
							Size = UDim2.new(1, -10, 0, 0),
							Position = UDim2.new(0.5, 0, 1, 0),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = craftResult and 0 or 1,
							BackgroundColor3 = (props.tutorialHighlight == "brew_button" and craftResult)
									and Color3.fromRGB(255, 215, 0)
								or Color3.fromRGB(56, 120, 90),
							Text = craftResult and "Craft" or "",
							AutomaticSize = Enum.AutomaticSize.Y,
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.FredokaOne,
							TextSize = 12,
							TextWrapped = true,
							ZIndex = props.tutorialHighlight == "brew_button" and 999 or 1,
							[React.Event.Activated] = function()
								craft(craftResult and craftResult.PotionId, props.currentCauldron)
								props.close()
							end,
						}, {
							Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
							Padding = e("UIPadding", {
								PaddingTop = UDim.new(0, 5),
								PaddingBottom = UDim.new(0, 5),
							}),
							NewIndicator = craftResult and not potionBook[craftResult.PotionId] and e("TextLabel", {
								Size = UDim2.new(1, 0, 0, 20),
								Position = UDim2.new(0, 0, 1, 0),
								BackgroundColor3 = Color3.fromRGB(255, 200, 0),
								Text = "NEW!",
								TextColor3 = Color3.new(0, 0, 0),
								Font = Enum.Font.FredokaOne,
								TextSize = 10,
							}, {
								Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
							}),
						}),
						ResultText = e("TextLabel", {
							Size = UDim2.new(1, -10, 0, 30),
							Position = UDim2.new(0, 5, 1, -30),
							BackgroundTransparency = 1,
							Text = craftResult and craftResult.DisplayName or "No Result",
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.FredokaOne,
							TextSize = 12,
							TextWrapped = true,
						}),
					}),
				}),

				-- Available Items List
				ItemListLabel = e("TextLabel", {
					Size = UDim2.new(1, -20, 0, 30),
					Position = UDim2.new(0, 10, 0, 280),
					BackgroundTransparency = 1,
					Text = "Available Items (Click to add to slot)",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				ItemList = e("ScrollingFrame", {
					Size = UDim2.new(1, -20, 0, 170),
					Position = UDim2.new(0, 10, 0, 320),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderSizePixel = 0,
					ScrollBarThickness = 6,
					CanvasSize = UDim2.new(0, 0, 0, #itemButtons * 45),
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Layout = e("UIGridLayout", {
						CellSize = UDim2.new(0, 50, 0, 50),
						CellPadding = UDim2.new(0, 5, 0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
					Padding = e("UIPadding", {
						PaddingTop = UDim.new(0, 5),
						PaddingBottom = UDim.new(0, 5),
					}),
					Items = e(React.Fragment, nil, itemButtons),
				}),
			}),
		}),
	})
end

return Craft
