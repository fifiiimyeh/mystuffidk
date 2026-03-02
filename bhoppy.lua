-- Toggle button modification
local function toggleScript(toggle)
    if toggle then
        -- Code when toggled on
    else
        -- When toggled off
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = 50
    end
end

-- Example usage
-- toggleScript(false) -- Call this function with false to set walkspeed and jumppower