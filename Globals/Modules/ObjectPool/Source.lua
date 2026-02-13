--!optimize 2

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)
local Signal = require(`./Signal`)
local Error = require(`../Libraries/Error`)

type Callback = (Object: Instance) -> ()

local NotMember: string = `Object: "%s" Is Not A Member Of Object Pool.`
local Unretrieved: string = `Object: "%s" Was Attempted To Be Freed When It Was Never Retrieved From Object Pool.`

-------------------------------------------------------------------------------------------------------------------
function ObjectPool.new(Object: Instance, Count: number, Create: Callback?, Cleanup: Callback?): Types.ObjectPool
	local self = setmetatable({}, ObjectPool)
	
	self.Pool = {}
	self.Object = Object
	self.Count = Count or 0
	self.OnGet = Signal.new()
	self.OnFree = Signal.new()
	self.Create = Create or function(Object: Instance) return end
	self.Cleanup = Cleanup or function(Object: Instance) return end
	
	for Index: number = 1, self.Count do
		local Clone: Instance = Object:Clone()
		self.Pool[Clone] = true
		self.Create(Clone)
	end
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function ObjectPool:Get(): Instance
	for Object: Instance, Available: boolean in self.Pool do
		if not Available then continue end
		self.Pool[Object] = false
		self.OnGet:Fire(Object)
		return Object
	end
	
	local Clone: Instance = self.Object:Clone()
	self.Pool[Clone] = false
	self.Create(Clone)
	self.Count += 1
	self.OnGet:Fire(Clone)
	
	return Clone
end

-------------------------------------------------------------------------------------------------------------------
function ObjectPool:Free(Object: Instance)
	if self.Pool[Object] == nil then Error(NotMember, Object:GetFullName()) return end
	if self.Pool[Object] == true then Error(Unretrieved, Object:GetFullName()) return end
	self.Pool[Object] = true
	self.OnFree:Fire(Object)
end

-------------------------------------------------------------------------------------------------------------------
function ObjectPool:Destroy()
	for Object: Instance, Available: boolean in self.Pool do self.Cleanup(Object) Object:Destroy() end
	self.OnFree:DisconnectAll()
	self.OnGet:DisconnectAll()
	setmetatable(self, nil)
	table.clear(self.Pool)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
function ObjectPool:SetCount(NewCount: number)
	if NewCount <= 0 or NewCount == self.Count then return end
	
	if NewCount > self.Count then
		for Index: number = 1, NewCount - self.Count do
			local Clone: Instance = self.Object:Clone()
			self.Pool[Clone] = true
			self.Create(Clone)
		end
	else
		local Total: number, Destroyed: number = self.Count - NewCount, 0
		for Object: Instance, Available: boolean in self.Pool do
			if not Available then continue end
			self.Pool[Object] = nil
			self.Cleanup(Object)
			Object:Destroy()
			Destroyed += 1
			if Destroyed >= Total then break end
		end
	end
	
	self.Count = NewCount
end

-------------------------------------------------------------------------------------------------------------------
return table.freeze(ObjectPool)
