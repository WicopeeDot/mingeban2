
local checkParam = mingeban.utils.checkParam

local Rank = mingeban.objects.Rank

function mingeban.CreateRank(name, level, root)
	checkParam(name, "string", 1, "CreateRank")
	checkParam(level, "number", 2, "CreateRank")
	checkParam(root, "boolean", 3, "CreateRank")

	assert(not istable(mingeban.ranks[level]), "rank with level " .. tostring(level) .. " already exists!")
	assert(not istable(mingeban.GetRank(name)), "rank with name " .. name .. " already exists!")

	local rank = setmetatable({
		level = level,
		name = name:lower(),
		root = root,
		permissions = {}
	}, Rank)
	mingeban.ranks[level] = rank
	return rank
end
function mingeban.DeleteRank(name)
	checkParam(name, "string", 1, "CreateRank")
	assert(istable(mingeban.GetRank(name)), "rank with name " .. name .. " doesn't exist!")

	for level, rank in next, mingeban.ranks do
		if rank:GetName() == name:lower() then
			for sid, _ in next, rank.users do
				local ply = player.GetBySteamID(sid)
				if IsValid(ply) then
					ply:SetNWString("UserGroup", "user")
				end
			end
			mingeban.ranks[level] = nil
			break
		end
	end
end

function mingeban.InitializeRanks()
	local ranks = util.JSONToTable(file.Read("mingeban/ranks.txt", "DATA") or "{}")
	for level, rank in next, ranks do
		local restoredRank = mingeban.CreateRank(rank.name, rank.level, rank.root)
		for permission, _ in next, rank.permissions do
			restoredRank:AddPermission(permission)
		end
	end
	mingeban.users = util.JSONToTable(file.Read("mingeban/users.txt", "DATA") or "{}")

	if table.Count(mingeban.ranks) < 1 then
		mingeban.utils.print(mingeban.colors.Yellow, "Reset ranks as we don't have any saved..?")

		mingeban.CreateRank("superadmin", 255, true)
		mingeban.CreateRank("user", 1, false)

		mingeban.SaveRanks()
		mingeban.SaveUsers()
	end

	for group, plys in next, mingeban.users do
		for sid, _ in next, plys do
			local ply = player.GetBySteamID(sid)
			if IsValid(ply) then
				ply:SetNWString("UserGroup", group)
			end
		end
	end
end

-- networking

util.AddNetworkString("mingeban-getranks")

function mingeban.NetworkRanks(ply)
	net.Start("mingeban-getranks")
		net.WriteTable(mingeban.ranks)
		net.WriteTable(mingeban.users)
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function mingeban.SaveRanks()
	if not file.Exists("mingeban", "DATA") then
		file.CreateDir("mingeban")
	end
	file.Write("mingeban/ranks.txt", util.TableToJSON(mingeban.ranks))

	mingeban.NetworkRanks()
end
function mingeban.SaveUsers()
	if not file.Exists("mingeban", "DATA") then
		file.CreateDir("mingeban")
	end
	local users = table.Copy(mingeban.users)
	users.user = nil
	file.Write("mingeban/users.txt", util.TableToJSON(users))

	mingeban.NetworkRanks()
end

local PLAYER = FindMetaTable("Player")

function PLAYER:SetUserGroup(name)
	local rank = mingeban.GetRank(name)
	assert(rank, "rank '" .. name .. "' doesn't exist!")

	rank:AddUser(self)
end

hook.Add("PlayerInitialSpawn", "mingeban-ranks", function(ply)
	ply:SetNWString("UserGroup", "user")

	for group, plys in next, mingeban.users do
		for sid, _ in next, plys do
			if ply:SteamID() == sid then
				ply:SetNWString("UserGroup", group)
				break
			end
		end
	end

	mingeban.NetworkRanks(ply)
end)

mingeban.InitializeRanks()
