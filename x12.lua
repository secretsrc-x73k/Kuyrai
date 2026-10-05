local AutoCrouchMobile = {
    Enabled = false,
    Busy = false,
    Attached = {},
    Connections = {}
}

local ACM_AnimationId = "80411309607666"
local ACM_MaxDistance = 40
local ACM_CrouchDuration = 1.2

local function ACM_IsKiller(player)
    return player
        and player.Team
        and player.Team.Name == "Killer"
end

local function ACM_IsDowned(character)
    if not character then
        return true
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return true
    end

    local state = character:GetAttribute("State")

    return state == "Downed" or state == "Dead"
end

local function ACM_PressMobileCrouch()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return
    end

    local survivorMob = playerGui:FindFirstChild("Survivor-mob")
    if not survivorMob then
        return
    end

    local controls = survivorMob:FindFirstChild("Controls")
    if not controls then
        return
    end

    local crouchButton = controls:FindFirstChild("crouch")
    if not crouchButton then
        return
    end

    if typeof(firesignal) == "function" then
        pcall(function()
            firesignal(crouchButton.MouseButton1Click)
        end)
    end
end

local function ACM_SetCrouch(character, humanoid, state)
    pcall(function()
        character:SetAttribute("Crouching", state)
    end)

    pcall(function()
        ReplicatedStorage.Remotes.Mechanics.ChangeAttribute
            :FireServer("Crouchingserver", state)
    end)

    if state then
        pcall(function()
            ReplicatedStorage.Remotes.Chase.Runevent
                :FireServer(character, false)
        end)
    end

    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end)
    end
end

local function ACM_TriggerCrouch()
    if not AutoCrouchMobile.Enabled or AutoCrouchMobile.Busy then
        return
    end

    AutoCrouchMobile.Busy = true

    task.spawn(function()
        local success, err = pcall(function()
            local character = LocalPlayer.Character
            if not character or ACM_IsDowned(character) then
                return
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                return
            end

            ACM_SetCrouch(character, humanoid, true)
            ACM_PressMobileCrouch()

            local startTime = os.clock()

            while os.clock() - startTime < ACM_CrouchDuration do
                if not AutoCrouchMobile.Enabled then
                    break
                end

                if LocalPlayer.Character ~= character then
                    break
                end

                pcall(function()
                    ReplicatedStorage.Remotes.Mechanics.ChangeAttribute
                        :FireServer("Crouchingserver", true)
                end)

                task.wait(0.1)
            end

            ACM_SetCrouch(character, humanoid, false)
            ACM_PressMobileCrouch()
        end)

        if not success then
            warn("[AutoCrouchMobile]", err)
        end

        AutoCrouchMobile.Busy = false
    end)
end

local function ACM_AttachCharacter(killerCharacter)
    if not killerCharacter or AutoCrouchMobile.Attached[killerCharacter] then
        return
    end

    AutoCrouchMobile.Attached[killerCharacter] = true

    task.spawn(function()
        local humanoid = killerCharacter:FindFirstChildOfClass("Humanoid")
            or killerCharacter:WaitForChild("Humanoid", 5)

        if not humanoid then
            AutoCrouchMobile.Attached[killerCharacter] = nil
            return
        end

        local animator = humanoid:FindFirstChildOfClass("Animator")
            or humanoid:WaitForChild("Animator", 5)

        if not animator then
            AutoCrouchMobile.Attached[killerCharacter] = nil
            return
        end

        local animationConnection

        animationConnection = animator.AnimationPlayed:Connect(function(track)
            if not AutoCrouchMobile.Enabled then
                return
            end

            local animation = track.Animation
            local animationId = animation
                and animation.AnimationId:match("%d+")

            if animationId ~= ACM_AnimationId then
                return
            end

            local myCharacter = LocalPlayer.Character
            if ACM_IsDowned(myCharacter) then
                return
            end

            local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
            local killerRoot = killerCharacter:FindFirstChild("HumanoidRootPart")

            if not myRoot or not killerRoot then
                return
            end

            local distance = (myRoot.Position - killerRoot.Position).Magnitude

            if distance <= ACM_MaxDistance then
                ACM_TriggerCrouch()
            end
        end)

        AutoCrouchMobile.Connections[killerCharacter] = animationConnection

        local ancestryConnection
        ancestryConnection = killerCharacter.AncestryChanged:Connect(function(_, parent)
            if parent then
                return
            end

            if animationConnection then
                animationConnection:Disconnect()
            end

            if ancestryConnection then
                ancestryConnection:Disconnect()
            end

            AutoCrouchMobile.Connections[killerCharacter] = nil
            AutoCrouchMobile.Attached[killerCharacter] = nil
        end)
    end)
end

local function ACM_TryAttach(player)
    if player == LocalPlayer then
        return
    end

    if ACM_IsKiller(player) and player.Character then
        ACM_AttachCharacter(player.Character)
    end
end

local function ACM_SetupPlayer(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        ACM_TryAttach(player)
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        ACM_TryAttach(player)
    end)

    ACM_TryAttach(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    ACM_SetupPlayer(player)
end

Players.PlayerAdded:Connect(ACM_SetupPlayer)

task.spawn(function()
    while true do
        task.wait(5)

        for _, player in ipairs(Players:GetPlayers()) do
            ACM_TryAttach(player)
        end
    end
end)

Tabs.Automatic:AddSection("Auto Crouch")

local AutoCrouch = Tabs.Automatic:AddToggle({
    Title = "Auto Crouch BETA",
    Default = false,
    Callback = function(v)
        AutoCrouchMobile.Enabled = v
    end
})

===========================
-- PC Version
===========================


local AutoCrouchPC = {
    Enabled = false,
    Busy = false,
    Attached = {},
    Connections = {}
}

local ACP_AnimationId = "80411309607666"
local ACP_MaxDistance = 40
local ACP_CrouchDuration = 1.2

local ACP_VirtualInputManager =
    game:GetService("VirtualInputManager")

local function ACP_IsKiller(player)
    return player
        and player.Team
        and player.Team.Name == "Killer"
end

local function ACP_IsDowned(character)
    if not character then
        return true
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return true
    end

    local state = character:GetAttribute("State")
    return state == "Downed" or state == "Dead"
end

local function ACP_PressCrouch(isDown)
    pcall(function()
        ACP_VirtualInputManager:SendKeyEvent(
            isDown,
            Enum.KeyCode.C,
            false,
            game
        )
    end)
end

local function ACP_TriggerCrouch()
    if not AutoCrouchPC.Enabled or AutoCrouchPC.Busy then
        return
    end

    AutoCrouchPC.Busy = true

    task.spawn(function()
        local pressed = false

        local success, err = pcall(function()
            local character = LocalPlayer.Character

            if not character or ACP_IsDowned(character) then
                return
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return
            end

            ACP_PressCrouch(true)
            pressed = true

            local startTime = os.clock()

            while os.clock() - startTime < ACP_CrouchDuration do
                if not AutoCrouchPC.Enabled then
                    break
                end

                if LocalPlayer.Character ~= character then
                    break
                end

                task.wait(0.05)
            end
        end)

        if pressed then
            ACP_PressCrouch(false)
        end

        if not success then
            warn("[AutoCrouchPC]", err)
        end

        AutoCrouchPC.Busy = false
    end)
end

local function ACP_AttachCharacter(killerCharacter)
    if not killerCharacter
        or AutoCrouchPC.Attached[killerCharacter] then
        return
    end

    AutoCrouchPC.Attached[killerCharacter] = true

    task.spawn(function()
        local humanoid =
            killerCharacter:FindFirstChildOfClass("Humanoid")
            or killerCharacter:WaitForChild("Humanoid", 5)

        if not humanoid then
            AutoCrouchPC.Attached[killerCharacter] = nil
            return
        end

        local animator =
            humanoid:FindFirstChildOfClass("Animator")
            or humanoid:WaitForChild("Animator", 5)

        if not animator then
            AutoCrouchPC.Attached[killerCharacter] = nil
            return
        end

        local connection

        connection = animator.AnimationPlayed:Connect(function(track)
            if not AutoCrouchPC.Enabled then
                return
            end

            local animation = track.Animation
            local animationId =
                animation and animation.AnimationId:match("%d+")

            if animationId ~= ACP_AnimationId then
                return
            end

            local character = LocalPlayer.Character

            if ACP_IsDowned(character) then
                return
            end

            local myRoot =
                character:FindFirstChild("HumanoidRootPart")

            local killerRoot =
                killerCharacter:FindFirstChild("HumanoidRootPart")

            if not myRoot or not killerRoot then
                return
            end

            local distance =
                (myRoot.Position - killerRoot.Position).Magnitude

            if distance <= ACP_MaxDistance then
                ACP_TriggerCrouch()
            end
        end)

        AutoCrouchPC.Connections[killerCharacter] = connection

        killerCharacter.AncestryChanged:Connect(function(_, parent)
            if parent then
                return
            end

            if connection then
                connection:Disconnect()
            end

            AutoCrouchPC.Connections[killerCharacter] = nil
            AutoCrouchPC.Attached[killerCharacter] = nil
        end)
    end)
end

local function ACP_TryAttach(player)
    if player == LocalPlayer then
        return
    end

    if ACP_IsKiller(player) and player.Character then
        ACP_AttachCharacter(player.Character)
    end
end

local function ACP_SetupPlayer(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        ACP_TryAttach(player)
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        ACP_TryAttach(player)
    end)

    ACP_TryAttach(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    ACP_SetupPlayer(player)
end

Players.PlayerAdded:Connect(ACP_SetupPlayer)

task.spawn(function()
    while true do
        task.wait(5)

        for _, player in ipairs(Players:GetPlayers()) do
            ACP_TryAttach(player)
        end
    end
end)

Tabs.Automatic:AddSection("Auto Crouch")

local AutoCrouch = Tabs.Automatic:AddToggle({
    Title = "Auto Crouch BETA",
    Default = false,
    Callback = function(v)
        AutoCrouchPC.Enabled = v == true
    end
})

