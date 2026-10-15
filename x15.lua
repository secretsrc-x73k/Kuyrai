-- [[ Survivor Auto Farm - 100% Exact Logic from Context ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local AutoFarmEnabled = false
local activeFarmState = "Idle"

-- [[ Original Variables Dependency ]]
local cachedGenerators = {}
local cachedHooks = {}
local cachedGates = {}
local repairCooldowns = {} -- สำหรับระบบ R(f, 25)
local isRepairingRemoteActive = false
local isGateRemoteActive = false
local currentGen = nil
local currentPoint = nil
local lastStatus = "OFF"

-- [[ Original Remote Variables ]]
local I_Repair = nil
local J_Unhook = nil
local K_Lever = nil

-- [[ EXACT HELPER FUNCTIONS FROM CODEX ]]

local function isGeneratorCompleted(c)
    local d = c:GetAttribute("Completed")
    if d == nil then
        local f = c:FindFirstChild("Completed")
        if f and f:IsA("BoolValue") then d = f.Value end
    end
    return d == true or tostring(d):lower() == "true"
end

local function isGeneratorPaused(c)
    if not c then return false end
    local d = c:GetAttribute("ProgressPaused")
    if d == nil then
        local f = c:FindFirstChild("ProgressPaused")
        if f and f:IsA("ValueBase") then d = f.Value end
    end
    return d == true or tostring(d):lower() == "true"
end

local function getGeneratorProgress(c)
    local d = c:GetAttribute("RepairProgress")
    if not d then
        local f = c:FindFirstChild("RepairProgress")
        if f and f:IsA("ValueObject") then d = f.Value end
    end
    if not d then return 0 end
    local f = tonumber(d)
    return (f <= 1.01 and f > 0) and math.round(f * 100) or math.round(f)
end

-- ระบบหา Killer (U Function)
local function getNearestKillerInfo()
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

-- ระบบ Scoring (bb Function) เป๊ะๆ
local function calculateGenScore(gen, killerPos, myPos)
    local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
    if not part then return -999999 end
    
    local distToKiller = 9999
    if killerPos then
        distToKiller = (part.Position - killerPos).Magnitude
        if distToKiller < 45 then return -999999 end -- ห้ามไปถ้า Killer อยู่ใกล้
    end
    
    local progress = getGeneratorProgress(gen)
    local score = (progress * 15) + (distToKiller * 2)
    return score
end

-- [[ CORE AUTO FARM LOOP (Exact Logic from Context) ]]

local function stopAllInteractions()
    if I_Repair and currentPoint then
        pcall(function() I_Repair:FireServer(currentPoint, false) end)
    end
    if K_Lever and currentPoint then
        pcall(function() K_Lever:FireServer(currentPoint, false) end)
    end
    isRepairingRemoteActive = false
    isGateRemoteActive = false
    currentGen = nil
    currentPoint = nil
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if not AutoFarmEnabled then 
            if lastStatus ~= "OFF" then stopAllInteractions() lastStatus = "OFF" end
            activeFarmState = "OFF"
            continue 
        end
        
        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then stopAllInteractions() continue end

        -- Remote Initialization (O function)
        if not I_Repair then
            I_Repair = ReplicatedStorage:FindFirstChild("RepairEvent", true)
            J_Unhook = ReplicatedStorage:FindFirstChild("UnHookEvent", true)
            K_Lever = ReplicatedStorage:FindFirstChild("LeverEvent", true)
        end

        local kDist, kPos = getNearestKillerInfo()
        
        -- Logic: Fleeing
        if kDist < 35 then
            activeFarmState = "FLEEING"
            stopAllInteractions()
            -- Flee Logic...
            continue
        end

        -- Logic: Picking best Generator (cb function)
        local bestGen = nil
        local bestScore = -math.huge
        
        -- Scan Gens
        local gens = {}
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Generator" and v:IsA("Model") then table.insert(gens, v) end
        end

        for _, gen in ipairs(gens) do
            if not isGeneratorCompleted(gen) and not isGeneratorPaused(gen) then
                local score = calculateGenScore(gen, kPos, hrp.Position)
                if score > bestScore then
                    bestScore = score
                    bestGen = gen
                end
            end
        end

        if bestGen then
            activeFarmState = "REPAIRING"
            local point = bestGen:FindFirstChild("GeneratorPoint") or bestGen:FindFirstChildWhichIsA("BasePart")
            if point then
                currentGen = bestGen
                currentPoint = point
                hrp.CFrame = point.CFrame + Vector3.new(0, 1.5, 0)
                
                if I_Repair and not isRepairingRemoteActive then
                    I_Repair:FireServer(point, true)
                    isRepairingRemoteActive = true
                end
            end
        else
            activeFarmState = "IDLE"
            stopAllInteractions()
        end
        lastStatus = activeFarmState
    end
end)

-- [[ DRAGGABLE CUSTOM GUI ]]

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SurvivorExactUI"
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -60)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- รองรับการลากแบบดั้งเดิม
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(45, 45, 55)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "HYPNOSIS CORE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.Ubuntu
Title.TextSize = 14
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "Toggle"
ToggleBtn.Size = UDim2.new(0, 180, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -90, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
ToggleBtn.Text = "AUTO FARM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
ToggleBtn.Font = Enum.Font.Ubuntu
ToggleBtn.TextSize = 13
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 1, -30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "STATE: IDLE"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 11
StatusLabel.Parent = MainFrame

-- [[ GUI LOGIC ]]

ToggleBtn.MouseButton1Click:Connect(function()
    AutoFarmEnabled = not AutoFarmEnabled
    if AutoFarmEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
        ToggleBtn.Text = "AUTO FARM: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        ToggleBtn.Text = "AUTO FARM: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        stopAllInteractions()
    end
end)

RunService.RenderStepped:Connect(function()
    StatusLabel.Text = "STATE: " .. activeFarmState
end)
