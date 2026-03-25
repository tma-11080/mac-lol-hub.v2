local Minimizer = Window:NewMinimizer({
 KeyCode = Enum.KeyCode.LeftControl
})

local MobileButton = Minimizer:CreateMobileMinimizer({
 Image = "rbxassetid://74521750290358",
 BackgroundColor3 = Color3.fromRGB(0,0,0),
 Size = UDim2.fromOffset(50,50)
})

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,12)
Corner.Parent = MobileButton
