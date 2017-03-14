
mingeban.ranks = {}
mingeban.users = {}

function mingeban:GetRank(name)
	for level, rank in next, self.ranks do
		if rank.name == name:lower() then
			return self.ranks[level]
		end
	end

end

--[[ useless, this is default

local PLAYER = FindMetaTable("Player")

function PLAYER:GetUserGroup()
	return self:GetNWString("UserGroup", "user")
end

]]

