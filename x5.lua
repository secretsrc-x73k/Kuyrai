local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "HyperX | Auto Escape Standalone",
    SubTitle = "Violence District Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

-- // Variables from your Codex
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

_G.AutoEscapeEnabled = false

-- // Core Logic: KYS_BeatGameSurvivor (Exact Match)
local function ExecuteAutoEscape()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local exitPos = nil
    local finishPart = nil
    local map = workspace:FindFirstChild("Map")

    -- Scan finishline (Logic จาก Codex คุณ)
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name)
        if (nameLower == "fininshline" or nameLower == "finishline") and obj:IsA("BasePart") then
            finishPart = obj
            exitPos = obj.Position
            break
        end
    end

    -- Fallback สำหรับแมพเฉพาะ (ตามโค้ดที่คุณส่งมา)
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

    -- เริ่มกระบวนการหนี (Loop 10 ครั้งตามต้นฉบับ)
    task.spawn(function()
        for i = 1, 10 do
            if not root or not root.Parent then break end

            -- ยิง Remote Event (Exact Path)
            pcall(function()
                local event = ReplicatedStorage:FindFirstChild("Remotes") and 
                              ReplicatedStorage.Remotes:FindFirstChild("Game") and 
                              ReplicatedStorage.Remotes.Game:FindFirstChild("PlayerActionEvent")
                if event then
                    event:FireServer("ESCAPED", 200)
                end
            end)

            -- แตะเส้นชัย (firetouchinterest)
            if firetouchinterest and finishPart then
                firetouchinterest(root, finishPart, 0)
                task.wait()
                firetouchinterest(root, finishPart, 1)
            end

            -- Teleport ในรอบแรก
            if i == 1 then
                root.Velocity = Vector3.zero
                root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0))
            end

            task.wait(0.2)
        end
    end)
end

-- // UI Elements
Tabs.Main:AddToggle("BeatSurvivor", {
    Title = "Beat Survivor (Auto Exit)",
    Description = "Teleports to exit and fires escape event",
    Default = false,
    Callback = function(Value)
        _G.AutoEscapeEnabled = Value
    end
})

-- // Loop System
task.spawn(function()
    while true do
        if _G.AutoEscapeEnabled then
            ExecuteAutoEscape()
            task.wait(5) -- หน่วงเวลาป้องกันการส่ง Remote ซ้ำซ้อนเกินไป
        end
        task.wait(1)
    end
end)

Window:SelectTab(1)
