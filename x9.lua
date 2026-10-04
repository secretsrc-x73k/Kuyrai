local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local _genv = getgenv()

-- =========================================================
-- VD FLAGS
-- =========================================================

_genv.VD = _genv.VD or {}
local VD = _genv.VD

VD.KILLER_SilentAimFlask =
    VD.KILLER_SilentAimFlask or false

VD.KILLER_FlaskLaser =
    VD.KILLER_FlaskLaser or false

-- =========================================================
-- FLASK LASER STATE
-- =========================================================

_genv.KYS_CureFlaskLaserThread = nil
_genv.KYS_CureFlaskLaserPart = nil

-- =========================================================
-- FLASK LASER UPDATE
-- =========================================================

function KYS_UpdateCureFlaskLaser()

    local char = Players.LocalPlayer.Character

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

        for _, v in pairs(Players:GetPlayers()) do

            if v ~= Players.LocalPlayer
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

    -- Original source:
    -- action == true means flask is being held/charged
    local actionActive = false

    for _, child in pairs(char:GetChildren()) do

        if child:IsA("LocalScript")
            and child:GetAttribute("action") == true then

            actionActive = true
            break
        end
    end

    if originPos and targetPos and actionActive then

        if not _genv.KYS_CureFlaskLaserPart then

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

            _genv.KYS_CureFlaskLaserPart = laser
        end

        local dist =
            (targetPos - originPos).Magnitude

        if dist > 0.1 then

            local laser =
                _genv.KYS_CureFlaskLaserPart

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

        if _genv.KYS_CureFlaskLaserPart then
            _genv.KYS_CureFlaskLaserPart.Transparency = 1
        end
    end
end

-- =========================================================
-- START FLASK LASER
-- =========================================================

function KYS_StartCureFlaskLaser()

    if _genv.KYS_CureFlaskLaserThread then
        return
    end

    _genv.KYS_CureFlaskLaserThread =
        RunService.RenderStepped:Connect(function()

            if not VD.KILLER_FlaskLaser then

                if _genv.KYS_CureFlaskLaserPart then

                    pcall(function()
                        _genv.KYS_CureFlaskLaserPart:Destroy()
                    end)

                    _genv.KYS_CureFlaskLaserPart = nil
                end

                if _genv.KYS_CureFlaskLaserThread then

                    _genv.KYS_CureFlaskLaserThread:Disconnect()
                    _genv.KYS_CureFlaskLaserThread = nil

                end

                return
            end

            pcall(KYS_UpdateCureFlaskLaser)
        end)
end

-- =========================================================
-- SILENT AIM
--
-- IMPORTANT:
-- If the original REAPER source already installed
-- KYS_oldNamecall, DO NOT INSTALL ANOTHER HOOK.
-- =========================================================

local function InstallFlaskHook()

    if _genv.KYS_FlaskStandaloneHook then
        return
    end

    -- If Main.lua's centralized hook already exists,
    -- don't create a second __namecall hook.
    if _genv.KYS_oldNamecall then
        _genv.KYS_FlaskStandaloneHook = true
        return
    end

    _genv.KYS_FlaskStandaloneHook = true

    _genv.KYS_oldNamecall =
        hookmetamethod(game, "__namecall", function(self, ...)

            local method = getnamecallmethod()

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
                        Players.LocalPlayer

                    local myPos =
                        lp.Character
                        and lp.Character:FindFirstChild(
                            "HumanoidRootPart"
                        )
                        and lp.Character.HumanoidRootPart.Position

                    if myPos then

                        for _, v in pairs(
                            Players:GetPlayers()
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

                        -- EXACTLY like original source:
                        -- args[1] = LookVector
                        -- args[2] = OriginPosition

                        if args[2]
                            and typeof(args[2]) == "Vector3" then

                            args[1] =
                                (targetPos - args[2]).Unit
                        end

                        setnamecallmethod(method)

                        return _genv.KYS_oldNamecall(
                            self,
                            unpack(args)
                        )
                    end
                end
            end

            if _genv.KYS_oldNamecall then
                return _genv.KYS_oldNamecall(
                    self,
                    ...
                )
            end
        end)
end

InstallFlaskHook()

-- =========================================================
-- FLUENT UI
-- =========================================================

local Window = Fluent:CreateWindow({

    Title = "ReaperX | Silent Aim Flask",

    SubTitle = "Violence District (Mobile)",

    TabWidth = 160,

    Size = UDim2.fromOffset(
        450,
        320
    ),

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

Tabs.Main:AddToggle(
    "FlaskSilentAim",
    {
        Title = "Silent Aim Flask (Cure)",

        Default =
            VD.KILLER_SilentAimFlask,

        Callback = function(value)

            VD.KILLER_SilentAimFlask =
                value

        end
    }
)

-- =========================================================
-- LASER TOGGLE
-- =========================================================

Tabs.Main:AddToggle(
    "FlaskLaser",
    {
        Title = "Flask Laser (Cure)",

        Default =
            VD.KILLER_FlaskLaser,

        Callback = function(value)

            VD.KILLER_FlaskLaser =
                value

            if value then

                pcall(
                    KYS_StartCureFlaskLaser
                )

            else

                if _genv.KYS_CureFlaskLaserThread then

                    _genv.KYS_CureFlaskLaserThread:Disconnect()

                    _genv.KYS_CureFlaskLaserThread =
                        nil
                end

                if _genv.KYS_CureFlaskLaserPart then

                    pcall(function()

                        _genv.KYS_CureFlaskLaserPart:Destroy()

                    end)

                    _genv.KYS_CureFlaskLaserPart =
                        nil
                end
            end
        end
    }
)

-- =========================================================
-- INITIAL STATE
-- =========================================================

if VD.KILLER_FlaskLaser then
    pcall(KYS_StartCureFlaskLaser)
end

Window:SelectTab(1)
