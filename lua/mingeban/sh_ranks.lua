
local checkParam = mingeban.utils.checkParam
local accessorFunc = mingeban.utils.accessorFunc

mingeban.ranks = {}
mingeban.users = {}

local Rank = {}
Rank.__index = Rank
if SERVER then
	function Rank:SetLevel(level)
		checkParam(level, "number", 1, "SetLevel")
		assert(not istable(mingeban.ranks[level]), "rank with level " .. tostring(level) .. " already exists!")

		mingeban.ranks[self.level] = nil
		self.level = level
		mingeban.ranks[level] = self

		mingeban:SaveRanks()
		return self

	end
	function Rank:SetName(name)
		checkParam(name, "string", 1, "SetName")
		assert(not istable(mingeban:GetRank(name)), "rank with name " .. name .. " already exists!")

		self.name = name

		mingeban:SaveRanks()
		return self

	end
	function Rank:SetRoot(root)
		checkParam(name, "boolean", 1, "SetRoot")

		self.root = root

		mingeban:SaveRanks()
		return self

	end
	function Rank:AddUser(sid)
		if type(sid) == "Player" and not sid:IsBot() then
			sid:SetNWString("UserGroup", self.name)
			sid = sid:SteamID()
		end
		checkParam(sid, "string", 1, "AddUser")
		assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'AddUser' (steamid expected, got something else)")

		for group, plys in next, mingeban.users do
			if plys[sid] then
				plys[sid] = nil
			end
		end
		if not mingeban.users[self.name] then
			mingeban.users[self.name] = {}
		end
		mingeban.users[self.name][sid] = true

		mingeban:SaveUsers()
		return self

	end
	function Rank:RemoveUser(sid)
		if type(sid) == "Player" and not sid:IsBot() then
			sid:SetNWString("UserGroup", "user")
			sid = sid:SteamID()
		end
		checkParam(sid, "string", 1, "RemoveUser")
		assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'RemoveUser' (steamid expected, got something else)")

		if not mingeban.users[self.name] then
			return false
		end
		mingeban.users[self.name][sid] = nil

		mingeban:SaveUsers()
		return self

	end
	function Rank:AddPermission(perm)
		checkParam(perm, "string", 1, "AddPermission")

		self.permissions[perm] = true

		mingeban:SaveRanks()
		return self
	end
	function Rank:RemovePermission(perm)
		checkParam(perm, "string", 1, "RemovePermission")

		self.permissions[perm] = nil

		mingeban:SaveRanks()
		return self
	end
end
function Rank:GetPermission(perm)
	checkParam(perm, "string", 1, "GetPermission")

	return self.permissions[perm]
end
function Rank:GetPermissions()
	return self.root or self.permissions
end
function Rank:GetUser(sid)
	if type(sid) == "Player" and not sid:IsBot() then
		return mingeban.users[self.name][sid:SteamID()] and sid or false
	else
		checkParam(sid, "string", 1, "GetUser")
		assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'GetUser' (steamid expected, got something else)")

		local ply = player.GetBySteamID(sid)
		if not IsValid(ply) then
			ply = true
		end
		return mingeban.users[self.name][sid] and ply or nil
	end

end
function Rank:GetUsers()
	return mingeban.users[self.name]
end
accessorFunc(Rank, "Name", "name", CLIENT)
accessorFunc(Rank, "Level", "level", CLIENT)
accessorFunc(Rank, "Root", "root", CLIENT)

mingeban.objects.Rank = Rank

function mingeban:GetRank(name)
	checkParam(name, "string", 1, "GetRank")

	for level, rank in next, self.ranks do
		if rank.name == name:lower() then
			return self.ranks[level]
		end
	end

end

local PLAYER = FindMetaTable("Player")

function PLAYER:CheckUserGroupLevel(name)
	checkParam(name, "string", 1, "CheckUserGroupLevel")

	local plyRank = mingeban:GetRank(self:GetUserGroup())
	if plyRank:GetRoot() then return true end

	local rank = mingeban:GetRank(name)
	if not rank then return true end

	if plyRank:GetLevel() < rank:GetLevel() then
		return false
	else
		return true
	end

end
function PLAYER:GetRank(name)
	return mingeban:GetRank(self:GetUserGroup())
end
function PLAYER:IsUserGroup(name)
	checkParam(name, "string", 1, "IsUserGroup")

	return self:GetUserGroup() == name:lower()

end

--[[ useless, this is default

function PLAYER:GetUserGroup()
	return self:GetNWString("UserGroup", "user")
end

]]

