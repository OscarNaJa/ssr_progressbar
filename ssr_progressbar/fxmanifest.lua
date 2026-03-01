fx_version 'cerulean'
game 'gta5'

name 'ssr_progressbar'
author 'Alzar - https://github.com/Alzar => modified by M. TaerAttO - https://github.com/MonsterTaerAttO/mythic_progbar'
version '1.1.0'

ui_page('html/index.html')

shared_script 'config.lua'

server_script 'server.lua'

client_scripts {
    'client/functions.lua',
    'client/events.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',

    'html/css/bootstrap.min.css',
    'html/js/jquery.min.js',
    'html/sounds/*.mp3',
}

exports {
    'Progress',
    'ProgressWithStartEvent',
    'ProgressWithTickEvent',
    'ProgressWithStartAndTick'
}

lua54 'yes'
