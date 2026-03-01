-- Example usage for exports from ssr_progressbar
-- Put this in another resource and call it from a command/event.

RegisterCommand('ssr_progbar_example', function()
    exports['ssr_progressbar']:Progress({
        name = 'ssr_export_example',
        duration = 5000,
        label = 'กำลังทำงาน...',
        useWhileDead = false,
        canCancel = true,
        disarm = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = 'mp_common',
            anim = 'givetake1_a',
            flags = 49,
        },
        prop = {},
        propTwo = {},
    }, function(cancelled)
        if cancelled then
            print('[ssr_progressbar] export example cancelled')
        else
            print('[ssr_progressbar] export example complete')
        end
    end)
end, false)
