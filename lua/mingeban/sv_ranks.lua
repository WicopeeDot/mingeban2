
local checkParam = mingeban.utils.checkParam

local Rank = {}
Rank.__index = Rank
function Rank:SetLevel(level)
	checkParam(level, "number", 1, "SetLevel")
	assert(not istable(mingeban.ranks[level]), "rank with level " .. tostring(level) .. " already exists!")

	mingeban.ranks[self.level] = nil
	self.level = level
	mingeban.ranks[level] = self
	return self
end
function Rank:SetName(name)
	checkParam(name, "string", 1, "SetName")
	assert(not istable(mingeban:GetRank(name)), "rank with name " .. name .. " already exists!")

	self.name = name
	return self
end
function Rank:SetRoot(root)
	self.root = root
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

	return self

end
function Rank:RemoveUser(sid)
	if type(sid) == "Player" and not sid:IsBot() then
		sid = sid:SteamID()
	end
	checkParam(sid, "string", 1, "RemoveUser")
	assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'RemoveUser' (steamid expected, got something else)")

	if not mingeban.users[self.name] then
		return false
	end
	mingeban.users[self.name][sid] = nil

	return self

end
function Rank:GetUser(sid)
	if type(sid) == "Player" and not sid:IsBot() then
		return mingeban.users[self.name][sid:SteamID()] and sid or false
	else
		checkParam(sid, "string", 1, "GetUser")
		assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'RemoveUser' (steamid expected, got something else)")

		local ply = player.GetBySteamID(sid)
		if not IsValid(ply) then
			ply = true
		end
		return mingeban.users[self.name][sid] and ply or false
	end

end

function mingeban:CreateRank(name, level, root)
	checkParam(name, "string", 1, "CreateRank")
	checkParam(level, "number", 2, "CreateRank")
	checkParam(root, "boolean", 3, "CreateRank")

	assert(not istable(mingeban.ranks[level]), "rank with level " .. tostring(level) .. " already exists!")
	assert(not istable(mingeban:GetRank(name)), "rank with name " .. name .. " already exists!")

	local rank = setmetatable({
		level = level,
		name = name:lower(),
		root = root,
	}, Rank)
	self.ranks[level] = rank
	return rank

end

function mingeban:InitializeRanks()
	local ranks = util.JSONToTable(file.Read("mingeban/ranks.txt", "DATA") or "{}")
	for level, rank in next, ranks do
		mingeban:CreateRank(rank.name, rank.level, rank.root)
	end
	self.users = util.JSONToTable(file.Read("mingeban/users.txt", "DATA") or "{}")

	if table.Count(self.ranks) < 1 then
		mingeban:CreateRank("superadmin", 255, true):AddUser(easylua.FindEntity("tenrys"):SteamID())
		mingeban:CreateRank("user", 1, false)

		self:SaveRanks()

	end

	for group, plys in next, self.users do
		for sid, _ in next, self.users do
			local ply = player.GetBySteamID(sid)
			if IsValid(ply) then
				ply:SetNWString("UserGroup", group)
			end
		end
	end

end

function mingeban:SaveRanks()
	if not file.Exists("mingeban", "DATA") then
		file.CreateDir("mingeban")
	end
	file.Write("mingeban/ranks.txt", util.TableToJSON(self.ranks))
	local users = table.Copy(self.users)
	users.user = nil
	file.Write("mingeban/users.txt", util.TableToJSON(users))

end

util.AddNetworkString("mingeban-getranks")

net.Receive("mingeban-getranks", function(_, ply)
	net.Start("mingeban-getranks")
		net.WriteTable(mingeban.ranks)
		net.WriteTable(mingeban.users)
	net.Send(ply)

end)

local PLAYER = FindMetaTable("Player")

function PLAYER:SetUserGroup(name)
	local rank = mingeban:GetRank(name)
	assert(rank, "rank '" .. name .. "' doesn't exist!")

	rank:AddUser(self)
end

hook.Add("PlayerInitialSpawn", "mingeban-ranks", function(ply)
	ply:SetNWString("UserGroup", "user")
	for group, plys in next, self.users do
		for sid, _ in next, self.users do
			if ply:SteamID() == sid then
				ply:SetNWString("UserGroup", group)
				break
			end
		end
	end
end)

mingeban:InitializeRanks()
