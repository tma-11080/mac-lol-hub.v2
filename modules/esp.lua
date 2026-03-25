task.spawn(function()

 while task.wait(1) do

  if getgenv().mac_config.playerESP then

   for _,plr in pairs(game.Players:GetPlayers()) do

    if plr ~= game.Players.LocalPlayer then

     local char = plr.Character

     if char and not char:FindFirstChild("PlayerESP") then

      local h = Instance.new("Highlight")
      h.Name = "PlayerESP"
      h.FillColor = Color3.fromRGB(0,255,0)
      h.Parent = char

     end

    end

   end

  end

 end

end)
