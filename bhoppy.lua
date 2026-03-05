-- Source Engine Movement for Roblox + ABH & Impulse Retention & Toggle Key (R)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local scriptEnabled = true
local spaceHeld = false

local velocity = Vector3.new()
local isGrounded = false
local wasGrounded = false
local moveDir = Vector3.new()

local footstepTimer = 0
local footstepInterval = 0.35
local lastFootstepIndex = 0

-- Configuración
local cfg = {
    groundAccel = 10,
    airAccel = 1000, 
    maxAirSpeed = 5,
    runSpeed = 20,
    jumpPower = 32,
    gravity = 90,
    friction = 5,
    stopSpeed = 10,
    abhMultiplier = 2.5,
    postImpulseGain = 0.01 
}

local rocketBlastRadius = 25

-- TABLA EXPANDIDA DE SONIDOS SOURCE (HL2 / CSS)
local footstepSounds = {
    Slate = {"rbxassetid://81623756670923", "rbxassetid://78754179999047", "rbxassetid://79418255155423", "rbxassetid://112240321395589"},
    Concrete = {"rbxassetid://81623756670923", "rbxassetid://78754179999047", "rbxassetid://79418255155423", "rbxassetid://112240321395589"},
    Brick = {"rbxassetid://81623756670923", "rbxassetid://78754179999047", "rbxassetid://79418255155423", "rbxassetid://112240321395589"},
    Wood = {"rbxassetid://87921439933530", "rbxassetid://89597871459985", "rbxassetid://139932856876296", "rbxassetid://75643573822739"},
    WoodPlanks = {"rbxassetid://87921439933530", "rbxassetid://89597871459985", "rbxassetid://139932856876296", "rbxassetid://75643573822739"},
    Metal = {"rbxassetid://78580994772675", "rbxassetid://79005288283137", "rbxassetid://98060045106272", "rbxassetid://122668036980895"},
    DiamondPlate = {"rbxassetid://78580994772675", "rbxassetid://79005288283137", "rbxassetid://98060045106272", "rbxassetid://122668036980895"},
    CorrodedMetal = {"rbxassetid://78580994772675", "rbxassetid://79005288283137", "rbxassetid://98060045106272", "rbxassetid://122668036980895"},
    Grass = {"rbxassetid://105277634319381", "rbxassetid://98069158661569", "rbxassetid://135182192451997", "rbxassetid://116425333836106"},
    Sand = {"rbxassetid://84209465430801", "rbxassetid://115151668857364", "rbxassetid://93919782627384", "rbxassetid://105793766638092"},
    Mud = {"rbxassetid://125078502573216", "rbxassetid://119139580459950", "rbxassetid://132103348107931", "rbxassetid://137748446979624"},
    Snow = {"rbxassetid://90615555465225", "rbxassetid://125184282810966", "rbxassetid://114138676251211", "rbxassetid://132337775532551"},
    Plastic = {"rbxassetid://135712042029119", "rbxassetid://90507702118699", "rbxassetid://98172042741214", "rbxassetid://106319783012941"},
    SmoothPlastic = {"rbxassetid://135712042029119", "rbxassetid://90507702118699", "rbxassetid://98172042741214", "rbxassetid://106319783012941"},
    Fabric = {"rbxassetid://134707629631621", "rbxassetid://120658421045233", "rbxassetid://82315729709772", "rbxassetid://101186178877521"},
    Glass = {"rbxassetid://88813292437651", "rbxassetid://126359516625890", "rbxassetid://133178229418641", "rbxassetid://80572007771746"},
    Ice = {"rbxassetid://105786448375088", "rbxassetid://106093339008891", "rbxassetid://86217431358704", "rbxassetid://131109062323793"},
    Air = {""},
}

local function fireRocket()
    if not scriptEnabled then return end
    local currentMode = gameModes[currentModeIndex]
    if string.find(currentMode, "no grenades") then return end
    
    local cam = workspace.CurrentCamera
    local direction = cam.CFrame.LookVector
    local rocket = Instance.new("Part", workspace)
    rocket.Size = Vector3.new(0.5, 0.5, 2)
    rocket.CFrame = CFrame.lookAt(root.Position + direction * 3, root.Position + direction * 4)
    rocket.Velocity = direction * 150
    rocket.CanCollide = false
    rocket.BrickColor = BrickColor.new("Really red")
    rocket.Material = Enum.Material.Neon
    
    local sound = Instance.new("Sound", root)
    sound.SoundId = "rbxassetid://2156366946"
    sound:Play()
    game.Debris:AddItem(sound, 2)

    rocket.Touched:Connect(function(hit)
        if hit and not hit:IsDescendantOf(character) then
            local pos = rocket.Position
            local explosion = Instance.new("Explosion", workspace)
            explosion.Position = pos
            explosion.BlastRadius = rocketBlastRadius
            explosion.BlastPressure = 0
            if (root.Position - pos).Magnitude <= rocketBlastRadius then
                velocity += (root.Position - pos).Unit * 100
            end
            rocket:Destroy()
        end
    end)
    game.Debris:AddItem(rocket, 5)
end

local function toggleScript()
    scriptEnabled = not scriptEnabled
    local g = gui:FindFirstChild("SourceDBG")
    if g then
        local toggleBtn = g:FindFirstChild("ToggleButton")
        if toggleBtn then
            toggleBtn.BackgroundColor3 = scriptEnabled and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(255, 60, 60)
            toggleBtn.Text = scriptEnabled and "ON" or "OFF"
        end
    end
    if not scriptEnabled then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        velocity = Vector3.new()
        local jumpButton = gui:FindFirstChild("SourceDBG"):FindFirstChild("JumpButton")
        local grenadeButton = gui:FindFirstChild("SourceDBG"):FindFirstChild("GrenadeButton")
        if jumpButton then jumpButton.Visible = false end
        if grenadeButton then grenadeButton.Visible = false end
    else
        local jumpButton = gui:FindFirstChild("SourceDBG"):FindFirstChild("JumpButton")
        local grenadeButton = gui:FindFirstChild("SourceDBG"):FindFirstChild("GrenadeButton")
        if jumpButton then jumpButton.Visible = true end
        if grenadeButton then grenadeButton.Visible = true end
    end
end

isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
gameModes = isMobile and {"default (mobile)", "no grenades (mobile)", "hard (mobile)"} or {"default (PC)", "no grenades (PC)", "hard (PC)"}
currentModeIndex = 1

local function createGui()
    local g = Instance.new("ScreenGui", gui)
    g.ResetOnSpawn = false
    g.Name = "SourceDBG"

    local toggle = Instance.new("TextButton", g)
    toggle.Name = "ToggleButton"
    toggle.Size = UDim2.new(0, 60, 0, 25)
    toggle.Position = UDim2.new(1, -70, 0, 80)
    toggle.BackgroundColor3 = Color3.fromRGB(80, 255, 130)
    toggle.Text = "ON"
    toggle.MouseButton1Click:Connect(toggleScript)

    local modeButton = Instance.new("TextButton", g)
    modeButton.Size = UDim2.new(0, 100, 0, 25)
    modeButton.Position = UDim2.new(1, -110, 0, 110)
    modeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    modeButton.Text = "Mode: " .. currentModeIndex
    modeButton.TextScaled = true
    modeButton.Name = "ModeButton"
    modeButton.MouseButton1Click:Connect(function()
        currentModeIndex = currentModeIndex + 1
        if currentModeIndex > #gameModes then currentModeIndex = 1 end
        modeButton.Text = "Mode: " .. gameModes[currentModeIndex]
    end)

    if isMobile then
        local jumpButton = Instance.new("TextButton", g)
        jumpButton.Size = UDim2.new(0, 80, 0, 80)
        jumpButton.Position = UDim2.new(1, -90, 1, -150)
        jumpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        jumpButton.Text = "JUMP"
        jumpButton.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", jumpButton).CornerRadius = UDim.new(0.5, 0)
        jumpButton.InputBegan:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then spaceHeld = true end end)
        jumpButton.InputEnded:Connect(function(io) if io.UserInputType == Enum.UserInputType.Touch then spaceHeld = false end end)
        
        local grenadeButton = Instance.new("TextButton", g)
        grenadeButton.Size = UDim2.new(0, 70, 0, 70)
        grenadeButton.Position = UDim2.new(1, -170, 1, -145)
        grenadeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        grenadeButton.Text = "X"
        grenadeButton.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", grenadeButton).CornerRadius = UDim.new(0.5, 0)
        grenadeButton.MouseButton1Click:Connect(fireRocket)
    end
end
createGui()

local function getFloorMaterial()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    if result and result.Instance then
        local floorMaterial = result.Instance.Material.Name
        return footstepSounds[floorMaterial] and floorMaterial or "Slate"
    end
    return "Slate"
end

local function playFootstep()
    local material = getFloorMaterial()
    local soundTable = footstepSounds[material]
    local sound = Instance.new("Sound", workspace)
    lastFootstepIndex = lastFootstepIndex + 1
    if lastFootstepIndex > #soundTable then lastFootstepIndex = 1 end
    sound.SoundId = soundTable[lastFootstepIndex]
    sound.Volume = 1.2
    sound.PlaybackSpeed = 1.0 + math.random(-10, 10) / 100
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local function playJump()
    local material = getFloorMaterial()
    local soundTable = footstepSounds[material]
    if #soundTable > 0 and soundTable[1] ~= "" then
        local sound = Instance.new("Sound", workspace)
        sound.SoundId = soundTable[math.random(1, #soundTable)]
        sound.Volume = 1.2
        sound.PlaybackSpeed = 1.0 + math.random(-5, 5) / 100
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end
end

local function playLand()
    if velocity.Y < -50 then
        local impact = Instance.new("Sound", workspace)
        impact.SoundId = "rbxassetid://155416568"
        impact.Volume = 1.5
        impact:Play()
        game:GetService("Debris"):AddItem(impact, 2)
    end

    local material = getFloorMaterial()
    local soundTable = footstepSounds[material]
    if #soundTable > 0 and soundTable[1] ~= "" then
        local sound = Instance.new("Sound", workspace)
        sound.SoundId = soundTable[math.random(1, #soundTable)]
        sound.Volume = 1.2
        sound.PlaybackSpeed = 1.0 + math.random(-5, 5) / 100
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end
end

local function grounded()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    return result and result.Instance and result.Instance.CanCollide
end

local function applyFriction(dt)
    if spaceHeld then return end
    local speed = velocity.Magnitude
    if speed < 0.1 then velocity = Vector3.new() return end
    local drop = 0
    if isGrounded then
        local control = math.max(speed, cfg.stopSpeed)
        drop = control * cfg.friction * dt
    end
    local newSpeed = math.max(speed - drop, 0)
    if newSpeed ~= speed then velocity = velocity * (newSpeed / speed) end
end

local function accel(wishDir, wishSpeed, accelValue, dt)
    local currentSpeed = velocity:Dot(wishDir)
    local addSpeed = wishSpeed - currentSpeed
    if addSpeed <= 0 then
        if spaceHeld and velocity.Magnitude > cfg.runSpeed then
            velocity += wishDir * (cfg.postImpulseGain)
        end
        return 
    end
    local accelSpeed = math.min(accelValue * dt * wishSpeed, addSpeed)
    velocity = velocity + wishDir * accelSpeed
end

local function process(dt)
    if not scriptEnabled then return end
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    wasGrounded = isGrounded
    isGrounded = grounded()

    if isGrounded and not wasGrounded and velocity.Y < -5 and not spaceHeld then
        playLand()
    end

    local cam = workspace.CurrentCamera
    local fwd = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    fwd = Vector3.new(fwd.X, 0, fwd.Z).Unit
    right = Vector3.new(right.X, 0, right.Z).Unit

    local input = Vector3.new()
    if isMobile then
        input = humanoid.MoveDirection
    else
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then input += fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then input -= fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then input -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then input += right end
    end
    if input.Magnitude > 0 then input = input.Unit end
    moveDir = input

    local flat = Vector3.new(fwd.X, 0, fwd.Z)
    if flat.Magnitude > 0.01 then root.CFrame = CFrame.new(root.Position, root.Position + flat) end

    local maxAir = (gameModes[currentModeIndex]:find("hard")) and cfg.maxAirSpeed * 0.3 or cfg.maxAirSpeed

    if isGrounded then
        applyFriction(dt)
        accel(moveDir, cfg.runSpeed, cfg.groundAccel, dt)

        if moveDir.Magnitude > 0.1 then
            footstepTimer += dt
            if footstepTimer >= footstepInterval then playFootstep() footstepTimer = 0 end
        else footstepTimer = 0 end

        if spaceHeld then
            local isMovingBack = moveDir:Dot(fwd) < -0.5
            if isMovingBack then
                velocity = velocity + (velocity * (cfg.abhMultiplier - 1) * dt * 5) + Vector3.new(0, cfg.jumpPower, 0)
            else
                velocity = Vector3.new(velocity.X, cfg.jumpPower, velocity.Z)
            end
            playJump()
        else
            velocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
    else
        local wallParams = RaycastParams.new()
        wallParams.FilterDescendantsInstances = {character}
        local wallRay = workspace:Raycast(root.Position, velocity.Unit * 2.5, wallParams)
        if wallRay and wallRay.Normal.Y < 0.7 then 
            local n = wallRay.Normal
            velocity = (velocity - velocity:Dot(n) * n) * 0.99
        end

        accel(moveDir, maxAir, cfg.airAccel, dt)
        velocity += Vector3.new(0, -cfg.gravity * dt, 0)
    end
    root.AssemblyLinearVelocity = velocity
end

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.Space then spaceHeld = true
    elseif i.KeyCode == Enum.KeyCode.X then fireRocket()
    elseif i.KeyCode == Enum.KeyCode.R then toggleScript() end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
end)

RunService.Heartbeat:Connect(function(dt)
    if humanoid and humanoid.Health > 0 then process(dt) end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    velocity = Vector3.new()
end)
