-- local cb = (workspace.Plots.Plot.CompletionBoard :: Model):GetPivot()
-- local min = math.huge
-- local max = 0
-- local t = game.Selection:Get()
-- for i, d: Model in t do
-- 	local distance = math.round((cb.Position - d:GetPivot().Position).Magnitude)
-- 	if distance <= min then
-- 		min = distance
-- 	end
-- 	if distance >= max then
-- 		max = distance
-- 	end
-- end
-- table.sort(t, function(a, b)
-- 	return (a:GetPivot().Position - cb.Position).Magnitude < (b:GetPivot().Position - cb.Position).Magnitude
-- end)
-- for i = 1, #t, 1 do
-- 	t[i].Name = "Rack" .. i
-- 	local distance = math.round((cb.Position - t[i]:GetPivot().Position).Magnitude)
-- 	if distance <= min then
-- 		min = distance
-- 		t[i]:SetAttribute("Price", 0)
-- 		continue
-- 	end
-- 	local price = distance - min
-- 	t[i]:SetAttribute("Price", 100 * price ^ 4)
-- end
local cb = (workspace.Plots.Plot.CompletionBoard :: Model):GetPivot()
local min = math.huge
local max = 0
local t = game.Selection:Get()
for i, d: Model in t do
	local distance = math.round((cb.Position - d:GetPivot().Position).Magnitude)
	if distance <= min then
		min = distance
	end
	if distance >= max then
		max = distance
	end
end
table.sort(t, function(a, b)
	return (a:GetPivot().Position - cb.Position).Magnitude < (b:GetPivot().Position - cb.Position).Magnitude
end)
for i = 1, #t, 1 do
	t[i].Name = "Cauldron" .. i
	local distance = math.round((cb.Position - t[i]:GetPivot().Position).Magnitude)
	if distance <= min then
		min = distance
		t[i]:SetAttribute("Price", 0)
		continue
	end
	local price = distance - min
	t[i]:SetAttribute("Price", 1000 * price ^ 4)
end
