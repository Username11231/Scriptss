local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local function ESP(Target)

    local a = Instance.new("BoxHandleAdornment")
    a.Name = Target.Name.."_PESP"
    a.Parent = Target
    a.Adornee = Target
    a.AlwaysOnTop = true
    a.ZIndex = 0
    a.Color3 = Color3.fromRGB(255, 0, 0)
    a.Transparency = 0.5
    a.Size = Vector3.new(2, 5, 1)
    local BillboardGui = Instance.new("BillboardGui")
    local TextLabel = Instance.new("TextLabel")
    local ESPholder = Instance.new("Folder")
    ESPholder.Name = Target.Name..'_ESP'
    ESPholder.Parent = game:GetService('CoreGui')
    BillboardGui.Adornee = Target
    BillboardGui.Name = Target.Name
    BillboardGui.Parent = ESPholder
    BillboardGui.Size = UDim2.new(0, 100, 0, 150)
    BillboardGui.StudsOffset = Vector3.new(0, -1, 0)
    BillboardGui.AlwaysOnTop = true
    TextLabel.Parent = BillboardGui
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0, 0, 0, -50)
    TextLabel.Size = UDim2.new(0, 100, 0, 100)
    TextLabel.Font = Enum.Font.SourceSansSemibold
    TextLabel.TextSize = 20
    TextLabel.TextColor3 = Color3.fromRGB(255, 25, 25)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    TextLabel.Text = Target.Name
    TextLabel.ZIndex = 10

end


local function UNESP(TargetName, Folder)
    if game:GetService('CoreGui'):FindFirstChild(TargetName..'_ESP') then
        game:GetService('CoreGui'):FindFirstChild(TargetName..'_ESP'):Destroy()
    end

    for i,v in pairs(Folder:GetChildren()) do
        if v.Name == TargetName then
            if v:FindFirstChild(TargetName..'_PESP') then
                v:FindFirstChild(TargetName..'_PESP'):Destroy()
            end
        end
    end

end


local window = Fluent:CreateWindow({
    Title = "Residence Massacre by N&C",
    SubTitle = "v0.0.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    MainTab = window:AddTab({ Title = "Main", Icon = "" }),
    HubsTab = window:AddTab({ Title = "Остальное", Icon = "" }),
}

local Options = Fluent.Options


Tabs.MainTab:AddButton({
    Title = "Обойти античит",
    Description = "",
    Callback = function()
        if not AntiCheatBypassed then
            AntiCheatBypassed = true
            loadstring(game:HttpGet("https://pastebin.com/raw/YR67Ndis"))()
            task.wait()
			Fluent:Notify({
            Title = "Успех",
        	Content = "Античит изи обойден!",
            SubContent = "",
            Duration = 3
            })
        end
  end
})

Tabs.MainTab:AddButton({
    Title = "Хукнуть прыжок (без кд и траты стамины)",
    Description = "",
    Callback = function()
        if AntiCheatBypassed then

		for _, connection in ipairs(getconnections(game:GetService("UserInputService").JumpRequest)) do
			if connection.Function then
				local info = getinfo(connection.Function)
				if info then
					print(info.source)
					connection:Disable()
					print('изи')
				end
			end
		end
		
		else
			Fluent:Notify({
            Title = "Ошибка",
        	Content = "Сначала обойди античит",
            SubContent = "",
            Duration = 3
            })
        end
  end
})


local InfiniteBreath = Tabs.MainTab:AddToggle("InfiniteBreath", {Title = "Бесконечный оксиген (Луп)", Default = false })

InfiniteBreath:OnChanged(function()
    isInfiniteBreathEnabled = Options.InfiniteBreath.Value
    

   if isInfiniteBreathEnabled == true then

        while isInfiniteBreathEnabled do

            game.Players.LocalPlayer.Character.Breath:SetAttribute('Max', 21)
            game.Players.LocalPlayer.Character.Breath.Value = 21
            game:GetService("Lighting").Blur.Enabled = false
            workspace.Sounds.HeavyBreath.Playing = false


            task.wait()
        end


    else

        game.Players.LocalPlayer.Character.Breath:SetAttribute('Max', 20)

        if game.Players.LocalPlayer.Character.Breath.Value > game.Players.LocalPlayer.Character.Breath:GetAttribute('Max') then
            game.Players.LocalPlayer.Character.Breath.Value = game.Players.LocalPlayer.Character.Breath:GetAttribute('Max')
            else
            game.Players.LocalPlayer.Character.Breath.Value = game.Players.LocalPlayer.Character.Breath.Value
        end

   end
end)

local InfiniteSprint = Tabs.MainTab:AddToggle("InfiniteSprint", {Title = "Бесконечный спринт (Луп)", Default = false })

InfiniteSprint:OnChanged(function()
    isInfiniteSprintEnabled = Options.InfiniteSprint.Value
    

   if isInfiniteSprintEnabled == true then

        while isInfiniteSprintEnabled do

            game.Players.LocalPlayer.Character.Sprint.Stam:SetAttribute('Max', 6)
           game.Players.LocalPlayer.Character.Sprint.Stam.Value = 6


            task.wait()
        end


    else

       game.Players.LocalPlayer.Character.Sprint.Stam:SetAttribute('Max', 5)

        if game.Players.LocalPlayer.Character.Sprint.Stam.Value > game.Players.LocalPlayer.Character.Sprint.Stam:GetAttribute('Max') then
            game.Players.LocalPlayer.Character.Sprint.Stam.Value = game.Players.LocalPlayer.Character.Sprint.Stam:GetAttribute('Max')
        else
            game.Players.LocalPlayer.Character.Sprint.Stam.Value = game.Players.LocalPlayer.Character.Sprint.Stam.Value
        end

   end
end)

local ThirdPersonLoop = Tabs.MainTab:AddToggle("ThirdPersonLoop", {Title = "Третье лицо луп", Default = false })

ThirdPersonLoop:OnChanged(function()
    ThirdPersonLoopEnabled = Options.ThirdPersonLoop.Value
        while ThirdPersonLoopEnabled do
			if ThirdPersonLoopEnabled == true then
				game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
			else
				break
			end
            task.wait()
        end
end)

local AutoVoteSkipNight = Tabs.MainTab:AddToggle("AutoVoteSkipNight", {Title = "Авто-голос за скип ночи", Default = false })

AutoVoteSkipNight:OnChanged(function()
    AutoVoteSkipNightEnabled = Options.AutoVoteSkipNight.Value
        while AutoVoteSkipNightEnabled do
			if AutoVoteSkipNightEnabled == false then
				break
			end
			if AutoVoteSkipNightEnabled == true and workspace:FindFirstChild('BedSkip') and workspace:FindFirstChild('BedSkip'):FindFirstChild('ClickDetector') and workspace:FindFirstChild('BedSkip'):FindFirstChild('ClickDetector').MaxActivationDistance > 0 then
				fireclickdetector(workspace.BedSkip.ClickDetector)
			end
            task.wait()
        end
end)

local MutantESP = Tabs.MainTab:AddToggle("MutantESP", {Title = "Подсветка монстра", Default = false })

MutantESP:OnChanged(function()

    if Options.MutantESP.Value == true then
        if not AntiCheatBypassed then Fluent:Notify({Title = "ERROR",Content = "Обойди античит сначала",SubContent = "",Duration = 1}) Options.MutantESP:SetValue(false) return end
    end

    isMutantESPEnabled = Options.MutantESP.Value
    

   if isMutantESPEnabled == true then

        while isMutantESPEnabled do

            if workspace:FindFirstChild('Mutant') and not workspace:FindFirstChild('Mutant'):FindFirstChild('Mutant_PESP') then
                ESP(workspace.Mutant)
            end


            task.wait()
        end


    else
    if not AntiCheatBypassed then return end
    if workspace:FindFirstChild('Mutant') then
        UNESP('Mutant', workspace)
    end
   end
end)

local MonsterNotify = Tabs.MainTab:AddToggle("MonsterNotify", {Title = "Уведомление о монстре", Default = false })

local MonsterNotifyFunc = nil
local MonsterNotifyFunc2 = nil

MonsterNotify:OnChanged(function()
if Options.MonsterNotify.Value == true then

    --if not AntiCheatBypassed then Fluent:Notify({Title = "ERROR",Content = "Обойди античит сначала",SubContent = "",Duration = 1}) Options.MonsterNotify:SetValue(false) return end
    
    if MonsterNotifyFunc == nil then
        MonsterNotifyFunc = workspace.ChildAdded:Connect(function(child)
            if child.Name == 'Mutant' then
                Fluent:Notify({
                Title = "УВЕДОМЛЕНИЕ",
                 Content = "МОНСТР ЗАСПАВНИЛСЯ",
                SubContent = "",
                Duration = 3
                })
            end
        end)
    end

    if MonsterNotifyFunc2 == nil then
        MonsterNotifyFunc2 = workspace.ChildRemoved:Connect(function(child)
            if child.Name == 'Mutant' then
                Fluent:Notify({
                Title = "УВЕДОМЛЕНИЕ",
                 Content = "МОНСТР ПРОПАЛ",
                SubContent = "",
                Duration = 3
                })
            end
        end)
    end

    else
    --if not AntiCheatBypassed then return end
    if MonsterNotifyFunc ~= nil then
        MonsterNotifyFunc:Disconnect()
        MonsterNotifyFunc = nil
        MonsterNotifyFunc2:Disconnect()
        MonsterNotifyFunc2 = nil
    end
   end

end)

local loopfb = Tabs.MainTab:AddToggle("loopfb", {Title = "loopfb", Description = "Типа фуллбрайт светло", Default = false })

loopfb:OnChanged(function()


    isloopfbEnabled = Options.loopfb.Value
    

   if isloopfbEnabled == true then

        while isloopfbEnabled do
            local Lighting = game.Lighting
            Lighting.Brightness = 2
		    Lighting.ClockTime = 14
		    Lighting.FogEnd = 100000
		    Lighting.GlobalShadows = false
		    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.FogEnd = 100000
			for i,v in pairs(Lighting:GetChildren()) do
				if v:IsA("Atmosphere") then
					v:Destroy()
				end
			end
			task.wait()
        end

   end
end)

local NoTemperature = Tabs.MainTab:AddToggle("NoTemperature", {Title = "Отключить скрипт на температуру (Замерзание)", Default = false})

NoTemperature:OnChanged(function()
if Options.NoTemperature.Value == true then

    game.Players.LocalPlayer.Character.Temperature.Enabled = false

else

    game.Players.LocalPlayer.Character.Temperature.Enabled = true

end

end)


local WalkAnimations = Tabs.MainTab:AddDropdown("WalkAnimations", {
        Title = "Анимации ходьбы",
        Values = {"Обычная", "Мутационная", "Раненный"},
        Multi = false,
        Default = 1,
})

WalkAnimations:OnChanged(function(value)
    if value == 'Обычная' then
        game.Players.LocalPlayer.Character.Animate.run.RunAnim.AnimationId = 'http://www.roblox.com/asset/?id=180426354'
        game.Players.LocalPlayer.Character.Animate.walk.WalkAnim.AnimationId = 'http://www.roblox.com/asset/?id=180426354'
    elseif value == 'Мутационная' then
        game.Players.LocalPlayer.Character.Animate.run.RunAnim.AnimationId = 'rbxassetid://105959612864729'
        game.Players.LocalPlayer.Character.Animate.walk.WalkAnim.AnimationId = 'rbxassetid://105959612864729'
    elseif value == 'Раненный' then
        game.Players.LocalPlayer.Character.Animate.run.RunAnim.AnimationId = 'rbxassetid://125185181472929'
        game.Players.LocalPlayer.Character.Animate.walk.WalkAnim.AnimationId = 'rbxassetid://125185181472929'

    end
end)

Tabs.MainTab:AddParagraph({
    Title = "Нелегитные функции",
    Content = "Ну типа по рейджу гонять окда"
})



local Slider = Tabs.MainTab:AddSlider("SpeedSliderOK", {
        Title = "Скорость игрока",
        Description = "",
        Default = 16,
        Min = 16,
        Max = 75,
        Rounding = 1,
        Callback = function(value)
        if AntiCheatBypassed then
			GWalkSpeed = tonumber(value) >= 0 and tonumber(value) or 16
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value

        else
            if tonumber(value) > 16 then
            Fluent:Notify({
             Title = "ERROR",
             Content = "Обойди античит сначала",
             SubContent = "",
             Duration = 1
             })
            end
        end
        end
    })

    local Slider = Tabs.MainTab:AddSlider("JumpSliderOK", {
        Title = "Сила прыжка игрока",
        Description = "",
        Default = 50,
        Min = 50,
        Max = 75,
        Rounding = 1,
        Callback = function(value)
        if tonumber(value) > 50 and AntiCheatBypassed then
			GJumpPower = tonumber(value) >= 0 and tonumber(value) or 50
            game.Players.LocalPlayer.Character.Humanoid.UseJumpPower = true
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = value

        else
            if tonumber(value) > 50 then
            Fluent:Notify({
             Title = "ERROR",
             Content = "Обойди античит сначала",
             SubContent = "",
             Duration = 1
             })
            end
        end
        end
    })

	local FovSliderSlider = Tabs.MainTab:AddSlider("FovSliderOK", {
		Title = "Хукнуть фов",
		Description = "",
		Default = 70,
		Min = 30,
		Max = 120,
		Rounding = 1,
		Callback = function(fov)
			if not AntiCheatBypassed then
				Fluent:Notify({ Title = "ERROR", Content = "Обойди сначала", SubContent = "", Duration = 1 })
				return
			end
			local n = tonumber(fov)
			if not n then return end

			local G = getgenv()
			G.hooked_fov11 = n
			G.fov_lock_enabled = true

			local RunService = game:GetService("RunService")

			-- вернуть наш FOV, если кто-то его изменил
			local function apply()
				local c = workspace.CurrentCamera
				if c and G.fov_lock_enabled and G.hooked_fov11 and c.FieldOfView ~= G.hooked_fov11 then
					c.FieldOfView = G.hooked_fov11
				end
			end

			-- (пере)подписка на изменение FOV текущей камеры
			local function bindCam()
				if G.fovPropConn then G.fovPropConn:Disconnect() end
				local c = workspace.CurrentCamera
				if not c then return end
				c.FieldOfView = G.hooked_fov11
				G.fovPropConn = c:GetPropertyChangedSignal("FieldOfView"):Connect(apply)
			end

			-- вешаем инфраструктуру один раз
			if not G.fov_lock_bool then
				G.fov_lock_bool = true
				-- смена камеры игрой -> переподписываемся на новую
				G.fovCamConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCam)
				-- страховка каждый кадр после апдейта камеры
				pcall(function() RunService:UnbindFromRenderStep("FovLock11") end)
				RunService:BindToRenderStep("FovLock11", Enum.RenderPriority.Camera.Value + 1, apply)
			end

			bindCam()
		end
	})

    Tabs.HubsTab:AddButton({
    Title = "Infinite Yield",
    Description = "",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})

game:GetService("RunService").RenderStepped:Connect(function()
	if AntiCheatBypassed then
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = GWalkSpeed or 16
		game.Players.LocalPlayer.Character.Humanoid.UseJumpPower = true
		game.Players.LocalPlayer.Character.Humanoid.JumpPower = GJumpPower or 50
	end
end)
