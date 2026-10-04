local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

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

getgenv().VD = getgenv().VD or {
    KILLER_SilentAimFlask = true,
    KILLER_FlaskLaser = true
}

-- =====================================================
-- SILENT AIM
-- =====================================================

local oldNamecall

oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if getgenv().VD.KILLER_SilentAimFlask
        and method == "FireServer"
        and self.Name == "ThrowFlask" then

        local closest = nil
        local minDst = math.huge

        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")

        if myRoot then
            local myPos = myRoot.Position

            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer
                    and v.Character
                    and v.Character:FindFirstChild("HumanoidRootPart")
                    and not v.Character:GetAttribute("IsKiller") then

                    local dst = (
                        v.Character.HumanoidRootPart.Position - myPos
                    ).Magnitude

                    if dst < minDst then
                        minDst = dst
                        closest = v
                    end
                end
            end
        end

        if closest then
            local targetPos =
                closest.Character.HumanoidRootPart.Position

            if args[2] and typeof(args[2]) == "Vector3" then
                args[1] = (targetPos - args[2]).Unit
            end

            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- =====================================================
-- FLASK LASER
-- =====================================================

getgenv().CureFlaskLaserPart = nil

local function UpdateCureFlaskLaser()
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local hand =
        char:FindFirstChild("LeftHand")
        or char:FindFirstChild("Left Arm")

    local originPos = hand and hand.Position or hrp.Position

    local closest = nil
    local minDst = math.huge

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer
            and v.Character
            and v.Character:FindFirstChild("HumanoidRootPart")
            and not v.Character:GetAttribute("IsKiller") then

            local dst = (
                v.Character.HumanoidRootPart.Position - hrp.Position
            ).Magnitude

            if dst < minDst then
                minDst = dst
                closest = v
            end
        end
    end

    local targetPos

    if closest then
        targetPos = closest.Character.HumanoidRootPart.Position
    end

    local actionActive = false

    for _, child in pairs(char:GetChildren()) do
        if child:IsA("LocalScript")
            and child:GetAttribute("action") == true then

            actionActive = true
            break
        end
    end

    if originPos and targetPos and actionActive then
        if not getgenv().CureFlaskLaserPart then
            local laser = Instance.new("Part")

            laser.Name = "FlaskSilentAimLaser"
            laser.Anchored = true
            laser.CanCollide = false
            laser.CanTouch = false
            laser.CanQuery = false
            laser.Material = Enum.Material.Neon
            laser.Color = Color3.fromRGB(0, 100, 255)
            laser.Parent = workspace

            getgenv().CureFlaskLaserPart = laser
        end

        local laser = getgenv().CureFlaskLaserPart
        local dist = (targetPos - originPos).Magnitude

        if dist > 0.1 then
            laser.Size = Vector3.new(0.1, 0.1, dist)
            laser.CFrame = CFrame.new(
                (originPos + targetPos) / 2,
                targetPos
            )
            laser.Transparency = 0
        end
    else
        if getgenv().CureFlaskLaserPart then
            getgenv().CureFlaskLaserPart.Transparency = 1
        end
    end
end

local FlaskLaserConnection = RunService.RenderStepped:Connect(function()
    if getgenv().VD.KILLER_FlaskLaser then
        pcall(UpdateCureFlaskLaser)
    elseif getgenv().CureFlaskLaserPart then
        getgenv().CureFlaskLaserPart:Destroy()
        getgenv().CureFlaskLaserPart = nil
    end
end)

-- =====================================================
-- FLUENT UI
-- =====================================================

local FlaskSection = Tabs.Killer:AddSection("Flask")

Tabs.Main:AddToggle("FlaskSilentAim", {
    Title = "Flask Silent Aim",
    Default = getgenv().VD.KILLER_SilentAimFlask,

    Callback = function(Value)
        getgenv().VD.KILLER_SilentAimFlask = Value
    end
})

Tabs.Main:AddToggle("FlaskLaser", {
    Title = "Flask Laser",
    Default = getgenv().VD.KILLER_FlaskLaser,

    Callback = function(Value)
        getgenv().VD.KILLER_FlaskLaser = Value

        if not Value and getgenv().CureFlaskLaserPart then
            getgenv().CureFlaskLaserPart:Destroy()
            getgenv().CureFlaskLaserPart = nil
        end
    end
})
