local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "HyperX | Weather Engine (Original Logic)",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Environment", Icon = "sun" })
}

-- // Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // [BACKUP ORIGINAL] เก็บค่าดั้งเดิมไว้ตาม Codex
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- // [PRESETS] ดึงมาจากตาราง KYS_WeatherPresets ใน Codex เป๊ะๆ
local WeatherPresets = {
    ["Default"] = {},
    ["Christmas (Snow)"] = {
        Lighting = { FogColor = Color3.fromRGB(150, 180, 220), FogEnd = 200, ClockTime = 8, OutdoorAmbient = Color3.fromRGB(100, 120, 150) },
        Atmosphere = { Density = 0.5, Color = Color3.fromRGB(180, 200, 220), Decay = Color3.fromRGB(150, 180, 220), Haze = 5, Glare = 0 },
        Particle = { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)), Size = NumberSequence.new(1.5), Rate = 150, Speed = NumberRange.new(15, 25), Lifetime = NumberRange.new(4, 6), EmissionDirection = Enum.NormalId.Bottom, RotSpeed = NumberRange.new(-45, 45) }
    },
    ["Heavy Rain (Storm)"] = {
        Lighting = { FogColor = Color3.fromRGB(50, 50, 60), FogEnd = 150, OutdoorAmbient = Color3.fromRGB(40, 40, 50), Brightness = 0.2, ClockTime = 12 },
        CC = { TintColor = Color3.fromRGB(150, 150, 180), Contrast = 0.2, Saturation = -0.5 },
        Particle = { Texture = "rbxasset://textures/particles/sparkles_main.dds", AnchorSize = Vector3.new(260, 1, 260), CameraOffset = Vector3.new(0, 38, -18), Squash = NumberSequence.new(16), Color = ColorSequence.new(Color3.fromRGB(235, 245, 255)), Size = NumberSequence.new(1.25), Rate = 2600, Speed = NumberRange.new(110, 145), Lifetime = NumberRange.new(0.85, 1.25), EmissionDirection = Enum.NormalId.Bottom, Transparency = NumberSequence.new(0), Acceleration = Vector3.new(-18, -75, 0), SpreadAngle = Vector2.new(3, 3), LightEmission = 1 }
    },
    ["Autumn (Musim Gugur)"] = {
        Lighting = { FogColor = Color3.fromRGB(200, 150, 80), FogEnd = 500, OutdoorAmbient = Color3.fromRGB(180, 140, 70), ClockTime = 16.5 },
        CC = { TintColor = Color3.fromRGB(255, 220, 180), Contrast = 0.1, Saturation = 0.2 },
        Particle = { Texture = "rbxasset://textures/particles/sparkles_main.dds", AnchorSize = Vector3.new(210, 1, 210), CameraOffset = Vector3.new(0, 28, -16), Squash = NumberSequence.new(3.2), Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 45)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(235, 95, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 45, 10)) }), Size = NumberSequence.new(2.05), Rate = 360, Speed = NumberRange.new(8, 15), Lifetime = NumberRange.new(6, 10), EmissionDirection = Enum.NormalId.Bottom, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-220, 220), Transparency = NumberSequence.new(0), Acceleration = Vector3.new(18, -8, 6), SpreadAngle = Vector2.new(38, 38), LightEmission = 0.6 }
    },
    ["Cherry Blossom (Sakura)"] = {
        Lighting = { FogColor = Color3.fromRGB(255, 200, 220), FogEnd = 600, OutdoorAmbient = Color3.fromRGB(255, 180, 200), ClockTime = 9 },
        CC = { TintColor = Color3.fromRGB(255, 230, 240), Saturation = 0.3 },
        Particle = { Texture = "rbxasset://textures/particles/sparkles_main.dds", AnchorSize = Vector3.new(160, 1, 160), CameraOffset = Vector3.new(0, 25, -18), Squash = NumberSequence.new(1.2), Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 235)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 165, 205)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 180)) }), Size = NumberSequence.new(1.25), Rate = 190, Speed = NumberRange.new(5, 10), Lifetime = NumberRange.new(7, 10), EmissionDirection = Enum.NormalId.Bottom, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-170, 170), Transparency = NumberSequence.new(0), Acceleration = Vector3.new(14, -5, 5), SpreadAngle = Vector2.new(32, 32), LightEmission = 0.55 }
    },
    ["Sunset (Golden Hour)"] = {
        Lighting = { FogColor = Color3.fromRGB(255, 120, 50), FogEnd = 1200, OutdoorAmbient = Color3.fromRGB(200, 100, 50), ClockTime = 17.5, Brightness = 1.5 },
        CC = { TintColor = Color3.fromRGB(255, 200, 150), Contrast = 0.2, Saturation = 0.4 }
    },
    ["Blood Moon (Spooky)"] = {
        Lighting = { FogColor = Color3.fromRGB(150, 10, 10), FogEnd = 500, OutdoorAmbient = Color3.fromRGB(80, 0, 0), ClockTime = 0, Brightness = 0.3 },
        CC = { TintColor = Color3.fromRGB(255, 50, 50), Contrast = 0.4, Saturation = 0.5 },
        Atmosphere = { Density = 0.35, Color = Color3.fromRGB(255, 0, 0), Decay = Color3.fromRGB(100, 0, 0), Haze = 5, Glare = 0 }
    },
    ["Toxic Wasteland"] = {
        Lighting = { FogColor = Color3.fromRGB(80, 150, 50), FogEnd = 250, OutdoorAmbient = Color3.fromRGB(50, 120, 40), ClockTime = 12, Brightness = 1 },
        CC = { TintColor = Color3.fromRGB(150, 255, 150), Contrast = 0.1, Saturation = 0.3 },
        Particle = { Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(Color3.fromRGB(100, 255, 50)), Size = NumberSequence.new(0.8), Rate = 200, Speed = NumberRange.new(50, 60), Lifetime = NumberRange.new(2, 3), EmissionDirection = Enum.NormalId.Bottom, Transparency = NumberSequence.new(0.5) }
    },
    ["Vaporwave (Synthwave)"] = {
        Lighting = { FogColor = Color3.fromRGB(200, 50, 255), FogEnd = 500, OutdoorAmbient = Color3.fromRGB(150, 0, 200), ClockTime = 20, Brightness = 1 },
        CC = { TintColor = Color3.fromRGB(255, 100, 255), Contrast = 0.3, Saturation = 0.5 }
    },
    ["Midnight (Pitch Black)"] = {
        Lighting = { FogColor = Color3.fromRGB(0, 0, 0), FogEnd = 100, OutdoorAmbient = Color3.fromRGB(0, 0, 0), Brightness = 0, ClockTime = 0 },
        CC = { TintColor = Color3.fromRGB(50, 50, 50), Contrast = 0.5, Saturation = -0.8 }
    }
}

-- // [CORE FUNCTION] VD_ApplyWeather (Exact Copy from Codex)
local function ApplyWeather(themeName)
    local theme = WeatherPresets[themeName] or WeatherPresets["Default"]
    
    -- Cleanup
    if getgenv().VD_WeatherCC then getgenv().VD_WeatherCC:Destroy() end
    if getgenv().VD_WeatherAtmosphere then getgenv().VD_WeatherAtmosphere:Destroy() end
    if getgenv().VD_ParticleAnchor then getgenv().VD_ParticleAnchor:Destroy() end
    
    -- Apply Atmosphere
    if theme.Atmosphere then
        local atm = Instance.new("Atmosphere", Lighting)
        atm.Name = "VD_WeatherAtmosphere"
        for k, v in pairs(theme.Atmosphere) do pcall(function() atm[k] = v end) end
        getgenv().VD_WeatherAtmosphere = atm
    end
    
    -- Apply ColorCorrection
    if theme.CC then
        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Name = "VD_WeatherCC"
        for k, v in pairs(theme.CC) do pcall(function() cc[k] = v end) end
        getgenv().VD_WeatherCC = cc
    end
    
    -- Apply Lighting
    if theme.Lighting then
        for k, v in pairs(theme.Lighting) do pcall(function() Lighting[k] = v end) end
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end

    -- Setup Particles (เม็ดฝน/หิมะ/ใบไม้ แบบเต็มระบบ)
    if theme.Particle then
        local anchor = Instance.new("Part", workspace)
        anchor.Name = "VD_WeatherAnchor"; anchor.Transparency = 1; anchor.CanCollide = false; anchor.Anchored = true
        anchor.Size = theme.Particle.AnchorSize or Vector3.new(120, 1, 120)
        anchor:SetAttribute("VD_CameraOffsetX", theme.Particle.CameraOffset and theme.Particle.CameraOffset.X or 0)
        anchor:SetAttribute("VD_CameraOffsetY", theme.Particle.CameraOffset and theme.Particle.CameraOffset.Y or 30)
        anchor:SetAttribute("VD_CameraOffsetZ", theme.Particle.CameraOffset and theme.Particle.CameraOffset.Z or 0)
        
        local pe = Instance.new("ParticleEmitter", anchor)
        pe.Enabled = true; pe.EmissionDirection = Enum.NormalId.Bottom
        for k, v in pairs(theme.Particle) do
            if k ~= "AnchorSize" and k ~= "CameraOffset" then pcall(function() pe[k] = v end) end
        end

        -- พิเศษ: Heavy Rain มี 3 ชั้นตามต้นฉบับ
        if themeName == "Heavy Rain (Storm)" then
            local nearRain = pe:Clone(); nearRain.Rate = 1800; nearRain.Size = NumberSequence.new(1.65); nearRain.Squash = NumberSequence.new(20); nearRain.Parent = anchor
            local rainSheet = pe:Clone(); rainSheet.Texture = "rbxasset://textures/particles/smoke_main.dds"; rainSheet.Rate = 650; rainSheet.Size = NumberSequence.new(3.2); rainSheet.Transparency = NumberSequence.new(0.45); rainSheet.Parent = anchor
        end
        
        -- พิเศษ: Autumn มีใบไม้ใหญ่ตามต้นฉบับ
        if themeName == "Autumn (Musim Gugur)" then
            local bigLeaves = pe:Clone(); bigLeaves.Rate = 150; bigLeaves.Size = NumberSequence.new(3.1); bigLeaves.Squash = NumberSequence.new(4.5); bigLeaves.Parent = anchor
        end

        getgenv().VD_ParticleAnchor = anchor
    end
end

-- // [LOGIC] Remove Fog (ปุ่มแยกตามสั่ง)
local function UpdateFog()
    if _G.RemoveFogEnabled then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        if getgenv().VD_WeatherAtmosphere then getgenv().VD_WeatherAtmosphere.Density = 0 end
    else
        local theme = KYS_WeatherPresets[_G.CurrentWeather]
        Lighting.FogEnd = (theme and theme.Lighting and theme.Lighting.FogEnd) or originalLighting.FogEnd
    end
end

-- // UI Elements
Tabs.Main:AddToggle("RemoveFog", {
    Title = "Remove Fog",
    Default = false,
    Callback = function(v) _G.RemoveFogEnabled = v UpdateFog() end
})

Tabs.Main:AddDropdown("Weather", {
    Title = "Select Weather Theme",
    Values = {"Default", "Christmas (Snow)", "Heavy Rain (Storm)", "Autumn (Musim Gugur)", "Cherry Blossom (Sakura)", "Sunset (Golden Hour)", "Blood Moon (Spooky)", "Toxic Wasteland", "Vaporwave (Synthwave)", "Midnight (Pitch Black)"},
    Default = "Default",
    Callback = function(v) _G.CurrentWeather = v ApplyWeather(v) UpdateFog() end
})

-- // [LOOP] Particle Follow (Exact Camera Logic from Codex)
RunService.Heartbeat:Connect(function()
    local anchor = getgenv().VD_ParticleAnchor
    local camera = workspace.CurrentCamera
    if anchor and camera then
        local offset = Vector3.new(anchor:GetAttribute("VD_CameraOffsetX") or 0, anchor:GetAttribute("VD_CameraOffsetY") or 30, anchor:GetAttribute("VD_CameraOffsetZ") or 0)
        anchor.CFrame = CFrame.new(camera.CFrame.Position + camera.CFrame.RightVector * offset.X + Vector3.new(0, offset.Y, 0) + camera.CFrame.LookVector * math.abs(offset.Z))
    end
    if _G.RemoveFogEnabled then Lighting.FogEnd = 100000 end
end)

Window:SelectTab(1)
