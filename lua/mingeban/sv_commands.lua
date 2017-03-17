
-- initialize helper functions

local checkParam = mingeban.utils.checkParam

local Argument = mingeban.objects.Argument
local Command = mingeban.objects.Command

-- command registering process

local function registerCommand(name, callback)
	mingeban.commands[name] = setmetatable({
		callback = callback, -- caller, line, ...
		group = "user",
		args = {},
	}, Command)
	return mingeban.commands[name]
end
function mingeban.CreateCommand(name, callback)
	checkParam(callback, "function", 2, "CreateCommand")

	if istable(name) then
		local cmds = {}
		for _, name in next, name do
			cmds[#cmds + 1] = registerCommand(name, callback)
		end
		return cmds
	else
		checkParam(name, "string", 1, "CreateCommand")

		return registerCommand(name, callback)
	end

end

-- command handling

util.AddNetworkString("mingeban-cmderror")

local function cmdError(ply, reason)
	net.Start("mingeban-cmderror")
		net.WriteString(reason)
	net.Send(ply)
end

function mingeban:RunCommand(name, caller, line)
	local cmd = self.commands[name]
	if not cmd then
		cmdError(caller, "Unknown command.")
		return false
	end

	if type(caller) == "Player" and not caller:CheckUserGroupLevel(cmd.group) then
		cmdError(caller, "Insufficient permissions.")
		return false
	end

	local args = self.utils.parseArgs(line)

	local neededArgs = 0
	for _, arg in next, cmd.args do
		if not arg.optional and arg.type ~= ARGTYPE_VARARGS then neededArgs = neededArgs + 1 end
	end

	local syntax = mingeban:GetCommandSyntax(name)
	if neededArgs > #args then
		cmdError(caller, name .. " syntax: " .. syntax)
		return false
	end

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
				funcArg = mingeban.utils.findPlayers(arg)[1]

			elseif argData.type == ARGTYPE_PLAYERS then
				funcArg = mingeban.utils.findPlayers(arg)
				if #arg <= 0 then
					cmdError(caller, "No players found.")
					return false
				end
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

			local endsWithVarargs = args[#args] == ARGTYPE_VARARGS
			if funcArg == nil and not endsWithVarargs then
				cmdError(caller, syntax)
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

	cmd.callback(caller, line, unpack(args))

end

-- load commands

local testargsCmd = mingeban.CreateCommand("testargs", function(caller, line, ...)
	print("Line: " .. line)
	print("Arguments: ")
	for k, v in next, { ... } do
		print("\t", v, type(v))
	end
end):SetGroup("superadmin")

testargsCmd:AddArgument(ARGTYPE_STRING)
testargsCmd:AddArgument(ARGTYPE_NUMBER)
testargsCmd:AddArgument(ARGTYPE_BOOLEAN)
testargsCmd:AddArgument(ARGTYPE_PLAYER)
testargsCmd:AddArgument(ARGTYPE_PLAYERS)
testargsCmd:AddArgument(ARGTYPE_VARARGS)

for _, file in next, (file.Find("mingeban/commands/*.lua", "LUA")) do
	include("mingeban/commands/" .. file)
end

util.AddNetworkString("mingeban-getcommands")

net.Receive("mingeban-getcommands", function(_, ply)
	net.Start("mingeban-getcommands")
		local commands = table.Copy(mingeban.commands)
		for name, _ in next, commands do
			commands[name].callback = nil
		end
		net.WriteTable(commands)
	net.Send(ply)

end)

-- commands running by chat or console

util.AddNetworkString("mingeban-runcommand")

net.Receive("mingeban-runcommand", function(_, ply)
	local cmd = net.ReadString()
	local args = net.ReadString()
	mingeban:RunCommand(cmd, ply, args)

end)

concommand.Add("mingeban", function(ply, _, cmd, args)
	local cmd = cmd[1]
	local args = args:sub(cmd:len() + 2):Trim()
	mingeban:RunCommand(cmd, ply, args)

end)

hook.Add("PlayerSay", "mingeban-commands", function(ply, txt)
	local prefix = txt:match(mingeban.utils.CmdPrefix)

	if prefix then
		local cmd = txt:Split(" ")
		cmd = cmd[1]:sub(prefix:len() + 1):lower()

		local args = txt:sub(prefix:len() + 1 + cmd:len() + 1)

		mingeban:RunCommand(cmd, ply, args)
	end

end)

-- networking
-- to be done (lul)

