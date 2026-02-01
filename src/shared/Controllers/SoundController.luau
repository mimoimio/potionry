local SoundController = {}

-- Sound pool configuration
local POOL_SIZE = 5 -- Pre-create 5 instances of each sound
local soundPools = {} -- {SoundName = {available = {Sound}, inUse = {Sound}}}

-- Initialize a sound pool for a specific sound
local function initializeSoundPool(soundName: string, poolSize: number)
	local sourceSound = game.ReplicatedStorage.Shared.SFX:FindFirstChild(soundName)
	if not sourceSound then
		warn("Sound not found:", soundName)
		return
	end

	soundPools[soundName] = {
		available = {},
		inUse = {},
		source = sourceSound,
	}

	-- Pre-create and load sounds
	for i = 1, poolSize do
		local sound = sourceSound:Clone()
		sound.Parent = game.ReplicatedStorage -- Store in ReplicatedStorage until needed
		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end
		table.insert(soundPools[soundName].available, sound)
	end
end

-- Get a sound from the pool (or create new if pool is empty)
local function getSound(soundName: string): Sound?
	local pool = soundPools[soundName]
	if not pool then
		warn("Sound pool not initialized:", soundName)
		initializeSoundPool(soundName, POOL_SIZE)
		pool = soundPools[soundName]
	end

	local sound
	if #pool.available > 0 then
		-- Reuse from pool
		sound = table.remove(pool.available)
	else
		-- Pool exhausted, create new instance
		sound = pool.source:Clone()
		sound.Parent = game.ReplicatedStorage
		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end
	end

	table.insert(pool.inUse, sound)
	return sound
end

-- Return a sound to the pool
local function returnSound(soundName: string, sound: Sound)
	local pool = soundPools[soundName]
	if not pool then
		sound:Destroy()
		return
	end

	-- Remove from inUse
	local index = table.find(pool.inUse, sound)
	if index then
		table.remove(pool.inUse, index)
	end

	-- Reset sound properties and return to available pool
	sound:Stop()
	sound.Parent = game.ReplicatedStorage
	table.insert(pool.available, sound)
end

function SoundController.CashSound()
	task.spawn(function()
		local sound = getSound("Cash")
		if not sound then
			return
		end

		sound.Parent = game.Players.LocalPlayer.Character.Head
		sound:Play()
		sound.Ended:Wait()

		-- Return to pool
		returnSound("Cash", sound)
	end)
end
function SoundController.Sound(name: string)
	task.spawn(function()
		local sound = getSound(name)
		if not sound then
			return
		end

		sound.Parent = game.Players.LocalPlayer.Character.Head
		sound:Play()
		sound.Ended:Wait()

		-- Return to pool
		returnSound(name, sound)
	end)
end

function SoundController.initialize()
	-- Initialize sound pools for all sounds you want to pool
	initializeSoundPool("Cash", POOL_SIZE)
	initializeSoundPool("Placed", POOL_SIZE)
	initializeSoundPool("PickUp", POOL_SIZE)
	initializeSoundPool("TaDa", POOL_SIZE)
	initializeSoundPool("PixieDust", POOL_SIZE)
	-- Add more sounds here as needed:
	-- initializeSoundPool("OtherSound", POOL_SIZE)
end

return SoundController
