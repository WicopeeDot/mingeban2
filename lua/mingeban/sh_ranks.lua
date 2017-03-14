
mingeban.ranks = {}
mingeban.users = {}

function mingeban:GetRank(name)
	for level, rank in next, self.ranks do
		if rank.name == name:lower() then
			return self.ranks[level]
		end
	end

end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetUserGroup()
	local group = self:GetNWString("UserGroup")
	group = group == "" and "user" or group
	return group
end

