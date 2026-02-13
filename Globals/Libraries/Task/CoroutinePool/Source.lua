local CoroutinePool = {}
CoroutinePool.__index = CoroutinePool

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)
local CoroutineCache = require(`@self/CoroutineCache`)

export type CoroutinePool = Types.CoroutinePool
export type CoroutineCache = Types.CoroutineCache

-------------------------------------------------------------------------------------------------------------------
function CoroutinePool.new(Count: number): CoroutinePool
	local self = setmetatable({}, CoroutinePool)
	
	self.Coroutines = {}
	self.Count = Count or 0
	
	for Index: number = 1, Count do self.Coroutines[CoroutineCache.new(self)] = true end
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function CoroutinePool:Get(): CoroutineCache
	for Index: CoroutineCache, Available: boolean in self.Coroutines do
		if not Available then continue end
		Index:Obtain()
		return Index
	end
	
	local NewCache: CoroutineCache = CoroutineCache.new(self)
	self.Coroutines[NewCache] = true
	NewCache:Obtain()
	self.Count += 1
	
	return NewCache
end

-------------------------------------------------------------------------------------------------------------------
function CoroutinePool:SetCount(NewCount: number)
	if NewCount == self.Count then return end
	
	if NewCount < self.Count then
		local Difference: number = self.Count - NewCount
		for Index: CoroutineCache, Available: boolean in self.Coroutines do
			Index:Close()
			Difference -= 1
			if Difference <= 0 then break end
		end
	else
		for Index: number = self.Count, NewCount do
			self.Coroutines[CoroutineCache.new(self)] = true
		end
	end
	
	self.Count = NewCount
end

-------------------------------------------------------------------------------------------------------------------
function CoroutinePool:Destroy()
	for Index: CoroutineCache, Available: boolean in self.Coroutines do Index:Close() end
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
return CoroutinePool.new(10) :: CoroutinePool
