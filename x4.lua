local function LoadFluent(url)
    local ok, result = pcall(function()
        local loader = load or loadstring
        if type(loader) ~= "function" then
            error("load/loadstring is unavailable")
        end
        local chunk = loader(game:HttpGet(url))
        if type(chunk) ~= "function" then
            error("NewUI response did not compile to a function")
        end
        local value = chunk()
        if type(value) == "function" then
            value = value()
        end
        return value
    end)
    if not ok then
        error("REAPER HUB UI load failed: " .. tostring(result))
    end
    if type(result) ~= "table" and type(result) ~= "userdata" then
        error("REAPER HUB UI load failed: NewUI returned " .. type(result))
    end
    return result
end

local Fluent = LoadFluent("https://raw.githubusercontent.com/secretsrc-x73k/NewUI/refs/heads/main/newui.lua")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local VD = getgenv().VD or {}
getgenv().VD = VD

local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 330),
    Theme = "ExtremeReaper",
    MinimizeKey = Enum.KeyCode.RightControl
})

local KillerTab = Window:AddTab({
    Title = "Killer",
    Icon = "target",
})

local VeilSection = KillerTab:AddSection("Veil Silent Aim")

VeilConfig = {
    Enabled              = false,
    ShowFOV              = true,
    ShowTargetLaser      = true,
    FOV                  = 150,
    SpearSpeed           = 165,
    Gravity              = workspace.Gravity * 0.5,
    MaxDist              = 200,
    AutoPredict          = false,
    TargetPart           = "Torso",
    HorizontalPredictFactor = 1.0,
}

VeilState = {
    chargingSpear    = false,
    touchInput       = nil,
    attackCooldown   = false,
    passiveCooldown  = false,
    remoteHooked     = false,
    lastPredictedPos = nil,
}

VeilVelocityCache = {}

local function Veil_NewDrawing(className)
    if type(Drawing) == "table" and type(Drawing.new) == "function" then
        local ok, object = pcall(Drawing.new, className)
        if ok and object then
            return object
        end
    end
    return setmetatable({}, {
        __newindex = function(t, k, v) rawset(t, k, v) end
    })
end

VeilDraw = {
    FOVCircle = Veil_NewDrawing("Circle"),
    Highlight = Instance.new("Highlight"),
    Tracer    = Veil_NewDrawing("Circle"),
}

VeilDraw.FOVCircle.Color     = Color3.fromRGB(255, 0, 255)
VeilDraw.FOVCircle.Thickness = 1.5
VeilDraw.FOVCircle.Filled    = false
VeilDraw.FOVCircle.Visible   = false

VeilDraw.Highlight.Name                = "VD_VeilTarget"
VeilDraw.Highlight.FillColor           = Color3.fromRGB(255, 0, 0)
VeilDraw.Highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
VeilDraw.Highlight.FillTransparency    = 0.5
VeilDraw.Highlight.OutlineTransparency = 0

VeilDraw.Tracer.Thickness = 2
VeilDraw.Tracer.Radius    = 5
VeilDraw.Tracer.Color     = Color3.fromRGB(255, 0, 255)
VeilDraw.Tracer.Filled    = true
VeilDraw.Tracer.Visible   = false

function Veil_GetRealVelocity(part, playerName)
    if not part then return Vector3.zero end
    local currentPos = part.Position
    local currentTime = tick()
    if not VeilVelocityCache[playerName] then
        VeilVelocityCache[playerName] = {lastPos = currentPos, lastTime = currentTime, velocity = Vector3.zero}
        return Vector3.zero
    end
    local cache = VeilVelocityCache[playerName]
    local dt = currentTime - cache.lastTime
    if dt > 0.01 then
        local rawVelocity = (currentPos - cache.lastPos) / dt
        if rawVelocity.Magnitude < 100 then
            cache.velocity = cache.velocity:Lerp(rawVelocity, 0.4)
        end
    end
    cache.lastPos = currentPos
    cache.lastTime = currentTime
    return cache.velocity
end

function veil_getTargetPart(char)
    if VeilConfig.TargetPart == "Head" then
        return char:FindFirstChild("Head")
    elseif VeilConfig.TargetPart == "Root" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
end

function veil_getClosestSurvivor()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local cam      = workspace.CurrentCamera
    local center   = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local bestDist = VeilConfig.FOV
    local bestTarget = nil

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
            local char = p.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local part = veil_getTargetPart(char)
            if hum and hum.Health > 0 and part then
                local dist3D = (part.Position - myRoot.Position).Magnitude
                if dist3D <= VeilConfig.MaxDist then
                    local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D < bestDist then
                            bestDist   = dist2D
                            bestTarget = { Player = p, Part = part }
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

function veil_setupInterceptor()
    if VeilState.remoteHooked then return end
    task.spawn(function()
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and method == "FireServer" then
                    if self.Name == "Spearthrow" and VeilConfig.Enabled then
                        return nil
                    end
                end
                return oldNamecall(self, ...)
            end)
            VeilState.remoteHooked = true
        end)
    end)
end

veil_setupInterceptor()

function veil_fire()
    if VeilState.attackCooldown then return end
    VeilState.attackCooldown = true
    task.delay(2, function() VeilState.attackCooldown = false end)

    local myChar    = LocalPlayer.Character
    local startPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
    if not startPart then return end

    local startPos   = startPart.Position
    local targetInfo = veil_getClosestSurvivor()
    local aimDir

    if targetInfo and targetInfo.Part then
        local targetPart = targetInfo.Part
        local targetPlayer = targetInfo.Player
        local targetPos = targetPart.Position

        local velocity = Veil_GetRealVelocity(targetPart, targetPlayer.Name)
        local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = horizontalVel.Magnitude

        local distance = (targetPos - startPos).Magnitude
        local timeToHit = distance / VeilConfig.SpearSpeed

        local horizontalPrediction = Vector3.zero
        if speed > 4 and VeilConfig.AutoPredict then
            local factor = VeilConfig.HorizontalPredictFactor
            horizontalPrediction = horizontalVel * timeToHit * factor
        end
        local predictedPos = targetPos + horizontalPrediction

        local autoGravity = math.max(0, distance - 8)
        local gravity = VeilConfig.AutoPredict and autoGravity or VeilConfig.Gravity
        local drop = 0.5 * gravity * (timeToHit ^ 2)
        local finalPos = predictedPos + Vector3.new(0, drop, 0)

        aimDir = (finalPos - startPos).Unit
        VeilState.lastPredictedPos = finalPos
    else
        aimDir = workspace.CurrentCamera.CFrame.LookVector
        VeilState.lastPredictedPos = nil
    end

    pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remotes then
            local killers = remotes:FindFirstChild("Killers")
            if killers then
                local veil = killers:FindFirstChild("Veil")
                if veil and veil:FindFirstChild("Spearthrow") then
                    veil.Spearthrow:FireServer(aimDir, VeilConfig.SpearSpeed, startPos)
                end
            end
        end
    end)

    VeilDraw.FOVCircle.Color = Color3.fromRGB(255, 0, 255)
    if not VeilState.passiveCooldown then
        VeilState.passiveCooldown = true
        task.delay(30, function()
            VeilDraw.FOVCircle.Color = Color3.fromRGB(255, 0, 255)
            VeilState.passiveCooldown = false
        end)
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    local char = LocalPlayer.Character
    local isSpearMode = char and char:GetAttribute("spearmode") == true
    if not VeilConfig.Enabled then return end
    if not isSpearMode then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        VeilState.chargingSpear = true
    elseif isTouch then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local slasher = pGui:FindFirstChild("Slasher-mob")
            if slasher then
                local ctrl = slasher:FindFirstChild("Controls")
                if ctrl then
                    local attackBtn = ctrl:FindFirstChild("attack")
                    if attackBtn and attackBtn.Visible then
                        local pos     = input.Position
                        local absPos  = attackBtn.AbsolutePosition
                        local absSize = attackBtn.AbsoluteSize
                        if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
                            VeilState.chargingSpear = true
                            VeilState.touchInput    = input
                        end
                    end
                end
            end
        end
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input, gp)
    if VeilState.chargingSpear
    and (input == VeilState.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
        VeilState.chargingSpear = false
        if VeilState.touchInput == input then VeilState.touchInput = nil end
        veil_fire()
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    local cam         = workspace.CurrentCamera
    local myChar      = LocalPlayer.Character
    local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true

    if VeilConfig.Enabled and VeilConfig.ShowFOV and isSpearMode then
        VeilDraw.FOVCircle.Visible  = true
        VeilDraw.FOVCircle.Radius   = VeilConfig.FOV
        VeilDraw.FOVCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    else
        VeilDraw.FOVCircle.Visible = false
    end

    if VeilState.chargingSpear and VeilConfig.Enabled and isSpearMode then
        local target = veil_getClosestSurvivor()
        if target and target.Part and target.Part.Parent then
            VeilDraw.Highlight.Parent = target.Part.Parent
            
            if VeilConfig.ShowTargetLaser then
                if not getgenv().KYS_SpearLaserPart then
                    local laser = Instance.new("Part")
                    laser.Name = "SpearSilentAimLaser"
                    laser.Anchored = true
                    laser.CanCollide = false
                    laser.CanTouch = false
                    laser.CastShadow = false
                    laser.Material = Enum.Material.Neon
                    laser.Color = Color3.fromRGB(255, 50, 50)
                    laser.Transparency = 0
                    laser.Parent = workspace
                    getgenv().KYS_SpearLaserPart = laser
                end
                
                local originPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
                if originPart then
                    local originPos = originPart.Position
                    local targetPos = target.Part.Position
                    local dist = (targetPos - originPos).Magnitude
                    if dist > 0.1 then
                        local laser = getgenv().KYS_SpearLaserPart
                        laser.Size = Vector3.new(0.16, 0.16, dist)
                        laser.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
                        laser.Transparency = 0.5
                    end
                end
            else
                if getgenv().KYS_SpearLaserPart then getgenv().KYS_SpearLaserPart.Transparency = 1 end
            end
        else
            VeilDraw.Highlight.Parent = nil
            if getgenv().KYS_SpearLaserPart then getgenv().KYS_SpearLaserPart.Transparency = 1 end
        end
    else
        VeilDraw.Highlight.Parent = nil
        if getgenv().KYS_SpearLaserPart then getgenv().KYS_SpearLaserPart.Transparency = 1 end
    end

    if VeilConfig.Enabled and isSpearMode and VeilState.lastPredictedPos then
        local screenPos, onScreen = cam:WorldToViewportPoint(VeilState.lastPredictedPos)
        local viewport = cam.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

        if onScreen then
            VeilDraw.Tracer.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            local dx = screenPos.X - center.X
            local dy = screenPos.Y - center.Y
            if math.abs(dx) < 1 and math.abs(dy) < 1 then
                VeilDraw.Tracer.Position = center
            else
                local angle = math.atan2(dy, dx)
                local maxX = viewport.X / 2 - 10
                local maxY = viewport.Y / 2 - 10
                local scaleX = maxX / math.abs(dx)
                local scaleY = maxY / math.abs(dy)
                local scale = math.min(scaleX, scaleY)
                local borderPos = Vector2.new(
                    center.X + dx * scale,
                    center.Y + dy * scale
                )
                VeilDraw.Tracer.Position = borderPos
            end
        end
        VeilDraw.Tracer.Visible = true
    else
        VeilDraw.Tracer.Visible = false
    end
end)

VeilSection:AddToggle("Veil_Enabled", {
    Title = "Silent Aim (Veil)",
    Default = VeilConfig.Enabled,
    Callback = function(value)
        VeilConfig.Enabled = value
        if not value then
            VeilState.chargingSpear = false
            VeilState.lastPredictedPos = nil
        end
    end,
})

VeilSection:AddToggle("Veil_ShowFOV", {
    Title = "Show FOV",
    Default = VeilConfig.ShowFOV,
    Callback = function(value)
        VeilConfig.ShowFOV = value
    end,
})

VeilSection:AddToggle("Veil_ShowTargetLaser", {
    Title = "Show Target Laser",
    Default = VeilConfig.ShowTargetLaser,
    Callback = function(value)
        VeilConfig.ShowTargetLaser = value
    end,
})

VeilSection:AddSlider("Veil_FOV", {
    Title = "FOV",
    Default = VeilConfig.FOV,
    Min = 1,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        VeilConfig.FOV = value
    end,
})

VeilSection:AddSlider("Veil_SpearSpeed", {
    Title = "Spear Speed",
    Min = 1,
    Max = 500,
    Default = VeilConfig.SpearSpeed,
    Rounding = 0,
    Callback = function(value)
        VeilConfig.SpearSpeed = value
    end,
})

VeilSection:AddSlider("Veil_Gravity", {
    Title = "Gravity",
    Min = 0,
    Max = 300,
    Default = VeilConfig.Gravity,
    Rounding = 1,
    Callback = function(value)
        VeilConfig.Gravity = value
    end,
})

VeilSection:AddSlider("Veil_MaxDist", {
    Title = "Max Distance",
    Min = 1,
    Max = 500,
    Default = VeilConfig.MaxDist,
    Rounding = 0,
    Callback = function(value)
        VeilConfig.MaxDist = value
    end,
})

VeilSection:AddToggle("Veil_AutoPredict", {
    Title = "Auto Predict",
    Default = VeilConfig.AutoPredict,
    Callback = function(value)
        VeilConfig.AutoPredict = value
    end,
})

VeilSection:AddDropdown("Veil_TargetPart", {
    Title = "Target Part",
    Values = {"Torso", "Head", "Root"},
    Default = VeilConfig.TargetPart,
    Callback = function(value)
        VeilConfig.TargetPart = value
    end,
})

VeilSection:AddSlider("Veil_HorizontalPredict", {
    Title = "Horizontal Predict Factor",
    Min = 0,
    Max = 3,
    Default = VeilConfig.HorizontalPredictFactor,
    Rounding = 2,
    Callback = function(value)
        VeilConfig.HorizontalPredictFactor = value
    end,
})

-- Floating UI toggle
if game.CoreGui:FindFirstChild("ToggleUI") then
    game.CoreGui.ToggleUI:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ToggleUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = game.CoreGui

local border = Instance.new("Frame")
border.Parent = gui
border.Size = UDim2.new(0, 0, 0, 0)
border.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
border.ZIndex = 1

local borderCorner = Instance.new("UICorner")
borderCorner.CornerRadius = UDim.new(0, 14)
borderCorner.Parent = border

local button = Instance.new("ImageButton")
button.Parent = gui
button.Size = UDim2.new(0, 60, 0, 60)
button.Position = UDim2.new(0, 60, 0.2, 0)
button.BackgroundTransparency = 1
button.ZIndex = 999999
button.AutoButtonColor = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button

local imgOn = "rbxassetid://86279908104891"
local imgOff = "rbxassetid://86279908104891"
button.Image = imgOn
button.ScaleType = Enum.ScaleType.Fit

local function UpdateBorder()
    local offset = (border.Size.X.Offset - button.Size.X.Offset) / 2
    border.Position = UDim2.new(
        button.Position.X.Scale,
        button.Position.X.Offset - offset,
        button.Position.Y.Scale,
        button.Position.Y.Offset - offset
    )
end

UpdateBorder()

local dragging = false
local dragStart, startPos

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        UpdateBorder()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local isOpen = true
button.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if Window then
        Window:Minimize(not isOpen)
    end
    button.Image = isOpen and imgOff or imgOn
end)
