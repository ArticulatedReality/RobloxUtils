----[[    SERVICES    ]]----
local Types = require(workspace.Types)
local RegistryService: Types.RegistryService = require(`../Services/RegistryService`)

----[[    HELPER TABLES    ]]----
local Factorials: {[number]: number} = {}
local Combinatorics: {[number]: {[number]: number}} = {}

----[[    MAIN LOGIC    ]]----
local function Factorial(Number: number): number
	if not Factorials[Number - 1] then Factorial(Number - 1) end
	return Factorials[Number - 1] * Number
end

local function Combinatoric(N: number, I: number): number
	return Factorials[N] / (Factorials[I] * Factorials[N - I])
end

----[[    INITIALIZE    ]]----
Factorials[0] = 1
Combinatorics[0] = {[0] = 1}

for Index: number = 1, 50 do
	task.desynchronize()
	Combinatorics[Index] = {[0] = 1}
	Factorials[Index] = Factorial(Index)
	task.synchronize()
	
	for Index2: number = 1, Index do
		task.desynchronize()
		Combinatorics[Index][Index2] = Combinatoric(Index, Index2)
		task.synchronize()	
	end
end

RegistryService:SetSharedTable(`Factorials`, SharedTable.new(Factorials))
RegistryService:SetSharedTable(`Combinatorics`, SharedTable.new(Combinatorics))

table.clear(Factorials)
table.clear(Combinatorics)

Factorial 		= nil
Factorials 		= nil
Combinatoric 	= nil
Combinatorics 	= nil
RegistryService = nil
