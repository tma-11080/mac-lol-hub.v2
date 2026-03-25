MacTab = Window:MakeTab({
 Name = "mac",
 Icon = "rbxassetid://7733658504"
})

MacTab:AddParagraph("ESP","ESP Settings")

MacTab:AddToggle({
 Name = "Player ESP",
 Default = false,
 Callback = function(v)
  getgenv().mac_config.playerESP = v
 end
})

MacTab:AddToggle({
 Name = "Chest ESP",
 Default = false,
 Callback = function(v)
  getgenv().mac_config.chestESP = v
 end
})

MacTab:AddParagraph("Movement","Movement Settings")

MacTab:AddSlider({
 Name = "Height",
 Min = 1,
 Max = 15,
 Default = 5,
 Callback = function(v)
  getgenv().mac_config.height = v
 end
})

MacTab:AddToggle({
 Name = "Follow Nearest Enemy",
 Default = false,
 Callback = function(v)
  getgenv().mac_config.followEnemy = v
 end
})
