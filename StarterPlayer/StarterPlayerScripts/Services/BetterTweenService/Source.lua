----[[    SERVICES    ]]----
local ReplicatedStorage: ReplicatedStorage = game:GetService(`ReplicatedStorage`)

----[[    MODULES    ]]----
local Types = require(workspace.Types)

local CleanupService = require(ReplicatedStorage.Globals.Services.CleanupService)
local BetterTweenService = require(ReplicatedStorage.Globals.Services.BetterTweenService)

----[[    REMOTES    ]]----
local Remote: RemoteEvent = ReplicatedStorage.Globals.Remotes.Tween

----[[    MAIN LOGIC    ]]----
local function CreateTweenInfo(Info: buffer): TweenInfo
	return TweenInfo.new(
		buffer.readf32(Info, 0),
		Enum.EasingStyle:FromValue(buffer.readu8(Info, 4)),
		Enum.EasingDirection:FromValue(buffer.readu8(Info, 5)),
		buffer.readu8(Info, 6),
		buffer.readu8(Info, 7) == 1,
		buffer.readf32(Info, 8)
	)
end

local function ClientEvent(Object: Instance, Info: buffer, Goal: Types.Goal)
	Info = CreateTweenInfo(Info)
	BetterTweenService:OnceLocal(Object, Info, Goal)
	local TotalTime: number = ((Info.DelayTime + Info.Time * (Info.RepeatCount + 1))) * (Info.Reverses and 2 or 1)
	CleanupService:DelayedDestroyObject(TotalTime, Goal)
end

----[[    CONNECTIONS    ]]----
CleanupService:BindObjectToShutdown(Remote.OnClientEvent:Connect(ClientEvent))
