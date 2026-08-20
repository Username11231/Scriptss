local Fluent = {}
Fluent.Options = {}
Fluent._refreshers = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
    Background = Color3.fromRGB(24, 24, 28),
    Secondary  = Color3.fromRGB(32, 32, 38),
    Tertiary   = Color3.fromRGB(42, 42, 50),
    Stroke     = Color3.fromRGB(58, 58, 68),
    Accent     = Color3.fromRGB(255, 130, 180),
    AccentDark = Color3.fromRGB(200, 90, 140),
    Text       = Color3.fromRGB(240, 240, 245),
    SubText    = Color3.fromRGB(165, 165, 175),
    Success    = Color3.fromRGB(120, 220, 150),
    Error      = Color3.fromRGB(230, 90, 100),
    Font       = Enum.Font.GothamMedium,
    FontBold   = Enum.Font.GothamBold,
}

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props); t:Play(); return t
end

local function quickTween(obj, props, dur)
    return tween(obj, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

local function corner(r)
    return create("UICorner", { CornerRadius = UDim.new(0, r or 8) })
end

local function stroke(col, thick, transp)
    return create("UIStroke", { Color = col or Theme.Stroke, Thickness = thick or 1, Transparency = transp or 0 })
end

local function padding(a)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, a), PaddingBottom = UDim.new(0, a),
        PaddingLeft = UDim.new(0, a), PaddingRight = UDim.new(0, a),
    })
end

local function darken(c, f)
    f = f or 0.85
    return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

local function lighten(c, amount)
    amount = amount or 0.15
    return Color3.new(
        math.clamp(c.R + (1 - c.R) * amount, 0, 1),
        math.clamp(c.G + (1 - c.G) * amount, 0, 1),
        math.clamp(c.B + (1 - c.B) * amount, 0, 1)
    )
end

local function pointInside(frame, pos)
    local a, sz = frame.AbsolutePosition, frame.AbsoluteSize
    return pos.X >= a.X and pos.X <= a.X + sz.X and pos.Y >= a.Y and pos.Y <= a.Y + sz.Y
end

local function applyPanelCorners(panel, radius, keep, skipMasks)
    corner(radius).Parent = panel
    if skipMasks then return {} end
    local col = panel.BackgroundColor3
    local masks = {}
    local function mask(name, pos)
        local m = create("Frame", {
            Name = name, BackgroundColor3 = col,
            BackgroundTransparency = panel.BackgroundTransparency,
            BorderSizePixel = 0,
            Position = pos, Size = UDim2.new(0, radius, 0, radius),
            ZIndex = (panel.ZIndex or 1) + 10, Parent = panel,
        })
        masks[name] = m
    end
    if not keep.TopLeft then mask("MaskTL", UDim2.new(0, 0, 0, 0)) end
    if not keep.TopRight then mask("MaskTR", UDim2.new(1, -radius, 0, 0)) end
    if not keep.BottomLeft then mask("MaskBL", UDim2.new(0, 0, 1, -radius)) end
    if not keep.BottomRight then mask("MaskBR", UDim2.new(1, -radius, 1, -radius)) end
    local function sync()
        local t = panel.BackgroundTransparency
        local c = panel.BackgroundColor3
        for _, m in pairs(masks) do
            m.BackgroundTransparency = t
            m.BackgroundColor3 = c
        end
    end
    panel:GetPropertyChangedSignal("BackgroundTransparency"):Connect(sync)
    panel:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
    sync()
    return masks
end

local function spawnRipple(button, relX, relY, color, fillDuration, rippleZIndex, parentOverride)
    fillDuration = fillDuration or 0.22
    local w = button.AbsoluteSize.X
    local h = button.AbsoluteSize.Y
    local diameter = math.sqrt(w * w + h * h) * 2.1
    local circle = create("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.35,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, relX, 0, relY),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = rippleZIndex or ((button.ZIndex or 1) + 1),
        Parent = parentOverride or button,
    }, { corner(9999) })
    tween(circle, TweenInfo.new(fillDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, diameter, 0, diameter),
        BackgroundTransparency = 1,
    })
    task.delay(fillDuration + 0.05, function()
        if circle and circle.Parent then circle:Destroy() end
    end)
end

function Fluent:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 4
    local pos = config.Position or "TopRight"
    
    if not self.ScreenGui then
        self.ScreenGui = create("ScreenGui", {
            Name = "Fluent", ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999, Parent = PlayerGui,
        })
        self._notifHolderTR = create("Frame", {
            Name = "NotifTR", BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -20, 0, 20),
            Size = UDim2.new(0, 300, 1, -40),
            Parent = self.ScreenGui,
        }, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
        self._notifHolderBR = create("Frame", {
            Name = "NotifBR", BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.new(0, 300, 1, -40),
            Parent = self.ScreenGui,
        }, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
    end

    local holder = pos == "BottomRight" and self._notifHolderBR or self._notifHolderTR
    local Frame = create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = holder,
    }, { corner(10), stroke(Theme.Stroke, 1) })
    
    local Inner = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Frame,
    }, { padding(14), create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
    
    local TitleRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = Inner })
    create("TextLabel", { Text = title, Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleRow })
    local XBtn = create("TextButton", { Text = "╳", Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -20, 0, -1), Parent = TitleRow })
    XBtn.MouseEnter:Connect(function() quickTween(XBtn, { TextColor3 = Theme.Error }, 0.12) end)
    XBtn.MouseLeave:Connect(function() quickTween(XBtn, { TextColor3 = Theme.SubText }, 0.12) end)
    
    create("TextLabel", { Text = content, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = Inner })
    
    local TimerLabel, ProgressFill
    if duration > 0 then
        local FooterRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 3, Parent = Inner })
        TimerLabel = create("TextLabel", { Text = math.ceil(duration) .. "s", Font = Theme.Font, TextSize = 11, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = FooterRow })
        local ProgressBar = create("Frame", { BackgroundColor3 = darken(Theme.Tertiary, 0.9), Size = UDim2.new(1, 0, 0, 3), LayoutOrder = 4, Parent = Inner }, { corner(2) })
        ProgressFill = create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(1, 0, 1, 0), Parent = ProgressBar }, { corner(2) })
    end
    
    Frame.BackgroundTransparency = 1
    Frame.Position = UDim2.new(1, 30, 0, 0)
    for _, d in ipairs(Frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then d.TextTransparency = 1 end
    end
    quickTween(Frame, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.25)
    for _, d in ipairs(Frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then quickTween(d, { TextTransparency = 0 }, 0.25) end
        if d:IsA("UIStroke") then quickTween(d, { Transparency = 0 }, 0.25) end
    end
    
    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        quickTween(Frame, { BackgroundTransparency = 1, Position = UDim2.new(1, 30, 0, 0) }, 0.25)
        for _, d in ipairs(Frame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then quickTween(d, { TextTransparency = 1 }, 0.25) end
            if d:IsA("UIStroke") then quickTween(d, { Transparency = 1 }, 0.25) end
        end
        task.wait(0.3)
        Frame:Destroy()
    end
    XBtn.MouseButton1Click:Connect(dismiss)
    if duration > 0 then
        tween(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Size = UDim2.new(0, 0, 1, 0) })
        task.spawn(function()
            local remaining = duration
            while remaining > 0 and not dismissed do
                task.wait(1)
                remaining = remaining - 1
                if TimerLabel and TimerLabel.Parent then TimerLabel.Text = math.ceil(remaining) .. "s" end
            end
            if not dismissed then dismiss() end
        end)
    end
end

function Fluent:Dialog(config)
    config = config or {}
    local title = config.Title or "Notice"
    local content = config.Content or ""
    local buttons = config.Buttons or {}
    local parent = self._mainFrame or self.ScreenGui
    if not parent or not parent.Parent then return end
    
    local Overlay = create("Frame", { Name = "DialogOverlay", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, Parent = parent })
    quickTween(Overlay, { BackgroundTransparency = 0.55 }, 0.2)
    
    local Card = create("Frame", { BackgroundColor3 = Theme.Secondary, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 320, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 51, Parent = Overlay }, { corner(14), stroke(Theme.Accent, 2), padding(20) })
    local inner = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 52, Parent = Card })
    create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top, HorizontalAlignment = Enum.HorizontalAlignment.Left }).Parent = inner
    
    create("TextLabel", { Text = title, Font = Theme.FontBold, TextSize = 17, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 53, Parent = inner })
    create("TextLabel", { Text = content, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, ZIndex = 53, Parent = inner })
    
    if #buttons > 0 then
        local btnRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 3, ZIndex = 53, Parent = inner }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
        for i, btn in ipairs(buttons) do
            if i > 2 then break end
            local b = create("TextButton", { Text = btn.Title or btn.Text or "OK", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundColor3 = i == 1 and Theme.Accent or Theme.Tertiary, Size = UDim2.new(0, 90, 0, 30), LayoutOrder = i, ZIndex = 54, Parent = btnRow }, { corner(7) })
            b.MouseButton1Click:Connect(function()
                if btn.Callback then btn.Callback() end
                quickTween(Overlay, { BackgroundTransparency = 1 }, 0.2)
                task.wait(0.22); Overlay:Destroy()
            end)
        end
    end
    Card.BackgroundTransparency = 1
    quickTween(Card, { BackgroundTransparency = 0 }, 0.25)
end

function Fluent:CreateWindow(config)
    config = config or {}
    local windowName = config.Title or "Fluent"
    local subtitle = config.SubTitle
    local tabWidth = config.TabWidth or 160
    local size = config.Size or UDim2.fromOffset(580, 460)
    local toggleKey = config.MinimizeKey or Enum.KeyCode.RightControl
    local acrylic = config.Acrylic or false
    local bgImage = acrylic and "rbxassetid://139904778246005" or nil
    local bgTransp = acrylic and 0.75 or 1
    
    if not self.ScreenGui then
        self.ScreenGui = create("ScreenGui", { Name = "Fluent", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = PlayerGui })
    end
    
    local Window = {}
    Window.Tabs = {}
    
    local Main = create("Frame", { Name = "Main", BackgroundColor3 = Theme.Background, Size = size, Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2), Parent = self.ScreenGui, ClipsDescendants = true }, { corner(12), stroke(Theme.Stroke, 1) })
    self._mainFrame = Main
    
    if bgImage then
        create("ImageLabel", { Name = "CustomBackground", Image = bgImage, BackgroundTransparency = 1, ImageTransparency = bgTransp, ScaleType = Enum.ScaleType.Crop, Size = UDim2.new(1, 0, 1, 0), ZIndex = 0, Parent = Main }, { corner(12) })
    end
    
    local TOPBAR_H = 38
    local TopBar = create("Frame", { Name = "TopBar", BackgroundColor3 = darken(Theme.Secondary, 0.92), BackgroundTransparency = bgImage and 0.6 or 0, Size = UDim2.new(1, 0, 0, TOPBAR_H), Parent = Main })
    local topBarMasks = applyPanelCorners(TopBar, 12, { TopLeft = true, TopRight = true, BottomLeft = false, BottomRight = false }, bgImage ~= nil)
    
    local titleOffset = 16
    if subtitle and subtitle ~= "" then
        create("TextLabel", { Text = windowName, Font = Theme.FontBold, TextSize = 16, TextColor3 = Theme.Text, BackgroundTransparency = 1, Position = UDim2.new(0, titleOffset, 0, 4), Size = UDim2.new(1, -titleOffset - 110, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
        create("TextLabel", { Text = subtitle, Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Position = UDim2.new(0, titleOffset, 0, 20), Size = UDim2.new(1, -titleOffset - 110, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
    else
        create("TextLabel", { Text = windowName, Font = Theme.FontBold, TextSize = 20, TextColor3 = Theme.Text, BackgroundTransparency = 1, Position = UDim2.new(0, titleOffset, 0, 0), Size = UDim2.new(1, -titleOffset - 110, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
    end
    
    local DragCatcher = create("Frame", { Name = "DragCatcher", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = TopBar })
    local Controls = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 96, 0, 26), Parent = TopBar }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
    
    local function makeCtrlBtn(text, hoverBg, hoverText, order)
        local b = create("TextButton", { Text = text, Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.SubText, BackgroundColor3 = hoverBg, BackgroundTransparency = 1, Size = UDim2.new(0, 28, 0, 26), LayoutOrder = order, Parent = Controls }, { corner(6) })
        b.MouseEnter:Connect(function() quickTween(b, { BackgroundTransparency = 0, TextColor3 = hoverText }, 0.15) end)
        b.MouseLeave:Connect(function() quickTween(b, { BackgroundTransparency = 1, TextColor3 = Theme.SubText }, 0.15) end)
        return b
    end
    
    local MinBtn = makeCtrlBtn("—", darken(Theme.Tertiary, 0.9), Theme.Accent, 1)
    local CloseBtn = makeCtrlBtn("╳", darken(Theme.Error, 0.5), Theme.Text, 3)
    
    local minimized = false
    local windowSize = size
    local windowPos = Main.Position
    
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if topBarMasks.MaskBL then topBarMasks.MaskBL.Visible = not minimized end
        if topBarMasks.MaskBR then topBarMasks.MaskBR.Visible = not minimized end
        MinBtn.Text = minimized and "▲" or "—"
        quickTween(Main, { Size = minimized and UDim2.new(0, size.X.Offset * 0.4, 0, TOPBAR_H) or windowSize }, 0.28)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
    
    local dragging = false
    local dragStart, startPos, targetPos
    DragCatcher.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; windowPos = Main.Position end end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        if targetPos then Main.Position = Main.Position:Lerp(targetPos, math.clamp(dt * 16, 0, 1)); windowPos = Main.Position end
    end)
    
    local TabListShell = create("Frame", { Name = "TabListShell", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = bgImage and 0.65 or 0, Position = UDim2.new(0, 0, 0, TOPBAR_H), Size = UDim2.new(0, tabWidth, 1, -TOPBAR_H), Parent = Main })
    applyPanelCorners(TabListShell, 12, { TopLeft = false, TopRight = false, BottomLeft = true, BottomRight = false }, bgImage ~= nil)
    
    local TabList = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = TabListShell }, { create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }), padding(10) })
    local ContentArea = create("Frame", { Name = "ContentArea", BackgroundTransparency = 1, Position = UDim2.new(0, tabWidth, 0, TOPBAR_H), Size = UDim2.new(1, -tabWidth, 1, -TOPBAR_H), Parent = Main })
    
    function Window:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Title or "Tab"
        local tabActiveTransparency = bgImage and 0.35 or 0
        
        local TabBtn = create("TextButton", { Text = "", BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ClipsDescendants = true, ZIndex = 2, Parent = TabList }, { corner(8) })
        local RippleLayer = create("Frame", { Name = "RippleLayer", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = TabBtn }, { corner(8) })
        local TabLabel = create("TextLabel", { Text = tabName, Font = Theme.Font, TextSize = 14, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4, Parent = TabBtn })
        
        local Page = create("ScrollingFrame", { Name = tabName .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Accent, Visible = false, Parent = ContentArea }, { padding(14), create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
        local PageLayout = Page:FindFirstChildOfClass("UIListLayout")
        local function updateCanvas() Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 28) end
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        updateCanvas()
        
        local Tab = { Page = Page, Button = TabBtn, Label = TabLabel, Active = false }
        
        local function selectTab(clickX, clickY)
            for _, t in pairs(Window.Tabs) do
                if t.Active and t ~= Tab then
                    t.Active = false
                    quickTween(t.Page, { BackgroundTransparency = 1 }, 0.12)
                    for _, d in ipairs(t.Page:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") then quickTween(d, { TextTransparency = 1 }, 0.12) end end
                    task.delay(0.13, function() t.Page.Visible = false end)
                else t.Active = false end
                quickTween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                quickTween(t.Label, { TextColor3 = Theme.SubText }, 0.15)
            end
            Tab.Active = true; Page.Visible = true
            for _, d in ipairs(Page:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") then quickTween(d, { TextTransparency = 0 }, 0.15) end end
            quickTween(TabBtn, { BackgroundTransparency = tabActiveTransparency }, 0.15)
            quickTween(TabLabel, { TextColor3 = Theme.Text }, 0.15)
            spawnRipple(TabBtn, clickX or TabBtn.AbsoluteSize.X / 2, clickY or TabBtn.AbsoluteSize.Y / 2, lighten(Theme.Accent, 0.1), 0.28, 3, RippleLayer)
        end
        
        TabBtn.MouseButton1Click:Connect(function()
            local mPos = UserInputService:GetMouseLocation()
            local abs = TabBtn.AbsolutePosition
            selectTab(mPos.X - abs.X, mPos.Y - abs.Y)
        end)
        
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then selectTab() end
        
        local function createElementContainer()
            return create("Frame", { BackgroundColor3 = Theme.Secondary, BackgroundTransparency = bgImage and 0.6 or 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = Page }, { corner(10), stroke(Theme.Stroke, 1), padding(12), create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
        end
        local currentSection = createElementContainer()
        local function getSection() return currentSection end
        
        function Tab:AddToggle(flag, c)
            c = c or {}
            local state = c.Default or false
            Fluent.Options[flag] = state
            local H = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = getSection() })
            create("TextLabel", { Text = c.Title or "Toggle", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -54, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = H })
            local Sw = create("Frame", { BackgroundColor3 = state and Theme.Accent or Theme.Tertiary, BackgroundTransparency = bgImage and 0.3 or 0, Size = UDim2.new(0, 48, 0, 24), Position = UDim2.new(1, -48, 0.5, -12), Parent = H }, { corner(6) })
            local Kn = create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 20, 0, 20), Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10), Parent = Sw }, { corner(4) })
            local Cl = create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = H })
            local tog = {}
            function tog:Set(ns, fire)
                state = ns; Fluent.Options[flag] = state
                quickTween(Sw, { BackgroundColor3 = state and Theme.Accent or Theme.Tertiary }, 0.18)
                quickTween(Kn, { Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }, 0.18)
                if fire ~= false and tog._callback then tog._callback(state) end
            end
            function tog:OnChanged(cb) tog._callback = cb end
            Cl.MouseButton1Click:Connect(function() tog:Set(not state) end)
            return tog
        end
        
        function Tab:AddInput(flag, c)
            c = c or {}
            Fluent.Options[flag] = c.Default or ""
            local H = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), Parent = getSection() })
            create("TextLabel", { Text = c.Title or "Input", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Parent = H })
            local Box = create("Frame", { BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = bgImage and 0.4 or 0, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 30), Parent = H }, { corner(8) })
            local Input = create("TextBox", { Text = tostring(c.Default or ""), PlaceholderText = c.Placeholder or "Enter text...", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = Box })
            if c.Numeric then Input:GetPropertyChangedSignal("Text"):Connect(function() Input.Text = Input.Text:gsub("%D", "") end) end
            Input.Focused:Connect(function() quickTween(Box, { BackgroundColor3 = Theme.AccentDark }, 0.15) end)
            Input.FocusLost:Connect(function(enter)
                quickTween(Box, { BackgroundColor3 = Theme.Tertiary }, 0.15)
                local val = c.Numeric and tonumber(Input.Text) or Input.Text
                Fluent.Options[flag] = val
                if c.Finished and not enter then return end
                if c.Callback then c.Callback(val) end
                if inp._callback then inp._callback(val) end
            end)
            local inp = {}
            function inp:OnChanged(cb) inp._callback = cb end
            return inp
        end
        
        function Tab:AddParagraph(c)
            c = c or {}
            return create("TextLabel", { Text = c.Content or c.Title or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = getSection() })
        end
        
        function Tab:AddButton(c)
            c = c or {}
            local Btn = create("TextButton", { Text = c.Title or "Button", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = bgImage and 0.5 or 0, Size = UDim2.new(1, 0, 0, 34), Parent = getSection() }, { corner(8) })
            Btn.MouseEnter:Connect(function() quickTween(Btn, { BackgroundColor3 = darken(Theme.Tertiary, 0.75) }, 0.15) end)
            Btn.MouseLeave:Connect(function() quickTween(Btn, { BackgroundColor3 = Theme.Tertiary }, 0.15) end)
            Btn.MouseButton1Down:Connect(function() quickTween(Btn, { Size = UDim2.new(1, -6, 0, 32) }, 0.08) end)
            Btn.MouseButton1Up:Connect(function() quickTween(Btn, { Size = UDim2.new(1, 0, 0, 34) }, 0.12) end)
            Btn.MouseButton1Click:Connect(function() if c.Callback then c.Callback() end end)
            return Btn
        end
        
        function Tab:AddColorpicker(flag, c)
            c = c or {}
            local col = c.Default or Color3.fromRGB(255, 255, 255)
            Fluent.Options[flag] = col
            local open, h, s, v = false, col:ToHSV()
            local BODY_H = 178
            local H = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = getSection(), ClipsDescendants = true })
            local Header = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = H })
            create("TextLabel", { Text = c.Title or "Color", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Header })
            local Preview = create("TextButton", { Text = "", BackgroundColor3 = col, BackgroundTransparency = bgImage and 0.3 or 0, Size = UDim2.new(0, 28, 0, 20), Position = UDim2.new(1, -28, 0.5, -10), Parent = Header }, { corner(6), stroke(Theme.Stroke, 1) })
            local Body = create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, Visible = false, Parent = H })
            local HueBar = create("Frame", { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 24), Parent = Body }, { corner(6) })
            create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }), Rotation = 0 }).Parent = HueBar
            local HueCur = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 6, 1, 4), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(h, 0, 0.5, 0), Parent = HueBar }, { corner(3), stroke(Color3.fromRGB(0, 0, 0), 1) })
            local SVBox = create("ImageLabel", { Image = "rbxassetid://4155801252", BackgroundColor3 = Color3.fromHSV(h, 1, 1), BackgroundTransparency = bgImage and 0.2 or 0, Size = UDim2.new(1, 0, 0, 146), Position = UDim2.new(0, 0, 0, 32), Parent = Body }, { corner(8) })
            local SVCur = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(s, 0, 1 - v, 0), Parent = SVBox }, { corner(5), stroke(Color3.fromRGB(0, 0, 0), 1) })
            
            local function updCol()
                col = Color3.fromHSV(h, s, v); Preview.BackgroundColor3 = col; SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Fluent.Options[flag] = col
                if cp._callback then cp._callback(col) end
            end
            local function updateSV(pos) s = math.clamp((pos.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1); v = 1 - math.clamp((pos.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1); SVCur.Position = UDim2.new(s, 0, 1 - v, 0); updCol() end
            local function updateHue(pos) h = math.clamp((pos.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1); HueCur.Position = UDim2.new(h, 0, 0.5, 0); updCol() end
            
            local dragSV, dragHue = false, false
            UserInputService.InputBegan:Connect(function(i)
                if not open or (i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch) then return end
                if pointInside(SVBox, i.Position) then dragSV = true; updateSV(i.Position)
                elseif pointInside(HueBar, i.Position) then dragHue = true; updateHue(i.Position) end
            end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSV, dragHue = false, false end end)
            UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
                if dragSV then updateSV(i.Position) elseif dragHue then updateHue(i.Position) end
            end)
            
            Preview.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Body.Visible = true; Body.Size = UDim2.new(1, 0, 0, 0)
                    quickTween(H, { Size = UDim2.new(1, 0, 0, 34 + BODY_H) }, 0.2)
                    quickTween(Body, { Size = UDim2.new(1, 0, 0, BODY_H) }, 0.2)
                else
                    quickTween(H, { Size = UDim2.new(1, 0, 0, 30) }, 0.2)
                    quickTween(Body, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                    task.delay(0.22, function() if not open then Body.Visible = false end end)
                end
            end)
            local cp = {}
            function cp:OnChanged(cb) cp._callback = cb end
            return cp
        end
        
        function Tab:AddDropdown(flag, c)
            c = c or {}
            local opts = c.Values or {}
            local mode = c.Multi and "multi" or "single"
            local cur = c.Default or (mode == "single" and opts[1] or {})
            local open = false
            Fluent.Options[flag] = cur
            
            local H = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), Parent = getSection(), ClipsDescendants = false })
            create("TextLabel", { Text = c.Title or "Dropdown", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Parent = H })
            local Box = create("TextButton", { Text = "", BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = bgImage and 0.4 or 0, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 32), Parent = H }, { corner(8) })
            Box.MouseEnter:Connect(function() if not open then quickTween(Box, { BackgroundColor3 = darken(Theme.Tertiary, 0.75) }, 0.15) end end)
            Box.MouseLeave:Connect(function() if not open then quickTween(Box, { BackgroundColor3 = Theme.Tertiary }, 0.15) end end)
            
            local SelLabel = create("TextLabel", { Text = mode == "single" and tostring(cur or "None") or "None", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -32, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Box })
            local Arrow = create("TextLabel", { Text = "˅", Font = Theme.Font, TextSize = 14, TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -28, 0, 0), Parent = Box })
            
            local optH = #opts * 30
            local OptionList = create("Frame", { BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = bgImage and 0.4 or 0, Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 20, ClipsDescendants = true, Visible = false, Parent = getSection() }, { corner(8), create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
            
            local function reposOptionList() OptionList.Position = UDim2.new(0, 0, 0, H.Position.Y.Offset + 56) end
            task.defer(reposOptionList)
            
            local selSet = {}
            if mode == "multi" and type(cur) == "table" then for _, v in ipairs(cur) do selSet[v] = true end end
            
            local function refreshLabel()
                if mode == "multi" then
                    local ns = {}
                    for _, o in ipairs(opts) do if selSet[o] then ns[#ns + 1] = o end end
                    SelLabel.Text = #ns > 0 and table.concat(ns, ", ") or "None"
                else
                    SelLabel.Text = tostring(cur or "None")
                end
            end
            refreshLabel()
            
            local optBtns = {}
            local function buildOptionButtons()
                for _, b in ipairs(optBtns) do if b and b.Parent then b:Destroy() end end
                optBtns = {}
                for i, opt in ipairs(opts) do
                    local isSel = mode == "multi" and selSet[opt] or (mode == "single" and opt == cur)
                    local OB = create("TextButton", { Text = tostring(opt), Font = Theme.Font, TextSize = 13, TextColor3 = isSel and Theme.Accent or Theme.SubText, BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = i, ZIndex = 21, Parent = OptionList })
                    OB.MouseEnter:Connect(function() quickTween(OB, { BackgroundTransparency = 0.6 }, 0.1) end)
                    OB.MouseLeave:Connect(function() quickTween(OB, { BackgroundTransparency = 1 }, 0.1) end)
                    OB.MouseButton1Click:Connect(function()
                        if mode == "multi" then
                            selSet[opt] = not selSet[opt]
                            OB.TextColor3 = selSet[opt] and Theme.Accent or Theme.SubText
                            refreshLabel()
                            local res = {}
                            for _, o in ipairs(opts) do if selSet[o] then res[#res + 1] = o end end
                            Fluent.Options[flag] = res
                            if dd._callback then dd._callback(res) end
                        else
                            cur = opt; refreshLabel()
                            for _, b in pairs(optBtns) do b.TextColor3 = Theme.SubText end
                            OB.TextColor3 = Theme.Accent
                            Fluent.Options[flag] = cur
                            if dd._callback then dd._callback(cur) end
                            open = false
                            quickTween(Arrow, { Rotation = 0 }, 0.18)
                            quickTween(OptionList, { Size = UDim2.new(1, -24, 0, 0) }, 0.18)
                            task.delay(0.2, function() if not open then OptionList.Visible = false end end)
                            quickTween(Box, { BackgroundColor3 = Theme.Tertiary }, 0.12)
                        end
                    end)
                    optBtns[#optBtns + 1] = OB
                end
            end
            buildOptionButtons()
            
            Box.MouseButton1Click:Connect(function()
                reposOptionList()
                open = not open
                quickTween(Arrow, { Rotation = open and 180 or 0 }, 0.18)
                if open then
                    OptionList.Visible = true; OptionList.Size = UDim2.new(1, -24, 0, 0)
                    quickTween(OptionList, { Size = UDim2.new(1, -24, 0, optH) }, 0.18)
                    quickTween(Box, { BackgroundColor3 = darken(Theme.Tertiary, 0.75) }, 0.12)
                else
                    quickTween(OptionList, { Size = UDim2.new(1, -24, 0, 0) }, 0.18)
                    task.delay(0.2, function() if not open then OptionList.Visible = false end end)
                    quickTween(Box, { BackgroundColor3 = Theme.Tertiary }, 0.12)
                end
            end)
            local dd = {}
            function dd:OnChanged(cb) dd._callback = cb end
            return dd
        end
        
        return Tab
    end
    return Window
end

return Fluent
