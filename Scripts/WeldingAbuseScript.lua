local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local currentTarget = nil
local heartbeatConnection = nil
local highlightInstance = nil

local modes = {
    "Anti-Jump (На голове)",
    "Attach Behind (Сзади)",
    "Speed Boost Fast (Ускорение)",
    "Анти убегание",
    "Speed Boost Fast 2",
}
local currentMode = 1

local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

local function Detach()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    if highlightInstance then
        highlightInstance:Destroy()
        highlightInstance = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                sethiddenproperty(hrp, "PhysicsRepRootPart", hrp)
            end)
        end
    end
    
    currentTarget = nil
end

local function StartAttachmentLoop()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local myChar = LocalPlayer.Character
        if not currentTarget then return end
        local targetChar = currentTarget.Character

        if not myChar or not targetChar then return end

        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")

        if myHRP and targetHRP then
            myHRP.Velocity = Vector3.zero
            myHRP.RotVelocity = Vector3.zero
            
            if currentMode == 1 then
                myHRP.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 2.65, 0)) * CFrame.Angles(-math.pi / 2, 0, 0)
                
            elseif currentMode == 2 then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 8.5)
                
            elseif currentMode == 3 then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0.7, 0.35)

            elseif currentMode == 4 then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, -0.6, -1.5)

            elseif currentMode == 5 then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0.5, 0.65)
            end
            
            pcall(function()
                sethiddenproperty(myHRP, "PhysicsRepRootPart", targetHRP)
            end)
        else
            Detach()
        end
    end)
end

local function AttachToTarget(targetPlayer)
    Detach()
    currentTarget = targetPlayer
    
    highlightInstance = Instance.new("Highlight")
    highlightInstance.FillColor = Color3.fromRGB(255, 50, 50)
    highlightInstance.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlightInstance.FillTransparency = 0.5
    highlightInstance.Parent = currentTarget.Character

    StartAttachmentLoop()
    Notify("Цель захвачена", "Прикреплен к: " .. targetPlayer.Name)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        currentMode = currentMode + 1
        if currentMode > #modes then
            currentMode = 1 
        end
        Notify("Режим изменён", "Текущий режим: " .. modes[currentMode])
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        local targetPart = Mouse.Target
        
        if targetPart then
            local model = targetPart:FindFirstAncestorOfClass("Model")
            if model then
                local clickedPlayer = Players:GetPlayerFromCharacter(model)
                
                if clickedPlayer and clickedPlayer ~= LocalPlayer then
                    if currentTarget == clickedPlayer then
                        Detach()
                        Notify("Открепление", "Вы отцепились от цели.")
                    else
                        AttachToTarget(clickedPlayer)
                    end
                    return
                end
            end
        end

        if currentTarget then
            Detach()
            Notify("Открепление", "Вы отцепились от цели.")
        end
    end
end)

Notify("Скрипт загружен!", "Нажми на цель колёсиком мыши.\nКлавиша X - смена режима.")
