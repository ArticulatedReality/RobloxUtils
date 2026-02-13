--!nocheck

export type Error = (Template: string, ...any) -> ()

-------------------------------------------------------------------------------------------------------------------
export type ConnectionBase = RBXScriptConnection | Connection

-------------------------------------------------------------------------------------------------------------------
export type SignalBase = RBXScriptSignal | Signal

-------------------------------------------------------------------------------------------------------------------
export type CoroutineCache = {
	Break: boolean,
	Coroutine: thread,
	Pool: CoroutinePool,
	Free: (self: CoroutineCache) -> (),
	Close: (self: CoroutineCache) -> (),
	Obtain: (self: CoroutineCache) -> (),
	Destroy: (self: CoroutineCache) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type CoroutinePool = {
	Count: number,
	Destroy: (self: CoroutinePool) -> (),
	Coroutines: {[CoroutineCache]: boolean},
	Get: (self: CoroutinePool) -> (CoroutineCache),
	SetCount: (self: CoroutinePool, NewCount: number) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type Task = {
	Sync: () -> (),
	Desync: () -> (),
	Wait: (number) -> (),
	Cancel: (Thread: thread) -> (),
	Spawn: (FunctionOrThread: (...any) -> () | thread, ...any) -> (),
	Defer: (FunctionOrThread: (...any) -> () | thread, ...any) -> (),
	RawSpawn: (FunctionOrThread: (...any) -> () | thread, ...any) -> (),
	RawDefer: (FunctionOrThread: (...any) -> () | thread, ...any) -> (),
	RawDelay: (Time: number, FunctionOrThread: (...any) -> () | thread, ...any) -> (),
	DelayBySeconds: (Time: number, FunctionOrThread: (...any) -> () | thread, ...any) -> (),
	DelayByFrames: (Frames: number, FunctionOrThread: (...any) -> () | thread, ...any) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type CleanupService = {
	DestroyObject: (self: CleanupService, Object: any) -> (),
	BindObjectToShutdown: (self: CleanupService, Object: any) -> (),
	DelayedDestroyObject: (self: CleanupService, Time: number, Object: any) -> (),
	BindToShutdown: (self: CleanupService, Callback: (Reason: Enum.CloseReason|Enum.PlayerExitReason) -> ()) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type Connection = {
	Signal: Signal,
	ArgumentBuffer: {any}?,
	Callback: (...any) -> (),
	PostBoundArguments: {any}?,
	Pause: (self: Connection) -> (),
	Resume: (self: Connection) -> (),
	Destroy: (self: Connection) -> (),
	Disconnect: (self: Connection) -> (),
	ConfigureArgumentBuffer: (self: Connection) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type Signal = {
	Accessor: string?,
	FireCount: number?,
	PreBindCount: number,
	PreBoundArguments: {any},
	Wait: (self: Signal) -> (),
	Behavior: Enum.SignalBehavior,
	Destroy: (self: Signal) -> (),
	Fire: (self: Signal, ...any) -> (),
	DisconnectAll: (self: Signal) -> (),
	MainConnection: RBXScriptConnection?,
	Connections: {[Connection]: boolean?},
	wrap: (ExistingSignal: RBXScriptSignal, ...any) -> (),
	UpdateInstance: (self: Signal, NewObject: Instance) -> (),
	Once: (self: Signal, Callback: (...any) -> (), ...any) -> (Connection),
	Connect: (self: Signal, Callback: (...any) -> (), ...any) -> (Connection),
	fromInstanceAccessor: (Object: Instance, Accessor: string, ...any) -> (Signal),
}

-------------------------------------------------------------------------------------------------------------------
export type ConnectionManager = {
	Name: string,
	Connections: {[any]: ConnectionBase},
	Destroy: (self: ConnectionManager) -> (),
	ReleaseAll: (self: ConnectionManager) -> (),
	ReleaseConnection: (self: ConnectionManager, Key: any) -> (),
	GetConnection: (self: ConnectionManager, Key: any) -> (ConnectionBase),
	AddConnection: (self: ConnectionManager, Key: any, Connection: ConnectionBase) -> (),
	ReplaceConnection: (self: ConnectionManager, Key: any, Connection: ConnectionBase) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type Goal = {[string]: any}

-------------------------------------------------------------------------------------------------------------------
export type SmoothDamp = {
	Target: any,
	Current: any,
	Velocity: any,
	MaxSpeed: number?,
	SmoothTime: number,
	Connection: RBXScriptConnection,
	Destroy: (self: SmoothDamp) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type BetterTweenService = {
	OnceLocal: (self: BetterTweenService, Object: Instance, Info: TweenInfo, Goal: Goal) -> (),
	CreateReplicated: (self: BetterTweenService, Object: Instance, Info: buffer, Goal: Goal) -> (),
	CreateLocal: (self: BetterTweenService, Object: Instance, Info: TweenInfo, Goal: Goal) -> (Tween),
	CreateReplicatedForGroup: (self: BetterTweenService, Object: Instance, Info: buffer, Goal: Goal, Group: {Player}) -> (),
	GetValue: (self: BetterTweenService, Alpha: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection) -> (number),
	CreateSmoothDamp: (self: BetterTweenService, Current: any, Target: any, Velocity: any, SmoothTime: number, MaxSpeed: number?) -> (SmoothDamp),
	TweenInfo: (self: BetterTweenService, Time: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection, Repeat: number, Reverses: boolean, DelayTime: number) -> (buffer),
}

-------------------------------------------------------------------------------------------------------------------
export type InstanceHelper = {
	ResolvePath: (Path: string) -> (Instance?),
	SetProperty: (Object: Instance, Property: string, Value: any) -> (),
	SetProperties: (Object: Instance, Properties: {[string]: any}, GCTable: boolean?) -> (),
	WaitForChildOfClass: (Object: Instance, ChildClass: string, Timeout: number?) -> (Instance?),
	WaitForChildWhichIsA: (Object: Instance, ChildClass: string, Timeout: number?) -> (Instance?),
	CreateInstance: (ClassName: string, Properties: {[string]: any}?, GCTable: boolean?) -> (Instance),
}

-------------------------------------------------------------------------------------------------------------------
export type BetterRunService = {
	Heartbeat: Signal,
	PreRender: Signal,
	Environment: string,
	PreAnimation: Signal,
	PreSimulation: Signal,
	Simulation1Hz: Signal,
	Simulation5Hz: Signal,
	PostSimulation: Signal,
	Simulation10Hz: Signal,
	Simulation15Hz: Signal,
	Simulation30Hz: Signal,
	Simulation60Hz: Signal,
	GetPredictionStatus: (self: BetterRunService, Object: Instance) -> (Enum.PredictionStatus),
	SetPredictionMode: (self: BetterRunService, Object: Instance, Mode: Enum.PredictionMode) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type Animation1D = {
	Fade: number,
	Current: AnimationTrack,
	Connections: ConnectionManager,
	MarkerReached: {[string]: Signal},
	Destroy: (self: Animation1D) -> (),
	SwitchAnimation: (self: Animation1D, New: string) -> (),
	Tracks: {Positive: AnimationTrack, Negative: AnimationTrack},
	SetSpeedAndWeight: (self: Animation1D, Speed: number, Weight: number) -> (),
	UpdateParameters: (self: Animation1D, ToPlay: string, Speed: number, Weight: number) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type ObjectPool = {
	OnGet: Signal,
	Count: number,
	OnFree: Signal,
	Object: Instance,
	Pool: {[Instance]: boolean},
	Create: (Object: Instance) -> (),
	Cleanup: (Object: Instance) -> (),
	Destroy: (self: ObjectPool) -> (),
	Get: (self: ObjectPool) -> (Instance),
	Free: (self: ObjectPool, Object: Instance) -> (),
	SetCount: (self: ObjectPool, NewCount: number) -> ()
}

-------------------------------------------------------------------------------------------------------------------
export type Observer = {
	Value: any,
	ID: string,
	Changed: Signal,
	Object: Instance,
	Type: Enums.Observer,
	Signal: RBXScriptSignal,
	Connection: RBXScriptConnection,
	Destroy: (self: Observer) -> (),
	UpdateInstance: (self: Observer, NewObject: Instance) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type RegistryService = {
	GetSharedTable: (self: RegistryService, Name: string) -> SharedTable?,
	SetSharedTable: (self: RegistryService, Name: string, Table: SharedTable) -> (),
	WaitForSharedTable: (self: RegistryService, Name: string, Timeout: number?) -> SharedTable?,
}

-------------------------------------------------------------------------------------------------------------------
export type TransitionSet = {[string]: {[string]: boolean}}

-------------------------------------------------------------------------------------------------------------------
export type State = {
	Name: string,
	OnStop: Signal,
	OnStart: Signal,
	OnUpdate: Signal?,
	Machine: StateMachine,
	TransitionTo: TransitionSet,
	Properties: {[string]: any},
	Destroy: (self: State) -> (),
	TransitionFrom: TransitionSet,
	RegisterProperty: (self: State, Name: string, Value: any) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type StateMachineOOP = {
	Name: string,
	States: {[string]: State},
	BaseState: string?,
	Incomplete: boolean,
	CurrentState: string?,
	Parameters: {[string]: any},
	Connection: RBXScriptConnection?,
	Destroy: (self: StateMachineOOP) -> (),
	ChangeState: (self: StateMachineOOP, NewState: string) -> (),
	RegisterProperty: (self: StateMachineOOP, Name: string, PropertyTable: {[string]: any}) -> (),
	RegisterState: (self: StateMachineOOP, Name: string, From: TransitionSet, To: TransitionSet) -> (),
	RegisterBaseState: (self: StateMachineOOP, Name: string, From: TransitionSet, To: TransitionSet) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type StateMachineECS = {
	Name: string,
	States: {[string]: State},
	BaseState: State?,
	Incomplete: boolean,
	Connection: RBXScriptConnection?,
	Destroy: (self: StateMachineECS) -> (),
	Participants: {[Instance]: {[string]: any}},
	RemoveParticipant: (self: StateMachineECS, Participant: Instance) -> (),
	ChangeState: (self: StateMachineECS, NewState: string, Participant: Instance) -> (),
	RegisterProperty: (self: StateMachineECS, Name: string, PropertyTable: {[string]: any}) -> (),
	RegisterState: (self: StateMachineECS, Name: string, From: TransitionSet, To: TransitionSet) -> (),
	RegisterBaseState: (self: StateMachineECS, Name: string, From: TransitionSet, To: TransitionSet) -> (),
	AddParticipant: (self: StateMachineECS, Participant: Instance, Parameters: {[string]: any}, InitialState: string?) -> (),
}

-------------------------------------------------------------------------------------------------------------------
export type StateMachine = StateMachineOOP | StateMachineECS

-------------------------------------------------------------------------------------------------------------------
return true
