-- Based on https://devforum.roblox.com/t/all-about-object-oriented-programming/8585
local ClassSystem = require("./ClassSystem/ClassType")


Car = ClassSystem.new()
Car:AddStatic("Speed", 5, false)
Car:AddStatic("Boost", function(self)
	
	self.Speed = self.Speed + 5
	
end, true)


return Car:Build()