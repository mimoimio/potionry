local Signal = require(game.ReplicatedStorage.Packages.Signal)
local TweenService = game:GetService("TweenService")
local self = {}

local sunsetBindableEvent = Instance.new("BindableEvent")
self.Sunset = sunsetBindableEvent.Event
local sunriseBindableEvent = Instance.new("BindableEvent")
self.Sunrise = sunriseBindableEvent.Event
local started = false

local morningTime = 6.5

function self.initialize()
	self.SpecialEventStarted = Signal.new()
	self.StartSpecialEvent = Signal.new()
end

local SecondsPerDay = 5 * 6 * 60 -- 30 mins

function self.start()
	if started then
		return
	end
	self.SecondsPerDay = SecondsPerDay
	self.CurrentTime = game.Lighting.ClockTime
	self.IsMorning = game.Lighting.ClockTime >= morningTime and game.Lighting.ClockTime < 18 or false
	if self.IsMorning then
		Sunrise()
	end
	local ss = require(game.ServerScriptService.Server.Services.ShopService)

	local ShopService = require(script.Parent.ShopService)
	local eventOn = false
	local previousSeed = nil
	task.spawn(function()
		while true do
			task.wait(1)
			local cs = ss.getCurrentState()

			-- Check if shop seed changed
			if previousSeed and cs.seed ~= previousSeed then
				ss.notifyRefresh()
			end
			previousSeed = cs.seed

			for i, player in game:GetService("Players"):GetPlayers() do
				ShopService.GetCurrentShopItems(player)
			end

			-- Edge-detect isSpecial and pass seed + state
			if cs.isSpecial and not eventOn then
				eventOn = true
				self.StartSpecialEvent:Fire(cs.seed, true)
			elseif (not cs.isSpecial) and eventOn then
				eventOn = false
				self.StartSpecialEvent:Fire(cs.seed, false)
			end

			self.TimeIncrement()
		end
	end)
	started = true
end

function Sunset()
	TweenService:Create(game.Lighting, TweenInfo.new(1), {
		OutdoorAmbient = Color3.new(0.4, 0.3, 1),
		Brightness = 0,
	}):Play()
	sunsetBindableEvent:Fire()
end

function Sunrise()
	TweenService:Create(game.Lighting, TweenInfo.new(1), {
		OutdoorAmbient = Color3.new(1, 0.8, 0.5),
		Brightness = 1,
	}):Play()
	sunriseBindableEvent:Fire()
end
local minPerGameDay = SecondsPerDay / 60
local secPerGameHour = minPerGameDay / ((1 / 60) / (1 / 24))
function self.TimeIncrement()
	local clockNow = (((workspace:GetServerTimeNow()) / secPerGameHour) % 24)
	game.Lighting.ClockTime = clockNow
	if game.Lighting.ClockTime >= morningTime and game.Lighting.ClockTime < 18 and not self.IsMorning then
		Sunrise()
		self.IsMorning = true
		if game.Lighting.ClockTime <= 8 then
			local sound = Instance.new("Sound", workspace)
			sound.SoundId = "rbxassetid://4096049827"
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end
			sound:Play()
			task.delay(sound.TimeLength, function()
				sound:Destroy()
			end)
		end
	elseif ((game.Lighting.ClockTime >= 19.5) or (game.Lighting.ClockTime < morningTime)) and self.IsMorning then
		self.IsMorning = false
		Sunset()
	end
end

return self
