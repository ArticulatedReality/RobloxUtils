--! optimize 2

local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

-------------------------------------------------------------------------------------------------------------------
local Types = require(workspace.Types)
local Error = require(`../Libraries/Error`)

local DoesNotExist: string = `A Connection Does Not Exist At Key: "%s" In ConnectionManager: "%s".`
local AlreadyExists: string = `A Connection Is Already Stored At Key: "%s" In ConnectionManager: "%s".`

-------------------------------------------------------------------------------------------------------------------
function ConnectionManager.new(Name: string): Types.ConnectionManager
	local self = setmetatable({}, ConnectionManager)
	
	self.Name = Name or ``
	self.Connections = {}
	
	return self
end

-------------------------------------------------------------------------------------------------------------------
function ConnectionManager:AddConnection(Key: any, Connection: Types.ConnectionBase)
	if self.Connections[Key] then Error(AlreadyExists, Key, self.Name) return end
	self.Connections[Key] = Connection
end

-------------------------------------------------------------------------------------------------------------------
function ConnectionManager:ReleaseConnection(Key: any)
	if not self.Connections[Key] then Error(DoesNotExist, Key, self.Name) return end
	self.Connections[Key]:Disconnect()
	self.Connections[Key] = nil
end

-------------------------------------------------------------------------------------------------------------------
function ConnectionManager:ReplaceConnection(Key: any, Connection: Types.ConnectionBase)
	if not self.Connections[Key] then Error(DoesNotExist, Key, self.Name) return end
	self.Connections[Key]:Disconnect()
	self.Connections[Key] = Connection
end

-------------------------------------------------------------------------------------------------------------------
function ConnectionManager:GetConnection(Key: any): Types.ConnectionBase
	if not self.Connections[Key] then Error(DoesNotExist, Key, self.Name) return end
	return self.Connections[Key]
end

-------------------------------------------------------------------------------------------------------------------
function ConnectionManager:ReleaseAll()
	for Key: any, Connection: Types.ConnectionBase in self.Connections do Connection:Disconnect() end
	setmetatable(self, nil)
	table.clear(self)
end

-------------------------------------------------------------------------------------------------------------------
ConnectionManager.Destroy = ConnectionManager.ReleaseAll

-------------------------------------------------------------------------------------------------------------------
return ConnectionManager
