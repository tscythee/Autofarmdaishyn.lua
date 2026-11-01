--[[
    ScyFe Visuals - Data Rollback (botão único)
    Jogo: Volleyball Legends
    Autor: Daishyn / ScyFe Visuals
    Uso: cole no executor e injete. Um botão, clica e rollback.
]]

if _G.ScyFe_Rollback and _G.ScyFe_Rollback.Unload then
    pcall(_G.ScyFe_Rollback.Unload)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

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
        Color = color or Color3.fromRGB(60, 65, 80),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

-- ============================================================
-- Remota do rollback (mesma da Source)
-- ============================================================

local function getUpdateKeybind()
    local ok, remote = pcall(function()
        return ReplicatedStorage
            .Packages._Index["sleitnick_knit@1.7.0"]
            .knit.Services.SettingsService.RF.UpdateKeybind
    end)
    if ok and remote then return remote end

    local ok2, found = pcall(function()
        local Index = ReplicatedStorage.Packages._Index
        for _, pkg in ipairs(Index:GetChildren()) do
            if pkg.Name:find("knit") then
                local Settings = pkg.knit.Services:FindFirstChild("SettingsService")
                local RF = Settings and Settings:FindFirstChild("RF")
                local UK = RF and RF:FindFirstChild("UpdateKeybind")
                if UK then return UK end
            end
        end
        return nil
    end)
    return ok2 and found or nil
end

-- ============================================================
-- Cores
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

-- ============================================================
-- GUI
-- ============================================================

local ScreenGui = newInstance("ScreenGui", {
    Name = "ScyFe_Rollback",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
})
protect(ScreenGui)
if not ScreenGui.Parent then ScreenGui.Parent = getHiddenParent() end

-- Botão principal, sempre visível
local MainBtn = newInstance("TextButton", {
    Size = UDim2.fromOffset(140, 44),
    Position = UDim2.new(0.5, -70, 0, 90),
    BackgroundColor3 = Colors.accentD,
    BorderSizePixel = 0,
    Text = "DATA ROLLBACK",
    TextColor3 = Colors.text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    AutoButtonColor = false,
    Selectable = false,
    ZIndex = 50,
}, ScreenGui)
corner(MainBtn, 10)
stroke(MainBtn, Colors.accent, 1)

-- Label de status logo abaixo
local Status = newInstance("TextLabel", {
    Size = UDim2.fromOffset(140, 16),
    Position = UDim2.new(0.5, -70, 0, 136),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Colors.sub,
    Text = "",
    ZIndex = 50,
}, ScreenGui)

-- Arrastar botão
do
    local dragging, dragStart, posStart
    MainBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            posStart = MainBtn.Position
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
            local newPos = UDim2.new(
                posStart.X.Scale, posStart.X.Offset + delta.X,
                posStart.Y.Scale, posStart.Y.Offset + delta.Y
            )
            MainBtn.Position = newPos
            Status.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset,
                newPos.Y.Scale, newPos.Y.Offset + 46
            )
        end
    end)
end

-- Hover
MainBtn.MouseEnter:Connect(function()
    TweenService:Create(MainBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Colors.accent,
    }):Play()
end)
MainBtn.MouseLeave:Connect(function()
    TweenService:Create(MainBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Colors.accentD,
    }):Play()
end)

-- ============================================================
-- Função do botão — idêntica à Source
-- ============================================================

local running = false

local function doRollback()
    if running then return end
    running = true
    MainBtn.Text = "ROLLING BACK..."
    Status.Text = "Enviando remota..."
    Status.TextColor3 = Colors.accent

    local remote = getUpdateKeybind()
    if not remote then
        Status.Text = "UpdateKeybind não encontrado"
        Status.TextColor3 = Colors.bad
        MainBtn.Text = "DATA ROLLBACK"
        running = false
        return
    end

    local ok, err = pcall(function()
        remote:InvokeServer("MouseButton1", true, "Spike\143")
    end)

    if not ok then
        Status.Text = "Erro: " .. tostring(err)
        Status.TextColor3 = Colors.bad
        MainBtn.Text = "DATA ROLLBACK"
        running = false
        return
    end

    Status.Text = "Rollback enviado, teleportando..."
    Status.TextColor3 = Colors.good

    task.wait(0.5)
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
end

MainBtn.MouseButton1Click:Connect(doRollback)

-- ============================================================
-- API pública
-- ============================================================

_G.ScyFe_Rollback = {
    Run = doRollback,
    Gui = ScreenGui,
    Unload = function()
        pcall(function() ScreenGui:Destroy() end)
        _G.ScyFe_Rollback = nil
    end,
}

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ScyFe Rollback",
        Text = "Botão carregado.",
        Duration = 3,
    })
end)

print("[ScyFe Rollback] Carregado. Botão na tela.")