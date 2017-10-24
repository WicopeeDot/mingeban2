
AddCSLuaFile("sh_utils.lua")
AddCSLuaFile("sh_ranks.lua")
AddCSLuaFile("sh_commands.lua")
AddCSLuaFile("sh_countdown.lua")
AddCSLuaFile("cl_ranks.lua")
AddCSLuaFile("cl_commands.lua")
include("sv_ranks.lua")
include("sv_commands.lua")
include("sv_bans.lua")

hook.Add("Initialize", "mingeban-nukedefault", function()
	hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")
	hook.Remove("Initialize", "mingeban-nukedefault")
end)

hook.Run("MingebanInitialized")

MsgC(Color(127, 255, 127), "[mingeban] ") MsgC(Color(255, 255, 255), "Server side loaded\n")

