------------ > INITING LOADSTRINGS <-------------------------------------------------------------- 

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScripterNumber/SPVKHUB/refs/heads/main/Fluent"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

------------ > DEPENDENCIES FUNCTIONS <-------------------------------------------------------------- 

function RegisterFunction(t, f, fallback)
	if type(f) == t then 
        return f 
    end

	return fallback
end

------------ > VALIDATING FUNCS <-------------------------------------------------------------- 

firetouchinterest = RegisterFunction("function", firetouchinterest)
replicatesignal = RegisterFunction("function", replicatesignal)
getconnections = RegisterFunction("function", getconnections or get_signal_cons)
hookfunction = RegisterFunction("function", hookfunction)
hookmetamethod = RegisterFunction("function", hookmetamethod)
getnamecallmethod = RegisterFunction("function", getnamecallmethod or get_namecall_method)
checkcaller = RegisterFunction("function", checkcaller, function() return false end)
newcclosure = RegisterFunction("function", newcclosure)
getgc = RegisterFunction("function", getgc or get_gc_objects)

------------ > SERVICES & LOCALS <-------------------------------------------------------------- 

local Workspace = game:GetService('Workspace')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local Lighting = game:GetService('Lighting')

local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild('Humanoid')
local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')

local github_base = "https://raw.githubusercontent.com/ScripterNumber/Assets/main/assets/"

local assets_table = {
	"skeet.wav",
}

local loaded_assets = {}

if makefolder and isfolder and writefile and isfile then
	pcall(function()
		if not isfolder("rakoofmenuscript") then makefolder("rakoofmenuscript") end
		if not isfolder("rakoofmenuscript/assets") then makefolder("rakoofmenuscript/assets") end
		
		for _, filename in ipairs(assets_table) do
			local path = "rakoofmenuscript/assets/" .. filename
			if not isfile(path) then
				local url = github_base .. filename
				local success, data = pcall(game.HttpGet, game, url)
				if success and data and #data > 0 then
					writefile(path, data)
					print("Downloaded:", filename)
				end
			end
		end
	end)
end

local function getcustomasset(filename)
	local path = "rakoofmenuscript/assets/" .. filename
	
	if loaded_assets[filename] then
		return loaded_assets[filename]
	end
	
	if isfile and isfile(path) then
		if getsynasset then
			loaded_assets[filename] = getsynasset(path)
			return loaded_assets[filename]
		elseif getcustomasset then
			loaded_assets[filename] = getcustomasset(path)
			return loaded_assets[filename]
		end
	end
	
	return github_base .. filename
end

local function esp_item(part : BasePart, texts, color)
	if part ~= nil and not part:FindFirstChild('espi') then
		local succ, err = pcall(function()
			local esph = Instance.new('Highlight', part)
			esph.Adornee = part
			esph.Name = 'espi'
			esph.FillColor = color ~= nil and color or Color3.fromRGB(255, 255, 255)
			local bb = Instance.new('BillboardGui', esph)
			bb.Adornee = part
			bb.Name = 'bb'
			bb.AlwaysOnTop = true
			bb.SizeOffset = Vector2.new(0, 2)
			bb.Size = UDim2.new(7, 50, 1, 8)
			local text = Instance.new('TextLabel', bb)
			text.Text = texts or 'Item'
			text.TextScaled = true
			text.BackgroundTransparency = 1
			text.Size = UDim2.new(1, 0, 1, 0)
			text.TextColor3 = color ~= nil and color or Color3.fromRGB(255, 255, 255)
			text.TextStrokeTransparency = 0
		end)
		if not succ then warn(err) end
	end
end

local function unesp_item(part : BasePart)
	if part ~= nil then
		pcall(function()
			if part:FindFirstChild('espi') then
				part:FindFirstChild('espi'):Destroy()
			end
		end)
	end
end

if getgenv().CharacterAddedConnection ~= nil then
    getgenv().CharacterAddedConnection:Disconnect()
    getgenv().CharacterAddedConnection = nil
end

getgenv().CharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(CharacterAddedConnectionChar)
    Character = CharacterAddedConnectionChar
    Humanoid = CharacterAddedConnectionChar:WaitForChild('Humanoid')
    HumanoidRootPart = CharacterAddedConnectionChar:WaitForChild('HumanoidRootPart')
end)

------------ > WINDOWS <-------------------------------------------------------------- 

local window = Fluent:CreateWindow({
    Title = 'The RakOOF',
    SubTitle = "v0.0.1 (BETA)",
    TabWidth = 150,
    Size = UDim2.fromOffset(580, 370),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftAlt
})

------------ > TABS <-------------------------------------------------------------- 

local Tabs = {
    MainTab = window:AddTab({ Title = "Главное", Icon = "" }),
	PlayerTab = window:AddTab({ Title = "Игрок", Icon = "" }),
	MovementTab = window:AddTab({ Title = "Передвижение", Icon = "" }),
	VisualTab = window:AddTab({ Title = "Визуалы", Icon = "" }),
	OtherTab = window:AddTab({ Title = "Остальное", Icon = "" }),
}

------------ > OPTIONS <-------------------------------------------------------------- 

local Options = Fluent.Options

------------ > FUNCTIONS <-------------------------------------------------------------- 

local Funcs = {

    ToRGB = function(C3)
        local r,g,b = C3.R*255, C3.G*255, C3.B*255
        return Color3.fromRGB(r, g, b)
    end,

}

------------ > MAIN <-------------------------------------------------------------- 
------------ > MAIN <-------------------------------------------------------------- 
------------ > MAIN <-------------------------------------------------------------- 
------------ > MAIN <-------------------------------------------------------------- 
------------ > MAIN <-------------------------------------------------------------- 

getgenv().IsAntiCheatBypassed = false
getgenv().IsAntiCheatTryingToBeBypassed = false

Tabs.MainTab:AddButton({
    Title = "Обход клиентского Анти-Чита (BETA)",
    Description = "",
    Callback = function()
	
		if getgenv().IsAntiCheatTryingToBeBypassed == true then return end
		if getgenv().IsAntiCheatBypassed == true then
			Fluent:Notify({Title = "Предупреждение",Content = "Анти-чит уже обойден",Duration = 1})
			return
		end

		getgenv().IsAntiCheatTryingToBeBypassed = true

		local succ, err = pcall(function()
			local a
			a = hookmetamethod(game, '__namecall', function(self, ...)
				if getnamecallmethod() == 'FireServer' and self.Name == "GameEffectHandler" then
					local args = {...}
					warn(' DEBUG - '..self:GetFullName().." tried be fired but prevented")       
					return
				end
				return a(self, ...)
			end)
		end)

		if succ == false then
			Fluent:Notify({
				Title = "Ошибка",
				Content = "Проверь консоль",
				Duration = 2
			})
			warn("ОШИБКА: " .. tostring(err))
			getgenv().IsAntiCheatTryingToBeBypassed = false
		else
			getgenv().IsAntiCheatBypassed = true
			getgenv().IsAntiCheatTryingToBeBypassed = false
			Fluent:Notify({
				Title = "Успешно",
				Content = "Анти-чит был хукнут.",
				Duration = 2
			})
		end

    end
})

local NoFallDamageToggle = Tabs.PlayerTab:AddToggle("NoFallDamageToggle", {Title = "Отключить урон от падения", Description = "Оффает функцию падения по сигнатуре", Default = false})

local signaturefound = false

NoFallDamageToggle:OnChanged(function()
    NoFallDamageToggleValue = Options.NoFallDamageToggle.Value
        
    if NoFallDamageToggleValue == true then

		if Character == nil then
			Fluent:Notify({
				Title = "Ошибка",
				Content = "Твоя персонаж должен существовать.",
				Duration = 2
			})
			Options.NoFallDamageToggle:SetValue(false)
			return
		end

		local connections = getconnections(game.Players.LocalPlayer.Character.Humanoid.StateChanged)
		for i,v in next, connections do
			if v ~= nil and v.Function ~= nil then
				for a,d in pairs(getupvalues(v.Function)) do
					if d ~= nil and typeof(d) == 'Instance' and tostring(d.Name) == 'Events' then
						v:Disable()
					end
				end
			end
		end

		getgenv().NoFallDamageRespawn = LocalPlayer.CharacterAdded:Connect(function(Character)
			game.Players.LocalPlayer.Character:WaitForChild('Humanoid')
			task.wait()

			task.spawn(function()
				local isDisabledSucc = false
				repeat task.wait(0.05)
					local connections = getconnections(game.Players.LocalPlayer.Character.Humanoid.StateChanged)
					for i,v in next, connections do
						if v ~= nil and v.Function ~= nil then
							for a,d in pairs(getupvalues(v.Function)) do
								if d ~= nil and typeof(d) == 'Instance' and tostring(d.Name) == 'Events' then
									FallDamageFuncHash = getfunctionhash(v.Function)
									v:Disable()
									isDisabledSucc = true
								end
							end
						end
					end
				until isDisabledSucc == true
				isDisabledSucc = nil
			end)	
		
		end)

    else

		if getgenv().NoFallDamageRespawn ~= nil then
			getgenv().NoFallDamageRespawn:Disconnect()
			getgenv().NoFallDamageRespawn = nil
		end
        
		local connections = getconnections(game.Players.LocalPlayer.Character.Humanoid.StateChanged)
		for i,v in next, connections do
			if v ~= nil and v.Function ~= nil then
				for a,d in pairs(getupvalues(v.Function)) do
					if d ~= nil and typeof(d) == 'Instance' and tostring(d.Name) == 'Events' then
						FallDamageFuncHash = getfunctionhash(v.Function)
						v:Enable()
					end
				end
			end
		end

    end
end)

local InfiniteStaminaToggle = Tabs.MovementTab:AddToggle("InfiniteStaminaToggle", {Title = "Бесконечная стамина", Default = false})

InfiniteStaminaToggle:OnChanged(function()
    InfiniteStaminaToggleValue = Options.InfiniteStaminaToggle.Value
        
    if InfiniteStaminaToggleValue == true then
        
		if Character ~= nil then
			Character:SetAttribute("Stamina", 100)
		else
			return
		end

		if getgenv().InfiniteStaminaConnection ~= nil then
			getgenv().InfiniteStaminaConnection:Disconnect()
			getgenv().InfiniteStaminaConnection = nil
		end

		getgenv().StaminaRespawn = LocalPlayer.CharacterAdded:Connect(function(Character)
			if getgenv().InfiniteStaminaConnection ~= nil then
				getgenv().InfiniteStaminaConnection:Disconnect()
				getgenv().InfiniteStaminaConnection = nil
			end
			getgenv().InfiniteStaminaConnection = Character:GetAttributeChangedSignal("Stamina"):Connect(function()
				if Character:GetAttribute("Stamina") < 100 then
					Character:SetAttribute("Stamina", 100)
				end
			end)
		end)

		getgenv().InfiniteStaminaConnection = Character:GetAttributeChangedSignal("Stamina"):Connect(function()
			if Character:GetAttribute("Stamina") < 100 then
				Character:SetAttribute("Stamina", 100)
			end
		end)

    else
        
		if getgenv().InfiniteStaminaConnection ~= nil then
			getgenv().InfiniteStaminaConnection:Disconnect()
			getgenv().InfiniteStaminaConnection = nil
		end

		if getgenv().StaminaRespawn ~= nil then
			getgenv().StaminaRespawn:Disconnect()
			getgenv().StaminaRespawn = nil
		end

    end
end)

local ScrapEspToggle = Tabs.VisualTab:AddToggle("ScrapEspToggle", {Title = "Подсветка скрапов", Default = false})

local function esp_scrap(scrap : BasePart)
	if scrap ~= nil then
		local succ, err = pcall(function()
			local esph = Instance.new('Highlight', scrap.TriggerPart)
			esph.Adornee = scrap
			esph.Name = 'esph'
			local bb = Instance.new('BillboardGui', esph)
			bb.Adornee = scrap
			bb.Name = 'bb'
			bb.AlwaysOnTop = true
			bb.SizeOffset = Vector2.new(0, 2)
			bb.Size = UDim2.new(7, 50, 1, 8)
			local text = Instance.new('TextLabel', bb)
			local isHigh = scrap.Name == 'High' and true or false
			local isMedium = scrap.Name == 'Medium' and true or false
			local isSmall = scrap.Name == 'Small' and true or false

			local scraptype = (isHigh and 'Большой скрап') or (isMedium and 'Средний скрап') or 'Мелкий скрап'
			local scrapcolor = (scraptype == 'Большой скрап' and Color3.fromRGB(255, 210, 145)) or (scraptype == 'Средний скрап' and Color3.fromRGB(119, 205, 114)) or Color3.fromRGB(202, 205, 173)

			esph.FillColor = scrapcolor

			text.Text = scraptype
			text.TextScaled = true
			text.BackgroundTransparency = 1
			text.Size = UDim2.new(1, 0, 1, 0)
			text.TextColor3 = scrapcolor
			text.TextStrokeTransparency = 0
		end)
		if not succ then warn(err) end
	end
end

local function unesp_scrap(scrap : BasePart)
	if scrap ~= nil then
		pcall(function()
			if scrap.TriggerPart:FindFirstChild('esph') then
				scrap.TriggerPart:FindFirstChild('esph'):Destroy()
			end
		end)
	end
end

ScrapEspToggle:OnChanged(function()
    ScrapEspToggleValue = Options.ScrapEspToggle.Value
        
    if ScrapEspToggleValue == true then

		if getgenv().ScrapEspConn ~= nil then
			getgenv().ScrapEspConn:Disconnect()
			getgenv().ScrapEspConn = nil
		end

		getgenv().ScrapEspConn = workspace.Filter.ScrapMetals.ChildAdded:Connect(function(Child)
			if Child:IsA('Model') and Child:FindFirstChild('TriggerPart') then
				esp_scrap(Child)
			end
		end)

		for _,Child in next, workspace.Filter.ScrapMetals:GetChildren() do
			if Child:IsA('Model') and Child:FindFirstChild('TriggerPart') then
				esp_scrap(Child)
			end
		end

    else
        
		if getgenv().ScrapEspConn ~= nil then
			getgenv().ScrapEspConn:Disconnect()
			getgenv().ScrapEspConn = nil
		end

		for _,Child in next, workspace.Filter.ScrapMetals:GetChildren() do
			if Child:IsA('Model') and Child:FindFirstChild('TriggerPart') then
				unesp_scrap(Child)
			end
		end

    end
end)

local ItemsEspToggle = Tabs.VisualTab:AddToggle("ItemsEspToggle", {Title = "Подсветка предметов", Default = false})

if getgenv().ItemsEspConnections ~= nil then for i,v in next, getgenv().ItemsEspConnections do if v ~= nil then v:Disconnect() v = nil end end end
getgenv().ItemsEspConnections = {}

ItemsEspToggle:OnChanged(function()
    ItemsEspToggleValue = Options.ItemsEspToggle.Value
        
    if ItemsEspToggleValue == true then

		for i,v in next, getgenv().ItemsEspConnections do
			if v ~= nil then
				v:Disconnect()
				v = nil
			end
		end

		for i,v in next, workspace.Filter.Givers.Burger:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				esp_item(v, 'Бургер', Color3.fromRGB(255, 215, 95))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Бургер', Color3.fromRGB(255, 215, 95))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Chips:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				esp_item(v, 'Чипсы', Color3.fromRGB(255, 135, 35))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Чипсы', Color3.fromRGB(255, 135, 35))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Coffee:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				esp_item(v, 'Кофе', Color3.fromRGB(255, 205, 205))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Кофе', Color3.fromRGB(255, 205, 205))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Fish:GetChildren() do
			if v.Name == 'Fish' and v.Transparency == 0 then
				esp_item(v, 'Рыба', Color3.fromRGB(155, 255, 164))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Рыба', Color3.fromRGB(155, 255, 164))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Flare:GetChildren() do
			if v.Name == 'Flare' and v.Handle.Transparency == 0 then
				esp_item(v, 'Сигналка', Color3.fromRGB(255, 139, 139))
			end
			getgenv().ItemsEspConnections[v] = v.Handle:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Handle.Transparency == 1 then
					unesp_item(v)
				elseif v.Handle.Transparency == 0 then
					esp_item(v, 'Сигналка', Color3.fromRGB(255, 139, 139))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Pan:GetChildren() do
			if v.ClassName == 'MeshPart' and v.Transparency == 0 then
				esp_item(v, 'Сковорода', Color3.fromRGB(181, 179, 179))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Сковорода', Color3.fromRGB(181, 179, 179))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Slushie:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				esp_item(v, 'Коктейль', Color3.fromRGB(181, 109, 152))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Коктейль', Color3.fromRGB(181, 109, 152))
				end
			end)
		end

		for i,v in next, workspace.Filter.Givers.Taco:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				esp_item(v, 'Тако', Color3.fromRGB(181, 173, 93))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Тако', Color3.fromRGB(181, 173, 93))
				end
			end)
		end

    else

		for i,v in next, getgenv().ItemsEspConnections do
			if v ~= nil then
				v:Disconnect()
				v = nil
			end
		end

		for i,v in next, workspace.Filter.Givers.Burger:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Chips:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Coffee:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Fish:GetChildren() do
			if v.Name == 'Fish' and v.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Flare:GetChildren() do
			if v.Name == 'Flare' and v.Handle.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Pan:GetChildren() do
			if v.ClassName == 'MeshPart' and v.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Slushie:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				unesp_item(v)
			end
		end

		for i,v in next, workspace.Filter.Givers.Taco:GetChildren() do
			if v.Name == 'Handle' and v.Transparency == 0 then
				unesp_item(v)
			end
		end
	
	end
        
end)

local CoinsEspToggle = Tabs.VisualTab:AddToggle("CoinsEspToggle", {Title = "Подсветка коинов", Default = false})

if getgenv().CoinsEspConnections ~= nil then for i,v in next, getgenv().ItemsEspConnections do if v ~= nil then v:Disconnect() v = nil end end end
getgenv().CoinsEspConnections = {}

CoinsEspToggle:OnChanged(function()
    CoinsEspToggleValue = Options.CoinsEspToggle.Value
        
    if CoinsEspToggleValue == true then

		for i,v in next, getgenv().CoinsEspConnections do
			if v ~= nil then
				v:Disconnect()
				v = nil
			end
		end

		for i,v in next, workspace.Filter.Givers.Coin:GetChildren() do
			if v.Name == 'CoinGiver' and v.Transparency == 0 then
				esp_item(v, 'Коин', Color3.fromRGB(255, 255, 0))
			end
			getgenv().ItemsEspConnections[v] = v:GetPropertyChangedSignal('Transparency'):Connect(function()
				if v.Transparency == 1 then
					unesp_item(v)
				elseif v.Transparency == 0 then
					esp_item(v, 'Коин', Color3.fromRGB(255, 255, 0))
				end
			end)
		end

    else

		for i,v in next, getgenv().CoinsEspConnections do
			if v ~= nil then
				v:Disconnect()
				v = nil
			end
		end

		for i,v in next, workspace.Filter.Givers.Coin:GetChildren() do
			if v.Name == 'CoinGiver' and v.Transparency == 0 then
				unesp_item(v)
			end
		end
	
	end
        
end)

local CustomDamageSounds = Tabs.OtherTab:AddDropdown("CustomDamageSounds", {
    Title = "Выбор кастомного звука дамага",
    Values = {"Skeet"},
    Multi = false,
    Default = 1,
})
local CustomDamageSoundSelected = 'Skeet'
CustomDamageSounds:OnChanged(function(Value)
	CustomDamageSoundSelected = tostring(Value)
end)

local CustomDamageSoundToggle = Tabs.OtherTab:AddToggle("CustomDamageSoundToggle", {Title = "Кастомный звук урона по себе", Default = false})

getgenv().DefaultDamageSounds = {}

CustomDamageSoundToggle:OnChanged(function()
    CustomDamageSoundToggleValue = Options.CustomDamageSoundToggle.Value
        
    if CustomDamageSoundToggleValue == true then
        
		if Character ~= nil and Character:FindFirstChild('Head') then
			for i,v in next, Character:FindFirstChild('Head'):GetChildren() do
				if v:IsA('Sound') and v.Name:find('Ouch') then
					getgenv().DefaultDamageSounds[v.Name] = v.SoundId
					if CustomDamageSoundSelected == 'Skeet' then
						v.SoundId = getcustomasset('skeet.wav')
						print('Sound spoofed!')
					end
				end
			end
		else
			return
		end

		getgenv().CustomDamageSoundRespawn = LocalPlayer.CharacterAdded:Connect(function(Character)
			if Character ~= nil and Character:WaitForChild('Head') then
				for i,v in next, Character:FindFirstChild('Head'):GetChildren() do
					if v:IsA('Sound') and v.Name:find('Ouch') then
						getgenv().DefaultDamageSounds[v.Name] = v.SoundId
						if CustomDamageSoundSelected == 'Skeet' then
							v.SoundId = getcustomasset('skeet.wav')
							print('Sound spoofed!')
						end
					end
				end
			end
		end)

    else

		if getgenv().CustomDamageSoundRespawn ~= nil then
			getgenv().CustomDamageSoundRespawn:Disconnect()
			getgenv().CustomDamageSoundRespawn = nil
		end

		if Character ~= nil and Character:WaitForChild('Head') then
			for i,v in next, Character:FindFirstChild('Head'):GetChildren() do
				if v:IsA('Sound') and v.Name:find('Ouch') then
					if DefaultDamageSounds[v.Name] ~= nil then
						v.SoundId = DefaultDamageSounds[v.Name]
					end
				end
			end
		end

    end
end)

------------ > END <-------------------------------------------------------------- 
