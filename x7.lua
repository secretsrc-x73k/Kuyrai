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

    local Head =
        Character:FindFirstChild("Head")

    if not Head then
        return
    end

    local Billboard =
        Instance.new("BillboardGui")

    Billboard.Name =
        "REAPER_InvisibleEye"

    Billboard.Size =
        UDim2.fromOffset(42, 42)

    Billboard.StudsOffset =
        Vector3.new(0, 3, 0)

    Billboard.AlwaysOnTop = true
    Billboard.LightInfluence = 0
    Billboard.ResetOnSpawn = false

    Billboard.Parent = Head

    local Eye =
        Instance.new("TextLabel")

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

    local Seat =
        Instance.new("Seat")

    Seat.Name =
        "REAPER_InvisibleSeat"

    Seat.Size =
        Vector3.new(0.1, 0.1, 0.1)

    Seat.CFrame =
        CFrame

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

    local Character =
        GetCharacter()

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
    -- SAVE STATE
    --==================================================

    Invisible.Character = Character
    Invisible.Humanoid = Humanoid
    Invisible.Root = Root
    Invisible.Torso = Torso

    Invisible.OriginalSpeed =
        Humanoid.WalkSpeed

    SaveTransparency(Character)

    Invisible.Active = true

    --==================================================
    -- SAVE START POSITION
    --==================================================

    local StartCFrame =
        Root.CFrame

    --==================================================
    -- HIDDEN POSITION
    -- CURRENT POSITION - 20,000
    --==================================================

    local HiddenCFrame =
        StartCFrame
        - Vector3.new(0, HIDDEN_DISTANCE, 0)

    --==================================================
    -- MOVE CHARACTER DOWN
    --==================================================

    Character:PivotTo(
        HiddenCFrame
    )

    task.wait(0.15)

    --==================================================
    -- CREATE SEAT AT HIDDEN POSITION
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
    -- RETURN SEAT TO START POSITION
    --==================================================

    Seat.CFrame =
        StartCFrame

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
        "[REAPER Invisible] ENABLED"
    )
end

--==================================================
-- DISABLE
--==================================================

function Invisible.Disable()

    if not Invisible.Active then
        return
    end

    --==================================================
    -- IMPORTANT:
    -- GET THE LATEST POSITION BEFORE DESTROYING
    -- THE WELD / SEAT
    --==================================================

    local ReturnCFrame = nil

    if Invisible.Seat
    and Invisible.Seat.Parent then

        ReturnCFrame =
            Invisible.Seat.CFrame

    elseif Invisible.Root
    and Invisible.Root.Parent then

        ReturnCFrame =
            Invisible.Root.CFrame

    end

    -- Stop active state
    Invisible.Active = false

    --==================================================
    -- REMOVE EYE
    --==================================================

    RemoveEye()

    --==================================================
    -- REMOVE WELD
    --==================================================

    if Invisible.Weld then

        pcall(function()
            Invisible.Weld:Destroy()
        end)

        Invisible.Weld = nil
    end

    --==================================================
    -- REMOVE SEAT
    --==================================================

    if Invisible.Seat then

        pcall(function()
            Invisible.Seat:Destroy()
        end)

        Invisible.Seat = nil
    end

    --==================================================
    -- RESTORE CHARACTER
    --==================================================

    local Character =
        Invisible.Character

    if Character
    and Character.Parent then

        -- Restore visual state
        RestoreTransparency()

        --==================================================
        -- RETURN TO LAST POSITION
        -- NOT THE POSITION WHEN INVISIBLE WAS ENABLED
        --==================================================

        if ReturnCFrame then

            pcall(function()

                Character:PivotTo(
                    ReturnCFrame
                )

            end)

        end

        --==================================================
        -- RESTORE SPEED
        --==================================================

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

    Invisible.OriginalSpeed = nil

    table.clear(
        Invisible.OriginalTransparency
    )

    print(
        "[REAPER Invisible] DISABLED"
    )
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
-- BUTTON
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
-- STATUS
--==================================================

local Status =
    Instance.new("TextLabel")

Status.Name =
    "Status"

Status.Size =
    UDim2.fromOffset(320, 25)

Status.Position =
    UDim2.new(
        0.5,
        -160,
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
-- BUTTON EVENT
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
-- CHARACTER REMOVING
--==================================================

LocalPlayer.CharacterRemoving:Connect(function()

    if Invisible.Active then

        Invisible.Disable()
        UpdateGUI()

    end

end)

--==================================================
-- INITIALIZE
--==================================================

UpdateGUI()

print("[REAPER Invisible Test] Loaded")
