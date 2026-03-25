local base = "https://raw.githubusercontent.com/USERNAME/REPO/main/"

loadstring(game:HttpGet(base.."config.lua"))()

loadstring(game:HttpGet(base.."core/ui.lua"))()
loadstring(game:HttpGet(base.."core/minimizer.lua"))()
loadstring(game:HttpGet(base.."core/font.lua"))()

loadstring(game:HttpGet(base.."tabs/mac.lua"))()
loadstring(game:HttpGet(base.."tabs/mainfarm.lua"))()
loadstring(game:HttpGet(base.."tabs/misc.lua"))()

loadstring(game:HttpGet(base.."modules/esp.lua"))()
loadstring(game:HttpGet(base.."modules/combat.lua"))()
loadstring(game:HttpGet(base.."modules/movement.lua"))()
