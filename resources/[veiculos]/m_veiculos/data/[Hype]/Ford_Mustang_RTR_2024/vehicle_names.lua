function AddTextEntry(key, value)
	Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), key, value)
end

Citizen.CreateThread(function()
	AddTextEntry("gsts6504", "Ford Mustang RTR SPEC 5")
	AddTextEntry("S6504", "2024")
end)
