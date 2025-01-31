local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local isRightMouseDown = false
local currentTarget = nil
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Create the FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255) -- White
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = true

local maxFOVDistance = 100 -- Adjustable max distance from screen center

-- Function to update the FOV Circle position
local function updateFOVCircle()
    if camera then
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        fovCircle.Radius = maxFOVDistance
        fovCircle.Visible = true
    end
end

-- Function to find the closest player to the center of the screen
local function findClosestPlayerToCursor()
    if not camera then return nil end

    local closestPlayer = nil
    local closestDistance = math.huge -- Start with a very large number
    local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local screenPosition = Vector2.new(screenPos.X, screenPos.Y)
                        local distanceToCenter = (screenPosition - centerScreen).Magnitude

                        -- Check if the player is within the FOV radius
                        if distanceToCenter < closestDistance and distanceToCenter <= maxFOVDistance then
                            closestDistance = distanceToCenter
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Function to find player parts
local function findPlayerParts(player)
    if not player then return nil end
    local character = player.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    return humanoidRootPart, head
end

-- Function to smoothly track the target's head
local function updateCameraFocus(targetPosition)
    if camera and isRightMouseDown then
        local currentCFrame = camera.CFrame
        local newCFrame = CFrame.new(currentCFrame.Position, targetPosition)
        camera.CFrame = currentCFrame:Lerp(newCFrame, 0.3) -- Adjust tracking smoothness
    end
end

-- Detect right mouse button press to track the closest player
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = true
        currentTarget = findClosestPlayerToCursor()
    end
end)

-- Detect right mouse button release to stop tracking
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
        currentTarget = nil
    end
end)

-- Tracking and FOV circle update loop
RunService.RenderStepped:Connect(function()
    -- Update FOV circle
    updateFOVCircle()

    -- Smoothly track target if right mouse is held down
    if isRightMouseDown and currentTarget then
        local _, head = findPlayerParts(currentTarget)
        if head then
            updateCameraFocus(head.Position)
        end
    end
end)
