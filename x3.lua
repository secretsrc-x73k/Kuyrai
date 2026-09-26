local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local NewUI_URL =
    "https://raw.githubusercontent.com/secretsrc-x73k/NewUI/refs/heads/main/newui.lua"

local NewUI

do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(NewUI_URL))()
    end)

    if not success then
        warn("[Eddie's Invisible] Failed to load NewUI:")
        warn(result)
        return
    end

    NewUI = result
end

if not NewUI then
    warn("[Eddie's Invisible] NewUI is nil")
    return
end

local Character
local Humanoid
local HRP

local CharacterConnections = {}

local function DisconnectCharacterConnections()
    for _, connection in ipairs(CharacterConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(CharacterConnections)
end

local function UpdateCharacter(char)
    if not char then
        return
    end

    DisconnectCharacterConnections()

    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")

    task.wait(0.1)
end

local State = {
    Invisible = false,
    UIKey = Enum.KeyCode.Q,
    ToggleKey = Enum.KeyCode.G,
    UIVisible = true,
    Destroyed = false
}

local BodyParts = {}

local function collectParts()
    table.clear(BodyParts)

    if not Character then
        return
    end

    for _, obj in ipairs(Character:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            table.insert(BodyParts, {
                Object = obj,
                Transparency = obj.Transparency
            })
        end
    end
end

local function applyInvisible()
    for _, data in ipairs(BodyParts) do
        local part = data.Object

        if part and part.Parent then
            if State.Invisible then
                part.Transparency = 0.5
            else
                part.Transparency = data.Transparency or 0
            end
        end
    end
end

local function RefreshCharacter()
    if not Character then
        return
    end

    collectParts()
    applyInvisible()
end

local function DestroyOldGUI()
    local names = {
        "EddiesInvisible",
        "EddiesInvisibleGUI",
        "EIU",
        "EIU_GUI",
        "EddieInvisible",
        "EddieInvisibleGUI"
    }

    for _, name in ipairs(names) do
        pcall(function()
            local object = CoreGui:FindFirstChild(name)

            if object then
                object:Destroy()
            end
        end)

        pcall(function()
            local playerGui =
                LocalPlayer:FindFirstChildOfClass("PlayerGui")

            if playerGui then
                local object = playerGui:FindFirstChild(name)

                if object then
                    object:Destroy()
                end
            end
        end)
    end
end

DestroyOldGUI()

local StatusText = "Disabled"

local function SetStatus(value)
    StatusText = value
end

local Window

do
    local success, result = pcall(function()
        return NewUI:CreateWindow({
            Title = "Eddie's Invisible",
            SubTitle = "Universal",
            TabWidth = 160,
            Size = UDim2.fromOffset(580, 460),
            Theme = "ExtremeReaper",
            MinimizeKey = State.UIKey
        })
    end)

    if not success then
        warn("[Eddie's Invisible] Failed to create Window:")
        warn(result)
        return
    end

    Window = result
end

if not Window then
    warn("[Eddie's Invisible] Window creation failed.")
    return
end

local Tabs = {
    Main = Window:AddTab({
        Title = "Main",
        Icon = "eye"
    }),

    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}

local MainTab = Tabs.Main

MainTab:AddParagraph({
    Title = "Eddie's Invisible",
    Content =
        "Universal invisibility system with mobile and PC support."
})

local InvisibleToggle

InvisibleToggle = MainTab:AddToggle(
    "Invisible",
    {
        Title = "Invisibility",
        Description =
            "Enable or disable player invisibility.",
        Default = false,

        Callback = function(Value)
            State.Invisible = Value

            if Value then
                SetStatus("Enabled")
            else
                SetStatus("Disabled")
            end

            applyInvisible()
        end
    }
)

local ToggleKeybind

pcall(function()
    ToggleKeybind = MainTab:AddKeybind(
        "InvisibleKey",
        {
            Title = "Toggle Key",
            Description =
                "Key used to toggle invisibility.",
            Default = "G",
            Mode = "Toggle",

            Callback = function()
                InvisibleToggle:SetValue(
                    not InvisibleToggle.Value
                )
            end,

            ChangedCallback = function(Key)
                if typeof(Key) == "EnumItem" then
                    State.ToggleKey = Key
                end
            end
        }
    )
end)

local StatusParagraph

pcall(function()
    StatusParagraph = MainTab:AddParagraph({
        Title = "Status",
        Content = "Disabled"
    })
end)

task.spawn(function()
    while not State.Destroyed do
        if StatusParagraph then
            pcall(function()
                StatusParagraph:SetDesc(
                    "Current status: " .. StatusText
                )
            end)
        end

        task.wait(0.25)
    end
end)

MainTab:AddButton({
    Title = "Refresh Character",
    Description =
        "Re-scan your character body parts.",

    Callback = function()
        collectParts()
        applyInvisible()

        pcall(function()
            NewUI:Notify({
                Title = "Eddie's Invisible",
                Content = "Character refreshed.",
                Duration = 2
            })
        end)
    end
})

local SettingsTab = Tabs.Settings

SettingsTab:AddParagraph({
    Title = "Controls",
    Content =
        "G = Toggle Invisibility\nQ = Minimize UI"
})

pcall(function()
    SettingsTab:AddKeybind(
        "UIKeybind",
        {
            Title = "UI Keybind",
            Description =
                "Key used to minimize the interface.",
            Default = "Q",
            Mode = "Toggle",

            Callback = function()
                State.UIVisible =
                    not State.UIVisible
            end,

            ChangedCallback = function(Key)
                if typeof(Key) == "EnumItem" then
                    State.UIKey = Key
                end
            end
        }
    )
end)

repeat
    task.wait()
until LocalPlayer.Character

UpdateCharacter(LocalPlayer.Character)
collectParts()

local FloatGui = Instance.new("ScreenGui")

FloatGui.Name =
    "EddiesInvisibleFloat"

FloatGui.ResetOnSpawn = false
FloatGui.IgnoreGuiInset = true
FloatGui.Parent = CoreGui

local FloatButton = Instance.new("TextButton")

FloatButton.Name =
    "FloatingButton"

FloatButton.Size =
    UDim2.fromOffset(58, 58)

FloatButton.Position =
    UDim2.new(
        1,
        -75,
        0.5,
        0
    )

FloatButton.AnchorPoint =
    Vector2.new(0.5, 0.5)

FloatButton.BackgroundColor3 =
    Color3.fromRGB(20, 20, 25)

FloatButton.Text = "EI"
FloatButton.TextColor3 =
    Color3.fromRGB(240, 240, 245)

FloatButton.TextSize = 16
FloatButton.Font = Enum.Font.GothamBold
FloatButton.BorderSizePixel = 0
FloatButton.AutoButtonColor = true
FloatButton.Parent = FloatGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius =
    UDim.new(0, 29)
Corner.Parent = FloatButton

local LastTap = 0
local DoubleTapDelay = 0.3

FloatButton.MouseButton1Click:Connect(function()
    local now = os.clock()

    if now - LastTap <= DoubleTapDelay then
        State.UIVisible =
            not State.UIVisible

        LastTap = 0
    else
        LastTap = now

        InvisibleToggle:SetValue(
            not InvisibleToggle.Value
        )
    end
end)

local Dragging = false
local DragStart
local StartPosition

local function UpdateDrag(input)
    local Delta =
        input.Position - DragStart

    FloatButton.Position =
        UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
end

FloatButton.InputBegan:Connect(function(input)
    if
        input.UserInputType ==
            Enum.UserInputType.MouseButton1
        or
        input.UserInputType ==
            Enum.UserInputType.Touch
    then
        Dragging = true
        DragStart = input.Position
        StartPosition = FloatButton.Position
    end
end)

FloatButton.InputChanged:Connect(function(input)
    if
        input.UserInputType ==
            Enum.UserInputType.MouseMovement
        or
        input.UserInputType ==
            Enum.UserInputType.Touch
    then
        local connection

        connection =
            UserInputService.InputChanged:Connect(
                function(changed)
                    if
                        changed == input
                        and Dragging
                    then
                        UpdateDrag(changed)
                    end
                end
            )

        task.delay(0.5, function()
            if connection then
                connection:Disconnect()
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if
        input.UserInputType ==
            Enum.UserInputType.MouseButton1
        or
        input.UserInputType ==
            Enum.UserInputType.Touch
    then
        Dragging = false
    end
end)

UserInputService.InputBegan:Connect(
    function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == State.ToggleKey then
            InvisibleToggle:SetValue(
                not InvisibleToggle.Value
            )
        end

        if input.KeyCode == State.UIKey then
            State.UIVisible =
                not State.UIVisible
        end
    end
)

RunService.Heartbeat:Connect(function()
    if State.Destroyed then
        return
    end

    if not State.Invisible then
        return
    end

    local character = Character

    local root =
        character
        and character:FindFirstChild(
            "HumanoidRootPart"
        )

    local humanoid =
        character
        and character:FindFirstChildOfClass(
            "Humanoid"
        )

    if not root or not humanoid then
        return
    end

    local originalCFrame =
        root.CFrame

    local originalCameraOffset =
        humanoid.CameraOffset

    local hiddenCFrame =
        originalCFrame
        * CFrame.new(
            0,
            -200000,
            0
        )

    local cameraOffset =
        hiddenCFrame:ToObjectSpace(
            CFrame.new(
                originalCFrame.Position
            )
        ).Position

    root.CFrame =
        hiddenCFrame

    humanoid.CameraOffset =
        cameraOffset

    RunService.RenderStepped:Wait()

    if root and root.Parent then
        root.CFrame =
            originalCFrame
    end

    if humanoid and humanoid.Parent then
        humanoid.CameraOffset =
            originalCameraOffset
    end
end)

LocalPlayer.CharacterAdded:Connect(
    function(char)
        State.Invisible = false

        pcall(function()
            InvisibleToggle:SetValue(false)
        end)

        UpdateCharacter(char)

        task.wait(0.5)

        collectParts()
        applyInvisible()
    end
)

LocalPlayer.CharacterRemoving:Connect(
    function()
        Character = nil
        Humanoid = nil
        HRP = nil

        table.clear(BodyParts)
    end
)

State.Invisible = false

pcall(function()
    InvisibleToggle:SetValue(false)
end)

collectParts()

task.delay(1, function()
    pcall(function()
        NewUI:Notify({
            Title = "Eddie's Invisible",
            Content =
                "Universal Edition loaded successfully.",
            Duration = 3
        })
    end)
end)

local function Cleanup()
    if State.Destroyed then
        return
    end

    State.Destroyed = true
    State.Invisible = false

    DisconnectCharacterConnections()

    pcall(function()
        InvisibleToggle:SetValue(false)
    end)

    pcall(function()
        FloatGui:Destroy()
    end)

    pcall(function()
        if NewUI.Destroy then
            NewUI:Destroy()
        end
    end)
end

getgenv().EddiesInvisibleCleanup = Cleanup

print(
    "[Eddie's Invisible] NewUI Edition loaded."
)
