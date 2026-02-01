local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThrowPanelProducer = require(ReplicatedStorage.Shared.producers.ThrowPanel)

local ThrowPotionController = {}

function ThrowPotionController.initialize()
	local player = Players.LocalPlayer

	-- Wait for RemoteEvents
	local PotionClicked = ReplicatedStorage.Shared.Events:WaitForChild("PotionClicked")
	local ThrowPotion = ReplicatedStorage.Shared.Events:WaitForChild("ThrowPotion")

	-- Track current state

	-- Subscribe to ThrowPanel state changes

	-- Listen for PotionClicked from server
	PotionClicked.OnClientEvent:Connect(function(potionUID)
		-- Check if throw panel is active and potion is equipped
		if ThrowPanelProducer:getState().panel == "throw" and ThrowPanelProducer:getState().equippedPotionUID then
			warn("s")
			local mouse = player:GetMouse()
			local hitCFrame = mouse.Hit
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local velocity = hrp and hrp.AssemblyLinearVelocity or Vector3.new()

			if hitCFrame then
				-- Fire to server for throwing
				ThrowPotion:FireServer(potionUID, hitCFrame, velocity)
			else
				warn("No target found for potion throw")
			end
		else
			warn(ThrowPanelProducer:getState())
		end
	end)
end

return ThrowPotionController
