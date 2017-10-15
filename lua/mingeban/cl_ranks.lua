
local Rank = mingeban.objects.Rank

net.Receive("mingeban-getranks", function()
	local ranks
	local succ = pcall(function()
		ranks = net.ReadTable()
	end)

	local users = net.ReadTable()

	for level, rank in next, ranks do
		ranks[level] = setmetatable(rank, Rank)
	end

	mingeban.ranks = ranks
	mingeban.users = users
end)

