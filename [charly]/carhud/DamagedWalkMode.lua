Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
		if (GetEntityHealth(GetPlayerPed(-1)) < 199) then
			RequestAnimSet("move_injured_generic")
			while not HasAnimSetLoaded("move_injured_generic") do
				Citizen.Wait(0)
			end
			SetPedMovementClipset(GetPlayerPed(-1), "move_injured_generic", 1 )
		else
			ResetPedMovementClipset(GetPlayerPed(-1), 0)
		end
	end
end)