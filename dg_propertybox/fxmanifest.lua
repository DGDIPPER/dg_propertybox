fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'YourName'
description 'Your resource description'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'qbx_core'
}
