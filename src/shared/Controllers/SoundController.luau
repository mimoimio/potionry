local SoundController = {}
function SoundController.CashSound()
	local donesound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Cash")
	if donesound then
		task.spawn(function()
			local sound = donesound:Clone()
			sound.Volume = 0.3
			sound.Parent = game.Players.LocalPlayer.Character.Head
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end
			sound:Play()
			sound.Ended:Wait()
			task.wait(1)
			sound:Destroy()
		end)
	end
end
function SoundController.initialize() end
return SoundController
