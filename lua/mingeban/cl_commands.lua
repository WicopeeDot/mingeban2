
net.Receive("mingeban-cmderror", function()
	local reason = net.ReadString()
	if not isstring(reason) then return end

	surface.PlaySound("buttons/button2.wav")
	notification.AddLegacy("mingeban: " .. reason, NOTIFY_ERROR, 6)
end)

