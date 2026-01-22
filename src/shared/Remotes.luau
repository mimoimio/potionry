-- ReplicatedStorage/Shared/Remotes.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function Start()
	local remote = ReplicatedStorage.Shared.Events:FindFirstChild("start") or Instance.new("RemoteEvent")
	remote.Name = "start"
	remote.Parent = ReplicatedStorage.Shared.Events
	return remote
end
local function Dispatch()
	local remote = ReplicatedStorage.Shared.Events:FindFirstChild("dispatch") or Instance.new("RemoteEvent")
	remote.Name = "dispatch"
	remote.Parent = ReplicatedStorage.Shared.Events
	return remote
end

return {
	start = Start() :: RemoteEvent,
	dispatch = Dispatch() :: RemoteEvent,
}
