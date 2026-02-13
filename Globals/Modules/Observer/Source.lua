--!optimize 2

local Observer = {}
Observer.__index = Observer

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)
local Signal = require(`./Signal`)
local Enums = require(`./Enums`)

-------------------------------------------------------------------------------------------------------------------
function Observer.new(Object: Instance, ID: string, Type: Enums.Observer): Types.Observer
	local self = setmetatable({}, Observer)
	
	self.ID = ID
	self.Type = Type
	self.Object = Object
	self.Changed = Signal.new()
	self.Signal = Object[`Get{self.Type}ChangedSignal`](self.Object, self.ID)
	self.Value = (self.Type == `Property`) and self.Object[self.ID] or self.Object:GetAttribute(self.ID)
	self.Connection = self.Signal:Connect(function()
		local Old: any = self.Value
		self.Value = (self.Type == `Property`) and self.Object[self.ID] or self.Object:GetAttribute(self.ID)
		self.Changed:Fire(Old, self.Value)
	end)
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function Observer:UpdateInstance(NewObject: Instance)
	self.Connection:Disconnect()
	self.Object = NewObject
	self.Signal = self.Object[`Get{self.Type}ChangedSignal`](self.Object, self.ID)
	self.Value = (self.Type == `Property`) and self.Object[self.ID] or self.Object:GetAttribute(self.ID)
	self.Connection = self.Signal:Connect(function()
		local Old: any = self.Value
		self.Value = (self.Type == `Property`) and self.Object[self.ID] or self.Object:GetAttribute(self.ID)
		self.Changed:Fire(Old, self.Value)
	end)
end

-------------------------------------------------------------------------------------------------------------------
function Observer:Destroy()
	self.Connection:Disconnect()
	self.Changed:DisconnectAll()
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
return Observer
