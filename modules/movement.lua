task.spawn(function()

 while task.wait(0.1) do

  if getgenv().mac_config.followEnemy then

   local nearest
   local dist = math.huge

   for _,mob in pairs(workspace.Enemies:GetChildren()) do

    local d =
    (mob.HumanoidRootPart.Position -
    game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

    if d < dist then
     dist = d
     nearest = mob
    end

   end

   if nearest then

    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
    nearest.HumanoidRootPart.CFrame *
    CFrame.new(0,getgenv().mac_config.height,0)

   end

  end

 end

end)
