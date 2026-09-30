shared_script '@WaveShield/resource/include.lua'
fx_version 'cerulean'
game 'gta5'
author 'TR'
description 'TR Admin Menu'
version '1.0.0'
shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'shared/config.lua',
    'shared/framework.lua',
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/webhooks.lua',
    'server/main.lua',
}
client_scripts {
    'client/main.lua',
}
ui_page 'html/index.html'
files {
    'html/**/*',
    'locales/*.json',
}
lua54 'yes'
