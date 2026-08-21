-- LuckyCharms UI Library
-- ══════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════
local function GetGui()
    if gethui then return gethui() end
    return CoreGui
end

local function Tween(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 3)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(55, 55, 55)
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function MakePadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
    return p
end

local function MakeList(parent, dir, pad, sort)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = dir  or Enum.FillDirection.Vertical
    l.SortOrder      = sort or Enum.SortOrder.LayoutOrder
    l.Padding        = UDim.new(0, pad or 0)
    l.Parent = parent
    return l
end

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

-- ══════════════════════════════════════════════════
--  PALETTE
-- ══════════════════════════════════════════════════
local C = {
    BG        = Color3.fromRGB(28,  28,  28),
    SIDEBAR   = Color3.fromRGB(22,  22,  22),
    PANEL     = Color3.fromRGB(34,  34,  34),
    PANEL2    = Color3.fromRGB(40,  40,  40),
    ELEMENT   = Color3.fromRGB(44,  44,  44),
    STROKE    = Color3.fromRGB(52,  52,  52),
    GREEN     = Color3.fromRGB(15, 125,  45),
    GREEN_HI  = Color3.fromRGB(25, 155,  65),
    GREEN_DIM = Color3.fromRGB(10,  80,  30),
    TEXT      = Color3.fromRGB(215, 215, 215),
    TEXT_DIM  = Color3.fromRGB(130, 130, 130),
    TEXT_DARK = Color3.fromRGB( 80,  80,  80),
    WHITE     = Color3.fromRGB(255, 255, 255),
    BLACK     = Color3.fromRGB(  0,   0,   0),
    RED       = Color3.fromRGB(185,  45,  45),
}

-- ══════════════════════════════════════════════════
--  LIBRARY TABLE
-- ══════════════════════════════════════════════════
local LuckyCharms = {}
LuckyCharms.__index = LuckyCharms

LuckyCharms.Flags       = {}   -- live flag values  { [Flag] = value }
LuckyCharms.Callbacks   = {}   -- setter fns        { [Flag] = fn }
LuckyCharms.Connections = {}   -- cleanup list

function LuckyCharms:_Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self.Connections, c)
    return c
end

function LuckyCharms:Destroy()
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    if self._gui then self._gui:Destroy() end
end

-- ══════════════════════════════════════════════════
--  DRAGGING UTILITY
-- ══════════════════════════════════════════════════
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════════
local NotifHolder  -- set when window is created

local function Notify(title, msg, duration)
    if not NotifHolder then return end
    duration = duration or 3

    local frame = New("Frame", {
        Size              = UDim2.new(1, 0, 0, 0),
        BackgroundColor3  = C.PANEL,
        AutomaticSize     = Enum.AutomaticSize.Y,
        ClipsDescendants  = true,
        BorderSizePixel   = 0,
    }, NotifHolder)
    MakeCorner(frame, 4)
    MakeStroke(frame, C.STROKE)

    -- accent bar
    New("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = C.GREEN,
        BorderSizePixel  = 0,
    }, frame)

    local inner = New("Frame", {
        Position         = UDim2.fromOffset(10, 0),
        Size             = UDim2.new(1, -13, 1, 0),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
    }, frame)
    MakePadding(inner, 8, 8, 0, 6)

    New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.PANEL,
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = C.GREEN_HI,
        TextSize         = 12,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        AutomaticSize    = Enum.AutomaticSize.Y,
    }, inner)

    if msg and msg ~= "" then
        New("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = C.PANEL,
            BackgroundTransparency = 1,
            Text             = msg,
            TextColor3       = C.TEXT_DIM,
            TextSize         = 11,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            AutomaticSize    = Enum.AutomaticSize.Y,
        }, inner)
    end

    MakeList(inner, nil, 3)

    task.delay(duration, function()
        Tween(frame, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        frame:Destroy()
    end)
end

-- ══════════════════════════════════════════════════
--  CREATE WINDOW
-- ══════════════════════════════════════════════════
function LuckyCharms:CreateWindow(cfg)
    cfg = cfg or {}
    local Title    = cfg.Title    or "LuckyCharms"
    local SubTitle = cfg.SubTitle or ""
    local ToggleKey= cfg.Key      or Enum.KeyCode.Insert
    local Size     = cfg.Size     or { W = 620, H = 420 }

    local W = Size.W or 620
    local H = Size.H or 420
    local SIDEBAR_W = 80

    -- ── Root ScreenGui ──────────────────────────────
    local gui = New("ScreenGui", {
        Name            = "LuckyCharmsLib",
        ResetOnSpawn    = false,
        IgnoreGuiInset  = true,
        ZIndexBehavior  = Enum.ZIndexBehavior.Global,
    })
    gui.Parent = GetGui()
    self._gui = gui

    -- ── Notification holder (bottom-right corner) ───
    NotifHolder = New("Frame", {
        AnchorPoint      = Vector2.new(1, 1),
        Position         = UDim2.new(1, -16, 1, -16),
        Size             = UDim2.fromOffset(240, 0),
        BackgroundTransparency = 1,
        AutomaticSize    = Enum.AutomaticSize.Y,
        BorderSizePixel  = 0,
    }, gui)
    MakeList(NotifHolder, nil, 6)

    -- ── Main frame ──────────────────────────────────
    local Main = New("Frame", {
        Name             = "Main",
        Size             = UDim2.fromOffset(W, H),
        Position         = UDim2.new(0.5, -W/2, 0.5, -H/2),
        BackgroundColor3 = C.BG,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, gui)
    MakeCorner(Main, 5)
    MakeStroke(Main, C.STROKE, 1)
    MakeDraggable(Main, Main)

    -- ── Sidebar ─────────────────────────────────────
    local Sidebar = New("Frame", {
        Size             = UDim2.new(0, SIDEBAR_W, 1, 0),
        BackgroundColor3 = C.SIDEBAR,
        BorderSizePixel  = 0,
    }, Main)
    MakeStroke(Sidebar, C.STROKE, 1)

    -- Logo block
    local LogoFrame = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = C.SIDEBAR,
        BorderSizePixel  = 0,
    }, Sidebar)

    -- green top accent bar
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = C.GREEN,
        BorderSizePixel  = 0,
    }, LogoFrame)

    -- shamrock icon (text stand-in)
    New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 32),
        Position         = UDim2.fromOffset(0, 10),
        BackgroundTransparency = 1,
        Text             = "☘",
        TextColor3       = C.GREEN,
        TextSize         = 22,
        Font             = Enum.Font.GothamBold,
    }, LogoFrame)

    New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 14),
        Position         = UDim2.fromOffset(0, 44),
        BackgroundTransparency = 1,
        Text             = "LC",
        TextColor3       = Color3.fromRGB(180, 220, 180),
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
    }, LogoFrame)

    -- Divider under logo
    New("Frame", {
        Position         = UDim2.new(0, 8, 0, 63),
        Size             = UDim2.new(1, -16, 0, 1),
        BackgroundColor3 = C.STROKE,
        BorderSizePixel  = 0,
    }, Sidebar)

    -- Tab button list
    local TabList = New("Frame", {
        Position         = UDim2.fromOffset(0, 68),
        Size             = UDim2.new(1, 0, 1, -68),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
    }, Sidebar)
    MakeList(TabList, nil, 2)

    -- ── Content area ────────────────────────────────
    local Content = New("Frame", {
        Position         = UDim2.fromOffset(SIDEBAR_W, 0),
        Size             = UDim2.new(1, -SIDEBAR_W, 1, 0),
        BackgroundColor3 = C.BG,
        BorderSizePixel  = 0,
    }, Main)

    -- Title bar inside content
    local TitleBar = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = C.PANEL,
        BorderSizePixel  = 0,
    }, Content)
    MakeStroke(TitleBar, C.STROKE, 1)
    MakePadding(TitleBar, 0, 0, 10, 10)

    New("TextLabel", {
        Size             = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Text             = Title .. (SubTitle ~= "" and ("  |  " .. SubTitle) or ""),
        TextColor3       = C.TEXT,
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, TitleBar)

    -- Close button
    local CloseBtn = New("TextButton", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.fromOffset(18, 18),
        BackgroundColor3 = C.RED,
        Text             = "×",
        TextColor3       = C.WHITE,
        TextSize         = 14,
        Font             = Enum.Font.GothamBold,
        AutoButtonColor  = false,
        BorderSizePixel  = 0,
    }, TitleBar)
    MakeCorner(CloseBtn, 3)
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
    end)

    -- Page holder (below title bar)
    local PageHolder = New("Frame", {
        Position         = UDim2.fromOffset(0, 34),
        Size             = UDim2.new(1, 0, 1, -34),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, Content)

    -- ── Toggle visibility with key ───────────────────
    local visible = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == ToggleKey then
            visible = not visible
            Main.Visible = visible
        end
    end)

    -- ══════════════════════════════════════════════
    --  WINDOW OBJECT (returned to caller)
    -- ══════════════════════════════════════════════
    local Window = {}
    Window._tabs       = {}
    Window._activeTab  = nil
    Window._lib        = self

    -- Notification shortcut
    function Window:Notify(title, msg, duration)
        Notify(title, msg, duration)
    end

    -- ── AddTab ──────────────────────────────────────
    function Window:AddTab(name, icon)
        -- ── Sidebar button ──────────────────────────
        local isFirst = #self._tabs == 0

        local BtnFrame = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = isFirst and C.PANEL or C.SIDEBAR,
            BorderSizePixel  = 0,
        }, TabList)

        -- selection indicator bar (left edge)
        local Indicator = New("Frame", {
            Size             = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = C.GREEN,
            BorderSizePixel  = 0,
            Visible          = isFirst,
        }, BtnFrame)

        local BtnLabel = New("TextLabel", {
            Position         = UDim2.fromOffset(3, 0),
            Size             = UDim2.new(1, -3, 1, 0),
            BackgroundTransparency = 1,
            Text             = icon and (icon.."\n"..name) or name,
            TextColor3       = isFirst and C.GREEN_HI or C.TEXT_DIM,
            TextSize         = 11,
            Font             = Enum.Font.Gotham,
            TextWrapped      = true,
        }, BtnFrame)

        -- invisible click button over the frame
        local BtnClick = New("TextButton", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text             = "",
            BorderSizePixel  = 0,
        }, BtnFrame)

        -- ── Page frame ──────────────────────────────
        local Page = New("ScrollingFrame", {
            Size                = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel     = 0,
            ScrollBarThickness  = 3,
            ScrollBarImageColor3= C.GREEN_DIM,
            CanvasSize          = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
            Visible             = isFirst,
        }, PageHolder)
        MakePadding(Page, 10, 10, 10, 10)
        MakeList(Page, nil, 6)

        -- ── Tab object ──────────────────────────────
        local Tab = {}
        Tab._page   = Page
        Tab._lib    = self._lib
        Tab._btn    = BtnFrame
        Tab._label  = BtnLabel
        Tab._indic  = Indicator

        table.insert(self._tabs, Tab)

        if isFirst then
            self._activeTab = Tab
        end

        -- Switch tab logic
        BtnClick.MouseButton1Click:Connect(function()
            if self._activeTab == Tab then return end
            -- hide old
            if self._activeTab then
                self._activeTab._page.Visible    = false
                self._activeTab._indic.Visible   = false
                Tween(self._activeTab._btn,   { BackgroundColor3 = C.SIDEBAR }, 0.12)
                Tween(self._activeTab._label, { TextColor3       = C.TEXT_DIM }, 0.12)
            end
            -- show new
            Tab._page.Visible  = true
            Tab._indic.Visible = true
            Tween(BtnFrame,   { BackgroundColor3 = C.PANEL }, 0.12)
            Tween(BtnLabel,   { TextColor3       = C.GREEN_HI }, 0.12)
            self._activeTab = Tab
        end)

        -- Hover
        BtnClick.MouseEnter:Connect(function()
            if self._activeTab ~= Tab then
                Tween(BtnFrame, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, 0.1)
            end
        end)
        BtnClick.MouseLeave:Connect(function()
            if self._activeTab ~= Tab then
                Tween(BtnFrame, { BackgroundColor3 = C.SIDEBAR }, 0.1)
            end
        end)

        -- ════════════════════════════════════════════
        --  COMPONENT BUILDERS
        -- ════════════════════════════════════════════

        -- ── internal helpers ────────────────────────
        local function ElementBase(height)
            local f = New("Frame", {
                Size             = UDim2.new(1, 0, 0, height or 28),
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
            }, Page)
            MakeCorner(f, 4)
            MakeStroke(f, C.STROKE, 1)
            MakePadding(f, 0, 0, 8, 8)
            return f
        end

        local function ElemLabel(parent, text, xOffset, yOffset, color, size)
            return New("TextLabel", {
                Position         = UDim2.fromOffset(xOffset or 0, yOffset or 0),
                Size             = UDim2.new(1, -(xOffset or 0), 1, 0),
                BackgroundTransparency = 1,
                Text             = text or "",
                TextColor3       = color or C.TEXT,
                TextSize         = size or 12,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, parent)
        end

        -- ────────────────────────────────────────────
        --  LABEL
        -- ────────────────────────────────────────────
        function Tab:Label(cfg)
            cfg = cfg or {}
            local f = ElementBase(22)
            f.BackgroundColor3 = C.BG
            f.Size = UDim2.new(1, 0, 0, 22)

            local lbl = ElemLabel(f, cfg.Name or "Label", 0, 0, C.TEXT_DARK, 11)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextColor3 = C.GREEN_DIM

            local obj = {}
            function obj:Set(text) lbl.Text = text end
            return obj
        end

        -- ────────────────────────────────────────────
        --  SEPARATOR
        -- ────────────────────────────────────────────
        function Tab:Separator()
            New("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = C.STROKE,
                BorderSizePixel  = 0,
            }, Page)
        end

        -- ────────────────────────────────────────────
        --  TOGGLE
        -- ────────────────────────────────────────────
        function Tab:Toggle(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Toggle"
            local default  = cfg.Default  or false
            local callback = cfg.Callback or function() end

            local enabled = default
            LuckyCharms.Flags[flag] = enabled

            local f = ElementBase(28)

            ElemLabel(f, cfg.Name or "Toggle", 26, 0)

            -- checkbox box
            local box = New("Frame", {
                Position         = UDim2.fromOffset(0, 8),
                Size             = UDim2.fromOffset(12, 12),
                BackgroundColor3 = enabled and C.GREEN or C.ELEMENT,
                BorderSizePixel  = 0,
            }, f)
            MakeCorner(box, 2)
            MakeStroke(box, C.STROKE)

            -- checkmark
            local check = New("TextLabel", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "✓",
                TextColor3       = C.WHITE,
                TextSize         = 10,
                Font             = Enum.Font.GothamBold,
                Visible          = enabled,
            }, box)

            -- click area
            local btn = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                BorderSizePixel  = 0,
            }, f)

            local function setEnabled(val)
                enabled = val
                LuckyCharms.Flags[flag] = val
                check.Visible = val
                Tween(box, { BackgroundColor3 = val and C.GREEN or C.ELEMENT }, 0.15)
                callback(val)
            end

            btn.MouseButton1Click:Connect(function()
                setEnabled(not enabled)
            end)

            LuckyCharms.Callbacks[flag] = setEnabled

            local obj = {}
            function obj:Set(v) setEnabled(v) end
            function obj:Get() return enabled end
            return obj
        end

        -- ────────────────────────────────────────────
        --  SLIDER
        -- ────────────────────────────────────────────
        function Tab:Slider(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Slider"
            local min      = cfg.Min      or 0
            local max      = cfg.Max      or 100
            local default  = cfg.Default  or min
            local suffix   = cfg.Suffix   or ""
            local decimal  = cfg.Decimal  or 0
            local callback = cfg.Callback or function() end

            local value = math.clamp(default, min, max)
            LuckyCharms.Flags[flag] = value

            local f = ElementBase(44)
            f.Size = UDim2.new(1, 0, 0, 44)

            -- Name
            ElemLabel(f, cfg.Name or "Slider", 0, 2, C.TEXT, 12)

            -- Value readout
            local fmt = decimal > 0 and ("%."..tostring(math.max(1, -math.log10(decimal))).. "f") or "%d"
            local valLabel = New("TextLabel", {
                AnchorPoint      = Vector2.new(1, 0),
                Position         = UDim2.new(1, -8, 0, 2),
                Size             = UDim2.fromOffset(60, 16),
                BackgroundTransparency = 1,
                Text             = string.format(fmt, value) .. suffix,
                TextColor3       = C.GREEN_HI,
                TextSize         = 11,
                Font             = Enum.Font.GothamBold,
                TextXAlignment   = Enum.TextXAlignment.Right,
            }, f)

            -- Track background
            local track = New("Frame", {
                Position         = UDim2.new(0, 0, 0, 26),
                Size             = UDim2.new(1, 0, 0, 8),
                BackgroundColor3 = C.ELEMENT,
                BorderSizePixel  = 0,
            }, f)
            MakeCorner(track, 4)
            MakeStroke(track, C.STROKE)

            -- Fill
            local fill = New("Frame", {
                Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = C.GREEN,
                BorderSizePixel  = 0,
            }, track)
            MakeCorner(fill, 4)

            -- Draggable button over track
            local dragBtn = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                BorderSizePixel  = 0,
            }, track)

            local dragging = false

            local function updateFromX(absX)
                local rx = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local raw = min + rx * (max - min)
                if decimal > 0 then
                    raw = math.floor(raw / decimal + 0.5) * decimal
                else
                    raw = math.floor(raw + 0.5)
                end
                value = math.clamp(raw, min, max)
                LuckyCharms.Flags[flag] = value
                Tween(fill, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) }, 0.05)
                valLabel.Text = string.format(fmt, value) .. suffix
                callback(value)
            end

            dragBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateFromX(inp.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromX(inp.Position.X)
                end
            end)

            LuckyCharms.Callbacks[flag] = function(v)
                value = math.clamp(v, min, max)
                LuckyCharms.Flags[flag] = value
                Tween(fill, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) }, 0.05)
                valLabel.Text = string.format(fmt, value) .. suffix
                callback(value)
            end

            local obj = {}
            function obj:Set(v) LuckyCharms.Callbacks[flag](v) end
            function obj:Get() return value end
            return obj
        end

        -- ────────────────────────────────────────────
        --  DROPDOWN
        -- ────────────────────────────────────────────
        function Tab:Dropdown(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Dropdown"
            local options  = cfg.Options  or {}
            local default  = cfg.Default  or (options[1] or "None")
            local multi    = cfg.Multi    or false
            local callback = cfg.Callback or function() end

            local selected = multi and {} or default
            LuckyCharms.Flags[flag] = selected

            local isOpen = false

            -- outer container (auto-sizes when open)
            local container = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
            }, Page)

            -- header row
            local header = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
            }, container)
            MakeCorner(header, 4)
            MakeStroke(header, C.STROKE)
            MakePadding(header, 0, 0, 8, 8)

            ElemLabel(header, cfg.Name or "Dropdown", 0, 0, C.TEXT, 12)

            local arrow = New("TextLabel", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -8, 0.5, 0),
                Size             = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Text             = "▾",
                TextColor3       = C.TEXT_DIM,
                TextSize         = 14,
                Font             = Enum.Font.GothamBold,
            }, header)

            -- current value display
            local valDisp = New("TextLabel", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -22, 0.5, 0),
                Size             = UDim2.fromOffset(140, 16),
                BackgroundTransparency = 1,
                Text             = multi and "None" or tostring(default),
                TextColor3       = C.GREEN_HI,
                TextSize         = 11,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Right,
            }, header)

            -- options list (hidden by default)
            local optHolder = New("Frame", {
                Position         = UDim2.fromOffset(0, 30),
                Size             = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = C.PANEL2,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                Visible          = false,
                ZIndex           = 10,
            }, container)
            MakeCorner(optHolder, 4)
            MakeStroke(optHolder, C.GREEN_DIM)
            MakePadding(optHolder, 4, 4, 4, 4)
            MakeList(optHolder, nil, 2)

            local optHeight = 0

            local function setDisplay()
                if multi then
                    local parts = {}
                    for k, v in pairs(selected) do if v then table.insert(parts, k) end end
                    valDisp.Text = #parts > 0 and table.concat(parts, ", ") or "None"
                else
                    valDisp.Text = tostring(selected)
                end
            end

            -- build option buttons
            local optBtns = {}
            for _, opt in ipairs(options) do
                local ob = New("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = C.PANEL2,
                    BorderSizePixel  = 0,
                    Text             = "",
                    AutoButtonColor  = false,
                }, optHolder)
                MakeCorner(ob, 3)

                local isChecked = multi and (selected[opt] == true) or (selected == opt)

                local optLbl = New("TextLabel", {
                    Size             = UDim2.new(1, -22, 1, 0),
                    Position         = UDim2.fromOffset(6, 0),
                    BackgroundTransparency = 1,
                    Text             = tostring(opt),
                    TextColor3       = isChecked and C.GREEN_HI or C.TEXT,
                    TextSize         = 11,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 11,
                }, ob)

                local dot = New("Frame", {
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -6, 0.5, 0),
                    Size             = UDim2.fromOffset(6, 6),
                    BackgroundColor3 = isChecked and C.GREEN or C.ELEMENT,
                    BorderSizePixel  = 0,
                    ZIndex           = 11,
                }, ob)
                MakeCorner(dot, 10)

                optBtns[opt] = { btn = ob, lbl = optLbl, dot = dot }
                optHeight = optHeight + 24

                ob.MouseButton1Click:Connect(function()
                    if multi then
                        selected[opt] = not selected[opt]
                        local on = selected[opt]
                        Tween(optLbl, { TextColor3 = on and C.GREEN_HI or C.TEXT }, 0.1)
                        Tween(dot,    { BackgroundColor3 = on and C.GREEN or C.ELEMENT }, 0.1)
                        setDisplay()
                        LuckyCharms.Flags[flag] = selected
                        callback(selected)
                    else
                        -- deselect old
                        if optBtns[selected] then
                            Tween(optBtns[selected].lbl, { TextColor3 = C.TEXT }, 0.1)
                            Tween(optBtns[selected].dot, { BackgroundColor3 = C.ELEMENT }, 0.1)
                        end
                        selected = opt
                        Tween(optLbl, { TextColor3 = C.GREEN_HI }, 0.1)
                        Tween(dot,    { BackgroundColor3 = C.GREEN }, 0.1)
                        setDisplay()
                        LuckyCharms.Flags[flag] = selected
                        callback(selected)
                        -- close
                        isOpen = false
                        Tween(optHolder, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                        task.delay(0.16, function() optHolder.Visible = false end)
                        container.Size = UDim2.new(1, 0, 0, 28)
                        arrow.Text = "▾"
                    end
                end)
            end

            optHeight = optHeight + 8

            -- toggle open/close
            local headerBtn = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                BorderSizePixel  = 0,
            }, header)

            headerBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    optHolder.Visible = true
                    optHolder.Size = UDim2.new(1, 0, 0, 0)
                    Tween(optHolder, { Size = UDim2.new(1, 0, 0, optHeight) }, 0.18)
                    container.Size = UDim2.new(1, 0, 0, 30 + optHeight)
                    arrow.Text = "▴"
                else
                    Tween(optHolder, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    task.delay(0.16, function() optHolder.Visible = false end)
                    container.Size = UDim2.new(1, 0, 0, 28)
                    arrow.Text = "▾"
                end
            end)

            setDisplay()

            LuckyCharms.Callbacks[flag] = function(v)
                if multi then
                    selected = v
                    for opt, btns in pairs(optBtns) do
                        local on = selected[opt]
                        btns.lbl.TextColor3  = on and C.GREEN_HI or C.TEXT
                        btns.dot.BackgroundColor3 = on and C.GREEN or C.ELEMENT
                    end
                else
                    if optBtns[selected] then
                        optBtns[selected].lbl.TextColor3 = C.TEXT
                        optBtns[selected].dot.BackgroundColor3 = C.ELEMENT
                    end
                    selected = v
                    if optBtns[v] then
                        optBtns[v].lbl.TextColor3 = C.GREEN_HI
                        optBtns[v].dot.BackgroundColor3 = C.GREEN
                    end
                end
                setDisplay()
                LuckyCharms.Flags[flag] = selected
                callback(selected)
            end

            local obj = {}
            function obj:Set(v) LuckyCharms.Callbacks[flag](v) end
            function obj:Get() return selected end
            function obj:Refresh(newOptions)
                -- clear & rebuild
                for _, b in pairs(optBtns) do b.btn:Destroy() end
                optBtns = {}
                optHeight = 0
                options = newOptions
                -- re-run the inner builder (simplified: caller rebuilds via RefreshOptions)
            end
            return obj
        end

        -- ────────────────────────────────────────────
        --  COLORPICKER
        -- ────────────────────────────────────────────
        function Tab:Colorpicker(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Color"
            local default  = cfg.Default  or Color3.fromRGB(255, 255, 255)
            local callback = cfg.Callback or function() end

            local h, s, v = default:ToHSV()
            local alpha = cfg.Alpha or 0

            LuckyCharms.Flags[flag] = { Color = default, Alpha = alpha }

            local isOpen = false

            -- row
            local row = ElementBase(28)

            ElemLabel(row, cfg.Name or "Color", 0, 0, C.TEXT, 12)

            -- swatch preview button
            local swatchOuter = New("Frame", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -8, 0.5, 0),
                Size             = UDim2.fromOffset(28, 14),
                BackgroundColor3 = C.STROKE,
                BorderSizePixel  = 0,
            }, row)
            MakeCorner(swatchOuter, 3)

            local swatch = New("Frame", {
                Position         = UDim2.fromOffset(1, 1),
                Size             = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = default,
                BorderSizePixel  = 0,
            }, swatchOuter)
            MakeCorner(swatch, 2)

            -- picker popup
            local PICKER_W, PICKER_H = 200, 180
            local picker = New("Frame", {
                Size             = UDim2.fromOffset(PICKER_W, PICKER_H),
                Position         = UDim2.fromOffset(0, 30),
                BackgroundColor3 = C.PANEL,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 20,
            }, row)
            MakeCorner(picker, 5)
            MakeStroke(picker, C.STROKE)
            MakePadding(picker, 6, 6, 6, 6)

            -- SV gradient square
            local svBox = New("Frame", {
                Size             = UDim2.new(1, -20, 0, 110),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel  = 0,
            }, picker)
            MakeCorner(svBox, 3)

            -- white→transparent gradient (saturation)
            New("UIGradient", {
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                    ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
                },
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                },
            }, svBox)

            -- black→transparent gradient (value) layered on top
            local valOverlay = New("Frame", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(0,0,0),
                BorderSizePixel  = 0,
            }, svBox)
            MakeCorner(valOverlay, 3)
            New("UIGradient", {
                Rotation     = 90,
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                },
            }, valOverlay)

            -- SV cursor
            local svCursor = New("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(s, 0, 1 - v, 0),
                Size             = UDim2.fromOffset(8, 8),
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel  = 0,
                ZIndex           = 22,
            }, svBox)
            MakeCorner(svCursor, 10)
            MakeStroke(svCursor, C.BLACK, 1)

            -- Hue bar (right side)
            local hueBar = New("Frame", {
                AnchorPoint      = Vector2.new(1, 0),
                Position         = UDim2.new(1, 0, 0, 0),
                Size             = UDim2.new(0, 14, 0, 110),
                BackgroundColor3 = Color3.new(1,0,0),
                BorderSizePixel  = 0,
            }, picker)
            MakeCorner(hueBar, 3)

            -- 7-stop rainbow gradient
            local hueColors = {}
            local stops = {0, 1/6, 2/6, 3/6, 4/6, 5/6, 1}
            local hues   = {0,   0,   1/6, 2/6, 3/6, 4/6, 5/6}
            -- simpler: manual rainbow
            New("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,   1, 1)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1, 1)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1, 1)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50,1, 1)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1, 1)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1, 1)),
                    ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,   1, 1)),
                },
            }, hueBar)

            -- hue cursor
            local hueCursor = New("Frame", {
                Position         = UDim2.new(0, -1, h, -2),
                Size             = UDim2.new(1, 2, 0, 4),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 22,
            }, hueBar)
            MakeCorner(hueCursor, 2)

            -- Alpha bar
            local alphaBar = New("Frame", {
                Position         = UDim2.new(0, 0, 0, 118),
                Size             = UDim2.new(1, -20, 0, 10),
                BackgroundColor3 = C.ELEMENT,
                BorderSizePixel  = 0,
            }, picker)
            MakeCorner(alphaBar, 3)
            MakeStroke(alphaBar, C.STROKE)

            local alphaFill = New("Frame", {
                Size             = UDim2.new(1 - alpha, 0, 1, 0),
                BackgroundColor3 = C.GREEN,
                BorderSizePixel  = 0,
            }, alphaBar)
            MakeCorner(alphaFill, 3)

            -- alpha cursor
            local alphaCursor = New("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(1 - alpha, 0, 0.5, 0),
                Size             = UDim2.fromOffset(6, 14),
                BackgroundColor3 = C.WHITE,
                BorderSizePixel  = 0,
                ZIndex           = 22,
            }, alphaBar)
            MakeCorner(alphaCursor, 3)
            MakeStroke(alphaCursor, C.BLACK, 1)

            -- Hex input
            local hexBox = New("TextBox", {
                Position         = UDim2.new(0, 0, 0, 136),
                Size             = UDim2.new(1, -20, 0, 18),
                BackgroundColor3 = C.ELEMENT,
                BorderSizePixel  = 0,
                Text             = "",
                PlaceholderText  = "#RRGGBB",
                TextColor3       = C.TEXT,
                PlaceholderColor3= C.TEXT_DIM,
                TextSize         = 11,
                Font             = Enum.Font.Gotham,
                ClearTextOnFocus = false,
            }, picker)
            MakeCorner(hexBox, 3)
            MakeStroke(hexBox, C.STROKE)
            MakePadding(hexBox, 0, 0, 6, 0)

            local function refreshAll()
                local col = Color3.fromHSV(h, s, v)
                swatch.BackgroundColor3 = col
                svBox.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
                svCursor.Position       = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position      = UDim2.new(0, -1, h, -2)
                alphaCursor.Position    = UDim2.new(1 - alpha, 0, 0.5, 0)
                alphaFill.Size          = UDim2.new(1 - alpha, 0, 1, 0)
                hexBox.Text             = "#" .. col:ToHex():upper()
                LuckyCharms.Flags[flag] = { Color = col, Alpha = alpha }
                callback(col, alpha)
            end

            -- drag state
            local dragSV, dragHue, dragAlpha = false, false, false

            local svBtn = New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", BorderSizePixel=0, ZIndex=21
            }, svBox)
            svBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true end
            end)

            local hueBtn = New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", BorderSizePixel=0, ZIndex=21
            }, hueBar)
            hueBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragHue = true end
            end)

            local alphaBtn = New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", BorderSizePixel=0, ZIndex=21
            }, alphaBar)
            alphaBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragAlpha = true end
            end)

            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragSV = false; dragHue = false; dragAlpha = false
                end
            end)

            UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local mx, my = inp.Position.X, inp.Position.Y
                if dragSV then
                    s = math.clamp((mx - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((my - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                    refreshAll()
                elseif dragHue then
                    h = math.clamp((my - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    refreshAll()
                elseif dragAlpha then
                    alpha = 1 - math.clamp((mx - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                    refreshAll()
                end
            end)

            hexBox.FocusLost:Connect(function()
                local txt = hexBox.Text:gsub("#", "")
                if #txt == 6 then
                    local ok, col = pcall(Color3.fromHex, txt)
                    if ok then
                        h, s, v = col:ToHSV()
                        refreshAll()
                    end
                end
            end)

            -- toggle swatch click
            local swatchBtn = New("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", BorderSizePixel=0
            }, swatchOuter)
            swatchBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                picker.Visible = isOpen
            end)

            -- click outside to close
            UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
                    local mp = UserInputService:GetMouseLocation()
                    local pa = picker.AbsolutePosition
                    local ps = picker.AbsoluteSize
                    if mp.X < pa.X or mp.X > pa.X + ps.X or mp.Y < pa.Y or mp.Y > pa.Y + ps.Y then
                        -- also ignore swatch
                        local sa = swatchOuter.AbsolutePosition
                        local ss = swatchOuter.AbsoluteSize
                        if not (mp.X >= sa.X and mp.X <= sa.X + ss.X and mp.Y >= sa.Y and mp.Y <= sa.Y + ss.Y) then
                            isOpen = false
                            picker.Visible = false
                        end
                    end
                end
            end)

            refreshAll()

            LuckyCharms.Callbacks[flag] = function(col, a)
                h, s, v = col:ToHSV()
                alpha = a or alpha
                refreshAll()
            end

            local obj = {}
            function obj:Set(col, a) LuckyCharms.Callbacks[flag](col, a) end
            function obj:Get() return LuckyCharms.Flags[flag] end
            return obj
        end

        -- ────────────────────────────────────────────
        --  KEYBIND
        -- ────────────────────────────────────────────
        function Tab:Keybind(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Keybind"
            local default  = cfg.Default  or nil
            local callback = cfg.Callback or function() end

            local currentKey = default
            local binding    = false
            LuckyCharms.Flags[flag] = currentKey

            local f = ElementBase(28)

            ElemLabel(f, cfg.Name or "Keybind", 0, 0, C.TEXT, 12)

            local keyBtn = New("TextButton", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -8, 0.5, 0),
                Size             = UDim2.fromOffset(56, 18),
                BackgroundColor3 = C.ELEMENT,
                Text             = currentKey and currentKey.Name or "None",
                TextColor3       = C.GREEN_HI,
                TextSize         = 11,
                Font             = Enum.Font.GothamBold,
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
            }, f)
            MakeCorner(keyBtn, 3)
            MakeStroke(keyBtn, C.STROKE)

            local listening = false

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text      = "..."
                keyBtn.TextColor3 = C.TEXT_DIM
            end)

            keyBtn.MouseButton2Click:Connect(function()
                currentKey = nil
                LuckyCharms.Flags[flag] = nil
                keyBtn.Text = "None"
                keyBtn.TextColor3 = C.GREEN_HI
                callback(nil)
            end)

            UserInputService.InputBegan:Connect(function(inp, gpe)
                if not listening then return end
                if gpe then return end

                local key = nil
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    if inp.KeyCode == Enum.KeyCode.Escape then
                        -- cancel
                        keyBtn.Text = currentKey and currentKey.Name or "None"
                        keyBtn.TextColor3 = C.GREEN_HI
                        listening = false
                        return
                    end
                    key = inp.KeyCode
                elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    key = inp.UserInputType
                elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                    key = inp.UserInputType
                end

                if key then
                    currentKey = key
                    LuckyCharms.Flags[flag] = key
                    local name = tostring(key):gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", "")
                    keyBtn.Text = name
                    keyBtn.TextColor3 = C.GREEN_HI
                    listening = false
                    callback(key)
                end
            end)

            LuckyCharms.Callbacks[flag] = function(k)
                currentKey = k
                LuckyCharms.Flags[flag] = k
                local name = k and (tostring(k):gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", "")) or "None"
                keyBtn.Text = name
                keyBtn.TextColor3 = C.GREEN_HI
                callback(k)
            end

            local obj = {}
            function obj:Set(k) LuckyCharms.Callbacks[flag](k) end
            function obj:Get() return currentKey end
            return obj
        end

        -- ────────────────────────────────────────────
        --  TEXTBOX
        -- ────────────────────────────────────────────
        function Tab:Textbox(cfg)
            cfg = cfg or {}
            local flag     = cfg.Flag     or cfg.Name or "Textbox"
            local default  = cfg.Default  or ""
            local callback = cfg.Callback or function() end

            LuckyCharms.Flags[flag] = default

            local f = ElementBase(28)

            ElemLabel(f, cfg.Name or "Textbox", 0, 0, C.TEXT_DIM, 11)

            local box = New("TextBox", {
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -8, 0.5, 0),
                Size             = UDim2.fromOffset(130, 18),
                BackgroundColor3 = C.ELEMENT,
                BorderSizePixel  = 0,
                Text             = default,
                PlaceholderText  = cfg.Placeholder or "...",
                TextColor3       = C.TEXT,
                PlaceholderColor3= C.TEXT_DIM,
                TextSize         = 11,
                Font             = Enum.Font.Gotham,
                ClearTextOnFocus = false,
            }, f)
            MakeCorner(box, 3)
            MakeStroke(box, C.STROKE)
            MakePadding(box, 0, 0, 5, 5)

            box:GetPropertyChangedSignal("Text"):Connect(function()
                LuckyCharms.Flags[flag] = box.Text
                callback(box.Text)
            end)

            -- focus highlight
            box.Focused:Connect(function()
                Tween(box, { BackgroundColor3 = C.PANEL2 }, 0.1)
            end)
            box.FocusLost:Connect(function()
                Tween(box, { BackgroundColor3 = C.ELEMENT }, 0.1)
            end)

            LuckyCharms.Callbacks[flag] = function(v)
                box.Text = v
                LuckyCharms.Flags[flag] = v
                callback(v)
            end

            local obj = {}
            function obj:Set(v) LuckyCharms.Callbacks[flag](v) end
            function obj:Get() return box.Text end
            return obj
        end

        -- ────────────────────────────────────────────
        --  BUTTON
        -- ────────────────────────────────────────────
        function Tab:Button(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end

            local f = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = C.GREEN_DIM,
                BorderSizePixel  = 0,
                Text             = cfg.Name or "Button",
                TextColor3       = Color3.fromRGB(180, 230, 180),
                TextSize         = 12,
                Font             = Enum.Font.GothamBold,
                AutoButtonColor  = false,
            }, Page)
            MakeCorner(f, 4)
            MakeStroke(f, C.GREEN_DIM)

            f.MouseEnter:Connect(function()
                Tween(f, { BackgroundColor3 = C.GREEN }, 0.12)
            end)
            f.MouseLeave:Connect(function()
                Tween(f, { BackgroundColor3 = C.GREEN_DIM }, 0.12)
            end)
            f.MouseButton1Click:Connect(function()
                Tween(f, { BackgroundColor3 = C.GREEN_HI }, 0.06)
                task.delay(0.12, function()
                    Tween(f, { BackgroundColor3 = C.GREEN_DIM }, 0.12)
                end)
                callback()
            end)

            local obj = {}
            function obj:SetText(t) f.Text = t end
            return obj
        end

        -- ────────────────────────────────────────────
        --  SECTION  (visual group header inside a tab)
        -- ────────────────────────────────────────────
        function Tab:Section(name)
            local f = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = C.GREEN_DIM,
                BorderSizePixel  = 0,
            }, Page)
            MakeCorner(f, 3)

            New("TextLabel", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = (name or "Section"):upper(),
                TextColor3       = Color3.fromRGB(200, 235, 200),
                TextSize         = 10,
                Font             = Enum.Font.GothamBold,
            }, f)
        end

        return Tab
    end  -- AddTab

    -- ── Window-level helpers ──────────────────────────
    function Window:GetFlag(flag)
        return LuckyCharms.Flags[flag]
    end

    function Window:SetFlag(flag, value)
        local cb = LuckyCharms.Callbacks[flag]
        if cb then cb(value) end
    end

    return Window
end  -- CreateWindow

-- ══════════════════════════════════════════════════
--  PUBLIC API
-- ══════════════════════════════════════════════════

-- Direct flag access
function LuckyCharms:GetFlag(flag)
    return LuckyCharms.Flags[flag]
end

function LuckyCharms:SetFlag(flag, value)
    local cb = LuckyCharms.Callbacks[flag]
    if cb then cb(value) end
end

-- Export notification globally too
function LuckyCharms:Notify(title, msg, duration)
    Notify(title, msg, duration)
end

return LuckyCharms
