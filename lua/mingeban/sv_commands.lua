
-- initialize helper functions

local checkParam = mingeban.utils.checkParam

local Argument = mingeban.objects.Argument
local Command = mingeban.objects.Command

-- command registering process

local function registerCommand(name, callback)
	mingeban.commands[name] = setmetatable({
		callback = callback, -- caller, line, ...
		args = {},
		name = name,
	}, Command)
	return mingeban.commands[name]
end
function mingeban.CreateCommand(name, callback)
	checkParam(callback, "function", 2, "CreateCommand")

	if istable(name) then
		local cmd
		for k, name in next, name do
			if k == 1 then
				cmd = registerCommand(name, callback)
			else
				mingeban.commands[name] = cmd
			end
		end

		local func = net.Receivers["mingeban-getcommands"]
		if func then
			func(nil, player.GetAll())
		end

		return cmd
	else
		checkParam(name, "string", 1, "CreateCommand")

		local cmd = registerCommand(name, callback)

		local func = net.Receivers["mingeban-getcommands"]
		if func then
			func(nil, player.GetAll())
		end
		return cmd
	end
end
mingeban.AddCommand = mingeban.CreateCommand

-- command handling

util.AddNetworkString("mingeban-cmderror")

local function cmdError(ply, reason)
	-- PrintTable(debug.getinfo(2))
	if not IsValid(ply) then
		mingeban.utils.print(mingeban.colors.Red, reason)
		return
	end

	net.Start("mingeban-cmderror")
		net.WriteString(reason or "")
	net.Send(ply)
end

local mingeban_unknowncmd_notify = CreateConVar("mingeban_unknowncmd_notify", "0", { FCVAR_ARCHIVE })
function mingeban.RunCommand(name, caller, line)
	checkParam(name, "string", 1, "RunCommand")
	checkParam(line, "string", 3, "RunCommand")

	local cmd = mingeban.commands[name]
	if not cmd then
		if mingeban_unknowncmd_notify:GetBool() then
			cmdError(caller, "Unknown command.")
		end
		return false
	end

	if IsValid(caller) then
		local hasPermission = caller:GetRank().permissions["command." .. cmd:GetName()]
		if not hasPermission then -- kinda ugly
			for alias, aliasCmd in next, mingeban.commands do
				if aliasCmd.name == cmd.name then
					hasPermission = caller:GetRank().permissions["command." .. alias]
					if hasPermission then break end
				end
			end
		end
		if type(caller) == "Player" and not hasPermission and not caller:GetRank().root then
			cmdError(caller, "Insufficient permissions.")
			return false
		end
	end

	local args
	if #cmd.args > 0 then
		args = mingeban.utils.parseArgs(line)

		local neededArgs = 0
		for _, arg in next, cmd.args do
			if not arg.optional and arg.type ~= ARGTYPE_VARARGS then neededArgs = neededArgs + 1 end
		end

		local syntax = mingeban.GetCommandSyntax(name)
		if neededArgs > #args then
			cmdError(caller, name .. " syntax: " .. syntax)
			return false
		end

		mingeban.CurrentPlayer = caller

		for k, arg in next, args do
			local argData = cmd.args[k] or (cmd.args[#cmd.args].type == ARGTYPE_VARARGS and cmd.args[#cmd.args] or nil)
			if argData then
				local funcArg = arg

				if (argData.type == ARGTYPE_STRING or argData.type == ARGTYPE_VARARGS) and funcArg:Trim() == "" then
					funcArg = nil

				elseif argData.type == ARGTYPE_NUMBER then
					funcArg = tonumber(arg:Trim():lower())

				elseif argData.type == ARGTYPE_BOOLEAN then
					funcArg = tobool(arg:Trim():lower())

				elseif argData.type == ARGTYPE_PLAYER then
					funcArg = mingeban.utils.findPlayer(arg)[1]

				elseif argData.type == ARGTYPE_PLAYERS then
					funcArg = mingeban.utils.findPlayer(arg)

				elseif argData.type == ARGTYPE_ENTITY then
					funcArg = mingeban.utils.findEntity(arg)[1]

				elseif argData.type == ARGTYPE_ENTITIES then
					funcArg = mingeban.utils.findEntity(arg)

				end

				if argData.filter then
					if istable(funcArg) then
						local newArg = {}
						for _, arg in next, funcArg do
							if argData.filter(arg) then
								newArg[#newArg] = arg
							end
						end
						funcArg = newArg
					else
						local filterRet = argData.filter(caller, funcArg)
						funcArg = filterRet and funcArg or nil
					end
				end

				local endsWithVarargs = cmd.args[#cmd.args].type == ARGTYPE_VARARGS
				if funcArg == nil and not endsWithVarargs then
					cmdError(caller, name .. " syntax: " .. syntax)
					return false
				end

				if funcArg ~= nil then
					args[k] = funcArg
				elseif endsWithVarargs then
					args[k] = args[k]
				else
					args[k] = nil
				end
			else
				args[k] = nil
			end
		end
	end

	--[[ This should be handled by custom argument filters.

	if type(caller) == "Player" then
		for k, v in next, args do
			if type(v) == "Player" then
				if not caller:CheckUserGroupLevel(v:GetUserGroup()) then
					cmdError(caller, "Can't target this player.")
					return false
				end
			elseif type(v) == "table" then
				for k, ply in next, v do
					if not caller:CheckUserGroupLevel(ply:GetUserGroup()) then
						cmdError(caller, "Can't target " .. ply:Nick() .. ".")
						v[k] = nil
					end
				end
			end
		end
	end

	]]

	local ok2, err2
	local ok, err = pcall(function()
		ok2, err2 = cmd.callback(IsValid(caller) and caller or "CONSOLE", line, unpack(args or {}))
	end)

	mingeban.CurrentPlayer = nil

	if not ok then
		ErrorNoHalt(err .. "\n")
		cmdError(caller, "command lua error: " .. err)
		return false
	elseif ok2 == false then
		cmdError(caller, err2)
		return false
	end
end
mingeban.CallCommand = mingeban.RunCommand

-- load commands

local testargsCmd = mingeban.CreateCommand("testargs", function(caller, line, ...)
	print("Line: " .. line)
	print("Arguments: ")
	for k, v in next, { ... } do
		print("\t", v, type(v))
	end
end)

testargsCmd:AddArgument(ARGTYPE_STRING)
testargsCmd:AddArgument(ARGTYPE_NUMBER)
testargsCmd:AddArgument(ARGTYPE_BOOLEAN)
testargsCmd:AddArgument(ARGTYPE_PLAYER)
testargsCmd:AddArgument(ARGTYPE_PLAYERS)
testargsCmd:AddArgument(ARGTYPE_VARARGS)

-- networking

util.AddNetworkString("mingeban-getcommands")

function mingeban.NetworkCommands(ply)
	net.Start("mingeban-getcommands")
		local commands = table.Copy(mingeban.commands)
		for name, _ in next, commands do
			commands[name].callback = nil
		end
		net.WriteTable(commands)
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

hook.Add("PlayerInitialSpawn", "mingeban-commands", function(ply)
	mingeban.NetworkCommands(ply)
end)

-- commands running by chat or console

util.AddNetworkString("mingeban-runcommand")

net.Receive("mingeban-runcommand", function(_, ply)
	local cmd = net.ReadString()
	local args = net.ReadString()
	mingeban.RunCommand(cmd, ply, args)
end)

concommand.Add("mingeban", function(ply, _, cmd, args)
	local cmd = cmd[1]
	if not cmd then return end

	local args = args:sub(cmd:len() + 2):Trim()
	mingeban.RunCommand(cmd, ply, args)
end)

for _, file in next, (file.Find("mingeban/commands/*.lua", "LUA")) do
	AddCSLuaFile("mingeban/commands/" .. file)
	include("mingeban/commands/" .. file)
end

hook.Add("PlayerSay", "mingeban-commands", function(ply, txt)
	local prefix = txt:match(mingeban.utils.CmdPrefix)

	if prefix then
		local cmd = txt:Split(" ")
		cmd = cmd[1]:sub(prefix:len() + 1):lower()

		local args = txt:sub(prefix:len() + 1 + cmd:len() + 1)

		mingeban.RunCommand(cmd, ply, args)
	end
end)

if istable(GAMEMODE) then
	mingeban.NetworkCommands()
end

