local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tma-11080/NeonGlass-UI.v2/refs/heads/main/main_redzglass.luau"))()
local Window = Library:MakeWindow({Title = "mac lol Hub : Cool Game", SubTitle = "by real_redz", ScriptFolder = "redz-library-V5"})
local Minimizer = Window:NewMinimizer({KeyCode = Enum.KeyCode.LeftControl})
local MobileButton = Minimizer:CreateMobileMinimizer({Image = "rbxassetid://74521750290358", BackgroundColor3 = Color3.fromRGB(0, 0, 0), Size = UDim2.fromOffset(50, 50)})

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MobileButton

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local fastAttack = false
local speedValue = 100
local toggleEnabled = false
local playerEspEnabled = false
local chestEspEnabled = false
local chestTpEnabled = false
local useNearest = true
local noclip = false
local currentFontMode = "Default"
local darkMode = false
local effectMono = false

-- BF / ported variables
local superRange = false
local autoV3 = false
local autoV4 = false
local nearestEnemyPos = nil
local aimbotSkill = false
local attackRange = 60

local targetPlayerName = ""
local jumpGui = nil
local lastChest = nil
local statsGui = nil

local autoAimEnabled = false
local autoAimGui = nil
local autoAimButton = nil
local autoAimLabel = nil
local lockedTarget = nil

local flyGui = nil
local flyToggleEnabled = false
local flySpeed = 1
local flyMoving = false
local flyUpConn = nil
local flyDownConn = nil

local playerEspCache = {}

local function getCharacter()
	return player.Character
end

local function getHumanoid(char)
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function getHRP(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function isAliveChar(char)
	local hum = getHumanoid(char)
	return hum and hum.Health > 0
end

local function applyFont(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
	if obj.Text and obj.Text:match("rbxassetid") then return end
	if obj.Name:lower():find("icon") then return end

	if currentFontMode == "Arcade" then
		obj.Font = Enum.Font.Arcade
	elseif currentFontMode == "Minecraft" then
		pcall(function()
			obj.FontFace = Font.new("rbxassetid://12187371840")
		end)
	else
		obj.Font = Enum.Font.SourceSans
	end
end

game.DescendantAdded:Connect(function(o)
	if currentFontMode ~= "Default" then
		pcall(function()
			applyFont(o)
		end)
	end
end)

local function getNearestEnemyCharacter()
	local char = getCharacter()
	local hrp = getHRP(char)
	if not char or not hrp then return nil end

	local closest = nil
	local dist = math.huge

	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return nil end

	for _, e in ipairs(enemies:GetChildren()) do
		if e:FindFirstChild("HumanoidRootPart") and isAliveChar(e) then
			local d = (e.HumanoidRootPart.Position - hrp.Position).Magnitude
			if d < dist then
				dist = d
				closest = e
			end
		end
	end

	return closest
end

local function getSelectedPlayerCharacter()
	if targetPlayerName ~= "" then
		local p = Players:FindFirstChild(targetPlayerName)
		if p and p.Character and isAliveChar(p.Character) then
			return p.Character
		end
	end
	return nil
end

local function getNearestPlayerCharacter()
	local char = getCharacter()
	local hrp = getHRP(char)
	if not char or not hrp then return nil end

	local closest = nil
	local dist = math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and getHRP(p.Character) and isAliveChar(p.Character) then
			local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
			if d < dist then
				dist = d
				closest = p.Character
			end
		end
	end

	return closest
end

local function getCombatTargetCharacter()
	local selected = getSelectedPlayerCharacter()
	if selected then return selected end

	if useNearest then
		local nearestPlayer = getNearestPlayerCharacter()
		if nearestPlayer then return nearestPlayer end
	end

	local enemy = getNearestEnemyCharacter()
	if enemy then return enemy end

	return nil
end

local function aimAtTarget(targetChar)
	local hrp = getHRP(targetChar)
	if not hrp then return end
	local camPos = Camera.CFrame.Position
	Camera.CFrame = CFrame.new(camPos, hrp.Position)
end

-- =========================================================
-- BF版 Kill Aura (message.txt より移植)
-- =========================================================
local function IsEntityAlive(entity)
	if not entity then return false end
	local humanoid = entity:FindFirstChild("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function GetEnemiesInRange(character, range)
	local targets = {}
	local playerPos = character:GetPivot().Position

	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, enemy in ipairs(enemies:GetChildren()) do
			local rootPart = enemy:FindFirstChild("HumanoidRootPart")
			if rootPart and IsEntityAlive(enemy) then
				if (rootPart.Position - playerPos).Magnitude <= range then
					table.insert(targets, enemy)
				end
			end
		end
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local rootPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if rootPart and IsEntityAlive(otherPlayer.Character) then
				if (rootPart.Position - playerPos).Magnitude <= range then
					table.insert(targets, otherPlayer.Character)
				end
			end
		end
	end

	return targets
end

local function attackNoCoolDown()
	local character = getCharacter()
	local hrp = getHRP(character)
	if not character or not hrp then return end

	local equippedWeapon
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") then
			equippedWeapon = item
			break
		end
	end
	if not equippedWeapon then return end

	if hrp:FindFirstChild("Buddha") and superRange then
		attackRange = 1000
	else
		attackRange = 60
	end

	local enemiesInRange = GetEnemiesInRange(character, attackRange)

	if equippedWeapon:FindFirstChild("LeftClickRemote") then
		local attackCount = 1
		for _, enemy in ipairs(enemiesInRange) do
			local rootPart = enemy:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local direction = (rootPart.Position - character:GetPivot().Position).Unit
				equippedWeapon.LeftClickRemote:FireServer(direction, attackCount)
				attackCount = attackCount + 1
			end
		end
	else
		local targets, mainTarget = {}, nil
		for _, enemy in ipairs(enemiesInRange) do
			if not enemy:GetAttribute("IsBoat") then
				local head = enemy:FindFirstChild("Head")
				if head then
					table.insert(targets, {enemy, head})
					mainTarget = head
				end
			end
		end
		if mainTarget then
			pcall(function()
				local net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
				local attackEvent = net:WaitForChild("RE/RegisterAttack")
				local hitEvent = net:WaitForChild("RE/RegisterHit")
				attackEvent:FireServer(0.1)
				hitEvent:FireServer(mainTarget, targets)
			end)
		end
	end
end

-- =========================================================
-- nearestEnemyPos 更新ループ (Aimbot 用)
-- =========================================================
task.spawn(function()
	while task.wait(0.1) do
		local char = getCharacter()
		if not char or not getHRP(char) then
			nearestEnemyPos = nil
			continue
		end
		local myPos = getHRP(char).Position
		local nearestDist = math.huge
		local nearestEnemy = nil
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other.Character and getHRP(other.Character) then
				local dist = (getHRP(other.Character).Position - myPos).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestEnemy = other.Character
				end
			end
		end
		nearestEnemyPos = nearestEnemy and getHRP(nearestEnemy).Position or nil
	end
end)

-- =========================================================
-- Aimbot __namecall フック (message.txt より移植)
-- =========================================================
pcall(function()
	spawn(function()
		local gg = getrawmetatable(game)
		local old = gg.__namecall
		setreadonly(gg, false)
		gg.__namecall = newcclosure(function(...)
			local method = getnamecallmethod()
			local args = {...}
			if tostring(method) == "FireServer" then
				if tostring(args[1]) == "RemoteEvent" then
					if tostring(args[2]) ~= "true" and tostring(args[2]) ~= "false" then
						if aimbotSkill and nearestEnemyPos then
							if type(args[2]) == "vector" then
								args[2] = nearestEnemyPos
							else
								args[2] = CFrame.new(nearestEnemyPos)
							end
							return old(unpack(args))
						end
					end
				end
			end
			return old(...)
		end)
	end)
end)

-- =========================================================
-- Auto V3 ループ
-- =========================================================
task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			if autoV3 then
				ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
			end
		end)
	end
end)

-- =========================================================
-- Auto V4 ループ
-- =========================================================
task.spawn(function()
	local lastCheckTime = 0
	while task.wait(0.1) do
		if autoV4 then
			local currentTime = tick()
			if currentTime - lastCheckTime >= 0.5 then
				lastCheckTime = currentTime
				local character = player.Character
				if character and character:FindFirstChild("RaceEnergy") and
					character.RaceEnergy.Value >= 1 and
					not character.RaceTransformed.Value then
					local be = game:GetService("VirtualInputManager")
					be:SendKeyEvent(true, "Y", false, game)
					task.wait(0.1)
					be:SendKeyEvent(false, "Y", false, game)
				end
			end
		end
	end
end)

-- =========================================================
-- Auto Aim GUI (既存)
-- =========================================================
local function createAutoAimGui()
	if autoAimGui then
		autoAimGui:Destroy()
		autoAimGui = nil
		autoAimButton = nil
		autoAimLabel = nil
	end

	autoAimGui = Instance.new("ScreenGui")
	autoAimGui.Name = "AutoAimUI"
	autoAimGui.ResetOnSpawn = false
	autoAimGui.Parent = CoreGui

	autoAimButton = Instance.new("ImageButton")
	autoAimButton.Name = "AutoAimToggle"
	autoAimButton.Size = UDim2.new(0, 80, 0, 80)
	autoAimButton.Position = UDim2.new(0, 20, 0.5, -40)
	autoAimButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
	autoAimButton.Image = "rbxassetid://74521750290358"
	autoAimButton.Draggable = true
	autoAimButton.Parent = autoAimGui

	autoAimLabel = Instance.new("TextLabel")
	autoAimLabel.Size = UDim2.new(1, 0, 0.3, 0)
	autoAimLabel.Position = UDim2.new(0, 0, 0.7, 0)
	autoAimLabel.BackgroundTransparency = 1
	autoAimLabel.Text = "OFF"
	autoAimLabel.TextColor3 = Color3.new(1, 1, 1)
	autoAimLabel.TextScaled = true
	autoAimLabel.Font = Enum.Font.SourceSansBold
	autoAimLabel.Parent = autoAimButton

	autoAimButton.MouseButton1Click:Connect(function()
		autoAimEnabled = not autoAimEnabled
		autoAimLabel.Text = autoAimEnabled and "ON" or "OFF"
		autoAimButton.BackgroundColor3 = autoAimEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 255, 50)

		if autoAimEnabled then
			local closestPlayer = nil
			local closestDist = math.huge
			local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = p.Character.HumanoidRootPart
					local screenPoint, onScreen = Camera:WorldToViewportPoint(hrp.Position)
					if onScreen then
						local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
						if dist < closestDist then
							closestDist = dist
							closestPlayer = p
						end
					end
				end
			end

			lockedTarget = closestPlayer
		else
			lockedTarget = nil
		end
	end)
end

-- =========================================================
-- Fly GUI
-- =========================================================
local function createFlyGui()
	if flyGui then
		flyGui:Destroy()
		flyGui = nil
	end

	flyGui = Instance.new("ScreenGui")
	flyGui.Name = "FlyV3"
	flyGui.ResetOnSpawn = false
	flyGui.Parent = playerGui

	local Frame = Instance.new("Frame")
	local up = Instance.new("TextButton")
	local down = Instance.new("TextButton")
	local onof = Instance.new("TextButton")
	local TextLabel = Instance.new("TextLabel")
	local plus = Instance.new("TextButton")
	local speed = Instance.new("TextLabel")
	local mine = Instance.new("TextButton")
	local closebutton = Instance.new("TextButton")
	local mini = Instance.new("TextButton")
	local mini2 = Instance.new("TextButton")

	Frame.Parent = flyGui
	Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
	Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
	Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
	Frame.Size = UDim2.new(0, 190, 0, 57)
	Frame.Active = true
	Frame.Draggable = true

	up.Name = "up"
	up.Parent = Frame
	up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
	up.Size = UDim2.new(0, 44, 0, 28)
	up.Font = Enum.Font.SourceSans
	up.Text = "UP"
	up.TextColor3 = Color3.fromRGB(0, 0, 0)
	up.TextSize = 14

	down.Name = "down"
	down.Parent = Frame
	down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
	down.Position = UDim2.new(0, 0, 0.491228074, 0)
	down.Size = UDim2.new(0, 44, 0, 28)
	down.Font = Enum.Font.SourceSans
	down.Text = "DOWN"
	down.TextColor3 = Color3.fromRGB(0, 0, 0)
	down.TextSize = 14

	onof.Name = "onof"
	onof.Parent = Frame
	onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
	onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
	onof.Size = UDim2.new(0, 56, 0, 28)
	onof.Font = Enum.Font.SourceSans
	onof.Text = "fly"
	onof.TextColor3 = Color3.fromRGB(0, 0, 0)
	onof.TextSize = 14

	TextLabel.Parent = Frame
	TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
	TextLabel.Position = UDim2.new(0.469327301, 0, 0, 0)
	TextLabel.Size = UDim2.new(0, 100, 0, 28)
	TextLabel.Font = Enum.Font.SourceSans
	TextLabel.Text = "FLY GUI V3"
	TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.TextScaled = true
	TextLabel.TextWrapped = true

	plus.Name = "plus"
	plus.Parent = Frame
	plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
	plus.Position = UDim2.new(0.231578946, 0, 0, 0)
	plus.Size = UDim2.new(0, 45, 0, 28)
	plus.Font = Enum.Font.SourceSans
	plus.Text = "+"
	plus.TextColor3 = Color3.fromRGB(0, 0, 0)
	plus.TextScaled = true
	plus.TextWrapped = true

	speed.Name = "speed"
	speed.Parent = Frame
	speed.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
	speed.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
	speed.Size = UDim2.new(0, 44, 0, 28)
	speed.Font = Enum.Font.SourceSans
	speed.Text = tostring(flySpeed)
	speed.TextColor3 = Color3.fromRGB(0, 0, 0)
	speed.TextScaled = true
	speed.TextWrapped = true

	mine.Name = "mine"
	mine.Parent = Frame
	mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
	mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
	mine.Size = UDim2.new(0, 45, 0, 29)
	mine.Font = Enum.Font.SourceSans
	mine.Text = "-"
	mine.TextColor3 = Color3.fromRGB(0, 0, 0)
	mine.TextScaled = true
	mine.TextWrapped = true

	closebutton.Name = "Close"
	closebutton.Parent = Frame
	closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
	closebutton.Font = Enum.Font.SourceSans
	closebutton.Size = UDim2.new(0, 45, 0, 28)
	closebutton.Text = "X"
	closebutton.TextSize = 30
	closebutton.Position = UDim2.new(0, 0, -1, 27)

	mini.Name = "minimize"
	mini.Parent = Frame
	mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
	mini.Font = Enum.Font.SourceSans
	mini.Size = UDim2.new(0, 45, 0, 28)
	mini.Text = "-"
	mini.TextSize = 40
	mini.Position = UDim2.new(0, 44, -1, 27)

	mini2.Name = "minimize2"
	mini2.Parent = Frame
	mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
	mini2.Font = Enum.Font.SourceSans
	mini2.Size = UDim2.new(0, 45, 0, 28)
	mini2.Text = "+"
	mini2.TextSize = 40
	mini2.Position = UDim2.new(0, 44, -1, 57)
	mini2.Visible = false

	local speaker = Players.LocalPlayer
	local nowe = false
	local tpwalking = false
	local movedUp = false
	local movedDown = false

	onof.MouseButton1Down:Connect(function()
		if nowe == true then
			nowe = false

			local ch = speaker.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
				hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
			end
		else
			nowe = true

			for i = 1, flySpeed do
				task.spawn(function()
					local hb = RunService.Heartbeat
					tpwalking = true
					local chr = Players.LocalPlayer.Character
					local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
					while tpwalking and hb:Wait() and chr and hum and hum.Parent do
						if hum.MoveDirection.Magnitude > 0 then
							chr:TranslateBy(hum.MoveDirection)
						end
					end
				end)
			end

			local char = Players.LocalPlayer.Character
			if char and char:FindFirstChild("Animate") then
				char.Animate.Disabled = true
			end

			local Hum = char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController"))
			if Hum then
				for _, v in next, Hum:GetPlayingAnimationTracks() do
					v:AdjustSpeed(0)
				end
			end

			local ch = speaker.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
				hum:ChangeState(Enum.HumanoidStateType.Swimming)
			end
		end

		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end

		if hum.RigType == Enum.HumanoidRigType.R6 then
			local plr = Players.LocalPlayer
			local torso = plr.Character and plr.Character:FindFirstChild("Torso")
			if not torso then return end

			local bg = Instance.new("BodyGyro", torso)
			bg.P = 9e4
			bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
			bg.cframe = torso.CFrame

			local bv = Instance.new("BodyVelocity", torso)
			bv.velocity = Vector3.new(0, 0.1, 0)
			bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

			if nowe == true then
				plr.Character.Humanoid.PlatformStand = true
			end

			while nowe == true and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 do
				RunService.RenderStepped:Wait()

				if plr.Character.Humanoid.MoveDirection.Magnitude > 0 then
					bv.velocity = workspace.CurrentCamera.CFrame.LookVector * (flySpeed * 5)
				else
					bv.velocity = Vector3.new(0, 0, 0)
				end

				bg.cframe = workspace.CurrentCamera.CFrame
			end

			bg:Destroy()
			bv:Destroy()
			plr.Character.Humanoid.PlatformStand = false
			if plr.Character:FindFirstChild("Animate") then
				plr.Character.Animate.Disabled = false
			end
			tpwalking = false
		else
			local plr = Players.LocalPlayer
			local UpperTorso = plr.Character and plr.Character:FindFirstChild("UpperTorso")
			if not UpperTorso then return end

			local bg = Instance.new("BodyGyro", UpperTorso)
			bg.P = 9e4
			bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
			bg.cframe = UpperTorso.CFrame

			local bv = Instance.new("BodyVelocity", UpperTorso)
			bv.velocity = Vector3.new(0, 0.1, 0)
			bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

			if nowe == true then
				plr.Character.Humanoid.PlatformStand = true
			end

			while nowe == true and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 do
				task.wait()

				if plr.Character.Humanoid.MoveDirection.Magnitude > 0 then
					bv.velocity = workspace.CurrentCamera.CFrame.LookVector * (flySpeed * 5)
				else
					bv.velocity = Vector3.new(0, 0, 0)
				end

				bg.cframe = workspace.CurrentCamera.CFrame
			end

			bg:Destroy()
			bv:Destroy()
			plr.Character.Humanoid.PlatformStand = false
			if plr.Character:FindFirstChild("Animate") then
				plr.Character.Animate.Disabled = false
			end
			tpwalking = false
		end
	end)

	up.MouseButton1Down:Connect(function()
		movedUp = true
		while movedUp do
			task.wait()
			local char = Players.LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = hrp.CFrame * CFrame.new(0, 1, 0)
			end
		end
	end)

	up.MouseButton1Up:Connect(function()
		movedUp = false
	end)

	down.MouseButton1Down:Connect(function()
		movedDown = true
		while movedDown do
			task.wait()
			local char = Players.LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = hrp.CFrame * CFrame.new(0, -1, 0)
			end
		end
	end)

	down.MouseButton1Up:Connect(function()
		movedDown = false
	end)

	game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.7)
		local ch = game.Players.LocalPlayer.Character
		if ch and ch:FindFirstChildOfClass("Humanoid") then
			ch.Humanoid.PlatformStand = false
		end
		if ch and ch:FindFirstChild("Animate") then
			ch.Animate.Disabled = false
		end
	end)

	plus.MouseButton1Down:Connect(function()
		flySpeed = flySpeed + 1
		speed.Text = tostring(flySpeed)
	end)

	mine.MouseButton1Down:Connect(function()
		if flySpeed == 1 then
			speed.Text = "cannot be less than 1"
			task.wait(1)
			speed.Text = tostring(flySpeed)
		else
			flySpeed = flySpeed - 1
			speed.Text = tostring(flySpeed)
		end
	end)

	closebutton.MouseButton1Click:Connect(function()
		if flyGui then
			flyGui:Destroy()
			flyGui = nil
		end
	end)

	mini.MouseButton1Click:Connect(function()
		up.Visible = false
		down.Visible = false
		onof.Visible = false
		plus.Visible = false
		speed.Visible = false
		mine.Visible = false
		mini.Visible = false
		mini2.Visible = true
		Frame.BackgroundTransparency = 1
		closebutton.Position = UDim2.new(0, 0, -1, 57)
	end)

	mini2.MouseButton1Click:Connect(function()
		up.Visible = true
		down.Visible = true
		onof.Visible = true
		plus.Visible = true
		speed.Visible = true
		mine.Visible = true
		mini.Visible = true
		mini2.Visible = false
		Frame.BackgroundTransparency = 0
		closebutton.Position = UDim2.new(0, 0, -1, 27)
	end)
end

local function refreshPlayers()
	local pList = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			table.insert(pList, p.Name)
		end
	end
	return pList
end

-- =========================================================
-- タブ構成
-- =========================================================

local FarmTab = Window:MakeTab({Title = "Main farm Tab", Icon = "Home"})
FarmTab:AddDropdown({
	Name = "Scarlet Tool",
	MultiSelect = false,
	Options = {"Melee", "Blox fruits", "Sword", "gen"},
	Default = "Melee",
	Callback = function(v)
	end
})
FarmTab:AddToggle({
	Name = "Chest Fast TP",
	Default = false,
	Callback = function(v)
		chestTpEnabled = v
	end
})

local VisualTab = Window:MakeTab({Title = "Visual", Icon = "eye"})
VisualTab:AddToggle({
	Name = "Player ESP",
	Default = false,
	Callback = function(v)
		playerEspEnabled = v
		if not v then
			for _, h in pairs(playerEspCache) do
				if h and h.Parent then
					h:Destroy()
				end
			end
			table.clear(playerEspCache)
		end
	end
})
VisualTab:AddToggle({
	Name = "Chest ESP",
	Default = false,
	Callback = function(v)
		chestEspEnabled = v
	end
})

local CombatTab = Window:MakeTab({Title = "Combat", Icon = "crosshair"})
CombatTab:AddToggle({
	Name = "Target Nearest (Priority)",
	Default = true,
	Callback = function(v)
		useNearest = v
	end
})
CombatTab:AddDropdown({
	Name = "Select Player",
	MultiSelect = false,
	Options = refreshPlayers(),
	Callback = function(v)
		targetPlayerName = v
	end
})
CombatTab:AddButton({
	Name = "Refresh Player List",
	Callback = function()
		local list = refreshPlayers()
		pcall(function()
			for _, child in ipairs(CombatTab:GetChildren()) do
				if child.Name == "Select Player" and child.SetOptions then
					child:SetOptions(list)
				end
			end
		end)
	end
})
CombatTab:AddToggle({
	Name = "Auto Aim Button",
	Default = false,
	Callback = function(v)
		if v then
			createAutoAimGui()
		else
			if autoAimGui then
				autoAimGui:Destroy()
				autoAimGui = nil
				autoAimButton = nil
				autoAimLabel = nil
			end
			autoAimEnabled = false
			lockedTarget = nil
		end
	end
})
CombatTab:AddToggle({
	Name = "Aimbot (BF)",
	Default = false,
	Callback = function(v)
		aimbotSkill = v
	end
})
CombatTab:AddToggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(v)
		effectMono = v
	end
})
CombatTab:AddToggle({
	Name = "Kill Aura",
	Default = false,
	Callback = function(v)
		fastAttack = v
	end
})
CombatTab:AddToggle({
	Name = "Super Range (Buddha Only)",
	Default = false,
	Callback = function(v)
		superRange = v
	end
})

local FontTab = Window:MakeTab({Title = "Font", Icon = "pencil"})
FontTab:AddToggle({
	Name = "Arcade font",
	Default = false,
	Callback = function(v)
		currentFontMode = v and "Arcade" or "Default"
		for _, x in pairs(game:GetDescendants()) do
			pcall(function()
				applyFont(x)
			end)
		end
	end
})
FontTab:AddToggle({
	Name = "Minecraft font",
	Default = false,
	Callback = function(v)
		currentFontMode = v and "Minecraft" or "Default"
		for _, x in pairs(game:GetDescendants()) do
			pcall(function()
				applyFont(x)
			end)
		end
	end
})

local MiscTab = Window:MakeTab({Title = "misc Tab", Icon = "settings"})
MiscTab:AddToggle({
	Name = "Noclip",
	Default = false,
	Callback = function(v)
		noclip = v
	end
})
MiscTab:AddToggle({
	Name = "Speed",
	Default = false,
	Callback = function(v)
		toggleEnabled = v
	end
})
MiscTab:AddSlider({
	Name = "Speed Slider",
	Min = 1,
	Max = 300,
	Increment = 1,
	Default = 100,
	Callback = function(v)
		speedValue = v
	end
})
MiscTab:AddButton({
	Name = "Show Jump Button",
	Callback = function()
		if jumpGui then
			jumpGui:Destroy()
		end
		jumpGui = Instance.new("ScreenGui")
		jumpGui.ResetOnSpawn = false
		jumpGui.Parent = playerGui

		local b = Instance.new("TextButton")
		b.Parent = jumpGui
		b.Size = UDim2.new(0, 60, 0, 60)
		b.Position = UDim2.new(0.8, 0, 0.7, 0)
		b.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		b.Text = "JUMP"
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.SourceSansBold
		b.TextSize = 20

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = b

		b.MouseButton1Click:Connect(function()
			local char = getCharacter()
			local hrp = getHRP(char)
			if hrp then
				hrp.CFrame = hrp.CFrame * CFrame.new(0, 10, 0)
			end
		end)
	end
})
MiscTab:AddToggle({
	Name = "Fly GUI V3",
	Default = false,
	Callback = function(v)
		flyToggleEnabled = v
		if v then
			if flyGui then
				flyGui:Destroy()
				flyGui = nil
			end
			createFlyGui()
		else
			if flyGui then
				flyGui:Destroy()
				flyGui = nil
			end
		end
	end
})
MiscTab:AddToggle({
	Name = "Show FPS / Ping",
	Default = false,
	Callback = function(v)
		if v then
			if statsGui then statsGui:Destroy() end
			statsGui = Instance.new("ScreenGui")
			statsGui.ResetOnSpawn = false
			statsGui.Parent = playerGui

			local l = Instance.new("TextLabel")
			l.Parent = statsGui
			l.Size = UDim2.new(0, 200, 0, 30)
			l.Position = UDim2.new(0, 20, 0, 20)
			l.BackgroundTransparency = 1
			l.TextColor3 = Color3.new(1, 1, 1)
			l.Font = Enum.Font.Code
			l.TextSize = 16
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Draggable = true

			task.spawn(function()
				local f = 0
				local fc = 0
				local ls = tick()
				local cn = RunService.RenderStepped:Connect(function()
					fc = fc + 1
				end)

				while statsGui do
					local n = tick()
					if n - ls >= 1 then
						f = fc
						fc = 0
						ls = n
					end
					pcall(function()
						l.Text = string.format("FPS: %d  Ping: %d", f, math.floor(StatsService.PerformanceStats.Ping:GetValue()))
					end)
					l.TextColor3 = Color3.fromHSV((n % 5) / 5, 1, 1)
					task.wait(0.1)
				end

				cn:Disconnect()
			end)
		else
			if statsGui then
				statsGui:Destroy()
				statsGui = nil
			end
		end
	end
})

-- =========================================================
-- BF タブ (新規・移植機能)
-- =========================================================
local BFTab = Window:MakeTab({Title = "BF", Icon = "zap"})

BFTab:AddToggle({
	Name = "Remove Lava",
	Default = false,
	Callback = function(v)
		if v then
			local targets = {"CircleIsland", "GhostShipInterior"}
			for _, areaName in ipairs(targets) do
				local map = workspace:FindFirstChild("Map")
				local area = map and map:FindFirstChild(areaName)
				if area then
					for _, obj in ipairs(area:GetDescendants()) do
						if obj.Name == "LavaParts" then
							obj:Destroy()
						end
					end
				end
			end
		end
	end
})

BFTab:AddToggle({
	Name = "Walk Water",
	Default = false,
	Callback = function(v)
		pcall(function()
			local waterPlane = workspace.Map["WaterBase-Plane"]
			if v then
				waterPlane.Size = Vector3.new(1000, 112, 1000)
			else
				waterPlane.Size = Vector3.new(1000, 80, 1000)
			end
		end)
	end
})

BFTab:AddToggle({
	Name = "Auto V3",
	Default = false,
	Callback = function(v)
		autoV3 = v
	end
})

BFTab:AddToggle({
	Name = "Auto V4",
	Default = false,
	Callback = function(v)
		autoV4 = v
	end
})

-- =========================================================
-- RenderStepped メインループ
-- =========================================================
RunService.RenderStepped:Connect(function()
	local char = getCharacter()
	local hrp = getHRP(char)
	if not char or not hrp then return end

	if toggleEnabled and getHumanoid(char) then
		getHumanoid(char).WalkSpeed = speedValue
	end

	if noclip then
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end

	if fastAttack then
		attackNoCoolDown()
	end

	if effectMono then
		local t = getCombatTargetCharacter()
		if t then
			pcall(function()
				aimAtTarget(t)
			end)
		end
	end

	if autoAimEnabled and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockedTarget.Character.HumanoidRootPart.Position)
	end

	if chestTpEnabled then
		for _, o in pairs(workspace:GetDescendants()) do
			if o:IsA("Model") and o.Name:lower():find("chest") then
				local p = o:FindFirstChildWhichIsA("BasePart")
				if p then
					if lastChest ~= o then
						hrp.CFrame = p.CFrame * CFrame.new(0, 3, 0)
						lastChest = o
						break
					end
				end
			end
		end
	end

	if playerEspEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				if not playerEspCache[p] or not playerEspCache[p].Parent then
					local h = Instance.new("Highlight")
					h.Name = "PlayerESP"
					h.FillColor = Color3.fromRGB(0, 170, 255)
					h.OutlineColor = Color3.fromRGB(255, 255, 255)
					h.FillTransparency = 0.5
					h.OutlineTransparency = 0
					h.Parent = p.Character
					playerEspCache[p] = h
				end
			end
		end
	else
		for p, h in pairs(playerEspCache) do
			if h and h.Parent then
				h:Destroy()
			end
			playerEspCache[p] = nil
		end
	end

	if chestEspEnabled then
		for _, o in pairs(workspace:GetDescendants()) do
			if o:IsA("Model") and o.Name:lower():find("chest") then
				if not o:FindFirstChild("Highlight") then
					local h = Instance.new("Highlight")
					h.Name = "Highlight"
					h.FillColor = Color3.fromRGB(255, 215, 0)
					h.OutlineColor = Color3.fromRGB(255, 255, 255)
					h.Parent = o
				end
			end
		end
	else
		for _, o in pairs(workspace:GetDescendants()) do
			if o:IsA("Model") and o.Name:lower():find("chest") then
				local h = o:FindFirstChild("Highlight")
				if h then
					h:Destroy()
				end
			end
		end
	end
end)
