local SCRIPT_VERSION_BUILD = 'v13'

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScripterNumber/SPVKHUB/refs/heads/main/Fluent"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

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

getgenv().AetherFriends = getgenv().AetherFriends or {}

local function IsFriend(charOrPlayer)
    if typeof(charOrPlayer) ~= "Instance" then return false end
    local p
    if charOrPlayer:IsA("Player") then
        p = charOrPlayer
    else
        p = Players:GetPlayerFromCharacter(charOrPlayer)
        if not p then
            local playerChars = Workspace:FindFirstChild("PlayerCharacters")
            if playerChars and charOrPlayer.Parent == playerChars then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character == charOrPlayer then
                        p = plr
                        break
                    end
                end
            end
        end
    end
    return p and getgenv().AetherFriends[p.UserId] ~= nil or false
end

local function FindPlayersByPartialName(query)
    if not query or query == "" then return {} end
    query = query:lower()
    local results = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Name:lower():find(query, 1, true) or p.DisplayName:lower():find(query, 1, true) then
                table.insert(results, p)
            end
        end
    end
    return results
end

local FriendSearchQuery = ""

local AimEnabled = false
local AimPredictEnabled = false
local AimPredictValue = 0.3
local AimMaxDistance = 100
local AimConnection = nil

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

local LastParryTick = 0
local LastParrySucceeded = false

local ParryConstants = nil
pcall(function()
    ParryConstants = require(ReplicatedStorage.Shared.Source.Parry.ParryConstants)
end)

local function GetGameCooldown()
    if ParryConstants then
        if LastParrySucceeded and ParryConstants.PARRY_COOLDOWN_IN_SECONDS_AFTER_SUCCESSFUL_PARRY then
            return ParryConstants.PARRY_COOLDOWN_IN_SECONDS_AFTER_SUCCESSFUL_PARRY
        elseif ParryConstants.PARRY_COOLDOWN_IN_SECONDS then
            return ParryConstants.PARRY_COOLDOWN_IN_SECONDS
        end
    end
    return CooldownTime
end

local function IsCooldownReady()
    if not CooldownEnabled then return true end
    return (tick() - LastParryTick) >= GetGameCooldown()
end

local function GetCooldownRemaining()
    if not CooldownEnabled then return 0 end
    local remaining = GetGameCooldown() - (tick() - LastParryTick)
    if remaining < 0 then return 0 end
    return remaining
end

local function MarkParryUsed()
    LastParryTick = tick()
    LastParrySucceeded = true
end

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

local function CanParryNow_NoCooldown(attackerPos)
    if not IsAlive() then return false end
    if not HasWeaponEquipped() then return false end
    if IsStunned() then return false end
    if not IsOnGround() then return false end
    if not IsAttackerInFront(attackerPos) then return false end
    if not isrbxactive() then return false end
    return true
end

local function CanParryNow(attackerPos)
    if not CanParryNow_NoCooldown(attackerPos) then return false end
    if not IsCooldownReady() then return false end
    return true
end

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

local function DoParryAction()
    MarkParryUsed()

    local Item = GetMainWeaponCharacter()

    task.spawn(function()
        if Item ~= nil then
            Item.Parent = LocalPlayer.Backpack
            task.wait() 
            Item.Parent = LocalPlayer.Character
            task.wait() 
        end

        if ParryMethod == "Network" then
            pcall(function()
                Network:FireServer(ParryEventName)
            end)
        else
            keypress(0x46)
            task.wait(0.15)
            keyrelease(0x46)
        end
    end)
end

local function DoParryWithCooldownWait(attackerPos, hitboxPart)
    if not CanParryNow_NoCooldown(attackerPos) then return false end

    if not IsCooldownReady() then
        local remaining = GetCooldownRemaining()
        if remaining > 0.5 then return false end
        local startTick = tick()
        while (tick() - startTick) < remaining do
            RunService.Heartbeat:Wait()
            if not CanParryNow_NoCooldown(attackerPos) then return false end
            if not AutoParryToggleValue then return false end
        end
        if not IsCooldownReady() then return false end
    end

    local effectiveDist = GetEffectiveParryDistance(hitboxPart)
    local lhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not lhrp then return false end
    local dist = (attackerPos - lhrp.Position).Magnitude
    if dist > effectiveDist then return false end

    DoParryAction()
    return true
end

local ParryQueue = {}
local QueueProcessing = false

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

        DoParryWithCooldownWait(best.position, best.hitboxPart)
    end)
end

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

local SlashAnimIdsCache = {}
local ParryAnimIdsCache = {}
local HasCachedAnims = false

local function CacheAllAnimations()
    if HasCachedAnims then return end
    HasCachedAnims = true

    local meleeAssets = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Assets")
        and ReplicatedStorage.Shared.Assets:FindFirstChild("Melee")
        
    if not meleeAssets then return end

    for _, weaponFolder in ipairs(meleeAssets:GetChildren()) do
        local animsFolder = weaponFolder:FindFirstChild("Animations")
        if animsFolder then
            for _, folderOrAnim in ipairs(animsFolder:GetDescendants()) do
                if folderOrAnim:IsA("Animation") then
                    local id = string.match(folderOrAnim.AnimationId, "%d+")
                    if id and tonumber(id) then
                        local name = folderOrAnim.Name:lower()
                        local pName = folderOrAnim.Parent and folderOrAnim.Parent.Name:lower() or ""
                        
                        if name:find("parry") or name:find("parries") or pName:find("parry") then
                            ParryAnimIdsCache[id] = true
                        elseif name:find("slash") or name:find("swing") or name:find("hit") or name:find("attack") or pName:find("slash") or pName:find("swing") then
                            SlashAnimIdsCache[id] = true
                        end
                    end
                end
            end
        end
    end
end
task.spawn(CacheAllAnimations)

local S2_AnimCache = {}
local S2_ActiveTrackers = {}
local S2_AnimConns = {}

local function S2_GetMarkerTimes(animId)
    local result = {startTime = nil, stopTime = nil}
    local ok, kfSeq = pcall(function()
        return KeyframeSequenceProvider:GetKeyframeSequenceAsync(animId)
    end)

    if not ok or not kfSeq then
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
    return result
end

local function S2_KillTracker(trackerId)
    local tracker = S2_ActiveTrackers[trackerId]
    if tracker then
        if tracker.conn then tracker.conn:Disconnect() end
        tracker.dead = true
        S2_ActiveTrackers[trackerId] = nil
    end
end

local function S2_KillAllTrackers()
    for id, tracker in pairs(S2_ActiveTrackers) do
        if tracker.conn then tracker.conn:Disconnect() end
        tracker.dead = true
    end
    S2_ActiveTrackers = {}
end

local function S2_KillTrackersForEnemy(enemyChar)
    for id, tracker in pairs(S2_ActiveTrackers) do
        if tracker.enemyChar == enemyChar then
            S2_KillTracker(id)
        end
    end
end

local function S2_GetEnemyHitboxPos(enemyChar)
    for _, child in ipairs(enemyChar:GetChildren()) do
        if child:IsA("Tool") then
            local hitboxes = child:FindFirstChild("Hitboxes")
            if hitboxes then
                local hb = hitboxes:FindFirstChild("Hitbox")
                if hb then
                    if hb:IsA("BasePart") then
                        return hb.Position, hb
                    end
                    for _, sub in ipairs(hb:GetChildren()) do
                        if sub:IsA("BasePart") then
                            return sub.Position, sub
                        end
                        if sub:IsA("Attachment") then
                            return sub.WorldPosition, nil
                        end
                    end
                end
            end
            local hb = child:FindFirstChild("Hitbox")
            if hb and hb:IsA("BasePart") then
                return hb.Position, hb
            end
        end
    end
    local hrp = enemyChar:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position, nil end
    return nil, nil
end

local function S2_StartTracker(enemyChar, animTrack, animId)
    local trackerId = tostring(enemyChar) .. "_" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999))
    
    if IsFriend(enemyChar) then return end
    
    local parried = false

    local tracker = {
        enemyChar = enemyChar,
        dead = false,
        conn = nil
    }
    S2_ActiveTrackers[trackerId] = tracker

    local markers = S2_AnimCache[animId]
    if not markers then
        markers = {startTime = nil, stopTime = 0.55}
        task.spawn(function()
            local realMarkers = S2_GetMarkerTimes(animId)
            markers.startTime = realMarkers.startTime
            if realMarkers.stopTime then
                markers.stopTime = realMarkers.stopTime
            end
            S2_AnimCache[animId] = markers
        end)
    end

    tracker.conn = RunService.Heartbeat:Connect(function()
        if tracker.dead then
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
        if markers.stopTime and elapsed >= markers.stopTime + 0.05 then
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

        local _, hitboxPart = S2_GetEnemyHitboxPos(enemyChar)

        local dist = (eHrp.Position - lhrp.Position).Magnitude
        local effectiveDist = GetEffectiveParryDistance(hitboxPart)

        if dist > effectiveDist then return end

        if IsCooldownReady() then
            parried = true
            DoParryAction()
            S2_KillTracker(trackerId)
            return
        end

        local remaining = GetCooldownRemaining()
        if remaining <= 0.35 then
            parried = true
            tracker.dead = true
            task.spawn(function()
                local startTick = tick()
                while (tick() - startTick) < remaining do
                    RunService.Heartbeat:Wait()
                    if not AutoParryToggleValue then return end
                end
                if not IsCooldownReady() then return end

                local lhrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not lhrp2 then return end

                local eHrp2 = enemyChar:FindFirstChild("HumanoidRootPart")
                if not eHrp2 then return end

                local _, hb2 = S2_GetEnemyHitboxPos(enemyChar)
                local dist2 = (eHrp2.Position - lhrp2.Position).Magnitude
                local eff2 = GetEffectiveParryDistance(hb2)
                
                if dist2 <= eff2 and CanParryNow(eHrp2.Position) then
                    DoParryAction()
                end
            end)
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

        local id = string.match(anim.AnimationId, "%d+")
        
        if not id or not SlashAnimIdsCache[id] then 
            return 
        end

        S2_StartTracker(enemyChar, animTrack, anim.AnimationId)
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
    CacheAllAnimations()

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
            S2_KillTrackersForEnemy(ch)
        end)
    end
end

function S2_Disable_Safe()
    S2_UnhookAll()
    if S2_ChildAddedConn then S2_ChildAddedConn:Disconnect(); S2_ChildAddedConn = nil end
    if S2_ChildRemovedConn then S2_ChildRemovedConn:Disconnect(); S2_ChildRemovedConn = nil end
end

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
        local cdText = ""
        local cdRemain = GetCooldownRemaining()
        if cdRemain > 0 then
            cdText = string.format(" | CD: %.2fs", cdRemain)
        end
        DebugLabel.Text = string.format("Parry: %.1f  Anti: %.1f%s%s%s%s", parryDist, antiDist, dynText, weapText, nearText, cdText)
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
            local remaining = GetCooldownRemaining()
            if remaining > 0 then
                cdLeft = string.format("(%.2fs)", remaining)
            end
        end

        local trackCount = 0
        for _ in pairs(S2_ActiveTrackers) do trackCount = trackCount + 1 end

        ChecksLabel.Text = string.format("%s | %s | %s%s | %s | %s | TRK:%d",
            tag("ALIVE", alive),
            tag("WEAP", weapon),
            tag("CD", cd), cdLeft,
            tag("STUN", not stun),
            tag("GND", ground),
            trackCount
        )
    end
end

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

local window = Fluent:CreateWindow({
    Title = 'Aether Hub',
    SubTitle = "Combat Warriors | "..SCRIPT_VERSION_BUILD,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightAlt
})

local Tabs = {
    CombatTab = window:AddTab({ Title = "Combat", Icon = "" }),
    ParryTab = window:AddTab({ Title = "Parry", Icon = "" }),
    VisualsTab = window:AddTab({ Title = "Visuals", Icon = "" }),
    MiscTab = window:AddTab({ Title = "Misc", Icon = "" }),
    ChecksTab = window:AddTab({ Title = "Checks", Icon = "" }),
    ConfigTab = window:AddTab({ Title = "Config", Icon = "" }),
    MainTab = window:AddTab({ Title = "Main", Icon = "" }),
    SocialTab = window:AddTab({ Title = "Social", Icon = "" }),
}

local Options = Fluent.Options

local Funcs = {
    ToRGB = function(C3)
        local r, g, b = C3.R * 255, C3.G * 255, C3.B * 255
        return Color3.fromRGB(r, g, b)
    end,
}

local ESPContainer = Instance.new("Folder")
ESPContainer.Name = "AetherESPContainer_" .. tostring(math.random(1000, 9999))
pcall(function() ESPContainer.Parent = gethui() end)
if not ESPContainer.Parent then
    ESPContainer.Parent = CoreGui
end

local ESP2DGui = Instance.new("ScreenGui")
ESP2DGui.Name = "AetherESP2D"
ESP2DGui.IgnoreGuiInset = true
ESP2DGui.Parent = ESPContainer

local ESPPlayers = {}
local ESPEnabled = false
local ESPMethod = "2D Box"
local ESPEnemyColor = Color3.fromRGB(255, 0, 0)
local ESPFriendColor = Color3.fromRGB(0, 255, 0)

local function Create2DBox()
    local box = {
        Top = Instance.new("Frame"),
        Bottom = Instance.new("Frame"),
        Left = Instance.new("Frame"),
        Right = Instance.new("Frame")
    }
    for _, line in pairs(box) do
        line.BackgroundColor3 = Color3.new(1, 1, 1)
        line.BorderSizePixel = 0
        line.Visible = false
        line.Parent = ESP2DGui
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = Color3.new(0, 0, 0)
        stroke.Parent = line
    end
    return box
end

local function CreateHighlight(adornee)
    local hl = Instance.new("Highlight")
    hl.Adornee = adornee
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Enabled = false
    hl.Parent = ESPContainer
    return hl
end

local function Create3DBox(adornee)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = adornee
    box.Size = Vector3.new(4, 5.5, 1.5)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Visible = false
    box.Parent = ESPContainer
    return box
end

local function CleanupESP(player)
    if ESPPlayers[player] then
        for _, line in pairs(ESPPlayers[player].Box2D) do
            line:Destroy()
        end
        if ESPPlayers[player].Highlight then ESPPlayers[player].Highlight:Destroy() end
        if ESPPlayers[player].Box3D then ESPPlayers[player].Box3D:Destroy() end
        if ESPPlayers[player].Text then ESPPlayers[player].Text:Destroy() end
        ESPPlayers[player] = nil
    end
end

local function SetupESP(player)
    if player == LocalPlayer then return end
    CleanupESP(player)
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Visible = false
    text.AnchorPoint = Vector2.new(0.5, 1)
    text.Size = UDim2.new(0, 0, 0, 0)
    text.Parent = ESP2DGui

    local objects = {
        Box2D = Create2DBox(),
        Highlight = CreateHighlight(nil),
        Box3D = Create3DBox(nil),
        Text = text
    }
    ESPPlayers[player] = objects
end

for _, p in ipairs(Players:GetPlayers()) do
    SetupESP(p)
end

Players.PlayerAdded:Connect(function(p)
    SetupESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
    CleanupESP(p)
end)

RunService.RenderStepped:Connect(function()
    for player, objs in pairs(ESPPlayers) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        local isAlive = char and hrp and hum and hum.Health > 0
        local draw2D = false
        local drawText = false
        local color = IsFriend(player) and ESPFriendColor or ESPEnemyColor

        if ESPEnabled and isAlive then
            local cam = workspace.CurrentCamera
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local head = char:FindFirstChild("Head")
                local headPos = head and head.Position or (hrp.Position + Vector3.new(0, 1.5, 0))
                local footPos = hrp.Position - Vector3.new(0, 3, 0)
                
                local topPos = cam:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
                local bottomPos = cam:WorldToViewportPoint(footPos)
                
                local height = math.abs(topPos.Y - bottomPos.Y)
                local width = height / 2
                local x = pos.X - width / 2
                local y = topPos.Y

                if ESPMethod == "2D Box" then
                    objs.Box2D.Top.Position = UDim2.new(0, x, 0, y)
                    objs.Box2D.Top.Size = UDim2.new(0, width, 0, 1)
                    objs.Box2D.Bottom.Position = UDim2.new(0, x, 0, y + height)
                    objs.Box2D.Bottom.Size = UDim2.new(0, width, 0, 1)
                    objs.Box2D.Left.Position = UDim2.new(0, x, 0, y)
                    objs.Box2D.Left.Size = UDim2.new(0, 1, 0, height)
                    objs.Box2D.Right.Position = UDim2.new(0, x + width, 0, y)
                    objs.Box2D.Right.Size = UDim2.new(0, 1, 0, height)

                    for _, line in pairs(objs.Box2D) do
                        line.BackgroundColor3 = color
                    end
                    draw2D = true
                end

                objs.Text.Text = string.format("%s [%d HP]", player.DisplayName, math.floor(hum.Health))
                objs.Text.TextColor3 = color
                objs.Text.Position = UDim2.new(0, pos.X, 0, topPos.Y - 2)
                drawText = true
            end

            if ESPMethod == "Highlight" then
                objs.Highlight.Adornee = char
                objs.Highlight.FillColor = color
                objs.Highlight.OutlineColor = color
                objs.Highlight.Enabled = true
            elseif ESPMethod == "3D Box" then
                objs.Box3D.Adornee = hrp
                objs.Box3D.Color3 = color
                objs.Box3D.Visible = true
            end
        end

        for _, line in pairs(objs.Box2D) do
            line.Visible = draw2D
        end
        objs.Text.Visible = drawText

        if not ESPEnabled or ESPMethod ~= "Highlight" or not isAlive then
            objs.Highlight.Enabled = false
        end
        if not ESPEnabled or ESPMethod ~= "3D Box" or not isAlive then
            objs.Box3D.Visible = false
        end
    end
end)

Tabs.VisualsTab:AddParagraph({
    Title = "ESP (Chams)",
    Content = "Отображение игроков сквозь стены. Полностью скрыто от детектов."
})

local ESPToggle = Tabs.VisualsTab:AddToggle("ESPToggle", { Title = "Включить ESP", Default = false })
ESPToggle:OnChanged(function()
    ESPEnabled = Options.ESPToggle.Value
end)

local ESPMethodDropdown = Tabs.VisualsTab:AddDropdown("ESPMethodDropdown", {
    Title = "Метод отрисовки",
    Values = { "2D Box", "Highlight", "3D Box" },
    Multi = false,
    Default = "2D Box",
})
ESPMethodDropdown:OnChanged(function(Value)
    ESPMethod = Value
end)

local EnemyColorPicker = Tabs.VisualsTab:AddColorpicker("EnemyColorPicker", {
    Title = "Цвет врагов",
    Default = Color3.fromRGB(255, 0, 0)
})
EnemyColorPicker:OnChanged(function(NewColor)
    ESPEnemyColor = Funcs.ToRGB(NewColor)
end)

local FriendColorPicker = Tabs.VisualsTab:AddColorpicker("FriendColorPicker", {
    Title = "Цвет друзей",
    Default = Color3.fromRGB(0, 255, 0)
})
FriendColorPicker:OnChanged(function(NewColor)
    ESPFriendColor = Funcs.ToRGB(NewColor)
end)

local function CheckForAnyParrier(maxDist)
    CacheAllAnimations()

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar then
                local eHrp = pChar:FindFirstChild("HumanoidRootPart")
                local eHum = pChar:FindFirstChild("Humanoid")
                
                if eHrp and eHum and eHum.Health > 0 then
                    local dist = (hrp.Position - eHrp.Position).Magnitude
                    
                    if dist <= maxDist then
                        local animator = eHum:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, animTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                                if animTrack.IsPlaying then
                                    local anim = animTrack.Animation
                                    if anim and anim.AnimationId then
                                        local id = string.match(anim.AnimationId, "%d+")

                                        if id and ParryAnimIdsCache[id] and animTrack.IsPlaying == true and id ~= '0' then
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

local function GetDistanceFromPart(Part)
    if LocalPlayer.Character ~= nil and Part ~= nil then
        return (LocalPlayer.Character.HumanoidRootPart.Position - Part.Position).Magnitude
    end
    return 0
end

Fluent:Notify({
    Title = "Aether Hub",
    Content = "Loaded successfully.",
    Duration = 3
})

Tabs.SocialTab:AddParagraph({
    Title = "Друзья",
    Content = "Друзья защищены от: Авто-парри, Perfect Hit, Aim.\nВведите ник или дисплейник (можно неполный)."
})

local function CheckAndAddRobloxFriend(plr)
    if plr ~= LocalPlayer and LocalPlayer:IsFriendsWith(plr.UserId) then
        if not getgenv().AetherFriends[plr.UserId] then
            getgenv().AetherFriends[plr.UserId] = plr.DisplayName .. " (@" .. plr.Name .. ")"
            Fluent:Notify({
                Title = "Social",
                Content = "Roblox друг автоматически добавлен в вайтлист:\n" .. plr.DisplayName,
                Duration = 4
            })
        end
    end
end

local AutoAddRobloxFriendsToggle = Tabs.SocialTab:AddToggle("AutoAddRobloxFriends", { Title = "Авто-добавление друзей из Roblox", Default = false })

AutoAddRobloxFriendsToggle:OnChanged(function()
    if Options.AutoAddRobloxFriends.Value then
        for _, p in ipairs(Players:GetPlayers()) do
            task.spawn(CheckAndAddRobloxFriend, p)
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if Options.AutoAddRobloxFriends and Options.AutoAddRobloxFriends.Value then
        task.spawn(CheckAndAddRobloxFriend, plr)
    end
end)

Tabs.SocialTab:AddInput("FriendSearchInput", {
    Title = "Поиск игрока",
    Default = "",
    Placeholder = "Введите ник...",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        FriendSearchQuery = Value
    end
})

Tabs.SocialTab:AddButton({
    Title = "➕ Добавить в друзья",
    Description = "Найдёт игрока по частичному нику и добавит",
    Callback = function()
        if FriendSearchQuery == "" then
            Fluent:Notify({Title = "Friends", Content = "Введите имя игрока.", Duration = 3})
            return
        end
        local results = FindPlayersByPartialName(FriendSearchQuery)
        if #results == 0 then
            Fluent:Notify({Title = "Friends", Content = "Игрок «" .. FriendSearchQuery .. "» не найден на сервере.", Duration = 3})
            return
        end
        local p = results[1]
        if getgenv().AetherFriends[p.UserId] then
            Fluent:Notify({Title = "Friends", Content = p.DisplayName .. " уже в друзьях.", Duration = 3})
            return
        end
        getgenv().AetherFriends[p.UserId] = p.DisplayName .. " (@" .. p.Name .. ")"
        local extra = ""
        if #results > 1 then
            extra = "\n(Найдено " .. #results .. " совпадений, добавлен первый)"
        end
        Fluent:Notify({Title = "Friends", Content = "✅ Добавлен: " .. p.DisplayName .. " (@" .. p.Name .. ")" .. extra, Duration = 4})
    end
})

Tabs.SocialTab:AddButton({
    Title = "➖ Удалить из друзей",
    Description = "Удалит друга по частичному нику",
    Callback = function()
        if FriendSearchQuery == "" then
            Fluent:Notify({Title = "Friends", Content = "Введите имя игрока.", Duration = 3})
            return
        end
        local query = FriendSearchQuery:lower()
        for uid, name in pairs(getgenv().AetherFriends) do
            if name:lower():find(query, 1, true) then
                getgenv().AetherFriends[uid] = nil
                Fluent:Notify({Title = "Friends", Content = "❌ Удалён: " .. name, Duration = 3})
                return
            end
        end
        local results = FindPlayersByPartialName(FriendSearchQuery)
        for _, p in ipairs(results) do
            if getgenv().AetherFriends[p.UserId] then
                local name = getgenv().AetherFriends[p.UserId]
                getgenv().AetherFriends[p.UserId] = nil
                Fluent:Notify({Title = "Friends", Content = "❌ Удалён: " .. name, Duration = 3})
                return
            end
        end
        Fluent:Notify({Title = "Friends", Content = "Друг с ником «" .. FriendSearchQuery .. "» не найден.", Duration = 3})
    end
})

Tabs.SocialTab:AddButton({
    Title = "📋 Показать список друзей",
    Description = "",
    Callback = function()
        local list = {}
        for uid, name in pairs(getgenv().AetherFriends) do
            local online = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == uid then online = true break end
            end
            table.insert(list, (online and "🟢 " or "⚫ ") .. name)
        end
        if #list == 0 then
            Fluent:Notify({Title = "Friends", Content = "Список друзей пуст.", Duration = 3})
        else
            Fluent:Notify({Title = "Друзья (" .. #list .. ")", Content = table.concat(list, "\n"), Duration = 10})
        end
    end
})

Tabs.SocialTab:AddButton({
    Title = "🗑️ Очистить всех друзей",
    Description = "",
    Callback = function()
        window:Dialog({
            Title = "Подтверждение",
            Content = "Удалить всех друзей?",
            Buttons = {
                {Title = "Да", Callback = function()
                    getgenv().AetherFriends = {}
                    Fluent:Notify({Title = "Friends", Content = "Список друзей очищен.", Duration = 3})
                end},
                {Title = "Нет", Callback = function() end}
            }
        })
    end
})

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
                        
                        local attackerChar = nil
                        local current = Child.Parent
                        local playerCharsFolder = workspace:FindFirstChild("PlayerCharacters")
                        while current and current ~= workspace do
                            if playerCharsFolder and current.Parent == playerCharsFolder then
                                attackerChar = current
                                break
                            end
                            current = current.Parent
                        end
                        if attackerChar and IsFriend(attackerChar) then return end

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

                        local effectiveDist = GetEffectiveParryDistance(hitboxPart)
                        if dist > effectiveDist then return end

                        DoParryWithCooldownWait(hitboxPos, hitboxPart)
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
        task.spawn(CacheAllAnimations)

        if getgenv().sc2 ~= nil then
            getgenv().sc2:Disconnect()
            getgenv().sc2 = nil
        end

        if getgenv().sc22 ~= nil then
            getgenv().sc22:Disconnect()
            getgenv().sc22 = nil
        end

        getgenv().sc2 = workspace.DescendantAdded:Connect(function(Child)
            pcall(function()
                if Child:IsA('Sound') and (Child.Name == 'Parry' or Child.Name == 'ParrySwing') then
                    local playerChars = Workspace:FindFirstChild("PlayerCharacters")
                    if not playerChars or not Child:IsDescendantOf(playerChars) then return end
                    
                    if not Child:IsDescendantOf(LocalPlayer.Character) and GetDistanceFromPart(Child.Parent) <= AntiParryDistance then
                        local Tool = GetMainWeaponCharacter()
                        if Tool ~= nil then
                            task.spawn(function()
                                Tool.Parent = LocalPlayer.Backpack
                                task.wait()
                                Tool.Parent = LocalPlayer.Character
                            end)
                        end
                    end
                end
            end)
        end)

        getgenv().sc22 = game:GetService('UserInputService').InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                pcall(function()
                    local someoneIsParrying = CheckForAnyParrier(AntiParryDistance)
                    if someoneIsParrying then
                        local Tool = GetMainWeaponCharacter()
                        if Tool ~= nil then
                            task.spawn(function()
                                Tool.Parent = LocalPlayer.Backpack
                                task.wait()
                                Tool.Parent = LocalPlayer.Character
                            end)
                        end
                    end
                end)
            end
        end)

    else
        if getgenv().sc2 ~= nil then
            getgenv().sc2:Disconnect()
            getgenv().sc2 = nil
        end
        if getgenv().sc22 ~= nil then
            getgenv().sc22:Disconnect()
            getgenv().sc22 = nil
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
    Title = "Время кулдауна (сек, фоллбэк)",
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

RunService.Heartbeat:Connect(function()
    if DynamicDistanceEnabled then
        local bonus, _, _ = CalculateDynamicBonus(AutoParryDistance)
        DynamicBonusDistance = bonus
    end
    if WeaponDistDetectEnabled then
        WeaponDetectedRange = GetNearestEnemyHitboxRange()
    end
end)

SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("AetherHub/CombatWarriors")
SaveManager:BuildConfigSection(Tabs.ConfigTab)

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

Tabs.CombatTab:AddParagraph({
    Title = "Aim",
    Content = "Автоматически наводит камеру на голову ближайшего врага."
})

local AimToggle = Tabs.CombatTab:AddToggle("AimToggle", { Title = "Aim (на голову)", Default = false })

local AimPredictToggle = Tabs.CombatTab:AddToggle("AimPredictToggle", { Title = "Predict (предикт движения)", Default = false })

local AimWallCheckToggle = Tabs.CombatTab:AddToggle("AimWallCheckToggle", { Title = "Wall Check (не целиться через стены)", Default = true })

local AimSmoothnessValue = 0
local AimWallCheckEnabled = true

local AimSmoothnessInput = Tabs.CombatTab:AddInput("AimSmoothnessInput", {
    Title = "Smoothness (0 = мгновенно, 1.5 = плавно)",
    Default = "0",
    Placeholder = "0",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            AimSmoothnessValue = math.clamp(num, 0, 1.5)
        end
    end
})

local AimPredictInput = Tabs.CombatTab:AddInput("AimPredictInput", {
    Title = "Predict Value (0.1 — 1.0)",
    Default = "0.3",
    Placeholder = "0.3",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            AimPredictValue = math.clamp(num, 0.05, 1.0)
        end
    end
})

local AimDistInput = Tabs.CombatTab:AddInput("AimDistInput", {
    Title = "Макс. дистанция Aim (studs)",
    Default = "100",
    Placeholder = "100",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 5 then
            AimMaxDistance = num
        end
    end
})

local AimToggleBind = Tabs.CombatTab:AddKeybind("AimToggleBind", {
    Title = "Бинд Aim",
    Mode = "Toggle",
    Default = "P",
    Callback = function(Value)
        Options.AimToggle:SetValue(not Options.AimToggle.Value)
        if Options.AimToggle.Value then
            Fluent:Notify({ Title = "Aether Hub", Content = "Aim ВКЛЮЧЁН.", Duration = 2 })
        else
            Fluent:Notify({ Title = "Aether Hub", Content = "Aim выключен.", Duration = 2 })
        end
    end,
})

AimPredictToggle:OnChanged(function()
    AimPredictEnabled = Options.AimPredictToggle.Value
end)

AimWallCheckToggle:OnChanged(function()
    AimWallCheckEnabled = Options.AimWallCheckToggle.Value
end)

local function AimIsVisibleTarget(fromPos, targetPos, targetChar)
    if not AimWallCheckEnabled then return true end

    local filter = {}
    
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end
    
    local playerChars = Workspace:FindFirstChild("PlayerCharacters")
    if playerChars then
        table.insert(filter, playerChars)
    end
    
    if Workspace:FindFirstChild("EffectsJunk") then table.insert(filter, Workspace.EffectsJunk) end
    if Workspace:FindFirstChild("Junk") then table.insert(filter, Workspace.Junk) end
    if Workspace:FindFirstChild("Projectiles") then table.insert(filter, Workspace.Projectiles) end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true
    params.RespectCanCollide = true

    local dir = targetPos - fromPos
    local ray = Workspace:Raycast(fromPos, dir, params)

    if not ray then return true end

    local hitDist = (ray.Position - fromPos).Magnitude
    local targetDist = dir.Magnitude
    return hitDist >= targetDist * 0.85
end

AimToggle:OnChanged(function()
    AimEnabled = Options.AimToggle.Value

    if AimEnabled then
        if AimConnection then AimConnection:Disconnect() end

        RunService:BindToRenderStep("AetherAim", Enum.RenderPriority.Camera.Value + 1, function()
            if not AimEnabled then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end

            local nearestChar = nil
            local nearestDist = AimMaxDistance + 1

            local playerChars = Workspace:FindFirstChild("PlayerCharacters")
            if not playerChars then return end

            local cam = workspace.CurrentCamera
            if not cam then return end

            for _, pChar in ipairs(playerChars:GetChildren()) do
                if pChar ~= char and not IsFriend(pChar) then
                    local eHrp = pChar:FindFirstChild("HumanoidRootPart")
                    local eHum = pChar:FindFirstChild("Humanoid")
                    local eHead = pChar:FindFirstChild("Head")
                    if eHrp and eHum and eHead and eHum.Health > 0 then
                        local dist = (hrp.Position - eHrp.Position).Magnitude
                        if dist < nearestDist and dist <= AimMaxDistance then
                            if AimIsVisibleTarget(cam.CFrame.Position, eHead.Position, pChar) then
                                nearestDist = dist
                                nearestChar = pChar
                            end
                        end
                    end
                end
            end

            if not nearestChar then return end

            local eHead = nearestChar:FindFirstChild("Head")
            local eHrp = nearestChar:FindFirstChild("HumanoidRootPart")
            if not eHead or not eHrp then return end

            local targetPos = eHead.Position

            if AimPredictEnabled then
                local eHum = nearestChar:FindFirstChild("Humanoid")
                if eHum then
                    local moveDir = eHum.MoveDirection
                    if moveDir.Magnitude > 0.1 then
                        local velocity = eHrp.AssemblyLinearVelocity
                        targetPos = targetPos + velocity * AimPredictValue
                    end
                end
            end

            if AimSmoothnessValue <= 0.01 then
                cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
            else
                local currentLook = cam.CFrame.LookVector
                local desiredLook = (targetPos - cam.CFrame.Position).Unit
                local alpha = math.clamp(1 - AimSmoothnessValue, 0.05, 1)
                local smoothed = currentLook:Lerp(desiredLook, alpha)
                cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + smoothed)
            end
        end)

        AimConnection = {Disconnect = function()
            pcall(function() RunService:UnbindFromRenderStep("AetherAim") end)
        end}
    else
        if AimConnection then
            AimConnection:Disconnect()
            AimConnection = nil
        end
    end
end)

local PerfectHitToggle = Tabs.CombatTab:AddToggle("PerfectHitToggle", { Title = "Perfect Hit (100% Hit)", Default = false })

local PH_IsSwinging = false
local PH_HitCache = {}
local PH_AnimConns = {}
local PH_CharAddedConn = nil

local function PerfectHitForceDamage(targetCharacter, tool)
    local char = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local myHitbox = tool:FindFirstChild("Hitboxes") and tool.Hitboxes:FindFirstChild("Hitbox")
    if myHitbox and not myHitbox:IsA("BasePart") then
        for _, sub in ipairs(myHitbox:GetChildren()) do
            if sub:IsA("BasePart") then myHitbox = sub break end
        end
    end
    if not myHitbox then myHitbox = tool:FindFirstChild("Hitbox") or tool:FindFirstChild("Handle") end
    if not myHitbox then return end

    local enemyHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
    local enemyHitPart = targetCharacter:FindFirstChild("Torso") or enemyHrp
    if not enemyHitPart then return end

    local oldId = getthreadidentity()
    setthreadidentity(2)

    local hitPos = enemyHitPart.Position
    local relHitPos = enemyHitPart.CFrame:ToObjectSpace(CFrame.new(hitPos))
    local lookVec = myHrp.CFrame.LookVector
    local hitDir = (enemyHitPart.Position - myHrp.Position).Unit
    local hitNormal = Vector3.new(0, 1, 0)

    local lastSlash = tool:GetAttribute("LastSlashTick") or tick()
    local swingDelay = tick() - lastSlash
    if swingDelay < 0 or swingDelay > 1 then swingDelay = 0.15 end

    Network:FireServer(
        "MeleeDamage",
        tool,
        enemyHitPart,
        myHitbox,
        hitPos,
        relHitPos,
        lookVec,
        hitDir,
        hitNormal,
        swingDelay
    )

    setthreadidentity(oldId)
end

RunService.Heartbeat:Connect(function()
    if not Options.PerfectHitToggle or not Options.PerfectHitToggle.Value then return end
    if not PH_IsSwinging then return end

    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool:GetAttribute("ItemType") ~= "weapon" then return end

    local myHitbox = tool:FindFirstChild("Hitboxes") and tool.Hitboxes:FindFirstChild("Hitbox")
    if myHitbox and not myHitbox:IsA("BasePart") then
        for _, sub in ipairs(myHitbox:GetChildren()) do
            if sub:IsA("BasePart") then myHitbox = sub break end
        end
    end
    if not myHitbox then myHitbox = tool:FindFirstChild("Hitbox") or tool:FindFirstChild("Handle") end
    if not myHitbox then return end

    local playerChars = Workspace:FindFirstChild("PlayerCharacters")
    if not playerChars then return end

    for _, enemyChar in ipairs(playerChars:GetChildren()) do
        if enemyChar ~= char and not PH_HitCache[enemyChar] then
            
            if IsFriend(enemyChar) then continue end

            local eHum = enemyChar:FindFirstChild("Humanoid")
            local eTorso = enemyChar:FindFirstChild("Torso") or enemyChar:FindFirstChild("HumanoidRootPart")

            if eHum and eHum.Health > 0 and eTorso then
                local dist = (myHitbox.Position - eTorso.Position).Magnitude
                local maxDist = (myHitbox.Size.Magnitude / 2) + (eTorso.Size.Magnitude / 2) + 3

                if dist <= maxDist then
                    PH_HitCache[enemyChar] = true
                    task.spawn(PerfectHitForceDamage, enemyChar, tool)
                end
            end
        end
    end
end)

local function HookPerfectHitAnimator(char)
    for _, conn in ipairs(PH_AnimConns) do conn:Disconnect() end
    PH_AnimConns = {}
    PH_IsSwinging = false
    PH_HitCache = {}

    local hum = char:WaitForChild("Humanoid", 5)
    local animator = hum and hum:WaitForChild("Animator", 5)
    if not animator then return end

    local animConn = animator.AnimationPlayed:Connect(function(animTrack)
        if not Options.PerfectHitToggle.Value then return end

        local startConn, stopConn, endConn

        startConn = animTrack:GetMarkerReachedSignal("startHitDetection"):Connect(function()
            PH_IsSwinging = true
            PH_HitCache = {}
        end)

        stopConn = animTrack:GetMarkerReachedSignal("stopHitDetection"):Connect(function()
            PH_IsSwinging = false
        end)

        endConn = animTrack.Stopped:Connect(function()
            PH_IsSwinging = false
            if startConn then startConn:Disconnect() end
            if stopConn then stopConn:Disconnect() end
            if endConn then endConn:Disconnect() end
        end)

        table.insert(PH_AnimConns, startConn)
        table.insert(PH_AnimConns, stopConn)
        table.insert(PH_AnimConns, endConn)
    end)
    table.insert(PH_AnimConns, animConn)
end

PerfectHitToggle:OnChanged(function()
    local val = Options.PerfectHitToggle.Value
    if val then
        if LocalPlayer.Character then
            HookPerfectHitAnimator(LocalPlayer.Character)
        end
        if not PH_CharAddedConn then
            PH_CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
                HookPerfectHitAnimator(char)
            end)
        end
    else
        PH_IsSwinging = false
        for _, conn in ipairs(PH_AnimConns) do conn:Disconnect() end
        PH_AnimConns = {}
        if PH_CharAddedConn then
            PH_CharAddedConn:Disconnect()
            PH_CharAddedConn = nil
        end
    end
end)

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
    Title = "Авто-фарм",
    Content = ""
})

local LegitAutoFarm = Tabs.MiscTab:AddToggle("LegitAutoFarm", { Title = "Legit AutoFarm", Default = false })

local AutoFarmRunning = false
local PathfindingService = game:GetService("PathfindingService")
local AF_ShiftHeld = false
local AF_LastPos = nil
local AF_StuckTimer = 0
local AF_StuckTarget = nil

local function IsInMainMenu()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return true end
    local roact = pg:FindFirstChild("RoactUI")
    if not roact then return false end
    return roact:FindFirstChild("MainMenu") ~= nil
end

local function TryRespawn()
    pcall(function()
        local m = require(ReplicatedStorage.Client.Source.Spawn.SpawnHandlerClient)
        m.spawnCharacter(true)
    end)
end

local function AF_EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end

    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("ItemType") == "weapon" then
            return
        end
    end

    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("ItemType") == "weapon" then
            local hasHitbox = v:FindFirstChild("Hitboxes") or v:FindFirstChild("Hitbox")
            if hasHitbox then
                v.Parent = char
                return
            end
        end
    end

    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("ItemType") == "weapon" then
            v.Parent = char
            return
        end
    end
end

local function AF_GetNearestEnemy(excludeChar)
    local char = LocalPlayer.Character
    if not char then return nil, 9999 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, 9999 end

    local nearestChar = nil
    local nearestDist = 9999

    local playerChars = Workspace:FindFirstChild("PlayerCharacters")
    if not playerChars then return nil, 9999 end

    for _, pChar in ipairs(playerChars:GetChildren()) do
        if pChar ~= char and pChar ~= excludeChar then
            local eHrp = pChar:FindFirstChild("HumanoidRootPart")
            local eHum = pChar:FindFirstChild("Humanoid")
            if eHrp and eHum and eHum.Health > 0 then
                local dist = (hrp.Position - eHrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestChar = pChar
                end
            end
        end
    end

    return nearestChar, nearestDist
end

local function AF_ManageSprint()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vel = hrp.AssemblyLinearVelocity
    local flatSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    if flatSpeed < 26.56 then
        if not AF_ShiftHeld then
            keypress(0x10)
            AF_ShiftHeld = true
        end
    end
end

local function AF_StopAllMovement()
    pcall(function()
        keyrelease(0x57)
        keyrelease(0x53)
        keyrelease(0x41)
        keyrelease(0x44)
        if AF_ShiftHeld then
            keyrelease(0x10)
            AF_ShiftHeld = false
        end
    end)
end

local function AF_SimulateMovement(direction)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local forward = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
    if forward.Magnitude < 0.01 then return end
    forward = forward.Unit

    local right = camera.CFrame.RightVector * Vector3.new(1, 0, 1)
    if right.Magnitude < 0.01 then return end
    right = right.Unit

    local dot_f = direction:Dot(forward)
    local dot_r = direction:Dot(right)

    if dot_f > 0.3 then keypress(0x57) else keyrelease(0x57) end
    if dot_f < -0.3 then keypress(0x53) else keyrelease(0x53) end
    if dot_r > 0.3 then keypress(0x44) else keyrelease(0x44) end
    if dot_r < -0.3 then keypress(0x41) else keyrelease(0x41) end

    AF_ManageSprint()
end

local function AF_DoAttack()
    mouse1press()
    task.wait(0.005 + math.random() * 0.02)
    mouse1release()
end

local function AF_WalkToTarget(targetPos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 7.2,
        AgentMaxSlope = 45,
    })

    local pathSuccess = false
    pcall(function()
        path:ComputeAsync(hrp.Position, targetPos)
        if path.Status == Enum.PathStatus.Success then
            pathSuccess = true
        end
    end)

    if pathSuccess then
        local waypoints = path:GetWaypoints()

        for i = 2, #waypoints do
            if not Options.LegitAutoFarm.Value or not AutoFarmRunning then
                AF_StopAllMovement()
                return false
            end

            local char2 = LocalPlayer.Character
            local hum2 = char2 and char2:FindFirstChild("Humanoid")
            local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
            if not char2 or not hum2 or hum2.Health <= 0 or not hrp2 then
                AF_StopAllMovement()
                return false
            end

            local _, curEnemyDist = AF_GetNearestEnemy(nil)
            if curEnemyDist and curEnemyDist <= 12 then
                AF_StopAllMovement()
                return true
            end

            local wp = waypoints[i]
            local wpPos = wp.Position

            if wp.Action == Enum.PathWaypointAction.Jump then
                keypress(0x20)
                task.wait(0.05)
                keyrelease(0x20)
            end

            local timeout = 0
            while timeout < 3 do
                if not Options.LegitAutoFarm.Value or not AutoFarmRunning then
                    AF_StopAllMovement()
                    return false
                end

                local hrp3 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp3 then
                    AF_StopAllMovement()
                    return false
                end

                local flatDist = (Vector3.new(hrp3.Position.X, 0, hrp3.Position.Z) - Vector3.new(wpPos.X, 0, wpPos.Z)).Magnitude
                if flatDist < 3 then break end

                local dir = Vector3.new(wpPos.X, 0, wpPos.Z) - Vector3.new(hrp3.Position.X, 0, hrp3.Position.Z)
                if dir.Magnitude > 0.01 then
                    AF_SimulateMovement(dir.Unit)
                end

                if hrp3.Position.Y < wpPos.Y - 1.5 then
                    keypress(0x20)
                    task.wait(0.05)
                    keyrelease(0x20)
                end

                AF_EquipWeapon()

                RunService.Heartbeat:Wait()
                timeout = timeout + (1/60)
            end
        end

        AF_StopAllMovement()
        return true
    end

    return false
end

local function AF_IsStuck()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local curPos = hrp.Position

    if AF_LastPos then
        local moved = (Vector3.new(curPos.X, 0, curPos.Z) - Vector3.new(AF_LastPos.X, 0, AF_LastPos.Z)).Magnitude
        if moved < 5 then
            AF_StuckTimer = AF_StuckTimer + 0.05
        else
            AF_StuckTimer = 0
        end
    end

    AF_LastPos = curPos
    return AF_StuckTimer >= 3.5
end

local function AF_ResetStuck()
    AF_StuckTimer = 0
    AF_LastPos = nil
end

local function AF_DirectWalk(targetPos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dir = Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
    if dir.Magnitude > 0.01 then
        AF_SimulateMovement(dir.Unit)
    end

    if hrp.Position.Y < targetPos.Y - 1 then
        keypress(0x20)
        task.wait(0.05)
        keyrelease(0x20)
    end
end

LegitAutoFarm:OnChanged(function()
    local val = Options.LegitAutoFarm.Value
    if val == true and not AutoFarmRunning then
        AutoFarmRunning = true

        if not AutoParryToggleValue then
            Options.AutoParryToggle:SetValue(true)
        end

        task.spawn(function()
            while Options.LegitAutoFarm.Value and AutoFarmRunning do

                if IsInMainMenu() then
                    AF_StopAllMovement()
                    AF_ResetStuck()
                    TryRespawn()
                    task.wait(5)
                    continue
                end

                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if not char or not hum or hum.Health <= 0 or not hrp then
                    AF_StopAllMovement()
                    AF_ResetStuck()
                    task.wait(1)
                    continue
                end

                if not AutoParryToggleValue then
                    Options.AutoParryToggle:SetValue(true)
                end
                if not AntiParryToggleValue then
                    Options.AntiParryToggle:SetValue(true)
                end

                AF_EquipWeapon()

                if AF_IsStuck() then
                    AF_StopAllMovement()
                    AF_ResetStuck()
                    AF_StuckTarget = AF_StuckTarget or nil

                    local enemyChar, _ = AF_GetNearestEnemy(AF_StuckTarget)
                    if enemyChar then
                        AF_StuckTarget = enemyChar
                    else
                        AF_StuckTarget = nil
                    end
                    task.wait(0.3)
                    continue
                end

                local enemyChar, enemyDist
                if AF_StuckTarget then
                    local eHrp = AF_StuckTarget:FindFirstChild("HumanoidRootPart")
                    local eHum = AF_StuckTarget:FindFirstChild("Humanoid")
                    if eHrp and eHum and eHum.Health > 0 and AF_StuckTarget.Parent then
                        enemyChar = AF_StuckTarget
                        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        enemyDist = myHrp and (myHrp.Position - eHrp.Position).Magnitude or 9999
                    else
                        AF_StuckTarget = nil
                        enemyChar, enemyDist = AF_GetNearestEnemy(nil)
                    end
                else
                    enemyChar, enemyDist = AF_GetNearestEnemy(nil)
                end

                if not enemyChar then
                    AF_StopAllMovement()
                    AF_ResetStuck()
                    task.wait(0.5)
                    continue
                end

                local eHrp = enemyChar:FindFirstChild("HumanoidRootPart")
                if not eHrp then
                    AF_StopAllMovement()
                    task.wait(0.3)
                    continue
                end

                if enemyDist <= 10 then
                    AF_ResetStuck()
                    AF_StuckTarget = nil

                    local dir = Vector3.new(eHrp.Position.X, 0, eHrp.Position.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
                    if dir.Magnitude > 0.01 then
                        AF_SimulateMovement(dir.Unit)
                    end

                    AF_DoAttack()
                    task.wait(0.08 + math.random() * 0.07)
                    continue
                end

                local targetPos = eHrp.Position
                local reached = AF_WalkToTarget(targetPos)

                if not reached then
                    AF_DirectWalk(targetPos)
                    task.wait(0.3)
                    AF_StopAllMovement()
                end

                task.wait(0.05)
            end

            AF_StopAllMovement()
            AF_ResetStuck()
            AF_StuckTarget = nil
            AutoFarmRunning = false
        end)
    elseif val == false then
        AutoFarmRunning = false
        AF_StopAllMovement()
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
