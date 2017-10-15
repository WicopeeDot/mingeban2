
if SERVER then
	AddCSLuaFile("mingeban/cl_init.lua")
	AddCSLuaFile("mingeban/sh_init.lua")
end

include("mingeban/sh_init.lua")

if SERVER then
	include("mingeban/sv_init.lua")
end

if CLIENT then
	include("mingeban/cl_init.lua")
end

