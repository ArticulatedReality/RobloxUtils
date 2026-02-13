--!optimize 2

local Types = require(workspace.Types)

local Signal = require(`./Signal`)
local State = require(`@self/State`)
local Error: Types.Error = require(`../Libraries/Error`)

type State = Types.State
type TransitionSet= Types.TransitionSet
type FSMOOP = Types.StateMachineOOP
type FSMECS = Types.StateMachineECS

local MissingParticipant: string = `State Machine: "%s" Has No Participant: "%s".`
local RewriteParticipant: string = `State Machine: "%s" Already Has Participant: "%s".`

local RewriteProperty: string = `All States In State Machine: "%s" Already Have Property With Name: "%s".`
local MissingBaseState: string = `Tried To Set Property: "%s" In State Machine: "%s" Before State Registration.`

local Incomplete: string = `Method: "%s" Called On State Machine: "%s" Before It Was Initialized.`
local InvalidTransition: string = `State: "%s" In State Machine: "%s" Can't Change To State: "%s". Check Sets.`
local RewriteState: string = `State: "%s" Pre-Exists In State Machine: "%s" But Was Tried To Be Registered Again.`
local SameState: string = `State: "%s" Already Current State In State Machine: "%s". But Tried Transition Anyway.`
local RewriteBase: string = `StateMachine: "%s" Has Base State: "%s", But State: "%s" Tried To Become Base State.`
local InvalidState: string = `State: "%s" Does Not Exist In State Machine: "%s". But Tried To Be Transitioned To.`

-------------------------------------------------------------------------------------------------------------------
local StateMachineOOP = {}
StateMachineOOP.__index = StateMachineOOP

-------------------------------------------------------------------------------------------------------------------
function StateMachineOOP.new(Name: string, Parameters: {[string]: any}, UpdateSignal: Types.SignalBase?): FSMOOP
	local self = setmetatable({}, StateMachineOOP)
	
	self.Name = Name
	self.States = {}
	self.BaseState = nil
	self.Incomplete = true
	self.CurrentState = nil
	self.Parameters = Parameters
	self.Connection = UpdateSignal and UpdateSignal:Connect(function(...: any)
		if self.Incomplete or not self.CurrentState then return end
		self.States[self.CurrentState].OnUpdate:Fire(self.Parameters, ...)
	end) or nil
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineOOP:RegisterState(Name: string, From: TransitionSet, To: TransitionSet)
	if self.States[Name] then Error(RewriteState, Name, self.Name) return end
	local NewState: State = State.new(Name, self, From, To)
	self.States[Name] = NewState
	if not self.Connection then return end
	NewState.OnUpdate = Signal.new(NewState)
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineOOP:RegisterBaseState(Name: string, From: TransitionSet, To: TransitionSet)
	if self.States[Name] then Error(RewriteState, Name, self.Name) return end
	if self.BaseState then Error(RewriteBase, self.Name, self.BaseState.Name, Name) return end
	
	self:RegisterState(Name, From, To)
	if not self.CurrentState then self.CurrentState = Name end
	self.BaseState = self.States[Name]
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineOOP:ChangeState(NewState: string)
	if self.Incomplete then Error(Incomplete, `ChangeState`, self.Name) return end
	if not self.States[NewState] then Error(InvalidState, NewState, self.Name) return end
	if self.CurrentState == NewState then Error(SameState, NewState, self.Name) return end
	
	local CurrentState: State = self.States[self.CurrentState]
	local NextState: State = self.States[NewState]
	
	if not CurrentState.TransitionTo[NewState] or not NextState.TransitionFrom[CurrentState.Name] then
		Error(InvalidTransition, CurrentState.Name, self.Name, NextState.Name) return
	end
	
	CurrentState.OnStop:Fire(self.Parameters)
	self.CurrentState = NewState
	NextState.OnStart:Fire(self.Parameters)
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineOOP:RegisterProperty(Name: string, PropertyTable: {[string]: any})
	if not self.BaseState then Error(MissingBaseState, Name, self.Name) return end
	if self.BaseState.Properties[Name] then Error(RewriteProperty, self.Name, Name) return end
	
	for StateName: string, State: State in self.States do
		State:RegisterProperty(Name, PropertyTable[StateName])
	end
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineOOP:Destroy()
	if self.Connection then self.Connection:Disconnect() end
	if self.CurrentState then self.States[self.CurrentState].OnStop:Fire(self.Parameters) end
	for Index: string, State: State in self.States do State:Destroy() end
	table.clear(self.States)
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
local StateMachineECS = {}
StateMachineECS.__index = StateMachineECS

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS.new(Name: string, UpdateSignal: Types.SignalBase?): FSMECS
	local self = setmetatable({}, StateMachineECS)
	
	self.Name = Name
	self.States = {}
	self.BaseState = nil
	self.Incomplete = true
	self.Participants = {}
	self.Connection = UpdateSignal and UpdateSignal:Connect(function(...: any)
		if self.Incomplete then return end
		for _: Instance, Parameters: {[string]: any} in self.Participants do
			self.States[Parameters.CurrentState].OnUpdate:Fire(Parameters, ...)
		end
	end) or nil
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:RegisterState(Name: string, From: TransitionSet, To: TransitionSet)
	if self.States[Name] then Error(RewriteState, Name, self.Name) return end
	local NewState: State = State.new(Name, self, From, To)
	self.States[Name] = NewState
	if not self.Connection then return end
	NewState.OnUpdate = Signal.new(NewState)
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:RegisterBaseState(Name: string, From: TransitionSet, To: TransitionSet)
	if self.States[Name] then Error(RewriteState, Name, self.Name) return end
	if self.BaseState then Error(RewriteBase, self.Name, self.BaseState.Name, Name) return end

	self:RegisterState(Name, From, To)
	for _: Instance, Parameters: {[string]: any} in self.Participants do Parameters.CurrentState = Name end
	self.BaseState = self.States[Name]
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:ChangeState(NewState: string, Participant: Instance)
	if self.Incomplete then Error(Incomplete, `ChangeState`, self.Name) return end
	if not self.States[NewState] then Error(InvalidState, NewState, self.Name) return end
	
	local Parameters: {[string]: any} = self.Participants[Participant]
	if not Parameters then Error(MissingParticipant, self.Name, Participant:GetFullName()) return end

	local CurrentState: State = self.States[Parameters.CurrentState]
	local NextState: State = self.States[NewState]

	if not CurrentState.TransitionTo[NewState] or not NextState.TransitionFrom[CurrentState.Name] then
		Error(InvalidTransition, CurrentState.Name, self.Name, NextState.Name) return
	end

	CurrentState.OnStop:Fire(NextState, Participant, Parameters)
	Parameters.CurrentState = NewState
	NextState.OnStart:Fire(CurrentState, Participant, Parameters)
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:RegisterProperty(Name: string, PropertyTable: {[string]: any})
	if not self.BaseState then Error(MissingBaseState, Name, self.Name) return end
	if self.BaseState.Properties[Name] then Error(RewriteProperty, self.Name, Name) return end
	
	for StateName: string, State: State in self.States do
		State:RegisterProperty(Name, PropertyTable[StateName])
	end
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:AddParticipant(Participant: Instance, Parameters: {[string]: any}, InitialState: string?)
	if self.Incomplete then Error(Incomplete, `AddParticipant`, self.Name) return end
	if self.Participants[Participant] then
		Error(RewriteParticipant, Participant:GetFullName(), self.Name) return
	end
	
	local StateToConsider: string = InitialState or self.BaseState.Name
	local ValidState: string = self.States[StateToConsider] and StateToConsider or self.BaseState.Name
	local CurrentState: State = self.States[ValidState]
	
	Parameters.CurrentState = ValidState
	self.Participants[Participant] = Parameters
	CurrentState.OnStart:Fire(nil, Participant, Parameters)
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:RemoveParticipant(Participant: Instance)
	if self.Incomplete then Error(Incomplete, `RemoveParticipant`, self.Name) return end
	if not self.Participants[Participant] then
		Error(MissingParticipant, self.Name, Participant:GetFullName()) return 
	end
	
	local Parameters: {[string]: any} = self.Participants[Participant]
	local CurrentState: State = self.States[Parameters.CurrentState]
	CurrentState.OnStop:Fire(nil, Participant, Parameters)
	self.Participants[Participant] = nil
end

-------------------------------------------------------------------------------------------------------------------
function StateMachineECS:Destroy()
	if self.Connection then self.Connection:Disconnect() end
	for Participant: Instance, _: {[string]: any} in self.Participants do self:RemoveParticipant(Participant) end
	for Name: string, State: State in self.States do State:Destroy() end
	table.clear(self.Participants)
	table.clear(self.States)
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
return {OOP = StateMachineOOP, ECS = StateMachineECS}

--[[
Usage:

1. Create State Machine.
2. Register Base State With Transitions.
3. Register All States With Transitions.
4. Register properties of Every State.
5. Connect Callbacks To States' Start, Stop, Update Signals.
6. Toggle Incomplete Flag.
7. Add Participants If ECS.
]]
