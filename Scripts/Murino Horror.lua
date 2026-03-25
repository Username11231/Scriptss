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

local IS_ANTI_ZAEC_ENABLED = false
local IS_ANTI_CHIGUR_ENABLED = false

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

if getgenv().CharacterAddedConnection ~= nil then
    getgenv().CharacterAddedConnection:Disconnect()
    getgenv().CharacterAddedConnection = nil
end

getgenv().CharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(CharacterAddedConnectionChar)
    Character = CharacterAddedConnectionChar
    Humanoid = CharacterAddedConnectionChar:WaitForChild('Humanoid')
    HumanoidRootPart = CharacterAddedConnectionChar:WaitForChild('HumanoidRootPart')
end)

pcall(task.spawn(function()
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" and self.ClassName == 'RemoteEvent' then
        if self.Name == 'Death' and IS_ANTI_ZAEC_ENABLED == true then
          warn('Aborted: '.. self.Name)
          return
        end
        if self.Name == 'Chigur' and IS_ANTI_CHIGUR_ENABLED == true then
          warn('Aborted: '.. self.Name)
          return
        end
    end
    
    return oldNamecall(self, ...)
end
setreadonly(mt, true)
end))

------------ > WINDOWS <-------------------------------------------------------------- 

local window = Fluent:CreateWindow({
    Title = 'Aether Hub | Мурино Хоррор',
    SubTitle = "v0.0.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightAlt
})

------------ > TABS <-------------------------------------------------------------- 

local Tabs = {
    MainTab = window:AddTab({ Title = "Main", Icon = "" }),
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

Fluent:Notify({
    Title = "Aether Hub",
    Content = "The script has been loaded.",
    Duration = 3
})

local AntiZaecToggle = Tabs.MainTab:AddToggle("AntiZaecToggle", {Title = "Анти-Заяц", Default = false})

AntiZaecToggle:OnChanged(function()
    AntiZaecToggleValue = Options.AntiZaecToggle.Value
        
    if AntiZaecToggleValue == true then
        IS_ANTI_ZAEC_ENABLED = true
    else
        IS_ANTI_ZAEC_ENABLED = false
    end
end)

local AntiChigurDeathToggle = Tabs.MainTab:AddToggle("AntiChigurDeathToggle", {Title = "Анти-Смерть от Чигура", Default = false})

AntiChigurDeathToggle:OnChanged(function()
    AntiChigurDeathToggleValue = Options.AntiChigurDeathToggle.Value
        
    if AntiChigurDeathToggleValue == true then
        IS_ANTI_CHIGUR_ENABLED = true
    else
        IS_ANTI_CHIGUR_ENABLED = false
    end
end)

local TestToggle = Tabs.MainTab:AddToggle("TestToggle", {Title = "тест фун", Default = false})

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
        }})
end})


local ColorPicker = Tabs.MainTab:AddColorpicker("ColorPicker", {
    Title = "Color Picker",
    Default = Color3.fromRGB(255, 255, 255)
})

ColorPicker:OnChanged(function(NewColor)
    print(Funcs.ToRGB(NewColor))
end)

local Dropdown = Tabs.MainTab:AddDropdown("Dropdown", {
    Title = "Dropdown",
    Values = {"12121", "221321", "1231"},
    Multi = false,
    Default = 1,
})

Dropdown:OnChanged(function(Value)
    print("Dropdown new:", Value)
end)

local MultiDropdown = Tabs.MainTab:AddDropdown("MultiDropdown", {
    Title = "MultiDropdown",
    Values = {"12121", "221321", "1231"},
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
