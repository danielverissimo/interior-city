function AddTextEntry(key, value)
	Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), key, value)
end

Citizen.CreateThread(function()
	AddTextEntry("gst862", "Toyota GT86 G.O.M. Styling V.2")
	AddTextEntry("gst862a", "2013")
end)
