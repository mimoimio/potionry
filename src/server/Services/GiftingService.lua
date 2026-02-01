local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)

local GiftingService = {}

-- Remote Events
local RequestGift = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
RequestGift.Name = "RequestGift"

local RespondToGift = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
RespondToGift.Name = "RespondToGift"

local ShowGiftConfirmation = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ShowGiftConfirmation.Name = "ShowGiftConfirmation"

local CancelGift = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
CancelGift.Name = "CancelGift"

-- Helper: Mount ProximityPrompt on character
local function mountProximityPrompt(character: Model, player: Player)
	-- Clean up existing gift prompts
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("ProximityPrompt") and child:HasTag("GiftPP") then
			child:Destroy()
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GiftPrompt"
	prompt.ActionText = "Gift Potion"
	prompt.ObjectText = player.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Enabled = false -- Disabled by default, enabled when potion is equipped
	prompt.Parent = character.PrimaryPart
		or character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChildWhichIsA("BasePart")

	CollectionService:AddTag(prompt, "GiftPP")
end

-- Handle character spawn
local function onCharacterAdded(character: Model, player: Player)
	-- Wait for humanoid root part
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		mountProximityPrompt(character, player)
	end
end

-- Handle player profile created
local function onProfileCreated(player: Player)
	-- Initialize Gifts field if not exists
	local state = PlayerSessions:getState()
	local playerData = state.players[player]
	if playerData and not playerData.Data.Gifts then
		PlayerSessions.setGifts(player, {})
	end

	-- Mount on current character if exists
	if player.Character then
		onCharacterAdded(player.Character, player)
	end

	-- Listen for character respawns
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)
end

-- Handle gift request from player1 to player2
local function onRequestGift(sender: Player, potionUID: string, receiver: Player)
	if not sender or not receiver or not potionUID then
		warn("[GiftingService] Invalid gift request parameters")
		return
	end

	-- Validate sender and receiver are different
	if sender == receiver then
		warn("[GiftingService] Cannot gift to yourself")
		return
	end

	-- Get player data from state
	local state = PlayerSessions:getState()
	local senderData = state.players[sender]
	local receiverData = state.players[receiver]

	if not senderData or not receiverData then
		warn("[GiftingService] Could not get player data")
		return
	end

	-- Validate sender owns the potion
	local potion = senderData.Data.Potions and senderData.Data.Potions[potionUID]
	if not potion then
		warn("[GiftingService] Sender does not own potion:", potionUID)
		return
	end

	-- Check if potion is placed in a slot
	for rackName, rack in pairs(senderData.Data.PotionSlots or {}) do
		for slotName, slotUID in pairs(rack) do
			if slotUID == potionUID then
				warn("[GiftingService] Cannot gift placed potion")
				return
			end
		end
	end

	-- Cancel any existing pending gift for receiver (only one at a time)
	local gifts = receiverData.Data.Gifts or {}
	if gifts[sender.UserId] then
		warn("[GiftingService] Replacing existing gift from", sender.Name)
	end

	-- Store pending gift in receiver's data
	PlayerSessions.addGift(receiver, sender.UserId, {
		PotionUID = potionUID,
		Timestamp = workspace:GetServerTimeNow(),
		SenderName = sender.Name,
	})

	-- Show confirmation UI to receiver
	ShowGiftConfirmation:FireClient(receiver, {
		SenderName = sender.Name,
		SenderUserId = sender.UserId,
		PotionId = potion.PotionId,
		VariationId = potion.VariationId,
		PotionUID = potionUID,
		Size = potion.Size,
	})

	-- print(string.format("[GiftingService] %s requested to gift potion to %s", sender.Name, receiver.Name))
end

-- Handle gift response from receiver
local function onRespondToGift(receiver: Player, senderUserId: number, accepted: boolean)
	if not receiver or not senderUserId then
		warn("[GiftingService] Invalid response parameters")
		return
	end

	local state = PlayerSessions:getState()
	local receiverData = state.players[receiver]
	if not receiverData then
		warn("[GiftingService] Could not get receiver data")
		return
	end

	-- Get pending gift data
	local giftData = receiverData.Data.Gifts and receiverData.Data.Gifts[senderUserId]
	if not giftData then
		warn("[GiftingService] No pending gift from user:", senderUserId)
		return
	end

	local sender = Players:GetPlayerByUserId(senderUserId)

	if not accepted then
		-- Gift declined
		PlayerSessions.removeGift(receiver, senderUserId)
		-- print(string.format("[GiftingService] %s declined gift from %s", receiver.Name, giftData.SenderName))
		return
	end

	-- Gift accepted - validate again
	if not sender then
		warn("[GiftingService] Sender no longer in game")
		PlayerSessions.removeGift(receiver, senderUserId)
		return
	end

	state = PlayerSessions:getState()
	local senderData = state.players[sender]
	if not senderData then
		warn("[GiftingService] Could not get sender data")
		PlayerSessions.removeGift(receiver, senderUserId)
		return
	end

	-- Validate sender still owns the potion
	local potion = senderData.Data.Potions and senderData.Data.Potions[giftData.PotionUID]
	if not potion then
		warn("[GiftingService] Sender no longer owns potion")
		PlayerSessions.removeGift(receiver, senderUserId)

		-- Notify receiver that gift is no longer available
		CancelGift:FireClient(receiver, "The potion is no longer available.")
		return
	end

	-- Check if potion is placed
	for rackName, rack in pairs(senderData.Data.PotionSlots or {}) do
		for slotName, slotUID in pairs(rack) do
			if slotUID == giftData.PotionUID then
				warn("[GiftingService] Potion is now placed, cannot gift")
				PlayerSessions.removeGift(receiver, senderUserId)
				CancelGift:FireClient(receiver, "The potion is now placed and cannot be gifted.")
				return
			end
		end
	end

	-- Execute transaction: Remove from sender, add to receiver
	PlayerSessions.removePotion(sender, giftData.PotionUID)

	-- Create new potion instance for receiver with same properties
	PlayerSessions.addPotion(receiver, {
		UID = potion.UID, -- Keep same UID for tracking
		PotionId = potion.PotionId,
		VariationId = potion.VariationId,
		Size = potion.Size,
	})

	-- Clear pending gift
	PlayerSessions.removeGift(receiver, senderUserId)

	-- print(string.format("[GiftingService] %s gifted potion to %s", sender.Name, receiver.Name))
end

function GiftingService.initialize()
	if GiftingService.isInitialized then
		return
	end
	GiftingService.isInitialized = true

	-- Initialize for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onProfileCreated(player)
	end

	-- Connect to new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(1) -- Wait for PlayerSessions to initialize player data
		onProfileCreated(player)
	end)

	-- Connect remote events
	RequestGift.OnServerEvent:Connect(onRequestGift)
	RespondToGift.OnServerEvent:Connect(onRespondToGift)

	-- print("[GiftingService] Initialized")
end

function GiftingService.start()
	-- Nothing to start
end

return GiftingService
