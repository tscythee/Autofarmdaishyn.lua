--[[
    ScyFe Visuals - Auto Rollback Style (Final Corrigido)
    Jogo: Volleyball Legends
    Autor: Daishyn / ScyFe Visuals
]]

if _G.ScyFeAutoRollback and _G.ScyFeAutoRollback.Unload then
    pcall(_G.ScyFeAutoRollback.Unload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- Remotes
-- ============================================================

local function getStyleRoll()
    local ok, rf = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.StyleService.RF.Roll
    end)
    if ok and rf then return rf end
    return nil
end

local function getUpdateKeybind()
    local ok, rf = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.SettingsService.RF.UpdateKeybind
    end)
    if ok and rf then return rf end
    return nil
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
-- Config
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
        spinsPerCycle = 10,
        autoStart = false,
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
    spinsPerCycle = SavedCfg.spinsPerCycle or 10,
    autoStart = SavedCfg.autoStart or false,
    currentTries = 0,
}

local function persist()
    saveConfig({
        targetStyle = State.targetStyle,
        spinType = State.spinType,
        useRollback = State.useRollback,
        spinsPerCycle = State.spinsPerCycle,
        autoStart = State.autoStart,
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
    Size = UDim2.fromOffset(310, 520),
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
-- Configurações
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

-- Dropdown Estilo
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
        if child:IsA("TextButton") then child:Destroy() end
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
        newInstance("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, item)
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

-- Dropdown Tipo
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
newInstance("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, typeList)
newInstance("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, typeList)

local typeOpen = false
for i, tName in ipairs({"Normal", "Lucky"}) do
    local item = newInstance("TextButton", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundColor3 = Colors.raised,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tName,
        AutoButtonColor = false,
        LayoutOrder = i,
        ZIndex = 46,
    }, typeList)
    corner(item, 4)
    newInstance("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, item)
    item.MouseButton1Click:Connect(function()
        State.spinType = tName
        typeLabel.Text = "Tipo: " .. tName
        typeList.Visible = false
        typeOpen = false
        typeList.Size = UDim2.new(1, 0, 0, 0)
        typeArrow.Text = "v"
        persist()
    end)
end

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

-- Spins por ciclo
local spinsBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.bg,
    BorderSizePixel = 0,
    LayoutOrder = 3,
    ZIndex = 42,
}, ConfigBox)
corner(spinsBox, 6)
stroke(spinsBox, Colors.line, 1)

newInstance("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Colors.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Spins por ciclo",
    ZIndex = 43,
}, spinsBox)

local spinsInput = newInstance("TextBox", {
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
    Text = tostring(State.spinsPerCycle),
    ZIndex = 44,
}, spinsBox)
corner(spinsInput, 4)
stroke(spinsInput, Colors.line, 1)

spinsInput.FocusLost:Connect(function()
    local n = tonumber(spinsInput.Text)
    if n and n > 0 then
        State.spinsPerCycle = math.floor(n)
    end
    spinsInput.Text = tostring(State.spinsPerCycle)
    persist()
end)

-- Toggle Rollback
local rbBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    LayoutOrder = 4,
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
        TweenService:Create(rbKnob, TweenInfo.new(0.15), { Position = UDim2.new(1, -17, 0.5, 0) }):Play()
    else
        rbPill.BackgroundColor3 = Colors.raised
        rbStroke.Color = Colors.line
        rbKnob.BackgroundColor3 = Colors.sub
        TweenService:Create(rbKnob, TweenInfo.new(0.15), { Position = UDim2.new(0, 3, 0.5, 0) }):Play()
    end
end

rbClick.MouseButton1Click:Connect(function()
    State.useRollback = not State.useRollback
    paintRB()
    persist()
end)
paintRB()

-- Toggle Auto-start
local asBox = newInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    LayoutOrder = 5,
    ZIndex = 42,
}, ConfigBox)

newInstance("TextLabel", {
    Size = UDim2.new(1, -46, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Colors.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Iniciar automaticamente",
    ZIndex = 43,
}, asBox)

local asPill = newInstance("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.fromOffset(38, 20),
    BackgroundColor3 = State.autoStart and Colors.accentD or Colors.raised,
    BorderSizePixel = 0,
    ZIndex = 43,
}, asBox)
corner(asPill, 10)
local asStroke = stroke(asPill, State.autoStart and Colors.accent or Colors.line, 1)
local asKnob = newInstance("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = State.autoStart and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundColor3 = State.autoStart and Colors.text or Colors.sub,
    BorderSizePixel = 0,
    ZIndex = 44,
}, asPill)
corner(asKnob, 7)

local asClick = newInstance("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 45,
}, asBox)

local function paintAS()
    if State.autoStart then
        asPill.BackgroundColor3 = Colors.accentD
        asStroke.Color = Colors.accent
        asKnob.BackgroundColor3 = Colors.text
        TweenService:Create(asKnob, TweenInfo.new(0.15), { Position = UDim2.new(1, -17, 0.5, 0) }):Play()
    else
        asPill.BackgroundColor3 = Colors.raised
        asStroke.Color = Colors.line
        asKnob.BackgroundColor3 = Colors.sub
        TweenService:Create(asKnob, TweenInfo.new(0.15), { Position = UDim2.new(0, 3, 0.5, 0) }):Play()
    end
end

asClick.MouseButton1Click:Connect(function()
    State.autoStart = not State.autoStart
    paintAS()
    persist()
end)
paintAS()

-- ============================================================
-- Controle
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

-- ============================================================
-- Lógica
-- ============================================================

local function doRollback()
    if not UpdateKeybindRemote then return false end
    local ok = pcall(function()
        UpdateKeybindRemote:InvokeServer("MouseButton1", true, "Spike\143")
    end)
    if not ok then return false end
    task.wait(0.5)
    pcall(function() TeleportService:Teleport(game.PlaceId) end)
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

local function doSpinBase()
    if not RollRemote then return false end
    return pcall(function()
        RollRemote:InvokeServer(State.spinType == "Lucky")
    end)
end

-- 3 tentativas com intervalo de 5s
local function trySpinWithIntervals()
    if doSpinBase() then return true end
    task.wait(5)
    if doSpinBase() then return true end
    task.wait(5)
    if doSpinBase() then return true end
    return false
end

local function autoRollbackLoop()
    State.currentTries = 0

    while State.running and State.currentTries < State.spinsPerCycle do
        State.currentTries = State.currentTries + 1
        statusLabel.Text = string.format("Tentativa %d/%d — Girando...", State.currentTries, State.spinsPerCycle)
        statusLabel.TextColor3 = Colors.accent

        local success = trySpinWithIntervals()

        if not success then
            statusLabel.Text = "Falha ao girar (3 tentativas)."
            statusLabel.TextColor3 = Colors.bad
            State.running = false
            startBtn.Text = "INICIAR SPIN"
            startBtn.BackgroundColor3 = Colors.good
            break
        end

        -- Espera o resultado (1.2s)
        task.wait(1.2)

        local result = getCurrentStyle()

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
        end
    end

    if State.running and State.currentTries >= State.spinsPerCycle then
        if State.useRollback then
            statusLabel.Text = "Limite atingido. Dando rollback..."
            statusLabel.TextColor3 = Colors.accent
            doRollback()
        else
            statusLabel.Text = "Limite atingido."
            statusLabel.TextColor3 = Colors.bad
            State.running = false
            startBtn.Text = "INICIAR SPIN"
            startBtn.BackgroundColor3 = Colors.good
        end
    end
end

local thread = nil

local function startSpin()
    if State.running then return end
    State.running = true
    State.currentTries = 0
    startBtn.Text = "RODANDO..."
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 60)
    thread = task.spawn(autoRollbackLoop)
end

local function stopSpin()
    State.running = false
    statusLabel.Text = "Parado."
    statusLabel.TextColor3 = Colors.sub
    startBtn.Text = "INICIAR SPIN"
    startBtn.BackgroundColor3 = Colors.good
    thread = nil
end

startBtn.MouseButton1Click:Connect(startSpin)
stopBtn.MouseButton1Click:Connect(stopSpin)

-- ============================================================
-- Toggle GUI
-- ============================================================

local guiVisible = false
local function setGuiVisible(v)
    guiVisible = v
    Window.Visible = v
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
-- API e Auto Start
-- ============================================================

_G.ScyFeAutoRollback = {
    Start = startSpin,
    Stop = stopSpin,
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
        Text = "Carregado. RightShift abre/fecha.",
        Duration = 4,
    })
end)

print("[ScyFe AutoRollbackStyle] Carregado. RightShift abre/fecha.")

if State.autoStart then
    task.spawn(function()
        print("[ScyFe AutoRollbackStyle] Auto Start ativado. Aguardando carregamento (5s)...")
        task.wait(5) -- Espera inicial de 5 segundos para o jogo carregar
        
        -- Verifica profunda para garantir que a UI existe
        local start = os.clock()
        local ready = false
        while os.clock() - start < 20 do
            local current = getCurrentStyle()
            if current and current ~= "" then
                ready = true
                break
            end
            task.wait(0.5)
        end
        
        if not ready then
            warn("[ScyFe AutoRollbackStyle] Jogo não carregou a tempo.")
            return
        end
        
        task.wait(3) -- Delay extra de segurança
        
        if _G.ScyFeAutoRollback and not State.running then
            print("[ScyFe AutoRollbackStyle] Tudo pronto. Iniciando Auto Start...")
            startSpin()
        end
    end)
end
