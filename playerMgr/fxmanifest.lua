fx_version 	'cerulean'
game 		'gta5'
lua54 		'yes'

author 		'Dr. Monero'
description 'Manages player and player assets'
version 	'0.0.1'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
	'client.lua'
}

ui_page '/nui/playerMgr.html'

files{
    'nui/playerMgr.html',
    'nui/playerMgr.css',
    'nui/playerMgr.js',
    'nui/img/*'
}