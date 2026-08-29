fx_version 'cerulean'
game 'gta5'

author 'bazq'
description 'DUI YouTube Sync TV for Paddock map'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales.lua'
}

client_scripts {
    'client/framework.lua',
    'client/main.lua'
}

server_scripts {
    'server/framework.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/control.css',
    'html/control.js',
    'html/tv.html',
    'html/style.css',
    'html/tv.js',
    'html/logo.webp',
    'html/weather_channel/index.html',
    'html/weather_channel/style.css',
    'html/weather_channel/app.js'
}

escrow_ignore {
    'config.lua',
    'locales.lua',
    'client/framework.lua',
    'client/main.lua',
    'server/framework.lua',
    'server/main.lua',
    'html/index.html',
    'html/control.css',
    'html/control.js',
    'html/tv.html',
    'html/style.css',
    'html/tv.js',
    'README.md',
    'DEVELOPER.md'
}
