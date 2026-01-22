local descendants = script.Services:GetChildren()

for i, d in descendants do
	if d:IsA("ModuleScript") then
		shared[d.Name] = require(d)
	end
end

for i, s in shared do
	if s.initialize and type(s.initialize) == "function" then
		s.initialize()
	end
end

for i, s in shared do
	if s.start and type(s.start) == "function" then
		s.start()
	end
end
