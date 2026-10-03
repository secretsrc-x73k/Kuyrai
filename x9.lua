local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- // Configuration //
getgenv().FlaskConfig = {
    Enabled = false,
    Laser = false,
    LaserColor = Color3.fromRGB(0, 100, 255),
    LaserTransparency = 0.5
}

-- // Target Logic //
local function GetClosestSurvivor()
    local closest = nil
    local minDst = math.huge
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if myRoot then
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                -- เช็คว่าเป็น Survivor (ไม่ใช่ฆาตกร) และไม่ตาย
                local isKiller = v.Character:GetAttribute("IsKiller")
                local health = v.Character:FindFirstChildOfClass("Humanoid") and v.Character:FindFirstChildOfClass("Humanoid").Health or 0
                
                if not isKiller and health > 0 then
                    local dst = (v.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                    if dst < minDst then
                        minDst = dst
                        closest = v
                    end
                end
            end
        end
    end
    return closest
end

-- // Metamethod Hook (Silent Aim) //
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if getgenv().FlaskConfig.Enabled and method == "FireServer" and self.Name == "ThrowFlask" then
        local target = GetClosestSurvivor()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Character.HumanoidRootPart.Position
            -- args[1] คือทิศทาง (Unit Vector), args[2] คือจุดกำเนิด
            if args[2] and typeof(args[2]) == "Vector3" then
                args[1] = (targetPos - args[2]).Unit -- บิดทิศทางเข้าหาเป้าหมาย
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- // Laser Visuals //
local LaserPart = nil
RunService.RenderStepped:Connect(function()
    if not getgenv().FlaskConfig.Laser then 
        if LaserPart then LaserPart.Transparency = 1 end
        return 
    end

    local char = LocalPlayer.Character
    if not char then return end

    -- ตรวจสอบว่ากำลังง้างขวดอยู่หรือไม่
    local isCharging = false
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("LocalScript") and child:GetAttribute("action") == true then
            isCharging = true
            break
        end
    end

    local target = GetClosestSurvivor()
    if isCharging and target and char:FindFirstChild("HumanoidRootPart") then
        if not LaserPart then
            LaserPart = Instance.new("Part")
            LaserPart.Name = "HyperX_FlaskLaser"
            LaserPart.Anchored = true
            LaserPart.CanCollide = false
            LaserPart.Material = Enum.Material.Neon
            LaserPart.Parent = workspace
        end

        local hand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm") or char.HumanoidRootPart
        local originPos = hand.Position
        local targetPos = target.Character.HumanoidRootPart.Position
        local dist = (targetPos - originPos).Magnitude

        LaserPart.Size = Vector3.new(0.12, 0.12, dist)
        LaserPart.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
        LaserPart.Color = getgenv().FlaskConfig.LaserColor
        LaserPart.Transparency = getgenv().FlaskConfig.LaserTransparency
    elseif LaserPart then
        LaserPart.Transparency = 1
    end
end)

-- // Fluent UI Setup //
local Window = Fluent:CreateWindow({
    Title = "ReaperX | Silent Aim Flask",
    SubTitle = "Violence District (Mobile)",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 320), -- ปรับขนาดให้พอดีมือถือ
    Acrylic = false, -- ปิดความโปร่งใสเพื่อความลื่นบนมือถือ
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Aiming", Icon = "target" })
}

local Section = Tabs.Main:AddSection("Flask Cure Settings")

Section:AddToggle("FlaskSilent", {
    Title = "Silent Aim Flask",
    Description = "",
    Default = false,
    Callback = function(Value)
        getgenv().FlaskConfig.Enabled = Value
    end
})

Section:AddToggle("FlaskLaser", {
    Title = "Show Visual Laser",
    Description = "",
    Default = false,
    Callback = function(Value)
        getgenv().FlaskConfig.Laser = Value
    end
})

Section:AddColorPicker("LaserColor", {
    Title = "Laser Color",
    Default = Color3.fromRGB(0, 100, 255),
    Callback = function(Value)
        getgenv().FlaskConfig.LaserColor = Value
    end
})
เ
