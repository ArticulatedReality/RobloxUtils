local InstanceHelper = {}

-------------------------------------------------------------------------------------------------------------------
local RunService: RunService = game:GetService(`RunService`)

local Types = require(workspace.Types)

local Task: Types.Task = require(`./Task`)
local Error: Types.Error = require(`./Error`)

local InvalidPath: string = `Error Resolving Path, Object: "%s" Has No Child "%s".`
local TimedOut: string = `Wait Request Timed Out For Object: "%s" To Find Child Of Class: "%s".`

-------------------------------------------------------------------------------------------------------------------
function InstanceHelper.SetProperty(Object: Instance, Property: string, Value: any)
	Object[Property] = Value
end

-------------------------------------------------------------------------------------------------------------------
function InstanceHelper.SetProperties(Object: Instance, Properties: {[string]: any}, GCTable: boolean?)
	for Property, Value in Properties do
		if Property == `Parent` then continue end
		Object[Property] = Value
	end
	
	if Properties.Parent then Object.Parent = Properties.Parent end
	
	GCTable = GCTable or false
	if not GCTable then return end
	Task.Spawn(table.clear, Properties)
end

-------------------------------------------------------------------------------------------------------------------
function InstanceHelper.CreateInstance(ClassName: string, Properties: {[string]: any}?, GCData: boolean?): Instance
	local Object: Instance = Instance.new(ClassName)
	if not Properties then return Object end
	InstanceHelper.SetProperties(Object, Properties, GCData)
	return Object
end

-------------------------------------------------------------------------------------------------------------------
function InstanceHelper.ResolvePath(Path: string): Instance?
	local Current: Instance? = game
	
	for Index: number, Next: string in string.split(Path, `.`) do
		local Child: Instance? = Current:FindFirstChild(Next)
		if not Child then Error(InvalidPath, Current:GetFullName(), Next) return end
		Current = Child
	end
	
	return Current
end

-------------------------------------------------------------------------------------------------------------------
function InstanceHelper.WaitForChildOfClass(Object: Instance, ChildClass: string, Timeout: number?): Instance?
	local Child: Instance? = Object:FindFirstChildOfClass(ChildClass)
	if Child then return Child end

	Timeout = Timeout or 10
	local Elapsed: number = 0
	local Found: boolean = false
	
	local Connection: RBXScriptConnection = Object.ChildAdded:Connect(function(AddedChild: Instance)
		if AddedChild.ClassName ~= ChildClass then return end Child = AddedChild Found = true
	end)
	
	Child = Object:FindFirstChildOfClass(ChildClass)
	if Child then Connection:Disconnect() return Child end

	while not Found do
		Elapsed += RunService.Heartbeat:Wait()
		if Elapsed > Timeout then break end
	end

	Connection:Disconnect()
	return Child or Error(TimedOut, Object:GetFullName(), ChildClass)
end

-------------------------------------------------------------------------------------------------------------------
function InstanceHelper.WaitForChildWhichIsA(Object: Instance, ChildClass: string, Timeout: number?): Instance?
	local Child: Instance? = Object:FindFirstChildWhichIsA(ChildClass)
	if Child then return Child end

	Timeout = Timeout or 10
	local Elapsed: number = 0
	local Found: boolean = false
	
	local Connection: RBXScriptConnection = Object.ChildAdded:Connect(function(AddedChild: Instance)
		if not AddedChild:IsA(ChildClass) then return end Child = AddedChild Found = true
	end)
	
	Child = Object:FindFirstChildWhichIsA(ChildClass)
	if Child then Connection:Disconnect() return Child end

	while not Found do
		Elapsed += RunService.Heartbeat:Wait()
		if Elapsed > Timeout then break end
	end

	Connection:Disconnect()
	return Child or Error(TimedOut, Object:GetFullName(), ChildClass)
end

-------------------------------------------------------------------------------------------------------------------
return table.freeze(InstanceHelper) :: Types.InstanceHelper
