--!optimize 2

local Connection = {}
Connection.__index = Connection

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)
local CleanupService: Types.CleanupService = require(`../Services/CleanupService`)
local CoroutinePool: Types.CoroutinePool = require(`../Libraries/Task/CoroutinePool`)

type Signal = Types.Signal
type Connection = Types.Connection
type CoroutineCache = Types.CoroutineCache

local ExecutorType: {[Enum.SignalBehavior]: any} = {
	[Enum.SignalBehavior.Immediate] = task.spawn,
	[Enum.SignalBehavior.Deferred ] = task.defer,
}

-------------------------------------------------------------------------------------------------------------------
local function HandleInvoker(Sent: Connection)
	local Cache: CoroutineCache = CoroutinePool:Get()
	ExecutorType[Sent.Signal.Behavior](Cache.Coroutine, Sent.Callback, table.unpack(Sent.ArgumentsBuffer))
end

-------------------------------------------------------------------------------------------------------------------
function Connection.new(Signal, Callback: (...any) -> (), PostBoundArguments: {any}): Connection
	local self = setmetatable({}, Connection)
	
	self.Signal = Signal
	self.Callback = Callback
	self.ArgumentsBuffer = nil
	self.PostBoundArguments = PostBoundArguments or {}
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function Connection:ConfigureArgumentsBuffer(FireCount: number)
	local Buffer = {}
	local Count: number = #self.Signal.PreBoundArguments
	local Count2: number = Count + FireCount
	
	for Index: number, Argument: any in self.Signal.PreBoundArguments do
		Buffer[Index] = Argument
	end
	
	for Index: number = Count + 1, Count + FireCount do
		Buffer[Index] = `__PLACEHOLDER__`
	end
	
	for Index: number = Count2 + 1, Count2 + #self.PostBoundArguments do
		Buffer[Index] = self.PostBoundArguments[Index - Count2]
	end
	
	self.ArgumentsBuffer = Buffer
	table.clear(self.PostBoundArguments)
	self.PostBoundArguments = nil
end

-------------------------------------------------------------------------------------------------------------------
function Connection:Disconnect()
	if self.PostBoundArguments then table.clear(self.PostBoundArguments) end
	if self.ArgumentsBuffer then table.clear(self.ArgumentsBuffer) end
	self.Signal.Connections[self] = nil
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
function Connection:Pause()
	self.Signal.Connections[self] = false
end

-------------------------------------------------------------------------------------------------------------------
function Connection:Resume()
	self.Signal.Connections[self] = true
end

-------------------------------------------------------------------------------------------------------------------
Connection.Destroy = Connection.Disconnect

-------------------------------------------------------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

-------------------------------------------------------------------------------------------------------------------
function Signal.new(...: any): Signal
	local self = setmetatable({}, Signal)
	
	self.Accessor = nil
	self.Connections = {}
	self.MainConnection = nil
	self.PreBoundArguments = table.pack(...)
	self.PreBindCount = #self.PreBoundArguments
	self.Behavior = Enum.SignalBehavior.Immediate
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function Signal.wrap(ExistingSignal: RBXScriptSignal, ...: any): Signal
	local self = setmetatable({}, Signal)
	
	self.Accessor = nil
	self.Connections = {}
	self.MainConnection = ExistingSignal:Connect(function(...) self:Fire(...) end)
	self.PreBoundArguments = table.pack(...)
	self.PreBindCount = #self.PreBoundArguments
	self.Behavior = Enum.SignalBehavior.Immediate
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function Signal.fromInstanceAccessor(Object: Instance, Accessor: string, ...: any): Signal
	local self = setmetatable({}, Signal)
	
	self.Accessor = Accessor
	self.Connections = {}
	self.MainConnection = Object[Accessor]:Connect(function(...) self:Fire(...) end)
	self.PreBoundArguments = table.pack(...)
	self.PreBindCount = #self.PreBoundArguments
	self.Behavior = Enum.SignalBehavior.Immediate
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function Signal:UpdateInstance(NewObject: Instance)
	if not self.Accessor then return end
	
	self.MainConnection:Disconnect()
	self.MainConnection = NewObject[self.Accessor]:Connect(function(...) self:Fire(...) end)
end

-------------------------------------------------------------------------------------------------------------------
function Signal:Connect(Listener: (...any) -> (), ...: any): Connection
	local Connection = Connection.new(self, Listener, table.pack(...))
	self.Connections[Connection] = true
	return Connection
end

-------------------------------------------------------------------------------------------------------------------
function Signal:Once(Listener: (...any) -> (), ...: any): Connection
	local Connection: Connection = self:Connect(function(...)
		if Connection and self.Connections[Connection] then Connection:Disconnect() end
		Listener(...)
	end, ...)

	return Connection
end

-------------------------------------------------------------------------------------------------------------------
function Signal:Wait()
	local TemporaryConnection: Connection? = nil
	local WaitCoroutine: thread = coroutine.running()

	local function WaitCallback(...)
		TemporaryConnection:Disconnect()
		if coroutine.status(WaitCoroutine) == `suspended` then task.spawn(WaitCoroutine, ...) end
	end

	TemporaryConnection = self:Connect(WaitCallback)
	return coroutine.yield()
end

-------------------------------------------------------------------------------------------------------------------
function Signal:Fire(...: any)
	local Count: number = select("#", ...)
	local Base = self.PreBindCount

	for InvokeConnection: Connection, Connected: boolean in self.Connections do
		if not InvokeConnection.ArgumentsBuffer then InvokeConnection:ConfigureArgumentsBuffer(Count) end
		if not Connected then continue end
		local Buffer: {any} = InvokeConnection.ArgumentsBuffer
		for Index: number = 1, Count do Buffer[Base + Index] = select(Index, ...) end
		HandleInvoker(InvokeConnection)
	end
end

-------------------------------------------------------------------------------------------------------------------
function Signal:DisconnectAll()
	for Connection: Connection, Connected: boolean in self.Connections do Connection:Disconnect() end
	if self.MainConnection then self.MainConnection:Disconnect() end
	table.clear(self.PreBoundArguments)
	table.clear(self.Connections)
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
Signal.Destroy = Signal.DisconnectAll

CleanupService:BindObjectToShutdown(ExecutorType)

-------------------------------------------------------------------------------------------------------------------
return Signal
