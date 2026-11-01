--[[
    ScyFe Visuals - Auto Farm (baseado no aero)
    Jogo: Volleyball Legends
    Autor: Daishyn / ScyFe Visuals
    Uso: cole no executor e injete. GUI própria, sem depender do hub.
]]

if _G.ScyFe_AutoFarm and _G.ScyFe_AutoFarm.Unload then
    pcall(_G.ScyFe_AutoFarm.Unload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- Remotas (idêntico ao aero)
-- ============================================================

local function getRF(name)
    local ok, rf = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RF[name]
    end)
    if ok and rf then return rf end

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

-- ============================================================
-- Estado
-- ============================================================

local State = {
    tp       = false,
    block    = false,
    spike    = false,
    jump     = false,
    interval = 0.05,
    tpOffset = 3,
    jumpState = false,
    running  = false,
}

-- ============================================================
-- Helpers do jogo
-- ============================================================

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
    local ok, t = pcall(function() return Workspace:GetServerTimeNow() end)
    if ok and typeof(t) == "number" then return t end
    return tick()
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

local ScreenGui = newInstance("ScreenGui", {
    Name = "ScyFe_AutoFarm",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
})
protect(ScreenGui)
if not ScreenGui.Parent then ScreenGui.Parent = getHiddenParent() end

-- Botão flutuante
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
local floatStroke = stroke(FloatBtn, Colors.accent, 2, 0.35)

-- Janela
local Window = newInstance("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 80, 0.5, 0),
    Size = UDim2.fromOffset(300, 400),
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
    Text = "SCYFE - AUTO FARM",
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
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

-- Container
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
        if State[key] then
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
    render()
    return { Set = function(v) State[key] = v; render() end }
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
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        valueLabel.Text = tostring(State[key])
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
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            applyX(input.Position.X)
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
            applyX(input.Position.X)
        end
    end)
    render()
    return { Set = function(v) State[key] = math.clamp(v, min, max); render() end }
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
slider(secConfig, "Intervalo (s)", "interval", 0.03, 0.3, 0.05, 0.01)
slider(secConfig, "Offset do TP", "tpOffset", 1, 8, 3, 0.5)

local secStatus = section("Status")
local statusLabel = info(secStatus, "Aguardando início...")

local secActions = section("Controle")
local startBtn = newInstance("TextButton", {
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
    LayoutOrder = #secActions:GetChildren(),
}, secActions)
corner(stopBtn, 8)

-- ============================================================
-- Loop de TP
-- ============================================================

local tpConn
local function startTP()
    if tpConn then tpConn:Disconnect() end
    tpConn = RunService.Heartbeat:Connect(function()
        if not State.running or not State.tp then return end
        local ball = getBall()
        local hrp = getHRP()
        if ball and hrp then
            local target = ball.Position + Vector3.new(0, ball.Size.Y * 0.5 + State.tpOffset, 0)
            pcall(function()
                hrp.CFrame = CFrame.new(target, target + Camera.CFrame.LookVector)
            end)
        end
    end)
end

-- ============================================================
-- Loop principal (baseado no aero)
-- ============================================================

local mainThread
local function startLoop()
    if mainThread then return end
    mainThread = task.spawn(function()
        while State.running do
            local waitT = State.interval or 0.05
            local ball, bid = getBall()
            local hrp = getHRP()
            local look = Camera and Camera.CFrame.LookVector or Vector3.new(0, 0, -1)
            local move = hrp and hrp.CFrame.LookVector or Vector3.zero
            local tilt = Vector3.new(0, 1, 0)
            local ts = getTimestamp()

            -- BLOCK (idêntico ao aero, com CreateHitbox antes do Interact)
            if State.block then
                if bid ~= 0 and ball and Remotes.CreateHitbox and Remotes.Interact then
                    local key = "Block" .. math.random(1000000, 9999999)
                    pcall(function()
                        Remotes.CreateHitbox:InvokeServer({
                            BallId = bid,
                            Charge = 1,
                            Key = key,
                            ClientTimestamp = ts,
                            Move = "Block",
                        })
                    end)
                    pcall(function()
                        Remotes.Interact:InvokeServer({
                            Charge = 1,
                            Move = "Block",
                            SpecialCharge = 0,
                            TiltDirection = tilt,
                            BallId = bid,
                            MoveDirection = move,
                            Key = key,
                            From = "Client",
                            LookVector = look,
                            Timestamp = ts,
                            ClientCanRunSpecial = false,
                            CustomClient = {},
                        })
                    end)
                    if Remotes.UpdateTilt then
                        pcall(function() Remotes.UpdateTilt:InvokeServer(tilt) end)
                    end
                end
            end

            -- SPIKE (não dispara junto com block)
            if State.spike and not State.block then
                if bid ~= 0 and ball and Remotes.Interact then
                    local realTilt = Vector3.new(look.X, 1, look.Z)
                    pcall(function()
                        Remotes.Interact:InvokeServer({
                            Charge = 1,
                            Move = "Spike",
                            SpecialCharge = 0,
                            TiltDirection = realTilt,
                            LookVector = look,
                            MoveDirection = move,
                            ClientCanRunSpecial = false,
                            From = "Client",
                            Timestamp = ts,
                            BallId = bid,
                            CustomClient = {},
                        })
                    end)
                    if Remotes.UpdateTilt then
                        pcall(function() Remotes.UpdateTilt:InvokeServer(realTilt) end)
                    end
                end
            end

            -- JUMP (idêntico ao aero, alterna estado)
            if State.jump and Remotes.Jump then
                State.jumpState = not State.jumpState
                pcall(function() Remotes.Jump:InvokeServer(State.jumpState) end)
            end

            -- status
            if statusLabel then
                local active = {}
                if State.tp then table.insert(active, "TP") end
                if State.block then table.insert(active, "Block") end
                if State.spike and not State.block then table.insert(active, "Spike") end
                if State.jump then table.insert(active, "Jump") end
                local txt = (#active > 0) and ("Ativo: " .. table.concat(active, ", "))
                    or "Nenhuma ação ativa"
                if ball then
                    txt = txt .. "  |  Bola #" .. tostring(bid)
                else
                    txt = txt .. "  |  Sem bola"
                end
                statusLabel.Text = txt
            end

            task.wait(waitT)
        end
    end)
end

-- ============================================================
-- Start / Stop
-- ============================================================

local function start()
    if State.running then return end
    State.running = true
    startBtn.Text = "RODANDO"
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 60)
    startTP()
    startLoop()
end

local function stop()
    State.running = false
    State.tp = false
    State.block = false
    State.spike = false
    State.jump = false
    State.jumpState = false
    mainThread = nil
    if tpConn then pcall(function() tpConn:Disconnect() end); tpConn = nil end
    startBtn.Text = "INICIAR"
    startBtn.BackgroundColor3 = Colors.good
    if statusLabel then statusLabel.Text = "Parado" end
end

startBtn.MouseButton1Click:Connect(start)
stopBtn.MouseButton1Click:Connect(stop)

-- ============================================================
-- Toggle da GUI
-- ============================================================

local guiVisible = false
local function setGuiVisible(v)
    guiVisible = v
    Window.Visible = v
    if v then
        TweenService:Create(Window, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
            Size = UDim2.fromOffset(300, 400),
        }):Play()
    end
end

FloatBtn.MouseButton1Click:Connect(function() setGuiVisible(not guiVisible) end)
CloseBtn.MouseButton1Click:Connect(function() setGuiVisible(false) end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setGuiVisible(not guiVisible)
    end
end)

-- Arrastar botão flutuante
do
    local dragging, dragStart, posStart
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            posStart = FloatBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

-- ============================================================
-- API pública
-- ============================================================

_G.ScyFe_AutoFarm = {
    Start   = start,
    Stop    = stop,
    Toggle  = function() if State.running then stop() else start() end end,
    State   = State,
    Gui     = ScreenGui,
    Unload  = function()
        stop()
        pcall(function() ScreenGui:Destroy() end)
        _G.ScyFe_AutoFarm = nil
    end,
}

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ScyFe Auto Farm",
        Text = "Carregado. RightShift ou AF.",
        Duration = 4,
    })
end)

print("[ScyFe AutoFarm] Carregado. RightShift abre/fecha.")