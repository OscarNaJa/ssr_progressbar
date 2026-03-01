Config = Config or {}

Config.Colors = {
    progressBar = '#18a4ff',
    percentText = '#f2f5f8',
    boxBackground = 'rgba(7, 11, 18, 0.97)',
    boxBorder = 'rgba(255, 255, 255, 0.08)',
    boxInnerBorder = 'rgba(255, 255, 255, 0.03)',
    segmentEmpty = 'rgba(235, 241, 255, 0.42)',
    actionLabel = '#f2f5f8'
}

Config.Sounds = {
    enabled = true,
    completeMp3 = 'sounds/complete.mp3',
    cancelMp3 = 'sounds/cancel.mp3',
    volume = 0.35
}

Config.AntiCheat = {
    enabled = true,
    allowedEarlyMs = 250,
    kickPlayer = true,
    kickReason = 'Progressbar exploit detected',
    webhookUrl = '',
    webhookName = 'SSR Progressbar AC',
    webhookTitle = 'Progressbar Exploit Detected',
    webhookColor = 16724787,
    enableTestCommand = false,
    testCommandName = 'pbac_test'
}

Config.Test = {
    enableCommands = false
}
