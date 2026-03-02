local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- SETUP JUMP ANIMATION
local jumpAnim = Instance.new("Animation")
jumpAnim.AnimationId = "rbxassetid://131814798893284"
local jumpAnimTrack = humanoid:LoadAnimation(jumpAnim)

local scriptEnabled = true
local spaceHeld = false

local velocity = Vector3.new()
local isGrounded = false
local wasGrounded = false
local moveDir = Vector3.new()

local footstepTimer = 0
local footstepInterval = 0.35
local lastFootstepIndex = 0

-- config
local cfg = {
    groundAccel = 50,
    airAccel = 3200,
    maxAirSpeed = 20,
    runSpeed = 23,
    jumpPower = 32,
    gravity = 80,
    friction = 6,
    stopSpeed = 5,
}

local rocketBlastRadius = 25

local footstepSounds = {
    "rbxassetid://81623756670923",
    "rbxassetid://78754179999047",
    "rbxassetid://79418255155423",
    "rbxassetid://112240321395589",
}

local jumpSound = Instance.new("Sound", root)
jumpSound.SoundId = "rbxassetid://78754179999047"
jumpSound.Volume = 0.5
jumpSound.PlaybackSpeed = 1

local landSound = Instance.new("Sound", root)
landSound.SoundId = "rbxassetid://78754179999047"
landSound.Volume = 0.6
landSound.PlaybackSpeed = 1

local function playFootstep()
    local sound = Instance.new("Sound", workspace)
    
    lastFootstepIndex = lastFootstepIndex + 1
    if lastFootstepIndex > #footstepSounds then
        lastFootstepIndex = 1
    end
    
    sound.SoundId = footstepSounds[lastFootstepIndex]
    sound.Volume = 0.6
    sound.PlaybackSpeed = 1.0 + math.random(-10, 10) / 100
    sound:Play()
    
    game:GetService("Debris"):AddItem(sound, 2)
end

local function playJump()
    if jumpSound then
        jumpSound:Stop()
        jumpSound:Play()
    end
    if jumpAnimTrack then
        jumpAnimTrack:Play()
    end
end

local function playLand()
    if landSound then
        landSound:Stop()
        landSound:Play()
    end
    -- STOP ANIMATION ON LANDING
    if jumpAnimTrack then
        jumpAnimTrack:Stop(0.1) -- 0.1 is the fade out time for a smooth transition
    end
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local gameModes = {}

if isMobile then
    gameModes = {"default (mobile)", "no grenades (mobile)", "hard (mobile)"}
else
    gameModes = {"default (PC)", "no grenades (PC)", "hard (PC)"}
end

local currentModeIndex = 1

-- GUI (Shortened for clarity, logic remains same as original)
local function createGui()
    local g = Instance.new("ScreenGui", gui)
    g.ResetOnSpawn = false
    g.Name = "SourceDBG"

    local destroy = Instance.new("TextButton", g)
    destroy.Size = UDim2.new(0, 70, 0, 30)
    destroy.Position = UDim2.new(0, 10, 1, -130)
    destroy.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    destroy.Text = "DESTROY"

    destroy.MouseButton1Click:Connect(function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        g:Destroy()
        scriptEnabled = false
        script:Destroy()
    end)

    local toggle = Instance.new("TextButton", g)
    toggle.Size = UDim2.new(0, 70, 0, 30)
    toggle.Position = UDim2.new(0, 10, 1, -90)
    toggle.BackgroundColor3 = Color3.fromRGB(80, 255, 130)
    toggle.Text = "ON"

    toggle.MouseButton1Click:Connect(function()
        scriptEnabled = not scriptEnabled
        toggle.Text = scriptEnabled and "ON" or "OFF"
        toggle.BackgroundColor3 = scriptEnabled and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(255, 60, 60)
    end)

    local modeButton = Instance.new("TextButton", g)
    modeButton.Size = UDim2.new(0, 150, 0, 30)
    modeButton.Position = UDim2.new(0, 10, 1, -50)
    modeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    modeButton.Text = "Mode: " .. gameModes[currentModeIndex]
    modeButton.TextScaled = true

    modeButton.MouseButton1Click:Connect(function()
        currentModeIndex = currentModeIndex + 1
        if currentModeIndex > #gameModes then currentModeIndex = 1 end
        modeButton.Text = "Mode: " .. gameModes[currentModeIndex]
    end)

    if isMobile then
        -- Jump button for mobile logic
        local jumpButton = Instance.new("TextButton", g)
        jumpButton.Size = UDim2.new(0, 80, 0, 80)
        jumpButton.Position = UDim2.new(1, -90, 1, -90)
        jumpButton.Text = "JUMP"
        jumpButton.Name = "JumpButton"
        jumpButton.MouseButton1Down:Connect(function() spaceHeld = true end)
        jumpButton.MouseButton1Up:Connect(function() spaceHeld = false end)
    end
end

createGui()

local function grounded()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    return (result and result.Instance and result.Instance.CanCollide)
end

local function applyFriction(dt)
    local speed = velocity.Magnitude
    if speed < 0.1 then velocity = Vector3.new() return end
    local drop = isGrounded and (math.max(speed, cfg.stopSpeed) * cfg.friction * dt) or 0
    local newSpeed = math.max(speed - drop, 0)
    if newSpeed ~= speed then velocity = velocity * (newSpeed / speed) end
end

local function accel(wishDir, wishSpeed, accel, dt)
    local cur = velocity:Dot(wishDir)
    local add = wishSpeed - cur
    if add <= 0 then return end
    local accelSpeed = math.min(accel * dt * wishSpeed, add)
    velocity = velocity + wishDir * accelSpeed
end

local function process(dt)
    if not scriptEnabled then return end

    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    wasGrounded = isGrounded
    isGrounded = grounded()

    -- Trigger landing logic
    if isGrounded and not wasGrounded then
        playLand()
        footstepTimer = 0
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

    if isGrounded then
        applyFriction(dt)
        accel(input, cfg.runSpeed, cfg.groundAccel, dt)
        if input.Magnitude > 0.1 then
            footstepTimer += dt
            if footstepTimer >= footstepInterval then
                playFootstep()
                footstepTimer = 0
            end
        end

        if spaceHeld then
            velocity = Vector3.new(velocity.X, cfg.jumpPower, velocity.Z)
            playJump()
        else
            velocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
    else
        accel(input, cfg.maxAirSpeed, cfg.airAccel, dt)
        velocity += Vector3.new(0, -cfg.gravity * dt, 0)
    end

    root.AssemblyLinearVelocity = velocity
end

UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Space then spaceHeld = true end
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
    jumpAnimTrack = humanoid:LoadAnimation(jumpAnim)
end)

print("Source Movement Loaded: Animation stops on land.")