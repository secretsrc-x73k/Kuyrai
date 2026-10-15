-- [[ Survivor Auto Farm Standalone - Extract Logic ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local AutoFarmEnabled = false

-- [[ Shared Variables From Original Codex ]]
local cachedGenerators = {}
local cachedHooks = {}
local cachedGates = {}
local hookedBlacklist = {}
local isRepairingRemoteActive = false
local isGateRemoteActive = false
local L, M = nil, nil -- Remote Trackers
local activeFarmState = "Idle"

-- [[ Helper Functions - Exact Logic from Source ]]

local function getDistance(part)
    if not part then return math.huge end
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    local targetPos = part:IsA("Model") and (part.PrimaryPart and part.PrimaryPart.Position or part:GetPivot().Position) or part.Position
    return (hrp.Position - targetPos).Magnitude
end

local function isGeneratorCompleted(gen)
    local val = gen:GetAttribute("Completed") or (gen:FindFirstChild("Completed") and gen.Completed.Value)
    return val == true or tostring(val):lower() == "true"
end

local function isGeneratorPaused(gen)
    local val = gen:GetAttribute("ProgressPaused") or (gen:FindFirstChild("ProgressPaused") and gen.ProgressPaused.Value)
    return val == true or tostring(val):lower() == "true"
end

local function getGeneratorProgress(gen)
    local prog = gen:GetAttribute("RepairProgress") or (gen:FindFirstChild("RepairProgress") and gen.RepairProgress.Value)
    if not prog then return 0 end
    return (prog <= 1.01 and prog > 0) and math.round(prog * 100) or math.round(prog)
end

-- Scan Objects Logic
local function scanObjects()
    local gens, hooks, gates = {}, {}, {}
    local map = workspace:FindFirstChild("Map")
    local targets = map and map:GetDescendants() or workspace:GetDescendants()
    
    for _, v in ipairs(targets) do
        if v.Name == "Generator" and v:IsA("Model") then table.insert(gens, v)
        elseif (v.Name == "Hook" or v.Name == "HookPoint") then table.insert(hooks, v)
        elseif v.Name == "Gate" and v:IsA("Model") then table.insert(gates, v) end
    end
    cachedGenerators, cachedHooks, cachedGates = gens, hooks, gates
end

-- Get Nearest Killer (Original U function)
local function getNearestKiller()
    local minDist = math.huge
    local killerPos = nil
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return minDist, nil end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Team and p.Team.Name == "Killer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < minDist then minDist = d killerPos = p.Character.HumanoidRootPart.Position end
        end
    end
    return minDist, killerPos
end

-- [[ CORE SURVIVOR FARM LOOP - REPLICATED ]]
task.spawn(function()
    while true do
        task.wait(0.2)
        if not AutoFarmEnabled then 
            activeFarmState = "OFF"
            continue 
        end
        
        scanObjects()
        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local kDist, kPos = getNearestKiller()
        
        -- Decision Logic (Same as Source)
        if kDist < 35 and kPos then
            activeFarmState = "FLEEING"
            -- Flee logic here...
        end

        -- Interaction State Machine
        local currentTargetGen = nil
        for _, gen in ipairs(cachedGenerators) do
            if not isGeneratorCompleted(gen) and not isGeneratorPaused(gen) then
                currentTargetGen = gen
                break
            end
        end

        if currentTargetGen then
            activeFarmState = "REPAIRING"
            local point = currentTargetGen:FindFirstChild("GeneratorPoint") or currentTargetGen:FindFirstChildWhichIsA("BasePart")
            if point then
                hrp.CFrame = point.CFrame + Vector3.new(0, 1.5, 0)
                -- Fire Repair Remote
                local remote = ReplicatedStorage:FindFirstChild("RepairEvent", true)
                if remote then remote:FireServer(point, true) end
            end
        else
            activeFarmState = "IDLE"
        end
    end
end)

-- [[ CUSTOM DRAGGABLE GUI ]]

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmUI"
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Legacy draggable
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Survivor Farm"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.Ubuntu
Title.TextSize = 14
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "Toggle"
ToggleBtn.Size = UDim2.new(0, 160, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -80, 0.5, -5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "Status: OFF"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.Ubuntu
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 1, -25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "State: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Ubuntu
StatusLabel.TextSize = 11
StatusLabel.Parent = MainFrame

-- [[ GUI Logic ]]

ToggleBtn.MouseButton1Click:Connect(function()
    AutoFarmEnabled = not AutoFarmEnabled
    if AutoFarmEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "Status: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Status: OFF"
    end
end)

-- Update Status Label
task.spawn(function()
    while true do
        StatusLabel.Text = "State: " .. activeFarmState
        task.wait(0.5)
    end
end)

-- Draggable Script (Modern way)
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
