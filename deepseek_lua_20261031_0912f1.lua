--[[
    ScyFe Visuals - Auto Farm Standalone v2
    Jogo: Volleyball Legends
    Autor: Daishyn / ScyFe Visuals

    Correções aplicadas:
      - getBall com cache (sem varredura total por frame)
      - Remotes com retry e cache sob demanda
      - Intervalo padrão 0.12, mínimo 0.08
      - TP com cooldown, distância mínima e restauração de colisão
      - UI sincronizada com o State
      - Shutdown robusto com Generation counter
]]

-- Descarrega versão anterior se existir
if _G.ScyFe_AutoFarm and _G.ScyFe_AutoFarm.Unload then
    pcall(_G.ScyFe_AutoFarm.Unload)
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
-- Helpers
-- ============================================================

local function getHiddenParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(gui)
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
        Color = color or Color3.fromRGB(60, 65, 80),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

-- ============================================================
-- Remotes com retry e cache
-- ============================================================

local RemoteCache = {
    ready       = false,
    Interact    = nil,
    CreateHitbox = nil,
    Jump        = nil,
    UpdateTilt  = nil,
    attempts    = 0,
}

local function tryAcquireRemotes()
    if RemoteCache.ready then return true end
    RemoteCache.attempts = RemoteCache.attempts + 1

    local ok, knit = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit
    end)
    if not ok or not knit then return false end

    local ok2, bs = pcall(function()
        return knit.Services:FindFirstChild("BallService")
    end)
    if not ok2 or not bs then return false end

    local ok3, rf = pcall(function()
        return bs:FindFirstChild("RF")
    end)
    if not ok3 or not rf then return false end

    RemoteCache.Interact     = rf:FindFirstChild("Interact")
    RemoteCache.CreateHitbox = rf:FindFirstChild("CreateHitbox")
    RemoteCache.Jump         = rf:FindFirstChild("Jump")
    RemoteCache.UpdateTilt   = rf:FindFirstChild("UpdateTilt")
    RemoteCache.ready        = RemoteCache.Interact ~= nil

    return RemoteCache.ready
end

-- Tenta adquirir já, e agenda novas tentativas se falhar
tryAcquireRemotes()
if not RemoteCache.ready then
    task.spawn(function()
        for _ = 1, 20 do
            if tryAcquireRemotes() then break end
            task.wait(0.5)
        end
    end)
end

-- ============================================================
-- Pool de bolas com cache
-- ============================================================

local BallPool = {
    models  = {},     -- [model] = { part = BasePart, id = number }
    dirty   = true,
    lastScan = 0,
}

local function registerBallModel(model)
    if not (model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$")) then return end
    local id = tonumber(model.Name:match("%d+"))
    if not id then return end
    BallPool.models[model] = { id = id, part = nil }
    BallPool.dirty = true
end

local function unregisterBallModel(model)
    if BallPool.models[model] then
        BallPool.models[model] = nil
        BallPool.dirty = true
    end
end

local function refreshBallParts()
    for model, info in pairs(BallPool.models) do
        if not model.Parent then
            BallPool.models[model] = nil
        elseif not info.part or not info.part.Parent then
            info.part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    BallPool.dirty = false
end

local BallConnections = {}
local function watchBalls()
    for _, c in ipairs(BallConnections) do pcall(function() c:Disconnect() end) end
    BallConnections = {}

    for _, m in ipairs(Workspace:GetChildren()) do registerBallModel(m) end
    BallPool.dirty = true

    local c1 = Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
            registerBallModel(child)
            -- Partes internas podem aparecer depois; re-scan curto
            task.delay(0.15, function()
                if BallPool.models[child] then BallPool.dirty = true end
            end)
        end
    end)
    local c2 = Workspace.ChildRemoved:Connect(function(child)
        if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
            unregisterBallModel(child)
        end
    end)
    table.insert(BallConnections, c1)
    table.insert(BallConnections, c2)
end
watchBalls()

local function getBall()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, 0 end

    -- Re-scan a cada 0.5s se estiver sujo, ou se pool estiver vazio
    if BallPool.dirty or os.clock() - BallPool.lastScan > 0.5 then
        refreshBallParts()
        BallPool.lastScan = os.clock()
    end

    local bestPart, bestId, bestDist = nil, 0, math.huge
    for model, info in pairs(BallPool.models) do
        if model.Parent and info.part and info.part.Parent then
            local d = (info.part.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist, bestPart, bestId = d, info.part, info.id
            end
        end
    end
    return bestPart, bestId
end

local function getHRP()
    local c = LocalPlayer.Character
    if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- Estado
-- ============================================================

local State = {
    enabled  = false,
    tp       = false,
    block    = false,
    spike    = false,
    jump     = false,
    interval = 0.12,
    tpOffset = 0.5,
    jumpCd   = 0,
    generation = 0,   -- invalida loops antigos
}

local Connections = {}
local function addConn(conn)
    table.insert(Connections, conn)
    return conn
end
local function clearConns()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    Connections = {}
end

-- ============================================================
-- GUI
-- ============================================================

local Colors = {
    bg      = Color3.fromRGB(16, 17, 22),
    top     = Color3.fromRGB(24, 26, 34),
    panel   = Color3.fromRGB(22, 24, 30),
    raised  = Color3.fromRGB(32, 35, 45),
    line    = Color3.fromRGB(50, 55, 70),
    text    = Color3.fromRGB(232, 235, 245),
    sub     = Color3.fromRGB(150, 158, 180),
    accent  = Color3.fromRGB(124, 140, 255),
    accentD = Color3.fromRGB(88, 102, 212),
    good    = Color3.fromRGB(0, 160, 90),
    bad     = Color3.fromRGB(220, 70, 70),
    warn    = Color3.fromRGB(230, 180, 60),
}

local ScreenGui = newInstance("ScreenGui", {
    Name = "ScyFe_AutoFarm",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
})
protectGui(ScreenGui)
if not ScreenGui.Parent then
    ScreenGui.Parent = getHiddenParent()
end

-- Toggle flutuante
local FloatBtn = newInstance("TextButton", {
    Size = UDim2.fromOffset(56, 56),
    Position = UDim2.new(0, 12, 0.5, -28),
    BackgroundColor3 = Colors.top,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Text = "AF",
    TextColor3 = Colors.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    Selectable = false,
    ZIndex = 50,
}, ScreenGui)
corner(FloatBtn, 28)
stroke(FloatBtn, Colors.accent, 2, 0.35)

do
    local dragging, dragStart, posStart
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            posStart = FloatBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            FloatBtn.Position = UDim2.new(
                posStart.X.Scale, posStart.X.Offset + delta.X,
                posStart.Y.Scale, posStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- Janela
local Window = newInstance("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 80, 0.5, 0),
    Size = UDim2.fromOffset(320, 440),
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
    Text = "SCYFE - AUTO FARM v2",
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

-- Arrastar janela
do
    local dragging, dragStart, posStart
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            posStart = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                posStart.X.Scale, posStart.X.Offset + delta.X,
                posStart.Y.Scale, posStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- Scroll
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
newInstance("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingTop = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 12),
}, Scroll)
newInstance("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 10),
}, Scroll)

-- ============================================================
-- Componentes de UI
-- ============================================================

local UI = {
    toggles = {},   -- [key] = { row, pill, knob, render }
    sliders = {},   -- [key] = { render, label }
    status  = nil,
    startBtn = nil,
    stopBtn = nil,
}

local function section(title)
    local box = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Colors.panel,
        BorderSizePixel = 0,
        LayoutOrder = #Scroll:GetChildren(),
        ZIndex = 42,
    }, Scroll)
    corner(box, 8)
    stroke(box, Colors.line, 1)
    newInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
    }, box)
    newInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, box)

    local header = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    }, box)
    newInstance("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 12),
        BackgroundColor3 = Colors.accent,
        BorderSizePixel = 0,
    }, header)
    newInstance("TextLabel", {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -10, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
    }, header)

    return box
end

local function toggle(parent, label, key)
    local row = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
    }, parent)
    newInstance("TextLabel", {
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Colors.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = label,
    }, row)

    local pill = newInstance("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(38, 20),
        BackgroundColor3 = Colors.raised,
        BorderSizePixel = 0,
    }, row)
    corner(pill, 10)
    local pillStroke = stroke(pill, Colors.line, 1)

    local knob = newInstance("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Colors.sub,
        BorderSizePixel = 0,
    }, pill)
    corner(knob, 7)

    local click = newInstance("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, row)

    local function render()
        local on = State[key] and true or false
        if on then
            pill.BackgroundColor3 = Colors.accentD
            pillStroke.Color = Colors.accent
            knob.BackgroundColor3 = Colors.text
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = UDim2.new(1, -17, 0.5, 0)
            }):Play()
        else
            pill.BackgroundColor3 = Colors.raised
            pillStroke.Color = Colors.line
            knob.BackgroundColor3 = Colors.sub
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = UDim2.new(0, 3, 0.5, 0)
            }):Play()
        end
    end

    click.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        render()
    end)

    UI.toggles[key] = { render = render }
    render()
end

local function slider(parent, label, key, min, max, def, step)
    step = step or 1
    local holder = newInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        LayoutOrder = #parent:GetChildren(),
    }, parent)

    newInstance("TextLabel", {
        Size = UDim2.new(1, -70, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Colors.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    }, holder)

    local valueLabel = newInstance("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(70, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Colors.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(def),
    }, holder)

    local bar = newInstance("Frame", {
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Colors.raised,
        BorderSizePixel = 0,
    }, holder)
    corner(bar, 5)
    stroke(bar, Colors.line, 1)

    local fill = newInstance("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Colors.accent,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 5)

    State[key] = def

    local function render()
        local alpha = (State[key] - min) / (max - min)
        fill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
        valueLabel.Text = tostring(State[key])
        if key == "interval" and State.interval < 0.08 then
            valueLabel.TextColor3 = Colors.bad
        else
            valueLabel.TextColor3 = Colors.accent
        end
    end

    local function applyX(x)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local alpha = math.clamp((x - abs) / w, 0, 1)
        local raw = min + (max - min) * alpha
        State[key] = math.floor(raw / step + 0.5) * step
        render()
    end

    local dragging = false
    addConn(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            applyX(input.Position.X)
        end
    end))
    addConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    addConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            applyX(input.Position.X)
        end
    end))

    UI.sliders[key] = { render = render }
    render()
end

local function info(parent, text)
    return newInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Colors.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Text = text,
        LayoutOrder = #parent:GetChildren(),
    }, parent)
end

-- ============================================================
-- Seções
-- ============================================================

local secMain = section("Ações")
toggle(secMain, "Teleport para bola", "tp")
toggle(secMain, "Block automático", "block")
toggle(secMain, "Spike automático", "spike")
toggle(secMain, "Pular (farm de salto)", "jump")

local secConfig = section("Configurações")
slider(secConfig, "Intervalo (s)", "interval", 0.08, 0.5, 0.12, 0.01)
slider(secConfig, "Offset do TP", "tpOffset", 0, 8, 0.5, 0.5)

local secStatus = section("Status")
UI.status = info(secStatus, "Aguardando início...")

local secActions = section("Controle")
UI.startBtn = newInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Colors.good,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.text,
    Text = "INICIAR",
    AutoButtonColor = false,
    LayoutOrder = #secActions:GetChildren(),
}, secActions)
corner(UI.startBtn, 8)

UI.stopBtn = newInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Colors.bad,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.text,
    Text = "PARAR",
    AutoButtonColor = false,
    LayoutOrder = #secActions:GetChildren(),
}, secActions)
corner(UI.stopBtn, 8)

-- ============================================================
-- TP loop com controle
-- ============================================================

local tpConn = nil
local tpCooldown = 0

local function setCollision(state)
    local hrp = getHRP()
    if hrp then hrp.CanCollide = state end
end

local function startTP()
    if tpConn then tpConn:Disconnect() end
    tpConn = RunService.Heartbeat:Connect(function()
        if not State.enabled or not State.tp then
            setCollision(true)
            return
        end
        if os.clock() < tpCooldown then return end

        local ball = getBall()
        local hrp = getHRP()
        if not ball or not hrp then return end

        -- Só teleporta se realmente precisar (distância > 2)
        local target = ball.Position + Vector3.new(0, State.tpOffset, 0)
        if (hrp.Position - target).Magnitude <= 2 then return end

        hrp.CanCollide = false
        pcall(function()
            hrp.CFrame = CFrame.new(target, target + Camera.CFrame.LookVector)
        end)
        tpCooldown = os.clock() + 0.03
    end)
    addConn(tpConn)
end

-- ============================================================
-- Loop principal
-- ============================================================

local mainThread = nil

local function startLoop()
    if mainThread then return end
    State.generation = State.generation + 1
    local myGen = State.generation

    mainThread = task.spawn(function()
        while State.enabled and State.generation == myGen do
            local interval = State.interval or 0.12

            -- Garante remotes antes de qualquer chamada
            if not RemoteCache.ready then
                tryAcquireRemotes()
            end

            local ball, ballId = getBall()
            local hrp = getHRP()

            if ball and ballId and ballId ~= 0 and hrp and RemoteCache.ready then
                local look = Camera.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                if flat.Magnitude < 0.1 then flat = Vector3.new(0, 0, -1) end
                flat = flat.Unit
                local tilt = Vector3.new(flat.X, 1, flat.Z)
                local hrpLook = hrp.CFrame.LookVector
                local now = Workspace:GetServerTimeNow()

                -- BLOCK
                if State.block and RemoteCache.Interact then
                    local key = "Block" .. math.random(1000000, 9999999)
                    pcall(function()
                        RemoteCache.CreateHitbox:InvokeServer({
                            BallId = ballId, Charge = 1, Key = key,
                            ClientTimestamp = now, Move = "Block",
                        })
                    end)
                    pcall(function()
                        RemoteCache.Interact:InvokeServer({
                            Charge = 1, Move = "Block", SpecialCharge = 0,
                            TiltDirection = Vector3.new(0, 1, 0),
                            BallId = ballId, MoveDirection = hrpLook,
                            Key = key, From = "Client", LookVector = look,
                            Timestamp = now, ClientCanRunSpecial = false,
                            CustomClient = {},
                        })
                    end)
                    if RemoteCache.UpdateTilt then
                        pcall(function()
                            RemoteCache.UpdateTilt:InvokeServer(Vector3.new(0, 1, 0))
                        end)
                    end
                end

                -- SPIKE (não dispara junto com block)
                if State.spike and not State.block and RemoteCache.Interact then
                    pcall(function()
                        RemoteCache.Interact:InvokeServer({
                            Charge = 1, Move = "Spike", SpecialCharge = 0,
                            TiltDirection = tilt, LookVector = look,
                            MoveDirection = hrpLook,
                            ClientCanRunSpecial = false, From = "Client",
                            Timestamp = now, BallId = ballId,
                            CustomClient = {},
                        })
                    end)
                    if RemoteCache.UpdateTilt then
                        pcall(function() RemoteCache.UpdateTilt:InvokeServer(tilt) end)
                    end
                end

                -- JUMP
                if State.jump and RemoteCache.Jump and os.clock() > State.jumpCd then
                    State.jumpCd = os.clock() + 0.35
                    pcall(function() RemoteCache.Jump:InvokeServer(true) end)
                end
            end

            -- Status
            if UI.status then
                if not RemoteCache.ready then
                    UI.status.Text = "Aguardando remotes do servidor..."
                else
                    local active = {}
                    if State.tp then table.insert(active, "TP") end
                    if State.block then table.insert(active, "Block") end
                    if State.spike and not State.block then table.insert(active, "Spike") end
                    if State.jump then table.insert(active, "Jump") end
                    local txt = (#active > 0) and ("Ativo: " .. table.concat(active, ", ")) or "Nenhuma ação ativa"
                    txt = txt .. " | Bola: " .. (ball and ("#" .. tostring(ballId)) or "nenhuma")
                    UI.status.Text = txt
                end
            end

            task.wait(interval)
        end
    end)
end

-- ============================================================
-- Start / Stop / Unload
-- ============================================================

local function refreshUI()
    for _, t in pairs(UI.toggles) do pcall(t.render) end
    for _, s in pairs(UI.sliders) do pcall(s.render) end
    if UI.startBtn then
        UI.startBtn.Text = State.enabled and "RODANDO" or "INICIAR"
        UI.startBtn.BackgroundColor3 = State.enabled and Color3.fromRGB(0, 110, 60) or Colors.good
    end
    if not State.enabled and UI.status then
        UI.status.Text = "Parado"
    end
end

local function start()
    if State.enabled then return end
    -- Bloqueia início se não houver remotes e nem bola ainda
    if not RemoteCache.ready then tryAcquireRemotes() end
    if not RemoteCache.ready then
        if UI.status then
            UI.status.Text = "Serviços do jogo não carregados ainda. Aguarde e tente de novo."
        end
        return
    end
    State.enabled = true
    startTP()
    startLoop()
    refreshUI()
end

local function stop()
    State.enabled = false
    State.tp = false
    State.block = false
    State.spike = false
    State.jump = false
    State.jumpCd = 0
    State.generation = State.generation + 1  -- invalida loop antigo
    mainThread = nil
    clearConns()
    if tpConn then pcall(function() tpConn:Disconnect() end); tpConn = nil end
    setCollision(true)
    refreshUI()
end

UI.startBtn.MouseButton1Click:Connect(start)
UI.stopBtn.MouseButton1Click:Connect(stop)

-- Toggle da GUI
local guiVisible