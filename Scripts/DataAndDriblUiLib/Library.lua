-- ===== Services =====
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ===== Constants =====
local THEME = {
    Dark = {
        Background = Color3.fromRGB(24, 24, 28),
        Secondary  = Color3.fromRGB(32, 32, 38),
        Tertiary   = Color3.fromRGB(42, 42, 50),
        Stroke     = Color3.fromRGB(58, 58, 68),
        Accent     = Color3.fromRGB(255, 130, 180),
        Text       = Color3.fromRGB(240, 240, 245),
        SubText    = Color3.fromRGB(165, 165, 175),
        Success    = Color3.fromRGB(120, 220, 150),
        Error      = Color3.fromRGB(230, 90, 100),
    }
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

-- ===== Utility Functions =====
local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function quickTween(obj, props, dur)
    return tween(obj, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    return inst
end

local function corner(r)
    local inst = Instance.new("UICorner")
    inst.CornerRadius = UDim.new(0, r or 8)
    return inst
end

local function stroke(col, thick, transp)
    local inst = Instance.new("UIStroke")
    inst.Color = col or Color3.fromRGB(58, 58, 68)
    inst.Thickness = thick or 1
    inst.Transparency = transp or 0
    return inst
end

local function padding(a)
    local inst = Instance.new("UIPadding")
    inst.PaddingTop = UDim.new(0, a)
    inst.PaddingBottom = UDim.new(0, a)
    inst.PaddingLeft = UDim.new(0, a)
    inst.PaddingRight = UDim.new(0, a)
    return inst
end

local function darken(col, factor)
    factor = factor or 0.85
    return Color3.new(
        math.clamp(col.R * factor, 0, 1),
        math.clamp(col.G * factor, 0, 1),
        math.clamp(col.B * factor, 0, 1)
    )
end

local function lighten(col, amount)
    amount = amount or 0.15
    return Color3.new(
        math.clamp(col.R + (1 - col.R) * amount, 0, 1),
        math.clamp(col.G + (1 - col.G) * amount, 0, 1),
        math.clamp(col.B + (1 - col.B) * amount, 0, 1)
    )
end

local function pointInside(frame, pos)
    local a = frame.AbsolutePosition
    local sz = frame.AbsoluteSize
    return pos.X >= a.X and pos.X <= a.X + sz.X and pos.Y >= a.Y and pos.Y <= a.Y + sz.Y
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
        Parent = parentOverride or button
    }, { corner(9999) })
    tween(circle, TweenInfo.new(fillDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, diameter, 0, diameter),
        BackgroundTransparency = 1
    })
    task.delay(fillDuration + 0.05, function()
        if circle and circle.Parent then circle:Destroy() end
    end)
end

-- ===== Fluent Library =====
local Fluent = {}
Fluent.Options = {}
Fluent._refreshers = {}
Fluent._notifHolderTR = nil
Fluent._notifHolderBR = nil
Fluent._mainFrame = nil
Fluent._keySystemFailed = false

function Fluent:SetAccentColor(color)
    if not color then return end
    THEME.Dark.Accent = color
end

function Fluent:Refresh()
    local alive = {}
    for _, fn in ipairs(self._refreshers) do
        local ok, keep = pcall(fn)
        if ok and keep ~= false then
            table.insert(alive, fn)
        end
    end
    self._refreshers = alive
end

function Fluent:Init()
    local ex = PlayerGui:FindFirstChild("FluentUI")
    if ex then ex:Destroy() end

    local sg = create("ScreenGui", {
        Name = "FluentUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = PlayerGui
    })
    self.ScreenGui = sg

    self._notifHolderTR = create("Frame", {
        Name = "NotifTR",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        Parent = sg
    }, {
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Right
        })
    })

    self._notifHolderBR = create("Frame", {
        Name = "NotifBR",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -40),
        Parent = sg
    }, {
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right
        })
    })

    self._mainFrame = nil
    self._refreshers = {}
    self._keySystemFailed = false

    return self
end

function Fluent:CreateKeySystem(config)
    -- Optional key system, not required
    if not config.Enabled then return true end
    -- implement if needed
    return true
end

function Fluent:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration
    if duration == nil then duration = 4 end
    local pos = config.Position or "TopRight"

    local holder = pos == "BottomRight" and self._notifHolderBR or self._notifHolderTR
    if not holder then return end

    local Frame = create("Frame", {
        BackgroundColor3 = THEME.Dark.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = holder
    }, { corner(10), stroke(THEME.Dark.Stroke, 1) })

    local Inner = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Frame
    }, {
        padding(14),
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    })

    local TitleRow = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
        Parent = Inner
    })
    create("TextLabel", {
        Text = title,
        Font = FONT_BOLD,
        TextSize = 15,
        TextColor3 = THEME.Dark.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleRow
    })
    local XBtn = create("TextButton", {
        Text = "╳",
        Font = FONT_BOLD,
        TextSize = 14,
        TextColor3 = THEME.Dark.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, -1),
        Parent = TitleRow
    })
    XBtn.MouseEnter:Connect(function() quickTween(XBtn, { TextColor3 = THEME.Dark.Error }, 0.12) end)
    XBtn.MouseLeave:Connect(function() quickTween(XBtn, { TextColor3 = THEME.Dark.SubText }, 0.12) end)

    create("TextLabel", {
        Text = content,
        Font = FONT,
        TextSize = 13,
        TextColor3 = THEME.Dark.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = Inner
    })

    local TimerLabel, ProgressFill
    if duration > 0 then
        local FooterRow = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = 3,
            Parent = Inner
        })
        TimerLabel = create("TextLabel", {
            Text = math.ceil(duration) .. "s",
            Font = FONT,
            TextSize = 11,
            TextColor3 = THEME.Dark.SubText,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = FooterRow
        })
        local ProgressBar = create("Frame", {
            BackgroundColor3 = darken(THEME.Dark.Tertiary, 0.9),
            Size = UDim2.new(1, 0, 0, 3),
            LayoutOrder = 4,
            Parent = Inner
        }, { corner(2) })
        ProgressFill = create("Frame", {
            BackgroundColor3 = THEME.Dark.Accent,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = ProgressBar
        }, { corner(2) })
    end

    Frame.BackgroundTransparency = 1
    Frame.Position = UDim2.new(1, 30, 0, 0)
    for _, d in ipairs(Frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            d.TextTransparency = 1
        end
    end
    quickTween(Frame, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.25)
    for _, d in ipairs(Frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            quickTween(d, { TextTransparency = 0 }, 0.25)
        end
        if d:IsA("UIStroke") then
            quickTween(d, { Transparency = 0 }, 0.25)
        end
    end

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        quickTween(Frame, { BackgroundTransparency = 1, Position = UDim2.new(1, 30, 0, 0) }, 0.25)
        for _, d in ipairs(Frame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                quickTween(d, { TextTransparency = 1 }, 0.25)
            end
            if d:IsA("UIStroke") then
                quickTween(d, { Transparency = 1 }, 0.25)
            end
        end
        task.wait(0.3)
        Frame:Destroy()
    end
    XBtn.MouseButton1Click:Connect(dismiss)

    if duration > 0 then
        tween(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 1, 0)
        })
        task.spawn(function()
            local remaining = duration
            while remaining > 0 and not dismissed do
                task.wait(1)
                remaining = remaining - 1
                if TimerLabel and TimerLabel.Parent then
                    TimerLabel.Text = math.ceil(remaining) .. "s"
                end
            end
            if not dismissed then dismiss() end
        end)
    end
end

function Fluent:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Fluent"
    local subtitle = config.SubTitle or ""
    local tabWidth = config.TabWidth or 160
    local size = config.Size or UDim2.fromOffset(580, 460)
    local acrylic = config.Acrylic or false
    local theme = config.Theme or "Dark"
    local minimizeKey = config.MinimizeKey or Enum.KeyCode.RightAlt

    local window = {}
    window.Tabs = {}
    window.Options = Fluent.Options

    local TOPBAR_H = 38
    local MIN_SIZE = UDim2.new(0, 200, 0, TOPBAR_H)

    local Main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = THEME.Dark.Background,
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Parent = self.ScreenGui,
        ClipsDescendants = true
    }, { corner(12), stroke(THEME.Dark.Stroke, 1) })
    self._mainFrame = Main

    -- Acrylic blur
    if acrylic then
        local blur = create("Frame", {
            Name = "BlurBackground",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Main,
            ZIndex = 0
        }, { create("UIGradient", {
            Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
            Transparency = NumberSequence.new(0.5, 0.7)
        }) })
        -- actual blur not available directly, but we can fake with semi-transparent
    end

    local FadeCover = create("Frame", {
        Name = "FadeCover",
        BackgroundColor3 = THEME.Dark.Background,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1000,
        Active = true,
        Visible = false,
        Parent = Main
    }, { corner(12) })

    local TopBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = darken(THEME.Dark.Secondary, 0.92),
        Size = UDim2.new(1, 0, 0, TOPBAR_H),
        Parent = Main
    })
    local topBarMasks = {}
    local maskTL = create("Frame", { BackgroundColor3 = TopBar.BackgroundColor3, Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 0, 0, 0), ZIndex = TopBar.ZIndex + 1, Parent = TopBar })
    local maskTR = create("Frame", { BackgroundColor3 = TopBar.BackgroundColor3, Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -12, 0, 0), ZIndex = TopBar.ZIndex + 1, Parent = TopBar })
    topBarMasks.MaskTL = maskTL
    topBarMasks.MaskTR = maskTR
    corner(12).Parent = TopBar

    local TitleLabel = create("TextLabel", {
        Text = title,
        Font = FONT_BOLD,
        TextSize = 16,
        TextColor3 = THEME.Dark.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 4),
        Size = UDim2.new(1, -110, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })
    local SubtitleLabel = create("TextLabel", {
        Text = subtitle,
        Font = FONT,
        TextSize = 12,
        TextColor3 = THEME.Dark.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 20),
        Size = UDim2.new(1, -110, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })

    local DragCatcher = create("Frame", {
        Name = "DragCatcher",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TopBar
    })

    local Controls = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 96, 0, 26),
        Parent = TopBar
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    local function makeCtrlBtn(text, hoverBg, hoverText, order)
        local b = create("TextButton", {
            Text = text,
            Font = FONT_BOLD,
            TextSize = 15,
            TextColor3 = THEME.Dark.SubText,
            BackgroundColor3 = hoverBg,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 28, 0, 26),
            LayoutOrder = order,
            Parent = Controls
        }, { corner(6) })
        b.MouseEnter:Connect(function() quickTween(b, { BackgroundTransparency = 0, TextColor3 = hoverText }, 0.15) end)
        b.MouseLeave:Connect(function() quickTween(b, { BackgroundTransparency = 1, TextColor3 = THEME.Dark.SubText }, 0.15) end)
        return b
    end

    local MinBtn = makeCtrlBtn("—", darken(THEME.Dark.Tertiary, 0.9), THEME.Dark.Accent, 1)
    local MaxBtn = makeCtrlBtn("▢", darken(THEME.Dark.Tertiary, 0.9), THEME.Dark.Accent, 2)
    local CloseBtn = makeCtrlBtn("╳", darken(THEME.Dark.Error, 0.5), THEME.Dark.Text, 3)

    local minimized, maximized = false, false
    local windowSize = size
    local windowPos = Main.Position
    local TabListShell, ContentArea

    local function hideCtrlBtns()
        MaxBtn.Visible = false
        CloseBtn.Visible = false
    end
    local function showCtrlBtns()
        MaxBtn.Visible = true
        CloseBtn.Visible = true
    end
    local function setMinVisual(isMin)
        if topBarMasks.MaskBL then topBarMasks.MaskBL.Visible = not isMin end
        if topBarMasks.MaskBR then topBarMasks.MaskBR.Visible = not isMin end
        MinBtn.Text = isMin and "▲" or "—"
        if isMin then hideCtrlBtns() else showCtrlBtns() end
    end

    MinBtn.MouseButton1Click:Connect(function()
        if maximized then return end
        minimized = not minimized
        if minimized then
            TabListShell.Visible = false
            ContentArea.Visible = false
            quickTween(Main, { Size = MIN_SIZE }, 0.28)
        else
            TabListShell.Visible = true
            ContentArea.Visible = true
            quickTween(Main, { Size = windowSize }, 0.28)
        end
        setMinVisual(minimized)
    end)

    MaxBtn.MouseButton1Click:Connect(function()
        if not maximized then
            if minimized then
                minimized = false
                TabListShell.Visible = true
                ContentArea.Visible = true
                setMinVisual(false)
            end
            maximized = true
            quickTween(Main, { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) }, 0.28)
        else
            maximized = false
            quickTween(Main, { Size = windowSize, Position = windowPos }, 0.28)
        end
    end)

    local transitioning = false

    function window:Close()
        if transitioning then return end
        transitioning = true
        FadeCover.Visible = true
        FadeCover.BackgroundTransparency = 1
        quickTween(FadeCover, { BackgroundTransparency = 0 }, 0.2)
        local curSize = Main.Size
        quickTween(Main, {
            Size = UDim2.new(curSize.X.Scale, curSize.X.Offset * 0.9, curSize.Y.Scale, curSize.Y.Offset * 0.9)
        }, 0.22)
        task.wait(0.22)
        Main.Visible = false
        transitioning = false
    end

    function window:Open()
        if transitioning then return end
        transitioning = true
        Main.Visible = true
        local targetSize, targetPos
        if maximized then
            targetSize = UDim2.new(1, 0, 1, 0)
            targetPos = UDim2.new(0, 0, 0, 0)
        elseif minimized then
            targetSize = MIN_SIZE
            targetPos = windowPos
        else
            targetSize = windowSize
            targetPos = windowPos
        end
        FadeCover.Visible = true
        FadeCover.BackgroundTransparency = 0
        Main.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset * 0.9, targetSize.Y.Scale, targetSize.Y.Offset * 0.9)
        Main.Position = targetPos
        tween(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize,
            Position = targetPos
        })
        task.delay(0.12, function()
            quickTween(FadeCover, { BackgroundTransparency = 1 }, 0.22)
            task.delay(0.24, function() FadeCover.Visible = false end)
        end)
        task.delay(0.3, function() transitioning = false end)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        task.spawn(function() window:Close() end)
    end)

    -- Drag
    local dragging = false
    local dragStart, startPos
    local targetPos
    DragCatcher.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if maximized then
            maximized = false
            local halfW = windowSize.X.Offset / 2
            local newX = input.Position.X - halfW
            local newY = input.Position.Y - TOPBAR_H / 2
            Main.Size = windowSize
            Main.Position = UDim2.new(0, newX, 0, newY)
            windowPos = Main.Position
        end
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                windowPos = Main.Position
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if maximized then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        if targetPos and not maximized then
            Main.Position = Main.Position:Lerp(targetPos, math.clamp(dt * 16, 0, 1))
            windowPos = Main.Position
        end
    end)

    -- Minimize keybind
    local toggling = false
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == minimizeKey then
            if toggling then return end
            toggling = true
            task.spawn(function()
                if Main.Visible then window:Close() else window:Open() end
                toggling = false
            end)
        end
    end)

    -- Tab list
    TabListShell = create("Frame", {
        Name = "TabListShell",
        BackgroundColor3 = THEME.Dark.Secondary,
        Position = UDim2.new(0, 0, 0, TOPBAR_H),
        Size = UDim2.new(0, tabWidth, 1, -TOPBAR_H),
        Parent = Main
    }, { corner(12) })
    -- Masks for bottom corners
    local maskBL = create("Frame", { BackgroundColor3 = TabListShell.BackgroundColor3, Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 0, 1, -12), ZIndex = TabListShell.ZIndex + 1, Parent = TabListShell })
    local maskBR = create("Frame", { BackgroundColor3 = TabListShell.BackgroundColor3, Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -12, 1, -12), ZIndex = TabListShell.ZIndex + 1, Parent = TabListShell })
    topBarMasks.MaskBL = maskBL
    topBarMasks.MaskBR = maskBR

    local TabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TabListShell
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(10)
    })

    ContentArea = create("Frame", {
        Name = "ContentArea",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, tabWidth, 0, TOPBAR_H),
        Size = UDim2.new(1, -tabWidth, 1, -TOPBAR_H),
        Parent = Main
    })

    function window:AddTab(config)
        config = config or {}
        local tabTitle = config.Title or "Tab"
        local icon = config.Icon or ""

        local TabBtn = create("TextButton", {
            Text = "",
            BackgroundColor3 = THEME.Dark.Tertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            ClipsDescendants = true,
            ZIndex = 2,
            Parent = TabList
        }, { corner(8) })

        local RippleLayer = create("Frame", {
            Name = "RippleLayer",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3,
            Parent = TabBtn
        }, { corner(8) })

        local TabLabel = create("TextLabel", {
            Text = tabTitle,
            Font = FONT,
            TextSize = 14,
            TextColor3 = THEME.Dark.SubText,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 4,
            Parent = TabBtn
        })

        local TabScale = create("UIScale", { Scale = 1, Parent = TabBtn })

        local Page = create("ScrollingFrame", {
            Name = tabTitle .. "Page",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = THEME.Dark.Accent,
            Visible = false,
            Parent = ContentArea
        }, {
            padding(14),
            create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
        })

        local PageLayout = Page:FindFirstChildOfClass("UIListLayout")
        local function updateCanvas()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 28)
        end
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        updateCanvas()

        local Tab = { Page = Page, Button = TabBtn, Label = TabLabel, Active = false }

        local function selectTab(clickX, clickY)
            for _, t in pairs(window.Tabs) do
                if t.Active and t ~= Tab then
                    t.Active = false
                    local oldPage = t.Page
                    quickTween(oldPage, { BackgroundTransparency = 1 }, 0.12)
                    for _, d in ipairs(oldPage:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            quickTween(d, { TextTransparency = 1 }, 0.12)
                        end
                    end
                    task.delay(0.13, function() oldPage.Visible = false end)
                else
                    t.Active = false
                end
                quickTween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                quickTween(t.Label, { TextColor3 = THEME.Dark.SubText }, 0.15)
            end

            Tab.Active = true
            Page.Visible = true
            for _, d in ipairs(Page:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    quickTween(d, { TextTransparency = 0 }, 0.15)
                end
            end

            quickTween(TabBtn, { BackgroundTransparency = 0 }, 0.15)
            quickTween(TabLabel, { TextColor3 = THEME.Dark.Text }, 0.15)

            local rx = clickX or TabBtn.AbsoluteSize.X / 2
            local ry = clickY or TabBtn.AbsoluteSize.Y / 2
            spawnRipple(TabBtn, rx, ry, lighten(THEME.Dark.Accent, 0.1), 0.28, 3, RippleLayer)
        end

        TabBtn.MouseButton1Click:Connect(function()
            local mPos = UserInputService:GetMouseLocation()
            local abs = TabBtn.AbsolutePosition
            selectTab(mPos.X - abs.X, mPos.Y - abs.Y)
        end)
        TabBtn.MouseEnter:Connect(function()
            if not Tab.Active then quickTween(TabLabel, { TextColor3 = THEME.Dark.Text }, 0.12) end
            quickTween(TabScale, { Scale = 1.035 }, 0.15)
        end)
        TabBtn.MouseLeave:Connect(function()
            if not Tab.Active then quickTween(TabLabel, { TextColor3 = THEME.Dark.SubText }, 0.12) end
            quickTween(TabScale, { Scale = 1 }, 0.15)
        end)

        table.insert(window.Tabs, Tab)
        if #window.Tabs == 1 then selectTab() end

        -- ===== Tab API methods =====
        function Tab:AddToggle(flag, config)
            config = config or {}
            local state = config.Default or false
            local Title = config.Title or "Toggle"
            local ToggleObj = { Value = state, Flag = flag }

            -- Create UI
            local H = create("Frame", {
                BackgroundColor3 = THEME.Dark.Secondary,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = Page
            }, { corner(8), stroke(THEME.Dark.Stroke, 1) })
            local NameLabel = create("TextLabel", {
                Text = Title,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -54, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = H
            })
            local Sw = create("Frame", {
                BackgroundColor3 = state and THEME.Dark.Accent or THEME.Dark.Tertiary,
                Size = UDim2.new(0, 48, 0, 24),
                Position = UDim2.new(1, -48, 0.5, -12),
                Parent = H
            }, { corner(6) })
            local Kn = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.new(0, 20, 0, 20),
                Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
                Parent = Sw
            }, { corner(4) })
            local Cl = create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.new(1, 0, 1, 0),
                Parent = H
            })

            local handlers = {}
            function ToggleObj:Set(newState, fire)
                state = newState
                ToggleObj.Value = newState
                Fluent.Options[flag] = { Value = newState }
                quickTween(Sw, { BackgroundColor3 = state and THEME.Dark.Accent or THEME.Dark.Tertiary }, 0.18)
                quickTween(Kn, { Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }, 0.18)
                if fire ~= false then
                    for _, fn in ipairs(handlers) do fn(newState) end
                end
            end
            function ToggleObj:OnChanged(handler)
                table.insert(handlers, handler)
                -- Call immediately with initial state? Usually no, but we can.
                -- handler(state)
                return ToggleObj
            end

            Cl.MouseButton1Click:Connect(function()
                ToggleObj:Set(not state)
            end)

            -- Register in Options
            Fluent.Options[flag] = { Value = state }

            -- Refresher for theme updates
            table.insert(Fluent._refreshers, function()
                if not H.Parent then return false end
                NameLabel.TextColor3 = THEME.Dark.Text
                Sw.BackgroundColor3 = state and THEME.Dark.Accent or THEME.Dark.Tertiary
                return true
            end)

            return ToggleObj
        end

        function Tab:AddInput(flag, config)
            config = config or {}
            local Title = config.Title or "Input"
            local Default = config.Default or ""
            local Placeholder = config.Placeholder or ""
            local Numeric = config.Numeric or false
            local Finished = config.Finished or false
            local Callback = config.Callback
            local InputObj = { Value = Default, Flag = flag }

            local H = create("Frame", {
                BackgroundColor3 = THEME.Dark.Secondary,
                Size = UDim2.new(1, 0, 0, 52),
                Parent = Page
            }, { corner(8), stroke(THEME.Dark.Stroke, 1) })
            local NameLabel = create("TextLabel", {
                Text = Title,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = H
            })
            local Box = create("Frame", {
                BackgroundColor3 = THEME.Dark.Tertiary,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 30),
                Parent = H
            }, { corner(8) })
            local Input = create("TextBox", {
                Text = tostring(Default),
                PlaceholderText = Placeholder,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                PlaceholderColor3 = THEME.Dark.SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Box
            })
            Input.Focused:Connect(function() quickTween(Box, { BackgroundColor3 = darken(THEME.Dark.Tertiary, 0.8) }, 0.15) end)
            Input.FocusLost:Connect(function(enter)
                quickTween(Box, { BackgroundColor3 = THEME.Dark.Tertiary }, 0.15)
                if Finished then
                    -- only update on focus lost
                    local val = Input.Text
                    if Numeric then
                        local num = tonumber(val)
                        if num then val = num end
                    end
                    InputObj.Value = val
                    Fluent.Options[flag] = { Value = val }
                    if Callback then Callback(val) end
                end
            end)
            if not Finished then
                Input:GetPropertyChangedSignal("Text"):Connect(function()
                    local val = Input.Text
                    if Numeric then
                        local num = tonumber(val)
                        if num then val = num end
                    end
                    InputObj.Value = val
                    Fluent.Options[flag] = { Value = val }
                    if Callback then Callback(val) end
                end)
            end

            Fluent.Options[flag] = { Value = Default }

            table.insert(Fluent._refreshers, function()
                if not H.Parent then return false end
                NameLabel.TextColor3 = THEME.Dark.Text
                Box.BackgroundColor3 = THEME.Dark.Tertiary
                Input.TextColor3 = THEME.Dark.Text
                return true
            end)

            return InputObj
        end

        function Tab:AddParagraph(config)
            config = config or {}
            local Title = config.Title or ""
            local Content = config.Content or ""

            local H = create("Frame", {
                BackgroundColor3 = THEME.Dark.Secondary,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Page
            }, { corner(8), stroke(THEME.Dark.Stroke, 1), padding(12) })
            local TitleLabel = create("TextLabel", {
                Text = Title,
                Font = FONT_BOLD,
                TextSize = 15,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = H
            })
            local ContentLabel = create("TextLabel", {
                Text = Content,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = H
            })
            return H
        end

        function Tab:AddButton(config)
            config = config or {}
            local Title = config.Title or "Button"
            local Description = config.Description or ""
            local Callback = config.Callback

            local H = create("Frame", {
                BackgroundColor3 = THEME.Dark.Secondary,
                Size = UDim2.new(1, 0, 0, Description ~= "" and 48 or 30),
                Parent = Page
            }, { corner(8), stroke(THEME.Dark.Stroke, 1), padding(8) })
            local Btn = create("TextButton", {
                Text = "",
                BackgroundColor3 = THEME.Dark.Tertiary,
                Size = UDim2.new(1, 0, 1, 0),
                TextColor3 = THEME.Dark.Text,
                Font = FONT_BOLD,
                TextSize = 14,
                Parent = H
            }, { corner(6) })
            Btn.MouseEnter:Connect(function() quickTween(Btn, { BackgroundColor3 = darken(THEME.Dark.Tertiary, 0.8) }, 0.12) end)
            Btn.MouseLeave:Connect(function() quickTween(Btn, { BackgroundColor3 = THEME.Dark.Tertiary }, 0.12) end)
            Btn.MouseButton1Click:Connect(function()
                spawnRipple(Btn, Btn.AbsoluteSize.X / 2, Btn.AbsoluteSize.Y / 2, THEME.Dark.Accent, 0.2)
                if Callback then Callback() end
            end)

            local BtnLabel = create("TextLabel", {
                Text = Title,
                Font = FONT_BOLD,
                TextSize = 14,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, Description ~= "" and 18 or 1, 0),
                Position = UDim2.new(0, 10, Description ~= "" and 0 or 0.5, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Btn
            })

            if Description ~= "" then
                create("TextLabel", {
                    Text = Description,
                    Font = FONT,
                    TextSize = 12,
                    TextColor3 = THEME.Dark.SubText,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 16),
                    Position = UDim2.new(0, 10, 0, 20),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Btn
                })
            end

            table.insert(Fluent._refreshers, function()
                if not H.Parent then return false end
                Btn.BackgroundColor3 = THEME.Dark.Tertiary
                BtnLabel.TextColor3 = THEME.Dark.Text
                return true
            end)

            return H
        end

        function Tab:AddColorpicker(flag, config)
            config = config or {}
            local Title = config.Title or "Color Picker"
            local Default = config.Default or Color3.fromRGB(255, 255, 255)
            local ColorObj = { Value = Default, Flag = flag }
            local open = false
            local h, s, v = Default:ToHSV()
            local BODY_H = 178

            local H = create("Frame", {
                BackgroundColor3 = THEME.Dark.Secondary,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = Page,
                ClipsDescendants = true
            }, { corner(8), stroke(THEME.Dark.Stroke, 1) })

            local Header = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = H
            })
            local NameLabel = create("TextLabel", {
                Text = Title,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Header
            })
            local Preview = create("TextButton", {
                Text = "",
                BackgroundColor3 = Default,
                Size = UDim2.new(0, 28, 0, 20),
                Position = UDim2.new(1, -28, 0.5, -10),
                Parent = Header
            }, { corner(6), stroke(THEME.Dark.Stroke, 1) })

            local Body = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 34),
                Size = UDim2.new(1, 0, 0, 0),
                ClipsDescendants = true,
                Visible = false,
                Parent = H
            })

            local HueBar = create("Frame", {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 24),
                Parent = Body
            }, { corner(6) })
            create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                }),
                Rotation = 0
            }).Parent = HueBar
            local HueCur = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 6, 1, 4),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(h, 0, 0.5, 0),
                Parent = HueBar
            }, { corner(3), stroke(Color3.fromRGB(0, 0, 0), 1) })

            local SVBox = create("ImageLabel", {
                Image = "rbxassetid://4155801252",
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                Size = UDim2.new(1, 0, 0, 146),
                Position = UDim2.new(0, 0, 0, 32),
                Parent = Body
            }, { corner(8) })
            local SVCur = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(s, 0, 1 - v, 0),
                Parent = SVBox
            }, { corner(5), stroke(Color3.fromRGB(0, 0, 0), 1) })

            local handlers = {}
            local function updCol()
                local col = Color3.fromHSV(h, s, v)
                ColorObj.Value = col
                Fluent.Options[flag] = { Value = col }
                Preview.BackgroundColor3 = col
                SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                for _, fn in ipairs(handlers) do fn(col) end
            end
            local function updateSV(pos)
                s = math.clamp((pos.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((pos.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                SVCur.Position = UDim2.new(s, 0, 1 - v, 0)
                updCol()
            end
            local function updateHue(pos)
                h = math.clamp((pos.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                HueCur.Position = UDim2.new(h, 0, 0.5, 0)
                updCol()
            end

            local dragSV, dragHue = false, false
            UserInputService.InputBegan:Connect(function(i)
                if not open then return end
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
                if pointInside(SVBox, i.Position) then
                    dragSV = true
                    updateSV(i.Position)
                elseif pointInside(HueBar, i.Position) then
                    dragHue = true
                    updateHue(i.Position)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragSV = false
                    dragHue = false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
                if dragSV then updateSV(i.Position)
                elseif dragHue then updateHue(i.Position) end
            end)

            Preview.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Body.Visible = true
                    Body.Size = UDim2.new(1, 0, 0, 0)
                    quickTween(H, { Size = UDim2.new(1, 0, 0, 34 + BODY_H) }, 0.2)
                    quickTween(Body, { Size = UDim2.new(1, 0, 0, BODY_H) }, 0.2)
                else
                    quickTween(H, { Size = UDim2.new(1, 0, 0, 30) }, 0.2)
                    quickTween(Body, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                    task.delay(0.22, function() if not open then Body.Visible = false end end)
                end
            end)

            function ColorObj:OnChanged(handler)
                table.insert(handlers, handler)
                return ColorObj
            end

            Fluent.Options[flag] = { Value = Default }

            table.insert(Fluent._refreshers, function()
                if not H.Parent then return false end
                NameLabel.TextColor3 = THEME.Dark.Text
                return true
            end)

            return ColorObj
        end

        function Tab:AddDropdown(flag, config)
            config = config or {}
            local Title = config.Title or "Dropdown"
            local Values = config.Values or {}
            local Multi = config.Multi or false
            local Default = config.Default

            if Multi then
                if type(Default) ~= "table" then Default = {} end
            else
                if type(Default) ~= "number" then Default = 1 end
            end

            local DropdownObj = {}
            if Multi then
                DropdownObj.Value = {}  -- will be a dictionary: {value = true}
            else
                DropdownObj.Value = Values[Default] or (Values[1] or "")
            end

            local H = create("Frame", {
                BackgroundColor3 = THEME.Dark.Secondary,
                Size = UDim2.new(1, 0, 0, 56),
                Parent = Page,
                ClipsDescendants = false
            }, { corner(8), stroke(THEME.Dark.Stroke, 1) })

            local NameLabel = create("TextLabel", {
                Text = Title,
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = H
            })
            local Box = create("TextButton", {
                Text = "",
                BackgroundColor3 = THEME.Dark.Tertiary,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 32),
                Parent = H
            }, { corner(8) })
            Box.MouseEnter:Connect(function() if not open then quickTween(Box, { BackgroundColor3 = darken(THEME.Dark.Tertiary, 0.8) }, 0.15) end end)
            Box.MouseLeave:Connect(function() if not open then quickTween(Box, { BackgroundColor3 = THEME.Dark.Tertiary }, 0.15) end end)

            local SelLabel = create("TextLabel", {
                Text = Multi and "None" or tostring(DropdownObj.Value),
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = Box
            })
            local Arrow = create("TextLabel", {
                Text = "˅",
                Font = FONT,
                TextSize = 14,
                TextColor3 = THEME.Dark.SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 24, 1, 0),
                Position = UDim2.new(1, -28, 0, 0),
                Parent = Box
            })

            local optH = #Values * 30
            local OptionList = create("Frame", {
                BackgroundColor3 = THEME.Dark.Tertiary,
                Size = UDim2.new(1, -24, 0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 20,
                ClipsDescendants = true,
                Visible = false,
                Parent = H
            }, { corner(8), create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

            local function reposOptionList()
                OptionList.Position = UDim2.new(0, 0, 0, H.Position.Y.Offset + 56)
            end
            task.defer(reposOptionList)

            local selectedSet = {}
            if Multi then
                for _, v in ipairs(Default) do
                    selectedSet[v] = true
                end
                DropdownObj.Value = selectedSet
            end

            local function refreshLabel()
                if Multi then
                    local ns = {}
                    for _, o in ipairs(Values) do
                        if selectedSet[o] then ns[#ns+1] = o end
                    end
                    SelLabel.Text = #ns > 0 and table.concat(ns, ", ") or "None"
                    DropdownObj.Value = selectedSet
                    Fluent.Options[flag] = { Value = selectedSet }
                else
                    SelLabel.Text = tostring(DropdownObj.Value)
                    Fluent.Options[flag] = { Value = DropdownObj.Value }
                end
            end
            refreshLabel()

            local handlers = {}
            function DropdownObj:OnChanged(handler)
                table.insert(handlers, handler)
                return DropdownObj
            end

            local optBtns = {}
            local function buildOptionButtons()
                for _, b in ipairs(optBtns) do
                    if b and b.Parent then b:Destroy() end
                end
                optBtns = {}

                for i, opt in ipairs(Values) do
                    local isSel = Multi and selectedSet[opt] or (not Multi and opt == DropdownObj.Value)
                    local OB = create("TextButton", {
                        Text = tostring(opt),
                        Font = FONT,
                        TextSize = 13,
                        TextColor3 = isSel and THEME.Dark.Accent or THEME.Dark.SubText,
                        BackgroundColor3 = THEME.Dark.Tertiary,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        LayoutOrder = i,
                        ZIndex = 21,
                        Parent = OptionList
                    })
                    OB.MouseEnter:Connect(function() quickTween(OB, { BackgroundTransparency = 0.6 }, 0.1) end)
                    OB.MouseLeave:Connect(function() quickTween(OB, { BackgroundTransparency = 1 }, 0.1) end)
                    OB.MouseButton1Click:Connect(function()
                        if Multi then
                            selectedSet[opt] = not selectedSet[opt]
                            OB.TextColor3 = selectedSet[opt] and THEME.Dark.Accent or THEME.Dark.SubText
                            refreshLabel()
                            for _, fn in ipairs(handlers) do fn(selectedSet) end
                        else
                            DropdownObj.Value = opt
                            refreshLabel()
                            for _, b in pairs(optBtns) do b.TextColor3 = THEME.Dark.SubText end
                            OB.TextColor3 = THEME.Dark.Accent
                            for _, fn in ipairs(handlers) do fn(opt) end
                            open = false
                            quickTween(Arrow, { Rotation = 0 }, 0.18)
                            quickTween(OptionList, { Size = UDim2.new(1, -24, 0, 0) }, 0.18)
                            task.delay(0.2, function() if not open then OptionList.Visible = false end end)
                            quickTween(Box, { BackgroundColor3 = THEME.Dark.Tertiary }, 0.12)
                        end
                    end)
                    optBtns[#optBtns+1] = OB
                end
            end

            buildOptionButtons()

            Box.MouseButton1Click:Connect(function()
                reposOptionList()
                open = not open
                quickTween(Arrow, { Rotation = open and 180 or 0 }, 0.18)
                if open then
                    OptionList.Visible = true
                    OptionList.Size = UDim2.new(1, -24, 0, 0)
                    quickTween(OptionList, { Size = UDim2.new(1, -24, 0, optH) }, 0.18)
                    quickTween(Box, { BackgroundColor3 = darken(THEME.Dark.Tertiary, 0.8) }, 0.12)
                else
                    quickTween(OptionList, { Size = UDim2.new(1, -24, 0, 0) }, 0.18)
                    task.delay(0.2, function() if not open then OptionList.Visible = false end end)
                    quickTween(Box, { BackgroundColor3 = THEME.Dark.Tertiary }, 0.12)
                end
            end)

            table.insert(Fluent._refreshers, function()
                if not H.Parent then return false end
                NameLabel.TextColor3 = THEME.Dark.Text
                Box.BackgroundColor3 = THEME.Dark.Tertiary
                Arrow.TextColor3 = THEME.Dark.SubText
                OptionList.BackgroundColor3 = THEME.Dark.Tertiary
                for _, b in pairs(optBtns) do
                    local isSel = Multi and selectedSet[b.Text] or (not Multi and b.Text == tostring(DropdownObj.Value))
                    b.TextColor3 = isSel and THEME.Dark.Accent or THEME.Dark.SubText
                end
                return true
            end)

            return DropdownObj
        end

        return Tab
    end

    function window:Dialog(config)
        config = config or {}
        local title = config.Title or "Dialog"
        local content = config.Content or ""
        local buttons = config.Buttons or {}

        local Overlay = create("Frame", {
            Name = "DialogOverlay",
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 50,
            Parent = Main
        })
        quickTween(Overlay, { BackgroundTransparency = 0.55 }, 0.2)

        local Card = create("Frame", {
            BackgroundColor3 = THEME.Dark.Secondary,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 320, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 51,
            Parent = Overlay
        }, { corner(14), stroke(THEME.Dark.Accent, 2), padding(20) })

        local inner = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 52,
            Parent = Card
        }, {
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 14),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            })
        })

        create("TextLabel", {
            Text = title,
            Font = FONT_BOLD,
            TextSize = 17,
            TextColor3 = THEME.Dark.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = inner
        })
        create("TextLabel", {
            Text = content,
            Font = FONT,
            TextSize = 13,
            TextColor3 = THEME.Dark.SubText,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Parent = inner
        })

        if #buttons > 0 then
            local btnRow = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                LayoutOrder = 3,
                Parent = inner
            }, {
                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right
                })
            })
            for i, btn in ipairs(buttons) do
                local b = create("TextButton", {
                    Text = btn.Title or "OK",
                    Font = FONT,
                    TextSize = 13,
                    TextColor3 = THEME.Dark.Text,
                    BackgroundColor3 = i == 1 and THEME.Dark.Accent or THEME.Dark.Tertiary,
                    Size = UDim2.new(0, 90, 0, 30),
                    LayoutOrder = i,
                    Parent = btnRow
                }, { corner(7) })
                b.MouseButton1Click:Connect(function()
                    if btn.Callback then btn.Callback() end
                    quickTween(Overlay, { BackgroundTransparency = 1 }, 0.2)
                    task.wait(0.22)
                    Overlay:Destroy()
                end)
            end
        else
            -- default close button
            local closeBtn = create("TextButton", {
                Text = "OK",
                Font = FONT,
                TextSize = 13,
                TextColor3 = THEME.Dark.Text,
                BackgroundColor3 = THEME.Dark.Accent,
                Size = UDim2.new(0, 90, 0, 30),
                LayoutOrder = 3,
                Parent = inner
            }, { corner(7) })
            closeBtn.MouseButton1Click:Connect(function()
                quickTween(Overlay, { BackgroundTransparency = 1 }, 0.2)
                task.wait(0.22)
                Overlay:Destroy()
            end)
        end

        Card.BackgroundTransparency = 1
        quickTween(Card, { BackgroundTransparency = 0 }, 0.25)
    end

    -- Initial animation
    Main.Size = UDim2.new(size.X.Scale, size.X.Offset * 0.4, size.Y.Scale, size.Y.Offset * 0.4)
    Main.BackgroundTransparency = 1
    tween(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = size,
        BackgroundTransparency = 0
    })

    return window
end

-- Initialize
Fluent:Init()

return Fluent
