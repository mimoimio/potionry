local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)

local IngredientService = {}

function IngredientService.AddIngredient(player: Player, itemId: string, quantity: number)
	if not player or not itemId or not quantity then
		warn("[IngredientService] Invalid parameters")
		return false
	end

	-- Update ingredient using Reflex action
	PlayerSessions.updateIngredient(player, itemId, quantity)

	-- Notify client with flash effect
	local Flash = game.ReplicatedStorage.Shared.Events:FindFirstChild("Flash")
	if Flash and player.Character then
		local pos = player.Character:GetPivot().Position
		local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
		local itemConfig = ItemsConfig[itemId]
		local displayName = itemConfig and itemConfig.DisplayName or itemId
		Flash:FireClient(player, CFrame.new(pos), "+" .. quantity .. " " .. displayName .. "!")
	end

	-- Play purchase sound
	local donesound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Cash")
	if donesound then
		task.spawn(function()
			local sound = donesound:Clone()
			sound.Volume = 0.3
			sound.Parent = player
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end
			sound:Play()
			sound.Ended:Wait()
			task.wait(1)
			sound:Destroy()
		end)
	end

	return true
end

function IngredientService.initialize()
	-- Future: Add ingredient-related event handlers here
end

return IngredientService
