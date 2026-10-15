-- [[ Survivor Auto Farm - Anti-Warp Version (Exact Logic) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local AutoFarmEnabled = false
local activeFarmState = "Idle"

-- [[ Variables - Exact Dependency ]]
local currentGen = nil    -- ตัวแปรล็อคเป้าหมายเครื่องปัจจุบัน
local currentPoint = nil  -- จุดที่ยืนซ่อมปัจจุบัน
local isRepairingRemoteActive = false
local I_Repair, J_Unhook, K_Lever = nil, nil, nil

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

-- Scoring Logic (Exact Function bb)
local function calculateGenScore(gen, killerPos)
    local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
    if not part then return -999999 end
    local distToKiller = 9999
    if killerPos then
        distToKiller = (part.Position - killerPos).Magnitude
        if distToKiller < 45 then return -999999 end -- Killer ใกล้เกินไป
    end
    local progress = getGeneratorProgress(gen)
    return (progress * 15) + (distToKiller * 2)
end

-- Interaction Logic
local function stopInteractions()
    if I_Repair and currentPoint then pcall(function() I_Repair:FireServer(currentPoint, false) end) end
    isRepairingRemoteActive = false
    currentGen, currentPoint = nil, nil
end

-- [[ CORE AUTO FARM LOOP - FIXED WARPING ]]
task.spawn(function()
    while true do
        task.wait(0.2)
        if not AutoFarmEnabled then 
            if currentGen then stopInteractions() end
            activeFarmState = "OFF"
            continue 
        end

        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then stopInteractions() continue end

        -- Init Remotes
        if not I_Repair then
            I_Repair = ReplicatedStorage:FindFirstChild("RepairEvent", true)
        end

        local kDist, kPos = getNearestKillerInfo()
        
        -- 1. เช็คว่าต้องหนีไหม (Flee Logic)
        if kDist < 35 then
            activeFarmState = "FLEEING"
            stopInteractions()
            continue
        end

        -- 2. ตรวจสอบเครื่องที่กำลังซ่อมอยู่ (Target Lock Logic)
        if currentGen then
            -- ถ้าซ่อมเสร็จแล้ว หรือ ถูกขัดขวาง หรือ Killer มาใกล้เครื่องที่ซ่อมอยู่
            if isGeneratorCompleted(currentGen) or isGeneratorPaused(currentGen) or (kPos and (currentGen:GetPivot().Position - kPos).Magnitude < 45) then
                stopInteractions() -- เลิกซ่อมเครื่องนี้
            end
        end

        -- 3. ถ้าไม่มีเครื่องที่ล็อคไว้ ให้หาเครื่องใหม่ (Exact Scoring)
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

        -- 4. การทำงาน (Interaction)
        if currentGen then
            activeFarmState = "REPAIRING"
            local point = currentGen:FindFirstChild("GeneratorPoint") or currentGen:FindFirstChildWhichIsA("BasePart")
            if point then
                currentPoint = point
                -- วาปไปตำแหน่งซ่อม (ครั้งเดียว หรือเมื่ออยู่ห่างเกินไป)
                if (hrp.Position - point.Position).Magnitude > 5 then
                    hrp.CFrame = point.CFrame + Vector3.new(0, 1.5, 0)
                end
                
                -- ส่ง Remote ซ่อม
                if I_Repair and not isRepairingRemoteActive then
                    I_Repair:FireServer(point, true)
                    isRepairingRemoteActive = true
                end
            end
        else
            activeFarmState = "IDLE"
            stopInteractions()
        end
    end
end)

-- [[ GUI SYSTEM - DRAGGABLE ]]
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SurvivorExactUI"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 110)
Main.Position = UDim2.new(0.5, -100, 0.5, -55)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.Draggable = true -- เปิดระบบลาก

local Corner = Instance.new("UICorner", Main)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(45, 45, 45)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "AUTO FARM FIXED"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.Ubuntu
Title.TextSize = 13
Title.BackgroundTransparency = 1

local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(0, 170, 0, 35)
Toggle.Position = UDim2.new(0.5, -85, 0.4, 0)
Toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Toggle.Text = "AUTO FARM: OFF"
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
    Toggle.Text = AutoFarmEnabled and "AUTO FARM: ON" or "AUTO FARM: OFF"
    Toggle.BackgroundColor3 = AutoFarmEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(200, 50, 50)
    if not AutoFarmEnabled then stopInteractions() end
end)

RunService.RenderStepped:Connect(function()
    Status.Text = "STATE: " .. activeFarmState:upper()
end)
