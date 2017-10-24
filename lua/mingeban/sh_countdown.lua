
if SERVER then
	local checkParam = mingeban.utils.checkParam

	util.AddNetworkString("mingeban-countdown")

	function mingeban.Countdown(time, func, text)
		checkParam(time, "number", 1, "Countdown")
		local time = math.abs(time)
		local time = time > 5 and time or 5

		checkParam(func, "function", 2, "Countdown")

		local text = isstring(text) and text or tostring(text or "")
		checkParam(text, "string", 3, "Countdown")

		net.Start("mingeban-countdown")
			net.WriteUInt(time, 16)
			net.WriteString(text)
		net.Broadcast()

		local time = CurTime() + time
		hook.Add("Think", "mingeban-countdown", function()
			if time < CurTime() then
				func()
				hook.Remove("Think", "mingeban-countdown")
			end
		end)

		mingeban.LastCountdown = text:Trim() ~= "" and text or nil
	end

	function mingeban.IsCountdownActive()
		if not hook.GetTable().Think then return false end
		return hook.GetTable().Think["mingeban-countdown"] and true or false
	end

	function mingeban.AbortCountdown()
		net.Start("mingeban-countdown")
			net.WriteUInt(0, 16)
			net.WriteString("")
		net.Broadcast()

		if mingeban.IsCountdownActive() then
			hook.Remove("Think", "mingeban-countdown")
		end
	end

	hook.Add("MingebanInitialized", "mingeban-countdown", function()
		local abort = mingeban.CreateCommand("abort", function(caller)
			mingeban.AbortCountdown()
			mingeban.utils.print(mingeban.colors.Cyan, tostring(caller) .. " aborted countdown" .. (mingeban.LastCountdown and " \"" .. mingeban.LastCountdown .. "\"" or ""))
		end)
	end)
elseif CLIENT then
	-- setup
	mingeban.Countdown = {}
	mingeban.Countdown.alpha = 0

	-- receive the countdown
	local wait = function(time, func)
		timer.Simple(time, func)
	end
	local play = function(pitch, vol, snd)
		vol = vol or 1
		snd = snd or "buttons/button18.wav"
		EmitSound(snd, LocalPlayer():GetPos(), LocalPlayer():EntIndex(), CHAN_AUTO, vol, 75, 0, pitch)
	end
	net.Receive("mingeban-countdown", function()
		local time = net.ReadUInt(16)
		local text = net.ReadString()

		mingeban.Countdown.time = time
		mingeban.Countdown.start = RealTime() + time
		mingeban.Countdown.text = text

		-- start sound
		if time > 0 then
			if IsMounted("portal2") then
				play(100, 0.66, "buttons/button_synth_positive_01.wav")
			else
				play(110, 0.66, "buttons/button3.wav")
			end
		end
	end)

	-- show it
	surface.CreateFont("mingeban-countdown", {
		font = "Roboto Cn",
		size = 32,
		weight = 500
	})
	local function LerpColor(frac, from, to)
		local col = Color(
			Lerp(frac, from.r, to.r),
			Lerp(frac, from.g, to.g),
			Lerp(frac, from.b, to.b),
			Lerp(frac, from.a, to.a)
		)
		return col
	end
	local last
	hook.Add("HUDPaint", "mingeban-countdown", function()
		local cd = mingeban.Countdown
		if not cd.start or not cd.time then return end

		cd.alpha = Lerp(FrameTime() * 7.5, cd.alpha, cd.start > RealTime() and 1 or 0)
		if cd.alpha <= 0.01 then last = nil return end

		local start = cd.start
		local time = cd.time
		local remaining = math.max(cd.start - RealTime(), 0)
		local percent = math.Clamp((start - RealTime()) / time, 0, 1)
		local w = ScrW() * 0.3
		local h = 24
		local y = 200

		surface.SetAlphaMultiplier(cd.alpha)

		-- bar
		surface.SetDrawColor(Color(0, 0, 0, 128))
		surface.DrawRect(ScrW() * 0.5 - w * 0.5, y, w, h)
		local col = LerpColor(percent, Color(192, 92, 92, 192), Color(92, 192, 92, 192))
		surface.SetDrawColor(col)
		surface.DrawRect(ScrW() * 0.5 - w * 0.5, y, w * percent, h)
		surface.SetDrawColor(Color(0, 0, 0, 48))
		surface.DrawRect(ScrW() * 0.5 - w * 0.5, y + h * 0.5, w * percent, h * 0.5)

		-- outline
		surface.SetDrawColor(Color(0, 0, 0, 255))
		surface.DrawLine( -- left
			ScrW() * 0.5 - w * 0.5 - 1, y,
			ScrW() * 0.5 - w * 0.5 - 1, y + h - 1
		)
		surface.DrawLine( -- right
			ScrW() * 0.5 - w * 0.5 - 1 + w, y,
			ScrW() * 0.5 - w * 0.5 - 1 + w, y + h - 1
		)
		surface.DrawLine( -- top
			ScrW() * 0.5 - w * 0.5, y - 1,
			ScrW() * 0.5 - w * 0.5 - 1 + w - 1, y - 1
		)
		surface.DrawLine( -- bottom
			ScrW() * 0.5 - w * 0.5, y + h,
			ScrW() * 0.5 - w * 0.5 - 1 + w - 1, y + h
		)

		-- text setup
		surface.SetFont("mingeban-countdown")
		local txt = string.format("%.2d:%06.3f", remaining / 60, math.Round(remaining, 3) % 60)
		local sec = math.ceil(remaining)
		if last ~= sec then -- everytime the time changes...
			if last then -- don't play a sound the first time we set the variable
				if remaining < 5 and remaining > 0 then
					-- countdown sound
					play(75, 0.66, "buttons/blip1.wav")
				elseif remaining <= 0 then
					-- end sound
					if IsMounted("portal2") then
						play(100, 0.66, "buttons/button_synth_negative_02.wav")
					else
						play(110, 0.66, "buttons/button6.wav")
					end
				end
			end
			last = sec
		end
		if cd.text:Trim() ~= "" then
			txt = txt .. " (" .. cd.text .. ")"
		end
		local txtW, txtH = surface.GetTextSize(txt)

		-- text shadow
		surface.SetTextPos(ScrW() * 0.5 - txtW * 0.5 + 2, y - 8 - txtH + 2)
		surface.SetTextColor(Color(0, 0, 0, 192))
		surface.DrawText(txt)

		-- text
		surface.SetTextPos(ScrW() * 0.5 - txtW * 0.5, y - 8 - txtH)
		surface.SetTextColor(Color(220, 220, 255, 192))
		surface.DrawText(txt)
	end)
end

