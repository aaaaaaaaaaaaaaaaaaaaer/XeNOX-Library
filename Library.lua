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
local DEFAULT_SHADE = Color3.fromRGB(25, 55, 95)
local DEFAULT_OUTLINE = Color3.fromRGB(0, 255, 255)
local DEFAULT_BUTTON = Color3.fromRGB(0, 200, 255)
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
    Pop = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Pulse = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

-- Utility Functions
local CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
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
    local dragging = false
    local dragStart, startPos

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
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
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
    task.delay(0.5, function()
        if ripple then ripple:Destroy() end
    end)
end

function XELIB:MakeWindow(config)
    config = config or {}
    
    -- Cleanup pre-existing active windows
    if getgenv and getgenv().XELIB_ActiveGui and typeof(getgenv().XELIB_ActiveGui) == "Instance" then
        pcall(function() getgenv().XELIB_ActiveGui:Destroy() end)
        getgenv().XELIB_ActiveGui = nil
    end
    if getgenv and getgenv().XELIB_ActiveLoading and typeof(getgenv().XELIB_ActiveLoading) == "Instance" then
        pcall(function() getgenv().XELIB_ActiveLoading:Destroy() end)
        getgenv().XELIB_ActiveLoading = nil
    end
    if getgenv and getgenv().XELIB_ToggleBtn and typeof(getgenv().XELIB_ToggleBtn) == "Instance" then
        pcall(function() getgenv().XELIB_ToggleBtn:Destroy() end)
        getgenv().XELIB_ToggleBtn = nil
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
    local toggleIcon = config.ToggleIcon or ""
    local closeCallback = config.CloseCallback

    local effects = {
        Rain = false, Trail = false, Blob = false, Matrix = false, Hex = false, Glitch = false
    }
    local effectColors = {
        Rain = Color3.fromRGB(255, 255, 255),
        Trail = Color3.fromRGB(0, 255, 255),
        Blob = Color3.fromRGB(0, 20, 100),
        Matrix = Color3.fromRGB(0, 255, 0),
        Hex = Color3.fromRGB(0, 255, 255),
        Glitch = Color3.fromRGB(255, 255, 255)
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

    -- Save System Setup
    local saveId = config.SaveId or config.Name or "XeNOX_Default"
    local autoSave = config.AutoSave ~= false
    local autoLoad = config.AutoLoad == true
    local configFolder = "XeNOX_Configs/" .. saveId:gsub("[^%w_]", "_")
    local activeConfigName = "default"
    
    local saveData = {
        toggles = {}, sliders = {}, dropdowns = {}, inputs = {},
        keybinds = {}, colors = {}, theme = {}, effects = {},
        effectColors = {}, menuKey = nil, _autoSave = nil, _autoLoad = nil,
        _activeConfigName = nil, custom = {}
    }

    local function EnsureFolder()
        if makefolder then
            pcall(function()
                if not isfolder("XeNOX_Configs") then makefolder("XeNOX_Configs") end
                if not isfolder(configFolder) then makefolder(configFolder) end
            end)
        end
    end

    local function GetConfigPath(name)
        return configFolder .. "/" .. name:gsub("[^%w_]", "_") .. ".json"
    end

    local function ListConfigs()
        local list = {}
        if not isfolder or not isfolder(configFolder) then return list end
        local success, files = pcall(function() return listfiles(configFolder) end)
        if not success or type(files) ~= "table" then return list end
        for _, path in ipairs(files) do
            local normalized = path:gsub("\\", "/")
            local name = normalized:match("([^/]+)%.json$")
            if name then table.insert(list, name) end
        end
        return list
    end

    local function SaveConfig(name)
        name = name or activeConfigName
        if not writefile then return end
        EnsureFolder()
        local path = GetConfigPath(name)
        local success, json = pcall(function() return HttpService:JSONEncode(saveData) end)
        if success then
            pcall(function() writefile(path, json) end)
        end
    end

    local function LoadConfig(name)
        name = name or activeConfigName
        if not isfile or not readfile then return nil end
        local path = GetConfigPath(name)
        if not isfile(path) then return nil end
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        return (success and type(data) == "table") and data or nil
    end

    local function DeleteConfig(name)
        if not isfile then return false end
        local path = GetConfigPath(name)
        if isfile(path) then
            pcall(function() delfile(path) end)
            return true
        end
        return false
    end

    local loadedConfig = LoadConfig() or {}

    -- Apply initial loaded options
    if loadedConfig.effects then
        for k, v in pairs(loadedConfig.effects) do if effects[k] ~= nil then effects[k] = v end end
    end
    if loadedConfig.effectColors then
        for k, v in pairs(loadedConfig.effectColors) do
            if effectColors[k] and type(v) == "table" and v.R and v.G and v.B then
                effectColors[k] = Color3.fromRGB(v.R, v.G, v.B)
            end
        end
    end
    if loadedConfig._autoSave ~= nil then autoSave = loadedConfig._autoSave end
    if loadedConfig._autoLoad ~= nil then autoLoad = loadedConfig._autoLoad end
    if loadedConfig.custom and type(loadedConfig.custom) == "table" then saveData.custom = loadedConfig.custom end
    if loadedConfig._activeConfigName and type(loadedConfig._activeConfigName) == "string" then activeConfigName = loadedConfig._activeConfigName end
    
    if loadedConfig.theme then
        for k, v in pairs(loadedConfig.theme) do
            if k == "Font" and type(v) == "string" then
                for _, f in ipairs({Enum.Font.SourceSansBold, Enum.Font.Roboto, Enum.Font.GothamBold, Enum.Font.Arcade, Enum.Font.Code, Enum.Font.SciFi}) do
                    if f.Name == v then theme.Font = f; break end
                end
            elseif theme[k] and type(v) == "table" and v.R and v.G and v.B then
                theme[k] = Color3.fromRGB(v.R, v.G, v.B)
            end
        end
    end
    if loadedConfig.menuKey and type(loadedConfig.menuKey) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[loadedConfig.menuKey] end)
        if ok and key then menuKey = key end
    end

    Window._loadedConfig = loadedConfig
    Window._saveData = saveData
    Window._saveConfigFunc = SaveConfig

    local uiRegistry = {
        toggles = {}, sliders = {}, dropdowns = {}, inputs = {}, keybinds = {}, colors = {}
    }
    Window._uiRegistry = uiRegistry

    local function DebouncedSave()
        if not autoSave then return end
        saveData._activeConfigName = activeConfigName
        if Window._debounceSave then task.cancel(Window._debounceSave) end
        Window._debounceSave = task.delay(0.5, function()
            SaveConfig(activeConfigName)
            Window._debounceSave = nil
        end)
    end

    local tabs = {}
    local tabCount = 0
    local activeNotifs = {}
    local uiCache = {Shade = {}, Button = {}, ButtonOutline = {}, Text = {}}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = RandomString(16)
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = PlayerGui
    else
        screenGui.Parent = CoreGui
    end

    if getgenv then getgenv().XELIB_ActiveGui = screenGui end

    -- Intro Screen Implementation
    if hasIntro then
        local Loading_Screen = Instance.new("ScreenGui")
        Loading_Screen.Name = RandomString(12)
        Loading_Screen.ResetOnSpawn = false
        Loading_Screen.IgnoreGuiInset = true
        if gethui then Loading_Screen.Parent = gethui()
        elseif syn and syn.protect_gui then syn.protect_gui(Loading_Screen); Loading_Screen.Parent = PlayerGui
        else Loading_Screen.Parent = CoreGui end
        
        if getgenv then getgenv().XELIB_ActiveLoading = Loading_Screen end

        local Loading_Frame = Instance.new("Frame")
        Loading_Frame.Size = UDim2.new(1, 0, 1, 0)
        Loading_Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        Loading_Frame.BackgroundTransparency = 1
        Loading_Frame.Parent = Loading_Screen

        local Loading_Stroke = Instance.new("UIStroke", Loading_Frame)
        Loading_Stroke.Thickness = 2
        Loading_Stroke.Color = theme.Main
        Loading_Stroke.Transparency = 1
        if rainbowMain then RainbowStroke(Loading_Stroke) end

        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 0, 0, 0)
        iconImg.Position = UDim2.new(0.5, 0, 0.4, 0)
        iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = Loading_Icon
        iconImg.ImageTransparency = 1
        iconImg.Parent = Loading_Frame

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, 0, 0, 40)
        titleLbl.Position = UDim2.new(0, 0, 0.55, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = Loading_Text
        titleLbl.TextColor3 = theme.Main
        titleLbl.Font = Enum.Font.LuckiestGuy
        titleLbl.TextSize = 32
        titleLbl.TextTransparency = 1
        titleLbl.Parent = Loading_Frame

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, 0, 0, 25)
        subLbl.Position = UDim2.new(0, 0, 0.62, 0)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = winName
        subLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        subLbl.Font = theme.Font
        subLbl.TextSize = 18
        subLbl.TextTransparency = 1
        subLbl.Parent = Loading_Frame

        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(0, 0, 0, 6)
        barBg.Position = UDim2.new(0.5, 0, 0.7, 0)
        barBg.AnchorPoint = Vector2.new(0.5, 0.5)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        barBg.BackgroundTransparency = 1
        barBg.Parent = Loading_Frame
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = theme.Main
        barFill.BackgroundTransparency = 1
        barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

        Tween(Loading_Frame, ANIM.Slow, {BackgroundTransparency = 0})
        task.wait(0.1)
        Tween(iconImg, ANIM.Bounce, {Size = UDim2.new(0, 80, 0, 80), Position = UDim2.new(0.5, -40, 0.4, -40), ImageTransparency = 0})
        task.wait(0.15)
        Tween(titleLbl, ANIM.Smooth, {TextTransparency = 0})
        task.wait(0.1)
        Tween(subLbl, ANIM.Smooth, {TextTransparency = 0})
        task.wait(0.1)
        Tween(barBg, ANIM.Smooth, {Size = UDim2.new(0, 200, 0, 6), BackgroundTransparency = 0})
        task.wait(0.2)
        Tween(barFill, ANIM.Slow, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0})
        task.wait(Loading_Speed + 0.2)
        
        Tween(barFill, ANIM.Fast, {BackgroundTransparency = 1})
        Tween(barBg, ANIM.Fast, {BackgroundTransparency = 1})
        Tween(subLbl, ANIM.Fast, {TextTransparency = 1})
        Tween(titleLbl, ANIM.Fast, {TextTransparency = 1})
        Tween(iconImg, ANIM.Fast, {ImageTransparency = 1, Size = UDim2.new(0, 100, 0, 100)})
        task.wait(0.2)
        Tween(Loading_Frame, ANIM.Slow, {BackgroundTransparency = 1})
        task.wait(0.4)
        Loading_Screen:Destroy()
        if getgenv then getgenv().XELIB_ActiveLoading = nil end
    end

    -- Main GUI Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = RandomString(16)
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = theme.Main
    mainFrame.BackgroundTransparency = 1
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

    local savedPos = mainFrame.Position
    local savedSize = mainFrame.Size

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = mainFrame
    uiScale.Scale = 0.7

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 0
    mainStroke.Color = theme.Outline
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    if rainbowMain then RainbowStroke(mainStroke) end

    Tween(mainFrame, ANIM.Smooth, {BackgroundTransparency = 0.4})
    Tween(mainStroke, ANIM.Smooth, {Thickness = 2})
    Tween(uiScale, ANIM.Bounce, {Scale = 1})

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 5
    titleBar.Active = true
    titleBar.Parent = mainFrame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -120, 0, 25)
    titleLbl.Position = UDim2.new(0, 15, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = winName
    titleLbl.TextColor3 = theme.Main
    titleLbl.Font = Enum.Font.LuckiestGuy
    titleLbl.TextSize = 22
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 5
    titleLbl.TextTransparency = 1
    titleLbl.Parent = titleBar
    Tween(titleLbl, ANIM.Smooth, {TextTransparency = 0})

    if rainbowTitle then
        local tStroke = Instance.new("UIStroke", titleLbl)
        tStroke.Thickness = 1
        RainbowStroke(tStroke)
    end

    if subTitle ~= "" then
        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -120, 0, 18)
        subLbl.Position = UDim2.new(0, 15, 0, 28)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = subTitle
        subLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        subLbl.Font = theme.Font
        subLbl.TextSize = 14
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.ZIndex = 5
        subLbl.TextTransparency = 1
        subLbl.Parent = titleBar
        Tween(subLbl, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {TextTransparency = 0})
        if rainbowSub then
            local sStroke = Instance.new("UIStroke", subLbl)
            sStroke.Thickness = 1
            RainbowStroke(sStroke)
        end
    end

    if iconAsset ~= "" then
        local winIcon = Instance.new("ImageLabel")
        winIcon.Size = UDim2.new(0, 0, 0, 0)
        winIcon.Position = UDim2.new(1, -80, 0, 10)
        winIcon.BackgroundTransparency = 1
        winIcon.Image = iconAsset
        winIcon.ZIndex = 5
        winIcon.Parent = titleBar
        Tween(winIcon, ANIM.Bounce, {Size = UDim2.new(0, 24, 0, 24)})
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "MinimizeBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "-"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 28
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.ZIndex = 20
    closeBtn.Parent = titleBar
    closeBtn.TextTransparency = 1
    Tween(closeBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})

    local destroyBtn = Instance.new("TextButton")
    destroyBtn.Name = "CloseBtn"
    destroyBtn.Size = UDim2.new(0, 30, 0, 30)
    destroyBtn.Position = UDim2.new(1, -70, 0, 8)
    destroyBtn.BackgroundTransparency = 1
    destroyBtn.Text = "X"
    destroyBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    destroyBtn.TextSize = 20
    destroyBtn.Font = Enum.Font.SourceSansBold
    destroyBtn.ZIndex = 20
    destroyBtn.Parent = titleBar
    destroyBtn.TextTransparency = 1
    Tween(destroyBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0})

    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, ANIM.Fast, {TextColor3 = Color3.fromRGB(0, 255, 255), TextSize = 32}) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, ANIM.Fast, {TextColor3 = Color3.new(1, 1, 1), TextSize = 28}) end)
    destroyBtn.MouseEnter:Connect(function() Tween(destroyBtn, ANIM.Fast, {TextColor3 = Color3.fromRGB(255, 50, 50), TextSize = 24}) end)
    destroyBtn.MouseLeave:Connect(function() Tween(destroyBtn, ANIM.Fast, {TextColor3 = Color3.fromRGB(255, 80, 80), TextSize = 20}) end)

    destroyBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
        if type(closeCallback) == "function" then closeCallback() end
    end)

    MakeDraggable(mainFrame, titleBar, Window._connections)

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 150, 1, -55)
    tabContainer.Position = UDim2.new(0, -160, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 8)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Parent = tabContainer

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -180, 1, -60)
    contentFrame.Position = UDim2.new(0, 170, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ClipsDescendants = true
    contentFrame.Parent = mainFrame

    Tween(tabContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.2), {Position = UDim2.new(0, 10, 0, 50)})

    closeBtn.MouseButton1Down:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            savedPos = mainFrame.Position
            savedSize = mainFrame.Size
            closeBtn.Text = "+"
            Tween(tabContainer, ANIM.Slide, {Position = UDim2.new(0, -160, 0, 50)})
            Tween(contentFrame, ANIM.FadeOut, {Position = UDim2.new(0, 300, 0, 50), BackgroundTransparency = 1})
            task.delay(0.15, function()
                tabContainer.Visible = false
                contentFrame.Visible = false
            end)
            Tween(mainFrame, ANIM.Smooth, {
                Size = UDim2.new(0, 700, 0, 45),
                Position = UDim2.new(0.5, -350, 0.5, -22)
            })
        else
            tabContainer.Visible = true
            contentFrame.Visible = true
            closeBtn.Text = "-"
            Tween(mainFrame, ANIM.Smooth, {Size = savedSize, Position = savedPos})
            Tween(tabContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.2), {Position = UDim2.new(0, 10, 0, 50)})
            Tween(contentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.25), {Position = UDim2.new(0, 170, 0, 50)})
        end
    end)

    local notifContainer = Instance.new("Frame")
    notifContainer.Size = UDim2.new(0, 280, 1, -20)
    notifContainer.Position = UDim2.new(1, -300, 0, 10)
    notifContainer.BackgroundTransparency = 1
    notifContainer.ZIndex = 100
    notifContainer.Parent = screenGui

    local notifList = Instance.new("UIListLayout")
    notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifList.Padding = UDim.new(0, 10)
    notifList.Parent = notifContainer

    -- Input Key Listening
    local menuKeyConnection = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == menuKey then
            menuOpen = not menuOpen
            if menuOpen then
                mainFrame.Visible = true
                uiScale.Scale = 0.8
                Tween(uiScale, ANIM.Bounce, {Scale = 1})
                Tween(mainFrame, ANIM.Smooth, {BackgroundTransparency = 0.4})
            else
                Tween(uiScale, ANIM.FadeOut, {Scale = 0.8})
                Tween(mainFrame, ANIM.FadeOut, {BackgroundTransparency = 1})
                task.delay(0.25, function()
                    if not menuOpen then mainFrame.Visible = false end
                end)
            end
        end
    end)
    table.insert(Window._connections, menuKeyConnection)

    -- Background Thread Particle Loop
    Window._backgroundThread = task.spawn(function()
        while task.wait(0.03) do
            if not screenGui or not screenGui.Parent then break end
            if not mainFrame.Visible then continue end
            
            local mLoc = UserInputService:GetMouseLocation()
            if effects.Rain then
                local star = GetFromPool("Star", "Frame")
                star.Size = UDim2.new(0, 1, 0, math.random(30, 80))
                star.Position = UDim2.new(math.random(0, 100)/100, 0, -0.2, 0)
                star.BackgroundColor3 = effectColors.Rain
                star.BackgroundTransparency = 1
                star.ZIndex = 1
                star.Parent = mainFrame
                Tween(star, TweenInfo.new(0.1), {BackgroundTransparency = 0})
                Tween(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0), BackgroundTransparency = 1})
                task.delay(0.6, function() ReturnToPool("Star", star) end)
            end
            if effects.Trail then
                local trail = GetFromPool("Trail", "Frame")
                local corner = trail:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", trail)
                corner.CornerRadius = UDim.new(1, 0)
                trail.Size = UDim2.new(0, 10, 0, 10)
                trail.Position = UDim2.new(0, mLoc.X - mainFrame.AbsolutePosition.X - 5, 0, mLoc.Y - mainFrame.AbsolutePosition.Y - 5)
                trail.BackgroundColor3 = effectColors.Trail
                trail.BackgroundTransparency = 0.3
                trail.ZIndex = 2
                trail.Parent = mainFrame
                Tween(trail, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)})
                task.delay(0.4, function() ReturnToPool("Trail", trail) end)
            end
        end
    end)

    function Window:Notify(titleText, descText, duration)
        duration = duration or 3
        if #activeNotifs >= 4 then
            local oldest = table.remove(activeNotifs, 1)
            if oldest and oldest.Parent then oldest:Destroy() end
        end

        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(1, 0, 0, 0)
        notif.BackgroundColor3 = theme.Shade
        notif.BackgroundTransparency = 1
        notif.Position = UDim2.new(1, 50, 0, 0)
        notif.ZIndex = 105
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = theme.Outline
        stroke.Thickness = 2
        stroke.Transparency = 1

        local tLbl = Instance.new("TextLabel", notif)
        tLbl.Size = UDim2.new(1, -20, 0, 25)
        tLbl.Position = UDim2.new(0, 10, 0, 5)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = titleText
        tLbl.TextColor3 = theme.Main
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Font = theme.Font
        tLbl.TextSize = 18
        tLbl.TextTransparency = 1

        local dLbl = Instance.new("TextLabel", notif)
        dLbl.Size = UDim2.new(1, -20, 0, 25)
        dLbl.Position = UDim2.new(0, 10, 0, 30)
        dLbl.BackgroundTransparency = 1
        dLbl.Text = descText
        dLbl.TextColor3 = Color3.new(1, 1, 1)
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Font = theme.Font
        dLbl.TextSize = 14
        dLbl.TextTransparency = 1

        local progressBar = Instance.new("Frame", notif)
        progressBar.Size = UDim2.new(1, 0, 0, 3)
        progressBar.Position = UDim2.new(0, 0, 1, -3)
        progressBar.BackgroundColor3 = theme.Main
        progressBar.BorderSizePixel = 0
        progressBar.BackgroundTransparency = 1

        notif.Parent = notifContainer
        table.insert(activeNotifs, notif)

        Tween(notif, ANIM.Bounce, {Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 0.1})
        Tween(stroke, ANIM.Smooth, {Transparency = 0})
        Tween(tLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
        Tween(dLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0})
        Tween(progressBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {BackgroundTransparency = 0})
        Tween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)})

        task.delay(duration, function()
            if not notif or not notif.Parent then return end
            for i, v in ipairs(activeNotifs) do
                if v == notif then table.remove(activeNotifs, i) break end
            end
            Tween(notif, ANIM.FadeOut, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
            task.delay(0.3, function() if notif and notif.Parent then notif:Destroy() end end)
        end)
    end

    function Window:AddTab(name)
        tabCount = tabCount + 1
        local tabID = tabCount

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = name .. "_Tab"
        tabBtn.Size = UDim2.new(1, 0, 0, 0)
        tabBtn.BackgroundColor3 = theme.Button
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.Font = theme.Font
        tabBtn.TextSize = 16
        tabBtn.LayoutOrder = tabID
        tabBtn.TextTransparency = 1
        tabBtn.Parent = tabContainer
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

        local btnStroke = Instance.new("UIStroke", tabBtn)
        btnStroke.Color = theme.ButtonOutline
        btnStroke.Thickness = 1

        Tween(tabBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.05 * tabID), {Size = UDim2.new(1, 0, 0, 40), TextTransparency = 0})

        local page = Instance.new("ScrollingFrame")
        page.Name = name .. "_Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = theme.Main
        page.Visible = (tabID == 1)
        page.Parent = contentFrame

        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)

        tabs[tabID] = {Page = page, Btn = tabBtn}

        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(tabs) do
                if v.Page.Visible then
                    v.Page.Visible = false
                end
                Tween(v.Btn, ANIM.Fast, {BackgroundColor3 = theme.Button, Size = UDim2.new(1, 0, 0, 40)})
            end
            page.Visible = true
            Tween(tabBtn, ANIM.Spring, {BackgroundColor3 = Color3.fromRGB(200, 200, 200), Size = UDim2.new(1, 4, 0, 40)})
        end)

        if tabID == 1 then
            tabBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        end

        local Tab = {}

        function Tab:AddLabel(text)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -20, 0, 40)
            l.BackgroundColor3 = theme.Shade
            l.Text = text
            l.TextColor3 = Color3.new(1, 1, 1)
            l.Font = theme.Font
            l.TextSize = 18
            l.Parent = page
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
            return l
        end

        function Tab:AddParagraph(title, content)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 80)
            frame.BackgroundColor3 = theme.Shade
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local t = Instance.new("TextLabel", frame)
            t.Size = UDim2.new(1, -20, 0, 25)
            t.Position = UDim2.new(0, 10, 0, 5)
            t.BackgroundTransparency = 1
            t.Text = title
            t.TextColor3 = theme.Main
            t.Font = theme.Font
            t.TextSize = 18
            t.TextXAlignment = Enum.TextXAlignment.Left

            local c = Instance.new("TextLabel", frame)
            c.Size = UDim2.new(1, -20, 0, 40)
            c.Position = UDim2.new(0, 10, 0, 30)
            c.BackgroundTransparency = 1
            c.Text = content
            c.TextColor3 = Color3.fromRGB(200, 200, 200)
            c.Font = theme.Font
            c.TextSize = 14
            c.TextXAlignment = Enum.TextXAlignment.Left
            c.TextWrapped = true
        end

        function Tab:AddButton(text, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundColor3 = theme.Shade
            frame.BackgroundTransparency = 0.5
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(1, -16, 1, -16)
            btn.Position = UDim2.new(0, 8, 0, 8)
            btn.BackgroundColor3 = theme.Button
            btn.Text = text
            btn.TextColor3 = Color3.new(0, 0, 0)
            btn.Font = theme.Font
            btn.TextSize = 16
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseButton1Click:Connect(function()
                CreateRipple(btn, Vector2.new(btn.AbsoluteSize.X / 2, btn.AbsoluteSize.Y / 2))
                if callback then callback() end
            end)
        end

        function Tab:AddToggle(text, default, callback)
            local saved = loadedConfig.toggles and loadedConfig.toggles[text]
            local enabled = (saved ~= nil) and saved or (default or false)

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 0.5
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -60, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local bg = Instance.new("TextButton", frame)
            bg.Size = UDim2.new(0, 45, 0, 25)
            bg.Position = UDim2.new(1, -55, 0.5, -12)
            bg.BackgroundColor3 = enabled and theme.Button or theme.Shade
            bg.Text = ""
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

            local ball = Instance.new("Frame", bg)
            ball.Size = UDim2.new(0, 17, 0, 17)
            ball.Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
            ball.BackgroundColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

            bg.MouseButton1Click:Connect(function()
                enabled = not enabled
                saveData.toggles[text] = enabled
                DebouncedSave()

                local targetColor = enabled and theme.Button or theme.Shade
                Tween(bg, ANIM.Normal, {BackgroundColor3 = targetColor})
                Tween(ball, ANIM.Spring, {Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)})
                if callback then callback(enabled) end
            end)
        end

        function Tab:AddInput(text, default, callback)
            local saved = loadedConfig.inputs and loadedConfig.inputs[text]
            local inputDefault = saved or default or ""

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 0.5
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel", frame)
            lb.Size = UDim2.new(1, -160, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left

            local box = Instance.new("TextBox", frame)
            box.Size = UDim2.new(0, 120, 0, 30)
            box.Position = UDim2.new(1, -135, 0.5, -15)
            box.BackgroundColor3 = theme.Shade
            box.Text = inputDefault
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = theme.Font
            box.TextSize = 14
            box.ClearTextOnFocus = false
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

            box.FocusLost:Connect(function()
                saveData.inputs[text] = box.Text
                DebouncedSave()
                if callback then callback(box.Text) end
            end)
        end

        return Tab
    end

    -- ==================== SETTINGS TAB ====================
    if hasSettings then
        local settingsTab = Window:AddTab("Settings")
        local settingsData = tabs[tabCount]
        settingsData.Btn.LayoutOrder = 999999

        settingsTab:AddLabel("XeNOX Manager")

        settingsTab:AddToggle("Auto Save Config", autoSave, function(t)
            autoSave = t
            saveData._autoSave = t
            DebouncedSave()
        end)

        settingsTab:AddToggle("Auto Load Config", autoLoad, function(t)
            autoLoad = t
            saveData._autoLoad = t
            DebouncedSave()
        end)

        local activeCard = Instance.new("Frame")
        activeCard.Size = UDim2.new(1, -20, 0, 58)
        activeCard.BackgroundColor3 = theme.Shade
        activeCard.Parent = settingsData.Page
        Instance.new("UICorner", activeCard).CornerRadius = UDim.new(0, 8)

        local activeHeader = Instance.new("TextLabel", activeCard)
        activeHeader.Size = UDim2.new(1, -20, 0, 18)
        activeHeader.Position = UDim2.new(0, 10, 0, 6)
        activeHeader.BackgroundTransparency = 1
        activeHeader.Text = "CURRENT ACTIVE CONFIG"
        activeHeader.TextColor3 = theme.Main
        activeHeader.Font = theme.Font
        activeHeader.TextSize = 13
        activeHeader.TextXAlignment = Enum.TextXAlignment.Left

        local activeNameLbl = Instance.new("TextLabel", activeCard)
        activeNameLbl.Size = UDim2.new(1, -20, 0, 28)
        activeNameLbl.Position = UDim2.new(0, 10, 0, 24)
        activeNameLbl.BackgroundTransparency = 1
        activeNameLbl.Text = activeConfigName
        activeNameLbl.TextColor3 = Color3.new(1, 1, 1)
        activeNameLbl.Font = theme.Font
        activeNameLbl.TextSize = 22
        activeNameLbl.TextXAlignment = Enum.TextXAlignment.Left

        settingsTab:AddLabel("Config Actions")

        local newConfigName = ""
        settingsTab:AddInput("New Config Name", "", function(txt)
            newConfigName = txt:gsub("[^%w_]", "_")
        end)

        settingsTab:AddButton("Create New Config", function()
            if newConfigName == "" then
                Window:Notify("Error", "Enter a config name first!", 2)
                return
            end
            activeConfigName = newConfigName
            SaveConfig(newConfigName)
            activeNameLbl.Text = activeConfigName
            Window:Notify("Config Created", "Created '" .. newConfigName .. "'!", 2)
        end)

        settingsTab:AddButton("Save Current Config", function()
            SaveConfig(activeConfigName)
            Window:Notify("Config Saved", "Saved settings to '" .. activeConfigName .. "'", 2)
        end)
    end

    function Window:Destroy()
        if Window._backgroundThread then
            task.cancel(Window._backgroundThread)
            Window._backgroundThread = nil
        end
        for _, conn in ipairs(Window._connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        if getgenv then
            getgenv().XELIB_ActiveGui = nil
            getgenv().XELIB_ToggleBtn = nil
            getgenv().XELIB_ActiveLoading = nil
        end
        if screenGui then
            screenGui:Destroy()
        end
    end

    return Window
end

return XELIB
