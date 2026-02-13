local SmoothDamp = {}
SmoothDamp.__index = SmoothDamp

-------------------------------------------------------------------------------------------------------------------
local RunService: RunService = game:GetService(`RunService`)
local TweenService: TweenService = game:GetService(`TweenService`)
local ReplicatedStorage: ReplicatedStorage = game:GetService(`ReplicatedStorage`)

local Remote: RemoteEvent = ReplicatedStorage.Globals.Remotes.Tween

local Types = require(workspace.Types)

type Goal = Types.Goal

-------------------------------------------------------------------------------------------------------------------
function SmoothDamp.new(Current: any, Target: any, Velocity: any, SmoothTime: number, MaxSpeed: number?)
	local self = setmetatable({}, SmoothDamp)
	
	self.Current = Current
	self.Target = Target
	self.Velocity = Velocity
	self.SmoothTime = SmoothTime
	self.MaxSpeed = MaxSpeed or nil
	
	self.Connection = RunService.Heartbeat:Connect(function(DeltaTime: number)
		self.Current, self.Velocity = TweenService:SmoothDamp(self.Current, self.Target, self.Velocity, self.SmoothTime, self.MaxSpeed, DeltaTime)
	end)
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function SmoothDamp:Destroy()
	self.Connection:Disconnect()
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
local BetterTweenService = {}

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:TweenInfo(Time: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection, Repeat: number, Reverses: boolean, DelayTime: number): buffer
	local Buffer: buffer = buffer.create(12)
	
	buffer.writef32(Buffer, 0, Time)
	buffer.writeu8(Buffer, 4, Style and Style.Value or 1)
	buffer.writeu8(Buffer, 5, Direction and Direction.Value or 1)
	buffer.writeu8(Buffer, 6, Repeat or 0)
	buffer.writeu8(Buffer, 7, Reverses and 1 or 0)
	buffer.writef32(Buffer, 8, DelayTime or 0)
	
	return Buffer
end

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:CreateLocal(Object: Instance, Info: TweenInfo, Goal: Goal): Tween
	return TweenService:Create(Object, Info, Goal)
end

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:OnceLocal(Object: Instance, Info: TweenInfo, Goal: Goal)
	local Tween: Tween = TweenService:Create(Object, Info, Goal)
	Tween.Completed:Once(function(PlaybackState: Enum.PlaybackState) Tween:Destroy() end)
	Tween:Play()
end

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:CreateReplicated(Object: Instance, Info: buffer, Goal: Goal)
	if RunService:IsServer() then
		Remote:FireAllClients(Object, Info, Goal)
	else
		Remote:FireServer(`Create`, Object, Info, Goal)
	end
end

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:CreateReplicatedForGroup(Object: Instance, Info: buffer, Goal: Goal, Group: {Player})	
	if RunService:IsServer() then
		for Index: number, Player: Player in Group do Remote:FireClient(Player, Object, Info, Goal) end
	else
		Remote:FireServer(`Group`, Object, Info, Goal, Group)
	end
end

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:GetValue(Alpha: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection)
	return TweenService:GetValue(Alpha, Style, Direction)
end

-------------------------------------------------------------------------------------------------------------------
function BetterTweenService:CreateSmoothDamp(Current: any, Target: any, Velocity: any, SmoothTime: number, MaxSpeed: number?)
	return SmoothDamp.new(Current, Target, Velocity, SmoothTime, MaxSpeed)
end

-------------------------------------------------------------------------------------------------------------------
return table.freeze(BetterTweenService) :: Types.BetterTweenService
