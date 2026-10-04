local _genv = getgenv()

_genv.VD = _genv.VD or {}
local VD = _genv.VD

VD.KILLER_SilentAimFlask =
    VD.KILLER_SilentAimFlask or false

VD.KILLER_FlaskLaser =
    VD.KILLER_FlaskLaser or false

_genv.CureFlaskLaserThread = nil
_genv.CureFlaskLaserPart = nil

function UpdateCureFlaskLaser()

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

    local actionActive = false

    for _, child in pairs(char:GetChildren()) do

        if child:IsA("LocalScript")
            and child:GetAttribute("action") == true then

            actionActive = true
            break
        end
    end

    if originPos and targetPos and actionActive then

        if not _genv.CureFlaskLaserPart then

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

            _genv.CureFlaskLaserPart = laser
        end

        local dist =
            (targetPos - originPos).Magnitude

        if dist > 0.1 then

            local laser =
                _genv.CureFlaskLaserPart

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

        if _genv.CureFlaskLaserPart then
            _genv.CureFlaskLaserPart.Transparency = 1
        end
    end
end

function StartCureFlaskLaser()

    if _genv.CureFlaskLaserThread then
        return
    end

    _genv.CureFlaskLaserThread =
        RunService.RenderStepped:Connect(function()

            if not VD.KILLER_FlaskLaser then

                if _genv.CureFlaskLaserPart then

                    pcall(function()
                        _genv.CureFlaskLaserPart:Destroy()
                    end)

                    _genv.CureFlaskLaserPart = nil
                end

                if _genv.CureFlaskLaserThread then

                    _genv.CureFlaskLaserThread:Disconnect()
                    _genv.CureFlaskLaserThread = nil

                end

                return
            end

            pcall(UpdateCureFlaskLaser)
        end)
end

local function InstallFlaskHook()

    if _genv.FlaskStandaloneHook then
        return
    end

    if _genv.oldNamecall then
        _genv.FlaskStandaloneHook = true
        return
    end

    _genv.FlaskStandaloneHook = true

    _genv.oldNamecall =
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

                        if args[2]
                            and typeof(args[2]) == "Vector3" then

                            args[1] =
                                (targetPos - args[2]).Unit
                        end

                        setnamecallmethod(method)

                        return _genv.oldNamecall(
                            self,
                            unpack(args)
                        )
                    end
                end
            end

            if _genv.oldNamecall then
                return _genv.oldNamecall(
                    self,
                    ...
                )
            end
        end)
end

InstallFlaskHook()


local FlaskSection = Tabs.Main:AddSection("Silent Aim Flask")

Tabs.Main:AddToggle("FlaskSilentAim",{
        Title = "Silent Aim Flask (Cure)",
        Default = VD.KILLER_SilentAimFlask,
        Callback = function(value)
        VD.KILLER_SilentAimFlask = value
end
    }
)


Tabs.Main:AddToggle("FlaskLaser",{
        Title = "Flask Laser (Cure)",
        Default =
        VD.KILLER_FlaskLaser,
        Callback = function(value)
        VD.KILLER_FlaskLaser = value if value then
        pcall(StartCureFlaskLaser)
            else
                if _genv.CureFlaskLaserThread then
                    _genv.CureFlaskLaserThread:Disconnect()
                    _genv.CureFlaskLaserThread = nil
                end

                if _genv.CureFlaskLaserPart then
                    pcall(function()
                        _genv.CureFlaskLaserPart:Destroy()
                    end)

                    _genv.CureFlaskLaserPart = nil
                end
            end
        end
    }
)

if VD.KILLER_FlaskLaser then
    pcall(StartCureFlaskLaser)
end
