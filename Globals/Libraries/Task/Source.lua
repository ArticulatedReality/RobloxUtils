local Task = {}

-------------------------------------------------------------------------------------------------------------------
local RunService: RunService = game:GetService(`RunService`)

local Types = require(workspace.Types)
local CoroutinePool = require(`@self/CoroutinePool`)

type Task = Types.Task
type CoroutinePool = Types.CoroutinePool
type CoroutineCache = Types.CoroutineCache

-------------------------------------------------------------------------------------------------------------------
Task.Wait = task.wait
Task.Cancel = task.cancel
Task.RawSpawn = task.spawn
Task.RawDefer = task.defer
Task.RawDelay = task.delay
Task.Sync = task.synchronize
Task.Desync = task.desynchronize

-------------------------------------------------------------------------------------------------------------------
local function YieldForFrames(Amount: number)
	local Index: number = 0
	for Index: number = 1, Amount do RunService.Heartbeat:Wait() end
end

-------------------------------------------------------------------------------------------------------------------
local function ThreadFrames(Frames: number, Callback: thread, ...: any)
	YieldForFrames(Frames)
	task.spawn(Callback, ...)
end

-------------------------------------------------------------------------------------------------------------------
local function FunctionFrames(Frames: number, Callback: (...any) -> (), ...: any)
	YieldForFrames(Frames)
	Callback(...)
end

-------------------------------------------------------------------------------------------------------------------
function Task.Spawn(Callback: (...any) -> () | thread, ...: any)
	if typeof(Callback) == `thread` then task.spawn(Callback, ...) return end
	local Cache: CoroutineCache = CoroutinePool:Get()
	task.spawn(Cache.Coroutine, Callback, ...)
end

-------------------------------------------------------------------------------------------------------------------
function Task.Defer(Callback: (...any) -> () | thread, ...: any)
	if typeof(Callback) == `thread` then task.defer(Callback, ...) return end
	local Cache: CoroutineCache = CoroutinePool:Get()
	task.defer(Cache.Coroutine, Callback, ...)
end

-------------------------------------------------------------------------------------------------------------------
function Task.DelayBySeconds(Time: number, Callback: (...any) -> () | thread, ...: any)
	if typeof(Callback) == `thread` then task.delay(Time, Callback, ...) return end
	local Cache: CoroutineCache = CoroutinePool:Get()
	task.delay(Time, Cache.Coroutine, Callback, ...)
end

-------------------------------------------------------------------------------------------------------------------
function Task.DelayByFrames(Frames: number, Callback: (...any) -> () | thread, ...: any)
	local Cache: CoroutineCache = CoroutinePool:Get()
	if typeof(Callback) == `thread` then task.spawn(Cache.Coroutine, ThreadFrames, Frames, Callback, ...) return end
	task.spawn(Cache.Coroutine, FunctionFrames, Frames, Callback, ...)
end

-------------------------------------------------------------------------------------------------------------------
return table.freeze(Task) :: Task
