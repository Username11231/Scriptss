local SCRIPT_VERSION_BUILD = 'v6'

------------ > INITING LOADSTRINGS <--------------------------------------------------------------

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScripterNumber/SPVKHUB/refs/heads/main/Fluent"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

------------ > SERVICES & LOCALS <--------------------------------------------------------------

local Workspace = game:GetService('Workspace')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local Lighting = game:GetService('Lighting')
local CoreGui = game:GetService('CoreGui')
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild('Humanoid')
local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')

if getgenv().CharacterAddedConnection ~= nil then
    getgenv().CharacterAddedConnection:Disconnect()
    getgenv().CharacterAddedConnection = nil
end

local function EnableReach(Tool, Reach)
    for i, v in next, Tool:FindFirstChild('Hitboxes'):FindFirstChild('Hitbox'):GetChildren() do
        if v:IsA('Attachment') and v.Name == 'DmgPoint' and not v:GetAttribute('OrigCFrame') then
            v:SetAttribute('OrigCFrame', v.CFrame)
            v.CFrame = v.CFrame + Vector3.new(0, Reach ~= nil and Reach or 7.5, 0)
            v.Visible = true
        end
    end
end

local function DisableReach(Tool)
    for i, v in next, Tool:FindFirstChild('Hitboxes'):FindFirstChild('Hitbox'):GetChildren() do
        if v:IsA('Attachment') and v.Name == 'DmgPoint' and v:GetAttribute('OrigCFrame') then
            v.CFrame = v:GetAttribute('OrigCFrame')
            v:SetAttribute('OrigCFrame', nil)
            v.Visible = false
        end
    end
end

getgenv().CharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(CharacterAddedConnectionChar)
    Character = CharacterAddedConnectionChar
    Humanoid = CharacterAddedConnectionChar:WaitForChild('Humanoid')
    HumanoidRootPart = CharacterAddedConnectionChar:WaitForChild('HumanoidRootPart')

    if getgenv().ReachConnection ~= nil then
        getgenv().ReachConnection:Disconnect()
        getgenv().ReachConnection = nil

        for i,Child in next, Character:GetChildren() do
            if Child:IsA('Tool') and Child:GetAttribute('ItemType') and Child:GetAttribute('ItemType') == 'weapon' then
                EnableReach(Child, ReachDistance)
            end
        end

        getgenv().ReachConnection = Character.ChildAdded:Connect(function(Child)
            if Child:IsA('Tool') and Child:GetAttribute('ItemType') and Child:GetAttribute('ItemType') == 'weapon' then
                EnableReach(Child, ReachDistance)
            end
        end)
    end
end)

local Network = require(game.ReplicatedStorage.Shared.Vendor.Network)

------------ > PARRY SETTINGS <--------------------------------------------------------------

local AutoParryDistance = 12
local AntiParryDistance = 16
local DynamicDistanceEnabled = true
local DynamicMaxPercent = 15
local DynamicBonusDistance = 0
local WeaponDistDetectEnabled = true
local WeaponDetectedRange = 0
local DebugEnabled = false

local ParryMethod = "keypress"
local ParryEventName = "Parry"
local DetectMethod = "Sounds (Default)"

local AliveCheckEnabled = true
local WeaponRequiredEnabled = true
local FacingCheckEnabled = false
local FacingAngle = 120
local CooldownEnabled = true
local CooldownTime = 0.65
local ClosestFirstEnabled = false
local QueueWindow = 0.12
local StunCheckEnabled = false
local GroundCheckEnabled = false

------------ > COOLDOWN SYSTEM <--------------------------------------------------------------

local LastParryTick = 0

local function IsCooldownReady()
    if not CooldownEnabled then return true end
    return (tick() - LastParryTick) >= CooldownTime
end

local function MarkParryUsed()
    LastParryTick = tick()
end

------------ > VALIDATION CHECKS <--------------------------------------------------------------

local function IsAlive()
    if not AliveCheckEnabled then return true end
    if not Character or not Humanoid or not HumanoidRootPart then return false end
    if Humanoid.Health <= 0 then return false end
    if not HumanoidRootPart.Parent then return false end
    return true
end

local function HasWeaponEquipped()
    if not WeaponRequiredEnabled then return true end
    if not Character then return false end
    for _, v in next, Character:GetChildren() do
        if v:IsA('Tool') and v:GetAttribute('ItemType') and v:GetAttribute('ItemType') == 'weapon' then
            return true
        end
    end
    return false
end

local function IsAttackerInFront(attackerPos)
    if not FacingCheckEnabled then return true end
    if not HumanoidRootPart then return false end
    local lookVector = HumanoidRootPart.CFrame.LookVector
    local toAttacker = (attackerPos - HumanoidRootPart.Position).Unit
    local dot = lookVector:Dot(toAttacker)
    local threshold = math.cos(math.rad(FacingAngle / 2))
    return dot >= threshold
end

local function IsStunned()
    if not StunCheckEnabled then return false end
    if not Character then return false end

    local stunAttr = Character:GetAttribute("Stunned")
    if stunAttr == true then return true end

    local blockStun = Character:GetAttribute("BlockStunned")
    if blockStun == true then return true end

    local stun2 = Character:GetAttribute("Stun")
    if stun2 == true then return true end

    if Humanoid then
        local state = Humanoid:GetState()
        if state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Ragdoll then
            return true
        end
    end

    for _, anim in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        local name = anim.Name:lower()
        if name:find("stun") or name:find("ragdoll") or name:find("knockback") or name:find("knockout") then
            return true
        end
    end

    return false
end

local function IsOnGround()
    if not GroundCheckEnabled then return true end
    if not HumanoidRootPart then return false end
    if Humanoid and Humanoid.FloorMaterial == Enum.Material.Air then
        return false
    end
    return true
end

local function CanParryNow(attackerPos)
    if not IsAlive() then return false end
    if not HasWeaponEquipped() then return false end
    if not IsCooldownReady() then return false end
    if IsStunned() then return false end
    if not IsOnGround() then return false end
    if not IsAttackerInFront(attackerPos) then return false end
    if not isrbxactive() then return false end
    return true
end

------------ > QUEUE SYSTEM <--------------------------------------------------------------

local ParryQueue = {}
local QueueProcessing = false

local function DoParryAction()
    MarkParryUsed()

    local Item = nil
    if Character then
        for _, v in next, Character:GetChildren() do
            if v:IsA('Tool') and v:GetAttribute('ItemType') and v:GetAttribute('ItemType') == 'weapon' then
                Item = v
                break
            end
        end
    end

    task.spawn(function()
        if Item ~= nil then
            Item.Parent = LocalPlayer.Backpack
            task.wait()
            Item.Parent = LocalPlayer.Character
        end
    end)

    task.wait(0.00001 + math.random() * 0.000005 + (math.random(3, 9) / 17500))

    if ParryMethod == "Network" then
        pcall(function()
            Network:FireServer(ParryEventName)
        end)
    else
        keypress(0x46)
        task.wait(0.1 + math.random() * 0.13 + (math.random(199, 250) / 1000))
        keyrelease(0x46)
    end
end

local function ProcessQueue()
    if QueueProcessing then return end
    QueueProcessing = true

    task.delay(QueueWindow, function()
        if #ParryQueue == 0 then
            QueueProcessing = false
            return
        end

        table.sort(ParryQueue, function(a, b)
            return a.distance < b.distance
        end)

        local best = ParryQueue[1]
        ParryQueue = {}
        QueueProcessing = false

        if CanParryNow(best.position) then
            local effectiveDist = GetEffectiveParryDistance(best.hitboxPart)
            if best.distance <= effectiveDist then
                DoParryAction()
            end
        end
    end)
end

------------ > WEAPON DISTANCE DETECT <--------------------------------------------------------------

local function GetHitboxRange(hitboxPart)
    if not hitboxPart or not hitboxPart:IsA("BasePart") then return 0 end
    local size = hitboxPart.Size
    return size.X + size.Y + size.Z
end

local function GetNearestEnemyHitboxRange()
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    local maxRange = 0
    local scanRadius = 40

    local playerChars = Workspace:FindFirstChild("PlayerCharacters")
    if not playerChars then return 0 end

    for _, playerChar in ipairs(playerChars:GetChildren()) do
        if playerChar ~= Character then
            local eHrp = playerChar:FindFirstChild("HumanoidRootPart")
            local eHum = playerChar:FindFirstChild("Humanoid")
            if eHrp and eHum and eHum.Health > 0 then
                local dist = (hrp.Position - eHrp.Position).Magnitude
                if dist < scanRadius then
                    for _, child in ipairs(playerChar:GetChildren()) do
                        if child:IsA("Tool") then
                            local hitbox = child:FindFirstChild("Hitbox")
                            if hitbox and hitbox:IsA("BasePart") then
                                local range = GetHitboxRange(hitbox)
                                if range > maxRange then
                                    maxRange = range
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return maxRange
end

function GetEffectiveParryDistance(hitboxPart)
    local base = AutoParryDistance

    if WeaponDistDetectEnabled then
        local hitboxRange = 0
        if hitboxPart then
            hitboxRange = GetHitboxRange(hitboxPart)
        else
            hitboxRange = WeaponDetectedRange
        end
        if hitboxRange > base then
            base = hitboxRange
        end
    end

    return base + DynamicBonusDistance
end

------------ > SOUNDS 2 (ANIMATION MARKERS) <--------------------------------------------------------------

local S2_AnimCache = {}
local S2_ActiveTrackers = {}
local S2_AnimConns = {}
local S2_CurrentTarget = nil
local S2_CurrentTrackerId = nil

local function S2_GetMarkerTimes(animId)
    if S2_AnimCache[animId] then
        return S2_AnimCache[animId]
    end

    local result = {startTime = nil, stopTime = nil}
    local ok, kfSeq = pcall(function()
        return KeyframeSequenceProvider:GetKeyframeSequenceAsync(animId)
    end)

    if not ok or not kfSeq then
        S2_AnimCache[animId] = result
        return result
    end

    for _, keyframe in ipairs(kfSeq:GetKeyframes()) do
        for _, marker in ipairs(keyframe:GetMarkers()) do
            if marker.Name == "startHitDetection" then
                result.startTime = keyframe.Time
            elseif marker.Name == "stopHitDetection" then
                result.stopTime = keyframe.Time
            end
        end
    end

    kfSeq:Destroy()
    S2_AnimCache[animId] = result
    return result
end

local function S2_KillTracker(trackerId)
    local tracker = S2_ActiveTrackers[trackerId]
    if tracker then
        if tracker.conn then tracker.conn:Disconnect() end
        tracker.dead = true
        S2_ActiveTrackers[trackerId] = nil
    end
    if S2_CurrentTrackerId == trackerId then
        S2_CurrentTarget = nil
        S2_CurrentTrackerId = nil
    end
end

local function S2_KillAllTrackers()
    for id, _ in pairs(S2_ActiveTrackers) do
        S2_KillTracker(id)
    end
    S2_ActiveTrackers = {}
    S2_CurrentTarget = nil
    S2_CurrentTrackerId = nil
end

local function S2_GetEnemyHitbox(enemyChar)
    for _, child in ipairs(enemyChar:GetChildren()) do
        if child:IsA("Tool") then
            local hitboxes = child:FindFirstChild("Hitboxes")
            if hitboxes then
                local hb = hitboxes:FindFirstChild("Hitbox")
                if hb and hb:IsA("BasePart") then return hb end
            end
            local hb = child:FindFirstChild("Hitbox")
            if hb and hb:IsA("BasePart") then return hb end
        end
    end
    return nil
end

local function S2_StartTracker(enemyChar, animTrack, markers)
    local trackerId = tostring(enemyChar) .. "_" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999))
    local parried = false

    local tracker = {
        enemyChar = enemyChar,
        parried = false,
        dead = false,
        conn = nil
    }
    S2_ActiveTrackers[trackerId] = tracker

    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then
        S2_ActiveTrackers[trackerId] = nil
        return
    end

    local enemyHrp = enemyChar:FindFirstChild("HumanoidRootPart")
    if not enemyHrp then
        S2_ActiveTrackers[trackerId] = nil
        return
    end

    local currentDist = (myHrp.Position - enemyHrp.Position).Magnitude

    if S2_CurrentTarget and S2_CurrentTrackerId then
        local oldTracker = S2_ActiveTrackers[S2_CurrentTrackerId]
        if oldTracker and not oldTracker.dead then
            local oldEnemy = oldTracker.enemyChar
            local oldHrp = oldEnemy and oldEnemy:FindFirstChild("HumanoidRootPart")
            if oldHrp then
                local oldDist = (myHrp.Position - oldHrp.Position).Magnitude
                if currentDist < oldDist then
                    S2_KillTracker(S2_CurrentTrackerId)
                else
                    S2_ActiveTrackers[trackerId] = nil
                    return
                end
            else
                S2_KillTracker(S2_CurrentTrackerId)
            end
        end
    end

    S2_CurrentTarget = enemyChar
    S2_CurrentTrackerId = trackerId

    tracker.conn = RunService.Heartbeat:Connect(function()
        if tracker.dead or parried then
            S2_KillTracker(trackerId)
            return
        end

        if not AutoParryToggleValue or DetectMethod ~= "Sounds 2 (Animation Markers)" then
            S2_KillTracker(trackerId)
            return
        end

        if not animTrack.IsPlaying then
            S2_KillTracker(trackerId)
            return
        end

        local elapsed = animTrack.TimePosition
        if markers.stopTime and elapsed >= markers.stopTime then
            S2_KillTracker(trackerId)
            return
        end

        local lhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not lhrp then return end

        local eHrp = enemyChar:FindFirstChild("HumanoidRootPart")
        if not eHrp then
            S2_KillTracker(trackerId)
            return
        end

        local hitboxPart = S2_GetEnemyHitbox(enemyChar)
        local checkPos = hitboxPart and hitboxPart.Position or eHrp.Position
        local dist = (checkPos - lhrp.Position).Magnitude

        if not CanParryNow(checkPos) then return end

        local effectiveDist = GetEffectiveParryDistance(hitboxPart)

        if dist <= effectiveDist then
            parried = true
            DoParryAction()
            S2_KillTracker(trackerId)
        end
    end)
end

local function S2_HookEnemy(enemyChar)
    local humanoid = enemyChar:FindFirstChild("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local connKey = tostring(enemyChar)
    if S2_AnimConns[connKey] then return end

    S2_AnimConns[connKey] = animator.AnimationPlayed:Connect(function(animTrack)
        if not AutoParryToggleValue or DetectMethod ~= "Sounds 2 (Animation Markers)" then return end

        local anim = animTrack.Animation
        if not anim or not anim.AnimationId or anim.AnimationId == "" then return end

        task.spawn(function()
            local markers = S2_GetMarkerTimes(anim.AnimationId)
            if not markers.startTime and not markers.stopTime then return end

            S2_StartTracker(enemyChar, animTrack, markers)
        end)
    end)
end

local function S2_UnhookAll()
    for key, conn in pairs(S2_AnimConns) do
        if conn then conn:Disconnect() end
    end
    S2_AnimConns = {}
    S2_KillAllTrackers()
end

local S2_ChildAddedConn = nil
local S2_ChildRemovedConn = nil

local function S2_Enable()
    S2_Disable_Safe()

    local playerChars = Workspace:FindFirstChild("PlayerCharacters")
    if playerChars then
        for _, ch in ipairs(playerChars:GetChildren()) do
            if ch ~= LocalPlayer.Character then
                S2_HookEnemy(ch)
            end
        end

        S2_ChildAddedConn = playerChars.ChildAdded:Connect(function(ch)
            if ch ~= LocalPlayer.Character then
                task.defer(function()
                    S2_HookEnemy(ch)
                end)
            end
        end)

        S2_ChildRemovedConn = playerChars.ChildRemoved:Connect(function(ch)
            local connKey = tostring(ch)
            if S2_AnimConns[connKey] then
                S2_AnimConns[connKey]:Disconnect()
                S2_AnimConns[connKey] = nil
            end
            for id, tracker in pairs(S2_ActiveTrackers) do
                if tracker.enemyChar == ch then
                    S2_KillTracker(id)
                end
            end
        end)
    end
end

function S2_Disable_Safe()
    S2_UnhookAll()
    if S2_ChildAddedConn then S2_ChildAddedConn:Disconnect(); S2_ChildAddedConn = nil end
    if S2_ChildRemovedConn then S2_ChildRemovedConn:Disconnect(); S2_ChildRemovedConn = nil end
end

------------ > DEBUG VISUALS <--------------------------------------------------------------

local DebugScreenGui = nil
local ParryCircle = nil
local AntiParryCircle = nil
local WeaponCircle = nil
local DebugLabel = nil
local ChecksLabel = nil
local DebugConnection = nil

local function DestroyDebugVisuals()
    if DebugConnection then
        DebugConnection:Disconnect()
        DebugConnection = nil
    end
    if DebugScreenGui then
        pcall(function() DebugScreenGui:Destroy() end)
        DebugScreenGui = nil
        ParryCircle = nil
        AntiParryCircle = nil
        WeaponCircle = nil
        DebugLabel = nil
        ChecksLabel = nil
    end
end

local function CreateCircle(parent, name, color, thickness)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundTransparency = 1
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.new(0, 100, 0, 100)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.Transparency = 0.3
    stroke.Parent = frame

    return frame
end

local function SetupDebugVisuals()
    DestroyDebugVisuals()

    DebugScreenGui = Instance.new("ScreenGui")
    DebugScreenGui.Name = "AetherDbg_" .. tostring(math.random(100000, 999999))
    DebugScreenGui.ResetOnSpawn = false
    DebugScreenGui.IgnoreGuiInset = true
    DebugScreenGui.DisplayOrder = 999

    pcall(function()
        DebugScreenGui.Parent = CoreGui
    end)
    if not DebugScreenGui.Parent then
        DebugScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    ParryCircle = CreateCircle(DebugScreenGui, "ParryRange", Color3.fromRGB(0, 170, 255), 2.5)
    AntiParryCircle = CreateCircle(DebugScreenGui, "AntiParryRange", Color3.fromRGB(255, 85, 0), 2)
    WeaponCircle = CreateCircle(DebugScreenGui, "WeaponRange", Color3.fromRGB(255, 255, 0), 2)
    WeaponCircle.Visible = false

    DebugLabel = Instance.new("TextLabel")
    DebugLabel.Name = "DebugInfo"
    DebugLabel.BackgroundTransparency = 1
    DebugLabel.Size = UDim2.new(0, 420, 0, 40)
    DebugLabel.Position = UDim2.new(0.5, -210, 0, 10)
    DebugLabel.Font = Enum.Font.GothamBold
    DebugLabel.TextSize = 13
    DebugLabel.TextColor3 = Color3.new(1, 1, 1)
    DebugLabel.TextStrokeTransparency = 0.3
    DebugLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugLabel.Text = ""
    DebugLabel.Parent = DebugScreenGui

    ChecksLabel = Instance.new("TextLabel")
    ChecksLabel.Name = "ChecksInfo"
    ChecksLabel.BackgroundTransparency = 1
    ChecksLabel.Size = UDim2.new(0, 500, 0, 20)
    ChecksLabel.Position = UDim2.new(0.5, -250, 0, 48)
    ChecksLabel.Font = Enum.Font.GothamBold
    ChecksLabel.TextSize = 11
    ChecksLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    ChecksLabel.TextStrokeTransparency = 0.3
    ChecksLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    ChecksLabel.Text = ""
    ChecksLabel.Parent = DebugScreenGui
end

local function WorldToScreenRadius(worldPos, worldRadius)
    local camera = workspace.CurrentCamera
    if not camera then return 0 end

    local screenPos, onScreen = camera:WorldToScreenPoint(worldPos)
    if not onScreen then return 0 end

    local edgePos = worldPos + camera.CFrame.RightVector * worldRadius
    local screenEdge, onScreen2 = camera:WorldToScreenPoint(edgePos)
    if not onScreen2 then return 0 end

    return math.abs(screenEdge.X - screenPos.X)
end

local function UpdateDebugVisuals(parryDist, antiDist, bonusDist, nearDist, nearSpeed, weaponRange)
    if not DebugScreenGui or not DebugScreenGui.Parent then return end
    if not ParryCircle or not AntiParryCircle then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local worldPos = hrp.Position
    local screenPos, onScreen = camera:WorldToScreenPoint(worldPos)

    if not onScreen then
        ParryCircle.Visible = false
        AntiParryCircle.Visible = false
        WeaponCircle.Visible = false
        if DebugLabel then DebugLabel.Visible = false end
        if ChecksLabel then ChecksLabel.Visible = false end
        return
    end

    ParryCircle.Visible = true
    AntiParryCircle.Visible = true
    if DebugLabel then DebugLabel.Visible = true end
    if ChecksLabel then ChecksLabel.Visible = true end

    local parryScreenR = WorldToScreenRadius(worldPos, parryDist)
    local antiScreenR = WorldToScreenRadius(worldPos, antiDist)

    local parrySize = math.max(parryScreenR * 2, 10)
    local antiSize = math.max(antiScreenR * 2, 10)

    ParryCircle.Size = UDim2.new(0, parrySize, 0, parrySize)
    ParryCircle.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)

    AntiParryCircle.Size = UDim2.new(0, antiSize, 0, antiSize)
    AntiParryCircle.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)

    if WeaponDistDetectEnabled and weaponRange > 0 then
        WeaponCircle.Visible = true
        local weaponScreenR = WorldToScreenRadius(worldPos, weaponRange)
        local weaponSize = math.max(weaponScreenR * 2, 10)
        WeaponCircle.Size = UDim2.new(0, weaponSize, 0, weaponSize)
        WeaponCircle.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
    else
        WeaponCircle.Visible = false
    end

    if DebugLabel then
        local dynText = ""
        if DynamicDistanceEnabled then
            dynText = string.format(" | Dyn: +%.1f", bonusDist)
        end
        local nearText = ""
        if nearDist < 999 then
            nearText = string.format(" | Near: %.1fs %.0fv", nearDist, nearSpeed)
        end
        local weapText = ""
        if WeaponDistDetectEnabled then
            weapText = string.format(" | WPN: %.1f", weaponRange)
        end
        DebugLabel.Text = string.format("Parry: %.1f  Anti: %.1f%s%s%s", parryDist, antiDist, dynText, weapText, nearText)
    end

    if ChecksLabel then
        local alive = IsAlive()
        local weapon = HasWeaponEquipped()
        local cd = IsCooldownReady()
        local stun = IsStunned()
        local ground = IsOnGround()

        local function tag(name, ok)
            if ok then
                return name .. ":OK"
            else
                return name .. ":NO"
            end
        end

        local cdLeft = ""
        if CooldownEnabled then
            local remaining = CooldownTime - (tick() - LastParryTick)
            if remaining > 0 then
                cdLeft = string.format("(%.1fs)", remaining)
            end
        end

        ChecksLabel.Text = string.format("%s | %s | %s%s | %s | %s",
            tag("ALIVE", alive),
            tag("WEAP", weapon),
            tag("CD", cd), cdLeft,
            tag("STUN", not stun),
            tag("GND", ground)
        )
    end
end

------------ > DYNAMIC DISTANCE <--------------------------------------------------------------

local function GetNearestEnemyData()
    local char = LocalPlayer.Character
    if not char then return nil, 9999, 0 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, 9999, 0 end

    local nearestPlayer = nil
    local nearestDist = 9999
    local approachSpeed = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local eChar = player.Character
            local eHrp = eChar:FindFirstChild("HumanoidRootPart")
            local eHum = eChar:FindFirstChild("Humanoid")
            if eHrp and eHum and eHum.Health > 0 then
                local dist = (hrp.Position - eHrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = player
                    local toUs = (hrp.Position - eHrp.Position).Unit
                    approachSpeed = eHrp.AssemblyLinearVelocity:Dot(toUs)
                end
            end
        end
    end

    return nearestPlayer, nearestDist, approachSpeed
end

local function CalculateDynamicBonus(baseDistance)
    if not DynamicDistanceEnabled then return 0, 9999, 0 end

    local _, dist, approachSpeed = GetNearestEnemyData()

    if approachSpeed <= 1 then return 0, dist, approachSpeed end

    local maxBonus = baseDistance * (DynamicMaxPercent / 100)
    local speedFactor = math.clamp(approachSpeed / 28, 0, 1)
    local distInfluence = math.clamp(1 - (dist / (baseDistance * 3)), 0, 1)
    local bonus = maxBonus * speedFactor * distInfluence

    return bonus, dist, approachSpeed
end

------------ > WINDOWS <--------------------------------------------------------------

local window = Fluent:CreateWindow({
    Title = 'Aether Hub',
    SubTitle = "Combat Warriors | "..SCRIPT_VERSION_BUILD,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightAlt
})

------------ > TABS <--------------------------------------------------------------

local Tabs = {
    CombatTab = window:AddTab({ Title = "Combat", Icon = "" }),
    ParryTab = window:AddTab({ Title = "Parry", Icon = "" }),
    MiscTab = window:AddTab({ Title = "Misc", Icon = "" }),
    ChecksTab = window:AddTab({ Title = "Checks", Icon = "" }),
    ConfigTab = window:AddTab({ Title = "Config", Icon = "" }),
    MainTab = window:AddTab({ Title = "Main", Icon = "" }),
}

------------ > OPTIONS <--------------------------------------------------------------

local Options = Fluent.Options

------------ > FUNCTIONS <--------------------------------------------------------------

local Funcs = {
    ToRGB = function(C3)
        local r, g, b = C3.R * 255, C3.G * 255, C3.B * 255
        return Color3.fromRGB(r, g, b)
    end,
}

local function GetMainWeaponCharacter()
    local t = nil
    if LocalPlayer.Character ~= nil then
        for i, v in next, LocalPlayer.Character:GetChildren() do
            if v:IsA('Tool') and v:GetAttribute('ItemType') and v:GetAttribute('ItemType') == 'weapon' then
                t = v
                break
            end
        end
    end
    return t
end

local function GetDistanceFromPart(Part)
    if LocalPlayer.Character ~= nil and Part ~= nil then
        return (LocalPlayer.Character.HumanoidRootPart.Position - Part.Position).Magnitude
    end
    return 0
end

------------ > MAIN <--------------------------------------------------------------

Fluent:Notify({
    Title = "Aether Hub",
    Content = "Loaded successfully.",
    Duration = 3
})

------------ > PARRY TAB <--------------------------------------------------------------

local AutoParryToggle = Tabs.ParryTab:AddToggle("AutoParryToggle", { Title = "Авто-парри", Default = false })

AutoParryToggle:OnChanged(function()
    AutoParryToggleValue = Options.AutoParryToggle.Value

    if AutoParryToggleValue == true then
        if DetectMethod == "Sounds (Default)" then
            if getgenv().sc ~= nil then
                getgenv().sc:Disconnect()
                getgenv().sc = nil
            end

            getgenv().sc = game.DescendantAdded:Connect(function(Child)
                if (Child:IsA('Sound') and Child:IsDescendantOf(workspace.PlayerCharacters))
                    and (Child.Parent ~= nil and Child.Parent.Name == 'Hitbox')
                    and not Child:IsDescendantOf(game.Players.LocalPlayer.Character) then

                    pcall(function()
                        local hitboxPart = Child.Parent
                        local hitboxPos = hitboxPart.Position
                        local myPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                        local dist = (hitboxPos - myPos).Magnitude

                        if ClosestFirstEnabled then
                            table.insert(ParryQueue, {
                                distance = dist,
                                position = hitboxPos,
                                hitboxPart = hitboxPart
                            })
                            ProcessQueue()
                            return
                        end

                        if not CanParryNow(hitboxPos) then return end

                        local effectiveDist = GetEffectiveParryDistance(hitboxPart)

                        if dist <= effectiveDist then
                            DoParryAction()
                        end
                    end)
                end
            end)
        elseif DetectMethod == "Sounds 2 (Animation Markers)" then
            S2_Enable()
        end
    else
        if getgenv().sc ~= nil then
            getgenv().sc:Disconnect()
            getgenv().sc = nil
        end
        S2_Disable_Safe()
    end
end)

local AntiParryToggle = Tabs.ParryTab:AddToggle("AntiParryToggle", { Title = "Анти-парри", Default = false })

AntiParryToggle:OnChanged(function()
    AntiParryToggleValue = Options.AntiParryToggle.Value

    if AntiParryToggleValue == true then
        if getgenv().sc2 ~= nil then
            getgenv().sc2:Disconnect()
            getgenv().sc2 = nil
        end

        getgenv().sc2 = workspace.DescendantAdded:Connect(function(Child)
            pcall(function()
                if Child:IsA('Sound') and Child.Name == 'Parry' and GetDistanceFromPart(Child.Parent) <= AntiParryDistance and not Child:IsDescendantOf(LocalPlayer.Character) then
                    local Tool = GetMainWeaponCharacter()
                    if Tool ~= nil then
                        task.spawn(function()
                            if Tool ~= nil then
                                Tool.Parent = LocalPlayer.Backpack
                                task.wait()
                                Tool.Parent = LocalPlayer.Character
                            end
                        end)
                    end
                end
            end)
        end)

    else
        if getgenv().sc2 ~= nil then
            getgenv().sc2:Disconnect()
            getgenv().sc2 = nil
        end
    end
end)

Tabs.ParryTab:AddParagraph({
    Title = "Настройки дистанции",
    Content = ""
})

local AutoParryDistInput = Tabs.ParryTab:AddInput("AutoParryDist", {
    Title = "Дистанция авто-парри (studs)",
    Default = tostring(AutoParryDistance),
    Placeholder = "12",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 1 and num <= 50 then
            AutoParryDistance = num
        end
    end
})

local AntiParryDistInput = Tabs.ParryTab:AddInput("AntiParryDist", {
    Title = "Дистанция анти-парри (studs)",
    Default = tostring(AntiParryDistance),
    Placeholder = "16",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 1 and num <= 50 then
            AntiParryDistance = num
        end
    end
})

Tabs.ParryTab:AddParagraph({
    Title = "Метод детекта",
    Content = "Sounds (Default) — срабатывает 1 раз при появлении звука.\nSounds 2 (Animation Markers) — отслеживает анимации врагов, парирует моментально при дистанции, останавливается на stopHitDetection."
})

local DetectMethodDropdown = Tabs.ParryTab:AddDropdown("DetectMethodDropdown", {
    Title = "Метод детекта",
    Values = { "Sounds (Default)", "Sounds 2 (Animation Markers)" },
    Multi = false,
    Default = "Sounds (Default)",
})

DetectMethodDropdown:OnChanged(function(Value)
    DetectMethod = Value
    if Options.AutoParryToggle.Value then
        Options.AutoParryToggle:SetValue(false)
        task.wait(0.1)
        Options.AutoParryToggle:SetValue(true)
    end
end)

Tabs.ParryTab:AddParagraph({
    Title = "Weapon Distance Detect",
    Content = "Расширяет радиус парри до размера хитбокса вражеского оружия (X+Y+Z)."
})

local WeaponDistToggle = Tabs.ParryTab:AddToggle("WeaponDistToggle", { Title = "Weapon Distance Detect", Default = true })

WeaponDistToggle:OnChanged(function()
    WeaponDistDetectEnabled = Options.WeaponDistToggle.Value
    if not WeaponDistDetectEnabled then
        WeaponDetectedRange = 0
    end
end)

Tabs.ParryTab:AddParagraph({
    Title = "Dynamic Distance",
    Content = ""
})

local DynamicDistToggle = Tabs.ParryTab:AddToggle("DynamicDistToggle", { Title = "Dynamic Distance (предикт)", Default = true })

DynamicDistToggle:OnChanged(function()
    DynamicDistanceEnabled = Options.DynamicDistToggle.Value
    if not DynamicDistanceEnabled then
        DynamicBonusDistance = 0
    end
end)

local DynamicPercentInput = Tabs.ParryTab:AddInput("DynamicPercent", {
    Title = "Макс. бонус Dynamic Distance (%)",
    Default = tostring(DynamicMaxPercent),
    Placeholder = "15",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 1 and num <= 100 then
            DynamicMaxPercent = num
        end
    end
})

Tabs.ParryTab:AddParagraph({
    Title = "Метод парри",
    Content = "keypress — обычное нажатие F. Network — через игровой модуль Network:FireServer."
})

local ParryMethodDropdown = Tabs.ParryTab:AddDropdown("ParryMethodDropdown", {
    Title = "Метод",
    Values = { "keypress", "Network" },
    Multi = false,
    Default = "keypress",
})

ParryMethodDropdown:OnChanged(function(Value)
    ParryMethod = Value
end)

local ParryEventInput = Tabs.ParryTab:AddInput("ParryEventName", {
    Title = "Network event name",
    Default = "Parry",
    Placeholder = "Parry",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        if Value and #Value > 0 then
            ParryEventName = Value
        end
    end
})

Tabs.ParryTab:AddParagraph({
    Title = "Визуал",
    Content = ""
})

local DebugToggle = Tabs.ParryTab:AddToggle("DebugToggle", { Title = "Дебаг (показать радиус + чеки)", Default = false })

DebugToggle:OnChanged(function()
    DebugEnabled = Options.DebugToggle.Value

    if DebugEnabled then
        SetupDebugVisuals()

        DebugConnection = RunService.RenderStepped:Connect(function()
            if not DebugEnabled then return end

            local bonus, nearDist, nearSpeed = CalculateDynamicBonus(AutoParryDistance)
            DynamicBonusDistance = bonus

            if WeaponDistDetectEnabled then
                WeaponDetectedRange = GetNearestEnemyHitboxRange()
            end

            local effectiveBase = AutoParryDistance
            if WeaponDistDetectEnabled and WeaponDetectedRange > effectiveBase then
                effectiveBase = WeaponDetectedRange
            end

            local effectiveParry = effectiveBase + DynamicBonusDistance
            UpdateDebugVisuals(effectiveParry, AntiParryDistance, DynamicBonusDistance, nearDist, nearSpeed, WeaponDetectedRange)
        end)
    else
        DestroyDebugVisuals()
        DynamicBonusDistance = 0
    end
end)

local AutoParryToggleBind = Tabs.ParryTab:AddKeybind("AutoParryToggleBind", {
    Title = "Бинд авто-парри",
    Mode = "Toggle",
    Default = "X",
    Callback = function(Value)
        Options.AutoParryToggle:SetValue(not Options.AutoParryToggle.Value)
        if Options.AutoParryToggle.Value == true then
            Fluent:Notify({ Title = "Aether Hub", Content = "Auto-Parry ВКЛЮЧЁН.", Duration = 3 })
        else
            Fluent:Notify({ Title = "Aether Hub", Content = "Auto-Parry выключен.", Duration = 3 })
        end
    end,
})

local AntiParryToggleBind = Tabs.ParryTab:AddKeybind("AntiParryToggleBind", {
    Title = "Бинд анти-парри",
    Mode = "Toggle",
    Default = "T",
    Callback = function(Value)
        Options.AntiParryToggle:SetValue(not Options.AntiParryToggle.Value)
        if Options.AntiParryToggle.Value == true then
            Fluent:Notify({ Title = "Aether Hub", Content = "Anti-Parry ВКЛЮЧЁН.", Duration = 3 })
        else
            Fluent:Notify({ Title = "Aether Hub", Content = "Anti-Parry выключен.", Duration = 3 })
        end
    end,
})

------------ > CHECKS TAB <--------------------------------------------------------------

Tabs.ChecksTab:AddParagraph({
    Title = "Проверки перед парированием",
    Content = "Каждая проверка должна пройти, иначе парирование не произойдёт."
})

local AliveCheckToggle = Tabs.ChecksTab:AddToggle("AliveCheckToggle", { Title = "Проверка жизни", Default = true })
AliveCheckToggle:OnChanged(function()
    AliveCheckEnabled = Options.AliveCheckToggle.Value
end)

local WeaponReqToggle = Tabs.ChecksTab:AddToggle("WeaponReqToggle", { Title = "Требовать оружие в руке", Default = true })
WeaponReqToggle:OnChanged(function()
    WeaponRequiredEnabled = Options.WeaponReqToggle.Value
end)

local StunCheckToggle = Tabs.ChecksTab:AddToggle("StunCheckToggle", { Title = "Проверка стана", Default = true })
StunCheckToggle:OnChanged(function()
    StunCheckEnabled = Options.StunCheckToggle.Value
end)

local GroundCheckToggle = Tabs.ChecksTab:AddToggle("GroundCheckToggle", { Title = "Только на земле", Default = false })
GroundCheckToggle:OnChanged(function()
    GroundCheckEnabled = Options.GroundCheckToggle.Value
end)

Tabs.ChecksTab:AddParagraph({
    Title = "Направление",
    Content = ""
})

local FacingCheckToggle = Tabs.ChecksTab:AddToggle("FacingCheckToggle", { Title = "Проверка направления (face check)", Default = false })
FacingCheckToggle:OnChanged(function()
    FacingCheckEnabled = Options.FacingCheckToggle.Value
end)

local FacingAngleInput = Tabs.ChecksTab:AddInput("FacingAngleInput", {
    Title = "Угол обзора для парри (градусы)",
    Default = tostring(FacingAngle),
    Placeholder = "120",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 30 and num <= 360 then
            FacingAngle = num
        end
    end
})

Tabs.ChecksTab:AddParagraph({
    Title = "Кулдаун",
    Content = ""
})

local CooldownToggle = Tabs.ChecksTab:AddToggle("CooldownToggle", { Title = "Кулдаун между парри", Default = true })
CooldownToggle:OnChanged(function()
    CooldownEnabled = Options.CooldownToggle.Value
end)

local CooldownInput = Tabs.ChecksTab:AddInput("CooldownInput", {
    Title = "Время кулдауна (сек)",
    Default = tostring(CooldownTime),
    Placeholder = "0.65",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0.1 and num <= 5 then
            CooldownTime = num
        end
    end
})

Tabs.ChecksTab:AddParagraph({
    Title = "Мульти-атака",
    Content = ""
})

local ClosestFirstToggle = Tabs.ChecksTab:AddToggle("ClosestFirstToggle", { Title = "Очередь: парить ближайшего", Default = false })
ClosestFirstToggle:OnChanged(function()
    ClosestFirstEnabled = Options.ClosestFirstToggle.Value
    ParryQueue = {}
end)

local QueueWindowInput = Tabs.ChecksTab:AddInput("QueueWindowInput", {
    Title = "Окно очереди (сек)",
    Default = tostring(QueueWindow),
    Placeholder = "0.12",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0.01 and num <= 1 then
            QueueWindow = num
        end
    end
})

------------ > DYNAMIC DISTANCE UPDATER <--------------------------------------------------------------

RunService.Heartbeat:Connect(function()
    if DynamicDistanceEnabled then
        local bonus, _, _ = CalculateDynamicBonus(AutoParryDistance)
        DynamicBonusDistance = bonus
    end
    if WeaponDistDetectEnabled then
        WeaponDetectedRange = GetNearestEnemyHitboxRange()
    end
end)

------------ > CONFIG TAB <------------------------------------------------------------

SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("AetherHub/CombatWarriors")
SaveManager:BuildConfigSection(Tabs.ConfigTab)

------------ > COMBAT TAB <------------------------------------------------------------

local ReachToggle = Tabs.CombatTab:AddToggle("ReachToggle", { Title = "Reach на оружие", Default = false })

getgenv().ReachConnection = nil
local ReachDistance = 7.5

ReachToggle:OnChanged(function()
    ReachToggleValue = Options.ReachToggle.Value
    if ReachToggleValue == true then
       if getgenv().ReachConnection ~= nil then
        getgenv().ReachConnection:Disconnect()
        getgenv().ReachConnection = nil
       end

       for i,Child in next, Character:GetChildren() do
            if Child:IsA('Tool') and Child:GetAttribute('ItemType') and Child:GetAttribute('ItemType') == 'weapon' and Child:FindFirstChild('Hitboxes') then
                EnableReach(Child, ReachDistance)
            end
        end

        getgenv().ReachConnection = Character.ChildAdded:Connect(function(Child)
            if Child:IsA('Tool') and Child:GetAttribute('ItemType') and Child:GetAttribute('ItemType') == 'weapon' and Child:FindFirstChild('Hitboxes') then
                EnableReach(Child, ReachDistance)
            end
        end)
    else
        if getgenv().ReachConnection ~= nil then
            getgenv().ReachConnection:Disconnect()
            getgenv().ReachConnection = nil
        end
        for i,Child in next, LocalPlayer.Backpack:GetChildren() do
            if Child:IsA('Tool') and Child:GetAttribute('ItemType') and Child:GetAttribute('ItemType') == 'weapon' and Child:FindFirstChild('Hitboxes') then
                DisableReach(Child)
            end
        end
        for i,Child in next, Character:GetChildren() do
            if Child:IsA('Tool') and Child:GetAttribute('ItemType') and Child:GetAttribute('ItemType') == 'weapon' and Child:FindFirstChild('Hitboxes') then
                DisableReach(Child)
            end
        end
    end
end)

local ReachDistanceInput = Tabs.CombatTab:AddInput("ReachDistance", {
    Title = "Reach Distance",
    Default = '7.5',
    Placeholder = "7.5",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        ReachDistance = tonumber(Value) <= 7.5 and tonumber(Value) or 7.5
    end
})

------------ > MISC TAB <--------------------------------------------------------------

local AirDropAutoLoot = Tabs.MiscTab:AddToggle("AirDropAutoLoot", { Title = "Авто-Лут Аирдропа", Default = false })

local AirdropBusy = false

AirDropAutoLoot:OnChanged(function()
    AirDropAutoLootValue = Options.AirDropAutoLoot.Value
    if AirDropAutoLootValue == true then
        while AirDropAutoLootValue do
            pcall(function()
                if AirdropBusy then return end

                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local mapFolder = workspace:FindFirstChild("Map")
                if not mapFolder then return end

                for _, obj in ipairs(mapFolder:GetChildren()) do
                    if AirdropBusy then break end
                    if obj.Name == "Airdrop" and obj:IsA("Model") then
                        local crate = obj:FindFirstChild("Crate")
                        if not crate then continue end
                        local base = crate:FindFirstChild("Base")
                        if not base or not base:IsA("BasePart") then continue end
                        local prompt = base:FindFirstChild("ProximityPrompt")
                        if not prompt or not prompt.Enabled then continue end

                        local dist = (hrp.Position - base.Position).Magnitude
                        if dist > 11 then continue end

                        AirdropBusy = true

                        local holdDuration = prompt.HoldDuration or 0
                        local holdCompleted = true

                        keypress(0x48)
                        task.wait(0.05 + math.random() * 0.03)

                        if holdDuration > 0 then
                            local elapsed = 0
                            local step = 0.15
                            while elapsed < holdDuration and AirDropAutoLootValue do
                                task.wait(step)
                                elapsed = elapsed + step

                                local hrpCheck = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if not hrpCheck then holdCompleted = false break end
                                if not prompt.Parent or not prompt.Enabled then holdCompleted = false break end
                                if (hrpCheck.Position - base.Position).Magnitude > 11 then holdCompleted = false break end
                            end
                        end

                        if holdCompleted and prompt.Parent and prompt.Enabled then
                            fireproximityprompt(prompt)
                        end

                        task.wait(0.05 + math.random() * 0.03)
                        keyrelease(0x48)

                        AirdropBusy = false
                    end
                end
            end)
            task.wait(0.5)
        end
        AirdropBusy = false
    end
end)

Tabs.MiscTab:AddParagraph({
    Title = "Остальне",
    Content = ""
})

local InfiniteStamina = Tabs.MiscTab:AddToggle("InfiniteStamina", { Title = "Бесконечная стамина", Default = false })

local StaminaClass = require(ReplicatedStorage.Shared.Source.Stamina.Stamina)
local oldGetRealValue = StaminaClass.getRealNewStaminaValue

InfiniteStamina:OnChanged(function()
    InfiniteStaminaValue = Options.InfiniteStamina.Value
    if InfiniteStaminaValue == true then
        StaminaClass.getRealNewStaminaValue = function(self, requestedValue)
            if self._maxStamina then
                return self._maxStamina
            end
            return oldGetRealValue(self, requestedValue)
        end
    else
        require(game:GetService("ReplicatedStorage").Shared.Source.Stamina.Stamina).getRealNewStaminaValue = oldGetRealValue
    end
end)

------------ > MAIN TAB <--------------------------------------------------------------

local TestToggle = Tabs.MainTab:AddToggle("TestToggle", { Title = "тест фун", Default = false })

TestToggle:OnChanged(function()
    TestToggleValue = Options.TestToggle.Value
    if TestToggleValue == true then
        print('Toggle Enabled')
    else
        print('Toggle Disabled')
    end
end)

local ToggleLoop = Tabs.MainTab:AddToggle("ToggleLoop", { Title = "Loop toggle test", Default = false })

ToggleLoop:OnChanged(function()
    LoopToggleValue = Options.ToggleLoop.Value
    if LoopToggleValue == true then
        while LoopToggleValue do
            print('Toggle Looped')
            task.wait()
        end
    else
        print('UnLooped')
    end
end)

local Input = Tabs.MainTab:AddInput("Input", {
    Title = "Input",
    Default = '50',
    Placeholder = "Input Test",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        print(Value)
    end
})

Tabs.MainTab:AddParagraph({
    Title = "Paragraph",
    Content = ""
})

Tabs.MainTab:AddButton({
    Title = "Button",
    Description = "",
    Callback = function()
        print('Button callback')
    end
})

Tabs.MainTab:AddButton({
    Title = "Button",
    Description = "Yep thats a button",
    Callback = function()
        window:Dialog({
            Title = "Title",
            Content = "This is a dialog",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        print("Confirmed the dialog.")
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        print("Cancelled the dialog.")
                    end
                }
            }
        })
    end
})

local ColorPicker = Tabs.MainTab:AddColorpicker("ColorPicker", {
    Title = "Color Picker",
    Default = Color3.fromRGB(255, 255, 255)
})

ColorPicker:OnChanged(function(NewColor)
    print(Funcs.ToRGB(NewColor))
end)

local Dropdown = Tabs.MainTab:AddDropdown("Dropdown", {
    Title = "Dropdown",
    Values = { "12121", "221321", "1231" },
    Multi = false,
    Default = 1,
})

Dropdown:OnChanged(function(Value)
    print("Dropdown new:", Value)
end)

local MultiDropdown = Tabs.MainTab:AddDropdown("MultiDropdown", {
    Title = "MultiDropdown",
    Values = { "12121", "221321", "1231" },
    Multi = true,
    Default = {},
})

MultiDropdown:OnChanged(function(Value)
    local Values = {}
    for Value, State in next, Value do
        Values[#Values + 1] = Value
    end
    print("MultiDropdown new:", table.concat(Values, ", "))
end)

------------ > END <--------------------------------------------------------------
