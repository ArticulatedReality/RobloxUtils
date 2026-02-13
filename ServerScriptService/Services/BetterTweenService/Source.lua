----[[    SERVICES    ]]----
local Players: Players = game:GetService(`Players`)
local ReplicatedStorage: ReplicatedStorage = game:GetService(`ReplicatedStorage`)

----[[    MODULES    ]]----
local Types = require(workspace.Types)

local CleanupService: Types.CleanupService = require(ReplicatedStorage.Globals.Services.CleanupService)
local BetterTweenService: Types.BetterTweenService = require(ReplicatedStorage.Globals.Services.BetterTweenService)

----[[    TYPE ANNOTATIONS    ]]----
type Goal = Types.Goal

----[[    REMOTES    ]]----
local Remote: RemoteEvent = ReplicatedStorage.Globals.Remotes.Tween

----[[    HELPER TABLES    ]]----
local MessageToFunction: {[string]: (Object: Instance, Info: buffer, Goal: Goal, Group: {Player}?) -> ()} = {}

----[[    MAIN LOGIC    ]]----
function MessageToFunction.Create(Object: Instance, Info: buffer, Goal: Goal, Group: {Player}?)
	Remote:FireAllClients(Object, Info, Goal)
end

function MessageToFunction.Group(Object: Instance, Info: buffer, Goal: Goal, Group: {Player})
	for _: number, Player: Player in Group do
		if not Player:IsAncestorOf(Players) then continue end
		Remote:FireClient(Player, Object, Info, Goal)
	end
end

local function ServerEvent(Player: Player, Message: string, Object: Instance, Info: buffer, Goal: Goal, Group: {Player}?)
	MessageToFunction[Message](Object, Info, Goal, Group)
end

----[[    CONNECTIONS    ]]----
CleanupService:BindObjectToShutdown(Remote.OnServerEvent:Connect(ServerEvent))
CleanupService:BindObjectToShutdown(MessageToFunction)
