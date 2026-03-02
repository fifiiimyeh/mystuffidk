-- shift lockk

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- --- 1. GUI System (completely preserves your original crosshair logic) ---
local ShiftLockGui = Instance.new("ScreenGui")
ShiftLockGui.Name = "shiftlockk"
ShiftLockGui.ResetOnSpawn = false
ShiftLockGui.Parent = PlayerGui

local LockButton = Instance.new("ImageButton")
LockButton.Name = "LockButton"
LockButton.Parent = ShiftLockGui
LockButton.AnchorPoint = Vector2.new(0.5, 0.5)
LockButton.Position = UDim2.new(0.85, 0, 0.5, 0)
LockButton.Size = UDim2.new(0, 50, 0, 50)
LockButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LockButton.BackgroundTransparency = 1
LockButton.BorderSizePixel = 0
LockButton.Image = ""

local ButtonIcon = Instance.new("ImageLabel")
ButtonIcon.Name = "btnIcon"
ButtonIcon.Parent = LockButton
ButtonIcon.BackgroundTransparency = 1
ButtonIcon.Position = UDim2.new(-0.05, 0, -0.03, 0)
ButtonIcon.Size = UDim2.new(1.1, 0, 1.1, 0)
ButtonIcon.Image = "rbxasset://textures/ui/mouseLock_off.png"
ButtonIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", LockButton).CornerRadius = UDim.new(1, 0)

local Crosshair = Instance.new("ImageLabel")
Crosshair.Name = "ShiftLockCrosshair"
Crosshair.Parent = ShiftLockGui
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Position = UDim2.new(0.5, 0, 0.5, -29)
Crosshair.Size = UDim2.new(0, 27, 0, 27)
Crosshair.BackgroundTransparency = 1
Crosshair.Image = "rbxasset://textures/MouseLockedCursor.png"
Crosshair.Visible = false -- Initially off/hidden

-- --- 2. Core variables ---
local isShiftLockEnabled = false
local userGameSettings = nil
local OFFSET_VAL = 1.75 

-- --- 3. Core loop (force RotationType) ---
local function enforceOfficialSync()
    -- Only runs when enabled
    if not isShiftLockEnabled then 
        RunService:UnbindFromRenderStep("FinalNailSync")
        return 
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    if not hum then return end

    -- Force RotationType every frame until disabled
    if not userGameSettings then
        pcall(function() userGameSettings = UserSettings():GetService("UserGameSettings") end)
    end
    if userGameSettings then
        if userGameSettings.RotationType ~= Enum.RotationType.CameraRelative then
            pcall(function() userGameSettings.RotationType = Enum.RotationType.CameraRelative end)
        end
    end

    -- Lock the mouse
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    -- Nail-level sync (very strict synchronization)
    local dist = (cam.Focus.Position - cam.CFrame.Position).Magnitude
    if dist > 0.6 then
        local rawCFrame = cam.CFrame
        cam.CFrame = rawCFrame * CFrame.new(OFFSET_VAL, 0, 0)
        cam.Focus = cam.CFrame * CFrame.new(0, 0, -dist)
        -- Core safeguard: force reset physical offset to zero, absolutely prevent stacking
        hum.CameraOffset = Vector3.new(0, 0, 0)
    else
        hum.CameraOffset = Vector3.new(0, 0, 0)
    end
end

-- --- 4. Toggle function ---
local function ToggleShiftLock(enabled)
    isShiftLockEnabled = enabled
    Crosshair.Visible = enabled -- Visibility changes only when manually clicking the button
    
    -- Completely remove old bindings before switching to prevent double loops
    RunService:UnbindFromRenderStep("FinalNailSync")

    if enabled then
        ButtonIcon.ImageColor3 = Color3.fromRGB(0, 180, 255)
        RunService:BindToRenderStep("FinalNailSync", Enum.RenderPriority.Camera.Value + 1, enforceOfficialSync)
    else
        ButtonIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        
        if userGameSettings then
            pcall(function() userGameSettings.RotationType = Enum.RotationType.MovementRelative end)
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
    end
end

-- --- 5. Event binding and respawn logic ---

LockButton.MouseButton1Click:Connect(function()
    ToggleShiftLock(not isShiftLockEnabled)
end)

-- [Critical fix]: Respawn logic absolutely does not touch crosshair visibility
LocalPlayer.CharacterAdded:Connect(function(char)
    -- 1. Immediately stop the old render loop
    RunService:UnbindFromRenderStep("FinalNailSync")
    
    -- 2. If previously enabled, only restore logic without touching the crosshair
    if isShiftLockEnabled then
        local hum = char:WaitForChild("Humanoid")
        hum.CameraOffset = Vector3.new(0, 0, 0) -- Force clear
        task.wait(0.1)
        -- Rebind the loop for the new character
        RunService:BindToRenderStep("FinalNailSync", Enum.RenderPriority.Camera.Value + 1, enforceOfficialSync)
    end
end)

-- (Preserve your drag logic)
local dragging, dragStart, startPos
LockButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true dragStart = input.Position startPos = LockButton.Position
    end
end)
LockButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        LockButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
