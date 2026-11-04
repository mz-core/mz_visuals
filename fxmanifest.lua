fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mz_visuals'
author 'MZ Framework'
description 'Presets graficos individuais, FPS Boost seguro e monitor de desempenho'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/presets.lua',
    'shared/locales.lua'
}

client_scripts {
    'client/engine.lua',
    'client/main.lua'
}

ui_page 'web/index.html'
files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}
