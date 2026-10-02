local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- [[ GEN BYPASS DATA & CONFIG ]]
local GenBypass = {
    Enabled = false,
    HotkeyCode = Enum.KeyCode.G,
    Processed = {},
    Cache = {},
    CacheTimer = 0,
    Button = nil,
    UI = nil,
    IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
}

-- [[ CORE LOGIC ]]
local function GB_GetAllGenerators()
    local now = tick()
    if now - GenBypass.CacheTimer < 5 then return GenBypass.Cache end
    GenBypass.Cache = {}
    GenBypass.CacheTimer = now
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return GenBypass.Cache end
    
    for _, v in pairs(mapFolder:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Generator" then
            if v:GetAttribute("RepairProgress") ~= nil or v:GetAttribute("kickcount") ~= nil then
                table.insert(GenBypass.Cache, v)
            end
        end
    end
    return GenBypass.Cache
end

local function GB_GetPoints(genModel)
    local points = {}
    for _, obj in pairs(genModel:GetChildren()) do
        if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
            table.insert(points, obj)
        end
    end
    return points
end

local function GB_WaitRepairing(point, timeout)
    local start = tick()
    while tick() - start < (timeout or 1) do
        if point:GetAttribute("IsRepairing") == true then return true end
        task.wait(0.05)
    end
    return false
end

local function GB_DoRepair(targetPoint)
    local genModel = targetPoint.Parent
    if GenBypass.Processed[genModel] then return end
    GenBypass.Processed[genModel] = true

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then GenBypass.Processed[genModel] = nil return end

    local RepairEvent = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("Generator")
        and ReplicatedStorage.Remotes.Generator:FindFirstChild("RepairEvent")

    if not RepairEvent then return end
    local originalCFrame = hrp.CFrame
    
    pcall(function()
        for _, point in pairs(GB_GetPoints(genModel)) do
            if point ~= targetPoint and point.Parent then
                hrp.Anchored = true
                hrp.CFrame = point.CFrame
                task.wait(0.15)
                RepairEvent:FireServer(point, true)
                if not GB_WaitRepairing(point, 0.8) then
                    RepairEvent:FireServer(point, false)
                    task.wait(0.1)
                    hrp.CFrame = point.CFrame
                    task.wait(0.15)
                    RepairEvent:FireServer(point, true)
                    GB_WaitRepairing(point, 0.5)
                end
                hrp.Anchored = false
                task.wait(0.05)
            end
        end
    end)

    pcall(function()
        if hrp and hrp.Parent then
            hrp.Anchored = false
            hrp.CFrame = originalCFrame
        end
    end)
    task.wait(0.1)
    RepairEvent:FireServer(targetPoint, false)
end

local function GB_GetNearestPoint()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local bestPoint, bestDist = nil, math.huge
    for _, gen in pairs(GB_GetAllGenerators()) do
        for _, point in pairs(GB_GetPoints(gen)) do
            local d = (hrp.Position - point.Position).Magnitude
            if d < bestDist then bestDist = d; bestPoint = point end
        end
    end
    return bestPoint, bestDist
end

local function GB_IsPromptVisible()
    local ok, frame = pcall(function()
        return LocalPlayer.PlayerGui.pcprompts.Frame.GeneratorRepair
    end)
    return ok and frame and frame.Visible
end

-- [[ MOBILE BUTTON CREATION ]]
local function GB_CreateMobileButton()
    if GenBypass.UI then GenBypass.UI:Destroy() end

    GenBypass.UI = Instance.new("ScreenGui")
    GenBypass.UI.Name = "BypassGenUI"
    GenBypass.UI.ResetOnSpawn = false
    GenBypass.UI.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local btn = Instance.new("ImageButton")
    btn.Name = "BypassButton"
    btn.Size = UDim2.new(0, 65, 0, 65)
    btn.Position = UDim2.new(0.85, 0, 0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.2
    btn.Visible = false
    btn.Parent = GenBypass.UI
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(255, 0, 0)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "BOOST"
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12

    btn.MouseButton1Click:Connect(function()
        if not GenBypass.Enabled then return end
        local bestPoint, bestDist = GB_GetNearestPoint()
        if bestPoint and bestDist <= 8 then GB_DoRepair(bestPoint) end
    end)

    GenBypass.Button = btn
end

local function UpdateButtonVisibility()
    if GenBypass.Button then
        GenBypass.Button.Visible = GenBypass.Enabled and GenBypass.IsMobile
    end
end

-- [[ INITIALIZE ]]
GB_CreateMobileButton()

UserInputService.InputBegan:Connect(function(input, gp)
    if not GenBypass.Enabled or gp then return end
    if input.KeyCode == GenBypass.HotkeyCode and GB_IsPromptVisible() then
        local bestPoint, bestDist = GB_GetNearestPoint()
        if bestPoint and bestDist <= 8 then GB_DoRepair(bestPoint) end
    end
end)

-- [[ FLUENT UI SETUP ]]
local Window = Fluent:CreateWindow({
    Title = "REAPER BYPASS",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 320),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = { Main = Window:AddTab({ Title = "Main", Icon = "bolt" }) }

Tabs.Main:AddToggle("GenBypassToggle", {
    Title = "Enable Gen Bypass",
    Description = "Works on PC (Key) & Mobile (Button)",
    Default = false,
    Callback = function(Value)
        GenBypass.Enabled = Value
        UpdateButtonVisibility()
    end
})

Tabs.Main:AddKeybind("GenBypassHotkey", {
    Title = "PC Hotkey",
    Mode = "Hold",
    Default = "G",
    Callback = function(Value) GenBypass.HotkeyCode = Value end,
    ChangedCallback = function(New) GenBypass.HotkeyCode = New end
})

Window:SelectTab(1)
