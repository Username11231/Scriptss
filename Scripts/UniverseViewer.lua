local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = gethui and gethui() or game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function Create(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

if CoreGui:FindFirstChild("UVX_Runtime") then
    CoreGui.UVX_Runtime:Destroy()
end

local screenGui = Create("ScreenGui", {
    Name = "UVX_Runtime",
    Parent = CoreGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    DisplayOrder = 9999999
})

local mainFrame = Create("Frame", {
    Parent = screenGui,
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    Position = UDim2.new(0.5, -225, 0.5, -250),
    Size = UDim2.new(0, 450, 0, 500),
    Active = true,
    Draggable = true,
    BorderSizePixel = 0
})
Create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0, 6)})
Create("UIStroke", {Parent = mainFrame, Color = Color3.fromRGB(45, 45, 45), Thickness = 1})

local topBar = Create("Frame", {
    Parent = mainFrame,
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    Size = UDim2.new(1, 0, 0, 35),
    BorderSizePixel = 0
})
Create("UICorner", {Parent = topBar, CornerRadius = UDim.new(0, 6)})
Create("Frame", {
    Parent = topBar,
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    Position = UDim2.new(0, 0, 1, -5),
    Size = UDim2.new(1, 0, 0, 5),
    BorderSizePixel = 0
})

Create("TextLabel", {
    Parent = topBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 15, 0, 0),
    Size = UDim2.new(0.8, 0, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "Universe Viewer X | Undetected",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
})

local closeBtn = Create("TextButton", {
    Parent = topBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -35, 0, 0),
    Size = UDim2.new(0, 35, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 65, 65),
    TextSize = 15
})
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local scrollList = Create("ScrollingFrame", {
    Parent = mainFrame,
    Active = true,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 45),
    Size = UDim2.new(1, -20, 1, -170),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
    BorderSizePixel = 0
})

local listLayout = Create("UIListLayout", {
    Parent = scrollList,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6)
})

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

local actionFrame = Create("Frame", {
    Parent = mainFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 1, -115),
    Size = UDim2.new(1, -20, 0, 105)
})

local function CreateButton(parent, text, pos, size, color, callback)
    local btn = Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = color,
        Position = pos,
        Size = size,
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        AutoButtonColor = true,
        BorderSizePixel = 0
    })
    Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
    Create("UIStroke", {Parent = btn, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1})
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateInput(parent, ph, pos, size)
    local box = Create("TextBox", {
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Position = pos,
        Size = size,
        Font = Enum.Font.Gotham,
        PlaceholderText = ph,
        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        BorderSizePixel = 0,
        ClearTextOnFocus = false
    })
    Create("UICorner", {Parent = box, CornerRadius = UDim.new(0, 4)})
    Create("UIStroke", {Parent = box, Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    return box
end

local function SpoofTeleport(placeId, jobId)
    local qot = queue_on_teleport or syn and syn.queue_on_teleport or fluxus and fluxus.queue_on_teleport or nil
    if qot then
        qot([[
            local p = game:GetService("Players").LocalPlayer
            p.OnTeleport:Connect(function(s)
                if s == Enum.TeleportState.Started then
                    -- Persistence
                end
            end)
        ]])
    end
    
    local id = getthreadidentity and getthreadidentity() or 2
    if setthreadidentity then setthreadidentity(8) end
    
    pcall(function()
        if jobId then
            TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
        else
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
    
    if setthreadidentity then setthreadidentity(id) end
end

local function GetSafePlaces()
    local oldId = getthreadidentity and getthreadidentity() or 2
    if setthreadidentity then setthreadidentity(8) end
    
    local s, r = pcall(function()
        return AssetService:GetGamePlacesAsync()
    end)
    
    if setthreadidentity then setthreadidentity(oldId) end
    
    if s and r then return r end

    local url = "https://games.roblox.com/v1/games/" .. tostring(game.GameId) .. "/places?sortOrder=Asc&limit=100"
    local s2, r2 = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if s2 and r2 and r2.data then
        return r2.data
    end
    
    return nil
end

local function AddPlaceButton(name, placeId)
    local btn = Create("Frame", {
        Parent = scrollList,
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        Size = UDim2.new(1, -5, 0, 38),
        BorderSizePixel = 0
    })
    Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
    
    Create("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = string.format("%s\n<font color='rgb(150,150,150)'>%d</font>", name, placeId),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true
    })
    
    local tpBtn = CreateButton(btn, "Join", UDim2.new(1, -65, 0.5, -13), UDim2.new(0, 55, 0, 26), Color3.fromRGB(45, 105, 45), function()
        SpoofTeleport(placeId)
    end)
    
    local copyBtn = CreateButton(btn, "Copy", UDim2.new(1, -125, 0.5, -13), UDim2.new(0, 55, 0, 26), Color3.fromRGB(55, 55, 75), function()
        if setclipboard then setclipboard(tostring(placeId)) end
    end)
end

local function LoadPlaces()
    for _, child in ipairs(scrollList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    task.spawn(function()
        local places = GetSafePlaces()
        if type(places) == "table" and not places.GetCurrentPage then
            for _, place in ipairs(places) do
                AddPlaceButton(place.name, place.id)
            end
        elseif places then
            while true do
                for _, place in ipairs(places:GetCurrentPage()) do
                    AddPlaceButton(place.Name, place.PlaceId)
                end
                if places.IsFinished then break end
                places:AdvanceToNextPageAsync()
            end
        else
            Create("TextLabel", {
                Parent = scrollList,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35),
                Font = Enum.Font.Gotham,
                Text = "Failed to load places (Bypass Failed)",
                TextColor3 = Color3.fromRGB(255, 80, 80),
                TextSize = 13
            })
        end
    end)
end

local customIdInput = CreateInput(actionFrame, "Enter PlaceId or JobId...", UDim2.new(0, 0, 0, 0), UDim2.new(0.73, 0, 0, 30))
CreateButton(actionFrame, "Teleport", UDim2.new(0.75, 0, 0, 0), UDim2.new(0.25, 0, 0, 30), Color3.fromRGB(80, 40, 100), function()
    local txt = customIdInput.Text
    if txt == "" then return end
    if tonumber(txt) then
        SpoofTeleport(tonumber(txt))
    else
        SpoofTeleport(game.PlaceId, txt)
    end
end)

CreateButton(actionFrame, "Refresh Map List", UDim2.new(0, 0, 0, 38), UDim2.new(0.48, 0, 0, 30), Color3.fromRGB(40, 40, 40), LoadPlaces)

CreateButton(actionFrame, "Rejoin Same Server", UDim2.new(0.52, 0, 0, 38), UDim2.new(0.48, 0, 0, 30), Color3.fromRGB(40, 40, 40), function()
    SpoofTeleport(game.PlaceId, game.JobId)
end)

CreateButton(actionFrame, "Hop Server (Random)", UDim2.new(0, 0, 0, 76), UDim2.new(0.48, 0, 0, 30), Color3.fromRGB(40, 40, 40), function()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    local s, r = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
    if s and r and r.data then
        for _, srv in ipairs(r.data) do
            if srv.playing > 0 and srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                SpoofTeleport(game.PlaceId, srv.id)
                break
            end
        end
    end
end)

CreateButton(actionFrame, "Hop Server (Smallest)", UDim2.new(0.52, 0, 0, 76), UDim2.new(0.48, 0, 0, 30), Color3.fromRGB(40, 40, 40), function()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local s, r = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
    if s and r and r.data then
        for _, srv in ipairs(r.data) do
            if srv.playing > 0 and srv.id ~= game.JobId then
                SpoofTeleport(game.PlaceId, srv.id)
                break
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

LoadPlaces()
