local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef

local function RemovePotionTool(props: { enabled: boolean })
	local toolRef = useRef()
	local connectionRef = useRef()

	useEffect(function()
		if not props.enabled then
			-- Clean up existing tool
			if toolRef.current then
				toolRef.current:Destroy()
				toolRef.current = nil
			end
			if connectionRef.current then
				connectionRef.current:Disconnect()
				connectionRef.current = nil
			end
			return
		end

		-- Create the tool
		local tool = Instance.new("Tool")
		tool.Name = "Remove Potion"
		tool.TextureId = ""
		tool.ToolTip = "Click a rack slot to remove a potion"
		tool.RequiresHandle = false
		tool.CanBeDropped = false

		-- Create handle (required for tools)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 1)
		handle.Transparency = 1
		handle.CanCollide = false
		handle.Parent = tool

		-- Weld tongs model to handle
		local tongsModel = game.ReplicatedStorage.Shared.Models.Tongs:Clone()
		tongsModel:PivotTo(handle:GetPivot() * CFrame.Angles(-math.pi / 2, 0, 0) + Vector3.new(0, 2, 0))
		tongsModel.Parent = handle

		for _, part in tongsModel:GetDescendants() do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = handle
			end
		end

		-- Handle activation
		local connection = tool.Activated:Connect(function()
			local player = game.Players.LocalPlayer
			local mouse = player:GetMouse()
			local target = mouse.Target

			if not target then
				warn("No target found")
				return
			end

			-- Check if target is a valid rack slot
			local parent = target.Parent
			if not parent or not parent.Name then
				warn("Invalid target parent")
				return
			end

			-- Match pattern Rack# and Slot#
			local rackMatch =  target:GetAttribute("RackNum") or nil
			local slotMatch =  target:GetAttribute("SlotNum") or nil

			if rackMatch and slotMatch then
				-- Extract rack ID and slot number
				local rackId = rackMatch
				local slotNum = slotMatch

				-- Fire to server to clear this slot
				local SetPotionSlot: RemoteEvent = game.ReplicatedStorage.Shared.Events:FindFirstChild("SetPotionSlot")
				if not SetPotionSlot then
					return
				end
				SetPotionSlot:FireServer(rackId, slotNum)

				-- Optional: Visual feedback
				-- local sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Ping")
				-- if sound and sound:FindFirstChildWhichIsA("Sound") then
				-- 	local soundClone = sound:FindFirstChildWhichIsA("Sound"):Clone()
				-- 	soundClone.Parent = player
				-- 	soundClone:Play()
				-- 	task.delay(1, function()
				-- 		soundClone:Destroy()
				-- 	end)
				-- end
			else
				warn("Target is not a valid rack slot")
			end
		end)

		connectionRef.current = connection
		toolRef.current = tool

		-- Equip the tool
		tool.Parent = game.Players.LocalPlayer.Backpack
		local conn = tool.Unequipped:Connect(function()
			props.toggle("none")
		end)
		game.Players.LocalPlayer.Character.Humanoid:EquipTool(tool)

		-- Cleanup function
		return function()
			if connectionRef.current then
				connectionRef.current:Disconnect()
				connectionRef.current = nil
			end
			if conn then
				conn:Disconnect()
				conn = nil
			end
			if toolRef.current then
				toolRef.current:Destroy()
				toolRef.current = nil
			end
		end
	end, { props.enabled })

	return nil
end

return RemovePotionTool
