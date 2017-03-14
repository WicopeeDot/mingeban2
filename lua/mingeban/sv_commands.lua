
mingeban.commands = {}

mingeban.CmdPrefix = "[%$]"
mingeban.CmdArgGrouper = "[\"']"
-- mingeban.CmdArgSeparators = { [" "] = true, [","] = true }
mingeban.CmdArgSeparators = "[%s,]"
mingeban.CmdEscapeChar = "[\\]"

function mingeban:ParseArgs(str) -- featuring no continues and better parsing than aowl!
	local chars = str:Split("")
	local grouping = false
	local escaping = false
	local separator = false
	local arg = ""
	local ret = {}

	for k, c in next, chars do
		local cont = true

		local before = chars[k - 1] -- check if there's anything behind the current char
		local after = chars[k + 1] -- check if there's anything after the current char

		if c:match(self.CmdEscapeChar) then
			escaping = true
			cont = false -- we're escaping a char, no need to continue
		end

		if cont then
			if ((arg ~= "" and grouping) or (arg == "" and not grouping)) and c:match(self.CmdArgGrouper) then -- do we try to group

				if not before or before and not escaping then -- are we escaping or starting a command
					grouping = not grouping -- toggle group mode
					if arg ~= "" then
						table.insert(ret, arg) -- finish the job, add arg to list
						arg = "" -- reset arg
					end
					cont = false -- we toggled grouping mode
				elseif escaping then
					escaping = false -- we escaped the character, disable it
				end

			end

			if cont then
				if c:match(separator or self.CmdArgSeparators) and not grouping then -- are we separating and not grouping

					if not separator then
						separator = c -- pick the current separator
					end
					if arg ~= "" then
						table.insert(ret, arg) -- finish the job, add arg to list
						arg = "" -- reset arg
					end
					cont = false -- let's get the next arg going

				end

				if cont then
					arg = arg .. c -- go on with the arg
					if not after then -- in case this is the end of the sentence, add last thing written
						table.insert(ret, arg)
					end
				end

			end
		end

	end

	return ret -- give results!!
end

hook.Add("PlayerSay", "mingeban-commands", function(ply, txt)
	local prefix = txt:sub(1, 1):match(mingeban.CmdPrefix)

	if prefix then
		local cmd = txt:Split(" ")
		cmd = cmd[1]:sub(prefix:len() + 1):lower()
		local args = txt:sub(prefix:len() + 1 + cmd:len() + 1)
		local time = SysTime()
		args = mingeban:ParseArgs(args)
		print("it took " .. (tostring(SysTime() - time) * 1000) .. " milliseconds to run a command")
		print("here is the command: \"" .. cmd .. "\"")
		print("here are the args")
		PrintTable(args)
	end
end)

