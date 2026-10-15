-- [[ Survivor Auto Farm - Anti-Stuck & Fixed Repair Logic ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local AutoFarmEnabled = false
local activeFarmState = "Idle"

-- [[ Variables Logic ]]
local currentGen = nil
local currentPoint = nil
local isRepairingRemoteActive = false
local I_Repair = nil
local lastRepairCheck = 0

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

-- Interaction Logic (Fixed: Reset status correctly)
local function stopInteractions()
    if I_Repair and currentPoint then 
        pcall(function() I_Repair:FireServer(currentPoint, false) end) 
    end
    isRepairingRemoteActive = false
    currentGen, currentPoint = nil, nil
end

-- [[ CORE AUTO FARM LOOP - STABILITY PATCH ]]
task.spawn(function()
    while true do
        task.wait(0.25) -- เพิ่ม Delay เล็กน้อยเพื่อเสถียรภาพ
        
        if not AutoFarmEnabled then 
            if currentGen then stopInteractions() end
            activeFarmState = "OFF"
            continue 
        end

        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then stopInteractions() continue end

        -- ดึง Remote ตามโครงสร้าง Codex
        if not I_Repair then
            I_Repair = ReplicatedStorage:FindFirstChild("RepairEvent", true)
        end

        local kDist, kPos = getNearestKillerInfo()
        
        -- 1. Flee Logic
        if kDist < 35 then
            activeFarmState = "FLEEING"
            stopInteractions()
            continue
        end

        -- 2. Target Lock & Stuck Check (จุดที่แก้)
        if currentGen then
            -- เช็คว่าซ่อมอยู่จริงไหมผ่าน Attribute 'repairing' ของตัวละคร (Logic เป๊ะตาม Codex)
            local isActuallyRepairing = char:GetAttribute("repairing")
            
            if isGeneratorCompleted(currentGen) or isGeneratorPaused(currentGen) or (kPos and (currentGen:GetPivot().Position - kPos).Magnitude < 45) then
                stopInteractions()
            elseif tick() - lastRepairCheck > 2 then -- ทุก 2 วิ ถ้าวาปไปแล้วแต่สถานะซ่อมไม่ขึ้น ให้ Reset เพื่อส่ง Remote ใหม่
                if not isActuallyRepairing or isActuallyRepairing == 0 then
                    isRepairingRemoteActive = false -- บังคับให้ส่ง Remote ซ่อมอีกครั้ง
                end
                lastRepairCheck = tick()
            end
        end

        -- 3. Search New Gen if Idle
        if not currentGen then
            local bestGen = nil
            local bestScore = -math.huge
            local gens = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name == "Generator" and v:IsA("Model") then table.insert(gens, v) end
            end

            for _, gen in ipairs(gens) do
                if not isGeneratorCompleted(gen) and not isGeneratorPaused(gen) then
                    local part = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dToK = kPos and (part.Position - kPos).Magnitude or 9999
                        if dToK > 45 then
                            local prog = getGeneratorProgress(gen)
                            local score = (prog * 15) + (dToK * 2)
                            if score > bestScore then bestScore = score bestGen = gen end
                        end
                    end
                end
            end
            currentGen = bestGen
        end

        -- 4. Repair Execution
        if currentGen then
            activeFarmState = "REPAIRING"
            local point = currentGen:FindFirstChild("GeneratorPoint") or currentGen:FindFirstChildWhichIsA("BasePart")
            if point then
                currentPoint = point
                -- วาปและรอจังหวะเล็กน้อยก่อนซ่อม (ลดโอกาส Remote โดน Reject)
                if (hrp.Position - point.Position).Magnitude > 5 then
                    hrp.CFrame = point.CFrame + Vector3.new(0, 1.5, 0)
                    task.wait(0.1) 
                end
                
                if I_Repair and not isRepairingRemoteActive then
                    I_Repair:FireServer(point, true)
                    isRepairingRemoteActive = true
                    lastRepairCheck = tick()
                end
            end
        else
            activeFarmState = "IDLE"
        end
    end
end)

-- [[ CUSTOM GUI - DRAGGABLE ]]
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SurvivorExactUI"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 110)
Main.Position = UDim2.new(0.5, -100, 0.5, -55)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.Draggable = true

local Corner = Instance.new("UICorner", Main)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(50, 50, 50)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "SURVIVOR AUTO FARM"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.Ubuntu
Title.TextSize = 13
Title.BackgroundTransparency = 1

local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(0, 170, 0, 35)
Toggle.Position = UDim2.new(0.5, -85, 0.4, 0)
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
