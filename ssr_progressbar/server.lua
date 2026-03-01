local activeProgress = {}

local function sendWebhook(payload)
    if not Config or not Config.AntiCheat or not Config.AntiCheat.webhookUrl or Config.AntiCheat.webhookUrl == '' then
        return
    end

    PerformHttpRequest(Config.AntiCheat.webhookUrl, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

local function notifyExploit(src, reason, expectedDuration, elapsed)
    local playerName = GetPlayerName(src) or 'unknown'
    local embed = {
        {
            title = (Config.AntiCheat.webhookTitle or 'Progressbar Exploit Detected'),
            color = Config.AntiCheat.webhookColor or 16724787,
            fields = {
                { name = 'Player', value = ('%s (ID: %s)'):format(playerName, src), inline = false },
                { name = 'Reason', value = reason or 'N/A', inline = false },
                { name = 'Expected (ms)', value = tostring(expectedDuration or 0), inline = true },
                { name = 'Elapsed (ms)', value = tostring(elapsed or 0), inline = true },
            },
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
        }
    }

    sendWebhook({
        username = Config.AntiCheat.webhookName or 'SSR Progressbar AC',
        embeds = embed
    })
end

RegisterNetEvent('ssr_progressbar:server:start', function(actionName, duration)
    local src = source
    local parsedDuration = tonumber(duration) or 0

    if parsedDuration < 0 then
        parsedDuration = 0
    end

    activeProgress[src] = {
        actionName = tostring(actionName or 'unknown'),
        duration = parsedDuration,
        startedAt = GetGameTimer()
    }
end)

RegisterNetEvent('ssr_progressbar:server:cancel', function()
    local src = source
    activeProgress[src] = nil
end)

RegisterNetEvent('ssr_progressbar:server:finish', function()
    local src = source
    local progressData = activeProgress[src]

    if not progressData then
        return
    end

    activeProgress[src] = nil

    if not Config or not Config.AntiCheat or not Config.AntiCheat.enabled then
        return
    end

    local now = GetGameTimer()
    local elapsed = now - progressData.startedAt
    local allowedEarlyMs = tonumber(Config.AntiCheat.allowedEarlyMs) or 0
    local minimumElapsed = math.max(progressData.duration - allowedEarlyMs, 0)

    if elapsed >= minimumElapsed then
        return
    end

    local reason = ('Action "%s" completed too fast'):format(progressData.actionName)

    print(('[ssr_progressbar] AntiCheat triggered for %s (%s) - expected %sms, got %sms'):format(GetPlayerName(src) or 'unknown', src, progressData.duration, elapsed))
    notifyExploit(src, reason, progressData.duration, elapsed)

    if Config.AntiCheat.kickPlayer then
        DropPlayer(src, Config.AntiCheat.kickReason or 'Progressbar exploit detected')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeProgress[src] = nil
end)

if Config and Config.AntiCheat and Config.AntiCheat.enableTestCommand then
    RegisterCommand(Config.AntiCheat.testCommandName or 'pbac_test', function(source)
        local src = source

        if src == 0 then
            print('[ssr_progressbar] test command is player-only')
            return
        end

        notifyExploit(src, 'Manual anti-cheat test command', 5000, 1)

        if Config.AntiCheat.kickPlayer then
            DropPlayer(src, '[TEST] Progressbar anti-cheat command')
        end
    end, false)
end
