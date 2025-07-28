--!nocheck
local TableHelpers = {}

--- Types ---

export type TableMergeType = "replace" | "overwrite" | "copy" | "push" | "append"


--- Local Functions ---

local function CheckDuplicate(Key: any, Value: any, CheckAgainst: any, Occurances: number, MaxOccurances: number, IsFunc: boolean)
	
	local ShouldClear = false
	local AddOccurance = false

	if IsFunc then

		ShouldClear, AddOccurance = CheckAgainst(Key, Value, Occurances, MaxOccurances)

	elseif Value == CheckAgainst then

		ShouldClear = Occurances >= MaxOccurances
		AddOccurance = not ShouldClear

	end
	
	
	return ShouldClear, AddOccurance
	
end


--- Functions ---

-- Creates a copy of a table. Unlike table.copy(), also creates a table for any sub-tables.
function TableHelpers.DeepCopy(target: {}, depth: number?)
	
	local function Recursion(target: {}, currentDepth: number)
		
		if typeof(depth) == "number" and currentDepth >= depth then return end
		
		for key, value in target do
			
			if typeof(value) == "table" then
				
				target[key] = table.clone(value)
				Recursion(value)
				
			end
			
		end
		
	end
	
	local newTable = table.clone(target)
	Recursion(newTable, 1)
	
	
	return newTable
	
end


-- Gets the closest (and second-closest) value in a dictionary (with numbers as keys) to a given number.
function TableHelpers.GetClosestKeyToValue(TargetTable: {number: number}, TargetValue: number): ({Difference: number, Value: any, Key: number}, {Difference: number, Value: any, Key: number}?)
	
	local ClosestDifference: number, ClosestValue: any, ClosestKey: number
	local SecondClosestDifference: number?, SecondClosestValue: any?, SecondClosestKey: number?
	
	
	for Key: number, Value: any in TargetTable do
		
		local Difference = math.abs(TargetValue - Key)
		
		
		if not ClosestValue or Difference < ClosestDifference then
			
			SecondClosestDifference = ClosestDifference
			SecondClosestValue = ClosestValue
			SecondClosestKey = ClosestKey
			
			
			ClosestDifference = Difference
			ClosestKey = Key
			ClosestValue = Value
			
		elseif not SecondClosestValue or Difference < SecondClosestDifference then
			
			SecondClosestDifference = Difference
			SecondClosestValue = Value
			SecondClosestKey = Key
			
		end

	end
	
	
	local ClosestTable = {
		Difference = ClosestDifference, 
		Value = ClosestValue, 
		Key = ClosestKey
	}
	local SecondClosestTable
	
	if typeof(SecondClosestDifference) ~= "nil" and typeof(SecondClosestKey) ~= "nil" and typeof(SecondClosestValue) ~= "nil" then
		
		SecondClosestTable = {
			Difference = SecondClosestDifference, 
			Value = SecondClosestValue, 
			Key = SecondClosestKey
		}
		
	end
	
	
	return ClosestTable, SecondClosestTable
	
end


-- Merges the 'From' table with the 'To' table; A more feature-rich table.move().
function TableHelpers.Merge(From: {}, To: {}, Type: TableMergeType)

	Type = Type or "append"
	

	if Type == "replace" then

		table.clear(To)
		
		TableHelpers.Merge(From, To, "overwrite")

	end


	for Key, Value in From do
		
		if Type == "push" then

			table.insert(To, 1, Value)
			continue

		end

		if Type == "append" then

			table.insert(To, Value)
			continue

		end


		if Type == "copy" then

			if To[Key] ~= nil then continue end

		elseif Type ~= "overwrite" then continue end


		To[Key] = Value

	end

end


-- A more feature-rich table.clear().
function TableHelpers.Clear(Target: {}, CheckAgainst: any | (Key: any, Value: any, CheckAgainst: any, Occurances: number, MaxOccurances: number) -> (boolean, boolean), IndexStyle: "keys" | "table", MaxOccurances: number?, ReplaceWith: (any | (Key: any, Value: any, Occurances: number) -> ())?, BreakAt: number?): number
	
	if CheckAgainst == nil then
		
		table.clear(Target)
		return 0
		
	end
	
	local IsCheckFunc = typeof(CheckAgainst) == "function"
	local IsReplaceFunc = typeof(ReplaceWith) == "function"
	MaxOccurances = MaxOccurances or 1
	local Occurances = 0
	
	
	
	if IndexStyle == "keys" then
		
		for Key, Value in Target do
			
			local ShouldClear, ShouldProgress = CheckDuplicate(Key, Value, CheckAgainst, Occurances, MaxOccurances, IsCheckFunc)
			
			if ShouldClear then
				
				Target[Key] = (IsReplaceFunc and ReplaceWith(Key, Value, Occurances)) or ReplaceWith
				
			elseif ShouldProgress then
				
				Occurances += 1
				
			end
			
			
			if BreakAt and Occurances >= BreakAt then
				
				break
				
			end
			
		end
		
	elseif IndexStyle == "table" then
		
		local Index = 1
		
		while Index <= #Target do
			
			local Value = Target[Index]
			
			if not Value then continue end
			
			
			local ShouldClear, ShouldProgress = CheckDuplicate(Index, Value, CheckAgainst, Occurances, MaxOccurances, IsCheckFunc)

			if ShouldClear then

				local ReplaceWith = (IsReplaceFunc and ReplaceWith(Index, Value, Occurances)) or ReplaceWith
				
				
				if ReplaceWith == nil then
					
					table.remove(Target, Index)
					
				else
					
					Target[Index] = ReplaceWith
					
				end

			else
				
				Index += 1
				
				if ShouldProgress then
					Occurances += 1
				end

			end
			
			
			if BreakAt and Occurances >= BreakAt then
				
				break
				
			end
			
		end
		
	end
	
	
	return Occurances
	
end



return TableHelpers