--[[
    ScyFe Visuals - Auto Rollback Style (v2)
    Jogo: Volleyball Legends
    Autor: Daishyn / ScyFe Visuals
    Uso: cole no executor e injete.
    Gira até acabar os spins, se não vier o estilo alvo, dá rollback e reinicia.
]]

if _G.ScyFeAutoRollback and _G.ScyFeAutoRollback.Unload then
    pcall(_G.ScyFeAutoRollback.Unload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- Caminhos da Source
-- ============================================================

local function path(root, ...)
    local cur = root
    for _, n in ipairs({ ... }) do
        if not cur then return nil end
        cur = cur:FindFirstChild(n)
    end
    return cur
end

local Services = path(ReplicatedStorage, "Packages", "_Index", "sleitnick_knit@1.7.0", "knit", "Services")

local function getStyleRoll()
    local ok, rf = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.StyleService.RF.Roll
    end)
    if ok and rf then return rf end
    local ok2, rf2 = pcall(function()
        local Index = ReplicatedStorage.Packages._Index
        for _, folder in Index:GetChildren() do
            if folder.Name:find("knit") then
                local knit = folder:FindFirstChild("knit")
                if knit then
                    local svc = knit:FindFirstChild("Services")
                        and knit.Services:FindFirstChild("StyleService")
                    if svc then
                        local RF = svc:FindFirstChild("RF")
                        if RF then return RF:FindFirstChild("Roll") end
                    end
                end
            end
        end
        return nil
    end)
    return ok2 and rf2 or nil
end

local function getUpdateKeybind()
    local ok, rf = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.SettingsService.RF.UpdateKeybind
    end)
    if ok and rf then return rf end
    local ok2, rf2 = pcall(function()
        local Index = ReplicatedStorage.Packages._Index
        for _, folder in Index:GetChildren() do
            if folder.Name:find("knit") then
                local knit = folder:FindFirstChild("knit")
                if knit then
                    local svc = knit:FindFirstChild("Services")
                        and knit.Services:FindFirstChild("SettingsService")
                    if svc then
                        local RF = svc:FindFirstChild("RF")
                        if RF then return RF:FindFirstChild("UpdateKeybind") end
                    end
                end
            end
        end
        return nil
    end)
    return ok2 and rf2 or nil
end

local RollRemote = getStyleRoll()
local UpdateKeybindRemote = getUpdateKeybind()

-- ============================================================
-- Cores e Helpers
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

-- ============================================================
-- Persistência de Config
-- ============================================================

local CONFIG_FOLDER = "ScyFeAutoRollback"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function fsReady()
    return type(writefile) == "function" and type(readfile) == "function"
        and type(isfolder) == "function" and type(makefolder) == "function"
end

local function loadConfig()
    local cfg = {
        targetStyle = "Ronin",
        spinType = "Normal",
        useRollback = true,
        spinDelay = 0.5,
        checkDelay = 2.0,
        maxTries = 50,
    }
    if not fsReady() then return cfg end
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    end)
    local ok, raw = pcall(function()
        if isfile(CONFIG_FILE) then return readfile(CONFIG_FILE) end
        return nil
    end)
    if ok and raw and raw ~= "" then
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok2 and type(data) == "table" then
            for k, v in pairs(data) do cfg[k] = v end
        end
    end
    return cfg
end

local function saveConfig(cfg)
    if not fsReady() then return end
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        local json = HttpService:JSONEncode(cfg)
        writefile(CONFIG_FILE, json)
    end)
end

local SavedCfg = loadConfig()

-- ============================================================
-- Estado
-- ============================================================

local State = {
    running = false,
    targetStyle = SavedCfg.targetStyle,
    useRollback = SavedCfg.useRollback,
    spinType = SavedCfg.spinType,
    spinDelay = SavedCfg.spinDelay or 0.5,
    checkDelay = SavedCfg.checkDelay or 2.0,
    maxTries = SavedCfg.maxTries or 50,
    currentTries = 0,
    noSpinLeft = false,
}

local function persist()
    saveConfig({
        targetStyle = State.targetStyle,
        spinType = State.spinType,
        useRollback = State.useRollback,
        spinDelay = State.spinDelay,
        checkDelay = State.checkDelay,
        maxTries = State.maxTries,
    })
end

-- ============================================================
-- Lista de Estilos
-- ============================================================

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
if not ScreenGui.Parent then ScreenGui.Parent = getHiddenParent() end

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
stroke(FloatBtn, Colors.accent, 2, 0.35)

local Window = newInstance("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 80, 0.5, 0),
    Size = UDim2.fromOffset(300, 460),
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
-- Seção: Configurações
-- ============================================================

local ConfigBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Colors.raised,
    BorderSizePixel = 0,
    LayoutOrder = 1,
    ZIndex = 42,
}, Scroll)
corner(ConfigBox, 8)
stroke(ConfigBox, Colors.line, 1)
newInstance("UIPadding", {
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 10),
}, ConfigBox)
newInstance("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, ConfigBox)

newInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Configurações",
    LayoutOrder = 0,
    ZIndex = 43,
}, ConfigBox)

-- Dropdown de Estilo
local styleBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.bg,
    BorderSizePixel = 0,
    LayoutOrder = 1,
    ZIndex = 42,
}, ConfigBox)
corner(styleBox, 6)
stroke(styleBox, Colors.line, 1)

local styleLabel = newInstance("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Estilo: " .. State.targetStyle,
    ZIndex = 43,
}, styleBox)

local styleArrow = newInstance("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(16, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.accent,
    Text = "v",
    ZIndex = 43,
}, styleBox)

local styleClick = newInstance("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 44,
}, styleBox)

local styleList = newInstance("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.fromOffset(0, 36),
    BackgroundColor3 = Colors.bg,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Colors.line,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 45,
}, ConfigBox)
corner(styleList, 6)
stroke(styleList, Colors.line, 1)
newInstance("UIPadding", {
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
}, styleList)
newInstance("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
}, styleList)

local styleOpen = false

local function rebuildStyleList()
    for _, child in ipairs(styleList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for i, style in ipairs(STYLE_LIST) do
        local item = newInstance("TextButton", {
            Size = UDim2.new(1, -8, 0, 26),
            BackgroundColor3 = Colors.raised,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Colors.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = style,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 46,
        }, styleList)
        corner(item, 4)
        newInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, item)

        item.MouseButton1Click:Connect(function()
            State.targetStyle = style
            styleLabel.Text = "Estilo: " .. style
            styleList.Visible = false
            styleOpen = false
            styleList.Size = UDim2.new(1, 0, 0, 0)
            styleArrow.Text = "v"
            persist()
        end)
    end
end

rebuildStyleList()

styleClick.MouseButton1Click:Connect(function()
    styleOpen = not styleOpen
    if styleOpen then
        styleList.Visible = true
        styleList.Size = UDim2.new(1, 0, 0, math.min(#STYLE_LIST * 30 + 8, 150))
        styleArrow.Text = "^"
    else
        styleList.Visible = false
        styleList.Size = UDim2.new(1, 0, 0, 0)
        styleArrow.Text = "v"
    end
end)

-- Dropdown de Tipo de Spin
local typeBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.bg,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    ZIndex = 42,
}, ConfigBox)
corner(typeBox, 6)
stroke(typeBox, Colors.line, 1)

local typeLabel = newInstance("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Tipo: " .. State.spinType,
    ZIndex = 43,
}, typeBox)

local typeArrow = newInstance("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(16, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.accent,
    Text = "v",
    ZIndex = 43,
}, typeBox)

local typeClick = newInstance("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 44,
}, typeBox)

local typeList = newInstance("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.fromOffset(0, 36),
    BackgroundColor3 = Colors.bg,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Colors.line,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 45,
}, ConfigBox)
corner(typeList, 6)
stroke(typeList, Colors.line, 1)
newInstance("UIPadding", {
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
}, typeList)
newInstance("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
}, typeList)

local typeOpen = false

local function rebuildTypeList()
    for _, child in ipairs(typeList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for i, t in ipairs({ "Normal", "Lucky" }) do
        local item = newInstance("TextButton", {
            Size = UDim2.new(1, -8, 0, 26),
            BackgroundColor3 = Colors.raised,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Colors.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = t,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 46,
        }, typeList)
        corner(item, 4)
        newInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, item)

        item.MouseButton1Click:Connect(function()
            State.spinType = t
            typeLabel.Text = "Tipo: " .. t
            typeList.Visible = false
            typeOpen = false
            typeList.Size = UDim2.new(1, 0, 0, 0)
            typeArrow.Text = "v"
            persist()
        end)
    end
end

rebuildTypeList()

typeClick.MouseButton1Click:Connect(function()
    typeOpen = not typeOpen
    if typeOpen then
        typeList.Visible = true
        typeList.Size = UDim2.new(1, 0, 0, 68)
        typeArrow.Text = "^"
    else
        typeList.Visible = false
        typeList.Size = UDim2.new(1, 0, 0, 0)
        typeArrow.Text = "v"
    end
end)

-- Toggle "Rollback se falhar"
local rbBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
    ZIndex = 42,
}, ConfigBox)

newInstance("TextLabel", {
    Size = UDim2.new(1, -46, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Colors.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Rollback se falhar",
    ZIndex = 43,
}, rbBox)

local rbPill = newInstance("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.fromOffset(38, 20),
    BackgroundColor3 = State.useRollback and Colors.accentD or Colors.raised,
    BorderSizePixel = 0,
    ZIndex = 43,
}, rbBox)
corner(rbPill, 10)
local rbStroke = stroke(rbPill, State.useRollback and Colors.accent or Colors.line, 1)
local rbKnob = newInstance("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = State.useRollback and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundColor3 = State.useRollback and Colors.text or Colors.sub,
    BorderSizePixel = 0,
    ZIndex = 44,
}, rbPill)
corner(rbKnob, 7)

local rbClick = newInstance("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 45,
}, rbBox)

local function paintRB()
    if State.useRollback then
        rbPill.BackgroundColor3 = Colors.accentD
        rbStroke.Color = Colors.accent
        rbKnob.BackgroundColor3 = Colors.text
        TweenService:Create(rbKnob, TweenInfo.new(0.15), {
            Position = UDim2.new(1, -17, 0.5, 0)
        }):Play()
    else
        rbPill.BackgroundColor3 = Colors.raised
        rbStroke.Color = Colors.line
        rbKnob.BackgroundColor3 = Colors.sub
        TweenService:Create(rbKnob, TweenInfo.new(0.15), {
            Position = UDim2.new(0, 3, 0.5, 0)
        }):Play()
    end
end

rbClick.MouseButton1Click:Connect(function()
    State.useRollback = not State.useRollback
    paintRB()
    persist()
end)

paintRB()

-- ============================================================
-- Seção: Controle
-- ============================================================

local CtrlBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Colors.raised,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    ZIndex = 42,
}, Scroll)
corner(CtrlBox, 8)
stroke(CtrlBox, Colors.line, 1)
newInstance("UIPadding", {
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 10),
}, CtrlBox)
newInstance("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, CtrlBox)

newInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Controle",
    LayoutOrder = 0,
    ZIndex = 43,
}, CtrlBox)

local statusLabel = newInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Colors.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Pronto. Estilo: " .. State.targetStyle .. " | " .. State.spinType,
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

-- ============================================================
-- Lógica
-- ============================================================

local function doRollback()
    if not UpdateKeybindRemote then
        warn("[AutoRollbackStyle] Remote UpdateKeybind não encontrada.")
        return false
    end
    local ok = pcall(function()
        UpdateKeybindRemote:InvokeServer("MouseButton1", true, "Spike\143")
    end)
    if not ok then
        warn("[AutoRollbackStyle] Falha ao invocar UpdateKeybind.")
        return false
    end
    task.wait(0.5)
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
    return true
end

local function getCurrentStyle()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local interface = gui and gui:FindFirstChild("Interface")
    local lobby = interface and interface:FindFirstChild("Lobby")
    local styles = lobby and lobby:FindFirstChild("Styles")
    local topPanel = styles and styles:FindFirstChild("TopPanel")
    local displayName = topPanel and topPanel:FindFirstChild("DisplayName")
    if displayName and displayName:IsA("TextLabel") then
        return displayName.Text
    end
    return nil
end

local function doSpin()
    if not RollRemote then
        warn("[AutoRollbackStyle] Remote de roll de estilo não encontrada.")
        return false
    end
    local ok = pcall(function()
        RollRemote:InvokeServer(State.spinType == "Lucky")
    end)
    return ok
end

local function waitForStyleChange(previousStyle, timeout)
    local startTime = os.clock()
    while os.clock() - startTime < timeout do
        local current = getCurrentStyle()
        if current and current ~= previousStyle then
            return current
        end
        task.wait(0.1)
    end
    return nil
end

-- Verifica se ainda tem spins disponíveis
local function hasSpinLeft()
    -- Tenta ler o saldo de spins da UI
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local interface = gui and gui:FindFirstChild("Interface")
    local lobby = interface and interface:FindFirstChild("Lobby")
    local styles = lobby and lobby:FindFirstChild("Styles")

    if not styles then return true end

    -- Procura por qualquer TextLabel que contenha número de spins
    for _, d in ipairs(styles:GetDescendants()) do
        if d:IsA("TextLabel") then
            local text = d.Text or ""
            local num = tonumber(text:match("^(%d+)$"))
            if num and d.Name:lower():find("spin") then
                return num > 0
            end
        end
    end

    return true -- se não conseguir ler, assume que tem
end

local function autoRollbackLoop()
    State.currentTries = 0
    State.noSpinLeft = false

    while State.running and State.currentTries < State.maxTries do
        State.currentTries = State.currentTries + 1
        statusLabel.Text = string.format("Tentativa %d/%d — Girando...", State.currentTries, State.maxTries)
        statusLabel.TextColor3 = Colors.accent

        local before = getCurrentStyle()

        if not doSpin() then
            statusLabel.Text = "Falha ao girar."
            statusLabel.TextColor3 = Colors.bad
            break
        end

        task.wait(State.spinDelay)

        local result = waitForStyleChange(before, State.checkDelay)

        if not State.running then break end

        if result and result == State.targetStyle then
            statusLabel.Text = string.format("Sucesso! Veio: %s", result)
            statusLabel.TextColor3 = Colors.good
            State.running = false
            startBtn.Text = "INICIAR SPIN"
            startBtn.BackgroundColor3 = Colors.good
            break
        else
            statusLabel.Text = string.format("Veio: %s — Tentando de novo...", result or "?")
            statusLabel.TextColor3 = Colors.bad

            -- Se não tem mais spins, dá rollback
            if not hasSpinLeft() then
                statusLabel.Text = "Sem spins. Dando rollback..."
                statusLabel.TextColor3 = Colors.accent

                if State.useRollback then
                    doRollback()
                    break
                else
                    State.running = false
                    startBtn.Text = "INICIAR SPIN"
                    startBtn.BackgroundColor3 = Colors.good
                    break
                end
            end

            task.wait(0.5)
        end
    end

    if State.currentTries >= State.maxTries and State.running then
        statusLabel.Text = "Máximo de tentativas atingido. Dando rollback..."
        statusLabel.TextColor3 = Colors.accent
        if State.useRollback then doRollback() end
        State.running = false
        startBtn.Text = "INICIAR SPIN"
        startBtn.BackgroundColor3 = Colors.good
    end
end

-- ============================================================
-- Start / Stop
-- ============================================================

local thread = nil

startBtn.MouseButton1Click:Connect(function()
    if State.running then return end
    State.running = true
    State.currentTries = 0
    startBtn.Text = "RODANDO..."
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 60)
    thread = task.spawn(autoRollbackLoop)
end)

stopBtn.MouseButton1Click:Connect(function()
    State.running = false
    statusLabel.Text = "Parado."
    statusLabel.TextColor3 = Colors.sub
    startBtn.Text = "INICIAR SPIN"
    startBtn.BackgroundColor3 = Colors.good
    thread = nil
end)

-- ============================================================
-- Toggle da GUI
-- ============================================================

local guiVisible = false
local function setGuiVisible(v)
    guiVisible = v
    Window.Visible = v
    if v then
        TweenService:Create(Window, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
            Size = UDim2.fromOffset(300, 460),
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

_G.ScyFeAutoRollback = {
    Start = function()
        if not State.running then
            State.running = true
            State.currentTries = 0
            startBtn.Text = "RODANDO..."
            startBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 60)
            thread = task.spawn(autoRollbackLoop)
        end
    end,
    Stop = function()
        State.running = false
        statusLabel.Text = "Parado."
        statusLabel.TextColor3 = Colors.sub
        startBtn.Text = "INICIAR SPIN"
        startBtn.BackgroundColor3 = Colors.good
        thread = nil
    end,
    SetStyle = function(style)
        if table.find(STYLE_LIST, style) then
            State.targetStyle = style
            styleLabel.Text = "Estilo: " .. style
            persist()
        end
    end,
    SetSpinType = function(t)
        if t == "Normal" or t == "Lucky" then
            State.spinType = t
            typeLabel.Text = "Tipo: " .. t
            persist()
        end
    end,
    GetStyle = function() return State.targetStyle end,
    GetSpinType = function() return State.spinType end,
    State = State,
    Gui = ScreenGui,
    Unload = function()
        State.running = false
        pcall(function() ScreenGui:Destroy() end)
        _G.ScyFeAutoRollback = nil
    end,
}

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ScyFe Auto Rollback Style",
        Text = "Carregado. Estilo: " .. State.targetStyle .. " | " .. State.spinType,
        Duration = 4,
    })
end)

print("[ScyFe AutoRollbackStyle] Carregado. RightShift abre/fecha.")
print("[ScyFe AutoRollbackStyle] Config salva em: " .. CONFIG_FILE)
