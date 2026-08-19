--[[
    Fluent UI Library
    Версия: 1.0.0
    GitHub: https://github.com/yourusername/fluent-ui-library
    Лицензия: MIT
]]

-- ===== БИБЛИОТЕКА =====

local Fluent = {}
Fluent.__index = Fluent
Fluent._windows = {}
Fluent._notifications = {}
Fluent._flags = {}
Fluent._theme = {
    Background = Color3.fromRGB(24, 24, 28),
    Secondary = Color3.fromRGB(32, 32, 38),
    Tertiary = Color3.fromRGB(42, 42, 50),
    Stroke = Color3.fromRGB(58, 58, 68),
    Accent = Color3.fromRGB(100, 149, 237),
    AccentDark = Color3.fromRGB(70, 110, 200),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(165, 165, 175),
    Success = Color3.fromRGB(120, 220, 150),
    Error = Color3.fromRGB(230, 90, 100),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
    return create("UICorner", { CornerRadius = UDim.new(0, r or 8) })
end

local function stroke(col, thick, transp)
    return create("UIStroke", {
        Color = col or Fluent._theme.Stroke,
        Thickness = thick or 1,
        Transparency = transp or 0
    })
end

local function padding(a)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, a),
        PaddingBottom = UDim.new(0, a),
        PaddingLeft = UDim.new(0, a),
        PaddingRight = UDim.new(0, a),
    })
end

local function darken(c, f)
    f = f or 0.85
    return Color3.new(
        math.clamp(c.R * f, 0, 1),
        math.clamp(c.G * f, 0, 1),
        math.clamp(c.B * f, 0, 1)
    )
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

local function spawnRipple(button, relX, relY, color, fillDuration, rippleZIndex)
    fillDuration = fillDuration or 0.22
    local w = button.AbsoluteSize.X
    local h = button.AbsoluteSize.Y
    local diameter = math.sqrt(w * w + h * h) * 2.1

    local circle = create("Frame", {
        BackgroundColor3 = color or Fluent._theme.Accent,
        BackgroundTransparency = 0.35,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, relX, 0, relY),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = rippleZIndex or ((button.ZIndex or 1) + 1),
        Parent = button,
    }, { corner(9999) })

    tween(circle, TweenInfo.new(fillDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, diameter, 0, diameter),
        BackgroundTransparency = 1,
    })

    task.delay(fillDuration + 0.05, function()
        if circle and circle.Parent then
            circle:Destroy()
        end
    end)
end

-- ===== ОБЪЕКТ ФЛАГОВ =====

Fluent.Options = {
    __index = function(_, key)
        return Fluent._flags[key]
    end,
    __newindex = function(_, key, value)
        Fluent._flags[key] = value
    end
}
setmetatable(Fluent.Options, Fluent.Options)

-- ===== УВЕДОМЛЕНИЯ =====

function Fluent:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 4

    local sg = self._screenGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local holder = sg:FindFirstChild("FluentNotifications")

    if not holder then
        holder = create("Frame", {
            Name = "FluentNotifications",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -20, 0, 20),
            Size = UDim2.new(0, 300, 1, -40),
            Parent = sg,
        }, {
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10),
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
            })
        })
    end

    local frame = create("Frame", {
        BackgroundColor3 = Fluent._theme.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = holder,
    }, { corner(10), stroke(Fluent._theme.Stroke, 1) })

    local inner = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame,
    }, {
        padding(14),
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    -- Заголовок
    local titleRow = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
        Parent = inner,
    })

    create("TextLabel", {
        Text = title,
        Font = Fluent._theme.FontBold,
        TextSize = 15,
        TextColor3 = Fluent._theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleRow,
    })

    local closeBtn = create("TextButton", {
        Text = "×",
        Font = Fluent._theme.FontBold,
        TextSize = 14,
        TextColor3 = Fluent._theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, -1),
        Parent = titleRow,
    })

    closeBtn.MouseEnter:Connect(function()
        quickTween(closeBtn, { TextColor3 = Fluent._theme.Error }, 0.12)
    end)
    closeBtn.MouseLeave:Connect(function()
        quickTween(closeBtn, { TextColor3 = Fluent._theme.SubText }, 0.12)
    end)

    -- Контент
    create("TextLabel", {
        Text = content,
        Font = Fluent._theme.Font,
        TextSize = 13,
        TextColor3 = Fluent._theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = inner,
    })

    -- Прогресс-бар
    if duration > 0 then
        local progressBar = create("Frame", {
            BackgroundColor3 = darken(Fluent._theme.Tertiary, 0.9),
            Size = UDim2.new(1, 0, 0, 3),
            LayoutOrder = 3,
            Parent = inner,
        }, { corner(2) })

        local progressFill = create("Frame", {
            BackgroundColor3 = Fluent._theme.Accent,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = progressBar,
        }, { corner(2) })

        tween(progressFill,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 0, 1, 0) }
        )
    end

    -- Анимация появления
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(1, 30, 0, 0)

    quickTween(frame, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.25)

    local dismissed = false

    local function dismiss()
        if dismissed then return end
        dismissed = true
        quickTween(frame, { BackgroundTransparency = 1, Position = UDim2.new(1, 30, 0, 0) }, 0.25)
        task.wait(0.3)
        frame:Destroy()
    end

    closeBtn.MouseButton1Click:Connect(dismiss)

    if duration > 0 then
        task.delay(duration, function()
            if not dismissed then
                dismiss()
            end
        end)
    end
end

-- ===== ДИАЛОГИ =====

function Fluent:Dialog(config)
    config = config or {}
    local title = config.Title or "Dialog"
    local content = config.Content or ""
    local buttons = config.Buttons or {}

    local sg = self._screenGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local overlay = create("Frame", {
        Name = "FluentDialogOverlay",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.55,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100,
        Parent = sg,
    })

    local card = create("Frame", {
        BackgroundColor3 = Fluent._theme.Secondary,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 101,
        Parent = overlay,
    }, { corner(14), stroke(Fluent._theme.Stroke, 1), padding(20) })

    create("TextLabel", {
        Text = title,
        Font = Fluent._theme.FontBold,
        TextSize = 17,
        TextColor3 = Fluent._theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    create("TextLabel", {
        Text = content,
        Font = Fluent._theme.Font,
        TextSize = 13,
        TextColor3 = Fluent._theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    if #buttons > 0 then
        local btnRow = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            LayoutOrder = 3,
            Parent = card,
        }, {
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
            })
        })

        for _, btn in ipairs(buttons) do
            local b = create("TextButton", {
                Text = btn.Title or "OK",
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundColor3 = Fluent._theme.Tertiary,
                Size = UDim2.new(0, 90, 0, 30),
                Parent = btnRow,
            }, { corner(7) })

            b.MouseEnter:Connect(function()
                quickTween(b, { BackgroundColor3 = darken(Fluent._theme.Tertiary, 0.75) }, 0.15)
            end)
            b.MouseLeave:Connect(function()
                quickTween(b, { BackgroundColor3 = Fluent._theme.Tertiary }, 0.15)
            end)

            b.MouseButton1Click:Connect(function()
                if btn.Callback then
                    btn.Callback()
                end
                quickTween(overlay, { BackgroundTransparency = 1 }, 0.2)
                task.wait(0.22)
                overlay:Destroy()
            end)
        end
    end

    card.BackgroundTransparency = 1
    quickTween(card, { BackgroundTransparency = 0 }, 0.25)
end

-- ===== СОЗДАНИЕ ОКНА =====

function Fluent:CreateWindow(config)
    config = config or {}

    -- Применяем тему
    if config.Theme == "Dark" then
        Fluent._theme.Background = Color3.fromRGB(24, 24, 28)
        Fluent._theme.Secondary = Color3.fromRGB(32, 32, 38)
        Fluent._theme.Tertiary = Color3.fromRGB(42, 42, 50)
        Fluent._theme.Text = Color3.fromRGB(240, 240, 245)
        Fluent._theme.SubText = Color3.fromRGB(165, 165, 175)
    elseif config.Theme == "Light" then
        Fluent._theme.Background = Color3.fromRGB(240, 240, 245)
        Fluent._theme.Secondary = Color3.fromRGB(230, 230, 235)
        Fluent._theme.Tertiary = Color3.fromRGB(220, 220, 225)
        Fluent._theme.Text = Color3.fromRGB(24, 24, 28)
        Fluent._theme.SubText = Color3.fromRGB(90, 90, 100)
    end

    if config.AccentColor then
        Fluent._theme.Accent = config.AccentColor
        Fluent._theme.AccentDark = config.AccentColorDark or darken(config.AccentColor, 0.8)
    end

    local windowName = config.Title or "Fluent"
    local subtitle = config.SubTitle or ""
    local size = config.Size or UDim2.fromOffset(580, 460)
    local tabWidth = config.TabWidth or 160
    local acrylic = config.Acrylic or false
    local minimizeKey = config.MinimizeKey or Enum.KeyCode.RightAlt

    local TOPBAR_H = 38

    -- Создаем ScreenGui
    local sg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    if sg:FindFirstChild("FluentGUI") then
        sg:FindFirstChild("FluentGUI"):Destroy()
    end

    local mainGui = create("ScreenGui", {
        Name = "FluentGUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = sg,
    })
    self._screenGui = mainGui

    -- Основное окно
    local main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = Fluent._theme.Background,
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Parent = mainGui,
        ClipsDescendants = true,
    }, { corner(12), stroke(Fluent._theme.Stroke, 1) })

    if acrylic then
        -- Эффект акрила (прозрачность с размытием)
        main.BackgroundTransparency = 0.85
        local blur = Instance.new("BlurEffect")
        blur.Size = 20
        blur.Parent = main
    end

    -- Верхняя панель
    local topBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = darken(Fluent._theme.Secondary, 0.92),
        Size = UDim2.new(1, 0, 0, TOPBAR_H),
        Parent = main,
    }, { corner(12) })

    -- Заголовок
    local titleOffset = 16
    create("TextLabel", {
        Text = windowName,
        Font = Fluent._theme.FontBold,
        TextSize = 18,
        TextColor3 = Fluent._theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, titleOffset, 0, 0),
        Size = UDim2.new(1, -titleOffset - 110, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    if subtitle and subtitle ~= "" then
        create("TextLabel", {
            Text = subtitle,
            Font = Fluent._theme.Font,
            TextSize = 12,
            TextColor3 = Fluent._theme.SubText,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, titleOffset, 0, 20),
            Size = UDim2.new(1, -titleOffset - 110, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = topBar,
        })
    end

    -- Кнопки управления
    local controls = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 96, 0, 26),
        Parent = topBar,
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })

    local function makeCtrlBtn(text, hoverBg, hoverText, order)
        local b = create("TextButton", {
            Text = text,
            Font = Fluent._theme.FontBold,
            TextSize = 15,
            TextColor3 = Fluent._theme.SubText,
            BackgroundColor3 = hoverBg,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 28, 0, 26),
            LayoutOrder = order,
            Parent = controls,
        }, { corner(6) })

        b.MouseEnter:Connect(function()
            quickTween(b, { BackgroundTransparency = 0, TextColor3 = hoverText }, 0.15)
        end)
        b.MouseLeave:Connect(function()
            quickTween(b, { BackgroundTransparency = 1, TextColor3 = Fluent._theme.SubText }, 0.15)
        end)

        return b
    end

    local minBtn = makeCtrlBtn("—", darken(Fluent._theme.Tertiary, 0.9), Fluent._theme.Accent, 1)
    local maxBtn = makeCtrlBtn("□", darken(Fluent._theme.Tertiary, 0.9), Fluent._theme.Accent, 2)
    local closeBtn = makeCtrlBtn("×", darken(Fluent._theme.Error, 0.5), Fluent._theme.Text, 3)

    -- Панель вкладок
    local tabListShell = create("Frame", {
        Name = "TabListShell",
        BackgroundColor3 = Fluent._theme.Secondary,
        Position = UDim2.new(0, 0, 0, TOPBAR_H),
        Size = UDim2.new(0, tabWidth, 1, -TOPBAR_H),
        Parent = main,
    }, { corner(12) })

    local tabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = tabListShell,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(10),
    })

    -- Область контента
    local contentArea = create("Frame", {
        Name = "ContentArea",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, tabWidth, 0, TOPBAR_H),
        Size = UDim2.new(1, -tabWidth, 1, -TOPBAR_H),
        Parent = main,
    })

    -- Объект окна
    local window = {
        _main = main,
        _topBar = topBar,
        _tabList = tabList,
        _contentArea = contentArea,
        _tabs = {},
        _activeTab = nil,
    }

    -- Перетаскивание окна
    local dragging = false
    local dragStart, startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Сворачивание/разворачивание
    local minimized = false

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            quickTween(main, { Size = UDim2.new(0, 580, 0, TOPBAR_H) }, 0.28)
            tabListShell.Visible = false
            contentArea.Visible = false
        else
            tabListShell.Visible = true
            contentArea.Visible = true
            quickTween(main, { Size = size }, 0.28)
        end
    end)

    -- Закрытие
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    -- Горячая клавиша
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and
           input.KeyCode == minimizeKey then
            minimized = not minimized
            if minimized then
                tabListShell.Visible = false
                contentArea.Visible = false
                quickTween(main, { Size = UDim2.new(0, 580, 0, TOPBAR_H) }, 0.28)
            else
                tabListShell.Visible = true
                contentArea.Visible = true
                quickTween(main, { Size = size }, 0.28)
            end
        end
    end)

    -- Методы окна
    function window:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Title or "Tab"

        -- Кнопка вкладки
        local tabBtn = create("TextButton", {
            Text = tabName,
            Font = Fluent._theme.Font,
            TextSize = 14,
            TextColor3 = Fluent._theme.SubText,
            BackgroundColor3 = Fluent._theme.Tertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            ClipsDescendants = true,
            ZIndex = 2,
            Parent = tabList,
        }, { corner(8) })

        -- Страница вкладки
        local page = create("ScrollingFrame", {
            Name = tabName .. "Page",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Fluent._theme.Accent,
            Visible = false,
            Parent = contentArea,
        }, {
            padding(14),
            create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        local pageLayout = page:FindFirstChildOfClass("UIListLayout")
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 28)
        end)

        local tab = {
            _btn = tabBtn,
            _page = page,
            _name = tabName,
            _active = false,
        }

        -- Функция выбора вкладки
        local function selectTab()
            -- Деактивируем все вкладки
            for _, t in pairs(window._tabs) do
                if t._active then
                    t._active = false
                    t._page.Visible = false
                    quickTween(t._btn, { BackgroundTransparency = 1 }, 0.15)
                    quickTween(t._btn, { TextColor3 = Fluent._theme.SubText }, 0.15)
                end
            end

            -- Активируем текущую
            tab._active = true
            tab._page.Visible = true
            quickTween(tabBtn, { BackgroundTransparency = 0 }, 0.15)
            quickTween(tabBtn, { TextColor3 = Fluent._theme.Text }, 0.15)

            -- Эффект пульсации
            spawnRipple(tabBtn, tabBtn.AbsoluteSize.X / 2, tabBtn.AbsoluteSize.Y / 2)
        end

        tabBtn.MouseButton1Click:Connect(selectTab)

        tabBtn.MouseEnter:Connect(function()
            if not tab._active then
                quickTween(tabBtn, { TextColor3 = Fluent._theme.Text }, 0.12)
            end
        end)

        tabBtn.MouseLeave:Connect(function()
            if not tab._active then
                quickTween(tabBtn, { TextColor3 = Fluent._theme.SubText }, 0.12)
            end
        end)

        table.insert(window._tabs, tab)

        -- Если это первая вкладка - активируем
        if #window._tabs == 1 then
            selectTab()
        end

        -- Методы вкладки
        function tab:AddToggle(name, toggleConfig)
            toggleConfig = toggleConfig or {}
            local state = toggleConfig.Default or false

            local container = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = page,
            })

            create("TextLabel", {
                Text = toggleConfig.Title or name,
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -54, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = container,
            })

            local switch = create("Frame", {
                BackgroundColor3 = state and Fluent._theme.Accent or Fluent._theme.Tertiary,
                Size = UDim2.new(0, 48, 0, 24),
                Position = UDim2.new(1, -48, 0.5, -12),
                Parent = container,
            }, { corner(6) })

            local knob = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.new(0, 20, 0, 20),
                Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
                Parent = switch,
            }, { corner(4) })

            local clickArea = create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.new(1, 0, 1, 0),
                Parent = container,
            })

            local toggle = {}

            function toggle:Set(newState, fire)
                state = newState
                quickTween(switch, { BackgroundColor3 = state and Fluent._theme.Accent or Fluent._theme.Tertiary }, 0.18)
                quickTween(knob, {
                    Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                }, 0.18)

                if toggleConfig.Flag then
                    Fluent._flags[toggleConfig.Flag] = state
                end

                if fire ~= false and toggleConfig.Callback then
                    toggleConfig.Callback(state)
                end
            end

            clickArea.MouseButton1Click:Connect(function()
                toggle:Set(not state)
            end)

            if toggleConfig.Flag then
                Fluent._flags[toggleConfig.Flag] = state
            end

            -- Сохраняем ссылку в Fluent.Options
            Fluent.Options[name] = { Value = state, Set = toggle.Set }

            return toggle
        end

        function tab:AddInput(name, inputConfig)
            inputConfig = inputConfig or {}

            local container = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 52),
                Parent = page,
            })

            create("TextLabel", {
                Text = inputConfig.Title or name,
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = container,
            })

            local box = create("Frame", {
                BackgroundColor3 = Fluent._theme.Tertiary,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 30),
                Parent = container,
            }, { corner(8) })

            local input = create("TextBox", {
                Text = inputConfig.Default or "",
                PlaceholderText = inputConfig.Placeholder or "Введите текст...",
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                PlaceholderColor3 = Fluent._theme.SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = box,
            })

            input.Focused:Connect(function()
                quickTween(box, { BackgroundColor3 = Fluent._theme.AccentDark }, 0.15)
            end)

            input.FocusLost:Connect(function(enter)
                quickTween(box, { BackgroundColor3 = Fluent._theme.Tertiary }, 0.15)

                if inputConfig.Flag then
                    Fluent._flags[inputConfig.Flag] = input.Text
                end

                if inputConfig.Callback then
                    inputConfig.Callback(input.Text, enter)
                end
            end)

            if inputConfig.Flag then
                Fluent._flags[inputConfig.Flag] = input.Text
            end

            Fluent.Options[name] = { Value = input.Text }

            return input
        end

        function tab:AddParagraph(paragraphConfig)
            paragraphConfig = paragraphConfig or {}

            local container = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = page,
            })

            create("TextLabel", {
                Text = paragraphConfig.Title or "",
                Font = Fluent._theme.FontBold,
                TextSize = 15,
                TextColor3 = Fluent._theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = container,
            })

            if paragraphConfig.Content and paragraphConfig.Content ~= "" then
                create("TextLabel", {
                    Text = paragraphConfig.Content,
                    Font = Fluent._theme.Font,
                    TextSize = 13,
                    TextColor3 = Fluent._theme.SubText,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })
            end

            return container
        end

        function tab:AddButton(buttonConfig)
            buttonConfig = buttonConfig or {}

            local btn = create("TextButton", {
                Text = buttonConfig.Title or "Кнопка",
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundColor3 = Fluent._theme.Tertiary,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = page,
            }, { corner(8) })

            btn.MouseEnter:Connect(function()
                quickTween(btn, { BackgroundColor3 = darken(Fluent._theme.Tertiary, 0.75) }, 0.15)
            end)

            btn.MouseLeave:Connect(function()
                quickTween(btn, { BackgroundColor3 = Fluent._theme.Tertiary }, 0.15)
            end)

            btn.MouseButton1Down:Connect(function()
                quickTween(btn, { Size = UDim2.new(1, -6, 0, 32) }, 0.08)
            end)

            btn.MouseButton1Up:Connect(function()
                quickTween(btn, { Size = UDim2.new(1, 0, 0, 34) }, 0.12)
            end)

            btn.MouseButton1Click:Connect(function()
                spawnRipple(btn, btn.AbsoluteSize.X / 2, btn.AbsoluteSize.Y / 2)
                if buttonConfig.Callback then
                    buttonConfig.Callback()
                end
            end)

            return btn
        end

        function tab:AddColorpicker(name, colorConfig)
            colorConfig = colorConfig or {}
            local currentColor = colorConfig.Default or Color3.fromRGB(255, 255, 255)

            local container = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = page,
                ClipsDescendants = true,
            })

            local header = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = container,
            })

            create("TextLabel", {
                Text = colorConfig.Title or name,
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = header,
            })

            local preview = create("TextButton", {
                Text = "",
                BackgroundColor3 = currentColor,
                Size = UDim2.new(0, 28, 0, 20),
                Position = UDim2.new(1, -28, 0.5, -10),
                Parent = header,
            }, { corner(6), stroke(Fluent._theme.Stroke, 1) })

            local isOpen = false

            preview.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    quickTween(container, { Size = UDim2.new(1, 0, 0, 178) }, 0.2)
                else
                    quickTween(container, { Size = UDim2.new(1, 0, 0, 30) }, 0.2)
                end
            end)

            -- Простой цветовой пикер
            local body = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 34),
                Size = UDim2.new(1, 0, 0, 144),
                Visible = isOpen,
                Parent = container,
            })

            -- Цветовая палитра (упрощенная)
            local colors = {
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(255, 128, 0),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(128, 0, 255),
                Color3.fromRGB(255, 0, 255),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(128, 128, 128),
                Color3.fromRGB(0, 0, 0),
            }

            local grid = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = body,
            }, {
                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                })
            })

            for _, color in ipairs(colors) do
                local btn = create("TextButton", {
                    Text = "",
                    BackgroundColor3 = color,
                    Size = UDim2.new(0, 24, 0, 24),
                    Parent = grid,
                }, { corner(4) })

                btn.MouseButton1Click:Connect(function()
                    currentColor = color
                    preview.BackgroundColor3 = color

                    if colorConfig.Flag then
                        Fluent._flags[colorConfig.Flag] = color
                    end

                    if colorConfig.Callback then
                        colorConfig.Callback(color)
                    end

                    isOpen = false
                    quickTween(container, { Size = UDim2.new(1, 0, 0, 30) }, 0.2)
                end)
            end

            if colorConfig.Flag then
                Fluent._flags[colorConfig.Flag] = currentColor
            end

            Fluent.Options[name] = { Value = currentColor }

            return preview
        end

        function tab:AddDropdown(name, dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local values = dropdownConfig.Values or {}
            local multi = dropdownConfig.Multi or false
            local default = dropdownConfig.Default

            local container = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 56),
                Parent = page,
                ClipsDescendants = false,
            })

            create("TextLabel", {
                Text = dropdownConfig.Title or name,
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = container,
            })

            local box = create("TextButton", {
                Text = "",
                BackgroundColor3 = Fluent._theme.Tertiary,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 32),
                Parent = container,
            }, { corner(8) })

            local selectedText = create("TextLabel", {
                Text = "",
                Font = Fluent._theme.Font,
                TextSize = 13,
                TextColor3 = Fluent._theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = box,
            })

            local arrow = create("TextLabel", {
                Text = "▼",
                Font = Fluent._theme.Font,
                TextSize = 14,
                TextColor3 = Fluent._theme.SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 24, 1, 0),
                Position = UDim2.new(1, -28, 0, 0),
                Parent = box,
            })

            local isOpen = false
            local selectedValues = {}

            if multi then
                if type(default) == "table" then
                    for _, v in ipairs(default) do
                        selectedValues[v] = true
                    end
                end
                selectedText.Text = #default > 0 and table.concat(default, ", ") or "None"
            else
                local def = default or values[1]
                selectedValues[def] = true
                selectedText.Text = tostring(def)
            end

            local list = create("Frame", {
                BackgroundColor3 = Fluent._theme.Tertiary,
                Size = UDim2.new(1, -24, 0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 20,
                ClipsDescendants = true,
                Visible = false,
                Parent = container,
            }, { corner(8), create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

            local function updatePosition()
                list.Position = UDim2.new(0, 0, 0, container.Position.Y.Offset + 56)
            end
            task.defer(updatePosition)

            local buttons = {}

            local function rebuildList()
                for _, btn in ipairs(buttons) do
                    if btn and btn.Parent then
                        btn:Destroy()
                    end
                end
                buttons = {}

                for i, val in ipairs(values) do
                    local isSelected = selectedValues[val] or false

                    local btn = create("TextButton", {
                        Text = tostring(val),
                        Font = Fluent._theme.Font,
                        TextSize = 13,
                        TextColor3 = isSelected and Fluent._theme.Accent or Fluent._theme.SubText,
                        BackgroundColor3 = Fluent._theme.Tertiary,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        LayoutOrder = i,
                        ZIndex = 21,
                        Parent = list,
                    })

                    btn.MouseEnter:Connect(function()
                        quickTween(btn, { BackgroundTransparency = 0.6 }, 0.1)
                    end)
                    btn.MouseLeave:Connect(function()
                        quickTween(btn, { BackgroundTransparency = 1 }, 0.1)
                    end)

                    btn.MouseButton1Click:Connect(function()
                        if multi then
                            selectedValues[val] = not selectedValues[val]
                            btn.TextColor3 = selectedValues[val] and Fluent._theme.Accent or Fluent._theme.SubText

                            local res = {}
                            for _, v in ipairs(values) do
                                if selectedValues[v] then
                                    table.insert(res, v)
                                end
                            end

                            selectedText.Text = #res > 0 and table.concat(res, ", ") or "None"

                            if dropdownConfig.Flag then
                                Fluent._flags[dropdownConfig.Flag] = res
                            end

                            if dropdownConfig.Callback then
                                dropdownConfig.Callback(res)
                            end
                        else
                            for _, b in ipairs(buttons) do
                                b.TextColor3 = Fluent._theme.SubText
                            end
                            btn.TextColor3 = Fluent._theme.Accent

                            selectedText.Text = tostring(val)
                            selectedValues = {}
                            selectedValues[val] = true

                            if dropdownConfig.Flag then
                                Fluent._flags[dropdownConfig.Flag] = val
                            end

                            if dropdownConfig.Callback then
                                dropdownConfig.Callback(val)
                            end

                            isOpen = false
                            quickTween(list, { Size = UDim2.new(1, -24, 0, 0) }, 0.18)
                            task.delay(0.2, function()
                                if not isOpen then list.Visible = false end
                            end)
                            quickTween(arrow, { Rotation = 0 }, 0.18)
                        end
                    end)

                    table.insert(buttons, btn)
                end
            end

            rebuildList()

            box.MouseButton1Click:Connect(function()
                updatePosition()
                isOpen = not isOpen

                if isOpen then
                    list.Visible = true
                    list.Size = UDim2.new(1, -24, 0, 0)
                    quickTween(list, { Size = UDim2.new(1, -24, 0, #values * 30) }, 0.18)
                    quickTween(arrow, { Rotation = 180 }, 0.18)
                else
                    quickTween(list, { Size = UDim2.new(1, -24, 0, 0) }, 0.18)
                    task.delay(0.2, function()
                        if not isOpen then list.Visible = false end
                    end)
                    quickTween(arrow, { Rotation = 0 }, 0.18)
                end
            end)

            if dropdownConfig.Flag then
                local def = default or values[1]
                Fluent._flags[dropdownConfig.Flag] = def
            end

            Fluent.Options[name] = { Value = default or values[1] }

            return container
        end

        return tab
    end

    table.insert(Fluent._windows, window)

    -- Уведомление о загрузке
    Fluent:Notify({
        Title = "Fluent",
        Content = "UI Library загружена!",
        Duration = 3
    })

    return window
end

-- ===== ИНИЦИАЛИЗАЦИЯ =====

function Fluent:Init()
    getgenv().Fluent = Fluent
    return Fluent
end

return Fluent
