server_script '@ElectronAC/src/include/server.lua'
client_script '@ElectronAC/src/include/client.lua'
fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Simple Ped Spawner for QB-Core'
version '1.0.0'
lua54 'yes'
shared_script '@ox_lib/init.lua'
shared_script 'config.lua'
client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}




