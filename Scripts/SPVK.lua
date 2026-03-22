local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScripterNumber/SPVKHUB/refs/heads/main/Fluent"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local LocalPlayerId = game.Players.LocalPlayer.Character.Name
LocalPlayerId = game:GetService("Players"):GetUserIdFromNameAsync(LocalPlayerId)


local window = Fluent:CreateWindow({
        Title = 'SPVK HUB v0.0.5',
        SubTitle = "(фиксы)",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
        MainTab = window:AddTab({ Title = "Main", Icon = "" }),
        TradeTab = window:AddTab({ Title = "Trade Things", Icon = "" }),
        OtherTab = window:AddTab({ Title = "Other", Icon = "" }),
        VisualTab = window:AddTab({ Title = "Visuals", Icon = "" }),
        RopeTab = window:AddTab({ Title = "Rope Things", Icon = "" }),
        TrollTab = window:AddTab({ Title = "Troll Things", Icon = "" }),
        BindsTab = window:AddTab({ Title = "Binds", Icon = "" }),
}

local Options = Fluent.Options

local FUNCTIONS = {

        test = function() print(123) end,

        TeleportWithRopeUnderMap = function(Rope, Target)
                Rope.Length = Rope.Length <= Rope.Length + 18 and Rope.Length + 18 or Rope.Length
                local OrigTargetPos = Target:GetPivot()
                local UnderTargetPos = OrigTargetPos + Vector3.new(0, -18, 0)
                Target.Humanoid.PlatformStand = true
                Target:PivotTo(UnderTargetPos)
                Target.Humanoid.PlatformStand = false
        end,

        Bring = function(Rope, Target)
                local OurPos = Rope.Parent:GetPivot()
                Target:PivotTo(OurPos)
        end,

}

_G.RagdollTimerEnabled = false
_G.SpiderBoostEnabled = false
_G.AutoSaveEnabled = false

local RainVisuals = {}
_G.WasVisualRain = _G.WasVisualRain == true and _G.WasVisualRain or false

_G.CustomNamesEnabled = false
_G.SelfVisualName = false

local RagdollTimer = Tabs.MainTab:AddToggle("RagdollTimer", {Title = "Таймер рагдолла", Default = false})

RagdollTimer:OnChanged(function()
        _G.RagdollTimerEnabled = Options.RagdollTimer.Value
        
        if _G.RagdollTimerEnabled == true then
        else
        end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local activeTimers = {}

local function createTimer(character)
        if activeTimers[character] then
                return
        end
        
        activeTimers[character] = true
        
        local head = character:FindFirstChild("Head")
        if not head then return end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "TimerGui"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = true
        textLabel.TextColor3 = Color3.new(1, 0, 0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Parent = billboard
        
        local timeLeft = 5
        
        while timeLeft > 0 do
                textLabel.Text = string.format("%.1f", timeLeft)
                task.wait(0.1)
                timeLeft = timeLeft - 0.1
        end
        
        billboard:Destroy()
        activeTimers[character] = nil
end

RunService.Heartbeat:Connect(function()
        if not _G.RagdollTimerEnabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                        local ragAttribute = player.Character:GetAttribute("rag")
                        if ragAttribute == true and not activeTimers[player.Character] then
                                task.spawn(createTimer, player.Character)
                        end
                end
        end
end)

_G.SignViewer = function(isEnabled)

        if isEnabled then

                local function ApplyText(sign, owner)
                        local SignPart = sign:WaitForChild('Part')
                        local BillboardGui = Instance.new('BillboardGui', SignPart)
                        BillboardGui.ResetOnSpawn = false
                        BillboardGui.Size = UDim2.new(10, 0, 1, 0)
                        BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
                        BillboardGui.AlwaysOnTop = false
                        BillboardGui.LightInfluence = 0
                        local TextLabel = Instance.new('TextLabel', BillboardGui)
                        TextLabel.Size = UDim2.new(1, 0, 1, 0)
                        TextLabel.TextScaled = true
                        TextLabel.Text = owner
                        TextLabel.BackgroundTransparency = 1
                        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end

                _G.SignViewerSignAdded = workspace.ChildAdded:Connect(function(Child)
                        if Child.Name:find('Sign') then
                                local SignOwner = tostring(Child.Name:gsub("'s Sign", ''))
                                if game.Players:FindFirstChild(SignOwner) then
                                        ApplyText(Child, SignOwner)
                                end
                        end
                end)

                for i, Child in pairs(workspace:GetChildren()) do
                        if Child.Name:find('Sign') then
                                local SignOwner = tostring(Child.Name:gsub("'s Sign", ''))
                                if game.Players:FindFirstChild(SignOwner) then
                                        ApplyText(Child, SignOwner)
                                end
                        end
                end

        else

                if _G.SignViewerSignAdded ~= nil then
                        _G.SignViewerSignAdded:Disconnect()
                end

                for i, Child in pairs(workspace:GetChildren()) do
                        if Child.Name:find('Sign') then
                                local SignOwner = tostring(Child.Name:gsub("'s Sign", ''))
                                if game.Players:FindFirstChild(SignOwner) and Child.Part:FindFirstChildOfClass('BillboardGui') then
                                        Child.Part:FindFirstChildOfClass('BillboardGui'):Destroy()
                                end
                        end
                end

        end

end

local SpiderBoost = Tabs.MainTab:AddToggle("SpiderBoost", { Title = "Ранбуст с притягом", Default = false })

SpiderBoost:OnChanged(function()
        _G.SpiderBoostEnabled = Options.SpiderBoost.Value
        
        if _G.SpiderBoostEnabled == true then
                
                local LocalPlayer = game.Players.LocalPlayer
                local Character = LocalPlayer.Character
                
                if _G.ToolBoost ~= nil then
                        _G.ToolBoost:Disconnect()
                end
                _G.ToolBoost = nil
                
                _G.ToolBoost = game.Players.LocalPlayer.Character.ChildAdded:Connect(function(child)
                        if not _G.SpiderBoostEnabled then return end
                        
                        if child:IsA('RopeConstraint') then
                                local rope = game.Players.LocalPlayer.Character:FindFirstChild("RopeConstraint", true)
                                if not rope.Attachment1 and not rope.Attachment1.Parent and not rope.Attachment1.Parent.Parent then
                                        return
                                end
                                if rope.Attachment1.Parent.Parent:FindFirstChild("Humanoid") then
                                        return
                                end
                                local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                                local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if rope.Attachment1.WorldPosition.Y > hrp.Position.Y then
                                        return
                                end
                                humanoid.UseJumpPower = true
                                humanoid.JumpPower = 51
                                child.WinchEnabled = true
                                child.WinchForce = 35075
                                child.WinchResponsiveness = 105
                                child.WinchSpeed = 105
                        end
                end)
                
                LocalPlayer.CharacterAdded:Connect(function(Char)
                        if not _G.SpiderBoostEnabled then return end
                        
                        if _G.ToolBoost then
                                _G.ToolBoost:Disconnect()
                        end
                        _G.ToolBoost = nil
                        
                        _G.ToolBoost = game.Players.LocalPlayer.Character.ChildAdded:Connect(function(child)
                                if not _G.SpiderBoostEnabled then return end
                                
                                if child:IsA('RopeConstraint') then
                                        local rope = game.Players.LocalPlayer.Character:FindFirstChild("RopeConstraint", true)
                                        if not rope.Attachment1 and not rope.Attachment1.Parent and not rope.Attachment1.Parent.Parent then
                                                return
                                        end
                                        if rope.Attachment1.Parent.Parent:FindFirstChild("Humanoid") then
                                                return
                                        end
                                        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                                        local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                        if rope.Attachment1.WorldPosition.Y > hrp.Position.Y then
                                                return
                                        end
                                        humanoid.UseJumpPower = true
                                        humanoid.JumpPower = 51
                                        child.WinchEnabled = true
                                        child.WinchForce = 35075
                                        child.WinchResponsiveness = 105
                                        child.WinchSpeed = 105
                                end
                        end)
                end)
        else
                
                if _G.ToolBoost ~= nil then
                        _G.ToolBoost:Disconnect()
                end
                _G.ToolBoost = nil
        end
end)

local AutoSave = Tabs.MainTab:AddToggle("AutoSave", { Title = "Авто сейв верёвкой", Default = false })

AutoSave:OnChanged(function()
        _G.AutoSaveEnabled = Options.AutoSave.Value
        
        if _G.AutoSaveEnabled == true then
        else
        end
end)

local function setupAutoSave()
        local Player = game.Players.LocalPlayer
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:WaitForChild("Humanoid")
        
        local BlockedParts = { Character,
                workspace.RagdollParts,
                workspace.PoisonParts,
                workspace.KillParts,
                workspace.SignPlaceRegion
        }
        
        local shouldStop = false
        local lastHealth = Humanoid.Health
        
        local function InitBlockedParts()
                spawn(function()
                        for i, v in pairs(workspace:GetChildren()) do
                                if v.Name == 'Wedge' or v.Name == 'Part' or v.Name == 'po' then
                                        table.insert(BlockedParts, v)
                                end
                        end
                end)
        end
        
        InitBlockedParts()
        
        local function findNearbyParts(radius)
                local overlapParams = OverlapParams.new()
                overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
                overlapParams.FilterDescendantsInstances = BlockedParts
                
                local parts = workspace:GetPartBoundsInRadius(HumanoidRootPart.Position, radius, overlapParams)
                
                for _, part in pairs(parts) do
                        if part.CanQuery == true then
                                return true
                        end
                end
                
                return false
        end
        
        local function placeRope()
                local startPos = HumanoidRootPart.Position
                local direction = Vector3.new(0, -0.1, 0)
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = { Character }
                
                local rayResult = workspace:Raycast(startPos, direction * 100000, raycastParams)
                
                if rayResult then
                        local hitPos = rayResult.Position
                        local targetDirection = (hitPos - startPos).Unit
                        local distance = (hitPos - startPos).Magnitude
                        
                        local args = {
                                Ray.new(startPos, targetDirection * distance)
                        }
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("MouseClick"):FireServer(unpack(args))
                else
                        local args = {
                                Ray.new(startPos, direction * 100000)
                        }
                        
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("MouseClick"):FireServer(unpack(args))
                end
        end
        
        Humanoid.HealthChanged:Connect(function(health)
                if not _G.AutoSaveEnabled then return end
                
                if health >= lastHealth then
                        shouldStop = true
                        lastHealth = health
                        return
                end
                
                lastHealth = health
                
                shouldStop = false
                
                spawn(function()
                        if Player.Backpack['Верёвка'] then
                                Player.Backpack['Верёвка'].Parent = Character
                        end
                        
                        if not Character:FindFirstChild('Верёвка') then
                                return
                        end
                        
                        if Character:FindFirstChild('RopeConstraint') then
                                if shouldStop then return end
                                placeRope()
                                task.wait(0.2)
                                if shouldStop then return end
                                if findNearbyParts(15) then
                                        placeRope()
                                end
                                task.wait(1)
                                if shouldStop then return end
                                placeRope()
                        else
                                if shouldStop then return end
                                placeRope()
                                task.wait(1)
                                if shouldStop then return end
                                placeRope()
                        end
                end)
        end)
end

local AutoLoot = Tabs.MainTab:AddToggle("AutoLoot", { Title = "Авто лут (бета)", Default = false })

AutoLoot:OnChanged(function()
        AutoLootToggle = Options.AutoLoot.Value
        
        if AutoLootToggle == true then
                
                while AutoLootToggle do
                        
                        for i, v in pairs(workspace:GetChildren()) do
                                if v:IsA('Folder') and v.Name == 'Folder' and v:FindFirstChild('Handle') and v.Handle:FindFirstChild('ItemGlow') then
                                        firetouchinterest(v.Handle, game.Players.LocalPlayer.Character.Torso, 1)
                                        firetouchinterest(v.Handle, game.Players.LocalPlayer.Character.Torso, 0)
                                        spawn(function()
                                                for i, v in pairs(v:GetDescendants()) do
                                                        if v:IsA('Part') or v:IsA('MeshPart') or v:IsA('UnionOperation') or v:IsA('WedgePart') then
                                                                v.CanCollide = false
                                                                v.CanQuery = false
                                                        end
                                                        if v.Name == 'ItemGlow' then
                                                                v.Enabled = false
                                                        end
                                                end
                                        end)
                                        v.Handle:PivotTo(game.Players.LocalPlayer.Character:GetPivot())
                                end
                        end

                        task.wait()

                end

        else
                
                AutoLootToggle = false

        end
end)

local GlobalJumpPowerSelected = 50

local JumpPowerInput = Tabs.MainTab:AddInput("JumpPowerInput", {
        Title = "Jump Power",
        Default = '50',
        Placeholder = "Силу прыжка введи тут",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then
                        GlobalJumpPowerSelected = Value
                end
        end
})

local LoopJPToggle = Tabs.MainTab:AddToggle("LoopJPToggle", { Title = "Включить силу прыжка", Default = false })

LoopJPToggle:OnChanged(function()
        LoopJPToggleVal = Options.LoopJPToggle.Value
        
        if LoopJPToggleVal == true then
                while LoopJPToggleVal do
                        if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 and LocalPlayer.Character:GetAttribute('rag') == false then
                                LocalPlayer.Character.Humanoid.UseJumpPower = true
                                LocalPlayer.Character.Humanoid.JumpPower = GlobalJumpPowerSelected
                        end
                        task.wait()
                end
        else
        if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 and LocalPlayer.Character:GetAttribute('rag') == false then

        LocalPlayer.Character.Humanoid.UseJumpPower = true
        LocalPlayer.Character.Humanoid.JumpPower = 50

        end

        end
end)

Tabs.MainTab:AddParagraph({
        Title = "Рейдж",
        Content = ""
})

local Velocity = Tabs.MainTab:AddToggle("Velocity", { Title = "Велосити-Анти-киды", Default = false })
local VelocityConn = nil
Velocity:OnChanged(function()
        VelocityToggle = Options.Velocity.Value
        
        if VelocityToggle then
                
                if VelocityConn ~= nil then
                        VelocityConn:Disconnect()
                        VelocityConn = nil
                end

                VelocityConn = LocalPlayer.Character.DescendantAdded:Connect(function(Child)
                        if Child:IsA('BodyVelocity') then
                                print(Child.Name)
                                Child.Velocity = vector.zero
                                
                                spawn(function()

                                        for i, v in pairs(LocalPlayer.Character:GetChildren()) do
                                                v.AssemblyLinearVelocity = vector.zero
                                        end

                                end)

                        end
                end)

        else
                if VelocityConn ~= nil then
                        VelocityConn:Disconnect()
                        VelocityConn = nil
                end
        end
end)

local AntiBananas = Tabs.MainTab:AddToggle("AntiBananas", { Title = "Анти-бананы (ворк 50/50)", Default = false })
local AntiBananasConn = nil
AntiBananas:OnChanged(function()
        AntiBananasToggle = Options.AntiBananas.Value
        
        if AntiBananasToggle then
                
                if AntiBananasConn ~= nil then
                        AntiBananasConn:Disconnect()
                        AntiBananasConn = nil
                end

                AntiBananasConn = game.RunService.RenderStepped:Connect(function()
                        for i, v in pairs(workspace:GetChildren()) do
                                if v.Name == 'Banana' then
                                        v.CanTouch = false
                                end
                        end
                end)

        else
                if AntiBananasConn ~= nil then
                        AntiBananasConn:Disconnect()
                        AntiBananasConn = nil
                end

                for i, v in pairs(workspace:GetChildren()) do
                        if v.Name == 'Banana' then
                                v.CanTouch = true
                        end
                end

        end
end)

local FastUnRagdollConnection = nil

local FastUnRagdoll = Tabs.MainTab:AddToggle("FastUnRagdoll", { Title = "Фаст вставание при рагдолле", Default = false })

FastUnRagdoll:OnChanged(function()
        FastUnRagdollToggle = Options.FastUnRagdoll.Value
        
        if FastUnRagdollToggle == true then
                
                local Character = LocalPlayer.Character

                if Character ~= nil then
                        if FastUnRagdollConnection ~= nil then
                                FastUnRagdollConnection:Disconnect()
                                FastUnRagdollConnection = nil
                        end
                        FastUnRagdollConnection = Character:GetAttributeChangedSignal("rag"):Connect(function()
                                if Character:GetAttribute('rag') == true then
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                                        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        wait(0.3)
                                        Character.Humanoid.Sit = true
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                                        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        wait(0.05)
                                        Character.Humanoid.Sit = true
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                                        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        Character.Humanoid.AutoRotate = true
                                        Character.Humanoid.Sit = false
                                        Character.Humanoid.AutoRotate = true
                                end
                        end)
                end

        else
                if FastUnRagdollConnection ~= nil then
                        FastUnRagdollConnection:Disconnect()
                        FastUnRagdollConnection = nil
                end
        end
end)

local AntiDangerParts = false

local AntiDangerPartsButton = Tabs.MainTab:AddToggle("AntiDangerPartsButton", { Title = "Отключить опасные парты (рагдолл\килл\огонь)", Default = false })

AntiDangerPartsButton:OnChanged(function()
        AntiDangerPartsToggle = Options.AntiDangerPartsButton.Value
        
        if AntiDangerPartsToggle == true then
                task.spawn(function()

                        for i, v in pairs(workspace.RagdollParts:GetChildren()) do
                                v.CanTouch = false
                        end

                end)
                task.spawn(function()

                        for i, v in pairs(workspace.PoisonParts:GetChildren()) do
                                v.CanTouch = false
                        end

                end)
                task.spawn(function()

                        for i, v in pairs(workspace.KillParts:GetChildren()) do
                                v.CanTouch = false
                        end

                end)
                task.spawn(function()

                        for i, v in pairs(workspace.FireParts:GetChildren()) do
                                v.CanTouch = false
                        end

                end)
                AntiDangerParts = true
        else
                AntiDangerParts = false
                task.spawn(function()

                        for i, v in pairs(workspace.RagdollParts:GetChildren()) do
                                v.CanTouch = true
                        end

                end)
                task.spawn(function()

                        for i, v in pairs(workspace.PoisonParts:GetChildren()) do
                                v.CanTouch = true
                        end

                end)
                task.spawn(function()

                        for i, v in pairs(workspace.KillParts:GetChildren()) do
                                v.CanTouch = true
                        end

                end)
                task.spawn(function()

                        for i, v in pairs(workspace.FireParts:GetChildren()) do
                                v.CanTouch = true
                        end

                end)
        end
end)

Tabs.TradeTab:AddParagraph({
        Title = "Блоки трейда",
        Content = ""
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 1",
        Description = "Заблокает дефолтный трейд возле крафта",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                  local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(142.422531, 2050.04907, 127.88311, -0.668970048, 3.59919849e-09, -0.743288875, 4.84288378e-08, 1, -4.84287739e-08, 0.743291557, 6.83940371e-08, -0.668969691)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд второй сит",
        Description = "Заблокает дефолтный трейд второй сит возле крафта",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                  local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(158.627472, 2050.72412, 143.999985, 0.698014498, 2.69277461e-10, 0.716085136, -1.86264693e-08, 1, 1.86264622e-08, -0.71608603, 2.10717204e-08, 0.698014379)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 2",
        Description = "Заблокает трейд тот через реку",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(-156.7, 2049.34912, 192.076538, 0.0228189826, 0, 0.999739647, 0, 1, 0, -0.999739647, 0, 0.0228189826)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 2 второй сит",
        Description = "Заблокает трейд тот через реку второй сит",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(-179.953842, 2049.84912, 192.11087, 0.0013421505, -4.83637237e-08, 0.999999106, 4.84288591e-08, 1, -4.84287881e-08, -1.00000203, -4.84938312e-08, 0.0013429235)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 3",
        Description = "Заблокает трейд тот через реку другой",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(-234.038635, 2049.22412, 245.946762, -0.00767621491, 0, -0.999970496, -3.7252903e-09, 1, 3.7252903e-09, 0.999970615, 0, -0.00767624378)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 3 второй сит",
        Description = "Заблокает трейд тот через реку другой второй сит",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(-211.090363, 2049.84912, 245.986923, -0.0190743208, 0, 0.999818027, 0, 1, 0, -0.999818027, 0, -0.0190743208)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 4",
        Description = "Заблокает золотой трейд",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(-219.4229736328125, 2098.349609375, 213.3)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 4 второй сит",
        Description = "Заблокает золотой трейд второй сит",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(-241.8, 2098.34912, 212.857391, 0.000854432583, 0, 0.999999702, 0, 1, 0, -0.999999702, 0, 0.000854432583)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 5",
        Description = "Заблокает трейд в канафке под картой",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        "create",
                        CFrame.new(153.699951, 2022.47449, -84.7629395, 0.971885681, 0, 0.235453948, -3.7252903e-09, 1, 3.7252903e-09, -0.235454008, 0, 0.971885562)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddButton({
        Title = "Заблокать трейд 5 второй сит",
        Description = "Заблокает трейд в канафке под картой второй сит",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        CFrame.new(149.745255, 2022.47449, -107.466614, -0.985789359, 0, -0.167986825, -3.7252903e-09, 1, 3.7252903e-09, 0.16798687, 0, -0.985789239)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

        end
})

Tabs.TradeTab:AddParagraph({
        Title = "Фаст сит",
        Content = ""
})

Tabs.TradeTab:AddButton({
        Title = "Трейд/Анти-верёвки",
        Description = "Садит тебя на дефолтный трейд, сбрасывает верёвку, без овнера, без кд",
        Callback = function()
                
                local Positions = {
                        Vector3.new(142.36827087402344, 2050.30029296875, 127.86827087402344),
                        Vector3.new(158.63172912597656, 2050.30029296875, 144.13172912597656)
                }

                local function isTrue(Seat)
                        local list = {}
                        for i, v in pairs(Positions) do
                                if Seat.Position == v then
                                        table.insert(list, Seat)
                                end
                        end
                        return list
                end

                for i, v in pairs(workspace.TradeSeats:GetDescendants()) do
                        if v:IsA('Seat') and isTrue(v)[1] ~= nil then
                            replicatesignal(v.RemoteCreateSeatWeld, game.Players.LocalPlayer.Character.Humanoid)
                        end
                end

        end
})

Tabs.TradeTab:AddButton({
        Title = "Трейд 2/Анти-верёвки",
        Description = "Садит тебя на трейд через реку",
        Callback = function()
                
                local Positions = {
                        Vector3.new(-180, 2050.30029296875, 192),
                        Vector3.new(-157, 2050.30029296875, 192)
                }

                local function isTrue(Seat)
                        local list = {}
                        for i, v in pairs(Positions) do
                                if Seat.Position == v then
                                        table.insert(list, Seat)
                                end
                        end
                        return list
                end

                for i, v in pairs(workspace.TradeSeats:GetDescendants()) do
                        if v:IsA('Seat') and isTrue(v)[1] ~= nil then
                            replicatesignal(v.RemoteCreateSeatWeld, game.Players.LocalPlayer.Character.Humanoid)
                        end
                end

        end
})

Tabs.TradeTab:AddButton({
        Title = "Трейд 3/Анти-верёвки",
        Description = "Садит тебя на второй трейд через реку",
        Callback = function()
                
                local Positions = {
                        Vector3.new(-211, 2050.30029296875, 246),
                        Vector3.new(-234, 2050.30029296875, 246)
                }

                local function isTrue(Seat)
                        local list = {}
                        for i, v in pairs(Positions) do
                                if Seat.Position == v then
                                        table.insert(list, Seat)
                                end
                        end
                        return list
                end

                for i, v in pairs(workspace.TradeSeats:GetDescendants()) do
                        if v:IsA('Seat') and isTrue(v)[1] ~= nil then
                            replicatesignal(v.RemoteCreateSeatWeld, game.Players.LocalPlayer.Character.Humanoid)
                        end
                end

        end
})

Tabs.TradeTab:AddButton({
        Title = "Трейд 4/Анти-верёвки",
        Description = "Садит тебя на золотой трейд",
        Callback = function()
                
                local Positions = {
                        Vector3.new(-219, 2099.30029296875, 213),
                        Vector3.new(-242, 2099.30029296875, 213)
                }

                local function isTrue(Seat)
                        local list = {}
                        for i, v in pairs(Positions) do
                                if Seat.Position == v then
                                        table.insert(list, Seat)
                                end
                        end
                        return list
                end

                for i, v in pairs(workspace.TradeSeats:GetDescendants()) do
                        if v:IsA('Seat') and isTrue(v)[1] ~= nil then
                            replicatesignal(v.RemoteCreateSeatWeld, game.Players.LocalPlayer.Character.Humanoid)
                        end
                end

        end
})

Tabs.TradeTab:AddButton({
        Title = "Трейд 5/Анти-верёвки",
        Description = "Садит тебя на трейд в канафке под картой",
        Callback = function()
                
                local Positions = {
                        Vector3.new(153.64410400390625, 2022.55029296875, -84.81301879882812),
                        Vector3.new(149.6501922607422, 2022.55029296875, -107.4636001586914)
                }

                local function isTrue(Seat)
                        local list = {}
                        for i, v in pairs(Positions) do
                                if Seat.Position == v then
                                        table.insert(list, Seat)
                                end
                        end
                        return list
                end

                for i, v in pairs(workspace.TradeSeats:GetDescendants()) do
                        if v:IsA('Seat') and isTrue(v)[1] ~= nil then
                            replicatesignal(v.RemoteCreateSeatWeld, game.Players.LocalPlayer.Character.Humanoid)
                        end
                end

        end
})

Tabs.OtherTab:AddButton({
        Title = "Табличка в торсо",
        Description = "",
        Callback = function()
                local player = game.Players.LocalPlayer
                local character = player.Character
                local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))

                local args = {
                        buffer.fromstring('\000'),
                        humanoidRootPart.CFrame + Vector3.new(0, -2.7, 0)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))
        end
})

Tabs.OtherTab:AddButton({
        Title = "Удалить табличку",
        Description = "",
        Callback = function()
                local args = {
                        buffer.fromstring('\002'),
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SignManager"):InvokeServer(unpack(args))
        end
})

local HitboxShow = Tabs.OtherTab:AddToggle("HitboxShow", {Title = "Показывать хитбокса удара", Default = false})

HitboxShow:OnChanged(function()
        HitboxShowToggle = Options.HitboxShow.Value

        if HitboxShowToggle == true then

                        while HitboxShowToggle do
                                task.wait()

                                if not HitboxShowToggle then 
                                        continue 
                                end

                                if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChild('Hitbox') then
                                        LocalPlayer.Character:FindFirstChild('Hitbox').Transparency = 0.4
                                end

                                if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChildOfClass('Tool') and LocalPlayer.Character:FindFirstChildOfClass('Tool'):FindFirstChild('Hitbox') then
                                        LocalPlayer.Character:FindFirstChildOfClass('Tool'):FindFirstChild('Hitbox').Transparency = 0.4
                                end

                        end

        else
                  if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChild('Hitbox') then
                        LocalPlayer.Character:FindFirstChild('Hitbox').Transparency = 1
                end

                if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChildOfClass('Tool') and LocalPlayer.Character:FindFirstChildOfClass('Tool'):FindFirstChild('Hitbox') then
                        LocalPlayer.Character:FindFirstChildOfClass('Tool'):FindFirstChild('Hitbox').Transparency = 1
                end
        end
end)

Tabs.OtherTab:AddParagraph({
        Title = "Остальное ещё",
        Content = ""
})

Tabs.OtherTab:AddButton({
        Title = "Быстрый доступ к парту Kil",
        Description = "Типа идет за тебя к парту Kil (ты умрешь и т.д.)",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then
                        local Targeting = true
                        while Targeting do
                                if Targeting == true then
                                        LocalPlayer.Character.Humanoid.WalkToPoint = Vector3.new(0, 0, -25)
                                        if (LocalPlayer.Character.Torso.Position - workspace.startPart.Position).Magnitude <= 20 then
                                                Targeting = false
                                                wait(3)
                                                LocalPlayer.Character:PivotTo(CFrame.new(-3, -12269, -32))
                                                LocalPlayer.Character.Humanoid.Health = 0
                                                LocalPlayer.Character.Torso.Anchored = true
                                                replicatesignal(LocalPlayer.Kill)
                                                break
                                        end
                                else
                                        break
                                end
                                task.wait()
                        end
                end
        end
})

Tabs.OtherTab:AddButton({
        Title = "Открыть крафт (визуал + ворк)",
        Description = "Открывает менюшку крафта",
        Callback = function()
                if LocalPlayer.Character ~= nil then
                        game:GetService("Players").LocalPlayer.PlayerGui.UI.CraftFrame.Visible = true
                end
        end
})

Tabs.OtherTab:AddButton({
    Title = "Перезайти на сервер через встроенный :rejoin Khols",
    Description = "Перезаходит на сервак через встроенную команда в Khols Admin",
    Callback = function()
        game:GetService('TextChatService').TextChannels.RBXGeneral:SendAsync(':rejoin')
    end
})

Tabs.OtherTab:AddButton({
    Title = "Фейк-аут (Убить бангера)",
    Description = "Фейк аут делает",
    Callback = function()
        local RunService = game:GetService('RunService')
        local Character = LocalPlayer.Character
        local HumanoidRootPart = Character.HumanoidRootPart

        if getgenv().AntiCollide then
                getgenv().AntiCollide:Disconnect()
                getgenv().AntiCollide = nil
        end

        local touchConnections = {}
        for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                        local conn = v.Touched:Connect(function() end)
                        table.insert(touchConnections, conn)
                        v.CanTouch = false
                end
        end

        for _, v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                        v.CanTouch = false
                end
        end

        getgenv().AntiCollide = RunService.Stepped:Connect(function()
                for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                                for _, v in pairs(player.Character:GetDescendants()) do
                                        if v:IsA("BasePart") then
                                                v.CanCollide = false
                                        end
                                end
                        end
                end
        end)

        local spos = HumanoidRootPart.CFrame
        local targetPos = CFrame.new(1136.749657, 21999, 219.829498, 0.0251305904, 0.984496653, -0.173593849, 7.79661491e-09, 0.173648685, 0.98480767, 0.999684155, -0.0247488003, 0.00436388655)
        local midPos = CFrame.new(116.749657, 2166, 219.829498, 0.0251305904, 0.984496653, -0.173593849, 7.79661491e-09, 0.173648685, 0.98480767, 0.999684155, -0.0247488003, 0.00436388655)
        local lowPos = CFrame.new(0, 2040, -512, 1, 0, 0, 0, 1, 0, 0, 0, 1)

        local ping = LocalPlayer:GetNetworkPing()

        local freezeConnection
        freezeConnection = RunService.Heartbeat:Connect(function()
                for _, v in pairs(Character:GetDescendants()) do
                        if v:IsA("BasePart") then
                                v.AssemblyLinearVelocity = Vector3.zero
                                v.AssemblyAngularVelocity = Vector3.zero
                        end
                end
        end)

        for i = 1, 35 do
                HumanoidRootPart.CFrame = targetPos
                RunService.Heartbeat:Wait()
        end

        HumanoidRootPart.Anchored = true

        task.wait(3 + ping * 5)

        HumanoidRootPart.Anchored = false

        for i,v in next, workspace.KillParts:GetChildren() do
        v.CanTouch = false
        end

        for i = 1, 30 do
                HumanoidRootPart.CFrame = midPos
                RunService.Heartbeat:Wait()
        end

        HumanoidRootPart.Anchored = true

        task.wait(3 + ping * 5)

        HumanoidRootPart.Anchored = false

        for i = 1, 30 do
                HumanoidRootPart.CFrame = lowPos
                RunService.Heartbeat:Wait()
        end

        HumanoidRootPart.Anchored = true

        task.wait(0.5 + ping * 5)

        HumanoidRootPart.Anchored = false

        for i = 1, 35 do
                HumanoidRootPart.CFrame = targetPos
                RunService.Heartbeat:Wait()
        end

        for i = 1, 30 do
                HumanoidRootPart.CFrame = spos
                RunService.Heartbeat:Wait()
        end

        for i,v in next, workspace.KillParts:GetChildren() do
        v.CanTouch = not AntiDangerParts
        end

        freezeConnection:Disconnect()

        for _, v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                        v.AssemblyLinearVelocity = Vector3.zero
                        v.AssemblyAngularVelocity = Vector3.zero
                end
        end

        task.wait(0.5)

        for _, conn in pairs(touchConnections) do
                conn:Disconnect()
        end

        for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                        v.CanTouch = true
                end
        end

        for _, v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                        v.CanTouch = true
                end
        end

        if getgenv().AntiCollide then
                getgenv().AntiCollide:Disconnect()
                getgenv().AntiCollide = nil
        end
    end
})

Tabs.OtherTab:AddParagraph({
        Title = "Хз ещё чета",
        Content = ""
})

Tabs.OtherTab:AddButton({
        Title = "Убить себя",
        Description = "Просто ты килляешься, палевно ибо да",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then
                        LocalPlayer.Character.Humanoid.Health = 0
                end
        end
})

Tabs.OtherTab:AddButton({
        Title = "Рагдоллнуть себя",
        Description = "",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then
                        workspace.RagdollParts.Part.CanTouch = true
                        firetouchinterest(LocalPlayer.Character.Torso, workspace.RagdollParts.Part, 1)
                        firetouchinterest(LocalPlayer.Character.Torso, workspace.RagdollParts.Part, 0)
                        if AntiDangerParts then
                                workspace.RagdollParts.Part.CanTouch = false
                        end
                end
        end
})

Tabs.OtherTab:AddParagraph({
        Title = "ПВП-ШНОЕ",
        Content = ""
})

Tabs.OtherTab:AddButton({
    Title = "Врубить/Вырубить пвп",
    Description = "Врубает или вырубает пвп",
    Callback = function()
        if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChild('pvpBillboard') then

                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PVPToggle"):InvokeServer(false)

        else

                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PVPToggle"):InvokeServer(true)

        end
    end
})

local VisualRain = Tabs.VisualTab:AddToggle("VisualRain", { Title = "Визуальный дождь", Default = false })

VisualRain:OnChanged(function()
        VisualRainToggle = Options.VisualRain.Value

        if VisualRainToggle == true then

                local RainM = game:GetService("ReplicatedStorage").RainM:Clone()
                RainM.Parent = workspace
                spawn(function()
                        for i = 1, #RainM:GetChildren() - 1 do
                        end
                        local LastPart = RainM:GetChildren()[1]
                        LastPart.ParticleEmitter.Enabled = true
                        LastPart.ParticleEmitter.Rate = 99999
                        LastPart.Size = Vector3.new(750, 0.25, 750)
                        for i = 1, 150 do
                                LastPart:Clone().Parent = RainM
                        end
                end)
                local RainSound = game:GetService("ReplicatedStorage").Sounds["Heavy Rain 2 (SFX)"]:Clone()
                RainSound.Parent = workspace
                RainSound.Playing = true

                local Atmosphere = game:GetService("ReplicatedStorage").WinterAtmosphere.Atmosphere:Clone()
                Atmosphere.Parent = game.Lighting
                Atmosphere.Density = 0.5
                Atmosphere.Offset = 0.354
                Atmosphere.Color = Color3.fromRGB(200, 170, 108)
                Atmosphere.Decay = Color3.fromRGB(92, 60, 14)
                Atmosphere.Haze = 0
                Atmosphere.Glare = 0
                game.Lighting.Ambient = Color3.fromRGB(138, 138, 138)
                game.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                game.Lighting.ColorShift_Bottom = Color3.fromRGB(128, 128, 128)
                game.Lighting.ColorShift_Top = Color3.fromRGB(128, 128, 128)
                game.Lighting.Brightness = 1
                game.Lighting.EnvironmentDiffuseScale = 0.02
                local Sky = game:GetService("ReplicatedStorage").WinterAtmosphere.Sky:Clone()
                Sky.Parent = game.Lighting
                Sky.SkyboxBk = 'rbxassetid://246480323'
                Sky.SkyboxDn = 'rbxassetid://246480523'
                Sky.SkyboxFt = 'rbxassetid://246480105'
                Sky.SkyboxLf = 'rbxassetid://246480549'
                Sky.SkyboxRt = 'rbxassetid://246480565'
                Sky.SkyboxUp = 'rbxassetid://246480504'

                game.Lighting.Brightness = 1
                game.Lighting.ExposureCompensation = -0.2

                if not _G.LightingProtectionHook then
                        _G.LightingProtectionEnabled = true
                        local old_newindex

                        old_newindex = hookmetamethod(game, "__newindex", newcclosure(function(self, property, value)
                                if _G.LightingProtectionEnabled and (self == game.Lighting or self:IsDescendantOf(game.Lighting)) then
                                        return
                                end
                                return old_newindex(self, property, value)
                        end))

                        _G.LightingProtectionHook = old_newindex
                else
                        _G.LightingProtectionEnabled = true
                end

                game.Lighting.Brightness = 1

                _G.LightingProtectionEnabled = true

                game.Lighting.Brightness = 1

                table.insert(RainVisuals, RainM)
                table.insert(RainVisuals, RainSound)
                table.insert(RainVisuals, Atmosphere)
                table.insert(RainVisuals, Sky)

        else

                _G.LightingProtectionEnabled = false

                game.Lighting.Brightness = 2
                game.Lighting.ExposureCompensation = 0

                spawn(function()
                        for i, v in pairs(RainVisuals) do
                                v:Destroy()
                        end
                        RainVisuals = {}
                end)
        end
end)

local FancyNicks = Tabs.VisualTab:AddToggle("FancyNicks", { Title = "Фанси никнеймы", Default = false })

FancyNicks:OnChanged(function()
        FancyNicksToggle = Options.FancyNicks.Value

        if FancyNicksToggle == true then

                _G.CustomNamesEnabled = true

                for _, player in pairs(Players:GetPlayers()) do
                        if player.Character then
                                if player == LocalPlayer and not _G.SelfVisualName then

                                else
                                        local head = player.Character:FindFirstChild("Head")
                                        if head then
                                                if head:FindFirstChild("Nickname") then
                                                        head:FindFirstChild("Nickname"):Destroy()
                                                end

                                                local humanoid = player.Character:FindFirstChild("Humanoid")
                                                if humanoid then
                                                        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                                                end

                                                local BillboardGui = Instance.new('BillboardGui', head)
                                                BillboardGui.Size = UDim2.new(5, 0, 1, 0)
                                                BillboardGui.StudsOffset = Vector3.new(0, 1.5, 0)
                                                BillboardGui.Name = 'Nickname'

                                                local NickLabel = Instance.new('TextLabel', BillboardGui)
                                                NickLabel.Font = Enum.Font.Roboto
                                                NickLabel.FontFace.Weight = Enum.FontWeight.Bold
                                                NickLabel.Text = player.DisplayName
                                                NickLabel.Position = UDim2.new(0.2, 0, 0, 0)
                                                NickLabel.TextXAlignment = Enum.TextXAlignment.Left
                                                NickLabel.Size = UDim2.new(1, 0, 1, 0)
                                                NickLabel.BackgroundTransparency = 1
                                                NickLabel.TextScaled = true
                                                NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                                NickLabel.BorderSizePixel = 0

                                                local ProfilePic = Instance.new('ImageLabel', BillboardGui)
                                                ProfilePic.Size = UDim2.new(0.18, 0, 1, 0)
                                                ProfilePic.BorderSizePixel = 0
                                                ProfilePic.BackgroundTransparency = 1
                                                ProfilePic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
                                        end
                                end
                        end

                        player.CharacterAdded:Connect(function(character)
                                if not _G.CustomNamesEnabled then return end
                                if player == LocalPlayer and not _G.SelfVisualName then return end

                                local head = character:WaitForChild("Head")

                                if head:FindFirstChild("Nickname") then
                                        head:FindFirstChild("Nickname"):Destroy()
                                end

                                local humanoid = character:FindFirstChild("Humanoid")
                                if humanoid then
                                        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                                end

                                local BillboardGui = Instance.new('BillboardGui', head)
                                BillboardGui.Size = UDim2.new(5, 0, 1, 0)
                                BillboardGui.StudsOffset = Vector3.new(0, 1.5, 0)
                                BillboardGui.Name = 'Nickname'

                                local NickLabel = Instance.new('TextLabel', BillboardGui)
                                NickLabel.Font = Enum.Font.Roboto
                                NickLabel.FontFace.Weight = Enum.FontWeight.Bold
                                NickLabel.Text = player.DisplayName
                                NickLabel.Position = UDim2.new(0.2, 0, 0, 0)
                                NickLabel.TextXAlignment = Enum.TextXAlignment.Left
                                NickLabel.Size = UDim2.new(1, 0, 1, 0)
                                NickLabel.BackgroundTransparency = 1
                                NickLabel.TextScaled = true
                                NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                NickLabel.BorderSizePixel = 0

                                local ProfilePic = Instance.new('ImageLabel', BillboardGui)
                                ProfilePic.Size = UDim2.new(0.18, 0, 1, 0)
                                ProfilePic.BorderSizePixel = 0
                                ProfilePic.BackgroundTransparency = 1
                                ProfilePic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
                        end)
                end

                Players.PlayerAdded:Connect(function(player)
                        player.CharacterAdded:Connect(function(character)
                                if not _G.CustomNamesEnabled then return end
                                if player == LocalPlayer and not _G.SelfVisualName then return end

                                local head = character:WaitForChild("Head")

                                if head:FindFirstChild("Nickname") then
                                        head:FindFirstChild("Nickname"):Destroy()
                                end

                                local humanoid = character:FindFirstChild("Humanoid")
                                if humanoid then
                                        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                                end

                                local BillboardGui = Instance.new('BillboardGui', head)
                                BillboardGui.Size = UDim2.new(5, 0, 1, 0)
                                BillboardGui.StudsOffset = Vector3.new(0, 1.5, 0)
                                BillboardGui.Name = 'Nickname'

                                local NickLabel = Instance.new('TextLabel', BillboardGui)
                                NickLabel.Font = Enum.Font.Roboto
                                NickLabel.FontFace.Weight = Enum.FontWeight.Bold
                                NickLabel.Text = player.DisplayName
                                NickLabel.Position = UDim2.new(0.2, 0, 0, 0)
                                NickLabel.TextXAlignment = Enum.TextXAlignment.Left
                                NickLabel.Size = UDim2.new(1, 0, 1, 0)
                                NickLabel.BackgroundTransparency = 1
                                NickLabel.TextScaled = true
                                NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                NickLabel.BorderSizePixel = 0

                                local ProfilePic = Instance.new('ImageLabel', BillboardGui)
                                ProfilePic.Size = UDim2.new(0.18, 0, 1, 0)
                                ProfilePic.BorderSizePixel = 0
                                ProfilePic.BackgroundTransparency = 1
                                ProfilePic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
                        end)
                end)

        else

                _G.CustomNamesEnabled = false

                for _, player in pairs(Players:GetPlayers()) do
                        if player.Character then
                                local head = player.Character:FindFirstChild("Head")
                                if head and head:FindFirstChild("Nickname") then
                                        head:FindFirstChild("Nickname"):Destroy()
                                end

                                local humanoid = player.Character:FindFirstChild("Humanoid")
                                if humanoid then
                                        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                                end
                        end
                end

        end
end)

local SeeMineFancyNickname = Tabs.VisualTab:AddToggle("SeeMineFancyNickname", { Title = "Видить свой фанси ник", Default = false })

SeeMineFancyNickname:OnChanged(function()
        SeeMineFancyNicknameToggle = Options.SeeMineFancyNickname.Value

        if SeeMineFancyNicknameToggle == true then
                _G.SelfVisualName = true

                if _G.CustomNamesEnabled and LocalPlayer.Character then
                        local head = LocalPlayer.Character:FindFirstChild("Head")
                        if head then
                                if head:FindFirstChild("Nickname") then
                                        head:FindFirstChild("Nickname"):Destroy()
                                end

                                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                                if humanoid then
                                        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                                end

                                local BillboardGui = Instance.new('BillboardGui', head)
                                BillboardGui.Size = UDim2.new(5, 0, 1, 0)
                                BillboardGui.StudsOffset = Vector3.new(0, 1.5, 0)
                                BillboardGui.Name = 'Nickname'

                                local NickLabel = Instance.new('TextLabel', BillboardGui)
                                NickLabel.Font = Enum.Font.Roboto
                                NickLabel.FontFace.Weight = Enum.FontWeight.Bold
                                NickLabel.Text = LocalPlayer.DisplayName
                                NickLabel.Position = UDim2.new(0.2, 0, 0, 0)
                                NickLabel.TextXAlignment = Enum.TextXAlignment.Left
                                NickLabel.Size = UDim2.new(1, 0, 1, 0)
                                NickLabel.BackgroundTransparency = 1
                                NickLabel.TextScaled = true
                                NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                NickLabel.BorderSizePixel = 0

                                local ProfilePic = Instance.new('ImageLabel', BillboardGui)
                                ProfilePic.Size = UDim2.new(0.18, 0, 1, 0)
                                ProfilePic.BorderSizePixel = 0
                                ProfilePic.BackgroundTransparency = 1
                                ProfilePic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420"
                        end
                end
        else
                _G.SelfVisualName = false

                if LocalPlayer.Character then
                        local head = LocalPlayer.Character:FindFirstChild("Head")
                        if head and head:FindFirstChild("Nickname") then
                                head:FindFirstChild("Nickname"):Destroy()
                        end

                        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                        if humanoid then
                                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                        end
                end
        end
end)

local ClumpsColorButton = Tabs.VisualTab:AddToggle("ClumpsColorButton", { Title = "Летающие партиклы", Default = false })

local ClumpsColorPicker = Tabs.VisualTab:AddColorpicker("ClumpsColorPicker", {
        Title = "Цвет летающих партиклов",
        Default = Color3.fromRGB(60, 87, 157)
})

local CelestialFolder, CelestialList, CelestialConn = nil, {}, nil

ClumpsColorButton:OnChanged(function()
        if Options.ClumpsColorButton.Value then

                CelestialFolder = Instance.new("Folder", workspace)
                CelestialFolder.Name = "CelestialFX"

                for i = 1, 75 do
                        local p = Instance.new("Part", CelestialFolder)
                        p.Size, p.Transparency, p.Anchored, p.CanCollide = Vector3.one * 0.2, 0.5, true, false

                        local a = Instance.new("Attachment", p)
                        local l = Instance.new("PointLight", a)
                        l.Brightness, l.Range, l.Color = 1, 20, Options.ClumpsColorPicker.Value

                        local e = Instance.new("ParticleEmitter", a)
                        e.Texture, e.Size, e.Brightness, e.LightEmission = "rbxassetid://241560722", NumberSequence.new(0.5), 2, 1
                        e.Color, e.Rate, e.Lifetime, e.Speed, e.LockedToPart = ColorSequence.new(Options.ClumpsColorPicker.Value), 0, NumberRange.new(9999), NumberRange.new(0), true
                        e:Emit(1)

                        local angle = math.random() * math.pi * 2
                        local dist = math.random(20, 40)
                        table.insert(CelestialList, {
                                Part = p, Light = l, Emitter = e,
                                Ox = math.random() * 999, Oy = math.random() * 999, Oz = math.random() * 999,
                                Pos = Vector3.new(math.cos(angle) * dist, math.random(-5, 10), math.sin(angle) * dist),
                                Vel = Vector3.new(math.random(-15,15), math.random(-8,8), math.random(-15,15)),
                                FollowPos = Vector3.zero,
                                NextPush = 0
                        })
                end

                CelestialConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
                        local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not root then return end
                        local t = tick()

                        for _, d in ipairs(CelestialList) do
                                local n1 = math.noise(d.Ox, t * 5) * 120
                                local n2 = math.noise(d.Oy, t * 5) * 80
                                local n3 = math.noise(d.Oz, t * 5) * 120
                                local n4 = math.noise(d.Ox + 500, t * 8) * 60
                                local n5 = math.noise(d.Oy + 500, t * 8) * 40
                                local n6 = math.noise(d.Oz + 500, t * 8) * 60

                                local accel = Vector3.new(n1 + n4, n2 + n5, n3 + n6)

                                if t > d.NextPush then
                                        d.Vel = d.Vel + Vector3.new(math.random(-30,30), math.random(-15,15), math.random(-30,30))
                                        d.Ox = d.Ox + math.random() * 10
                                        d.Oy = d.Oy + math.random() * 10
                                        d.Oz = d.Oz + math.random() * 10
                                        d.NextPush = t + math.random() * 2 + 0.5
                                end

                                d.Vel = d.Vel + accel * dt
                                d.Vel = d.Vel * 0.96
                                if d.Vel.Magnitude > 40 then d.Vel = d.Vel.Unit * 40 end
                                if d.Vel.Magnitude < 5 then d.Vel = d.Vel + Vector3.new(math.random(-20,20), math.random(-10,10), math.random(-20,20)) end

                                d.Pos = d.Pos + d.Vel * dt

                                local flatDist = math.sqrt(d.Pos.X ^ 2 + d.Pos.Z ^ 2)
                                if flatDist > 45 then
                                        local n = Vector3.new(d.Pos.X, 0, d.Pos.Z).Unit
                                        d.Pos = Vector3.new(n.X * 45, d.Pos.Y, n.Z * 45)
                                        d.Vel = d.Vel - n * d.Vel:Dot(n) * 2
                                end
                                if flatDist < 12 then
                                        local n = Vector3.new(d.Pos.X, 0, d.Pos.Z).Unit
                                        d.Pos = Vector3.new(n.X * 12, d.Pos.Y, n.Z * 12)
                                        d.Vel = d.Vel - n * d.Vel:Dot(n) * 2
                                end
                                d.Pos = Vector3.new(d.Pos.X, math.clamp(d.Pos.Y, -10, 18), d.Pos.Z)

                                d.FollowPos = d.FollowPos:Lerp(root.Position, dt * 2)
                                d.Part.Position = d.FollowPos + d.Pos
                        end
                end)
        else
                if CelestialConn then CelestialConn:Disconnect() end
                if CelestialFolder then CelestialFolder:Destroy() end
                CelestialList = {}
        end
end)

ClumpsColorPicker:OnChanged(function()
        for _, d in ipairs(CelestialList) do
                d.Light.Color = Options.ClumpsColorPicker.Value
                d.Emitter.Color = ColorSequence.new(Options.ClumpsColorPicker.Value)
        end
end)

local SignViewer = Tabs.VisualTab:AddToggle("SignViewer", { Title = "Посмотреть авторов таблички", Default = false })

SignViewer:OnChanged(function()
        SignViewerToggle = Options.SignViewer.Value

        if SignViewerToggle == true then
                _G.SignViewer(true)
        else
                _G.SignViewer(false)
        end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
        if not _G.CustomNamesEnabled then return end
        if not _G.SelfVisualName then return end

        local head = character:WaitForChild("Head")

        if head:FindFirstChild("Nickname") then
                head:FindFirstChild("Nickname"):Destroy()
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        local BillboardGui = Instance.new('BillboardGui', head)
        BillboardGui.Size = UDim2.new(5, 0, 1, 0)
        BillboardGui.StudsOffset = Vector3.new(0, 1.5, 0)
        BillboardGui.Name = 'Nickname'

        local NickLabel = Instance.new('TextLabel', BillboardGui)
        NickLabel.Font = Enum.Font.Roboto
        NickLabel.FontFace.Weight = Enum.FontWeight.Bold
        NickLabel.Text = LocalPlayer.DisplayName
        NickLabel.Position = UDim2.new(0.2, 0, 0, 0)
        NickLabel.TextXAlignment = Enum.TextXAlignment.Left
        NickLabel.Size = UDim2.new(1, 0, 1, 0)
        NickLabel.BackgroundTransparency = 1
        NickLabel.TextScaled = true
        NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        NickLabel.BorderSizePixel = 0

        local ProfilePic = Instance.new('ImageLabel', BillboardGui)
        ProfilePic.Size = UDim2.new(0.18, 0, 1, 0)
        ProfilePic.BorderSizePixel = 0
        ProfilePic.BackgroundTransparency = 1
        ProfilePic.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420"
end)

local TradeSpyConnection = nil

local TradeSpyConnections = {}
local ActiveTrades = {}

local TradeBillboard = {}

----------------------- TRADE SPY SUKA --------------------


function TradeBillboard.Create(player)
	local character = player.Character
	if not character then return nil end
	
	local head = character:FindFirstChild("Head")
	if not head then return nil end

	local Billboard = Instance.new("BillboardGui")
	Billboard.Name = "TradeBillboard_" .. player.Name
	Billboard.Size = UDim2.new(150, 0, 4, 0)
	Billboard.StudsOffset = Vector3.new(0, 3, 0)
	Billboard.Adornee = head
	Billboard.AlwaysOnTop = true
	Billboard.ResetOnSpawn = false
	Billboard.Parent = LocalPlayer.PlayerGui

	local ItemsHolder = Instance.new("Frame")
	ItemsHolder.Name = "ItemsHolder"
	ItemsHolder.Size = UDim2.new(0, 0, 1, 0)
	ItemsHolder.Position = UDim2.new(0.5, 0, 0, 0)
	ItemsHolder.AnchorPoint = Vector2.new(0.5, 0)
	ItemsHolder.AutomaticSize = Enum.AutomaticSize.X
	ItemsHolder.BackgroundTransparency = 1
	ItemsHolder.Parent = Billboard

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.FillDirection = Enum.FillDirection.Horizontal
	ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ListLayout.Padding = UDim.new(0.002, 0)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ItemsHolder

	return Billboard
end

function TradeBillboard.AddItemCell(billboard, layoutOrder, count)
	local ItemsHolder = billboard.ItemsHolder

	local Cell = Instance.new("Frame")
	Cell.Name = "ItemCell_" .. layoutOrder
	Cell.Size = UDim2.new(0.8, 0, 0.9, 0)
	Cell.SizeConstraint = Enum.SizeConstraint.RelativeYY
	Cell.BackgroundTransparency = 1
	Cell.LayoutOrder = layoutOrder
	Cell.Parent = ItemsHolder

	local ViewportFrame = Instance.new("ViewportFrame")
	ViewportFrame.Name = "ModelViewport"
	ViewportFrame.Size = UDim2.new(1, 0, 1, 0)
	ViewportFrame.BackgroundTransparency = 1
	ViewportFrame.Ambient = Color3.fromRGB(255, 255, 255)
	ViewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	ViewportFrame.LightDirection = Vector3.new(-1, -1, -1)
	ViewportFrame.Parent = Cell

	local Camera = Instance.new("Camera")
	Camera.FieldOfView = 70
	Camera.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = Camera

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = "ItemName"
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.BackgroundTransparency = 1
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.TextScaled = true
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.Text = ""
	TextLabel.Visible = false
	TextLabel.Parent = Cell

	local CountLabel = Instance.new("TextLabel")
	CountLabel.Name = "CountLabel"
	CountLabel.Size = UDim2.new(0.45, 0, 0.25, 0)
	CountLabel.Position = UDim2.new(0.55, 0, 0.75, 0)
	CountLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	CountLabel.BackgroundTransparency = 0.2
	CountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	CountLabel.TextScaled = true
	CountLabel.Font = Enum.Font.GothamBold
	CountLabel.ZIndex = 10
	CountLabel.Parent = Cell

	local CountCorner = Instance.new("UICorner")
	CountCorner.CornerRadius = UDim.new(0.2, 0)
	CountCorner.Parent = CountLabel

	CountLabel.Text = "x" .. (count or 1)

	return Cell, ViewportFrame, Camera, TextLabel, CountLabel
end

function TradeBillboard.SetModel(viewportFrame, model)
	for _, child in pairs(viewportFrame:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Tool") then
			child:Destroy()
		end
	end

	if model:IsA("BasePart") then
		local clone = model:Clone()
		clone.CFrame = CFrame.new(0, 0, 0)
		clone.Anchored = true
		clone.Parent = viewportFrame
		viewportFrame.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 4, 4), Vector3.new(0, 0, 0))
		return clone
	end

	local clone = model:Clone()
	clone.Parent = viewportFrame

	for _, part in pairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	local handle = clone:FindFirstChild("Handle")
	if handle then
		local center = handle.Position
		for _, part in pairs(clone:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame - center
			end
		end
	end

	viewportFrame.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 4, 4), Vector3.new(0, 0, 0))

	return clone
end

function TradeBillboard.ClearItems(billboard)
	local ItemsHolder = billboard.ItemsHolder
	for _, child in pairs(ItemsHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function FindToolByName(player, itemName)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	
	if backpack then
		local tool = backpack:FindFirstChild(itemName)
		if tool and tool:IsA("Tool") then
			return tool
		end
	end
	
	if character then
		local tool = character:FindFirstChild(itemName)
		if tool and tool:IsA("Tool") then
			return tool
		end
	end
	
	return nil
end

local function UpdatePlayerTrade(player, itomsFolder, billboard, operationFolder)
	if not ActiveTrades[operationFolder] then return end
	
	TradeBillboard.ClearItems(billboard)
	
	local index = 0
	for _, itemValue in pairs(itomsFolder:GetChildren()) do
		if itemValue:IsA("IntValue") then
			index = index + 1
			local itemName = itemValue.Name
			local count = itemValue.Value
			local cell, viewport, camera, textLabel, countLabel = TradeBillboard.AddItemCell(billboard, index, count)
			
			local tool = FindToolByName(player, itemName)
			if tool and tool:FindFirstChild("Handle") then
				textLabel.Visible = false
				viewport.Visible = true
				TradeBillboard.SetModel(viewport, tool)
			else
				viewport.Visible = false
				textLabel.Text = itemName
				textLabel.Visible = true
			end
		end
	end
end

local function RemoveTradeOperation(operationFolder)
	local tradeData = ActiveTrades[operationFolder]
	if not tradeData then return end
	
	for _, conn in pairs(tradeData.connections) do
		conn:Disconnect()
	end
	
	if tradeData.billboard1 then
		tradeData.billboard1:Destroy()
	end
	
	if tradeData.billboard2 then
		tradeData.billboard2:Destroy()
	end
	
	ActiveTrades[operationFolder] = nil
end

local function SetupTradeOperation(operationFolder)
	local folder1 = operationFolder:FindFirstChild("1")
	local folder2 = operationFolder:FindFirstChild("2")
	
	if not folder1 or not folder2 then return end
	
	local plr1Value = folder1:FindFirstChild("Plr")
	local plr2Value = folder2:FindFirstChild("Plr")
	
	if not plr1Value or not plr2Value then return end
	
	local player1 = plr1Value.Value
	local player2 = plr2Value.Value
	
	if not player1 or not player2 then return end
	
	local itoms1 = folder1:FindFirstChild("itoms")
	local itoms2 = folder2:FindFirstChild("itoms")
	
	if not itoms1 or not itoms2 then return end
	
	local billboard1 = TradeBillboard.Create(player1)
	local billboard2 = TradeBillboard.Create(player2)
	
	if not billboard1 or not billboard2 then return end
	
	local tradeConnections = {}
	
	ActiveTrades[operationFolder] = {
		billboard1 = billboard1,
		billboard2 = billboard2,
		connections = tradeConnections
	}
	
	UpdatePlayerTrade(player1, itoms1, billboard1, operationFolder)
	UpdatePlayerTrade(player2, itoms2, billboard2, operationFolder)
	
	table.insert(tradeConnections, itoms1.ChildAdded:Connect(function(child)
		UpdatePlayerTrade(player1, itoms1, billboard1, operationFolder)
		if child:IsA("IntValue") then
			table.insert(tradeConnections, child.Changed:Connect(function()
				UpdatePlayerTrade(player1, itoms1, billboard1, operationFolder)
			end))
		end
	end))
	
	table.insert(tradeConnections, itoms1.ChildRemoved:Connect(function()
		UpdatePlayerTrade(player1, itoms1, billboard1, operationFolder)
	end))
	
	table.insert(tradeConnections, itoms2.ChildAdded:Connect(function(child)
		UpdatePlayerTrade(player2, itoms2, billboard2, operationFolder)
		if child:IsA("IntValue") then
			table.insert(tradeConnections, child.Changed:Connect(function()
				UpdatePlayerTrade(player2, itoms2, billboard2, operationFolder)
			end))
		end
	end))
	
	table.insert(tradeConnections, itoms2.ChildRemoved:Connect(function()
		UpdatePlayerTrade(player2, itoms2, billboard2, operationFolder)
	end))
	
	for _, itemValue in pairs(itoms1:GetChildren()) do
		if itemValue:IsA("IntValue") then
			table.insert(tradeConnections, itemValue.Changed:Connect(function()
				UpdatePlayerTrade(player1, itoms1, billboard1, operationFolder)
			end))
		end
	end
	
	for _, itemValue in pairs(itoms2:GetChildren()) do
		if itemValue:IsA("IntValue") then
			table.insert(tradeConnections, itemValue.Changed:Connect(function()
				UpdatePlayerTrade(player2, itoms2, billboard2, operationFolder)
			end))
		end
	end
	
	table.insert(tradeConnections, operationFolder.AncestryChanged:Connect(function(_, parent)
		if not parent then
			RemoveTradeOperation(operationFolder)
		end
	end))
end

local function StartTradeSpy()
	local OperationsFolder = ReplicatedStorage:WaitForChild("ItemTrade"):WaitForChild("Operations")
	
	for _, operation in pairs(OperationsFolder:GetChildren()) do
		if operation:IsA("Folder") then
			SetupTradeOperation(operation)
		end
	end
	
	table.insert(TradeSpyConnections, OperationsFolder.ChildAdded:Connect(function(operation)
		if operation:IsA("Folder") then
			task.wait(0.1)
			SetupTradeOperation(operation)
		end
	end))
	
	table.insert(TradeSpyConnections, OperationsFolder.ChildRemoved:Connect(function(operation)
		if operation:IsA("Folder") then
			RemoveTradeOperation(operation)
		end
	end))
end

local function StopTradeSpy()
	for _, conn in pairs(TradeSpyConnections) do
		conn:Disconnect()
	end
	TradeSpyConnections = {}
	
	for operationFolder, _ in pairs(ActiveTrades) do
		RemoveTradeOperation(operationFolder)
	end
	ActiveTrades = {}
end


Tabs.VisualTab:AddParagraph({
Title = "Чёто крутое",
Content = ""
})

-----------------------------------------------------------

local TradeSpy = Tabs.VisualTab:AddToggle("TradeSpy", {Title = "Следить за трейдами", Default = false})

TradeSpy:OnChanged(function()
	if Options.TradeSpy.Value then
	        StartTradeSpy()
	else
	        StopTradeSpy()
	end
end)
---------------------------------------------------------- END OF TRADE SPY NAHUY ----------------

Tabs.RopeTab:AddParagraph({
        Title = "С нетворкой",
        Content = ""
})

Tabs.RopeTab:AddButton({
        Title = "Поджечь верёвкой (С нетворкой)",
        Description = "Поджигает того, кто у тебя на вере, если у тебя есть нетворк",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent
                                workspace.FireParts.FireTouch.CanTouch = true
                                firetouchinterest(Target.Torso, workspace.FireParts.FireTouch, 1)
                                firetouchinterest(Target.Torso, workspace.FireParts.FireTouch, 0)

                                if AntiDangerParts then
                                        workspace.FireParts.FireTouch.CanTouch = false
                                end

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Взорвать верёвкой (С нетворкой)",
        Description = "Взрывает того, кто у тебя на вере, если у тебя есть нетворк",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent
                                workspace.Kil.CanTouch = true
                                firetouchinterest(Target.Torso, workspace.Kil, 1)
                                firetouchinterest(Target.Torso, workspace.Kil, 0)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Посадить в секрет туалет верёвкой (С нетворкой)",
        Description = "",
        Callback = function()
        if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if game.Players.LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and game.Players.LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') or game.Players.LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = game.Players.LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') and game.Players.LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or game.Players.LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent
                        
                        game.Players.LocalPlayer.Character.RopeConstraint.Length = math.huge
                        
                        Target.HumanoidRootPart:PivotTo(CFrame.new(-223.80, 2063, 224.28))

                        local ping = game.Players.LocalPlayer:GetNetworkPing()

                        task.wait(ping * 5)

                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("MouseClick"):FireServer()

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Флингануть верёвкой (С нетворкой)",
        Description = "Флингует того, кто у тебя на вере, если у тебя есть нетворк",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent

                                LocalPlayer.Character.RopeConstraint.Length = math.huge
                                local BAV = Instance.new('BodyAngularVelocity', Target.Torso)
                                BAV.AngularVelocity = Vector3.new(99999999, 99999999, 99999999)
                                BAV.MaxTorque = Vector3.new(999999999999999, 999999999999999, 9999999999999)
                                BAV.P = 9999

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Убить верёвкой типа в щите (С нетворкой)",
        Description = "Убивает типа у тебя на вере, если у тебя есть нетворк",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent
                                local bp = Target:GetPivot()
                                LocalPlayer.Character.RopeConstraint.Length = math.huge
                                Target:PivotTo(CFrame.new(114.78804016113281, 2127.28955078125, 216.4189453125))
                                wait(0.8)
                                Target:PivotTo(bp)
                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Зафризить верой (С нетворкой)",
        Description = "Фризит того, кто у тебя на вере, если у тебя есть нетворк",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent

                                Target.Torso.Anchored = true

                                local FreezeCon
                                FreezeCon = LocalPlayer.Character.ChildRemoved:Connect(function(child)
                                        Target.Torso.Anchored = false
                                        FreezeCon:Disconnect()
                                        FreezeCon = nil
                                end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Рагдоллнуть верёвкой (С нетворкой)",
        Description = "Рагдоллит того, кто у тебя на вере, если у тебя есть нетворк",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent
                                workspace.RagdollParts.Part.CanTouch = true
                                firetouchinterest(Target.Torso, workspace.RagdollParts.Part, 1)
                                firetouchinterest(Target.Torso, workspace.RagdollParts.Part, 0)
                                if AntiDangerParts then
                                        workspace.RagdollParts.Part.CanTouch = false
                                end

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Заразить верёвкой (С нетворкой)",
        Description = "Заразит партом зеленым который в канашке типа на верёвке",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent
                                workspace.PoisonParts.Union.CanTouch = true
                                firetouchinterest(Target.Torso, workspace.PoisonParts.Union, 1)
                                firetouchinterest(Target.Torso, workspace.PoisonParts.Union, 0)
                                if AntiDangerParts then
                                        workspace.PoisonParts.Union.CanTouch = false
                                end
                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Тепнуть под карту (С нетворкой)",
        Description = "Тепает чуть ниже того, кто у тебя на вере",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent

                                local OurRope = LocalPlayer.Character.RopeConstraint
                                FUNCTIONS.TeleportWithRopeUnderMap(OurRope, Target)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Тепнуть к себе (С нетворкой)",
        Description = "Тепает к тебе того, кто у тебя на вере",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent:FindFirstChildOfClass('Humanoid') then

                        local Target = LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent or LocalPlayer.Character.RopeConstraint.Attachment1.Parent.Parent.Parent

                                local OurRope = LocalPlayer.Character.RopeConstraint
                                FUNCTIONS.Bring(OurRope, Target)

                        end

                end
        end
})

Tabs.RopeTab:AddParagraph({
        Title = "Без нетворки, держащего тебя",
        Content = ""
})

Tabs.RopeTab:AddButton({
        Title = "Поджечь держащего верой",
        Description = "Поджигает того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        workspace.FireParts.FireTouch.CanTouch = true
                                                        firetouchinterest(Target.Torso, workspace.FireParts.FireTouch, 1)
                                                        firetouchinterest(Target.Torso, workspace.FireParts.FireTouch, 0)

                                                        if AntiDangerParts then
                                                                workspace.FireParts.FireTouch.CanTouch = false
                                                        end
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Взорвать держащего верой",
        Description = "Взрывает килпартом того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        workspace.Kil.CanTouch = true
                                                        firetouchinterest(Target.Torso, workspace.Kil, 1)
                                                        firetouchinterest(Target.Torso, workspace.Kil, 0)
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Посадить в секрет туалет держащего верой",
        Description = "Воркает на того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                       game.Players.LocalPlayer.Character.RopeConstraint.Length = math.huge
                                                       Target.RopeConstraint.Length = math.huge
                        
                                                        Target.HumanoidRootPart:PivotTo(CFrame.new(-223.80, 2063, 224.28))

                                                        local ping = game.Players.LocalPlayer:GetNetworkPing()

                                                        task.wait(ping * 5)

                                                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("MouseClick"):FireServer()
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Флингануть держащего верой",
        Description = "Флингует того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        LocalPlayer.Character.RopeConstraint.Length = math.huge
                                                        Target.RopeConstraint.Length = math.huge
                                                        local BAV = Instance.new('BodyAngularVelocity', Target.Torso)
                                                        BAV.AngularVelocity = Vector3.new(99999999, 99999999, 99999999)
                                                        BAV.MaxTorque = Vector3.new(999999999999999, 999999999999999, 9999999999999)
                                                        BAV.P = 9999
                                                        wait(0.1)
                                                        workspace.RagdollParts.Part.CanTouch = true
                                                        firetouchinterest(Target.Torso, workspace.RagdollParts.Part, 1)
                                                        firetouchinterest(Target.Torso, workspace.RagdollParts.Part, 0)
                                                        if AntiDangerParts then
                                                                workspace.RagdollParts.Part.CanTouch = false
                                                        end
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Убить держащего верой типа в щите",
        Description = "Убивает того, кто тебя держит в щите, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        local bp = Target:GetPivot()
                                                        Target.RopeConstraint.Length = math.huge
                                                        LocalPlayer.Character.RopeConstraint.Length = math.huge
                                                        Target:PivotTo(CFrame.new(114.78804016113281, 2127.28955078125, 216.4189453125))
                                                        wait(0.8)
                                                        Target:PivotTo(bp)
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Зафризить держащего верой",
        Description = "Фризит того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then

                                                        Target.Torso.Anchored = true

                                                        local FreezeCon
                                                        FreezeCon = LocalPlayer.Character.ChildRemoved:Connect(function(child)
                                                                Target.Torso.Anchored = false
                                                                FreezeCon:Disconnect()
                                                                FreezeCon = nil
                                                        end)

                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Рагдоллнуть держащего верой",
        Description = "Рагдоллит того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        workspace.RagdollParts.Part.CanTouch = true
                                                        firetouchinterest(Target.Torso, workspace.RagdollParts.Part, 1)
                                                        firetouchinterest(Target.Torso, workspace.RagdollParts.Part, 0)
                                                        if AntiDangerParts then
                                                                workspace.RagdollParts.Part.CanTouch = false
                                                        end
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Заразить держащего верой",
        Description = "Заразит того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        workspace.PoisonParts.Union.CanTouch = true
                                                        firetouchinterest(Target.Torso, workspace.PoisonParts.Union, 1)
                                                        firetouchinterest(Target.Torso, workspace.PoisonParts.Union, 0)
                                                        if AntiDangerParts then
                                                                workspace.PoisonParts.Union.CanTouch = false
                                                        end
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Тепнуть под карту держащего верой",
        Description = "Тепает чуть ниже того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        local OurRope = LocalPlayer.Character.RopeConstraint
                                                        Target.RopeConstraint.Length += 20
                                                        FUNCTIONS.TeleportWithRopeUnderMap(OurRope, Target)
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Тепнуть к себе держащего верой",
        Description = "Тепает к тебе того, кто тебя держит, если ты держишься за землю верой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character ~= nil then

                                spawn(function()

                                for i, Target in pairs(workspace:GetDescendants()) do
                                        if Target:FindFirstChild('Humanoid') and Target:FindFirstChild('RopeConstraint') then
                                                local WhoIsOnRope = Target.RopeConstraint.Attachment1.Parent.Parent:IsA('Model') and Target.RopeConstraint.Attachment1.Parent.Parent or Target.RopeConstraint.Attachment1.Parent.Parent.Parent
                                                if WhoIsOnRope == LocalPlayer.Character then
                                                        local OurRope = LocalPlayer.Character.RopeConstraint
                                                        FUNCTIONS.Bring(OurRope, Target)
                                                end
                                        end
                                end

                        end)

                        end

                end
        end
})

Tabs.RopeTab:AddParagraph({
        Title = "Остальное",
        Content = ""
})

Tabs.RopeTab:AddButton({
        Title = "Удлинить свою верёвку",
        Description = "Визуально удлиняет до бесконечности когда ты что-то держишь верёвкой",
        Callback = function()
                if LocalPlayer.Character ~= nil and LocalPlayer.Character.Humanoid.Health > 0 then

                        if LocalPlayer.Character:FindFirstChild('RopeConstraint') then
                                LocalPlayer.Character:FindFirstChild('RopeConstraint').Length = math.huge
                        end

                end
        end
})

Tabs.RopeTab:AddParagraph({
        Title = "Игроковое",
        Content = ""
})

_G.AutoCatchTargetName = ""
_G.AutoCatchEnabled = false

local CatatchRopePlayerInput = Tabs.RopeTab:AddInput("CatatchRopePlayerInput", {
        Title = "Попытаться схватить верой",
        Default = '',
        Placeholder = "Ну пытается схватить верой игрока",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
                _G.AutoCatchTargetName = Value

                if Value == "" then
                        _G.AutoCatchEnabled = false
                end
        end
})

Tabs.RopeTab:AddButton({
        Title = "Попытаться поймать",
        Description = "Автоматически пытается поймать игрока верой за тебя указаного",
        Callback = function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MouseClick")

                _G.AutoCatchEnabled = true

                task.spawn(function()
                        while _G.AutoCatchEnabled do
                                task.wait(0.1)

                                if not _G.AutoCatchEnabled then break end

                                local character = LocalPlayer.Character
                                local targetPlayer = Players:FindFirstChild(_G.AutoCatchTargetName)

                                if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
                                if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end

                                if not character:FindFirstChild("Верёвка") then
                                        _G.AutoCatchEnabled = false
                                        break
                                end

                                local rope = character:FindFirstChild("RopeConstraint")
                                if rope then

                                        if rope.Attachment1 and rope.Attachment1.Parent then
                                                local caughtParent = rope.Attachment1.Parent.Parent

                                                if caughtParent and caughtParent:IsA("Accessory") then
                                                        caughtParent = caughtParent.Parent
                                                end

                                                if caughtParent and caughtParent.Name == _G.AutoCatchTargetName then
                                                        _G.AutoCatchEnabled = false
                                                        break
                                                else
                                                        Remote:FireServer()
                                                        task.wait(0.5)
                                                end
                                        end
                                else

                                        local targetHRP = targetPlayer.Character.HumanoidRootPart

                                        local origin = targetHRP.Position + Vector3.new(0, 2, 0)
                                        local direction = Vector3.new(0, -4, 0)
                                        local args = {
                                                Ray.new(origin, direction)
                                        }

                                        Remote:FireServer(unpack(args))
                                end
                        end
                end)
        end
})

setupAutoSave()

game.Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        setupAutoSave()

        if VelocityToggle then
                if VelocityConn ~= nil then
                        VelocityConn:Disconnect()
                        VelocityConn = nil
                end

                VelocityConn = LocalPlayer.Character.DescendantAdded:Connect(function(Child)
                        if Child:IsA('BodyVelocity') then
                                print(Child.Name)
                                Child.Velocity = vector.zero

                                spawn(function()

                                        for i, v in pairs(LocalPlayer.Character:GetChildren()) do
                                                v.AssemblyLinearVelocity = vector.zero
                                        end

                                end)

                        end
                end)
        end

        task.spawn(function()
                if FastUnRagdollConnection ~= nil then
                        FastUnRagdollConnection:Disconnect()
                        FastUnRagdollConnection = nil
                        local Character = game.Players.LocalPlayer.Character
                        FastUnRagdollConnection = Character:GetAttributeChangedSignal("rag"):Connect(function()
                                if Character:GetAttribute('rag') == true then
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                                        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        wait(0.3)
                                        Character.Humanoid.Sit = true
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                                        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        wait(0.05)
                                        Character.Humanoid.Sit = true
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                        Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                                        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                                        Character.Humanoid.AutoRotate = true
                                        Character.Humanoid.Sit = false
                                        Character.Humanoid.AutoRotate = true
                                end
                        end)

                end
        end)
end)

_G.TrollTarget = 'Someone'

local CatatchRopePlayerInput = Tabs.TrollTab:AddInput("CatatchRopePlayerInput", {
        Title = "Таргет типочек",
        Default = '',
        Placeholder = "ну тип тот кто будет под таргетом троллинга",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            _G.TrollTarget = Value
        end
})

Tabs.TrollTab:AddButton({
        Title = "Положить в трейд 100 перпл итов",
        Description = "Тролленг ода (НЕ СПАМЬ ФУНКЦИЕЙ) (ник не обязателен)",
        Callback = function()
            for i = 1, 100 do
                local args = {
            "\208\159\208\190\208\191 \208\184\209\130"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TakeItem"):FireServer(unpack(args))
            local args = {
            "\208\147\208\190\208\178\209\143\208\180\208\184\208\189\208\176"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TakeItem"):FireServer(unpack(args))
            local args = {
            {
            "\208\147\208\190\208\178\209\143\208\180\208\184\208\189\208\176",
            "\208\159\208\190\208\191 \208\184\209\130"
            }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Craft"):FireServer(unpack(args))

            end

            for i,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
            local args = {
            "manage",
            {
            "remove",
            v.Name
            }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TradeTh"):FireServer(unpack(args))

            end

            for i = 1,100 do
                local args = {
            "manage",
            {
            "add",
            "\208\159\209\145\209\128\208\191\208\187 \208\184\209\130"
            }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TradeTh"):FireServer(unpack(args))
            end


            local args = {
            "accept"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TradeTh"):FireServer(unpack(args))
        end
})

Tabs.TrollTab:AddButton({
    Title = "Таргет килл с беброй",
    Description = "Тролленг ода кароч пытается беброй убить лашков (не юзать пока не не закончится то что делает эта кнопка)",
    Callback = function()
        
        ----------


        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local TargetName = _G.TrollTarget

        if not Players:FindFirstChild(TargetName) then
            return
        end

        local player = Players.LocalPlayer
        local character = player.Character
        local rootPart = character:WaitForChild("HumanoidRootPart")

        local Remotes = ReplicatedStorage:WaitForChild("Remotes")
        local MouseClick = Remotes:WaitForChild("MouseClick")
        local TakeItem = Remotes:WaitForChild("TakeItem")

        character:PivotTo(CFrame.new(53.4488258, 2051.49976, 49.5550652, 0.00192128937, -8.16024013e-08, -0.999998152, 1.00207551e-07, 1, -8.14100218e-08, 0.999998152, -1.00050954e-07, 0.00192128937))

        wait(0.5)

        fireproximityprompt(workspace.CTInteract.ProximityPrompt)

        wait(0.1)

        local target = Players:FindFirstChild(TargetName)
        local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")

        local tp = 0

        local function getPing()
            return player:GetNetworkPing()
        end

        local function predictPosition()
            if not targetRoot or not targetRoot.Parent then return nil end
            
            local ping = getPing()
            local currentPos = targetRoot.Position
            local velocity = targetRoot.AssemblyLinearVelocity
            
            local predictedPos = currentPos + (velocity * ping * 1.5)
            
            return predictedPos
        end

        con = character:GetAttributeChangedSignal('rag'):Connect(function()
            if character:GetAttribute('rag') == true then
                task.wait(0.025)
                character.Humanoid.Sit = true
                task.wait(0.025)
                character.Humanoid.Sit = false
            end
        end)

        repeat 
            task.wait()
            
            target = Players:FindFirstChild(TargetName)
            targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            
            local predictedPos = predictPosition()
            if predictedPos then
                rootPart.CFrame = CFrame.new(predictedPos) * CFrame.new(0, 0, 0)
            end
            
            if not character:FindFirstChild('Бебра') then
                TakeItem:FireServer("Бебра")
                task.wait(0.01)
                
                local tool = player.Backpack:FindFirstChild('Бебра')
                if tool then
                    tool.Parent = character
                end
            end
            
            task.wait(0.01)
            
            MouseClick:FireServer()
            tp += 1
            
        until tp >= 650

        wait(5)

        con:Disconnect()
        con = nil


        ----------

    end
})

Tabs.TrollTab:AddButton({
    Title = "Таргет килл с пряником",
    Description = "Тролленг ода кароч пытается пряником убить лашков (не юзать пока не не закончится то что делает эта кнопка)",
    Callback = function()
        
        ----------


        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local TargetName = _G.TrollTarget

        if not Players:FindFirstChild(TargetName) then
            return
        end

        local player = Players.LocalPlayer
        local character = player.Character
        local rootPart = character:WaitForChild("HumanoidRootPart")

        local Remotes = ReplicatedStorage:WaitForChild("Remotes")
        local MouseClick = Remotes:WaitForChild("MouseClick")
        local TakeItem = Remotes:WaitForChild("TakeItem")

        character:PivotTo(CFrame.new(53.4488258, 2051.49976, 49.5550652, 0.00192128937, -8.16024013e-08, -0.999998152, 1.00207551e-07, 1, -8.14100218e-08, 0.999998152, -1.00050954e-07, 0.00192128937))

        wait(0.5)
        Remotes.HitRequest:InvokeServer()
        fireproximityprompt(workspace.CTInteract.ProximityPrompt)
        
        local target = Players:FindFirstChild(TargetName)
        local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")

        local tp = 0

        local function getPing()
                return player:GetNetworkPing()
        end

        local function predictPosition()
                if not targetRoot or not targetRoot.Parent then return nil end
                
                local ping = getPing()
                local currentPos = targetRoot.Position
                local velocity = targetRoot.AssemblyLinearVelocity
                
                local predictedPos = currentPos + (velocity * 1.25 * ping * 5)
                
                return predictedPos
        end

        con = character:GetAttributeChangedSignal('rag'):Connect(function()
                if character:GetAttribute('rag') == true then
                        task.wait(0.025)
                        character.Humanoid.Sit = true
                        task.wait(0.025)
                        character.Humanoid.Sit = false
                end
        end)

        local stop = false

        character.AncestryChanged:Once(function()
                stop = true
        end)

        repeat 
                task.wait()
                
                target = Players:FindFirstChild(TargetName)
                targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                
                local predictedPos = predictPosition()
                if predictedPos then
                        character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        wait(0.0025)
                        rootPart.CFrame = CFrame.new(predictedPos) + Vector3.new(0, -1.5, 0)
                end
                
                if not character:FindFirstChild('Тульский пряник') then
                        TakeItem:FireServer("Тульский пряник")
                        task.wait(0.01)
                        
                        local tool = player.Backpack:FindFirstChild('Тульский пряник')
                        if tool then
                                tool.Parent = character
                        end
                end
                
                task.wait(0.01)
                
                MouseClick:FireServer()
        tp += 1
                
        until target.Character == nil or target.Character.Humanoid.Health == 0 or character == nil or stop == true


        wait(5)

        con:Disconnect()
        con = nil


        ----------

    end
})

Tabs.TrollTab:AddButton({
    Title = "Карооч спам едениемо огурца",
    Description = "Тролленг ода (НЕ СПАМЬ ФУНКЦИЕЙ) (ник не обязателен)",
    Callback = function()
        
        local function FoundOgurecBro()
            local bro = nil
            for i,v in pairs(game.Players:GetPlayers()) do
                if v.Character ~= nil and v.Character:FindFirstChild('ogurec') then
                    bro = v.Character
                end
            end
            return bro
        end

        local target = FoundOgurecBro()

        if target == nil then
            return
        end

        local tp = 0

        repeat task.wait()

        tp += 1

        LocalPlayer.Character:PivotTo(target.HumanoidRootPart:GetPivot())

        task.spawn(function()
            for i = 1,500 do
            fireproximityprompt(target.HumanoidRootPart.ProximityPrompt)
            end
        end)

        until tp >= 25

    end
})

local AntiExplosionsConnection = nil

local AntiExplosions = Tabs.TrollTab:AddToggle("AntiExplosions", {Title = "Убрать взрывы визуально", Default = false})

AntiExplosions:OnChanged(function()
        AntiExplosionsEnabled = Options.AntiExplosions.Value
        
        if AntiExplosionsEnabled == true then
           AntiExplosionsConnection = workspace.ChildAdded:Connect(function(Child)
                if Child:IsA('Explosion') then
                    Child.Position = Vector3.new(0, -99999999999, 0)
                    Child.TimeScale = 0
                    Child.BlastRadius = 0
                    Child.BlastPressure = 0
                    Child:Destroy()
                end
            end)
        else
            if AntiExplosionsConnection ~= nil then
                AntiExplosionsConnection:Disconnect()
                AntiExplosionsConnection = nil
            end
        end
end)

local function GetTortEater()
	local Character = game.Players.LocalPlayer.Character
	if not Character or not Character:FindFirstChild('Cake') then return nil end
	
	local cakePos = Character.Cake:GetPivot().Position
	local closestEater = nil
	local closestDistance = 125
	
	for _, v in pairs(game.Players:GetPlayers()) do
		if v ~= game.Players.LocalPlayer and v.Character and v.Character:FindFirstChild('HumanoidRootPart') then
            print('tortoed naiden v 0: ' .. v.Character.Name)
			local hrp = v.Character.HumanoidRootPart
			local torso = v.Character:FindFirstChild('Torso') or hrp
			
			if hrp:FindFirstChild('Eat') then
                print('tortoed naiden v1: ' .. hrp.Parent.Name)
				local distance = (torso:GetPivot().Position - cakePos).Magnitude
				if distance < closestDistance then
                    print('tortoed naidenv 2: ' .. v.Name)
					closestDistance = distance
					closestEater = v.Character
				end
			end
		end
	end
	
	return closestEater
end

Tabs.TrollTab:AddButton({
    Title = "ТОРТ КИЛЛЕР УБИЙЦА",
    Description = "Убивает того кто тебя ест (онли с нетворкой)",
    Callback = function()
        local Character = game.Players.LocalPlayer.Character
        if Character:FindFirstChild('Cake') then
        
         local Target = GetTortEater()
        print('tortoed naiden v 3: ' .. Target.Name)
        if Target == nil then return end
        print('tortoed naiden v 4: ' .. Target.Name)
        workspace.KillParts.K.CanTouch = true
        firetouchinterest(Target.Torso, workspace.KillParts.Part, 1)
        task.wait(0.025)
        firetouchinterest(Target.Torso, workspace.KillParts.Part, 0)

        if AntiDangerParts then
        workspace.KillParts.K.CanTouch = false
        end

        end
    end
})

Tabs.TrollTab:AddButton({
	Title = "Флингануть бсдшкой",
	Description = "Флингует бравлстарсером жертву",
	Callback = function()
		local Character = LocalPlayer.Character
		
		if not Character then return end
		
		local RopeConstraint = Character:FindFirstChild("RopeConstraint")
		if not RopeConstraint or not RopeConstraint.Attachment1 then
			Fluent:Notify({
				Title = "Ошибка епта",
				Content = "Тебе нужно взять бсд на верёвку",
				Duration = 3
			})
			return
		end
		
		local attachment = RopeConstraint.Attachment1
		local NPC = attachment.Parent:FindFirstChild('NPC') and attachment.Parent or attachment.Parent.Parent

		
		if not NPC:FindFirstChild("NPC") and not NPC:FindFirstChildOfClass("Humanoid") then
			Fluent:Notify({
				Title = "Ошибка епта",
				Content = "Тебе нужно взять бсд на верёвку",
				Duration = 3
			})
			return
		end
		
                local startposfling = CFrame.new(0, 10000, 0)
		local TargetName = _G.TrollTarget
		
		if not TargetName or TargetName == "" then
			Fluent:Notify({
				Title = "Ошибка епта",
				Content = "Выбери жертву сначала",
				Duration = 3
			})
			return
		end

                if not game.Players:FindFirstChild(TargetName) then return end

                local targetPlayer = game.Players:FindFirstChild(TargetName)

                if not targetPlayer then return end
		RopeConstraint.Length = math.huge
		task.spawn(function()
			local npcRoot = NPC:FindFirstChild("HumanoidRootPart") or NPC:FindFirstChild("Torso")
			if not npcRoot then return end
			startposfling = npcRoot.CFrame
			local startTime = tick()
			local duration = 5
			local movel = 0.1
			local pingStep = 5.5
			local velocityStep = 1.5
			
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyVelocity.Parent = npcRoot
			
			local bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			bodyGyro.P = 50000
			bodyGyro.Parent = npcRoot
			
			repeat
				RunService.Heartbeat:Wait()
				
				local targetChar = targetPlayer.Character
				if not targetChar then continue end
				
				local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
				if not targetRoot then continue end
				
				local ping = LocalPlayer:GetNetworkPing() * pingStep
				local targetVelocity = targetRoot.Velocity
				local predictedPos = targetRoot.Position + (targetVelocity * ping * velocityStep)
				
				local direction = (predictedPos - npcRoot.Position).Unit
				local vel = npcRoot.Velocity
				
				npcRoot.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
				bodyVelocity.Velocity = direction * 500
				bodyGyro.CFrame = CFrame.lookAt(npcRoot.Position, predictedPos)
				
				RunService.RenderStepped:Wait()
				if npcRoot and npcRoot.Parent then
					npcRoot.Velocity = vel
				end
				
                                for i,v in next, Character:GetDescendants() do
                                        if v:IsA('BasePart') then
                                        v.AssemblyLinearVelocity = vector.zero
                                        end
                                end

				RunService.Stepped:Wait()
				if npcRoot and npcRoot.Parent then
					npcRoot.Velocity = vel + Vector3.new(0, movel, 0)
					movel = movel * -1
					npcRoot.CFrame = CFrame.new(predictedPos + Vector3.new(0, 2, 0))
				end
				
			until tick() - startTime >= duration
			
			bodyVelocity:Destroy()
			bodyGyro:Destroy()
                        for i,v in next, NPC:GetDescendants() do
                                if v:IsA('BasePart') then
                                v.AssemblyLinearVelocity = vector.zero
                                end
                        end
                        npcRoot:PivotTo(startposfling)
                        for i,v in next, NPC:GetDescendants() do
                                if v:IsA('BasePart') then
                                v.AssemblyLinearVelocity = vector.zero
                                end
                        end
                        
			
		end)
	end
})


Tabs.TrollTab:AddButton({
    Title = "Врубить/Вырубить пвп",
    Description = "Врубает или вырубает пвп",
    Callback = function()
        if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChild('pvpBillboard') then

                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PVPToggle"):InvokeServer(false)

        else

                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PVPToggle"):InvokeServer(true)

        end
    end
})


local PVPEnablerBind = Tabs.BindsTab:AddKeybind("PVPEnablerBind", {
    Title = "Бинд для врубания/вырубания пвп",
    Mode = "Toggle",
    Default = "NONE",

    Callback = function(Value)
        if LocalPlayer.Character ~= nil and LocalPlayer.Character:FindFirstChild('pvpBillboard') then

                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PVPToggle"):InvokeServer(false)

        else

                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PVPToggle"):InvokeServer(true)

        end
    end,
})
