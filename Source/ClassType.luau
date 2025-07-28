-- Fauxtyai 2025
local ClassType = {}
ClassType.__index = ClassType

local Class_Constructor = require("@self/Constructor")
local Module_TableHelpers = require("@self/External/TableHelpers")


--- Types ---

type DependencyMergeOptions = {
	Defaults: Module_TableHelpers.TableMergeType;
	Static: Module_TableHelpers.TableMergeType;
	Constructors: {[string]: {
		Args: Module_TableHelpers.TableMergeType;
		Callback: Module_TableHelpers.TableMergeType;
	}}
}
type AddDependency1 = (self: ClassType, OtherClass: BuiltClass, Index: number?, Options: DependencyMergeOptions?) -> ()
type AddDependency2 = (self: ClassType, OtherClass: ClassType, Index: number?, Options: DependencyMergeOptions?) -> ()


export type StaticConstruct = {
	Value: any;
	Persistent: boolean;
}

export type BuiltClass = {
	__type: "BuiltClass";
	__source: ClassType;
}

export type ClassType = {
	__type: "ClassType";
	
	Dependencies: {ClassType};
	Defaults: {[any]: any};
	Constructors: {[string]: Class_Constructor.Constructor};
	Static: {[string]: StaticConstruct};
	
	new: () -> (ClassType);
	AddDependency: AddDependency1&AddDependency2;
	AddStatic: (self: ClassType, Name: string, Value: any, Persistent: boolean) -> ();
	AddConstructor: (self: ClassType, Name: string, Factory: (Class: BuiltClass) -> (BuiltClass), Args: {Class_Constructor.ArgumentConstruct}?, Callback: {Class_Constructor.CallbackConstruct}?) -> (Class_Constructor.Constructor);
	Build: (self: ClassType) -> (BuiltClass);
}


--- Constructors ---

function ClassType.new()
	
	local self = setmetatable({}, ClassType) :: ClassType
	self.__type = "ClassType"
	
	
	self.Constructors = {}
	self.Dependencies = {}
	self.Defaults = {}
	self.Static = {}
	
	
	local BaseConstructor = self:AddConstructor("new", function(Class)

		local New = setmetatable({}, Class)

		return New

	end)
	
	BaseConstructor:AddCallback(nil, "AddDefaults", "before", function(New: BuiltClass)

		for Key, Value in self.Defaults do

			New[Key] = Value

		end

	end)
	
	
	return self
	
end


--- Functions ---

function ClassType:AddDependency(OtherClass: ClassType, Index: number?, Options: DependencyMergeOptions?)
	
	if OtherClass.__type == "BuiltClass" then
		
		OtherClass = OtherClass.__source
		
	end
	Options = Options or {} :: DependencyMergeOptions
	
	
	local Dependencies = self.Dependencies :: {ClassType}
	
	if Index then
		
		table.insert(Dependencies, Index, OtherClass)
		
	else
		
		table.insert(Dependencies, OtherClass)
		
	end
	
	
	for _, Dependency: ClassType in OtherClass.Dependencies do
		
		if table.find(Dependencies, Dependency) then continue end
		
		self:AddDependency(Dependency)
		
	end
	
	
	Module_TableHelpers.Merge(OtherClass.Defaults, self.Defaults, Options.Defaults or "copy")
	Module_TableHelpers.Merge(OtherClass.Static, self.Static, Options.Static or "copy")
	
	for Name: string, Constructor: Class_Constructor.Constructor in self.Constructors do
		
		local Mirror = OtherClass.Constructors[Name] :: Class_Constructor.Constructor
		
		if not Mirror then continue end
		
		
		local Options = (Options.Constructors and Options.Constructors[Name]) or {}
		
		
		Module_TableHelpers.Merge(Mirror.Args, Constructor.Args, Options.Args or "push")
		Module_TableHelpers.Merge(Mirror.Callback, Constructor.Callback, Options.Callback or "append")
		
		Constructor:ClearDuplicates()
		
	end
	
end


function ClassType:AddStatic(Name: string, Value: any, Persistent: boolean)
	
	if Persistent then
		
		self.Static[Name] = Value
		
	else
		
		self.Defaults[Name] = Value
		
	end
	
end


function ClassType:AddConstructor(Name: string, Factory: (Class: BuiltClass) -> (BuiltClass), Args: {Class_Constructor.ArgumentConstruct}?, Callback: {Class_Constructor.CallbackConstruct}?)
	
	local Constructor = Class_Constructor.new(Name, Factory, Args, Callback)
	
	
	self.Constructors[Name] = Constructor
	return Constructor
	
end


function ClassType:Build()
	
	local Class = {}
	Class.__type = "BuiltClass"
	Class.__source = self
	Class.__index = Class
	
	
	for Key, Static: any in self.Static do
		
		Class[Key] = Static
		
	end
	
	
	for Name: string, Constructor: Class_Constructor.Constructor in self.Constructors do
		
		local PreFuncs = {} :: {() -> ()}
		local PostFuncs = {} :: {() -> ()}
		
		for _, Callback: Class_Constructor.CallbackConstruct in Constructor.Callback do
			
			if Callback.Order == "before" then
				
				table.insert(PreFuncs, Callback.Function)
				
			else
				
				table.insert(PostFuncs, Callback.Function)
				
			end
			
		end
		
		
		local Args = Constructor.Args :: {Class_Constructor.ArgumentConstruct}
		
		Class[Name] = function(...)
			
			local New = Constructor.Factory(Class, ...)
			local PassedArgs = {...}
			
			for _, Func in PreFuncs do
				
				Func(New, ...)
				
			end
			
			
			for Index, Arg: Class_Constructor.ArgumentConstruct in Args do

				local Passed = PassedArgs[Index]

				if Arg.Required and Passed == nil then

					error(`Constructor '{Constructor.Name}' expected argument #{Index}, but got nil!`)

				end


				if Arg.IsSaved and (Arg.Overwrites or New[Arg.Name] == nil) then

					New[Arg.Name] = Passed

				end

			end
			
			
			for _, Func in PostFuncs do
				
				Func(New, ...)
				
			end
			
			return New
			
		end
		
	end
	
	
	return Class
	
end





return ClassType