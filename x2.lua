local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [[ CONFIGURATION ]]
getgenv().VD = {
    VeilEnabled = false,
    VeilShowFOV = true,
    VeilWallCheck = true,
    VeilShowTracker = false,
    VeilAutoPredict = true,
    VeilFOV = 150,
    VeilMaxDist = 600,
    VeilSpearSpeed = 165,
    VeilGravity = 103,
    VeilAuraSpearSpeed = 165,
    VeilAuraSpearGravity = 96,
    VeilLeadMultiplier = 1.4,
    TargetPart = "HumanoidRootPart",
    FOVColor = Color3.fromRGB(255, 255, 255),
    TrackerColor = Color3.fromRGB(255, 0, 0)
}

-- [[ INTERNAL STATE ]]
local VeilState = {
    target = nil,
    lookVector = nil,
    velHistory = {},
    lastPos = nil,
    lastTime = nil
}

local VeilVisuals = {
    FOVCircle = Drawing.new("Circle"),
    TrackerLine = Drawing.new("Line")
}

-- [[ MATH & LOGIC ]]
local function IsVisible(targetPart, character)
    if not VD.VeilWallCheck then return true end
    local origin = Camera.CFrame.Position
    local path = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, character, Workspace:FindFirstChild("Map")}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, path, raycastParams)
    return result == nil
end

local function GetRole()
    if Player.Team and string.find(string.lower(Player.Team.Name), "killer") then return "Killer" end
    return "Killer" -- Default for Testing
end

local function solvePitch(p, d, dy)
    local s2 = p.v0 * p.v0
    local root = s2 * s2 - p.g * (p.g * d * d + 2 * dy * s2)
    if root < 0 then return math.atan2(dy, d) end
    return math.atan((s2 - math.sqrt(root)) / (p.g * d))
end

local function getVelocity(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return Vector3.zero end
    local now = os.clock()
    local last = VeilState.velHistory[char]
    local measured = Vector3.zero
    if last and now - last.t > 0 then
        measured = (root.Position - last.pos) / (now - last.t)
    end
    local smooth = last and last.smooth or measured
    smooth = smooth:Lerp(measured, 0.5)
    VeilState.velHistory[char] = { pos = root.Position, t = now, smooth = smooth }
    return Vector3.new(smooth.X, 0, smooth.Z)
end

-- [[ CORE UPDATE ]]
local function UpdateAimbot()
    if GetRole() ~= "Killer" or not VD.VeilEnabled then
        VeilVisuals.FOVCircle.Visible = false
        VeilVisuals.TrackerLine.Visible = false
        return
    end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Visual: FOV
    VeilVisuals.FOVCircle.Position = center
    VeilVisuals.FOVCircle.Radius = VD.VeilFOV
    VeilVisuals.FOVCircle.Color = VD.FOVColor
    VeilVisuals.FOVCircle.Visible = VD.VeilShowFOV

    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local nearest, bestDist = nil, VD.VeilFOV

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild(VD.TargetPart) then
            local targetPart = p.Character[VD.TargetPart]
            local sp, on = Camera:WorldToViewportPoint(targetPart.Position)
            
            if on and sp.Z > 0 then
                local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                local worldDist = (targetPart.Position - hrp.Position).Magnitude
                
                if screenDist < bestDist and worldDist <= VD.VeilMaxDist then
                    if IsVisible(targetPart, p.Character) then
                        bestDist = screenDist
                        nearest = p
                    end
                end
            end
        end
    end

    if nearest and nearest.Character then
        local tpPart = nearest.Character[VD.TargetPart]
        local origin = hrp.Position
        
        local isSpecial = char:GetAttribute("special") or false
        local prof = {
            v0 = (isSpecial and VD.VeilAuraSpearSpeed or VD.VeilSpearSpeed),
            g = (isSpecial and VD.VeilAuraSpearGravity or VD.VeilGravity)
        }

        local aimPoint = tpPart.Position
        if VD.VeilAutoPredict then
            local vel = getVelocity(nearest.Character)
            local dist = (aimPoint - origin).Magnitude
            local timeToHit = dist / prof.v0
            aimPoint = aimPoint + (vel * (timeToHit + 0.03) * VD.VeilLeadMultiplier)
        end

        local adir = aimPoint - origin
        local hDist = Vector3.new(adir.X, 0, adir.Z).Magnitude
        local pitch = solvePitch(prof, hDist, adir.Y)
        
        VeilState.lookVector = Vector3.new(adir.X, 0, adir.Z).Unit * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
        
        -- Visual: Tracker
        if VD.VeilShowTracker then
            local sp, vis = Camera:WorldToViewportPoint(tpPart.Position)
            VeilVisuals.TrackerLine.From = Vector2.new(center.X, Camera.ViewportSize.Y)
            VeilVisuals.TrackerLine.To = Vector2.new(sp.X, sp.Y)
            VeilVisuals.TrackerLine.Color = VD.TrackerColor
            VeilVisuals.TrackerLine.Visible = vis
        end
    else
        VeilState.lookVector = nil
        VeilVisuals.TrackerLine.Visible = false
    end
end

-- [[ INTERCEPTOR ]]
local function SetupHooks()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if not checkcaller() and method == "FireServer" and self.Name == "Spearthrow" and VD.VeilEnabled then
            if VeilState.lookVector then
                args[1] = VeilState.lookVector
            end
            return oldNamecall(self, unpack(args))
        end
        return oldNamecall(self, ...)
    end)
end

-- [[ UI GENERATION ]]
local Window = Fluent:CreateWindow({
    Title = "HyperX | Silent Veil V1",
    SubTitle = "Complete Edition",
    TabWidth = 160, Size = UDim2.fromOffset(580, 520), Acrylic = true,
    Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main Aimbot", Icon = "target" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:AddToggle("VeilToggle", {Title = "Enable Silent Aim", Default = false, Callback = function(v) VD.VeilEnabled = v end})
Tabs.Main:AddToggle("WallCheck", {Title = "Wall Check", Default = true, Callback = function(v) VD.VeilWallCheck = v end})
Tabs.Main:AddToggle("Predict", {Title = "Auto Prediction", Default = true, Callback = function(v) VD.VeilAutoPredict = v end})

Tabs.Main:AddDropdown("Part", {
    Title = "Target Body Part",
    Values = {"HumanoidRootPart", "Head", "UpperTorso"},
    Default = "HumanoidRootPart",
    Callback = function(v) VD.TargetPart = v end
})

Tabs.Main:AddSlider("FOV", {Title = "FOV Radius", Min = 30, Max = 800, Default = 150, Rounding = 0, Callback = function(v) VD.VeilFOV = v end})
Tabs.Main:AddSlider("Speed", {Title = "Spear Speed", Min = 100, Max = 300, Default = 165, Rounding = 0, Callback = function(v) VD.VeilSpearSpeed = v end})
Tabs.Main:AddSlider("Gravity", {Title = "Spear Gravity", Min = 50, Max = 200, Default = 103, Rounding = 0, Callback = function(v) VD.VeilGravity = v end})
Tabs.Main:AddSlider("Lead", {Title = "Prediction Strength", Min = 0.5, Max = 3.0, Default = 1.4, Rounding = 1, Callback = function(v) VD.VeilLeadMultiplier = v end})

Tabs.Settings:AddToggle("ShowFOV", {Title = "Draw FOV Circle", Default = true, Callback = function(v) VD.VeilShowFOV = v end})
Tabs.Settings:AddToggle("ShowTracker", {Title = "Draw Tracker Line", Default = false, Callback = function(v) VD.VeilShowTracker = v end})

-- [[ INITIALIZE ]]
RunService.RenderStepped:Connect(function()
    pcall(UpdateAimbot)
end)

SetupHooks()
Fluent:Notify({Title = "HyperX Assistant", Content = "Script Loaded Successfully", Duration = 5})
