local CoroutineCache = {}
CoroutineCache.__index = CoroutineCache

-------------------------------------------------------------------------------------------------------------------
local Error = require(`../../Error`)
local Types = require(workspace.Types)

local InUse: string = `Attempted To Obtain CoroutineCache While It Is Busy. Check Your Logic!`
local Free:  string = `Attempted To Free/Execute CoroutineCache While It Is Free. Check Your Logic!`

export type CoroutinePool = Types.CoroutinePool
export type CoroutineCache = Types.CoroutineCache

-------------------------------------------------------------------------------------------------------------------
local function RunCallback(Callback: (...any) -> (), ...: any)
	if not Callback then return end
	Callback(...)
end

-------------------------------------------------------------------------------------------------------------------
local function Runner(Cache: CoroutineCache)
	while true do
		if Cache.Break then break end
		RunCallback(coroutine.yield())
		Cache:Free()
	end
end

-------------------------------------------------------------------------------------------------------------------
function CoroutineCache.new(Pool: CoroutinePool): CoroutineCache
	local self = setmetatable({}, CoroutineCache)
	
	self.Pool = Pool
	self.Break = false
	self.Coroutine = coroutine.create(Runner)
	
	self.Pool.Coroutines[self] = true
	coroutine.resume(self.Coroutine, self)
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function CoroutineCache:Obtain()
	if not self.Pool.Coroutines[self] then Error(InUse) return end
	self.Pool.Coroutines[self] = false
end

-------------------------------------------------------------------------------------------------------------------
function CoroutineCache:Free()
	if self.Pool.Coroutines[self] then Error(Free) return end
	self.Pool.Coroutines[self] = true
end

-------------------------------------------------------------------------------------------------------------------
function CoroutineCache:Close()
	if not self.Pool.Coroutines[self] then task.defer(self.Close, self) return end
	self.Break = true
	coroutine.resume(self.Coroutine, self)
	coroutine.close(self.Coroutine)
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
CoroutineCache.Destroy = CoroutineCache.Close

-------------------------------------------------------------------------------------------------------------------
return CoroutineCache
