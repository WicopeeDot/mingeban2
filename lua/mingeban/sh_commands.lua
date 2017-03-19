
local checkParam = mingeban.utils.checkParam
local accessorFunc = mingeban.utils.accessorFunc

mingeban.commands = mingeban.commands or {} -- intialize commands table

-- setup argument object

ARGTYPE_STRING  = 1
ARGTYPE_NUMBER  = 2
ARGTYPE_BOOLEAN = 3
ARGTYPE_PLAYER  = 4
ARGTYPE_PLAYERS = 5
ARGTYPE_ENTITY  = 6
ARGTYPE_ENTITIES= 7
ARGTYPE_VARARGS = 8

mingeban.argTypesStrings = {
	[ ARGTYPE_STRING   ] = "string",
	[ ARGTYPE_NUMBER   ] = "number",
	[ ARGTYPE_BOOLEAN  ] = "boolean",
	[ ARGTYPE_PLAYER   ] = "player",
	[ ARGTYPE_PLAYERS  ] = "players",
	[ ARGTYPE_ENTITY   ] = "entity",
	[ ARGTYPE_ENTITIES ] = "entities",
	[ ARGTYPE_VARARGS  ] = "varargs"
}
local types = mingeban.argTypesStrings

local Argument = {}
Argument.__index = Argument
accessorFunc(Argument, "Type", "type", CLIENT)
accessorFunc(Argument, "Name", "name", CLIENT)
accessorFunc(Argument, "Optional", "optional", CLIENT)
accessorFunc(Argument, "Filter", "filter", CLIENT)

mingeban.objects.Argument = Argument

-- setup command object, holds arguments

local Command = {}
Command.__index = Command
if SERVER then
	function Command:AddArgument(type)
		local arg = setmetatable({
			type = type,
		}, Argument)
		self.args[#self.args + 1] = arg
		return arg

	end
end
accessorFunc(Command, "Name", "name", false) -- no don't touch that
accessorFunc(Command, "Help", "help", CLIENT) -- to use in future help command or something

mingeban.objects.Command = Command

function mingeban:GetCommandSyntax(name)
	local cmd = self.commands[name]
	if not cmd then return end

	local str = ""
	for k, arg in next, cmd.args do
		local brStart, brEnd
		if arg:GetOptional() or arg:GetType() == ARGTYPE_VARARGS then
			brStart = "["
			brEnd = "]"
		else
			brStart = "<"
			brEnd = ">"
		end
		str = str .. brStart .. (arg:GetName() and arg:GetName() .. ":" or "") .. types[arg:GetType()] .. brEnd .. " "
	end

	return str

end

