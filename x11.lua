local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local DASH_ANIM = "98163597193511"

local State = {
    Running = false,
    Tracking = false,
    Killer = nil,
    Survivor = nil,
    Connection = nil,
    HealthConnection = nil,

    StartTime = 0,
    MovementStartTime = nil,
    EndTime = nil,

    StartPosition = nil,
    LastPosition = nil,
    EndPosition = nil,

    StartDistance = nil,
    MovementStartDistance = nil,
    DamageDistance = nil,

    TravelDistance = 0,
    MaxDistance = 0,
    MaxSpeed = 0,
    SpeedSum = 0,
    SpeedSamples = 0,

    LastTime = 0,
    LastHealth = nil,

    DamageDetected = false,
    DamageTime = nil,
    DamageAmount = nil,
    HealthBefore = nil,
    HealthAfter = nil,
    DamageKillerPosition = nil,
    DamageSurvivorPosition = nil
}

local function FindPlayer(text)
    text = tostring(text or ""):lower()
    if text == "" then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower() == text then
            return player
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.DisplayName:lower() == text then
            return player
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(text, 1, true) or player.DisplayName:lower():find(text, 1, true) then
            return player
        end
    end

    return nil
end

local function GetRoot(player)
    if not player or not player.Character then
        return nil
    end

    return player.Character:FindFirstChild("HumanoidRootPart")
        or player.Character.PrimaryPart
end

local function GetHumanoid(player)
    if not player or not player.Character then
        return nil
    end

    return player.Character:FindFirstChildOfClass("Humanoid")
end

local function IsDashPlaying(player)
    local humanoid = GetHumanoid(player)
    if not humanoid then
        return false
    end

    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        local animation = track.Animation

        if animation and animation.AnimationId then
            local id = animation.AnimationId:match("%d+")

            if id == DASH_ANIM then
                return true
            end
        end
    end

    return false
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ReaperDashTester"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(420, 650)
Main.Position = UDim2.new(0.5, -210, 0.5, -325)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 55, 65)
Stroke.Thickness = 1
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.fromOffset(10, 8)
Title.BackgroundTransparency = 1
Title.Text = "REAPER DASH TESTER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local function CreateLabel(text, x, y, w, h, size, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromOffset(w, h)
    label.Position = UDim2.fromOffset(x, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(220, 220, 225)
    label.TextSize = size or 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Main
    return label
end

local function CreateBox(y, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(270, 34)
    box.Position = UDim2.fromOffset(130, y)
    box.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(240, 240, 245)
    box.TextSize = 13
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = box

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(55, 55, 65)
    s.Thickness = 1
    s.Parent = box

    return box
end

CreateLabel("Killer", 20, 55, 100, 30, 13)
local KillerBox = CreateBox(53, "Username / Display Name")

CreateLabel("Survivor", 20, 98, 100, 30, 13)
local SurvivorBox = CreateBox(96, "Username / Display Name")

local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.fromOffset(130, 36)
StartButton.Position = UDim2.fromOffset(20, 140)
StartButton.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
StartButton.BorderSizePixel = 0
StartButton.Text = "START"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.TextSize = 13
StartButton.Font = Enum.Font.GothamBold
StartButton.Parent = Main

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 6)
StartCorner.Parent = StartButton

local ResetButton = Instance.new("TextButton")
ResetButton.Size = UDim2.fromOffset(130, 36)
ResetButton.Position = UDim2.fromOffset(160, 140)
ResetButton.BackgroundColor3 = Color3.fromRGB(120, 55, 55)
ResetButton.BorderSizePixel = 0
ResetButton.Text = "RESET"
ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetButton.TextSize = 13
ResetButton.Font = Enum.Font.GothamBold
ResetButton.Parent = Main

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 6)
ResetCorner.Parent = ResetButton

local Status = CreateLabel("STATUS: Idle", 20, 184, 380, 25, 13, Color3.fromRGB(180, 190, 205))

local function Section(text, y)
    local line = Instance.new("Frame")
    line.Size = UDim2.fromOffset(380, 1)
    line.Position = UDim2.fromOffset(20, y + 20)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    line.BorderSizePixel = 0
    line.Parent = Main

    CreateLabel(text, 20, y, 180, 25, 12, Color3.fromRGB(130, 135, 150))
end

local Values = {}

local function Stat(name, text, y)
    CreateLabel(name, 25, y, 170, 22, 12, Color3.fromRGB(155, 158, 170))

    local value = CreateLabel(text, 195, y, 205, 22, 12, Color3.fromRGB(235, 235, 240))
    value.TextXAlignment = Enum.TextXAlignment.Right

    Values[name] = value
    return value
end

Section("ANIMATION", 215)
Stat("Animation Start", "--", 238)
Stat("Animation Duration", "--", 260)
Stat("Movement Start", "--", 282)
Stat("Movement Delay", "--", 304)

Section("KILLER MOVEMENT", 330)
Stat("Start Distance", "--", 353)
Stat("Movement Distance", "--", 375)
Stat("Max Distance", "--", 397)
Stat("Max Speed", "--", 419)
Stat("Average Speed", "--", 441)

Section("SURVIVOR / DAMAGE", 467)
Stat("Victim", "--", 490)
Stat("Health Before", "--", 512)
Stat("Health After", "--", 534)
Stat("Damage Amount", "--", 556)
Stat("Damage Time", "--", 578)
Stat("Damage Distance", "--", 600)
Stat("Speed At Damage", "--", 622)

local function FormatNumber(value, digits)
    if value == nil then
        return "--"
    end

    return string.format("%." .. tostring(digits or 2) .. "f", value)
end

local function SetStatus(text)
    Status.Text = "STATUS: " .. text
end

local function ResetValues()
    for _, label in pairs(Values) do
        label.Text = "--"
    end

    Values["Victim"].Text = "--"
end

local function DisconnectHealth()
    if State.HealthConnection then
        State.HealthConnection:Disconnect()
        State.HealthConnection = nil
    end
end

local function ResetState()
    State.Running = false
    State.Tracking = false
    State.Killer = nil
    State.Survivor = nil

    State.StartTime = 0
    State.MovementStartTime = nil
    State.EndTime = nil

    State.StartPosition = nil
    State.LastPosition = nil
    State.EndPosition = nil

    State.StartDistance = nil
    State.MovementStartDistance = nil
    State.DamageDistance = nil

    State.TravelDistance = 0
    State.MaxDistance = 0
    State.MaxSpeed = 0
    State.SpeedSum = 0
    State.SpeedSamples = 0

    State.LastTime = 0
    State.LastHealth = nil

    State.DamageDetected = false
    State.DamageTime = nil
    State.DamageAmount = nil
    State.HealthBefore = nil
    State.HealthAfter = nil
    State.DamageKillerPosition = nil
    State.DamageSurvivorPosition = nil

    DisconnectHealth()
    ResetValues()
    SetStatus("Idle")
end

local function SetupHealthTracking()
    DisconnectHealth()

    local humanoid = GetHumanoid(State.Survivor)
    if not humanoid then
        return
    end

    State.LastHealth = humanoid.Health

    State.HealthConnection = humanoid.HealthChanged:Connect(function(newHealth)
        if not State.Tracking then
            State.LastHealth = newHealth
            return
        end

        local oldHealth = State.LastHealth or newHealth
        State.LastHealth = newHealth

        if State.DamageDetected then
            return
        end

        if newHealth >= oldHealth then
            return
        end

        local killerRoot = GetRoot(State.Killer)
        local survivorRoot = GetRoot(State.Survivor)

        State.DamageDetected = true
        State.DamageTime = os.clock() - State.StartTime
        State.DamageAmount = oldHealth - newHealth
        State.HealthBefore = oldHealth
        State.HealthAfter = newHealth

        if killerRoot and survivorRoot then
            State.DamageKillerPosition = killerRoot.Position
            State.DamageSurvivorPosition = survivorRoot.Position
            State.DamageDistance = (killerRoot.Position - survivorRoot.Position).Magnitude
        end

        Values["Victim"].Text = State.Survivor.Name
        Values["Health Before"].Text = FormatNumber(State.HealthBefore, 1)
        Values["Health After"].Text = FormatNumber(State.HealthAfter, 1)
        Values["Damage Amount"].Text = FormatNumber(State.DamageAmount, 1)
        Values["Damage Time"].Text = FormatNumber(State.DamageTime, 3) .. "s"
        Values["Damage Distance"].Text = FormatNumber(State.DamageDistance, 2)

        local damageSpeed = 0

        if State.LastPosition then
            local root = GetRoot(State.Killer)

            if root then
                local now = os.clock()
                local dt = now - State.LastTime

                if dt > 0 then
                    damageSpeed = (root.Position - State.LastPosition).Magnitude / dt
                end
            end
        end

        Values["Speed At Damage"].Text = FormatNumber(damageSpeed, 2)

        SetStatus("DAMAGE DETECTED")
    end)
end

local function StartTracking()
    local killer = FindPlayer(KillerBox.Text)
    local survivor = FindPlayer(SurvivorBox.Text)

    if not killer then
        SetStatus("Killer not found")
        return
    end

    if not survivor then
        SetStatus("Survivor not found")
        return
    end

    if killer == survivor then
        SetStatus("Killer and Survivor must be different")
        return
    end

    ResetState()

    State.Killer = killer
    State.Survivor = survivor
    State.Running = true
    State.Tracking = false

    SetupHealthTracking()

    SetStatus("Waiting for Dash...")
end

local function BeginDash()
    local killerRoot = GetRoot(State.Killer)
    local survivorRoot = GetRoot(State.Survivor)

    if not killerRoot or not survivorRoot then
        State.Running = false
        SetStatus("Character not ready")
        return
    end

    State.Tracking = true
    State.StartTime = os.clock()
    State.LastTime = State.StartTime

    State.StartPosition = killerRoot.Position
    State.LastPosition = killerRoot.Position
    State.EndPosition = killerRoot.Position

    State.StartDistance = (killerRoot.Position - survivorRoot.Position).Magnitude
    State.TravelDistance = 0
    State.MaxDistance = 0
    State.MaxSpeed = 0
    State.SpeedSum = 0
    State.SpeedSamples = 0

    Values["Animation Start"].Text = "0.000s"
    Values["Start Distance"].Text = FormatNumber(State.StartDistance, 2) .. " studs"

    SetStatus("Dash detected - tracking")

    SetupHealthTracking()
end

local function FinishDash()
    if not State.Tracking then
        return
    end

    State.Tracking = false
    State.EndTime = os.clock()

    local totalTime = State.EndTime - State.StartTime
    local averageSpeed = 0

    if State.SpeedSamples > 0 then
        averageSpeed = State.SpeedSum / State.SpeedSamples
    end

    Values["Animation Duration"].Text = FormatNumber(totalTime, 3) .. "s"
    Values["Movement Distance"].Text = FormatNumber(State.TravelDistance, 2) .. " studs"
    Values["Max Distance"].Text = FormatNumber(State.MaxDistance, 2) .. " studs"
    Values["Max Speed"].Text = FormatNumber(State.MaxSpeed, 2) .. " studs/s"
    Values["Average Speed"].Text = FormatNumber(averageSpeed, 2) .. " studs/s"

    if State.MovementStartTime then
        Values["Movement Start"].Text = FormatNumber(State.MovementStartTime - State.StartTime, 3) .. "s"
        Values["Movement Delay"].Text = FormatNumber(State.MovementStartTime - State.StartTime, 3) .. "s"
    end

    if State.DamageDetected then
        SetStatus("Complete - Damage detected")
    else
        SetStatus("Complete - No damage")
    end

    State.Running = false
    DisconnectHealth()
end

StartButton.MouseButton1Click:Connect(function()
    if State.Running then
        return
    end

    StartTracking()
end)

ResetButton.MouseButton1Click:Connect(function()
    ResetState()
end)

State.Connection = RunService.RenderStepped:Connect(function()
    if not State.Running then
        return
    end

    local killerRoot = GetRoot(State.Killer)
    local survivorRoot = GetRoot(State.Survivor)

    if not killerRoot or not survivorRoot then
        if State.Tracking then
            FinishDash()
        end

        SetStatus("Character lost")
        return
    end

    if not State.Tracking then
        if IsDashPlaying(State.Killer) then
            BeginDash()
        end

        return
    end

    local now = os.clock()
    local position = killerRoot.Position
    local survivorPosition = survivorRoot.Position

    local deltaTime = now - State.LastTime

    if deltaTime > 0 then
        local movement = (position - State.LastPosition).Magnitude

        if movement > 0 then
            State.TravelDistance += movement

            local speed = movement / deltaTime

            if speed > State.MaxSpeed then
                State.MaxSpeed = speed
            end

            State.SpeedSum += speed
            State.SpeedSamples += 1

            if not State.MovementStartTime and movement >= 0.025 then
                State.MovementStartTime = now

                Values["Movement Start"].Text =
                    FormatNumber(State.MovementStartTime - State.StartTime, 3) .. "s"

                Values["Movement Delay"].Text =
                    FormatNumber(State.MovementStartTime - State.StartTime, 3) .. "s"
            end
        end
    end

    local currentDistance = (position - State.StartPosition).Magnitude

    if currentDistance > State.MaxDistance then
        State.MaxDistance = currentDistance
    end

    State.LastPosition = position
    State.LastTime = now
    State.EndPosition = position

    if State.DamageDetected then
        if not IsDashPlaying(State.Killer) then
            FinishDash()
        end
    elseif not IsDashPlaying(State.Killer) then
        FinishDash()
    end
end)
