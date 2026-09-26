--3
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--========================================================--
-- FLUENT
--========================================================--

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/secretsrc-x73k/NewUI/refs/heads/main/newui.lua"))()

--========================================================--
-- CONFIG
--========================================================--

local ToF_Config = {
    Enabled = false,
    Laser = true,
    WallCheck = false,
    BlockKnocked = true,
    TargetMode = "Killer"
}

--========================================================--
-- STATE
--========================================================--

local ToF_State = {
    Connection = nil,

    InputBegan = nil,
    InputEnded = nil,

    TouchInput = nil,
    IsAiming = false,

    Laser = nil,

    ZombieCache = {},
    ZombieCacheTime = 0,

    InputStarted = false
}

--========================================================--
-- REMOTE
--========================================================--

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

--========================================================--
-- GUN
--========================================================--

local function GetGun()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end

    local baseToF = char:FindFirstChild("Twist of Fate", true)
    if not baseToF then
        return nil
    end

    local rightArm = baseToF:FindFirstChild("Right Arm")

    if rightArm then
        local gunPart = rightArm:FindFirstChild("gun")
        if gunPart then
            return gunPart
        end

        local emperorGun = rightArm:FindFirstChild("EmperorGun")
        if emperorGun then
            return emperorGun
        end
    end

    return baseToF
end

--========================================================--
-- DOWNED CHECK
--========================================================--

local function IsDowned(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return true
    end

    local state = char:GetAttribute("State")

    return state == "Downed" or state == "Dead"
end

--========================================================--
-- MOBILE SHOOT BUTTON
--========================================================--

local function GetShootButton()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local survivorMob = playerGui and playerGui:FindFirstChild("Survivor-mob")
    local controls = survivorMob and survivorMob:FindFirstChild("Controls")
    local guiMob = controls and controls:FindFirstChild("Gui-mob")

    if not guiMob then
        return nil
    end

    local directNames = {
        "attack",
        "Attack",
        "shoot",
        "Shoot",
        "fire",
        "Fire"
    }

    for _, name in ipairs(directNames) do
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

    if guiMob:IsA("GuiObject") then
        return guiMob
    end

    return nil
end

--========================================================--
-- TOUCH BUTTON CHECK
--========================================================--

local function IsTouchOnShootButton(input)
    local shootButton = GetShootButton()

    if not (shootButton and shootButton.Visible) then
        return false
    end

    local pos = input.Position

    local absPos = shootButton.AbsolutePosition
    local absSize = shootButton.AbsoluteSize

    return
        pos.X >= absPos.X
        and pos.X <= absPos.X + absSize.X
        and pos.Y >= absPos.Y
        and pos.Y <= absPos.Y + absSize.Y
end

--========================================================--
-- WALL CHECK
--========================================================--

local function IsVisible(originPos, targetPos, targetCharacter)
    local direction = targetPos - originPos
    local distance = direction.Magnitude

    if distance < 0.1 then
        return true
    end

    local rayParams = RaycastParams.new()

    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local excludeList = {}

    local localChar = LocalPlayer.Character

    if localChar then
        table.insert(excludeList, localChar)
    end

    if targetCharacter and targetCharacter ~= localChar then
        table.insert(excludeList, targetCharacter)
    end

    if ToF_State.Laser then
        table.insert(excludeList, ToF_State.Laser)
    end

    rayParams.FilterDescendantsInstances = excludeList

    local result = workspace:Raycast(
        originPos,
        direction.Unit * distance,
        rayParams
    )

    return result == nil
end

--========================================================--
-- ZOMBIE CACHE
--========================================================--

local function GetZombies()
    if tick() - ToF_State.ZombieCacheTime < 0.5 then
        return ToF_State.ZombieCache
    end

    local newTargets = {}

    local mapFolder = workspace:FindFirstChild("Map")

    if mapFolder then
        for _, container in pairs(mapFolder:GetDescendants()) do
            if container:IsA("Model") then

                local attributes = container:GetAttributes()

                if
                    container:GetAttribute("CorpseCreated0492")
                    or next(attributes) ~= nil
                then

                    local root = container:FindFirstChild("HumanoidRootPart")

                    if root then
                        table.insert(newTargets, root)
                    end
                end
            end
        end
    end

    ToF_State.ZombieCache = newTargets
    ToF_State.ZombieCacheTime = tick()

    return ToF_State.ZombieCache
end

--========================================================--
-- TARGET POSITION / PREDICTION
--========================================================--

local function GetTarget()
    local gunObject = GetGun()
    local char = LocalPlayer.Character

    if not (gunObject and char) then
        return nil, nil, nil, nil
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil, nil, nil, nil
    end

    local myPos = hrp.Position
    local originPos

    if char:GetAttribute("IsCarried") then

        originPos =
            hrp.Position
            + (hrp.CFrame.LookVector * 2)

    else

        pcall(function()

            if gunObject:IsA("BasePart") then
                originPos = gunObject.Position
            else
                local basePart =
                    gunObject:FindFirstChildOfClass("BasePart")

                if basePart then
                    originPos = basePart.Position
                end
            end

        end)

        originPos =
            originPos
            or Vector3.new(
                myPos.X,
                myPos.Y + 1.5,
                myPos.Z
            )
    end

    --====================================================--
    -- PREDICTION
    --====================================================--

    local function PredictTarget(torso, targetCharacter)

        local targetPos = torso.Position

        if
            ToF_Config.WallCheck
            and not IsVisible(
                originPos,
                targetPos,
                targetCharacter
            )
        then
            return nil, nil, nil, nil
        end

        local targetVelocity =
            Vector3.new(0, 0, 0)

        local rootPart =
            targetCharacter
            and (
                targetCharacter:FindFirstChild(
                    "HumanoidRootPart"
                )
                or torso
            )

        if rootPart then
            targetVelocity = rootPart.Velocity
        end

        local directionRaw =
            targetPos - originPos

        local distance =
            directionRaw.Magnitude

        if distance < 0.1 then
            return nil, nil, nil, nil
        end

        -- Close range = no prediction
        if distance < 5 then
            return
                directionRaw.Unit,
                gunObject,
                originPos,
                targetPos
        end

        --================================================--
        -- ORIGINAL SPEED
        --================================================--

        local travelTime =
            distance / 400

        local predictedPos =
            targetPos
            + (targetVelocity * travelTime)

        --================================================--
        -- TWO REFINEMENT PASSES
        --================================================--

        for _ = 1, 2 do

            local newDistance =
                (predictedPos - originPos).Magnitude

            travelTime =
                newDistance / 400

            predictedPos =
                targetPos
                + (targetVelocity * travelTime)
        end

        local finalDirection =
            predictedPos - originPos

        if finalDirection.Magnitude < 0.1 then
            return nil, nil, nil, nil
        end

        return
            finalDirection.Unit,
            gunObject,
            originPos,
            predictedPos
    end

    --====================================================--
    -- KILLER
    --====================================================--

    if ToF_Config.TargetMode == "Killer" then

        local closestTorso
        local closestCharacter
        local shortestDistance = math.huge

        for _, player in ipairs(Players:GetPlayers()) do

            if
                player ~= LocalPlayer
                and player.Team
                and player.Team.Name == "Killer"
                and player.Character
            then

                local torso =
                    player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")

                if torso then

                    local distance =
                        (myPos - torso.Position).Magnitude

                    if distance < shortestDistance then

                        shortestDistance = distance
                        closestTorso = torso
                        closestCharacter = player.Character

                    end
                end
            end
        end

        if not closestTorso then
            return nil, nil, nil, nil
        end

        return PredictTarget(
            closestTorso,
            closestCharacter
        )
    end

    --====================================================--
    -- SURVIVORS
    --====================================================--

    if ToF_Config.TargetMode == "Survivors" then

        local bestTorso
        local bestCharacter
        local bestDot = -math.huge

        local camera = workspace.CurrentCamera

        if not camera then
            return nil, nil, nil, nil
        end

        local cameraPosition =
            camera.CFrame.Position

        local cameraLook =
            camera.CFrame.LookVector

        for _, player in ipairs(Players:GetPlayers()) do

            if
                player ~= LocalPlayer
                and player.Team
                and player.Team.Name == "Survivors"
                and player.Character
            then

                local torso =
                    player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")

                if torso then

                    local direction =
                        torso.Position - cameraPosition

                    if direction.Magnitude > 0.1 then

                        local dot =
                            cameraLook:Dot(
                                direction.Unit
                            )

                        if
                            dot > 0.5
                            and dot > bestDot
                        then

                            bestDot = dot
                            bestTorso = torso
                            bestCharacter = player.Character

                        end
                    end
                end
            end
        end

        if not bestTorso then
            return nil, nil, nil, nil
        end

        return PredictTarget(
            bestTorso,
            bestCharacter
        )
    end

    --====================================================--
    -- ZOMBIE
    --====================================================--

    if ToF_Config.TargetMode == "Zombie" then

        local bestPart
        local bestDot = -math.huge

        local camera = workspace.CurrentCamera

        if not camera then
            return nil, nil, nil, nil
        end

        local cameraPosition =
            camera.CFrame.Position

        local cameraLook =
            camera.CFrame.LookVector

        for _, root in ipairs(GetZombies()) do

            if root and root.Parent then

                local direction =
                    root.Position - cameraPosition

                if direction.Magnitude > 0.1 then

                    local dot =
                        cameraLook:Dot(
                            direction.Unit
                        )

                    if
                        dot > 0.5
                        and dot > bestDot
                    then

                        bestDot = dot
                        bestPart = root

                    end
                end
            end
        end

        if not bestPart then
            return nil, nil, nil, nil
        end

        return PredictTarget(
            bestPart,
            bestPart.Parent
        )
    end

    return nil, nil, nil, nil
end

--========================================================--
-- LASER
--========================================================--

local function UpdateLaser(originPos, targetPos)

    if not ToF_State.Laser then

        local laser = Instance.new("Part")

        laser.Name = "ToFLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CastShadow = false

        laser.Material = Enum.Material.Neon
        laser.Color =
            Color3.fromRGB(255, 50, 50)

        laser.Parent = workspace

        ToF_State.Laser = laser
    end

    local distance =
        (targetPos - originPos).Magnitude

    ToF_State.Laser.Size =
        Vector3.new(
            0.05,
            0.05,
            distance
        )

    ToF_State.Laser.CFrame =
        CFrame.new(
            (originPos + targetPos) / 2,
            targetPos
        )

    ToF_State.Laser.Transparency = 0
end

--========================================================--
-- CLEAR LASER
--========================================================--

local function ClearLaser()

    if ToF_State.Laser then

        pcall(function()
            ToF_State.Laser:Destroy()
        end)

        ToF_State.Laser = nil
    end
end

--========================================================--
-- SHOOT
--========================================================--

local function Shoot()

    if not ToF_Config.Enabled then
        return
    end

    local char = LocalPlayer.Character

    if char then

        if
            ToF_Config.BlockKnocked
            and IsDowned(char)
        then
            return
        end
    end

    local
        targetDirection,
        gunObject,
        originPos,
        targetPos =
        GetTarget()

    if not (
        targetDirection
        and gunObject
        and targetPos
        and originPos
    ) then
        return
    end

    local tofEvent = GetRemote()

    if not tofEvent then
        return
    end

    -- Recalculate direction immediately before firing
    local freshDirection =
        targetPos - originPos

    if freshDirection.Magnitude < 0.1 then
        return
    end

    pcall(function()

        tofEvent:FireServer(
            gunObject,
            freshDirection.Unit
        )

    end)
end

--========================================================--
-- INPUT
--========================================================--

local function StopInput()

    if ToF_State.InputBegan then
        ToF_State.InputBegan:Disconnect()
        ToF_State.InputBegan = nil
    end

    if ToF_State.InputEnded then
        ToF_State.InputEnded:Disconnect()
        ToF_State.InputEnded = nil
    end

    ToF_State.TouchInput = nil
    ToF_State.IsAiming = false
    ToF_State.InputStarted = false

    ClearLaser()
end

local function StartInput()

    StopInput()

    --====================================================--
    -- PRESS
    --====================================================--

    ToF_State.InputBegan =
        UserInputService.InputBegan:Connect(
            function(input, gameProcessed)

                if gameProcessed then
                    return
                end

                -- PC
                if
                    input.UserInputType
                    == Enum.UserInputType.MouseButton1
                then

                    ToF_State.IsAiming = true
                    ToF_State.InputStarted = true

                    -- IMPORTANT:
                    -- NO SHOOT HERE
                    -- Shooting happens on release.

                    return
                end

                -- Mobile
                if
                    input.UserInputType
                    == Enum.UserInputType.Touch
                then

                    if IsTouchOnShootButton(input) then

                        ToF_State.IsAiming = true
                        ToF_State.TouchInput = input
                        ToF_State.InputStarted = true

                    end
                end
            end
        )

    --====================================================--
    -- RELEASE
    --====================================================--

    ToF_State.InputEnded =
        UserInputService.InputEnded:Connect(
            function(input)

                local isMouseRelease =
                    input.UserInputType
                    == Enum.UserInputType.MouseButton1

                local isTouchRelease =
                    input.UserInputType
                    == Enum.UserInputType.Touch
                    and input == ToF_State.TouchInput

                if not (isMouseRelease or isTouchRelease) then
                    return
                end

                if not ToF_State.InputStarted then
                    return
                end

                -- Stop aiming first
                ToF_State.IsAiming = false
                ToF_State.InputStarted = false
                ToF_State.TouchInput = nil

                --================================================--
                -- SHOOT ON RELEASE
                --================================================--

                if ToF_Config.Enabled then
                    Shoot()
                end

                ClearLaser()
            end
        )
end

--========================================================--
-- HEARTBEAT
--========================================================--

local function StopConnection()

    if ToF_State.Connection then

        ToF_State.Connection:Disconnect()
        ToF_State.Connection = nil

    end

    ClearLaser()
end

local function StartConnection()

    StopConnection()

    ToF_State.Connection =
        RunService.Heartbeat:Connect(
            function()

                if not ToF_Config.Enabled then

                    if ToF_State.IsAiming then
                        ToF_State.IsAiming = false
                    end

                    ClearLaser()

                    return
                end

                if not ToF_State.IsAiming then

                    ClearLaser()

                    return
                end

                local
                    direction,
                    gunObject,
                    originPos,
                    targetPos =
                    GetTarget()

                if not (
                    direction
                    and gunObject
                    and originPos
                    and targetPos
                ) then

                    ClearLaser()
                    return
                end

                --================================================--
                -- FACE TARGET WHILE HOLDING
                --================================================--

                local char = LocalPlayer.Character
                local hrp =
                    char
                    and char:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if
                    hrp
                    and not char:GetAttribute("IsCarried")
                then

                    local lookTarget =
                        Vector3.new(
                            targetPos.X,
                            hrp.Position.Y,
                            targetPos.Z
                        )

                    if
                        (lookTarget - hrp.Position).Magnitude
                        > 0.1
                    then

                        hrp.CFrame =
                            CFrame.lookAt(
                                hrp.Position,
                                lookTarget
                            )
                    end
                end

                --================================================--
                -- LASER
                --================================================--

                if ToF_Config.Laser then

                    UpdateLaser(
                        originPos,
                        targetPos
                    )

                else

                    ClearLaser()

                end
            end
        )
end

--========================================================--
-- ENABLE / DISABLE
--========================================================--

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

--========================================================--
-- FLUENT WINDOW
--========================================================--

local Window = Fluent:CreateWindow({
    Title = "REAPER | Twist of Fate",
    SubTitle = "Silent Aim",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--========================================================--
-- TAB
--========================================================--

local AimTab = Window:AddTab({
    Title = "Silent Aim",
    Icon = "crosshair"
})

--========================================================--
-- SECTION
--========================================================--

AimTab:AddSection("Twist of Fate")

--========================================================--
-- ENABLE
--========================================================--

AimTab:AddToggle("ToFEnabled", {
    Title = "Silent Aim",
    Description = "Hold to aim, release to shoot once",
    Default = false
}):OnChanged(function(value)

    SetEnabled(value)

end)

--========================================================--
-- LASER
--========================================================--

AimTab:AddToggle("ToFLaser", {
    Title = "Laser Beam",
    Description = "Show target direction while holding",
    Default = true
}):OnChanged(function(value)

    ToF_Config.Laser = value

    if not value then
        ClearLaser()
    end

end)

--========================================================--
-- WALL CHECK
--========================================================--

AimTab:AddToggle("ToFWallCheck", {
    Title = "Wall Check",
    Description = "Ignore targets blocked by walls",
    Default = false
}):OnChanged(function(value)

    ToF_Config.WallCheck = value

end)

--========================================================--
-- BLOCK KNOCKED
--========================================================--

AimTab:AddToggle("ToFBlockKnocked", {
    Title = "Block When Knocked",
    Description = "Do not fire while downed/dead",
    Default = true
}):OnChanged(function(value)

    ToF_Config.BlockKnocked = value

end)

--========================================================--
-- TARGET MODE
--========================================================--

AimTab:AddDropdown("ToFTargetMode", {
    Title = "Target Mode",
    Values = {
        "Killer",
        "Survivors",
        "Zombie"
    },
    Multi = false,
    Default = "Killer"
}):OnChanged(function(value)

    if type(value) == "table" then
        value = value[1]
    end

    if
        value == "Killer"
        or value == "Survivors"
        or value == "Zombie"
    then

        ToF_Config.TargetMode = value

    end
end)

--========================================================--
-- INFO
--========================================================--

AimTab:AddParagraph({
    Title = "Input Behavior",
    Content =
        "Hold Mouse1 / attack button to aim.\n" ..
        "Release the button to fire once.\n" ..
        "Holding the button will not repeatedly fire."
})

--========================================================--
-- INITIALIZE INPUT
--========================================================--

StartInput()

--========================================================--
-- CLEANUP
--========================================================--

task.spawn(function()

    while task.wait(1) do

        if not ToF_Config.Enabled then
            continue
        end

        local char = LocalPlayer.Character

        if not char then
            ClearLaser()
        end
    end

end)
