server_script '@ElectronAC/src/include/server.lua'
client_script '@ElectronAC/src/include/client.lua'
fx_version "cerulean"
game "gta5"
lua54 "yes"
author "Alfaben"
description "iPhone 15"
version "1.0.0"

dependency "simi_logger"
dependency "ox_lib"
dependency "screenshot-basic"

-- ui_page "http://localhost:5173"
ui_page "html/index.html"

shared_scripts {
  "@ox_lib/init.lua",
  "config/config.lua",
  "config/**",
  "shared/messages.lua",
  "shared/constants.lua",
  "shared/events.lua",
  "shared/types.lua"
}

client_scripts {
  "shared/messages.lua",
  "client/lib/rpc.lua",
  "client/lib/state.lua",
  "client/lib/nui.lua",
  "client/lib/sound.lua",
  "client/lib/animation.lua",
  "client/lib/net.lua",
  "client/lib/zones.lua",
  "client/core/*.lua",
  "client/apps/*.lua",
  "client/main.lua"
}

server_scripts {
  "shared/messages.lua",
  "@oxmysql/lib/MySQL.lua",
  "server/queries/*.lua",
  "server/**"
}

files {
  "html/index.html",
  "html/**/*.png",
  "html/**/*.svg",
  "html/**/*.json",
  "html/**/*.jpg",
  "html/assets/*.css",
  "html/assets/*.js"
}
