
local Rank = mingeban.objects.Rank

local function askRanks()
	net.Start("mingeban-getranks")
	net.SendToServer()
end

net.Receive("mingeban-getranks", function()
	local ranks
	local succ = pcall(function()
		ranks = net.ReadTable()
	end)

	if not istable(ranks) then
		askRanks()
		return
	end

	local users = net.ReadTable()

	for level, rank in next, ranks do
		ranks[level] = setmetatable(rank, Rank)
	end

	mingeban.ranks = ranks
	mingeban.users = users

end)

if istable(GAMEMODE) then
	askRanks()
end
hook.Add("Initialize", "mingeban-requestranks", askRanks)

