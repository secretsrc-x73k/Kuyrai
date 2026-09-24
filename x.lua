local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local ToF_Config = {
    Enabled = false,
    Laser = true,
    WallCheck = false,
    BlockKnocked = true,
    TargetMode = "Killer",
    Speed = 400
}

local ToF_Internal = {
    Connection = nil,
    TouchInput = nil,
    IsAiming = false,
    LaserPart = nil,
    Cache = {},
    LastCache = 0
}

local function IsBlocked()
    if not ToF_Config.BlockKnocked then
        return false
    end

    local char = LocalPlayer.Character
    if not char then
        return true
    end

    local state = char:GetAttribute("State")
    local knocked = char:GetAttribute("Knocked")

    return state == "Downed"
        or state == "Dead"
        or knocked == true
end

local function GetToFRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local tof = items and items:FindFirstChild("Twist of Fate")

    return tof and tof:FindFirstChild("Fire")
end

local function GetGunObject()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end

    local tof = char:FindFirstChild("Twist of Fate", true)
    if not tof then
        return nil
    end

    local arm = tof:FindFirstChild("Right Arm")
    if not arm then
        return tof
    end

    return arm:FindFirstChild("gun")
        or arm:FindFirstChild("EmperorGun")
        or tof
end

local function IsTouchOnShootButton(input)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return false
    end

    local guiNames = {
        "Survivor-mob",
        "Slasher-mob"
    }

    local buttonNames = {
        "attack",
        "Attack",
        "shoot",
        "Shoot",
        "fire",
        "Fire"
    }

    for _, guiName in ipairs(guiNames) do
        local gui = playerGui:FindFirstChild(guiName)
        local controls = gui and gui:FindFirstChild("Controls")
        local guiMob = controls and controls:FindFirstChild("Gui-mob")

        if guiMob and guiMob.Visible then
            for _, buttonName in ipairs(buttonNames) do
                local button = guiMob:FindFirstChild(buttonName, true)

                if button
                    and button:IsA("GuiObject")
                    and button.Visible
                    and button.AbsoluteSize.X > 0 then

                    local position = input.Position
                    local buttonPosition = button.AbsolutePosition
                    local buttonSize = button.AbsoluteSize

                    if position.X >= buttonPosition.X
                        and position.X <= buttonPosition.X + buttonSize.X
                        and position.Y >= buttonPosition.Y
                        and position.Y <= buttonPosition.Y + buttonSize.Y then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function IsTargetVisible(origin, targetPosition, targetCharacter)
    local direction = targetPosition - origin

    if direction.Magnitude < 0.1 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local filter = {}

    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end

    if targetCharacter then
        table.insert(filter, targetCharacter)
    end

    if ToF_Internal.LaserPart then
        table.insert(filter, ToF_Internal.LaserPart)
    end

    params.FilterDescendantsInstances = filter

    return Workspace:Raycast(origin, direction, params) == nil
end

local function GetZombies()
    if tick() - ToF_Internal.LastCache < 0.5 then
        return ToF_Internal.Cache
    end

    local targets = {}
    local map = Workspace:FindFirstChild("Map")

    if map then
        for _, object in ipairs(map:GetDescendants()) do
            if object:IsA("Model")
                and (
                    object:GetAttribute("CorpseCreated0492")
                    or object:GetAttribute("Zombie")
                ) then

                local root = object:FindFirstChild("HumanoidRootPart")

                if root then
                    table.insert(targets, root)
                end
            end
        end
    end

    ToF_Internal.Cache = targets
    ToF_Internal.LastCache = tick()

    return targets
end

local function GetTarget()
    local gun = GetGunObject()
    local char = LocalPlayer.Character

    if not gun or not char then
        return nil
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local myPos = hrp.Position
    local origin

    if char:GetAttribute("IsCarried") then
        origin = hrp.Position + hrp.CFrame.LookVector * 2
    else
        if gun:IsA("BasePart") then
            origin = gun.Position
        else
            local part = gun:FindFirstChildOfClass("BasePart")
            if part then
                origin = part.Position
            end
        end

        origin = origin or Vector3.new(myPos.X, myPos.Y + 1.5, myPos.Z)
    end

    local function Predict(torso, targetCharacter)
        local targetPosition = torso.Position

        if ToF_Config.WallCheck
            and not IsTargetVisible(origin, targetPosition, targetCharacter) then
            return nil
        end

        local velocity = Vector3.zero
        local root = targetCharacter
            and (
                targetCharacter:FindFirstChild("HumanoidRootPart")
                or torso
            )

        if root then
            velocity = root.Velocity
        end

        local direction = targetPosition - origin
        local distance = direction.Magnitude

        if distance < 0.1 then
            return nil
        end

        if distance < 5 then
            return {
                Origin = origin,
                Target = targetPosition,
                Direction = direction.Unit,
                Gun = gun
            }
        end

        local speed = math.max(ToF_Config.Speed, 1)
        local travelTime = distance / speed
        local predicted = targetPosition + velocity * travelTime

        for _ = 1, 2 do
            local newDistance = (predicted - origin).Magnitude
            travelTime = newDistance / speed
            predicted = targetPosition + velocity * travelTime
        end

        local finalDirection = predicted - origin

        if finalDirection.Magnitude < 0.1 then
            return nil
        end

        return {
            Origin = origin,
            Target = predicted,
            Direction = finalDirection.Unit,
            Gun = gun
        }
    end

    if ToF_Config.TargetMode == "Killer" then
        local closestTorso
        local closestCharacter
        local shortestDistance = math.huge

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer
                and player.Team
                and player.Team.Name == "Killer"
                and player.Character then

                local torso = player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")

                if torso then
                    local distance = (myPos - torso.Position).Magnitude

                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestTorso = torso
                        closestCharacter = player.Character
                    end
                end
            end
        end

        if closestTorso then
            return Predict(closestTorso, closestCharacter)
        end
    elseif ToF_Config.TargetMode == "Survivors" then
        local camera = Workspace.CurrentCamera
        if not camera then
            return nil
        end

        local bestTorso
        local bestCharacter
        local bestDot = -math.huge
        local cameraPosition = camera.CFrame.Position
        local cameraLook = camera.CFrame.LookVector

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer
                and player.Team
                and player.Team.Name == "Survivors"
                and player.Character then

                local torso = player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")

                if torso then
                    local direction = torso.Position - cameraPosition

                    if direction.Magnitude > 0.1 then
                        local dot = cameraLook:Dot(direction.Unit)

                        if dot > 0.5 and dot > bestDot then
                            bestDot = dot
                            bestTorso = torso
                            bestCharacter = player.Character
                        end
                    end
                end
            end
        end

        if bestTorso then
            return Predict(bestTorso, bestCharacter)
        end
    elseif ToF_Config.TargetMode == "Zombie" then
        local camera = Workspace.CurrentCamera
        if not camera then
            return nil
        end

        local bestPart
        local bestDot = -math.huge
        local cameraPosition = camera.CFrame.Position
        local cameraLook = camera.CFrame.LookVector

        for _, root in ipairs(GetZombies()) do
            if root and root.Parent then
                local direction = root.Position - cameraPosition

                if direction.Magnitude > 0.1 then
                    local dot = cameraLook:Dot(direction.Unit)

                    if dot > 0.5 and dot > bestDot then
                        bestDot = dot
                        bestPart = root
                    end
                end
            end
        end

        if bestPart then
            return Predict(bestPart, bestPart.Parent)
        end
    end

    return nil
end

local function UpdateLaser(origin, target)
    if not ToF_Internal.LaserPart then
        local laser = Instance.new("Part")

        laser.Name = "ToFLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(255, 50, 50)
        laser.Parent = Workspace

        ToF_Internal.LaserPart = laser
    end

    local laser = ToF_Internal.LaserPart
    local distance = (target - origin).Magnitude

    laser.Size = Vector3.new(0.05, 0.05, distance)
    laser.CFrame = CFrame.new((origin + target) / 2, target)
    laser.Transparency = 0
end

local function ClearLaser()
    if ToF_Internal.LaserPart then
        ToF_Internal.LaserPart:Destroy()
        ToF_Internal.LaserPart = nil
    end
end

local function DoShoot()
    if not ToF_Config.Enabled or IsBlocked() then
        return
    end

    local target = GetTarget()
    if not target then
        return
    end

    local remote = GetToFRemote()
    if not remote then
        return
    end

    pcall(function()
        remote:FireServer(target.Gun, target.Direction)
    end)
end

local function StartInput()
    if ToF_Internal.InputBegan then
        return
    end

    ToF_Internal.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not ToF_Config.Enabled then
            return
        end

        local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
        local touch = input.UserInputType == Enum.UserInputType.Touch
            and IsTouchOnShootButton(input)

        if mouse or touch then
            ToF_Internal.IsAiming = true
            ToF_Internal.TouchInput = touch and input or nil
            DoShoot()
        end
    end)

    ToF_Internal.InputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or (
                input.UserInputType == Enum.UserInputType.Touch
                and input == ToF_Internal.TouchInput
            ) then

            ToF_Internal.IsAiming = false
            ToF_Internal.TouchInput = nil

            if ToF_Internal.LaserPart then
                ToF_Internal.LaserPart.Transparency = 1
            end
        end
    end)
end

local function StopInput()
    if ToF_Internal.InputBegan then
        ToF_Internal.InputBegan:Disconnect()
        ToF_Internal.InputBegan = nil
    end

    if ToF_Internal.InputEnded then
        ToF_Internal.InputEnded:Disconnect()
        ToF_Internal.InputEnded = nil
    end

    ToF_Internal.IsAiming = false
    ToF_Internal.TouchInput = nil
end

local function StartHeartbeat()
    if ToF_Internal.Connection then
        return
    end

    ToF_Internal.Connection = RunService.Heartbeat:Connect(function()
        if not ToF_Config.Enabled
            or not ToF_Internal.IsAiming
            or IsBlocked() then

            if ToF_Internal.LaserPart then
                ToF_Internal.LaserPart.Transparency = 1
            end

            return
        end

        local target = GetTarget()

        if not target then
            if ToF_Internal.LaserPart then
                ToF_Internal.LaserPart.Transparency = 1
            end

            return
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp and not char:GetAttribute("IsCarried") then
            hrp.CFrame = CFrame.new(
                hrp.Position,
                Vector3.new(
                    target.Target.X,
                    hrp.Position.Y,
                    target.Target.Z
                )
            )
        end

        if ToF_Config.Laser then
            UpdateLaser(target.Origin, target.Target)
        elseif ToF_Internal.LaserPart then
            ToF_Internal.LaserPart.Transparency = 1
        end
    end)
end

local function StopHeartbeat()
    if ToF_Internal.Connection then
        ToF_Internal.Connection:Disconnect()
        ToF_Internal.Connection = nil
    end

    ToF_Internal.IsAiming = false
    ClearLaser()
end

local function SetEnabled(value)
    ToF_Config.Enabled = value

    if value then
        StartInput()
        StartHeartbeat()
    else
        StopInput()
        StopHeartbeat()
    end
end

local Window = Fluent:CreateWindow({
    Title = "Violence District",
    SubTitle = "Twist of Fate Rewrite",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 360),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Aim = Window:AddTab({
        Title = "Combat",
        Icon = "crosshair"
    })
}

Tabs.Aim:AddToggle("ToF_Enabled", {
    Title = "Enable Silent Aim",
    Default = false,
    Callback = SetEnabled
})

Tabs.Aim:AddToggle("ToF_Laser", {
    Title = "Laser Beam",
    Default = true,
    Callback = function(value)
        ToF_Config.Laser = value

        if not value then
            ClearLaser()
        end
    end
})

Tabs.Aim:AddToggle("ToF_WallCheck", {
    Title = "Wall Check",
    Default = false,
    Callback = function(value)
        ToF_Config.WallCheck = value
    end
})

Tabs.Aim:AddToggle("ToF_BlockKnocked", {
    Title = "Block When Knocked",
    Default = true,
    Callback = function(value)
        ToF_Config.BlockKnocked = value
    end
})

Tabs.Aim:AddDropdown("ToF_Target", {
    Title = "Target Mode",
    Values = {
        "Killer",
        "Survivors",
        "Zombie"
    },
    Default = "Killer",
    Callback = function(value)
        ToF_Config.TargetMode = value
    end
})

Tabs.Aim:AddInput("ToF_Speed", {
    Title = "Prediction Speed",
    Default = "400",
    Placeholder = "400",
    Numeric = true,
    Finished = true,
    Callback = function(value)
        local speed = tonumber(value)

        if speed and speed > 0 then
            ToF_Config.Speed = speed
        end
    end
})

Window:SelectTab(1)
