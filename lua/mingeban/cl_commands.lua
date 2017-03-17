
local checkParam = mingeban.utils.checkParam

local Argument = mingeban.objects.Argument
local Command = mingeban.objects.Command

function mingeban.ConsoleAutoComplete(_, args)
	local autoComplete = {}

	local cmd = args:Split(" ")[2]
	local argsTbl = mingeban.utils.parseArgs(args)
	table.remove(argsTbl, 1)

	local argsStr = args:sub(cmd:len() + 2):Trim()
	if cmd then
		local cmdData = mingeban.commands[cmd]
		if cmdData then
			local curArg = argsTbl[#argsTbl]
			local argData = cmdData.args[#argsTbl]
			if argData then
				if argData.type == ARGTYPE_PLAYER then
					for _, ply in next, player.GetAll() do
						if ('"' .. ply:Nick() .. '"'):lower():match(curArg) then
							autoComplete[#autoComplete + 1] = '"' .. ply:Nick() .. '"' -- autocomplete nick
						end
					end
				end
			end
		else
			for name, cmdData in next, mingeban.commands do
				if name:lower():match(cmd) then
					autoComplete[#autoComplete + 1] = name -- autocomplete command
				end
			end
		end
	end

	for k, v in next, autoComplete do -- adapt for console use
		local curArg = argsTbl[#argsTbl] or ""
		local argsStr = argsStr:sub(1, argsStr:len() - curArg:len(), 0):Trim()
		autoComplete[k] = "mingeban" .. (mingeban.commands[cmd] and (" " .. cmd .. " ") or "") .. argsStr .. " " .. v
	end

	if table.Count(autoComplete) <= 0 then -- no suggestions? print syntax
		autoComplete[1] = mingeban.commands[cmd] and "mingeban " .. (cmd or "") .. ((" " .. mingeban:GetCommandSyntax(cmd)) or "")
	end

	return autoComplete

end

concommand.Add("mingeban", function(ply, _, cmd, args)
	local cmd = cmd[1]
	if not cmd then return end

	local args = args:sub(cmd:len() + 2):Trim()

	net.Start("mingeban-runcommand")
		net.WriteString(cmd)
		net.WriteString(args)
	net.SendToServer()

end, mingeban.ConsoleAutoComplete)

for _, file in next, (file.Find("mingeban/commands/*.lua", "LUA")) do
	include("mingeban/commands/" .. file)
end

local function askCommands()
	net.Start("mingeban-getcommands")
	net.SendToServer()
end

net.Receive("mingeban-getcommands", function()
	local commands
	local succ = pcall(function()
		commands = net.ReadTable()
	end)

	if not istable(commands) then
		askCommands()
		return
	end

	for name, cmd in next, commands do
		for k, arg in next, cmd.args do
			cmd.args[k] = setmetatable(arg, Argument)
		end
		commands[name] = setmetatable(cmd, Command)
	end

	mingeban.commands = commands

end)

if istable(GAMEMODE) then
	askCommands()
end
hook.Add("Initialize", "mingeban-requestcommands", askRanks)

net.Receive("mingeban-cmderror", function()
	local reason
	local succ = pcall(function()
		reason = net.ReadString()
	end)

	surface.PlaySound("buttons/button2.wav")
	if not reason then return end

	notification.AddLegacy("mingeban: " .. reason, NOTIFY_ERROR, 6)

end)

