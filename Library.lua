-- ╔══════════════════════════════════════════════════╗
-- ║          LuckyCharms UI Library  v2.0           ║
-- ║  Toggle / Slider / Dropdown / Colorpicker       ║
-- ║  Keybind / Textbox / Button / Label / Section   ║
-- ╚══════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local RunService       = game:GetService("RunService")

-- ══════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════
local function GetGui()
    if gethui then return gethui() end
    return CoreGui
end

local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Pad(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
end

local function List(parent, dir, pad)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, pad or 0)
    l.Parent = parent
    return l
end

local function Draggify(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = target.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ══════════════════════════════════════════════════
--  PALETTE
-- ══════════════════════════════════════════════════
local C = {
    BG        = Color3.fromRGB(30,  30,  30),
    SIDEBAR   = Color3.fromRGB(46,  46,  46),
    PANEL     = Color3.fromRGB(34,  34,  34),
    PANEL2    = Color3.fromRGB(38,  38,  38),
    BORDER    = Color3.fromRGB(45,  45,  45),
    GREEN     = Color3.fromRGB(15, 125,  45),
    GREEN_TXT = Color3.fromRGB(30, 145,  65),
    GREEN_CHK = Color3.fromRGB(20, 145,  50),
    BTN_BG    = Color3.fromRGB(31,  31,  31),
    BTN_HOV   = Color3.fromRGB(38,  38,  38),
    TEXT      = Color3.fromRGB(215, 215, 215),
    TEXT_DIM  = Color3.fromRGB(135, 135, 135),
    TEXT_LOGO = Color3.fromRGB(220, 255, 220),
    WHITE     = Color3.fromRGB(255, 255, 255),
    BLACK     = Color3.fromRGB(  0,   0,   0),
    RED       = Color3.fromRGB(180,  40,  40),
}

-- ══════════════════════════════════════════════════
--  LIBRARY
-- ══════════════════════════════════════════════════
local LuckyCharms      = {}
LuckyCharms.__index    = LuckyCharms
LuckyCharms.Flags      = {}
LuckyCharms.Callbacks  = {}

-- shared overlay layer for colorpicker popups (always on top)
local OverlayGui = nil

local NotifParent = nil

local function DoNotify(title, msg, duration)
    if not NotifParent then return end
    duration = duration or 3

    local frame = New("Frame", {
        Size             = UDim2.new(1, 0, 0, msg and 46 or 26),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, NotifParent)
    New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = frame })

    -- left green bar
    New("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = C.GREEN,
        BorderSizePixel  = 0,
    }, frame)

    local inner = New("Frame", {
        Position               = UDim2.fromOffset(10, 0),
        Size                   = UDim2.new(1, -14, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
    }, frame)
    List(inner, nil, 2)
    Pad(inner, 5, 5, 0, 0)

    New("TextLabel", {
        Size                   = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = C.GREEN_TXT,
        TextSize               = 11,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }, inner)

    if msg and msg ~= "" then
        New("TextLabel", {
            Size                   = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text                   = msg,
            TextColor3             = C.TEXT_DIM,
            TextSize               = 10,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
        }, inner)
    end

    -- slide in
    frame.Position = UDim2.new(1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
    Tween(frame, { Position = UDim2.new(0, 0, frame.Position.Y.Scale, frame.Position.Y.Offset) }, 0.2)

    task.delay(duration, function()
        Tween(frame, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        if frame and frame.Parent then frame:Destroy() end
    end)
end

-- ══════════════════════════════════════════════════
--  CREATE WINDOW
-- ══════════════════════════════════════════════════
function LuckyCharms:CreateWindow(cfg)
    cfg = cfg or {}
    local Title     = cfg.Title    or "LuckyCharms"
    local SubTitle  = cfg.SubTitle or ""
    local ToggleKey = cfg.Key      or Enum.KeyCode.Insert
    local W         = (cfg.Size and cfg.Size.W) or 620
    local H         = (cfg.Size and cfg.Size.H) or 420
    local SIDEBAR_W = 78

    -- ── ScreenGui ─────────────────────────────────
    local gui = New("ScreenGui", {
        Name           = "LuckyCharmsLib",
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    })
    gui.Parent = GetGui()
    self._gui  = gui

    -- Overlay layer for popups that need to float above everything
    OverlayGui = New("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 100,
    }, gui)

    -- ── Notification area (bottom-right) ──────────
    NotifParent = New("Frame", {
        AnchorPoint           = Vector2.new(1, 1),
        Position              = UDim2.new(1, -12, 1, -12),
        Size                  = UDim2.fromOffset(240, 0),
        BackgroundTransparency = 1,
        AutomaticSize         = Enum.AutomaticSize.Y,
        BorderSizePixel       = 0,
        ZIndex                = 200,
    }, gui)
    List(NotifParent, nil, 5)

    -- ── Main frame ────────────────────────────────
    local Main = New("Frame", {
        Name             = "Main",
        Size             = UDim2.fromOffset(W, H),
        Position         = UDim2.new(0.5, -W/2, 0.5, -H/2),
        BackgroundColor3 = C.BG,
        BorderSizePixel  = 0,
        ZIndex           = 1,
    }, gui)
    New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = Main })
    Draggify(Main, Main)

    -- ── Sidebar ───────────────────────────────────
    local Sidebar = New("Frame", {
        Size             = UDim2.new(0, SIDEBAR_W, 1, 0),
        BackgroundColor3 = C.SIDEBAR,
        BorderSizePixel  = 0,
    }, Main)
    New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = Sidebar })

    -- Logo block
    local LogoBlock = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = C.SIDEBAR,
        BorderSizePixel  = 0,
    }, Sidebar)

    local LogoLabel = New("TextLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "LU\nCKY",
        TextColor3             = C.TEXT_LOGO,
        TextSize               = 16,
        Font                   = Enum.Font.GothamBold,
        LineHeight             = 1.1,
    }, LogoBlock)
    New("UIStroke", { Color = C.GREEN, Thickness = 1, Parent = LogoLabel })

    -- Tab buttons list
    local TabList = New("Frame", {
        Position               = UDim2.fromOffset(0, 70),
        Size                   = UDim2.new(1, 0, 1, -70),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
    }, Sidebar)
    List(TabList, nil, 0)

    -- ── Content area ─────────────────────────────
    local Content = New("Frame", {
        Position               = UDim2.fromOffset(SIDEBAR_W, 0),
        Size                   = UDim2.new(1, -SIDEBAR_W, 1, 0),
        BackgroundColor3       = C.BG,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
    }, Main)

    local PageHolder = New("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
    }, Content)

    -- Insert key toggle
    local visible = true
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == ToggleKey then
            visible      = not visible
            Main.Visible = visible
            -- hide all popups when menu closes
            if not visible then
                for _, child in ipairs(OverlayGui:GetChildren()) do
                    child.Visible = false
                end
            end
        end
    end)

    -- ══════════════════════════════════════════════
    --  WINDOW OBJECT
    -- ══════════════════════════════════════════════
    local Window      = {}
    Window._tabs      = {}
    Window._activeTab = nil
    Window._lib       = self

    function Window:Notify(title, msg, duration) DoNotify(title, msg, duration) end

    -- ── AddTab ────────────────────────────────────
    function Window:AddTab(name)
        local isFirst = #self._tabs == 0

        local BtnFrame = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = isFirst and C.BG or C.SIDEBAR,
            BorderSizePixel  = 0,
        }, TabList)

        local BtnLabel = New("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = name,
            TextColor3             = isFirst and C.TEXT or C.TEXT_DIM,
            TextSize               = 14,
            Font                   = Enum.Font.Gotham,
        }, BtnFrame)

        local BtnClick = New("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            BorderSizePixel        = 0,
        }, BtnFrame)

        local Page = New("ScrollingFrame", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 4,
            ScrollBarImageColor3   = C.BORDER,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticCanvasSize.Y,
            Visible                = isFirst,
        }, PageHolder)
        Pad(Page, 10, 10, 10, 10)
        List(Page, nil, 6)

        local Tab      = {}
        Tab._page      = Page
        Tab._btn       = BtnFrame
        Tab._label     = BtnLabel
        Tab._lib       = self._lib

        table.insert(self._tabs, Tab)
        if isFirst then self._activeTab = Tab end

        BtnClick.MouseButton1Click:Connect(function()
            if self._activeTab == Tab then return end
            if self._activeTab then
                self._activeTab._page.Visible = false
                Tween(self._activeTab._btn,   { BackgroundColor3 = C.SIDEBAR }, 0.1)
                Tween(self._activeTab._label, { TextColor3 = C.TEXT_DIM },      0.1)
            end
            Tab._page.Visible = true
            Tween(BtnFrame, { BackgroundColor3 = C.BG   }, 0.1)
            Tween(BtnLabel, { TextColor3 = C.TEXT       }, 0.1)
            self._activeTab = Tab
        end)
        BtnClick.MouseEnter:Connect(function()
            if self._activeTab ~= Tab then
                Tween(BtnFrame, { BackgroundColor3 = Color3.fromRGB(36,36,36) }, 0.08)
            end
        end)
        BtnClick.MouseLeave:Connect(function()
            if self._activeTab ~= Tab then
                Tween(BtnFrame, { BackgroundColor3 = C.SIDEBAR }, 0.08)
            end
        end)

        -- ══════════════════════════════════════════
        --  COMPONENT BUILDERS
        -- ══════════════════════════════════════════

        -- Internal row helper
        local function Row(height)
            local f = New("Frame", {
                Size             = UDim2.new(1, 0, 0, height or 24),
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
            }, Page)
            Pad(f, 0, 0, 14, 8)
            return f
        end

        -- ── SECTION ───────────────────────────────
        -- Full-width green header bar
        function Tab:Section(name)
            New("Frame", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = C.GREEN,
                BorderSizePixel  = 0,
            }, Page)
            -- label is a child of the frame above
            local f = Page:FindFirstChildOfClass("Frame")  -- get last added
            -- rebuild properly:
            local sec = Page:GetChildren()
            local sf  = sec[#sec]
            New("TextLabel", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = name or "Section",
                TextColor3             = Color3.fromRGB(210, 230, 210),
                TextSize               = 11,
                Font                   = Enum.Font.GothamSemibold,
            }, sf)
        end

        -- (cleaner Section implementation that doesn't rely on children ordering)
        -- Override with a clean version:
        Tab.Section = function(self, name)
            local sf = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = C.GREEN,
                BorderSizePixel  = 0,
            }, Page)
            New("TextLabel", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = name or "Section",
                TextColor3             = Color3.fromRGB(210, 230, 210),
                TextSize               = 11,
                Font                   = Enum.Font.GothamSemibold,
            }, sf)
        end

        -- ── LABEL ─────────────────────────────────
        function Tab:Label(cfg)
            cfg = cfg or {}
            local f = Row(20)

            local lbl = New("TextLabel", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Label",
                TextColor3             = C.TEXT_DIM,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, f)

            local obj = {}
            function obj:Set(t) lbl.Text = t end
            function obj:Get()  return lbl.Text end
            return obj
        end

        -- ── SEPARATOR ─────────────────────────────
        function Tab:Separator()
            New("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = C.BORDER,
                BorderSizePixel  = 0,
            }, Page)
        end

        -- ── TOGGLE ────────────────────────────────
        function Tab:Toggle(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Toggle"
            local default  = cfg.Default  or false
            local callback = cfg.Callback or function() end
            local enabled  = default
            LuckyCharms.Flags[flag] = enabled

            local f = Row(24)

            local box = New("Frame", {
                Position         = UDim2.fromOffset(0, 7),
                Size             = UDim2.fromOffset(11, 11),
                BackgroundColor3 = enabled and C.GREEN_CHK or Color3.fromRGB(48, 48, 48),
                BorderSizePixel  = 0,
            }, f)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = box })

            -- checkmark tick (shown when enabled)
            local tick = New("TextLabel", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "✓",
                TextColor3             = C.WHITE,
                TextSize               = 8,
                Font                   = Enum.Font.GothamBold,
                Visible                = enabled,
            }, box)

            New("TextLabel", {
                Position               = UDim2.fromOffset(16, 0),
                Size                   = UDim2.new(1, -16, 1, 0),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Toggle",
                TextColor3             = C.TEXT,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, f)

            local click = New("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                BorderSizePixel        = 0,
            }, f)

            local function Set(val)
                enabled = val
                LuckyCharms.Flags[flag] = val
                Tween(box, { BackgroundColor3 = val and C.GREEN_CHK or Color3.fromRGB(48, 48, 48) }, 0.1)
                tick.Visible = val
                callback(val)
            end

            click.MouseButton1Click:Connect(function() Set(not enabled) end)
            click.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL2 }, 0.08) end)
            click.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL  }, 0.08) end)
            LuckyCharms.Callbacks[flag] = Set

            local obj = {}
            function obj:Set(v) Set(v)       end
            function obj:Get() return enabled end
            return obj
        end

        -- ── SLIDER ────────────────────────────────
        function Tab:Slider(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Slider"
            local min      = cfg.Min      or 0
            local max      = cfg.Max      or 100
            local default  = cfg.Default  or min
            local suffix   = cfg.Suffix   or ""
            local decimal  = cfg.Decimal  or 0
            local callback = cfg.Callback or function() end
            local value    = math.clamp(default, min, max)
            LuckyCharms.Flags[flag] = value

            local f = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
            }, Page)
            Pad(f, 6, 6, 14, 8)

            -- format string
            local decimals = (decimal > 0) and math.max(0, math.ceil(-math.log10(decimal))) or 0
            local fmt      = decimals > 0 and ("%." .. decimals .. "f") or "%d"

            New("TextLabel", {
                Size                   = UDim2.new(0.6, 0, 0, 14),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Slider",
                TextColor3             = C.TEXT,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, f)

            local valLbl = New("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0),
                Position               = UDim2.new(1, 0, 0, 0),
                Size                   = UDim2.new(0.4, 0, 0, 14),
                BackgroundTransparency = 1,
                Text                   = string.format(fmt, value) .. suffix,
                TextColor3             = C.GREEN_TXT,
                TextSize               = 11,
                Font                   = Enum.Font.GothamSemibold,
                TextXAlignment         = Enum.TextXAlignment.Right,
            }, f)

            -- track
            local track = New("Frame", {
                Position         = UDim2.fromOffset(0, 18),
                Size             = UDim2.new(1, 0, 0, 8),
                BackgroundColor3 = Color3.fromRGB(48, 48, 48),
                BorderSizePixel  = 0,
            }, f)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = track })

            local fillRatio = (max == min) and 0 or ((value - min) / (max - min))

            local fill = New("Frame", {
                Size             = UDim2.new(fillRatio, 0, 1, 0),
                BackgroundColor3 = C.GREEN,
                BorderSizePixel  = 0,
            }, track)

            -- thumb knob
            local thumb = New("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(fillRatio, 0, 0.5, 0),
                Size             = UDim2.fromOffset(10, 10),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 5,
            }, track)
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
            New("UIStroke", { Color = C.GREEN, Thickness = 1, Parent = thumb })

            local dragBtn = New("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                BorderSizePixel        = 0,
                ZIndex                 = 6,
            }, track)

            local dragging = false

            local function UpdateVal(absX)
                local ratio = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local raw   = min + ratio * (max - min)
                if decimal > 0 then
                    raw = math.floor(raw / decimal + 0.5) * decimal
                else
                    raw = math.floor(raw + 0.5)
                end
                value = math.clamp(raw, min, max)
                LuckyCharms.Flags[flag] = value
                local r = (max == min) and 0 or ((value - min) / (max - min))
                fill.Size     = UDim2.new(r, 0, 1, 0)
                thumb.Position = UDim2.new(r, 0, 0.5, 0)
                valLbl.Text   = string.format(fmt, value) .. suffix
                callback(value)
            end

            dragBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    UpdateVal(inp.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateVal(inp.Position.X)
                end
            end)

            local function Set(val_)
                value = math.clamp(val_, min, max)
                LuckyCharms.Flags[flag] = value
                local r = (max == min) and 0 or ((value - min) / (max - min))
                fill.Size      = UDim2.new(r, 0, 1, 0)
                thumb.Position = UDim2.new(r, 0, 0.5, 0)
                valLbl.Text    = string.format(fmt, value) .. suffix
                callback(value)
            end
            LuckyCharms.Callbacks[flag] = Set

            local obj = {}
            function obj:Set(v) Set(v)      end
            function obj:Get() return value end
            return obj
        end

        -- ── DROPDOWN ──────────────────────────────
        function Tab:Dropdown(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Dropdown"
            local options  = cfg.Options  or {}
            local default  = cfg.Default  or options[1] or "None"
            local multi    = cfg.Multi    or false
            local callback = cfg.Callback or function() end
            local selected = multi and {} or default
            LuckyCharms.Flags[flag] = selected

            local isOpen = false

            local wrap = New("Frame", {
                Size                   = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                ClipsDescendants       = false,
            }, Page)

            local header = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = C.BTN_BG,
                BorderSizePixel  = 0,
            }, wrap)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = header })
            Pad(header, 0, 0, 10, 8)

            New("TextLabel", {
                Size                   = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Dropdown",
                TextColor3             = C.TEXT,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, header)

            local arrow = New("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                Position               = UDim2.new(1, -6, 0.5, 0),
                Size                   = UDim2.fromOffset(12, 12),
                BackgroundTransparency = 1,
                Text                   = "▾",
                TextColor3             = C.TEXT_DIM,
                TextSize               = 12,
                Font                   = Enum.Font.GothamBold,
            }, header)

            local valDisp = New("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                Position               = UDim2.new(1, -20, 0.5, 0),
                Size                   = UDim2.fromOffset(120, 14),
                BackgroundTransparency = 1,
                Text                   = multi and "None" or tostring(default),
                TextColor3             = C.TEXT_DIM,
                TextSize               = 10,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Right,
                TextTruncate           = Enum.TextTruncate.AtEnd,
            }, header)

            local LIST_ITEM_H = 20
            local listH       = #options * LIST_ITEM_H + 4

            local optFrame = New("Frame", {
                Position         = UDim2.fromOffset(0, 23),
                Size             = UDim2.new(1, 0, 0, listH),
                BackgroundColor3 = C.BTN_BG,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 20,
                ClipsDescendants = true,
            }, wrap)
            New("UIStroke", { Color = C.GREEN, Thickness = 1, Parent = optFrame })
            List(optFrame, nil, 0)
            Pad(optFrame, 2, 2, 0, 0)

            local optBtns = {}

            local function SetDisplay()
                if multi then
                    local parts = {}
                    for k, vv in pairs(selected) do if vv then parts[#parts + 1] = k end end
                    valDisp.Text = #parts > 0 and table.concat(parts, ", ") or "None"
                else
                    valDisp.Text = tostring(selected)
                end
            end

            for _, opt in ipairs(options) do
                local isActive = multi and (selected[opt] == true) or (selected == opt)

                local ob = New("TextButton", {
                    Size             = UDim2.new(1, 0, 0, LIST_ITEM_H),
                    BackgroundColor3 = C.BTN_BG,
                    BorderSizePixel  = 0,
                    Text             = "",
                    AutoButtonColor  = false,
                    ZIndex           = 21,
                }, optFrame)

                local optLbl = New("TextLabel", {
                    Position               = UDim2.fromOffset(10, 0),
                    Size                   = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = tostring(opt),
                    TextColor3             = isActive and C.GREEN_TXT or C.TEXT_DIM,
                    TextSize               = 10,
                    Font                   = Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 22,
                }, ob)

                optBtns[opt] = { btn = ob, lbl = optLbl }

                ob.MouseEnter:Connect(function() Tween(ob, { BackgroundColor3 = C.BTN_HOV }, 0.08) end)
                ob.MouseLeave:Connect(function() Tween(ob, { BackgroundColor3 = C.BTN_BG  }, 0.08) end)

                ob.MouseButton1Click:Connect(function()
                    if multi then
                        selected[opt]        = not selected[opt]
                        optLbl.TextColor3    = selected[opt] and C.GREEN_TXT or C.TEXT_DIM
                        SetDisplay()
                        LuckyCharms.Flags[flag] = selected
                        callback(selected)
                    else
                        if optBtns[selected] then optBtns[selected].lbl.TextColor3 = C.TEXT_DIM end
                        selected             = opt
                        optLbl.TextColor3    = C.GREEN_TXT
                        SetDisplay()
                        LuckyCharms.Flags[flag] = selected
                        callback(selected)
                        isOpen             = false
                        optFrame.Visible   = false
                        wrap.Size          = UDim2.new(1, 0, 0, 22)
                        arrow.Text         = "▾"
                    end
                end)
            end

            local headerBtn = New("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                BorderSizePixel        = 0,
            }, header)

            headerBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                optFrame.Visible = isOpen
                wrap.Size        = UDim2.new(1, 0, 0, isOpen and (23 + listH) or 22)
                arrow.Text       = isOpen and "▴" or "▾"
            end)

            SetDisplay()

            LuckyCharms.Callbacks[flag] = function(v)
                if multi then
                    selected = v
                    for opt, b in pairs(optBtns) do
                        b.lbl.TextColor3 = selected[opt] and C.GREEN_TXT or C.TEXT_DIM
                    end
                else
                    if optBtns[selected] then optBtns[selected].lbl.TextColor3 = C.TEXT_DIM end
                    selected = v
                    if optBtns[v] then optBtns[v].lbl.TextColor3 = C.GREEN_TXT end
                end
                SetDisplay()
                LuckyCharms.Flags[flag] = selected
                callback(selected)
            end

            local obj = {}
            function obj:Set(v) LuckyCharms.Callbacks[flag](v) end
            function obj:Get() return selected end
            return obj
        end

        -- ── COLORPICKER ───────────────────────────
        -- Swatch inline in row; picker popup floats in OverlayGui so it's
        -- never clipped by the ScrollingFrame.
        function Tab:Colorpicker(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Color"
            local default  = cfg.Default  or Color3.fromRGB(255, 255, 255)
            local hasAlpha = cfg.Alpha    ~= nil
            local callback = cfg.Callback or function() end

            local h, s, v = default:ToHSV()
            local alpha    = cfg.Alpha or 0      -- 0 = fully opaque
            LuckyCharms.Flags[flag] = { Color = default, Alpha = alpha }

            local isOpen = false

            -- Row with swatch
            local f = Row(24)

            New("TextLabel", {
                Size                   = UDim2.new(1, -40, 1, 0),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Color",
                TextColor3             = C.TEXT,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, f)

            local swatchWrap = New("Frame", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -4, 0.5, 0),
                Size             = UDim2.fromOffset(30, 16),
                BackgroundColor3 = C.BORDER,
                BorderSizePixel  = 0,
            }, f)

            local swatch = New("Frame", {
                Position         = UDim2.fromOffset(1, 1),
                Size             = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = default,
                BorderSizePixel  = 0,
            }, swatchWrap)

            -- ── Picker popup (lives in OverlayGui so it's never clipped) ──
            local SV_W     = 150
            local SV_H     = 110
            local HUE_W    = 12
            local PICKER_W = SV_W + HUE_W + 16
            local PICKER_H = hasAlpha and 192 or 172

            local picker = New("Frame", {
                Size             = UDim2.fromOffset(PICKER_W, PICKER_H),
                Position         = UDim2.fromOffset(0, 0),   -- set on open
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 110,
            }, OverlayGui)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = picker })
            Pad(picker, 7, 7, 7, 7)

            -- SV square
            local svBox = New("Frame", {
                Size             = UDim2.fromOffset(SV_W, SV_H),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel  = 0,
                ZIndex           = 111,
            }, picker)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = svBox })

            local satOverlay = New("Frame", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 112,
            }, svBox)
            New("UIGradient", {
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                },
            }, satOverlay)

            local valOverlay = New("Frame", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = C.BLACK,
                BorderSizePixel  = 0,
                ZIndex           = 113,
            }, svBox)
            New("UIGradient", {
                Rotation     = 90,
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                },
            }, valOverlay)

            local svCursor = New("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(s, 0, 1 - v, 0),
                Size             = UDim2.fromOffset(8, 8),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 115,
            }, svBox)
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCursor })
            New("UIStroke", { Color = C.BLACK, Thickness = 1, Parent = svCursor })

            -- Hue bar (right of SV)
            local hueBar = New("Frame", {
                AnchorPoint      = Vector2.new(1, 0),
                Position         = UDim2.new(1, 0, 0, 0),
                Size             = UDim2.fromOffset(HUE_W, SV_H),
                BorderSizePixel  = 0,
                ZIndex           = 111,
            }, picker)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = hueBar })
            New("UIGradient", {
                Rotation = 90,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                    ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,    1, 1)),
                },
            }, hueBar)

            local hueCursor = New("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(0.5, 0, h, 0),
                Size             = UDim2.new(1, 4, 0, 4),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 115,
            }, hueBar)
            New("UIStroke", { Color = C.BLACK, Thickness = 1, Parent = hueCursor })

            -- Alpha bar (below SV, shown only when hasAlpha)
            local alphaBar, alphaCursor, alphaGrad
            if hasAlpha then
                alphaBar = New("Frame", {
                    Position         = UDim2.fromOffset(0, SV_H + 8),
                    Size             = UDim2.fromOffset(SV_W, 10),
                    BackgroundColor3 = C.WHITE,
                    BorderSizePixel  = 0,
                    ZIndex           = 111,
                }, picker)
                New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = alphaBar })

                alphaGrad = New("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, v)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(h, s, v)),
                    },
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    },
                }, alphaBar)

                alphaCursor = New("Frame", {
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(1 - alpha, 0, 0.5, 0),
                    Size             = UDim2.fromOffset(5, 14),
                    BackgroundColor3 = C.WHITE,
                    BorderSizePixel  = 0,
                    ZIndex           = 115,
                }, alphaBar)
                New("UIStroke", { Color = C.BLACK, Thickness = 1, Parent = alphaCursor })
            end

            -- Hex input
            local hexY = hasAlpha and (SV_H + 24) or (SV_H + 8)
            local hexBox = New("TextBox", {
                Position          = UDim2.fromOffset(0, hexY),
                Size              = UDim2.fromOffset(SV_W, 18),
                BackgroundColor3  = Color3.fromRGB(48, 48, 48),
                BorderSizePixel   = 0,
                Text              = "#" .. default:ToHex():upper(),
                TextColor3        = C.TEXT,
                PlaceholderText   = "#RRGGBB",
                PlaceholderColor3 = C.TEXT_DIM,
                TextSize          = 10,
                Font              = Enum.Font.Gotham,
                ClearTextOnFocus  = false,
                ZIndex            = 111,
            }, picker)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = hexBox })
            Pad(hexBox, 0, 0, 5, 0)

            -- RGB readout label
            local rgbLbl = New("TextLabel", {
                Position               = UDim2.fromOffset(0, hexY + 22),
                Size                   = UDim2.fromOffset(SV_W, 14),
                BackgroundTransparency = 1,
                Text                   = "",
                TextColor3             = C.TEXT_DIM,
                TextSize               = 9,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 111,
            }, picker)

            local function Refresh()
                local col = Color3.fromHSV(h, s, v)
                swatch.BackgroundColor3  = col
                svBox.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                svCursor.Position        = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position       = UDim2.new(0.5, 0, h, 0)
                hexBox.Text              = "#" .. col:ToHex():upper()
                rgbLbl.Text              = math.floor(col.R*255) .. ", " .. math.floor(col.G*255) .. ", " .. math.floor(col.B*255)
                if hasAlpha then
                    alphaCursor.Position = UDim2.new(1 - alpha, 0, 0.5, 0)
                    alphaGrad.Color      = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, col),
                        ColorSequenceKeypoint.new(1, col),
                    }
                end
                LuckyCharms.Flags[flag] = { Color = col, Alpha = alpha }
                callback(col, alpha)
            end

            local dragSV, dragHue, dragAlpha = false, false, false

            local function MkDragBtn(target, onDown, zidx)
                local b = New("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    BorderSizePixel        = 0,
                    ZIndex                 = zidx or 116,
                }, target)
                b.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then onDown() end
                end)
                return b
            end

            MkDragBtn(svBox,  function() dragSV    = true end, 116)
            MkDragBtn(hueBar, function() dragHue   = true end, 116)
            if hasAlpha then
                MkDragBtn(alphaBar, function() dragAlpha = true end, 116)
            end

            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragSV = false; dragHue = false; dragAlpha = false
                end
            end)

            UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if not isOpen then return end
                local mx, my = inp.Position.X, inp.Position.Y
                if dragSV then
                    s = math.clamp((mx - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((my - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                    Refresh()
                elseif dragHue then
                    h = math.clamp((my - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    Refresh()
                elseif dragAlpha and hasAlpha then
                    alpha = 1 - math.clamp((mx - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                    Refresh()
                end
            end)

            hexBox.FocusLost:Connect(function()
                local t = hexBox.Text:gsub("#", "")
                if #t == 6 then
                    local ok, col = pcall(Color3.fromHex, t)
                    if ok then h, s, v = col:ToHSV(); Refresh() end
                end
            end)

            -- Position picker relative to swatch in screen space
            local function OpenPicker()
                local sa  = swatchWrap.AbsolutePosition
                local ss  = swatchWrap.AbsoluteSize
                local gs  = gui.AbsoluteSize
                local px  = sa.X
                local py  = sa.Y + ss.Y + 4
                -- clamp so it doesn't go off screen
                px = math.clamp(px, 0, gs.X - PICKER_W - 4)
                py = math.clamp(py, 0, gs.Y - PICKER_H - 4)
                picker.Position = UDim2.fromOffset(px, py)
                picker.Visible  = true
                isOpen          = true
            end

            local swBtn = New("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                BorderSizePixel        = 0,
            }, swatchWrap)

            swBtn.MouseButton1Click:Connect(function()
                if isOpen then
                    picker.Visible = false
                    isOpen         = false
                else
                    OpenPicker()
                end
            end)

            -- Close when clicking outside
            UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe or not isOpen then return end
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp  = UserInputService:GetMouseLocation()
                    local pa  = picker.AbsolutePosition
                    local ps  = picker.AbsoluteSize
                    local sa2 = swatchWrap.AbsolutePosition
                    local ss2 = swatchWrap.AbsoluteSize
                    local inP = mp.X >= pa.X and mp.X <= pa.X+ps.X and mp.Y >= pa.Y and mp.Y <= pa.Y+ps.Y
                    local inS = mp.X >= sa2.X and mp.X <= sa2.X+ss2.X and mp.Y >= sa2.Y and mp.Y <= sa2.Y+ss2.Y
                    if not inP and not inS then
                        picker.Visible = false
                        isOpen         = false
                    end
                end
            end)

            Refresh()

            LuckyCharms.Callbacks[flag] = function(col, a)
                h, s, v = col:ToHSV()
                if a ~= nil then alpha = a end
                Refresh()
            end

            local obj = {}
            function obj:Set(col, a) LuckyCharms.Callbacks[flag](col, a) end
            function obj:Get()       return LuckyCharms.Flags[flag]       end
            return obj
        end

        -- ── KEYBIND ───────────────────────────────
        function Tab:Keybind(cfg)
            cfg = cfg or {}
            local flag      = cfg.Flag     or cfg.Name or "Keybind"
            local default   = cfg.Default  or nil
            local callback  = cfg.Callback or function() end
            local holdMode  = cfg.Hold     or false   -- true = fires while held
            local currentKey = default
            local listening  = false
            LuckyCharms.Flags[flag] = currentKey

            local f = Row(24)

            New("TextLabel", {
                Size                   = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Keybind",
                TextColor3             = C.TEXT,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, f)

            local badge = New("TextLabel", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -4, 0.5, 0),
                Size             = UDim2.fromOffset(52, 16),
                BackgroundColor3 = Color3.fromRGB(42, 42, 42),
                BorderSizePixel  = 0,
                Text             = currentKey and tostring(currentKey):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","") or "NONE",
                TextColor3       = C.TEXT_DIM,
                TextSize         = 9,
                Font             = Enum.Font.GothamSemibold,
            }, f)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = badge })

            local clickBtn = New("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                BorderSizePixel        = 0,
            }, f)

            local function RefreshBadge()
                if listening then
                    badge.Text      = "..."
                    badge.TextColor3 = C.TEXT
                    Tween(badge, { BackgroundColor3 = Color3.fromRGB(30, 80, 50) }, 0.1)
                else
                    badge.Text       = currentKey
                        and tostring(currentKey):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
                        or "NONE"
                    badge.TextColor3 = currentKey and C.GREEN_TXT or C.TEXT_DIM
                    Tween(badge, { BackgroundColor3 = Color3.fromRGB(42, 42, 42) }, 0.1)
                end
            end

            -- Left-click: enter listen mode
            clickBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                RefreshBadge()
            end)

            -- Right-click: clear keybind
            clickBtn.MouseButton2Click:Connect(function()
                currentKey = nil
                listening  = false
                LuckyCharms.Flags[flag] = nil
                RefreshBadge()
                callback(nil)
            end)

            clickBtn.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL2 }, 0.08) end)
            clickBtn.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL  }, 0.08) end)

            UserInputService.InputBegan:Connect(function(inp, gpe)
                if not listening then
                    -- fire callback if bound key pressed (not while game processing event for our own UI)
                    if currentKey and not gpe then
                        local pressedKey = inp.UserInputType == Enum.UserInputType.Keyboard
                            and inp.KeyCode or inp.UserInputType
                        if pressedKey == currentKey then
                            callback(currentKey)
                        end
                    end
                    return
                end
                -- in listen mode: accept any key or mouse button
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    if inp.KeyCode == Enum.KeyCode.Escape then
                        listening = false
                        RefreshBadge()
                        return
                    end
                    currentKey = inp.KeyCode
                elseif inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.MouseButton2
                    or inp.UserInputType == Enum.UserInputType.MouseButton3 then
                    currentKey = inp.UserInputType
                else
                    return
                end
                LuckyCharms.Flags[flag] = currentKey
                listening = false
                RefreshBadge()
                callback(currentKey)
            end)

            LuckyCharms.Callbacks[flag] = function(k)
                currentKey = k
                LuckyCharms.Flags[flag] = k
                listening  = false
                RefreshBadge()
                callback(k)
            end

            local obj = {}
            function obj:Set(k) LuckyCharms.Callbacks[flag](k) end
            function obj:Get() return currentKey end
            return obj
        end

        -- ── TEXTBOX ───────────────────────────────
        function Tab:Textbox(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Textbox"
            local default  = cfg.Default  or ""
            local callback = cfg.Callback or function() end
            local numeric  = cfg.Numeric  or false   -- only allow numbers
            LuckyCharms.Flags[flag] = default

            local f = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
            }, Page)
            Pad(f, 4, 4, 14, 8)

            New("TextLabel", {
                Size                   = UDim2.new(1, 0, 0, 14),
                BackgroundTransparency = 1,
                Text                   = cfg.Name or "Textbox",
                TextColor3             = C.TEXT_DIM,
                TextSize               = 10,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, f)

            local box = New("TextBox", {
                Position          = UDim2.fromOffset(0, 18),
                Size              = UDim2.new(1, 0, 0, 18),
                BackgroundColor3  = Color3.fromRGB(42, 42, 42),
                BorderSizePixel   = 0,
                Text              = default,
                PlaceholderText   = cfg.Placeholder or "...",
                TextColor3        = C.TEXT,
                PlaceholderColor3 = C.TEXT_DIM,
                TextSize          = 10,
                Font              = Enum.Font.Gotham,
                ClearTextOnFocus  = false,
                TextXAlignment    = Enum.TextXAlignment.Left,
            }, f)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = box })
            Pad(box, 0, 0, 6, 0)

            box:GetPropertyChangedSignal("Text"):Connect(function()
                local t = box.Text
                if numeric then
                    t = t:gsub("[^%d%.%-]", "")
                    if t ~= box.Text then box.Text = t end
                end
                LuckyCharms.Flags[flag] = t
                callback(t)
            end)

            LuckyCharms.Callbacks[flag] = function(val)
                box.Text = val
                LuckyCharms.Flags[flag] = val
                callback(val)
            end

            local obj = {}
            function obj:Set(v) LuckyCharms.Callbacks[flag](v) end
            function obj:Get() return box.Text end
            return obj
        end

        -- ── BUTTON ────────────────────────────────
        function Tab:Button(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end

            local btn = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = C.BTN_BG,
                BorderSizePixel  = 0,
                Text             = cfg.Name or "Button",
                TextColor3       = C.GREEN_TXT,
                TextSize         = 10,
                Font             = Enum.Font.Gotham,
                AutoButtonColor  = false,
            }, Page)
            New("UIStroke", { Color = C.BORDER, Thickness = 1, Parent = btn })

            btn.MouseEnter:Connect(function()  Tween(btn, { BackgroundColor3 = C.BTN_HOV }, 0.08) end)
            btn.MouseLeave:Connect(function()  Tween(btn, { BackgroundColor3 = C.BTN_BG  }, 0.08) end)
            btn.MouseButton1Click:Connect(function()
                Tween(btn, { BackgroundColor3 = Color3.fromRGB(44, 44, 44) }, 0.05)
                task.delay(0.1, function() Tween(btn, { BackgroundColor3 = C.BTN_BG }, 0.08) end)
                callback()
            end)

            local obj = {}
            function obj:SetText(t) btn.Text = t end
            function obj:Get()      return btn.Text end
            return obj
        end

        return Tab
    end  -- AddTab

    function Window:GetFlag(f) return LuckyCharms.Flags[f] end
    function Window:SetFlag(f, val)
        local cb = LuckyCharms.Callbacks[f]
        if cb then cb(val) end
    end

    return Window
end  -- CreateWindow

-- ══════════════════════════════════════════════════
--  GLOBAL API
-- ══════════════════════════════════════════════════
function LuckyCharms:GetFlag(f) return LuckyCharms.Flags[f] end
function LuckyCharms:SetFlag(f, val)
    local cb = LuckyCharms.Callbacks[f]
    if cb then cb(val) end
end
function LuckyCharms:Notify(title, msg, duration) DoNotify(title, msg, duration) end

return LuckyCharms
