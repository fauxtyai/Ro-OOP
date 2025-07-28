-- Based on https://devforum.roblox.com/t/all-about-object-oriented-programming/8585
local ClassSystem = require("./ClassSystem/ClassType")
local Car = require("./CarExample")


Truck = ClassSystem.new()
Truck:AddDependency(Car)
Truck.Constructors.new:AddArg({
	Name = "Powerup";
	Required = true;
	IsSaved = true;
})


return Truck:Build()