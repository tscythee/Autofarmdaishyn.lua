--[[
    ScyFe Auto Rollback Style (v2)
    Jogo: Volleyball Legends

    Gira estilos OU habilidades ate vir o alvo. Se nao vier dentro do limite de
    spins, faz o "Data Rollback" (restaura os spins) e tenta de novo.

    MODO MANUAL:    abra o menu (botao RS ou RightShift) e clique em INICIAR SPIN.
    MODO AUTOMATICO: coloque este arquivo na pasta autoexec do injetor.
        - Ligue "Iniciar automaticamente" no menu, ou
        - defina antes da execucao (opcional):
            getgenv().ScyFeAutoRollbackConfig = {
                mode = "Style",            -- "Style" ou "Ability"
                targetStyle = "Sanju", spinType = "Lucky", slot = "2",
                targetAbility = "Shield Breaker", abilityType = "Normal",
                spinsPerCycle = 10, useRollback = true, autoStart = true,
            }
    Depois do rollback o jogo reinicia (teleport); o autoexec roda o script de novo
    e ele continua sozinho de onde parou (por ate 5 minutos).

    API: _G.ScyFeAutoRollback.Start() / .Stop() / .Unload()
]]

if _G.ScyFeAutoRollback and _G.ScyFeAutoRollback.Unload then
    pcall(_G.ScyFeAutoRollback.Unload)
end

-- Autoexec roda cedo demais: espera o jogo e o jogador existirem
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

-- ============================================================
-- Conexoes (para limpar no Unload)
-- ============================================================

local conns = {}
local function track(c)
    conns[#conns + 1] = c
    return c
end

-- ============================================================
-- Remotes (procurados na hora de usar, nunca so no inicio)
-- ============================================================

-- A chave do rollback tem um zero-width space (U+200B) entre "Spike" e o byte 143.
-- Escrita com escapes decimais para o caractere invisivel nao se perder ao copiar.
local ROLLBACK_KEY = "Spike\226\128\139\143"

local function findRemote(serviceName, remoteName)
    local ok, remote = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services[serviceName].RF[remoteName]
    end)
    if ok and remote then return remote end
    return nil
end

-- ============================================================
-- Cores e helpers de GUI
-- ============================================================

local Colors = {
    bg      = Color3.fromRGB(16, 17, 22),
    top     = Color3.fromRGB(24, 26, 34),
    raised  = Color3.fromRGB(32, 35, 45),
    line    = Color3.fromRGB(50, 55, 70),
    text    = Color3.fromRGB(232, 235, 245),
    sub     = Color3.fromRGB(150, 158, 180),
    accent  = Color3.fromRGB(255, 170, 60),
    accentD = Color3.fromRGB(200, 130, 30),
    good    = Color3.fromRGB(0, 160, 90),
    goodD   = Color3.fromRGB(0, 110, 60),
    bad     = Color3.fromRGB(220, 70, 70),
}

local function getHiddenParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
    if type(protect_gui) == "function" then pcall(protect_gui, gui) end
    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    end
end

local function newInstance(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(inst, radius)
    return newInstance("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

local function stroke(inst, color, thickness, transparency)
    return newInstance("UIStroke", {
        Color = color or Colors.line,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

local function padding(inst, l, r, t, b)
    return newInstance("UIPadding", {
        PaddingLeft = UDim.new(0, l),
        PaddingRight = UDim.new(0, r),
        PaddingTop = UDim.new(0, t),
        PaddingBottom = UDim.new(0, b),
    }, inst)
end

local function vlist(inst, gap)
    return newInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 6),
    }, inst)
end

-- ============================================================
-- Config (arquivo) + config opcional via getgenv
-- ============================================================

local CONFIG_FOLDER = "ScyFeAutoRollback"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function fsReady()
    return type(writefile) == "function" and type(readfile) == "function"
        and type(isfile) == "function" and type(isfolder) == "function"
        and type(makefolder) == "function"
end

local function loadConfig()
    local cfg = {
        mode = "Style",
        targetStyle = "Ronin",
        spinType = "Normal",
        targetAbility = "Shield Breaker",
        abilityType = "Normal",
        slot = "Atual",
        useRollback = true,
        spinsPerCycle = 10,
        interval = 0.5,
        autoStart = false,
        cycles = 0,
        resume = false,
        resumeAt = 0,
    }
    if fsReady() then
        pcall(function()
            if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        end)
        local ok, raw = pcall(function()
            if isfile(CONFIG_FILE) then return readfile(CONFIG_FILE) end
            return nil
        end)
        if ok and raw and raw ~= "" then
            local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(data) == "table" then
                for k, v in pairs(data) do cfg[k] = v end
            end
        end
    end
    return cfg
end

local function saveConfig(cfg)
    if not fsReady() then return end
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
end

local SavedCfg = loadConfig()

-- Config explicita via getgenv tem prioridade sobre o arquivo salvo
local override = nil
if type(getgenv) == "function" then
    local okEnv, env = pcall(getgenv)
    if okEnv and type(env) == "table" and type(env.ScyFeAutoRollbackConfig) == "table" then
        override = env.ScyFeAutoRollbackConfig
    end
end
if override then
    for _, key in ipairs({ "mode", "targetStyle", "spinType", "targetAbility", "abilityType", "slot", "useRollback", "spinsPerCycle", "interval", "autoStart" }) do
        if override[key] ~= nil then SavedCfg[key] = override[key] end
    end
end

-- ============================================================
-- Estado
-- ============================================================

local SLOT_OPTIONS = { "Atual", "1", "2", "3", "4", "+" }

local function validSlot(v)
    v = tostring(v or "Atual")
    for _, o in ipairs(SLOT_OPTIONS) do
        if o == v then return v end
    end
    return "Atual"
end

local ABILITY_LIST = {
    "Shield Breaker", "Magnetic Pull", "Lead Feet", "Extra Touch", "Godly", "Redirection Jump",
    "Curve Spike", "Divine Strength", "Legendary", "Steel Block", "Zero Gravity Set", "Rare",
    "Boom Jump", "Moonball", "Common", "Super Sprint", "Team Spirit", "Rolling Thunder",
}

local State = {
    running = false,
    token = 0,
    mode = (SavedCfg.mode == "Ability") and "Ability" or "Style",
    targetStyle = tostring(SavedCfg.targetStyle or "Ronin"),
    spinType = (SavedCfg.spinType == "Lucky") and "Lucky" or "Normal",
    targetAbility = tostring(SavedCfg.targetAbility or "Shield Breaker"),
    abilityType = (SavedCfg.abilityType == "Lucky") and "Lucky" or "Normal",
    slot = validSlot(SavedCfg.slot),
    useRollback = SavedCfg.useRollback ~= false,
    spinsPerCycle = math.max(1, math.floor(tonumber(SavedCfg.spinsPerCycle) or 10)),
    interval = math.max(0.1, tonumber(SavedCfg.interval) or 0.5),
    autoStart = SavedCfg.autoStart == true,
    cycles = math.max(0, math.floor(tonumber(SavedCfg.cycles) or 0)),
    currentTries = 0,
}

-- "resume" = estava rodando quando o script/jogo foi encerrado (ex.: teleport do rollback)
local function persist()
    saveConfig({
        mode = State.mode,
        targetStyle = State.targetStyle,
        spinType = State.spinType,
        targetAbility = State.targetAbility,
        abilityType = State.abilityType,
        slot = State.slot,
        useRollback = State.useRollback,
        spinsPerCycle = State.spinsPerCycle,
        interval = State.interval,
        autoStart = State.autoStart,
        cycles = State.cycles,
        resume = State.running,
        resumeAt = os.time(),
    })
end

local STYLE_LIST = {
    "Ronin", "Hidari", "Jinko", "Timeskip Hinto", "Timeskip Kyamo", "Akuto", "Taichou", "Sanju",
    "Mikage", "Kazana", "Timeskip Okazu", "Kisuki", "Bakuri", "Kyamo", "Okazu", "Hirakumi",
    "Kozai", "Azmei", "Uchikai", "Yokai", "Yogan", "Sazuroku", "Kyoshin", "Yomosuke", "Oyatsu",
    "Tsuchiro", "Imaezi", "Tonkura", "Ninyoku", "Hinto", "Hakochi", "Yakisukai", "Sagumi",
    "Koshoti",
}

-- ============================================================
-- GUI
-- ============================================================

local ScreenGui = newInstance("ScreenGui", {
    Name = "ScyFe_AutoRollbackStyle",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
})
protect(ScreenGui)
ScreenGui.Parent = getHiddenParent()

local FloatBtn = newInstance("TextButton", {
    Size = UDim2.fromOffset(56, 56),
    Position = UDim2.new(0, 12, 0.5, -28),
    BackgroundColor3 = Colors.top,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Text = "RS",
    TextColor3 = Colors.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    Selectable = false,
    ZIndex = 50,
}, ScreenGui)
corner(FloatBtn, 28)
local FloatStroke = stroke(FloatBtn, Colors.accent, 2, 0.35)

local Window = newInstance("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 80, 0.5, 0),
    Size = UDim2.fromOffset(310, 500),
    BackgroundColor3 = Colors.bg,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 40,
}, ScreenGui)
corner(Window, 12)
stroke(Window, Colors.line, 1)

local TopBar = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Colors.top,
    BorderSizePixel = 0,
    ZIndex = 41,
}, Window)
corner(TopBar, 12)
newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = Colors.top,
    BorderSizePixel = 0,
    ZIndex = 41,
}, TopBar)
newInstance("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "AUTO ROLLBACK STYLE",
    ZIndex = 42,
}, TopBar)

local CloseBtn = newInstance("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(26, 26),
    BackgroundColor3 = Colors.raised,
    BorderSizePixel = 0,
    Text = "X",
    TextColor3 = Colors.sub,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 42,
}, TopBar)
corner(CloseBtn, 8)

-- Arrastar. onTap so dispara se nao houve arrasto (evita abrir/fechar ao mover o botao)
local function makeDraggable(handle, target, onTap)
    local dragging = false
    local moved = false
    local dragStart, posStart
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            posStart = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onTap then onTap() end
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(
                    posStart.X.Scale, posStart.X.Offset + delta.X,
                    posStart.Y.Scale, posStart.Y.Offset + delta.Y
                )
            end
        end
    end))
end

local guiVisible = false
local function setGuiVisible(v)
    guiVisible = v
    Window.Visible = v
end

makeDraggable(TopBar, Window, nil)
makeDraggable(FloatBtn, FloatBtn, function() setGuiVisible(not guiVisible) end)
track(CloseBtn.MouseButton1Click:Connect(function() setGuiVisible(false) end))
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setGuiVisible(not guiVisible)
    end
end))

local Scroll = newInstance("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(1, 0, 1, -42),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Colors.line,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ZIndex = 41,
}, Window)
padding(Scroll, 12, 12, 12, 12)
vlist(Scroll, 10)

local function makeSection(title, order)
    local box = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Colors.raised,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 42,
    }, Scroll)
    corner(box, 8)
    stroke(box, Colors.line, 1)
    padding(box, 10, 10, 8, 10)
    vlist(box, 6)
    newInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
        LayoutOrder = 0,
        ZIndex = 43,
    }, box)
    return box
end

-- Dropdown: a caixa usa LayoutOrder = order e a lista logo abaixo usa order + 1
local function makeDropdown(parent, order, prefix, options, initial, onSelect)
    local box = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Colors.bg,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 42,
    }, parent)
    corner(box, 6)
    stroke(box, Colors.line, 1)

    local label = newInstance("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = prefix .. initial,
        ZIndex = 43,
    }, box)

    local arrow = newInstance("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.accent,
        Text = "v",
        ZIndex = 43,
    }, box)

    local click = newInstance("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 44,
    }, box)

    local list = newInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Colors.bg,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Colors.line,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        LayoutOrder = order + 1,
        ZIndex = 45,
    }, parent)
    corner(list, 6)
    stroke(list, Colors.line, 1)
    padding(list, 4, 4, 4, 4)
    vlist(list, 2)

    local open = false
    local function setOpen(v)
        open = v
        list.Visible = v
        if v then
            list.Size = UDim2.new(1, 0, 0, math.min(#options * 28 + 8, 150))
            arrow.Text = "^"
        else
            list.Size = UDim2.new(1, 0, 0, 0)
            arrow.Text = "v"
        end
    end

    for i, opt in ipairs(options) do
        local item = newInstance("TextButton", {
            Size = UDim2.new(1, -8, 0, 26),
            BackgroundColor3 = Colors.raised,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Colors.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = opt,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 46,
        }, list)
        corner(item, 4)
        padding(item, 8, 8, 0, 0)
        track(item.MouseButton1Click:Connect(function()
            label.Text = prefix .. opt
            setOpen(false)
            onSelect(opt)
        end))
    end

    track(click.MouseButton1Click:Connect(function() setOpen(not open) end))

    return {
        Set = function(value) label.Text = prefix .. value end,
    }
end

local function makeNumberRow(parent, text, order, initial, minV, maxV, isInt, onCommit)
    local box = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Colors.bg,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 42,
    }, parent)
    corner(box, 6)
    stroke(box, Colors.line, 1)

    newInstance("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        ZIndex = 43,
    }, box)

    local input = newInstance("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(50, 22),
        BackgroundColor3 = Colors.raised,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.accent,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        Text = tostring(initial),
        ZIndex = 44,
    }, box)
    corner(input, 4)
    stroke(input, Colors.line, 1)

    local current = initial
    track(input.FocusLost:Connect(function()
        local n = tonumber(input.Text)
        if n then
            if isInt then
                n = math.floor(n)
            else
                n = math.floor(n * 100 + 0.5) / 100
            end
            n = math.clamp(n, minV, maxV)
            current = n
            onCommit(n)
        end
        input.Text = tostring(current)
    end))
end

local function makeToggle(parent, text, order, initial, onChange)
    local box = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        ZIndex = 42,
    }, parent)

    newInstance("TextLabel", {
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Colors.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        ZIndex = 43,
    }, box)

    local pill = newInstance("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(38, 20),
        BorderSizePixel = 0,
        ZIndex = 43,
    }, box)
    corner(pill, 10)
    local pillStroke = stroke(pill, Colors.line, 1)
    local knob = newInstance("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(14, 14),
        BorderSizePixel = 0,
        ZIndex = 44,
    }, pill)
    corner(knob, 7)

    local click = newInstance("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 45,
    }, box)

    local value = initial
    local function paint(animate)
        local pos
        if value then
            pill.BackgroundColor3 = Colors.accentD
            pillStroke.Color = Colors.accent
            knob.BackgroundColor3 = Colors.text
            pos = UDim2.new(1, -17, 0.5, 0)
        else
            pill.BackgroundColor3 = Colors.raised
            pillStroke.Color = Colors.line
            knob.BackgroundColor3 = Colors.sub
            pos = UDim2.new(0, 3, 0.5, 0)
        end
        if animate then
            TweenService:Create(knob, TweenInfo.new(0.15), { Position = pos }):Play()
        else
            knob.Position = pos
        end
    end

    track(click.MouseButton1Click:Connect(function()
        value = not value
        paint(true)
        onChange(value)
    end))
    paint(false)
end

-- Botoes lado a lado (um selecionado)
local function makeSegmented(parent, order, options, initial, onSelect)
    local row = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        ZIndex = 42,
    }, parent)
    newInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, row)

    local count = #options
    local gap = 4
    local buttons = {}
    local selected = initial

    local function paint()
        for opt, b in pairs(buttons) do
            if opt == selected then
                b.BackgroundColor3 = Colors.accentD
                b.TextColor3 = Colors.text
            else
                b.BackgroundColor3 = Colors.bg
                b.TextColor3 = Colors.sub
            end
        end
    end

    for i, opt in ipairs(options) do
        local b = newInstance("TextButton", {
            Size = UDim2.new(1 / count, -((count - 1) * gap) / count, 1, 0),
            BackgroundColor3 = Colors.bg,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Colors.sub,
            Text = opt,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 43,
        }, row)
        corner(b, 6)
        stroke(b, Colors.line, 1)
        buttons[opt] = b
        track(b.MouseButton1Click:Connect(function()
            selected = opt
            paint()
            onSelect(opt)
        end))
    end
    paint()
end

-- Configuracoes
local ConfigBox = makeSection("Configuracoes", 1)

local function makeGroup(parent, order)
    local g = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 42,
    }, parent)
    vlist(g, 6)
    return g
end

local StyleGroup = makeGroup(ConfigBox, 3)
local AbilityGroup = makeGroup(ConfigBox, 4)

local function applyMode()
    StyleGroup.Visible = State.mode ~= "Ability"
    AbilityGroup.Visible = State.mode == "Ability"
end

makeDropdown(ConfigBox, 1, "Modo: ", { "Estilo", "Habilidade" },
    (State.mode == "Ability") and "Habilidade" or "Estilo", function(opt)
    State.mode = (opt == "Habilidade") and "Ability" or "Style"
    applyMode()
    persist()
end)

-- Grupo Estilo
makeDropdown(StyleGroup, 1, "Estilo: ", STYLE_LIST, State.targetStyle, function(style)
    State.targetStyle = style
    persist()
end)

makeDropdown(StyleGroup, 3, "Tipo: ", { "Normal", "Lucky" }, State.spinType, function(kind)
    State.spinType = kind
    persist()
end)

newInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Colors.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Slot do estilo (Atual = nao troca de slot)",
    LayoutOrder = 5,
    ZIndex = 43,
}, StyleGroup)

makeSegmented(StyleGroup, 6, SLOT_OPTIONS, State.slot, function(opt)
    State.slot = opt
    persist()
end)

-- Grupo Habilidade
makeDropdown(AbilityGroup, 1, "Habilidade: ", ABILITY_LIST, State.targetAbility, function(ability)
    State.targetAbility = ability
    persist()
end)

makeDropdown(AbilityGroup, 3, "Tipo: ", { "Normal", "Lucky" }, State.abilityType, function(kind)
    State.abilityType = kind
    persist()
end)

applyMode()

makeNumberRow(ConfigBox, "Spins por ciclo", 5, State.spinsPerCycle, 1, 9999, true, function(n)
    State.spinsPerCycle = n
    persist()
end)

makeNumberRow(ConfigBox, "Intervalo por spin (s)", 6, State.interval, 0.1, 10, false, function(n)
    State.interval = n
    persist()
end)

makeToggle(ConfigBox, "Rollback se falhar", 7, State.useRollback, function(v)
    State.useRollback = v
    persist()
end)

makeToggle(ConfigBox, "Iniciar automaticamente", 8, State.autoStart, function(v)
    State.autoStart = v
    persist()
end)

-- Controle
local CtrlBox = makeSection("Controle", 2)

local statusLabel = newInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Colors.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "Pronto.",
    LayoutOrder = 1,
    ZIndex = 43,
}, CtrlBox)

local startBtn = newInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Colors.good,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.text,
    Text = "INICIAR SPIN",
    AutoButtonColor = false,
    LayoutOrder = 2,
    ZIndex = 43,
}, CtrlBox)
corner(startBtn, 8)

local stopBtn = newInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Colors.bad,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.text,
    Text = "PARAR",
    AutoButtonColor = false,
    LayoutOrder = 3,
    ZIndex = 43,
}, CtrlBox)
corner(stopBtn, 8)

local mapBtn = newInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Colors.top,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Colors.sub,
    Text = "MAPEAR SLOTS (diagnostico)",
    AutoButtonColor = false,
    LayoutOrder = 4,
    ZIndex = 43,
}, CtrlBox)
corner(mapBtn, 8)
stroke(mapBtn, Colors.line, 1)

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or Colors.sub
end

local function paintButtons()
    if State.running then
        startBtn.Text = "RODANDO..."
        startBtn.BackgroundColor3 = Colors.goodD
        FloatStroke.Color = Colors.good
    else
        startBtn.Text = "INICIAR SPIN"
        startBtn.BackgroundColor3 = Colors.good
        FloatStroke.Color = Colors.accent
    end
end

local function targetText()
    if State.mode == "Ability" then
        return State.targetAbility .. " | " .. State.abilityType
    end
    return State.targetStyle .. " | " .. State.spinType .. " | slot " .. State.slot
end

setStatus("Pronto. " .. targetText(), Colors.sub)

-- ============================================================
-- Logica
-- ============================================================

local function modeInfo()
    if State.mode == "Ability" then
        return {
            service = "AbilityService", panel = "Abilities", noun = "habilidade",
            target = State.targetAbility, lucky = (State.abilityType == "Lucky"),
        }
    end
    return {
        service = "StyleService", panel = "Styles", noun = "estilo",
        target = State.targetStyle, lucky = (State.spinType == "Lucky"),
    }
end

local function getLobbyPanel(panelName)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local interface = gui and gui:FindFirstChild("Interface")
    local lobby = interface and interface:FindFirstChild("Lobby")
    return lobby and lobby:FindFirstChild(panelName)
end

-- Texto atual do painel (estilo ou habilidade equipada/girada)
local function getCurrentValue()
    local panel = getLobbyPanel(modeInfo().panel)
    local topPanel = panel and panel:FindFirstChild("TopPanel")
    local displayName = topPanel and topPanel:FindFirstChild("DisplayName")
    if not displayName then return nil end
    local ok, txt = pcall(function() return displayName.Text end)
    if ok and type(txt) == "string" and txt ~= "" then return txt end
    return nil
end

local function norm(s)
    s = tostring(s or "")
    s = s:gsub("<[^>]+>", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s:lower()
end

local function isTarget(current)
    return current ~= nil and norm(current) == norm(modeInfo().target)
end

local function isReady()
    return getCurrentValue() ~= nil and findRemote(modeInfo().service, "Roll") ~= nil
end

local function waitTime(seconds, alive)
    local t0 = os.clock()
    while alive() and os.clock() - t0 < seconds do
        task.wait(0.1)
    end
end

-- ---------- Slots (so estilo) ----------

local BLOCK_WORDS = { "buy", "purchase", "robux", "shop", "gamepass", "product", "premium", "vip" }

local function looksLikePurchase(inst)
    local path = inst:GetFullName():lower()
    for _, w in ipairs(BLOCK_WORDS) do
        if path:find(w, 1, true) then return true end
    end
    return false
end

-- Clica num GuiButton chamando os eventos dele
local function pressButton(btn)
    local fired = false
    if type(firesignal) == "function" then
        local a = pcall(firesignal, btn.MouseButton1Click)
        local b = pcall(firesignal, btn.Activated)
        fired = a or b
    end
    if not fired and type(getconnections) == "function" then
        for _, sig in ipairs({ btn.MouseButton1Click, btn.Activated }) do
            local okc, list = pcall(getconnections, sig)
            if okc and type(list) == "table" then
                for _, c in ipairs(list) do
                    if pcall(function() c:Fire() end) then fired = true end
                end
            end
        end
    end
    return fired
end

-- Procura o botao do slot dentro do painel de estilos (so botoes que parecem slot)
local function findSlotButton(slot)
    local styles = getLobbyPanel("Styles")
    if not styles then return nil end
    local names, texts
    if slot == "+" then
        names = { ["slot5"] = true, ["5"] = true, ["plus"] = true, ["extra"] = true, ["extraslot"] = true, ["addslot"] = true }
        texts = { ["+"] = true, ["5"] = true }
    else
        names = { [slot] = true, ["slot" .. slot] = true }
        texts = { [slot] = true }
    end
    for _, d in ipairs(styles:GetDescendants()) do
        if d:IsA("GuiButton") and not looksLikePurchase(d) then
            local nm = (d.Name:lower():gsub("[%s_%-]", ""))
            if names[nm] then return d end
            if d:IsA("TextButton") then
                local t = norm(d.Text)
                if texts[t] then return d end
            end
        end
    end
    return nil
end

local function selectSlot(slot)
    if slot == "Atual" then return true, "slot atual" end
    local btn = findSlotButton(slot)
    if not btn then
        return false, "botao do slot " .. slot .. " nao encontrado (use MAPEAR SLOTS)"
    end
    if not pressButton(btn) then
        return false, "nao consegui clicar no slot (executor sem firesignal/getconnections)"
    end
    return true, btn:GetFullName()
end

-- Diagnostico: lista remotes dos servicos e botoes do painel de estilos
local function dumpInfo()
    local lines = {}
    local function add(t) lines[#lines + 1] = t end
    add("== ScyFe dump ==")
    for _, svc in ipairs({ "StyleService", "AbilityService" }) do
        local ok, folder = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services[svc]
        end)
        if ok and folder then
            for _, kind in ipairs({ "RF", "RE" }) do
                local sub = folder:FindFirstChild(kind)
                if sub then
                    local list = {}
                    for _, c in ipairs(sub:GetChildren()) do list[#list + 1] = c.Name end
                    add(svc .. "." .. kind .. ": " .. table.concat(list, ", "))
                end
            end
        else
            add(svc .. ": nao encontrado")
        end
    end
    local styles = getLobbyPanel("Styles")
    if styles then
        local count = 0
        for _, d in ipairs(styles:GetDescendants()) do
            if d:IsA("GuiObject") and count < 300 then
                local nm = d.Name:lower()
                local interesting = d:IsA("GuiButton")
                    or nm:find("slot", 1, true) or nm:find("lock", 1, true)
                    or nm:find("plus", 1, true) or nm:find("equip", 1, true)
                    or nm:find("select", 1, true)
                if interesting then
                    count = count + 1
                    local txt = ""
                    local okT, t = pcall(function() return d.Text end)
                    if okT and type(t) == "string" then txt = t end
                    local path = (d:GetFullName():gsub("^.-Styles", "Styles"))
                    add(string.format("%s | %s | text=%q | visible=%s", path, d.ClassName, txt, tostring(d.Visible)))
                end
            end
        end
    else
        add("Painel Styles nao encontrado (esteja no lobby).")
    end
    local text = table.concat(lines, "\n")
    for _, l in ipairs(lines) do print("[ScyFe dump] " .. l) end
    local saved = false
    if fsReady() then
        saved = pcall(function() writefile(CONFIG_FOLDER .. "/dump.txt", text) end)
    end
    local copied = false
    if type(setclipboard) == "function" then
        copied = pcall(setclipboard, text)
    end
    setStatus(string.format("Mapa gerado (%d linhas). Clipboard: %s | arquivo: %s",
        #lines, copied and "sim" or "nao", saved and "dump.txt" or "nao"), Colors.accent)
end

-- ---------- Spin ----------

-- 1 spin, com ate 3 tentativas se o remote falhar
local function spinWithRetry(alive)
    local lastErr = "falha desconhecida"
    for attempt = 1, 3 do
        local info = modeInfo()
        local rf = findRemote(info.service, "Roll")
        if rf then
            local ok, res = pcall(function()
                return rf:InvokeServer(info.lucky)
            end)
            if ok then return true end
            lastErr = tostring(res)
        else
            lastErr = "remote Roll nao encontrado"
        end
        if not alive() then return false, "cancelado" end
        if attempt < 3 then waitTime(3, alive) end
    end
    return false, lastErr
end

-- Depois do spin, confere o valor varias vezes durante o intervalo
local function waitForTarget(maxWait, alive)
    local t0 = os.clock()
    local last = nil
    repeat
        last = getCurrentValue()
        if isTarget(last) then return true, last end
        if not alive() then return false, last end
        task.wait(0.05)
    until os.clock() - t0 >= maxWait
    last = getCurrentValue()
    return isTarget(last), last
end

local function finish(msg, color)
    State.running = false
    setStatus(msg, color)
    paintButtons()
    persist()
end

local function rollbackAndRejoin(alive)
    local rf = nil
    local t0 = os.clock()
    while alive() and not rf and os.clock() - t0 < 15 do
        rf = findRemote("SettingsService", "UpdateKeybind")
        if not rf then task.wait(0.5) end
    end
    if not alive() then return false, "cancelado" end
    if not rf then return false, "remote UpdateKeybind nao encontrado" end

    State.cycles = State.cycles + 1
    persist() -- grava resume=true para o autoexec continuar depois do teleport

    local ok, err = pcall(function()
        rf:InvokeServer("MouseButton1", true, ROLLBACK_KEY)
    end)
    if not ok then return false, "rollback falhou: " .. tostring(err) end

    task.wait(0.5)
    for attempt = 1, 4 do
        if not alive() then return false, "cancelado" end
        setStatus(string.format("Rollback feito. Reentrando no jogo (%d/4)...", attempt), Colors.accent)
        pcall(function() TeleportService:Teleport(game.PlaceId) end)
        waitTime(12, alive)
    end
    return false, "teleport nao completou"
end

local function runLoop(token)
    local function alive()
        return State.running and token == State.token
    end

    setStatus("Aguardando o lobby carregar...", Colors.accent)
    local t0 = os.clock()
    while alive() and not isReady() do
        if os.clock() - t0 > 120 then
            finish("Lobby nao carregou em 120s.", Colors.bad)
            return
        end
        task.wait(0.5)
    end
    if not alive() then return end
    waitTime(1.5, alive)
    if not alive() then return end

    -- Troca de slot (so no modo estilo)
    if State.mode ~= "Ability" and State.slot ~= "Atual" then
        setStatus("Selecionando o slot " .. State.slot .. "...", Colors.accent)
        local okSlot, slotInfo = selectSlot(State.slot)
        if not okSlot then
            finish("Slot: " .. tostring(slotInfo), Colors.bad)
            return
        end
        waitTime(1, alive)
        if not alive() then return end
    end

    local info = modeInfo()
    local startValue = getCurrentValue()
    if isTarget(startValue) then
        finish("Ja esta com " .. info.noun .. ": " .. tostring(startValue), Colors.good)
        return
    end

    State.currentTries = 0
    while alive() do
        if State.currentTries >= State.spinsPerCycle then
            if State.useRollback then
                setStatus(string.format("Limite de %d spins. Dando rollback...", State.spinsPerCycle), Colors.accent)
                local ok, err = rollbackAndRejoin(alive)
                if alive() and not ok then
                    finish("Rollback: " .. tostring(err), Colors.bad)
                end
            else
                finish("Limite atingido sem " .. info.noun .. " alvo.", Colors.bad)
            end
            return
        end

        State.currentTries = State.currentTries + 1
        setStatus(string.format("Ciclo %d | Tentativa %d/%d - girando...",
            State.cycles + 1, State.currentTries, State.spinsPerCycle), Colors.accent)

        local ok, err = spinWithRetry(alive)
        if not alive() then return end
        if not ok then
            finish("Falha ao girar: " .. tostring(err), Colors.bad)
            return
        end

        local hit, got = waitForTarget(State.interval, alive)
        if not alive() then return end
        if hit then
            finish("Sucesso! Veio: " .. tostring(got), Colors.good)
            return
        end
        setStatus(string.format("Ciclo %d | %d/%d - veio: %s",
            State.cycles + 1, State.currentTries, State.spinsPerCycle, tostring(got or "?")), Colors.bad)
    end
end

track(mapBtn.MouseButton1Click:Connect(dumpInfo))

local function startSpin(keepCycles)
    if State.running then return end
    State.running = true
    State.token = State.token + 1
    if not keepCycles then State.cycles = 0 end
    State.currentTries = 0
    paintButtons()
    persist()
    local token = State.token
    task.spawn(function()
        local ok, err = pcall(runLoop, token)
        if not ok then
            warn("[ScyFe AutoRollbackStyle] erro: " .. tostring(err))
            if token == State.token and State.running then
                finish("Erro: " .. tostring(err), Colors.bad)
            end
        end
    end)
end

local function stopSpin()
    State.running = false
    State.token = State.token + 1
    setStatus("Parado.", Colors.sub)
    paintButtons()
    persist()
end

track(startBtn.MouseButton1Click:Connect(function() startSpin(false) end))
track(stopBtn.MouseButton1Click:Connect(stopSpin))

-- ============================================================
-- API e inicio automatico
-- ============================================================

_G.ScyFeAutoRollback = {
    Start = function() startSpin(false) end,
    Stop = stopSpin,
    State = State,
    Gui = ScreenGui,
    Unload = function()
        State.running = false
        State.token = State.token + 1
        persist() -- limpa o resume: reexecutar o script nao deve iniciar sozinho
        for _, c in ipairs(conns) do
            pcall(function() c:Disconnect() end)
        end
        pcall(function() ScreenGui:Destroy() end)
        _G.ScyFeAutoRollback = nil
    end,
}

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ScyFe Auto Rollback Style",
        Text = "Carregado. RightShift ou botao RS abre/fecha.",
        Duration = 4,
    })
end)
print("[ScyFe AutoRollbackStyle] Carregado. RightShift ou botao RS abre/fecha.")

-- Inicia sozinho se "Iniciar automaticamente" estiver ligado
-- ou se estava rodando antes do rollback (teleport) ha menos de 5 minutos
local resumeValid = SavedCfg.resume == true
    and (os.time() - (tonumber(SavedCfg.resumeAt) or 0)) < 300

if State.autoStart or resumeValid then
    task.spawn(function()
        print("[ScyFe AutoRollbackStyle] Iniciando automaticamente (aguardando o lobby)...")
        task.wait(2)
        if _G.ScyFeAutoRollback and not State.running then
            startSpin(resumeValid)
        end
    end)
end
