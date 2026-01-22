-- Client/ClientStore.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FusionApp = require(script.FusionApp)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)

-- 1. Create the Receiver
local receiver = Reflex.createBroadcastReceiver({
	start = function()
		Remotes.start:FireServer()
	end,
})

Remotes.dispatch.OnClientEvent:Connect(function(actions)
	receiver:dispatch(actions)
end)

PlayerSessions:applyMiddleware(receiver.middleware)

local function selectCash(state: PlayerSessions.PlayersState)
	local session = state.players[game.Players.LocalPlayer]
	if not session then
		return
	end
	return session.Data.Cash
end

-- PlayerSessions:subscribe(selectCash, function(state, prevState)
-- 	warn("CASH:", state)
-- end)

FusionApp({
	Parent = game.Players.LocalPlayer.PlayerGui:WaitForChild("ScreenGui"),
})

-- FusionApp()
