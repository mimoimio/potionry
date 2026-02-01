--[[
	TutorialV2 - Stateless Priority-Based Tutorial System

	Priority Ladder (P1-P6):
	- P1: Global Safety Check (TutorialFinished)
	- P2: Completion Verification (placed potion)
	- P3: Placing Phase (have potion, need to place)
	- P4: Brewing Phase (waiting for brew)
	- P5: Crafting Phase (have ingredients, need to brew)
	- P6: Shopping Phase (need ingredients)
]]

local React = require(game.ReplicatedStorage.Packages.React)
local TutorialRefs = require(game.ReplicatedStorage.Shared.producers.TutorialRefs)
local TweenService = game:GetService("TweenService")
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

type TutorialProps = {
	PlayerData: PlayerData,
	activePanel: string?,
	onHighlightChange: ((highlightType: string?, targetId: string?) -> ())?,
}

local function getDistance(pos1: Vector3, pos2: Vector3): number
	return (pos1 - pos2).Magnitude
end

local function createBeam(
	fromPart: BasePart,
	toPart: BasePart
): { beam: Beam, att0: Attachment, att1: Attachment, arrowGui: BillboardGui? }
	-- Create attachments
	local att0 = Instance.new("Attachment")
	att0.Parent = fromPart

	local att1 = Instance.new("Attachment")
	att1.Parent = toPart

	-- Create beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = 0.5
	beam.Width1 = 0.5
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
	beam.FaceCamera = true
	beam.Texture = "rbxassetid://136242854116857"
	beam.TextureSpeed = 0.3
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	beam.Parent = fromPart

	-- Add arrow GUI
	local arrowGui = nil
	local arrowTemplate = game.ReplicatedStorage.Shared:FindFirstChild("ArrowGui")
	if arrowTemplate then
		arrowGui = arrowTemplate:Clone()
		arrowGui.Parent = att1
		arrowGui.Enabled = true
	end

	return {
		beam = beam,
		att0 = att0,
		att1 = att1,
		arrowGui = arrowGui,
	}
end

local function cleanupBeam(beamData)
	if not beamData then
		return
	end

	if beamData.beam then
		beamData.beam:Destroy()
	end
	if beamData.att0 then
		beamData.att0:Destroy()
	end
	if beamData.att1 then
		beamData.att1:Destroy()
	end
	if beamData.arrowGui then
		beamData.arrowGui:Destroy()
	end
end

local function TutorialV2(props: TutorialProps)
	local beamRef = useRef(nil)
	local currentActionRef = useRef(nil)
	local pulseRef = useRef(nil)
	local character, setCharacter = useState(player.Character)
	local tutorialMessage, setTutorialMessage = useState("")
	local highlightTarget, setHighlightTarget = useState(nil)
	local tutorialRefs, setTutorialRefs = useState({} :: TutorialRefs.TutorialRefsState)

	-- Track character changes
	useEffect(function()
		local charAddedConn
		local charRemovingConn
		task.spawn(function()
			setCharacter(player.Character or player.CharacterAdded:Wait())
			charAddedConn = player.CharacterAdded:Connect(function(newChar)
				setCharacter(newChar)
			end)

			charRemovingConn = player.CharacterRemoving:Connect(function()
				setCharacter(nil)
				cleanupBeam(beamRef.current)
				beamRef.current = nil
			end)
		end)
		return function()
			if charAddedConn then
				charAddedConn:Disconnect()
			end
			if charRemovingConn then
				charRemovingConn:Disconnect()
			end
		end
	end, {})

	-- Subscribe to TutorialRefs
	useEffect(function()
		local unsubscribe = TutorialRefs:subscribe(function(state)
			warn("changed:", state)
			setTutorialRefs(state)
		end)

		-- Initial state
		setTutorialRefs(TutorialRefs:getState())

		return function()
			unsubscribe()
		end
	end, {})

	-- Main priority loop
	useEffect(function()
		if not props.PlayerData then
			return
		end

		local running = true

		task.spawn(function()
			while running do
				task.wait(0.1)

				if not running or not props.PlayerData then
					break
				end

				local pd = props.PlayerData
				local hrp = character and character:FindFirstChild("HumanoidRootPart")

				-- P1: Global Safety Check
				if pd.TutorialFinished == true then
					-- Hide all visuals
					cleanupBeam(beamRef.current)
					beamRef.current = nil
					setTutorialMessage("")
					setHighlightTarget(nil)
					currentActionRef.current = "finished"
					if props.onHighlightChange then
						props.onHighlightChange(nil, nil)
					end
					break -- Terminate loop
				end

				-- P2: Completion Verification (placed potion?)
				local hasPlacedPotion = false
				if pd.PotionSlots then
					for rackName, rack in pairs(pd.PotionSlots) do
						for slotName, slotValue in pairs(rack) do
							if slotValue ~= "none" then
								hasPlacedPotion = true
								break
							end
						end
						if hasPlacedPotion then
							break
						end
					end
				end

				if hasPlacedPotion then
					if currentActionRef.current ~= "completing" then
						currentActionRef.current = "completing"

						-- Fire server event
						local FinishTutorial = game.ReplicatedStorage.Shared.Events:FindFirstChild("FinishTutorial")
						if FinishTutorial then
							task.delay(2, function()
								FinishTutorial:FireServer()
							end)
						end

						-- Play success effect
						if hrp then
							local confetti = Instance.new("ParticleEmitter")

							local donesound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Confetti")
							if donesound then
								task.spawn(function()
									local sound = donesound:Clone()
									sound.Volume = 0.3
									sound.Parent = game.Players.LocalPlayer
									if not sound.IsLoaded then
										sound.Loaded:Wait()
									end
									sound:Play()
									sound.Ended:Wait()
									task.wait(1)
									sound:Destroy()
								end)
							end

							confetti.Texture = "rbxassetid://9084349372"
							confetti.Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
								ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 100)),
								ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 255, 255)),
							})
							confetti.Rate = 0
							confetti.Lifetime = NumberRange.new(2, 4)
							confetti.Speed = NumberRange.new(10, 30)
							confetti.SpreadAngle = Vector2.new(40, 40)
							confetti.Parent = hrp
							confetti.Acceleration = Vector3.new(0, -10, 0)

							confetti:Emit(100)
							setTutorialMessage("🎉 Tutorial Complete! Keep brewing potions!")
							task.delay(2, function()
								confetti.Enabled = false
								task.wait(4)
								confetti:Destroy()
							end)
						end

						cleanupBeam(beamRef.current)
						beamRef.current = nil
					end
					continue
				end

				-- P3: Placing Phase (have potion, need to place)
				if pd.Potions and #pd.Potions > 0 then
					if currentActionRef.current ~= "placing" then
						currentActionRef.current = "placing"
						warn("P3 placing")
						cleanupBeam(beamRef.current)
						beamRef.current = nil

						-- Find first owned rack with empty slot
						task.spawn(function()
							local success, plot = pcall(function()
								local GetPlot = game.ReplicatedStorage.Shared.Events:FindFirstChild("GetPlot")
								return GetPlot and GetPlot:InvokeServer()
							end)

							if not success or not plot then
								setTutorialMessage("⚠️ Loading your plot...")
								return
							end

							local potionSlots = plot:FindFirstChild("PotionSlots")
							if not potionSlots then
								setTutorialMessage("⚠️ Potion slots not ready...")
								return
							end

							local targetSlotPart = nil
							local targetRackName = nil
							local targetSlotName = nil

							-- Find first owned rack with empty slot
							if pd.PotionSlots then
								for rackName, rack in pairs(pd.PotionSlots) do
									for slotName, slotValue in pairs(rack) do
										if slotValue == "none" then
											local rackFolder = potionSlots:FindFirstChild(rackName)
											if rackFolder then
												local rackModel = rackFolder:FindFirstChild("Rack")
												if rackModel then
													local slotPart = rackModel:FindFirstChild(slotName)
													if slotPart and slotPart:IsA("BasePart") then
														targetSlotPart = slotPart
														targetRackName = rackName
														targetSlotName = slotName
														break
													end
												end
											end
										end
									end
									if targetSlotPart then
										break
									end
								end
							end

							if targetSlotPart and hrp then
								beamRef.current = createBeam(hrp, targetSlotPart)
								setTutorialMessage(
									string.format(
										"✨ Place your potion on your racks" --[[, targetSlotName or "the slot"]]
									)
								)
							else
								setTutorialMessage("You have a potion! Find a rack to place it.")
							end
						end)
					end
					continue
				end

				-- P4: Brewing Phase (waiting for brew)
				local activeCauldronId = nil
				local activeCauldronData = nil
				if pd.Cauldrons then
					for cauldronId, cauldronData in pairs(pd.Cauldrons) do
						if cauldronData ~= "none" then
							activeCauldronId = cauldronId
							activeCauldronData = cauldronData
							break
						end
					end
				end

				if activeCauldronId then
					if currentActionRef.current ~= "brewing_" .. activeCauldronId then
						currentActionRef.current = "brewing_" .. activeCauldronId
						warn("if activeCauldronId then")
						cleanupBeam(beamRef.current)
						beamRef.current = nil

						-- Find cauldron in world
						task.spawn(function()
							local success, plot = pcall(function()
								local GetPlot = game.ReplicatedStorage.Shared.Events:FindFirstChild("GetPlot")
								return GetPlot and GetPlot:InvokeServer()
							end)

							if not success or not plot then
								setTutorialMessage("⚠️ Loading your plot...")
								return
							end

							local cauldrons = plot:FindFirstChild("Cauldrons")
							if not cauldrons then
								setTutorialMessage("⚠️ Cauldrons not ready...")
								return
							end

							local cauldronFolder = cauldrons:FindFirstChild(activeCauldronId)
							if cauldronFolder then
								local cauldronModel = cauldronFolder:FindFirstChild("Cauldron")
								if cauldronModel and hrp then
									local targetPart = cauldronModel.PrimaryPart
										or cauldronModel:FindFirstChildWhichIsA("BasePart", true)
									if targetPart then
										beamRef.current = createBeam(hrp, targetPart)
									end
								end
							end

							-- Calculate elapsed time
							local elapsed = activeCauldronData
									and activeCauldronData.StartTime
									and (os.time() - activeCauldronData.StartTime)
								or 0
							setTutorialMessage("⏳ Wait until it's ready to pickup... ")
						end)
					end
					continue
				end

				-- P5: Crafting Phase (have ingredients, need to brew)
				local hasDaybloom = pd.Ingredients and pd.Ingredients["daybloom"] and pd.Ingredients["daybloom"] > 0
				if hasDaybloom then
					-- Sub-ladder for P5
					local activePanel = props.activePanel

					-- P5-A: Craft UI is open, highlight brew button
					if activePanel == "craft" then
						if currentActionRef.current ~= "craft_ui_open" then
							currentActionRef.current = "craft_ui_open"
							cleanupBeam(beamRef.current)
							beamRef.current = nil
							setHighlightTarget("brew_button")
							setTutorialMessage("Click on an ingredient and the craft button to start crafting a potion")
							if props.onHighlightChange then
								props.onHighlightChange("craft_button", "brew_button")
							end
						end
						continue
					end

					-- P5-B: Player near cauldron, show prompt
					local success, plot = pcall(function()
						local GetPlot = game.ReplicatedStorage.Shared.Events:FindFirstChild("GetPlot")
						return GetPlot and GetPlot:InvokeServer()
					end)

					if success and plot and hrp then
						local cauldrons = plot:FindFirstChild("Cauldrons")
						if cauldrons then
							local nearestCauldron = nil
							local nearestDistance = math.huge

							for _, cauldronFolder in pairs(cauldrons:GetChildren()) do
								local cauldronModel = cauldronFolder:FindFirstChild("Cauldron")
								if cauldronModel then
									local targetPart = cauldronModel.PrimaryPart
										or cauldronModel:FindFirstChildWhichIsA("BasePart", true)
									if targetPart then
										local dist = getDistance(hrp.Position, targetPart.Position)
										if dist < nearestDistance then
											nearestDistance = dist
											nearestCauldron = targetPart
										end
									end
								end
							end

							-- P5-B: Near cauldron (< 30 studs)
							if nearestDistance < 30 and nearestCauldron then
								if currentActionRef.current ~= "near_cauldron" then
									currentActionRef.current = "near_cauldron"
									cleanupBeam(beamRef.current)
									beamRef.current = nil
									beamRef.current = createBeam(hrp, nearestCauldron)
									setTutorialMessage("🔮 Click the cauldron to start brewing!")
								end
								-- Cleanup pulse overlay
								if pulseRef.current then
									if pulseRef.current.tween then
										pulseRef.current.tween:Cancel()
									end
									if pulseRef.current.gui then
										pulseRef.current.gui:Destroy()
									end
									pulseRef.current = nil
								end
								continue
							end

							-- P5-C: Far from cauldron
							if nearestCauldron then
								if currentActionRef.current ~= "find_cauldron" then
									currentActionRef.current = "find_cauldron"
									cleanupBeam(beamRef.current)
									beamRef.current = nil
									beamRef.current = createBeam(hrp, nearestCauldron)
									setTutorialMessage("Go to your Cauldron or use the Base button")

									-- Create pulsing overlay on BaseButton
									local state = TutorialRefs:getState()
									if state and state.baseButton and not pulseRef.current then
										task.spawn(function()
											local sg = Instance.new("ScreenGui")
											sg.Name = "TutorialPulse"
											sg.DisplayOrder = 1000
											sg.Parent = player.PlayerGui
											local img = Instance.new("ImageLabel")
											local v2: Vector2 = tutorialRefs.baseButton.AbsoluteSize
												+ Vector2.new(20, 20)
											img.Size = UDim2.fromOffset(100, 100)
											img.Position = UDim2.fromOffset(
												tutorialRefs.baseButton.AbsolutePosition.X
													+ tutorialRefs.baseButton.AbsoluteSize.X / 2,
												tutorialRefs.baseButton.AbsolutePosition.Y
													+ tutorialRefs.baseButton.AbsoluteSize.Y
											)
											img.BackgroundTransparency = 1
											img.Image = "rbxassetid://12364133962"
											img.ImageColor3 = Color3.fromRGB(255, 255, 255)
											img.ImageTransparency = 0
											img.Parent = sg
											img.AnchorPoint = Vector2.new(0.5, 0)

											local tweenInfo = TweenInfo.new(
												0.3,
												Enum.EasingStyle.Sine,
												Enum.EasingDirection.InOut,
												-1,
												true
											)
											local tween = TweenService:Create(img, tweenInfo, {
												ImageTransparency = 0.7,
												Position = UDim2.fromOffset(
													tutorialRefs.baseButton.AbsolutePosition.X
														+ tutorialRefs.baseButton.AbsoluteSize.X / 2,
													tutorialRefs.baseButton.AbsolutePosition.Y + 90
												),
											})

											tween:Play()

											pulseRef.current = { gui = sg, tween = tween }
										end)
									end
								end
								if not beamRef.current then
									beamRef.current = createBeam(hrp, nearestCauldron)
								end
							else
								-- Cauldron not found yet, keep searching
								currentActionRef.current = "searching_cauldron"
								-- Cleanup pulse overlay
								if pulseRef.current then
									if pulseRef.current.tween then
										pulseRef.current.tween:Cancel()
									end
									if pulseRef.current.gui then
										pulseRef.current.gui:Destroy()
									end
									pulseRef.current = nil
								end
								setTutorialMessage("Looking for your Cauldron...")
							end
							continue
						end
					end

					-- Fallback if plot not loaded
					if currentActionRef.current ~= "find_cauldron_loading" then
						currentActionRef.current = "find_cauldron_loading"
						setTutorialMessage("Looking for your Cauldron...")
					end
					continue
				end

				-- P6: Shopping Phase (need ingredients) - Default fallback
				local activePanel = props.activePanel

				-- P6-A: Shop UI is open, highlight daybloom
				if activePanel == "shop" then
					if currentActionRef.current ~= "shop_ui_open" then
						currentActionRef.current = "shop_ui_open"
						-- Cleanup beam and pulse overlay
						if pulseRef.current then
							if pulseRef.current.tween then
								pulseRef.current.tween:Cancel()
							end
							if pulseRef.current.gui then
								pulseRef.current.gui:Destroy()
							end
							pulseRef.current = nil
						end
						setHighlightTarget("daybloom")
						setTutorialMessage("🌻 Buy a Daybloom to get started!")
						if props.onHighlightChange then
							props.onHighlightChange("shop_item", "daybloom")
						end

						-- Pulse daybloom card background
						if tutorialRefs.daybloomCard then
							task.spawn(function()
								local originalColor = tutorialRefs.daybloomCard.BackgroundColor3
								local tweenInfo =
									TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
								local tween = TweenService:Create(
									tutorialRefs.daybloomCard,
									tweenInfo,
									{ BackgroundColor3 = Color3.fromRGB(100, 150, 100) }
								)
								tween:Play()
								pulseRef.current = { tween = tween, originalColor = originalColor }
							end)
						end
					end
					continue
				end

				-- P6-B/C: Find shop or show hint
				-- Try to find Shop NPC
				local shopNPCs = CollectionService:GetTagged("ShopNPC")
				local nearestShop = nil
				local nearestDistance = math.huge

				if hrp then
					for _, npc in pairs(shopNPCs) do
						if npc:IsA("Model") then
							local npcPart = npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart", true)
							if npcPart then
								local dist = getDistance(hrp.Position, npcPart.Position)
								if dist < nearestDistance then
									nearestDistance = dist
									nearestShop = npcPart
								end
							end
						elseif npc:IsA("BasePart") then
							local dist = getDistance(hrp.Position, npc.Position)
							if dist < nearestDistance then
								nearestDistance = dist
								nearestShop = npc
							end
						end
					end
				end

				-- P6-B: Near shop (< 30 studs)
				if nearestDistance < 30 and nearestShop and hrp then
					if currentActionRef.current ~= "near_shop" then
						currentActionRef.current = "near_shop"
						cleanupBeam(beamRef.current)
						beamRef.current = nil
						beamRef.current = createBeam(hrp, nearestShop)
						if pulseRef.current then
							if pulseRef.current.tween then
								pulseRef.current.tween:Cancel()
							end
							if pulseRef.current.gui then
								pulseRef.current.gui:Destroy()
							end
							pulseRef.current = nil
						end

						setTutorialMessage("🛒 Press [R] or click to open the Shop!")
					end
					continue
				end

				-- P6-C: Far from shop or shop not found
				if nearestShop and hrp then
					if currentActionRef.current ~= "find_shop" then
						currentActionRef.current = "find_shop"
						cleanupBeam(beamRef.current)
						beamRef.current = nil
						beamRef.current = createBeam(hrp, nearestShop)
						setTutorialMessage("Find the Shop or use the Shop button")

						-- Create pulsing overlay on ShopButton

						local state = TutorialRefs:getState()
						if state and state.shopButton and not pulseRef.current then
							task.spawn(function()
								local sg = Instance.new("ScreenGui")
								sg.Name = "TutorialPulse"
								sg.DisplayOrder = 1000
								sg.Parent = player.PlayerGui

								local img = Instance.new("ImageLabel")
								local v2: Vector2 = tutorialRefs.shopButton.AbsoluteSize + Vector2.new(20, 20)
								img.Size = UDim2.fromOffset(100, 100)
								img.Position = UDim2.fromOffset(
									tutorialRefs.shopButton.AbsolutePosition.X
										+ tutorialRefs.shopButton.AbsoluteSize.X / 2,
									tutorialRefs.shopButton.AbsolutePosition.Y + tutorialRefs.shopButton.AbsoluteSize.Y
								)
								img.BackgroundTransparency = 1
								img.Image = "rbxassetid://12364133962"
								img.ImageColor3 = Color3.fromRGB(255, 255, 255)
								img.ImageTransparency = 0
								img.Parent = sg
								img.AnchorPoint = Vector2.new(0.5, 0)

								local tweenInfo =
									TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
								local tween = TweenService:Create(img, tweenInfo, {
									ImageTransparency = 0.7,
									Position = UDim2.fromOffset(
										tutorialRefs.shopButton.AbsolutePosition.X
											+ tutorialRefs.shopButton.AbsoluteSize.X / 2,
										tutorialRefs.shopButton.AbsolutePosition.Y + 90
									),
								})
								tween:Play()

								pulseRef.current = { gui = sg, tween = tween }
							end)
						end
					end
				else
					-- Shop not found yet, keep searching (reset action so next loop tries again)
					currentActionRef.current = "searching_shop"
					cleanupBeam(beamRef.current)
					beamRef.current = nil
					-- Cleanup pulse overlay
					if pulseRef.current then
						if pulseRef.current.tween then
							pulseRef.current.tween:Cancel()
						end
						if pulseRef.current.gui then
							pulseRef.current.gui:Destroy()
						end
						pulseRef.current = nil
					end
					setTutorialMessage("Looking for the shop... Press [G] to open shop menu")
				end
			end
		end)

		return function()
			running = false
			cleanupBeam(beamRef.current)
			beamRef.current = nil
			-- Cleanup pulse
			if pulseRef.current then
				if pulseRef.current.tween then
					pulseRef.current.tween:Cancel()
				end
				if pulseRef.current.gui then
					pulseRef.current.gui:Destroy()
				end
				if pulseRef.current.originalColor and tutorialRefs.daybloomCard then
					tutorialRefs.daybloomCard.BackgroundColor3 = pulseRef.current.originalColor
				end
				pulseRef.current = nil
			end
		end
	end, {
		tutorialRefs,
		props.PlayerData and props.PlayerData.Ingredients,
		props.PlayerData and props.PlayerData.Cauldrons,
		props.PlayerData and props.PlayerData.Potions,
		props.PlayerData and props.PlayerData.PotionSlots,
		props.PlayerData and props.PlayerData.TutorialFinished,
		character,
	})

	-- Render tutorial UI
	if not props.PlayerData or props.PlayerData.TutorialFinished == true then
		return nil
	end

	if tutorialMessage == "" then
		return nil
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 100,
	}, {
		MessageBox = React.createElement("Frame", {
			Position = UDim2.fromScale(0.5, #props.PlayerData.Potions > 0 and 0 or 1),
			AnchorPoint = Vector2.new(0.5, #props.PlayerData.Potions > 0 and 0 or 1),
			Size = UDim2.new(0.9, 0, 0, 100),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			ZIndex = 100,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 15),
				PaddingBottom = UDim.new(0, 15),
			}),
			Message = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				TextSize = 24,
				TextStrokeTransparency = 0,
				Text = tutorialMessage,
				TextColor3 = Color3.new(1, 1, 1),
				TextWrapped = true,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),
	})
end

return TutorialV2
