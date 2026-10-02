local Fluent = LoadFluent("https://raw.githubusercontent.com/secretsrc-x73k/NewUI/refs/heads/main/newui.lua")




local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 330),
    Theme = "ExtremeReaper",
    MinimizeKey = Enum.KeyCode.RightControl
})

local KillerTab = Window:AddTab({
    Title = "Automatic",
    Icon = "target",
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VIM = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer

local Config = {
    Enabled = false,
    Distance = 9,
    ShowCircle = false,
    ShowStatusUI = false,
    CheckInterval = 0.025
}

local State = {
    Cooldown = false,
    CurrentCD = 0,
    Connections = {},
    ActiveAttacks = {},
    ParryRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Items"):WaitForChild("Parrying Dagger"):WaitForChild("parry"),
    ResultRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Items"):WaitForChild("Parrying Dagger"):WaitForChild("parryResult"),
    RayParams = RaycastParams.new()
}

State.RayParams.FilterType = Enum.RaycastFilterType.Exclude

local ATTACK_ANIMS = {
    ["113255068724446"] = true,
    ["74968262036854"] = true,
    ["110355011987939"] = true,
    ["139369275981139"] = true,
    ["132817836308238"] = true,
    ["129784271201071"] = true,
    ["133963973694098"] = true,
    ["117042998468241"] = true,
    ["105374834496520"] = true,
    ["111920872708571"] = true,
    ["78432063483146"] = true,
    ["118907603246885"] = true,
    ["138720291317243"] = true,
    ["115244153053858"] = true,
    ["130593238885843"] = true,
    ["122812055447896"] = true,
    ["78935059863801"] = true,
    ["135002183282873"] = true,
    ["121216847022485"] = true
}

local GUI_NAME = "ReaperStatus"

local Colors = {
    Background = Color3.fromRGB(8, 8, 10),
    Background2 = Color3.fromRGB(13, 13, 16),
    Red = Color3.fromRGB(255, 30, 50),
    White = Color3.fromRGB(245, 245, 247),
    Muted = Color3.fromRGB(75, 75, 83),
    TrafficRed = Color3.fromRGB(255, 95, 87),
    TrafficYellow = Color3.fromRGB(254, 188, 46),
    TrafficGreen = Color3.fromRGB(40, 200, 64)
}

if CoreGui:FindFirstChild(GUI_NAME) then
    CoreGui[GUI_NAME]:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name = GUI_NAME
Screen.IgnoreGuiInset = true
Screen.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(260, 100)
Main.Position = UDim2.fromScale(0.5, 0.4)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = Screen

local function ApplyStyle(obj, radius, color, thick, trans)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj

    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thick
    s.Transparency = trans or 0
    s.Parent = obj

    return s
end

ApplyStyle(Main, 12, Colors.Red, 1.5, 0.2)

local MainGlow = Instance.new("UIStroke")
MainGlow.Color = Colors.Red
MainGlow.Thickness = 6
MainGlow.Transparency = 0.8
MainGlow.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, -2, 0, 26)
TopBar.Position = UDim2.fromOffset(1, 1)
TopBar.BackgroundColor3 = Colors.Background2
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

ApplyStyle(TopBar, 11, Colors.Red, 1, 0.8)

local Traffic = Instance.new("Frame")
Traffic.Size = UDim2.fromOffset(45, 10)
Traffic.Position = UDim2.fromOffset(10, 8)
Traffic.BackgroundTransparency = 1
Traffic.Parent = TopBar

local tCols = {
    Colors.TrafficRed,
    Colors.TrafficYellow,
    Colors.TrafficGreen
}

for i, col in ipairs(tCols) do
    local d = Instance.new("Frame")
    d.Size = UDim2.fromOffset(7, 7)
    d.Position = UDim2.fromOffset((i - 1) * 14, 0)
    d.BackgroundColor3 = col
    d.BorderSizePixel = 0
    d.Parent = Traffic

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = d
end

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, -60, 1, 0)
Header.Position = UDim2.fromOffset(55, 0)
Header.BackgroundTransparency = 1
Header.Text = "REAPER X SYSTEM"
Header.TextColor3 = Colors.White
Header.TextTransparency = 0.4
Header.TextSize = 10
Header.Font = Enum.Font.GothamBold
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.Parent = TopBar

local StatusArea = Instance.new("Frame")
StatusArea.Size = UDim2.new(1, -20, 1, -35)
StatusArea.Position = UDim2.fromOffset(10, 35)
StatusArea.BackgroundTransparency = 1
StatusArea.Parent = Main

local Indicator = Instance.new("Frame")
Indicator.Size = UDim2.fromOffset(6, 6)
Indicator.Position = UDim2.fromOffset(5, 11)
Indicator.BackgroundColor3 = Colors.TrafficGreen
Indicator.Parent = StatusArea

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = Indicator

local IndGlow = Instance.new("UIStroke")
IndGlow.Thickness = 3
IndGlow.Color = Colors.TrafficGreen
IndGlow.Transparency = 0.5
IndGlow.Parent = Indicator

local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(1, -20, 0, 15)
DistLabel.Position = UDim2.fromOffset(20, 5)
DistLabel.BackgroundTransparency = 1
DistLabel.Text = "Killer Distance : N/A"
DistLabel.TextColor3 = Colors.White
DistLabel.TextSize = 12
DistLabel.Font = Enum.Font.GothamBold
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = StatusArea

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 15)
StatusLabel.Position = UDim2.fromOffset(20, 23)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status : READY"
StatusLabel.TextColor3 = Colors.TrafficGreen
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusArea

local dragging = false
local dragStart
local startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging
        and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

local function GetRole(player)
    local team = player.Team
    local teamName = team and team.Name or "None"
    local lower = string.lower(teamName)

    if lower:find("killer")
        or lower:find("murder")
        or lower:find("beast") then
        return "Killer"
    end

    if lower:find("survivor")
        or lower:find("innocent")
        or lower:find("human") then
        return "Survivors"
    end

    return "Spectator"
end

local function IsDowned(character)
    if not character then
        return true
    end

    if character:GetAttribute("State") == "Downed" then
        return true
    end

    if character:GetAttribute("State") == "Dead" then
        return true
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health <= 0 then
        return true
    end

    return false
end

local function IsDirectionValid(killer, victim, attackCF)
    local kRoot = killer.PrimaryPart
    local vRoot = victim.PrimaryPart

    if not kRoot or not vRoot then
        return false
    end

    local offset = vRoot.Position - attackCF.Position

    if offset.Magnitude <= 0 then
        return true
    end

    local look = Vector3.new(
        attackCF.LookVector.X,
        0,
        attackCF.LookVector.Z
    )

    local target = Vector3.new(
        offset.X,
        0,
        offset.Z
    )

    if look.Magnitude <= 0 or target.Magnitude <= 0 then
        return false
    end

    return look.Unit:Dot(target.Unit) > 0.4
end

local function IsThreatening(killer, victim, range, attackCF)
    local kPart = killer.PrimaryPart

    if not kPart then
        return false
    end

    local kCF = attackCF or kPart.CFrame

    local angles = {
        -72.5,
        -60.4,
        -48.3,
        -36.25,
        -24.2,
        -12.1,
        0,
        12.1,
        24.2,
        36.25,
        48.3,
        60.4,
        72.5
    }

    local levels = {
        {
            offset = -1.8,
            pitch = math.rad(-15)
        },
        {
            offset = 0,
            pitch = 0
        },
        {
            offset = 1.8,
            pitch = math.rad(15)
        }
    }

    State.RayParams.FilterDescendantsInstances = {
        killer,
        workspace.CurrentCamera
    }

    for i = 1, #levels do
        local origin =
            (kCF * CFrame.new(0, levels[i].offset, 0)).Position

        for j = 1, #angles do
            local direction =
                (
                    kCF
                    * CFrame.Angles(
                        levels[i].pitch,
                        math.rad(angles[j]),
                        0
                    )
                ).LookVector

            local rayResult = workspace:Raycast(
                origin,
                direction * (range + 3),
                State.RayParams
            )

            if rayResult
                and rayResult.Instance
                and rayResult.Instance:IsDescendantOf(victim) then
                return true
            end
        end
    end

    return false
end

local function PerformInput()
    pcall(function()
        local survivorMob =
            LP.PlayerGui:FindFirstChild(
                "Survivor-mob",
                true
            )

        local mobBtn =
            survivorMob
            and survivorMob:FindFirstChild(
                "Gui-mob",
                true
            )

        if mobBtn and mobBtn.Visible then
            firesignal(mobBtn.MouseButton1Down)
        else
            VIM:SendMouseButtonEvent(
                0,
                0,
                1,
                true,
                game,
                0
            )

            task.wait(0.01)

            VIM:SendMouseButtonEvent(
                0,
                0,
                1,
                false,
                game,
                0
            )
        end
    end)
end

local function ExecuteParry()
    if State.Cooldown then
        return
    end

    State.Cooldown = true

    for i = 1, 8 do
        pcall(function()
            State.ParryRemote:FireServer()
        end)
    end

    PerformInput()
end

State.ResultRemote.OnClientEvent:Connect(function(_, cd)
    State.CurrentCD = tonumber(cd) or 0.8
    State.Cooldown = true
end)

local function CleanupAttack(track)
    local attack = State.ActiveAttacks[track]

    if not attack then
        return
    end

    attack.Active = false

    if attack.Connection then
        pcall(function()
            attack.Connection:Disconnect()
        end)
    end

    State.ActiveAttacks[track] = nil
end

local function StartAttackWindow(char, track)
    if State.ActiveAttacks[track] then
        return
    end

    if not Config.Enabled
        or State.Cooldown
        or GetRole(LP) ~= "Survivors" then
        return
    end

    local myChar = LP.Character

    if not myChar
        or IsDowned(myChar) then
        return
    end

    local kRoot = char.PrimaryPart
    local vRoot = myChar.PrimaryPart

    if not kRoot or not vRoot then
        return
    end

    local attackCF = kRoot.CFrame

    local attackState = {
        Active = true,
        AttackCF = attackCF,
        Connection = nil
    }

    State.ActiveAttacks[track] = attackState

    attackState.Connection = track.Ended:Connect(function()
        CleanupAttack(track)
    end)

    task.spawn(function()
        while attackState.Active
            and Config.Enabled
            and track
            and track.IsPlaying do

            local currentChar = LP.Character

            if not currentChar
                or IsDowned(currentChar) then
                break
            end

            local currentKRoot = char.PrimaryPart
            local currentVRoot = currentChar.PrimaryPart

            if not currentKRoot or not currentVRoot then
                break
            end

            local distance =
                (currentVRoot.Position - currentKRoot.Position).Magnitude

            if distance <= Config.Distance then
                if IsDirectionValid(
                    char,
                    currentChar,
                    attackState.AttackCF
                ) then

                    if IsThreatening(
                        char,
                        currentChar,
                        Config.Distance,
                        attackState.AttackCF
                    ) then

                        ExecuteParry()
                        break
                    end
                end
            end

            task.wait(Config.CheckInterval)
        end

        CleanupAttack(track)
    end)
end

local function AttachSensor(char)
    if not char or State.Connections[char] then
        return
    end

    local hum = char:WaitForChild(
        "Humanoid",
        10
    )

    if not hum then
        return
    end

    local animator = hum:WaitForChild(
        "Animator",
        10
    )

    if not animator then
        return
    end

    State.Connections[char] =
        animator.AnimationPlayed:Connect(function(track)

            if not Config.Enabled
                or State.Cooldown
                or GetRole(LP) ~= "Survivors" then
                return
            end

            if not track.Animation then
                return
            end

            local animationId =
                track.Animation.AnimationId:match("%d+")

            if not animationId then
                return
            end

            if not ATTACK_ANIMS[animationId] then
                return
            end

            StartAttackWindow(
                char,
                track
            )
        end)
end

local RangeAdorn =
    Instance.new(
        "CylinderHandleAdornment",
        workspace.Terrain
    )

RangeAdorn.Height = 0.1
RangeAdorn.Transparency = 0.5

RunService.RenderStepped:Connect(function(dt)
    if State.CurrentCD > 0 then
        State.CurrentCD =
            math.max(
                0,
                State.CurrentCD - dt
            )

        if State.CurrentCD <= 0 then
            State.Cooldown = false
        end
    end

    local myChar = LP.Character
    local myRole = GetRole(LP)

    Main.Visible = Config.ShowStatusUI

    if myChar and myChar.PrimaryPart then
        local myPos =
            myChar.PrimaryPart.Position

        local closestDist = 999

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP
                and p.Character
                and p.Character.PrimaryPart
                and GetRole(p) == "Killer" then

                local d =
                    (
                        myPos
                        - p.Character.PrimaryPart.Position
                    ).Magnitude

                if d < closestDist then
                    closestDist = d
                end
            end
        end

        if Config.ShowStatusUI then
            if myRole ~= "Survivors" then
                DistLabel.Text =
                    "Killer Distance : N/A"

                StatusLabel.Text =
                    "Status : N/A"

                StatusLabel.TextColor3 =
                    Colors.Muted

                Indicator.BackgroundColor3 =
                    Colors.Muted

                IndGlow.Color =
                    Colors.Muted
            else
                DistLabel.Text =
                    "Killer Distance : "
                    .. (
                        closestDist == 999
                        and "N/A"
                        or string.format(
                            "%.1f",
                            closestDist
                        )
                    )

                if State.CurrentCD > 0 then
                    StatusLabel.Text =
                        string.format(
                            "Status : CD (%.1fs)",
                            State.CurrentCD
                        )

                    StatusLabel.TextColor3 =
                        Colors.TrafficYellow

                    Indicator.BackgroundColor3 =
                        Colors.TrafficYellow
                else
                    StatusLabel.Text =
                        "Status : READY"

                    StatusLabel.TextColor3 =
                        Colors.TrafficGreen

                    Indicator.BackgroundColor3 =
                        Colors.TrafficGreen
                end

                IndGlow.Color =
                    Indicator.BackgroundColor3
            end
        end

        if Config.ShowCircle
            and myRole == "Survivors" then

            RangeAdorn.Visible = true

            RangeAdorn.Color3 =
                (
                    State.CurrentCD > 0
                    and Colors.TrafficYellow
                )
                or (
                    closestDist <= Config.Distance
                    and Colors.TrafficRed
                )
                or Colors.TrafficGreen

            RangeAdorn.Radius =
                Config.Distance

            RangeAdorn.InnerRadius =
                Config.Distance - 0.2

            RangeAdorn.Adornee =
                workspace.Terrain

            RangeAdorn.CFrame =
                CFrame.new(
                    myPos - Vector3.new(0, 2.9, 0)
                )
                * CFrame.Angles(
                    math.pi / 2,
                    0,
                    0
                )
        else
            RangeAdorn.Visible = false
        end
    end
end)

if Tabs and Tabs.Automatic then
    Tabs.Automatic:AddToggle(
        "AutoParry",
        {
            Title = "Auto Parry",
            Default = Config.Enabled,
            Callback = function(V)
                Config.Enabled = V

                if not V then
                    for track in pairs(State.ActiveAttacks) do
                        CleanupAttack(track)
                    end
                end
            end
        }
    )

    Tabs.Automatic:AddSlider(
        "ParryRange",
        {
            Title = "Parry Range",
            Default = Config.Distance,
            Min = 5,
            Max = 12,
            Rounding = 1,
            Callback = function(V)
                Config.Distance =
                    tonumber(V) or 9
            end
        }
    )

    Tabs.Automatic:AddToggle(
        "ShowRange",
        {
            Title = "Show Range Circle",
            Default = Config.ShowCircle,
            Callback = function(V)
                Config.ShowCircle = V
            end
        }
    )

    Tabs.Automatic:AddToggle(
        "ShowStatusUI",
        {
            Title = "Show Status UI",
            Default = Config.ShowStatusUI,
            Callback = function(V)
                Config.ShowStatusUI = V
            end
        }
    )
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            AttachSensor(char)
        end)

        if p.Character then
            task.spawn(function()
                AttachSensor(p.Character)
            end)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        AttachSensor(char)
    end)
end)

LP.CharacterAdded:Connect(function()
    for track in pairs(State.ActiveAttacks) do
        CleanupAttack(track)
    end

    State.Cooldown = false
    State.CurrentCD = 0
end)

-- Floating UI toggle
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
border.Size = UDim2.new(0, 0, 0, 0)
border.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
border.ZIndex = 1

local borderCorner = Instance.new("UICorner")
borderCorner.CornerRadius = UDim.new(0, 14)
borderCorner.Parent = border

local button = Instance.new("ImageButton")
button.Parent = gui
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(0, 60, 0.2, 0)
button.BackgroundTransparency = 1
button.ZIndex = 999999
button.AutoButtonColor = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button

local imgOn = "rbxassetid://86279908104891"
local imgOff = "rbxassetid://86279908104891"
button.Image = imgOn
button.ScaleType = Enum.ScaleType.Fit

local function UpdateBorder()
    local offset = (border.Size.X.Offset - button.Size.X.Offset) / 2
    border.Position = UDim2.new(
        button.Position.X.Scale,
        button.Position.X.Offset - offset,
        button.Position.Y.Scale,
        button.Position.Y.Offset - offset
    )
end

UpdateBorder()

local dragging = false
local dragStart, startPos

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        UpdateBorder()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
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
