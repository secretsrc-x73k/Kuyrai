local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "Streamer Mode",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Streamer = Window:AddTab({
        Title = "Streamer Mode",
        Icon = "users"
    })
}

local FakeNameConnection = nil

local function shouldHideNameObject(object)
    local ok, isTextObj = pcall(function()
        return object:IsA("TextLabel")
            or object:IsA("TextButton")
            or object:IsA("TextBox")
    end)

    if not ok or not isTextObj then
        return false
    end

    local text = ""

    pcall(function()
        text = tostring(object.Text or "")
    end)

    return text == LocalPlayer.Name
        or text == LocalPlayer.DisplayName
        or text:find(LocalPlayer.Name, 1, true) ~= nil
end

local function enableFakeName(enabled)
    if FakeNameConnection then
        pcall(function()
            FakeNameConnection:Disconnect()
        end)

        FakeNameConnection = nil
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        return
    end

    local function process(object)
        if shouldHideNameObject(object) then
            object.Visible = not enabled
        end
    end

    for _, descendant in ipairs(playerGui:GetDescendants()) do
        process(descendant)
    end

    if enabled then
        FakeNameConnection = playerGui.DescendantAdded:Connect(function(object)
            task.defer(process, object)
        end)
    end
end

Tabs.Streamer:AddToggle("HideName", {
    Title = "Hide Name",
    Description = "Hide your username and display name",
    Default = false,

    Callback = function(value)
        pcall(enableFakeName, value)
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Streamer Mode",
    Content = "Loaded successfully.",
    Duration = 3
})
