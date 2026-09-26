--2
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local NewUI_URL =
    "https://raw.githubusercontent.com/secretsrc-x73k/NewUI/refs/heads/main/newui.lua"

local function LoadUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet(NewUI_URL))()
    end)

    if not success then
        warn("[Eddie's Invisible] Failed to load NewUI:")
        warn(result)
        return nil
    end

    return result
end

local UI = LoadUI()

if not UI then
    return
end

local function CleanupOldUI()
    pcall(function()
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name == "EIU_GUI"
                or gui.Name == "EIU_Float"
                or gui.Name == "EIU_Loader"
            then
                gui:Destroy()
            end
        end
    end)

    pcall(function()
        local PlayerGui =
            LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if PlayerGui then
            for _, gui in ipairs(PlayerGui:GetChildren()) do
                if gui.Name == "EIU_GUI"
                    or gui.Name == "EIU_Float"
                    or gui.Name == "EIU_Loader"
                then
                    gui:Destroy()
                end
            end
        end
    end)
end

CleanupOldUI()

repeat
    task.wait()
until LocalPlayer.Character

local Character = LocalPlayer.Character
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local State = {
    Invisible = false,
    Running = false,
    Destroyed = false,
    LastCycle = 0
}

local bodyParts = {}

local function collectParts()
    bodyParts = {}

    if not Character then
        return
    end

    for _, d in ipairs(Character:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency == 0 then
            table.insert(bodyParts, d)
        end
    end
end

local function applyInvisible()
    for _, p in ipairs(bodyParts) do
        if p and p.Parent then
            p.Transparency = State.Invisible and 0.5 or 0
        end
    end
end

local function RestoreCharacter()
    for _, p in ipairs(bodyParts) do
        if p and p.Parent then
            p.Transparency = 0
        end
    end
end

local function InvisibleCycle()
    if not State.Invisible then
        return false
    end

    local root =
        Character
        and Character:FindFirstChild("HumanoidRootPart")

    local hum =
        Character
        and Character:FindFirstChildOfClass("Humanoid")

    if not root or not hum then
        return false
    end

    local camCF = root.CFrame
    local camOffset = hum.CameraOffset

    local hidden =
        camCF * CFrame.new(0, -200000, 0)

    local pos =
        hidden:ToObjectSpace(
            CFrame.new(camCF.Position)
        ).Position

    root.CFrame = hidden
    hum.CameraOffset = pos

    RunService.RenderStepped:Wait()

    if root and root.Parent then
        root.CFrame = camCF
    end

    if hum and hum.Parent then
        hum.CameraOffset = camOffset
    end

    State.LastCycle = os.clock()
    State.Running = true

    return true
end

local function StartInvisible()
    if State.Destroyed then
        return
    end

    if not Character then
        return
    end

    collectParts()
    applyInvisible()

    State.Invisible = true
end

local function StopInvisible()
    State.Invisible = false
    State.Running = false

    RestoreCharacter()
end

local function SetInvisible(value)
    if value then
        StartInvisible()
    else
        StopInvisible()
    end
end

local Window

do
    local success, result = pcall(function()
        return UI:CreateWindow({
            Title = "Eddie's Invisible",
            SubTitle = "Universal",
            TabWidth = 160,
            Size = UDim2.fromOffset(580, 460),
            Theme = "Dark",
            MinimizeKey = Enum.KeyCode.RightControl
        })
    end)

    if not success then
        warn("[Eddie's Invisible] Failed to create UI:")
        warn(result)
        return
    end

    Window = result
end

if not Window then
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

Tabs.Main:AddParagraph({
    Title = "Eddie's Invisible",
    Content = "Universal Invisibility"
})

local StatusParagraph = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = "Disabled"
})

local InvisibleToggle = Tabs.Main:AddToggle(
    "InvisibleToggle",
    {
        Title = "Invisibility",
        Description = "Automatically maintains invisibility",
        Default = false
    }
)

local function UpdateStatus()
    pcall(function()
        if State.Invisible then
            if State.Running then
                StatusParagraph:SetDesc("Active")
            else
                StatusParagraph:SetDesc("Starting...")
            end
        else
            StatusParagraph:SetDesc("Disabled")
        end
    end)
end

InvisibleToggle:OnChanged(function(Value)
    SetInvisible(Value)
    UpdateStatus()
end)

Tabs.Main:AddButton({
    Title = "Refresh",
    Description = "Re-scan character parts",

    Callback = function()
        if Character then
            collectParts()

            if State.Invisible then
                applyInvisible()
            else
                RestoreCharacter()
            end
        end

        UpdateStatus()
    end
})

Tabs.Settings:AddParagraph({
    Title = "Auto System",
    Content =
        "Invisibility automatically resumes after respawn and attempts to recover if the engine stops."
})

Tabs.Settings:AddParagraph({
    Title = "Status",
    Content =
        "No keyboard shortcut is required."
})

RunService.Heartbeat:Connect(function()
    if State.Destroyed then
        return
    end

    if not State.Invisible then
        return
    end

    InvisibleCycle()
end)

task.spawn(function()
    while not State.Destroyed do
        task.wait(0.5)

        if State.Invisible then
            local elapsed =
                os.clock() - State.LastCycle

            if elapsed > 1 then
                State.Running = false

                collectParts()
                applyInvisible()

                UpdateStatus()
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char

    Humanoid =
        char:WaitForChild("Humanoid")

    HRP =
        char:WaitForChild("HumanoidRootPart")

    State.Running = false
    State.LastCycle = 0

    task.wait(0.5)

    collectParts()

    if State.Invisible then
        applyInvisible()
        UpdateStatus()
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    State.Running = false
    State.LastCycle = 0

    Character = nil
    Humanoid = nil
    HRP = nil

    bodyParts = {}
end)

collectParts()

State.Invisible = false
State.Running = false

pcall(function()
    InvisibleToggle:SetValue(false)
end)

UpdateStatus()

print("[Eddie's Invisible] Loaded")
