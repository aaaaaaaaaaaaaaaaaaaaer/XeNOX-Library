local XELIB = {}
XELIB.__index = XELIB

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Constants & Defaults
local DEFAULT_THEME = Color3.fromRGB(0, 255, 255)
local DEFAULT_SHADE = Color3.fromRGB(20, 25, 35)
local DEFAULT_OUTLINE = Color3.fromRGB(0, 255, 255)
local DEFAULT_BUTTON = Color3.fromRGB(0, 180, 230)
local DEFAULT_BTN_OUTLINE = Color3.fromRGB(0, 255, 255)

local ANIM = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FadeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    Slide = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}

-- Utility Helpers
local CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local MATRIX_CHARS = "0123456789ABCDEFµΞXØ$#@&%"

local function RandomString(len)
    len = len or 16
    local t = table.create(len)
    for i = 1, len do
        local r = math.random(1, #CHARS)
        t[i] = string.sub(CHARS, r, r)
    end
    return table.concat(t)
end

local function MakeDraggable(frame, handle, connectionTracker)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    local c1 = handle.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    local c2 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local c3 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    if connectionTracker then
        table.insert(connectionTracker, c1)
        table.insert(connectionTracker, c2)
        table.insert(connectionTracker, c3)
    end
end

local function Tween(obj, info, props)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

-- Instance Pool System
local Pool = {}
local function GetFromPool(poolName, className)
    if not Pool[poolName] then Pool[poolName] = {} end
    if #Pool[poolName] > 0 then
        local obj = table.remove(Pool[poolName])
        obj.Visible = true
        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("TextLabel") then
            obj.BackgroundTransparency = 0
        end
        if obj:IsA("TextLabel") then obj.TextTransparency = 0 end
        if obj:IsA("ImageLabel") then obj.ImageTransparency = 0 end
        return obj
    end
    return Instance.new(className)
end

local function ReturnToPool(poolName, obj)
    obj.Visible = false
    obj.Parent = nil
    if not Pool[poolName] then Pool[poolName] = {} end
    table.insert(Pool[poolName], obj)
end

local function RainbowStroke(stroke)
    task.spawn(function()
        while stroke and stroke.Parent do
            local hue = (tick() * 0.5) % 1
            stroke.Color = Color3.fromHSV(hue, 1, 1)
            task.wait(0.05)
        end
    end)
end

local function CreateRipple(parent, pos)
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, pos.X, 0, pos.Y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.6
    ripple.BorderSizePixel = 0
    ripple.ZIndex = parent.ZIndex + 1
    ripple.Parent = parent
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    task.delay(0.5, function() if ripple then ripple:Destroy() end end)
end

-- Main Library Window
function XELIB:MakeWindow(config)
    config = config or {}

    -- Pre-execution Cleanup
    if getgenv then
        if getgenv().XELIB_ActiveGui then pcall(function() getgenv().XELIB_ActiveGui:Destroy() end) end
        if getgenv().XELIB_ActiveLoading then pcall(function() getgenv().XELIB_ActiveLoading:Destroy() end) end
    end

    local Window = {}
    setmetatable(Window, {__index = XELIB})
    Window._connections = {}

    local winName = config.Name or "XeNOX Library"
    local subTitle = config.SubTitle or ""
    local hasSettings = config.Setting ~= false
    local hasIntro = config.Intro == true
    local Loading_Text = config.IntroText or "LOADING"
    local Loading_Icon = config.IntroIcon or ""
    local Loading_Speed = config.IntroSpeed or 1
    local iconAsset = config.Icon or ""
    local rainbowMain = config.RainbowMainFrame == true
    local rainbowTitle = config.RainbowTitle == true
    local rainbowSub = config.RainbowSubTitle == true
    local closeCallback = config.CloseCallback

    -- Background Effects State
    local effects = {
        Rain = config.Rain or false,
        Trail = config.Trail or false,
        Blob = config.Blob or false,
        Matrix = config.Matrix or false,
        Hex = config.Hex or false,
        Glitch = config.Glitch or false
    }

    local effectColors = {
        Rain = Color3.fromRGB(0, 255, 255),
        Trail = Color3.fromRGB(0, 255, 255),
        Blob = Color3.fromRGB(0, 100, 255),
        Matrix = Color3.fromRGB(0, 255, 120),
        Hex = Color3.fromRGB(0, 200, 255),
        Glitch = Color3.fromRGB(255, 0, 100)
    }

    local theme = {
        Main = DEFAULT_THEME,
        Shade = DEFAULT_SHADE,
        Outline = DEFAULT_OUTLINE,
        Button = DEFAULT_BUTTON,
        ButtonOutline = DEFAULT_BTN_OUTLINE,
        Font = Enum.Font.SourceSansBold
    }

    local menuKey = Enum.KeyCode.RightControl
    local menuOpen = true
    local isMinimized = false

    -- Configuration Engine
    local saveId = config.SaveId or config.Name or "XeNOX_Default"
    local autoSave = config.AutoSave ~= false
    local autoLoad = config.AutoLoad == true
    local configFolder = "XeNOX_Configs/" .. saveId:gsub("[^%w_]", "_")
    local activeConfigName = "default"

    local saveData = {
        toggles = {}, sliders = {}, dropdowns = {}, inputs = {},
        keybinds = {}, colors = {}, theme = {}, effects = effects,
        effectColors = {}, menuKey = nil
    }

    local function EnsureFolder()
        if makefolder then
            pcall(function()
                if not isfolder("XeNOX_Configs") then makefolder("XeNOX_Configs") end
                if not isfolder(configFolder) then makefolder(configFolder) end
            end)
        end
    end

    local function SaveConfig(name)
        name = name or activeConfigName
        if not writefile then return end
        EnsureFolder()
        local success, json = pcall(function() return HttpService:JSONEncode(saveData) end)
        if success then
            pcall(function() writefile(configFolder .. "/" .. name .. ".json", json) end)
        end
    end

    local function LoadConfig(name)
        name = name or activeConfigName
        if not readfile then return nil end
        local path = configFolder .. "/" .. name .. ".json"
        if not isfile or not isfile(path) then return nil end
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        return success and data or nil
    end

    local loadedConfig = LoadConfig() or {}
    if loadedConfig.effects then
        for k, v in pairs(loadedConfig.effects) do if effects[k] ~= nil then effects[k] = v end end
    end

    local function DebouncedSave()
        if not autoSave then return end
        if Window._debounceSave then task.cancel(Window._debounceSave) end
        Window._debounceSave = task.delay(0.5, function() SaveConfig(activeConfigName) end)
    end

    -- Core GUI Instance Setup
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = RandomString(16)
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if gethui then screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(screenGui); screenGui.Parent = PlayerGui
    else screenGui.Parent = CoreGui end

    if getgenv then getgenv().XELIB_ActiveGui = screenGui end

    -- Animated Intro Screen
    if hasIntro then
        local Loading_Screen = Instance.new("ScreenGui")
        Loading_Screen.Name = RandomString(12)
        Loading_Screen.ResetOnSpawn = false
        Loading_Screen.IgnoreGuiInset = true
        if gethui then Loading_Screen.Parent = gethui() else Loading_Screen.Parent = CoreGui end

        local Loading_Frame = Instance.new("Frame", Loading_Screen)
        Loading_Frame.Size = UDim2.new(1, 0, 1, 0)
        Loading_Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        Loading_Frame.BackgroundTransparency = 1

        local iconImg = Instance.new("ImageLabel", Loading_Frame)
        iconImg.Size = UDim2.new(0, 60, 0, 60)
        iconImg.Position = UDim2.new(0.5, -30, 0.35, -30)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = Loading_Icon
        iconImg.ImageTransparency = 1

        local titleLbl = Instance.new("TextLabel", Loading_Frame)
        titleLbl.Size = UDim2.new(1, 0, 0, 40)
        titleLbl.Position = UDim2.new(0, 0, 0.48, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = Loading_Text
        titleLbl.TextColor3 = theme.Main
        titleLbl.Font = Enum.Font.LuckiestGuy
        titleLbl.TextSize = 32
        titleLbl.TextTransparency = 1

        local subLbl = Instance.new("TextLabel", Loading_Frame)
        subLbl.Size = UDim2.new(1, 0, 0, 25)
        subLbl.Position = UDim2.new(0, 0, 0.55, 0)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = winName
        subLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        subLbl.Font = theme.Font
        subLbl.TextSize = 18
        subLbl.TextTransparency = 1

        local barBg = Instance.new("Frame", Loading_Frame)
        barBg.Size = UDim2.new(0, 200, 0, 6)
        barBg.Position = UDim2.new(0.5, -100, 0.65, 0)
        barBg.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        barBg.BackgroundTransparency = 1
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame", barBg)
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = theme.Main
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

        Tween(Loading_Frame, ANIM.Slow, {BackgroundTransparency = 0})
        Tween(iconImg, ANIM.Smooth, {ImageTransparency = 0})
        Tween(titleLbl, ANIM.Smooth, {TextTransparency = 0})
        Tween(subLbl, ANIM.Smooth, {TextTransparency = 0})
        Tween(barBg, ANIM.Smooth, {BackgroundTransparency = 0})
        Tween(barFill, TweenInfo.new(Loading_Speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        task.wait(Loading_Speed + 0.2)

        Tween(Loading_Frame, ANIM.Slow, {BackgroundTransparency = 1})
        Tween(iconImg, ANIM.Fast, {ImageTransparency = 1})
        Tween(titleLbl, ANIM.Fast, {TextTransparency = 1})
        Tween(subLbl, ANIM.Fast, {TextTransparency = 1})
        Tween(barBg, ANIM.Fast, {BackgroundTransparency = 1})
        task.wait(0.5)
        Loading_Screen:Destroy()
    end

    -- Main UI Structure
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = RandomString(16)
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = theme.Shade
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Thickness = 2
    mainStroke.Color = theme.Outline
    if rainbowMain then RainbowStroke(mainStroke) end

    -- FX Engine Canvas Layer
    local fxCanvas = Instance.new("Frame", mainFrame)
    fxCanvas.Name = "FXCanvas"
    fxCanvas.Size = UDim2.new(1, 0, 1, 0)
    fxCanvas.BackgroundTransparency = 1
    fxCanvas.ZIndex = 1
    fxCanvas.ClipsDescendants = true

    -- Header / Title Bar
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 5

    local titleLbl = Instance.new("TextLabel", titleBar)
    titleLbl.Size = UDim2.new(1, -120, 0, 25)
    titleLbl.Position = UDim2.new(0, 15, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = winName
    titleLbl.TextColor3 = theme.Main
    titleLbl.Font = Enum.Font.LuckiestGuy
    titleLbl.TextSize = 22
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    if rainbowTitle then
        local tStroke = Instance.new("UIStroke", titleLbl)
        tStroke.Thickness = 1
        RainbowStroke(tStroke)
    end

    if subTitle ~= "" then
        local subLbl = Instance.new("TextLabel", titleBar)
        subLbl.Size = UDim2.new(1, -120, 0, 18)
        subLbl.Position = UDim2.new(0, 15, 0, 26)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = subTitle
        subLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        subLbl.Font = theme.Font
        subLbl.TextSize = 13
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        if rainbowSub then
            local sStroke = Instance.new("UIStroke", subLbl)
            sStroke.Thickness = 1
            RainbowStroke(sStroke)
        end
    end

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "-"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 28
    closeBtn.Font = Enum.Font.SourceSansBold

    local destroyBtn = Instance.new("TextButton", titleBar)
    destroyBtn.Size = UDim2.new(0, 30, 0, 30)
    destroyBtn.Position = UDim2.new(1, -70, 0, 8)
    destroyBtn.BackgroundTransparency = 1
    destroyBtn.Text = "X"
    destroyBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    destroyBtn.TextSize = 20
    destroyBtn.Font = Enum.Font.SourceSansBold

    destroyBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
        if type(closeCallback) == "function" then closeCallback() end
    end)

    MakeDraggable(mainFrame, titleBar, Window._connections)

    -- Tab & Content Frames
    local tabContainer = Instance.new("Frame", mainFrame)
    tabContainer.Size = UDim2.new(0, 150, 1, -55)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ZIndex = 5

    local tabList = Instance.new("UIListLayout", tabContainer)
    tabList.Padding = UDim.new(0, 8)

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -180, 1, -60)
    contentFrame.Position = UDim2.new(0, 170, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 5

    -- Minimize Action Connection
    local savedSize = mainFrame.Size
    closeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            closeBtn.Text = "+"
            Tween(tabContainer, ANIM.Fast, {Position = UDim2.new(0, -160, 0, 50)})
            Tween(contentFrame, ANIM.Fast, {Position = UDim2.new(0, 300, 0, 50)})
            Tween(mainFrame, ANIM.Smooth, {Size = UDim2.new(0, 700, 0, 45)})
        else
            closeBtn.Text = "-"
            Tween(mainFrame, ANIM.Smooth, {Size = savedSize})
            Tween(tabContainer, ANIM.Smooth, {Position = UDim2.new(0, 10, 0, 50)})
            Tween(contentFrame, ANIM.Smooth, {Position = UDim2.new(0, 170, 0, 50)})
        end
    end)

    -- Keybind Visibility Listener
    table.insert(Window._connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == menuKey then
            menuOpen = not menuOpen
            mainFrame.Visible = menuOpen
        end
    end))

    -- Notifications Engine
    local notifContainer = Instance.new("Frame", screenGui)
    notifContainer.Size = UDim2.new(0, 280, 1, -20)
    notifContainer.Position = UDim2.new(1, -300, 0, 10)
    notifContainer.BackgroundTransparency = 1
    notifContainer.ZIndex = 100

    local notifList = Instance.new("UIListLayout", notifContainer)
    notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifList.Padding = UDim.new(0, 10)

    local activeNotifs = {}
    function Window:Notify(titleText, descText, duration)
        duration = duration or 3
        if #activeNotifs >= 4 then
            local oldest = table.remove(activeNotifs, 1)
            if oldest and oldest.Parent then oldest:Destroy() end
        end

        local notif = Instance.new("Frame", notifContainer)
        notif.Size = UDim2.new(1, 0, 0, 65)
        notif.BackgroundColor3 = theme.Shade
        notif.BackgroundTransparency = 0.1
        notif.ZIndex = 105
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = theme.Outline
        stroke.Thickness = 2

        local tLbl = Instance.new("TextLabel", notif)
        tLbl.Size = UDim2.new(1, -20, 0, 25)
        tLbl.Position = UDim2.new(0, 10, 0, 5)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = titleText
        tLbl.TextColor3 = theme.Main
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Font = theme.Font
        tLbl.TextSize = 16

        local dLbl = Instance.new("TextLabel", notif)
        dLbl.Size = UDim2.new(1, -20, 0, 25)
        dLbl.Position = UDim2.new(0, 10, 0, 30)
        dLbl.BackgroundTransparency = 1
        dLbl.Text = descText
        dLbl.TextColor3 = Color3.new(1, 1, 1)
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Font = theme.Font
        dLbl.TextSize = 13

        local progressBar = Instance.new("Frame", notif)
        progressBar.Size = UDim2.new(1, 0, 0, 3)
        progressBar.Position = UDim2.new(0, 0, 1, -3)
        progressBar.BackgroundColor3 = theme.Main
        progressBar.BorderSizePixel = 0

        table.insert(activeNotifs, notif)
        Tween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)})

        task.delay(duration, function()
            if notif and notif.Parent then
                for i, v in ipairs(activeNotifs) do if v == notif then table.remove(activeNotifs, i) break end end
                notif:Destroy()
            end
        end)
    end

    -- ==================== VISUAL EFFECTS ENGINE ====================
    local blobs = {}
    for i = 1, 4 do
        local b = Instance.new("Frame", fxCanvas)
        b.Size = UDim2.new(0, 120, 0, 120)
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.Position = UDim2.new(math.random(), 0, math.random(), 0)
        b.BackgroundColor3 = effectColors.Blob
        b.BackgroundTransparency = 0.85
        b.ZIndex = 1
        b.Visible = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        blobs[i] = b
    end

    Window._backgroundThread = task.spawn(function()
        local step = 0
        while task.wait(0.03) do
            if not mainFrame or not mainFrame.Parent or not mainFrame.Visible then continue end
            step = step + 0.03

            local mLoc = UserInputService:GetMouseLocation()
            local framePos = mainFrame.AbsolutePosition
            local relMouseX = mLoc.X - framePos.X
            local relMouseY = mLoc.Y - framePos.Y

            -- 1. Rain
            if effects.Rain then
                local drop = GetFromPool("RainDrop", "Frame")
                drop.Size = UDim2.new(0, 2, 0, math.random(15, 35))
                drop.Position = UDim2.new(math.random(), 0, -0.1, 0)
                drop.BackgroundColor3 = effectColors.Rain
                drop.BackgroundTransparency = 0.2
                drop.ZIndex = 2
                drop.Parent = fxCanvas
                Tween(drop, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(drop.Position.X.Scale, 0, 1.1, 0),
                    BackgroundTransparency = 1
                })
                task.delay(0.5, function() ReturnToPool("RainDrop", drop) end)
            end

            -- 2. Trail
            if effects.Trail and relMouseX >= 0 and relMouseX <= mainFrame.AbsoluteSize.X and relMouseY >= 0 and relMouseY <= mainFrame.AbsoluteSize.Y then
                local trail = GetFromPool("TrailDot", "Frame")
                trail.Size = UDim2.new(0, 12, 0, 12)
                trail.Position = UDim2.new(0, relMouseX - 6, 0, relMouseY - 6)
                trail.BackgroundColor3 = effectColors.Trail
                trail.BackgroundTransparency = 0.3
                trail.ZIndex = 3
                trail.Parent = fxCanvas
                Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)
                Tween(trail, TweenInfo.new(0.4), {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0, relMouseX, 0, relMouseY),
                    BackgroundTransparency = 1
                })
                task.delay(0.4, function() ReturnToPool("TrailDot", trail) end)
            end

            -- 3. Blob
            for i, b in ipairs(blobs) do
                b.Visible = effects.Blob
                if effects.Blob then
                    b.BackgroundColor3 = effectColors.Blob
                    local offsetX = math.sin(step + i) * 0.15
                    local offsetY = math.cos(step * 0.8 + i) * 0.15
                    b.Position = UDim2.new(0.5 + offsetX, 0, 0.5 + offsetY, 0)
                end
            end

            -- 4. Matrix
            if effects.Matrix and math.random(1, 2) == 1 then
                local matChar = GetFromPool("MatrixChar", "TextLabel")
                local rIndex = math.random(1, #MATRIX_CHARS)
                matChar.Text = string.sub(MATRIX_CHARS, rIndex, rIndex)
                matChar.Size = UDim2.new(0, 15, 0, 15)
                matChar.Position = UDim2.new(math.random(), 0, -0.05, 0)
                matChar.BackgroundTransparency = 1
                matChar.TextColor3 = effectColors.Matrix
                matChar.Font = Enum.Font.Code
                matChar.TextSize = math.random(12, 16)
                matChar.ZIndex = 2
                matChar.Parent = fxCanvas
                Tween(matChar, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(matChar.Position.X.Scale, 0, 1.05, 0),
                    TextTransparency = 1
                })
                task.delay(1.2, function() ReturnToPool("MatrixChar", matChar) end)
            end

            -- 5. Hex
            if effects.Hex and math.random(1, 4) == 1 then
                local hex = GetFromPool("HexParticle", "ImageLabel")
                hex.Size = UDim2.new(0, 20, 0, 20)
                hex.Position = UDim2.new(math.random(), 0, 1.05, 0)
                hex.BackgroundTransparency = 1
                hex.Image = "rbxassetid://6015808269"
                hex.ImageColor3 = effectColors.Hex
                hex.ImageTransparency = 0.2
                hex.ZIndex = 2
                hex.Parent = fxCanvas
                Tween(hex, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(hex.Position.X.Scale, math.random(-30, 30), -0.1, 0),
                    Rotation = math.random(0, 180),
                    ImageTransparency = 1
                })
                task.delay(1.8, function() ReturnToPool("HexParticle", hex) end)
            end

            -- 6. Glitch
            if effects.Glitch and math.random(1, 25) == 1 then
                local gSlice = GetFromPool("GlitchSlice", "Frame")
                gSlice.Size = UDim2.new(1, 0, 0, math.random(2, 12))
                gSlice.Position = UDim2.new(0, math.random(-10, 10), math.random(), 0)
                gSlice.BackgroundColor3 = effectColors.Glitch
                gSlice.BackgroundTransparency = 0.5
                gSlice.ZIndex = 4
                gSlice.Parent = fxCanvas
                task.delay(0.08, function() ReturnToPool("GlitchSlice", gSlice) end)
            end
        end
    end)

    -- Tab System
    local tabs = {}
    local tabCount = 0

    function Window:AddTab(name)
        tabCount = tabCount + 1
        local tabID = tabCount

        local tabBtn = Instance.new("TextButton", tabContainer)
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.BackgroundColor3 = theme.Button
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.Font = theme.Font
        tabBtn.TextSize = 16
        tabBtn.LayoutOrder = tabID
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

        local page = Instance.new("ScrollingFrame", contentFrame)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = theme.Main
        page.Visible = (tabID == 1)

        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)

        tabs[tabID] = {Page = page, Btn = tabBtn}

        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(tabs) do v.Page.Visible = false end
            page.Visible = true
        end)

        local Tab = {}

        -- 1. Label
        function Tab:AddLabel(text)
            local l = Instance.new("TextLabel", page)
            l.Size = UDim2.new(1, -10, 0, 35)
            l.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            l.Text = "  " .. text
            l.TextColor3 = Color3.new(1, 1, 1)
            l.Font = theme.Font
            l.TextSize = 16
            l.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
            return l
        end

        -- 2. Paragraph
        function Tab:AddParagraph(title, content)
            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 75)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local t = Instance.new("TextLabel", frame)
            t.Size = UDim2.new(1, -20, 0, 25)
            t.Position = UDim2.new(0, 10, 0, 5)
            t.BackgroundTransparency = 1
            t.Text = title
            t.TextColor3 = theme.Main
            t.Font = theme.Font
            t.TextSize = 16
            t.TextXAlignment = Enum.TextXAlignment.Left

            local c = Instance.new("TextLabel", frame)
            c.Size = UDim2.new(1, -20, 0, 40)
            c.Position = UDim2.new(0, 10, 0, 30)
            c.BackgroundTransparency = 1
            c.Text = content
            c.TextColor3 = Color3.fromRGB(180, 180, 180)
            c.Font = theme.Font
            c.TextSize = 13
            c.TextXAlignment = Enum.TextXAlignment.Left
            c.TextWrapped = true
        end

        -- 3. Button
        function Tab:AddButton(text, callback)
            local btn = Instance.new("TextButton", page)
            btn.Size = UDim2.new(1, -10, 0, 40)
            btn.BackgroundColor3 = theme.Button
            btn.Text = text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = theme.Font
            btn.TextSize = 16
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseButton1Click:Connect(function()
                CreateRipple(btn, Vector2.new(btn.AbsoluteSize.X / 2, btn.AbsoluteSize.Y / 2))
                if callback then callback() end
            end)
        end

        -- 4. Toggle
        function Tab:AddToggle(text, default, callback)
            local saved = loadedConfig.toggles and loadedConfig.toggles[text]
            local enabled = (saved ~= nil) and saved or (default or false)

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 45)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -60, 1, 0)
            lb.Position = UDim2.new(0, 12, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 16
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local bg = Instance.new("TextButton", frame)
            bg.Size = UDim2.new(0, 40, 0, 22)
            bg.Position = UDim2.new(1, -50, 0.5, -11)
            bg.BackgroundColor3 = enabled and theme.Button or Color3.fromRGB(40, 45, 55)
            bg.Text = ""
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

            local ball = Instance.new("Frame", bg)
            ball.Size = UDim2.new(0, 16, 0, 16)
            ball.Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            ball.BackgroundColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

            bg.MouseButton1Click:Connect(function()
                enabled = not enabled
                saveData.toggles[text] = enabled
                DebouncedSave()
                Tween(bg, ANIM.Normal, {BackgroundColor3 = enabled and theme.Button or Color3.fromRGB(40, 45, 55)})
                Tween(ball, ANIM.Spring, {Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                if callback then callback(enabled) end
            end)
        end

        -- 5. Slider
        function Tab:AddSlider(text, min, max, default, callback)
            min, max = min or 0, max or 100
            local saved = loadedConfig.sliders and loadedConfig.sliders[text]
            local val = saved or default or min

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 55)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -60, 0, 25)
            lb.Position = UDim2.new(0, 12, 0, 4)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 16
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local valLbl = Instance.new("TextLabel", frame)
            valLbl.Size = UDim2.new(0, 50, 0, 25)
            valLbl.Position = UDim2.new(1, -60, 0, 4)
            valLbl.Text = tostring(val)
            valLbl.TextColor3 = theme.Main
            valLbl.Font = theme.Font
            valLbl.TextSize = 16
            valLbl.BackgroundTransparency = 1

            local sliderTrack = Instance.new("TextButton", frame)
            sliderTrack.Size = UDim2.new(1, -24, 0, 8)
            sliderTrack.Position = UDim2.new(0, 12, 0, 36)
            sliderTrack.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
            sliderTrack.Text = ""
            Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame", sliderTrack)
            fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = theme.Button
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local dragging = false
            local function UpdateSlider(input)
                local percent = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
                val = math.floor(min + (max - min) * percent)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                valLbl.Text = tostring(val)
                saveData.sliders[text] = val
                DebouncedSave()
                if callback then callback(val) end
            end

            sliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; UpdateSlider(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end

        -- 6. Input
        function Tab:AddInput(text, default, callback)
            local saved = loadedConfig.inputs and loadedConfig.inputs[text]
            local val = saved or default or ""

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 45)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -150, 1, 0)
            lb.Position = UDim2.new(0, 12, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 16
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local box = Instance.new("TextBox", frame)
            box.Size = UDim2.new(0, 120, 0, 28)
            box.Position = UDim2.new(1, -132, 0.5, -14)
            box.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
            box.Text = val
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = theme.Font
            box.TextSize = 14
            box.ClearTextOnFocus = false
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

            box.FocusLost:Connect(function()
                saveData.inputs[text] = box.Text
                DebouncedSave()
                if callback then callback(box.Text) end
            end)
        end

        -- 7. Dropdown
        function Tab:AddDropdown(text, options, default, callback)
            options = options or {}
            local saved = loadedConfig.dropdowns and loadedConfig.dropdowns[text]
            local selected = saved or default or options[1] or "None"
            local expanded = false

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 45)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            frame.ClipsDescendants = true
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(1, 0, 0, 45)
            btn.BackgroundTransparency = 1
            btn.Text = "  " .. text .. ": " .. selected
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = theme.Font
            btn.TextSize = 16
            btn.TextXAlignment = Enum.TextXAlignment.Left

            local holder = Instance.new("Frame", frame)
            holder.Size = UDim2.new(1, -20, 0, #options * 30)
            holder.Position = UDim2.new(0, 10, 0, 45)
            holder.BackgroundTransparency = 1

            local hList = Instance.new("UIListLayout", holder)
            hList.Padding = UDim.new(0, 2)

            for _, opt in ipairs(options) do
                local oBtn = Instance.new("TextButton", holder)
                oBtn.Size = UDim2.new(1, 0, 0, 28)
                oBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
                oBtn.Text = opt
                oBtn.TextColor3 = Color3.new(1, 1, 1)
                oBtn.Font = theme.Font
                oBtn.TextSize = 14
                Instance.new("UICorner", oBtn).CornerRadius = UDim.new(0, 4)

                oBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    btn.Text = "  " .. text .. ": " .. selected
                    expanded = false
                    Tween(frame, ANIM.Fast, {Size = UDim2.new(1, -10, 0, 45)})
                    saveData.dropdowns[text] = selected
                    DebouncedSave()
                    if callback then callback(selected) end
                end)
            end

            btn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetH = expanded and (45 + #options * 30 + 10) or 45
                Tween(frame, ANIM.Fast, {Size = UDim2.new(1, -10, 0, targetH)})
            end)
        end

        -- 8. Keybind
        function Tab:AddKeybind(text, defaultKey, callback)
            local saved = loadedConfig.keybinds and loadedConfig.keybinds[text]
            local currentKey = saved and Enum.KeyCode[saved] or defaultKey or Enum.KeyCode.E
            local binding = false

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 45)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -120, 1, 0)
            lb.Position = UDim2.new(0, 12, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 16
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(0, 90, 0, 28)
            btn.Position = UDim2.new(1, -102, 0.5, -14)
            btn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
            btn.Text = currentKey.Name
            btn.TextColor3 = theme.Main
            btn.Font = theme.Font
            btn.TextSize = 14
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            btn.MouseButton1Click:Connect(function()
                binding = true
                btn.Text = "..."
            end)

            table.insert(Window._connections, UserInputService.InputBegan:Connect(function(input, gpe)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        currentKey = input.KeyCode
                        btn.Text = currentKey.Name
                        saveData.keybinds[text] = currentKey.Name
                        DebouncedSave()
                    end
                elseif not gpe and input.KeyCode == currentKey then
                    if callback then callback(currentKey) end
                end
            end))
        end

        -- 9. Color Picker
        function Tab:AddColorPicker(text, defaultColor, callback)
            local saved = loadedConfig.colors and loadedConfig.colors[text]
            local color = saved and Color3.fromRGB(saved.R, saved.G, saved.B) or defaultColor or Color3.fromRGB(255, 255, 255)

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 45)
            frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -60, 1, 0)
            lb.Position = UDim2.new(0, 12, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 16
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local box = Instance.new("TextButton", frame)
            box.Size = UDim2.new(0, 32, 0, 22)
            box.Position = UDim2.new(1, -44, 0.5, -11)
            box.BackgroundColor3 = color
            box.Text = ""
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

            box.MouseButton1Click:Connect(function()
                local h, s, v = Color3.toHSV(color)
                color = Color3.fromHSV((h + 0.15) % 1, 1, 1)
                box.BackgroundColor3 = color
                saveData.colors[text] = {R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255)}
                DebouncedSave()
                if callback then callback(color) end
            end)
        end

        return Tab
    end

    -- ==================== SETTINGS & CONFIG TAB ====================
    if hasSettings then
        local settingsTab = Window:AddTab("Settings")

        settingsTab:AddLabel("Background Visual Effects")
        settingsTab:AddToggle("Rain Effect", effects.Rain, function(t) effects.Rain = t; saveData.effects.Rain = t; DebouncedSave() end)
        settingsTab:AddToggle("Trail Effect", effects.Trail, function(t) effects.Trail = t; saveData.effects.Trail = t; DebouncedSave() end)
        settingsTab:AddToggle("Blob Effect", effects.Blob, function(t) effects.Blob = t; saveData.effects.Blob = t; DebouncedSave() end)
        settingsTab:AddToggle("Matrix Effect", effects.Matrix, function(t) effects.Matrix = t; saveData.effects.Matrix = t; DebouncedSave() end)
        settingsTab:AddToggle("Hex Effect", effects.Hex, function(t) effects.Hex = t; saveData.effects.Hex = t; DebouncedSave() end)
        settingsTab:AddToggle("Glitch Effect", effects.Glitch, function(t) effects.Glitch = t; saveData.effects.Glitch = t; DebouncedSave() end)

        settingsTab:AddLabel("Effect Colors")
        settingsTab:AddColorPicker("Rain Color", effectColors.Rain, function(c) effectColors.Rain = c end)
        settingsTab:AddColorPicker("Trail Color", effectColors.Trail, function(c) effectColors.Trail = c end)
        settingsTab:AddColorPicker("Matrix Color", effectColors.Matrix, function(c) effectColors.Matrix = c end)

        settingsTab:AddLabel("Config Engine")
        local newConfigName = ""
        settingsTab:AddInput("Config Name", "default", function(txt)
            newConfigName = txt:gsub("[^%w_]", "_")
        end)

        settingsTab:AddButton("Save Config", function()
            local target = (newConfigName ~= "") and newConfigName or activeConfigName
            SaveConfig(target)
            Window:Notify("Config Saved", "Saved data to '" .. target .. "'", 2)
        end)

        settingsTab:AddToggle("Auto Save On Change", autoSave, function(t)
            autoSave = t
        end)
    end

    function Window:Destroy()
        if Window._backgroundThread then task.cancel(Window._backgroundThread) end
        for _, conn in ipairs(Window._connections) do if conn and conn.Connected then conn:Disconnect() end end
        if screenGui then screenGui:Destroy() end
    end

    return Window
end

return XELIB
