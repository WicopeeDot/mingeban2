
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

function PLAYER:CheckUserGroupLevel(name)
	local rank = mingeban:GetRank(name)
	if not rank then
		return true
	end
	if rank:GetLevel() <= mingeban:GetRank(self:GetUserGroup()):GetLevel() then
		return true
	else
		return false
	end
end
function PLAYER:IsUserGroup(name)
	return self:GetUserGroup() == name:lower()
end

--[[ useless, this is default

function PLAYER:GetUserGroup()
	return self:GetNWString("UserGroup", "user")
end

]]

