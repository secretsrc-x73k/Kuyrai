--// REAPER Invisible Test
--// Seat + Weld Prototype
--// Hidden position = current position - 20,000 studs

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local HIDDEN_DISTANCE = 20000
local FADE_TRANSPARENCY = 0.5

--==================================================
-- STATE
--==================================================

local Invisible = {
    Active = false,

    Character = nil,
    Humanoid = nil,
    Root = nil,
    Torso = nil,

    Seat = nil,
    Weld = nil,

    OriginalCFrame = nil,
    OriginalSpeed = nil,

    OriginalTransparency = {},

    Eye = nil,
    EyeLabel = nil,
    EyeConnection = nil
}

--==================================================
-- CHARACTER
--==================================================

local function GetCharacter()
    local Character = LocalPlayer.Character

    if not Character or not Character.Parent then
        return nil
    end

    return Character
end

--==================================================
-- SAVE TRANSPARENCY
--==================================================

local function SaveTransparency(Character)

    table.clear(Invisible.OriginalTransparency)

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object:IsA("BasePart")
        or Object:IsA("Decal") then

            if Object.Name ~= "HumanoidRootPart" then

                Invisible.OriginalTransparency[Object] =
                    Object.Transparency

            end
        end
    end
end

--==================================================
-- SET TRANSPARENCY
--==================================================

local function SetTransparency(Character, Value)

    if not Character then
        return
    end

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object:IsA("BasePart")
        or Object:IsA("Decal") then

            if Object.Name ~= "HumanoidRootPart" then

                pcall(function()
                    Object.Transparency = Value
                end)

            end
        end
    end
end

--==================================================
-- RESTORE TRANSPARENCY
--==================================================

local function RestoreTransparency()

    for Object, Transparency in pairs(
        Invisible.OriginalTransparency
    ) do

        if Object and Object.Parent then

            pcall(function()
                Object.Transparency = Transparency
            end)

        end
    end

    table.clear(Invisible.OriginalTransparency)
end

--==================================================
-- EYE INDICATOR
--==================================================

local function RemoveEye()

    if Invisible.EyeConnection then

        Invisible.EyeConnection:Disconnect()
        Invisible.EyeConnection = nil

    end

    if Invisible.Eye then

        pcall(function()
            Invisible.Eye:Destroy()
        end)

        Invisible.Eye = nil
        Invisible.EyeLabel = nil
    end
end

local function CreateEye(Character)

    RemoveEye()

    local Head = Character:FindFirstChild("Head")

    if not Head then
        return
    end

    local Billboard = Instance.new("BillboardGui")

    Billboard.Name = "REAPER_InvisibleEye"

    Billboard.Size =
        UDim2.fromOffset(42, 42)

    Billboard.StudsOffset =
        Vector3.new(0, 3, 0)

    Billboard.AlwaysOnTop = true
    Billboard.LightInfluence = 0
    Billboard.ResetOnSpawn = false

    Billboard.Parent = Head

    local Eye = Instance.new("TextLabel")

    Eye.Name = "Eye"

    Eye.BackgroundTransparency = 1

    Eye.Size =
        UDim2.fromScale(1, 1)

    Eye.Text = "◉"

    Eye.TextScaled = true

    Eye.Font =
        Enum.Font.GothamBold

    Eye.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Eye.TextTransparency = 0.2

    Eye.Parent = Billboard

    Invisible.Eye = Billboard
    Invisible.EyeLabel = Eye

    -- Slow blinking animation
    Invisible.EyeConnection =
        RunService.RenderStepped:Connect(function()

            if not Invisible.Active then
                return
            end

            if not Eye.Parent then
                return
            end

            local Alpha =
                (math.sin(os.clock() * 1.5) + 1) / 2

            Eye.TextTransparency =
                0.2 + (Alpha * 0.45)

        end)
end

--==================================================
-- CREATE SEAT
--==================================================

local function CreateSeat(CFrame)

    local Seat = Instance.new("Seat")

    Seat.Name =
        "REAPER_InvisibleSeat"

    Seat.Size =
        Vector3.new(0.1, 0.1, 0.1)

    Seat.CFrame = CFrame

    Seat.Anchored = false

    Seat.CanCollide = false
    Seat.CanTouch = false
    Seat.CanQuery = false

    Seat.Transparency = 1

    Seat.CastShadow = false

    Seat.Parent = Workspace

    return Seat
end

--==================================================
-- ENABLE
--==================================================

function Invisible.Enable()

    if Invisible.Active then
        return
    end

    local Character = GetCharacter()

    if not Character then
        warn("[REAPER Invisible] Character not found")
        return
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    local Root =
        Character:FindFirstChild("HumanoidRootPart")

    local Torso =
        Character:FindFirstChild("Torso")
        or Character:FindFirstChild("UpperTorso")

    if not Humanoid then
        warn("[REAPER Invisible] Humanoid not found")
        return
    end

    if not Root then
        warn("[REAPER Invisible] HumanoidRootPart not found")
        return
    end

    if not Torso then
        warn("[REAPER Invisible] Torso not found")
        return
    end

    --==================================================
    -- SAVE CURRENT STATE
    --==================================================

    Invisible.Character = Character
    Invisible.Humanoid = Humanoid
    Invisible.Root = Root
    Invisible.Torso = Torso

    Invisible.OriginalCFrame =
        Root.CFrame

    Invisible.OriginalSpeed =
        Humanoid.WalkSpeed

    SaveTransparency(Character)

    Invisible.Active = true

    --==================================================
    -- CALCULATE HIDDEN POSITION
    --==================================================

    local OriginalCFrame =
        Invisible.OriginalCFrame

    local HiddenCFrame =
        OriginalCFrame
        - Vector3.new(0, HIDDEN_DISTANCE, 0)

    --==================================================
    -- MOVE CHARACTER DOWN 20,000
    --==================================================

    Character:PivotTo(HiddenCFrame)

    task.wait(0.15)

    --==================================================
    -- CREATE INVISIBLE SEAT
    --==================================================

    local Seat =
        CreateSeat(HiddenCFrame)

    Invisible.Seat = Seat

    --==================================================
    -- WELD SEAT TO TORSO
    --==================================================

    local Weld =
        Instance.new("Weld")

    Weld.Name =
        "REAPER_InvisibleWeld"

    Weld.Part0 =
        Seat

    Weld.Part1 =
        Torso

    Weld.C0 =
        CFrame.new()

    Weld.C1 =
        CFrame.new()

    Weld.Parent =
        Seat

    Invisible.Weld = Weld

    task.wait()

    --==================================================
    -- MOVE SEAT BACK TO ORIGINAL POSITION
    --==================================================

    Seat.CFrame =
        OriginalCFrame

    task.wait()

    --==================================================
    -- FADE CHARACTER
    --==================================================

    SetTransparency(
        Character,
        FADE_TRANSPARENCY
    )

    --==================================================
    -- CREATE EYE
    --==================================================

    CreateEye(Character)

    print(
        "[REAPER Invisible] Enabled | Hidden Y = -"
        .. tostring(HIDDEN_DISTANCE)
    )
end

--==================================================
-- DISABLE
--==================================================

function Invisible.Disable()

    if not Invisible.Active then
        return
    end

    Invisible.Active = false

    -- Stop eye
    RemoveEye()

    -- Remove weld
    if Invisible.Weld then

        pcall(function()
            Invisible.Weld:Destroy()
        end)

        Invisible.Weld = nil
    end

    -- Remove seat
    if Invisible.Seat then

        pcall(function()
            Invisible.Seat:Destroy()
        end)

        Invisible.Seat = nil
    end

    local Character =
        Invisible.Character

    if Character and Character.Parent then

        -- Restore transparency
        RestoreTransparency()

        -- Restore position
        if Invisible.OriginalCFrame then

            pcall(function()

                Character:PivotTo(
                    Invisible.OriginalCFrame
                )

            end)

        end

        -- Restore speed
        local Humanoid =
            Character:FindFirstChildOfClass("Humanoid")

        if Humanoid
        and Invisible.OriginalSpeed then

            Humanoid.WalkSpeed =
                Invisible.OriginalSpeed

        end
    end

    Invisible.Character = nil
    Invisible.Humanoid = nil
    Invisible.Root = nil
    Invisible.Torso = nil

    Invisible.OriginalCFrame = nil
    Invisible.OriginalSpeed = nil

    table.clear(
        Invisible.OriginalTransparency
    )

    print("[REAPER Invisible] Disabled")
end

--==================================================
-- GUI
--==================================================

local PlayerGui =
    LocalPlayer:WaitForChild("PlayerGui")

local OldGui =
    PlayerGui:FindFirstChild(
        "REAPER_InvisibleTest"
    )

if OldGui then
    OldGui:Destroy()
end

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "REAPER_InvisibleTest"

ScreenGui.ResetOnSpawn = false

ScreenGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

ScreenGui.Parent =
    PlayerGui

--==================================================
-- MAIN BUTTON
--==================================================

local Button =
    Instance.new("TextButton")

Button.Name =
    "InvisibleToggle"

Button.Size =
    UDim2.fromOffset(210, 50)

Button.Position =
    UDim2.new(
        0.5,
        -105,
        0.8,
        0
    )

Button.BackgroundColor3 =
    Color3.fromRGB(30, 30, 30)

Button.BorderSizePixel = 0

Button.Text =
    "Invisible : OFF"

Button.TextColor3 =
    Color3.fromRGB(255, 255, 255)

Button.TextSize = 16

Button.Font =
    Enum.Font.GothamMedium

Button.AutoButtonColor = true

Button.Parent =
    ScreenGui

local ButtonCorner =
    Instance.new("UICorner")

ButtonCorner.CornerRadius =
    UDim.new(0, 9)

ButtonCorner.Parent =
    Button

--==================================================
-- STATUS LABEL
--==================================================

local Status =
    Instance.new("TextLabel")

Status.Name =
    "Status"

Status.Size =
    UDim2.fromOffset(300, 25)

Status.Position =
    UDim2.new(
        0.5,
        -150,
        0.8,
        55
    )

Status.BackgroundTransparency = 1

Status.Text =
    "Status: OFF"

Status.TextColor3 =
    Color3.fromRGB(190, 190, 190)

Status.TextSize = 14

Status.Font =
    Enum.Font.Gotham

Status.Parent =
    ScreenGui

--==================================================
-- UPDATE GUI
--==================================================

local function UpdateGUI()

    if Invisible.Active then

        Button.Text =
            "Invisible : ON"

        Button.BackgroundColor3 =
            Color3.fromRGB(45, 100, 65)

        Status.Text =
            "Status: ON | Hidden: -20,000"

    else

        Button.Text =
            "Invisible : OFF"

        Button.BackgroundColor3 =
            Color3.fromRGB(30, 30, 30)

        Status.Text =
            "Status: OFF"

    end
end

--==================================================
-- BUTTON
--==================================================

Button.MouseButton1Click:Connect(function()

    if Invisible.Active then

        Invisible.Disable()

    else

        Invisible.Enable()

    end

    UpdateGUI()
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterRemoving:Connect(function(Character)

    if Invisible.Active then
        Invisible.Disable()
        UpdateGUI()
    end

end)

--==================================================
-- INITIAL
--==================================================

UpdateGUI()

print("[REAPER Invisible Test] Loaded")--// REAPER Invisible Test
--// Seat + Weld Prototype
--// Hidden position = current position - 20,000 studs

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local HIDDEN_DISTANCE = 20000
local FADE_TRANSPARENCY = 0.5

--==================================================
-- STATE
--==================================================

local Invisible = {
    Active = false,

    Character = nil,
    Humanoid = nil,
    Root = nil,
    Torso = nil,

    Seat = nil,
    Weld = nil,

    OriginalCFrame = nil,
    OriginalSpeed = nil,

    OriginalTransparency = {},

    Eye = nil,
    EyeLabel = nil,
    EyeConnection = nil
}

--==================================================
-- CHARACTER
--==================================================

local function GetCharacter()
    local Character = LocalPlayer.Character

    if not Character or not Character.Parent then
        return nil
    end

    return Character
end

--==================================================
-- SAVE TRANSPARENCY
--==================================================

local function SaveTransparency(Character)

    table.clear(Invisible.OriginalTransparency)

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object:IsA("BasePart")
        or Object:IsA("Decal") then

            if Object.Name ~= "HumanoidRootPart" then

                Invisible.OriginalTransparency[Object] =
                    Object.Transparency

            end
        end
    end
end

--==================================================
-- SET TRANSPARENCY
--==================================================

local function SetTransparency(Character, Value)

    if not Character then
        return
    end

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object:IsA("BasePart")
        or Object:IsA("Decal") then

            if Object.Name ~= "HumanoidRootPart" then

                pcall(function()
                    Object.Transparency = Value
                end)

            end
        end
    end
end

--==================================================
-- RESTORE TRANSPARENCY
--==================================================

local function RestoreTransparency()

    for Object, Transparency in pairs(
        Invisible.OriginalTransparency
    ) do

        if Object and Object.Parent then

            pcall(function()
                Object.Transparency = Transparency
            end)

        end
    end

    table.clear(Invisible.OriginalTransparency)
end

--==================================================
-- EYE INDICATOR
--==================================================

local function RemoveEye()

    if Invisible.EyeConnection then

        Invisible.EyeConnection:Disconnect()
        Invisible.EyeConnection = nil

    end

    if Invisible.Eye then

        pcall(function()
            Invisible.Eye:Destroy()
        end)

        Invisible.Eye = nil
        Invisible.EyeLabel = nil
    end
end

local function CreateEye(Character)

    RemoveEye()

    local Head = Character:FindFirstChild("Head")

    if not Head then
        return
    end

    local Billboard = Instance.new("BillboardGui")

    Billboard.Name = "REAPER_InvisibleEye"

    Billboard.Size =
        UDim2.fromOffset(42, 42)

    Billboard.StudsOffset =
        Vector3.new(0, 3, 0)

    Billboard.AlwaysOnTop = true
    Billboard.LightInfluence = 0
    Billboard.ResetOnSpawn = false

    Billboard.Parent = Head

    local Eye = Instance.new("TextLabel")

    Eye.Name = "Eye"

    Eye.BackgroundTransparency = 1

    Eye.Size =
        UDim2.fromScale(1, 1)

    Eye.Text = "◉"

    Eye.TextScaled = true

    Eye.Font =
        Enum.Font.GothamBold

    Eye.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Eye.TextTransparency = 0.2

    Eye.Parent = Billboard

    Invisible.Eye = Billboard
    Invisible.EyeLabel = Eye

    -- Slow blinking animation
    Invisible.EyeConnection =
        RunService.RenderStepped:Connect(function()

            if not Invisible.Active then
                return
            end

            if not Eye.Parent then
                return
            end

            local Alpha =
                (math.sin(os.clock() * 1.5) + 1) / 2

            Eye.TextTransparency =
                0.2 + (Alpha * 0.45)

        end)
end

--==================================================
-- CREATE SEAT
--==================================================

local function CreateSeat(CFrame)

    local Seat = Instance.new("Seat")

    Seat.Name =
        "REAPER_InvisibleSeat"

    Seat.Size =
        Vector3.new(0.1, 0.1, 0.1)

    Seat.CFrame = CFrame

    Seat.Anchored = false

    Seat.CanCollide = false
    Seat.CanTouch = false
    Seat.CanQuery = false

    Seat.Transparency = 1

    Seat.CastShadow = false

    Seat.Parent = Workspace

    return Seat
end

--==================================================
-- ENABLE
--==================================================

function Invisible.Enable()

    if Invisible.Active then
        return
    end

    local Character = GetCharacter()

    if not Character then
        warn("[REAPER Invisible] Character not found")
        return
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    local Root =
        Character:FindFirstChild("HumanoidRootPart")

    local Torso =
        Character:FindFirstChild("Torso")
        or Character:FindFirstChild("UpperTorso")

    if not Humanoid then
        warn("[REAPER Invisible] Humanoid not found")
        return
    end

    if not Root then
        warn("[REAPER Invisible] HumanoidRootPart not found")
        return
    end

    if not Torso then
        warn("[REAPER Invisible] Torso not found")
        return
    end

    --==================================================
    -- SAVE CURRENT STATE
    --==================================================

    Invisible.Character = Character
    Invisible.Humanoid = Humanoid
    Invisible.Root = Root
    Invisible.Torso = Torso

    Invisible.OriginalCFrame =
        Root.CFrame

    Invisible.OriginalSpeed =
        Humanoid.WalkSpeed

    SaveTransparency(Character)

    Invisible.Active = true

    --==================================================
    -- CALCULATE HIDDEN POSITION
    --==================================================

    local OriginalCFrame =
        Invisible.OriginalCFrame

    local HiddenCFrame =
        OriginalCFrame
        - Vector3.new(0, HIDDEN_DISTANCE, 0)

    --==================================================
    -- MOVE CHARACTER DOWN 20,000
    --==================================================

    Character:PivotTo(HiddenCFrame)

    task.wait(0.15)

    --==================================================
    -- CREATE INVISIBLE SEAT
    --==================================================

    local Seat =
        CreateSeat(HiddenCFrame)

    Invisible.Seat = Seat

    --==================================================
    -- WELD SEAT TO TORSO
    --==================================================

    local Weld =
        Instance.new("Weld")

    Weld.Name =
        "REAPER_InvisibleWeld"

    Weld.Part0 =
        Seat

    Weld.Part1 =
        Torso

    Weld.C0 =
        CFrame.new()

    Weld.C1 =
        CFrame.new()

    Weld.Parent =
        Seat

    Invisible.Weld = Weld

    task.wait()

    --==================================================
    -- MOVE SEAT BACK TO ORIGINAL POSITION
    --==================================================

    Seat.CFrame =
        OriginalCFrame

    task.wait()

    --==================================================
    -- FADE CHARACTER
    --==================================================

    SetTransparency(
        Character,
        FADE_TRANSPARENCY
    )

    --==================================================
    -- CREATE EYE
    --==================================================

    CreateEye(Character)

    print(
        "[REAPER Invisible] Enabled | Hidden Y = -"
        .. tostring(HIDDEN_DISTANCE)
    )
end

--==================================================
-- DISABLE
--==================================================

function Invisible.Disable()

    if not Invisible.Active then
        return
    end

    Invisible.Active = false

    -- Stop eye
    RemoveEye()

    -- Remove weld
    if Invisible.Weld then

        pcall(function()
            Invisible.Weld:Destroy()
        end)

        Invisible.Weld = nil
    end

    -- Remove seat
    if Invisible.Seat then

        pcall(function()
            Invisible.Seat:Destroy()
        end)

        Invisible.Seat = nil
    end

    local Character =
        Invisible.Character

    if Character and Character.Parent then

        -- Restore transparency
        RestoreTransparency()

        -- Restore position
        if Invisible.OriginalCFrame then

            pcall(function()

                Character:PivotTo(
                    Invisible.OriginalCFrame
                )

            end)

        end

        -- Restore speed
        local Humanoid =
            Character:FindFirstChildOfClass("Humanoid")

        if Humanoid
        and Invisible.OriginalSpeed then

            Humanoid.WalkSpeed =
                Invisible.OriginalSpeed

        end
    end

    Invisible.Character = nil
    Invisible.Humanoid = nil
    Invisible.Root = nil
    Invisible.Torso = nil

    Invisible.OriginalCFrame = nil
    Invisible.OriginalSpeed = nil

    table.clear(
        Invisible.OriginalTransparency
    )

    print("[REAPER Invisible] Disabled")
end

--==================================================
-- GUI
--==================================================

local PlayerGui =
    LocalPlayer:WaitForChild("PlayerGui")

local OldGui =
    PlayerGui:FindFirstChild(
        "REAPER_InvisibleTest"
    )

if OldGui then
    OldGui:Destroy()
end

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "REAPER_InvisibleTest"

ScreenGui.ResetOnSpawn = false

ScreenGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

ScreenGui.Parent =
    PlayerGui

--==================================================
-- MAIN BUTTON
--==================================================

local Button =
    Instance.new("TextButton")

Button.Name =
    "InvisibleToggle"

Button.Size =
    UDim2.fromOffset(210, 50)

Button.Position =
    UDim2.new(
        0.5,
        -105,
        0.8,
        0
    )

Button.BackgroundColor3 =
    Color3.fromRGB(30, 30, 30)

Button.BorderSizePixel = 0

Button.Text =
    "Invisible : OFF"

Button.TextColor3 =
    Color3.fromRGB(255, 255, 255)

Button.TextSize = 16

Button.Font =
    Enum.Font.GothamMedium

Button.AutoButtonColor = true

Button.Parent =
    ScreenGui

local ButtonCorner =
    Instance.new("UICorner")

ButtonCorner.CornerRadius =
    UDim.new(0, 9)

ButtonCorner.Parent =
    Button

--==================================================
-- STATUS LABEL
--==================================================

local Status =
    Instance.new("TextLabel")

Status.Name =
    "Status"

Status.Size =
    UDim2.fromOffset(300, 25)

Status.Position =
    UDim2.new(
        0.5,
        -150,
        0.8,
        55
    )

Status.BackgroundTransparency = 1

Status.Text =
    "Status: OFF"

Status.TextColor3 =
    Color3.fromRGB(190, 190, 190)

Status.TextSize = 14

Status.Font =
    Enum.Font.Gotham

Status.Parent =
    ScreenGui

--==================================================
-- UPDATE GUI
--==================================================

local function UpdateGUI()

    if Invisible.Active then

        Button.Text =
            "Invisible : ON"

        Button.BackgroundColor3 =
            Color3.fromRGB(45, 100, 65)

        Status.Text =
            "Status: ON | Hidden: -20,000"

    else

        Button.Text =
            "Invisible : OFF"

        Button.BackgroundColor3 =
            Color3.fromRGB(30, 30, 30)

        Status.Text =
            "Status: OFF"

    end
end

--==================================================
-- BUTTON
--==================================================

Button.MouseButton1Click:Connect(function()

    if Invisible.Active then

        Invisible.Disable()

    else

        Invisible.Enable()

    end

    UpdateGUI()
end)

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterRemoving:Connect(function(Character)

    if Invisible.Active then
        Invisible.Disable()
        UpdateGUI()
    end

end)

--==================================================
-- INITIAL
--==================================================

UpdateGUI()

print("[REAPER Invisible Test] Loaded")
