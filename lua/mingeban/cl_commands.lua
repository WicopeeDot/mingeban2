
local checkParam = mingeban.utils.checkParam

local Argument = mingeban.objects.Argument
local Command = mingeban.objects.Command

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

function mingeban.ConsoleAutoComplete(_, args)
	local autoComplete = {}

	local argsTbl = args:Split(" ")
	local cmd = argsTbl[1]
	if cmd then
		local cmd = mingeban.commands[cmd]
		if cmd then
			local argsStr = args:sub(cmd:len() + 2):Trim()
			local curArg = argsTbl[#argsTbl]

			local argData = cmd.args[#argsTbl]
			if argData then
				if argData.type == ARGTYPE_PLAYER then
					for _, ply in next, player.GetAll() do
						plys[#plys + 1] = ply:Nick()
					end
				end
			end
		end
	end

	for k, v in next, autoComplete do
		autoComplete[k] = "mingeban " .. (cmd or "") .. v
	end

	return table.Count(autoComplete) > 0 and autoComplete or (cmd and { mingeban:GetCommandSyntax(cmd) } or {})

end

concommand.Add("mingeban", function(ply, _, cmd, args)
	local cmd = cmd[1]
	local args = args:sub(cmd:len() + 2):Trim()

	net.Start("mingeban-runcommand")
		net.WriteString(cmd)
		net.WriteString(args)
	net.SendToServer()

end, mingeban.ConsoleAutoComplete)

net.Receive("mingeban-cmderror", function()
	local reason = net.ReadString()
	if not isstring(reason) then return end

	surface.PlaySound("buttons/button2.wav")
	notification.AddLegacy("mingeban: " .. reason, NOTIFY_ERROR, 6)
end)

