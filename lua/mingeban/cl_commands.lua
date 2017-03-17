
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

net.Receive("mingeban-cmderror", function()
	local reason = net.ReadString()
	if not isstring(reason) then return end

	surface.PlaySound("buttons/button2.wav")
	notification.AddLegacy("mingeban: " .. reason, NOTIFY_ERROR, 6)
end)

