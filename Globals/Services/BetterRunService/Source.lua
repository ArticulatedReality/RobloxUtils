local BetterRunService = {}

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)

local RunService: RunService = game:GetService(`RunService`)

local Signal = require(`../Modules/Signal`)
local CleanupService: Types.CleanupService = require(`./CleanupService`)

-------------------------------------------------------------------------------------------------------------------
BetterRunService.Environment = RunService:IsServer() and `Server` or `Client`

-------------------------------------------------------------------------------------------------------------------
function BetterRunService:GetPredictionStatus(Object: Instance): Enum.PredictionStatus
	return RunService:GetPredictionStatus(Object)
end

-------------------------------------------------------------------------------------------------------------------
function BetterRunService:SetPredictionMode(Object: Instance, Mode: Enum.PredictionMode)
	return RunService:SetPredictionMode(Object, Mode)
end

-------------------------------------------------------------------------------------------------------------------
BetterRunService.Heartbeat = Signal.wrap(RunService.Heartbeat)
BetterRunService.PreRender = Signal.wrap(RunService.PreRender)
BetterRunService.PreAnimation = Signal.wrap(RunService.PreAnimation)
BetterRunService.PreSimulation = Signal.wrap(RunService.PreSimulation)
BetterRunService.PostSimulation = Signal.wrap(RunService.PostSimulation)

-------------------------------------------------------------------------------------------------------------------
BetterRunService.Simulation1Hz  = Signal.new()
BetterRunService.Simulation5Hz  = Signal.new()
BetterRunService.Simulation10Hz = Signal.new()
BetterRunService.Simulation15Hz = Signal.new()
BetterRunService.Simulation30Hz = Signal.new()
BetterRunService.Simulation60Hz = Signal.new()

-------------------------------------------------------------------------------------------------------------------
CleanupService:BindObjectToShutdown(RunService:BindToSimulation(function(DeltaTime: number)
	BetterRunService.Simulation1Hz:Fire(DeltaTime)
end, Enum.StepFrequency.Hz1))

CleanupService:BindObjectToShutdown(RunService:BindToSimulation(function(DeltaTime: number)
	BetterRunService.Simulation5Hz:Fire(DeltaTime)
end, Enum.StepFrequency.Hz5))

CleanupService:BindObjectToShutdown(RunService:BindToSimulation(function(DeltaTime: number)
	BetterRunService.Simulation10Hz:Fire(DeltaTime)
end, Enum.StepFrequency.Hz10))

CleanupService:BindObjectToShutdown(RunService:BindToSimulation(function(DeltaTime: number)
	BetterRunService.Simulation15Hz:Fire(DeltaTime)
end, Enum.StepFrequency.Hz15))

CleanupService:BindObjectToShutdown(RunService:BindToSimulation(function(DeltaTime: number)
	BetterRunService.Simulation30Hz:Fire(DeltaTime)
end, Enum.StepFrequency.Hz30))

CleanupService:BindObjectToShutdown(RunService:BindToSimulation(function(DeltaTime: number)
	BetterRunService.Simulation60Hz:Fire(DeltaTime)
end, Enum.StepFrequency.Hz60))

CleanupService:BindObjectToShutdown(BetterRunService.Simulation1Hz)
CleanupService:BindObjectToShutdown(BetterRunService.Simulation5Hz)
CleanupService:BindObjectToShutdown(BetterRunService.Simulation10Hz)
CleanupService:BindObjectToShutdown(BetterRunService.Simulation15Hz)
CleanupService:BindObjectToShutdown(BetterRunService.Simulation30Hz)
CleanupService:BindObjectToShutdown(BetterRunService.Simulation60Hz)

CleanupService:BindObjectToShutdown(BetterRunService.Heartbeat)
CleanupService:BindObjectToShutdown(BetterRunService.PreRender)
CleanupService:BindObjectToShutdown(BetterRunService.PreAnimation)
CleanupService:BindObjectToShutdown(BetterRunService.PreSimulation)
CleanupService:BindObjectToShutdown(BetterRunService.PostSimulation)

-------------------------------------------------------------------------------------------------------------------
return table.freeze(BetterRunService) :: Types.BetterRunService
