local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()

local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "Violence District",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

Main = Window:AddTab({ Title = "Main", Icon = "home" })

getgenv().AutoHelpPlayers = false

local HelpConnection = nil
local CurrentHelpTarget = nil

local function setAutoHelpPlayers(v)
    getgenv().AutoHelpPlayers = v

    if v then
        if HelpConnection then
            HelpConnection:Disconnect()
        end

        HelpConnection = RunService.Heartbeat:Connect(function()
            if not getgenv().AutoHelpPlayers then
                return
            end

            local lp = Players.LocalPlayer
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if not root then
                return
            end

            if CurrentHelpTarget then
                local tChar = CurrentHelpTarget.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

                if tChar and tRoot and tHum and tHum.Health > 0 then
                    local isHooked =
                        tChar:GetAttribute("IsHooked")
                        or tChar:GetAttribute("Hooked")

                    local isDowned =
                        tChar:GetAttribute("State") == "Downed"
                        or (tHum.Health < tHum.MaxHealth * 0.9)

                    if isHooked or isDowned then
                        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)

                        if isHooked then
                            ReplicatedStorage.Remotes.Carry.UnHookEvent:FireServer(tChar)
                        else
                            ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(
                                tRoot,
                                true
                            )

                            ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent:FireServer(
                                "success",
                                100,
                                tChar
                            )
                        end

                        return
                    end
                end

                pcall(function()
                    ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(
                        tRoot or root,
                        false
                    )
                end)

                CurrentHelpTarget = nil
            end

            local target = nil

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp
                    and p.Character
                    and (
                        p.Character:GetAttribute("IsHooked")
                        or p.Character:GetAttribute("Hooked")
                    )
                then
                    target = p
                    break
                end
            end

            if not target then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")

                        if hum
                            and hum.Health > 0
                            and hum.Health < hum.MaxHealth * 0.9
                        then
                            target = p
                            break
                        end
                    end
                end
            end

            if target then
                CurrentHelpTarget = target
            end
        end)
    else
        if HelpConnection then
            HelpConnection:Disconnect()
            HelpConnection = nil
        end

        CurrentHelpTarget = nil

        pcall(function()
            local lp = Players.LocalPlayer
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(
                    root,
                    false
                )
            end
        end)
    end
end

local AutoHelpSection = Tabs.Main:AddSection("Auto Help Players")

Tabs.Main:AddToggle("AutoHelpPlayers", {
    Title = "Auto Help Players (Unhook & Heal)",
    Description = "TP to Rescue Hooked and Downed players automatically",
    Default = false,
    Callback = function(Value)
        setAutoHelpPlayers(Value)
    end
})

Window:SelectTab(1)
