RegisterNetEvent("mythic_progbar:client:progress")
AddEventHandler("mythic_progbar:client:progress", function(action, finish)
	Process(action, nil, nil, finish)
end)

RegisterNetEvent("mythic_progbar:client:ProgressWithStartEvent")
AddEventHandler("mythic_progbar:client:ProgressWithStartEvent", function(action, start, finish)
	Process(action, start, nil, finish)
end)

RegisterNetEvent("mythic_progbar:client:ProgressWithTickEvent")
AddEventHandler("mythic_progbar:client:ProgressWithTickEvent", function(action, tick, finish)
	Process(action, nil, tick, finish)
end)

RegisterNetEvent("mythic_progbar:client:ProgressWithStartAndTick")
AddEventHandler("mythic_progbar:client:ProgressWithStartAndTick", function(action, start, tick, finish)
	Process(action, start, tick, finish)
end)

RegisterNetEvent("mythic_progbar:client:cancel")
AddEventHandler("mythic_progbar:client:cancel", function()
	Cancel()
end)

RegisterNUICallback('actionFinish', function(data, cb)
	Finish()
	if cb then cb('ok') end
end)

RegisterNUICallback('actionCancel', function(data, cb)
	Cancel()
	if cb then cb('ok') end
end)

RegisterCommand('testprogbar', function()
	Process({
		name = 'ui_test',
		duration = 7000,
		label = '',
		useWhileDead = true,
		canCancel = true,
		disarm = false,
		controlDisables = {
			disableMovement = false,
			disableCarMovement = false,
			disableMouse = false,
			disableCombat = false,
		},
		animation = {},
		prop = {},
		propTwo = {},
	}, function(cancelled)
		if cancelled then
			print('[mythic_progbar] test cancelled')
		else
			print('[mythic_progbar] test finished')
		end
	end)
end, false)

RegisterCommand('cancelprogbar', function()
	TriggerEvent('mythic_progbar:client:cancel')
end, false)
