local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "HyperX | Anti-Hook System",
    SubTitle = "Fluent Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 320),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "shield" })
}

local function InitAntiHook()
local Options = Fluent.Options
local AntiHookData = {
    Enabled = false,
    CarriedOnly = true,
    OffsetY = -250,
    Hz = 60,
    Connection = nil,
    LastSend = 0,
    Remote = nil
}

local function FindRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameRemotes = remotes and remotes:FindFirstChild("Game")
    AntiHookData.Remote = gameRemotes and gameRemotes:FindFirstChild("UpdateCharacterLook")
    return AntiHookData.Remote
end

local function IsCarried(char)
    return char and char:GetAttribute("IsCarried") == true
end

local function SendAntiHookPacket()
    local remote = AntiHookData.Remote or FindRemote()
    if not remote or not localPlayer.Character then return end
    
    local cfBase = CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    local cfOffset = CFrame.new(0, AntiHookData.OffsetY, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

    pcall(function()
        remote:FireServer(cfBase, cfOffset, cfOffset, cfOffset, cfOffset)
    end)
end

local function UpdateAntiHook()
    if not AntiHookData.Enabled then return end
    local char = localPlayer.Character
    if not char then return end

    local shouldSend = true
    if AntiHookData.CarriedOnly then
        shouldSend = IsCarried(char)
    end

    if shouldSend then
        local now = os.clock()
        if (now - AntiHookData.LastSend) >= (1 / math.max(1, AntiHookData.Hz)) then
            AntiHookData.LastSend = now
            SendAntiHookPacket()
        end
    end
end

-- // UI Elements
local Sectionantihook = Tabs.Main:AddSection("Anti Hook")

Sectionantihook:AddToggle("AntiHookEnabled", {
     Title = "Enable Anti-Hook", 
     Default = false})
MainToggle:OnChanged(function()
    AntiHookData.Enabled = Options.AntiHookEnabled.Value
    
    if AntiHookData.Enabled then
        if AntiHookData.Connection then AntiHookData.Connection:Disconnect() end
        AntiHookData.Connection = RunService.Heartbeat:Connect(UpdateAntiHook)
        Fluent:Notify({Title = "Anti-Hook", Content = "System Activated", Duration = 2})
    else
        if AntiHookData.Connection then
            AntiHookData.Connection:Disconnect()
            AntiHookData.Connection = nil
        end
        Fluent:Notify({Title = "Anti-Hook", Content = "System Deactivated", Duration = 2})
    end
end)

Sectionantihook:AddToggle("AntiHookCarriedOnly", {
    Title = "Carried Only", 
    Default = true}):OnChanged(function()
    AntiHookData.CarriedOnly = Options.AntiHookCarriedOnly.Value
end)

Sectionantihook:AddSlider("AntiHookOffsetY", {
    Title = "Teleport Offset Y",
    Description = "",
    Default = -250,
    Min = -1000,
    Max = -1,
    Rounding = 0,
    Callback = function(Value)
        AntiHookData.OffsetY = Value
    end
})

Sectionantihook:AddSlider("AntiHookHz", {
    Title = "Anti Hook Level",
    Description = "",
    Default = 60,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        AntiHookData.Hz = Value
    end
})

-- // Event Listeners
localPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if AntiHookData.Enabled then
        FindRemote()
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        FindRemote()
    end
end)

-- Initialize
FindRemote()
end

InitAntiHook()
Window:SelectTab(1)
