--[[
    ██████╗░██████╗░██╗██████╗░██╗░░░░░██╗██╗░░██╗██╗░░██╗
    ██╔══██╗██╔══██╗██║██╔══██╗██║░░░░░██║╚██╗██╔╝╚██╗██╔╝
    ██║░░██║██████╔╝██║██████╔╝██║░░░░░██║░╚███╔╝░░╚███╔╝░
    ██║░░██║██╔══██╗██║██╔══██╗██║░░░░░██║░██╔██╗░░██╔██╗░░
    ██████╔╝██║░░██║██║██║░░██║███████╗██║██╔╝╚██╗░░██║░░░
    ╚═════╝░╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚══════╝╚═╝╚═╝░░╚═╝░░╚═╝░░░
    CuteWare UI Library — standalone
]]

-- ===== SERVICES =====
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ===== THEME =====
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

local STARTUP_SOUND_ID = "rbxassetid://135244211779631"

-- ===== HELPERS =====
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
        PaddingTop    = UDim.new(0, a), PaddingBottom = UDim.new(0, a),
        PaddingLeft   = UDim.new(0, a), PaddingRight  = UDim.new(0, a),
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

local imageCache = {}
local function resolveImage(source)
    if source == nil or source == "" then return nil end
    if typeof(source) == "number" then return "rbxassetid://" .. source end
    source = tostring(source)
    if source:match("^rbxassetid://") or source:match("^rbxthumb://") then return source end
    if source:match("^https?://") then
        if imageCache[source] then return imageCache[source] end
        local ok, result = pcall(function()
            if writefile and getcustomasset then
                local fileName = "cuteware_img_" .. tostring(#source) .. ".png"
                if not (isfile and isfile(fileName)) then
                    local bytes = game:HttpGet(source)
                    writefile(fileName, bytes)
                end
                return getcustomasset(fileName)
            end
            return nil
        end)
        if ok and result then
            imageCache[source] = result
            return result
        end
        return nil
    end
    return "rbxassetid://" .. source
end

local function spawnRipple(button, relX, relY, color, fillDuration, rippleZIndex, parentOverride)
    fillDuration = fillDuration or 0.22
    local w, h = button.AbsoluteSize.X, button.AbsoluteSize.Y
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
    if not keep.TopLeft     then mask("MaskTL", UDim2.new(0, 0, 0, 0)) end
    if not keep.TopRight    then mask("MaskTR", UDim2.new(1, -radius, 0, 0)) end
    if not keep.BottomLeft  then mask("MaskBL", UDim2.new(0, 0, 1, -radius)) end
    if not keep.BottomRight then mask("MaskBR", UDim2.new(1, -radius, 1, -radius)) end

    local function sync()
        local t, c = panel.BackgroundTransparency, panel.BackgroundColor3
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

local function makeNoOpProxy()
    local proxy = {}
    setmetatable(proxy, {
        __index = function(_, _) return function(...) return proxy end end,
    })
    return proxy
end

-- ===== LIBRARY CORE =====
local CuteWare = {}
CuteWare.__index = CuteWare
CuteWare.Flags = {}
CuteWare._refreshers = {}

local function registerRefresh(fn)
    table.insert(CuteWare._refreshers, fn)
end

function CuteWare:SetAccentColor(color, darkColor)
    if not color then return end
    Theme.Accent = color
    Theme.AccentDark = darkColor or darken(color, 0.8)
end

function CuteWare:Refresh()
    local alive = {}
    for _, fn in ipairs(self._refreshers) do
        local ok, keep = pcall(fn)
        if ok and keep ~= false then table.insert(alive, fn) end
    end
    self._refreshers = alive
end

function CuteWare:Init()
    local ex = PlayerGui:FindFirstChild("CuteWare")
    if ex then ex:Destroy() end

    local sg = create("ScreenGui", {
        Name = "CuteWare", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999, Parent = PlayerGui,
    })
    self.ScreenGui = sg

    self._notifHolderTR = create("Frame", {
        Name = "NotifTR", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        Parent = sg,
    }, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    self._notifHolderBR = create("Frame", {
        Name = "NotifBR", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -40),
        Parent = sg,
    }, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    self._mainFrame = nil
    self._refreshers = {}
    self._keySystemFailed = false

    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = STARTUP_SOUND_ID
        s.Volume = 0.6
        s.Parent = SoundService
        s:Play()
        Debris:AddItem(s, 6)
    end)

    return self
end

-- ===== KEY SYSTEM =====
function CuteWare:CreateKeySystem(config)
    config = config or {}
    if not config.Enabled then return true end

    local validKeys = {}
    if type(config.Key) == "table" then
        for _, k in ipairs(config.Key) do validKeys[k] = true end
    else
        validKeys[tostring(config.Key or "")] = true
    end

    local sg = self.ScreenGui
    local approved = false
    local closedManually = false

    local blur = create("BlurEffect", { Name = "CuteWareKeyBlur", Size = 0, Parent = Lighting })
    quickTween(blur, { Size = 22 }, 0.35)

    local Overlay = create("Frame", {
        Name = "KeySystem",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 900, Parent = sg,
    })
    quickTween(Overlay, { BackgroundTransparency = 0.45 }, 0.25)

    local Card = create("Frame", {
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 224),
        ZIndex = 901, Parent = Overlay,
    }, { corner(14), stroke(Theme.Stroke, 1) })

    local CloseBtn = create("TextButton", {
        Text = "╳", Font = Theme.FontBold, TextSize = 16, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -32, 0, 10), Size = UDim2.new(0, 22, 0, 22),
        ZIndex = 903, Parent = Card,
    })
    CloseBtn.MouseEnter:Connect(function() quickTween(CloseBtn, { TextColor3 = Theme.Error }, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() quickTween(CloseBtn, { TextColor3 = Theme.SubText }, 0.15) end)

    create("TextLabel", {
        Text = config.Title or "cuteware — key system",
        Font = Theme.FontBold, TextSize = 16, TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 18), Size = UDim2.new(1, -64, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 902, Parent = Card,
    })
    create("TextLabel", {
        Text = config.Note or "Enter your key to continue.",
        Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, TextWrapped = true,
        Position = UDim2.new(0, 20, 0, 44), Size = UDim2.new(1, -40, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 902, Parent = Card,
    })

    local InputBox = create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        Position = UDim2.new(0, 20, 0, 92), Size = UDim2.new(1, -40, 0, 36),
        ZIndex = 902, Parent = Card,
    }, { corner(8) })
    local Input = create("TextBox", {
        Text = "", PlaceholderText = "Key here...",
        Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText, BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 903, Parent = InputBox,
    })

    local SubmitBtn = create("TextButton", {
        Text = "Submit", Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 20, 0, 140), Size = UDim2.new(1, -40, 0, 36),
        ZIndex = 902, Parent = Card,
    }, { corner(8) })
    SubmitBtn.MouseEnter:Connect(function() quickTween(SubmitBtn, { BackgroundColor3 = darken(Theme.Accent, 0.85) }, 0.15) end)
    SubmitBtn.MouseLeave:Connect(function() quickTween(SubmitBtn, { BackgroundColor3 = Theme.Accent }, 0.15) end)

    local StatusLabel = create("TextLabel", {
        Text = "", Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Error,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 182), Size = UDim2.new(1, -40, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 902, Parent = Card,
    })

    local function shake()
        local orig = Card.Position
        for _ = 1, 3 do
            quickTween(Card, { Position = orig + UDim2.new(0, 8, 0, 0) }, 0.05); task.wait(0.06)
            quickTween(Card, { Position = orig - UDim2.new(0, 8, 0, 0) }, 0.05); task.wait(0.06)
        end
        quickTween(Card, { Position = orig }, 0.05)
    end

    local function tryKey()
        if Input.Text ~= "" and validKeys[Input.Text] then
            approved = true
        else
            StatusLabel.Text = "Invalid key, try again."
            task.spawn(shake)
        end
    end

    SubmitBtn.MouseButton1Click:Connect(tryKey)
    Input.FocusLost:Connect(function(enter) if enter then tryKey() end end)
    CloseBtn.MouseButton1Click:Connect(function() closedManually = true end)

    repeat task.wait() until approved or closedManually

    quickTween(blur, { Size = 0 }, 0.3)
    quickTween(Overlay, { BackgroundTransparency = 1 }, 0.2)
    task.wait(0.3)
    blur:Destroy()
    Overlay:Destroy()

    if closedManually and not approved then
        self._keySystemFailed = true
        if config.OnClose then config.OnClose() end
        return false
    end
    return true
end

-- ===== NOTIFICATIONS =====
function CuteWare:Notify(config)
    config = config or {}
    local title    = config.Title or "Notification"
    local content  = config.Content or ""
    local duration = config.Duration
    if duration == nil then duration = 4 end
    local pos = config.Position or "TopRight"

    local holder = pos == "BottomRight" and self._notifHolderBR or self._notifHolderTR

    local Frame = create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true, Parent = holder,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    local Inner = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = Frame,
    }, {
        padding(14),
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    local TitleRow = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1, Parent = Inner,
    })
    create("TextLabel", {
        Text = title, Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleRow,
    })
    local XBtn = create("TextButton", {
        Text = "╳", Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, -1), Parent = TitleRow,
    })
    XBtn.MouseEnter:Connect(function() quickTween(XBtn, { TextColor3 = Theme.Error }, 0.12) end)
    XBtn.MouseLeave:Connect(function() quickTween(XBtn, { TextColor3 = Theme.SubText }, 0.12) end)

    create("TextLabel", {
        Text = content, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = Inner,
    })

    local TimerLabel, ProgressFill
    if duration > 0 then
        local FooterRow = create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = 3, Parent = Inner,
        })
        TimerLabel = create("TextLabel", {
            Text = math.ceil(duration) .. "s",
            Font = Theme.Font, TextSize = 11, TextColor3 = Theme.SubText,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = FooterRow,
        })
        local ProgressBar = create("Frame", {
            BackgroundColor3 = darken(Theme.Tertiary, 0.9),
            Size = UDim2.new(1, 0, 0, 3), LayoutOrder = 4, Parent = Inner,
        }, { corner(2) })
        ProgressFill = create("Frame", {
            BackgroundColor3 = Theme.Accent, Size = UDim2.new(1, 0, 1, 0), Parent = ProgressBar,
        }, { corner(2) })
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
        tween(ProgressFill,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 0, 1, 0) }
        )
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

function CuteWare:NotifyBig(config)
    config = config or {}
    local title    = config.Title or "Notice"
    local content  = config.Content or ""
    local duration = config.Duration or 5
    local iconSide = config.IconSide or 1
    local buttons  = config.Buttons or {}

    local parent = self._mainFrame or self.ScreenGui
    if not parent or not parent.Parent then return end

    local Overlay = create("Frame", {
        Name = "BigNotifOverlay",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 50, Parent = parent,
    })
    quickTween(Overlay, { BackgroundTransparency = 0.55 }, 0.2)

    local Card = create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 51, Parent = Overlay,
    }, { corner(14), stroke(Theme.Accent, 2), padding(20) })

    local inner = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 52, Parent = Card,
    })
    create("UIListLayout", {
        FillDirection     = iconSide == 1 and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        Padding           = UDim.new(0, 14),
        SortOrder         = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = iconSide == 2 and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left,
    }).Parent = inner

    local resolvedIcon = resolveImage(config.Icon)
    if resolvedIcon then
        create("ImageLabel", {
            Image = resolvedIcon,
            BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 0.3,
            Size = UDim2.new(0, 52, 0, 52), LayoutOrder = 1,
            ZIndex = 53, Parent = inner,
        }, { corner(10) })
    end

    local textBlock = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(resolvedIcon and iconSide == 1 and 0 or 1,
                         resolvedIcon and iconSide == 1 and 220 or 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2, ZIndex = 52, Parent = inner,
    }, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

    create("TextLabel", {
        Text = title, Font = Theme.FontBold, TextSize = 17, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 53, Parent = textBlock,
    })
    create("TextLabel", {
        Text = content, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, ZIndex = 53, Parent = textBlock,
    })

    if #buttons > 0 then
        local btnRow = create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34),
            LayoutOrder = 3, ZIndex = 53, Parent = textBlock,
        }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
        for i, btn in ipairs(buttons) do
            if i > 2 then break end
            local b = create("TextButton", {
                Text = btn.Text or "OK",
                Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundColor3 = i == 1 and Theme.Accent or Theme.Tertiary,
                Size = UDim2.new(0, 90, 0, 30), LayoutOrder = i,
                ZIndex = 54, Parent = btnRow,
            }, { corner(7) })
            b.MouseButton1Click:Connect(function()
                if btn.Callback then btn.Callback() end
                quickTween(Overlay, { BackgroundTransparency = 1 }, 0.2)
                task.wait(0.22); Overlay:Destroy()
            end)
        end
    end

    Card.BackgroundTransparency = 1
    quickTween(Card, { BackgroundTransparency = 0 }, 0.25)

    task.delay(duration, function()
        if not Overlay.Parent then return end
        quickTween(Overlay, { BackgroundTransparency = 1 }, 0.22)
        task.wait(0.25); Overlay:Destroy()
    end)
end

-- ===== WINDOW =====
function CuteWare:CreateWindow(config)
    config = config or {}

    if self._keySystemFailed then
        warn("[CuteWare] Key system was closed without a valid key - window not created.")
        return makeNoOpProxy()
    end

    if config.AccentColor then
        CuteWare:SetAccentColor(config.AccentColor, config.AccentColorDark)
    end

    local windowName = config.Name or "CuteWare"
    local subtitle   = config.Subtitle
    local size       = config.Size or UDim2.new(0, 560, 0, 380)
    local titleIcon  = resolveImage(config.Icon)
    local bgImage    = resolveImage(config.BackgroundImage)
    local bgTransp   = config.BackgroundImageTransparency or 0.75
    local useComponentGradient = config.ComponentGradient ~= false

    local TOPBAR_H = 38
    local MIN_SIZE = UDim2.new(0, 200, 0, TOPBAR_H)

    local Window = {}
    Window.Tabs = {}

    local Main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Parent = self.ScreenGui,
        ClipsDescendants = true,
    }, { corner(12), stroke(Theme.Stroke, 1) })
    self._mainFrame = Main
    registerRefresh(function()
        if not Main.Parent then return false end
        Main.BackgroundColor3 = Theme.Background
    end)

    local FadeCover = create("Frame", {
        Name = "FadeCover",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1000, Active = true, Visible = false, Parent = Main,
    }, { corner(12) })
    registerRefresh(function()
        if not FadeCover.Parent then return false end
        FadeCover.BackgroundColor3 = Theme.Background
    end)

    local BackgroundImage
    if bgImage then
        BackgroundImage = create("ImageLabel", {
            Name = "CustomBackground", Image = bgImage,
            BackgroundTransparency = 1, ImageTransparency = bgTransp,
            ScaleType = Enum.ScaleType.Crop, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0, Parent = Main,
        }, { corner(12) })
    end

    function Window:SetBackgroundImage(imageSource, transparency)
        local resolved = resolveImage(imageSource)
        if not resolved then return end
        if not BackgroundImage then
            BackgroundImage = create("ImageLabel", {
                Name = "CustomBackground", BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Crop, Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 0, Parent = Main,
            }, { corner(12) })
        end
        BackgroundImage.Image = resolved
        BackgroundImage.ImageTransparency = transparency or bgTransp
        bgImage = resolved
    end

    function Window:Refresh()
        pcall(function() CuteWare:Refresh() end)
    end

    Main.Size = UDim2.new(0, size.X.Offset * 0.4, 0, size.Y.Offset * 0.4)
    Main.BackgroundTransparency = 1
    tween(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = size, BackgroundTransparency = 0,
    })

    local TopBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = darken(Theme.Secondary, 0.92),
        BackgroundTransparency = bgImage and 0.6 or 0,
        Size = UDim2.new(1, 0, 0, TOPBAR_H), Parent = Main,
    })
    registerRefresh(function()
        if not TopBar.Parent then return false end
        TopBar.BackgroundColor3 = darken(Theme.Secondary, 0.92)
    end)
    local topBarMasks = applyPanelCorners(TopBar, 12,
        { TopLeft = true, TopRight = true, BottomLeft = false, BottomRight = false },
        bgImage ~= nil)

    local titleOffset = 16
    if titleIcon then
        create("ImageLabel", {
            Image = titleIcon, BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(0, 12, 0.5, -11),
            Parent = TopBar,
        })
        titleOffset = 40
    end

    if subtitle and subtitle ~= "" then
        local TitleLabel = create("TextLabel", {
            Text = windowName, Font = Theme.FontBold, TextSize = 16, TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, titleOffset, 0, 4), Size = UDim2.new(1, -titleOffset - 110, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
        })
        local SubtitleLabel = create("TextLabel", {
            Text = subtitle, Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, titleOffset, 0, 20), Size = UDim2.new(1, -titleOffset - 110, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
        })
        registerRefresh(function()
            if not TitleLabel.Parent then return false end
            TitleLabel.TextColor3 = Theme.Text
            SubtitleLabel.TextColor3 = Theme.SubText
        end)
    else
        local TitleLabel = create("TextLabel", {
            Text = windowName, Font = Theme.FontBold, TextSize = 20, TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, titleOffset, 0, 0), Size = UDim2.new(1, -titleOffset - 110, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
        })
        registerRefresh(function()
            if not TitleLabel.Parent then return false end
            TitleLabel.TextColor3 = Theme.Text
        end)
    end

    local DragCatcher = create("Frame", {
        Name = "DragCatcher",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = TopBar,
    })

    local Controls = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 96, 0, 26), Parent = TopBar,
    }, { create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
    }) })

    local function makeCtrlBtn(text, hoverBg, hoverText, order)
        local b = create("TextButton", {
            Text = text, Font = Theme.FontBold, TextSize = 15,
            TextColor3 = Theme.SubText, BackgroundColor3 = hoverBg,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 28, 0, 26), LayoutOrder = order, Parent = Controls,
        }, { corner(6) })
        b.MouseEnter:Connect(function() quickTween(b, { BackgroundTransparency = 0, TextColor3 = hoverText }, 0.15) end)
        b.MouseLeave:Connect(function() quickTween(b, { BackgroundTransparency = 1, TextColor3 = Theme.SubText }, 0.15) end)
        registerRefresh(function()
            if not b.Parent then return false end
            b.TextColor3 = Theme.SubText
        end)
        return b
    end

    local MinBtn   = makeCtrlBtn("—", darken(Theme.Tertiary, 0.9), Theme.Accent, 1)
    local MaxBtn   = makeCtrlBtn("▢", darken(Theme.Tertiary, 0.9), Theme.Accent, 2)
    local CloseBtn = makeCtrlBtn("╳", darken(Theme.Error, 0.5), Theme.Text, 3)

    local minimized, maximized = false, false
    local windowSize = size
    local windowPos  = Main.Position
    local TabListShell, ContentArea

    local function hideCtrlBtns()
        MaxBtn.Visible   = false
        CloseBtn.Visible = false
    end
    local function showCtrlBtns()
        MaxBtn.Visible   = true
        CloseBtn.Visible = true
    end

    local function setMinVisual(isMin)
        if topBarMasks.MaskBL then topBarMasks.MaskBL.Visible = not isMin end
        if topBarMasks.MaskBR then topBarMasks.MaskBR.Visible = not isMin end
        MinBtn.Text = isMin and "▲" or "—"
        if isMin then hideCtrlBtns() else showCtrlBtns() end
    end

    local clearDrag

    MinBtn.MouseButton1Click:Connect(function()
        if maximized then return end
        minimized = not minimized
        if clearDrag then clearDrag() end
        if minimized then
            TabListShell.Visible = false
            ContentArea.Visible  = false
            quickTween(Main, { Size = MIN_SIZE }, 0.28)
        else
            TabListShell.Visible = true
            ContentArea.Visible  = true
            quickTween(Main, { Size = windowSize }, 0.28)
        end
        setMinVisual(minimized)
    end)

    MaxBtn.MouseButton1Click:Connect(function()
        if clearDrag then clearDrag() end
        if not maximized then
            if minimized then
                minimized = false
                TabListShell.Visible = true
                ContentArea.Visible  = true
                setMinVisual(false)
            end
            maximized = true
            quickTween(Main, { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) }, 0.28)
        else
            maximized = false
            quickTween(Main, { Size = windowSize, Position = windowPos }, 0.28)
        end
    end)

    local function currentTargetSizePos()
        if maximized then
            return UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0)
        elseif minimized then
            return MIN_SIZE, windowPos
        else
            return windowSize, windowPos
        end
    end

    local transitioning = false

    function Window:Close()
        if transitioning then return end
        transitioning = true
        FadeCover.Visible = true
        FadeCover.BackgroundTransparency = 1
        quickTween(FadeCover, { BackgroundTransparency = 0 }, 0.2)
        local curSize = Main.Size
        quickTween(Main, {
            Size = UDim2.new(
                curSize.X.Scale, curSize.X.Offset * 0.9,
                curSize.Y.Scale, curSize.Y.Offset * 0.9
            ),
        }, 0.22)
        task.wait(0.22)
        Main.Visible = false
        transitioning = false
    end

    function Window:Open()
        if transitioning then return end
        transitioning = true
        Main.Visible = true
        local targetSize, targetPos = currentTargetSizePos()
        FadeCover.Visible = true
        FadeCover.BackgroundTransparency = 0
        Main.Size = UDim2.new(
            targetSize.X.Scale, targetSize.X.Offset * 0.9,
            targetSize.Y.Scale, targetSize.Y.Offset * 0.9
        )
        Main.Position = targetPos
        tween(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize, Position = targetPos,
        })
        task.delay(0.12, function()
            quickTween(FadeCover, { BackgroundTransparency = 1 }, 0.22)
            task.delay(0.24, function() FadeCover.Visible = false end)
        end)
        task.delay(0.3, function() transitioning = false end)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        task.spawn(function() Window:Close() end)
    end)

    local toggleKey = config.ToggleKeybind or Enum.KeyCode.RightControl
    local toggling = false

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            if toggling then return end
            toggling = true
            task.spawn(function()
                if Main.Visible then Window:Close() else Window:Open() end
                toggling = false
            end)
        end
    end)

    -- Dragging with smooth lerp
    do
        local dragging = false
        local dragStart, startPos
        local targetPos

        clearDrag = function() targetPos = nil; dragging = false end

        DragCatcher.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

            if maximized then
                maximized = false
                local halfW = windowSize.X.Offset / 2
                local newX  = input.Position.X - halfW
                local newY  = input.Position.Y - TOPBAR_H / 2
                Main.Size     = windowSize
                Main.Position = UDim2.new(0, newX, 0, newY)
                windowPos     = Main.Position
            end

            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging  = false
                    windowPos = Main.Position
                end
            end)
        end)

        UserInputService.InputChanged:Connect(function(input)
            if maximized then return end
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                          or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                targetPos = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end)

        RunService.RenderStepped:Connect(function(dt)
            if targetPos and not maximized then
                Main.Position = Main.Position:Lerp(targetPos, math.clamp(dt * 16, 0, 1))
                windowPos = Main.Position
            end
        end)
    end

    TabListShell = create("Frame", {
        Name = "TabListShell",
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = bgImage and 0.65 or 0,
        Position = UDim2.new(0, 0, 0, TOPBAR_H),
        Size = UDim2.new(0, 140, 1, -TOPBAR_H), Parent = Main,
    })
    registerRefresh(function()
        if not TabListShell.Parent then return false end
        TabListShell.BackgroundColor3 = Theme.Secondary
    end)
    applyPanelCorners(TabListShell, 12,
        { TopLeft = false, TopRight = false, BottomLeft = true, BottomRight = false },
        bgImage ~= nil)

    local TabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), Parent = TabListShell,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(10),
    })

    ContentArea = create("Frame", {
        Name = "ContentArea",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 140, 0, TOPBAR_H),
        Size = UDim2.new(1, -140, 1, -TOPBAR_H), Parent = Main,
    })

    function Window:AddTabButton(c)
        c = c or {}
        local Btn = create("TextButton", {
            Text = c.Name or "Action", Font = Theme.Font, TextSize = 13,
            TextColor3 = Theme.SubText,
            BackgroundColor3 = darken(Theme.Secondary, 0.8),
            BackgroundTransparency = bgImage and 0.7 or 0,
            Size = UDim2.new(1, 0, 0, 30),
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Parent = TabListShell,
        }, { corner(7) })
        Btn.MouseEnter:Connect(function() quickTween(Btn, { TextColor3 = Theme.Accent }, 0.12) end)
        Btn.MouseLeave:Connect(function() quickTween(Btn, { TextColor3 = Theme.SubText }, 0.12) end)
        Btn.MouseButton1Click:Connect(function()
            if c.Callback then c.Callback() end
        end)
        registerRefresh(function()
            if not Btn.Parent then return false end
            Btn.BackgroundColor3 = darken(Theme.Secondary, 0.8)
            Btn.TextColor3 = Theme.SubText
        end)
        return Btn
    end

    -- ===== TABS =====
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"

        local tabActiveTransparency = bgImage and 0.35 or 0

        local TabBtn = create("TextButton", {
            Text = "",
            BackgroundColor3 = Theme.Tertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            ClipsDescendants = true, ZIndex = 2, Parent = TabList,
        }, { corner(8) })

        local RippleLayer = create("Frame", {
            Name = "RippleLayer",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = TabBtn,
        }, { corner(8) })

        local TabLabel = create("TextLabel", {
            Text = tabName, Font = Theme.Font, TextSize = 14,
            TextColor3 = Theme.SubText, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 4, Parent = TabBtn,
        })

        local TabScale = create("UIScale", { Scale = 1, Parent = TabBtn })

        local Page = create("ScrollingFrame", {
            Name = tabName .. "Page", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false, Parent = ContentArea,
        }, {
            padding(14),
            create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        local PageLayout = Page:FindFirstChildOfClass("UIListLayout")
        local function updateCanvas()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 28)
        end
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        updateCanvas()

        local Tab = { Page = Page, Button = TabBtn, Label = TabLabel, Active = false }

        registerRefresh(function()
            if not TabBtn.Parent then return false end
            TabBtn.BackgroundColor3 = Theme.Tertiary
            Page.ScrollBarImageColor3 = Theme.Accent
            TabLabel.TextColor3 = Tab.Active and Theme.Text or Theme.SubText
        end)

        local function selectTab(clickX, clickY)
            for _, t in pairs(Window.Tabs) do
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
                quickTween(t.Label,  { TextColor3 = Theme.SubText }, 0.15)
            end

            Tab.Active   = true
            Page.Visible = true
            for _, d in ipairs(Page:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    quickTween(d, { TextTransparency = 0 }, 0.15)
                end
            end

            quickTween(TabBtn,   { BackgroundTransparency = tabActiveTransparency }, 0.15)
            quickTween(TabLabel, { TextColor3 = Theme.Text }, 0.15)

            local rx = clickX or TabBtn.AbsoluteSize.X / 2
            local ry = clickY or TabBtn.AbsoluteSize.Y / 2
            spawnRipple(TabBtn, rx, ry, lighten(Theme.Accent, 0.1), 0.28, 3, RippleLayer)
        end

        TabBtn.MouseButton1Click:Connect(function()
            local mPos = UserInputService:GetMouseLocation()
            local abs  = TabBtn.AbsolutePosition
            selectTab(mPos.X - abs.X, mPos.Y - abs.Y)
        end)
        TabBtn.MouseEnter:Connect(function()
            if not Tab.Active then quickTween(TabLabel, { TextColor3 = Theme.Text }, 0.12) end
            quickTween(TabScale, { Scale = 1.035 }, 0.15)
        end)
        TabBtn.MouseLeave:Connect(function()
            if not Tab.Active then quickTween(TabLabel, { TextColor3 = Theme.SubText }, 0.12) end
            quickTween(TabScale, { Scale = 1 }, 0.15)
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then selectTab() end

        -- ===== SECTIONS =====
        function Tab:CreateSection(name)
            local SH = create("Frame", {
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = bgImage and 0.6 or 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, Parent = Page,
            }, {
                corner(10), stroke(Theme.Stroke, 1), padding(12),
                create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
            })
            registerRefresh(function()
                if not SH.Parent then return false end
                SH.BackgroundColor3 = Theme.Secondary
            end)

            if useComponentGradient then
                create("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    },
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0.85),
                        NumberSequenceKeypoint.new(1, 0.95)
                    },
                    Rotation = 90
                }).Parent = SH
            end

            local SectionTitle = create("TextLabel", {
                Text = name or "Section", Font = Theme.FontBold, TextSize = 14,
                TextColor3 = Theme.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = SH,
            })
            registerRefresh(function()
                if not SectionTitle.Parent then return false end
                SectionTitle.TextColor3 = Theme.Text
            end)

            local Section = { Holder = SH }

            -- ===== BUTTON =====
            function Section:CreateButton(c)
                c = c or {}
                local Btn = create("TextButton", {
                    Text = c.Name or "Button", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.Text, BackgroundColor3 = Theme.Tertiary,
                    BackgroundTransparency = bgImage and 0.5 or 0,
                    Size = UDim2.new(1, 0, 0, 34), Parent = SH,
                }, { corner(8) })
                Btn.MouseEnter:Connect(function() quickTween(Btn, { BackgroundColor3 = darken(Theme.Tertiary, 0.75) }, 0.15) end)
                Btn.MouseLeave:Connect(function() quickTween(Btn, { BackgroundColor3 = Theme.Tertiary }, 0.15) end)
                Btn.MouseButton1Down:Connect(function() quickTween(Btn, { Size = UDim2.new(1, -6, 0, 32) }, 0.08) end)
                Btn.MouseButton1Up:Connect(function() quickTween(Btn, { Size = UDim2.new(1, 0, 0, 34) }, 0.12) end)
                Btn.MouseButton1Click:Connect(function() if c.Callback then c.Callback() end end)
                registerRefresh(function()
                    if not Btn.Parent then return false end
                    Btn.BackgroundColor3 = Theme.Tertiary
                    Btn.TextColor3 = Theme.Text
                end)
                return Btn
            end

            function Section:CreateCloseButton(c)
                c = c or {}
                return Section:CreateButton({
                    Name = c.Name or "Close",
                    Callback = function()
                        task.spawn(function() Window:Close() end)
                        if c.Callback then c.Callback() end
                    end,
                })
            end

            -- ===== TOGGLE =====
            function Section:CreateToggle(c)
                c = c or {}
                local state = c.CurrentValue or false
                local flag = c.Flag
                local H = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = SH })
                local NameLabel = create("TextLabel", {
                    Text = c.Name or "Toggle", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -54, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = H,
                })
                local Sw = create("Frame", {
                    BackgroundColor3 = state and Theme.Accent or Theme.Tertiary,
                    BackgroundTransparency = bgImage and 0.3 or 0,
                    Size = UDim2.new(0, 48, 0, 24), Position = UDim2.new(1, -48, 0.5, -12),
                    Parent = H,
                }, { corner(12) })
                local Knob = create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                    Parent = Sw,
                }, { corner(9) })

                if flag then CuteWare.Flags[flag] = state end

                local function setState(v, skipCb)
                    state = v
                    if flag then CuteWare.Flags[flag] = state end
                    quickTween(Sw, { BackgroundColor3 = state and Theme.Accent or Theme.Tertiary }, 0.18)
                    quickTween(Knob, {
                        Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    }, 0.18)
                    if not skipCb and c.Callback then c.Callback(state) end
                end

                local ToggleBtn = create("TextButton", {
                    Text = "", BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0), Parent = H,
                })
                ToggleBtn.MouseButton1Click:Connect(function() setState(not state) end)

                registerRefresh(function()
                    if not H.Parent then return false end
                    NameLabel.TextColor3 = Theme.Text
                    Sw.BackgroundColor3 = state and Theme.Accent or Theme.Tertiary
                    Knob.BackgroundColor3 = Theme.Text
                end)

                return { Set = function(_, v) setState(v, false) end, Get = function() return state end }
            end

            -- ===== SLIDER =====
            function Section:CreateSlider(c)
                c = c or {}
                local min = c.Range and c.Range[1] or 0
                local max = c.Range and c.Range[2] or 100
                local value = math.clamp(c.CurrentValue or min, min, max)
                local flag = c.Flag
                local decimals = c.Decimals or (max - min <= 10 and 1 or 0)
                local suffix = c.Suffix or ""

                local Holder = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), Parent = SH,
                })
                local TopRow = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = Holder,
                })
                local NameLabel = create("TextLabel", {
                    Text = c.Name or "Slider", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = TopRow,
                })
                local ValueLabel = create("TextLabel", {
                    Text = string.format("%." .. decimals .. "f", value) .. suffix,
                    Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.Accent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -60, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = TopRow,
                })
                local Track = create("Frame", {
                    BackgroundColor3 = Theme.Tertiary,
                    Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 26), Parent = Holder,
                }, { corner(3) })
                local Fill = create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0), Parent = Track,
                }, { corner(3) })
                local Knob = create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    Size = UDim2.new(0, 14, 0, 14),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                    Parent = Track,
                }, { corner(7) })

                if flag then CuteWare.Flags[flag] = value end

                local function setValue(v, skipCb)
                    v = math.clamp(v, min, max)
                    value = v
                    if flag then CuteWare.Flags[flag] = value end
                    local pct = (v - min) / (max - min)
                    quickTween(Fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.1)
                    quickTween(Knob, { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.1)
                    ValueLabel.Text = string.format("%." .. decimals .. "f", v) .. suffix
                    if not skipCb and c.Callback then c.Callback(v) end
                end

                local dragging = false
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                                  or input.UserInputType == Enum.UserInputType.Touch) then
                        local rel = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                        setValue(min + (max - min) * math.clamp(rel, 0, 1))
                    end
                end)
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local rel = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                        setValue(min + (max - min) * math.clamp(rel, 0, 1))
                    end
                end)

                registerRefresh(function()
                    if not Holder.Parent then return false end
                    NameLabel.TextColor3 = Theme.Text
                    ValueLabel.TextColor3 = Theme.Accent
                    Fill.BackgroundColor3 = Theme.Accent
                    Knob.BackgroundColor3 = Theme.Text
                end)

                return { Set = function(_, v) setValue(v, false) end, Get = function() return value end }
            end

            -- ===== DROPDOWN =====
            function Section:CreateDropdown(c)
                c = c or {}
                local options = c.Options or {}
                local value = c.CurrentValue
                local flag = c.Flag

                local Holder = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = SH,
                })
                local MainBtn = create("TextButton", {
                    Text = "", BackgroundColor3 = Theme.Tertiary,
                    BackgroundTransparency = bgImage and 0.5 or 0,
                    Size = UDim2.new(1, 0, 0, 30), Parent = Holder,
                }, { corner(8) })
                local NameLabel = create("TextLabel", {
                    Text = (value and (c.Name .. ": " .. tostring(value))) or (c.Name or "Dropdown"),
                    Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = MainBtn,
                })
                local Arrow = create("TextLabel", {
                    Text = "▼", Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -24, 0, 0),
                    Parent = MainBtn,
                })

                local ListFrame = create("Frame", {
                    BackgroundColor3 = darken(Theme.Tertiary, 0.85),
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 32),
                    Visible = false, ZIndex = 20, Parent = Holder,
                }, { corner(8) })

                local open = false
                local function refreshList()
                    for _, ch in ipairs(ListFrame:GetChildren()) do
                        if ch:IsA("TextButton") then ch:Destroy() end
                    end
                    local y = 4
                    for _, opt in ipairs(options) do
                        local optBtn = create("TextButton", {
                            Text = tostring(opt), Font = Theme.Font, TextSize = 12,
                            TextColor3 = (value == opt) and Theme.Accent or Theme.Text,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, -8, 0, 22),
                            Position = UDim2.new(0, 4, 0, y),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 21, Parent = ListFrame,
                        }, { corner(6) })
                        optBtn.MouseButton1Click:Connect(function()
                            value = opt
                            if flag then CuteWare.Flags[flag] = value end
                            NameLabel.Text = c.Name .. ": " .. tostring(value)
                            if c.Callback then c.Callback(value) end
                            -- close
                            open = false
                            quickTween(Arrow, { Rotation = 0 }, 0.15)
                            quickTween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                            task.delay(0.16, function() if not open then ListFrame.Visible = false end end)
                        end)
                        y = y + 24
                    end
                    ListFrame.Size = UDim2.new(1, 0, 0, y)
                end

                MainBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        refreshList()
                        ListFrame.Visible = true
                        ListFrame.Size = UDim2.new(1, 0, 0, 0)
                        quickTween(ListFrame, { Size = UDim2.new(1, 0, 0, 4 + #options * 24) }, 0.15)
                        quickTween(Arrow, { Rotation = 180 }, 0.15)
                    else
                        quickTween(Arrow, { Rotation = 0 }, 0.15)
                        quickTween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                        task.delay(0.16, function() if not open then ListFrame.Visible = false end end)
                    end
                end)

                if flag then CuteWare.Flags[flag] = value end

                registerRefresh(function()
                    if not Holder.Parent then return false end
                    MainBtn.BackgroundColor3 = Theme.Tertiary
                    NameLabel.TextColor3 = Theme.Text
                    ListFrame.BackgroundColor3 = darken(Theme.Tertiary, 0.85)
                end)

                return {
                    Set = function(_, v)
                        value = v
                        if flag then CuteWare.Flags[flag] = value end
                        NameLabel.Text = c.Name .. ": " .. tostring(value)
                        if c.Callback then c.Callback(value) end
                    end,
                    Get = function() return value end,
                    Refresh = function(_, newOptions)
                        options = newOptions or options
                        if open then refreshList() end
                    end,
                }
            end

            -- ===== TEXT INPUT =====
            function Section:CreateInput(c)
                c = c or {}
                local flag = c.Flag
                local Holder = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), Parent = SH,
                })
                create("TextLabel", {
                    Text = c.Name or "Input", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder,
                })
                local InputBox = create("Frame", {
                    BackgroundColor3 = Theme.Tertiary,
                    Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 20), Parent = Holder,
                }, { corner(8) })
                local Box = create("TextBox", {
                    Text = c.CurrentValue or "", PlaceholderText = c.Placeholder or "...",
                    Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.SubText, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
                    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = InputBox,
                })
                Box.FocusLost:Connect(function()
                    if flag then CuteWare.Flags[flag] = Box.Text end
                    if c.Callback then c.Callback(Box.Text) end
                end)
                if flag then CuteWare.Flags[flag] = c.CurrentValue or "" end
                registerRefresh(function()
                    if not Holder.Parent then return false end
                    InputBox.BackgroundColor3 = Theme.Tertiary
                end)
                return { Set = function(_, v) Box.Text = v end, Get = function() return Box.Text end }
            end

            -- ===== KEYBIND =====
            function Section:CreateKeybind(c)
                c = c or {}
                local key = c.CurrentValue
                local flag = c.Flag
                local listening = false

                local Holder = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = SH,
                })
                local NameLabel = create("TextLabel", {
                    Text = c.Name or "Keybind", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -70, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder,
                })
                local KeyBtn = create("TextButton", {
                    Text = key and key.Name or "None",
                    Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
                    BackgroundColor3 = Theme.Tertiary,
                    Size = UDim2.new(0, 70, 0, 26), Position = UDim2.new(1, -70, 0.5, -13),
                    Parent = Holder,
                }, { corner(6) })

                local bindConn
                KeyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = Theme.Accent
                    bindConn = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            KeyBtn.Text = key.Name
                            KeyBtn.TextColor3 = Theme.SubText
                            if flag then CuteWare.Flags[flag] = key end
                            listening = false
                            if bindConn then bindConn:Disconnect() end
                            if c.Callback then c.Callback(key) end
                        end
                    end)
                end)

                if flag and key then CuteWare.Flags[flag] = key end

                registerRefresh(function()
                    if not Holder.Parent then return false end
                    NameLabel.TextColor3 = Theme.Text
                    KeyBtn.BackgroundColor3 = Theme.Tertiary
                end)

                return { Get = function() return key end }
            end

            -- ===== LABEL / PARAGRAPH =====
            function Section:CreateLabel(c)
                c = c or {}
                local lbl = create("TextLabel", {
                    Text = c.Name or "Label", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.SubText, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = SH,
                })
                registerRefresh(function()
                    if not lbl.Parent then return false end
                    lbl.TextColor3 = Theme.SubText
                end)
                return lbl
            end

            function Section:CreateParagraph(c)
                c = c or {}
                local Holder = create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, Parent = SH,
                }, { create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
                create("TextLabel", {
                    Text = c.Name or "Paragraph", Font = Theme.FontBold, TextSize = 14,
                    TextColor3 = Theme.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = Holder,
                })
                create("TextLabel", {
                    Text = c.Content or "", Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.SubText, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 2, Parent = Holder,
                })
                return Holder
            end

            -- ===== DIVIDER =====
            function Section:CreateDivider()
                local div = create("Frame", {
                    BackgroundColor3 = Theme.Stroke,
                    Size = UDim2.new(1, 0, 0, 1), Parent = SH,
                })
                registerRefresh(function()
                    if not div.Parent then return false end
                    div.BackgroundColor3 = Theme.Stroke
                end)
                return div
            end

            return Section
        end

        return Tab
    end

    return Window
end

return CuteWare
