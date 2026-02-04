local DATASTORENAME = "THROW_POTIONS"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStoreModule = require(game.ServerScriptService.Server.Modules.ProfileStore) -- Adjust path if needed
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Reflex = require(game.ReplicatedStorage.Packages.Reflex)
local PlayerSessions = require(ReplicatedStorage.Shared.producers.PlayerSessions)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Signal = require(game.ReplicatedStorage.Packages.Signal)

type Profile = ProfileStoreModule.Profile<PlayerData> -- Typed Profile object
export type PotionInstance = {
	UID: string,
	PotionId: string,
	VariationId: string,
	Size: number,
}

local Potions = {}
local PROFILE_TEMPLATE: PlayerSessions.Data = {
	Cash = 50,
	Cauldrons = {},
	Potions = Potions,
	PotionSlots = {},
	ThrownPotions = {},
	PotionBook = {},
	Ingredients = {
		daybloom = 0,
		blinkroot = 0,
		luckyclover = 0,
		moonglow = 0,
		glowshroom = 0,
		waterleaf = 0,
		fireblossom = 0,
	},
	Multipliers = {}, -- { [multiplierId]: { DisplayName, Value (bonus %), Expire } }
	Collectors = {},
	ShopCycles = {},
	TutorialFinished = false,
	Gifts = {},
}

local function selectPlayerData(player: Player)
	return function(state)
		return state.players[player] and state.players[player].Data
	end
end

-- 3. Create the ProfileStore object using New()
local PlayerProfileStore = ProfileStoreModule.New(
	DATASTORENAME, -- Your DataStore name
	PROFILE_TEMPLATE
)

-- 4. Cache for active player profiles on this server
local Profiles: { [Player]: Profile } = {}

-- Service module to return
local PlayerDataService = {}
PlayerDataService.PlayerSessions = {}
PlayerDataService.PROFILE_TEMPLATE = PROFILE_TEMPLATE

-- create bindable events
local ProfileCreated = Signal.new()
PlayerDataService.ProfileCreated = ProfileCreated

local ProfileSessionEnded = Signal.new()
PlayerDataService.ProfileSessionEnded = ProfileSessionEnded

-- Function to handle when a player joins the game
local function OnPlayerAdded(player: Player)
	local profileKey = tostring(player.UserId) -- Use UserId as the key

	-- Load and session-lock the profile asynchronously
	local profile: Profile? = PlayerProfileStore:StartSessionAsync(profileKey)
	print("profile", profileKey, profile)
	if profile then
		-- Add GDPR compliance UserIds (Recommended)
		profile:AddUserId(player.UserId)

		-- Fill in missing data fields from the template
		profile:Reconcile()

		-- Silent Migration: Infer HighestStep from owned ingredients (backfill for existing players)
		if (profile.Data.HighestStep or 0) == 0 and profile.Data.Resources and profile.Data.Resources.Ingredients then
			local ProgressionAnalytics = require(game.ServerScriptService.Server.Services.ProgressionAnalytics)
			local maxStep = 0

			for itemId, count in pairs(profile.Data.Resources.Ingredients) do
				if count and count > 0 then
					local step = ProgressionAnalytics.GetStepForItem(itemId)
					if step and step > maxStep then
						maxStep = step
					end
				end
			end

			if maxStep > 0 then
				profile.Data.HighestStep = maxStep
				print(
					string.format(
						"[Migration] Inferred HighestStep=%d for %s from owned ingredients",
						maxStep,
						player.Name
					)
				)
			end
		end

		-- Store the active profile in the cache
		Profiles[player] = profile

		-- Create leaderboard stats
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local cash = Instance.new("StringValue")
		cash.Name = "Cash"
		cash.Value = Mionum.new(profile.Data.Resources and profile.Data.Resources.Money or 0):toString()
		cash.Parent = leaderstats

		local Update = Instance.new("BindableEvent")
		Update.Name = "Update"
		Update.Parent = cash
		Update.Event:Connect(function(money: number)
			money = profile.Data.Resources.Money
			cash.Value = Mionum.new(money):toString()
		end)

		ProfileCreated:Fire()
	else
		-- The profile couldn't be loaded
		warn(`Critical error: Failed to load profile for {player.Name} ({player.UserId}). Kicking.`)
		-- player:Kick("Failed to load your data. Please try rejoining the server.")
	end
end

-- Function to handle when a player leaves the game
local function OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		-- End the session - this saves the data and unlocks the session
		profile:EndSession()
		print(`Ending session profile for {player.Name} ({player.UserId}) on leave.`)
	end
end

-- Function to handle server shutdown
local function OnShutdown()
	-- warn("Server shutting down. Ending sessions for all active player profiles...")
	local startTime = os.clock()

	-- Iterate through all active profiles and end sessions concurrently
	local threads = {}
	for player, profile in pairs(Profiles) do
		-- Check if the profile session is still active before trying to end it
		if profile:IsActive() then -- IsActive() is still valid
			table.insert(
				threads,
				task.spawn(function()
					profile:EndSession() -- Yields until saved and released
					print(`Profile session for {player.Name} ended during shutdown.`)
				end)
			)
		end
	end

	-- Wait for all end session threads to complete
	for _, thread in ipairs(threads) do
		task.wait(thread) -- Wait for each coroutine to finish
	end

	local duration = os.clock() - startTime
	warn(`All profile sessions ended. Shutdown process took {string.format("%.2f", duration)} seconds.`)
end

function PlayerDataService.initialize()
	PlayerDataService.initialized = true
	-- Connect Player events
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	-- Bind the shutdown function
	game:BindToClose(OnShutdown)
end

local broadcaster = Reflex.createBroadcaster({
	producers = {
		PlayerSessions = PlayerSessions,
	},
	dispatch = function(player, actions)
		local relevantActions = {}

		for _, action in actions do
			local targetPlayer = action.arguments[1]
			-- Logic:
			-- 1. If targetPlayer matches the current player (Private)
			-- 2. OR if targetPlayer is nil (Global - send to everyone)
			if targetPlayer == player or targetPlayer == nil then
				table.insert(relevantActions, action)
			end
		end

		if #relevantActions > 0 then
			Remotes.dispatch:FireClient(player, relevantActions)
		end
	end,
})

PlayerSessions:applyMiddleware(broadcaster.middleware)

Remotes.start.OnServerEvent:Connect(function(player)
	broadcaster:start(player)
	local profile
	local timeout = 10 -- seconds
	local elapsed = 0
	repeat
		profile = Profiles[player]
		task.wait(0.1)
		elapsed += 0.1
		if elapsed >= timeout then
			player:Kick("Failed to load your data. Please try rejoining.")
			return
		end
	until profile
	local PlotService = require(game.ServerScriptService.Server.Services.PlotService)
	local plot = PlotService.GetPlot(player)
	local character = player.Character or player.CharacterAdded:Wait()
	PlayerSessions.addPlayer(player, profile.Data, plot)
	local selectData = selectPlayerData(player)
	local unsubscribe = PlayerSessions:subscribe(selectData, function(state, prevData)
		profile.Data = state
	end)

	task.spawn(function()
		PlayerSessions.setCharacter(player, character)
	end)

	player.CharacterAdded:Connect(function(character)
		PlayerSessions.setCharacter(player, character)
	end)

	profile.OnSessionEnd:Connect(function()
		unsubscribe()
		PlotService.ReturnPlot(player)
		Profiles[player] = nil
		PlayerSessions.removePlayer(player)
		player:Kick("Your data session has ended. Please rejoin.")
		ProfileSessionEnded:Fire()
	end)
end)

-- Handle tutorial completion
local FinishTutorial = Instance.new("RemoteEvent")
FinishTutorial.Name = "FinishTutorial"
FinishTutorial.Parent = ReplicatedStorage.Shared.Events

FinishTutorial.OnServerEvent:Connect(function(player)
	local profile = Profiles[player]
	if not profile then
		-- warn("[PlayerDataService] No profile found for player:", player.Name)
		return
	end

	-- Mark tutorial as finished
	PlayerSessions.setTutorialFinished(player, true)
	print(string.format("[PlayerDataService] %s completed the tutorial!", player.Name))
end)

return PlayerDataService
