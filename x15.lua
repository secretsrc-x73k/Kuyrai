local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- // Configuration
local Config = {
    Enabled = false,
    FleeDistance = 45, -- ระยะที่ต้องหนีจากฆาตกร
    State = "Idle"
}

-- // GUI Creation
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "HyperX_AutoFarm"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0

local UICorner = Instance.new("UICorner", MainFrame)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "SURVIVOR AUTO FARM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.Ubuntu
Title.TextSize = 14

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 160, 0, 40)
ToggleBtn.Position = UDim2.new(0.5, -80, 0.6, -20)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "Status: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.Ubuntu
ToggleBtn.TextSize = 16
Instance.new("UICorner", ToggleBtn)

-- // Dragging Logic
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- // Utility Functions
local function getRemote(folder, name)
    return ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild(folder) and ReplicatedStorage.Remotes[folder]:FindFirstChild(name)
end

local function getKiller()
    local nearestDist = math.huge
    local killerPos = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Team and p.Team.Name == "Killer" or p:GetAttribute("Role") == "Killer") then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    killerPos = p.Character.HumanoidRootPart.Position
                end
            end
        end
    end
    return nearestDist, killerPos
end

-- // Core Logic Functions
local function repairGen()
    local gens = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Generators")
    if not gens then return end
    
    local bestGen = nil
    local maxProg = -1
    
    for _, g in pairs(gens:GetChildren()) do
        if g:IsA("Model") and not g:GetAttribute("Completed") then
            local prog = g:GetAttribute("RepairProgress") or 0
            if prog > maxProg then
                maxProg = prog
                bestGen = g
            end
        end
    end
    
    if bestGen then
        local point = bestGen:FindFirstChild("GeneratorPoint") or bestGen:FindFirstChildWhichIsA("BasePart", true)
        local repairRemote = getRemote("Generator", "RepairEvent")
        
        if point and repairRemote then
            Character.HumanoidRootPart.CFrame = point.CFrame + Vector3.new(0, 1, 0)
            repairRemote:FireServer(point, true)
            Config.State = "Repairing"
        end
    end
end

local function stopActions()
    local repairRemote = getRemote("Generator", "RepairEvent")
    if repairRemote then repairRemote:FireServer(nil, false) end
end

-- // Main Loop
task.spawn(function()
    while task.wait(0.3) do
        if not Config.Enabled then 
            Config.State = "Idle"
            continue 
        end
        
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local distToKiller, killerPos = getKiller()
        
        -- Priority 1: หนีฆาตกร
        if distToKiller < Config.FleeDistance then
            stopActions()
            Config.State = "Fleeing"
            -- วาร์ปไปที่ปลอดภัย (เช่น มุมแมพ)
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 50) 
            continue
        end

        -- Priority 2: ตรวจสอบทางออก (ถ้าปั่นเสร็จแล้ว)
        local gate = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Gates")
        if gate then
            -- Logic เปิดประตูและ Finishline (ตัดย่อเพื่อความเสถียร)
        end

        -- Priority 3: ซ่อมเครื่อง
        if Config.State ~= "Repairing" then
            repairGen()
        end
    end
end)

-- // Toggle Button Logic
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    if Config.Enabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "Status: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Status: OFF"
        stopActions()
    end
end)
