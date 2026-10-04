local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- FLAGS
-- =========================================================

getgenv().VD = getgenv().VD or {}

if getgenv().VD.KILLER_SilentAimFlask == nil then
    getgenv().VD.KILLER_SilentAimFlask = false
end

if getgenv().VD.KILLER_FlaskLaser == nil then
    getgenv().VD.KILLER_FlaskLaser = false
end

local VD = getgenv().VD

-- =========================================================
-- FLASK LASER STATE
-- =========================================================

getgenv().KYS_CureFlaskLaserThread = nil
getgenv().KYS_CureFlaskLaserPart = nil

-- =========================================================
-- FLASK LASER UPDATE
-- =========================================================

function KYS_UpdateCureFlaskLaser()

    local char = game:GetService("Players").LocalPlayer.Character

    if not char then
        return
    end

    local targetPos = nil
    local originPos = nil

    local closest = nil
    local minDst = math.huge

    local hrp = char:FindFirstChild("HumanoidRootPart")

    if hrp then

        local hand =
            char:FindFirstChild("LeftHand")
            or char:FindFirstChild("Left Arm")

        originPos =
            hand and hand.Position
            or hrp.Position

        for _, v in pairs(
            game:GetService("Players"):GetPlayers()
        ) do

            if v ~= game:GetService("Players").LocalPlayer
                and v.Character
                and v.Character:FindFirstChild("HumanoidRootPart") then

                if not v.Character:GetAttribute("IsKiller") then

                    local dst =
                        (
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

    -- Check action attribute
    local actionActive = false

    for _, child in pairs(char:GetChildren()) do

        if child:IsA("LocalScript")
            and child:GetAttribute("action") == true then

            actionActive = true
            break
        end
    end

    -- Create / update laser
    if originPos and targetPos and actionActive then

        if not getgenv().KYS_CureFlaskLaserPart then

            local laser = Instance.new("Part")

            laser.Name = "FlaskSilentAimLaser"
            laser.Anchored = true
            laser.CanCollide = false
            laser.CanTouch = false
            laser.CastShadow = false

            laser.Material = Enum.Material.Neon
            laser.Color = Color3.fromRGB(0, 100, 255)
            laser.Transparency = 0

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

-- =========================================================
-- START FLASK LASER
-- =========================================================

function KYS_StartCureFlaskLaser()

    if getgenv().KYS_CureFlaskLaserThread then
        return
    end

    getgenv().KYS_CureFlaskLaserThread =
        RunService.RenderStepped:Connect(function()

            if not VD.KILLER_FlaskLaser then

                if getgenv().KYS_CureFlaskLaserPart then

                    pcall(function()
                        getgenv().KYS_CureFlaskLaserPart:Destroy()
                    end)

                    getgenv().KYS_CureFlaskLaserPart = nil
                end

                if getgenv().KYS_CureFlaskLaserThread then

                    getgenv().KYS_CureFlaskLaserThread:Disconnect()
                    getgenv().KYS_CureFlaskLaserThread = nil

                end

                return
            end

            pcall(KYS_UpdateCureFlaskLaser)
        end)
end

-- =========================================================
-- CENTRALIZED NAMECALL HOOK
-- =========================================================

local _genv = getgenv()

if not _genv.KYS_FlaskHookInstalled then

    _genv.KYS_FlaskHookInstalled = true

    _genv.KYS_oldNamecall =
        hookmetamethod(game, "__namecall", function(self, ...)

            local method = getnamecallmethod()

            -- =============================================
            -- SILENT AIM FLASK
            -- =============================================

            if VD.KILLER_SilentAimFlask
                and method == "FireServer" then

                local ok, name =
                    pcall(function()
                        return self.Name
                    end)

                if ok and name == "ThrowFlask" then

                    local args = {...}

                    local closest = nil
                    local minDst = math.huge

                    local lp =
                        game:GetService("Players").LocalPlayer

                    local myPos =
                        lp.Character
                        and lp.Character:FindFirstChild(
                            "HumanoidRootPart"
                        )
                        and lp.Character.HumanoidRootPart.Position

                    if myPos then

                        for _, v in pairs(
                            game:GetService("Players"):GetPlayers()
                        ) do

                            if v ~= lp
                                and v.Character
                                and v.Character:FindFirstChild(
                                    "HumanoidRootPart"
                                ) then

                                if not v.Character:GetAttribute(
                                    "IsKiller"
                                ) then

                                    local dst =
                                        (
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
                            closest.Character
                            .HumanoidRootPart.Position

                        -- args[1] = LookVector
                        -- args[2] = OriginPosition

                        if args[2]
                            and typeof(args[2]) == "Vector3" then

                            args[1] =
                                (targetPos - args[2]).Unit
                        end

                        -- Keep the original method
                        setnamecallmethod(method)

                        return _genv.KYS_oldNamecall(
                            self,
                            unpack(args)
                        )
                    end
                end
            end

            -- =============================================
            -- ORIGINAL NAMECALL
            -- =============================================

            if _genv.KYS_oldNamecall then

                return _genv.KYS_oldNamecall(
                    self,
                    ...
                )

            end
        end)
end

-- =========================================================
-- FLUENT UI
-- =========================================================

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

local FlaskSection =
    Tabs.Main:AddSection("Silent Aim Flask (Cure)")

-- =========================================================
-- SILENT AIM TOGGLE
-- =========================================================

Tabs.Main:AddToggle("FlaskSilentAim", {

    Title = "Silent Aim Flask (Cure)",

    Default = VD.KILLER_SilentAimFlask,

    Callback = function(v)

        VD.KILLER_SilentAimFlask = v

    end
})

-- =========================================================
-- LASER TOGGLE
-- =========================================================

Tabs.Main:AddToggle("FlaskLaser", {

    Title = "Flask Laser (Cure)",

    Default = VD.KILLER_FlaskLaser,

    Callback = function(v)

        VD.KILLER_FlaskLaser = v

        if v then

            pcall(KYS_StartCureFlaskLaser)

        else

            if getgenv().KYS_CureFlaskLaserThread then

                getgenv().KYS_CureFlaskLaserThread:Disconnect()
                getgenv().KYS_CureFlaskLaserThread = nil

            end

            if getgenv().KYS_CureFlaskLaserPart then

                pcall(function()
                    getgenv().KYS_CureFlaskLaserPart:Destroy()
                end)

                getgenv().KYS_CureFlaskLaserPart = nil

            end
        end
    end
})

-- =========================================================
-- INITIALIZE LASER IF ENABLED
-- =========================================================

if VD.KILLER_FlaskLaser then
    pcall(KYS_StartCureFlaskLaser)
end

Window:SelectTab(1)
