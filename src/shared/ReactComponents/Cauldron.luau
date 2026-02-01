local SoundService = game:GetService("SoundService")
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)
local React = require(game.ReplicatedStorage.Packages.React)
local Mionum = require(game.ReplicatedStorage.Packages.Mionum)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState
local CraftingModule = require(game.ReplicatedStorage.Shared.CraftingModule)
type Phase = "cooking" | "cookinglong" | "done" | "none"
local function CauldronItem(props)
	local now, setNow = useState(workspace:GetServerTimeNow())
	local phase: Phase, setPhase = useState(nil)
	local cookingsound = useRef(nil)
	local completionindicator = useRef(nil)
	local ingredientModelsRef = useRef({})
	local progressBarRef = useRef(nil)
	local proximityprompt: ProximityPrompt, setProximityPrompt = useState(nil)
	useEffect(function()
		if phase == "none" or phase == "done" then
			return
		end

		-- only run if needs to count til end
		local running = true
		task.spawn(function()
			while running do
				task.wait(1)
				setNow(workspace:GetServerTimeNow())
			end
		end)
		return function()
			if running then
				running = false
			end
		end
	end, { props.Cauldron, phase })

	useEffect(function()
		if not now then
			return
		end
		local conn, skipConn
		task.spawn(function()
			local cauldronModel = props.Plot.Cauldrons:WaitForChild(props.CauldronId):WaitForChild("Cauldron") :: Model
			local pp = cauldronModel:WaitForChild("Hitbox").ProximityPrompt
			setProximityPrompt(pp)
			pp.Enabled = props.activePanel ~= "craft"
			if props.Cauldron == "none" then
				pp.ActionText = "Craft"
				(pp :: ProximityPrompt).HoldDuration = 0
				pp.ObjectText = ""

				setPhase("none")
				if cookingsound.current then
					cookingsound.current:Stop()
					cookingsound.current = nil
				end
				if completionindicator.current then
					completionindicator.current:Destroy()
					completionindicator.current = nil
				end
				if progressBarRef.current then
					progressBarRef.current:Destroy()
					progressBarRef.current = nil
				end
				return
			end

			local config = CraftingModule.CraftingLookup[props.PotionId]
			local duration = config.Duration
			local done = workspace:GetServerTimeNow() > (props.StartTime + duration)
			local timeleft = math.abs((props.StartTime + duration) - workspace:GetServerTimeNow())

			if done then
				-- stop cooking
				pp.ActionText = "Pickup"
				pp.ObjectText = "Completed!"
				setPhase(function(prev)
					if prev == "cooking" or prev == "cookinglong" then
						local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
						SoundController.Sound("Done")
					end
					return "done"
				end)
				if not completionindicator.current then
					local model = game.ReplicatedStorage.Shared.Models.Potions:FindFirstChild(props.PotionId)
					model = model and model:Clone() or nil

					if props.Cauldron.Size then
						model:ScaleTo(1 + (props.Cauldron.Size - 1) / 3)
					end

					completionindicator.current =
						game.ReplicatedStorage.Shared.Models:FindFirstChild("Completion"):Clone()
					completionindicator.current:PivotTo(cauldronModel:GetPivot() + Vector3.new(0, 8, 0))
					if model then
						model.Parent = completionindicator.current
						model:PivotTo(completionindicator.current:GetPivot() + Vector3.new(0, -4, 0))
					end
					completionindicator.current.Parent = workspace
				end
				(pp :: ProximityPrompt).HoldDuration = 0
				if cookingsound.current then
					cookingsound.current:Stop()
					cookingsound.current = nil
				end
				if progressBarRef.current then
					progressBarRef.current:Destroy()
					progressBarRef.current = nil
				end
				-- Clean up ingredient models when done
				for _, model in ipairs(ingredientModelsRef.current) do
					if model and model.Parent then
						model:Destroy()
					end
				end
				ingredientModelsRef.current = {}
				-- warn("DONE!!!!!!")
			else
				-- start or continue cooking

				-- Render ingredients model (if not done already) when not done
				if #ingredientModelsRef.current == 0 then
					-- warn("RENDERING INGREDIENTS", ingredientModelsRef.current)
					-- Only render if we haven't already
					for i, ingredientId in ipairs(config.Ingredients) do
						local ingredientModel = game.ReplicatedStorage.Shared.Models:FindFirstChild(ingredientId)
						if ingredientModel then
							local clone = ingredientModel:Clone()

							-- Position ingredients in a circle around the cauldron
							local angle = (2 * math.pi / #config.Ingredients) * (i - 1)
							local radius = 3
							local offset = Vector3.new(math.cos(angle) * radius, 4, math.sin(angle) * radius)
							clone:PivotTo(cauldronModel:GetPivot() + offset)
							clone.Parent = cauldronModel

							if props.Cauldron.Size then
								clone:ScaleTo(1 + (props.Cauldron.Size - 1) / 3)
							end

							table.insert(ingredientModelsRef.current, clone)
							-- warn("INSERTED,", ingredientModelsRef.current)
						end
					end
				end
				(pp :: ProximityPrompt).ActionText = timeleft < 30 and "Brewing..." or "Skip?"
				(pp :: ProximityPrompt).HoldDuration = timeleft < 30 and 0 or 1
				pp.ObjectText = ([[%02s:%.02s]]):format(timeleft // 60, timeleft % 60)
				setPhase(timeleft < 30 and "cooking" or "cookinglong")
				if completionindicator.current then
					completionindicator.current:Destroy()
					completionindicator.current = nil
				end

				-- Create or update progress bar
				if not progressBarRef.current then
					local billboard = Instance.new("BillboardGui")
					billboard.Size = UDim2.new(6, 0, 0.5, 0)
					billboard.StudsOffset = Vector3.new(0, 6, 0)
					billboard.AlwaysOnTop = true
					billboard.Adornee = cauldronModel:FindFirstChild("Hitbox")
					billboard.Parent = cauldronModel

					local background = Instance.new("Frame")
					background.Size = UDim2.new(1, 0, 1, 0)
					background.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
					background.BorderSizePixel = 0
					background.Parent = billboard

					local progressBar = Instance.new("Frame")
					progressBar.Name = "Progress"
					progressBar.Size = UDim2.new(0, 0, 1, 0)
					progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
					progressBar.BorderSizePixel = 0
					progressBar.Parent = background

					local uiCorner1 = Instance.new("UICorner")
					uiCorner1.CornerRadius = UDim.new(0.2, 0)
					uiCorner1.Parent = background

					local uiCorner2 = Instance.new("UICorner")
					uiCorner2.CornerRadius = UDim.new(0.2, 0)
					uiCorner2.Parent = progressBar

					progressBarRef.current = billboard
				end

				-- Update progress bar
				if progressBarRef.current then
					local progress = 1 - (timeleft / duration)
					local progressBar = progressBarRef.current:FindFirstChild("Frame"):FindFirstChild("Progress")
					if progressBar then
						progressBar.Size = UDim2.new(progress, 0, 1, 0)
					end
				end
				if not cookingsound.current then
					local sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Cooking")
					task.spawn(function()
						cookingsound.current = sound:Clone()
						cookingsound.current.Parent = cauldronModel:WaitForChild("Hitbox")
						if not cookingsound.current.IsLoaded then
							cookingsound.current.Loaded:Wait()
						end
						(cookingsound.current :: Sound).Looped = true
						cookingsound.current:Play()
					end)
				end
			end
		end)
		return function()
			if conn then
				conn:Disconnect()
			end
			if skipConn then
				skipConn:Disconnect()
			end
			if progressBarRef.current then
				progressBarRef.current:Destroy()
				progressBarRef.current = nil
			end
		end
	end, { now, props.PlayerData })

	local connref = useRef(nil)
	useEffect(function()
		task.spawn(function()
			if not proximityprompt then
				return
			end
			connref.current = proximityprompt.Triggered:Connect(function()
				local fn = {
					done = function()
						game.ReplicatedStorage.Shared.Events:WaitForChild("CraftPickup"):FireServer(props.CauldronId)
					end,
					none = function()
						props.setCurrentCauldron(props.CauldronId)
					end,
					cookinglong = function()
						game.ReplicatedStorage.Shared.Events:WaitForChild("SkipCraft"):FireServer(props.CauldronId)
					end,
				}
				local action = fn[phase]
				if action then
					pcall(action)
				else
					-- warn("Not done yet!")
				end
			end)
			proximityprompt.Enabled = false
			task.spawn(function()
				task.wait()
				proximityprompt.Enabled = true
			end)
		end)
		return function()
			if connref.current then
				connref.current:Disconnect()
			end
		end
	end, { phase, proximityprompt })

	useEffect(function()
		return function()
			-- Cleanup ingredient models on unmount
			for _, model in ipairs(ingredientModelsRef.current) do
				if model and model.Parent then
					model:Destroy()
				end
			end
			ingredientModelsRef.current = {}
		end
	end, {})

	useEffect(function()
		if not proximityprompt then
			return
		end
		if props.activePanel == "craft" then
			proximityprompt.Enabled = false
		else
			proximityprompt.Enabled = true
		end
	end, { props.activePanel })
	return e("Attachment")
end

local function Cauldrons(props)
	local setCurrentCauldron = props.setCurrentCauldron
	local PlayerData = props.PlayerData
	local children = {}
	local Plot, setPlot = useState(nil)
	local state = PlayerSessions:getState()
	local playerSession = state.players[game.Players.LocalPlayer]

	useEffect(function()
		task.spawn(function()
			if playerSession then
				setPlot(playerSession.Plot)
			end
		end)
	end, { playerSession })
	if not Plot then
		return
	end

	if not PlayerData then
		return
	end
	for i, folder: Folder in Plot.Cauldrons:GetChildren() do
		local CauldronId = folder.Name
		local cauldron = PlayerData.Cauldrons[CauldronId]
		if not cauldron then
			continue
		end
		children[CauldronId] = e(CauldronItem, {
			PlayerData = PlayerData,
			key = CauldronId,
			CauldronId = CauldronId,
			Cauldron = cauldron,
			PotionId = cauldron ~= "none" and cauldron.PotionId,
			StartTime = cauldron ~= "none" and cauldron.StartTime,
			VariationId = cauldron ~= "none" and cauldron.VariationId,
			UID = cauldron ~= "none" and cauldron.UID,
			Plot = Plot,
			activePanel = props.activePanel,
			setCurrentCauldron = props.setCurrentCauldron,
		})
	end
	return e("Attachment", {}, children)
end
return Cauldrons
