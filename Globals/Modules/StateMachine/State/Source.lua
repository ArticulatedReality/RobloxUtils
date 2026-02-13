--!optimize 2

local State = {}
State.__index = State

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)

local Signal = require(`../Signal`)
local Error: Types.Error = require(`../../Libraries/Error`)

type State = Types.State
type TransitionSet = Types.TransitionSet

local RewriteProperty: string = `Value: "%s" (Current: "%s") Tried To Be Written To Property: "%s" In State: "%s".`

-------------------------------------------------------------------------------------------------------------------
function State.new(Name: string, Machine: Types.StateMachine, From: TransitionSet, To: TransitionSet): State
	local self = setmetatable({}, State)

	self.Name = Name
	self.Machine = Machine

	self.Properties = {}
	self.TransitionTo = To
	self.TransitionFrom = From

	self.OnStop = Signal.new(self)
	self.OnStart = Signal.new(self)

	return self
end

-------------------------------------------------------------------------------------------------------------------
function State:RegisterProperty(Name: string, Value: any)
	if self.Properties[Name] then Error(RewriteProperty, self.Properties[Name], Value, Name, self.Name) return end
	self.Properties[Name] = Value
end

-------------------------------------------------------------------------------------------------------------------
function State:Destroy()
	if self.OnUpdate then self.OnUpdate:DisconnectAll() end
	self.OnStart:DisconnectAll()
	self.OnStop:DisconnectAll()

	table.clear(self.TransitionFrom)
	table.clear(self.TransitionTo)
	table.clear(self.Properties)

	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
return State
