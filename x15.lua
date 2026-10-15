-- [[ Survivor Auto Farm - Exact Logic with Warp Fix ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local AutoFarmEnabled = false
local activeFarmState = "Idle"

-- [[ Core Variables from Source ]]
local currentGen = nil    -- ตัวแปรล็อคเครื่องปั่นไฟ
local currentPoint = nil  -- ตัวแปรล็อคจุดซ่อม
local isRepairingRemoteActive = false
local I_Repair = nil
local lastStuckCheck = 0

-- [[ EXACT HELPER FUNCTIONS FROM CODEX ]]
local function getGeneratorProgress(c)
    local d = c:GetAttribute("RepairProgress") or (c:FindFirstChild("RepairProgress") and c.RepairProgress.Value)
    if not d then return 0 end
    local f = tonumber(d)
    return (f <= 1.01 and f > 0) and math.round(f * 100) or math.round(f)
end

local function isGeneratorCompleted(c)
    local d = c:GetAttribute("Completed") or (c:FindFirstChild("Completed") and c.Completed.Value)
    return d == true or tostring(d):lower() == "true"
end

local function isGeneratorPaused(c)
    local d = c:GetAttribute("ProgressPaused") or (c:FindFirstChild("ProgressPaused") and c.ProgressPaused.Value)
    return d == true or tostring(d):lower() == "true"
end

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

-- Scoring Logic (Exact Function bb from source)
local function calculateGenScore(gen, killerPos)
    local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
    if not part then return -999999 end
    local distToKiller = 9999
    if killerPos then
        distToKiller = (part.Position - killerPos).Magnitude
        if distToKiller < 45 then return -999999 end 
    end
    local progress = getGeneratorProgress(gen)
    return (progress * 15) + (distToKiller * 2)
end

local function stopInteractions()
    if I_Repair and currentPoint then 
        pcall(function() I_Repair:FireServer(currentPoint, false) end) 
    end
    isRepairingRemoteActive = false
    currentGen, currentPoint = nil, nil
end

-- [[ CORE LOOP - RE-STABILIZED ]]
task.spawn(function()
    while true do
        task.wait(0.3) -- เพิ่มดีเลย์การวนรอบให้เสถียรขึ้น
        
        if not AutoFarmEnabled then 
            if currentGen then stopInteractions() end
            activeFarmState = "OFF"
            continue 
        end

        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then stopInteractions() continue end

        if not I_Repair then
            I_Repair = ReplicatedStorage:FindFirstChild("RepairEvent", true)
        end

        local kDist, kPos = getNearestKillerInfo()
        
        -- 1. หนี (Flee)
        if kDist < 35 then
            activeFarmState = "FLEEING"
            stopInteractions()
            continue
        end

        -- 2. Target Lock Logic (แก้จุดที่วาปรัวๆ)
        if currentGen then
            -- เช็คว่าเครื่องปัจจุบันยังควรซ่อมอยู่ไหม?
            local tooClose = kPos and (currentGen:GetPivot().Position - kPos).Magnitude < 45
            if isGeneratorCompleted(currentGen) or isGeneratorPaused(currentGen) or tooClose then
                stopInteractions() -- ปลดล็อคเครื่องเมื่อเสร็จหรืออันตราย
            end
        end

        -- 3. ค้นหาเครื่อง (เฉพาะตอนที่ไม่มีเป้าหมายที่ล็อคไว้)
        if not currentGen then
            local bestGen = nil
            local bestScore = -math.huge
            local gens = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name == "Generator" and v:IsA("Model") then table.insert(gens, v) end
            end

            for _, gen in ipairs(gens) do
                if not isGeneratorCompleted(gen) and not isGeneratorPaused(gen) then
                    local score = calculateGenScore(gen, kPos)
                    if score > bestScore then
                        bestScore = score
                        bestGen = gen
                    end
                end
            end
            currentGen = bestGen
        end

        -- 4. เข้าไปซ่อม
        if currentGen then
            activeFarmState = "REPAIRING"
            local point = currentGen:FindFirstChild("GeneratorPoint") or currentGen:FindFirstChildWhichIsA("BasePart")
            if point then
                currentPoint = point
                -- วาปเฉพาะเมื่ออยู่ห่างเกินไป (แก้ปัญหาตัวกระตุก)
                if (hrp.Position - point.Position).Magnitude > 6 then
                    hrp.CFrame = point.CFrame + Vector3.new(0, 1.5, 0)
                    task.wait(0.1)
                end
                
                -- ส่ง Remote ซ่อม (ส่งครั้งเดียวเมื่อวาปถึง)
                if I_Repair and not isRepairingRemoteActive then
                    I_Repair:FireServer(point, true)
                    isRepairingRemoteActive = true
                    lastStuckCheck = tick()
                end
                
                -- Stuck Check: ถ้าผ่านไป 3 วิแล้ว Attribute 'repairing' ยังไม่ขึ้น ให้ลองส่ง Remote ใหม่
                if tick() - lastStuckCheck > 3 then
                    if char:GetAttribute("repairing") == 0 or not char:GetAttribute("repairing") then
                        isRepairingRemoteActive = false 
                    end
                    lastStuckCheck = tick()
                end
            end
        else
            activeFarmState = "IDLE"
            stopInteractions()
        end
    end
end)

-- [[ CUSTOM GUI - DRAGGABLE ]]
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SurvivorExactUI"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 210, 0, 110)
Main.Position = UDim2.new(0.5, -105, 0.5, -55)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.Draggable = true

local Corner = Instance.new("UICorner", Main)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(60, 60, 60)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "AUTO FARM v2 (FIXED)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.Ubuntu
Title.TextSize = 13
Title.BackgroundTransparency = 1

local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(0, 180, 0, 35)
Toggle.Position = UDim2.new(0.5, -90, 0, 40)
Toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
Toggle.Text = "STATUS: OFF"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Font = Enum.Font.Ubuntu
Toggle.TextSize = 12
Instance.new("UICorner", Toggle)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 1, -25)
Status.BackgroundTransparency = 1
Status.Text = "STATE: IDLE"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.Font = Enum.Font.Code
Status.TextSize = 10

Toggle.MouseButton1Click:Connect(function()
    AutoFarmEnabled = not AutoFarmEnabled
    Toggle.Text = AutoFarmEnabled and "STATUS: ON" or "STATUS: OFF"
    Toggle.BackgroundColor3 = AutoFarmEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    if not AutoFarmEnabled then stopInteractions() end
end)

RunService.RenderStepped:Connect(function()
    Status.Text = "STATE: " .. activeFarmState:upper()
end)
