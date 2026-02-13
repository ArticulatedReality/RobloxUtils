local RegistryService = {}

-------------------------------------------------------------------------------------------------------------------
local RunService: RunService = game:GetService(`RunService`)
local SharedTableRegistry: SharedTableRegistry = game:GetService(`SharedTableRegistry`)

local Types = require(workspace.Types)
local Error: Types.Error = require(`../Libraries/Error`)

local TimedOut: string = `Wait Request Timed Out For SharedTable: "%s".`

-------------------------------------------------------------------------------------------------------------------
function RegistryService:SetSharedTable(Name: string, Table: SharedTable)
	SharedTableRegistry:SetSharedTable(Name, Table)
	SharedTableRegistry:SetAttribute(Name, true)
end

-------------------------------------------------------------------------------------------------------------------
function RegistryService:GetSharedTable(Name: string): SharedTable?
	return SharedTableRegistry:GetSharedTable(Name)
end

-------------------------------------------------------------------------------------------------------------------
function RegistryService:WaitForSharedTable(Name: string, Timeout: number?): SharedTable?
	local Table: SharedTable = SharedTableRegistry:GetSharedTable(Name)
	if Table then return Table end

	Timeout = Timeout or 10
	local Elapsed: number = 0
	local Found: boolean = false

	local Connection: RBXScriptConnection = SharedTableRegistry:GetAttributeChangedSignal(Name):Connect(function()
		Table = SharedTableRegistry:GetSharedTable(Name) if not Table then return end Found = true
	end)

	Table = SharedTableRegistry:GetSharedTable(Name)
	if Table then Connection:Disconnect() return Table end

	while not Found do
		Elapsed += RunService.Heartbeat:Wait()
		if Elapsed > Timeout then break end
	end

	Connection:Disconnect()
	return Table or Error(TimedOut, Name)
end

-------------------------------------------------------------------------------------------------------------------
return table.freeze(RegistryService) :: Types.RegistryService
