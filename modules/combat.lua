task.spawn(function()

 while task.wait(getgenv().mac_config.attackSpeed) do

  if getgenv().mac_config.auraRange then

   for _,mob in pairs(workspace.Enemies:GetChildren()) do

    if mob:FindFirstChild("Humanoid") then

     local dist =
     (mob.HumanoidRootPart.Position -
     game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

     if dist <= getgenv().mac_config.auraRange then

      mob.Humanoid:TakeDamage(1)

     end

    end

   end

  end

 end

end)
