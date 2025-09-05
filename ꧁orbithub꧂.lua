-- // Orbit Aura v1.0.4 // --
-- GUI + Souls + AimLock + Draggable + Close Button

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local Settings = {
    Enabled = false,
    SoulCount = 8,
    SoulColor = Color3.fromRGB(255,50,50),
    Rainbow = false,
    SoulTransparency = 0.3,
    SoulMaterial = Enum.Material.Neon,
    ToggleKey = Enum.KeyCode.F,
    Speed = 5,
    Radius = 4,
    Height = 1,
    Friendlist = {},
    Mode = "Legit" -- Legit / HvH
}

local Souls = {}
local CurrentTarget = nil
local Gui = nil
local WaitingForBind = false
local Dragging = false
local DragOffset = Vector2.new(0,0)
local OrbitConnection = nil

-- Check if player alive
local function IsAlive(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- Check if friend
local function IsFriend(player)
    for _, name in ipairs(Settings.Friendlist) do
        if player.Name:lower() == name:lower() then
            return true
        end
    end
    return false
end

-- Find closest target
local function GetClosestTarget()
    local closest, dist = nil, math.huge
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and not IsFriend(plr) then
            local hrp = plr.Character.HumanoidRootPart
            local d = (hrp.Position - myHRP.Position).Magnitude
            if d < dist then
                dist, closest = d, plr
            end
        end
    end
    return closest
end

-- Souls
local function RemoveSouls()
    for _, s in ipairs(Souls) do
        if s and s.Parent then
            s:Destroy()
        end
    end
    Souls = {}
end

local function CreateSouls()
    RemoveSouls()
    if not CurrentTarget or not IsAlive(CurrentTarget) then return end
    for i = 1, Settings.SoulCount do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.6,0.6,0.6)
        part.Shape = Enum.PartType.Ball
        part.Anchored = true
        part.CanCollide = false
        part.Material = Settings.SoulMaterial
        part.Transparency = Settings.SoulTransparency
        part.Color = Settings.SoulColor

        local light = Instance.new("PointLight", part)
        light.Brightness = 2
        light.Range = 6
        light.Color = Settings.SoulColor

        part.Parent = workspace
        table.insert(Souls, part)
    end
end

local function UpdateSoulColors()
    if Settings.Rainbow then
        local t = tick()
        for i,s in ipairs(Souls) do
            local col = Color3.fromHSV((t*0.5 + i/Settings.SoulCount)%1,1,1)
            s.Color = col
            if s:FindFirstChildOfClass("PointLight") then
                s.PointLight.Color = col
            end
        end
    else
        for _, s in ipairs(Souls) do
            s.Color = Settings.SoulColor
            if s:FindFirstChildOfClass("PointLight") then
                s.PointLight.Color = Settings.SoulColor
            end
        end
    end
end

-- Orbit & AimLock
local function StartOrbit()
    if OrbitConnection then OrbitConnection:Disconnect() end

    OrbitConnection = RunService.Heartbeat:Connect(function()
        if Settings.Enabled then
            CurrentTarget = CurrentTarget or GetClosestTarget()
            if not CurrentTarget or not IsAlive(CurrentTarget) then
                CurrentTarget = GetClosestTarget()
                RemoveSouls()
                if CurrentTarget then CreateSouls() end
                return
            end

            local hrp = CurrentTarget.Character.HumanoidRootPart
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end

            -- Orbit movement
            local angle = tick()*Settings.Speed
            local offset = Vector3.new(math.cos(angle)*Settings.Radius,0,math.sin(angle)*Settings.Radius)

            if Settings.Mode == "Legit" then
                myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(hrp.Position + offset, hrp.Position),0.2)
            else
                myHRP.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
            end

            -- Souls orbit
            for i,s in ipairs(Souls) do
                local soulAngle = angle*2 + i*(2*math.pi/Settings.SoulCount)
                local x = math.cos(soulAngle)*(Settings.Radius+2)
                local z = math.sin(soulAngle)*(Settings.Radius+2)
                local y = math.sin(tick()*2 + i)*Settings.Height
                s.Position = hrp.Position + Vector3.new(x,y+2,z)
            end

            UpdateSoulColors()
        end
    end)
end

local function StopOrbit()
    if OrbitConnection then
        OrbitConnection:Disconnect()
        OrbitConnection = nil
    end
end

-- GUI
local function CreateGUI()
    if Gui then Gui:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OrbitAuraGUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0,300,0,400)
    mainFrame.Position = UDim2.new(0.5,-150,0.5,-200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,50)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,12)
    corner.Parent = mainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.Text = "Orbit Aura v1.0.4"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = mainFrame

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,25,0,25)
    closeBtn.Position = UDim2.new(1,-30,0,5)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        StopOrbit()
        RemoveSouls()
    end)

    -- Create button helper
    local function CreateButton(text,yPos,callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9,0,0,30)
        btn.Position = UDim2.new(0.05,0,0,yPos)
        btn.Text = text
        btn.Font = Enum.Font.Gotham
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = Color3.fromRGB(60,60,80)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0,6)
        c.Parent = btn
        btn.MouseButton1Click:Connect(callback)
        btn.Parent = mainFrame
        return btn
    end

    -- Buttons
    local toggleBtn = CreateButton("OFF", 40, function()
        Settings.Enabled = not Settings.Enabled
        toggleBtn.Text = Settings.Enabled and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
        if Settings.Enabled then StartOrbit() else StopOrbit() RemoveSouls() end
    end)

    local rainbowBtn = CreateButton("RAINBOW: "..(Settings.Rainbow and "ON" or "OFF"),80,function()
        Settings.Rainbow = not Settings.Rainbow
        rainbowBtn.Text = "RAINBOW: "..(Settings.Rainbow and "ON" or "OFF")
    end)

    local soulBtn = CreateButton("SOULS: "..Settings.SoulCount,120,function()
        Settings.SoulCount = (Settings.SoulCount%12)+1
        soulBtn.Text = "SOULS: "..Settings.SoulCount
        if Settings.Enabled then CreateSouls() end
    end)

    local speedBtn = CreateButton("SPEED: "..Settings.Speed,160,function()
        Settings.Speed = (Settings.Speed%10)+1
        speedBtn.Text = "SPEED: "..Settings.Speed
    end)

    local radiusBtn = CreateButton("RADIUS: "..Settings.Radius,200,function()
        Settings.Radius = (Settings.Radius%10)+1
        radiusBtn.Text = "RADIUS: "..Settings.Radius
    end)

    local heightBtn = CreateButton("HEIGHT: "..Settings.Height,240,function()
        Settings.Height = (Settings.Height%10)+1
        heightBtn.Text = "HEIGHT: "..Settings.Height
    end)

    -- Drag
    title.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            Dragging=true
            DragOffset = Vector2.new(input.Position.X - mainFrame.AbsolutePosition.X,input.Position.Y - mainFrame.AbsolutePosition.Y)
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then Dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local mousePos = input.Position
            mainFrame.Position = UDim2.new(0,mousePos.X-DragOffset.X,0,mousePos.Y-DragOffset.Y)
        end
    end)

    mainFrame.Parent = ScreenGui
    Gui = ScreenGui
end

-- Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if WaitingForBind and input.UserInputType==Enum.UserInputType.Keyboard then
        Settings.ToggleKey = input.KeyCode
        WaitingForBind=false
    elseif input.KeyCode == Settings.ToggleKey then
        Settings.Enabled = not Settings.Enabled
        if Settings.Enabled then StartOrbit() else StopOrbit() RemoveSouls() end
    end
end)

CreateGUI()
print("Orbit Aura v1.0.4 loaded!")