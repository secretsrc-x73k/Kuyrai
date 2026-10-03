-- [[ Auto Help Players Logic - Combined Unhook & Heal ]] --
getgenv().AutoHelpPlayers = false
local HelpConnection = nil
local CurrentHelpTarget = nil

function setAutoHelpPlayers(v)
    getgenv().AutoHelpPlayers = v
    if v then
        if HelpConnection then HelpConnection:Disconnect() end
        HelpConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not getgenv().AutoHelpPlayers then return end
            
            local lp = game.Players.LocalPlayer
            local char = lp.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- 1. Task Locking: ตรวจสอบเป้าหมายปัจจุบัน
            if CurrentHelpTarget then
                local tChar = CurrentHelpTarget.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

                if tChar and tRoot and tHum and tHum.Health > 0 then
                    local isHooked = tChar:GetAttribute("IsHooked") or tChar:GetAttribute("Hooked")
                    local isDowned = tChar:GetAttribute("State") == "Downed" or (tHum.Health < tHum.MaxHealth * 0.9)

                    if isHooked or isDowned then
                        -- วาร์ปไปตำแหน่งเป้าหมาย (ด้านหลังเล็กน้อย)
                        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                        
                        if isHooked then
                            game:GetService("ReplicatedStorage").Remotes.Carry.UnHookEvent:FireServer(tChar)
                        else
                            -- ส่ง Remote ฮีลและ Instant Skillcheck
                            game:GetService("ReplicatedStorage").Remotes.Healing.HealEvent:FireServer(tRoot, true)
                            game:GetService("ReplicatedStorage").Remotes.Healing.SkillCheckResultEvent:FireServer("success", 100, tChar)
                        end
                        return -- ล็อคเป้าหมายเดิมจนกว่าจะเสร็จ
                    end
                end
                
                -- ถ้าหลุดเงื่อนไข (ช่วยเสร็จ/ตาย/หายไป) ให้หยุดฮีลและเคลียร์เป้าหมาย
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Healing.HealEvent:FireServer(tRoot or root, false) end)
                CurrentHelpTarget = nil 
            end

            -- 2. หาเป้าหมายใหม่ (Priority: Hook > Downed)
            local players = game.Players:GetPlayers()
            local target = nil

            -- ลำดับ 1: หาคนติด Hook
            for _, p in ipairs(players) do
                if p ~= lp and p.Character and (p.Character:GetAttribute("IsHooked") or p.Character:GetAttribute("Hooked")) then
                    target = p; break
                end
            end

            -- ลำดับ 2: ถ้าไม่มีคนติด Hook หาคนล้ม/บาดเจ็บ
            if not target then
                for _, p in ipairs(players) do
                    if p ~= lp and p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.9 then
                            target = p; break
                        end
                    end
                end
            end

            if target then
                CurrentHelpTarget = target
            end
        end)
    else
        if HelpConnection then HelpConnection:Disconnect(); HelpConnection = nil end
        CurrentHelpTarget = nil
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                game:GetService("ReplicatedStorage").Remotes.Healing.HealEvent:FireServer(root, false)
            end
        end)
    end
end

-- UI Section (Fluent UI)
Tabs.Main:AddToggle("AutoHelpPlayers", {
    Title = "Auto Help Players (Unhook & Heal)",
    Description = "TP to Rescue Hooked and Downed players automatically",
    Default = false,
    Callback = function(Value)
        setAutoHelpPlayers(Value)
    end
})
