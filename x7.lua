local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local OriginalPrint = print

print = function(...)
    local args = {...}
    local parts = {}

    for i, v in ipairs(args) do
        parts[i] = tostring(v)
    end

    local message = table.concat(parts, " ")

    if message == "[Meng Hub] Invisibility Script Loaded Successfully!" then
        OriginalPrint("[REAPER] Invisibility Script Loaded Successfully!")
        return
    end

    if message == "[Meng Hub] This Invisibility Script Private…" then
        OriginalPrint("[REAPER] This Invisibility Script Private…")
        return
    end

    OriginalPrint(...)
end

local success, result = pcall(function()
    return loadstring(game:HttpGet(
        "https://leekguy.vercel.app/roblox/menghub/crack_obf_invisible_93978595733734.lua"
    ))()
end)

if not success then
    Fluent:Notify({
        Title = "Error",
        Content = "Failed to load Invisible Script",
        Duration = 5
    })
    return
end

task.wait(0.5)

local Invisible = _G.MengHub and _G.MengHub.Invisible

if not Invisible then
    Fluent:Notify({
        Title = "Error",
        Content = "Failed to load Invisible API",
        Duration = 5
    })
    return
end

local Window = Fluent:CreateWindow({
    Title = "REAPER HUB",
    SubTitle = "Fluent Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 320),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({
        Title = "Main",
        Icon = "user"
    })
}

Tabs.Main:AddToggle("InvisibleToggle", {
    Title = "Invisible Mode",
    Default = false,

    Callback = function(Value)
        if Value then
            local success = pcall(function()
                Invisible.enable()
            end)

            if not success then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to enable Invisible",
                    Duration = 3
                })
            end
        else
            local success = pcall(function()
                Invisible.disable()
            end)

            if not success then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to disable Invisible",
                    Duration = 3
                })
            end
        end
    end
})

Window:SelectTab(1)
