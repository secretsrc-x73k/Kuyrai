--2
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
    TargetMode = "Killer"
}

local ToF_State = {
    Connection = nil,
    InputBegan = nil,
    InputEnded = nil,
    TouchInput = nil,
    IsAiming = false,
    Laser = nil,
    ZombieCache = {},
    ZombieCacheTime = 0
}

local function GetRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local tof = items and items:FindFirstChild("Twist of Fate")
    local fire = tof and tof:FindFirstChild("Fire")

    if fire and fire:IsA("RemoteEvent") then
        return fire
    end

    return nil
end

local function GetGun()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end

    local tof = char:FindFirstChild("Twist of Fate", true)
    if not tof then
        return nil
    end

    local rightArm = tof:FindFirstChild("Right Arm")

    if rightArm then
        local gun = rightArm:FindFirstChild("gun")
        if gun then
            return gun
        end

        local emperorGun = rightArm:FindFirstChild("EmperorGun")
        if emperorGun then
            return emperorGun
        end
    end

    return tof
end

local function IsDowned(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return true
    end

    local state = char:GetAttribute("State")

    return state == "Downed" or state == "Dead"
end

local function GetShootButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local survivorMob = playerGui and playerGui:FindFirstChild("Survivor-mob")
    local controls = survivorMob and survivorMob:FindFirstChild("Controls")
    local guiMob = controls and controls:FindFirstChild("Gui-mob")

    if not guiMob then
        return nil
    end

    local names = {
        "attack",
        "Attack",
        "shoot",
        "Shoot",
        "fire",
        "Fire"
    }

    for _, name in ipairs(names) do
        local button = guiMob:FindFirstChild(name, true)

        if button and button:IsA("GuiObject") then
            return button
        end
    end

    for _, object in ipairs(guiMob:GetDescendants()) do
        if object:IsA("GuiButton") and object.Visible then
            return object
        end
    end

    return guiMob:IsA("GuiObject") and guiMob or nil
end

local function IsTouchOnShootButton(input)
    local button = GetShootButton()

    if not button or not button.Visible then
        return false
    end

    local position = input.Position
    local buttonPosition = button.AbsolutePosition
    local buttonSize = button.AbsoluteSize

    return position.X >= buttonPosition.X
        and position.X <= buttonPosition.X + buttonSize.X
        and position.Y >= buttonPosition.Y
        and position.Y <= buttonPosition.Y + buttonSize.Y
end

local function IsVisible(origin, target, targetCharacter)
    local direction = target - origin
    local distance = direction.Magnitude

    if distance < 0.1 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local exclude = {}

    if LocalPlayer.Character then
        table.insert(exclude, LocalPlayer.Character)
    end

    if targetCharacter and targetCharacter ~= LocalPlayer.Character then
        table.insert(exclude, targetCharacter)
    end

    if ToF_State.Laser then
        table.insert(exclude, ToF_State.Laser)
    end

    params.FilterDescendantsInstances = exclude

    local result = Workspace:Raycast(
        origin,
        direction.Unit * distance,
        params
    )

    return result == nil
end

local function GetZombies()
    if tick() - ToF_State.ZombieCacheTime < 0.5 then
        return ToF_State.ZombieCache
    end

    local targets = {}
    local map = Workspace:FindFirstChild("Map")

    if map then
        for _, object in pairs(map:GetDescendants()) do
            if object:IsA("Model") then
                local attributes = object:GetAttributes()

                if object:GetAttribute("CorpseCreated0492")
                    or next(attributes) ~= nil then

                    local root = object:FindFirstChild("HumanoidRootPart")

                    if root then
                        table.insert(targets, root)
                    end
                end
            end
        end
    end

    ToF_State.ZombieCache = targets
    ToF_State.ZombieCacheTime = tick()

    return targets
end

local function GetTarget()
    local gun = GetGun()
    local char = LocalPlayer.Character

    if not gun or not char then
        return nil
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil
    end

    local myPosition = hrp.Position
    local origin

    if char:GetAttribute("IsCarried") then
        origin = hrp.Position + hrp.CFrame.LookVector * 2
    else
        pcall(function()
            if gun:IsA("BasePart") then
                origin = gun.Position
            else
                local part = gun:FindFirstChildOfClass("BasePart")

                if part then
                    origin = part.Position
                end
            end
        end)

        origin = origin or Vector3.new(
            myPosition.X,
            myPosition.Y + 1.5,
            myPosition.Z
        )
    end

    local function Predict(torso, targetCharacter)
        local targetPosition = torso.Position

        if ToF_Config.WallCheck
            and not IsVisible(
                origin,
                targetPosition,
                targetCharacter
            ) then
            return nil
        end

        local targetVelocity = Vector3.new(0, 0, 0)

        local rootPart = targetCharacter
            and (
                targetCharacter:FindFirstChild("HumanoidRootPart")
                or torso
            )

        if rootPart then
            targetVelocity = rootPart.Velocity
        end

        local direction = targetPosition - origin
        local distance = direction.Magnitude

        if distance < 0.1 then
            return nil
        end

        if distance < 5 then
            return {
                Direction = direction.Unit,
                Origin = origin,
                Target = targetPosition,
                Gun = gun
            }
        end

        local travelTime = distance / 400
        local predictedPosition =
            targetPosition + targetVelocity * travelTime

        for _ = 1, 2 do
            local newDistance =
                (predictedPosition - origin).Magnitude

            travelTime = newDistance / 400

            predictedPosition =
                targetPosition + targetVelocity * travelTime
        end

        local finalDirection =
            predictedPosition - origin

        if finalDirection.Magnitude < 0.1 then
            return nil
        end

        return {
            Direction = finalDirection.Unit,
            Origin = origin,
            Target = predictedPosition,
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

                local torso =
                    player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")

                if torso then
                    local distance =
                        (myPosition - torso.Position).Magnitude

                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestTorso = torso
                        closestCharacter = player.Character
                    end
                end
            end
        end

        if closestTorso then
            return Predict(
                closestTorso,
                closestCharacter
            )
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

                local torso =
                    player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")

                if torso then
                    local direction =
                        torso.Position - cameraPosition

                    if direction.Magnitude > 0.1 then
                        local dot =
                            cameraLook:Dot(direction.Unit)

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
            return Predict(
                bestTorso,
                bestCharacter
            )
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
                local direction =
                    root.Position - cameraPosition

                if direction.Magnitude > 0.1 then
                    local dot =
                        cameraLook:Dot(direction.Unit)

                    if dot > 0.5 and dot > bestDot then
                        bestDot = dot
                        bestPart = root
                    end
                end
            end
        end

        if bestPart then
            return Predict(
                bestPart,
                bestPart.Parent
            )
        end
    end

    return nil
end

local function UpdateLaser(origin, target)
    if not ToF_State.Laser then
        local laser = Instance.new("Part")

        laser.Name = "ToFLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(255, 50, 50)
        laser.Parent = Workspace

        ToF_State.Laser = laser
    end

    local distance = (target - origin).Magnitude

    ToF_State.Laser.Size =
        Vector3.new(0.05, 0.05, distance)

    ToF_State.Laser.CFrame =
        CFrame.new(
            (origin + target) / 2,
            target
        )

    ToF_State.Laser.Transparency = 0
end

local function ClearLaser()
    if ToF_State.Laser then
        pcall(function()
            ToF_State.Laser:Destroy()
        end)

        ToF_State.Laser = nil
    end
end

local function Shoot()
    if not ToF_Config.Enabled then
        return
    end

    local char = LocalPlayer.Character

    if char
        and ToF_Config.BlockKnocked
        and IsDowned(char) then
        return
    end

    local target = GetTarget()

    if not target then
        return
    end

    local remote = GetRemote()

    if not remote then
        return
    end

    local direction =
        target.Target - target.Origin

    if direction.Magnitude < 0.1 then
        return
    end

    pcall(function()
        remote:FireServer(
            target.Gun,
            direction.Unit
        )
    end)
end

local function StartInput()
    if ToF_State.InputBegan then
        return
    end

    ToF_State.InputBegan =
        UserInputService.InputBegan:Connect(function(
            input,
            gameProcessed
        )
            if gameProcessed
                or not ToF_Config.Enabled then
                return
            end

            local mouse =
                input.UserInputType ==
                Enum.UserInputType.MouseButton1

            local touch =
                input.UserInputType ==
                Enum.UserInputType.Touch
                and IsTouchOnShootButton(input)

            if mouse or touch then
                ToF_State.IsAiming = true

                if touch then
                    ToF_State.TouchInput = input
                end

                Shoot()
            end
        end)

    ToF_State.InputEnded =
        UserInputService.InputEnded:Connect(function(input)
            local mouse =
                input.UserInputType ==
                Enum.UserInputType.MouseButton1

            local touch =
                input.UserInputType ==
                Enum.UserInputType.Touch
                and input == ToF_State.TouchInput

            if mouse or touch then
                ToF_State.IsAiming = false
                ToF_State.TouchInput = nil

                if ToF_State.Laser then
                    ToF_State.Laser.Transparency = 1
                end
            end
        end)
end

local function StopInput()
    if ToF_State.InputBegan then
        ToF_State.InputBegan:Disconnect()
        ToF_State.InputBegan = nil
    end

    if ToF_State.InputEnded then
        ToF_State.InputEnded:Disconnect()
        ToF_State.InputEnded = nil
    end

    ToF_State.IsAiming = false
    ToF_State.TouchInput = nil
end

local function StartConnection()
    if ToF_State.Connection then
        return
    end

    ToF_State.Connection =
        RunService.Heartbeat:Connect(function()
            if not ToF_Config.Enabled
                or not ToF_State.IsAiming then

                if ToF_State.Laser then
                    ToF_State.Laser.Transparency = 1
                end

                return
            end

            local target = GetTarget()

            if not target then
                if ToF_State.Laser then
                    ToF_State.Laser.Transparency = 1
                end

                return
            end

            local char = LocalPlayer.Character
            local hrp =
                char and char:FindFirstChild("HumanoidRootPart")

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
                UpdateLaser(
                    target.Origin,
                    target.Target
                )
            elseif ToF_State.Laser then
                ToF_State.Laser.Transparency = 1
            end
        end)
end

local function StopConnection()
    if ToF_State.Connection then
        ToF_State.Connection:Disconnect()
        ToF_State.Connection = nil
    end

    ToF_State.IsAiming = false
    ClearLaser()
end

local function SetEnabled(value)
    ToF_Config.Enabled = value

    if value then
        StartInput()
        StartConnection()
    else
        StopInput()
        StopConnection()
    end
end

local Window = Fluent:CreateWindow({
    Title = "Violence District",
    SubTitle = "Twist of Fate Rewrite",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 340),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Combat = Window:AddTab({
        Title = "Combat",
        Icon = "crosshair"
    })
}

Tabs.Combat:AddToggle("ToF_Enabled", {
    Title = "Enable Silent Aim",
    Default = false,
    Callback = SetEnabled
})

Tabs.Combat:AddToggle("ToF_Laser", {
    Title = "Laser Beam",
    Default = true,
    Callback = function(value)
        ToF_Config.Laser = value

        if not value then
            ClearLaser()
        end
    end
})

Tabs.Combat:AddToggle("ToF_WallCheck", {
    Title = "Wall Check",
    Default = false,
    Callback = function(value)
        ToF_Config.WallCheck = value
    end
})

Tabs.Combat:AddToggle("ToF_BlockKnocked", {
    Title = "Block When Knocked",
    Default = true,
    Callback = function(value)
        ToF_Config.BlockKnocked = value
    end
})

Tabs.Combat:AddDropdown("ToF_TargetMode", {
    Title = "Target Mode",
    Values = {
        "Killer",
        "Survivors",
        "Zombie"
    },
    Default = "Killer",
    Multi = false,
    Callback = function(value)
        if type(value) == "table" then
            value = value[1]
        end

        ToF_Config.TargetMode =
            value or "Killer"
    end
})

Window:SelectTab(1)
