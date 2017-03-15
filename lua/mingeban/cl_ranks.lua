
local Rank = {}
function Rank:GetUser(sid)
	local ply = player.GetBySteamID(sid)
	if not IsValid(ply) then
		ply = true
	end
	if not mingeban.users[self.name] then return false end
	return mingeban.users[self.name][sid] and ply or false

end

local function readonly(tbl, add)
	local mt = {
		__index = tbl,
		__newindex = function(tbl, key, value)
			MsgC(Color(255, 127, 127), "[ERROR] mingeban: attempt to modify rank table!\n")
			return false
		end,
		__metatable = table.Merge(tbl, add or {}),
	}
	if add then
		table.Merge(mt, add)
	end

	return setmetatable({}, mt)

end
local function askRanks()
	net.Start("mingeban-getranks")
	net.SendToServer()
end

net.Receive("mingeban-getranks", function()
	local ranks = pcall(function() net.ReadTable() end)

	if not istable(ranks) then
		askRanks()
		return
	end

	local users = net.ReadTable()

	for level, rank in next, ranks do
		ranks[level] = readonly(rank, Rank)
	end
	ranks = readonly(ranks)
	for group, plys in next, users do
		users[group] = readonly(plys)
	end
	users = readonly(users)

	mingeban.ranks = ranks
	mingeban.users = users

end)

if istable(GAMEMODE) then
	askRanks()
end
hook.Add("Initialize", "mingeban-requestranks", askRanks)

