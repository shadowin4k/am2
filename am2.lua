local Library = (function()
    local success, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    end)
    return success and lib or nil
end)()
if not Library then return end

local Window = Library.CreateLib("Neverlose Private Speed", "Midnight")
local Tab = Window:NewTab("Private Speed NEVERLOSE")
local Section = Tab:NewSection("CFrame Speed")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = nil
local HumanoidRootPart = nil

local enabled = false
local speed = 1
local moveConnection = nil

-- Utility: Random jitter [-0.05 .. 0.05]
local function randomJitter()
    return (math.random() - 0.5) / 10
end

local function safeFireServer(scriptObj)
    pcall(function()
        local fire = scriptObj and scriptObj:FindFirstChild("LocalScript")
        if fire then
            for _=1, math.random(1,2) do
                pcall(function()
                    fire:FireServer()
                end)
                task.wait(math.random(50,150)/1000)
            end
        end
    end)
end

local function cleanUpScripts()
    if not Character then return end
    for _, c in pairs(Character:GetChildren()) do
        if c:IsA("Script") and c.Name ~= "Health" and c.Name ~= "Sound" and c:FindFirstChild("LocalScript") then
            pcall(function() c:Destroy() end)
        end
    end
end

local function onCharacterAdded(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
    cleanUpScripts()

    char.ChildAdded:Connect(function(child)
        if child:IsA("Script") and child:FindFirstChild("LocalScript") then
            task.wait(0.1 + math.random() / 5) -- random delay
            safeFireServer(child)
        end
    end)
end

local function moveLoop()
    while enabled and HumanoidRootPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") do
        local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local offset = moveDir * speed
            -- add jitter on each axis
            offset = offset + Vector3.new(randomJitter(), 0, randomJitter())
            pcall(function()
                HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + offset
            end)
        end
        RunService.Stepped:Wait()
        task.wait(0.01 + math.random() / 100) -- small random throttle delay
    end
end

Section:NewButton("CFrame Guns FIX", "Fix local scripts that can get you detected", function()
    if LocalPlayer.Character then
        cleanUpScripts()
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end)

Section:NewButton("Toggle CFrame Speed (F)", "Toggle stealth speed mode (randomized)", function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.CharacterAdded:Wait()
    end
    Character = LocalPlayer.Character
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local toggleKey = Enum.KeyCode.F -- stealth toggle key

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            enabled = not enabled
            if enabled then
                coroutine.wrap(moveLoop)()
            end
        elseif input.KeyCode == Enum.KeyCode.LeftBracket then
            speed = math.clamp(speed - 0.05, 0.2, 3)
        elseif input.KeyCode == Enum.KeyCode.RightBracket then
            speed = math.clamp(speed + 0.05, 0.2, 3)
        end
    end)
end)

Section:NewSlider("Speed Multiplier", "Speed from 0.2 (slow) to 3 (fast)", 3, 0.2, function(val)
    speed = val
end)

Section:NewKeybind("Toggle UI", "Toggle the UI (default V)", Enum.KeyCode.V, function()
    Library.ToggleUI()
end)

-- Initialize on player character spawn
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
else
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end
