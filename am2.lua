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
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = nil
local HumanoidRootPart = nil

local enabled = false
local baseSpeed = 1
local moveLoopCoroutine = nil
local lastToggleTime = 0
local toggleCooldown = 0.3 -- 300ms cooldown between toggles

-- Smooth noise generator (Perlin-like) for jitter, oscillates between -1 and 1
local noiseTime = 0
local function smoothNoise(freq)
    noiseTime = noiseTime + freq
    return math.sin(noiseTime) * math.cos(noiseTime*1.5)
end

local function isNearOtherPlayers()
    if not Character or not HumanoidRootPart then return false end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist < 20 then
                return true
            end
        end
    end
    return false
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
            task.wait(0.1 + math.random() / 5)
            pcall(function()
                child.LocalScript:FireServer()
            end)
        end
    end)
end

local function tweenMoveTo(newCFrame)
    local tweenInfo = TweenInfo.new(
        0.1 + math.random() * 0.05,
        Enum.EasingStyle.Linear
    )
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = newCFrame})
    tween:Play()
end

local function moveLoop()
    local pauseFrames = 0
    local verticalOscillation = 0
    while enabled and HumanoidRootPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") do
        if pauseFrames > 0 then
            pauseFrames = pauseFrames - 1
            RunService.Stepped:Wait()
            continue
        end

        local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local speedMultiplier = baseSpeed
            if isNearOtherPlayers() then
                speedMultiplier = math.clamp(baseSpeed * 0.4, 0.2, 2)
            end

            -- Smooth jitter that oscillates over time
            local jitterX = smoothNoise(0.15) * (speedMultiplier / 30)
            local jitterZ = smoothNoise(0.22) * (speedMultiplier / 30)

            -- Vertical bobbing to simulate natural movement sway
            verticalOscillation = verticalOscillation + 0.1
            local verticalOffset = math.sin(verticalOscillation) * 0.015

            local offset = moveDir * speedMultiplier + Vector3.new(jitterX, verticalOffset, jitterZ)
            local targetCFrame = HumanoidRootPart.CFrame + offset
            tweenMoveTo(targetCFrame)
        end

        -- Occasionally pause for 1-3 frames (random micro-pauses)
        if math.random() < 0.06 then
            pauseFrames = math.random(1,3)
        end

        -- Random frame skip between 2-5 frames
        local skipFrames = math.random(2,5)
        for _=1, skipFrames do
            RunService.Stepped:Wait()
        end

        task.wait(math.clamp(0.015 + math.random() / 150, 0.015, 0.03))
    end
end

Section:NewButton("CFrame Guns FIX", "Fix local scripts that can get you detected", function()
    if LocalPlayer.Character then
        cleanUpScripts()
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end)

Section:NewButton("Toggle CFrame Speed (C)", "Toggle stealth speed mode (randomized, adaptive)", function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.CharacterAdded:Wait()
    end
    Character = LocalPlayer.Character
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local toggleKey = Enum.KeyCode.C

    if _G._inputConn then
        _G._inputConn:Disconnect()
    end

    _G._inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        if input.KeyCode == toggleKey then
            local now = tick()
            if now - lastToggleTime < toggleCooldown then
                return -- ignore toggles during cooldown
            end
            lastToggleTime = now

            task.delay(math.random(1,3)/10, function()
                enabled = not enabled
                if enabled then
                    if moveLoopCoroutine and coroutine.status(moveLoopCoroutine) ~= "dead" then return end
                    moveLoopCoroutine = coroutine.create(moveLoop)
                    coroutine.resume(moveLoopCoroutine)
                end
            end)
        elseif input.KeyCode == Enum.KeyCode.LeftBracket then
            baseSpeed = math.clamp(baseSpeed - 0.05, 0.2, 5)
        elseif input.KeyCode == Enum.KeyCode.RightBracket then
            baseSpeed = math.clamp(baseSpeed + 0.05, 0.2, 5)
        end
    end)
end)

Section:NewSlider("Speed Multiplier", "Speed from 0.2 (slow) to 5 (fast)", 5, 0.2, function(val)
    baseSpeed = val
end)

Section:NewKeybind("Toggle UI", "Toggle the UI (default V)", Enum.KeyCode.V, function()
    Library.ToggleUI()
end)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
else
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end
