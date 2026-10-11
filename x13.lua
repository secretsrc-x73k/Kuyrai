local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local Players = game:GetService("Players")
    local ContentProvider = game:GetService("ContentProvider")
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
        ["Adrenaline Shot"] = {
            Icon = "rbxassetid://135388781922226",
            Color = Color3.fromRGB(255, 60, 60)
        },
        ["Bandage"] = {
            Icon = "rbxassetid://97791520639443",
            Color = Color3.fromRGB(80, 255, 80)
        },
        ["Flashlight"] = {
            Icon = "rbxassetid://103299939715311",
            Color = Color3.fromRGB(255, 255, 255)
        },
        ["Gate"] = {
            Icon = "rbxassetid://131249244284700",
            Color = Color3.fromRGB(100, 200, 255)
        },
        ["Holy Water"] = {
            Icon = "rbxassetid://86130208614143",
            Color = Color3.fromRGB(0, 150, 255)
        },
        ["Motion Tracker"] = {
            Icon = "rbxassetid://92303584765773",
            Color = Color3.fromRGB(150, 150, 150)
        },
        ["Riot Shield"] = {
            Icon = "rbxassetid://95718705901699",
            Color = Color3.fromRGB(80, 80, 80)
        },
        ["Shadow Clone"] = {
            Icon = "rbxassetid://134088840518889",
            Color = Color3.fromRGB(128, 0, 128)
        },
        ["Twist of Fate"] = {
            Icon = "rbxassetid://98397448432071",
            Color = Color3.fromRGB(255, 255, 0)
        },
        ["WaxBound Candle"] = {
            Icon = "rbxassetid://110413686590821",
            Color = Color3.fromRGB(255, 165, 0)
        },
        ["Parry Dagger"] = {
            Icon = "rbxassetid://76822757630703",
            Color = Color3.fromRGB(200, 200, 200)
        }
    }
    local ESP_Settings = {
        ShowName = true,
        ShowIcon = true,
        MaxDistance = 2000
    }
    local ImageLoadStatus = {}
    for itemName, data in pairs(ITEM_DATABASE) do
        task.spawn(function()
            local loaded = false
            local success = pcall(function()
                ContentProvider:PreloadAsync({data.Icon}, function(_, status)
                    loaded = status == Enum.AssetFetchStatus.Success
                end)
            end)
            ImageLoadStatus[itemName] = success and loaded
        end)
    end
    local function GetPlayerHeldItem(character)
        if not character then
            return nil
        end
        for _, obj in ipairs(character:GetDescendants()) do
            if ITEM_DATABASE[obj.Name] then
                return obj.Name
            end
        end
        return nil
    end
    local function CreatePlayerESP(player)
        if player == LocalPlayer then
            return
        end
        local function SetupUI(character)
            local head = character:WaitForChild("Head", 10)
            if not head or not character.Parent then
                return
            end
            local existing = head:FindFirstChild("PlayerItemESP")
            if existing then
                existing:Destroy()
            end
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "PlayerItemESP"
            billboard.Adornee = head
            billboard.Size = UDim2.fromOffset(150, 58)
            billboard.StudsOffset = Vector3.new(0, 3.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Enabled = false
            billboard.Parent = head
            local container = Instance.new("Frame")
            container.Size = UDim2.fromScale(1, 1)
            container.BackgroundTransparency = 1
            container.Parent = billboard
            local layout = Instance.new("UIListLayout")
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            layout.Parent = container
            local icon = Instance.new("ImageLabel")
            icon.Name = "ItemImage"
            icon.Size = UDim2.fromOffset(35, 35)
            icon.BackgroundTransparency = 1
            icon.ScaleType = Enum.ScaleType.Fit
            icon.LayoutOrder = 1
            icon.Visible = false
            icon.Parent = container
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "ItemName"
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, 0, 0, 18)
            nameLabel.Font = Enum.Font.GothamBlack
            nameLabel.TextSize = 13
            nameLabel.TextStrokeTransparency = 0.4
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.LayoutOrder = 2
            nameLabel.Visible = false
            nameLabel.Parent = container
            task.spawn(function()
                while billboard.Parent and character.Parent do
                    local itemName = GetPlayerHeldItem(character)
                    local data = itemName and ITEM_DATABASE[itemName]
                    local camera = workspace.CurrentCamera
                    if data and camera then
                        local distance = (head.Position - camera.CFrame.Position).Magnitude
                        if distance <= ESP_Settings.MaxDistance then
                            billboard.Enabled = true
                            icon.Image = data.Icon
                            icon.Visible = ESP_Settings.ShowIcon
                                and ImageLoadStatus[itemName] ~= false
                            nameLabel.Text = itemName:upper()
                            nameLabel.TextColor3 = data.Color
                            nameLabel.Visible = ESP_Settings.ShowName
                        else
                            billboard.Enabled = false
                        end
                    else
                        billboard.Enabled = false
                    end
                    task.wait(0.1)
                end
                if billboard.Parent then
                    billboard:Destroy()
                end
            end)
        end
        if player.Character then
            task.spawn(SetupUI, player.Character)
        end
        player.CharacterAdded:Connect(SetupUI)
    end
    local function Init()
        for _, player in ipairs(Players:GetPlayers()) do
            CreatePlayerESP(player)
        end
        Players.PlayerAdded:Connect(CreatePlayerESP)
    end
    Tabs.Object:AddToggle("ItemESP_Name", {
        Title = "Show Name Item",
        Default = true,
        Callback = function(value)
            ESP_Settings.ShowName = value
        end
    })
    Tabs.Object:AddToggle("ItemESP_Icon", {
        Title = "Item Image",
        Default = true,
        Callback = function(value)
            ESP_Settings.ShowIcon = value
        end
    })
    Init()
end
InitItem()
