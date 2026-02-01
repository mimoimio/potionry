local ItemViewport = require(script.Parent.ItemViewport)
local PotionViewport = require(script.Parent.PotionViewport)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

local ItemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)

local IngredientsColor = {
	daybloom = Color3.new(0.9, 0.8, 0.4),
	blinkroot = Color3.new(0.6, 0.2, 0.1),
	luckyclover = Color3.new(0.2, 0.8, 0.4),
	glowshroom = Color3.new(0.2, 0.2, 0.8),
	bloodthorn = Color3.new(0.8, 0.2, 0.6),
	spiralaloe = Color3.new(0.1, 0.9, 0.2),
	waterleaf = Color3.new(0.2, 0.3, 0.9),
	fireblossom = Color3.new(0.9, 0.2, 0.1),
}
-- Constants
local DRAG_THRESHOLD = 15

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
	CraftPotion:FireServer(resultId, currentCauldron)
end

type CraftProps = {
	CraftOpen: boolean,
	close: () -> nil,
	currentCauldron: string?,
	PotionBook: { [string]: boolean }?,
	tutorialHighlight: string?,
	PlayerData: any,
}

local function ListItem(props)
	useEffect(function()
		local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
		SoundController.Sound("Placed")
		return function()
			SoundController.Sound("PickUp")
		end
	end, {})
	return e("Frame", {
		Size = UDim2.new(0, 90, 0, 90),
		BackgroundColor3 = Color3.fromRGB(80, 120, 80),
		LayoutOrder = props.index,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Viewport = e(ItemViewport, {
			ItemId = props.itemId,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}),
		NumberLabel = e("TextLabel", {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			Text = tostring(props.index),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.FredokaOne,
			TextSize = 14,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		}),
		RemoveButton = e("TextButton", {
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(200, 50, 50),
			Text = "X",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.FredokaOne,
			TextSize = 16,
			ZIndex = 5,
			[React.Event.Activated] = function()
				props.onSlotClicked(props.index)
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		}),
	})
end
local function ListContainer(props)
	local addedIngredients = props.addedIngredients
	local onSlotClicked = props.onSlotClicked
	local children = {
		Layout = e("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for index, itemId in ipairs(addedIngredients or {}) do
		children["Slot" .. index] = e(ListItem, {
			key = itemId,
			index = index,
			itemId = itemId,
			onSlotClicked = onSlotClicked,
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, -16, 1, -48),
		Position = UDim2.new(0, 8, 0, 40),
		BackgroundTransparency = 1,
	}, children)
end

local function Craft(props: CraftProps)
	-- State
	local addedIngredients, setAddedIngredients = useState({} :: { string })
	local craftResult, setCraftResult = useState(nil)
	local Ingredients: { [string]: number }, setIngredients = useState(nil)
	local potionBook = props.PotionBook or {}

	-- Dragging state
	local isDragging, setIsDragging = useState(false)
	local isMouseDown, setIsMouseDown = useState(false)
	local dragStartPos, setDragStartPos = useState(Vector2.zero)
	local dragSourceItemId, setDragSourceItemId = useState(nil :: string?)
	local dragTargetSlot, setDragTargetSlot = useState(nil :: number?)
	local hoveredItemId, setHoveredItemId = useState(nil :: string?)
	local ghostRef = useRef(nil)
	local originalCameraRef = useRef(nil)
	local playerGuiRef = useRef(nil)
	local dragTimeoutRef = useRef(nil)

	-- Initialize PlayerGui reference (works in both play and edit mode)
	useEffect(function()
		if Players.LocalPlayer then
			playerGuiRef.current = Players.LocalPlayer.PlayerGui
		else
			-- In edit mode (stories), find the ScreenGui ancestor
			-- This will be set when the component mounts in a story target
			local coreGui = game:GetService("CoreGui")
			playerGuiRef.current = coreGui
		end
	end, {})

	-- useEffect(function()
	-- 	warn("ingredients", Ingredients, PlayerSessions:getState())
	-- end, { Ingredients })
	useEffect(function()
		local insidePart, originalColor
		local transparencyTween, colorTween

		if
			dragTargetSlot and #addedIngredients < 3
			or (dragSourceItemId and table.find(addedIngredients, dragSourceItemId))
		then
			local state = PlayerSessions:getState()
			local playerSession = state.players[game.Players.LocalPlayer]
			local plot = playerSession and playerSession.Plot
			local cauldrons = plot and plot:FindFirstChild("Cauldrons")
			local cauldron = cauldrons and cauldrons:FindFirstChild(props.currentCauldron)
			insidePart = cauldron and cauldron:FindFirstChild("Cauldron") and cauldron.Cauldron:FindFirstChild("Inside")

			if not insidePart then
				return
			end

			-- Store original color
			originalColor = insidePart.Color

			-- Tween transparency to visible
			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			transparencyTween = TweenService:Create(insidePart, tweenInfo, { Transparency = 0 })
			transparencyTween:Play()

			-- Tween color change
			local newColor = IngredientsColor[dragSourceItemId] or Color3.new(1, 1, 1)
			colorTween = TweenService:Create(insidePart, tweenInfo, { Color = newColor })
			colorTween:Play()
		end

		return function()
			-- Cancel any running tweens
			if transparencyTween then
				transparencyTween:Cancel()
			end
			if colorTween then
				colorTween:Cancel()
			end

			-- Restore original state with tween
			if insidePart and originalColor then
				local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local restoreTransparency = TweenService:Create(insidePart, tweenInfo, { Transparency = 1 })
				local restoreColor = TweenService:Create(insidePart, tweenInfo, { Color = originalColor })
				restoreTransparency:Play()
				restoreColor:Play()
			end
		end
	end, { dragTargetSlot })

	-- Camera manipulation on open/close
	useEffect(function()
		if not props.CraftOpen then
			-- Restore camera when closing
			if originalCameraRef.current then
				workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
				originalCameraRef.current = nil
			end
			return
		end

		-- Get cauldron model from PlayerSessions
		task.spawn(function()
			local state = PlayerSessions:getState()
			-- Handle both real players and mock players
			local player = Players.LocalPlayer
			if not player then
				-- In edit mode, find the mock player in state
				for p, _ in pairs(state.players) do
					player = p
					break
				end
			end

			local playerSession = player and state.players[player]
			if playerSession and playerSession.Plot and props.currentCauldron then
				local cauldronFolder = playerSession.Plot.Cauldrons:FindFirstChild(props.currentCauldron)
				if cauldronFolder then
					local cauldronModel = cauldronFolder:FindFirstChild("Cauldron")
					if cauldronModel then
						-- Store original camera type
						originalCameraRef.current = workspace.CurrentCamera.CameraType

						-- Set camera to scriptable
						workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

						-- Position camera relative to cauldron
						local cauldronCFrame = cauldronModel:GetPivot()
						local cameraOffset = Vector3.new(03, 7, 0)
						local cf = cauldronCFrame:ToWorldSpace(CFrame.new(cameraOffset))
						workspace.CurrentCamera.CFrame =
							CFrame.lookAt(cf.Position, cauldronCFrame.Position + Vector3.new(0, 4, 0))
					end
				end
			end
		end)

		return function()
			-- Cleanup: restore camera
			if originalCameraRef.current then
				workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
				originalCameraRef.current = nil
			end
		end
	end, { props.CraftOpen, props.currentCauldron })

	-- Subscribe to Reflex state for ingredients
	useEffect(function()
		-- Handle both real players and mock players
		local player = game.Players.LocalPlayer
		if not player then
			-- In edit mode, find the mock player in state
			local state = PlayerSessions:getState()
			for p, _ in pairs(state.players) do
				player = p
				break
			end
		end

		if not player then
			return
		end

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

	-- Whenever added ingredients change, try to craft
	useEffect(function()
		if #addedIngredients > 0 then
			local result = CraftingModule:Craft(addedIngredients)
			setCraftResult(result)
		else
			setCraftResult(nil)
		end
	end, { addedIngredients })

	-- Clear slots if ingredients run out
	useEffect(function()
		if not Ingredients then
			return
		end
		local filtered = {}
		for _, itemId in ipairs(addedIngredients) do
			if Ingredients[itemId] and Ingredients[itemId] > 0 then
				table.insert(filtered, itemId)
			end
		end
		if #filtered ~= #addedIngredients then
			setAddedIngredients(filtered)
		end
	end, { Ingredients, addedIngredients })

	-- Reset slots when closing
	useEffect(function()
		if props.CraftOpen then
			return
		end
		setAddedIngredients({})
	end, { props.CraftOpen })

	local minimized = props.activePanel == "none" or props.activePanel == "shop"
	-- Drag and drop handlers
	local function onIngredientInputBegan(input, itemId)
		if isDragging or isMouseDown or minimized then
			-- warn("CANCEL isDragging or isMouseDown or minimized", isDragging or isMouseDown or minimized)
			-- warn("CANCEL isDragging , isMouseDown , minimized", isDragging, isMouseDown, minimized)
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if Ingredients and Ingredients[itemId] and Ingredients[itemId] > 0 then
				-- Check if already used in slots
				local usedCount = 0
				for _, addedId in ipairs(addedIngredients) do
					if addedId == itemId then
						usedCount = usedCount + 1
					end
				end
				if Ingredients[itemId] - usedCount > 0 then
					setIsMouseDown(true)
					setDragSourceItemId(itemId)
					setDragStartPos(UserInputService:GetMouseLocation())
				end
			end
		end
	end

	local function onSlotClicked(index)
		-- Remove ingredient from slot at index
		local newIngredients = {}
		for i, itemId in ipairs(addedIngredients) do
			if i ~= index then
				table.insert(newIngredients, itemId)
			end
		end
		setAddedIngredients(newIngredients)
	end

	-- Render Loop: Handle threshold + ghost moving + target detection
	useEffect(function()
		if not isMouseDown and not isDragging then
			return
		end

		local connection = RunService.RenderStepped:Connect(function()
			-- Safety check: if we're in drag state but mouse isn't actually pressed, reset
			if
				(isMouseDown or isDragging)
				and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			then
				-- warn("[Craft] Safety reset: drag state active but mouse not pressed")
				setIsMouseDown(false)
				setIsDragging(false)
				setDragSourceItemId(nil)
				setDragTargetSlot(nil)
				if dragTimeoutRef.current then
					task.cancel(dragTimeoutRef.current)
					dragTimeoutRef.current = nil
				end
				return
			end

			local mousePos = UserInputService:GetMouseLocation()

			-- Phase A: Check threshold
			if isMouseDown and not isDragging then
				local distance = (mousePos - dragStartPos).Magnitude
				if distance > DRAG_THRESHOLD then
					setIsDragging(true)
					-- Start timeout to auto-reset if drag gets stuck
					if dragTimeoutRef.current then
						task.cancel(dragTimeoutRef.current)
					end
					dragTimeoutRef.current = task.delay(3, function()
						warn("[Craft] Timeout: force resetting drag state")
						setIsMouseDown(false)
						setIsDragging(false)
						setDragSourceItemId(nil)
						setDragTargetSlot(nil)
						dragTimeoutRef.current = nil
					end)
				end
			end

			-- Phase B: Update ghost and detect target
			if isDragging then
				if ghostRef.current then
					ghostRef.current.Position = UDim2.fromOffset(mousePos.X - 30, mousePos.Y - 30)
				end

				-- Detect drop zone target
				local topBarOffset = GuiService:GetGuiInset()
				local detectionY = mousePos.Y - topBarOffset.Y
				local objects = playerGuiRef.current
						and playerGuiRef.current:GetGuiObjectsAtPosition(mousePos.X, detectionY)
					or {}
				local foundDropZone = false
				for _, obj in ipairs(objects) do
					if obj.Name == "IngredientDropZone" then
						foundDropZone = true
						break
					end
				end
				setDragTargetSlot(foundDropZone and 1 or nil)
			end
		end)

		return function()
			connection:Disconnect()
			if dragTimeoutRef.current then
				task.cancel(dragTimeoutRef.current)
				dragTimeoutRef.current = nil
			end
		end
	end, { isMouseDown, isDragging, dragStartPos })

	-- Input Ended: Drop or ignore
	useEffect(function()
		if not isMouseDown then
			-- Ensure dragTargetSlot is cleared when not dragging
			if dragTargetSlot ~= nil then
				setDragTargetSlot(nil)
			end
			return
		end

		local inputConnection = UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if isDragging and dragTargetSlot and dragSourceItemId then
					-- Check if ingredient already exists in array (prevent duplicates)
					local alreadyExists = false
					for _, itemId in ipairs(addedIngredients) do
						if itemId == dragSourceItemId then
							alreadyExists = true
							break
						end
					end

					if not alreadyExists and #addedIngredients < 3 then
						local newIngredients = table.clone(addedIngredients)
						table.insert(newIngredients, dragSourceItemId)
						setAddedIngredients(newIngredients)
					end
				end
				-- Reset all drag state
				setIsMouseDown(false)
				setIsDragging(false)
				setDragSourceItemId(nil)
				setDragTargetSlot(nil)
				-- Cancel timeout since drag completed normally
				if dragTimeoutRef.current then
					task.cancel(dragTimeoutRef.current)
					dragTimeoutRef.current = nil
				end
			end
		end)

		return function()
			inputConnection:Disconnect()
		end
	end, { isMouseDown, isDragging, dragSourceItemId, dragTargetSlot, addedIngredients })

	useEffect(function()
		-- warn("isMouseDown, isDragging,", isMouseDown, ",", isDragging)
	end, { isMouseDown, isDragging })
	-- Create list of available items from ItemConfigs
	local itemButtons = {}
	for i, config in ipairs(ItemConfigs) do
		local amt = (Ingredients and Ingredients[config.ItemId] or 0)
		-- Calculate available amount (subtract what's in slots)
		local usedCount = 0
		for _, itemId in ipairs(addedIngredients) do
			if itemId == config.ItemId then
				usedCount = usedCount + 1
			end
		end
		amt = math.max(0, amt - usedCount)

		local isHovered = hoveredItemId == config.ItemId
		local isDraggingThis = dragSourceItemId == config.ItemId
		local isHighlighted = isHovered or isDraggingThis

		itemButtons[config.ItemId] = e("Frame", {
			Name = config.ItemId,
			Size = UDim2.new(0, 32, 0, 32),
			BackgroundColor3 = isHighlighted and Color3.fromRGB(100, 140, 100) or Color3.fromRGB(60, 60, 60),
			BorderSizePixel = isHighlighted and 2 or 0,
			BorderColor3 = isHighlighted and Color3.fromRGB(150, 200, 150) or Color3.fromRGB(60, 60, 60),
			LayoutOrder = config.Rate,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Viewport = e(ItemViewport, {
				ItemId = config.ItemId,
				Size = UDim2.new(1, 0, 1, -14),
				BackgroundTransparency = 1,
				ImageTransparency = amt <= 0 and 0.8 or 0,
			}),
			AmountLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 14),
				Position = UDim2.new(0, 0, 1, -14),
				BackgroundTransparency = 1,
				Text = tostring(amt),
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = minimized and 12 or 24,
			}),
			Button = e("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Active = amt > 0,
				[React.Event.InputBegan] = function(rbx, input)
					onIngredientInputBegan(input, config.ItemId)
				end,
				[React.Event.MouseEnter] = function()
					if amt > 0 then
						setHoveredItemId(config.ItemId)
					end
				end,
				[React.Event.MouseLeave] = function()
					setHoveredItemId(nil)
				end,
			}),
		})
	end

	-- Ghost element for dragging
	local ghostElement = nil
	if isDragging and dragSourceItemId then
		ghostElement = ReactRoblox.createPortal(
			e("ScreenGui", {
				DisplayOrder = 100,
				IgnoreGuiInset = true,
			}, {
				Ghost = e("Frame", {
					ref = ghostRef,
					Size = UDim2.fromOffset(60, 60),
					BackgroundColor3 = Color3.fromRGB(60, 60, 60),
					BackgroundTransparency = 0.5,
					BorderSizePixel = 2,
					BorderColor3 = Color3.new(1, 1, 1),
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Viewport = e(ItemViewport, {
						ItemId = dragSourceItemId,
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
					}),
				}),
			}),
			playerGuiRef.current or game:GetService("CoreGui")
		)
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = minimized or props.CraftOpen,
		ZIndex = 10,
	}, {
		-- Ingredient Grid (Left side)
		IngredientsPanel = e("Frame", {
			Size = UDim2.new(0, minimized and 210 or 260, 0, 260),
			Position = props.CraftOpen and UDim2.new(0.5, -120, 0.5, 0) or UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(props.CraftOpen and 1 or 0, 0.5),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0.3,
			Visible = minimized or props.CraftOpen,
			Active = not minimized,
		}, {
			-- Close Button (Top Left)
			CloseButton = e("TextButton", {
				Size = UDim2.new(0, 44, 0, 44),
				Visible = not minimized,
				Position = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(200, 50, 50),
				AnchorPoint = Vector2.new(1, 1),
				Text = "Exit",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 20,
				[React.Event.Activated] = props.close,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}),

			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Title = e("TextLabel", {
				Size = UDim2.new(1, -16, 0, 32),
				Position = UDim2.new(0, 8, 0, 8),
				BackgroundTransparency = 1,
				Text = "INGREDIENTS",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
			ScrollingFrame = e("ScrollingFrame", {
				Size = UDim2.new(1, -16, 1, -48),
				Position = UDim2.new(0, 8, 0, 40),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				Active = not minimized,
				Interactable = not minimized,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				ScrollBarThickness = minimized and 12 or 28,
				VerticalScrollBarInset = "Always",
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Layout = e("UIGridLayout", {
					CellSize = UDim2.new(0, minimized and 50 or 65, 0, minimized and 50 or 65),
					CellPadding = UDim2.new(0, 3, 0, 3),
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				Padding = e("UIPadding", {
					PaddingTop = UDim.new(0, 3),
					PaddingBottom = UDim.new(0, 3),
					PaddingLeft = UDim.new(0, 3),
					PaddingRight = UDim.new(0, 3),
				}),
				Items = e(React.Fragment, nil, itemButtons),
			}),
		}),

		-- Center: Drop Zone + Craft Button
		CraftingArea = e("Frame", {
			Size = UDim2.new(0, 240, 0, 400),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Visible = props.CraftOpen,
		}, {
			-- Drop Zone
			DropZone = e("Frame", {
				Name = "IngredientDropZone",
				Size = UDim2.new(0, 200, 0, 200),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BackgroundTransparency = 1,

				BorderSizePixel = dragTargetSlot and 3 or 2,
				BorderColor3 = dragTargetSlot and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 100),
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Label = e("TextLabel", {
					Size = UDim2.new(1, 0, 0, 40),
					AutomaticSize = Enum.AutomaticSize.Y,
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 1),
					TextStrokeColor3 = Color3.new(0, 0, 0),
					TextStrokeTransparency = 0,
					Text = #addedIngredients < 3 and "Drag ingredients into the cauldron" or "Cauldron filled!",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.FredokaOne,
					TextSize = 16,
					TextWrapped = true,
				}),
				CraftButton = e("TextButton", {
					Size = UDim2.new(0, 160, 0, 44),
					Position = UDim2.new(0.5, 0, 1, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = craftResult and Color3.fromRGB(56, 120, 90) or Color3.fromRGB(80, 80, 80),
					Text = craftResult and "BREW" or "No Recipe",
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.FredokaOne,
					TextSize = 16,
					Active = craftResult ~= nil,
					ZIndex = props.tutorialHighlight == "brew_button" and 999 or 1,
					[React.Event.Activated] = function()
						if craftResult then
							craft(craftResult.PotionId, props.currentCauldron)
							props.close()
						end
					end,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
				}),
			}),

			-- Result Display + Craft Button
			ResultArea = e("Frame", {
				Size = UDim2.new(1, 0, 0, 160),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}, {
				ResultViewport = craftResult and e("Frame", {
					Size = UDim2.new(0, 110, 0, 100),
					Position = UDim2.new(0.5, 0, 0, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.fromRGB(120, 80, 120),
					BackgroundTransparency = 0.3,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Viewport = e(PotionViewport, {
						PotionId = craftResult.PotionId,
						DisplayName = craftResult.DisplayName,
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
					}),
					NewIndicator = not potionBook[craftResult.PotionId] and e("TextLabel", {
						Size = UDim2.new(0, 48, 0, 18),
						Position = UDim2.new(1, -52, 0, -22),
						BackgroundColor3 = Color3.fromRGB(255, 200, 0),
						Text = "NEW!",
						TextColor3 = Color3.new(0, 0, 0),
						Font = Enum.Font.FredokaOne,
						TextSize = 10,
					}, {
						Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
					}),
				}),
			}),
		}),

		-- Right: Ingredient List
		IngredientsListPanel = e("Frame", {
			Size = UDim2.new(0, 120, 0, 350),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 180, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			Visible = props.CraftOpen,
			BackgroundTransparency = 0.3,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Title = e("TextLabel", {
				Size = UDim2.new(1, -16, 0, 32),
				Position = UDim2.new(0, 8, 0, 8),
				BackgroundTransparency = 1,
				Text = "ADDED",
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
			ListContainer = e(ListContainer, {
				addedIngredients = addedIngredients,
				onSlotClicked = onSlotClicked,
			}),
		}),

		-- Ghost portal
		Ghost = ghostElement,
	})
end

return Craft
