local CleanupService = {}

-------------------------------------------------------------------------------------------------------------------
local Players: Players = game:GetService(`Players`)
local RunService: RunService = game:GetService(`RunService`)

local Types = require(workspace.Types)
local Error = require(`../Libraries/Error`)

type Reason = Enum.CloseReason | Enum.PlayerExitReason
type CleanupCallback = (Reason: Reason) -> ()

local NotEligible: string = `Object Of Type: "%s" Is Not Eligible For Cleanup!`

-------------------------------------------------------------------------------------------------------------------
CleanupService.CleanupTypes 	= {}
CleanupService.CleanupScheduled = {}
CleanupService.CleanupCallbacks = {}

-------------------------------------------------------------------------------------------------------------------
function CleanupService.Server(Reason: Enum.CloseReason)
	for Index: number, Callback: CleanupCallback in CleanupService.CleanupCallbacks do Callback(Reason) end
	for Index: number, Object: any in CleanupService.CleanupScheduled do CleanupService:DestroyObject(Object) end
	if CleanupService.Connection then CleanupService.Connection:Disconnect() end -- game:BindToClose() returns
	-- nothing, so this key may or may not exist, hence nil check
	table.clear(CleanupService.CleanupScheduled)
	table.clear(CleanupService.CleanupCallbacks)
	table.clear(CleanupService.CleanupTypes)
	table.clear(CleanupService)
end

-------------------------------------------------------------------------------------------------------------------
function CleanupService.Client(Player: Player, Reason: Enum.PlayerExitReason)
	if Player ~= Players.LocalPlayer then return end
	for Index: number, Callback: CleanupCallback in CleanupService.CleanupCallbacks do Callback(Reason) end
	for Index: number, Object: any in CleanupService.CleanupScheduled do CleanupService:DestroyObject(Object) end
	if CleanupService.Connection then CleanupService.Connection:Disconnect() end
	table.clear(CleanupService.CleanupScheduled)
	table.clear(CleanupService.CleanupCallbacks)
	table.clear(CleanupService.CleanupTypes)
	table.clear(CleanupService)
end

-------------------------------------------------------------------------------------------------------------------
function CleanupService:DestroyObject(Object: any)
	local Type: string = typeof(Object)
	if not self.CleanupTypes[Type] then Error(NotEligible, `{Type}`) return end
	self.CleanupTypes[Type](Object)
end

-------------------------------------------------------------------------------------------------------------------
function CleanupService:DelayedDestroyObject(Time: number, Object: any)
	task.delay(Time, CleanupService.DestroyObject, CleanupService, Object)
end

-------------------------------------------------------------------------------------------------------------------
function CleanupService:BindToShutdown(Callback: CleanupCallback)
	table.insert(CleanupService.CleanupCallbacks, Callback)
end

-------------------------------------------------------------------------------------------------------------------
function CleanupService:BindObjectToShutdown(Object: any)
	table.insert(CleanupService.CleanupScheduled, Object)
end

-------------------------------------------------------------------------------------------------------------------
CleanupService.CleanupTypes.thread = task.cancel
CleanupService.CleanupTypes.SharedTable = SharedTable.clear

function CleanupService.CleanupTypes.Instance(Object: Instance)
	Object:Destroy()
end

function CleanupService.CleanupTypes.RBXScriptConnection(Connection: RBXScriptConnection)
	Connection:Disconnect()
end

function CleanupService.CleanupTypes.table(Table: {any})
	if Table.Destroy then Table:Destroy() else table.clear(Table) end
end

-------------------------------------------------------------------------------------------------------------------
CleanupService.Connection = RunService:IsClient() and
	Players.PlayerRemoving:Connect(CleanupService.Client) or game:BindToClose(CleanupService.Server)

-------------------------------------------------------------------------------------------------------------------
return CleanupService :: Types.CleanupService
