local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FusionApp = require(script.Parent.FusionApp)
local controls = {}

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props)
		local scope = props.scope
		local component = FusionApp({
			Parent = props.target,
		})
	end,
}

return story
