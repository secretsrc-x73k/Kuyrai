local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "ITEM",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Object = Window:AddTab({
        Title = "Object",
        Icon = "box"
    })
}

local function InitItem()
    local ITEM_DATABASE = {
        ["Adrenaline Shot"] = {Icon = "rbxassetid://135388781922226", Color = Color3.fromRGB(255, 60, 60)},
        ["Bandage"] = {Icon = "rbxassetid://97791520639443", Color = Color3.fromRGB(80, 255, 80)},
        ["Flashlight"] = {Icon = "rbxassetid://103299939715311", Color = Color3.fromRGB(255, 255, 255)},
        ["Gate"] = {Icon = "rbxassetid://131249244284700", Color = Color3.fromRGB(100, 200, 255)},
        ["Holy Water"] = {Icon = "rbxassetid://86130208614143", Color = Color3.fromRGB(0, 150, 255)},
        ["Motion Tracker"] = {Icon = "rbxassetid://92303584765773", Color = Color3.fromRGB(150, 150, 150)},
        ["Riot Shield"] = {Icon = "rbxassetid://95718705901699", Color = Color3.fromRGB(80, 80, 80)},
        ["Shadow Clone"] = {Icon = "rbxassetid://134088840518889", Color = Color3.fromRGB(128, 0, 128)},
        ["Twist of Fate"] = {Icon = "rbxassetid://98397448432071", Color = Color3.fromRGB(255, 255, 0)},
        ["WaxBound Candle"] = {Icon = "rbxassetid://110413686590821", Color = Color3.fromRGB(255, 165, 0)},
        ["Parrying Dagger"] = {Icon = "rbxassetid://76822757630703", Color = Color3.fromRGB(200, 200, 200)}
    }

    local ESP_Settings = {
        ShowName = true,
        ShowIcon = true,
        MaxDistance = 2000
    }

    -- ฟังก์ชันตรวจสอบไอเท็มทั้งในตัวละคร (ถืออยู่) และใน Backpack (สะพาย/เก็บไว้)
    local function GetCurrentItem(player)
        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")
        
        -- 1. เช็คในตัวละคร (ที่ถืออยู่)
        if character then
            for _, obj in ipairs(character:GetChildren()) do
                if ITEM_DATABASE[obj.Name] then return obj.Name end
            end
        end
        
        -- 2. เช็คใน Backpack (กรณีเก็บไว้หรือสะพายหลัง)
        if backpack then
            for _, obj in ipairs(backpack:GetChildren()) do
                if ITEM_DATABASE[obj.Name] then return obj.Name end
            end
        end
        
        return nil
    end

    local function CreatePlayerESP(player)
        if player == LocalPlayer then return end

        local function SetupUI(character)
            local head = character:WaitForChild("Head", 15)
            if not head then return end

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ItemESP_Root"
            billboard.Adornee = head
            billboard.Size = UDim2.fromOffset(150, 60)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.ResetOnSpawn = false
            billboard.Parent = head

            local container = Instance.new("Frame")
            container.Size = UDim2.fromScale(1, 1)
            container.BackgroundTransparency = 1
            container.Parent = billboard

            local layout = Instance.new("UIListLayout")
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 4)
            layout.Parent = container

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.fromOffset(35, 35)
            icon.BackgroundTransparency = 1
            icon.ScaleType = Enum.ScaleType.Fit
            icon.LayoutOrder = 1
            icon.Parent = container

            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, 0, 0, 18)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.LayoutOrder = 2
            nameLabel.Parent = container

            local connection
            connection = RunService.RenderStepped:Connect(function()
                -- ตรวจสอบความมีอยู่ของ Player และ Character ตลอดเวลา
                if not player or not player.Parent or not character or not character.Parent or not head or not head.Parent then
                    billboard:Destroy()
                    connection:Disconnect()
                    return
                end

                local itemName = GetCurrentItem(player)
                local data = itemName and ITEM_DATABASE[itemName]
                local camera = workspace.CurrentCamera

                if data and camera then
                    local dist = (head.Position - camera.CFrame.Position).Magnitude
                    if dist <= ESP_Settings.MaxDistance then
                        billboard.Enabled = true
                        icon.Image = data.Icon
                        icon.Visible = ESP_Settings.ShowIcon
                        nameLabel.Text = itemName:upper()
                        nameLabel.TextColor3 = data.Color
                        nameLabel.Visible = ESP_Settings.ShowName
                    else
                        billboard.Enabled = false
                    end
                else
                    billboard.Enabled = false
                end
            end)
        end

        player.CharacterAdded:Connect(SetupUI)
        if player.Character then task.spawn(SetupUI, player.Character) end
    end

    -- UI Toggles
    Tabs.Object:AddToggle("ItemESP_Name", {
        Title = "Show Name Item",
        Default = true,
        Callback = function(v) ESP_Settings.ShowName = v end
    })

    Tabs.Object:AddToggle("ItemESP_Icon", {
        Title = "Show Item Icon",
        Default = true,
        Callback = function(v) ESP_Settings.ShowIcon = v end
    })

    for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end
    Players.PlayerAdded:Connect(CreatePlayerESP)
end

InitItem()
