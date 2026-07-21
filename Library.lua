local XELIB = {}
XELIB.__index = XELIB

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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

local function RandomString(len)
    len = len or 10
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, len do
        str = str .. chars:sub(math.random(1, #chars))
    end
    return str
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local connection = nil

    handle.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            connection = UserInputService.InputChanged:Connect(function(changed)
                if dragging and (changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch) then
                    local delta = changed.Position - dragStart
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)
end

local function Tween(obj, info, props)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function TweenAsync(obj, info, props)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    tw.Completed:Wait()
end

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
    local fadeOut = false
    if obj:IsA("Frame") then
        Tween(obj, ANIM.Fast, {BackgroundTransparency = 1})
        fadeOut = true
    end
    if obj:IsA("TextLabel") then
        Tween(obj, ANIM.Fast, {TextTransparency = 1})
        fadeOut = true
    end
    if obj:IsA("ImageLabel") then
        Tween(obj, ANIM.Fast, {ImageTransparency = 1})
        fadeOut = true
    end
    if fadeOut then
        task.delay(0.2, function()
            obj.Visible = false
            obj.Parent = nil
            if not Pool[poolName] then Pool[poolName] = {} end
            table.insert(Pool[poolName], obj)
        end)
    else
        obj.Visible = false
        obj.Parent = nil
        if not Pool[poolName] then Pool[poolName] = {} end
        table.insert(Pool[poolName], obj)
    end
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

local function AddGlow(frame, color)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0, -15, 0, -15)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = color or DEFAULT_THEME
    glow.ImageTransparency = 1
    glow.ZIndex = frame.ZIndex - 1
    glow.Parent = frame
    return glow
end
local function AttachTooltip(target, text, screenGui)
    if not text or text == "" then return end

    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    tooltip.BackgroundTransparency = 1
    tooltip.BorderSizePixel = 0
    tooltip.ZIndex = 10000
    tooltip.Visible = false
    tooltip.Parent = screenGui
    Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 6)

    local tStroke = Instance.new("UIStroke", tooltip)
    tStroke.Color = DEFAULT_THEME
    tStroke.Thickness = 1
    tStroke.Transparency = 1

    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(1, -16, 1, -10)
    tLabel.Position = UDim2.new(0, 8, 0, 5)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = text
    tLabel.TextColor3 = Color3.new(1, 1, 1)
    tLabel.Font = Enum.Font.SourceSansBold
    tLabel.TextSize = 14
    tLabel.TextWrapped = true
    tLabel.TextTransparency = 1
    tLabel.ZIndex = 10001
    tLabel.Parent = tooltip

    local padding = Instance.new("UIPadding", tLabel)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingTop = UDim.new(0, 4)

    local function show()
        if not tooltip or not tooltip.Parent then return end
        local abs = target.AbsolutePosition
        local size = target.AbsoluteSize

        -- Measure text
        tLabel.Size = UDim2.new(0, 200, 0, 0)
        local textHeight = math.max(tLabel.TextBounds.Y + 14, 28)
        tooltip.Size = UDim2.new(0, 220, 0, textHeight)

        -- Position above element, or below if too high
        local yPos = abs.Y - textHeight
        if yPos < 40 then
            yPos = abs.Y + size.Y
        end

        tooltip.Position = UDim2.new(0, math.clamp(abs.X + size.X/2 - 110, 10, screenGui.AbsoluteSize.X - 230), 0, yPos)
        tooltip.Visible = true

        Tween(tooltip, ANIM.Fast, {BackgroundTransparency = 0.1})
        Tween(tStroke, ANIM.Fast, {Transparency = 0})
        Tween(tLabel, ANIM.Fast, {TextTransparency = 0})
    end

    local function hide()
        if not tooltip or not tooltip.Parent then return end
        Tween(tooltip, ANIM.FadeOut, {BackgroundTransparency = 1})
        Tween(tStroke, ANIM.Fast, {Transparency = 1})
        Tween(tLabel, ANIM.Fast, {TextTransparency = 1})
        task.delay(0.2, function()
            if tooltip and tooltip.Parent then tooltip.Visible = false end
        end)
    end

    target.MouseEnter:Connect(show)
    target.MouseLeave:Connect(hide)
end


function XELIB:MakeWindow(config)
    config = config or {}
    -- Config aliases for compatibility
    if config.LoadIntro ~= nil then config.Intro = config.LoadIntro end
    if config.Toggle ~= nil then config._forceToggle = config.Toggle end
    if config.CloseCallback == true then config.CloseCallback = nil end
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
    local winName = config.Name or "XeNOX Library"
    local subTitle = config.SubTitle or ""
    local hasSettings = config.Setting ~= false
    local hasIntro = config.Intro == true
    local Loading_Text = config.IntroText or "LOADING"
    local Loading_Icon = config.IntroIcon or ""
    local Loading_Speed = config.IntroSpeed or 1
    local isPremium = config.IsPremium == true
    local iconAsset = config.Icon or ""
    local rainbowMain = config.RainbowMainFrame == true
    local rainbowTitle = config.RainbowTitle == true
    local rainbowSub = config.RainbowSubTitle == true
    local toggleIcon = config.ToggleIcon or ""
    local closeCallback = config.CloseCallback
    local effects = {
        Rain = false,
        Trail = false,
        Blob = false,
        Matrix = false,
        Hex = false,
        Glitch = false
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

    local saveId = config.SaveId or config.Name or "XeNOX_Default"
    local autoSave = config.AutoSave ~= false
    local autoLoad = config.AutoLoad == true
    local configFolder = "XeNOX_Configs/" .. saveId:gsub("[^%w_]", "_")
    local defaultConfigPath = configFolder .. "/default.json"
    local activeConfigName = "default"
    local autoSaveTarget = "default"
    local saveData = {
        toggles = {},
        sliders = {},
        dropdowns = {},
        inputs = {},
        keybinds = {},
        colors = {},
        theme = {},
        effects = {},
        effectColors = {},
        menuKey = nil,
        _autoSave = nil,
        _autoLoad = nil,
        _activeConfigName = nil,
        _autoSaveTarget = nil,
        custom = {}
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
        local success, files = pcall(function()
            return listfiles(configFolder)
        end)
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
        local success, json = pcall(function()
            return HttpService:JSONEncode(saveData)
        end)
        if success then
            pcall(function() writefile(path, json) end)
        end
    end

    local function LoadConfig(name)
        name = name or activeConfigName
        if not isfile or not readfile then return nil end
        local path = GetConfigPath(name)
        if not isfile(path) then return nil end
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if success and type(data) == "table" then
            return data
        end
        return nil
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

    if loadedConfig.effects then
        for k, v in pairs(loadedConfig.effects) do
            if effects[k] ~= nil then effects[k] = v end
        end
    end
    if loadedConfig.effectColors then
        for k, v in pairs(loadedConfig.effectColors) do
            if effectColors[k] and type(v) == "table" and v.R and v.G and v.B then
                effectColors[k] = Color3.fromRGB(v.R, v.G, v.B)
            end
        end
    end
    if loadedConfig._autoSave ~= nil then
        autoSave = loadedConfig._autoSave
    end
    if loadedConfig._autoLoad ~= nil then
        autoLoad = loadedConfig._autoLoad
    end
    if loadedConfig.custom and type(loadedConfig.custom) == "table" then
        saveData.custom = loadedConfig.custom
    end
    if loadedConfig._activeConfigName and type(loadedConfig._activeConfigName) == "string" then
        activeConfigName = loadedConfig._activeConfigName
    end
    if loadedConfig._autoSaveTarget and type(loadedConfig._autoSaveTarget) == "string" then
        autoSaveTarget = loadedConfig._autoSaveTarget
    end
    if loadedConfig.theme then
        for k, v in pairs(loadedConfig.theme) do
            if k == "Font" and type(v) == "string" then
                for _, f in ipairs(Enum.Font:GetEnumItems()) do
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
    Window._debounceSave = nil

    local uiRegistry = {
        toggles = {},
        sliders = {},
        dropdowns = {},
        inputs = {},
        keybinds = {},
        colors = {},
    }
    Window._uiRegistry = uiRegistry

    local function DebouncedSave()
        if not autoSave then return end
        saveData._activeConfigName = activeConfigName
        saveData._autoSaveTarget = autoSaveTarget
        if Window._debounceSave then
            task.cancel(Window._debounceSave)
        end
        Window._debounceSave = task.delay(0.5, function()
            SaveConfig(autoSaveTarget)
            Window._debounceSave = nil
        end)
    end

    local function ApplyConfig(data)
        if type(data) ~= "table" then return end
        if data.toggles then
            for text, value in pairs(data.toggles) do
                local entry = uiRegistry.toggles[text]
                if entry and entry.bg and entry.bg.Parent then
                    entry.enabled = value
                    local targetColor = value and theme.Button or theme.Shade
                    Tween(entry.bg, ANIM.Normal, {BackgroundColor3 = targetColor})
                    Tween(entry.ball, ANIM.Spring, {Position = value and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)})
                    if entry.ballGlow then Tween(entry.ballGlow, ANIM.Normal, {Color = targetColor}) end
                    if entry.callback then pcall(function() entry.callback(value) end) end
                end
            end
        end
        if data.sliders then
            for text, value in pairs(data.sliders) do
                local entry = uiRegistry.sliders[text]
                if entry and entry.track and entry.track.Parent and entry.min and entry.max then
                    entry.value = value
                    local pos = (value - entry.min) / (entry.max - entry.min)
                    entry.lb.Text = text .. ": " .. tostring(value)
                    Tween(entry.fill, ANIM.Normal, {Size = UDim2.new(pos, 0, 1, 0)})
                    Tween(entry.knob, ANIM.Normal, {Position = UDim2.new(pos, -7, 0.5, -7)})
                    if entry.callback then pcall(function() entry.callback(value) end) end
                end
            end
        end
        if data.dropdowns then
            for text, value in pairs(data.dropdowns) do
                local entry = uiRegistry.dropdowns[text]
                if entry and entry.btn and entry.btn.Parent then
                    entry.selected = value
                    entry.btn.Text = value
                    if entry.callback then pcall(function() entry.callback(value) end) end
                end
            end
        end
        if data.inputs then
            for text, value in pairs(data.inputs) do
                local entry = uiRegistry.inputs[text]
                if entry and entry.box and entry.box.Parent then
                    entry.box.Text = value
                    if entry.callback then pcall(function() entry.callback(value) end) end
                end
            end
        end
        if data.keybinds then
            for text, keyName in pairs(data.keybinds) do
                local entry = uiRegistry.keybinds[text]
                if entry and entry.btn and entry.btn.Parent then
                    local ok, key = pcall(function() return Enum.KeyCode[keyName] end)
                    if ok and key then
                        entry.currentKey = key
                        entry.btn.Text = key.Name
                        if entry.callback then pcall(function() entry.callback(key) end) end
                    end
                end
            end
        end
        if data.colors then
            for text, cData in pairs(data.colors) do
                local entry = uiRegistry.colors[text]
                if entry and entry.preview and entry.preview.Parent and type(cData) == "table" and cData.R then
                    local c = Color3.fromRGB(cData.R, cData.G, cData.B)
                    entry.preview.BackgroundColor3 = c
                    entry.curH, entry.curS, entry.curV = c:ToHSV()
                    if entry.callback then pcall(function() entry.callback(c) end) end
                end
            end
        end
        if data.effects then
            for k, v in pairs(data.effects) do if effects[k] ~= nil then effects[k] = v end end
        end
        if data.effectColors then
            for k, v in pairs(data.effectColors) do
                if effectColors[k] and type(v) == "table" and v.R then
                    effectColors[k] = Color3.fromRGB(v.R, v.G, v.B)
                end
            end
        end
        if data.theme then
            for k, v in pairs(data.theme) do
                if k == "Font" and type(v) == "string" then
                    for _, f in ipairs({Enum.Font.SourceSansBold, Enum.Font.Roboto, Enum.Font.GothamBold, Enum.Font.Arcade, Enum.Font.Code, Enum.Font.SciFi}) do
                        if f.Name == v then
                            theme.Font = f
                            for _, lbl in ipairs(uiCache.Text) do if lbl and lbl.Parent then lbl.Font = f end end
                            break
                        end
                    end
                elseif theme[k] and type(v) == "table" and v.R then
                    theme[k] = Color3.fromRGB(v.R, v.G, v.B)
                end
            end
            mainFrame.BackgroundColor3 = theme.Main
            titleLbl.TextColor3 = theme.Main
            mainStroke.Color = theme.Outline
            for _, v in ipairs(uiCache.Shade) do if v and v.Parent then v.BackgroundColor3 = theme.Shade end end
            for _, v in ipairs(uiCache.Button) do if v and v.Parent then v.BackgroundColor3 = theme.Button end end
            for _, v in ipairs(uiCache.ButtonOutline) do if v and v.Parent then v.Color = theme.ButtonOutline end end
        end
        if data.menuKey and type(data.menuKey) == "string" then
            local ok, key = pcall(function() return Enum.KeyCode[data.menuKey] end)
            if ok and key then menuKey = key end
        end
        if data._autoSave ~= nil then autoSave = data._autoSave end
        if data._activeConfigName and type(data._activeConfigName) == "string" then activeConfigName = data._activeConfigName end
        if data._autoSaveTarget and type(data._autoSaveTarget) == "string" then autoSaveTarget = data._autoSaveTarget end
        if data.custom and type(data.custom) == "table" then
            saveData.custom = data.custom
            for _, cb in ipairs(Window._configCallbacks or {}) do
                pcall(function() cb(data.custom) end)
            end
        end
    end
    Window._applyConfig = ApplyConfig

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

    if hasIntro then
        local Loading_Screen = Instance.new("ScreenGui")
        Loading_Screen.Name = RandomString(12)
        Loading_Screen.ResetOnSpawn = false
        Loading_Screen.IgnoreGuiInset = true
        if gethui then
            Loading_Screen.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(Loading_Screen)
            Loading_Screen.Parent = PlayerGui
        else
            Loading_Screen.Parent = CoreGui
        end
        if getgenv then getgenv().XELIB_ActiveLoading = Loading_Screen end

        local Loading_Frame = Instance.new("Frame")
        Loading_Frame.Size = UDim2.new(1, 0, 1, 0)
        Loading_Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        Loading_Frame.BackgroundTransparency = 1
        Loading_Frame.Parent = Loading_Screen
        Instance.new("UICorner", Loading_Frame).CornerRadius = UDim.new(0, 0)

        local Loading_Stroke = Instance.new("UIStroke", Loading_Frame)
        Loading_Stroke.Thickness = 2
        Loading_Stroke.Color = theme.Main
        Loading_Stroke.Transparency = 1
        if rainbowMain then
            RainbowStroke(Loading_Stroke)
        end

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

    if rainbowMain then
        RainbowStroke(mainStroke)
    end

    Tween(mainFrame, ANIM.Smooth, {BackgroundTransparency = 0.4})
    Tween(mainStroke, ANIM.Smooth, {Thickness = 2})
    Tween(uiScale, ANIM.Bounce, {Scale = 1})

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
    titleLbl.Parent = titleBar
    titleLbl.TextTransparency = 1
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
        subLbl.Parent = titleBar
        subLbl.TextTransparency = 1
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
    closeBtn.Active = true
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
    destroyBtn.Active = true
    destroyBtn.Parent = titleBar
    destroyBtn.TextTransparency = 1
    Tween(destroyBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0})

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, ANIM.Fast, {TextColor3 = Color3.fromRGB(0, 255, 255), TextSize = 32})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, ANIM.Fast, {TextColor3 = Color3.new(1, 1, 1), TextSize = 28})
    end)
    destroyBtn.MouseEnter:Connect(function()
        Tween(destroyBtn, ANIM.Fast, {TextColor3 = Color3.fromRGB(255, 50, 50), TextSize = 24})
    end)
    destroyBtn.MouseLeave:Connect(function()
        Tween(destroyBtn, ANIM.Fast, {TextColor3 = Color3.fromRGB(255, 80, 80), TextSize = 20})
    end)
    destroyBtn.MouseButton1Click:Connect(function()
        Tween(mainFrame, ANIM.Smooth, {BackgroundTransparency = 1})
        Tween(uiScale, ANIM.FadeOut, {Scale = 0.8})
        Tween(mainStroke, ANIM.FadeOut, {Transparency = 1})
        task.delay(0.3, function()
            if type(closeCallback) == "function" then
                closeCallback()
            end
            if getgenv then
                getgenv().XELIB_ActiveGui = nil
                getgenv().XELIB_ToggleBtn = nil
            end
            screenGui:Destroy()
        end)
    end)

    MakeDraggable(mainFrame, titleBar)

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
    contentFrame.Parent = mainFrame
    contentFrame.ClipsDescendants = true

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
            Tween(mainFrame, ANIM.Smooth, {
                Size = savedSize,
                Position = savedPos
            })
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

    if UserInputService.TouchEnabled or UserInputService.GamepadEnabled or config._forceToggle then
        local toggleBtn = Instance.new("ImageButton")
        toggleBtn.Size = UDim2.new(0, 0, 0, 0)
        toggleBtn.Position = UDim2.new(0, 40, 0, 40)
        toggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
        toggleBtn.BackgroundColor3 = theme.Shade
        toggleBtn.Image = toggleIcon
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.ZIndex = 50
        toggleBtn.Parent = screenGui
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

        local tStroke = Instance.new("UIStroke", toggleBtn)
        tStroke.Color = theme.Outline
        tStroke.Thickness = 2
        Tween(toggleBtn, ANIM.Spring, {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 20, 0, 20)})

        toggleBtn.MouseButton1Click:Connect(function()
            menuOpen = not menuOpen
            if menuOpen then
                mainFrame.Visible = true
                uiScale.Scale = 0.8
                Tween(uiScale, ANIM.Bounce, {Scale = 1})
                Tween(mainFrame, ANIM.Smooth, {BackgroundTransparency = 0.4})
                Tween(toggleBtn, ANIM.Fast, {Rotation = 0})
            else
                Tween(uiScale, ANIM.FadeOut, {Scale = 0.8})
                Tween(mainFrame, ANIM.FadeOut, {BackgroundTransparency = 1})
                Tween(toggleBtn, ANIM.Fast, {Rotation = 180})
                task.delay(0.25, function()
                    if not menuOpen then mainFrame.Visible = false end
                end)
            end
        end)
        toggleBtn.MouseEnter:Connect(function()
            Tween(toggleBtn, ANIM.Fast, {Size = UDim2.new(0, 46, 0, 46)})
        end)
        toggleBtn.MouseLeave:Connect(function()
            Tween(toggleBtn, ANIM.Fast, {Size = UDim2.new(0, 40, 0, 40)})
        end)
        if getgenv then getgenv().XELIB_ToggleBtn = toggleBtn end
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
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

    task.spawn(function()
        while task.wait(0.03) do
            if not screenGui.Parent then break end
            if not mainFrame.Visible then continue end
            local mLoc = UserInputService:GetMouseLocation()
            if effects.Rain then
                local star = GetFromPool("Star", "Frame")
                star.Size = UDim2.new(0, 1, 0, math.random(30, 80))
                star.Position = UDim2.new(math.random(0, 100)/100, 0, -0.2, 0)
                star.BackgroundColor3 = effectColors.Rain
                star.BackgroundTransparency = 0
                star.ZIndex = 1
                star.Parent = mainFrame
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
            if effects.Matrix and math.random(1, 5) == 1 then
                local char = GetFromPool("Matrix", "TextLabel")
                char.Size = UDim2.new(0, 20, 0, 20)
                char.Position = UDim2.new(math.random(0, 100)/100, 0, -0.1, 0)
                char.BackgroundTransparency = 1
                char.Text = string.char(math.random(33, 126))
                char.TextColor3 = effectColors.Matrix
                char.Font = Enum.Font.Code
                char.TextSize = 15
                char.TextTransparency = 0
                char.ZIndex = 1
                char.Parent = mainFrame
                Tween(char, TweenInfo.new(math.random(1, 3), Enum.EasingStyle.Linear), {Position = UDim2.new(char.Position.X.Scale, 0, 1.1, 0), TextTransparency = 1})
                task.delay(3, function() ReturnToPool("Matrix", char) end)
            end
            if effects.Hex and math.random(1, 15) == 1 then
                local hex = GetFromPool("Hex", "ImageLabel")
                hex.Size = UDim2.new(0, 0, 0, 0)
                hex.Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0)
                hex.Image = "rbxassetid://6073628820"
                hex.ImageColor3 = effectColors.Hex
                hex.BackgroundTransparency = 1
                hex.ImageTransparency = 0.8
                hex.Rotation = 0
                hex.ZIndex = 1
                hex.Parent = mainFrame
                local size = math.random(50, 150)
                Tween(hex, TweenInfo.new(2), {Size = UDim2.new(0, size, 0, size), ImageTransparency = 1, Rotation = 180})
                task.delay(2, function() ReturnToPool("Hex", hex) end)
            end
            if effects.Glitch and math.random(1, 10) == 1 then
                local g = GetFromPool("Glitch", "Frame")
                g.Size = UDim2.new(0, math.random(20, 100), 0, 2)
                g.Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0)
                g.BackgroundColor3 = effectColors.Glitch
                g.BackgroundTransparency = 0.5
                g.Parent = mainFrame
                task.spawn(function()
                    for i = 1, 3 do
                        if not g or not g.Parent then break end
                        g.BackgroundTransparency = i % 2 == 0 and 0.5 or 1
                        task.wait(0.03)
                    end
                end)
                task.delay(0.1, function() ReturnToPool("Glitch", g) end)
            end
            if effects.Blob then
                local blob = GetFromPool("Blob", "ImageLabel")
                blob.Size = UDim2.new(math.random(2, 5)/10, 0, math.random(2, 5)/10, 0)
                blob.Position = UDim2.new(math.random(-1, 9)/10, 0, math.random(-1, 9)/10, 0)
                blob.Image = "rbxassetid://232918622"
                blob.ImageColor3 = effectColors.Blob
                blob.BackgroundTransparency = 1
                blob.ImageTransparency = 0.93
                blob.ZIndex = 1
                blob.Parent = mainFrame
                task.spawn(function()
                    local start = tick()
                    while tick() - start < 3 do
                        if not blob or not blob.Parent or not effects.Blob then break end
                        local currentMouse = UserInputService:GetMouseLocation()
                        local diff = (blob.AbsolutePosition + blob.AbsoluteSize/2) - currentMouse
                        if diff.Magnitude < 250 then
                            local push = diff.Unit * (1 - (diff.Magnitude / 250)) * 0.18
                            blob.Position = blob.Position:Lerp(UDim2.new(blob.Position.X.Scale + push.X, 0, blob.Position.Y.Scale + push.Y, 0), 0.45)
                        end
                        task.wait()
                    end
                    ReturnToPool("Blob", blob)
                end)
            end
        end
    end)

    local function StyleButton(btn)
        btn.BackgroundColor3 = theme.Button
        btn.TextColor3 = Color3.new(0, 0, 0)
        btn.Font = theme.Font
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke")
        stroke.Color = theme.ButtonOutline
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = btn
        table.insert(uiCache.ButtonOutline, stroke)
        table.insert(uiCache.Button, btn)
        table.insert(uiCache.Text, btn)
        btn.MouseEnter:Connect(function()
            Tween(btn, ANIM.Fast, {BackgroundTransparency = 0.2, Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset + 4, btn.Size.Y.Scale, btn.Size.Y.Offset + 2)})
            Tween(stroke, ANIM.Fast, {Thickness = 2})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, ANIM.Fast, {BackgroundTransparency = 0, Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 4, btn.Size.Y.Scale, btn.Size.Y.Offset - 2)})
            Tween(stroke, ANIM.Fast, {Thickness = 1})
        end)
    end

    local function ShadeFrame(frame)
        frame.BackgroundColor3 = theme.Shade
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, frame)
    end

    function Window:Notify(titleText, descText, duration)
        duration = duration or 3
        if #activeNotifs >= 4 then
            local oldest = table.remove(activeNotifs, 1)
            if oldest and oldest.Parent then
                Tween(oldest, ANIM.FadeOut, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1})
                for _, child in ipairs(oldest:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        Tween(child, ANIM.Fast, {TextTransparency = 1})
                    elseif child:IsA("UIStroke") then
                        Tween(child, ANIM.Fast, {Transparency = 1})
                    end
                end
                task.delay(0.3, function()
                    if oldest and oldest.Parent then oldest:Destroy() end
                end)
            end
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
        tLbl.ZIndex = 106

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
        dLbl.ZIndex = 106

        local progressBar = Instance.new("Frame")
        progressBar.Size = UDim2.new(1, 0, 0, 3)
        progressBar.Position = UDim2.new(0, 0, 1, -3)
        progressBar.BackgroundColor3 = theme.Main
        progressBar.BorderSizePixel = 0
        progressBar.ZIndex = 107
        progressBar.Parent = notif
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
                if v == notif then
                    table.remove(activeNotifs, i)
                    break
                end
            end
            Tween(notif, ANIM.FadeOut, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
            Tween(stroke, ANIM.Fast, {Transparency = 1})
            Tween(tLbl, ANIM.Fast, {TextTransparency = 1})
            Tween(dLbl, ANIM.Fast, {TextTransparency = 1})
            Tween(progressBar, ANIM.Fast, {BackgroundTransparency = 1})
            task.delay(0.5, function()
                if notif and notif.Parent then notif:Destroy() end
            end)
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
        tabBtn.Parent = tabContainer
        tabBtn.TextTransparency = 1
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Button, tabBtn)
        table.insert(uiCache.Text, tabBtn)

        local btnStroke = Instance.new("UIStroke", tabBtn)
        btnStroke.Color = theme.ButtonOutline
        btnStroke.Thickness = 1
        table.insert(uiCache.ButtonOutline, btnStroke)

        Tween(tabBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.05 * tabID), {Size = UDim2.new(1, 0, 0, 40), TextTransparency = 0})

        tabBtn.MouseEnter:Connect(function()
            if tabs[tabID] and tabs[tabID].Page and not tabs[tabID].Page.Visible then
                Tween(tabBtn, ANIM.Fast, {BackgroundTransparency = 0.15, Size = UDim2.new(1, 4, 0, 42)})
                Tween(btnStroke, ANIM.Fast, {Thickness = 2})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if tabs[tabID] and tabs[tabID].Page and not tabs[tabID].Page.Visible then
                Tween(tabBtn, ANIM.Fast, {BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 40)})
                Tween(btnStroke, ANIM.Fast, {Thickness = 1})
            end
        end)

        local page = Instance.new("ScrollingFrame")
        page.Name = name .. "_Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = theme.Main
        page.Visible = (tabID == 1)
        page.Parent = contentFrame
        page.CanvasSize = UDim2.new(0, 0, 0, 2000)
        page.ScrollBarImageTransparency = 0

        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)

        -- Search bar
        local searchFrame = Instance.new("Frame")
        searchFrame.Size = UDim2.new(1, -20, 0, 0)
        searchFrame.BackgroundColor3 = theme.Shade
        searchFrame.BackgroundTransparency = 0.5
        searchFrame.LayoutOrder = -9999
        searchFrame.Parent = page
        Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, searchFrame)

        local searchIcon = Instance.new("TextLabel")
        searchIcon.Size = UDim2.new(0, 30, 0, 30)
        searchIcon.Position = UDim2.new(0, 8, 0.5, -15)
        searchIcon.BackgroundTransparency = 1
        searchIcon.Text = "🔍"
        searchIcon.TextSize = 18
        searchIcon.Font = Enum.Font.SourceSansBold
        searchIcon.TextColor3 = Color3.new(1, 1, 1)
        searchIcon.Parent = searchFrame

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -50, 0, 30)
        searchBox.Position = UDim2.new(0, 40, 0.5, -15)
        searchBox.BackgroundTransparency = 1
        searchBox.Text = ""
        searchBox.PlaceholderText = "Search..."
        searchBox.TextColor3 = Color3.new(1, 1, 1)
        searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        searchBox.Font = theme.Font
        searchBox.TextSize = 16
        searchBox.ClearTextOnFocus = false
        searchBox.Parent = searchFrame

        Tween(searchFrame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 44)})

        local tabElements = {}

        tabs[tabID] = {Page = page, Btn = tabBtn}

        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(tabs) do
                if v.Page.Visible then
                    Tween(v.Page, ANIM.Fast, {Position = UDim2.new(-0.1, 0, 0, 0), CanvasPosition = Vector2.new(0, 0)})
                    Tween(v.Page, TweenInfo.new(0.15), {BackgroundTransparency = 1})
                    task.delay(0.15, function()
                        v.Page.Visible = false
                        v.Page.Position = UDim2.new(0, 0, 0, 0)
                    end)
                end
                Tween(v.Btn, ANIM.Fast, {BackgroundColor3 = theme.Button, Size = UDim2.new(1, 0, 0, 40)})
            end
            page.Visible = true
            page.Position = UDim2.new(0.1, 0, 0, 0)
            Tween(page, ANIM.Smooth, {Position = UDim2.new(0, 0, 0, 0)})
            Tween(tabBtn, ANIM.Spring, {BackgroundColor3 = Color3.fromRGB(200, 200, 200), Size = UDim2.new(1, 4, 0, 40)})
        end)

        if tabID == 1 then
            tabBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        end

        local Tab = {}

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = searchBox.Text:lower()
            if query == "" then
                for _, entry in ipairs(tabElements) do
                    if entry.frame and entry.frame.Parent then
                        entry.frame.Visible = true
                    end
                end
            else
                for _, entry in ipairs(tabElements) do
                    if entry.frame and entry.frame.Parent then
                        local match = entry.searchText:lower():find(query, 1, true) ~= nil
                        entry.frame.Visible = match
                    end
                end
            end
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)

        function Tab:AddLabel(text)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -20, 0, 0)
            l.BackgroundColor3 = theme.Shade
            l.Text = text
            l.TextColor3 = Color3.new(1, 1, 1)
            l.Font = theme.Font
            l.TextSize = 18
            l.Parent = page
            l.TextTransparency = 1
            l.BackgroundTransparency = 1
            Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
            table.insert(uiCache.Shade, l)
            table.insert(uiCache.Text, l)
            Tween(l, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 40), TextTransparency = 0, BackgroundTransparency = 0})
            table.insert(tabElements, {frame = l, searchText = text})
            return l
        end

        function Tab:AddParagraph(title, content)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = theme.Shade
            frame.BackgroundTransparency = 1
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            table.insert(uiCache.Shade, frame)

            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -20, 0, 25)
            t.Position = UDim2.new(0, 10, 0, 5)
            t.BackgroundTransparency = 1
            t.Text = title
            t.TextColor3 = theme.Main
            t.Font = theme.Font
            t.TextSize = 18
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.TextTransparency = 1
            t.Parent = frame
            table.insert(uiCache.Text, t)

            local c = Instance.new("TextLabel")
            c.Size = UDim2.new(1, -20, 0, 40)
            c.Position = UDim2.new(0, 10, 0, 30)
            c.BackgroundTransparency = 1
            c.Text = content
            c.TextColor3 = Color3.fromRGB(200, 200, 200)
            c.Font = theme.Font
            c.TextSize = 14
            c.TextXAlignment = Enum.TextXAlignment.Left
            c.TextWrapped = true
            c.TextTransparency = 1
            c.Parent = frame
            table.insert(uiCache.Text, c)

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 80), BackgroundTransparency = 0})
            Tween(t, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
            Tween(c, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0})
            table.insert(tabElements, {frame = frame, searchText = title .. " " .. content})
        end

        function Tab:AddButton(text, callback, description)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = theme.Shade
            frame.BackgroundTransparency = 0.5
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            table.insert(uiCache.Shade, frame)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -16, 1, -16)
            btn.Position = UDim2.new(0, 8, 0, 8)
            btn.BackgroundColor3 = theme.Button
            btn.Text = text
            btn.TextColor3 = Color3.new(0, 0, 0)
            btn.Font = theme.Font
            btn.TextSize = 16
            btn.Parent = frame
            btn.AutoButtonColor = false
            StyleButton(btn)
            AttachTooltip(frame, description, screenGui)

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 50)})
            table.insert(tabElements, {frame = frame, searchText = text})

            btn.MouseButton1Down:Connect(function()
                Tween(btn, ANIM.Fast, {BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10)})
                CreateRipple(btn, Vector2.new(btn.AbsoluteSize.X / 2, btn.AbsoluteSize.Y / 2))
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, ANIM.Spring, {BackgroundColor3 = theme.Button, Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8)})
            end)
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        function Tab:AddToggle(text, default, callback, description, stateLabels)
            local saved = loadedConfig.toggles and loadedConfig.toggles[text]
            local enabled
            if saved ~= nil then
                enabled = saved
            else
                enabled = default or false
            end
            saveData.toggles[text] = enabled

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -60, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.TextTransparency = 1
            lb.Parent = frame
            table.insert(uiCache.Text, lb)

            local bg = Instance.new("TextButton")
            bg.Name = "ToggleBG"
            bg.Size = UDim2.new(0, 45, 0, 25)
            bg.Position = UDim2.new(1, -55, 0.5, -12)
            bg.BackgroundColor3 = enabled and theme.Button or theme.Shade
            bg.Text = ""
            bg.AutoButtonColor = false
            bg.Parent = frame
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

            local ball = Instance.new("Frame")
            ball.Size = UDim2.new(0, 17, 0, 17)
            ball.Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
            ball.BackgroundColor3 = Color3.new(1, 1, 1)
            ball.Parent = bg
            Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

            local ballGlow = Instance.new("UIStroke", ball)
            ballGlow.Color = enabled and theme.Button or theme.Shade
            ballGlow.Thickness = 2
            ballGlow.Transparency = 0.5

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 0.5})
            Tween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
            AttachTooltip(frame, description, screenGui)
            table.insert(tabElements, {frame = frame, searchText = text})

            uiRegistry.toggles[text] = {enabled = enabled, bg = bg, ball = ball, ballGlow = ballGlow, callback = callback, lb = lb}

            bg.MouseButton1Click:Connect(function()
                enabled = not enabled
                saveData.toggles[text] = enabled
                DebouncedSave()
                local targetColor = enabled and theme.Button or theme.Shade
                Tween(bg, ANIM.Normal, {BackgroundColor3 = targetColor})
                Tween(ball, ANIM.Spring, {Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)})
                Tween(ballGlow, ANIM.Normal, {Color = targetColor})
                Tween(ball, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 20, 0, 20)})
                task.delay(0.15, function()
                    Tween(ball, ANIM.Spring, {Size = UDim2.new(0, 17, 0, 17)})
                end)
                if stateLabels and type(stateLabels) == "table" then
                    lb.Text = enabled and (stateLabels.On or text) or (stateLabels.Off or text)
                elseif stateLabels and type(stateLabels) == "string" then
                    lb.Text = enabled and (stateLabels .. " [ON]") or (stateLabels .. " [OFF]")
                end
                if callback then callback(enabled) end
            end)
        end

        function Tab:AddSlider(text, min, max, default, callback, description)
            local saved = loadedConfig.sliders and loadedConfig.sliders[text]
            local value = saved or default or min
            saveData.sliders[text] = value

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -20, 0, 25)
            lb.Position = UDim2.new(0, 15, 0, 5)
            lb.BackgroundTransparency = 1
            lb.Text = text .. ": " .. tostring(value)
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 16
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.TextTransparency = 1
            lb.Parent = frame
            table.insert(uiCache.Text, lb)

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -30, 0, 8)
            track.Position = UDim2.new(0, 15, 0, 35)
            track.BackgroundColor3 = theme.Shade
            track.Parent = frame
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = theme.Button
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.Parent = track
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            local knobStroke = Instance.new("UIStroke", knob)
            knobStroke.Color = theme.Button
            knobStroke.Thickness = 2

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 60), BackgroundTransparency = 0.5})
            Tween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
            AttachTooltip(frame, description, screenGui)
            table.insert(tabElements, {frame = frame, searchText = text})

            uiRegistry.sliders[text] = {value = value, lb = lb, fill = fill, knob = knob, track = track, min = min, max = max, callback = callback}

            local dragging = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Tween(knob, ANIM.Fast, {Size = UDim2.new(0, 18, 0, 18)})
                    Tween(knobStroke, ANIM.Fast, {Thickness = 3})
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                    dragging = false
                    Tween(knob, ANIM.Spring, {Size = UDim2.new(0, 14, 0, 14)})
                    Tween(knobStroke, ANIM.Fast, {Thickness = 2})
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (pos * (max - min)))
                    saveData.sliders[text] = value
                    DebouncedSave()
                    uiRegistry.sliders[text].value = value
                    lb.Text = text .. ": " .. tostring(value)
                    Tween(fill, ANIM.Fast, {Size = UDim2.new(pos, 0, 1, 0)})
                    Tween(knob, ANIM.Fast, {Position = UDim2.new(pos, -7, 0.5, -7)})
                    if callback then callback(value) end
                end
            end)
        end

        function Tab:AddDropdown(text, options, callback, description)
            local saved = loadedConfig.dropdowns and loadedConfig.dropdowns[text]
            local selected = saved or options[1] or ""
            saveData.dropdowns[text] = selected
            local open = false

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = page
            frame.ClipsDescendants = false
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -160, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.TextTransparency = 1
            lb.Parent = frame
            table.insert(uiCache.Text, lb)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 120, 0, 30)
            btn.Position = UDim2.new(1, -135, 0.5, -15)
            btn.BackgroundColor3 = theme.Shade
            btn.Text = selected
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = theme.Font
            btn.TextSize = 14
            btn.AutoButtonColor = false
            btn.Parent = frame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            table.insert(uiCache.Shade, btn)
            table.insert(uiCache.Text, btn)

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 0, 20)
            arrow.Position = UDim2.new(1, -22, 0, 5)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Color3.new(1, 1, 1)
            arrow.TextSize = 12
            arrow.Font = Enum.Font.SourceSansBold
            arrow.Parent = btn

            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(0, 120, 0, 0)
            dropFrame.Position = UDim2.new(1, -135, 0.5, 15)
            dropFrame.BackgroundColor3 = theme.Shade
            dropFrame.BackgroundTransparency = 1
            dropFrame.ClipsDescendants = true
            dropFrame.ZIndex = 10
            dropFrame.Parent = frame
            Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)

            local dropList = Instance.new("UIListLayout", dropFrame)
            dropList.Padding = UDim.new(0, 2)

            local optionButtons = {}
            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundTransparency = 1
                optBtn.Text = opt
                optBtn.TextColor3 = Color3.new(1, 1, 1)
                optBtn.Font = theme.Font
                optBtn.TextSize = 14
                optBtn.TextTransparency = 1
                optBtn.ZIndex = 11
                optBtn.Parent = dropFrame
                optBtn.LayoutOrder = i
                table.insert(optionButtons, optBtn)

                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, ANIM.Fast, {BackgroundTransparency = 0.8, BackgroundColor3 = theme.Button, TextColor3 = Color3.new(0, 0, 0)})
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, ANIM.Fast, {BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1)})
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    saveData.dropdowns[text] = selected
                    DebouncedSave()
                    btn.Text = selected
                    open = false
                    Tween(dropFrame, ANIM.Normal, {Size = UDim2.new(0, 120, 0, 0), BackgroundTransparency = 1})
                    Tween(arrow, ANIM.Fast, {Rotation = 0})
                    for _, ob in ipairs(optionButtons) do
                        Tween(ob, ANIM.Fast, {TextTransparency = 1})
                    end
                    if callback then callback(selected) end
                end)
            end

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 0.5})
            Tween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
            AttachTooltip(frame, description, screenGui)
            table.insert(tabElements, {frame = frame, searchText = text})

            uiRegistry.dropdowns[text] = {selected = selected, btn = btn, callback = callback}

            btn.MouseButton1Click:Connect(function()
                open = not open
                local h = math.min(#options * 30, 150)
                if open then
                    Tween(dropFrame, ANIM.Normal, {Size = UDim2.new(0, 120, 0, h), BackgroundTransparency = 0})
                    Tween(arrow, ANIM.Spring, {Rotation = 180})
                    for _, ob in ipairs(optionButtons) do
                        ob.TextTransparency = 0
                        Tween(ob, ANIM.Fast, {TextTransparency = 0})
                    end
                else
                    Tween(dropFrame, ANIM.Normal, {Size = UDim2.new(0, 120, 0, 0), BackgroundTransparency = 1})
                    Tween(arrow, ANIM.Spring, {Rotation = 0})
                    for _, ob in ipairs(optionButtons) do
                        Tween(ob, ANIM.Fast, {TextTransparency = 1})
                    end
                end
            end)
            btn.MouseEnter:Connect(function()
                Tween(btn, ANIM.Fast, {BackgroundColor3 = Color3.fromRGB(theme.Shade.R * 255 + 20, theme.Shade.G * 255 + 20, theme.Shade.B * 255 + 20)})
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, ANIM.Fast, {BackgroundColor3 = theme.Shade})
            end)
        end

        function Tab:AddInput(text, default, callback, description)
            local saved = loadedConfig.inputs and loadedConfig.inputs[text]
            local inputDefault = saved or default or ""
            saveData.inputs[text] = inputDefault

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 0.5
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -160, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.TextTransparency = 0
            lb.Parent = frame
            table.insert(uiCache.Text, lb)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 120, 0, 30)
            box.Position = UDim2.new(1, -135, 0.5, -15)
            box.BackgroundColor3 = theme.Shade
            box.Text = inputDefault
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = theme.Font
            box.TextSize = 14
            box.ClearTextOnFocus = false
            box.TextTransparency = 0
            box.Parent = frame
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
            table.insert(uiCache.Shade, box)
            table.insert(uiCache.Text, box)

            local boxStroke = Instance.new("UIStroke", box)
            boxStroke.Color = theme.Outline
            boxStroke.Thickness = 1
            boxStroke.Transparency = 0
            AttachTooltip(frame, description, screenGui)
            table.insert(tabElements, {frame = frame, searchText = text})

            uiRegistry.inputs[text] = {box = box, callback = callback}

            box.Focused:Connect(function()
                Tween(box, ANIM.Normal, {BackgroundColor3 = Color3.fromRGB(theme.Shade.R * 255 + 15, theme.Shade.G * 255 + 15, theme.Shade.B * 255 + 15)})
                Tween(boxStroke, ANIM.Normal, {Thickness = 2, Color = theme.Main})
                Tween(box, ANIM.Spring, {Size = UDim2.new(0, 130, 0, 34), Position = UDim2.new(1, -140, 0.5, -17)})
            end)
            box.FocusLost:Connect(function()
                saveData.inputs[text] = box.Text
                DebouncedSave()
                Tween(box, ANIM.Normal, {BackgroundColor3 = theme.Shade})
                Tween(boxStroke, ANIM.Normal, {Thickness = 1, Color = theme.Outline})
                Tween(box, ANIM.Spring, {Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(1, -135, 0.5, -15)})
                if callback then callback(box.Text) end
            end)
        end

        function Tab:AddKeybind(text, defaultKey, callback, description)
            local saved = loadedConfig.keybinds and loadedConfig.keybinds[text]
            local currentKey = saved and Enum.KeyCode[saved] or defaultKey or Enum.KeyCode.Unknown
            saveData.keybinds[text] = currentKey.Name
            local listening = false

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -160, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.TextTransparency = 1
            lb.Parent = frame
            table.insert(uiCache.Text, lb)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 120, 0, 30)
            btn.Position = UDim2.new(1, -135, 0.5, -15)
            btn.BackgroundColor3 = theme.Shade
            btn.Text = currentKey.Name
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = theme.Font
            btn.TextSize = 14
            btn.AutoButtonColor = false
            btn.TextTransparency = 1
            btn.Parent = frame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            table.insert(uiCache.Shade, btn)
            table.insert(uiCache.Text, btn)

            local btnStroke = Instance.new("UIStroke", btn)
            btnStroke.Color = theme.Outline
            btnStroke.Thickness = 1
            btnStroke.Transparency = 1

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 0.5})
            Tween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
            Tween(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0})
            Tween(btnStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {Transparency = 0})
            AttachTooltip(frame, description, screenGui)
            table.insert(tabElements, {frame = frame, searchText = text})

            uiRegistry.keybinds[text] = {currentKey = currentKey, btn = btn, callback = callback}

            local pulseConn
            btn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                btn.Text = "..."
                btn.TextColor3 = theme.Button
                Tween(btn, ANIM.Spring, {Size = UDim2.new(0, 130, 0, 34), Position = UDim2.new(1, -140, 0.5, -17)})
                Tween(btnStroke, ANIM.Normal, {Color = theme.Button, Thickness = 2})
                local pulseDir = 1
                pulseConn = task.spawn(function()
                    while listening do
                        Tween(btn, ANIM.Pulse, {BackgroundColor3 = pulseDir == 1 and theme.Button or theme.Shade})
                        pulseDir = pulseDir * -1
                        task.wait(0.4)
                    end
                end)
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        conn:Disconnect()
                        listening = false
                        currentKey = input.KeyCode
                        saveData.keybinds[text] = currentKey.Name
                        DebouncedSave()
                        btn.Text = currentKey.Name
                        btn.TextColor3 = Color3.new(1, 1, 1)
                        Tween(btn, ANIM.Spring, {Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(1, -135, 0.5, -15)})
                        Tween(btnStroke, ANIM.Normal, {Color = theme.Outline, Thickness = 1})
                        if callback then callback(currentKey) end
                    end
                end)
            end)

            btn.MouseEnter:Connect(function()
                if not listening then
                    Tween(btn, ANIM.Fast, {BackgroundColor3 = Color3.fromRGB(theme.Shade.R * 255 + 15, theme.Shade.G * 255 + 15, theme.Shade.B * 255 + 15)})
                end
            end)
            btn.MouseLeave:Connect(function()
                if not listening then
                    Tween(btn, ANIM.Fast, {BackgroundColor3 = theme.Shade})
                end
            end)
        end

        function Tab:AddColorPicker(text, defaultColor, callback, description)
            local saved = loadedConfig.colors and loadedConfig.colors[text]
            if saved and type(saved) == "table" and saved.R and saved.G and saved.B then
                defaultColor = Color3.fromRGB(saved.R, saved.G, saved.B)
            end
            defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local curH, curS, curV = defaultColor:ToHSV()

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 0)
            frame.BackgroundColor3 = theme.Shade
            frame.BackgroundTransparency = 1
            frame.Parent = page
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            table.insert(uiCache.Shade, frame)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1, -60, 1, 0)
            lb.Position = UDim2.new(0, 15, 0, 0)
            lb.Text = text
            lb.TextColor3 = Color3.new(1, 1, 1)
            lb.Font = theme.Font
            lb.TextSize = 18
            lb.BackgroundTransparency = 1
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.TextTransparency = 1
            lb.Parent = frame
            table.insert(uiCache.Text, lb)

            local preview = Instance.new("TextButton")
            preview.Size = UDim2.new(0, 0, 0, 0)
            preview.Position = UDim2.new(1, -40, 0.5, -15)
            preview.BackgroundColor3 = defaultColor
            preview.Text = ""
            preview.AutoButtonColor = false
            preview.Parent = frame
            Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)

            local previewStroke = Instance.new("UIStroke", preview)
            previewStroke.Color = theme.Outline
            previewStroke.Thickness = 2

            Tween(frame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 0})
            Tween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
            Tween(preview, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.15), {Size = UDim2.new(0, 30, 0, 30)})
            AttachTooltip(frame, description, screenGui)
            table.insert(tabElements, {frame = frame, searchText = text})

            uiRegistry.colors[text] = {preview = preview, callback = callback, curH = curH, curS = curS, curV = curV}

            local popup = Instance.new("Frame")
            popup.Size = UDim2.new(0, 0, 0, 0)
            popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            popup.ZIndex = 1000
            popup.Visible = false
            popup.Active = true
            popup.Parent = screenGui
            popup.AnchorPoint = Vector2.new(0.5, 0)
            Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)

            local pStroke = Instance.new("UIStroke", popup)
            pStroke.Color = theme.Outline
            pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            pStroke.Thickness = 0

            local box = Instance.new("ImageButton")
            box.Size = UDim2.new(0, 150, 0, 150)
            box.Position = UDim2.new(0, 10, 0, 10)
            box.Image = "rbxassetid://4155801252"
            box.ImageColor3 = Color3.new(1, 1, 1)
            box.AutoButtonColor = false
            box.ZIndex = 1001
            box.Parent = popup
            box.ImageTransparency = 1

            local cursorSV = Instance.new("Frame")
            cursorSV.Size = UDim2.new(0, 6, 0, 6)
            cursorSV.BackgroundColor3 = Color3.new(1, 1, 1)
            cursorSV.ZIndex = 1002
            cursorSV.Parent = box
            cursorSV.BackgroundTransparency = 1
            Instance.new("UICorner", cursorSV).CornerRadius = UDim.new(1, 0)
            local cStroke = Instance.new("UIStroke", cursorSV)
            cStroke.Color = Color3.new(0, 0, 0)
            cStroke.Thickness = 1

            local hue = Instance.new("TextButton")
            hue.Size = UDim2.new(0, 20, 0, 150)
            hue.Position = UDim2.new(0, 170, 0, 10)
            hue.BackgroundColor3 = Color3.new(1, 1, 1)
            hue.Text = ""
            hue.AutoButtonColor = false
            hue.ZIndex = 1001
            hue.Parent = popup
            hue.BackgroundTransparency = 1

            local grad = Instance.new("UIGradient", hue)
            grad.Rotation = 90
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))
            })

            local cursorHue = Instance.new("Frame")
            cursorHue.Size = UDim2.new(1, 4, 0, 3)
            cursorHue.Position = UDim2.new(0, -2, 0, 0)
            cursorHue.BackgroundColor3 = Color3.new(1, 1, 1)
            cursorHue.ZIndex = 1002
            cursorHue.Parent = hue
            cursorHue.BackgroundTransparency = 1
            local hStroke = Instance.new("UIStroke", cursorHue)
            hStroke.Color = Color3.new(0, 0, 0)
            hStroke.Thickness = 1

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, -20, 0, 30)
            txt.Position = UDim2.new(0, 10, 0, 165)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = Color3.new(0.8, 0.8, 0.8)
            txt.Font = Enum.Font.Code
            txt.TextSize = 14
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.ZIndex = 1001
            txt.TextTransparency = 1
            txt.Parent = popup
            table.insert(uiCache.Text, txt)

            local function update()
                local c = Color3.fromHSV(curH, curS, curV)
                box.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
                preview.BackgroundColor3 = c
                cursorSV.Position = UDim2.new(curS, -3, 1 - curV, -3)
                cursorHue.Position = UDim2.new(0, -2, curH, -1)
                local r, g, b = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
                txt.Text = string.format("#%02X%02X%02X   %d, %d, %d", r, g, b, r, g, b)
                saveData.colors[text] = {R = r, G = g, B = b}
                DebouncedSave()
                if callback then callback(c) end
            end
            update()

            preview.MouseButton1Click:Connect(function()
                popup.Visible = not popup.Visible
                if popup.Visible then
                    local abs = preview.AbsolutePosition
                    popup.Position = UDim2.new(0, abs.X + 15, 0, abs.Y + 40)
                    popup.Size = UDim2.new(0, 0, 0, 0)
                    Tween(popup, ANIM.Bounce, {Size = UDim2.new(0, 200, 0, 200)})
                    Tween(pStroke, ANIM.Normal, {Thickness = 2})
                    Tween(box, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {ImageTransparency = 0})
                    Tween(cursorSV, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {BackgroundTransparency = 0})
                    Tween(cursorHue, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {BackgroundTransparency = 0})
                    Tween(hue, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {BackgroundTransparency = 0})
                    Tween(txt, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {TextTransparency = 0})
                else
                    Tween(popup, ANIM.Fast, {Size = UDim2.new(0, 0, 0, 0)})
                    Tween(pStroke, ANIM.Fast, {Thickness = 0})
                    task.delay(0.2, function()
                        if not popup.Visible then popup.Visible = false end
                    end)
                end
            end)

            local dragHue, dragSV = false, false
            local dragLoop
            local function updateHSV()
                if dragHue then
                    curH = math.clamp((LocalPlayer:GetMouse().Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
                elseif dragSV then
                    curS = math.clamp((LocalPlayer:GetMouse().X - box.AbsolutePosition.X) / box.AbsoluteSize.X, 0, 1)
                    curV = 1 - math.clamp((LocalPlayer:GetMouse().Y - box.AbsolutePosition.Y) / box.AbsoluteSize.Y, 0, 1)
                end
                update()
            end

            local function startDrag()
                if dragLoop then dragLoop:Disconnect() end
                dragLoop = RunService.RenderStepped:Connect(updateHSV)
            end

            local function stopDrag()
                if dragLoop then dragLoop:Disconnect(); dragLoop = nil end
            end

            hue.MouseButton1Down:Connect(function() dragHue = true; startDrag() end)
            box.MouseButton1Down:Connect(function() dragSV = true; startDrag() end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragHue = false
                    dragSV = false
                    stopDrag()
                end
            end)

            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and popup.Visible then
                    local mx, my = LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y
                    local px, py = popup.AbsolutePosition.X, popup.AbsolutePosition.Y
                    local bx, by = preview.AbsolutePosition.X, preview.AbsolutePosition.Y
                    local inPopup = (mx >= px and mx <= px + popup.AbsoluteSize.X and my >= py and my <= py + popup.AbsoluteSize.Y)
                    local inBtn = (mx >= bx and mx <= bx + preview.AbsoluteSize.X and my >= by and my <= by + preview.AbsoluteSize.Y)
                    if not inPopup and not inBtn then
                        Tween(popup, ANIM.Fast, {Size = UDim2.new(0, 0, 0, 0)})
                        Tween(pStroke, ANIM.Fast, {Thickness = 0})
                        task.delay(0.2, function()
                            popup.Visible = false
                        end)
                    end
                end
            end)
        end

        return Tab
    end

    function Window:MakeTab(config)
        config = config or {}
        local name = config.Name or "Tab"
        local icon = config.Icon or ""

        local Tab = self:AddTab(name)
        local tabID = tabCount

        if icon ~= "" then
            local tabData = tabs[tabID]
            if tabData and tabData.Btn then
                local tabBtn = tabData.Btn

                local iconImg = Instance.new("ImageLabel")
                iconImg.Name = "TabIcon"
                iconImg.Size = UDim2.new(0, 20, 0, 20)
                iconImg.Position = UDim2.new(0, 8, 0.5, -10)
                iconImg.BackgroundTransparency = 1
                iconImg.Image = icon
                iconImg.ZIndex = tabBtn.ZIndex + 1
                iconImg.Parent = tabBtn

                tabBtn.TextXAlignment = Enum.TextXAlignment.Left
                tabBtn.Text = "            " .. name
            end
        end

        return Tab
    end


    if hasSettings then
        local settingsTab = Window:AddTab("Settings")
        local settingsData = tabs[tabCount]
        settingsData.Btn.LayoutOrder = 999999

        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -10, 0, 1)
        sep.Position = UDim2.new(0, 5, 0, 0)
        sep.BackgroundColor3 = theme.Outline
        sep.BackgroundTransparency = 0.6
        sep.LayoutOrder = 999998
        sep.Parent = tabContainer
        Instance.new("UICorner", sep).CornerRadius = UDim.new(1, 0)

        local sp = Instance.new("Frame")
        sp.Size = UDim2.new(1, 0, 0, 4)
        sp.BackgroundTransparency = 1
        sp.LayoutOrder = 999997
        sp.Parent = tabContainer

        settingsTab:AddLabel("XeNOX v2.2 — Config Manager")
        settingsTab:AddParagraph("Manage Configs", "All your saved configurations appear below. Click LOAD to apply instantly.")

        settingsTab:AddToggle("Auto Save", autoSave, function(t)
            autoSave = t
            saveData._autoSave = t
            saveData._activeConfigName = activeConfigName
            DebouncedSave()
        end)

        local allConfigs = ListConfigs()
        if #allConfigs == 0 then allConfigs = {"default"} end
        settingsTab:AddDropdown("Auto Save Target", allConfigs, function(selected)
            autoSaveTarget = selected
            saveData._autoSaveTarget = selected
            DebouncedSave()
        end, "Which config file auto-save writes to")

        settingsTab:AddToggle("Auto Load", autoLoad, function(t)
            autoLoad = t
            saveData._autoLoad = t
            saveData._activeConfigName = activeConfigName
            DebouncedSave()
        end)

        local activeCard = Instance.new("Frame")
        activeCard.Size = UDim2.new(1, -20, 0, 0)
        activeCard.BackgroundColor3 = theme.Shade
        activeCard.BackgroundTransparency = 1
        activeCard.Parent = settingsData.Page
        Instance.new("UICorner", activeCard).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, activeCard)

        local activeStroke = Instance.new("UIStroke", activeCard)
        activeStroke.Color = theme.Main
        activeStroke.Thickness = 2
        activeStroke.Transparency = 1

        local activeHeader = Instance.new("TextLabel")
        activeHeader.Size = UDim2.new(1, -20, 0, 18)
        activeHeader.Position = UDim2.new(0, 10, 0, 6)
        activeHeader.BackgroundTransparency = 1
        activeHeader.Text = "CURRENTLY ACTIVE"
        activeHeader.TextColor3 = theme.Main
        activeHeader.Font = theme.Font
        activeHeader.TextSize = 13
        activeHeader.TextXAlignment = Enum.TextXAlignment.Left
        activeHeader.TextTransparency = 1
        activeHeader.Parent = activeCard
        table.insert(uiCache.Text, activeHeader)

        local activeNameLbl = Instance.new("TextLabel")
        activeNameLbl.Size = UDim2.new(1, -20, 0, 28)
        activeNameLbl.Position = UDim2.new(0, 10, 0, 24)
        activeNameLbl.BackgroundTransparency = 1
        activeNameLbl.Text = activeConfigName
        activeNameLbl.TextColor3 = Color3.new(1, 1, 1)
        activeNameLbl.Font = theme.Font
        activeNameLbl.TextSize = 22
        activeNameLbl.TextXAlignment = Enum.TextXAlignment.Left
        activeNameLbl.TextTransparency = 1
        activeNameLbl.Parent = activeCard
        table.insert(uiCache.Text, activeNameLbl)

        Tween(activeCard, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 58), BackgroundTransparency = 0})
        Tween(activeStroke, ANIM.Smooth, {Transparency = 0})
        Tween(activeHeader, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0})
        Tween(activeNameLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0})

        settingsTab:AddLabel("Saved Configs")

        local listContainer = Instance.new("Frame")
        listContainer.Size = UDim2.new(1, -20, 0, 0)
        listContainer.BackgroundTransparency = 1
        listContainer.Parent = settingsData.Page

        local listLayout = Instance.new("UIListLayout", listContainer)
        listLayout.Padding = UDim.new(0, 6)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local configRows = {}

        local function RefreshConfigList()
            for _, row in ipairs(configRows) do
                if row and row.Parent then row:Destroy() end
            end
            configRows = {}

            local list = ListConfigs()
            if #list == 0 then list = {"default"} end

            for i, name in ipairs(list) do
                local isActive = (name == activeConfigName)

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 46)
                row.BackgroundColor3 = isActive and theme.Button or theme.Shade
                row.BackgroundTransparency = 1
                row.LayoutOrder = i
                row.Parent = listContainer
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
                if not isActive then table.insert(uiCache.Shade, row) end

                local rowStroke = Instance.new("UIStroke", row)
                rowStroke.Color = isActive and theme.ButtonOutline or theme.Outline
                rowStroke.Thickness = isActive and 2 or 1
                rowStroke.Transparency = 1

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, -200, 1, 0)
                nameLbl.Position = UDim2.new(0, 14, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = name .. (isActive and "  ●" or "")
                nameLbl.TextColor3 = Color3.new(1, 1, 1)
                nameLbl.Font = theme.Font
                nameLbl.TextSize = 16
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTransparency = 1
                nameLbl.Parent = row
                table.insert(uiCache.Text, nameLbl)

                local selBtn = Instance.new("TextButton")
                selBtn.Size = UDim2.new(0, 46, 0, 28)
                selBtn.Position = UDim2.new(1, -168, 0.5, -14)
                selBtn.BackgroundColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
                selBtn.Text = "SEL"
                selBtn.TextColor3 = Color3.new(0, 0, 0)
                selBtn.Font = theme.Font
                selBtn.TextSize = 11
                selBtn.AutoButtonColor = false
                selBtn.Parent = row
                Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 6)
                local selStroke = Instance.new("UIStroke", selBtn)
                selStroke.Color = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
                selStroke.Thickness = 1

                local loadBtn = Instance.new("TextButton")
                loadBtn.Size = UDim2.new(0, 52, 0, 28)
                loadBtn.Position = UDim2.new(1, -114, 0.5, -14)
                loadBtn.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
                loadBtn.Text = "LOAD"
                loadBtn.TextColor3 = Color3.new(0, 0, 0)
                loadBtn.Font = theme.Font
                loadBtn.TextSize = 11
                loadBtn.AutoButtonColor = false
                loadBtn.Parent = row
                Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 6)
                local loadStroke = Instance.new("UIStroke", loadBtn)
                loadStroke.Color = Color3.fromRGB(80, 220, 120)
                loadStroke.Thickness = 1

                local delBtn = Instance.new("TextButton")
                delBtn.Size = UDim2.new(0, 52, 0, 28)
                delBtn.Position = UDim2.new(1, -56, 0.5, -14)
                delBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
                delBtn.Text = "DEL"
                delBtn.TextColor3 = Color3.new(0, 0, 0)
                delBtn.Font = theme.Font
                delBtn.TextSize = 11
                delBtn.AutoButtonColor = false
                delBtn.Parent = row
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)
                local delStroke = Instance.new("UIStroke", delBtn)
                delStroke.Color = Color3.fromRGB(255, 70, 70)
                delStroke.Thickness = 1

                row.MouseEnter:Connect(function()
                    if not isActive then
                        Tween(row, ANIM.Fast, {BackgroundColor3 = Color3.fromRGB(theme.Shade.R * 255 + 20, theme.Shade.G * 255 + 20, theme.Shade.B * 255 + 20)})
                    end
                    Tween(rowStroke, ANIM.Fast, {Thickness = 2})
                end)
                row.MouseLeave:Connect(function()
                    if not isActive then
                        Tween(row, ANIM.Fast, {BackgroundColor3 = theme.Shade})
                    end
                    Tween(rowStroke, ANIM.Fast, {Thickness = isActive and 2 or 1})
                end)

                selBtn.MouseEnter:Connect(function()
                    Tween(selBtn, ANIM.Fast, {BackgroundTransparency = 0.2, Size = UDim2.new(0, 50, 0, 30), Position = UDim2.new(1, -170, 0.5, -15)})
                    Tween(selStroke, ANIM.Fast, {Thickness = 2})
                end)
                selBtn.MouseLeave:Connect(function()
                    Tween(selBtn, ANIM.Fast, {BackgroundTransparency = 0, Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(1, -168, 0.5, -14)})
                    Tween(selStroke, ANIM.Fast, {Thickness = 1})
                end)
                selBtn.MouseButton1Down:Connect(function()
                    Tween(selBtn, ANIM.Fast, {BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 44, 0, 26), Position = UDim2.new(1, -166, 0.5, -13)})
                end)
                selBtn.MouseButton1Up:Connect(function()
                    Tween(selBtn, ANIM.Spring, {BackgroundColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120), Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(1, -168, 0.5, -14)})
                end)
                selBtn.MouseButton1Click:Connect(function()
                    activeConfigName = name
                    activeNameLbl.Text = activeConfigName
                    Window:Notify("Config Selected", "'" .. name .. "' is now the active target.", 2)
                    RefreshConfigList()
                end)

                loadBtn.MouseEnter:Connect(function()
                    Tween(loadBtn, ANIM.Fast, {BackgroundTransparency = 0.2, Size = UDim2.new(0, 56, 0, 30), Position = UDim2.new(1, -116, 0.5, -15)})
                    Tween(loadStroke, ANIM.Fast, {Thickness = 2})
                end)
                loadBtn.MouseLeave:Connect(function()
                    Tween(loadBtn, ANIM.Fast, {BackgroundTransparency = 0, Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -114, 0.5, -14)})
                    Tween(loadStroke, ANIM.Fast, {Thickness = 1})
                end)
                loadBtn.MouseButton1Down:Connect(function()
                    Tween(loadBtn, ANIM.Fast, {BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 48, 0, 26), Position = UDim2.new(1, -112, 0.5, -13)})
                end)
                loadBtn.MouseButton1Up:Connect(function()
                    Tween(loadBtn, ANIM.Spring, {BackgroundColor3 = Color3.fromRGB(80, 220, 120), Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -114, 0.5, -14)})
                end)
                loadBtn.MouseButton1Click:Connect(function()
                    local newData = LoadConfig(name)
                    if newData then
                        loadedConfig = newData
                        Window._loadedConfig = newData
                        activeConfigName = name
                        ApplyConfig(newData)
                        activeNameLbl.Text = activeConfigName
                        Window:Notify("Config Loaded", "Applied '" .. name .. "' live!", 3)
                        RefreshConfigList()
                    else
                        Window:Notify("Error", "Failed to load '" .. name .. "'", 2)
                    end
                end)

                delBtn.MouseEnter:Connect(function()
                    Tween(delBtn, ANIM.Fast, {BackgroundTransparency = 0.2, Size = UDim2.new(0, 56, 0, 30), Position = UDim2.new(1, -58, 0.5, -15)})
                    Tween(delStroke, ANIM.Fast, {Thickness = 2})
                end)
                delBtn.MouseLeave:Connect(function()
                    Tween(delBtn, ANIM.Fast, {BackgroundTransparency = 0, Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -56, 0.5, -14)})
                    Tween(delStroke, ANIM.Fast, {Thickness = 1})
                end)
                delBtn.MouseButton1Down:Connect(function()
                    Tween(delBtn, ANIM.Fast, {BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 48, 0, 26), Position = UDim2.new(1, -54, 0.5, -13)})
                end)
                delBtn.MouseButton1Up:Connect(function()
                    Tween(delBtn, ANIM.Spring, {BackgroundColor3 = Color3.fromRGB(255, 70, 70), Size = UDim2.new(0, 52, 0, 28), Position = UDim2.new(1, -56, 0.5, -14)})
                end)
                delBtn.MouseButton1Click:Connect(function()
                    if name == "default" then
                        Window:Notify("Error", "Cannot delete default config.", 2)
                        return
                    end
                    if DeleteConfig(name) then
                        Window:Notify("Deleted", "Config '" .. name .. "' removed.", 2)
                        if activeConfigName == name then
                            activeConfigName = "default"
                            activeNameLbl.Text = "default"
                        end
                        RefreshConfigList()
                    else
                        Window:Notify("Error", "Config '" .. name .. "' not found.", 2)
                    end
                end)

                Tween(row, ANIM.Bounce, {BackgroundTransparency = 0})
                Tween(rowStroke, ANIM.Smooth, {Transparency = 0})
                Tween(nameLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.05 * i), {TextTransparency = 0})

                table.insert(configRows, row)
            end

            listContainer.Size = UDim2.new(1, -20, 0, math.max(#list * 52, 0))
        end

        settingsTab:AddLabel("Config Actions")
        settingsTab:AddParagraph("Create New", "Type a name below, then click CREATE NEW to save current settings as a brand new config file.")

        local newConfigName = ""
        settingsTab:AddInput("New Config Name", "", function(txt)
            newConfigName = txt:gsub("[^%w_]", "_")
        end)

        local createFrame = Instance.new("Frame")
        createFrame.Size = UDim2.new(1, -20, 0, 0)
        createFrame.BackgroundColor3 = theme.Shade
        createFrame.BackgroundTransparency = 0.5
        createFrame.Parent = settingsData.Page
        Instance.new("UICorner", createFrame).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, createFrame)

        local createBtn = Instance.new("TextButton")
        createBtn.Size = UDim2.new(1, -16, 1, -16)
        createBtn.Position = UDim2.new(0, 8, 0, 8)
        createBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        createBtn.Text = "➕  CREATE NEW CONFIG"
        createBtn.TextColor3 = Color3.new(0, 0, 0)
        createBtn.Font = theme.Font
        createBtn.TextSize = 15
        createBtn.Parent = createFrame
        createBtn.AutoButtonColor = false

        Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 6)
        local createStroke = Instance.new("UIStroke", createBtn)
        createStroke.Color = Color3.fromRGB(0, 220, 255)
        createStroke.Thickness = 1
        createStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        table.insert(uiCache.ButtonOutline, createStroke)

        createBtn.MouseEnter:Connect(function()
            Tween(createBtn, ANIM.Fast, {BackgroundColor3 = Color3.fromRGB(50, 200, 255)})
            Tween(createStroke, ANIM.Fast, {Thickness = 2})
        end)

        createBtn.MouseLeave:Connect(function()
            Tween(createBtn, ANIM.Fast, {BackgroundColor3 = Color3.fromRGB(0, 180, 255)})
            Tween(createStroke, ANIM.Fast, {Thickness = 1})
        end)

        createBtn.MouseButton1Click:Connect(function()
            if newConfigName == "" then
                Window:Notify("Error", "Please enter a valid config name.", 2)
                return
            end
            activeConfigName = newConfigName
            saveData._activeConfigName = activeConfigName
            SaveConfig(activeConfigName)
            activeNameLbl.Text = activeConfigName
            Window:Notify("Config Created", "Saved as '" .. activeConfigName .. "'", 2)
            RefreshConfigList()
        end)
        Tween(createFrame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 54)})

        -- Separator
        local sep2 = Instance.new("Frame")
        sep2.Size = UDim2.new(1, -40, 0, 1)
        sep2.BackgroundColor3 = theme.Outline
        sep2.BackgroundTransparency = 0.4
        sep2.Parent = settingsData.Page

        settingsTab:AddParagraph("Save Active", "Click below to overwrite the currently active config with your current settings.")

        -- SAVE ACTIVE button (green)
        local saveActiveFrame = Instance.new("Frame")
        saveActiveFrame.Size = UDim2.new(1, -20, 0, 0)
        saveActiveFrame.BackgroundColor3 = theme.Shade
        saveActiveFrame.BackgroundTransparency = 0.5
        saveActiveFrame.Parent = settingsData.Page
        Instance.new("UICorner", saveActiveFrame).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, saveActiveFrame)

        local saveActiveBtn = Instance.new("TextButton")
        saveActiveBtn.Size = UDim2.new(1, -16, 1, -16)
        saveActiveBtn.Position = UDim2.new(0, 8, 0, 8)
        saveActiveBtn.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
        saveActiveBtn.Text = "💾  SAVE ACTIVE CONFIG"
        saveActiveBtn.TextColor3 = Color3.new(0, 0, 0)
        saveActiveBtn.Font = theme.Font
        saveActiveBtn.TextSize = 15
        saveActiveBtn.Parent = saveActiveFrame
        saveActiveBtn.AutoButtonColor = false

        Instance.new("UICorner", saveActiveBtn).CornerRadius = UDim.new(0, 6)
        local saveActiveStroke = Instance.new("UIStroke", saveActiveBtn)
        saveActiveStroke.Color = Color3.fromRGB(100, 255, 150)
        saveActiveStroke.Thickness = 1
        saveActiveStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        table.insert(uiCache.ButtonOutline, saveActiveStroke)

        saveActiveBtn.MouseEnter:Connect(function()
            Tween(saveActiveBtn, ANIM.Fast, {BackgroundTransparency = 0.2, Size = UDim2.new(1, -12, 1, -12), Position = UDim2.new(0, 6, 0, 6)})
            Tween(saveActiveStroke, ANIM.Fast, {Thickness = 2})
        end)
        saveActiveBtn.MouseLeave:Connect(function()
            Tween(saveActiveBtn, ANIM.Fast, {BackgroundTransparency = 0, Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8)})
            Tween(saveActiveStroke, ANIM.Fast, {Thickness = 1})
        end)
        saveActiveBtn.MouseButton1Down:Connect(function()
            Tween(saveActiveBtn, ANIM.Fast, {BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10)})
            CreateRipple(saveActiveBtn, Vector2.new(saveActiveBtn.AbsoluteSize.X / 2, saveActiveBtn.AbsoluteSize.Y / 2))
        end)
        saveActiveBtn.MouseButton1Up:Connect(function()
            Tween(saveActiveBtn, ANIM.Spring, {BackgroundColor3 = Color3.fromRGB(80, 220, 120), Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8)})
        end)
        saveActiveBtn.MouseButton1Click:Connect(function()
            SaveConfig(activeConfigName)
            Window:Notify("Config Saved", "Overwritten '" .. activeConfigName .. "' with current settings!", 3)
        end)

        Tween(saveActiveFrame, ANIM.Bounce, {Size = UDim2.new(1, -20, 0, 54)})

        -- Populate list on first open
        RefreshConfigList()
        -- ==================== BACKGROUND EFFECTS ====================
        settingsTab:AddLabel("BACKGROUND EFFECTS")
        settingsTab:AddToggle("Enable Rain", effects.Rain, function(t) effects.Rain = t saveData.effects.Rain = t DebouncedSave() end)
        settingsTab:AddColorPicker("Rain Color", effectColors.Rain, function(c) effectColors.Rain = c saveData.effectColors.Rain = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)} DebouncedSave() end)
        settingsTab:AddToggle("Enable Mouse Trail", effects.Trail, function(t) effects.Trail = t saveData.effects.Trail = t DebouncedSave() end)
        settingsTab:AddColorPicker("Trail Color", effectColors.Trail, function(c) effectColors.Trail = c saveData.effectColors.Trail = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)} DebouncedSave() end)
        settingsTab:AddToggle("Enable Interactive Blobs", effects.Blob, function(t) effects.Blob = t saveData.effects.Blob = t DebouncedSave() end)
        settingsTab:AddColorPicker("Blob Color", effectColors.Blob, function(c) effectColors.Blob = c saveData.effectColors.Blob = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)} DebouncedSave() end)
        settingsTab:AddToggle("Enable Matrix Rain", effects.Matrix, function(t) effects.Matrix = t saveData.effects.Matrix = t DebouncedSave() end)
        settingsTab:AddColorPicker("Matrix Color", effectColors.Matrix, function(c) effectColors.Matrix = c saveData.effectColors.Matrix = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)} DebouncedSave() end)
        settingsTab:AddToggle("Enable Floating Hexagons", effects.Hex, function(t) effects.Hex = t saveData.effects.Hex = t DebouncedSave() end)
        settingsTab:AddColorPicker("Hex Color", effectColors.Hex, function(c) effectColors.Hex = c saveData.effectColors.Hex = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)} DebouncedSave() end)
        settingsTab:AddToggle("Enable Glitch Blocks", effects.Glitch, function(t) effects.Glitch = t saveData.effects.Glitch = t DebouncedSave() end)
        settingsTab:AddColorPicker("Glitch Color", effectColors.Glitch, function(c) effectColors.Glitch = c saveData.effectColors.Glitch = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)} DebouncedSave() end)

        -- ==================== APPEARANCE ====================
        settingsTab:AddLabel("APPEARANCE")
        settingsTab:AddKeybind("Menu Toggle Key", menuKey, function(newKey) menuKey = newKey saveData.menuKey = newKey.Name DebouncedSave() end)

        local allFonts = Enum.Font:GetEnumItems()
        local fontNames = {}
        for _, f in ipairs(allFonts) do table.insert(fontNames, f.Name) end

        settingsTab:AddDropdown("Global Font", fontNames, function(selected)
            for _, f in ipairs(allFonts) do
                if f.Name == selected then
                    theme.Font = f
                    saveData.theme.Font = f.Name
                    DebouncedSave()
                    for _, v in ipairs(uiCache.Text) do
                        if v and v.Parent then
                            v.Font = f
                        end
                    end
                    break
                end
            end
        end, "Changes the font used across the entire UI")

        settingsTab:AddColorPicker("Main Theme", theme.Main, function(c)
            theme.Main = c
            saveData.theme.Main = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)}
            DebouncedSave()
            Tween(mainFrame, ANIM.Normal, {BackgroundColor3 = c})
            Tween(titleLbl, ANIM.Normal, {TextColor3 = c})
            Tween(mainStroke, ANIM.Normal, {Color = c})
        end)

        settingsTab:AddColorPicker("UI Outline Color", theme.Outline, function(c)
            theme.Outline = c
            saveData.theme.Outline = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)}
            DebouncedSave()
            Tween(mainStroke, ANIM.Normal, {Color = c})
            for _, v in ipairs(uiCache.ButtonOutline) do
                if v and v.Parent then Tween(v, ANIM.Normal, {Color = c}) end
            end
        end)

        settingsTab:AddColorPicker("Shade Color", theme.Shade, function(c)
            theme.Shade = c
            saveData.theme.Shade = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)}
            DebouncedSave()
            for _, v in ipairs(uiCache.Shade) do
                if v and v.Parent then Tween(v, ANIM.Normal, {BackgroundColor3 = c}) end
            end
        end)

        settingsTab:AddColorPicker("Button Color", theme.Button, function(c)
            theme.Button = c
            saveData.theme.Button = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)}
            DebouncedSave()
            for _, v in ipairs(uiCache.Button) do
                if v and v.Parent then Tween(v, ANIM.Normal, {BackgroundColor3 = c}) end
            end
        end)

        settingsTab:AddColorPicker("Button Outline Color", theme.ButtonOutline, function(c)
            theme.ButtonOutline = c
            saveData.theme.ButtonOutline = {R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255)}
            DebouncedSave()
            for _, v in ipairs(uiCache.ButtonOutline) do
                if v and v.Parent then Tween(v, ANIM.Normal, {Color = c}) end
            end
        end)

        task.delay(0.1, function()
            if settingsData and settingsData.Page then
                settingsData.Page.CanvasSize = UDim2.new(0, 0, 0, 3000)
            end
        end)
    end
    function Window:SaveConfig(name)
        SaveConfig(name)
    end

    function Window:LoadConfig(name)
        return LoadConfig(name)
    end

    function Window:DeleteConfig(name)
        return DeleteConfig(name)
    end

    function Window:ListConfigs()
        return ListConfigs()
    end

    function Window:SetActiveConfig(name)
        activeConfigName = name
    end

    function Window:GetActiveConfig()
        return activeConfigName
    end

    function Window:ResetConfig()
        local path = GetConfigPath(activeConfigName)
        if isfile and isfile(path) then
            pcall(function() delfile(path) end)
        end
        saveData.toggles = {}
        saveData.sliders = {}
        saveData.dropdowns = {}
        saveData.inputs = {}
        saveData.keybinds = {}
        saveData.colors = {}
        saveData.theme = {}
        saveData.effects = {}
        saveData.effectColors = {}
        saveData.menuKey = nil
    end

    function Window:GetConfigPath(name)
        return GetConfigPath(name or activeConfigName)
    end


    -- AUTO LOAD: If enabled, apply the active config after UI is fully built
    if autoLoad then
        local data = LoadConfig(activeConfigName)
        if data then
            loadedConfig = data
            Window._loadedConfig = data
            ApplyConfig(data)
            Window:Notify("Auto Load", "Applied config '" .. activeConfigName .. "' automatically!", 3)
        end
    end

    -- ==================== EXTERNAL SCRIPT SAVE API ====================
    Window._configCallbacks = {}

    function Window:SetCustomData(key, value)
        if type(key) ~= "string" then return end
        saveData.custom[key] = value
        DebouncedSave()
    end

    function Window:GetCustomData(key, default)
        if saveData.custom[key] ~= nil then
            return saveData.custom[key]
        end
        return default
    end

    function Window:GetAllCustomData()
        local copy = {}
        for k, v in pairs(saveData.custom) do
            copy[k] = v
        end
        return copy
    end

    function Window:OnConfigLoaded(callback)
        if type(callback) == "function" then
            table.insert(Window._configCallbacks, callback)
        end
    end

    function Window:ForceSave()
        SaveConfig(activeConfigName)
    end

    function Window:ForceLoad(name)
        name = name or activeConfigName
        local data = LoadConfig(name)
        if data then
            loadedConfig = data
            Window._loadedConfig = data
            activeConfigName = name
            ApplyConfig(data)
            return true
        end
        return false
    end
    -- ==================== /EXTERNAL SCRIPT SAVE API ====================

    return Window
end

function CreateXELIB(config)
    return XELIB:MakeWindow(config)
end
return XELIB
