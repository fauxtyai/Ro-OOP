-- Fauxtyai 2025
local Constructor = {}
Constructor.__index = Constructor

local Module_TableHelpers = require("./External/TableHelpers")


--- Types ---

export type CallbackOrder = "before" | "after"

export type CallbackConstruct = {
	Order: CallbackOrder;
	Name: string?;
	Function: (self: {}) -> ();
}

export type ArgumentConstruct = {
	Name: string;
	Required: boolean?;
	IsSaved: boolean?;
	Overwrites: boolean?;
}

export type Constructor = {
	Name: string;
	Factory: (Class: {}) -> ({});
	Args: {ArgumentConstruct};
	Callback: {CallbackConstruct};
	
	AddArg: (self: Constructor, Arg: ArgumentConstruct, Index: number?) -> (ArgumentConstruct);
	AddCallback: (self: Constructor, Index: number?, Name: string?, Order: CallbackOrder, Func: (self: {}) -> ()) -> (CallbackConstruct);
	ClearDuplicates: (self: Constructor) -> ();
	
}


--- Constructors ---

function Constructor.new(Name: string, Factory: (Class: {}) -> ({}), Args: {ArgumentConstruct}?, Callback: {CallbackConstruct}?): Constructor
	
	local self = setmetatable({}, Constructor)
	
	
	self.Name = Name
	self.Factory = Factory
	
	self.Args = Args or {}
	self.Callback = Callback or {}
	
	
	return self
	
end


--- Local Functions ---

local function MakeDuplicateChecker(Name: string)
	
	return function(Key: number, Value: ArgumentConstruct | CallbackConstruct, Occurances: number, MaxOccurances: number)

		local IsOccurance = Value.Name == Name
		
		print(Occurances, MaxOccurances)

		return IsOccurance and Occurances >= MaxOccurances, IsOccurance

	end
	
end

local function ClearDuplicateRecursion(Table: {})
	
	local Cleared = {}
	
	for _, Value: ArgumentConstruct | CallbackConstruct in Table do
		
		local Name = Value.Name
		if not Name or table.find(Cleared, Name) then continue end
		
		
		local o = Module_TableHelpers.Clear(Table, MakeDuplicateChecker(Name), "table")
		print(Name, o)
		
		table.insert(Cleared, Name)
		
	end
	
end


--- Functions ---

function Constructor:AddArg(Arg: ArgumentConstruct, Index: number?)
	
	if Index then
		
		table.insert(self.Args, Index, Arg)
		
	else
		
		table.insert(self.Args, Arg)
		
	end
	
	
	return Arg
	
end


function Constructor:AddCallback(Index: number?, Name: string?, Order: CallbackOrder, Function: (self: {}) -> ())
	
	local Construct: CallbackConstruct = {
		Order = Order;
		Function = Function;
		Name = Name;
	}
	
	
	if Index then
		
		table.insert(self.Callback, Index, Construct)
		
	else
		
		table.insert(self.Callback, Construct)
		
	end
	
	return Construct
	
end


function Constructor:ClearDuplicates()
	
	ClearDuplicateRecursion(self.Args)
	ClearDuplicateRecursion(self.Callback)
	
end




return Constructor