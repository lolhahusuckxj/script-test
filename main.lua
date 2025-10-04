-- CombatCoreV7 by Matt & Copilot
-- Full feature stack: SilentAim, AutoShoot, Aimbot, ESP, ForceField checks
-- Knife Mode excluded

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Toggles
local SilentAimEnabled = false
local AimbotEnabled = false
local AutoShootEnabled = false
local ESPEnabled = false
local ForceFieldCheckEnabled = true

-- GUI Setup
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "CombatCoreV7"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 180)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local function makeToggle(text, y, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 20)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
end

makeToggle("SilentAim: OFF", 10, function(btn)
    SilentAimEnabled = not SilentAimEnabled
    btn.Text = "SilentAim: " .. (SilentAimEnabled and "ON" or "OFF")
end)

makeToggle("Aimbot: OFF", 35, function(btn)
    AimbotEnabled = not AimbotEnabled
    btn.Text = "Aimbot: " .. (AimbotEnabled and "ON" or "OFF")
end)

makeToggle("AutoShoot: OFF", 60, function(btn)
    AutoShootEnabled = not AutoShootEnabled
    btn.Text = "AutoShoot: " .. (AutoShootEnabled and "ON" or "OFF")
end)

makeToggle("ESP: OFF", 85, function(btn)
    ESPEnabled = not ESPEnabled
    btn.Text = "ESP: " .. (ESPEnabled and "ON" or "OFF")
end)

-- Targeting Logic
local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    if ForceFieldCheckEnabled and player.Character:FindFirstChildOfClass("ForceField") then return false end
    return true
end

local function getClosestTarget()
    local closest, dist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - Workspace.CurrentCamera.ViewportSize / 2).Magnitude
                if mag < dist then
                    closest = player
                    dist = mag
                end
            end
        end
    end
    return closest
end

-- Aimbot
RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, target.Character.HumanoidRootPart.Position)
        end
    end
end)

-- SilentAim Hook
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if SilentAimEnabled and method == "FireServer" and tostring(self):lower():find("shoot") then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            args[2] = target.Character.HumanoidRootPart.Position
            return old(self, unpack(args))
        end
    end
    return old(self, ...)
end)

-- AutoShoot
spawn(function()
    while true do
        wait(0.1)
        if AutoShootEnabled then
            local target = getClosestTarget()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                for _, obj in pairs(getgc(true)) do
                    if typeof(obj) == "Instance" and obj:IsA("RemoteEvent") and tostring(obj):lower():find("shoot") then
                        obj:FireServer("CombatCoreAuto")
                    end
                end
            end
        end
    end
end)

-- ESP
RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if isValidTarget(player) then
                if not player.Character:FindFirstChild("CombatCoreESP") then
                    local tag = Instance.new("BillboardGui", player.Character.HumanoidRootPart)
                    tag.Name = "CombatCoreESP"
                    tag.Size = UDim2.new(0, 100, 0, 40)
                    tag.AlwaysOnTop = true
                    local label = Instance.new("TextLabel", tag)
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.new(1, 0, 0)
                    label.Text = player.Name
                end
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("CombatCoreESP") then
                player.Character.CombatCoreESP:Destroy()
            end
        end
    end
end)

print("[CombatCoreV7] Loaded. All features active except Knife Mode.")
