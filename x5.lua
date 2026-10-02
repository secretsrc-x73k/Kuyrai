local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "HyperX | Auto Escape",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

-- // Variables (จาก Codex ของคุณ)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

_G.AutoEscapeEnabled = false

-- // Role Checker (Logic ตาม Codex)
local function GetRole()
    if not LocalPlayer.Team then return "Unknown" end
    local name = LocalPlayer.Team.Name
    if name == "Killer" then return "Killer" end
    if name == "Survivors" then return "Survivor" end
    return "Lobby"
end

-- // Core Logic: Beat Survivor (Exact Logic)
local function KYS_BeatGameSurvivor()
    -- ตรวจสอบ Role: ถ้าไม่ใช่ Survivor จะไม่ทำงาน (ไม่มีการแจ้งเตือน)
    if GetRole() ~= "Survivor" then return end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local exitPos = nil
    local finishPart = nil
    local map = Workspace:FindFirstChild("Map")

    -- 1. Scan finishline
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        if (nameLower == "fininshline" or nameLower == "finishline") and obj:IsA("BasePart") then
            finishPart = obj
            exitPos = obj.Position
            break
        end
    end

    -- 2. Fallback Maps
    if not exitPos and map then
        if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
            finishPart = map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop")
            if finishPart:IsA("Model") then finishPart = finishPart.PrimaryPart or finishPart:FindFirstChildWhichIsA("BasePart") end
            exitPos = finishPart and finishPart.Position or Vector3.new(3098.16, 454.04, -4918.74)
        elseif map:FindFirstChild("HooksMeat") then
            finishPart = map:FindFirstChild("HooksMeat")
            if finishPart:IsA("Model") then finishPart = finishPart.PrimaryPart or finishPart:FindFirstChildWhichIsA("BasePart") end
            exitPos = finishPart and finishPart.Position or Vector3.new(1546.12, 152.21, -796.72)
        end
    end

    if not exitPos then return end

    -- 3. Execution Loop (10 ครั้ง)
    task.spawn(function()
        for i = 1, 10 do
            if not root or not root.Parent or GetRole() ~= "Survivor" then break end

            -- Fire Remote
            pcall(function()
                local event = ReplicatedStorage:FindFirstChild("Remotes") and 
                              ReplicatedStorage.Remotes:FindFirstChild("Game") and 
                              ReplicatedStorage.Remotes.Game:FindFirstChild("PlayerActionEvent")
                if event then
                    event:FireServer("ESCAPED", 200)
                end
            end)

            -- Touch Interest
            if firetouchinterest and finishPart then
                firetouchinterest(root, finishPart, 0)
                task.wait()
                firetouchinterest(root, finishPart, 1)
            end

            -- Teleport
            if i == 1 then
                root.Velocity = Vector3.zero
                root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0))
            end

            task.wait(0.2)
        end
    end)
end

-- // UI Toggle (ลบ Notify ออกแล้ว)
Tabs.Main:AddToggle("BeatSurvivor", {
    Title = "Beat Survivor (Auto Exit)",
    Description = "ทํางานเฉพาะทีม Survivor เท่านั้น",
    Default = false,
    Callback = function(Value)
        _G.AutoEscapeEnabled = Value
    end
})

-- // Main Loop
task.spawn(function()
    while true do
        if _G.AutoEscapeEnabled and GetRole() == "Survivor" then
            KYS_BeatGameSurvivor()
            task.wait(5)
        end
        task.wait(1)
    end
end)

Window:SelectTab(1)
