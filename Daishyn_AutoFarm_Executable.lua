--[[
    DAISHYN | Auto Farm UI
    Interface-only module for Roblox LocalScripts.
    This file provides a lightweight, mobile-friendly control panel and state API.
    It intentionally does not automate gameplay or invoke game remotes.

    Usage:
        local AutoFarmUI = loadstring(readfile("Daishyn_AutoFarm_GUI.lua"))()
        local panel = AutoFarmUI.new()
        panel.Changed:Connect(function(option, enabled)
            print(option, enabled)
        end)
        panel:Destroy()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local AutoFarmUI = {}
AutoFarmUI.__index = AutoFarmUI

local COLORS = {
    Background = Color3.fromRGB(19, 19, 22),
    Surface = Color3.fromRGB(29, 29, 34),
    SurfaceHover = Color3.fromRGB(39, 39, 45),
    Accent = Color3.fromRGB(255, 135, 45),
    Text = Color3.fromRGB(245, 245, 245),
    Muted = Color3.fromRGB(155, 155, 163),
    Off = Color3.fromRGB(75, 75, 82),
    Green = Color3.fromRGB(75, 190, 120),
}

local OPTIONS = { "TP", "BALL", "BLOCK", "SPIKE", "JUMP" }

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 9) }, parent)
end

local function stroke(parent, color, transparency)
    create("UIStroke", {
        Color = color or COLORS.Accent,
        Transparency = transparency or 0.65,
        Thickness = 1,
    }, parent)
end

function AutoFarmUI.new()
    local self = setmetatable({}, AutoFarmUI)
    self.Enabled = false
    self.Interval = 0.10
    self.Options = {}
    self.Buttons = {}
    self._connections = {}
    self._destroyed = false
    self.Changed = Instance.new("BindableEvent")
    self.ChangedEvent = self.Changed.Event

    for _, name in ipairs(OPTIONS) do
        self.Options[name] = false
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("DaishynAutoFarmUI")
    if old then old:Destroy() end

    self.Gui = create("ScreenGui", {
        Name = "DaishynAutoFarmUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 50,
    }, playerGui)

    self.Main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(250, 420),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
    }, self.Gui)
    corner(self.Main, 13)
    stroke(self.Main, COLORS.Accent, 0.45)

    local scale = create("UIScale", { Scale = 1 }, self.Main)
    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        scale.Scale = math.clamp(math.min(viewport.X / 430, viewport.Y / 520), 0.72, 1)
    end
    updateScale()
    if workspace.CurrentCamera then
        table.insert(self._connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, self.Main)
    corner(header, 13)
    local headerCover = create("Frame", {
        Position = UDim2.new(0, 0, 1, -13),
        Size = UDim2.new(1, 0, 0, 13),
        BackgroundColor3 = COLORS.Surface,
        BorderSizePixel = 0,
    }, header)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -55, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "DAISHYN  /  AUTO FARM",
        TextColor3 = COLORS.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    local close = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = COLORS.Off,
        Text = "×",
        TextColor3 = COLORS.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = true,
    }, header)
    corner(close, 8)
    table.insert(self._connections, close.Activated:Connect(function() self:Destroy() end))

    local dragArea = header
    local dragging, dragStart, startPosition
    table.insert(self._connections, dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = self.Main.Position
        end
    end))
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            self.Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local content = create("Frame", {
        Position = UDim2.fromOffset(12, 58),
        Size = UDim2.new(1, -24, 1, -70),
        BackgroundTransparency = 1,
    }, self.Main)
    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local status = create("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundColor3 = COLORS.Surface,
        Text = "STATUS  •  DESLIGADO",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.GothamSemibold,
        TextSize = 10,
    }, content)
    corner(status, 7)
    self.StatusLabel = status

    local master = create("TextButton", {
        Name = "MasterToggle",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = COLORS.Accent,
        Text = "ATIVAR PAINEL",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = true,
    }, content)
    corner(master, 8)
    table.insert(self._connections, master.Activated:Connect(function()
        self:SetEnabled(not self.Enabled)
    end))
    self.MasterButton = master

    for _, option in ipairs(OPTIONS) do
        local button = create("TextButton", {
            Name = option,
            Size = UDim2.new(1, 0, 0, 29),
            BackgroundColor3 = COLORS.Surface,
            Text = option .. "   •   OFF",
            TextColor3 = COLORS.Muted,
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            AutoButtonColor = true,
        }, content)
        corner(button, 7)
        self.Buttons[option] = button
        table.insert(self._connections, button.Activated:Connect(function()
            self:SetOption(option, not self.Options[option])
        end))
    end

    local intervalLabel = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "INTERVALO: 0.10s",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
    self.IntervalLabel = intervalLabel

    local intervalBox = create("TextBox", {
        Name = "IntervalInput",
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundColor3 = COLORS.Surface,
        Text = "0.10",
        PlaceholderText = "0.05 - 2.00",
        TextColor3 = COLORS.Text,
        PlaceholderColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        ClearTextOnFocus = false,
    }, content)
    corner(intervalBox, 7)
    table.insert(self._connections, intervalBox.FocusLost:Connect(function()
        local value = tonumber(intervalBox.Text)
        if not value then
            intervalBox.Text = string.format("%.2f", self.Interval)
            return
        end
        self:SetInterval(value)
        intervalBox.Text = string.format("%.2f", self.Interval)
    end))

    local note = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "Interface de controle • sem automação incluída",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextWrapped = true,
    }, content)

    return self
end

function AutoFarmUI:SetEnabled(enabled)
    if self._destroyed then return end
    self.Enabled = enabled == true
    self.MasterButton.Text = self.Enabled and "DESATIVAR PAINEL" or "ATIVAR PAINEL"
    self.MasterButton.BackgroundColor3 = self.Enabled and COLORS.Green or COLORS.Accent
    self.StatusLabel.Text = self.Enabled and "STATUS  •  ATIVO" or "STATUS  •  DESLIGADO"
    self.StatusLabel.TextColor3 = self.Enabled and COLORS.Green or COLORS.Muted
    self.Changed:Fire("Enabled", self.Enabled)
end

function AutoFarmUI:SetOption(option, enabled)
    if self._destroyed or self.Options[option] == nil then return end
    self.Options[option] = enabled == true
    local button = self.Buttons[option]
    button.Text = option .. (enabled and "   •   ON" or "   •   OFF")
    button.TextColor3 = enabled and COLORS.Text or COLORS.Muted
    button.BackgroundColor3 = enabled and Color3.fromRGB(65, 43, 29) or COLORS.Surface
    self.Changed:Fire(option, self.Options[option])
end

function AutoFarmUI:SetInterval(value)
    if self._destroyed then return end
    self.Interval = math.clamp(tonumber(value) or 0.10, 0.05, 2.00)
    self.IntervalLabel.Text = string.format("INTERVALO: %.2fs", self.Interval)
    self.Changed:Fire("Interval", self.Interval)
end

function AutoFarmUI:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self._connections)
    if self.Gui then self.Gui:Destroy() end
    if self.Changed then self.Changed:Destroy() end
end

-- Execucao direta: ao executar este arquivo, a interface e criada.
local panel = AutoFarmUI.new()

-- Retorna a instancia para quem quiser controlar a interface pelo proprio script.
return panel
