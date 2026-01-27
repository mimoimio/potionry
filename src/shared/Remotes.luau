-- ReplicatedStorage/Shared/Remotes.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local isserver = RunService:IsServer()
local function Start()
	local remote = isserver and Instance.new("RemoteEvent") or ReplicatedStorage.Shared.Events:WaitForChild("start") 
	remote.Name = "start"
	remote.Parent = ReplicatedStorage.Shared.Events
	return remote
end
local function Dispatch()
	local remote = isserver and Instance.new("RemoteEvent") or ReplicatedStorage.Shared.Events:WaitForChild("dispatch") 
	remote.Name = "dispatch"
	remote.Parent = ReplicatedStorage.Shared.Events
	return remote
end

return {
	start = Start() :: RemoteEvent,
	dispatch = Dispatch() :: RemoteEvent,
}
