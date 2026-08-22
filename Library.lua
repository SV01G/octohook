-- ============================================================
--  Nebula  |  BloxStrike  |  Custom UI  (FIXED BUILD)
--  ESP · Healthbar · BHop · EdgeBug · PixelSurf
--  Silent Aim · FOV Circle · Skin/Knife/Glove · Grenade Pred
--  RightShift = hide/show
--
--  FIXES APPLIED:
--  1. All `continue` replaced with goto/repeat pattern (Lua 5.1 compat)
--  2. `syn` / `gethui` nil-guarded
--  3. SR() require guard made executor-safe
--  4. Drawing API guarded (some executors name it differently)
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Character, HumanoidRootPart, Humanoid
local function refreshChar()
    Character        = LocalPlayer.Character
    HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    Humanoid         = Character and Character:FindFirstChildOfClass("Humanoid")
end
refreshChar()

local function SR(m)
    if not m then return nil end
    local ok, r = pcall(function() return require(m) end)
    return (ok and type(r) == "table") and r or nil
end

local CharController, Remotes
pcall(function() CharController = SR(ReplicatedStorage.Controllers.CharacterController) end)
pcall(function() Remotes = SR(ReplicatedStorage.Database.Security.Remotes) end)

-- ══════════════════════════════════════════════════════════════
--  FLAGS
-- ══════════════════════════════════════════════════════════════
local F = {
    esp=false, espColor=Color3.fromRGB(255,80,80), espFill=0.55,
    espBox=false, espBoxCol=Color3.fromRGB(255,255,255),
    espHealth=true, espName=true, espDist=true,
    bhop=false,
    edgebug=false, ebThresh=-20,
    surf=false, surfKey=Enum.KeyCode.C, surfHeld=false,
    sa=false, saFOV=180, saPart="Head",
    showFOV=false, fovColor=Color3.fromRGB(255,255,255),
    grenade=false, grenadeCol=Color3.fromRGB(0,200,255),
    skinOn=false, knifeOn=false, knifeModel="Karambit",
    gloveOn=false, gloveModel="Driver Gloves",
}

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function getTeam() return LocalPlayer:GetAttribute("Team") end
local function isEnemy(p)
    local my = getTeam(); if not my then return false end
    local t = p:GetAttribute("Team"); return t ~= nil and t ~= my
end
local function isDead(char)
    if not char then return true end
    local hp = char:GetAttribute("Health"); if hp and hp <= 0 then return true end
    local h = char:FindFirstChildOfClass("Humanoid"); return h and h.Health <= 0
end
local function getHP(char)
    if not char then return 0, 100 end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return 0, 100 end
    return math.max(0, h.Health), math.max(1, h.MaxHealth)
end

-- ══════════════════════════════════════════════════════════════
--  HIGHLIGHT ESP
-- ══════════════════════════════════════════════════════════════
local hlMap = {}
local hlCon = {}

local function applyHL(h, p)
    h.FillColor         = F.espColor
    h.OutlineColor      = F.espColor
    h.FillTransparency  = F.espFill
    h.OutlineTransparency = 0
    h.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled           = F.esp and isEnemy(p) and not isDead(p.Character)
end
local function addHL(p)
    if p == LocalPlayer or hlMap[p] then return end
    local char = p.Character; if not char then return end
    local h = Instance.new("Highlight")
    h.Adornee = char; applyHL(h, p); h.Parent = char; hlMap[p] = h
    local cons = {}
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        table.insert(cons, hum.Died:Connect(function()
            if hlMap[p] then hlMap[p].Enabled = false end
        end))
    end
    pcall(function()
        table.insert(cons, char:GetAttributeChangedSignal("Health"):Connect(function()
            if (char:GetAttribute("Health") or 100) <= 0 and hlMap[p] then
                hlMap[p].Enabled = false
            end
        end))
    end)
    hlCon[p] = cons
end
local function removeHL(p)
    local h = hlMap[p]; if h then pcall(function() h:Destroy() end) end; hlMap[p] = nil
    for _, c in ipairs(hlCon[p] or {}) do pcall(function() c:Disconnect() end) end; hlCon[p] = nil
end
local function refreshHL()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local h = hlMap[p]
            if h and h.Parent then
                applyHL(h, p)
            else
                hlMap[p] = nil
                if F.esp then addHL(p) end
            end
        end
    end
end
local function hookPlayer(p)
    addHL(p)
    p:GetAttributeChangedSignal("Team"):Connect(function()
        local h = hlMap[p]; if h then applyHL(h, p) end
    end)
    p.CharacterAdded:Connect(function() removeHL(p); task.wait(0.05); addHL(p) end)
    p.CharacterRemoving:Connect(function() removeHL(p) end)
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(removeHL)
LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshHL)

-- ══════════════════════════════════════════════════════════════
--  DRAWING ESP
--  Guard Drawing API — some executors expose it differently
-- ══════════════════════════════════════════════════════════════
local DrawingAPI = (typeof(Drawing) == "table" or typeof(Drawing) == "userdata") and Drawing or nil

local drawObjs = {}
local function newLine(th, c)
    if not DrawingAPI then return {Visible=false,From=Vector2.new(),To=Vector2.new(),Color=c,Thickness=th,Transparency=1,Remove=function()end} end
    local l = DrawingAPI.new("Line")
    l.Thickness = th; l.Color = c; l.Transparency = 1; l.Visible = false
    return l
end
local function newTxt(sz)
    if not DrawingAPI then return {Visible=false,Text="",Size=sz,Position=Vector2.new(),Color=Color3.new(1,1,1),Remove=function()end} end
    local t = DrawingAPI.new("Text")
    t.Size = sz; t.Center = true; t.Outline = true; t.Font = 2; t.Visible = false
    return t
end
local function makeDO()
    return {
        box = {
            newLine(1.5, Color3.new(1,1,1)), newLine(1.5, Color3.new(1,1,1)),
            newLine(1.5, Color3.new(1,1,1)), newLine(1.5, Color3.new(1,1,1))
        },
        hpBg = newLine(3, Color3.new(0,0,0)),
        hp   = newLine(3, Color3.fromRGB(0,255,0)),
        name = newTxt(13),
        dist = newTxt(11),
    }
end
local function hideDO(d)
    if not d then return end
    for _, l in ipairs(d.box) do l.Visible = false end
    d.hpBg.Visible = false; d.hp.Visible = false
    d.name.Visible = false; d.dist.Visible = false
end
local function killDO(d)
    if not d then return end
    for _, l in ipairs(d.box) do pcall(function() l:Remove() end) end
    pcall(function() d.hpBg:Remove() end); pcall(function() d.hp:Remove() end)
    pcall(function() d.name:Remove() end); pcall(function() d.dist:Remove() end)
end

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then  -- FIX: was `continue`
            if not drawObjs[p] then drawObjs[p] = makeDO() end
            local d = drawObjs[p]; local char = p.Character
            local anyOn = F.espBox or F.espHealth or F.espName or F.espDist
            local show = anyOn and isEnemy(p) and char and not isDead(char)
            if show then
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if root and head then
                    local sH, vH = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,.5,0))
                    local sF, vF = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
                    if (vH and vF) and sH.Z > 0 then
                        local h2 = math.abs(sF.Y - sH.Y); local w = h2 * 0.45
                        local xL, xR, yT, yB = sH.X-w/2, sH.X+w/2, sH.Y, sF.Y
                        if F.espBox then
                            local bc = F.espBoxCol
                            d.box[1].From=Vector2.new(xL,yT); d.box[1].To=Vector2.new(xR,yT); d.box[1].Color=bc; d.box[1].Visible=true
                            d.box[2].From=Vector2.new(xL,yB); d.box[2].To=Vector2.new(xR,yB); d.box[2].Color=bc; d.box[2].Visible=true
                            d.box[3].From=Vector2.new(xL,yT); d.box[3].To=Vector2.new(xL,yB); d.box[3].Color=bc; d.box[3].Visible=true
                            d.box[4].From=Vector2.new(xR,yT); d.box[4].To=Vector2.new(xR,yB); d.box[4].Color=bc; d.box[4].Visible=true
                        else
                            for _, l in ipairs(d.box) do l.Visible = false end
                        end
                        if F.espHealth then
                            local hp, mhp = getHP(char); local hf = hp/mhp
                            local bx = xL - 6
                            d.hpBg.From=Vector2.new(bx,yT); d.hpBg.To=Vector2.new(bx,yB); d.hpBg.Thickness=3; d.hpBg.Visible=true
                            d.hp.From=Vector2.new(bx,yB); d.hp.To=Vector2.new(bx,yB-h2*hf)
                            d.hp.Color=Color3.fromRGB(math.floor(255*(1-hf)),math.floor(255*hf),0); d.hp.Thickness=3; d.hp.Visible=true
                        else d.hpBg.Visible=false; d.hp.Visible=false end
                        if F.espName then
                            d.name.Text=p.Name; d.name.Size=13; d.name.Position=Vector2.new(sH.X,yT-16)
                            d.name.Color=Color3.new(1,1,1); d.name.Visible=true
                        else d.name.Visible=false end
                        if F.espDist then
                            local myPos = HumanoidRootPart and HumanoidRootPart.Position or root.Position
                            d.dist.Text=math.floor((root.Position-myPos).Magnitude).."m"
                            d.dist.Size=11; d.dist.Position=Vector2.new(sH.X,yB+3)
                            d.dist.Color=Color3.fromRGB(180,180,180); d.dist.Visible=true
                        else d.dist.Visible=false end
                    else hideDO(d) end
                else hideDO(d) end
            else hideDO(d) end
        end
    end
    for p, d in pairs(drawObjs) do
        if not p.Parent then killDO(d); drawObjs[p] = nil end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  FOV CIRCLE
-- ══════════════════════════════════════════════════════════════
local fovCirc
if DrawingAPI then
    fovCirc = DrawingAPI.new("Circle")
    fovCirc.Thickness=1.5; fovCirc.Color=Color3.new(1,1,1)
    fovCirc.Transparency=1; fovCirc.Filled=false; fovCirc.Visible=false; fovCirc.NumSides=64
end

RunService.RenderStepped:Connect(function()
    if not fovCirc then return end
    fovCirc.Visible = F.showFOV and F.sa
    if not fovCirc.Visible then return end
    local vp = Camera.ViewportSize
    local fr = math.rad(F.saFOV / 2)
    local r  = (vp.Y/2) * (math.tan(fr) / math.tan(math.rad(Camera.FieldOfView/2)))
    fovCirc.Position = Vector2.new(vp.X/2, vp.Y/2)
    fovCirc.Radius   = math.clamp(r, 0, math.min(vp.X, vp.Y)/2)
    fovCirc.Color    = F.fovColor
end)

-- ══════════════════════════════════════════════════════════════
--  BHOP
-- ══════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not F.bhop then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
    local hum = Humanoid; if not hum then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        if CharController then
            pcall(function() CharController.jump(nil) end)
        else
            hum.Jump = true
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  EDGEBUG
-- ══════════════════════════════════════════════════════════════
local edgeConn; local lastVY = 0
local function startEdge()
    if edgeConn then return end
    edgeConn = RunService.Heartbeat:Connect(function()
        if not F.edgebug then return end
        local root = HumanoidRootPart; if not root then return end
        local vy = root.AssemblyLinearVelocity.Y
        if lastVY < F.ebThresh and vy > lastVY + 8 then
            local hum = Humanoid
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Landed)
                task.defer(function()
                    if hum and F.edgebug then hum:ChangeState(Enum.HumanoidStateType.Running) end
                end)
            end
        end
        lastVY = vy
    end)
end
local function stopEdge()
    if edgeConn then edgeConn:Disconnect(); edgeConn = nil end
end

-- ══════════════════════════════════════════════════════════════
--  PIXEL SURF
-- ══════════════════════════════════════════════════════════════
local surfConn
local surfRP = RaycastParams.new(); surfRP.FilterType = Enum.RaycastFilterType.Exclude
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == F.surfKey then F.surfHeld = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == F.surfKey then F.surfHeld = false end
end)
local function startSurf()
    if surfConn then return end
    surfConn = RunService.Heartbeat:Connect(function()
        if not F.surf or not F.surfHeld then return end
        local root = HumanoidRootPart; if not root then return end
        local vel  = root.AssemblyLinearVelocity
        if Vector2.new(vel.X, vel.Z).Magnitude < 6 then return end
        surfRP.FilterDescendantsInstances = {Character}
        local dirs = {
            Vector3.new(vel.X,0,vel.Z).Unit, Vector3.new(1,0,0),
            Vector3.new(-1,0,0), Vector3.new(0,0,1), Vector3.new(0,0,-1)
        }
        for _, dir in ipairs(dirs) do
            local hit = Workspace:Raycast(root.Position, dir*2, surfRP)
            if hit and hit.Normal and math.abs(hit.Normal.Y) < 0.3 then
                local n = hit.Normal
                root.AssemblyLinearVelocity = vel:Lerp(vel - n*vel:Dot(n), 0.25)
                break
            end
        end
    end)
end
local function stopSurf()
    if surfConn then surfConn:Disconnect(); surfConn = nil end
end

-- ══════════════════════════════════════════════════════════════
--  SILENT AIM
-- ══════════════════════════════════════════════════════════════
local origSend, saHooked = nil, false
local function getBestTarget()
    local vp = Camera.ViewportSize; local cx, cy = vp.X/2, vp.Y/2
    local fr = math.rad(F.saFOV / 2)
    local screenR = (vp.Y/2) * (math.tan(fr) / math.tan(math.rad(Camera.FieldOfView/2)))
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) then
            local char = p.Character
            if char and not isDead(char) then
                local part = char:FindFirstChild(F.saPart) or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = math.sqrt((sp.X-cx)^2 + (sp.Y-cy)^2)
                        if d <= screenR and d < bestD then bestD = d; best = part.Position end
                    end
                end
            end
        end
    end
    return best
end
local function hookSA()
    if saHooked or not Remotes then return end
    local sw = Remotes.Inventory and Remotes.Inventory.ShootWeapon
    if not sw or not sw.Send then return end
    origSend = sw.Send
    sw.Send = function(self, data)
        if F.sa and type(data) == "table" and type(data.Bullets) == "table" then
            for _, bullet in ipairs(data.Bullets) do
                if typeof(bullet.Direction) == "Vector3" then
                    local origin = bullet.Origin or (HumanoidRootPart and HumanoidRootPart.Position) or Vector3.zero
                    local target = getBestTarget()
                    if target then
                        bullet.Direction = (target - origin).Unit
                        if type(bullet.Hits) == "table" then
                            for _, hit in ipairs(bullet.Hits) do
                                if typeof(hit.Position) == "Vector3" then hit.Position = target end
                            end
                        end
                    end
                end
            end
        end
        return origSend(self, data)
    end
    saHooked = true
end
local function unhookSA()
    if not saHooked or not Remotes then return end
    local sw = Remotes.Inventory and Remotes.Inventory.ShootWeapon
    if sw and origSend then sw.Send = origSend end; saHooked = false
end

-- ══════════════════════════════════════════════════════════════
--  GRENADE PREDICTION
-- ══════════════════════════════════════════════════════════════
local gpLines = {}
local gpDot
if DrawingAPI then
    gpDot = DrawingAPI.new("Circle")
    gpDot.Radius=5; gpDot.Filled=true
    gpDot.Color=Color3.fromRGB(255,60,60); gpDot.Visible=false
    gpDot.Transparency=1; gpDot.NumSides=16
end
local gpRP = RaycastParams.new(); gpRP.FilterType = Enum.RaycastFilterType.Exclude
local GREN = {
    molotov    = {r=0.2,f=10,e=true},
    incendiary = {r=0.2,f=10,e=true},
    flashbang  = {r=0.6,f=2},
    smoke      = {r=0.4,f=3},
    he         = {r=0.4,f=3},
    grenade    = {r=0.4,f=3},
    decoy      = {r=0.5,f=15},
}
local gpCache = {pts={}, lastCF=CFrame.new(), lastT=0}

local function clearGP()
    for _, l in ipairs(gpLines) do pcall(function() l:Remove() end) end
    gpLines = {}
    if gpDot then gpDot.Visible = false end
end

RunService.RenderStepped:Connect(function()
    if not F.grenade then clearGP(); return end
    local cam = Workspace.CurrentCamera; if not cam then clearGP(); return end
    local props
    for _, ch in ipairs(cam:GetChildren()) do
        if ch:IsA("Model") and not ch.Name:lower():find("arm") then
            for k, v in pairs(GREN) do
                if ch.Name:lower():find(k) then props = v; break end
            end
        end
        if props then break end
    end
    if not props then clearGP(); return end
    local ch = LocalPlayer.Character; if not ch or not ch.PrimaryPart then clearGP(); return end
    local now = tick()
    local sameCam = (cam.CFrame.Position - gpCache.lastCF.Position).Magnitude < 0.05 and (now - gpCache.lastT) < 0.1
    if not sameCam then
        local gPos = cam.CFrame.Position
        local vel  = cam.CFrame.LookVector * (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and 60 or 125) + ch.PrimaryPart.AssemblyLinearVelocity
        local grav = Vector3.new(0, -Workspace.Gravity, 0)
        local pts  = {gPos}
        gpRP.FilterDescendantsInstances = {ch, cam}
        for _ = 1, math.floor((props.f or 3) / 0.03) do
            vel  = vel + grav * 0.03; vel = vel * 0.98
            local np = gPos + vel * 0.03
            local ray = Workspace:Raycast(gPos, np - gPos, gpRP)
            if ray then
                if props.e then gPos = ray.Position; break end
                local n = ray.Normal; vel = (vel - 2*vel:Dot(n)*n) * (props.r or 0.5)
                gPos = ray.Position + n * 0.05
                if vel.Magnitude < 5 then break end
            else
                gPos = np
            end
            table.insert(pts, gPos)
        end
        gpCache.pts = pts; gpCache.lastCF = cam.CFrame; gpCache.lastT = now
    end
    clearGP()
    local pts = gpCache.pts
    if DrawingAPI then
        for i = 1, #pts - 1 do
            local s1, v1 = cam:WorldToViewportPoint(pts[i])
            local s2, v2 = cam:WorldToViewportPoint(pts[i+1])
            if v1 and v2 and s1.Z > 0 and s2.Z > 0 then
                local l = DrawingAPI.new("Line")
                l.Thickness=2; l.Color=F.grenadeCol; l.Transparency=1
                l.From=Vector2.new(s1.X,s1.Y); l.To=Vector2.new(s2.X,s2.Y); l.Visible=true
                table.insert(gpLines, l)
            end
        end
        if #pts > 0 then
            local sp, sv = cam:WorldToViewportPoint(pts[#pts])
            if sv and sp.Z > 0 then
                gpDot.Position=Vector2.new(sp.X,sp.Y); gpDot.Color=F.grenadeCol; gpDot.Visible=true
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  SKIN CHANGER
-- ══════════════════════════════════════════════════════════════
local SkinsRoot; pcall(function() SkinsRoot = ReplicatedStorage.Assets.Skins end)
local SkinSelections = {}
local GloveFolders   = {}
if SkinsRoot then
    for _, wf in ipairs(SkinsRoot:GetChildren()) do
        local t = {}
        for _, sf in ipairs(wf:GetChildren()) do table.insert(t, sf.Name) end
        table.sort(t); SkinSelections[wf.Name] = t
        local n = wf.Name:lower()
        if (n:find("glove") or n:find("wraps")) and not n:find("^ct") and not n:find("^t ") then
            table.insert(GloveFolders, wf.Name)
        end
    end
end
table.sort(GloveFolders)

local KNIFE_MODELS = {"Karambit","Butterfly Knife","Flip Knife","Gut Knife","M9 Bayonet","Stiletto Knife","Skeleton Knife"}
local BASE_KNIVES  = {"CT Knife","T Knife","Knife"}
local function isBaseKnife(n)
    for _, k in ipairs(BASE_KNIVES) do if n == k then return true end end
end

local selSkins = {}; for w, s in pairs(SkinSelections) do selSkins[w] = s[1] or "Default" end
local selGloves = {}; for _, g in ipairs(GloveFolders) do selGloves[g] = "Default" end

local function getSkinSAs(w, s)
    if not SkinsRoot then return nil end
    local wf = SkinsRoot:FindFirstChild(w); if not wf then return nil end
    local sf = wf:FindFirstChild(s); if not sf then return nil end
    local cf = sf:FindFirstChild("Camera"); if not cf then return nil end
    return cf:FindFirstChild("Factory New") or cf:GetChildren()[1]
end
local function patchModel(m, saf)
    if not m or not saf then return end
    for _, sa in ipairs(saf:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            local pt = m:FindFirstChild(sa.Name, true)
            if pt and pt:IsA("BasePart") then
                for _, old in ipairs(pt:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
                sa:Clone().Parent = pt
            end
        end
    end
end
local function getVM()
    local cam = Workspace.CurrentCamera; if not cam then return end
    for _, ch in ipairs(cam:GetChildren()) do
        if ch:IsA("Model") and not ch.Name:lower():find("arm") and ch.Name ~= "Viewmodel" then return ch end
    end
end
local function getArms()
    local cam = Workspace.CurrentCamera; if not cam then return end
    for _, ch in ipairs(cam:GetChildren()) do
        if ch:IsA("Model") and (ch.Name:find("Arms") or (ch:FindFirstChild("Left Arm") and ch:FindFirstChild("Right Arm"))) then return ch end
    end
end
local function applyWeaponSkin()
    if not F.skinOn then return end
    local wm = getVM(); if not wm then return end
    local name = wm.Name; if isBaseKnife(name) and F.knifeOn then name = F.knifeModel end
    local skin = selSkins[name]; if not skin or skin == "Default" then return end
    if wm:GetAttribute("NebulaSkin") == skin then return end
    local saf = getSkinSAs(name, skin); if saf then patchModel(wm, saf); wm:SetAttribute("NebulaSkin", skin) end
end
local function applyGloveSkin()
    if not F.gloveOn then return end
    local am = getArms(); if not am then return end
    local la = am:FindFirstChild("Left Arm"); local ra = am:FindFirstChild("Right Arm")
    if not la or not ra then return end
    local lg = la:FindFirstChild("Glove"); local rg = ra:FindFirstChild("Glove")
    if not lg or not rg then return end
    local skin = selGloves[F.gloveModel]; if not skin or skin == "Default" then return end
    local saf = getSkinSAs(F.gloveModel, skin); if not saf then return end
    for _, tgt in ipairs({lg, rg}) do
        for _, old in ipairs(tgt:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
        for _, sa in ipairs(saf:GetChildren()) do if sa:IsA("SurfaceAppearance") then sa:Clone().Parent = tgt end end
    end
end
local knifeHooked = false
local function hookKnife()
    if knifeHooked then return end
    local SM = ReplicatedStorage:FindFirstChild("Database")
        and ReplicatedStorage.Database:FindFirstChild("Components")
        and ReplicatedStorage.Database.Components:FindFirstChild("Libraries")
        and ReplicatedStorage.Database.Components.Libraries:FindFirstChild("Skins")
    local VM = ReplicatedStorage:FindFirstChild("Classes")
        and ReplicatedStorage.Classes:FindFirstChild("WeaponComponent")
        and ReplicatedStorage.Classes.WeaponComponent:FindFirstChild("Classes")
        and ReplicatedStorage.Classes.WeaponComponent.Classes:FindFirstChild("Viewmodel")
    if not SM or not VM then return end
    local Sk = SR(SM); local Vw = SR(VM); if not Sk or not Vw then return end
    if not (Sk.GetCameraModel and Sk.GetCharacterModel and Vw.new) then return end
    local oGCM = Sk.GetCameraModel
    Sk.GetCameraModel = function(w, sk, ...)
        if F.knifeOn and isBaseKnife(w) then
            local ok, r = pcall(oGCM, F.knifeModel, selSkins[F.knifeModel] or "Vanilla", ...)
            if ok and r then return r end
        end
        return oGCM(w, sk, ...)
    end
    local oGChM = Sk.GetCharacterModel
    Sk.GetCharacterModel = function(w, sk, ...)
        if F.knifeOn and isBaseKnife(w) then
            local ok, r = pcall(oGChM, F.knifeModel, selSkins[F.knifeModel] or "Vanilla", ...)
            if ok and r then return r end
        end
        return oGChM(w, sk, ...)
    end
    local oVN = Vw.new
    Vw.new = function(vc, w, sk, ...)
        if F.knifeOn and isBaseKnife(w) then
            local ok, r = pcall(oVN, vc, F.knifeModel, selSkins[F.knifeModel] or "Vanilla", ...)
            if ok and r then return r end
        end
        return oVN(vc, w, sk, ...)
    end
    if Sk.GetGloves then
        local oGG = Sk.GetGloves
        Sk.GetGloves = function(g, sk)
            if F.gloveOn then
                local gs = selGloves[F.gloveModel] or "Default"
                if gs ~= "Default" then
                    local ok, r = pcall(oGG, F.gloveModel, gs)
                    if ok and r then return r end
                end
            end
            return oGG(g, sk)
        end
    end
    knifeHooked = true
end
pcall(hookKnife)

local skinDB = false
local function trySkins()
    if skinDB then return end; skinDB = true
    task.spawn(function()
        task.wait(0.2); pcall(applyWeaponSkin)
        pcall(applyGloveSkin); task.wait(0.3); skinDB = false
    end)
end
local function hookCam()
    local cam = Workspace.CurrentCamera; if not cam then return end
    cam.ChildAdded:Connect(function() if F.skinOn or F.gloveOn then trySkins() end end)
end
hookCam()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCam)

-- ══════════════════════════════════════════════════════════════
--  CUSTOM UI
-- ══════════════════════════════════════════════════════════════
local guiParent = CoreGui
-- FIX: nil-guard gethui and syn before accessing them
if type(gethui) == "function" then
    pcall(function() guiParent = gethui() end)
end

local GUI = Instance.new("ScreenGui")
GUI.Name          = "NebulaCheat"
GUI.ResetOnSpawn  = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder  = 999

local parentOk = false
if type(gethui) == "function" then
    pcall(function() GUI.Parent = gethui(); parentOk = GUI.Parent ~= nil end)
end
if not parentOk then
    pcall(function()
        -- FIX: nil-guard syn
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            syn.protect_gui(GUI)
        end
        GUI.Parent = CoreGui; parentOk = GUI.Parent ~= nil
    end)
end
if not parentOk then
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ── Theme colours ─────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(22,22,22),
    Panel  = Color3.fromRGB(30,30,30),
    Header = Color3.fromRGB(16,16,16),
    Side   = Color3.fromRGB(18,18,18),
    Accent = Color3.fromRGB(0,170,75),
    AccDk  = Color3.fromRGB(0,120,52),
    Text   = Color3.fromRGB(235,235,235),
    Dim    = Color3.fromRGB(130,130,130),
    Border = Color3.fromRGB(50,50,50),
    Tog    = Color3.fromRGB(55,55,55),
    SlBG   = Color3.fromRGB(42,42,42),
    InpBG  = Color3.fromRGB(38,38,38),
}

local function N(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do pcall(function() i[k] = v end) end
    if parent then i.Parent = parent end
    return i
end
local function uiCorner(r, p)    N("UICorner",   {CornerRadius=UDim.new(0,r)}, p) end
local function uiStroke(t, c, p) N("UIStroke",   {Thickness=t, Color=c}, p) end
local function uiPad(l,r,t2,b,p) N("UIPadding",  {PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r),PaddingTop=UDim.new(0,t2),PaddingBottom=UDim.new(0,b)}, p) end
local function uiList(sp, p)     N("UIListLayout",{Padding=UDim.new(0,sp),SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=Enum.FillDirection.Vertical}, p) end

-- ── Main window ───────────────────────────────────────────────
local WIN = N("Frame",{
    Name="NebWin", Size=UDim2.fromOffset(620,500),
    Position=UDim2.new(0.5,-310,0.5,-250),
    BackgroundColor3=C.BG, BorderSizePixel=0,
}, GUI)
uiCorner(6, WIN); uiStroke(1, C.Border, WIN)

-- drag
do
    local drag, ds, sp = false, nil, nil
    WIN.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; sp = WIN.Position
        end
    end)
    WIN.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            WIN.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- title bar
local TBAR = N("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.Header,BorderSizePixel=0},WIN)
uiCorner(6, TBAR)
N("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.Header,BorderSizePixel=0},TBAR)
N("TextLabel",{Text="nebula",Font=Enum.Font.GothamBold,TextSize=17,TextColor3=C.Accent,BackgroundTransparency=1,Size=UDim2.new(0,80,1,0),Position=UDim2.fromOffset(12,0),TextXAlignment=Enum.TextXAlignment.Left},TBAR)
N("TextLabel",{Text="· bloxstrike",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.Dim,BackgroundTransparency=1,Size=UDim2.new(0,100,1,0),Position=UDim2.fromOffset(78,0),TextXAlignment=Enum.TextXAlignment.Left},TBAR)
local closeBtn = N("TextButton",{Text="✕",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.Dim,BackgroundTransparency=1,Size=UDim2.fromOffset(38,38),Position=UDim2.new(1,-38,0,0)},TBAR)
closeBtn.MouseButton1Click:Connect(function() WIN.Visible = false end)

-- sidebar
local SIDE = N("Frame",{Name="Sidebar",Size=UDim2.new(0,108,1,-38),Position=UDim2.new(0,0,0,38),BackgroundColor3=C.Side,BorderSizePixel=0,ClipsDescendants=true},WIN)
N("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.Border,BorderSizePixel=0},SIDE)
local sideTabIndex = 0  -- tracks how many tabs have been added for manual Y positioning

-- content
local CONT = N("ScrollingFrame",{
    Name="Content", Size=UDim2.new(1,-108,1,-38), Position=UDim2.new(0,108,0,38),
    BackgroundColor3=C.Panel, BorderSizePixel=0,
    ScrollBarThickness=4, ScrollBarImageColor3=C.Accent,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
    ScrollingDirection=Enum.ScrollingDirection.Y,
}, WIN)
uiList(8, CONT); uiPad(10,10,10,10,CONT)

-- ── Tab management ────────────────────────────────────────────
local TABS = {}
local activeTabName = nil

local function showTab(name)
    activeTabName = name
    for tname, tdata in pairs(TABS) do
        local isActive = tname == name
        tdata.btn.TextColor3 = isActive and C.Accent or C.Dim
        tdata.btn.BackgroundTransparency = isActive and 0.85 or 1
        tdata.btn.BackgroundColor3 = isActive and C.Accent or C.BG
        local bar = tdata.btn:FindFirstChild("AccentBar")
        if bar then bar.Visible = isActive end
        for _, sec in ipairs(tdata.sections) do sec.Visible = isActive end
    end
end

local function registerTab(name)
    local yPos = sideTabIndex * 38  -- stack buttons top-to-bottom, each 38px tall
    sideTabIndex = sideTabIndex + 1
    local btn = N("TextButton",{
        Text=name, Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=C.Dim, BackgroundTransparency=1,
        BackgroundColor3=C.BG,
        Size=UDim2.new(1,0,0,38),
        Position=UDim2.fromOffset(0, yPos),
        BorderSizePixel=0, AutoButtonColor=false,
    }, SIDE)
    N("Frame",{Name="AccentBar",Size=UDim2.fromOffset(3,22),Position=UDim2.new(0,0,0.5,-11),BackgroundColor3=C.Accent,BorderSizePixel=0,Visible=false},btn)
    TABS[name] = {btn=btn, sections={}}
    btn.MouseButton1Click:Connect(function() showTab(name) end)
end

local function addSection(tabName, secName)
    local sec = N("Frame",{
        Name=secName, BackgroundColor3=C.BG, BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y, Size=UDim2.new(1,0,0,0), Visible=false,
    }, CONT)
    uiCorner(5, sec); uiStroke(1, C.Border, sec)
    local hdr = N("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Header,BorderSizePixel=0},sec)
    uiCorner(5, hdr)
    N("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.Header,BorderSizePixel=0},hdr)
    N("Frame",{Size=UDim2.fromOffset(3,14),Position=UDim2.new(0,10,0.5,-7),BackgroundColor3=C.Accent,BorderSizePixel=0},hdr)
    N("TextLabel",{Text=secName,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-30,1,0),Position=UDim2.fromOffset(22,0),TextXAlignment=Enum.TextXAlignment.Left},hdr)
    local body = N("Frame",{Name="Body",BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(0,0,0,28)},sec)
    uiList(2, body); uiPad(10,10,6,8,body)
    table.insert(TABS[tabName].sections, sec)
    return body
end

-- ── UI Controls ───────────────────────────────────────────────
local function row(parent, height)
    return N("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 28),BorderSizePixel=0},parent)
end

local function uiToggle(parent, label, default, cb)
    local f = row(parent, 28)
    N("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-46,1,0),TextXAlignment=Enum.TextXAlignment.Left},f)
    local track = N("Frame",{Size=UDim2.fromOffset(34,18),Position=UDim2.new(1,-38,0.5,-9),BackgroundColor3=C.Tog,BorderSizePixel=0},f)
    uiCorner(9, track)
    local thumb = N("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(2,2),BackgroundColor3=C.Dim,BorderSizePixel=0},track)
    uiCorner(7, thumb)
    local state = default or false
    local function upd(s)
        state = s
        TweenService:Create(track, TweenInfo.new(0.12), {BackgroundColor3=state and C.Accent or C.Tog}):Play()
        TweenService:Create(thumb, TweenInfo.new(0.12), {
            Position=state and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2),
            BackgroundColor3=state and Color3.new(1,1,1) or C.Dim
        }):Play()
        if cb then pcall(cb, state) end
    end
    N("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),BorderSizePixel=0},f).MouseButton1Click:Connect(function() upd(not state) end)
    upd(state)
    return {get=function() return state end, set=upd}
end

local function uiSlider(parent, label, mn, mx, default, suffix, cb)
    local f = row(parent, 44)
    local valFmt = (mx-mn) > 20 and "%.0f" or "%.1f"
    local lbl = N("TextLabel",{Text=label..": "..string.format(valFmt,default)..(suffix or ""),Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),TextXAlignment=Enum.TextXAlignment.Left},f)
    local track = N("Frame",{Size=UDim2.new(1,0,0,5),Position=UDim2.new(0,0,0,26),BackgroundColor3=C.SlBG,BorderSizePixel=0},f)
    uiCorner(3, track)
    local fill = N("Frame",{Size=UDim2.new((default-mn)/(mx-mn),0,1,0),BackgroundColor3=C.Accent,BorderSizePixel=0},track)
    uiCorner(3, fill)
    local val = default
    local function set(v)
        v = math.clamp(v, mn, mx)
        if (mx-mn) > 20 then v = math.floor(v+0.5) else v = math.floor(v*10+0.5)/10 end
        val = v; fill.Size = UDim2.new((v-mn)/(mx-mn), 0, 1, 0)
        lbl.Text = label..": "..string.format(valFmt, v)..(suffix or "")
        if cb then pcall(cb, v) end
    end
    local sliding = false
    N("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0)},track).InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            set(mn + (mx-mn) * math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
        end
    end)
    set(default)
    return {get=function() return val end, set=set}
end

local allDropdowns = {}
local function uiDropdown(parent, label, opts, default, cb)
    local f = row(parent, 48); f.ClipsDescendants = false
    N("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),TextXAlignment=Enum.TextXAlignment.Left},f)
    local btn = N("TextButton",{Text=default or opts[1] or "",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.Text,BackgroundColor3=C.InpBG,BorderSizePixel=0,Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,20),TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false},f)
    uiCorner(4, btn); uiPad(8,26,0,0,btn)
    N("TextLabel",{Text="▾",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Dim,BackgroundTransparency=1,Size=UDim2.fromOffset(22,26),Position=UDim2.new(1,-24,0,0),TextXAlignment=Enum.TextXAlignment.Center},btn)
    local sel = default or opts[1] or ""
    local isOpen = false
    local listFrame = N("ScrollingFrame",{
        BackgroundColor3=C.InpBG, BorderSizePixel=0,
        Size=UDim2.new(1,-20,0,0), Visible=false,
        ScrollBarThickness=3, ScrollBarImageColor3=C.Accent,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
        ZIndex=10,
    }, CONT)
    uiCorner(4, listFrame); uiStroke(1, C.Border, listFrame)
    uiList(0, listFrame)
    table.insert(allDropdowns, {frame=listFrame, f=f})
    local function closeAll()
        for _, d in ipairs(allDropdowns) do
            if d.frame ~= listFrame then d.frame.Visible = false end
        end
    end
    local optBtns = {}
    local function populate()
        for _, b in ipairs(optBtns) do b:Destroy() end; optBtns = {}
        for _, opt in ipairs(opts) do
            local ob = N("TextButton",{Text=opt,Font=Enum.Font.Gotham,TextSize=12,TextColor3=opt==sel and C.Accent or C.Text,BackgroundTransparency=1,Size=UDim2.new(1,0,0,24),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10},listFrame)
            uiPad(8,0,0,0,ob)
            ob.MouseButton1Click:Connect(function()
                sel=opt; btn.Text=opt; listFrame.Visible=false; isOpen=false
                for _, b in ipairs(optBtns) do b.TextColor3 = b.Text==sel and C.Accent or C.Text end
                if cb then pcall(cb, opt) end
            end)
            table.insert(optBtns, ob)
        end
        listFrame.Size = UDim2.new(1,-20,0,math.min(#opts*24,120))
    end
    populate()
    btn.MouseButton1Click:Connect(function()
        closeAll(); isOpen = not isOpen; listFrame.Visible = isOpen
    end)
    return {
        get = function() return sel end,
        set = function(v) sel=v; btn.Text=v; if cb then pcall(cb,v) end end,
        setOptions = function(newOpts) opts=newOpts; sel=newOpts[1] or ""; btn.Text=sel; populate() end,
    }
end

local function uiColorpicker(parent, label, default, cb)
    local f = row(parent, 28)
    N("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-40,1,0),TextXAlignment=Enum.TextXAlignment.Left},f)
    local prev = N("TextButton",{Text="",BackgroundColor3=default,Size=UDim2.fromOffset(30,18),Position=UDim2.new(1,-34,0.5,-9),BorderSizePixel=0,AutoButtonColor=false},f)
    uiCorner(4, prev); uiStroke(1, C.Border, prev)
    local col = default; local h2, s2, v2 = col:ToHSV()
    local pop = N("Frame",{BackgroundColor3=C.BG,BorderSizePixel=0,Size=UDim2.fromOffset(210,190),Visible=false,ZIndex=100},GUI)
    uiCorner(6, pop); uiStroke(1, C.Border, pop)
    local svF = N("Frame",{Size=UDim2.fromOffset(168,120),Position=UDim2.fromOffset(10,10),BackgroundColor3=Color3.fromHSV(h2,1,1),BorderSizePixel=0,ZIndex=100},pop)
    uiCorner(3, svF)
    local whiteGrad = Instance.new("UIGradient")
    whiteGrad.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1))
    whiteGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
    whiteGrad.Parent = svF
    local blkOver = N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=101},svF)
    uiCorner(3, blkOver)
    local blkGrad = Instance.new("UIGradient")
    blkGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
    blkGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
    blkGrad.Rotation = 90; blkGrad.Parent = blkOver
    local svBtn = N("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=102},svF)
    local hueF = N("Frame",{Size=UDim2.fromOffset(168,14),Position=UDim2.fromOffset(10,138),BorderSizePixel=0,ZIndex=100},pop)
    uiCorner(4, hueF)
    local hGrad = Instance.new("UIGradient")
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,1,1)),
        ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),
        ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
        ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),
        ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),
        ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,1,1)),
    })
    hGrad.Parent = hueF
    local hueBtn  = N("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),ZIndex=102},hueF)
    local prevBig = N("Frame",{Size=UDim2.fromOffset(168,14),Position=UDim2.fromOffset(10,158),BackgroundColor3=col,BorderSizePixel=0,ZIndex=100},pop)
    uiCorner(4, prevBig)
    local function applyColor()
        col = Color3.fromHSV(h2, s2, v2)
        prev.BackgroundColor3 = col; prevBig.BackgroundColor3 = col
        svF.BackgroundColor3 = Color3.fromHSV(h2, 1, 1)
        if cb then pcall(cb, col) end
    end
    local svDrag, hueDrag = false, false
    svBtn.InputBegan:Connect(function(i)  if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=true  end end)
    hueBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDrag=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=false; hueDrag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if svDrag then
            s2 = math.clamp((i.Position.X-svF.AbsolutePosition.X)/svF.AbsoluteSize.X,0,1)
            v2 = 1-math.clamp((i.Position.Y-svF.AbsolutePosition.Y)/svF.AbsoluteSize.Y,0,1)
            applyColor()
        end
        if hueDrag then
            h2 = math.clamp((i.Position.X-hueF.AbsolutePosition.X)/hueF.AbsoluteSize.X,0,1)
            applyColor()
        end
    end)
    prev.MouseButton1Click:Connect(function()
        pop.Visible = not pop.Visible
        if pop.Visible then
            local ap = prev.AbsolutePosition
            pop.Position = UDim2.fromOffset(math.clamp(ap.X-200,0,1200), math.clamp(ap.Y+22,0,700))
        end
    end)
    return {get=function() return col end}
end

local function uiKeybind(parent, label, default, cb)
    local f = row(parent, 28)
    N("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.Text,BackgroundTransparency=1,Size=UDim2.new(1,-80,1,0),TextXAlignment=Enum.TextXAlignment.Left},f)
    local key = default
    local btn = N("TextButton",{Text=key and key.Name or "None",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.Dim,BackgroundColor3=C.InpBG,BorderSizePixel=0,Size=UDim2.fromOffset(72,20),Position=UDim2.new(1,-76,0.5,-10),AutoButtonColor=false},f)
    uiCorner(4, btn)
    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening=true; btn.Text="..."; btn.TextColor3=C.Accent
        local con; con = UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                key=i.KeyCode; btn.Text=i.KeyCode.Name; btn.TextColor3=C.Dim
                listening=false; con:Disconnect()
                if cb then pcall(cb, key) end
            end
        end)
    end)
    return {get=function() return key end}
end

local function uiButton(parent, label, cb)
    local btn = N("TextButton",{Text=label,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Text,BackgroundColor3=C.AccDk,BorderSizePixel=0,Size=UDim2.new(1,0,0,28),AutoButtonColor=false},parent)
    uiCorner(4, btn)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=C.Accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=C.AccDk}):Play() end)
    btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end

local function uiSpacer(parent, h) row(parent, h or 4) end

-- ── Register tabs ─────────────────────────────────────────────
registerTab("Combat")
registerTab("Rage")
registerTab("Visuals")
registerTab("Misc")
registerTab("Skins")
registerTab("Settings")

-- ╔══════════════════════════════════════╗
-- ║  COMBAT                               ║
-- ║  Silent Aim                           ║
-- ╚══════════════════════════════════════╝
do
    local b = addSection("Combat", "Silent Aim")
    uiToggle(b, "Enable Silent Aim", false, function(v) F.sa=v; if v then hookSA() else unhookSA() end end)
    uiToggle(b, "Show FOV Circle", false, function(v) F.showFOV=v end)
    uiColorpicker(b, "FOV Color", F.fovColor, function(c) F.fovColor=c end)
    uiSlider(b, "FOV Degrees", 1, 180, 180, "°", function(v) F.saFOV=v end)
    uiDropdown(b, "Target Part", {"Head","HumanoidRootPart","UpperTorso","Torso"}, "Head", function(v) F.saPart=v end)
end

-- ╔══════════════════════════════════════╗
-- ║  RAGE                                 ║
-- ║  Placeholder for aimbot-style feats   ║
-- ╚══════════════════════════════════════╝
do
    local b = addSection("Rage", "Rage Options")
    N("TextLabel",{
        Text="Rage features coming soon.",
        Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.Dim,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,20),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, b)
end

-- ╔══════════════════════════════════════╗
-- ║  VISUALS                              ║
-- ║  ESP · Box · Health · Name · Dist     ║
-- ╚══════════════════════════════════════╝
do
    local b = addSection("Visuals", "ESP")
    uiToggle(b, "Enable Highlight (Wallhack)", false, function(v) F.esp=v; refreshHL() end)
    uiColorpicker(b, "Highlight Color", F.espColor, function(c) F.espColor=c; refreshHL() end)
    uiSlider(b, "Fill Opacity", 0, 100, 45, "%", function(v) F.espFill=1-(v/100); refreshHL() end)
    uiSpacer(b)
    uiToggle(b, "Box ESP", false, function(v) F.espBox=v end)
    uiColorpicker(b, "Box Color", F.espBoxCol, function(c) F.espBoxCol=c end)
    uiSpacer(b)
    uiToggle(b, "Health Bar", true, function(v) F.espHealth=v end)
    uiToggle(b, "Name", true, function(v) F.espName=v end)
    uiToggle(b, "Distance", true, function(v) F.espDist=v end)
end

-- ╔══════════════════════════════════════╗
-- ║  MISC                                 ║
-- ║  BHop · EdgeBug · Surf · Grenades     ║
-- ╚══════════════════════════════════════╝
do
    local b = addSection("Misc", "Bunny Hop")
    uiToggle(b, "Enable BHop  [hold Space]", false, function(v) F.bhop=v end)

    local b2 = addSection("Misc", "EdgeBug")
    uiToggle(b2, "Enable EdgeBug", false, function(v) F.edgebug=v; if v then startEdge() else stopEdge() end end)
    uiSlider(b2, "Trigger Velocity", -60, -5, -20, "", function(v) F.ebThresh=v end)

    local b3 = addSection("Misc", "Pixel Surf")
    uiToggle(b3, "Enable Pixel Surf", false, function(v) F.surf=v; if v then startSurf() else stopSurf() end end)
    uiKeybind(b3, "Hold Key", Enum.KeyCode.C, function(k) F.surfKey=k; F.surfHeld=false end)

    local b4 = addSection("Misc", "Grenade Prediction")
    uiToggle(b4, "Enable", false, function(v) F.grenade=v end)
    uiColorpicker(b4, "Line Color", F.grenadeCol, function(c) F.grenadeCol=c end)
end

-- ╔══════════════════════════════════════╗
-- ║  SKINS                                ║
-- ║  Weapon · Knife · Glove               ║
-- ╚══════════════════════════════════════╝
do
    local b = addSection("Skins", "Weapon Skins")
    uiToggle(b, "Enable Skin Changer", false, function(v) F.skinOn=v end)
    local wList = {}
    for w in pairs(SkinSelections) do
        local isK = false; for _, k in ipairs(KNIFE_MODELS) do if w==k then isK=true; break end end
        local isG = false; for _, g in ipairs(GloveFolders) do if w==g then isG=true; break end end
        if not isK and not isG then table.insert(wList, w) end
    end
    table.sort(wList); if #wList == 0 then wList = {"AK-47"} end
    local selW = wList[1]; local skinDDRef
    uiDropdown(b, "Weapon", wList, selW, function(v)
        selW = v
        local skins = SkinSelections[v] or {"Stock"}
        selSkins[v] = skins[1]
        if skinDDRef then skinDDRef.setOptions(skins) end
    end)
    skinDDRef = uiDropdown(b, "Skin", SkinSelections[selW] or {"Stock"}, (SkinSelections[selW] or {"Stock"})[1], function(v) selSkins[selW]=v end)
    uiButton(b, "Apply Skin", function() trySkins() end)

    local b2 = addSection("Skins", "Knife Changer")
    uiToggle(b2, "Enable (next equip)", false, function(v) F.knifeOn=v; pcall(hookKnife) end)
    local kSkinRef
    uiDropdown(b2, "Knife Model", KNIFE_MODELS, "Karambit", function(v)
        F.knifeModel = v; if kSkinRef then kSkinRef.setOptions(SkinSelections[v] or {"Vanilla"}) end
    end)
    kSkinRef = uiDropdown(b2, "Knife Skin", SkinSelections["Karambit"] or {"Vanilla"}, (SkinSelections["Karambit"] or {"Vanilla"})[1], function(v) selSkins[F.knifeModel]=v end)

    local b3 = addSection("Skins", "Glove Changer")
    uiToggle(b3, "Enable Gloves", false, function(v) F.gloveOn=v end)
    local gSkinRef
    uiDropdown(b3, "Glove Model", #GloveFolders>0 and GloveFolders or {"Driver Gloves"}, "Driver Gloves", function(v)
        F.gloveModel = v
        local gs = {"Default"}; for _, sk in ipairs(SkinSelections[v] or {}) do table.insert(gs, sk) end
        if gSkinRef then gSkinRef.setOptions(gs) end
    end)
    do
        local gs = {"Default"}; for _, sk in ipairs(SkinSelections[F.gloveModel] or {}) do table.insert(gs, sk) end
        gSkinRef = uiDropdown(b3, "Glove Skin", gs, "Default", function(v) selGloves[F.gloveModel]=v end)
    end
    uiButton(b3, "Apply Gloves", function() pcall(applyGloveSkin) end)
end

-- ╔══════════════════════════════════════╗
-- ║  SETTINGS                             ║
-- ║  Config save / load · UI controls     ║
-- ╚══════════════════════════════════════╝
do
    -- Config is stored as a JSON-like string in a WritableFile if supported,
    -- otherwise falls back to clipboard or a printed string the user can paste back.
    local CONFIG_KEY = "NebulaCFG"

    local function serializeConfig()
        -- Capture every flag that makes sense to persist
        return game:GetService("HttpService"):JSONEncode({
            esp        = F.esp,
            espFill    = F.espFill,
            espBox     = F.espBox,
            espHealth  = F.espHealth,
            espName    = F.espName,
            espDist    = F.espDist,
            bhop       = F.bhop,
            edgebug    = F.edgebug,
            ebThresh   = F.ebThresh,
            surf       = F.surf,
            sa         = F.sa,
            saFOV      = F.saFOV,
            saPart     = F.saPart,
            showFOV    = F.showFOV,
            grenade    = F.grenade,
            skinOn     = F.skinOn,
            knifeOn    = F.knifeOn,
            knifeModel = F.knifeModel,
            gloveOn    = F.gloveOn,
            gloveModel = F.gloveModel,
        })
    end

    local function applyConfig(tbl)
        if type(tbl) ~= "table" then return end
        for k, v in pairs(tbl) do
            if F[k] ~= nil then F[k] = v end
        end
        -- re-apply side-effects
        refreshHL()
        if F.edgebug then startEdge() else stopEdge() end
        if F.surf     then startSurf() else stopSurf()  end
        if F.sa       then hookSA()    else unhookSA()  end
        if F.skinOn or F.gloveOn then trySkins() end
    end

    local function saveConfig()
        local json = serializeConfig()
        -- Try writefile (Synapse / Fluxus / etc.)
        local ok = false
        if type(writefile) == "function" then
            pcall(function() writefile("nebula_cfg.json", json); ok = true end)
        end
        if ok then
            return "[Nebula] Config saved to nebula_cfg.json"
        end
        -- Fallback: copy to clipboard
        if type(setclipboard) == "function" then
            pcall(function() setclipboard(json) end)
            return "[Nebula] Copied config to clipboard"
        end
        return "[Nebula] Save failed — writefile/setclipboard unavailable"
    end

    local function loadConfig()
        -- Try readfile first
        if type(readfile) == "function" then
            local ok, data = pcall(readfile, "nebula_cfg.json")
            if ok and data and #data > 0 then
                local ok2, tbl = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(data)
                end)
                if ok2 then applyConfig(tbl); return "[Nebula] Config loaded from nebula_cfg.json" end
            end
        end
        return "[Nebula] No saved config found (nebula_cfg.json missing)"
    end

    -- Status label shown after save/load
    local b = addSection("Settings", "Config")
    local statusLbl = N("TextLabel",{
        Text="",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.Accent,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, b)
    local function setStatus(msg)
        statusLbl.Text = msg
        task.delay(4, function() if statusLbl and statusLbl.Parent then statusLbl.Text = "" end end)
    end

    uiButton(b, "Save Config", function()
        local msg = saveConfig(); setStatus(msg); print(msg)
    end)
    uiButton(b, "Load Config", function()
        local msg = loadConfig(); setStatus(msg); print(msg)
    end)

    uiSpacer(b)

    local b2 = addSection("Settings", "Interface")
    N("TextLabel",{
        Text="RightShift = hide / show UI",
        Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.Dim,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,20),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, b2)
    uiSpacer(b2)
    uiButton(b2, "Close UI", function() WIN.Visible=false end)
    uiButton(b2, "Unload Script", function()
        for _, p in pairs(Players:GetPlayers()) do removeHL(p) end
        if fovCirc then fovCirc.Visible=false end
        clearGP()
        for _, d in pairs(drawObjs) do killDO(d) end
        GUI:Destroy()
    end)
end

-- ── Open on Combat ────────────────────────────────────────────
showTab("Combat")

-- ── RightShift toggle ─────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then WIN.Visible = not WIN.Visible end
end)

-- ── Respawn ───────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1); refreshChar(); lastVY = 0
    stopEdge(); if F.edgebug then startEdge() end
    stopSurf(); if F.surf then startSurf() end
    if F.skinOn or F.gloveOn then task.wait(0.5); trySkins() end
end)

print("[Nebula] UI loaded — RightShift to hide")
