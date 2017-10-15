
local checkParam = mingeban.utils.checkParam

function mingeban.LoadBans()
	mingeban.Bans = file.Exists("mingeban/bans.txt", "DATA") and util.JSONToTable(file.Read("mingeban/bans.txt")) or {}
end

function mingeban.Ban(sid, time, reason)
	if type(sid) == "Player" and not sid:IsBot() then
		sid = sid:SteamID()
	end
	checkParam(sid, "string", 1, "Ban")
	assert(sid:Trim():match("^STEAM_0:%d:%d+$"), "bad argument #1 to 'Ban' (invalid SteamID)")
	checkParam(time, "number", 2, "Ban")
	checkParam(reason, "string", 3, "Ban")

	mingeban.Bans[sid] = {time = (time <= 0 and 0 or os.time() + time), reason = reason}

	mingeban.SaveBans()
end

function mingeban.Unban(sid)
	mingeban.Bans[sid] = nil

	mingeban.SaveBans()
end

function mingeban.SaveBans()
	file.Write("mingeban/bans.txt", util.TableToJSON(mingeban.bans))
end

hook.Add("CheckPassword", "mingeban-bans", function(sid)
	sid = util.SteamIDFrom64(sid)
	local ban = mingeban.Bans[sid]

	if ban and (os.time() < ban.time or ban.time <= 0) then
		local date, reason
		if ban.time > 0 then
			date = os.date("%d/%m/%y %H:%M:%S", ban.time)
			reason = "[mingeban] You have been banned from the server for the following reason:\n\n'" .. ban.reason .. "'.\n\nYou may try to join back at this time: " .. date .. " (UTC format)."
		else
			reason = "[mingeban] You have been permanently banned from the server for the following reason:\n\n'" .. ban.reason .. "'."
		end
		return false, reason
	elseif ban and ban.time > 0 and os.time() >= ban.time then
		mingeban.Unban(sid)
	end
end)

mingeban.LoadBans()
