fx_version 'cerulean'
game 'gta5'

author 'DaniWorld'
description 'Advanced Job Center Script'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
    'html/review.js'
}