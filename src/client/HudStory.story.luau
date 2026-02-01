local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Craft = require(game.ReplicatedStorage.Shared.ReactComponents.Craft)
local PlayerSessions = require(game.ReplicatedStorage.Shared.producers.PlayerSessions)

local function Hud()
	return e("Frame", {
		Size = UDim2.new(0, 200, 0, 50),
		Position = UDim2.new(0.5, -100, 0, 10),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0,
		ZIndex = 10,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		BaseButton = e("TextButton", {
			Size = UDim2.new(0.48, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			BorderSizePixel = 0,
			Text = "Base",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			ZIndex = 11,
			[React.Event.Activated] = function()
				PlayerSessions:getState(function(state: PlayerSessions.PlayersState)
					local session = state.players[game.Players.LocalPlayer]
					if not (session and session.Plot) then
						return
					end
					game.Players.LocalPlayer.Character:PivotTo(session.Plot:GetPivot())
				end)
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}),
		Divider = e("Frame", {
			Size = UDim2.new(0, 2, 0.6, 0),
			Position = UDim2.new(0.5, -1, 0.2, 0),
			BackgroundColor3 = Color3.fromRGB(80, 80, 80),
			BorderSizePixel = 0,
			ZIndex = 11,
		}),
		ShopButton = e("TextButton", {
			Size = UDim2.new(0.48, 0, 1, 0),
			Position = UDim2.new(0.52, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			BorderSizePixel = 0,
			Text = "Shop",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			ZIndex = 11,
			[React.Event.Activated] = function()
				game.Players.LocalPlayer.Character:PivotTo(workspace.Shops.June:GetPivot())
			end,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}),
		NothingButton = e(function(nb_props)
			-- local multext = ("Multiplier: %.2fx"):format(
			-- 	MultiplierHelper.GetFinalMultiplier(nb_props.PlayerData and nb_props.PlayerData.Multipliers)
			-- )

			return e("TextButton", {
				Size = UDim2.new(0, 200, 1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				Text = "multext",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				ZIndex = 11,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			})
		end, {
			-- PlayerData = playerData,
		}),
	})
end

function story(target: Frame)
	local root = ReactRoblox.createRoot(target)
	root:render(e(Hud))
	return function()
		root:unmount()
	end
end

return story
