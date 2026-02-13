local TableUtility = {}

-------------------------------------------------------------------------------------------------------------------
local Enums = require(`./Enums`)
local Types = require(workspace.Types)
local Task: Types.Task = require(`../Libraries/Task`)
local Error: Types.Error = require(`../Libraries/Error`)

local AttemptFailed: string = `ProtectedCall Failed! Retrying In "%s" Seconds. Remaining Attempts: "%s".`

-------------------------------------------------------------------------------------------------------------------
local Memo = {}
Memo.__index = Memo
Memo.__call = function(self, Input: any): any
	if self.Cache[Input] then return self.Cache[Input] end
	local Output: any = self.Callback(Input)
	self.Cache[Input] = Output
	return Output
end

-------------------------------------------------------------------------------------------------------------------
function Memo.new(Callback: (Input: any) -> (...any))
	local self = setmetatable({}, Memo)
	
	self.Cache = {}
	self.Callback = Callback
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function Memo:Destroy()
	table.clear(self.Cache)
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
local AsyncHandler = {}
AsyncHandler.__index = AsyncHandler

-------------------------------------------------------------------------------------------------------------------
function AsyncHandler.new(Object: Instance, Method: string, ShowError: boolean, BackOff: (number) -> (number))
	local self = setmetatable({}, AsyncHandler)

	self.Object = Object
	self.Method = Object[Method]
	self.ShowError = ShowError or false
	self.BackOff = BackOff or Enums.BackOff.Linear

	return self
end

-------------------------------------------------------------------------------------------------------------------
function AsyncHandler:Execute(Attempts: number, ...: any): ...any?
	local Attempt: number = 0

	while Attempt <= Attempts do
		local Output: {any} = table.pack(pcall(self.Method, self.Object, ...))
		if Output[1] then return table.unpack(Output, 2, Output.n) end
		Attempt += 1
		if Attempt >= Attempts then break end
		local Time: number = self.BackOff(Attempt)
		if self.ShowError then Error(AttemptFailed, Time, Attempts - Attempt) end
		Task.Wait(Time)
	end

	Error(`ProtectedCall Failed! Max Attempts({Attempts}) Reached.`)
end

-------------------------------------------------------------------------------------------------------------------
function AsyncHandler:Once(...: any): ...any
	return self:Execute(1, ...)
end

-------------------------------------------------------------------------------------------------------------------
function AsyncHandler:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
local TableCache = {}
TableCache.__index = TableCache
TableCache.__iter = function(self)
	local MainTable = self.MainTable
	local Key, Value = nil, nil

	return function()
		Key, Value = next(MainTable, Key)
		if Key == nil then return nil end
		return Key, Value
	end
end

-------------------------------------------------------------------------------------------------------------------
function TableCache.new(Object: Instance, Method: string, Added: RBXScriptSignal, Removed: RBXScriptSignal)
	local self = setmetatable({}, TableCache)

	self.MainTable = {}

	for Index: number, Value: any in Object[Method](Object) do
		self.MainTable[Value] = true
	end

	self.AddConnection = Added:Connect(function(Value: any)
		if self.MainTable[Value] then return end
		self.MainTable[Value] = true
	end)

	self.RemoveConnection = Removed:Connect(function(Value: any)
		if not self.MainTable[Value] then return end
		self.MainTable[Value] = nil
	end)

	return self
end

-------------------------------------------------------------------------------------------------------------------
function TableCache:Destroy()
	self.RemoveConnection:Disconnect()
	self.AddConnection:Disconnect()
	table.clear(self.MainTable)
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
TableUtility.Memo = Memo
TableUtility.TableCache = TableCache
TableUtility.AsyncHandler = AsyncHandler

-------------------------------------------------------------------------------------------------------------------
return TableUtility
