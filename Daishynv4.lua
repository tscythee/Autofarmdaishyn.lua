--[[ Daishyn - Volleyball Legends
     Tudo visual e local (só você vê). Pílula ou tecla do painel abre/fecha. Erros: console (F9), prefixo [Daishyn]. ]]

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local THEMES = {
    Halloween = {
        accent = rgb(255, 138, 36), glow2 = rgb(255, 200, 70),
        tint = { win = rgb(255, 215, 180), side = rgb(255, 200, 150), card = rgb(255, 225, 200), btn = rgb(255, 205, 150) },
        Clean = { bg = rgb(9, 8, 7), side = rgb(14, 12, 10), card = rgb(20, 17, 15), field = rgb(12, 10, 9), btn = rgb(34, 29, 25), line = rgb(52, 44, 38) },
        Soft = { bg = rgb(16, 10, 8), side = rgb(22, 14, 10), card = rgb(32, 20, 13), field = rgb(20, 13, 9), btn = rgb(52, 32, 18), line = rgb(96, 58, 28) },
    },
    Roxo = {
        accent = rgb(168, 120, 255), glow2 = rgb(236, 120, 255),
        tint = { win = rgb(215, 195, 255), side = rgb(210, 180, 255), card = rgb(225, 205, 255), btn = rgb(215, 190, 255) },
        Clean = { bg = rgb(8, 8, 8), side = rgb(12, 12, 12), card = rgb(17, 17, 18), field = rgb(10, 10, 10), btn = rgb(28, 28, 30), line = rgb(40, 40, 44) },
        Soft = { bg = rgb(5, 4, 9), side = rgb(10, 7, 17), card = rgb(22, 15, 38), field = rgb(12, 9, 20), btn = rgb(38, 24, 66), line = rgb(72, 44, 118) },
    },
}
local function resolveTheme(mode)
    return THEMES[mode] and mode or "Roxo"
end
local VGRAD_BOTTOM = { Roxo = rgb(60, 28, 110), Halloween = rgb(255, 200, 70) }

local DISCORD_CODE = "wQsTbapFVT"
local DISCORD_URL = "https://discord.gg/" .. DISCORD_CODE
local DISCORD_ICON = "rbxassetid://18505728250"

local function discordJoin()
    local copied = false
    for _, fnName in ipairs({ "setclipboard", "toclipboard", "set_clipboard" }) do
        local fn = getgenv()[fnName]
        if type(fn) == "function" and pcall(fn, DISCORD_URL) then
            copied = true
            break
        end
    end
    local req = (syn and syn.request) or request or http_request
    if req then
        pcall(function()
            req({
                Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
                Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
                Body = HttpService:JSONEncode({
                    cmd = "INVITE_BROWSER", args = { code = DISCORD_CODE }, nonce = HttpService:GenerateGUID(false),
                }),
            })
        end)
    end
    return copied
end

local function showError(msg)
    warn("[Daishyn] " .. msg)
    pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name = "DaishynError"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.DisplayOrder = 1000
        g.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 150)
        l.Position = UDim2.new(0, 10, 0, 50)
        l.BackgroundColor3 = Color3.fromRGB(25, 0, 0)
        l.TextColor3 = Color3.new(1, 1, 1)
        l.TextWrapped = true
        l.TextSize = 12
        l.Font = Enum.Font.Code
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.Text = "Daishyn - erro ao iniciar:\n" .. string.sub(msg, 1, 700)
        l.Parent = g
        task.delay(45, function() g:Destroy() end)
    end)
end

local function main()
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

if not game:IsLoaded() then game.Loaded:Wait() end

local LP = Players.LocalPlayer
while not LP do
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LP = Players.LocalPlayer
end

local GEN = (getgenv().__DaishynGen or 0) + 1
getgenv().__DaishynGen = GEN
local function mine() return getgenv().__DaishynGen == GEN end

local STATE
do
    local legacy = getgenv().__ScyFeState
    if legacy then pcall(legacy.teardown) end
    local prev = getgenv().__DaishynState
    if prev then pcall(prev.teardown) end

    local conns, cleanups = {}, {}
    STATE = {
        connect = function(signal, fn)
            local c = signal:Connect(fn)
            table.insert(conns, c)
            return c
        end,
        onCleanup = function(fn) table.insert(cleanups, fn) end,
        teardown = function()
            for _, fn in ipairs(cleanups) do pcall(fn) end
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            table.clear(conns)
            table.clear(cleanups)
            if getgenv().__DaishynState == STATE then getgenv().__DaishynState = nil end
        end,
    }
    getgenv().__DaishynState = STATE
end

local UI
do

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local THEME = {
    bg     = Color3.fromRGB(8, 8, 8),
    side   = Color3.fromRGB(12, 12, 12),
    card   = Color3.fromRGB(17, 17, 18),
    field  = Color3.fromRGB(10, 10, 10),
    btn    = Color3.fromRGB(28, 28, 30),
    line   = Color3.fromRGB(40, 40, 44),
    accent = Color3.fromRGB(168, 120, 255),
    text   = Color3.fromRGB(255, 255, 255),
    sub    = Color3.fromRGB(150, 150, 158),
    off    = Color3.fromRGB(56, 56, 62),
    warn   = Color3.fromRGB(255, 112, 112),
}

local themeMode = "Roxo"
local themeName = resolveTheme(themeMode)
local PALETTE = THEMES[themeName]
local TINT = PALETTE.tint
local glow2 = PALETTE.glow2
local isSoft = true
for k, v in pairs(PALETTE.Soft) do THEME[k] = v end
THEME.accent = PALETTE.accent

local FONT = { reg = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold }
local FONTSETS, FONT_NAMES = {}, {}
for _, def in ipairs({
    { "Gotham", "GothamMedium", "GothamBold" }, { "Source Sans", "SourceSans", "SourceSansBold" },
    { "Roboto", "Roboto", "Roboto" }, { "Nunito", "Nunito", "Nunito" }, { "Ubuntu", "Ubuntu", "Ubuntu" },
    { "Oswald", "Oswald", "Oswald" }, { "Jura", "Jura", "Jura" }, { "Titillium", "TitilliumWeb", "TitilliumWeb" },
    { "Fredoka", "FredokaOne", "FredokaOne" }, { "Código", "Code", "Code" }, { "Arial", "Arial", "ArialBold" },
}) do
    local okA, reg = pcall(function() return Enum.Font[def[2]] end)
    local okB, bold = pcall(function() return Enum.Font[def[3]] end)
    if okA and okB and reg and bold then
        FONTSETS[def[1]] = { reg, bold }
        table.insert(FONT_NAMES, def[1])
    end
end
local animLevel = 2
local gradMode = "Automático"
local radiusExtra = 0
local custom = { accent = nil, bg = nil, border = nil }
local binds = {}
local DEFAULT_ACCENT = PALETTE.accent

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if props and props.Font == FONT.bold then o:SetAttribute("sfb", true) end
    if parent then o.Parent = parent end
    return o
end
local function round(o, r)
    new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
    return o
end
local function outline(o, color, thickness)
    return new("UIStroke", {
        Color = color, Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end
local function pad(o, l, t, r, b)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    }, o)
end
local function label(props, parent)
    props.BackgroundTransparency = 1
    props.Font = props.Font or FONT.reg
    props.TextColor3 = props.TextColor3 or THEME.text
    props.TextSize = props.TextSize or 13
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local function tween(inst, goal, t)
    if animLevel == 0 then
        for k, v in pairs(goal) do inst[k] = v end
        return
    end
    TweenService:Create(inst, TweenInfo.new(t or 0.12), goal):Play()
end
local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end
local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

UI = { controls = {}, lang = "Português", EN = {} }

local function tr(key)
    if UI.lang == "English" then return UI.EN[key] or key end
    return key
end
UI.tr = tr

function UI.call(fn, ...)
    if not fn then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = xpcall(fn, debug.traceback, table.unpack(args, 1, args.n))
        if not ok then
            warn("[Daishyn] " .. tostring(err))
            UI.notify("Erro", string.sub(tostring(err):match("^[^\n]+") or "erro", 1, 90))
        end
    end)
end
function UI.trf(fmt, ...)
    return string.format(tr(fmt), ...)
end
local langLabels, langHooks = {}, {}
local function reg(inst, key)
    inst.Text = tr(key)
    table.insert(langLabels, { inst = inst, key = key })
    return inst
end
local function tlabel(props, parent, key)
    local l = label(props, parent)
    return reg(l, key)
end

local gui = new("ScreenGui", {
    Name = "DaishynGUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
do
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    local ok = pcall(function()
        local host = (gethui and gethui()) or game:GetService("CoreGui")
        gui.Parent = host
    end)
    if not ok or not gui.Parent then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end
end
STATE.onCleanup(function() gui:Destroy() end)

local tracked, surfaces, lineStrokes, styleHooks = {}, {}, {}, {}
local transp = 0

local function track(frame)
    table.insert(tracked, frame)
    frame.BackgroundTransparency = transp
    return frame
end
local function surface(frame, key)
    table.insert(surfaces, { frame = frame, key = key })
    return frame
end
local function skin(frame, key)
    surface(frame, key)
    return track(frame)
end
local function onStyle(fn)
    table.insert(styleHooks, fn)
    fn(isSoft)
end
local function lineStroke(o)
    local stroke = outline(o, THEME.line, 1)
    table.insert(lineStrokes, stroke)
    return stroke
end
local gradients = {}
local function cornerStyle(obj, clean, soft)
    local corner = obj:FindFirstChildOfClass("UICorner")
    if corner then
        onStyle(function(sf) corner.CornerRadius = UDim.new(0, math.max((sf and soft or clean) + radiusExtra, 2)) end)
    end
end
local function gradientsOn()
    if gradMode == "Gradiente" then return true end
    if gradMode == "Sólido" then return false end
    return isSoft
end
local function gradient(frame, c0, c1, rotation)
    local key = type(c1) == "string" and c1 or nil
    local g = new("UIGradient", {
        Color = ColorSequence.new(c0, key and TINT[key] or c1), Rotation = rotation or 90, Enabled = gradientsOn(),
    }, frame)
    table.insert(gradients, { g = g, key = key })
    return g
end

function UI.setTransparency(percent)
    transp = math.clamp((tonumber(percent) or 0) / 100, 0, 0.6)
    for _, f in ipairs(tracked) do
        if f.Parent then f.BackgroundTransparency = transp end
    end
    if UI.refreshNav then UI.refreshNav() end
end
local function applyPalette()
    for k, v in pairs(PALETTE[isSoft and "Soft" or "Clean"]) do THEME[k] = v end
    if custom.bg then
        local bg = custom.bg
        THEME.bg = bg
        THEME.side = bg:Lerp(rgb(255, 255, 255), 0.04)
        THEME.card = bg:Lerp(rgb(255, 255, 255), 0.08)
        THEME.field = bg:Lerp(rgb(0, 0, 0), 0.3)
        THEME.btn = bg:Lerp(rgb(255, 255, 255), 0.16)
    end
    if custom.border then THEME.line = custom.border end
end
local function refreshSurfaces()
    for _, item in ipairs(surfaces) do
        if item.frame.Parent then item.frame.BackgroundColor3 = THEME[item.key] end
    end
    for _, stroke in ipairs(lineStrokes) do stroke.Color = THEME.line end
    local on = gradientsOn()
    for _, e in ipairs(gradients) do
        if e.g.Parent then
            e.g.Enabled = on
            if e.key then e.g.Color = ColorSequence.new(rgb(255, 255, 255), TINT[e.key]) end
        end
    end
    for _, fn in ipairs(styleHooks) do pcall(fn, isSoft) end
end
function UI.setStyle(name)
    isSoft = (name == "Soft")
    applyPalette()
    refreshSurfaces()
end
function UI.setBackground(color)
    custom.bg = color
    applyPalette()
    refreshSurfaces()
end
function UI.setBorder(color)
    custom.border = color
    applyPalette()
    refreshSurfaces()
end
function UI.setGradient(mode)
    gradMode = mode
    refreshSurfaces()
end
function UI.setRadius(value)
    radiusExtra = (tonumber(value) or 8) - 8
    refreshSurfaces()
end
function UI.setAccent(color)
    local old = THEME.accent
    custom.accent = color
    local new_ = color or DEFAULT_ACCENT
    THEME.accent = new_
    if old ~= new_ then
        for _, d in ipairs(gui:GetDescendants()) do
            pcall(function()
                if d:IsA("GuiObject") and d.BackgroundColor3 == old then d.BackgroundColor3 = new_ end
                if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.TextColor3 == old then
                    d.TextColor3 = new_
                end
                if d:IsA("UIStroke") and d.Color == old then d.Color = new_ end
            end)
        end
    end
    refreshSurfaces()
end
function UI.setFont(name)
    local set = FONTSETS[name]
    if not set then return end
    FONT.reg, FONT.bold = set[1], set[2]
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            d.Font = d:GetAttribute("sfb") and FONT.bold or FONT.reg
        end
    end
end
function UI.setAnim(mode)
    animLevel = (mode == "Desligadas") and 0 or (mode == "Suaves") and 1 or 2
end
function UI.setTheme(mode)
    themeMode = mode
    themeName = resolveTheme(mode)
    PALETTE = THEMES[themeName]
    TINT = PALETTE.tint
    glow2 = PALETTE.glow2
    DEFAULT_ACCENT = PALETTE.accent
    applyPalette()
    UI.setAccent(custom.accent)
end
UI.fontNames = FONT_NAMES

local function makeDraggable(target, handle, onTap)
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    handle.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging, moved = true, false
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    STATE.connect(UIS.InputChanged, function(input)
        if dragging and isMove(input) then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    if onTap then
        handle.Activated:Connect(function()
            if not moved then onTap() end
        end)
    end
end

local SIDE_W = 150
local win = new("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.68, 0.86),
    BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
}, gui)
round(win, 14)
local winStroke = outline(win, THEME.accent, 2)
skin(win, "bg")
local winBgGrad = new("UIGradient", { Rotation = 90 }, win)
local function paintWinGrad()
    winBgGrad.Color = ColorSequence.new(VGRAD_BOTTOM[themeName] or rgb(60, 28, 110), THEME.bg)
end
onStyle(function() paintWinGrad() end)
local winGlow = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.accent),
        ColorSequenceKeypoint.new(0.5, glow2),
        ColorSequenceKeypoint.new(1, THEME.accent),
    }),
}, winStroke)
local glowRings = {}
for _, cfg in ipairs({ { 5, 0.78 }, { 10, 0.88 }, { 16, 0.94 } }) do
    local ring = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, win)
    round(ring, 14)
    outline(ring, THEME.accent, cfg[1]).Transparency = cfg[2]
    table.insert(glowRings, ring)
end
onStyle(function(sf)
    local c = custom.border or THEME.accent
    winStroke.Color = c
    winGlow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c),
        ColorSequenceKeypoint.new(0.5, custom.border and c or glow2),
        ColorSequenceKeypoint.new(1, c),
    })
    winGlow.Enabled = sf
    for _, ring in ipairs(glowRings) do ring.Visible = sf end
end)
local glowClock = 0
STATE.connect(RunService.Heartbeat, function(dt)
    glowClock += dt
    if glowClock < 0.04 then return end
    glowClock = 0
    if animLevel == 2 and isSoft and win.Visible then winGlow.Rotation = (os.clock() * 40) % 360 end
end)
new("UISizeConstraint", { MinSize = Vector2.new(460, 280), MaxSize = Vector2.new(820, 500) }, win)
local winScale = new("UIScale", { Scale = 1 }, win)
local uiScaleValue = 1
local winOpen = true
local function showWindow(on)
    winOpen = on
    if animLevel == 0 then
        win.Visible = on
        winScale.Scale = uiScaleValue
        return
    end
    if on then
        winScale.Scale = uiScaleValue * 0.9
        win.Visible = true
        TweenService:Create(winScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = uiScaleValue }):Play()
    else
        TweenService:Create(winScale, TweenInfo.new(0.14), { Scale = uiScaleValue * 0.92 }):Play()
        task.delay(0.15, function()
            if not winOpen then
                win.Visible = false
                winScale.Scale = uiScaleValue
            end
        end)
    end
end
function UI.toggle() showWindow(not winOpen) end

local side = new("Frame", {
    Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundColor3 = THEME.side, BorderSizePixel = 0,
}, win)
round(side, 14)
skin(side, "side")
gradient(side, rgb(255, 255, 255), "side", 90)
local sideCover = new("Frame", {
    Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0),
    BackgroundColor3 = THEME.side, BorderSizePixel = 0,
}, side)
skin(sideCover, "side")
gradient(sideCover, rgb(255, 255, 255), "side", 90)
local sideEdge = new("Frame", {
    Size = UDim2.new(0, 2, 1, -30), Position = UDim2.new(1, -2, 0, 15),
    BackgroundColor3 = THEME.accent, BorderSizePixel = 0,
}, side)
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1),
    }),
}, sideEdge)
onStyle(function(s) sideEdge.Visible = s end)
local hint = label({
    Text = "", TextSize = 9, TextColor3 = THEME.sub, TextWrapped = true, Visible = false,
    Position = UDim2.new(0, 12, 1, -14), Size = UDim2.new(1, -16, 0, 1),
}, side)

local nav = new("ScrollingFrame", {
    Position = UDim2.new(0, 6, 0, 10), Size = UDim2.new(1, -12, 1, -20), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, side)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, nav)

local main = new("Frame", {
    Position = UDim2.new(0, SIDE_W, 0, 0), Size = UDim2.new(1, -SIDE_W, 1, 0), BackgroundTransparency = 1,
}, win)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Active = true,
}, main)
lineStroke(new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1 }, header))

local logoBadge = new("Frame", {
    Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 14, 0.5, -17),
    BackgroundColor3 = rgb(255, 255, 255),
}, header)
round(logoBadge, 10)
gradient(logoBadge, rgb(190, 130, 255), rgb(90, 40, 170), 45)
label({
    Text = "D", Font = FONT.bold, TextSize = 17, TextColor3 = rgb(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 1, 0),
}, logoBadge)
local titleKey = ""
local titleLabel = label({
    Text = "Daishyn", Font = FONT.bold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd,
    Position = UDim2.new(0, 56, 0, 9), Size = UDim2.new(0, 160, 0, 18),
}, header)
label({
    Text = "Volleyball Legends", TextSize = 10, TextColor3 = THEME.sub,
    Position = UDim2.new(0, 56, 0, 27), Size = UDim2.new(0, 160, 0, 14),
}, header)

local function headerButton(text, fromRight, y)
    local b = new("TextButton", {
        Text = text, Font = FONT.bold, TextSize = 14, TextColor3 = THEME.sub,
        Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, fromRight, 0, y or 8),
        BackgroundColor3 = THEME.btn, AutoButtonColor = false,
    }, header)
    round(b, 8)
    skin(b, "btn")
    return b
end
local closeBtn = headerButton("X", -32, 8)
local minBtn = headerButton("-", -62, 8)
closeBtn.Activated:Connect(function() showWindow(false) end)

local discordBtn = new("TextButton", {
    Text = "", Size = UDim2.new(0, 72, 0, 26), Position = UDim2.new(1, -144, 0, 8),
    BackgroundColor3 = rgb(255, 255, 255), AutoButtonColor = false,
}, header)
round(discordBtn, 8)
new("UIGradient", { Color = ColorSequence.new(rgb(114, 137, 218), rgb(71, 82, 196)) }, discordBtn)
new("ImageLabel", {
    Image = DISCORD_ICON, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -9),
    Size = UDim2.new(0, 18, 0, 18), ZIndex = 2,
}, discordBtn)
label({
    Text = "Discord", Font = FONT.bold, TextSize = 11, TextColor3 = rgb(255, 255, 255),
    Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -36, 1, 0),
}, discordBtn)
discordBtn.Activated:Connect(function()
    UI.call(function()
        local copied = discordJoin()
        UI.notify("Discord", string.format(tr(copied and "Convite copiado: %s" or "Não consegui copiar. Convite: %s"), DISCORD_URL))
    end)
end)

local accountAvatar = new("ImageLabel", {
    Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 14, 0.5, -17),
    BackgroundColor3 = THEME.btn, Image = "", AnchorPoint = Vector2.new(0, 0),
}, header)
round(accountAvatar, 17)
skin(accountAvatar, "btn")
local accountLabel = label({
    Text = "", Font = FONT.bold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
    Position = UDim2.new(0, 46, 0, 9), Size = UDim2.new(0, 110, 0, 16),
}, header)
local accountSub = label({
    Text = "@...", TextSize = 10, TextColor3 = THEME.sub, TextTruncate = Enum.TextTruncate.AtEnd,
    Position = UDim2.new(0, 46, 0, 27), Size = UDim2.new(0, 110, 0, 14),
}, header)
local accountHolder = new("Frame", {
    Size = UDim2.new(0, 160, 0, 36), Position = UDim2.new(1, -312, 0, 13), BackgroundTransparency = 1,
}, header)
accountAvatar.Parent = accountHolder
accountLabel.Parent = accountHolder
accountSub.Parent = accountHolder
accountAvatar.Position = UDim2.new(0, 0, 0.5, -17)
accountLabel.Position = UDim2.new(0, 42, 0, 1)
accountSub.Position = UDim2.new(0, 42, 0, 19)
task.spawn(function()
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and content then accountAvatar.Image = content end
end)
accountLabel.Text = LP.DisplayName
accountSub.Text = "@" .. LP.Name

local searchBox = new("TextBox", {
    Text = "", PlaceholderColor3 = THEME.sub, TextColor3 = THEME.text,
    Font = FONT.reg, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false, Position = UDim2.new(0, 56, 0, 44), Size = UDim2.new(0, 240, 0, 1),
    BackgroundTransparency = 1, Visible = false,
}, header)
searchBox.PlaceholderText = "Pesquisar opções..."

local pages = new("Frame", {
    Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 1, -62),
    BackgroundTransparency = 1, ClipsDescendants = true,
}, main)

do
    local sizeC = win:FindFirstChildOfClass("UISizeConstraint")
    local origMin, fullSize = sizeC.MinSize, nil
    local minimized = false
    minBtn.Activated:Connect(function()
        minimized = not minimized
        if minimized then
            fullSize = win.Size
            sizeC.MinSize = Vector2.new(origMin.X, 44)
            win.Size = UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 44)
        else
            sizeC.MinSize = origMin
            win.Size = fullSize
        end
        side.Visible = not minimized
        pages.Visible = not minimized
        minBtn.Text = minimized and "+" or "-"
    end)
end

makeDraggable(win, header, nil)

local pill = new("TextButton", {
    Text = "Daishyn", Font = FONT.bold, TextSize = 13, TextColor3 = THEME.text,
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), Size = UDim2.new(0, 140, 0, 30),
    BackgroundColor3 = THEME.bg, AutoButtonColor = false,
}, gui)
round(pill, 15)
surface(pill, "bg")
local pillStroke = outline(pill, THEME.accent, 2)
onStyle(function() pillStroke.Color = custom.border or THEME.accent end)
local pillRing = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, pill)
round(pillRing, 15)
outline(pillRing, THEME.accent, 5).Transparency = 0.8
onStyle(function(s) pillRing.Visible = s end)

makeDraggable(pill, pill, UI.toggle)

local bubble = new("TextButton", {
    Text = "", Font = FONT.bold, TextSize = 15, TextColor3 = THEME.text,
    AnchorPoint = Vector2.new(0.5, 0), Position = pill.Position, Size = UDim2.new(0, 46, 0, 46),
    BackgroundColor3 = THEME.bg, AutoButtonColor = false, Visible = false,
}, gui)
round(bubble, 23)
surface(bubble, "bg")
local bubbleFallback = label({
    Text = "D", Font = FONT.bold, TextSize = 18, TextColor3 = THEME.accent,
    TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 1, 0),
}, bubble)
local bubbleImage = new("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "rbxassetid://8942361531",
    ScaleType = Enum.ScaleType.Crop, ZIndex = 2,
}, bubble)
round(bubbleImage, 23)
gradient(bubble, rgb(255, 255, 255), "win", 90)
local bubbleStroke = outline(bubble, THEME.accent, 2)
onStyle(function() bubbleStroke.Color = custom.border or THEME.accent end)
local bubbleRing = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, bubble)
round(bubbleRing, 23)
outline(bubbleRing, THEME.accent, 6).Transparency = 0.78
onStyle(function(sf) bubbleRing.Visible = sf end)
makeDraggable(bubble, bubble, UI.toggle)
local openerMode = "Pílula"
local revealed = false
local function applyOpener()
    pill.Visible = revealed and openerMode == "Pílula"
    bubble.Visible = revealed and openerMode == "Bolha"
end
function UI.setOpener(mode)
    if mode == "Nenhum" then
        local b = binds["menu"]
        if not (b and b.key) then
            UI.notify("Aviso", tr("Defina a tecla do painel antes de usar Nenhum."))
            mode = "Pílula"
        end
    end
    if mode == "Bolha" and openerMode ~= "Bolha" then
        bubble.Position = pill.Position
    elseif mode == "Pílula" and openerMode == "Bolha" then
        pill.Position = bubble.Position
    end
    openerMode = mode
    applyOpener()
end
function UI.reveal()
    revealed = true
    winOpen = true
    win.Visible = true
    winScale.Scale = uiScaleValue
    applyOpener()
end
function UI.setPillTransparency(percent)
    local t = math.clamp((tonumber(percent) or 0) / 100, 0, 0.9)
    pill.BackgroundTransparency = t
    pillStroke.Transparency = t * 0.6
end
function UI.setBubbleTransparency(percent)
    local t = math.clamp((tonumber(percent) or 0) / 100, 0, 0.9)
    bubble.BackgroundTransparency = t
    bubbleImage.ImageTransparency = t
    bubbleFallback.TextTransparency = t
    bubbleStroke.Transparency = t * 0.6
end
win.Visible = false
winOpen = false
pill.Visible = false

local toast = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 96),
    Size = UDim2.new(0, 240, 0, 46), BackgroundColor3 = THEME.bg, Visible = false,
}, gui)
round(toast, 10)
skin(toast, "bg")
outline(toast, THEME.accent, 1)
local toastTitle = label({
    Text = "", Font = FONT.bold, TextSize = 13, TextColor3 = THEME.accent,
    Position = UDim2.new(0, 12, 0, 5), Size = UDim2.new(1, -24, 0, 16),
}, toast)
local toastBody = label({
    Text = "", TextSize = 12, TextColor3 = THEME.text, TextTruncate = Enum.TextTruncate.AtEnd,
    Position = UDim2.new(0, 12, 0, 23), Size = UDim2.new(1, -24, 0, 16),
}, toast)
local toastToken = 0
function UI.notify(title, content)
    toastToken += 1
    local mine_ = toastToken
    toastTitle.Text = tr(tostring(title or ""))
    toastBody.Text = tostring(content or "")
    toast.Visible = true
    task.delay(2.6, function()
        if toastToken == mine_ and toast.Parent then toast.Visible = false end
    end)
end
function UI.setNotifySide(sideName)
    if sideName == "Esquerda" then
        toast.AnchorPoint = Vector2.new(0, 0)
        toast.Position = UDim2.new(0, 12, 0, 96)
    elseif sideName == "Centro" then
        toast.AnchorPoint = Vector2.new(0.5, 0)
        toast.Position = UDim2.new(0.5, 0, 0, 94)
    else
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.Position = UDim2.new(1, -12, 0, 96)
    end
end
function UI.setScale(percent)
    uiScaleValue = math.clamp((tonumber(percent) or 100) / 100, 0.5, 1.5)
    winScale.Scale = uiScaleValue
end

local KEYNAMES = {
    RightControl = "RCtrl", LeftControl = "LCtrl", RightShift = "RShift", LeftShift = "LShift",
    Return = "Enter", Backspace = "Bksp", Space = "Espaço", RightAlt = "RAlt", LeftAlt = "LAlt",
}
local capturing = nil

local function makeHotkey(row, id, defaultKey, fn, rightOffset, alwaysShown, onResize)
    local b = { key = nil, fn = fn }
    binds[id] = b
    local shown = alwaysShown and true or false

    local plus
    if not alwaysShown then
        plus = new("TextButton", {
            Text = "+", Font = FONT.bold, TextSize = 14, TextColor3 = THEME.accent,
            Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -(rightOffset + 20), 0.5, -10),
            BackgroundColor3 = THEME.btn, AutoButtonColor = false,
        }, row)
        round(plus, 5)
        skin(plus, "btn")
        lineStroke(plus)
    end
    local chipRight = alwaysShown and rightOffset or (rightOffset + 24)
    local chip = new("TextButton", {
        Size = UDim2.new(0, 54, 0, 22), Position = UDim2.new(1, -(chipRight + 54), 0.5, -11),
        BackgroundColor3 = THEME.field, Text = "—", Font = FONT.reg, TextSize = 11,
        TextColor3 = THEME.sub, AutoButtonColor = false, Visible = shown,
    }, row)
    round(chip, 5)
    skin(chip, "field")
    lineStroke(chip)

    local function show()
        chip.Visible = shown
        if plus then plus.Text = shown and "-" or "+" end
        chip.Text = b.key and (KEYNAMES[b.key.Name] or b.key.Name) or "—"
        chip.TextColor3 = b.key and THEME.accent or THEME.sub
        if onResize then onResize(shown) end
    end
    local function setKey(name)
        b.key = nil
        if name and name ~= "" then
            local ok, kc = pcall(function() return Enum.KeyCode[name] end)
            if ok then b.key = kc end
            shown = true
        elseif not alwaysShown then
            shown = false
        end
        show()
    end
    local function startCapture()
        chip.Text = "..."
        capturing = { set = setKey, show = show }
    end

    if plus then
        plus.Activated:Connect(function()
            if shown then
                b.key = nil
                shown = false
                show()
            else
                shown = true
                show()
                startCapture()
            end
        end)
    end
    chip.Activated:Connect(startCapture)

    if defaultKey and defaultKey ~= "" then setKey(defaultKey) else show() end
    UI.controls[id .. "#key"] = {
        get = function() return b.key and b.key.Name or "" end,
        set = setKey,
    }
end

STATE.connect(UIS.InputBegan, function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if capturing then
        local cap = capturing
        capturing = nil
        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
            cap.set(nil)
        else
            cap.set(input.KeyCode.Name)
        end
        return
    end
    if processed or UIS:GetFocusedTextBox() then return end
    for _, b in pairs(binds) do
        if b.key and input.KeyCode == b.key then UI.call(b.fn) end
    end
end)

function UI.floatButton(text, index, onTap)
    local b = new("TextButton", {
        Text = text, Font = FONT.bold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0.22, index * 56, 0.78, -24),
        BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.15, AutoButtonColor = false,
        Visible = false,
    }, gui)
    round(b, 24)
    makeDraggable(b, b, function() UI.call(onTap) end)
    return { Show = function(_, v) b.Visible = v and true or false end }
end

local tabs, cats = {}, {}
local catCount, tabCount = 0, 0
local currentTab = nil
local rowsReg = {}
local searching = false

local searchPage = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
}, pages)
local searchHolder = new("Frame", {
    Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -22, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
}, searchPage)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, searchHolder)
pad(searchHolder, 0, 0, 0, 12)
local emptyLabel = label({
    TextSize = 12, TextColor3 = THEME.sub, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = -1, Visible = false,
}, searchHolder)
reg(emptyLabel, "Nenhuma opção encontrada.")

local function setTitle(key)
    titleKey = key
end

local function setCategory(cat, open)
    cat.open = open
    cat.chev.Text = open and "v" or ">"
    for _, b in ipairs(cat.items) do b.Visible = open end
end

function UI.select(name)
    if not tabs[name] then
        name = "Jogo"
        if not tabs[name] then
            for n in pairs(tabs) do name = n break end
        end
    end
    currentTab = name
    for n, t in pairs(tabs) do
        local on = (n == name)
        local show = on and not searching
        if show and not t.page.Visible and animLevel >= 1 then
            t.page.Position = UDim2.new(0, 0, 0, 12)
            TweenService:Create(t.page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Position = UDim2.new(0, 0, 0, 0) }):Play()
        elseif show then
            t.page.Position = UDim2.new(0, 0, 0, 0)
        end
        t.page.Visible = show
        t.btn.BackgroundTransparency = on and transp or 1
        t.btn.TextColor3 = on and THEME.text or THEME.sub
        t.bar.Visible = on
    end
    local t = tabs[name]
    if t and not t.cat.open then setCategory(t.cat, true) end
    if not searching then setTitle(name) end
end
function UI.refreshNav()
    if currentTab then UI.select(currentTab) end
end

local function applySearch()
    local q = string.lower((searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")))
    if q == "" then
        if searching then
            searching = false
            for _, r in ipairs(rowsReg) do r.row.Parent = r.page end
            searchPage.Visible = false
            emptyLabel.Visible = false
            if currentTab then UI.select(currentTab) end
        end
        return
    end
    searching = true
    for _, t in pairs(tabs) do t.page.Visible = false end
    searchPage.Visible = true
    setTitle("Resultados")
    local count = 0
    for _, r in ipairs(rowsReg) do
        if string.find(r.text, q, 1, true) then
            r.row.Parent = searchHolder
            count += 1
        else
            r.row.Parent = r.page
        end
    end
    emptyLabel.Visible = (count == 0)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

function UI.setLang(lang)
    UI.lang = (lang == "English") and "English" or "Português"
    for _, e in ipairs(langLabels) do
        if e.inst.Parent then e.inst.Text = tr(e.key) end
    end
    searchBox.PlaceholderText = tr("Pesquisar opções...")
    titleLabel.Text = tr(titleKey)
    for _, h in ipairs(langHooks) do pcall(h) end
end

local Tab = {}
Tab.__index = Tab
local G = {}
G.__index = G

function UI.tab(name, category, color)
    category = category or name
    local cat = cats[category]
    if not cat then
        catCount += 1
        cat = { order = catCount * 100, items = {}, open = true }
        cats[category] = cat
        local headBtn = new("TextButton", {
            Text = "", Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
            AutoButtonColor = false, LayoutOrder = cat.order,
        }, nav)
        local headLabel = label({
            Font = FONT.bold, TextSize = 12, TextColor3 = color or THEME.sub,
            Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -34, 1, 0),
        }, headBtn)
        reg(headLabel, category)
        cat.chev = label({
            Text = ">", TextSize = 12, TextColor3 = color or THEME.sub, TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 16, 1, 0),
        }, headBtn)
        headBtn.Activated:Connect(function() setCategory(cat, not cat.open) end)
    end

    tabCount += 1
    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, pages)
    local holder = new("Frame", {
        Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -22, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, page)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
    pad(holder, 0, 0, 0, 12)

    local btn = new("TextButton", {
        Text = "", Font = FONT.reg, TextSize = 13, TextColor3 = THEME.sub,
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = THEME.btn, BackgroundTransparency = 1, AutoButtonColor = false,
        LayoutOrder = cat.order + #cat.items + 1, Visible = cat.open,
    }, nav)
    reg(btn, name)
    round(btn, 8)
    surface(btn, "btn")
    pad(btn, 24, 0, 0, 0)
    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 0, 14), Position = UDim2.new(0, -16, 0.5, -7),
        BackgroundColor3 = color or THEME.accent, BorderSizePixel = 0, Visible = false,
    }, btn)
    round(bar, 2)
    table.insert(cat.items, btn)
    btn.Activated:Connect(function()
        if searching then searchBox.Text = "" end
        UI.select(name)
    end)

    tabs[name] = { page = page, btn = btn, bar = bar, cat = cat }
    return setmetatable({ page = page, holder = holder, idx = tabCount, gcount = 0 }, Tab)
end

function Tab:group(title)
    self.gcount += 1
    local base = self.idx * 100000 + self.gcount * 1000
    tlabel({
        TextSize = 12, TextColor3 = THEME.sub, Size = UDim2.new(1, 0, 0, self.gcount > 1 and 30 or 22),
        TextYAlignment = self.gcount > 1 and Enum.TextYAlignment.Bottom or Enum.TextYAlignment.Center,
        LayoutOrder = base,
    }, self.holder, title)
    return setmetatable({ card = self.holder, n = 0, base = base }, G)
end

local function both(s)
    return string.lower(tostring(s or "") .. " " .. tostring(UI.EN[s] or ""))
end

function G:_row(height, title, desc)
    self.n += 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = THEME.card, BorderSizePixel = 0,
        LayoutOrder = self.base + self.n,
    }, self.card)
    round(row, 8)
    cornerStyle(row, 8, 10)
    lineStroke(row)
    skin(row, "card")
    gradient(row, rgb(255, 255, 255), "card", 90)
    pad(row, 12, 5, 12, 5)
    row.MouseEnter:Connect(function()
        if animLevel >= 2 then tween(row, { BackgroundColor3 = THEME.card:Lerp(rgb(255, 255, 255), 0.06) }, 0.12) end
    end)
    row.MouseLeave:Connect(function()
        if animLevel >= 2 then tween(row, { BackgroundColor3 = THEME.card }, 0.12) end
    end)
    table.insert(rowsReg, { row = row, page = self.card, text = both(title) .. " " .. both(desc) })
    return row
end

local function register(o, get, set)
    if o.Id then UI.controls[o.Id] = { get = get, set = set } end
end

local function rowText(row, title, desc, rightPad)
    local t, d
    if desc then
        t = tlabel({
            TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(1, -rightPad, 0, 16),
        }, row, title)
        d = tlabel({
            TextSize = 10, TextColor3 = THEME.sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 0, 0, 17), Size = UDim2.new(1, -rightPad, 0, 24),
        }, row, desc)
    else
        t = tlabel({
            TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -rightPad, 1, 0),
        }, row, title)
    end
    return t, d
end

local function clickArea(row)
    return new("TextButton", {
        Text = "", Position = UDim2.new(0, -12, 0, -5), Size = UDim2.new(1, 24, 1, 10),
        BackgroundTransparency = 1,
    }, row)
end

function G:note(text)
    self.n += 1
    local l = label({
        TextSize = 11, TextColor3 = THEME.sub, TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = self.base + self.n,
    }, self.card)
    local obj = {}
    reg(l, text)
    function obj:SetText(t)
        l.Text = t
        for _, e in ipairs(langLabels) do
            if e.inst == l then e.key = t end
        end
    end
    return obj
end

function G:notice(date, version, text)
    self.n += 1
    local red = Color3.fromRGB(255, 84, 84)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = THEME.card,
        BorderSizePixel = 0, LayoutOrder = self.base + self.n,
    }, self.card)
    round(row, 8)
    cornerStyle(row, 8, 10)
    outline(row, red, 1)
    skin(row, "card")
    gradient(row, rgb(255, 255, 255), "card", 90)
    pad(row, 12, 8, 12, 8)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, row)
    label({
        Text = "Daishyn  •  " .. date .. "  •  v" .. version, Font = FONT.bold, TextSize = 12, TextColor3 = red,
        Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1,
    }, row)
    label({
        Text = text, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 2,
    }, row)
    table.insert(rowsReg, { row = row, page = self.card, text = string.lower(text .. " " .. date) })
end

function G:text(text)
    self.n += 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = THEME.card,
        BorderSizePixel = 0, LayoutOrder = self.base + self.n,
    }, self.card)
    round(row, 8)
    cornerStyle(row, 8, 10)
    lineStroke(row)
    skin(row, "card")
    gradient(row, rgb(255, 255, 255), "card", 90)
    pad(row, 12, 8, 12, 8)
    local l = label({
        Text = text, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
    }, row)
    table.insert(rowsReg, { row = row, page = self.card, text = string.lower(text) })
    return l
end

function G:toggle(o)
    local row = self:_row(o.Desc and 54 or 38, o.Title, o.Desc)
    local baseRight = 42 + (o.Hotkey and 26 or 0)
    local tlab, dlab = rowText(row, o.Title, o.Desc, baseRight)
    local click = clickArea(row)

    local track_ = new("Frame", {
        Size = UDim2.new(0, 34, 0, 18), Position = UDim2.new(1, -34, 0.5, -9),
        BackgroundColor3 = THEME.off, BorderSizePixel = 0,
    }, row)
    round(track_, 9)
    track(track_)
    local knob = new("Frame", {
        Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, track_)
    round(knob, 6)

    local state = o.Value and true or false
    local function paint(animate)
        local g1 = { BackgroundColor3 = state and THEME.accent or THEME.off }
        local g2 = { Position = state and UDim2.new(0, 19, 0.5, -6) or UDim2.new(0, 3, 0.5, -6) }
        if animate then
            tween(track_, g1)
            tween(knob, g2)
        else
            for k, v in pairs(g1) do track_[k] = v end
            for k, v in pairs(g2) do knob[k] = v end
        end
    end
    paint(false)

    local obj = {}
    function obj:Set(v)
        state = v and true or false
        paint(true)
        if o.Callback then UI.call(o.Callback, state) end
    end
    click.Activated:Connect(function() obj:Set(not state) end)

    if o.Hotkey and o.Id then
        makeHotkey(row, o.Id, o.Key, function() obj:Set(not state) end, 40, false, function(shown)
            local p = baseRight + (shown and 58 or 0)
            tlab.Size = UDim2.new(1, -p, tlab.Size.Y.Scale, tlab.Size.Y.Offset)
            if dlab then dlab.Size = UDim2.new(1, -p, 0, 24) end
        end)
    end
    register(o, function() return state end, function(v) obj:Set(v) end)
    return obj
end

function G:button(o)
    local row = self:_row(o.Desc and 54 or 38, o.Title, o.Desc)
    rowText(row, o.Title, o.Desc, 30)
    label({
        Text = ">", TextSize = 16, TextColor3 = THEME.accent, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(1, -18, 0, 0), Size = UDim2.new(0, 18, 1, 0),
    }, row)
    local click = clickArea(row)
    click.Activated:Connect(function()
        tween(row, { BackgroundColor3 = THEME.btn }, 0.08)
        task.delay(0.14, function()
            if row.Parent then tween(row, { BackgroundColor3 = THEME.card }, 0.14) end
        end)
        if o.Callback then UI.call(o.Callback) end
    end)
end

function G:keybind(o)
    local row = self:_row(o.Desc and 54 or 38, o.Title, o.Desc)
    rowText(row, o.Title, o.Desc, 66)
    makeHotkey(row, o.Id, o.Key, function()
        if o.Callback then o.Callback() end
    end, 0, true, nil)
end

function G:input(o)
    local row = self:_row(o.Desc and 54 or 38, o.Title, o.Desc)
    rowText(row, o.Title, o.Desc, 160)
    local box = new("TextBox", {
        Text = tostring(o.Value or ""), PlaceholderText = o.Placeholder or "", PlaceholderColor3 = THEME.sub,
        TextColor3 = THEME.text, Font = FONT.reg, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        Size = UDim2.new(0, 150, 0, 26), Position = UDim2.new(1, -150, 0.5, -13),
        BackgroundColor3 = THEME.field,
    }, row)
    round(box, 6)
    skin(box, "field")
    lineStroke(box)
    pad(box, 10, 0, 10, 0)
    box.FocusLost:Connect(function()
        if o.Callback then UI.call(o.Callback, box.Text) end
    end)
    local obj = {}
    function obj:Get() return box.Text end
    function obj:Set(v) box.Text = tostring(v or "") end
    register(o, function() return box.Text end, function(v)
        box.Text = tostring(v or "")
        if o.Callback then UI.call(o.Callback, box.Text) end
    end)
    return obj
end

function G:slider(o)
    local innerH = o.Desc and 58 or 44
    local row = self:_row(innerH + 10, o.Title, o.Desc)
    tlabel({
        TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -62, 0, 18),
    }, row, o.Title)
    if o.Desc then
        tlabel({
            TextSize = 10, TextColor3 = THEME.sub, TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 0, 0, 18), Size = UDim2.new(1, 0, 0, 14),
        }, row, o.Desc)
    end

    local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
    local typeStep = o.TypeStep or step
    local decimals = (step < 1 or typeStep < 1) and 2 or 0
    local value = min

    local valueBox = new("TextBox", {
        Text = "", Font = FONT.reg, TextSize = 11, TextColor3 = THEME.accent,
        Size = UDim2.new(0, 54, 0, 18), Position = UDim2.new(1, -54, 0, 0),
        BackgroundColor3 = THEME.field, ClearTextOnFocus = false,
    }, row)
    round(valueBox, 4)
    skin(valueBox, "field")
    lineStroke(valueBox)

    local track_ = new("Frame", {
        Position = UDim2.new(0, 0, 0, innerH - 10), Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = THEME.off, BorderSizePixel = 0,
    }, row)
    round(track_, 3)
    track(track_)
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = THEME.accent, BorderSizePixel = 0,
    }, track_)
    round(fill, 3)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, fill)
    round(knob, 6)

    local function fmt(v)
        if o.Format then return o.Format(v) end
        if decimals > 0 then
            local s = string.format("%." .. decimals .. "f", v)
            s = s:gsub("0+$", ""):gsub("%.$", "")
            return s
        end
        return tostring(v)
    end
    local function setValue(v, fire, stepOverride)
        local st = stepOverride or step
        v = math.clamp(math.floor(v / st + 0.5) * st, min, max)
        v = tonumber(string.format("%.4f", v))
        value = v
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valueBox.Text = fmt(v)
        if fire and o.Callback then UI.call(o.Callback, v) end
    end
    setValue(o.Value or min, false)

    valueBox.FocusLost:Connect(function()
        local n = tonumber((valueBox.Text:gsub(",", ".")))
        if n then
            setValue(n, true, typeStep)
        else
            valueBox.Text = fmt(value)
        end
    end)

    local hit = new("TextButton", {
        Text = "", Position = UDim2.new(0, 0, 0, innerH - 26), Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
    }, row)
    local dragging = false
    local function scroller()
        local p = row.Parent
        while p and not p:IsA("ScrollingFrame") do p = p.Parent end
        return p
    end
    local function fromInput(pos)
        local a = math.clamp((pos.X - track_.AbsolutePosition.X) / math.max(track_.AbsoluteSize.X, 1), 0, 1)
        setValue(min + a * (max - min), true)
    end
    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            local sp = scroller()
            if sp then sp.ScrollingEnabled = false end
            fromInput(input.Position)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if sp then sp.ScrollingEnabled = true end
                end
            end)
        end
    end)
    STATE.connect(UIS.InputChanged, function(input)
        if dragging and isMove(input) then fromInput(input.Position) end
    end)

    local obj = {}
    function obj:Set(v) setValue(v, true) end
    register(o, function() return value end, function(v) setValue(tonumber(v) or min, true, typeStep) end)
    return obj
end

function G:dropdown(o)
    local options = o.Options or {}
    local value = o.Value
    local fav = {}
    local topH = o.Desc and 44 or 28
    local HEAD = topH + 10
    local OPEN_H = topH + 172

    local row = self:_row(HEAD, o.Title, o.Desc)
    row.ClipsDescendants = true
    rowText(row, o.Title, o.Desc, 160)

    local head = new("TextButton", {
        Text = "", Size = UDim2.new(0, 150, 0, 26), Position = UDim2.new(1, -150, 0, (topH - 26) / 2),
        BackgroundColor3 = THEME.field, AutoButtonColor = false,
    }, row)
    round(head, 6)
    skin(head, "field")
    lineStroke(head)
    local cur = label({
        Text = tr(tostring(value or "-")), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -30, 1, 0),
    }, head)
    local arrow = label({
        Text = "v", TextSize = 11, TextColor3 = THEME.accent, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 16, 1, 0),
    }, head)

    local search = new("TextBox", {
        Text = "", PlaceholderColor3 = THEME.sub, TextColor3 = THEME.text,
        Font = FONT.reg, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Position = UDim2.new(0, 0, 0, topH + 8), Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = THEME.field, Visible = false,
    }, row)
    search.PlaceholderText = tr("Pesquisar...")
    round(search, 6)
    skin(search, "field")
    lineStroke(search)
    pad(search, 10, 0, 10, 0)

    local list = new("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, topH + 38), Size = UDim2.new(1, 0, 0, 120),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.accent, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, row)
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local items = {}
    local obj = {}

    local function paintOptions()
        for name, it in pairs(items) do
            local sel = (name == value)
            it.name.TextColor3 = sel and THEME.accent or THEME.text
            it.frame.BackgroundColor3 = sel and THEME.btn or THEME.field
            if it.star then
                it.star.Text = fav[name] and "★" or "☆"
                it.star.TextColor3 = fav[name] and Color3.fromRGB(255, 205, 80) or THEME.sub
            end
        end
    end
    local function reorder()
        for i, name in ipairs(options) do
            local it = items[name]
            if it then it.frame.LayoutOrder = (fav[name] and 0 or 100000) + i end
        end
    end
    local function filter()
        local q = string.lower(search.Text)
        for _, name in ipairs(options) do
            local it = items[name]
            if it then
                local hay = string.lower(name .. " " .. tr(name))
                it.frame.Visible = (q == "") or (string.find(hay, q, 1, true) ~= nil)
            end
        end
    end
    local open = false
    local function setOpen(v)
        open = v
        search.Visible = v
        list.Visible = v
        arrow.Text = v and "^" or "v"
        row.Size = UDim2.new(1, 0, 0, v and OPEN_H or HEAD)
        if v then
            search.Text = ""
            filter()
        end
    end
    local function pick(name, fire)
        value = name
        cur.Text = tr(tostring(name))
        paintOptions()
        if fire and o.Callback then UI.call(o.Callback, name) end
    end
    local function rebuild()
        for _, it in pairs(items) do it.frame:Destroy() end
        items = {}
        for i, name in ipairs(options) do
            local frame = new("Frame", {
                Size = UDim2.new(1, -6, 0, 26), BackgroundColor3 = THEME.field, BorderSizePixel = 0,
                LayoutOrder = i,
            }, list)
            round(frame, 5)
            track(frame)
            local nameBtn = new("TextButton", {
                Text = tr(name), Font = FONT.reg, TextSize = 12, TextColor3 = THEME.text,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Size = UDim2.new(1, o.Favorites and -26 or 0, 1, 0), BackgroundTransparency = 1,
                AutoButtonColor = false,
            }, frame)
            pad(nameBtn, 8, 0, 4, 0)
            nameBtn.Activated:Connect(function()
                pick(name, true)
                setOpen(false)
            end)
            local star
            if o.Favorites then
                star = new("TextButton", {
                    Text = "☆", Font = FONT.bold, TextSize = 15, TextColor3 = THEME.sub,
                    Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1, AutoButtonColor = false,
                }, frame)
                star.Activated:Connect(function()
                    fav[name] = (not fav[name]) or nil
                    paintOptions()
                    reorder()
                    if o.Id and UI.favStore then UI.favStore.set(o.Id, obj:GetFavorites()) end
                end)
            end
            items[name] = { frame = frame, name = nameBtn, star = star }
        end
        paintOptions()
        reorder()
        filter()
    end

    head.Activated:Connect(function() setOpen(not open) end)
    search:GetPropertyChangedSignal("Text"):Connect(filter)
    rebuild()
    onStyle(function() paintOptions() end)

    table.insert(langHooks, function()
        cur.Text = tr(tostring(value or "-"))
        search.PlaceholderText = tr("Pesquisar...")
        for name, it in pairs(items) do it.name.Text = tr(name) end
    end)

    function obj:Set(v)
        value = v
        cur.Text = tr(tostring(v))
        paintOptions()
    end
    function obj:Get() return value end
    function obj:SetOptions(list2)
        options = list2
        rebuild()
    end
    function obj:GetFavorites()
        local out = {}
        for name in pairs(fav) do table.insert(out, name) end
        table.sort(out)
        return out
    end
    function obj:SetFavorites(list2)
        fav = {}
        if type(list2) ~= "table" then list2 = {} end
        for _, n in ipairs(list2) do fav[n] = true end
        paintOptions()
        reorder()
    end
    register(o, function() return value end, function(v)
        if v ~= nil then pick(v, true) end
    end)
    if o.Id and o.Favorites then
        UI.controls[o.Id .. "#fav"] = {
            get = function() return obj:GetFavorites() end,
            set = function(v) obj:SetFavorites(v) end,
        }
        if UI.favStore then obj:SetFavorites(UI.favStore.get(o.Id)) end
    end
    return obj
end

function G:weights(o)
    local entries = {}
    local function r1(x) return math.floor(x * 10 + 0.5) / 10 end

    self.n += 1
    local listFrame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = THEME.card,
        BorderSizePixel = 0, LayoutOrder = self.base + self.n,
    }, self.card)
    round(listFrame, 8)
    cornerStyle(listFrame, 8, 10)
    lineStroke(listFrame)
    skin(listFrame, "card")
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
    pad(listFrame, 12, 8, 12, 8)

    local totalLabel = label({
        TextSize = 11, TextColor3 = THEME.sub, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 100000,
    }, listFrame)
    local emptyNote = label({
        TextSize = 11, TextColor3 = THEME.sub, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1,
    }, listFrame)
    reg(emptyNote, "Lista vazia: sorteia entre todos.")

    local obj = {}
    local frames = {}

    local function changed()
        if o.Callback then
            local copy = {}
            for _, e in ipairs(entries) do table.insert(copy, { name = e.name, pct = e.pct }) end
            UI.call(o.Callback, copy)
        end
    end
    local function equalize()
        local n = #entries
        if n == 0 then return end
        local base = math.floor(1000 / n) / 10
        for _, e in ipairs(entries) do e.pct = base end
        entries[n].pct = r1(entries[n].pct + (100 - base * n))
    end
    local function normalize()
        local sum = 0
        for _, e in ipairs(entries) do sum += e.pct end
        if #entries == 0 then return end
        if sum <= 0 then equalize() return end
        local acc = 0
        for i, e in ipairs(entries) do
            if i < #entries then
                e.pct = r1(e.pct * 100 / sum)
                acc += e.pct
            else
                e.pct = r1(100 - acc)
            end
        end
    end
    local function render()
        for _, f in ipairs(frames) do f:Destroy() end
        frames = {}
        emptyNote.Visible = (#entries == 0)
        local sum = 0
        for i, e in ipairs(entries) do
            sum += e.pct
            local f = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 10 + i }, listFrame)
            label({
                Text = tr(e.name), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
                Size = UDim2.new(1, -96, 1, 0),
            }, f)
            local box = new("TextBox", {
                Text = tostring(e.pct), Font = FONT.reg, TextSize = 11, TextColor3 = THEME.accent,
                Size = UDim2.new(0, 46, 0, 20), Position = UDim2.new(1, -88, 0.5, -10),
                BackgroundColor3 = THEME.field, ClearTextOnFocus = false,
            }, f)
            round(box, 4)
            skin(box, "field")
            lineStroke(box)
            label({
                Text = "%", TextSize = 11, TextColor3 = THEME.sub,
                Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 12, 1, 0),
            }, f)
            local rm = new("TextButton", {
                Text = "-", Font = FONT.bold, TextSize = 14, TextColor3 = THEME.warn,
                Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -22, 0.5, -10),
                BackgroundColor3 = THEME.btn, AutoButtonColor = false,
            }, f)
            round(rm, 4)
            skin(rm, "btn")
            box.FocusLost:Connect(function()
                local n = tonumber((box.Text:gsub(",", ".")))
                if n then e.pct = r1(math.clamp(n, 0, 100)) end
                render()
                changed()
            end)
            rm.Activated:Connect(function()
                for k, x in ipairs(entries) do
                    if x == e then table.remove(entries, k) break end
                end
                normalize()
                render()
                changed()
            end)
            table.insert(frames, f)
        end
        local ok = math.abs(sum - 100) < 0.05 or #entries == 0
        totalLabel.Text = string.format("%s: %s%%", tr("Total"), tostring(r1(sum)))
        totalLabel.TextColor3 = ok and THEME.sub or THEME.warn
    end
    table.insert(langHooks, render)

    function obj:Add(name)
        for _, e in ipairs(entries) do
            if e.name == name then return false end
        end
        table.insert(entries, { name = name, pct = 0 })
        equalize()
        render()
        changed()
        return true
    end
    function obj:Normalize()
        normalize()
        render()
        changed()
    end
    function obj:Clear()
        entries = {}
        render()
        changed()
    end
    function obj:Get()
        local copy = {}
        for _, e in ipairs(entries) do table.insert(copy, { name = e.name, pct = e.pct }) end
        return copy
    end
    function obj:Set(list)
        entries = {}
        if type(list) ~= "table" then list = {} end
        for _, e in ipairs(list) do
            if type(e) == "table" and e.name then
                table.insert(entries, { name = tostring(e.name), pct = tonumber(e.pct) or 0 })
            end
        end
        render()
        changed()
    end

    render()
    register(o, function() return obj:Get() end, function(v) obj:Set(v) end)
    return obj
end

function UI.setHint(text) hint.Text = text end
UI.win = win

end

_G.DaishynUI = UI
_G.__DaishynUI = UI

local RS = game:GetService("ReplicatedStorage")

local function path(root, ...)
    local cur = root
    for _, n in ipairs({ ... }) do
        if not cur then return nil end
        cur = cur:FindFirstChild(n)
    end
    return cur
end

local Services    = path(RS, "Packages", "_Index", "sleitnick_knit@1.7.0", "knit", "Services")
local HitGround   = path(Services, "BallService", "RE", "HitGround")
local OnFlashCard = path(Services, "PlayerCardService", "RE", "OnFlashCard")
local Assets      = RS:FindFirstChild("Assets")

local Cfg = {
    Effect = "SupernovaScoreEffect", EffectOn = false, EffectRandom = false,
    Ball   = "ClassicBall",          BallOn   = false, BallRandom   = false,
    Jersey = "DragonTuxedoJersey",   JerseyOn = false,
    Card   = "UltimateChampionPlayerCard", CardOn = false, CardRandom = false,
    Name   = "Daishyn",                ProtectOn = false,
}

local function pick(list)
    if #list > 0 then return list[math.random(1, #list)] end
    return nil
end
local function plainFind(s, sub)
    return string.find(string.upper(s), string.upper(sub), 1, true) ~= nil
end
local function esc(s) return (s:gsub("%p", "%%%0")) end
local function escRepl(s) return (s:gsub("%%", "%%%%")) end
local function notify(title, content)
    if UI and UI.notify then pcall(UI.notify, title, UI.tr(content or "")) end
end

local function listEffects()
    local out = {}
    local folder = path(Assets, "ScoreEffect")
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("ModuleScript") then table.insert(out, v.Name) end
        end
    end
    local fx = path(Assets, "Effects")
    if fx then
        for _, n in ipairs({ "GroundHit1", "GroundHit2", "SupernovaScoreEffect" }) do
            if fx:FindFirstChild(n) then table.insert(out, n) end
        end
    end
    table.sort(out)
    if #out == 0 then out = { "SupernovaScoreEffect", "GroundHit1", "GroundHit2" } end
    return out
end

local function listBalls()
    local out = {}
    local folder = path(Assets, "Ball")
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("Model") then table.insert(out, v.Name) end
        end
    end
    table.sort(out)
    if #out == 0 then out = { "ClassicBall", "ExtremeBall", "MediumBall" } end
    return out
end

local function listCards()
    local out = {}
    local ent = path(RS, "Content", "Item", "Entities")
    if ent then
        for _, v in ipairs(ent:GetChildren()) do
            if v:IsA("ModuleScript") and v.Name:match("Card") then table.insert(out, v.Name) end
        end
    end
    table.sort(out)
    if #out == 0 then out = { "ContentCreatorPlayerCard", "UltimateChampionPlayerCard", "ProPlayerCard" } end
    return out
end

local function listJerseys()
    local out = {}
    pcall(function()
        local item = require(path(RS, "Content", "Item"))
        local ent = path(RS, "Content", "Item", "Entities")
        if ent and item and item.Type then
            for _, v in ipairs(ent:GetChildren()) do
                if v:IsA("ModuleScript") then
                    local ok, m = pcall(require, v)
                    if ok and type(m) == "table" and m.Type == item.Type.Jersey then
                        table.insert(out, tostring(m.Id or v.Name))
                    end
                end
            end
        end
    end)
    if #out == 0 then
        local j = path(Assets, "Jersey")
        if j then
            for _, v in ipairs(j:GetChildren()) do table.insert(out, v.Name) end
        end
    end
    table.sort(out)
    if #out == 0 then out = { "DragonTuxedoJersey" } end
    return out
end

local effects, balls, cards, jerseys = listEffects(), listBalls(), listCards(), listJerseys()
local function firstOr(list, want) return table.find(list, want) and want or list[1] end
Cfg.Effect = firstOr(effects, Cfg.Effect)
Cfg.Ball   = firstOr(balls, Cfg.Ball)
Cfg.Card   = firstOr(cards, Cfg.Card)
Cfg.Jersey = firstOr(jerseys, Cfg.Jersey)

Cfg.EffectWeights = {}
local function pickEffect()
    local list = Cfg.EffectWeights
    if type(list) == "table" and #list > 0 then
        local total = 0
        for _, e in ipairs(list) do total += math.max(tonumber(e.pct) or 0, 0) end
        if total > 0 then
            local r, acc = math.random() * total, 0
            for _, e in ipairs(list) do
                acc += math.max(tonumber(e.pct) or 0, 0)
                if r <= acc then return e.name end
            end
            return list[#list].name
        end
    end
    return pick(effects)
end

local function hitIsMine(args)
    local c = args[6]
    if typeof(c) == "Instance" then
        local p = Players:GetPlayerFromCharacter(c)
        if p then return p == LP end
    end
    for i = 1, args.n do
        if tostring(args[i]) == LP.Name then return true end
    end
    return false
end

local FX = { hit = false, hitAt = 0, busy = false, selfFiring = false }

local function fxFire(position)
    if FX.busy or not FX.hit or os.clock() - FX.hitAt > 4 then return end
    if not (Cfg.EffectOn or Cfg.EffectRandom) or not firesignal or not HitGround then return end
    FX.busy = true

    local effect = Cfg.Effect
    if Cfg.EffectRandom then effect = pickEffect() or effect end

    local strong = true
    if effect == "GroundHit1" or effect == "GroundHit2" then
        strong = (effect == "GroundHit2")
        effect = nil
    end

    local char = workspace:FindFirstChild(LP.Name) or LP.Character
    FX.selfFiring = true
    pcall(firesignal, HitGround.OnClientEvent, position, strong, false, 5, effect, char,
        Vector3.new(-0.0000020885916001134, 1, -0.000004710930170404))
    FX.selfFiring = false

    task.wait(0.5)
    FX.busy = false
    FX.hit = false
end

local fxConns = {}
local function fxUpdate()
    local want = (Cfg.EffectOn or Cfg.EffectRandom) and HitGround ~= nil
    if want and #fxConns == 0 then
        fxConns[1] = HitGround.OnClientEvent:Connect(function(...)
            if FX.selfFiring then return end
            FX.hit = hitIsMine(table.pack(...))
            FX.hitAt = os.clock()
        end)
        fxConns[2] = workspace.DescendantAdded:Connect(function(d)
            if d.Name == "HitIndicator" and d:IsA("BasePart") and d.Color == Color3.fromRGB(0, 255, 0) then
                fxFire(d.Position)
            end
        end)
        fxConns[3] = workspace.DescendantRemoving:Connect(function(d)
            if d.Name == "HitIndicator" then
                FX.busy = false
                FX.hit = false
            end
        end)
    elseif not want and #fxConns > 0 then
        for _, c in ipairs(fxConns) do c:Disconnect() end
        fxConns = {}
        FX.hit, FX.busy = false, false
    end
end
STATE.onCleanup(function()
    for _, c in ipairs(fxConns) do c:Disconnect() end
    fxConns = {}
end)

local Prot = { notif = {}, loop = nil, char = nil, last = 0 }

local function protNametag()
    local char = LP.Character
    local tag = char and char:FindFirstChild("Nametag")
    local lbl = tag and tag:FindFirstChild("PlayerName")
    if lbl and lbl:IsA("TextLabel") then lbl.Text = Cfg.Name end
end

local function protReplace(label)
    if not label:IsA("TextLabel") then return end
    local t = label.Text or ""
    if string.find(t, LP.Name, 1, true) then
        label.Text = string.gsub(t, esc(LP.Name), escRepl(Cfg.Name))
    end
end

local function protCard()
    local gui = LP:FindFirstChild("PlayerGui")
    local persistent = path(gui, "Interface", "Persistent")
    if not persistent then return end
    for _, f in ipairs(persistent:GetChildren()) do
        if f.Name == "FlashPlayerCardFrame" then
            local u = f:FindFirstChild("Username", true)
            if u and u:IsA("TextLabel") and plainFind(u.Text or "", LP.Name) then
                u.Text = Cfg.Name
            end
        end
    end
end

local function protDisconnectNotifs()
    for _, c in ipairs(Prot.notif) do pcall(function() c:Disconnect() end) end
    Prot.notif = {}
end

local function protNotifications()
    protDisconnectNotifs()
    if not Cfg.ProtectOn then return end
    local notes = path(LP:FindFirstChild("PlayerGui"), "Interface", "Persistent", "Notifications")
    if not notes then return end
    local function handle(inst)
        local lbl = inst:FindFirstChild("TextLabel")
        if not lbl then
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") then lbl = d break end
            end
        end
        if lbl then protReplace(lbl) end
    end
    for _, c in ipairs(notes:GetChildren()) do handle(c) end
    table.insert(Prot.notif, notes.ChildAdded:Connect(handle))
    table.insert(Prot.notif, notes.DescendantAdded:Connect(protReplace))
end

local function setProtect(on)
    Cfg.ProtectOn = on and true or false
    protDisconnectNotifs()
    if Prot.loop then Prot.loop:Disconnect() Prot.loop = nil end
    if Prot.char then Prot.char:Disconnect() Prot.char = nil end

    if Cfg.ProtectOn then
        protNametag()
        protNotifications()
        Prot.loop = RunService.Heartbeat:Connect(function()
            protCard()
            if os.clock() - Prot.last > 0.25 then
                Prot.last = os.clock()
                protNametag()
            end
        end)
        Prot.char = LP.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Cfg.ProtectOn then
                protNametag()
                protNotifications()
            end
        end)
    else
        local char = LP.Character
        local tag = char and char:FindFirstChild("Nametag")
        local lbl = tag and tag:FindFirstChild("PlayerName")
        if lbl and lbl:IsA("TextLabel") then lbl.Text = LP.Name end
    end
end
STATE.onCleanup(function() setProtect(false) end)

local Ball = { clones = {}, saved = {} }

local function ballRestoreOne(model)
    local c = Ball.clones[model]
    if c then c:Destroy() Ball.clones[model] = nil end
    local s = Ball.saved[model]
    if s then
        for inst, d in pairs(s) do
            if inst.Parent then pcall(function() inst[d.field] = d.value end) end
        end
        Ball.saved[model] = nil
    end
end

local function ballRestoreAll()
    local list = {}
    for m in pairs(Ball.clones) do table.insert(list, m) end
    for m in pairs(Ball.saved) do table.insert(list, m) end
    for _, m in ipairs(list) do ballRestoreOne(m) end
end

local function ballApply(model)
    local folder = path(Assets, "Ball")
    local template = folder and folder:FindFirstChild(Cfg.Ball)
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not template or not part then return end

    ballRestoreOne(model)

    local saved = {}
    local function hide(inst, field, value)
        saved[inst] = { field = field, value = inst[field] }
        inst[field] = value
    end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            hide(d, "Transparency", 1)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            hide(d, "Transparency", 1)
        elseif d:IsA("Trail") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light")
            or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
            hide(d, "Enabled", false)
        end
    end
    Ball.saved[model] = saved

    local clone = template:Clone()
    clone.Name = "DaishynBall"
    clone.Parent = model

    local parts = {}
    if clone:IsA("BasePart") then parts[#parts + 1] = clone end
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BasePart") then parts[#parts + 1] = d end
    end

    local main = clone:IsA("Model") and clone.PrimaryPart or nil
    if not main then
        local best
        for _, p in ipairs(parts) do
            local s = p.Size
            local score = s.X * s.Y * s.Z
            local cubic = math.abs(s.X - s.Y) < 0.5 and math.abs(s.Y - s.Z) < 0.5
            if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
                score = score * 6
            elseif cubic then
                score = score * 3
            end
            if not best or score > best then main = p best = score end
        end
    end
    if main then
        local rel = clone:GetPivot():ToObjectSpace(main.CFrame)
        clone:PivotTo(part.CFrame * rel:Inverse())
    else
        clone:PivotTo(part.CFrame)
    end

    for _, p in ipairs(parts) do
        p.Anchored = false
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Massless = true
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part
        weld.Part1 = p
        weld.Parent = p
    end

    Ball.clones[model] = clone
end

local function ballApplyAll()
    ballRestoreAll()
    if not (Cfg.BallOn or Cfg.BallRandom) then return end
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m.Name:match("^CLIENT_BALL_") then
            pcall(ballApply, m)
        end
    end
end

STATE.onCleanup(ballRestoreAll)

local Jersey = { saved = setmetatable({}, { __mode = "k" }), team = nil }

local function jerseyClear(char)
    for _, v in ipairs(char:GetChildren()) do
        if v.Name == "JerseyFront" or v.Name == "JerseyBack" or v.Name == "_jerseyInstances"
            or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
            v:Destroy()
        end
    end
end

local function jerseyRestore()
    local char = LP.Character
    local saved = char and Jersey.saved[char]
    Jersey.team = nil
    if not saved then return end
    jerseyClear(char)
    for _, item in ipairs(saved) do
        local c = item:Clone()
        if c:IsA("SurfaceGui") then c.Adornee = char:FindFirstChild("UpperTorso") end
        c.Parent = char
    end
    Jersey.saved[char] = nil
end

local function jerseyApply()
    local char = LP.Character
    if not char or not char:FindFirstChild("UpperTorso") then return false end
    local jerseyAssets = path(Assets, "Jersey")
    if not jerseyAssets then return false end

    if not Jersey.saved[char] then
        local keep = {}
        for _, v in ipairs(char:GetChildren()) do
            if v.Name == "JerseyFront" or v.Name == "JerseyBack" or v:IsA("Clothing") or v:IsA("ShirtGraphic") then
                table.insert(keep, v:Clone())
            end
        end
        Jersey.saved[char] = keep
    end

    local function findTeam()
        local shirt = char:FindFirstChildOfClass("Shirt")
        if not shirt then return nil end
        for _, group in ipairs(jerseyAssets:GetChildren()) do
            for _, team in ipairs(group:GetChildren()) do
                local s = team:FindFirstChild("Shirt")
                if s and s:IsA("Shirt") and s.ShirtTemplate == shirt.ShirtTemplate then
                    return team.Name
                end
            end
        end
        return nil
    end

    local okReq, tool = pcall(require, path(RS, "Tools", "Jersey"))
    if not okReq or type(tool) ~= "table" or not tool.set then return false end

    Jersey.team = Jersey.team or findTeam()
    local ok, err = pcall(tool.set, {
        Player = LP, Character = char, Id = Cfg.Jersey, TeamName = Jersey.team,
    })
    if not ok then
        warn("[Daishyn] jersey apply failed: " .. tostring(err))
        return false
    end
    Jersey.team = Jersey.team or findTeam()
    return true
end

STATE.connect(LP.CharacterAdded, function(char)
    Jersey.team = nil
    if char:WaitForChild("UpperTorso", 10) and Cfg.JerseyOn and mine() then
        task.wait(1)
        if Cfg.JerseyOn and mine() then jerseyApply() end
    end
end)
STATE.onCleanup(function() pcall(jerseyRestore) end)

local Card = { conn = nil, firedFor = nil, busy = false }

local function cardFire()
    if Card.busy or not OnFlashCard or not firesignal then return end
    Card.busy = true
    pcall(firesignal, OnFlashCard.OnClientEvent, {
        PlayerCardItemId = Cfg.Card,
        Context = { Custom = {}, PlacementId = "ScoredPoint" },
        Player = LP,
    })
    task.wait(0.3)
    Card.busy = false
end

local function cardHandle(frame)
    task.wait(0.1)
    if Card.busy or not frame.Parent or not (Cfg.CardOn or Cfg.CardRandom) then return end
    local u = frame:FindFirstChild("Username", true)
    if not (u and u:IsA("TextLabel")) then return end
    local t = u.Text or ""
    local isMine = plainFind(t, LP.Name) or (Cfg.ProtectOn and plainFind(t, Cfg.Name))
    if not isMine or Card.firedFor == frame then return end

    if Cfg.CardRandom then
        local c = pick(cards)
        if c then
            Cfg.Card = c
            notify("Player Card", UI.trf("Aleatório: %s", c))
        end
    end
    Card.firedFor = frame
    frame:Destroy()
    task.wait(0.1)
    cardFire()
end

local function cardRefresh()
    if Card.conn then Card.conn:Disconnect() Card.conn = nil end
    Card.firedFor = nil
    if not (Cfg.CardOn or Cfg.CardRandom) then return end
    task.spawn(function()
        local gui = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
        local iface = gui:WaitForChild("Interface", 10)
        local persistent = iface and iface:WaitForChild("Persistent", 10)
        if not persistent or not (Cfg.CardOn or Cfg.CardRandom) or not mine() then return end
        if Card.conn then Card.conn:Disconnect() end
        Card.conn = persistent.ChildAdded:Connect(function(ch)
            if ch.Name == "FlashPlayerCardFrame" then task.spawn(cardHandle, ch) end
        end)
    end)
end
STATE.onCleanup(function()
    if Card.conn then Card.conn:Disconnect() Card.conn = nil end
end)

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local function rnd()
    return string.char(math.random(97, 122), math.random(97, 122), math.random(97, 122))
        .. tostring(math.random(100000, 999999))
end

Cfg.MaxCharge, Cfg.MaxServe, Cfg.LeadFeet, Cfg.ESP, Cfg.AntiLag = false, false, false, false, false

local Interact = path(Services, "BallService", "RF", "Interact")
local Serve = path(Services, "GameService", "RF", "Serve")
local Hook = { installed = false }

local function installHook()
    if Hook.installed then return true end
    if not (getrawmetatable and setreadonly and getnamecallmethod) then
        notify("Aviso", "Seu executor não suporta hooks.")
        return false
    end
    local ok, err = pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        local wrap = newcclosure or function(f) return f end
        mt.__namecall = wrap(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" then
                if Cfg.MaxCharge and self == Interact then
                    local a = ...
                    if type(a) == "table" and a.Move == "Spike" then
                        a.Charge = 1
                        a.SpecialCharge = 1
                        a.HoldDuration = 1
                        if type(a.CustomClient) == "table" then
                            a.CustomClient.HoldDuration = 1
                        else
                            a.CustomClient = { HoldDuration = 1 }
                        end
                    end
                elseif Cfg.MaxServe and self == Serve then
                    local args = { ... }
                    args[2] = 5
                    return old(self, unpack(args))
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
    if not ok then
        warn("[Daishyn] hook falhou: " .. tostring(err))
        return false
    end
    Hook.installed = true
    return true
end

local HB = { on = false, size = 5, color = Color3.fromRGB(255, 165, 0), transp = 0.3, name = rnd() }
local HB_COLORS = {
    ["Invisível"] = { Color3.fromRGB(255, 255, 255), 1 },
    ["Branco"]    = { Color3.fromRGB(255, 255, 255), 0.3 },
    ["Verde"]     = { Color3.fromRGB(0, 255, 0), 0.3 },
    ["Azul"]      = { Color3.fromRGB(0, 0, 255), 0.3 },
    ["Vermelho"]  = { Color3.fromRGB(255, 0, 0), 0.3 },
    ["Amarelo"]   = { Color3.fromRGB(255, 255, 0), 0.3 },
    ["Roxo"]      = { Color3.fromRGB(150, 90, 255), 0.3 },
    ["Laranja"]   = { Color3.fromRGB(255, 165, 0), 0.3 },
    ["Rosa"]      = { Color3.fromRGB(255, 105, 180), 0.3 },
}
local HB_COLOR_NAMES = { "Invisível", "Branco", "Verde", "Azul", "Vermelho", "Amarelo", "Roxo", "Laranja", "Rosa" }

local function isBallModel(m)
    return m:IsA("Model") and m.Name:match("^CLIENT_BALL_%d+$") ~= nil
end
local function firstBallPart(model, skipName)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= skipName then return d end
    end
    return nil
end

local function hbApply()
    if not HB.on then return end
    for _, m in ipairs(workspace:GetChildren()) do
        if isBallModel(m) then
            local p = m:FindFirstChild(HB.name)
            if not p then
                local base = firstBallPart(m, HB.name)
                if base then
                    p = Instance.new("Part")
                    p.Name = HB.name
                    p.Shape = Enum.PartType.Ball
                    p.CFrame = base.CFrame
                    p.Anchored = true
                    p.CanCollide = false
                    p.Material = Enum.Material.ForceField
                    p.Parent = m
                end
            end
            if p then
                local s = math.max(HB.size, 0.1) * 2
                p.Size = Vector3.new(s, s, s)
                p.Color = HB.color
                p.Transparency = HB.transp
            end
        end
    end
end
local function hbRemove()
    for _, m in ipairs(workspace:GetChildren()) do
        if isBallModel(m) then
            local p = m:FindFirstChild(HB.name)
            if p then p:Destroy() end
        end
    end
end
local childUpdate
local hbConn
local function hbSet(on)
    HB.on = on
    childUpdate()
    if hbConn then hbConn:Disconnect() hbConn = nil end
    if on then
        local cache, last = {}, 0
        hbConn = RunService.RenderStepped:Connect(function()
            local now = os.clock()
            if now - last > 0.2 then
                last = now
                cache = {}
                for _, m in ipairs(workspace:GetChildren()) do
                    if isBallModel(m) then cache[#cache + 1] = m end
                end
            end
            for _, m in ipairs(cache) do
                local p = m.Parent and m:FindFirstChild(HB.name)
                local base = p and firstBallPart(m, HB.name)
                if p and base then p.CFrame = base.CFrame end
            end
        end)
        hbApply()
    else
        hbRemove()
    end
end
STATE.onCleanup(function() hbSet(false) end)

local childConn
childUpdate = function()
    local want = HB.on or Cfg.BallOn or Cfg.BallRandom
    if want and not childConn then
        childConn = workspace.ChildAdded:Connect(function(child)
            if not child:IsA("Model") or not child.Name:match("^CLIENT_BALL_") then return end
            if HB.on then task.delay(0.1, hbApply) end
            if Cfg.BallOn or Cfg.BallRandom then
                task.spawn(function()
                    local n = 0
                    while n < 40 and not (child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")) do
                        n += 1
                        task.wait(0.05)
                    end
                    if child.Parent and (Cfg.BallOn or Cfg.BallRandom) then
                        if Cfg.BallRandom then
                            local b = pick(balls)
                            if b then
                                Cfg.Ball = b
                                notify("Ball", UI.trf("Aleatória: %s", b))
                            end
                        end
                        pcall(ballApply, child)
                    end
                end)
            end
        end)
    elseif not want and childConn then
        childConn:Disconnect()
        childConn = nil
    end
end
STATE.onCleanup(function()
    if childConn then childConn:Disconnect() childConn = nil end
end)

local AL = {
    saved = {}, conn = nil, hb = nil, queue = {}, qi = 1, ql = nil, sql = nil, token = 0,
    opts = { chars = true, ball = true, court = true, fx = true, light = true, quality = true },
}
local PARTICLE = {
    ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
}

local function alSet(inst, prop, val)
    if not inst then return end
    local ok, cur = pcall(function() return inst[prop] end)
    if not ok or cur == nil then return end
    local saved = AL.saved[inst]
    if not saved then
        saved = {}
        AL.saved[inst] = saved
    end
    if saved[prop] == nil then saved[prop] = cur end
    pcall(function() inst[prop] = val end)
end

local function alCharacterOf(inst)
    local p = inst.Parent
    while p and p ~= workspace do
        if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then return p end
        p = p.Parent
    end
    return nil
end
local function alIsBall(inst)
    local p = inst
    while p and p ~= workspace do
        if string.sub(p.Name, 1, 12) == "CLIENT_BALL_" then return true end
        p = p.Parent
    end
    return false
end
local function alCategory(inst)
    if PARTICLE[inst.ClassName] then return "fx" end
    local char = alCharacterOf(inst)
    if char then return (char ~= LP.Character) and "chars" or nil end
    if alIsBall(inst) then return "ball" end
    return "court"
end

local function alInst(i)
    local particle = PARTICLE[i.ClassName]
    if not (particle or i:IsA("BasePart") or i:IsA("Decal") or i:IsA("Texture") or i:IsA("SpecialMesh")
        or i:IsA("SurfaceAppearance") or i:IsA("Clothing") or i:IsA("ShirtGraphic")) then
        return
    end
    local cat = alCategory(i)
    if not cat or not AL.opts[cat] then return end
    if particle then
        alSet(i, "Enabled", false)
        return
    end
    if cat == "chars" then
        if i:IsA("Shirt") then
            alSet(i, "ShirtTemplate", "")
        elseif i:IsA("Pants") then
            alSet(i, "PantsTemplate", "")
        elseif i:IsA("ShirtGraphic") then
            alSet(i, "Graphic", "")
        elseif i:IsA("Decal") or i:IsA("Texture") then
            alSet(i, "Transparency", 1)
        elseif i:IsA("BasePart") then
            if i.Parent and i.Parent:IsA("Accessory") then alSet(i, "Transparency", 1) end
            alSet(i, "Material", Enum.Material.SmoothPlastic)
            if i:IsA("MeshPart") then alSet(i, "TextureID", "") end
        elseif i:IsA("SpecialMesh") then
            alSet(i, "TextureId", "")
        end
        return
    end
    if i:IsA("BasePart") then
        alSet(i, "Material", Enum.Material.SmoothPlastic)
        alSet(i, "Reflectance", 0)
        alSet(i, "CastShadow", false)
        if i:IsA("MeshPart") then
            alSet(i, "RenderFidelity", Enum.RenderFidelity.Performance)
            alSet(i, "TextureID", "")
        end
    elseif i:IsA("Decal") or i:IsA("Texture") then
        alSet(i, "Transparency", 1)
    elseif i:IsA("SpecialMesh") then
        alSet(i, "TextureId", "")
    elseif i:IsA("SurfaceAppearance") then
        alSet(i, "ColorMap", "")
        alSet(i, "MetalnessMap", "")
        alSet(i, "NormalMap", "")
        alSet(i, "RoughnessMap", "")
    end
end

local function alProcess(budget)
    local queue = AL.queue
    local n = 0
    while AL.qi <= #queue and n < budget do
        local inst = queue[AL.qi]
        queue[AL.qi] = false
        AL.qi += 1
        if inst and inst.Parent then alInst(inst) end
        n += 1
    end
    if AL.qi > #queue then AL.queue, AL.qi = {}, 1 end
end

local function alQuality()
    pcall(function()
        local r = settings().Rendering
        if AL.ql == nil then AL.ql = r.QualityLevel end
        r.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        local ugs = UserSettings():GetService("UserGameSettings")
        if AL.sql == nil then AL.sql = ugs.SavedQualityLevel end
        ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
end

local function alLighting()
    alSet(Lighting, "Technology", Enum.Technology.Compatibility)
    alSet(Lighting, "GlobalShadows", false)
    alSet(Lighting, "FogEnd", 1000000000)
    alSet(Lighting, "ShadowSoftness", 0)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then
            alSet(v, "Enabled", false)
        elseif v:IsA("Atmosphere") then
            alSet(v, "Density", 0)
            alSet(v, "Haze", 0)
            alSet(v, "Glare", 0)
        elseif v:IsA("Sky") then
            alSet(v, "CelestialBodiesShown", false)
            alSet(v, "StarCount", 0)
        end
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        alSet(terrain, "Decoration", false)
        alSet(terrain, "WaterWaveSize", 0)
        alSet(terrain, "WaterWaveSpeed", 0)
        alSet(terrain, "WaterReflectance", 0)
        alSet(terrain, "WaterTransparency", 1)
    end
end

local function alRestore(sync)
    AL.token += 1
    if AL.conn then AL.conn:Disconnect() AL.conn = nil end
    if AL.hb then AL.hb:Disconnect() AL.hb = nil end
    AL.queue, AL.qi = {}, 1
    local saved, ql, sql = AL.saved, AL.ql, AL.sql
    AL.saved, AL.ql, AL.sql = {}, nil, nil

    pcall(function()
        if ql ~= nil then settings().Rendering.QualityLevel = ql end
    end)
    pcall(function()
        if sql ~= nil then UserSettings():GetService("UserGameSettings").SavedQualityLevel = sql end
    end)

    local function run()
        local n = 0
        for inst, props in pairs(saved) do
            for prop, val in pairs(props) do
                pcall(function() inst[prop] = val end)
            end
            n += 1
            if n % 300 == 0 then task.wait() end
        end
    end
    if sync then run() else task.spawn(run) end
end

local function alEnable()
    AL.token += 1
    if AL.opts.quality then alQuality() end
    if AL.opts.light then alLighting() end
    local queue = AL.queue
    for _, d in ipairs(workspace:GetDescendants()) do queue[#queue + 1] = d end
    AL.conn = workspace.DescendantAdded:Connect(function(d) AL.queue[#AL.queue + 1] = d end)
    AL.hb = RunService.Heartbeat:Connect(function() alProcess(120) end)
end

local alBusy, alDirty = false, false
local function alRefresh()
    if not Cfg.AntiLag then return end
    if alBusy then
        alDirty = true
        return
    end
    alBusy = true
    pcall(function()
        repeat
            alDirty = false
            alRestore(true)
            if Cfg.AntiLag then alEnable() end
        until not alDirty
    end)
    alBusy = false
end
STATE.onCleanup(function() alRestore() end)

local LF = { conn = nil }
local function leadFeet()
    if not Cfg.LeadFeet then return end
    local char = LP.Character
    local root = char and char.PrimaryPart
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    local meta = { Acceleration = -10000, TerminalVelocity = -300, Duration = 2 }
    local gc
    pcall(function()
        local mod = require(RS.Content.Ability.LeadFeet)
        if type(mod) == "table" and type(mod.Metadata) == "table" then meta = mod.Metadata end
        gc = require(RS.Packages.Knit).GetController("GameController")
        if gc then gc.IsBusy:set(false) end
        require(RS.Content.Effect):Play("LeadFeetFX")({ Player = LP })
        require(ReplicatedFirst.Controllers.GameController.Actions.Move.Jump).stop()
        if gc then gc.IsBusy:set(true) end
    end)

    if LF.conn then LF.conn:Disconnect() LF.conn = nil end
    local untilT = os.clock() + (meta.Duration or 2)
    LF.conn = RunService.Heartbeat:Connect(function(dt)
        if not root.Parent or hum.FloorMaterial ~= Enum.Material.Air or os.clock() >= untilT then
            if gc then pcall(function() gc.IsBusy:set(false) end) end
            if LF.conn then LF.conn:Disconnect() LF.conn = nil end
            return
        end
        local v = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(
            v.X, math.max(v.Y + (meta.Acceleration or -10000) * dt, meta.TerminalVelocity or -300), v.Z)
    end)
end
STATE.onCleanup(function()
    if LF.conn then LF.conn:Disconnect() LF.conn = nil end
end)

local ESP = {
    hl = {}, acc = 0, name = rnd(), color = HB_COLORS["Vermelho"][1], outlineOnly = false,
}
local function espClear(p)
    local h = ESP.hl[p]
    if h then h:Destroy() ESP.hl[p] = nil end
end
local function espClearAll()
    for p in pairs(ESP.hl) do espClear(p) end
end
local function espStep(dt)
    ESP.acc += dt
    if ESP.acc < 0.1 then return end
    ESP.acc = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local enemy = p.Team and LP.Team and p.Team ~= LP.Team
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local jumping = false
            if hum then
                local st = hum:GetState()
                jumping = (st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall)
            end
            if enemy and char and jumping then
                local h = ESP.hl[p]
                if not h or h.Parent ~= char then
                    espClear(p)
                    h = Instance.new("Highlight")
                    h.Name = ESP.name
                    h.Adornee = char
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = char
                    ESP.hl[p] = h
                end
                h.FillColor = ESP.color
                h.OutlineColor = ESP.color
                h.FillTransparency = ESP.outlineOnly and 1 or 0.72
            else
                espClear(p)
            end
        end
    end
end
local espConn
local function espSet(on)
    Cfg.ESP = on
    if espConn then espConn:Disconnect() espConn = nil end
    if on then
        espConn = RunService.Heartbeat:Connect(espStep)
    else
        espClearAll()
    end
end
STATE.onCleanup(function() espSet(false) end)

local LN = {
    conn = nil, parts = {}, color = HB_COLORS["Vermelho"][1], width = 0.15, dist = 50,
    who = "Inimigos", move = true, name = rnd(),
}
local function lnDraw(p, key, from, to, color, width)
    local entry = LN.parts[p]
    if not entry then
        entry = {}
        LN.parts[p] = entry
    end
    local part = entry[key]
    if not part or not part.Parent then
        part = Instance.new("Part")
        part.Name = LN.name
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Transparency = 0.25
        part.Parent = workspace.CurrentCamera
        entry[key] = part
    end
    local length = (to - from).Magnitude
    part.Size = Vector3.new(width, width, math.max(length, 0.1))
    part.CFrame = CFrame.lookAt((from + to) / 2, to)
    part.Color = color
end
local function lnHide(p, key)
    local entry = LN.parts[p]
    if not entry then return end
    if key then
        if entry[key] then entry[key]:Destroy() entry[key] = nil end
    else
        for _, part in pairs(entry) do part:Destroy() end
        LN.parts[p] = nil
    end
end
local function lnClearAll()
    for p in pairs(LN.parts) do lnHide(p) end
end
local function lnStep()
    for p in pairs(LN.parts) do
        if not p.Parent then lnHide(p) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local sameTeam = p.Team ~= nil and p.Team == LP.Team
            local show = LN.who == "Todos" or (LN.who == "Time" and sameTeam) or (LN.who == "Inimigos" and not sameTeam)
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if show and root and hum and hum.Health > 0 then
                local origin = root.Position
                local look = root.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                if flat.Magnitude > 0.01 then
                    lnDraw(p, "face", origin, origin + flat.Unit * LN.dist, LN.color, LN.width)
                end
                local vel = root.AssemblyLinearVelocity
                local move = Vector3.new(vel.X, 0, vel.Z)
                if LN.move and move.Magnitude > 2 then
                    local reach = math.min(LN.dist, move.Magnitude * 2.5 + 6)
                    lnDraw(p, "move", origin, origin + move.Unit * reach, LN.color:Lerp(Color3.new(1, 1, 1), 0.55), LN.width * 0.6)
                else
                    lnHide(p, "move")
                end
            else
                lnHide(p)
            end
        end
    end
end
local function lnSet(on)
    if LN.conn then LN.conn:Disconnect() LN.conn = nil end
    if on then
        LN.conn = RunService.RenderStepped:Connect(lnStep)
    else
        lnClearAll()
    end
end
STATE.onCleanup(function() lnSet(false) end)

local SL = { on = false, conn = nil, orig = nil }
local function slHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function slSet(on)
    SL.on = on
    local hum = slHumanoid()
    if on then
        if hum and SL.orig == nil then SL.orig = hum.AutoRotate end
    else
        if hum and SL.orig ~= nil then hum.AutoRotate = SL.orig end
        SL.orig = nil
    end
end
local function slBind(char)
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    if SL.conn then SL.conn:Disconnect() SL.conn = nil end
    SL.conn = hum:GetPropertyChangedSignal("Jump"):Connect(function()
        if not SL.on then return end
        if hum.Jump then
            task.defer(function()
                task.wait(0.03)
                local cam = workspace.CurrentCamera
                if not cam or not root.Parent then return end
                local facing = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                if facing.Magnitude > 0 then
                    root.CFrame = CFrame.lookAt(root.Position, root.Position + facing.Unit)
                    hum.AutoRotate = false
                end
            end)
        else
            hum.AutoRotate = false
        end
    end)
end
STATE.connect(LP.CharacterAdded, function(char)
    SL.orig = nil
    slBind(char)
end)
if LP.Character then task.spawn(slBind, LP.Character) end
STATE.onCleanup(function()
    if SL.conn then SL.conn:Disconnect() SL.conn = nil end
    slSet(false)
end)

local PR = { on = false, mode = "Completo", size = 6, marker = nil, label = nil, tracked = nil, last = nil, stamp = 0,
    drift = Vector3.zero, name = rnd() }

function PR.clear()
    if PR.marker then PR.marker:Destroy() PR.marker = nil PR.label = nil end
    PR.tracked, PR.last, PR.drift = nil, nil, Vector3.zero
end

function PR.build()
    local part = Instance.new("Part")
    part.Name = PR.name
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(0.2, 7, 7)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Transparency = 0.35
    part.CastShadow = false
    part.Parent = workspace.CurrentCamera

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 90, 0, 30)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0
    lbl.Parent = bb

    PR.marker, PR.label = part, lbl
end

function PR.gravity()
    local ok, g = pcall(function()
        local cfg = require(RS.Configuration.Game)
        local state = require(RS.Common.State)
        return state.get(RS, state.Id.Modifier, "BallGravity", cfg.Physics.Gravity)
    end)
    if ok and type(g) == "number" and g > 0 then return g end
    return 17
end

function PR.velocity(part)
    local ok, knit = pcall(require, RS.Packages.Knit)
    if ok then
        local ok2, ctrl = pcall(knit.GetController, "BallController")
        if ok2 and type(ctrl) == "table" and type(ctrl.ActiveBalls) == "table" then
            for _, v in pairs(ctrl.ActiveBalls) do
                local b = v.Ball
                if b and b.Parent and b:IsAncestorOf(part) and typeof(v.Velocity) == "Vector3" then
                    return v.Velocity
                end
            end
        end
    end
    return PR.drift
end

function PR.solve(pos, vel, g, floorY)
    local h = pos.Y - floorY
    if h < 0 then return nil end
    local disc = vel.Y * vel.Y + 2 * g * h
    if disc < 0 then return nil end
    local t = (vel.Y + math.sqrt(disc)) / g
    if t ~= t or t <= 0 or t > 15 then return nil end
    return t
end

function PR.netHit(pos, vel, g, t)
    local map = workspace:FindFirstChild("Map")
    local coll = map and map:FindFirstChild("BallCollideOnly")
    local net = coll and coll:FindFirstChild("Net")
    if not net then return false end
    local dz = net.Position.Z - pos.Z
    if math.abs(vel.Z) < 0.01 then return false end
    local tn = dz / vel.Z
    if tn <= 0 or tn >= t then return false end
    local y = pos.Y + vel.Y * tn - 0.5 * g * tn * tn
    local x = pos.X + vel.X * tn
    if y > net.Position.Y + net.Size.Y * 0.5 or y < net.Position.Y - net.Size.Y * 0.5 then return false end
    return math.abs(x - net.Position.X) <= net.Size.X * 0.5
end

function PR.predict(part)
    local ok, Physics = pcall(require, RS.Common.Physics)
    if not ok then return nil end
    local g = PR.gravity()
    local pos = part.Position
    local vel = PR.velocity(part)
    if typeof(vel) ~= "Vector3" then return nil end

    local floorY = Physics.LastFloorHeight
    if not floorY then
        local ok2, h = pcall(Physics.calculateFloorHeight, pos, true)
        floorY = ok2 and h or nil
    end
    if not floorY then return nil end

    local t = PR.solve(pos, vel, g, floorY)
    if not t then return nil end
    local land = Vector3.new(pos.X + vel.X * t, floorY, pos.Z + vel.Z * t)

    local ok3, h2 = pcall(Physics.calculateFloorHeight, Vector3.new(land.X, pos.Y, land.Z), true)
    if ok3 and type(h2) == "number" and math.abs(h2 - floorY) > 0.05 then
        local t2 = PR.solve(pos, vel, g, h2)
        if t2 then
            t = t2
            land = Vector3.new(pos.X + vel.X * t, h2, pos.Z + vel.Z * t)
        end
    end
    return land, Physics, t, PR.netHit(pos, vel, g, t)
end

local ballCache, ballCacheAt = {}, 0
local function nearestBallPart()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local now = os.clock()
    if now - ballCacheAt > 0.25 then
        ballCacheAt = now
        ballCache = {}
        for _, m in ipairs(workspace:GetChildren()) do
            if isBallModel(m) then
                for _, d in ipairs(m:GetDescendants()) do
                    if d:IsA("BasePart") then
                        table.insert(ballCache, d)
                        break
                    end
                end
            end
        end
    end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(ballCache) do
        if p.Parent then
            local dist = (p.Position - root.Position).Magnitude
            if dist < bestDist then best, bestDist = p, dist end
        end
    end
    return best
end

local function prStep()
    if not PR.on then
        if PR.marker then PR.clear() end
        return
    end
    local part = nearestBallPart()
    if not part then
        if PR.marker then PR.marker.Transparency = 1 end
        PR.last = nil
        return
    end
    local now = os.clock()
    if PR.tracked == part and PR.last and now > PR.stamp then
        PR.drift = (part.Position - PR.last) / (now - PR.stamp)
    end
    PR.tracked, PR.last, PR.stamp = part, part.Position, now

    local land, Physics, t, netHit = PR.predict(part)
    if not land then
        if PR.marker then PR.marker.Transparency = 1 end
        return
    end
    if not PR.marker then PR.build() end

    local inCourt = true
    if Physics._getCourtlines and Physics.isPositionInCourt and Physics._getCourtlines() then
        local ok, res = pcall(Physics.isPositionInCourt, land, nil, part.Size.X * 0.5, nil)
        inCourt = (not ok) or res
    end

    local color, text = Color3.fromRGB(255, 150, 40), ""
    if PR.mode == "Completo" then
        if netHit then
            color, text = Color3.fromRGB(250, 180, 40), "REDE"
        elseif inCourt then
            color, text = Color3.fromRGB(60, 220, 90), "DENTRO"
        else
            color, text = Color3.fromRGB(235, 60, 60), "FORA"
        end
    end

    local k = math.clamp(1 - t / 2, 0, 1)
    local size = PR.size * (1 + k * 0.5)
    PR.marker.Size = Vector3.new(0.2, size, size)
    PR.marker.Transparency = 0.35 - k * 0.15
    PR.marker.Color = color
    PR.marker.CFrame = CFrame.new(land + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
    PR.label.Visible = PR.mode ~= "Marcação"
    PR.label.Text = (text ~= "" and (text .. "  ") or "") .. string.format("%.1fs", t)
    PR.label.TextColor3 = color
end
local prConn
local function prSet(on)
    PR.on = on
    if prConn then prConn:Disconnect() prConn = nil end
    if on then
        prConn = RunService.RenderStepped:Connect(prStep)
    else
        PR.clear()
    end
end
STATE.onCleanup(function() prSet(false) end)

local function claimLevel()
    local rf = path(Services, "LevelService", "RF", "ClaimLevelRewards")
    if not rf then notify("Recompensas", "Não achei o remote de nível.") return end
    local ok = pcall(function() rf:InvokeServer() end)
    notify("Recompensas", ok and "Recompensas de nível solicitadas." or "Falha ao coletar.")
end

local function claimQuests()
    local rf = path(Services, "QuestService", "RF", "ClaimAll")
    if not rf then notify("Recompensas", "Não achei o remote de missões.") return end
    local ok = pcall(function() rf:InvokeServer(true) end)
    notify("Recompensas", ok and "Recompensas de missões solicitadas." or "Falha ao coletar.")
end

local function redeemAll()
    local rf = path(Services, "CodeService", "RF", "Redeem")
    if not rf then notify("Códigos", "Não achei o remote de códigos.") return end
    local ok, html = pcall(function() return game:HttpGet("https://beebom.com/haikyuu-legends-codes/") end)
    if not ok or not html then notify("Códigos", "Não consegui buscar a lista de códigos.") return end
    local codes, seen = {}, {}
    for line in string.gmatch(html, "[^\n]+") do
        if string.find(line, "(NEW)") then
            local c = string.match(line, "(%u+[%u%d_]+)")
            if c and not seen[c] then
                seen[c] = true
                table.insert(codes, c)
            end
        end
        if #codes >= 3 then break end
    end
    if #codes == 0 then notify("Códigos", "Nenhum código novo encontrado.") return end
    for _, c in ipairs(codes) do
        pcall(function() rf:InvokeServer(c) end)
        task.wait(0.01)
    end
    notify("Códigos", UI.trf("%d código(s) enviado(s).", #codes))
end

local CS = { on = false, found = nil, patched = {}, bind = "DaishynNoShake" }

local function makeDummy()
    local d = {}
    setmetatable(d, {
        __index = function() return d end,
        __call = function() return d end,
    })
    return d
end

local function csScan()
    if CS.found then return end
    CS.found = {}
    local roots = { RS, ReplicatedFirst, LP:FindFirstChild("PlayerScripts") }
    for _, root in ipairs(roots) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("ModuleScript") and string.find(string.lower(d.Name), "shake", 1, true) then
                    table.insert(CS.found, d)
                end
            end
        end
    end
    local names = {}
    for _, m in ipairs(CS.found) do table.insert(names, m:GetFullName()) end
    print("[Daishyn] módulos de shake encontrados: " .. (#names > 0 and table.concat(names, ", ") or "nenhum"))
end

local function csPatch()
    csScan()
    for _, ms in ipairs(CS.found) do
        local ok, mod = pcall(require, ms)
        if ok and type(mod) == "table" then
            pcall(function() if setreadonly then setreadonly(mod, false) end end)
            for k, v in pairs(mod) do
                if type(k) == "string" and type(v) == "function"
                    and string.find(string.lower(k), "shake", 1, true) then
                    CS.patched[mod] = CS.patched[mod] or {}
                    if CS.patched[mod][k] == nil then CS.patched[mod][k] = v end
                    pcall(function() mod[k] = function() return makeDummy() end end)
                end
            end
        end
    end
end

local function csRestore()
    for mod, fns in pairs(CS.patched) do
        for k, v in pairs(fns) do
            pcall(function() mod[k] = v end)
        end
    end
    CS.patched = {}
end

local UserInputService = game:GetService("UserInputService")
local function shiftLockOffset()
    local locked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
    if not locked then
        pcall(function()
            locked = UserSettings():GetService("UserGameSettings").RotationType == Enum.RotationType.CameraRelative
        end)
    end
    return locked and Vector3.new(1.75, 0, 0) or Vector3.zero
end

local function csSet(on)
    CS.on = on
    pcall(function() RunService:UnbindFromRenderStep(CS.bind) end)
    if on then
        task.spawn(csPatch)
        RunService:BindToRenderStep(CS.bind, Enum.RenderPriority.Camera.Value - 1, function()
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local target = shiftLockOffset()
            if hum.CameraOffset ~= target then hum.CameraOffset = target end
        end)
    else
        csRestore()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = shiftLockOffset() end
    end
end
STATE.onCleanup(function() csSet(false) end)

local FOLDER = "Daishyn"
local function fsReady()
    if not (writefile and readfile and isfolder and makefolder) then return false end
    pcall(function()
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        if not isfolder(FOLDER .. "/configs") then makefolder(FOLDER .. "/configs") end
    end)
    return true
end
local function migrateOld()
    if not (isfolder and listfiles and readfile and writefile) then return end
    pcall(function()
        if isfolder("ScyFeVisuals/configs") and fsReady() and #listfiles(FOLDER .. "/configs") == 0 then
            for _, f in ipairs(listfiles("ScyFeVisuals/configs")) do
                local name = tostring(f):match("([^/\\]+%.json)$")
                if name then writefile(FOLDER .. "/configs/" .. name, readfile(f)) end
            end
            if isfile("ScyFeVisuals/autoload.txt") then
                writefile(FOLDER .. "/autoload.txt", readfile("ScyFeVisuals/autoload.txt"))
            end
        end
    end)
end
migrateOld()

local FAV_FILE = FOLDER .. "/favorites.json"
local favData = {}
local function loadFavorites()
    if not (isfile and readfile) then return end
    local ok, raw = pcall(function()
        if isfile(FAV_FILE) then return readfile(FAV_FILE) end
        return nil
    end)
    if ok and raw then
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok2 and type(data) == "table" then favData = data end
    end
end
local function saveFavorites()
    if not fsReady() then return end
    local ok, json = pcall(HttpService.JSONEncode, HttpService, favData)
    if ok then pcall(writefile, FAV_FILE, json) end
end
loadFavorites()
UI.favStore = {
    get = function(id) return favData[id] end,
    set = function(id, list)
        favData[id] = list
        saveFavorites()
    end,
}

local function cfgPath(name) return FOLDER .. "/configs/" .. name .. ".json" end
local function cleanName(name)
    return (tostring(name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
local function cfgExists(name)
    return isfile and isfile(cfgPath(name)) or false
end
local function listConfigs()
    local out = {}
    if not fsReady() or not listfiles then return out end
    local ok, files = pcall(listfiles, FOLDER .. "/configs")
    if ok and type(files) == "table" then
        for _, f in ipairs(files) do
            local n = tostring(f):match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    table.sort(out)
    return out
end
local function collect()
    local data = {}
    for id, c in pairs(UI.controls) do
        if not string.find(id, "#fav", 1, true) then
            local ok, v = pcall(c.get)
            if ok and v ~= nil then data[id] = v end
        end
    end
    return data
end
local function saveConfig(name)
    if not fsReady() then notify("Config", "Seu executor não suporta salvar arquivos.") return false end
    local ok, json = pcall(HttpService.JSONEncode, HttpService, collect())
    if not ok then notify("Config", "Falha ao montar a configuração.") return false end
    local ok2 = pcall(writefile, cfgPath(name), json)
    if not ok2 then notify("Config", "Falha ao gravar o arquivo.") return false end
    return true
end
local function loadConfig(name, silent)
    if not fsReady() or not cfgExists(name) then
        if not silent then notify("Config", "Config não encontrada.") end
        return false
    end
    local ok, raw = pcall(readfile, cfgPath(name))
    if not ok then return false end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then
        if not silent then notify("Config", "Arquivo de config inválido.") end
        return false
    end
    for id, v in pairs(data) do
        local c = UI.controls[id]
        if c and not string.find(id, "#fav", 1, true) then pcall(c.set, v) end
    end
    notify("Config", UI.trf("Carregada: %s", name))
    return true
end
local function readAutoload()
    if not (isfile and readfile) then return nil end
    local ok, v = pcall(function()
        if isfile(FOLDER .. "/autoload.txt") then return readfile(FOLDER .. "/autoload.txt") end
        return nil
    end)
    if ok and v and v ~= "" then return v end
    return nil
end
local function writeAutoload(name)
    if not fsReady() then return false end
    return (pcall(writefile, FOLDER .. "/autoload.txt", name or ""))
end

local function buildMenu()
UI.EN = {
    ["Jogo"] = "Game", ["Personagem"] = "Character", ["Visuais"] = "Visuals", ["Misc"] = "Misc",
    ["Proteção"] = "Protection", ["Config"] = "Settings",
    ["Hitbox"] = "Hitbox", ["Especiais e Saque"] = "Specials & Serve", ["Movimento"] = "Movement",
    ["Desempenho"] = "Performance", ["Câmera"] = "Camera", ["Efeito de Ponto"] = "Score Effect",
    ["Lista de Efeitos (sorteio)"] = "Effect List (random)", ["Previsão da Bola"] = "Ball Prediction",
    ["Bola"] = "Ball", ["Camisa"] = "Jersey", ["Card do Jogador"] = "Player Card",
    ["Recompensas"] = "Rewards", ["Idioma"] = "Language", ["Menu"] = "Menu",
    ["Configurações Salvas"] = "Saved Configs",
    ["Pesquisar opções..."] = "Search options...", ["Pesquisar..."] = "Search...",
    ["Resultados"] = "Results", ["Nenhuma opção encontrada."] = "No options found.",
    ["Lista vazia: sorteia entre todos."] = "Empty list: picks among all.", ["Total"] = "Total",
    ["Pílula ou tecla do painel"] = "Pill or panel key",
    ["Hitbox da Bola"] = "Ball Hitbox", ["Cria uma esfera de alcance em volta da bola."] = "Creates a reach sphere around the ball.",
    ["Tamanho do Hitbox"] = "Hitbox Size", ["Alcance em studs (máx. 20). Toque no número pra digitar."] = "Reach in studs (max 20). Tap the number to type.",
    ["Cor do Hitbox"] = "Hitbox Color", ["Cor da esfera."] = "Sphere color.",
    ["Remover Hitboxes"] = "Remove Hitboxes", ["Apaga as esferas da bola."] = "Deletes the spheres on the ball.",
    ["Invisível"] = "Invisible", ["Branco"] = "White", ["Verde"] = "Green", ["Azul"] = "Blue", ["Vermelho"] = "Red",
    ["Amarelo"] = "Yellow", ["Roxo"] = "Purple", ["Laranja"] = "Orange", ["Rosa"] = "Pink",
    ["Carga Máxima do Especial"] = "Max Special Charge", ["Seu especial sai sempre com carga cheia."] = "Your special always comes out fully charged.",
    ["Saque Máximo"] = "Max Serve", ["Saque com a potência máxima."] = "Serve with maximum power.",
    ["Pés de Chumbo"] = "Lead Feet", ["Mostra um botão LF pra cair rápido no ar."] = "Shows an LF button to drop fast in the air.",
    ["Tecla dos Pés de Chumbo"] = "Lead Feet Key", ["Tecla que ativa a queda (com o recurso ligado)."] = "Key that triggers the drop (feature on).",
    ["ESP de Pulo"] = "Jump ESP", ["Destaca inimigos enquanto pulam."] = "Highlights enemies while they jump.",
    ["Anti-Lag"] = "Anti-Lag", ["Reduz os gráficos pra rodar mais leve."] = "Lowers graphics to run lighter.",
    ["Shift Lock Automático"] = "Auto Shift Lock", ["Vira o personagem pra câmera ao pular."] = "Turns the character toward the camera on jump.",
    ["Desativar Tremor de Câmera"] = "Disable Camera Shake", ["Remove o tremor de câmera do jogo."] = "Removes the game's camera shake.",
    ["Efeito escolhido"] = "Score effect", ["Pesquise ou favorite com a estrela."] = "Search or favorite with the star.",
    ["Trocar Efeito de Ponto"] = "Change Score Effect", ["Troca o efeito do seu ponto (só pra você)."] = "Changes your point effect (client-side).",
    ["Efeito Aleatório"] = "Random Effect", ["Sorteia um efeito a cada ponto (usa a lista)."] = "Picks an effect each point (uses the list).",
    ["Adicionar à lista"] = "Add to list", ["Escolha um efeito pra entrar no sorteio."] = "Pick an effect to join the draw.",
    ["Adicionar efeito..."] = "Add effect...",
    ["Normalizar %"] = "Normalize %", ["Ajusta tudo pra somar 100%."] = "Rescales everything to total 100%.",
    ["Limpar lista"] = "Clear list", ["Remove todos os efeitos da lista."] = "Removes all effects from the list.",
    ["Marcador de Queda"] = "Landing Marker", ["Mostra onde a bola cai: dentro, fora ou rede."] = "Shows where the ball lands: in, out or net.",
    ["Skin da bola"] = "Ball skin", ["Trocar Skin da Bola"] = "Change Ball Skin", ["Aplica em toda bola nova."] = "Applies to every new ball.",
    ["Skin Aleatória"] = "Random Skin", ["Sorteia uma skin a cada bola."] = "Picks a skin each ball.",
    ["Trocar Camisa"] = "Change Jersey", ["Mantém a camisa (reaplica ao renascer)."] = "Keeps the jersey (reapplies on respawn).",
    ["Card"] = "Card", ["Trocar Card"] = "Change Card", ["Troca o card do seu ponto."] = "Changes your point card.",
    ["Card Aleatório"] = "Random Card", ["Sorteia um card a cada ponto."] = "Picks a card each point.",
    ["Testar Card"] = "Test Card", ["Mostra o card agora."] = "Shows the card now.",
    ["Coletar Missões"] = "Claim Quests", ["Resgata as recompensas de missões prontas."] = "Claims ready quest rewards.",
    ["Coletar Recompensas de Nível"] = "Claim Level Rewards", ["Resgata as recompensas de nível disponíveis."] = "Claims available level rewards.",
    ["Resgatar Todos os Códigos"] = "Redeem All Codes", ["Busca códigos novos e resgata (até 3)."] = "Fetches new codes and redeems (up to 3).",
    ["Português"] = "Português", ["English"] = "English", ["Escolha o idioma da interface."] = "Choose the interface language.",
    ["Custom Protect"] = "Custom Protect", ["Nome"] = "Name", ["Aparece no lugar do seu nome real."] = "Shown instead of your real name.",
    ["Troca seu nome na nametag, avisos e card."] = "Swaps your name on nametag, alerts and card.",
    ["Lado das notificações"] = "Notification side", ["Onde os avisos aparecem."] = "Where alerts appear.",
    ["Esquerda"] = "Left", ["Centro"] = "Center", ["Direita"] = "Right",
    ["Tamanho da GUI"] = "GUI size", ["Escala do painel em %."] = "Panel scale in %.",
    ["Transparência da GUI"] = "GUI transparency", ["Menor % = mais opaca."] = "Lower % = more opaque.",
    ["Habilidades"] = "Abilities", ["Efeitos"] = "Effects", ["Previsão"] = "Prediction", ["Cosméticos"] = "Cosmetics",
    ["Configs Salvas"] = "Saved Configs", ["Gráficos"] = "Graphics",
    ["Cor do ESP"] = "ESP Color", ["Cor do contorno dos inimigos que pulam."] = "Outline color of jumping enemies.",
    ["Só contorno"] = "Outline only", ["Esconde o preenchimento do corpo."] = "Hides the body fill.",
    ["Modo do marcador"] = "Marker mode",
    ["Marcação, Marcação + tempo ou Completo (dentro/fora/rede)."] = "Marker, Marker + time or Full (in/out/net).",
    ["Marcação"] = "Marker", ["Marcação + tempo"] = "Marker + time", ["Completo"] = "Full",
    ["Tamanho da marcação"] = "Marker size", ["Tamanho do círculo no chão."] = "Size of the ground circle.",
    ["Tremor de Câmera"] = "Camera Shake",
    ["Aparência"] = "Appearance", ["Sobre"] = "About", ["Log de alterações"] = "Changelog",
    ["Cores"] = "Colors", ["Estilo e fundo"] = "Style & background", ["Comunidade"] = "Community",
    ["Cor de destaque"] = "Accent color", ["Cor principal dos botões e detalhes."] = "Main color of buttons and details.",
    ["Destaque personalizado (hex)"] = "Custom accent (hex)", ["Ex.: #A878FF. Vazio usa a cor acima."] = "E.g. #A878FF. Empty uses the color above.",
    ["Cor de fundo"] = "Background color", ["Cor base do painel."] = "Base color of the panel.",
    ["Fundo personalizado (hex)"] = "Custom background (hex)",
    ["Cor das bordas"] = "Border color", ["Contorno da janela e dos cards."] = "Outline of the window and cards.",
    ["Bordas personalizadas (hex)"] = "Custom borders (hex)",
    ["Fundo"] = "Background", ["Sólido, gradiente ou automático (segue o estilo)."] = "Solid, gradient or automatic (follows the style).",
    ["Automático"] = "Automatic", ["Sólido"] = "Solid", ["Gradiente"] = "Gradient",
    ["Arredondamento"] = "Roundness", ["Raio dos cantos dos cards."] = "Corner radius of the cards.",
    ["Fonte"] = "Font", ["Fonte usada em toda a GUI."] = "Font used across the GUI.",
    ["Animações"] = "Animations", ["Desligadas, Suaves ou Completas (com brilho e hover)."] = "Off, Smooth or Full (with glow and hover).",
    ["Desligadas"] = "Off", ["Suaves"] = "Smooth", ["Completas"] = "Full",
    ["Botão de abrir"] = "Open button", ["Como abrir o painel: pílula ou bolha."] = "How to open the panel: pill or bubble.",
    ["Pílula"] = "Pill", ["Bolha"] = "Bubble",
    ["Padrão"] = "Default", ["Grafite"] = "Graphite", ["Roxo escuro"] = "Dark purple", ["Azul escuro"] = "Dark blue",
    ["Verde escuro"] = "Dark green", ["Vinho"] = "Wine", ["Preto puro"] = "Pure black", ["Cinza"] = "Gray",
    ["Preto"] = "Black", ["Ciano"] = "Cyan",
    ["Entrar no Discord"] = "Join Discord", ["Copia o convite e tenta abrir o Discord."] = "Copies the invite and tries to open Discord.",
    ["Convite copiado: %s"] = "Invite copied: %s", ["Não consegui copiar. Convite: %s"] = "Couldn't copy. Invite: %s",
    ["Adicionado"] = "Added", ["Alterado"] = "Changed", ["Modificado"] = "Modified", ["Excluído"] = "Removed", ["Corrigido"] = "Fixed",
    ["Versão 1.0"] = "Version 1.0",
    ["Avisos"] = "Notices", ["Últimos avisos"] = "Latest notices", ["Linhas"] = "Lines",
    ["Linhas nos inimigos"] = "Enemy lines", ["O que o Anti-Lag afeta"] = "What Anti-Lag affects",
    ["Linhas nos Inimigos"] = "Enemy Lines", ["Mostra pra onde cada jogador está olhando e se movendo."] = "Shows where each player is facing and moving.",
    ["Mostrar"] = "Show", ["Quem recebe a linha."] = "Who gets a line.", ["Inimigos"] = "Enemies", ["Time"] = "Team", ["Todos"] = "All",
    ["Cor da linha"] = "Line color", ["Cor das linhas."] = "Color of the lines.",
    ["Espessura da linha"] = "Line thickness", ["Grossura em studs."] = "Thickness in studs.",
    ["Distância da linha"] = "Line distance", ["Comprimento em studs."] = "Length in studs.",
    ["Linha de movimento"] = "Movement line", ["Mostra também pra onde o jogador está andando."] = "Also shows where the player is moving.",
    ["Personagens"] = "Characters", ["Skins e roupas dos outros jogadores (avatar do Roblox)."] = "Skins and clothes of other players (Roblox avatars).",
    ["Texturas e materiais da bola."] = "Ball textures and materials.",
    ["Quadra"] = "Court", ["Cenário, materiais e texturas da quadra."] = "Scenery, materials and textures of the court.",
    ["Partículas, rastros e luzes (score effects e outros)."] = "Particles, trails and lights (score effects and more).",
    ["Iluminação e sombras"] = "Lighting and shadows", ["Sombras, névoa e pós-processamento."] = "Shadows, fog and post-processing.",
    ["Qualidade gráfica"] = "Graphics quality", ["Nível de qualidade do Roblox."] = "Roblox quality level.",
    ["Tema"] = "Theme", ["Automático usa Halloween de 20/10 a 02/11."] = "Automatic uses Halloween from Oct 20 to Nov 2.",
    ["Halloween"] = "Halloween", ["Nenhum"] = "None",
    ["Pílula, bolha ou nenhum (só pela tecla do painel)."] = "Pill, bubble or none (panel key only).",
    ["Transparência da pílula"] = "Pill transparency", ["Só o botão pílula."] = "Pill button only.",
    ["Transparência da bolha"] = "Bubble transparency", ["Só o botão bolha."] = "Bubble button only.",
    ["Defina a tecla do painel antes de usar Nenhum."] = "Set the panel key before using None.",
    ["Nome pra criar ou renomear uma config."] = "Name to create or rename a config.",
    ["Pesquise ou escolha uma. [Auto] carrega ao iniciar."] = "Search or pick one. [Auto] loads on start.",
    ["Renomear"] = "Rename", ["Renomeia a escolhida pro nome digitado."] = "Renames the chosen one to the typed name.",
    ["Renomeada: %s"] = "Renamed: %s", ["Não consegui renomear."] = "Couldn't rename.",
    ["Estilo da GUI"] = "GUI style", ["Clean: simples. Soft: brilho e degradê."] = "Clean: simple. Soft: glow and gradient.",
    ["Tecla do painel"] = "Panel key", ["Toque na caixa e aperte a tecla."] = "Tap the box and press a key.",
    ["Descarregar Script"] = "Unload Script", ["Desfaz tudo e fecha o menu."] = "Undoes everything and closes the menu.",
    ["Nome da config"] = "Config name", ["Nome pra criar uma config."] = "Name to create a config.",
    ["Config escolhida"] = "Saved configs", ["Pesquise ou escolha uma."] = "Search or pick one.",
    ["Criar"] = "Create", ["Salva as opções atuais com o nome digitado."] = "Saves current options under the typed name.",
    ["Carregar"] = "Load", ["Aplica a config escolhida."] = "Applies the chosen config.",
    ["Sobrescrever"] = "Overwrite", ["Atualiza a escolhida com as opções atuais."] = "Updates the chosen one with current options.",
    ["Apagar"] = "Delete", ["Remove a config escolhida."] = "Removes the chosen config.",
    ["Definir como Auto Load"] = "Set as Auto Load", ["Carrega sozinha ao iniciar o script."] = "Loads automatically on script start.",
    ["Limpar Auto Load"] = "Clear Auto Load", ["Para de carregar automaticamente."] = "Stops loading automatically.",
    ["Aviso"] = "Warning", ["Seu executor não suporta hooks."] = "Your executor doesn't support hooks.",
    ["Recompensas"] = "Rewards", ["Não achei o remote de nível."] = "Couldn't find the level remote.",
    ["Recompensas de nível solicitadas."] = "Level rewards requested.", ["Falha ao coletar."] = "Failed to claim.",
    ["Não achei o remote de missões."] = "Couldn't find the quest remote.", ["Recompensas de missões solicitadas."] = "Quest rewards requested.",
    ["Códigos"] = "Codes", ["Não achei o remote de códigos."] = "Couldn't find the codes remote.",
    ["Não consegui buscar a lista de códigos."] = "Couldn't fetch the code list.", ["Nenhum código novo encontrado."] = "No new codes found.",
    ["%d código(s) enviado(s)."] = "%d code(s) sent.",
    ["Seu executor não suporta salvar arquivos."] = "Your executor can't save files.",
    ["Falha ao montar a configuração."] = "Failed to build the config.", ["Falha ao gravar o arquivo."] = "Failed to write the file.",
    ["Config não encontrada."] = "Config not found.", ["Arquivo de config inválido."] = "Invalid config file.",
    ["Carregada: %s"] = "Loaded: %s", ["Escolha uma config na lista."] = "Pick a config from the list.",
    ["Digite um nome primeiro."] = "Type a name first.", ["Já existe. Use Sobrescrever."] = "Already exists. Use Overwrite.",
    ["Criada: %s"] = "Created: %s", ["Atualizada: %s"] = "Updated: %s", ["Apagada: %s"] = "Deleted: %s",
    ["Não consegui apagar."] = "Couldn't delete.", ["Auto load: %s"] = "Auto load: %s", ["Auto load removido."] = "Auto load cleared.",
    ["nenhum"] = "none", ["Já está na lista."] = "Already in the list.",
    ["Carregado. Toque na pílula pra abrir/fechar."] = "Loaded. Tap the pill to open/close.",
    ["Aleatória: %s"] = "Random: %s", ["Aleatório: %s"] = "Random: %s", ["Nome: %s"] = "Name: %s",
    ["Tremor de câmera: %d módulo(s) tratado(s)."] = "Camera Shake: %d module(s) handled.",
}

local effectWeights = nil
local function autoText()
    return UI.trf("Auto load: %s", readAutoload() or UI.tr("nenhum"))
end

local JogoPage = UI.tab("Jogo", "Jogo")
local Jogo = { Hitbox = JogoPage, Habilidades = JogoPage, Linhas = JogoPage, Desempenho = JogoPage }

local gHit = Jogo.Hitbox:group("Hitbox")
gHit:toggle({
    Title = "Hitbox da Bola", Desc = "Cria uma esfera de alcance em volta da bola.",
    Id = "hb_on", Hotkey = true,
    Callback = function(v)
        hbSet(v)
    end,
})
gHit:slider({
    Title = "Tamanho do Hitbox", Desc = "Alcance em studs (máx. 20). Toque no número pra digitar.",
    Id = "hb_size", Min = 0, Max = 20, Step = 0.1, TypeStep = 0.1, Value = 5,
    Callback = function(v)
        HB.size = v
        hbApply()
    end,
})
gHit:dropdown({
    Title = "Cor do Hitbox", Desc = "Cor da esfera.",
    Id = "hb_color", Options = HB_COLOR_NAMES, Value = "Laranja",
    Callback = function(v)
        local c = HB_COLORS[v]
        if c then
            HB.color, HB.transp = c[1], c[2]
            hbApply()
        end
    end,
})
gHit:button({
    Title = "Remover Hitboxes", Desc = "Apaga as esferas da bola.",
    Callback = hbRemove,
})

local gSpec = Jogo.Habilidades:group("Especiais e Saque")
gSpec:toggle({
    Title = "Carga Máxima do Especial", Desc = "Seu especial sai sempre com carga cheia.",
    Id = "maxcharge", Hotkey = true,
    Callback = function(v)
        Cfg.MaxCharge = v
        if v and not installHook() then Cfg.MaxCharge = false end
    end,
})
gSpec:toggle({
    Title = "Saque Máximo", Desc = "Saque com a potência máxima.",
    Id = "maxserve", Hotkey = true,
    Callback = function(v)
        Cfg.MaxServe = v
        if v and not installHook() then Cfg.MaxServe = false end
    end,
})

local gMove = Jogo.Habilidades:group("Movimento")
local lfFloat = UI.floatButton("LF", 0, leadFeet)
gMove:toggle({
    Title = "Pés de Chumbo", Desc = "Mostra um botão LF pra cair rápido no ar.",
    Id = "leadfeet", Hotkey = true,
    Callback = function(v)
        Cfg.LeadFeet = v
        lfFloat:Show(v)
    end,
})
gMove:keybind({
    Title = "Tecla dos Pés de Chumbo", Desc = "Tecla que ativa a queda (com o recurso ligado).",
    Id = "leadfeet_act", Key = "G", Callback = leadFeet,
})
gMove:toggle({
    Title = "ESP de Pulo", Desc = "Destaca inimigos enquanto pulam.",
    Id = "esp", Hotkey = true,
    Callback = function(v)
        espSet(v)
    end,
})
gMove:dropdown({
    Title = "Cor do ESP", Desc = "Cor do contorno dos inimigos que pulam.",
    Id = "esp_color", Options = { "Branco", "Verde", "Azul", "Vermelho", "Amarelo", "Roxo", "Laranja", "Rosa" },
    Value = "Vermelho",
    Callback = function(v)
        local c = HB_COLORS[v]
        if c then ESP.color = c[1] end
    end,
})
gMove:toggle({
    Title = "Só contorno", Desc = "Esconde o preenchimento do corpo.",
    Id = "esp_outline",
    Callback = function(v) ESP.outlineOnly = v end,
})

local gLines = Jogo.Linhas:group("Linhas nos inimigos")
gLines:toggle({
    Title = "Linhas nos Inimigos", Desc = "Mostra pra onde cada jogador está olhando e se movendo.",
    Id = "lines_on", Hotkey = true,
    Callback = function(v) lnSet(v) end,
})
gLines:dropdown({
    Title = "Mostrar", Desc = "Quem recebe a linha.",
    Id = "lines_who", Options = { "Inimigos", "Time", "Todos" }, Value = "Inimigos",
    Callback = function(v) LN.who = v end,
})
gLines:dropdown({
    Title = "Cor da linha", Desc = "Cor das linhas.",
    Id = "lines_color", Options = { "Branco", "Verde", "Azul", "Vermelho", "Amarelo", "Roxo", "Laranja", "Rosa" },
    Value = "Vermelho",
    Callback = function(v)
        local c = HB_COLORS[v]
        if c then LN.color = c[1] end
    end,
})
gLines:slider({
    Title = "Espessura da linha", Desc = "Grossura em studs.",
    Id = "lines_width", Min = 0.05, Max = 1, Step = 0.05, TypeStep = 0.01, Value = 0.15,
    Callback = function(v) LN.width = v end,
})
gLines:slider({
    Title = "Distância da linha", Desc = "Comprimento em studs.",
    Id = "lines_dist", Min = 10, Max = 200, Step = 5, Value = 50,
    Callback = function(v) LN.dist = v end,
})
gLines:toggle({
    Title = "Linha de movimento", Desc = "Mostra também pra onde o jogador está andando.",
    Id = "lines_move", Value = true,
    Callback = function(v) LN.move = v end,
})

local gPerf = Jogo.Desempenho:group("Gráficos")
gPerf:toggle({
    Title = "Anti-Lag", Desc = "Reduz os gráficos pra rodar mais leve.",
    Id = "antilag", Hotkey = true,
    Callback = function(v)
        Cfg.AntiLag = v
        if v then alEnable() else alRestore() end
    end,
})
local gAL = Jogo.Desempenho:group("O que o Anti-Lag afeta")
for _, item in ipairs({
    { "chars", "Personagens", "Skins e roupas dos outros jogadores (avatar do Roblox)." },
    { "ball", "Bola", "Texturas e materiais da bola." },
    { "court", "Quadra", "Cenário, materiais e texturas da quadra." },
    { "fx", "Efeitos", "Partículas, rastros e luzes (score effects e outros)." },
    { "light", "Iluminação e sombras", "Sombras, névoa e pós-processamento." },
    { "quality", "Qualidade gráfica", "Nível de qualidade do Roblox." },
}) do
    gAL:toggle({
        Title = item[2], Desc = item[3], Id = "al_" .. item[1], Value = true,
        Callback = function(v)
            AL.opts[item[1]] = v
            alRefresh()
        end,
    })
end

local PersonagemPage = UI.tab("Personagem", "Personagem")
local Personagem = { Movimento = PersonagemPage, Camera = PersonagemPage }
local gChar = Personagem.Movimento:group("Shift Lock")
gChar:toggle({
    Title = "Shift Lock Automático", Desc = "Vira o personagem pra câmera ao pular.",
    Id = "autoshift", Hotkey = true,
    Callback = function(v) slSet(v) end,
})
local gCam = Personagem.Camera:group("Tremor de Câmera")
gCam:toggle({
    Title = "Desativar Tremor de Câmera", Desc = "Remove o tremor de câmera do jogo.",
    Id = "noshake", Hotkey = true,
    Callback = function(v)
        csSet(v)
        if v then
            task.delay(0.5, function()
                local n = 0
                for _ in pairs(CS.patched) do n += 1 end
                notify("Câmera", UI.trf("Tremor de câmera: %d módulo(s) tratado(s).", n))
            end)
        end
    end,
})

local VisuaisPage = UI.tab("Visuais", "Visuais")
local Visuais = { Efeitos = VisuaisPage, Previsao = VisuaisPage, Cosmeticos = VisuaisPage }

local gFx = Visuais.Efeitos:group("Efeito de Ponto")
gFx:dropdown({
    Title = "Efeito escolhido", Desc = "Pesquise ou favorite com a estrela.",
    Id = "fx_sel", Options = effects, Value = Cfg.Effect, Favorites = true,
    Callback = function(v) Cfg.Effect = v end,
})
gFx:toggle({
    Title = "Trocar Efeito de Ponto", Desc = "Troca o efeito do seu ponto (só pra você).",
    Id = "fx_on", Hotkey = true,
    Callback = function(v)
        Cfg.EffectOn = v
        fxUpdate()
    end,
})
gFx:toggle({
    Title = "Efeito Aleatório", Desc = "Sorteia um efeito a cada ponto (usa a lista).",
    Id = "fx_rand", Hotkey = true,
    Callback = function(v)
        Cfg.EffectRandom = v
        fxUpdate()
    end,
})

local gList = Visuais.Efeitos:group("Lista de Efeitos (sorteio)")
local addKey = "Adicionar efeito..."
local addDD
addDD = gList:dropdown({
    Title = "Adicionar à lista", Desc = "Escolha um efeito pra entrar no sorteio.",
    Options = effects, Value = addKey,
    Callback = function(v)
        if effectWeights and not effectWeights:Add(v) then notify("Config", "Já está na lista.") end
        addDD:Set(addKey)
    end,
})
effectWeights = gList:weights({
    Id = "fx_list",
    Callback = function(list) Cfg.EffectWeights = list end,
})
gList:button({
    Title = "Normalizar %", Desc = "Ajusta tudo pra somar 100%.",
    Callback = function() effectWeights:Normalize() end,
})
gList:button({
    Title = "Limpar lista", Desc = "Remove todos os efeitos da lista.",
    Callback = function() effectWeights:Clear() end,
})

local gPred = Visuais.Previsao:group("Previsão da Bola")
gPred:toggle({
    Title = "Marcador de Queda", Desc = "Mostra onde a bola cai: dentro, fora ou rede.",
    Id = "pred", Hotkey = true,
    Callback = function(v)
        prSet(v)
    end,
})
gPred:dropdown({
    Title = "Modo do marcador", Desc = "Marcação, Marcação + tempo ou Completo (dentro/fora/rede).",
    Id = "pred_mode", Options = { "Marcação", "Marcação + tempo", "Completo" }, Value = "Completo",
    Callback = function(v) PR.mode = v end,
})
gPred:slider({
    Title = "Tamanho da marcação", Desc = "Tamanho do círculo no chão.",
    Id = "pred_size", Min = 2, Max = 20, Step = 0.5, TypeStep = 0.1, Value = 6,
    Callback = function(v) PR.size = v end,
})

local gBall = Visuais.Cosmeticos:group("Bola")
gBall:dropdown({
    Title = "Skin da bola", Desc = "Pesquise ou favorite com a estrela.",
    Id = "ball_sel", Options = balls, Value = Cfg.Ball, Favorites = true,
    Callback = function(v)
        Cfg.Ball = v
        if Cfg.BallOn then ballApplyAll() end
    end,
})
gBall:toggle({
    Title = "Trocar Skin da Bola", Desc = "Aplica em toda bola nova.",
    Id = "ball_on", Hotkey = true,
    Callback = function(v)
        Cfg.BallOn = v
        childUpdate()
        ballApplyAll()
    end,
})
gBall:toggle({
    Title = "Skin Aleatória", Desc = "Sorteia uma skin a cada bola.",
    Id = "ball_rand", Hotkey = true,
    Callback = function(v)
        Cfg.BallRandom = v
        childUpdate()
        ballApplyAll()
    end,
})

local gJersey = Visuais.Cosmeticos:group("Camisa")
gJersey:dropdown({
    Title = "Camisa", Desc = "Pesquise ou favorite com a estrela.",
    Id = "jersey_sel", Options = jerseys, Value = Cfg.Jersey, Favorites = true,
    Callback = function(v)
        Cfg.Jersey = v
        Jersey.team = nil
        if Cfg.JerseyOn then task.spawn(jerseyApply) end
    end,
})
gJersey:toggle({
    Title = "Trocar Camisa", Desc = "Mantém a camisa (reaplica ao renascer).",
    Id = "jersey_on", Hotkey = true,
    Callback = function(v)
        Cfg.JerseyOn = v
        if v then task.spawn(jerseyApply) else jerseyRestore() end
    end,
})

local gCard = Visuais.Cosmeticos:group("Card do Jogador")
gCard:dropdown({
    Title = "Card", Desc = "Pesquise ou favorite com a estrela.",
    Id = "card_sel", Options = cards, Value = Cfg.Card, Favorites = true,
    Callback = function(v) Cfg.Card = v end,
})
gCard:toggle({
    Title = "Trocar Card", Desc = "Troca o card do seu ponto.",
    Id = "card_on", Hotkey = true,
    Callback = function(v)
        Cfg.CardOn = v
        cardRefresh()
    end,
})
gCard:toggle({
    Title = "Card Aleatório", Desc = "Sorteia um card a cada ponto.",
    Id = "card_rand", Hotkey = true,
    Callback = function(v)
        Cfg.CardRandom = v
        cardRefresh()
    end,
})
gCard:button({
    Title = "Testar Card", Desc = "Mostra o card agora.",
    Callback = function() task.spawn(cardFire) end,
})

local MiscPage = UI.tab("Misc", "Misc")
local Misc = { Recompensas = MiscPage, Idioma = MiscPage }
local gRew = Misc.Recompensas:group("Recompensas")
gRew:button({
    Title = "Coletar Missões", Desc = "Resgata as recompensas de missões prontas.",
    Callback = claimQuests,
})
gRew:button({
    Title = "Coletar Recompensas de Nível", Desc = "Resgata as recompensas de nível disponíveis.",
    Callback = claimLevel,
})
gRew:button({
    Title = "Resgatar Todos os Códigos", Desc = "Busca códigos novos e resgata (até 3).",
    Callback = redeemAll,
})
local gLang = Misc.Idioma:group("Idioma")
gLang:dropdown({
    Title = "Idioma", Desc = "Escolha o idioma da interface.",
    Id = "lang", Options = { "Português", "English" }, Value = "Português",
    Callback = function(v) UI.setLang(v) end,
})

local Protecao = UI.tab("Proteção", "Proteção")
local gProt = Protecao:group("Custom Protect")
gProt:input({
    Title = "Nome", Desc = "Aparece no lugar do seu nome real.",
    Id = "prot_name", Value = Cfg.Name, Placeholder = "Daishyn",
    Callback = function(text)
        text = cleanName(text)
        if text == "" then text = "Daishyn" end
        Cfg.Name = text
        if Cfg.ProtectOn then
            protNametag()
            protCard()
        end
    end,
})
gProt:toggle({
    Title = "Custom Protect", Desc = "Troca seu nome na nametag, avisos e card.",
    Id = "prot_on", Hotkey = true,
    Callback = function(v) setProtect(v) end,
})

local ConfigPage = UI.tab("Config", "Config")
local Config = { Aparencia = ConfigPage, Menu = ConfigPage, Salvas = ConfigPage }
local gCfg = Config.Salvas:group("Configurações Salvas")
local cfgNameInput = gCfg:input({
    Title = "Nome da config", Desc = "Nome pra criar ou renomear uma config.",
    Placeholder = "minha-config",
})
local selectedCfg = nil
local cfgDD
local autoNote

local function displayName(n)
    return readAutoload() == n and (n .. "  [Auto]") or n
end
local function realName(d)
    return (tostring(d):gsub("  %[Auto%]$", ""))
end
local function cfgLists()
    local list, shown = listConfigs(), {}
    for _, n in ipairs(list) do shown[#shown + 1] = displayName(n) end
    return list, shown
end
local function refreshCfgList(selectName)
    local list, shown = cfgLists()
    cfgDD:SetOptions(shown)
    local want = selectName or selectedCfg
    if want and table.find(list, want) then
        selectedCfg = want
        cfgDD:Set(displayName(want))
    else
        selectedCfg = nil
        cfgDD:Set("-")
    end
end
local function renameConfig(old, new)
    if not (isfile and readfile and writefile and delfile) then return false end
    local ok, raw = pcall(readfile, cfgPath(old))
    if not ok or not pcall(writefile, cfgPath(new), raw) then return false end
    pcall(delfile, cfgPath(old))
    if readAutoload() == old then writeAutoload(new) end
    return true
end
local _, initialShown = cfgLists()
cfgDD = gCfg:dropdown({
    Title = "Config escolhida", Desc = "Pesquise ou escolha uma. [Auto] carrega ao iniciar.",
    Options = initialShown, Value = "-",
    Callback = function(v) selectedCfg = realName(v) end,
})
local function needSelected()
    if not selectedCfg then notify("Config", "Escolha uma config na lista.") return false end
    return true
end
gCfg:button({
    Title = "Criar", Desc = "Salva as opções atuais com o nome digitado.",
    Callback = function()
        local name = cleanName(cfgNameInput:Get())
        if name == "" then notify("Config", "Digite um nome primeiro.") return end
        if cfgExists(name) then notify("Config", "Já existe. Use Sobrescrever.") return end
        if saveConfig(name) then
            notify("Config", UI.trf("Criada: %s", name))
            refreshCfgList(name)
        end
    end,
})
gCfg:button({
    Title = "Carregar", Desc = "Aplica a config escolhida.",
    Callback = function()
        if needSelected() then loadConfig(selectedCfg) end
    end,
})
gCfg:button({
    Title = "Sobrescrever", Desc = "Atualiza a escolhida com as opções atuais.",
    Callback = function()
        if needSelected() and saveConfig(selectedCfg) then
            notify("Config", UI.trf("Atualizada: %s", selectedCfg))
        end
    end,
})
gCfg:button({
    Title = "Renomear", Desc = "Renomeia a escolhida pro nome digitado.",
    Callback = function()
        if not needSelected() then return end
        local name = cleanName(cfgNameInput:Get())
        if name == "" then notify("Config", "Digite um nome primeiro.") return end
        if cfgExists(name) then notify("Config", "Já existe. Use Sobrescrever.") return end
        if renameConfig(selectedCfg, name) then
            notify("Config", UI.trf("Renomeada: %s", name))
            refreshCfgList(name)
            autoNote:SetText(autoText())
        else
            notify("Config", "Não consegui renomear.")
        end
    end,
})
gCfg:button({
    Title = "Apagar", Desc = "Remove a config escolhida.",
    Callback = function()
        if not needSelected() then return end
        local name = selectedCfg
        local ok = delfile and pcall(delfile, cfgPath(name))
        if ok then
            if readAutoload() == name then writeAutoload("") end
            notify("Config", UI.trf("Apagada: %s", name))
            selectedCfg = nil
            refreshCfgList()
            autoNote:SetText(autoText())
        else
            notify("Config", "Não consegui apagar.")
        end
    end,
})
gCfg:button({
    Title = "Definir como Auto Load", Desc = "Carrega sozinha ao iniciar o script.",
    Callback = function()
        if needSelected() and writeAutoload(selectedCfg) then
            autoNote:SetText(autoText())
            refreshCfgList()
            notify("Config", UI.trf("Auto load: %s", selectedCfg or "-"))
        end
    end,
})
gCfg:button({
    Title = "Limpar Auto Load", Desc = "Para de carregar automaticamente.",
    Callback = function()
        writeAutoload("")
        autoNote:SetText(autoText())
        refreshCfgList()
        notify("Config", "Auto load removido.")
    end,
})
autoNote = gCfg:note(autoText())

UI.setHint("Pílula ou tecla do painel")
UI.select("Jogo")
print("[Daishyn] pronto.")

local autoName = readAutoload()
if autoName and mine() then
    loadConfig(autoName, true)
end
UI.reveal()
notify("Daishyn", "Carregado. Toque na pílula pra abrir/fechar.")
end
buildMenu()

end

local ok, err = xpcall(main, function(e) return debug.traceback(tostring(e), 2) end)
if not ok then warn("[Daishyn] " .. tostring(err)) end

-- ============================================================
-- INTEGRAÇÃO: Auto Farm (aba dentro do hub)
-- ============================================================

task.spawn(function()
    -- Espera o hub montar
    local tries = 0
    while tries < 200 and not _G.DaishynUI do
        tries = tries + 1
        task.wait(0.05)
    end

    local UIref = _G.DaishynUI
    local STATEref = _G.__DaishynState

    -- ========================================================
    -- 1) AUTO FARM — aba dentro do hub
    -- ========================================================

    if UIref and UIref.tab then
        local okAF, errAF = pcall(function()
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local RunService = game:GetService("RunService")
            local Workspace = game:GetService("Workspace")
            local LocalPlayer = Players.LocalPlayer
            local Camera = Workspace.CurrentCamera

            local function getRF(name)
                local ok1, rf = pcall(function()
                    return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"]
                        .knit.Services.BallService.RF[name]
                end)
                if ok1 and rf then return rf end
                local ok2, rf2 = pcall(function()
                    local Index = ReplicatedStorage.Packages._Index
                    for _, folder in Index:GetChildren() do
                        if folder.Name:find("knit") then
                            local knit = folder:FindFirstChild("knit")
                            if knit then
                                local svc = knit:FindFirstChild("Services")
                                    and knit.Services:FindFirstChild("BallService")
                                if svc then
                                    local RF = svc:FindFirstChild("RF")
                                    if RF then return RF:FindFirstChild(name) end
                                end
                            end
                        end
                    end
                    return nil
                end)
                return ok2 and rf2 or nil
            end

            local Remotes = {
                CreateHitbox = getRF("CreateHitbox"),
                Interact     = getRF("Interact"),
                Jump         = getRF("Jump"),
                UpdateTilt   = getRF("UpdateTilt"),
            }

            local AF = {
                tp = false, block = false, spike = false, jump = false,
                interval = 0.05, tpOffset = 3, jumpState = false, running = false,
            }

            local function getBall()
                for _, value in ipairs(Workspace:GetDescendants()) do
                    if typeof(value.Name) == "string" and value.Name:sub(1, 12) == "CLIENT_BALL_" then
                        local part = value:IsA("BasePart") and value
                            or value:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local id = value:GetAttribute("ServerId")
                                or part:GetAttribute("ServerId")
                                or value:GetAttribute("Id")
                                or part:GetAttribute("Id")
                                or tonumber(value.Name:sub(13))
                            if id then return part, id end
                        end
                    end
                end
                return nil, 0
            end

            local function getHRP()
                local c = LocalPlayer.Character
                return c and c:FindFirstChild("HumanoidRootPart")
            end

            local function getTimestamp()
                local okT, t = pcall(function() return Workspace:GetServerTimeNow() end)
                if okT and typeof(t) == "number" then return t end
                return tick()
            end

            local AFtab = UIref.tab("Auto Farm", "Jogo")
            local gAF = AFtab:group("Auto Farm")

            local tpConn, mainThread

            local function startTP()
                if tpConn then tpConn:Disconnect() end
                tpConn = RunService.Heartbeat:Connect(function()
                    if not AF.running or not AF.tp then return end
                    local ball = getBall()
                    local hrp = getHRP()
                    if ball and hrp then
                        local target = ball.Position + Vector3.new(0, ball.Size.Y * 0.5 + AF.tpOffset, 0)
                        pcall(function()
                            hrp.CFrame = CFrame.new(target, target + Camera.CFrame.LookVector)
                        end)
                    end
                end)
            end

            local function startLoop()
                if mainThread then return end
                startTP()
                mainThread = task.spawn(function()
                    while AF.running do
                        local waitT = AF.interval or 0.05
                        local ball, bid = getBall()
                        local hrp = getHRP()
                        local look = Camera and Camera.CFrame.LookVector or Vector3.new(0, 0, -1)
                        local move = hrp and hrp.CFrame.LookVector or Vector3.zero
                        local tilt = Vector3.new(0, 1, 0)
                        local ts = getTimestamp()

                        if AF.block and bid ~= 0 and ball and Remotes.CreateHitbox and Remotes.Interact then
                            local key = "Block" .. math.random(1000000, 9999999)
                            pcall(function()
                                Remotes.CreateHitbox:InvokeServer({
                                    BallId = bid, Charge = 1, Key = key,
                                    ClientTimestamp = ts, Move = "Block",
                                })
                            end)
                            pcall(function()
                                Remotes.Interact:InvokeServer({
                                    Charge = 1, Move = "Block", SpecialCharge = 0,
                                    TiltDirection = tilt, BallId = bid, MoveDirection = move,
                                    Key = key, From = "Client", LookVector = look,
                                    Timestamp = ts, ClientCanRunSpecial = false,
                                    CustomClient = {},
                                })
                            end)
                            if Remotes.UpdateTilt then
                                pcall(function() Remotes.UpdateTilt:InvokeServer(tilt) end)
                            end
                        end

                        if AF.spike and not AF.block and bid ~= 0 and ball and Remotes.Interact then
                            local realTilt = Vector3.new(look.X, 1, look.Z)
                            pcall(function()
                                Remotes.Interact:InvokeServer({
                                    Charge = 1, Move = "Spike", SpecialCharge = 0,
                                    TiltDirection = realTilt, LookVector = look,
                                    MoveDirection = move, ClientCanRunSpecial = false,
                                    From = "Client", Timestamp = ts, BallId = bid,
                                    CustomClient = {},
                                })
                            end)
                            if Remotes.UpdateTilt then
                                pcall(function() Remotes.UpdateTilt:InvokeServer(realTilt) end)
                            end
                        end

                        if AF.jump and Remotes.Jump then
                            AF.jumpState = not AF.jumpState
                            pcall(function() Remotes.Jump:InvokeServer(AF.jumpState) end)
                        end

                        task.wait(waitT)
                    end
                end)
            end

            gAF:toggle({
                Title = "Teleport para bola",
                Desc = "Mantém o personagem em cima da bola.",
                Id = "af_tp", Hotkey = true,
                Callback = function(v) AF.tp = v end,
            })
            gAF:toggle({
                Title = "Block automático",
                Desc = "Bloqueia a bola automaticamente.",
                Id = "af_block", Hotkey = true,
                Callback = function(v) AF.block = v end,
            })
            gAF:toggle({
                Title = "Spike automático",
                Desc = "Ataca a bola automaticamente (não roda junto com Block).",
                Id = "af_spike", Hotkey = true,
                Callback = function(v) AF.spike = v end,
            })
            gAF:toggle({
                Title = "Pular (farm de salto)",
                Desc = "Alterna pulo automaticamente.",
                Id = "af_jump", Hotkey = true,
                Callback = function(v) AF.jump = v end,
            })
            gAF:slider({
                Title = "Intervalo", Desc = "Tempo entre cada ação em segundos.",
                Id = "af_interval", Min = 0.03, Max = 0.3, Step = 0.01, TypeStep = 0.01, Value = 0.05,
                Callback = function(v) AF.interval = v end,
            })
            gAF:slider({
                Title = "Offset do TP", Desc = "Altura acima da bola.",
                Id = "af_offset", Min = 1, Max = 8, Step = 0.5, Value = 3,
                Callback = function(v) AF.tpOffset = v end,
            })
            gAF:toggle({
                Title = "Iniciar Auto Farm",
                Desc = "Liga o loop principal.",
                Id = "af_on", Hotkey = true,
                Callback = function(v)
                    AF.running = v
                    if v then
                        startLoop()
                    else
                        AF.tp, AF.block, AF.spike, AF.jump = false, false, false, false
                        if tpConn then pcall(function() tpConn:Disconnect() end); tpConn = nil end
                        mainThread = nil
                    end
                end,
            })

            if STATEref and STATEref.onCleanup then
                STATEref.onCleanup(function()
                    AF.running = false
                    if tpConn then pcall(function() tpConn:Disconnect() end) end
                    mainThread = nil
                end)
            end
        end)
        if not okAF then
            warn("[Daishyn] falha no Auto Farm: " .. tostring(errAF))
        end
    end

end)