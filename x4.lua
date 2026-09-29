-- This Project Create by REAPER
-- พ่อมึงตาย
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local VD = getgenv().VD or {}
getgenv().VD = VD

local function GetRole()
    if LocalPlayer.Team and LocalPlayer.Team.Name == "Killer" then
        return "Killer"
    end
    if LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors" then
        return "Survivor"
    end
    return "Survivor"
end

local function IsKiller(player)
    return player and player.Team and player.Team.Name == "Killer"
end

local function GetRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local Root = GetRoot()

LocalPlayer.CharacterAdded:Connect(function(character)
    Root = character:WaitForChild("HumanoidRootPart", 10)
end)

local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 330),
    Theme = "ExtremeReaper",
    MinimizeKey = Enum.KeyCode.RightControl
})

local function VD_Notify(title, content, duration)
    pcall(function()
        Fluent:Notify({
            Title = tostring(title or "REAPER HUB"),
            Content = tostring(content or ""),
            Duration = duration or 3
        })
    end)
end

VD.AimLockMaxDistance = VD.AimLockMaxDistance or 50
VD.KILLER_SilentAimFlask = VD.KILLER_SilentAimFlask or false
VD.TOF_SilentAim = VD.TOF_SilentAim or false
VD.TOF_TargetMode = VD.TOF_TargetMode or "Killer"
VD.TOF_WallCheck = VD.TOF_WallCheck ~= false
VD.TOF_BlockKnocked = VD.TOF_BlockKnocked ~= false
VD.TOF_Laser = VD.TOF_Laser or false
VD.FLASH_SilentAim = VD.FLASH_SilentAim or false
VD.FLASH_TargetPart = VD.FLASH_TargetPart or "Head"
VD.FLASH_Range = VD.FLASH_Range or 120
VD.FLASH_Smooth = VD.FLASH_Smooth or 0.35
VD.FLASH_Laser = VD.FLASH_Laser or false
VD.AIM_Enabled = VD.AIM_Enabled or false
VD.AIM_UseRMB = VD.AIM_UseRMB or false
VD.AIM_VisCheck = VD.AIM_VisCheck or false
VD.AIM_Predict = VD.AIM_Predict or false
VD.AIM_Smooth = VD.AIM_Smooth or 0.3

do
local VD_AimLockState = {
    Active = false,
    CurrentTarget = nil,
}

local function VD_AimLock_IsSurvivor(p)
    return p.Team and p.Team.Name == "Survivors"
end

local function VD_AimLock_IsDowned(character)
    if not character then return true end
    if character:GetAttribute("Knocked") == true then return true end
    if character:GetAttribute("IsHooked") == true then return true end
    local hum = character:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end

local function VD_AimLock_GetClosest()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local maxDist = VD.AimLockMaxDistance or 50
    local bestTarget = nil
    local bestDistance = maxDist + 1

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character and VD_AimLock_IsSurvivor(otherPlayer) then
            if not VD_AimLock_IsDowned(otherPlayer.Character) then
                local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")

                if otherHrp and otherHum and otherHum.Health > 0 then
                    local distance = (otherHrp.Position - hrp.Position).Magnitude
                    if distance <= maxDist and distance < bestDistance then
                        bestDistance = distance
                        bestTarget = otherHrp
                    end
                end
            end
        end
    end

    return bestTarget
end

local function VD_SetAimLockActive(state)
    VD_AimLockState.Active = state and true or false
    if not VD_AimLockState.Active then
        VD_AimLockState.CurrentTarget = nil
    end
end
getgenv().VD_SetAimLockActive = VD_SetAimLockActive

LocalPlayer.CharacterAdded:Connect(function()
    if VD_AimLockState.Active then
        VD_SetAimLockActive(false)
    end
    VD_AimLockState.CurrentTarget = nil
end)

RunService.RenderStepped:Connect(function()
    if not VD_AimLockState.Active then
        VD_AimLockState.CurrentTarget = nil
        return
    end

    local targetPart = VD_AimLock_GetClosest()
    if not targetPart then
        VD_AimLockState.CurrentTarget = nil
        return
    end

    VD_AimLockState.CurrentTarget = targetPart
    pcall(function()
        local cam = Workspace.CurrentCamera
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
    end)
end)
end

VeilConfig = {
    Enabled              = false,
    ShowFOV              = true,
    ShowTargetLaser      = true,
    FOV                  = 150,
    SpearSpeed           = 165,
    Gravity              = workspace.Gravity * 0.5,
    MaxDist              = 200,
    AutoPredict          = false,
    TargetPart           = "Torso",
    HorizontalPredictFactor = 1.0,
}

VeilState = {
    chargingSpear    = false,
    touchInput       = nil,
    attackCooldown   = false,
    passiveCooldown  = false,
    remoteHooked     = false,
    lastPredictedPos = nil,
}

VeilVelocityCache = {}

VeilDraw = {
    FOVCircle = Drawing.new("Circle"),
    Highlight = Instance.new("Highlight"),
    Tracer    = Drawing.new("Circle"),
}

VeilDraw.FOVCircle.Color     = Color3.fromRGB(255, 0, 255)
VeilDraw.FOVCircle.Thickness = 1.5
VeilDraw.FOVCircle.Filled    = false
VeilDraw.FOVCircle.Visible   = false

VeilDraw.Highlight.Name                = "VD_VeilTarget"
VeilDraw.Highlight.FillColor           = Color3.fromRGB(255, 0, 0)
VeilDraw.Highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
VeilDraw.Highlight.FillTransparency    = 0.5
VeilDraw.Highlight.OutlineTransparency = 0

VeilDraw.Tracer.Thickness = 2
VeilDraw.Tracer.Radius    = 5
VeilDraw.Tracer.Color     = Color3.fromRGB(255, 0, 255)
VeilDraw.Tracer.Filled    = true
VeilDraw.Tracer.Visible   = false

function Veil_GetRealVelocity(part, playerName)
    if not part then return Vector3.zero end
    local currentPos = part.Position
    local currentTime = tick()
    if not VeilVelocityCache[playerName] then
        VeilVelocityCache[playerName] = {lastPos = currentPos, lastTime = currentTime, velocity = Vector3.zero}
        return Vector3.zero
    end
    local cache = VeilVelocityCache[playerName]
    local dt = currentTime - cache.lastTime
    if dt > 0.01 then
        local rawVelocity = (currentPos - cache.lastPos) / dt
        if rawVelocity.Magnitude < 100 then
            cache.velocity = cache.velocity:Lerp(rawVelocity, 0.4)
        end
    end
    cache.lastPos = currentPos
    cache.lastTime = currentTime
    return cache.velocity
end

function veil_getTargetPart(char)
    if VeilConfig.TargetPart == "Head" then
        return char:FindFirstChild("Head")
    elseif VeilConfig.TargetPart == "Root" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
end

function veil_getClosestSurvivor()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local cam      = workspace.CurrentCamera
    local center   = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local bestDist = VeilConfig.FOV
    local bestTarget = nil

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
            local char = p.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local part = veil_getTargetPart(char)
            if hum and hum.Health > 0 and part then
                local dist3D = (part.Position - myRoot.Position).Magnitude
                if dist3D <= VeilConfig.MaxDist then
                    local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D < bestDist then
                            bestDist   = dist2D
                            bestTarget = { Player = p, Part = part }
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

function veil_setupInterceptor()
    if VeilState.remoteHooked then return end
    task.spawn(function()
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
                if not checkcaller() then
                    if string.lower(method) == "kick" then
                        return nil
                    end

                    if method == "GetAttribute" then
                        if args[1] == "LakeMist" and VD.KILLER_InfLakeMist then
                            local caller = getcallingscript()
                            if caller and caller.Name == "AwardLog" then return 0 end
                            return false
                        end
                        if args[1] == "Pursuit" and VD.KILLER_InfPursuit then
                            local caller = getcallingscript()
                            if caller and caller.Name == "AwardLog" then return 0 end
                            return false
                        end
                    end

                    if method == "GetAttributes" then
                        if VD.KILLER_InfLakeMist or VD.KILLER_InfPursuit then
                            local attrs = oldNamecall(self, ...)
                            if type(attrs) == "table" then
                                local caller = getcallingscript()
                                if caller and caller.Name == "AwardLog" then
                                    if VD.KILLER_InfLakeMist then attrs.LakeMist = 0 end
                                    if VD.KILLER_InfPursuit then attrs.Pursuit = 0 end
                                else
                                    if VD.KILLER_InfLakeMist then attrs.LakeMist = false end
                                    if VD.KILLER_InfPursuit then attrs.Pursuit = false end
                                end
                                return attrs
                            end
                        end
                    end

                    if method == "FireServer" then

                if VD.KILLER_SilentAimFlask and method == "FireServer" then
                    local ok, name = pcall(function() return self.Name end)
                    if ok and name == "ThrowFlask" then
                        local args = {...}
                        local closest = nil
                        local minDst = math.huge
                        local lp = game:GetService("Players").LocalPlayer
                        local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position

                        if myPos then
                            for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                    if not v.Character:GetAttribute("IsKiller") then
                                        local dst = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
                                        if dst < minDst then
                                            minDst = dst
                                            closest = v
                                        end
                                    end
                                end
                            end
                        end

                        if closest then
                            local targetPos = closest.Character.HumanoidRootPart.Position
                            if args[2] and typeof(args[2]) == "Vector3" then
                                args[1] = (targetPos - args[2]).Unit
                            end

                            setnamecallmethod(method)
                            return _genv.KYS_oldNamecall(self, unpack(args))
                        end
                    end
                        if self.Name == "Spearthrow" and VeilConfig.Enabled then
                            return nil
                        end

                        if VD.KILLER_InfLakeMist and self.Name == "LakeMist" then
                            local a1 = args[1]
                            if a1 == false then
                                return nil
                            elseif a1 == true then
                                task.delay(0.2, function()
                                    pcall(function()
                                        local c = game:GetService("Players").LocalPlayer.Character
                                        if c and c:GetAttribute("action") == true then
                                            c:SetAttribute("action", false)
                                        end
                                    end)
                                end)
                            end
                        end

                        if VD.KILLER_InfPursuit and self.Name == "Pursuit" then
                            local a1 = args[1]
                            if a1 == false then
                                return nil
                            elseif a1 == true then
                                task.delay(0.2, function()
                                    pcall(function()
                                        local c = game:GetService("Players").LocalPlayer.Character
                                        if c and c:GetAttribute("action") == true then
                                            c:SetAttribute("action", false)
                                        end
                                    end)
                                end)
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
            VeilState.remoteHooked = true
        end)
    end)
end
veil_setupInterceptor()

function veil_fire()
    if VeilState.attackCooldown then return end
    VeilState.attackCooldown = true
    task.delay(2, function() VeilState.attackCooldown = false end)

    local myChar    = LocalPlayer.Character
    local startPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
    if not startPart then return end

    local startPos   = startPart.Position
    local targetInfo = veil_getClosestSurvivor()
    local aimDir

    if targetInfo and targetInfo.Part then
        local targetPart = targetInfo.Part
        local targetPlayer = targetInfo.Player
        local targetPos = targetPart.Position

        local velocity = Veil_GetRealVelocity(targetPart, targetPlayer.Name)
        local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = horizontalVel.Magnitude

        local distance = (targetPos - startPos).Magnitude
        local timeToHit = distance / VeilConfig.SpearSpeed

        local horizontalPrediction = Vector3.zero
        if speed > 4 and VeilConfig.AutoPredict then
            local factor = VeilConfig.HorizontalPredictFactor
            horizontalPrediction = horizontalVel * timeToHit * factor
        end
        local predictedPos = targetPos + horizontalPrediction

        local autoGravity = math.max(0, distance - 8)
        local gravity = VeilConfig.AutoPredict and autoGravity or VeilConfig.Gravity
        local drop = 0.5 * gravity * (timeToHit ^ 2)
        local finalPos = predictedPos + Vector3.new(0, drop, 0)

        aimDir = (finalPos - startPos).Unit
        VeilState.lastPredictedPos = finalPos
    else
        aimDir = workspace.CurrentCamera.CFrame.LookVector
        VeilState.lastPredictedPos = nil
    end

    pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local killers = remotes:FindFirstChild("Killers")
            if killers then
                local veil = killers:FindFirstChild("Veil")
                if veil and veil:FindFirstChild("Spearthrow") then
                    veil.Spearthrow:FireServer(aimDir, VeilConfig.SpearSpeed, startPos)
                end
            end
        end
    end)

    VeilDraw.FOVCircle.Color = Color3.fromRGB(255, 0, 255)
    if not VeilState.passiveCooldown then
        VeilState.passiveCooldown = true
        task.delay(30, function()
            VeilDraw.FOVCircle.Color = Color3.fromRGB(255, 0, 255)
            VeilState.passiveCooldown = false
        end)
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    local char = LocalPlayer.Character
    local isSpearMode = char and char:GetAttribute("spearmode") == true
    if not VeilConfig.Enabled then return end
    if not isSpearMode then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        VeilState.chargingSpear = true
    elseif isTouch then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local slasher = pGui:FindFirstChild("Slasher-mob")
            if slasher then
                local ctrl = slasher:FindFirstChild("Controls")
                if ctrl then
                    local attackBtn = ctrl:FindFirstChild("attack")
                    if attackBtn and attackBtn.Visible then
                        local pos     = input.Position
                        local absPos  = attackBtn.AbsolutePosition
                        local absSize = attackBtn.AbsoluteSize
                        if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
                            VeilState.chargingSpear = true
                            VeilState.touchInput    = input
                        end
                    end
                end
            end
        end
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input, gp)
    if VeilState.chargingSpear
    and (input == VeilState.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
        VeilState.chargingSpear = false
        if VeilState.touchInput == input then VeilState.touchInput = nil end
        veil_fire()
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    local cam         = workspace.CurrentCamera
    local myChar      = LocalPlayer.Character
    local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true

    if VeilConfig.Enabled and VeilConfig.ShowFOV and isSpearMode then
        VeilDraw.FOVCircle.Visible  = true
        VeilDraw.FOVCircle.Radius   = VeilConfig.FOV
        VeilDraw.FOVCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    else
        VeilDraw.FOVCircle.Visible = false
    end

    if VeilState.chargingSpear and VeilConfig.Enabled and isSpearMode then
        local target = veil_getClosestSurvivor()
        if target and target.Part and target.Part.Parent then
            VeilDraw.Highlight.Parent = target.Part.Parent

            if VeilConfig.ShowTargetLaser then
                if not getgenv().KYS_SpearLaserPart then
                    local laser = Instance.new("Part")
                    laser.Name = "SpearSilentAimLaser"
                    laser.Anchored = true
                    laser.CanCollide = false
                    laser.CanTouch = false
                    laser.CastShadow = false
                    laser.Material = Enum.Material.Neon
                    laser.Color = Color3.fromRGB(255, 50, 50)
                    laser.Transparency = 0
                    laser.Parent = workspace
                    getgenv().KYS_SpearLaserPart = laser
                end

                local originPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
                if originPart then
                    local originPos = originPart.Position
                    local targetPos = target.Part.Position
                    local dist = (targetPos - originPos).Magnitude
                    if dist > 0.1 then
                        local laser = getgenv().KYS_SpearLaserPart
                        laser.Size = Vector3.new(0.16, 0.16, dist)
                        laser.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
                        laser.Transparency = 0.5
                    end
                end
            else
                if getgenv().KYS_SpearLaserPart then getgenv().KYS_SpearLaserPart.Transparency = 1 end
            end
        else
            VeilDraw.Highlight.Parent = nil
            if getgenv().KYS_SpearLaserPart then getgenv().KYS_SpearLaserPart.Transparency = 1 end
        end
    else
        VeilDraw.Highlight.Parent = nil
        if getgenv().KYS_SpearLaserPart then getgenv().KYS_SpearLaserPart.Transparency = 1 end
    end

    if VeilConfig.Enabled and isSpearMode and VeilState.lastPredictedPos then
        local screenPos, onScreen = cam:WorldToViewportPoint(VeilState.lastPredictedPos)
        local viewport = cam.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

        if onScreen then
            VeilDraw.Tracer.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            local dx = screenPos.X - center.X
            local dy = screenPos.Y - center.Y
            if math.abs(dx) < 1 and math.abs(dy) < 1 then
                VeilDraw.Tracer.Position = center
            else
                local angle = math.atan2(dy, dx)
                local maxX = viewport.X / 2 - 10
                local maxY = viewport.Y / 2 - 10
                local scaleX = maxX / math.abs(dx)
                local scaleY = maxY / math.abs(dy)
                local scale = math.min(scaleX, scaleY)
                local borderPos = Vector2.new(
                    center.X + dx * scale,
                    center.Y + dy * scale
                )
                VeilDraw.Tracer.Position = borderPos
            end
        end
        VeilDraw.Tracer.Visible = true
    else
        VeilDraw.Tracer.Visible = false
    end
end)

(function()
local KYS_ToFState = {
    Connection = nil,
    LaserBeam = nil,
    TargetGui = nil,
    InputBegan = nil,
    InputEnded = nil,
    TouchInput = nil,
    IsAiming = false,
    SavedUIPos = UDim2.new(0.5, -120, 0, 110),
    SCPCache = {},
    SCPCacheTimer = 0,
}

local function KYS_ToFGetEvent()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local tof = items and items:FindFirstChild("Twist of Fate")
    local fire = tof and tof:FindFirstChild("Fire")
    if fire and fire:IsA("RemoteEvent") then
        return fire
    end
    return nil
end

local function KYS_ToFGetGunObject()
    local char = LocalPlayer.Character
    if not char then return nil end

    local baseToF = char:FindFirstChild("Twist of Fate", true)
    if not baseToF then return nil end

    local rightArm = baseToF:FindFirstChild("Right Arm")
    if rightArm then
        local gunPart = rightArm:FindFirstChild("gun")
        if gunPart then return gunPart end

        local emperorGun = rightArm:FindFirstChild("EmperorGun")
        if emperorGun then return emperorGun end
    end

    return baseToF
end

local function KYS_ToFIsTargetVisible(originPos, targetPos, targetCharacter)
    local direction = targetPos - originPos
    local distance = direction.Magnitude
    if distance < 0.1 then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local excludeList = {}
    local localChar = LocalPlayer.Character
    if localChar then table.insert(excludeList, localChar) end
    if targetCharacter and targetCharacter ~= localChar then table.insert(excludeList, targetCharacter) end
    if KYS_ToFState.LaserBeam then table.insert(excludeList, KYS_ToFState.LaserBeam) end

    rayParams.FilterDescendantsInstances = excludeList

    local result = workspace:Raycast(originPos, direction.Unit * distance, rayParams)
    return result == nil
end

local function KYS_ToFGetSCPs()
    if tick() - KYS_ToFState.SCPCacheTimer < 0.5 then
        return KYS_ToFState.SCPCache
    end

    local newTargets = {}
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        for _, container in pairs(mapFolder:GetDescendants()) do
            if container:IsA("Model") then
                local attributes = container:GetAttributes()
                if container:GetAttribute("CorpseCreated0492") or next(attributes) ~= nil then
                    local root = container:FindFirstChild("HumanoidRootPart")
                    if root then table.insert(newTargets, root) end
                end
            end
        end
    end

    KYS_ToFState.SCPCache = newTargets
    KYS_ToFState.SCPCacheTimer = tick()
    return KYS_ToFState.SCPCache
end

local function KYS_ToFGetTargetPosition()
    local gunObj = KYS_ToFGetGunObject()
    local char = LocalPlayer.Character
    if not (gunObj and char) then return nil, nil, nil, nil end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil, nil end

    local myPos = hrp.Position
    local originPos
    if char:GetAttribute("IsCarried") then
        originPos = hrp.Position + (hrp.CFrame.LookVector * 2)
    else
        pcall(function()
            originPos = gunObj:IsA("BasePart") and gunObj.Position
                or (gunObj:FindFirstChildOfClass("BasePart") and gunObj:FindFirstChildOfClass("BasePart").Position)
        end)
        originPos = originPos or Vector3.new(myPos.X, myPos.Y + 1.5, myPos.Z)
    end

    local function predictTarget(torso, targetCharacter)
        local targetPos = torso.Position
        if VD.TOF_WallCheck and not KYS_ToFIsTargetVisible(originPos, targetPos, targetCharacter) then
            return nil, nil, nil, nil
        end

        local targetVel = Vector3.new(0, 0, 0)
        local rootPart = targetCharacter and (targetCharacter:FindFirstChild("HumanoidRootPart") or torso)
        if rootPart then targetVel = rootPart.Velocity end

        local directionRaw = targetPos - originPos
        local distance = directionRaw.Magnitude
        if distance < 0.1 then return nil, nil, nil, nil end
        if distance < 5 then return directionRaw.Unit, gunObj, originPos, targetPos end

        local travelTime = distance / 400
        local predictedPos = targetPos + (targetVel * travelTime)
        for _ = 1, 2 do
            local newDist = (predictedPos - originPos).Magnitude
            travelTime = newDist / 400
            predictedPos = targetPos + (targetVel * travelTime)
        end

        local finalDirection = predictedPos - originPos
        if finalDirection.Magnitude < 0.1 then return nil, nil, nil, nil end

        return finalDirection.Unit, gunObj, originPos, predictedPos
    end

    local targetMode = VD.TOF_TargetMode or "Killer"
    if targetMode == "Killer" then
        local closestTorso, closestChar, shortestDist = nil, nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team and player.Team.Name == "Killer" and player.Character then
                local torso = player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                if torso then
                    local dist = (myPos - torso.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestTorso = torso
                        closestChar = player.Character
                    end
                end
            end
        end
        if not closestTorso then return nil, nil, nil, nil end
        return predictTarget(closestTorso, closestChar)
    elseif targetMode == "Survivors" then
        local bestTorso, bestChar, bestDot = nil, nil, -math.huge
        local cam = workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
                local torso = player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                if torso then
                    local dirToTarget = torso.Position - cam.CFrame.Position
                    if dirToTarget.Magnitude > 0.1 then
                        local dot = camLook:Dot(dirToTarget.Unit)
                        if dot > 0.5 and dot > bestDot then
                            bestDot = dot
                            bestTorso = torso
                            bestChar = player.Character
                        end
                    end
                end
            end
        end
        if not bestTorso then return nil, nil, nil, nil end
        return predictTarget(bestTorso, bestChar)
    elseif targetMode == "Zombie" then
        local bestPart, bestDot = nil, -math.huge
        local cam = workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector

        for _, root in ipairs(KYS_ToFGetSCPs()) do
            if root and root.Parent then
                local dirToTarget = root.Position - cam.CFrame.Position
                if dirToTarget.Magnitude > 0.1 then
                    local dot = camLook:Dot(dirToTarget.Unit)
                    if dot > 0.5 and dot > bestDot then
                        bestDot = dot
                        bestPart = root
                    end
                end
            end
        end
        if not bestPart then return nil, nil, nil, nil end
        return predictTarget(bestPart, bestPart.Parent)
    end

    return nil, nil, nil, nil
end

local function KYS_ToFUpdateLaser(originPos, targetPos)
    if not KYS_ToFState.LaserBeam then
        local laser = Instance.new("Part")
        laser.Name = "ToFLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(255, 50, 50)
        laser.Parent = workspace
        KYS_ToFState.LaserBeam = laser
    end

    local dist = (targetPos - originPos).Magnitude
    KYS_ToFState.LaserBeam.Size = Vector3.new(0.05, 0.05, dist)
    KYS_ToFState.LaserBeam.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
    KYS_ToFState.LaserBeam.Transparency = 0
end

local function KYS_ToFClearLaser()
    if KYS_ToFState.LaserBeam then
        pcall(function() KYS_ToFState.LaserBeam:Destroy() end)
        KYS_ToFState.LaserBeam = nil
    end
end

local AimConfig = {
    Pistol_BlockKnocked = true,
}

local function IsDowned(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    local state = char:GetAttribute("State")
    return state == "Downed" or state == "Dead"
end

local function KYS_ToFGetMobileShootButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local survivorMob = playerGui and playerGui:FindFirstChild("Survivor-mob")
    local controls = survivorMob and survivorMob:FindFirstChild("Controls")
    local guiMob = controls and controls:FindFirstChild("Gui-mob")
    if not guiMob then return nil end

    local directNames = { "attack", "Attack", "shoot", "Shoot", "fire", "Fire" }
    for _, name in ipairs(directNames) do
        local btn = guiMob:FindFirstChild(name, true)
        if btn and btn:IsA("GuiObject") then return btn end
    end

    for _, obj in ipairs(guiMob:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible then
            return obj
        end
    end

    return guiMob:IsA("GuiObject") and guiMob or nil
end

local function KYS_ToFIsTouchOnShootButton(input)
    local shootButton = KYS_ToFGetMobileShootButton()
    if not (shootButton and shootButton.Visible) then return false end

    local pos = input.Position
    local absPos = shootButton.AbsolutePosition
    local absSize = shootButton.AbsoluteSize

    return pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
end

local function KYS_ToFDoShoot()
    if not VD.TOF_SilentAim then return end

    AimConfig.Pistol_BlockKnocked = VD.TOF_BlockKnocked ~= false
    local char = LocalPlayer.Character
    if char then
        if AimConfig.Pistol_BlockKnocked and IsDowned(char) then
            return
        end
    end

    local targetDirection, gunObject, originPos, targetPos = KYS_ToFGetTargetPosition()
    if not (targetDirection and gunObject and targetPos and originPos) then return end

    local tofEvent = KYS_ToFGetEvent()
    if not tofEvent then return end

    local freshDirection = targetPos - originPos
    if freshDirection.Magnitude < 0.1 then return end

    pcall(function()
        tofEvent:FireServer(gunObject, freshDirection.Unit)
    end)
end

local function KYS_ToFSetTargetMode(modeName, notify)
    if modeName ~= "Killer" and modeName ~= "Survivors" and modeName ~= "Zombie" then return end
    VD.TOF_TargetMode = modeName
    if notify then VD_Notify("Target Mode", modeName, 1) end
end

local function KYS_ToFStartConnection()
    if KYS_ToFState.Connection then return end
    KYS_ToFState.Connection = RunService.Heartbeat:Connect(function()
        if not VD.TOF_SilentAim or not KYS_ToFState.IsAiming then
            if KYS_ToFState.LaserBeam then KYS_ToFState.LaserBeam.Transparency = 1 end
            return
        end

        local _, _, originPos, targetPos = KYS_ToFGetTargetPosition()
        if originPos and targetPos then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and not char:GetAttribute("IsCarried") then
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                end
            end)

            if VD.TOF_Laser then
                KYS_ToFUpdateLaser(originPos, targetPos)
            elseif KYS_ToFState.LaserBeam then
                KYS_ToFState.LaserBeam.Transparency = 1
            end
        elseif KYS_ToFState.LaserBeam then
            KYS_ToFState.LaserBeam.Transparency = 1
        end
    end)
end

local function KYS_ToFStopConnection()
    if KYS_ToFState.Connection then
        pcall(function() KYS_ToFState.Connection:Disconnect() end)
        KYS_ToFState.Connection = nil
    end
    KYS_ToFState.IsAiming = false
    KYS_ToFClearLaser()
end

local function KYS_ToFDisconnectInputs()
    if KYS_ToFState.InputBegan then pcall(function() KYS_ToFState.InputBegan:Disconnect() end) end
    if KYS_ToFState.InputEnded then pcall(function() KYS_ToFState.InputEnded:Disconnect() end) end
    KYS_ToFState.InputBegan = nil
    KYS_ToFState.InputEnded = nil
end

local KYS_SetToFSilentAim

local function KYS_ToFEnsureInputs()
    if not KYS_ToFState.InputBegan then
        KYS_ToFState.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not VD.TOF_SilentAim then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or (input.UserInputType == Enum.UserInputType.Touch and KYS_ToFIsTouchOnShootButton(input)) then
                KYS_ToFState.IsAiming = true
                if input.UserInputType == Enum.UserInputType.Touch then
                    KYS_ToFState.TouchInput = input
                end
                KYS_ToFDoShoot()
            end
        end)
    end
    if not KYS_ToFState.InputEnded then
        KYS_ToFState.InputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or (input.UserInputType == Enum.UserInputType.Touch and input == KYS_ToFState.TouchInput) then
                KYS_ToFState.IsAiming = false
                if input == KYS_ToFState.TouchInput then KYS_ToFState.TouchInput = nil end
                if KYS_ToFState.LaserBeam then KYS_ToFState.LaserBeam.Transparency = 1 end
            end
        end)
    end
end

KYS_SetToFSilentAim = function(enabled)
    VD.TOF_SilentAim = enabled and true or false
    KYS_ToFEnsureInputs()
    if VD.TOF_SilentAim then
        KYS_ToFStartConnection()
    else
        KYS_ToFStopConnection()
    end
end

KYS_ToFEnsureInputs()
getgenv().KYS_SetToFSilentAim = KYS_SetToFSilentAim
getgenv().KYS_ToFClearLaser = KYS_ToFClearLaser
getgenv().KYS_ToFSetTargetMode = KYS_ToFSetTargetMode
end)();

(function()
local KYS_FlashlightAimState = {
    Connection = nil,
    LaserBeam = nil,
    FlashlightPart = nil,
    Active = false,
}

local function KYS_GetFlashlightActivateRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local flashlight = items and items:FindFirstChild("Flashlight")
    local activate = flashlight and flashlight:FindFirstChild("Activate")
    if activate and activate:IsA("RemoteEvent") then
        return activate
    end
    return nil
end

local function KYS_GetFlashlightTargetPart(char)
    if not char then return nil end
    local preferred = VD.FLASH_TargetPart or "Head"
    local part = char:FindFirstChild(preferred)
    if part and part:IsA("BasePart") then return part end
    return char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
end

local function KYS_IsAliveCharacter(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local state = char:GetAttribute("State")
    return state ~= "Dead"
end

local function KYS_GetFlashlightTarget()
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    local maxRange = tonumber(VD.FLASH_Range) or 120
    local bestPart, bestScore = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and KYS_IsAliveCharacter(player.Character) then
            local isKiller = player.Team and player.Team.Name == "Killer"
            if isKiller then
                local part = KYS_GetFlashlightTargetPart(player.Character)
                if part then
                    local dist = (localRoot.Position - part.Position).Magnitude
                    if dist <= maxRange and dist < bestScore then
                        bestScore = dist
                        bestPart = part
                    end
                end
            end
        end
    end

    return bestPart
end

local function KYS_ClearFlashlightLaser()
    if KYS_FlashlightAimState.LaserBeam then
        pcall(function() KYS_FlashlightAimState.LaserBeam:Destroy() end)
        KYS_FlashlightAimState.LaserBeam = nil
    end
end

local function KYS_GetFlashlightOrigin(cam)
    local source = KYS_FlashlightAimState.FlashlightPart
    if typeof and typeof(source) == "Instance" then
        if source:IsA("BasePart") then
            return source.Position
        end
        local part = source:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.Position
        end
    end

    local char = LocalPlayer.Character
    local hand = char and (
        char:FindFirstChild("RightHand")
        or char:FindFirstChild("Right Arm")
        or char:FindFirstChild("HumanoidRootPart")
    )
    if hand and hand:IsA("BasePart") then
        return hand.Position
    end

    return cam and cam.CFrame.Position or nil
end

local function KYS_UpdateFlashlightLaser(originPos, targetPos)
    if not KYS_FlashlightAimState.LaserBeam then
        local laser = Instance.new("Part")
        laser.Name = "FlashlightSilentAimLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(80, 220, 255)
        laser.Transparency = 0
        laser.Parent = workspace
        KYS_FlashlightAimState.LaserBeam = laser
    end

    local dist = (targetPos - originPos).Magnitude
    if dist < 0.1 then return end

    local laser = KYS_FlashlightAimState.LaserBeam
    laser.Size = Vector3.new(0.16, 0.16, dist)
    laser.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
    laser.Transparency = 0
end

local function KYS_FlashlightAimStep()
    if false then
        if KYS_FlashlightAimState.LaserBeam then
            KYS_FlashlightAimState.LaserBeam.Transparency = 1
        end
        return
    end

    if not (VD.FLASH_SilentAim and KYS_FlashlightAimState.Active) then
        if KYS_FlashlightAimState.LaserBeam then
            KYS_FlashlightAimState.LaserBeam.Transparency = 1
        end
        return
    end

    local cam = workspace.CurrentCamera
    local targetPart = KYS_GetFlashlightTarget()
    if not (cam and targetPart) then
        if KYS_FlashlightAimState.LaserBeam then
            KYS_FlashlightAimState.LaserBeam.Transparency = 1
        end
        return
    end

    local targetPos = targetPart.Position
    local smooth = math.clamp(tonumber(VD.FLASH_Smooth) or 0.35, 0.05, 1)
    local originPos = KYS_GetFlashlightOrigin(cam)

    if VD.FLASH_Laser and originPos then
        KYS_UpdateFlashlightLaser(originPos, targetPos)
    elseif KYS_FlashlightAimState.LaserBeam then
        KYS_FlashlightAimState.LaserBeam.Transparency = 1
    end

    pcall(function()
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), smooth)
    end)

    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
        end
    end)
end

local function KYS_StartFlashlightSilentAim()
    getgenv().KYS_FlashlightActivateRemote = KYS_GetFlashlightActivateRemote()
    if KYS_FlashlightAimState.Connection then return end
    KYS_FlashlightAimState.Connection = RunService.RenderStepped:Connect(KYS_FlashlightAimStep)
end

local function KYS_StopFlashlightSilentAim()
    KYS_FlashlightAimState.Active = false
    KYS_FlashlightAimState.FlashlightPart = nil
    KYS_ClearFlashlightLaser()
    if KYS_FlashlightAimState.Connection then
        pcall(function() KYS_FlashlightAimState.Connection:Disconnect() end)
        KYS_FlashlightAimState.Connection = nil
    end
end

local function KYS_SetFlashlightSilentAim(enabled)
    if enabled and false then
        VD.FLASH_SilentAim = false
        KYS_StopFlashlightSilentAim()
        return
    end

    VD.FLASH_SilentAim = enabled and true or false
    if VD.FLASH_SilentAim then
        KYS_StartFlashlightSilentAim()
    else
        KYS_StopFlashlightSilentAim()
    end
end

getgenv().KYS_SetFlashlightSilentAim = KYS_SetFlashlightSilentAim
getgenv().KYS_ClearFlashlightLaser = KYS_ClearFlashlightLaser
getgenv().KYS_SetFlashlightAimActive = function(active, flashlightPart)
    KYS_FlashlightAimState.Active = active and true or false
    if KYS_FlashlightAimState.Active and flashlightPart then
        KYS_FlashlightAimState.FlashlightPart = flashlightPart
    elseif not KYS_FlashlightAimState.Active then
        KYS_FlashlightAimState.FlashlightPart = nil
    end
    if not KYS_FlashlightAimState.Active and KYS_FlashlightAimState.LaserBeam then
        KYS_FlashlightAimState.LaserBeam.Transparency = 1
    end
end
            
getgenv().KYS_FlashlightActivateRemote = KYS_GetFlashlightActivateRemote()

local Aimbot = {}
local State  = { AimTarget = nil, AimHolding = false }

function Aimbot.GetClosestTarget(cam)
    if not cam then return nil end
    if GetRole() ~= "Survivor" then return nil end

    local root = Root
    if not root then return nil end

    local closestPlayer = nil
    local closestDist   = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsKiller(player) and player.Character then
            local tr = player.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local dist = (tr.Position - root.Position).Magnitude

                local passVis = true
                if VD.AIM_VisCheck then
                    local camPos = cam.CFrame.Position
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Blacklist
                    params.FilterDescendantsInstances = { cam, LocalPlayer.Character, player.Character }
                    local ray = workspace:Raycast(camPos, tr.Position - camPos, params)
                    passVis = (ray == nil)
                end

                if passVis and dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

function Aimbot.GetPredictedPosition(target, targetPart)
    if not target or not targetPart then return nil end
    local pos = targetPart.Position
    if VD.AIM_Predict then
        local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if root then pos = pos + root.AssemblyLinearVelocity * 0.1 end
    end
    return pos
end

function Aimbot.AimAt(cam, targetPos)
    if not cam or not targetPos then return end
    local cur    = cam.CFrame
    local smooth = VD.AIM_Smooth or 0.3
    cam.CFrame   = cur:Lerp(CFrame.new(cur.Position, targetPos), smooth)
end

function Aimbot.Update(cam, screenSize, screenCenter)
    if not VD.AIM_Enabled or GetRole() ~= "Survivor" then
        State.AimTarget = nil; return
    end
    if VD.AIM_UseRMB and not State.AimHolding then
        State.AimTarget = nil; return
    end
    local target = Aimbot.GetClosestTarget(cam)
    State.AimTarget = target
    if target and target.Character then
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            local pred = Aimbot.GetPredictedPosition(target, tr)
            if pred then Aimbot.AimAt(cam, pred) end
        end
    end
end

local KillerTab = Window:AddTab({Title = "Killer", Icon = "target"})
            
local KillerAimLockSection = KillerTab:AddSection("Aim Lock")
KillerAimLockSection:AddToggle("Killer_AimLock", {
    Title = "Aim Lock",
    Description = "Lock camera onto the closest alive Survivor.",
    Default = VD_AimLockState.Active,
    Callback = function(value)
        VD_SetAimLockActive(value)
    end,
})
KillerAimLockSection:AddInput("Killer_AimLockDistance", {
    Title = "Max Distance",
    Description = "Maximum Aim Lock target distance.",
    Default = tostring(VD.AimLockMaxDistance),
    Placeholder = "50",
    Callback = function(value)
        local n = tonumber(value)
        if n then VD.AimLockMaxDistance = math.max(1, n) end
    end,
})

local VeilSection = KillerTab:AddSection("Veil Spear")
VeilSection:AddToggle("Killer_VeilEnabled", {
Title="Veil Silent Aim",
Description="Enable Veil spear target selection and silent fire.", 
Default=VeilConfig.Enabled, Callback=function(v) VeilConfig.Enabled=v end})
            
VeilSection:AddToggle("Killer_VeilFOV", {
Title="Show FOV", 
Description="Show the Veil FOV circle.", 
Default=VeilConfig.ShowFOV, 
Callback=function(v) VeilConfig.ShowFOV=v end})
            
VeilSection:AddToggle("Killer_VeilLaser", {
Title="Show Target Laser", 
Description="Show the target laser while charging.", 
Default=VeilConfig.ShowTargetLaser, 
Callback=function(v) VeilConfig.ShowTargetLaser=v end})
            
VeilSection:AddToggle("Killer_VeilPredict", {
Title="Auto Prediction", 
Description="Enable horizontal prediction and automatic gravity calculation.", 
Default=VeilConfig.AutoPredict, 
Callback=function(v) VeilConfig.AutoPredict=v end})
            
VeilSection:AddDropdown("Killer_VeilTargetPart", {
Title="Target Part", 
Description="Part used by Veil target selection.", 
Values={"Torso","Head","Root"}, 
Multi=false, 
Default=VeilConfig.TargetPart, Callback=function(v) VeilConfig.TargetPart=type(v)=="table" and v[1] or v end})
            
VeilSection:AddInput("Killer_VeilFOV", {
Title="FOV", 
Description="Screen-space target radius.", 
Default=tostring(VeilConfig.FOV), 
Placeholder="150", 
Callback=function(v) local n=tonumber(v); if n then VeilConfig.FOV=math.max(1,n) end end})
            
VeilSection:AddInput("Killer_VeilSpeed", {
Title="Spear Speed", 
Description="Projectile speed used for prediction.", 
Default=tostring(VeilConfig.SpearSpeed), 
Placeholder="165", 
Callback=function(v) local n=tonumber(v); if n then VeilConfig.SpearSpeed=math.max(1,n) end end})
            
VeilSection:AddInput("Killer_VeilGravity", {
Title="Gravity", 
Description="Gravity when Auto Prediction is disabled.", 
Default=tostring(VeilConfig.Gravity), 
Placeholder="80", 
Callback=function(v) local n=tonumber(v); if n then VeilConfig.Gravity=n end end})
            
VeilSection:AddInput("Killer_VeilMaxDist", {
Title="Max Distance",
Description="Maximum 3D target distance.",
Default=tostring(VeilConfig.MaxDist), 
Placeholder="200", 
Callback=function(v) local n=tonumber(v); if n then VeilConfig.MaxDist=math.max(1,n) end end})
            
VeilSection:AddInput("Killer_VeilPredictFactor",{
Title="Horizontal Predict Factor", 
Description="Horizontal prediction multiplier.", 
Default=tostring(VeilConfig.HorizontalPredictFactor), 
Placeholder="1.0", Callback=function(v) local n=tonumber(v); if n then VeilConfig.HorizontalPredictFactor=n end end})

local FlaskSection = KillerTab:AddSection("Flask")
FlaskSection:AddToggle("Killer_FlaskSilentAim", {
Title="Flask Silent Aim", 
Description="Enable the original ThrowFlask target redirection.", 
Default=VD.KILLER_SilentAimFlask,
Callback=function(v) VD.KILLER_SilentAimFlask=v end})

local SurvivorTab = Window:AddTab({Title="Survivor", Icon="crosshair"})
local ToFSection = SurvivorTab:AddSection("Twist of Fate")
ToFSection:AddToggle("Survivor_ToFSilentAim", {
Title="Twist of Fate Silent Aim", 
Description="Enable the original Twist of Fate silent aim.", 
Default=VD.TOF_SilentAim, 
Callback=function(value) KYS_SetToFSilentAim(value) end})
            
ToFSection:AddDropdown("Survivor_ToFTargetMode", {
Title="Target Mode", 
Description="Killer,Survivors, or Zombie.", 
Values={"Killer","Survivors","Zombie"}, 
Multi=false,
Default=VD.TOF_TargetMode, 
Callback=function(value) value=type(value)=="table" and value[1] or value; KYS_ToFSetTargetMode(value,false) end})
            
ToFSection:AddToggle("Survivor_ToFWallCheck", {
Title="Wall Check", 
Description="Use the source visibility check.", 
Default=VD.TOF_WallCheck, Callback=function(value) VD.TOF_WallCheck=value end})
            
ToFSection:AddToggle("Survivor_ToFBlockKnocked", {
Title="Block Knocked", 
Description="Block downed/dead targets according to the source settings.", 
Default=VD.TOF_BlockKnocked, Callback=function(value) VD.TOF_BlockKnocked=value end})
            
ToFSection:AddToggle("Survivor_ToFLaser", {
Title="Laser", 
Description="Show the Twist of Fate target laser.", 
Default=VD.TOF_Laser, 
Callback=function(value) VD.TOF_Laser=value end})

local FlashlightSection = SurvivorTab:AddSection("Flashlight")
FlashlightSection:AddToggle("Survivor_FlashlightSilentAim", {
Title="Flashlight Silent Aim", 
Description="Enable the original flashlight silent aim.", 
Default=VD.FLASH_SilentAim, 
Callback=function(value) KYS_SetFlashlightSilentAim(value); getgenv().KYS_SetFlashlightAimActive(value) end})
        
FlashlightSection:AddDropdown("Survivor_FlashlightTargetPart", {
Title="Target Part", 
Description="Preferred target body part.", 
Values={"Head","UpperTorso","Torso","HumanoidRootPart"}, 
Multi=false, 
Default=VD.FLASH_TargetPart, 
Callback=function(value) VD.FLASH_TargetPart=type(value)=="table" and value[1] or value end})
            
FlashlightSection:AddInput("Survivor_FlashlightRange", {
Title="Range", 
Description="Maximum flashlight target range.", 
Default=tostring(VD.FLASH_Range), Placeholder="120", 
Callback=function(value) local number=tonumber(value); if number then VD.FLASH_Range=math.max(1,number) end end})
            
FlashlightSection:AddInput("Survivor_FlashlightSmooth", {
Title="Smooth", 
Description="Camera interpolation amount.", 
Default=tostring(VD.FLASH_Smooth), 
Placeholder="0.35", 
Callback=function(value) local number=tonumber(value); if number then VD.FLASH_Smooth=math.clamp(number,0.05,1) end end})
        
FlashlightSection:AddToggle("Survivor_FlashlightLaser", {
Title="Laser", 
Description="Show the flashlight target laser.", 
Default=VD.FLASH_Laser, 
Callback=function(value) VD.FLASH_Laser=value end})

local AimbotSection = SurvivorTab:AddSection("Camera Aimbot")
AimbotSection:AddToggle("Survivor_AimbotEnabled", {
Title="Camera Aimbot", 
Description="Enable the source camera-aim state.", 
Default=VD.AIM_Enabled, 
Callback=function(value) VD.AIM_Enabled=value end})

AimbotSection:AddToggle("Survivor_AimbotRMB", {
Title="Use RMB", 
Description="Only aim while the source AimHolding state is active.", 
Default=VD.AIM_UseRMB, 
Callback=function(value) VD.AIM_UseRMB=value end})

AimbotSection:AddToggle("Survivor_AimbotVisCheck", {
Title="Visibility Check", 
Description="Use the source raycast visibility check.", 
Default=VD.AIM_VisCheck, 
Callback=function(value) VD.AIM_VisCheck=value end})
            
AimbotSection:AddToggle("Survivor_AimbotPrediction", {
Title="Prediction", 
Description="Predict target position from AssemblyLinearVelocity.", 
Default=VD.AIM_Predict, 
Callback=function(value) VD.AIM_Predict=value end})
            
AimbotSection:AddInput("Survivor_AimbotSmooth", {
Title="Smooth", 
Description="Camera interpolation amount.", 
Default=tostring(VD.AIM_Smooth), 
Placeholder="0.3", 
Callback=function(value) local number=tonumber(value); if number then VD.AIM_Smooth=math.clamp(number,0.01,1) end end})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then State.AimHolding=true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then State.AimHolding=false end
end)
RunService.RenderStepped:Connect(function()
    Root = GetRoot()
    Aimbot.Update(workspace.CurrentCamera, workspace.CurrentCamera.ViewportSize, workspace.CurrentCamera.ViewportSize / 2)
end)

if game.CoreGui:FindFirstChild("ToggleUI") then
    game.CoreGui.ToggleUI:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ToggleUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = game.CoreGui

local border = Instance.new("Frame")
border.Parent = gui
border.Size = UDim2.new(0,0,0,0)
border.BackgroundColor3 = Color3.fromRGB(0,0,0)
border.ZIndex = 1
border.AnchorPoint = Vector2.new(0,0)

local borderCorner = Instance.new("UICorner")
borderCorner.CornerRadius = UDim.new(0,14)
borderCorner.Parent = border

local button = Instance.new("ImageButton")
button.Parent = gui
button.Size = UDim2.new(0,60,0,60)
button.Position = UDim2.new(0,60,0.2,0)
button.AnchorPoint = Vector2.new(0,0)
button.BackgroundTransparency = 1
button.ZIndex = 999999
button.AutoButtonColor = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = button

local imgOn = "rbxassetid://86279908104891"
local imgOff = "rbxassetid://86279908104891"
button.Image = imgOn
button.ScaleType = Enum.ScaleType.Fit

local function UpdateBorder()
    local offset = (border.Size.X.Offset - button.Size.X.Offset) / 2
    border.Position = UDim2.new(button.Position.X.Scale, button.Position.X.Offset - offset, button.Position.Y.Scale, button.Position.Y.Offset - offset)
end
UpdateBorder()

local dragging = false
local dragStart, startPos
button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        UpdateBorder()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local isOpen = true
button.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if Window then
        Window:Minimize(not isOpen)
    end
    button.Image = isOpen and imgOff or imgOn
end)
