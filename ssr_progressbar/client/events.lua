RegisterNetEvent("ssr_progressbar:client:progress")
AddEventHandler("ssr_progressbar:client:progress", function(action, finish)
	Process(action, nil, nil, finish)
end)

RegisterNetEvent("ssr_progressbar:client:ProgressWithStartEvent")
AddEventHandler("ssr_progressbar:client:ProgressWithStartEvent", function(action, start, finish)
	Process(action, start, nil, finish)
end)

RegisterNetEvent("ssr_progressbar:client:ProgressWithTickEvent")
AddEventHandler("ssr_progressbar:client:ProgressWithTickEvent", function(action, tick, finish)
	Process(action, nil, tick, finish)
end)

RegisterNetEvent("ssr_progressbar:client:ProgressWithStartAndTick")
AddEventHandler("ssr_progressbar:client:ProgressWithStartAndTick", function(action, start, tick, finish)
	Process(action, start, tick, finish)
end)

RegisterNetEvent("ssr_progressbar:client:cancel")
AddEventHandler("ssr_progressbar:client:cancel", function()
	Cancel()
end)

RegisterNUICallback('actionFinish', function(data, cb)
	Finish()
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
			print('[ssr_progressbar] test cancelled')
		else
			print('[ssr_progressbar] test finished')
		end
	end)
end, false)

RegisterCommand('cancelprogbar', function()
	TriggerEvent('ssr_progressbar:client:cancel')
end, false)
