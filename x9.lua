local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

getgenv().VD = getgenv().VD or {}

if getgenv().VD.KILLER_SilentAimFlask == nil then
    getgenv().VD.KILLER_SilentAimFlask = true
end

if getgenv().VD.KILLER_FlaskLaser == nil then
    getgenv().VD.KILLER_FlaskLaser = true
end


local Window = Fluent:CreateWindow({
    Title = "ReaperX | Silent Aim Flask",
    SubTitle = "Violence District (Mobile)",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 320),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({
        Title = "Aiming",
        Icon = "target"
    })
}


local oldNamecall

oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" and self.Name == "ThrowFlask" then
        if getgenv().VD.KILLER_SilentAimFlask then

            local closest = nil
            local minDst = math.huge

            local character = LocalPlayer.Character

            local root =
                character
                and character:FindFirstChild("HumanoidRootPart")

            local myPos = root and root.Position

            if myPos then

                for _, v in pairs(Players:GetPlayers()) do

                    if v ~= LocalPlayer
                        and v.Character
                        and v.Character:FindFirstChild("HumanoidRootPart") then

                        if not v.Character:GetAttribute("IsKiller") then

                            local dst = (
                                v.Character.HumanoidRootPart.Position
                                - myPos
                            ).Magnitude

                            if dst < minDst then
                                minDst = dst
                                closest = v
                            end
                        end
                    end
                end
            end

            if closest then

                local targetPos =
                    closest.Character.HumanoidRootPart.Position

                if args[2] and typeof(args[2]) == "Vector3" then

                    args[1] =
                        (targetPos - args[2]).Unit

                end

                return oldNamecall(
                    self,
                    unpack(args)
                )
            end
        end
    end

    return oldNamecall(self, ...)
end)

getgenv().KYS_CureFlaskLaserPart = nil

function UpdateCureFlaskLaser()

    local char = LocalPlayer.Character

    if not char then
        return
    end

    local targetPos = nil
    local originPos = nil
    local closest = nil
    local minDst = math.huge

    local hrp =
        char:FindFirstChild("HumanoidRootPart")

    if hrp then

        local hand =
            char:FindFirstChild("LeftHand")
            or char:FindFirstChild("Left Arm")

        originPos =
            hand and hand.Position
            or hrp.Position

        for _, v in pairs(Players:GetPlayers()) do

            if v ~= LocalPlayer
                and v.Character
                and v.Character:FindFirstChild("HumanoidRootPart") then

                if not v.Character:GetAttribute("IsKiller") then

                    local dst = (
                        v.Character.HumanoidRootPart.Position
                        - hrp.Position
                    ).Magnitude

                    if dst < minDst then
                        minDst = dst
                        closest = v
                    end
                end
            end
        end
    end

    if closest then
        targetPos =
            closest.Character.HumanoidRootPart.Position
    end

    -- Check Flask action state
    local actionActive = false

    for _, child in pairs(char:GetChildren()) do

        if child:IsA("LocalScript")
            and child:GetAttribute("action") == true then

            actionActive = true
            break
        end
    end

    -- Create / update laser
    if originPos
        and targetPos
        and actionActive
        and getgenv().VD.KILLER_FlaskLaser then

        if not getgenv().KYS_CureFlaskLaserPart then

            local laser = Instance.new("Part")

            laser.Name = "FlaskSilentAimLaser"

            laser.Anchored = true
            laser.CanCollide = false
            laser.CanTouch = false

            laser.Material = Enum.Material.Neon
            laser.Color = Color3.fromRGB(0, 100, 255)

            laser.Parent = workspace

            getgenv().KYS_CureFlaskLaserPart = laser
        end

        local dist =
            (targetPos - originPos).Magnitude

        if dist > 0.1 then

            local laser =
                getgenv().KYS_CureFlaskLaserPart

            laser.Size =
                Vector3.new(
                    0.16,
                    0.16,
                    dist
                )

            laser.CFrame =
                CFrame.new(
                    (originPos + targetPos) / 2,
                    targetPos
                )

            laser.Transparency = 0
        end

    else

        if getgenv().KYS_CureFlaskLaserPart then
            getgenv().KYS_CureFlaskLaserPart.Transparency = 1
        end
    end
end

RunService.RenderStepped:Connect(function()

    pcall(function()
        UpdateCureFlaskLaser()
    end)

end)


local FlaskSection =
    Tabs.Main:AddSection("Flask")

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

        if not Value then

            if getgenv().KYS_CureFlaskLaserPart then

                getgenv().KYS_CureFlaskLaserPart:Destroy()
                getgenv().KYS_CureFlaskLaserPart = nil

            end
        end
    end
})

Window:SelectTab(1)
