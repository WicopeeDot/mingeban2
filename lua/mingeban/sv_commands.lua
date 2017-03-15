
mingeban.commands = {}

-- for commands
MINGEBAN_ARG_STRING = 0
MINGEBAN_ARG_NUMBER = 1
MINGEBAN_ARG_PLAYER = 2
MINGEBAN_ARG_PLAYERS = 4
MINGEBAN_ARG_BOOL = 8
MINGEBAN_ARG_OPTIONAL = 16
MINGEBAN_ARG_VARARGS = 32
local types = {
	[ MINGEBAN_ARG_STRING  ] = "string",
	[ MINGEBAN_ARG_NUMBER  ] = "number",
	[ MINGEBAN_ARG_PLAYER  ] = "player",
	[ MINGEBAN_ARG_PLAYERS ] = "players",
	[ MINGEBAN_ARG_BOOL	   ] = "bool",
	[ MINGEBAN_ARG_VARARGS ] = "varargs"
}

local checkParam = mingeban.utils.checkParam

local Command = {}
Command.__index = Command
local function accessorFunc(keyName, key)
	Command["Set" .. keyName] = function(self, value)
		self[key] = value
		return self
	end
	Command["Get" .. keyName] = function(self)
		return self[key]
	end
end
accessorFunc("Group", "group")
accessorFunc("Arguments", "args")
accessorFunc("Syntax", "syntax")
accessorFunc("EndsWithVarargs", "varargs")
local function registerCommand(name, callback, group)
	if not isbool(varargs) then varargs = true end
	mingeban.commands[name] = setmetatable({
		callback = callback, -- caller, line, ...
		group = group,
		args = { MINGEBAN_ARG_VARARGS },
		syntax = {},
		endsWithVarargs = true
	}, Command)
	return mingeban.commands[name]
end
function mingeban.CreateCommand(name, callback, group)
	checkParam(callback, "function", 2, "CreateCommand")
	checkParam(group, "string", 3, "CreateCommand")

	if istable(name) then
		local cmds = {}
		for _, name in next, name do
			cmds[#cmds + 1] = registerCommand(name, callback, group)
		end
		return cmds
	else
		checkParam(name, "string", 1, "CreateCommand")

		return registerCommand(name, callback, group)
	end
end

function mingeban:GetCommandSyntax(name)
	local cmd = self.commands[name]
	if not cmd then return end

	local str = name .. " syntax: "
	for k, argType in next, cmd.args do
		local optional = argType < MINGEBAN_ARG_OPTIONAL
		local typ = argType % MINGEBAN_ARG_OPTIONAL
		local brStart, brEnd
		if optional then
			brStart = "["
			brEnd = "]"
		else
			brStart = "<"
			brEnd = ">"
		end
		str = str .. brStart .. (cmd.syntax[k] and cmd.syntax[k] .. ":" or "") .. types[typ] .. brEnd .. " "
	end

	return str
end

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
	for _, argType in next, cmd.args do
		if argType < MINGEBAN_ARG_OPTIONAL then neededArgs = neededArgs + 1 end
	end

	local syntax = mingeban:GetCommandSyntax(name)
	if neededArgs > #args then
		cmdError(caller, syntax)
		return false
	end

	for k, _ in next, args do
		local argType = cmd.args[k] and cmd.args[k] % MINGEBAN_ARG_OPTIONAL
		local arg
		if argType == MINGEBAN_ARG_NUMBER then
			arg = tonumber(string.Trim(string.lower(args[k])))
		elseif argType == MINGEBAN_ARG_BOOL then
			arg = tobool(string.Trim(string.lower(args[k])))
		elseif argType == MINGEBAN_ARG_PLAYER then
			arg = mingeban.utils.findPlayers(args[k])[1]
		elseif argType == MINGEBAN_ARG_PLAYERS then
			arg = mingeban.utils.findPlayers(args[k])
			if #arg <= 0 then
				cmdError(caller, "No players found.")
				return false
			end
		end
		if arg == nil and not cmd.endsWithVarargs then
			cmdError(caller, syntax)
			return false
		end
		if arg ~= nil then
			args[k] = arg
		elseif cmd.endsWithVarargs then
			args[k] = args[k]
		else
			args[k] = nil
		end
	end

	if type(caller) == "Player" then
		for k, v in next, args do
			if type(v) == "Player" then
				local ply = v
				if not caller:CheckUserGroupLevel(ply:GetUserGroup()) then
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

	cmd.callback(caller, line, unpack(args))

end

-- not real command
mingeban.CreateCommand("ban", function(caller, line, ply, time, reason)
	print(line)
	print(ply, time, reason)
end, "superadmin")
	:SetArguments({ MINGEBAN_ARG_PLAYER, MINGEBAN_ARG_STRING, MINGEBAN_ARG_STRING + MINGEBAN_ARG_OPTIONAL })
	:SetSyntax({ "target", "time", "reason" })
	:SetEndsWithVarargs(false)

hook.Add("PlayerSay", "mingeban-commands", function(ply, txt)
	local prefix = txt:match(mingeban.utils.CmdPrefix)

	if prefix then

		local cmd = txt:Split(" ")
		cmd = cmd[1]:sub(prefix:len() + 1):lower()

		local args = txt:sub(prefix:len() + 1 + cmd:len() + 1)

		mingeban:RunCommand(cmd, ply, args)
		--[[
		local time = SysTime()

		args = mingeban:ParseArgs(args)

		print("it took " .. (tostring((SysTime() - time) * 1000)) .. " milliseconds to run a command")
		print("here is the command: \"" .. cmd .. "\"")
		print("here are the args")
		PrintTable(args)
		]]

	end

end)

