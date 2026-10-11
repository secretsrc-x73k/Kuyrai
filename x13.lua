local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/secretsrc-x73k/NewUI/refs/heads/main/newui.lua"))()
local Players = game:GetService("Players")
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
    Object = Window:AddTab({ Title = "Object", Icon = "box" })
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
        ShowName = false,
        ShowIcon = false,
        MaxDistance = 2000
    }

    local ActiveESP = {}

    local function GetCurrentItem(player)
        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")
        if character then
            for _, obj in ipairs(character:GetChildren()) do
                if ITEM_DATABASE[obj.Name] then return obj.Name end
            end
        end
        if backpack then
            for _, obj in ipairs(backpack:GetChildren()) do
                if ITEM_DATABASE[obj.Name] then return obj.Name end
            end
        end
        return nil
    end

    local function UpdateESPState()
        for _, entry in pairs(ActiveESP) do
            if entry.Icon then entry.Icon.Visible = ESP_Settings.ShowIcon end
            if entry.Text then entry.Text.Visible = ESP_Settings.ShowName end
            if entry.Billboard then entry.Billboard.MaxDistance = ESP_Settings.MaxDistance end
        end
    end

    local function CreatePlayerESP(player)
        if player == LocalPlayer then return end

        local function SetupUI(character)
            local head = character:WaitForChild("Head", 10)
            if not head then return end

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ItemESP"
            billboard.Adornee = head
            billboard.Size = UDim2.fromOffset(100, 50)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = ESP_Settings.MaxDistance
            billboard.Parent = head

            local container = Instance.new("Frame")
            container.Size = UDim2.fromScale(1, 1)
            container.BackgroundTransparency = 1
            container.Parent = billboard

            local layout = Instance.new("UIListLayout")
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            layout.Padding = UDim.new(0, 2)
            layout.Parent = container

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.fromOffset(30, 30)
            icon.BackgroundTransparency = 1
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Visible = ESP_Settings.ShowIcon
            icon.Parent = container

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0, 14)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 9
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.Visible = ESP_Settings.ShowName
            nameLabel.Parent = container

            local entry = {Billboard = billboard, Icon = icon, Text = nameLabel}
            ActiveESP[player.UserId] = entry

            local function Refresh()
                local itemName = GetCurrentItem(player)
                local data = ITEM_DATABASE[itemName]
                if data then
                    billboard.Enabled = true
                    icon.Image = data.Icon
                    nameLabel.Text = itemName:upper()
                    nameLabel.TextColor3 = data.Color
                else
                    billboard.Enabled = false
                end
            end

            -- ประสิทธิภาพสูง: อัปเดตเฉพาะเมื่อมีการเปลี่ยนไอเทม
            local connections = {}
            local backpack = player:WaitForChild("Backpack", 5)
            
            local function TrackFolder(folder)
                if not folder then return end
                table.insert(connections, folder.ChildAdded:Connect(Refresh))
                table.insert(connections, folder.ChildRemoved:Connect(Refresh))
            end

            TrackFolder(character)
            TrackFolder(backpack)
            Refresh()

            character.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    for _, c in ipairs(connections) do c:Disconnect() end
                    ActiveESP[player.UserId] = nil
                    billboard:Destroy()
                end
            end)
        end

        player.CharacterAdded:Connect(SetupUI)
        if player.Character then task.spawn(SetupUI, player.Character) end
    end

    local Itobj = Tabs.Teleport:AddSection("ESP ITEM")

    Tabs.Object:AddToggle("ItemESP_Icon", {
        Title = "Show Item Icon",
        Default = false,
        Callback = function(v) ESP_Settings.ShowIcon = v UpdateESPState() end
    })
    
    -- UI Controls
    Tabs.Object:AddToggle("ItemESP_Name", {
        Title = "Show Name Item",
        Default = false,
        Callback = function(v) ESP_Settings.ShowName = v UpdateESPState() end
    })

    Tabs.Object:AddSlider("ItemESP_Dist", {
        Title = "Max Distance",
        Min = 100, Max = 2000, Default = 1000,
        Rounding = 0,
        Callback = function(v) ESP_Settings.MaxDistance = v UpdateESPState() end
    })

    for _, p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end
    Players.PlayerAdded:Connect(CreatePlayerESP)
end

InitItem()
