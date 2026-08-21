-- LuckyCharms UI Library v2.1
-- Toggle / Slider / Dropdown / Colorpicker / Keybind / Textbox / Button

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

------------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------------
local function GetGui()
 if gethui then return gethui() end
 return CoreGui
end

local function Tween(obj, props, t)
 TweenService:Create(obj,
 TweenInfo.new(t or 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
 props):Play()
end

local function New(class, props, parent)
 local obj = Instance.new(class)
 for k, v in pairs(props) do obj[k] = v end
 if parent then obj.Parent = parent end
 return obj
end

local function Pad(p, top, bot, left, right)
 local ui = Instance.new("UIPadding")
 ui.PaddingTop = UDim.new(0, top or 0)
 ui.PaddingBottom = UDim.new(0, bot or 0)
 ui.PaddingLeft = UDim.new(0, left or 0)
 ui.PaddingRight = UDim.new(0, right or 0)
 ui.Parent = p
end

local function ListLayout(p, dir, gap)
 local l = Instance.new("UIListLayout")
 l.FillDirection = dir or Enum.FillDirection.Vertical
 l.SortOrder = Enum.SortOrder.LayoutOrder
 l.Padding = UDim.new(0, gap or 0)
 l.Parent = p
 return l
end

local function Draggify(handle, target)
 local drag, ds, sp = false, nil, nil
 handle.InputBegan:Connect(function(i)
 if i.UserInputType == Enum.UserInputType.MouseButton1 then
 drag = true; ds = i.Position; sp = target.Position
 end
 end)
 handle.InputEnded:Connect(function(i)
 if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
 end)
 UserInputService.InputChanged:Connect(function(i)
 if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
 local d = i.Position - ds
 target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
 sp.Y.Scale, sp.Y.Offset + d.Y)
 end
 end)
end

------------------------------------------------------------------------
-- PALETTE
------------------------------------------------------------------------
local C = {
 BG = Color3.fromRGB(30, 30, 30),
 SIDEBAR = Color3.fromRGB(46, 46, 46),
 PANEL = Color3.fromRGB(34, 34, 34),
 PANEL2 = Color3.fromRGB(40, 40, 40),
 BORDER = Color3.fromRGB(52, 52, 52),
 GREEN = Color3.fromRGB(15, 125, 45),
 GREEN_TXT = Color3.fromRGB(30, 145, 65),
 GREEN_CHK = Color3.fromRGB(20, 145, 50),
 BTN_BG = Color3.fromRGB(31, 31, 31),
 BTN_HOV = Color3.fromRGB(42, 42, 42),
 TEXT = Color3.fromRGB(215, 215, 215),
 TEXT_DIM = Color3.fromRGB(130, 130, 130),
 TEXT_LOGO = Color3.fromRGB(220, 255, 220),
 WHITE = Color3.fromRGB(255, 255, 255),
 BLACK = Color3.fromRGB( 0, 0, 0),
}

------------------------------------------------------------------------
-- LIBRARY
------------------------------------------------------------------------
local Lib = {}
Lib.__index = Lib
Lib.Flags = {}
Lib.Callbacks = {}

local _notifParent = nil -- set when CreateWindow is called
local _overlayGui = nil -- top-level frame for colorpicker popups

local function DoNotify(title, msg, dur)
 if not _notifParent then return end
 dur = dur or 3

 local h = (msg and msg ~= "") and 46 or 28
 local frm = New("Frame", {
 Size = UDim2.new(1, 0, 0, h),
 BackgroundColor3 = C.PANEL,
 BorderSizePixel = 0,
 ClipsDescendants = true,
 }, _notifParent)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, frm)
 New("Frame", { Size = UDim2.new(0,3,1,0), BackgroundColor3 = C.GREEN, BorderSizePixel = 0 }, frm)

 local inner = New("Frame", {
 Position = UDim2.fromOffset(10, 0),
 Size = UDim2.new(1, -14, 1, 0),
 BackgroundTransparency = 1, BorderSizePixel = 0,
 }, frm)
 ListLayout(inner, nil, 2)
 Pad(inner, 5, 5, 0, 0)

 New("TextLabel", {
 Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1,
 Text = title, TextColor3 = C.GREEN_TXT,
 TextSize = 11, Font = Enum.Font.GothamBold,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, inner)

 if msg and msg ~= "" then
 New("TextLabel", {
 Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1,
 Text = msg, TextColor3 = C.TEXT_DIM,
 TextSize = 10, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, inner)
 end

 task.delay(dur, function()
 if frm and frm.Parent then
 Tween(frm, { BackgroundTransparency = 1 }, 0.25)
 task.wait(0.3); frm:Destroy()
 end
 end)
end

------------------------------------------------------------------------
-- CREATE WINDOW
------------------------------------------------------------------------
function Lib:CreateWindow(cfg)
 cfg = cfg or {}
 local title = cfg.Title or "LuckyCharms"
 local toggleKey = cfg.Key or Enum.KeyCode.Insert
 local W = (cfg.Size and cfg.Size.W) or 620
 local H = (cfg.Size and cfg.Size.H) or 420
 local SW = 80 -- sidebar width

 -- ScreenGui
 local gui = New("ScreenGui", {
 Name = "LuckyCharmsGui", ResetOnSpawn = false,
 IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global,
 })
 gui.Parent = GetGui()

 -- Overlay for colorpicker popups (never clipped)
 _overlayGui = New("Frame", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 BorderSizePixel = 0, ZIndex = 200,
 }, gui)

 -- Notifications
 _notifParent = New("Frame", {
 AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-10,1,-10),
 Size = UDim2.fromOffset(230, 0), BackgroundTransparency = 1,
 AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 300,
 }, gui)
 ListLayout(_notifParent, nil, 5)

 -- Main window frame
 local Main = New("Frame", {
 Name = "Main",
 Size = UDim2.fromOffset(W, H),
 Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
 BackgroundColor3 = C.BG, BorderSizePixel = 0,
 }, gui)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, Main)
 Draggify(Main, Main)

 -- Sidebar
 local Sidebar = New("Frame", {
 Size = UDim2.new(0, SW, 1, 0),
 BackgroundColor3 = C.SIDEBAR, BorderSizePixel = 0,
 }, Main)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, Sidebar)

 -- Logo
 local LogoBlock = New("Frame", {
 Size = UDim2.new(1,0,0,68), BackgroundColor3 = C.SIDEBAR, BorderSizePixel = 0,
 }, Sidebar)
 local logoLbl = New("TextLabel", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "LU\nCKY", TextColor3 = C.TEXT_LOGO,
 TextSize = 16, Font = Enum.Font.GothamBold, LineHeight = 1.1,
 }, LogoBlock)
 New("UIStroke", { Color = C.GREEN, Thickness = 1 }, logoLbl)

 -- Tab button list (below logo)
 local TabList = New("Frame", {
 Position = UDim2.fromOffset(0, 68),
 Size = UDim2.new(1, 0, 1, -68),
 BackgroundTransparency = 1, BorderSizePixel = 0,
 ClipsDescendants = true,
 }, Sidebar)
 ListLayout(TabList, nil, 0)

 -- Content area
 local Content = New("Frame", {
 Position = UDim2.fromOffset(SW, 0),
 Size = UDim2.new(1, -SW, 1, 0),
 BackgroundColor3 = C.BG, BorderSizePixel = 0,
 ClipsDescendants = true,
 }, Main)

 local PageHolder = New("Frame", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 BorderSizePixel = 0, ClipsDescendants = true,
 }, Content)

 -- Toggle key
 local menuVisible = true
 UserInputService.InputBegan:Connect(function(inp, gpe)
 if gpe then return end
 if inp.KeyCode == toggleKey then
 menuVisible = not menuVisible
 Main.Visible = menuVisible
 end
 end)

 --------------------------------------------------------------------------
 -- WINDOW OBJECT
 --------------------------------------------------------------------------
 local Win = {}
 Win._tabs = {}
 Win._activeTab = nil

 function Win:Notify(t, m, d) DoNotify(t, m, d) end

 --------------------------------------------------------------------------
 -- AddTab
 --------------------------------------------------------------------------
 function Win:AddTab(tabName)
 local first = #self._tabs == 0

 -- Sidebar button
 local BtnFrm = New("Frame", {
 Size = UDim2.new(1,0,0,32),
 BackgroundColor3 = first and C.BG or C.SIDEBAR,
 BorderSizePixel = 0,
 }, TabList)
 local BtnLbl = New("TextLabel", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = tabName, TextColor3 = first and C.TEXT or C.TEXT_DIM,
 TextSize = 14, Font = Enum.Font.Gotham,
 }, BtnFrm)
 local BtnBtn = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0,
 }, BtnFrm)

 -- Scrolling page
 local Page = New("ScrollingFrame", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 BorderSizePixel = 0, ScrollBarThickness = 4,
 ScrollBarImageColor3 = C.BORDER,
 CanvasSize = UDim2.new(0,0,0,0),
 AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
 Visible = first,
 }, PageHolder)
 Pad(Page, 8, 8, 8, 8)
 ListLayout(Page, nil, 4)

 -- Tab object
 local Tab = { _page = Page, _btn = BtnFrm, _lbl = BtnLbl }
 table.insert(self._tabs, Tab)
 if first then self._activeTab = Tab end

 -- Switch logic
 BtnBtn.MouseButton1Click:Connect(function()
 if self._activeTab == Tab then return end
 self._activeTab._page.Visible = false
 Tween(self._activeTab._btn, { BackgroundColor3 = C.SIDEBAR }, 0.1)
 Tween(self._activeTab._lbl, { TextColor3 = C.TEXT_DIM }, 0.1)
 Tab._page.Visible = true
 Tween(BtnFrm, { BackgroundColor3 = C.BG }, 0.1)
 Tween(BtnLbl, { TextColor3 = C.TEXT }, 0.1)
 self._activeTab = Tab
 end)
 BtnBtn.MouseEnter:Connect(function()
 if self._activeTab ~= Tab then
 Tween(BtnFrm, { BackgroundColor3 = Color3.fromRGB(38,38,38) }, 0.08)
 end
 end)
 BtnBtn.MouseLeave:Connect(function()
 if self._activeTab ~= Tab then
 Tween(BtnFrm, { BackgroundColor3 = C.SIDEBAR }, 0.08)
 end
 end)

 ----------------------------------------------------------------------
 -- PRIVATE: make a plain row frame parented to Page
 ----------------------------------------------------------------------
 local function MakeRow(h)
 local f = New("Frame", {
 Size = UDim2.new(1, 0, 0, h or 24),
 BackgroundColor3 = C.PANEL,
 BorderSizePixel = 0,
 }, Page)
 Pad(f, 0, 0, 12, 8)
 return f
 end

 ----------------------------------------------------------------------
 -- SECTION (green header bar)
 ----------------------------------------------------------------------
 function Tab:Section(name)
 local sf = New("Frame", {
 Size = UDim2.new(1, 0, 0, 20),
 BackgroundColor3 = C.GREEN,
 BorderSizePixel = 0,
 }, Page)
 New("TextLabel", {
 Size = UDim2.new(1, 0, 1, 0),
 BackgroundTransparency = 1,
 Text = name or "Section",
 TextColor3 = Color3.fromRGB(210, 235, 210),
 TextSize = 11,
 Font = Enum.Font.GothamSemibold,
 }, sf)
 end

 ----------------------------------------------------------------------
 -- SEPARATOR
 ----------------------------------------------------------------------
 function Tab:Separator()
 New("Frame", {
 Size = UDim2.new(1, 0, 0, 1),
 BackgroundColor3 = C.BORDER,
 BorderSizePixel = 0,
 }, Page)
 end

 ----------------------------------------------------------------------
 -- LABEL
 ----------------------------------------------------------------------
 function Tab:Label(cfg)
 cfg = cfg or {}
 local f = MakeRow(20)
 local lbl = New("TextLabel", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = cfg.Name or "", TextColor3 = C.TEXT_DIM,
 TextSize = 11, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, f)
 local o = {}
 function o:Set(t) lbl.Text = t end
 function o:Get() return lbl.Text end
 return o
 end

 ----------------------------------------------------------------------
 -- TOGGLE
 ----------------------------------------------------------------------
 function Tab:Toggle(cfg)
 cfg = cfg or {}
 local flag = cfg.Flag or cfg.Name or "Toggle"
 local cb = cfg.Callback or function() end
 local val = cfg.Default or false
 Lib.Flags[flag] = val

 local f = MakeRow(24)

 local box = New("Frame", {
 Position = UDim2.fromOffset(0, 7),
 Size = UDim2.fromOffset(11, 11),
 BackgroundColor3 = val and C.GREEN_CHK or Color3.fromRGB(48,48,48),
 BorderSizePixel = 0,
 }, f)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, box)

 local tick = New("TextLabel", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "✓", TextColor3 = C.WHITE,
 TextSize = 8, Font = Enum.Font.GothamBold,
 Visible = val,
 }, box)

 New("TextLabel", {
 Position = UDim2.fromOffset(16, 0),
 Size = UDim2.new(1,-16,1,0), BackgroundTransparency = 1,
 Text = cfg.Name or "Toggle", TextColor3 = C.TEXT,
 TextSize = 11, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, f)

 local btn = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0,
 }, f)

 local function Set(newVal)
 val = newVal
 Lib.Flags[flag] = val
 Tween(box, { BackgroundColor3 = val and C.GREEN_CHK or Color3.fromRGB(48,48,48) }, 0.1)
 tick.Visible = val
 cb(val)
 end

 btn.MouseButton1Click:Connect(function() Set(not val) end)
 btn.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL2 }, 0.08) end)
 btn.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL }, 0.08) end)
 Lib.Callbacks[flag] = Set

 local o = {}
 function o:Set(v) Set(v) end
 function o:Get() return val end
 return o
 end

 ----------------------------------------------------------------------
 -- SLIDER
 ----------------------------------------------------------------------
 function Tab:Slider(cfg)
 cfg = cfg or {}
 local flag = cfg.Flag or cfg.Name or "Slider"
 local min = cfg.Min or 0
 local max = cfg.Max or 100
 local suffix = cfg.Suffix or ""
 local step = cfg.Decimal or 0 -- 0 = integer steps
 local cb = cfg.Callback or function() end
 local val = math.clamp(cfg.Default or min, min, max)
 Lib.Flags[flag] = val

 -- decimals needed for format string
 local dp = (step > 0) and math.max(0, math.ceil(-math.log10(step))) or 0
 local fmt = dp > 0 and ("%." .. dp .. "f") or "%d"

 local f = New("Frame", {
 Size = UDim2.new(1,0,0,44), BackgroundColor3 = C.PANEL, BorderSizePixel = 0,
 }, Page)
 Pad(f, 6, 6, 12, 8)

 New("TextLabel", {
 Size = UDim2.new(0.6,0,0,14), BackgroundTransparency = 1,
 Text = cfg.Name or "Slider", TextColor3 = C.TEXT,
 TextSize = 11, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, f)

 local valLbl = New("TextLabel", {
 AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0),
 Size = UDim2.new(0.4,0,0,14), BackgroundTransparency = 1,
 Text = string.format(fmt, val) .. suffix,
 TextColor3 = C.GREEN_TXT, TextSize = 11,
 Font = Enum.Font.GothamSemibold,
 TextXAlignment = Enum.TextXAlignment.Right,
 }, f)

 local track = New("Frame", {
 Position = UDim2.fromOffset(0, 18),
 Size = UDim2.new(1,0,0,8),
 BackgroundColor3 = Color3.fromRGB(48,48,48), BorderSizePixel = 0,
 }, f)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, track)

 local ratio = (max ~= min) and ((val - min) / (max - min)) or 0

 local fill = New("Frame", {
 Size = UDim2.new(ratio,0,1,0),
 BackgroundColor3 = C.GREEN, BorderSizePixel = 0,
 }, track)

 local thumb = New("Frame", {
 AnchorPoint = Vector2.new(0.5,0.5),
 Position = UDim2.new(ratio,0,0.5,0),
 Size = UDim2.fromOffset(10,10),
 BackgroundColor3 = C.WHITE, BorderSizePixel = 0, ZIndex = 5,
 }, track)
 New("UICorner", { CornerRadius = UDim.new(1,0) }, thumb)
 New("UIStroke", { Color = C.GREEN, Thickness = 1 }, thumb)

 local dragBtn = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0, ZIndex = 6,
 }, track)

 local dragging = false

 local function UpdateFromX(absX)
 local r = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
 local raw = min + r * (max - min)
 if step > 0 then
 raw = math.floor(raw / step + 0.5) * step
 else
 raw = math.floor(raw + 0.5)
 end
 val = math.clamp(raw, min, max)
 Lib.Flags[flag] = val
 local nr = (max ~= min) and ((val - min) / (max - min)) or 0
 fill.Size = UDim2.new(nr, 0, 1, 0)
 thumb.Position = UDim2.new(nr, 0, 0.5, 0)
 valLbl.Text = string.format(fmt, val) .. suffix
 cb(val)
 end

 dragBtn.InputBegan:Connect(function(i)
 if i.UserInputType == Enum.UserInputType.MouseButton1 then
 dragging = true; UpdateFromX(i.Position.X)
 end
 end)
 UserInputService.InputEnded:Connect(function(i)
 if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
 end)
 UserInputService.InputChanged:Connect(function(i)
 if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
 UpdateFromX(i.Position.X)
 end
 end)

 local function Set(newVal)
 val = math.clamp(newVal, min, max)
 Lib.Flags[flag] = val
 local nr = (max ~= min) and ((val - min) / (max - min)) or 0
 fill.Size = UDim2.new(nr, 0, 1, 0)
 thumb.Position = UDim2.new(nr, 0, 0.5, 0)
 valLbl.Text = string.format(fmt, val) .. suffix
 cb(val)
 end
 Lib.Callbacks[flag] = Set

 local o = {}
 function o:Set(v) Set(v) end
 function o:Get() return val end
 return o
 end

 ----------------------------------------------------------------------
 -- DROPDOWN
 ----------------------------------------------------------------------
 function Tab:Dropdown(cfg)
 cfg = cfg or {}
 local flag = cfg.Flag or cfg.Name or "Dropdown"
 local opts = cfg.Options or {}
 local multi = cfg.Multi or false
 local cb = cfg.Callback or function() end
 local sel = multi and {} or (cfg.Default or opts[1] or "None")
 Lib.Flags[flag] = sel

 local isOpen = false

 -- Wrapper (grows when open)
 local wrap = New("Frame", {
 Size = UDim2.new(1,0,0,22),
 BackgroundTransparency = 1, BorderSizePixel = 0,
 ClipsDescendants = false,
 }, Page)

 local header = New("Frame", {
 Size = UDim2.new(1,0,0,22),
 BackgroundColor3 = C.BTN_BG, BorderSizePixel = 0,
 }, wrap)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, header)
 Pad(header, 0, 0, 10, 6)

 New("TextLabel", {
 Size = UDim2.new(0.5,0,1,0), BackgroundTransparency = 1,
 Text = cfg.Name or "Dropdown", TextColor3 = C.TEXT,
 TextSize = 11, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, header)

 local arrow = New("TextLabel", {
 AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0),
 Size = UDim2.fromOffset(12,12), BackgroundTransparency = 1,
 Text = "▾", TextColor3 = C.TEXT_DIM,
 TextSize = 12, Font = Enum.Font.GothamBold,
 }, header)

 local valDisp = New("TextLabel", {
 AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-18,0.5,0),
 Size = UDim2.fromOffset(110,14), BackgroundTransparency = 1,
 Text = multi and "None" or tostring(sel),
 TextColor3 = C.TEXT_DIM, TextSize = 10, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Right,
 TextTruncate = Enum.TextTruncate.AtEnd,
 }, header)

 local ITEM_H = 20
 local listH = #opts * ITEM_H + 4

 local optFrm = New("Frame", {
 Position = UDim2.fromOffset(0, 23),
 Size = UDim2.new(1,0,0,listH),
 BackgroundColor3 = C.BTN_BG, BorderSizePixel = 0,
 Visible = false, ZIndex = 20, ClipsDescendants = true,
 }, wrap)
 New("UIStroke", { Color = C.GREEN, Thickness = 1 }, optFrm)
 ListLayout(optFrm, nil, 0)
 Pad(optFrm, 2, 2, 0, 0)

 local btnMap = {}

 local function RefreshDisplay()
 if multi then
 local parts = {}
 for k, v in pairs(sel) do if v then parts[#parts+1] = k end end
 valDisp.Text = #parts > 0 and table.concat(parts, ", ") or "None"
 else
 valDisp.Text = tostring(sel)
 end
 end

 local function Close()
 isOpen = false
 optFrm.Visible = false
 wrap.Size = UDim2.new(1,0,0,22)
 arrow.Text = "▾"
 end

 for _, opt in ipairs(opts) do
 local active = multi and sel[opt] or (sel == opt)
 local ob = New("TextButton", {
 Size = UDim2.new(1,0,0,ITEM_H),
 BackgroundColor3 = C.BTN_BG, BorderSizePixel = 0,
 Text = "", AutoButtonColor = false, ZIndex = 21,
 }, optFrm)
 local ol = New("TextLabel", {
 Position = UDim2.fromOffset(8,0), Size = UDim2.new(1,-16,1,0),
 BackgroundTransparency = 1,
 Text = tostring(opt),
 TextColor3 = active and C.GREEN_TXT or C.TEXT_DIM,
 TextSize = 10, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22,
 }, ob)
 btnMap[opt] = { btn = ob, lbl = ol }

 ob.MouseEnter:Connect(function() Tween(ob, { BackgroundColor3 = C.BTN_HOV }, 0.08) end)
 ob.MouseLeave:Connect(function() Tween(ob, { BackgroundColor3 = C.BTN_BG }, 0.08) end)
 ob.MouseButton1Click:Connect(function()
 if multi then
 sel[opt] = not sel[opt]
 ol.TextColor3 = sel[opt] and C.GREEN_TXT or C.TEXT_DIM
 Lib.Flags[flag] = sel
 RefreshDisplay()
 cb(sel)
 else
 if btnMap[sel] then btnMap[sel].lbl.TextColor3 = C.TEXT_DIM end
 sel = opt
 ol.TextColor3 = C.GREEN_TXT
 Lib.Flags[flag] = sel
 RefreshDisplay()
 cb(sel)
 Close()
 end
 end)
 end

 local hBtn = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0,
 }, header)
 hBtn.MouseButton1Click:Connect(function()
 isOpen = not isOpen
 optFrm.Visible = isOpen
 wrap.Size = UDim2.new(1, 0, 0, isOpen and (23 + listH) or 22)
 arrow.Text = isOpen and "▴" or "▾"
 end)

 RefreshDisplay()

 Lib.Callbacks[flag] = function(v)
 if multi then
 sel = v
 for opt, b in pairs(btnMap) do
 b.lbl.TextColor3 = sel[opt] and C.GREEN_TXT or C.TEXT_DIM
 end
 else
 if btnMap[sel] then btnMap[sel].lbl.TextColor3 = C.TEXT_DIM end
 sel = v
 if btnMap[v] then btnMap[v].lbl.TextColor3 = C.GREEN_TXT end
 end
 Lib.Flags[flag] = sel; RefreshDisplay(); cb(sel)
 end

 local o = {}
 function o:Set(v) Lib.Callbacks[flag](v) end
 function o:Get() return sel end
 return o
 end

 ----------------------------------------------------------------------
 -- COLORPICKER
 -- Popup lives in _overlayGui so it is never clipped by ScrollingFrame
 ----------------------------------------------------------------------
 function Tab:Colorpicker(cfg)
 cfg = cfg or {}
 local flag = cfg.Flag or cfg.Name or "Color"
 local default = cfg.Default or Color3.fromRGB(255,255,255)
 local hasAlpha = (cfg.Alpha ~= nil)
 local cb = cfg.Callback or function() end

 local h, s, v = default:ToHSV()
 local alpha = cfg.Alpha or 0
 Lib.Flags[flag] = { Color = default, Alpha = alpha }

 local isOpen = false

 -- Row with swatch
 local row = MakeRow(24)

 New("TextLabel", {
 Size = UDim2.new(1,-38,1,0), BackgroundTransparency = 1,
 Text = cfg.Name or "Color", TextColor3 = C.TEXT,
 TextSize = 11, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)

 local swWrap = New("Frame", {
 AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0),
 Size = UDim2.fromOffset(30,16), BackgroundColor3 = C.BORDER, BorderSizePixel = 0,
 }, row)
 local swatch = New("Frame", {
 Position = UDim2.fromOffset(1,1), Size = UDim2.new(1,-2,1,-2),
 BackgroundColor3 = default, BorderSizePixel = 0,
 }, swWrap)

 -- Picker dimensions
 local SV_W = 148
 local SV_H = 110
 local HUE_W = 12
 local PW = SV_W + HUE_W + 18
 local PH = SV_H + (hasAlpha and 68 or 52)

 local picker = New("Frame", {
 Size = UDim2.fromOffset(PW, PH),
 BackgroundColor3 = C.PANEL, BorderSizePixel = 0,
 Visible = false, ZIndex = 210,
 }, _overlayGui)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, picker)
 Pad(picker, 7, 7, 7, 7)

 -- SV square
 local svBox = New("Frame", {
 Size = UDim2.fromOffset(SV_W, SV_H),
 BackgroundColor3 = Color3.fromHSV(h,1,1),
 BorderSizePixel = 0, ZIndex = 211,
 }, picker)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, svBox)

 -- White saturation overlay (left→right transparency)
 local satO = New("Frame", {
 Size = UDim2.new(1,0,1,0), BackgroundColor3 = C.WHITE,
 BorderSizePixel = 0, ZIndex = 212,
 }, svBox)
 New("UIGradient", {
 Transparency = NumberSequence.new{
 NumberSequenceKeypoint.new(0, 0),
 NumberSequenceKeypoint.new(1, 1),
 },
 }, satO)

 -- Black value overlay (top→bottom)
 local valO = New("Frame", {
 Size = UDim2.new(1,0,1,0), BackgroundColor3 = C.BLACK,
 BorderSizePixel = 0, ZIndex = 213,
 }, svBox)
 New("UIGradient", {
 Rotation = 90,
 Transparency = NumberSequence.new{
 NumberSequenceKeypoint.new(0, 1),
 NumberSequenceKeypoint.new(1, 0),
 },
 }, valO)

 -- SV cursor
 local svCur = New("Frame", {
 AnchorPoint = Vector2.new(0.5,0.5),
 Position = UDim2.new(s, 0, 1-v, 0),
 Size = UDim2.fromOffset(8,8), ZIndex = 215,
 BackgroundColor3 = C.WHITE, BorderSizePixel = 0,
 }, svBox)
 New("UICorner", { CornerRadius = UDim.new(1,0) }, svCur)
 New("UIStroke", { Color = C.BLACK, Thickness = 1 }, svCur)

 -- Hue bar (vertical, right of SV)
 local hueBar = New("Frame", {
 AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0),
 Size = UDim2.fromOffset(HUE_W, SV_H),
 BorderSizePixel = 0, ZIndex = 211,
 }, picker)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, hueBar)
 New("UIGradient", {
 Rotation = 90,
 Color = ColorSequence.new{
 ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1,1)),
 ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1,1)),
 ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1,1)),
 ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1,1)),
 ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1,1)),
 ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1,1)),
 ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1,1)),
 },
 }, hueBar)
 local hueCur = New("Frame", {
 AnchorPoint = Vector2.new(0.5,0.5),
 Position = UDim2.new(0.5, 0, h, 0),
 Size = UDim2.new(1,4,0,4),
 BackgroundColor3 = C.WHITE, BorderSizePixel = 0, ZIndex = 215,
 }, hueBar)
 New("UIStroke", { Color = C.BLACK, Thickness = 1 }, hueCur)

 -- Alpha bar (optional, below SV)
 local alphaBar, alphaCur, alphaGrad
 if hasAlpha then
 alphaBar = New("Frame", {
 Position = UDim2.fromOffset(0, SV_H + 8),
 Size = UDim2.fromOffset(SV_W, 10),
 BackgroundColor3 = C.WHITE, BorderSizePixel = 0, ZIndex = 211,
 }, picker)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, alphaBar)
 alphaGrad = New("UIGradient", {
 Color = ColorSequence.new{
 ColorSequenceKeypoint.new(0, default),
 ColorSequenceKeypoint.new(1, default),
 },
 Transparency = NumberSequence.new{
 NumberSequenceKeypoint.new(0, 0),
 NumberSequenceKeypoint.new(1, 1),
 },
 }, alphaBar)
 alphaCur = New("Frame", {
 AnchorPoint = Vector2.new(0.5,0.5),
 Position = UDim2.new(1-alpha, 0, 0.5, 0),
 Size = UDim2.fromOffset(5,14),
 BackgroundColor3 = C.WHITE, BorderSizePixel = 0, ZIndex = 215,
 }, alphaBar)
 New("UIStroke", { Color = C.BLACK, Thickness = 1 }, alphaCur)
 end

 -- Hex input
 local hexY = SV_H + (hasAlpha and 24 or 8)
 local hexBox = New("TextBox", {
 Position = UDim2.fromOffset(0, hexY),
 Size = UDim2.fromOffset(SV_W, 18),
 BackgroundColor3 = Color3.fromRGB(42,42,42), BorderSizePixel = 0,
 Text = "#" .. default:ToHex():upper(),
 TextColor3 = C.TEXT, PlaceholderColor3 = C.TEXT_DIM,
 PlaceholderText = "#RRGGBB",
 TextSize = 10, Font = Enum.Font.Gotham,
 ClearTextOnFocus = false, ZIndex = 211,
 }, picker)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, hexBox)
 Pad(hexBox, 0,0,5,0)

 -- RGB readout
 local rgbLbl = New("TextLabel", {
 Position = UDim2.fromOffset(0, hexY + 22),
 Size = UDim2.fromOffset(SV_W, 13),
 BackgroundTransparency = 1,
 Text = "", TextColor3 = C.TEXT_DIM,
 TextSize = 9, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 211,
 }, picker)

 -- Refresh all picker visuals
 local function Refresh()
 local col = Color3.fromHSV(h, s, v)
 swatch.BackgroundColor3 = col
 svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
 svCur.Position = UDim2.new(s, 0, 1-v, 0)
 hueCur.Position = UDim2.new(0.5, 0, h, 0)
 hexBox.Text = "#" .. col:ToHex():upper()
 rgbLbl.Text = math.floor(col.R*255) .. " "
 .. math.floor(col.G*255) .. " "
 .. math.floor(col.B*255)
 if hasAlpha then
 alphaCur.Position = UDim2.new(1-alpha, 0, 0.5, 0)
 alphaGrad.Color = ColorSequence.new{
 ColorSequenceKeypoint.new(0, col),
 ColorSequenceKeypoint.new(1, col),
 }
 end
 Lib.Flags[flag] = { Color = col, Alpha = alpha }
 cb(col, alpha)
 end

 -- Drag state
 local dSV, dHue, dAlpha = false, false, false

 local function MkDrag(target, onStart, zi)
 local b = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0, ZIndex = zi or 216,
 }, target)
 b.InputBegan:Connect(function(i)
 if i.UserInputType == Enum.UserInputType.MouseButton1 then
 onStart()
 end
 end)
 end

 MkDrag(svBox, function() dSV = true end)
 MkDrag(hueBar, function() dHue = true end)
 if hasAlpha then MkDrag(alphaBar, function() dAlpha = true end) end

 UserInputService.InputEnded:Connect(function(i)
 if i.UserInputType == Enum.UserInputType.MouseButton1 then
 dSV = false; dHue = false; dAlpha = false
 end
 end)
 UserInputService.InputChanged:Connect(function(i)
 if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
 if not isOpen then return end
 local mx, my = i.Position.X, i.Position.Y
 if dSV then
 s = math.clamp((mx - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
 v = 1 - math.clamp((my - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
 Refresh()
 elseif dHue then
 h = math.clamp((my - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
 Refresh()
 elseif dAlpha then
 alpha = 1 - math.clamp((mx - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
 Refresh()
 end
 end)

 hexBox.FocusLost:Connect(function()
 local t = hexBox.Text:gsub("#","")
 if #t == 6 then
 local ok, col = pcall(Color3.fromHex, t)
 if ok then h, s, v = col:ToHSV(); Refresh() end
 end
 end)

 -- Open/close picker, positioned near the swatch
 local function OpenAt()
 local gs = gui.AbsoluteSize
 local sa = swWrap.AbsolutePosition
 local ss = swWrap.AbsoluteSize
 local px = math.clamp(sa.X, 2, gs.X - PW - 4)
 local py = math.clamp(sa.Y + ss.Y + 4, 2, gs.Y - PH - 4)
 picker.Position = UDim2.fromOffset(px, py)
 picker.Visible = true
 isOpen = true
 end

 local swBtn = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0,
 }, swWrap)
 swBtn.MouseButton1Click:Connect(function()
 if isOpen then picker.Visible = false; isOpen = false
 else OpenAt() end
 end)

 -- Close when clicking outside picker and swatch
 UserInputService.InputBegan:Connect(function(inp, gpe)
 if gpe or not isOpen then return end
 if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
 local mp = UserInputService:GetMouseLocation()
 local pa = picker.AbsolutePosition; local ps = picker.AbsoluteSize
 local sa2 = swWrap.AbsolutePosition; local ss2 = swWrap.AbsoluteSize
 local inP = mp.X>=pa.X and mp.X<=pa.X+ps.X and mp.Y>=pa.Y and mp.Y<=pa.Y+ps.Y
 local inS = mp.X>=sa2.X and mp.X<=sa2.X+ss2.X and mp.Y>=sa2.Y and mp.Y<=sa2.Y+ss2.Y
 if not inP and not inS then picker.Visible = false; isOpen = false end
 end)

 Refresh()

 Lib.Callbacks[flag] = function(col, a)
 h, s, v = col:ToHSV()
 if a ~= nil then alpha = a end
 Refresh()
 end

 local o = {}
 function o:Set(col, a) Lib.Callbacks[flag](col, a) end
 function o:Get() return Lib.Flags[flag] end
 return o
 end

 ----------------------------------------------------------------------
 -- KEYBIND
 ----------------------------------------------------------------------
 function Tab:Keybind(cfg)
 cfg = cfg or {}
 local flag = cfg.Flag or cfg.Name or "Keybind"
 local cb = cfg.Callback or function() end
 local curKey = cfg.Default or nil
 local listen = false
 Lib.Flags[flag] = curKey

 local f = MakeRow(24)

 New("TextLabel", {
 Size = UDim2.new(1,-60,1,0), BackgroundTransparency = 1,
 Text = cfg.Name or "Keybind", TextColor3 = C.TEXT,
 TextSize = 11, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, f)

 local badge = New("TextLabel", {
 AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-4,0.5,0),
 Size = UDim2.fromOffset(50,16),
 BackgroundColor3 = Color3.fromRGB(42,42,42), BorderSizePixel = 0,
 Text = curKey and tostring(curKey):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","") or "NONE",
 TextColor3 = curKey and C.GREEN_TXT or C.TEXT_DIM,
 TextSize = 9, Font = Enum.Font.GothamSemibold,
 }, f)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, badge)

 local clickBtn = New("TextButton", {
 Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
 Text = "", BorderSizePixel = 0,
 }, f)

 local function RefBadge()
 if listen then
 badge.Text = "..."
 badge.TextColor3 = C.TEXT
 Tween(badge, { BackgroundColor3 = Color3.fromRGB(25,70,40) }, 0.1)
 else
 badge.Text = curKey
 and tostring(curKey):gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","")
 or "NONE"
 badge.TextColor3 = curKey and C.GREEN_TXT or C.TEXT_DIM
 Tween(badge, { BackgroundColor3 = Color3.fromRGB(42,42,42) }, 0.1)
 end
 end

 -- Left-click = enter listen mode
 clickBtn.MouseButton1Click:Connect(function()
 if listen then return end
 listen = true; RefBadge()
 end)
 -- Right-click = clear
 clickBtn.MouseButton2Click:Connect(function()
 curKey = nil; listen = false
 Lib.Flags[flag] = nil; RefBadge(); cb(nil)
 end)
 clickBtn.MouseEnter:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL2 }, 0.08) end)
 clickBtn.MouseLeave:Connect(function() Tween(f, { BackgroundColor3 = C.PANEL }, 0.08) end)

 UserInputService.InputBegan:Connect(function(inp, gpe)
 if listen then
 -- capture key/mouse
 if inp.UserInputType == Enum.UserInputType.Keyboard then
 if inp.KeyCode == Enum.KeyCode.Escape then
 listen = false; RefBadge(); return
 end
 curKey = inp.KeyCode
 elseif inp.UserInputType == Enum.UserInputType.MouseButton1
 or inp.UserInputType == Enum.UserInputType.MouseButton2
 or inp.UserInputType == Enum.UserInputType.MouseButton3 then
 curKey = inp.UserInputType
 else return end
 Lib.Flags[flag] = curKey
 listen = false; RefBadge(); cb(curKey)
 else
 -- fire callback when bound key pressed in-game
 if gpe or not curKey then return end
 local pressed = inp.UserInputType == Enum.UserInputType.Keyboard
 and inp.KeyCode or inp.UserInputType
 if pressed == curKey then cb(curKey) end
 end
 end)

 Lib.Callbacks[flag] = function(k)
 curKey = k; Lib.Flags[flag] = k; listen = false; RefBadge(); cb(k)
 end

 local o = {}
 function o:Set(k) Lib.Callbacks[flag](k) end
 function o:Get() return curKey end
 return o
 end

 ----------------------------------------------------------------------
 -- TEXTBOX
 ----------------------------------------------------------------------
 function Tab:Textbox(cfg)
 cfg = cfg or {}
 local flag = cfg.Flag or cfg.Name or "Textbox"
 local cb = cfg.Callback or function() end
 local numeric = cfg.Numeric or false
 local def = cfg.Default or ""
 Lib.Flags[flag] = def

 local f = New("Frame", {
 Size = UDim2.new(1,0,0,44),
 BackgroundColor3 = C.PANEL, BorderSizePixel = 0,
 }, Page)
 Pad(f, 4, 4, 12, 8)

 New("TextLabel", {
 Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1,
 Text = cfg.Name or "Textbox", TextColor3 = C.TEXT_DIM,
 TextSize = 10, Font = Enum.Font.Gotham,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, f)

 local box = New("TextBox", {
 Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1,0,0,18),
 BackgroundColor3 = Color3.fromRGB(42,42,42), BorderSizePixel = 0,
 Text = def, PlaceholderText = cfg.Placeholder or "...",
 TextColor3 = C.TEXT, PlaceholderColor3 = C.TEXT_DIM,
 TextSize = 10, Font = Enum.Font.Gotham,
 ClearTextOnFocus = false,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, f)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, box)
 Pad(box, 0,0,6,0)

 box:GetPropertyChangedSignal("Text"):Connect(function()
 local t = box.Text
 if numeric then
 local clean = t:gsub("[^%d%.%-]","")
 if clean ~= t then box.Text = clean; return end
 end
 Lib.Flags[flag] = t; cb(t)
 end)

 Lib.Callbacks[flag] = function(val)
 box.Text = val; Lib.Flags[flag] = val; cb(val)
 end

 local o = {}
 function o:Set(v) Lib.Callbacks[flag](v) end
 function o:Get() return box.Text end
 return o
 end

 ----------------------------------------------------------------------
 -- BUTTON
 ----------------------------------------------------------------------
 function Tab:Button(cfg)
 cfg = cfg or {}
 local cb = cfg.Callback or function() end

 local btn = New("TextButton", {
 Size = UDim2.new(1,0,0,22),
 BackgroundColor3 = C.BTN_BG, BorderSizePixel = 0,
 Text = cfg.Name or "Button", TextColor3 = C.GREEN_TXT,
 TextSize = 10, Font = Enum.Font.Gotham,
 AutoButtonColor = false,
 }, Page)
 New("UIStroke", { Color = C.BORDER, Thickness = 1 }, btn)

 btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = C.BTN_HOV }, 0.08) end)
 btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = C.BTN_BG }, 0.08) end)
 btn.MouseButton1Click:Connect(function()
 Tween(btn, { BackgroundColor3 = Color3.fromRGB(44,44,44) }, 0.04)
 task.delay(0.1, function() Tween(btn, { BackgroundColor3 = C.BTN_BG }, 0.08) end)
 cb()
 end)

 local o = {}
 function o:SetText(t) btn.Text = t end
 function o:Get() return btn.Text end
 return o
 end

 return Tab
 end -- AddTab

 function Win:GetFlag(f) return Lib.Flags[f] end
 function Win:SetFlag(f, v)
 local cb = Lib.Callbacks[f]
 if cb then cb(v) end
 end

 return Win
end -- CreateWindow

------------------------------------------------------------------------
-- GLOBAL API
------------------------------------------------------------------------
function Lib:GetFlag(f) return Lib.Flags[f] end
function Lib:SetFlag(f, v)
 local cb = Lib.Callbacks[f]
 if cb then cb(v) end
end
function Lib:Notify(t, m, d) DoNotify(t, m, d) end

return Lib
