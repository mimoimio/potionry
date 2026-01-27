local variationcolor = {
	-- none = Color3.fromRGB(255, 255, 255), -- White (default)
	copper = Color3.fromRGB(255, 140, 80), -- Copper/orange
	silver = Color3.fromRGB(220, 220, 240), -- Silver/grey-blue
	gold = Color3.fromRGB(255, 230, 120), -- Golden yellow
	diamond = Color3.fromRGB(120, 240, 255), -- Diamond cyan
	strange = Color3.fromRGB(200, 100, 255), -- Purple/magenta
	starlight = Color3.fromRGB(160, 160, 255), -- Deep blue
}
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local useRobloxInventory = require(script.Parent.useRobloxInventory)
local PotionViewport = require(script.Parent.PotionViewport)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

-- Constants
local ROWS = 6
local COLS = 9
local TOTAL_SLOTS = ROWS * COLS
local HOTBAR_SLOTS = 9
local SLOT_SIZE = 65
local PADDING = 5
local PLAYER_GUI = Players.LocalPlayer.PlayerGui
local DRAG_THRESHOLD = 15 -- Pixels mouse must move before drag starts

local function Slot(props: {
	i: number,
	bgColor: Color3,
	borderColor: Color3,
	borderSize: number,
	isTarget: boolean,
	tool: Tool,
	displayName: string,
	onSlotInputBegan: () -> (),
})
	local i = props.i
	local bgColor = props.bgColor
	local borderColor = props.borderColor
	local borderSize = props.borderSize
	local isTarget = props.isTarget
	local tool = props.tool
	local displayName = props.displayName
	local onSlotInputBegan = props.onSlotInputBegan

	local version, setVersion = useState(0)
	useEffect(function()
		if not tool then
			return
		end
		local conn2 = tool:GetAttributeChangedSignal("RateString"):Connect(function()
			setVersion(version + 1)
			-- warn("RateString CHANGED")
		end)
		return function()
			if conn2 then
				conn2:Disconnect()
			end
		end
	end, { tool })

	local PotionId = tool and tool:GetAttribute("PotionId")
	local RateString = tool and tool:GetAttribute("RateString")

	return e("Frame", {
		key = "Slot_" .. i,
		LayoutOrder = i,
		BackgroundColor3 = bgColor,
		BorderColor3 = borderColor,
		BorderSizePixel = borderSize,
		ZIndex = isTarget and 5 or 1,
	}, {
		Content = tool and e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Viewport = e(PotionViewport, {
				PotionId = PotionId,
				DisplayName = displayName,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				RateString = RateString,
			}),
			Button = e("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 3,
				[React.Event.InputBegan] = function(rbx, input)
					onSlotInputBegan(input, i)
				end,
			}),
		}) or e("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			[React.Event.InputBegan] = function(rbx, input)
				-- allows dropping ONTO empty slots, but not dragging FROM them
			end,
		}),
	})
end

local function InventoryApp(props)
	-- 1. Data State
	local inventory, setInventory = useRobloxInventory(TOTAL_SLOTS)

	-- 2. UI State
	local isOpen = props.InventoryOpen
	local isVisible, setIsVisible = useState(true)

	-- 3. Dragging & Input State
	local isDragging, setIsDragging = useState(false)
	local isMouseDown, setIsMouseDown = useState(false) -- New: Track if button is held
	local dragStartPos, setDragStartPos = useState(Vector2.zero) -- New: Track where we clicked

	local dragSourceIndex, setDragSourceIndex = useState(nil)
	local dragTargetIndex, setDragTargetIndex = useState(nil)
	local ghostRef = useRef(nil)

	-- =================================================================================
	-- Logic: Equip / Unequip
	-- =================================================================================
	local function toggleEquip(tool)
		if not tool then
			return
		end
		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if not hum then
			return
		end

		if tool.Parent == char then
			hum:UnequipTools()
		else
			hum:EquipTool(tool)
		end
	end

	-- =================================================================================
	-- Logic: Sort Inventory
	-- =================================================================================
	local function sortInventory()
		setInventory(function(prev)
			local newInv = table.create(TOTAL_SLOTS, nil)
			local compactedTools = {}

			-- Collect all non-nil tools
			for i = 1, TOTAL_SLOTS do
				if prev[i] then
					table.insert(compactedTools, prev[i])
				end
			end

			-- Place them back starting from slot 1
			for i, tool in ipairs(compactedTools) do
				newInv[i] = tool
			end

			return newInv
		end)
	end

	-- =================================================================================
	-- Logic: Keybinds
	-- =================================================================================
	useEffect(function()
		task.spawn(function()
			local function handleHotbar(_, state, inputObject)
				if state == Enum.UserInputState.Begin then
					local keyVal = inputObject.KeyCode.Value
					local slotNum = keyVal - Enum.KeyCode.One.Value + 1
					if slotNum >= 1 and slotNum <= 9 then
						local tool = inventory[slotNum]
						if tool then
							toggleEquip(tool)
						end
					end
				end
			end

			local keyNames = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Zero" }
			for i, num in ipairs(keyNames) do
				ContextActionService:BindAction("Inv_Hotbar_" .. i, handleHotbar, false, Enum.KeyCode[num])
			end
		end)
		return function()
			for i = 1, 9 do
				ContextActionService:UnbindAction("Inv_Hotbar_" .. i)
			end
		end
	end, { inventory })

	-- =================================================================================
	-- Logic: Drag & Drop + Click Detection
	-- =================================================================================

	-- 1. Input Began (Just record the press, don't drag yet)
	local function onSlotInputBegan(input, index)
		if isDragging or isMouseDown then
			setIsDragging(false)
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			warn("MOUSE1 down")
			if inventory[index] then
				setIsMouseDown(true)
				setDragSourceIndex(index)
				setDragStartPos(UserInputService:GetMouseLocation()) -- Record start pos
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			-- Right click instant toggle
			local tool = inventory[index]
			if tool then
				toggleEquip(tool)
			end
		end
	end

	-- 2. Render Loop (Handle Threshold + Ghost Moving)
	useEffect(function()
		-- We run this if mouse is down (checking for drag start) OR if we are already dragging
		if not isMouseDown and not isDragging then
			return
		end

		local connection = RunService.RenderStepped:Connect(function()
			local mousePos = UserInputService:GetMouseLocation()

			-- Phase A: Check Threshold (Start Dragging?)
			if isMouseDown and not isDragging then
				local distance = (mousePos - dragStartPos).Magnitude
				if distance > DRAG_THRESHOLD then
					setIsDragging(true)
				end
			end

			-- Phase B: If Dragging, Update Visuals
			if isDragging then
				-- Update Ghost
				if ghostRef.current then
					ghostRef.current.Position =
						UDim2.fromOffset(mousePos.X - (SLOT_SIZE / 2), mousePos.Y - (SLOT_SIZE / 2))
				end

				-- Update Detection
				local topBarOffset = GuiService:GetGuiInset()
				local detectionY = mousePos.Y - topBarOffset.Y
				local objects = PLAYER_GUI:GetGuiObjectsAtPosition(mousePos.X, detectionY)

				local foundIndex = nil
				for _, obj in ipairs(objects) do
					if obj.Name:match("Slot_") and obj.LayoutOrder then
						foundIndex = obj.LayoutOrder
						break
					end
				end
				setDragTargetIndex(foundIndex)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { isMouseDown, isDragging, dragStartPos })

	-- 3. Input Ended (Decide: Was it a Click or a Drop?)
	useEffect(function()
		if not isMouseDown then
			return
		end -- Only care if we started an interaction

		local inputConnection = UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if isDragging then
					-- SCENARIO A: We were dragging -> Perform Drop
					local finalTarget = dragTargetIndex
					if finalTarget and finalTarget ~= dragSourceIndex then
						setInventory(function(prev)
							local newInv = table.clone(prev)
							local sourceTool = newInv[dragSourceIndex]
							local targetTool = newInv[finalTarget]
							newInv[finalTarget] = sourceTool
							newInv[dragSourceIndex] = targetTool
							return newInv
						end)
					end
				else
					-- SCENARIO B: We never crossed the threshold -> Perform Click (Equip)
					if dragSourceIndex then
						local tool = inventory[dragSourceIndex]
						toggleEquip(tool)
					end
				end

				-- Reset ALL states
				setIsMouseDown(false)
				setIsDragging(false)
				setDragSourceIndex(nil)
				setDragTargetIndex(nil)
			end
		end)

		return function()
			inputConnection:Disconnect()
		end
	end, { isMouseDown, isDragging, dragSourceIndex, dragTargetIndex })

	-- =================================================================================
	-- Render
	-- =================================================================================
	local slots = {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
	}

	slots["Layout"] = e("UIGridLayout", {
		CellSize = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		CellPadding = UDim2.fromOffset(PADDING, PADDING),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local limit = isOpen and TOTAL_SLOTS or HOTBAR_SLOTS

	for i = 1, limit do
		local tool = inventory[i]
		local isSource = (isDragging and dragSourceIndex == i)
		local isTarget = (isDragging and dragTargetIndex == i and dragTargetIndex ~= dragSourceIndex)
		local variationId = tool and tool:GetAttribute("VariationId")
		local displayName = tool and tool:GetAttribute("DisplayName")
		local color = variationId and variationcolor[variationId] or nil

		-- Visuals
		local bgColor = i <= HOTBAR_SLOTS and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(40, 40, 40)
		if i <= HOTBAR_SLOTS then
			bgColor = Color3.fromRGB(60, 60, 60)
		end -- Slight darken for hotbar styling
		if color then
			bgColor = color
		end

		local toolName = tool and tool.Name or ""
		local isEquipped = tool and tool.Parent and tool.Parent:IsA("Model")

		local borderColor = Color3.fromRGB(0, 0, 0)
		local borderSize = 0

		if isTarget then
			borderColor = Color3.new(1, 1, 1)
			borderSize = 2
		elseif isEquipped then
			borderColor = Color3.fromRGB(0, 255, 0)
			borderSize = 2
		end

		slots["Slot_" .. i] = e(Slot, {
			i = i,
			bgColor = bgColor,
			borderColor = borderColor,
			borderSize = borderSize,
			isTarget = isTarget,
			tool = tool,
			displayName = displayName,
			onSlotInputBegan = onSlotInputBegan,
		})
	end

	local ghostElement = nil
	if isDragging and dragSourceIndex then
		local tool = inventory[dragSourceIndex]
		if tool then
			local ghostDisplayName = tool:GetAttribute("DisplayName")
			ghostElement = ReactRoblox.createPortal(
				e("ScreenGui", {
					DisplayOrder = 100,
					IgnoreGuiInset = true,
				}, {
					Ghost = e("Frame", {
						ref = ghostRef,
						Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
						BackgroundColor3 = Color3.fromRGB(60, 60, 60),
						BackgroundTransparency = 0.5,
						BorderSizePixel = 2,
						BorderColor3 = Color3.new(1, 1, 1),
					}, {
						Viewport = e(PotionViewport, {
							PotionId = tool.Name,
							DisplayName = ghostDisplayName,
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
						}),
					}),
				}),
				PLAYER_GUI
			)
		end
	end
	-- ... (Drag and Drop Logic above remains the same)

	-- =================================================================================
	-- Render: Main Container
	-- =================================================================================

	-- Calculate size based on open/closed state
	-- We add a little extra padding (+10) to the frame size so the slots don't touch the edge
	local totalWidth = (COLS * (SLOT_SIZE + PADDING)) + 10
	local totalHeight = isOpen and ((ROWS * (SLOT_SIZE + PADDING)) + 10) or ((1 * (SLOT_SIZE + PADDING)) + 10)

	return e("Frame", {
		-- 1. Positioning (Bottom Center)
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),

		-- 2. Sizing
		Size = UDim2.fromOffset(totalWidth, totalHeight),
		Visible = isVisible,
		-- 3. Styling
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = -10000,
	}, {
		-- A. The Close Button (Only render if Open)
		CloseButton = isOpen and e("TextButton", {
			Text = "X",
			Font = Enum.Font.FredokaOne,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(200, 60, 60),

			-- Top Right Corner
			Size = UDim2.fromOffset(40, 40),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -5, 0, -25), -- Floating just above the frame on the right
			-- OR if you want it INSIDE: Position = UDim2.new(1, -5, 0, 5),

			ZIndex = 10,
			[React.Event.Activated] = props.close, -- Triggers the prop function
		}),
		pack = e("TextButton", {
			Text = "🎒",
			Font = Enum.Font.FredokaOne,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(226, 118, 118),
			Size = UDim2.fromOffset(60, 60),
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.new(1, 5, 0, 0), -- Floating just above the frame on the right

			ZIndex = 10,
			[React.Event.Activated] = function()
				props.toggle("inventory")
			end, -- Triggers the prop function
		}),
		SortButton = e("TextButton", {
			Text = "Sort",
			Font = Enum.Font.FredokaOne,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(80, 120, 200),
			Size = UDim2.fromOffset(60, 40),
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.new(1, 5, 0, 65), -- Below the Pick Up Potion button

			ZIndex = 10,
			[React.Event.Activated] = sortInventory,
		}),

		-- B. The Slots Container (Wraps the grid)
		SlotsContainer = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			-- Slight padding so the slots aren't glued to the edges
			Position = UDim2.fromOffset(5, 5),
		}, slots), -- 'slots' contains the UIGridLayout + Item Frames

		-- C. The Ghost Portal
		Ghost = ghostElement,
	})
end

return InventoryApp
