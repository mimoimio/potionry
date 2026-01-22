local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)

local TycoonService = {}

function TycoonService.initialize()
	local Click = Instance.new("RemoteEvent", ReplicatedStorage.Shared.Events)
	Click.Name = "Click"
	Click.OnServerEvent:Connect(function(player)
		PlayerSessions.addPlayerCash(player, 1)
	end)
end

function TycoonService.start() end

return TycoonService
