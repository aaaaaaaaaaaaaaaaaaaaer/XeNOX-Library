local XELIB = {}
XELIB.__index = XELIB

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = nil
if LocalPlayer then
    pcall(function() PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) end)
end

local DEFAULT_THEME = Color3.fromRGB(0, 255, 255)
local DEFAULT_SHADE = Color3.fromRGB(25, 55, 95)
local DEFAULT_OUTLINE = Color3.fromRGB(0, 255, 255)
local DEFAULT_BUTTON = Color3.fromRGB(0, 200, 255)
local DEFAULT_BTN_OUTLINE = Color3.fromRGB(0, 255, 255)

local ANIM = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FadeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    Slide = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Pop = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Pulse = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

-- Utils
local RNG = Random.new()
local function RandomString(len)
    len = len or 10
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local t = {}
    for i = 1, len do
        local idx = RNG:NextInteger(1, #chars)
        t[i] = chars:sub(idx, idx)
    end
    return table.concat(t)
end

local function ClampRGB(v) return math.clamp(math.floor(v), 0, 255) end
local function LightenColor(c, amount)
    return Color3.fromRGB(
        ClampRGB(c.R * 255 + amount),
        ClampRGB(c.G * 255 + amount),
        ClampRGB(c.B * 255 + amount)
    )
end
local function ColorToTable(c) return {R = ClampRGB(c.R*255), G = ClampRGB(c.G*255), B = ClampRGB(c.B*255)} end
local function GetContrastColor(bg)
    local lum = bg.R*0.299 + bg.G*0.587 + bg.B*0.114
    if lum > 0.6 then return Color3.fromRGB(15, 15, 18) else return Color3.fromRGB(255, 255, 255) end
end
local CUSTOM_FONTS = {
    {Name="BuilderSans Bold", Family="BuilderSans", Weight=Enum.FontWeight.Bold},
    {Name="BuilderSans Medium", Family="BuilderSans", Weight=Enum.FontWeight.Medium},
    {Name="BuilderSans Regular", Family="BuilderSans", Weight=Enum.FontWeight.Regular},
    {Name="Gotham Black", Family="GothamSSm", Weight=Enum.FontWeight.Black},
    {Name="Gotham Bold", Family="GothamSSm", Weight=Enum.FontWeight.Bold},
    {Name="Gotham Medium", Family="GothamSSm", Weight=Enum.FontWeight.Medium},
    {Name="Montserrat Bold", Family="Montserrat", Weight=Enum.FontWeight.Bold},
    {Name="Montserrat SemiBold", Family="Montserrat", Weight=Enum.FontWeight.SemiBold},
    {Name="Montserrat Medium", Family="Montserrat", Weight=Enum.FontWeight.Medium},
    {Name="Arimo Bold", Family="Arimo", Weight=Enum.FontWeight.Bold},
    {Name="Arimo Regular", Family="Arimo", Weight=Enum.FontWeight.Regular},
    {Name="RobotoMono Medium", Family="RobotoMono", Weight=Enum.FontWeight.Medium},
    {Name="Ubuntu Bold", Family="Ubuntu", Weight=Enum.FontWeight.Bold},
    {Name="Nunito Bold", Family="Nunito", Weight=Enum.FontWeight.Bold},
}
local function ResolveFont(fontName)
    if type(fontName)~="string" then return Enum.Font.SourceSansBold, nil end
    for _, f in ipairs(Enum.Font:GetEnumItems()) do
        if f.Name==fontName then
            local _, fo = pcall(function() return Font.fromEnum(f) end)
            return f, fo
        end
    end
    for _, c in ipairs(CUSTOM_FONTS) do
        if c.Name==fontName then
            local _, fo = pcall(function() return Font.fromName(c.Family, c.Weight, Enum.FontStyle.Normal) end)
            local fb = Enum.Font.GothamBold
            if c.Weight==Enum.FontWeight.Regular then fb=Enum.Font.Gotham
            elseif c.Weight==Enum.FontWeight.Medium then fb=Enum.Font.GothamMedium
            elseif c.Weight==Enum.FontWeight.SemiBold then fb=Enum.Font.GothamSemibold
            elseif c.Weight==Enum.FontWeight.Black then fb=Enum.Font.GothamBlack end
            if fo then return fb, fo else return fb, nil end
        end
    end
    return Enum.Font.SourceSansBold, nil
end
local function BuildFontList()
    local names, seen = {}, {}
    for _, f in ipairs(Enum.Font:GetEnumItems()) do names[#names+1]=f.Name; seen[f.Name]=true end
    table.sort(names)
    for _, c in ipairs(CUSTOM_FONTS) do if not seen[c.Name] then names[#names+1]=c.Name end end
    return names
end
local function TableToColor(t, fallback)
    if type(t) == "table" and type(t.R) == "number" and type(t.G) == "number" and type(t.B) == "number" then
        return Color3.fromRGB(ClampRGB(t.R), ClampRGB(t.G), ClampRGB(t.B))
    end
    return fallback
end
local function GetSafeParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and typeof(hui) == "Instance" then return hui end
    if PlayerGui and PlayerGui.Parent then return PlayerGui end
    local ok2, pg = pcall(function() return CoreGui end)
    if ok2 and pg then return pg end
    return PlayerGui or CoreGui
end

local function SafeTween(obj, info, props)
    if not obj or not obj.Parent then return nil end
    local ok, tw = pcall(function() return TweenService:Create(obj, info, props) end)
    if ok and tw then pcall(function() tw:Play() end); return tw end
    return nil
end

local function MakeDraggable(frame, handle, connections)
    handle = handle or frame
    if not handle or not frame then return end
    -- Ensure handle can receive input
    pcall(function() handle.Active = true end)
    local dragging = false
    local dragStart, startPos
    local moveConn

    local function cleanup()
        dragging = false
        if moveConn then pcall(function() moveConn:Disconnect() end); moveConn=nil end
    end

    local con1
    con1 = handle.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if moveConn then pcall(function() moveConn:Disconnect() end); moveConn=nil end
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            moveConn = UserInputService.InputChanged:Connect(function(changed)
                if dragging and (changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch) then
                    if not dragStart or not startPos or not frame.Parent then return end
                    local delta = changed.Position - dragStart
                    -- Only offset, keep scale intact
                    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    frame.Position = newPos
                end
            end)
            if connections then table.insert(connections, moveConn) end
        end
    end)
    if connections then table.insert(connections, con1) end

    local con2 = UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            if dragging then cleanup() end
        end
    end)
    if connections then table.insert(connections, con2) end

    -- Cleanup if frame destroyed
    local con3
    con3 = frame.AncestryChanged:Connect(function(_, parent)
        if not parent then cleanup() end
    end)
    if connections then table.insert(connections, con3) end
end

local Pool = {}
local MAX_POOL = 40
local function GetFromPool(poolName, className)
    if not Pool[poolName] then Pool[poolName] = {} end
    if #Pool[poolName] > 0 then
        local obj = table.remove(Pool[poolName])
        pcall(function()
            obj.Visible = true
            if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("TextLabel") then
                obj.BackgroundTransparency = 0
            end
            if obj:IsA("TextLabel") then obj.TextTransparency = 0 end
            if obj:IsA("ImageLabel") then obj.ImageTransparency = 0 end
            -- reset common props
            if obj:FindFirstChildOfClass("UICorner") then end
        end)
        return obj
    end
    return Instance.new(className)
end

local function ReturnToPool(poolName, obj)
    if not obj then return end
    local pool = Pool[poolName]
    if not pool then Pool[poolName] = {}; pool = Pool[poolName] end
    if #pool >= MAX_POOL then pcall(function() obj:Destroy() end); return end
    local shouldFade = obj:IsA("Frame") or obj:IsA("TextLabel") or obj:IsA("ImageLabel")
    if shouldFade then
        pcall(function()
            if obj:IsA("Frame") then SafeTween(obj, ANIM.Fast, {BackgroundTransparency = 1}) end
            if obj:IsA("TextLabel") then SafeTween(obj, ANIM.Fast, {TextTransparency = 1}) end
            if obj:IsA("ImageLabel") then SafeTween(obj, ANIM.Fast, {ImageTransparency = 1}) end
        end)
        task.delay(0.22, function()
            pcall(function()
                if obj and obj.Parent then
                    obj.Visible = false
                    obj.Parent = nil
                    table.insert(pool, obj)
                elseif obj and not obj.Parent then
                    obj.Visible = false
                    table.insert(pool, obj)
                end
            end)
        end)
    else
        pcall(function()
            obj.Visible = false
            obj.Parent = nil
            table.insert(pool, obj)
        end)
    end
end

local function RainbowStroke(stroke, stopFlag)
    -- stopFlag is a table {stop = false} so caller can signal stop
    task.spawn(function()
        while stroke and stroke.Parent do
            if stopFlag and stopFlag.stop then break end
            local hue = (os.clock() * 0.3) % 1
            pcall(function() stroke.Color = Color3.fromHSV(hue, 1, 1) end)
            task.wait(0.05)
        end
    end)
end

local function CreateRipple(parent, pos)
    if not parent or not parent.Parent then return end
    if parent.AbsoluteSize.X < 1 or parent.AbsoluteSize.Y < 1 then return end
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, pos.X, 0, pos.Y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.55
    ripple.BorderSizePixel = 0
    ripple.ZIndex = parent.ZIndex + 1
    ripple.ClipsDescendants = false
    ripple.Parent = parent
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
    if maxSize < 10 then maxSize = 80 end
    SafeTween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    task.delay(0.55, function() pcall(function() ripple:Destroy() end) end)
end

local function AttachTooltip(target, text, screenGui, connections)
    if not text or text == "" or not target or not screenGui then return end
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
    tLabel.Font = Enum.Font.Gotham
    tLabel.TextSize = 12
    tLabel.TextWrapped = true
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.TextYAlignment = Enum.TextYAlignment.Top
    tLabel.TextTransparency = 1
    tLabel.ZIndex = 10001
    tLabel.Parent = tooltip

    local function show()
        if not tooltip or not tooltip.Parent or not target.Parent then return end
        if screenGui.AbsoluteSize.X < 10 then return end
        local abs = target.AbsolutePosition
        local size = target.AbsoluteSize
        local bounds = game:GetService("TextService"):GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(188, 1000))
        local textHeight = math.clamp(bounds.Y + 16, 28, 120)
        tooltip.Size = UDim2.new(0, 220, 0, textHeight)
        tLabel.Size = UDim2.new(1, -16, 1, -10)
        tLabel.Position = UDim2.new(0, 8, 0, 5)
        local yPos = abs.Y - textHeight - 8
        if yPos < 36 then yPos = abs.Y + size.Y + 8 end
        local xPos = math.clamp(abs.X + size.X/2 - 110, 10, screenGui.AbsoluteSize.X - 230)
        yPos = math.clamp(yPos, 36, screenGui.AbsoluteSize.Y - textHeight - 10)
        tooltip.Position = UDim2.new(0, xPos, 0, yPos)
        tooltip.Visible = true
        SafeTween(tooltip, ANIM.Fast, {BackgroundTransparency = 0.08})
        SafeTween(tStroke, ANIM.Fast, {Transparency = 0})
        SafeTween(tLabel, ANIM.Fast, {TextTransparency = 0})
    end
    local function hide()
        if not tooltip or not tooltip.Parent then return end
        SafeTween(tooltip, ANIM.FadeOut, {BackgroundTransparency = 1})
        SafeTween(tStroke, ANIM.Fast, {Transparency = 1})
        SafeTween(tLabel, ANIM.Fast, {TextTransparency = 1})
        task.delay(0.22, function()
            if tooltip and tooltip.Parent then tooltip.Visible = false end
        end)
    end
    local c1, c2
    pcall(function()
        c1 = target.MouseEnter:Connect(show)
        c2 = target.MouseLeave:Connect(hide)
    end)
    if connections and c1 then table.insert(connections, c1) end
    if connections and c2 then table.insert(connections, c2) end
    -- Touch support: show on hover not easily, keep as is
    return tooltip
end

function XELIB:MakeWindow(config)
    config = config or {}
    if config.LoadIntro ~= nil then config.Intro = config.LoadIntro end
    if config.Toggle ~= nil then config._forceToggle = config.Toggle end
    if config.CloseCallback == true then config.CloseCallback = nil end

    -- Clean previous instances
    if getgenv then
        pcall(function()
            if getgenv().XELIB_ActiveGui and typeof(getgenv().XELIB_ActiveGui) == "Instance" then
                getgenv().XELIB_ActiveGui:Destroy()
            end
            getgenv().XELIB_ActiveGui = nil
            if getgenv().XELIB_ActiveLoading and typeof(getgenv().XELIB_ActiveLoading) == "Instance" then
                getgenv().XELIB_ActiveLoading:Destroy()
            end
            getgenv().XELIB_ActiveLoading = nil
            if getgenv().XELIB_ToggleBtn and typeof(getgenv().XELIB_ToggleBtn) == "Instance" then
                getgenv().XELIB_ToggleBtn:Destroy()
            end
            getgenv().XELIB_ToggleBtn = nil
        end)
    end

    local Window = {}
    setmetatable(Window, {__index = XELIB})
    Window._connections = {}
    Window._effectsRunning = true
    Window._destroyed = false

    local winName = config.Name or "XeNOX Library"
    local subTitle = config.SubTitle or ""
    local hasSettings = config.Setting ~= false
    local hasIntro = config.Intro == true
    local Loading_Text = config.IntroText or "LOADING"
    local Loading_Icon = config.IntroIcon or ""
    local Loading_Speed = math.clamp(tonumber(config.IntroSpeed) or 1, 0.2, 5)
    local iconAsset = config.Icon or ""
    local rainbowMain = config.RainbowMainFrame == true
    local rainbowTitle = config.RainbowTitle == true
    local rainbowSub = config.RainbowSubTitle == true
    local toggleIcon = config.ToggleIcon or ""
    local closeCallback = config.CloseCallback

    local effects = { Rain = false, Trail = false, Blob = false, Matrix = false, Hex = false, Glitch = false }
    local effectColors = {
        Rain = Color3.fromRGB(255,255,255),
        Trail = Color3.fromRGB(0,255,255),
        Blob = Color3.fromRGB(0,20,100),
        Matrix = Color3.fromRGB(0,255,0),
        Hex = Color3.fromRGB(0,255,255),
        Glitch = Color3.fromRGB(255,255,255)
    }
    local theme = {
        Main = DEFAULT_THEME,
        Shade = DEFAULT_SHADE,
        Outline = DEFAULT_OUTLINE,
        Button = DEFAULT_BUTTON,
        ButtonOutline = DEFAULT_BTN_OUTLINE,
        Font = Enum.Font.SourceSansBold,
        FontName = "SourceSansBold",
        FontFace = nil,
    }
    local introBackgroundColor = Color3.fromRGB(0,0,0)
    local introTextColor = Color3.fromRGB(255,255,255)
    local menuKey = Enum.KeyCode.RightControl
    local menuOpen = true
    local isMinimized = false

    local saveId = config.SaveId or config.Name or "XeNOX_Default"
    local autoSave = config.AutoSave ~= false
    local autoLoad = config.AutoLoad == true
    local configFolder = "XeNOX_Configs/" .. tostring(saveId):gsub("[^%w_]", "_")
    local activeConfigName = "default"
    local autoSaveTarget = "default"
    local autoLoadTarget = "default"
    local saveData = {
        toggles={}, sliders={}, dropdowns={}, inputs={}, keybinds={}, colors={},
        theme={}, effects={}, effectColors={}, menuKey=nil,
        _autoSave=nil,_autoLoad=nil,_activeConfigName=nil,_autoSaveTarget=nil,_autoLoadTarget=nil,
        introBackgroundColor=nil,introTextColor=nil, custom={}, glowEnabled=nil, glowColor=nil, glowOpacity=nil
    }

    -- Forward declares for ApplyConfig closure (fix upvalue bug)
    local mainFrame, titleLbl, mainStroke, mainGlow, glowContainer, uiScale, screenGui
    local uiCache = {Shade={}, Button={}, ButtonOutline={}, Text={}}
    local function CacheText(lbl)
        table.insert(uiCache.Text, lbl)
        if theme.FontFace then pcall(function() lbl.FontFace = theme.FontFace end) end
        return lbl
    end
    local function SetGlobalFont(fontName)
        local enumFb, face = ResolveFont(fontName)
        theme.Font = enumFb
        theme.FontFace = face
        theme.FontName = fontName
        saveData.theme.Font = fontName
        for _, v in ipairs(uiCache.Text) do
            if v and v.Parent then
                pcall(function()
                    v.Font = enumFb
                    if face then v.FontFace = face end
                end)
            end
        end
    end
    Window._setGlobalFont = SetGlobalFont
    local tabs = {}
    local tabCount = 0
    local activeNotifs = {}
    local uiRegistry = {toggles={}, sliders={}, dropdowns={}, inputs={}, keybinds={}, colors={}}
    Window._uiRegistry = uiRegistry
    Window._uiCache = uiCache

    local function EnsureFolder()
        if not makefolder then return end
        pcall(function()
            if isfolder and not isfolder("XeNOX_Configs") then makefolder("XeNOX_Configs") end
            if isfolder and not isfolder(configFolder) then makefolder(configFolder) end
        end)
    end
    local function GetConfigPath(name) return configFolder .. "/" .. tostring(name):gsub("[^%w_]", "_") .. ".json" end
    local function ListConfigs()
        local list = {}
        if not (isfolder and isfolder(configFolder) and listfiles) then return list end
        local ok, files = pcall(function() return listfiles(configFolder) end)
        if not ok or type(files) ~= "table" then return list end
        for _, path in ipairs(files) do
            local n = tostring(path):gsub("\\","/"):match("([^/]+)%.json$")
            if n then table.insert(list, n) end
        end
        return list
    end
    local function SaveConfig(name)
        name = name or activeConfigName
        if not writefile then return end
        EnsureFolder()
        local path = GetConfigPath(name)
        local ok, json = pcall(function() return HttpService:JSONEncode(saveData) end)
        if ok and json then pcall(function() writefile(path, json) end) end
    end
    local function LoadConfig(name)
        name = name or activeConfigName
        if not (isfile and readfile) then return nil end
        local path = GetConfigPath(name)
        local exists = false
        pcall(function() exists = isfile(path) end)
        if not exists then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if ok and type(data)=="table" then return data end
        return nil
    end
    local function DeleteConfig(name)
        if not isfile then return false end
        local path = GetConfigPath(name)
        local exists=false
        pcall(function() exists=isfile(path) end)
        if exists then pcall(function() delfile(path) end); return true end
        return false
    end

    local loadedConfig = LoadConfig() or {}
    local glowEnabled = (loadedConfig.glowEnabled == true)
    local glowColor = TableToColor(loadedConfig.glowColor, theme.Main)
    local glowOpacity = (type(loadedConfig.glowOpacity)=="number") and math.clamp(loadedConfig.glowOpacity,0,1) or 0.4

    if type(loadedConfig.effects)=="table" then for k,v in pairs(loadedConfig.effects) do if effects[k]~=nil then effects[k]=v end end end
    if type(loadedConfig.effectColors)=="table" then for k,v in pairs(loadedConfig.effectColors) do effectColors[k]=TableToColor(v, effectColors[k]) or effectColors[k] end end
    if loadedConfig._autoSave ~= nil then autoSave = not not loadedConfig._autoSave end
    if loadedConfig._autoLoad ~= nil then autoLoad = not not loadedConfig._autoLoad end
    if type(loadedConfig.custom)=="table" then saveData.custom = loadedConfig.custom end
    if type(loadedConfig._activeConfigName)=="string" then activeConfigName = loadedConfig._activeConfigName end
    if type(loadedConfig._autoSaveTarget)=="string" then autoSaveTarget = loadedConfig._autoSaveTarget end
    if type(loadedConfig._autoLoadTarget)=="string" then autoLoadTarget = loadedConfig._autoLoadTarget end
    if type(loadedConfig.theme)=="table" then
        for k,v in pairs(loadedConfig.theme) do
            if k=="Font" and type(v)=="string" then
                local ef, ff = ResolveFont(v); theme.Font=ef; theme.FontFace=ff; theme.FontName=v
            elseif theme[k] and type(v)=="table" then theme[k]=TableToColor(v, theme[k]) or theme[k] end
        end
    end
    if type(loadedConfig.menuKey)=="string" then local ok,key=pcall(function() return Enum.KeyCode[loadedConfig.menuKey] end); if ok and key then menuKey=key end end
    if loadedConfig.introBackgroundColor then introBackgroundColor = TableToColor(loadedConfig.introBackgroundColor, introBackgroundColor) or introBackgroundColor end
    if loadedConfig.introTextColor then introTextColor = TableToColor(loadedConfig.introTextColor, introTextColor) or introTextColor end
    saveData.introBackgroundColor = ColorToTable(introBackgroundColor)
    saveData.introTextColor = ColorToTable(introTextColor)
    saveData.glowEnabled = glowEnabled
    saveData.glowColor = ColorToTable(glowColor)
    saveData.glowOpacity = glowOpacity

    Window._loadedConfig = loadedConfig
    Window._saveData = saveData
    Window._saveConfigFunc = SaveConfig
    Window._debounceSave = nil
    Window._configCallbacks = {}

    local function DebouncedSave()
        if not autoSave or Window._destroyed then return end
        saveData._activeConfigName = activeConfigName
        saveData._autoSaveTarget = autoSaveTarget
        saveData._autoLoadTarget = autoLoadTarget
        saveData._autoSave = autoSave
        saveData._autoLoad = autoLoad
        if Window._debounceSave then
            pcall(function() task.cancel(Window._debounceSave) end)
            Window._debounceSave=nil
        end
        Window._debounceSave = task.delay(0.45, function()
            if Window._destroyed then return end
            SaveConfig(autoSaveTarget)
            Window._debounceSave=nil
        end)
    end
    Window._debouncedSave = DebouncedSave

    -- ApplyConfig defined AFTER forwards so upvalues are correct
    local function ApplyConfig(data)
        if type(data)~="table" then return end
        if data.toggles then
            for text, value in pairs(data.toggles) do
                local entry = uiRegistry.toggles[text]
                if entry and entry.bg and entry.bg.Parent then
                    entry.enabled = not not value
                    local targetColor = entry.enabled and theme.Button or theme.Shade
                    SafeTween(entry.bg, ANIM.Normal, {BackgroundColor3 = targetColor})
                    SafeTween(entry.ball, ANIM.Spring, {Position = entry.enabled and UDim2.new(1,-21,0.5,-8) or UDim2.new(0,4,0.5,-8)})
                    if entry.ballGlow then SafeTween(entry.ballGlow, ANIM.Normal, {Color = targetColor}) end
                    if entry.callback then pcall(entry.callback, entry.enabled) end
                end
            end
        end
        if data.sliders then
            for text, value in pairs(data.sliders) do
                local entry = uiRegistry.sliders[text]
                if entry and entry.track and entry.track.Parent and entry.min and entry.max then
                    local v = math.clamp(tonumber(value) or entry.min, entry.min, entry.max)
                    entry.value = v
                    local pos = (entry.max==entry.min) and 0 or (v - entry.min)/(entry.max-entry.min)
                    entry.lb.Text = text .. ": " .. tostring(v)
                    SafeTween(entry.fill, ANIM.Normal, {Size = UDim2.new(pos,0,1,0)})
                    SafeTween(entry.knob, ANIM.Normal, {Position = UDim2.new(pos,-7,0.5,-7)})
                    if entry.callback then pcall(entry.callback, v) end
                end
            end
        end
        if data.dropdowns then
            for text, value in pairs(data.dropdowns) do
                local entry = uiRegistry.dropdowns[text]
                if entry and entry.btn and entry.btn.Parent then
                    entry.selected = tostring(value)
                    entry.btn.Text = entry.selected
                    if entry.callback then pcall(entry.callback, entry.selected) end
                end
            end
        end
        if data.inputs then
            for text, value in pairs(data.inputs) do
                local entry = uiRegistry.inputs[text]
                if entry and entry.box and entry.box.Parent then
                    entry.box.Text = tostring(value)
                    if entry.callback then pcall(entry.callback, tostring(value)) end
                end
            end
        end
        if data.keybinds then
            for text, keyName in pairs(data.keybinds) do
                local entry = uiRegistry.keybinds[text]
                if entry and entry.btn and entry.btn.Parent and type(keyName)=="string" then
                    local ok,key=pcall(function() return Enum.KeyCode[keyName] end)
                    if ok and key then entry.currentKey=key; entry.btn.Text=key.Name; if entry.callback then pcall(entry.callback, key) end end
                end
            end
        end
        if data.colors then
            for text, cData in pairs(data.colors) do
                local entry = uiRegistry.colors[text]
                if entry and entry.preview and entry.preview.Parent and type(cData)=="table" and cData.R then
                    local c = Color3.fromRGB(ClampRGB(cData.R), ClampRGB(cData.G), ClampRGB(cData.B))
                    entry.preview.BackgroundColor3 = c
                    entry.curH, entry.curS, entry.curV = c:ToHSV()
                    if entry.update then pcall(entry.update) end
                    if entry.callback then pcall(entry.callback, c) end
                end
            end
        end
        if type(data.effects)=="table" then for k,v in pairs(data.effects) do if effects[k]~=nil then effects[k]=not not v end end end
        if type(data.effectColors)=="table" then for k,v in pairs(data.effectColors) do if effectColors[k] and type(v)=="table" then effectColors[k]=TableToColor(v, effectColors[k]) or effectColors[k] end end end
        if type(data.theme)=="table" then
            for k,v in pairs(data.theme) do
                if k=="Font" and type(v)=="string" then
                    local ef, ff = ResolveFont(v); theme.Font=ef; theme.FontFace=ff; theme.FontName=v
                    for _,lbl in ipairs(uiCache.Text) do if lbl and lbl.Parent then pcall(function() lbl.Font=ef; if ff then lbl.FontFace=ff end end) end end
                elseif theme[k] and type(v)=="table" then theme[k]=TableToColor(v, theme[k]) or theme[k] end
            end
            if mainFrame and mainFrame.Parent then SafeTween(mainFrame, ANIM.Normal, {BackgroundColor3 = theme.Main}) end
            if titleLbl and titleLbl.Parent then titleLbl.TextColor3 = GetContrastColor(theme.Main) end
            if mainStroke and mainStroke.Parent then SafeTween(mainStroke, ANIM.Normal, {Color = theme.Outline}) end
            for _,v in ipairs(uiCache.Shade) do if v and v.Parent then SafeTween(v, ANIM.Normal, {BackgroundColor3 = theme.Shade}) end end
            for _,v in ipairs(uiCache.Button) do if v and v.Parent then SafeTween(v, ANIM.Normal, {BackgroundColor3 = theme.Button}) end end
            for _,v in ipairs(uiCache.ButtonOutline) do if v and v.Parent then SafeTween(v, ANIM.Normal, {Color = theme.ButtonOutline}) end end
        end
        if type(data.menuKey)=="string" then local ok,key=pcall(function() return Enum.KeyCode[data.menuKey] end); if ok and key then menuKey=key end end
        if data._autoSave~=nil then autoSave = not not data._autoSave end
        if data._autoLoad~=nil then autoLoad = not not data._autoLoad end
        if type(data._activeConfigName)=="string" then activeConfigName=data._activeConfigName end
        if type(data._autoSaveTarget)=="string" then autoSaveTarget=data._autoSaveTarget end
        if type(data._autoLoadTarget)=="string" then autoLoadTarget=data._autoLoadTarget end
        if data.glowEnabled~=nil then glowEnabled = not not data.glowEnabled; if mainGlow and mainGlow.Parent then SafeTween(mainGlow, ANIM.Normal, {ImageTransparency = glowEnabled and (1-glowOpacity) or 1}) end end
        if data.glowColor and type(data.glowColor)=="table" then glowColor = TableToColor(data.glowColor, glowColor) or glowColor; if mainGlow and mainGlow.Parent then SafeTween(mainGlow, ANIM.Normal, {ImageColor3 = glowColor}) end end
        if type(data.glowOpacity)=="number" then glowOpacity=math.clamp(data.glowOpacity,0,1); if mainGlow and mainGlow.Parent then SafeTween(mainGlow, ANIM.Normal, {ImageTransparency = glowEnabled and (1-glowOpacity) or 1}) end end
        if data.introBackgroundColor and type(data.introBackgroundColor)=="table" then introBackgroundColor = TableToColor(data.introBackgroundColor, introBackgroundColor) or introBackgroundColor; saveData.introBackgroundColor = ColorToTable(introBackgroundColor) end
        if data.introTextColor and type(data.introTextColor)=="table" then introTextColor = TableToColor(data.introTextColor, introTextColor) or introTextColor; saveData.introTextColor = ColorToTable(introTextColor) end
        if type(data.custom)=="table" then saveData.custom=data.custom; for _,cb in ipairs(Window._configCallbacks or {}) do pcall(cb, data.custom) end end
        -- persist glow/intro for next save
        saveData.glowEnabled = glowEnabled
        saveData.glowColor = ColorToTable(glowColor)
        saveData.glowOpacity = glowOpacity
    end
    Window._applyConfig = ApplyConfig

    -- Create ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = RandomString(16)
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    local parent = GetSafeParent()
    pcall(function() screenGui.Parent = parent end)
    if not screenGui.Parent then
        screenGui.Parent = PlayerGui or CoreGui
    end
    if getgenv then getgenv().XELIB_ActiveGui = screenGui end

    -- Intro
    if hasIntro then
        local Loading_Screen = Instance.new("ScreenGui")
        Loading_Screen.Name = RandomString(12)
        Loading_Screen.ResetOnSpawn = false
        Loading_Screen.IgnoreGuiInset = true
        Loading_Screen.DisplayOrder = 20
        pcall(function() Loading_Screen.Parent = GetSafeParent() end)
        if getgenv then getgenv().XELIB_ActiveLoading = Loading_Screen end
        local Loading_Frame = Instance.new("Frame")
        Loading_Frame.Size = UDim2.new(1,0,1,0)
        Loading_Frame.BackgroundColor3 = introBackgroundColor
        Loading_Frame.BackgroundTransparency = 1
        Loading_Frame.Parent = Loading_Screen
        Instance.new("UICorner", Loading_Frame).CornerRadius = UDim.new(0,0)
        local Loading_Stroke = Instance.new("UIStroke", Loading_Frame)
        Loading_Stroke.Thickness = 2
        Loading_Stroke.Color = introTextColor
        Loading_Stroke.Transparency = 1
        local rainbowFlag = {stop=false}
        if rainbowMain then RainbowStroke(Loading_Stroke, rainbowFlag) end
        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0,0,0,0)
        iconImg.Position = UDim2.new(0.5,0,0.4,0)
        iconImg.AnchorPoint = Vector2.new(0.5,0.5)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = Loading_Icon
        iconImg.ImageTransparency = 1
        iconImg.Parent = Loading_Frame
        local lTitle = Instance.new("TextLabel")
        lTitle.Size = UDim2.new(1,0,0,40)
        lTitle.Position = UDim2.new(0,0,0.55,0)
        lTitle.BackgroundTransparency = 1
        lTitle.Text = Loading_Text
        lTitle.TextColor3 = introTextColor
        lTitle.Font = Enum.Font.LuckiestGuy
        lTitle.TextSize = 22
        lTitle.TextTransparency = 1
        lTitle.Parent = Loading_Frame
        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(0,0,0,6)
        barBg.Position = UDim2.new(0.5,0,0.7,0)
        barBg.AnchorPoint = Vector2.new(0.5,0.5)
        barBg.BackgroundColor3 = Color3.fromRGB(40,40,50)
        barBg.BackgroundTransparency = 1
        barBg.Parent = Loading_Frame
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)
        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(0,0,1,0)
        barFill.BackgroundColor3 = introTextColor
        barFill.BackgroundTransparency = 1
        barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)
        SafeTween(Loading_Frame, ANIM.Slow, {BackgroundTransparency=0})
        task.wait(0.1)
        SafeTween(iconImg, ANIM.Bounce, {Size=UDim2.new(0,80,0,80), Position=UDim2.new(0.5,-40,0.4,-40), ImageTransparency=0})
        task.wait(0.15)
        SafeTween(lTitle, ANIM.Smooth, {TextTransparency=0})
        task.wait(0.2)
        SafeTween(barBg, ANIM.Smooth, {Size=UDim2.new(0,200,0,6), BackgroundTransparency=0})
        task.wait(0.15)
        SafeTween(barFill, TweenInfo.new(Loading_Speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,1,0), BackgroundTransparency=0})
        task.wait(Loading_Speed + 0.25)
        SafeTween(barFill, ANIM.Fast, {BackgroundTransparency=1})
        SafeTween(barBg, ANIM.Fast, {BackgroundTransparency=1})
        SafeTween(lTitle, ANIM.Fast, {TextTransparency=1})
        SafeTween(iconImg, ANIM.Fast, {ImageTransparency=1, Size=UDim2.new(0,100,0,100)})
        task.wait(0.2)
        SafeTween(Loading_Frame, ANIM.Slow, {BackgroundTransparency=1})
        task.wait(0.35)
        rainbowFlag.stop=true
        pcall(function() Loading_Screen:Destroy() end)
        if getgenv then getgenv().XELIB_ActiveLoading=nil end
    end

    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = RandomString(16)
    mainFrame.Size = UDim2.new(0,700,0,500)
    mainFrame.Position = UDim2.new(0.5,-350,0.5,-250)
    mainFrame.BackgroundColor3 = theme.Main
    mainFrame.BackgroundTransparency = 1
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    glowContainer = Instance.new("Frame")
    glowContainer.Name = "GlowContainer"
    glowContainer.Size = mainFrame.Size
    glowContainer.Position = mainFrame.Position
    glowContainer.BackgroundTransparency = 1
    glowContainer.ZIndex = 0
    glowContainer.Visible = mainFrame.Visible
    glowContainer.Parent = screenGui
    mainGlow = Instance.new("ImageLabel")
    mainGlow.Name = "WindowGlow"
    mainGlow.Size = UDim2.new(1,40,1,40)
    mainGlow.Position = UDim2.new(0,-20,0,-20)
    mainGlow.BackgroundTransparency = 1
    mainGlow.Image = "rbxassetid://5028857084"
    mainGlow.ImageColor3 = glowColor
    mainGlow.ImageTransparency = glowEnabled and (1-glowOpacity) or 1
    mainGlow.ZIndex = 0
    mainGlow.Parent = glowContainer

    local function syncGlow()
        if glowContainer and glowContainer.Parent and mainFrame.Parent then
            glowContainer.Position = mainFrame.Position
            glowContainer.Size = mainFrame.Size
            glowContainer.Visible = mainFrame.Visible
        end
    end
    local cPos = mainFrame:GetPropertyChangedSignal("Position"):Connect(syncGlow)
    local cSize = mainFrame:GetPropertyChangedSignal("Size"):Connect(syncGlow)
    local cVis = mainFrame:GetPropertyChangedSignal("Visible"):Connect(syncGlow)
    table.insert(Window._connections, cPos); table.insert(Window._connections, cSize); table.insert(Window._connections, cVis)

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,6)
    local savedPos = mainFrame.Position
    local savedSize = mainFrame.Size
    -- keep savedPos updated when dragged and not minimized
    local dragTrackConn = mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        if not isMinimized then savedPos = mainFrame.Position end
    end)
    table.insert(Window._connections, dragTrackConn)

    uiScale = Instance.new("UIScale")
    uiScale.Parent = mainFrame
    uiScale.Scale = 0.7
    mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 0
    mainStroke.Color = theme.Outline
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    local mainRainbowFlag = {stop=false}
    if rainbowMain then RainbowStroke(mainStroke, mainRainbowFlag); table.insert(Window._connections, {Disconnect=function() mainRainbowFlag.stop=true end}) end
    SafeTween(mainFrame, ANIM.Smooth, {BackgroundTransparency=0.04})
    SafeTween(mainStroke, ANIM.Smooth, {Thickness=1})
    SafeTween(uiScale, ANIM.Smooth, {Scale=1})

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,45)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 5
    titleBar.Active = true
    titleBar.Parent = mainFrame

    titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-120,0,25)
    titleLbl.Position = UDim2.new(0,15,0,5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = winName
    titleLbl.TextColor3 = GetContrastColor(theme.Main)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 5
    titleLbl.Parent = titleBar
    titleLbl.TextTransparency = 1
    SafeTween(titleLbl, ANIM.Smooth, {TextTransparency=0})
    if rainbowTitle then local f={stop=false}; local s=Instance.new("UIStroke", titleLbl); s.Thickness=1; RainbowStroke(s,f); table.insert(Window._connections,{Disconnect=function() f.stop=true end}) end
    if subTitle ~= "" then
        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1,-120,0,18)
        subLbl.Position = UDim2.new(0,15,0,28)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = subTitle
        subLbl.TextColor3 = GetContrastColor(theme.Main)
        subLbl.Font = theme.Font
        subLbl.TextSize = 12
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.ZIndex = 5
        subLbl.Parent = titleBar
        subLbl.TextTransparency = 1
        SafeTween(subLbl, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {TextTransparency=0})
        if rainbowSub then local f={stop=false}; local s=Instance.new("UIStroke", subLbl); s.Thickness=1; RainbowStroke(s,f); table.insert(Window._connections,{Disconnect=function() f.stop=true end}) end
    end
    if iconAsset ~= "" then
        local winIcon = Instance.new("ImageLabel")
        winIcon.Size = UDim2.new(0,0,0,0)
        winIcon.Position = UDim2.new(1,-80,0,10)
        winIcon.BackgroundTransparency = 1
        winIcon.Image = iconAsset
        winIcon.ZIndex = 5
        winIcon.Parent = titleBar
        SafeTween(winIcon, ANIM.Bounce, {Size=UDim2.new(0,24,0,24)})
    end

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0,30,0,30)
    minimizeBtn.Position = UDim2.new(1,-40,0,8)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = GetContrastColor(theme.Main)
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.ZIndex = 20
    minimizeBtn.Active = true
    minimizeBtn.Parent = titleBar
    minimizeBtn.TextTransparency = 1
    SafeTween(minimizeBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency=0})
    local destroyBtn = Instance.new("TextButton")
    destroyBtn.Name = "CloseBtn"
    destroyBtn.Size = UDim2.new(0,30,0,30)
    destroyBtn.Position = UDim2.new(1,-70,0,8)
    destroyBtn.BackgroundTransparency = 1
    destroyBtn.Text = "X"
    destroyBtn.TextColor3 = Color3.fromRGB(255,80,80)
    destroyBtn.TextSize = 14
    destroyBtn.Font = Enum.Font.SourceSansBold
    destroyBtn.ZIndex = 20
    destroyBtn.Active = true
    destroyBtn.Parent = titleBar
    destroyBtn.TextTransparency = 1
    SafeTween(destroyBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency=0})

    minimizeBtn.MouseEnter:Connect(function() SafeTween(minimizeBtn, ANIM.Fast, {TextSize=22}) end)
    minimizeBtn.MouseLeave:Connect(function() SafeTween(minimizeBtn, ANIM.Fast, {TextColor3=GetContrastColor(theme.Main), TextSize=20}) end)
    destroyBtn.MouseEnter:Connect(function() SafeTween(destroyBtn, ANIM.Fast, {TextColor3=Color3.fromRGB(255,50,50), TextSize=16}) end)
    destroyBtn.MouseLeave:Connect(function() SafeTween(destroyBtn, ANIM.Fast, {TextColor3=Color3.fromRGB(255,80,80), TextSize=14}) end)

    local function DoDestroy()
        if Window._destroyed then return end
        Window._destroyed = true
        Window._effectsRunning = false
        mainRainbowFlag.stop=true
        for _, conn in ipairs(Window._connections) do pcall(function() conn:Disconnect() end) end
        SafeTween(mainFrame, ANIM.Smooth, {BackgroundTransparency=1})
        SafeTween(uiScale, ANIM.FadeOut, {Scale=0.8})
        SafeTween(mainStroke, ANIM.FadeOut, {Transparency=1})
        task.delay(0.3, function()
            if type(closeCallback)=="function" then pcall(closeCallback) end
            if getgenv then getgenv().XELIB_ActiveGui=nil; getgenv().XELIB_ToggleBtn=nil end
            pcall(function() if glowContainer and glowContainer.Parent then glowContainer:Destroy() end end)
            pcall(function() if screenGui and screenGui.Parent then screenGui:Destroy() end end)
        end)
    end
    Window.Destroy = DoDestroy
    Window.Close = DoDestroy
    destroyBtn.MouseButton1Click:Connect(DoDestroy)
    MakeDraggable(mainFrame, titleBar, Window._connections)

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0,150,1,-55)
    tabContainer.Position = UDim2.new(0,-160,0,50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0,8)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Parent = tabContainer
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1,-180,1,-60)
    contentFrame.Position = UDim2.new(0,170,0,50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    contentFrame.ClipsDescendants = false -- allow dropdown overflow

    SafeTween(tabContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.2), {Position=UDim2.new(0,10,0,50)})
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            savedPos = mainFrame.Position
            savedSize = mainFrame.Size
            minimizeBtn.Text = "+"
            if glowContainer then glowContainer.Visible=false end
            SafeTween(tabContainer, ANIM.Slide, {Position=UDim2.new(0,-160,0,50)})
            SafeTween(contentFrame, ANIM.FadeOut, {Position=UDim2.new(0,300,0,50)})
            task.delay(0.15, function() tabContainer.Visible=false; contentFrame.Visible=false end)
            SafeTween(mainFrame, ANIM.Smooth, {Size=UDim2.new(0,700,0,45), Position=UDim2.new(0.5,-350,0.5,-22)})
        else
            tabContainer.Visible=true; contentFrame.Visible=true; minimizeBtn.Text="-"
            if glowContainer then glowContainer.Visible=true end
            SafeTween(mainFrame, ANIM.Smooth, {Size=savedSize, Position=savedPos})
            SafeTween(tabContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.2), {Position=UDim2.new(0,10,0,50)})
            SafeTween(contentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.25), {Position=UDim2.new(0,170,0,50)})
        end
    end)

    local notifContainer = Instance.new("Frame")
    notifContainer.Size = UDim2.new(0,280,1,-20)
    notifContainer.Position = UDim2.new(1,-300,0,10)
    notifContainer.BackgroundTransparency = 1
    notifContainer.ZIndex = 100
    notifContainer.Parent = screenGui
    local notifList = Instance.new("UIListLayout")
    notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifList.Padding = UDim.new(0,10)
    notifList.Parent = notifContainer

    if UserInputService.TouchEnabled or UserInputService.GamepadEnabled or config._forceToggle then
        local toggleBtn = Instance.new("ImageButton")
        toggleBtn.Size = UDim2.new(0,0,0,0)
        toggleBtn.Position = UDim2.new(0,40,0,40)
        toggleBtn.AnchorPoint = Vector2.new(0.5,0.5)
        toggleBtn.BackgroundColor3 = theme.Shade
        toggleBtn.Image = toggleIcon ~= "" and toggleIcon or ""
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.ZIndex = 50
        toggleBtn.Parent = screenGui
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)
        local tStroke = Instance.new("UIStroke", toggleBtn); tStroke.Color=theme.Outline; tStroke.Thickness=2
        SafeTween(toggleBtn, ANIM.Spring, {Size=UDim2.new(0,40,0,40), Position=UDim2.new(0,20,0,20)})
        toggleBtn.MouseButton1Click:Connect(function()
            menuOpen = not menuOpen
            if menuOpen then
                mainFrame.Visible=true; if glowContainer then glowContainer.Visible=true end; uiScale.Scale=0.8
                SafeTween(uiScale, ANIM.Bounce, {Scale=1}); SafeTween(mainFrame, ANIM.Smooth, {BackgroundTransparency=0.04}); SafeTween(toggleBtn, ANIM.Fast, {Rotation=0})
            else
                SafeTween(uiScale, ANIM.FadeOut, {Scale=0.8}); SafeTween(mainFrame, ANIM.FadeOut, {BackgroundTransparency=1}); SafeTween(toggleBtn, ANIM.Fast, {Rotation=180})
                task.delay(0.25, function() if not menuOpen then mainFrame.Visible=false; if glowContainer then glowContainer.Visible=false end end end)
            end
        end)
        if getgenv then getgenv().XELIB_ToggleBtn = toggleBtn end
    end

    local menuToggleConn = UserInputService.InputBegan:Connect(function(input,gpe)
        if not gpe and input.KeyCode==menuKey then
            menuOpen = not menuOpen
            if menuOpen then
                mainFrame.Visible=true; if glowContainer then glowContainer.Visible=true end; uiScale.Scale=0.8; SafeTween(uiScale, ANIM.Bounce, {Scale=1}); SafeTween(mainFrame, ANIM.Smooth, {BackgroundTransparency=0.04})
            else
                SafeTween(uiScale, ANIM.FadeOut, {Scale=0.8}); SafeTween(mainFrame, ANIM.FadeOut, {BackgroundTransparency=1})
                task.delay(0.25, function() if not menuOpen then mainFrame.Visible=false; if glowContainer then glowContainer.Visible=false end end end)
            end
        end
    end)
    table.insert(Window._connections, menuToggleConn)

    -- Effects loop (throttled)
    task.spawn(function()
        local lastBlob = 0
        while task.wait(0.03) do
            if Window._destroyed or not Window._effectsRunning then break end
            if not screenGui.Parent or not mainFrame.Parent then break end
            if not mainFrame.Visible then task.wait(0.2); continue end
            local any=false; for _,v in pairs(effects) do if v then any=true break end end
            if not any then task.wait(0.2); continue end
            local mLoc = UserInputService:GetMouseLocation()
            if effects.Rain then
                local star=GetFromPool("Star","Frame")
                star.Size=UDim2.new(0,1,0,RNG:NextInteger(30,80)); star.Position=UDim2.new(RNG:NextNumber(0,1),0,-0.2,0)
                star.BackgroundColor3=effectColors.Rain; star.BackgroundTransparency=0; star.ZIndex=1; star.BorderSizePixel=0; star.Parent=mainFrame
                SafeTween(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position=UDim2.new(star.Position.X.Scale,0,1.2,0), BackgroundTransparency=1})
                task.delay(0.62, function() ReturnToPool("Star", star) end)
            end
            if effects.Trail then
                local trail=GetFromPool("Trail","Frame")
                local corner=trail:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", trail); corner.CornerRadius=UDim.new(1,0)
                trail.Size=UDim2.new(0,10,0,10); trail.Position=UDim2.new(0, mLoc.X - mainFrame.AbsolutePosition.X -5, 0, mLoc.Y - mainFrame.AbsolutePosition.Y -5)
                trail.BackgroundColor3=effectColors.Trail; trail.BackgroundTransparency=0.3; trail.ZIndex=2; trail.BorderSizePixel=0; trail.Parent=mainFrame
                SafeTween(trail, TweenInfo.new(0.4), {BackgroundTransparency=1, Size=UDim2.new(0,0,0,0)})
                task.delay(0.42, function() ReturnToPool("Trail", trail) end)
            end
            if effects.Matrix and RNG:NextInteger(1,5)==1 then
                local char=GetFromPool("Matrix","TextLabel")
                char.Size=UDim2.new(0,20,0,20); char.Position=UDim2.new(RNG:NextNumber(0,1),0,-0.1,0)
                char.BackgroundTransparency=1; char.Text=string.char(RNG:NextInteger(33,126)); char.TextColor3=effectColors.Matrix; char.Font=Enum.Font.Code; char.TextSize=13; char.TextTransparency=0; char.ZIndex=1; char.Parent=mainFrame
                SafeTween(char, TweenInfo.new(RNG:NextInteger(1,3), Enum.EasingStyle.Linear), {Position=UDim2.new(char.Position.X.Scale,0,1.1,0), TextTransparency=1})
                task.delay(3.1, function() ReturnToPool("Matrix", char) end)
            end
            if effects.Hex and RNG:NextInteger(1,15)==1 then
                local hex=GetFromPool("Hex","ImageLabel")
                hex.Size=UDim2.new(0,0,0,0); hex.Position=UDim2.new(RNG:NextNumber(0,1),0,RNG:NextNumber(0,1),0)
                hex.Image="rbxassetid://6073628820"; hex.ImageColor3=effectColors.Hex; hex.BackgroundTransparency=1; hex.ImageTransparency=0; hex.Rotation=0; hex.ZIndex=1; hex.Parent=mainFrame
                local sz=RNG:NextInteger(50,150); SafeTween(hex, TweenInfo.new(2), {Size=UDim2.new(0,sz,0,sz), ImageTransparency=1, Rotation=180})
                task.delay(2.05, function() ReturnToPool("Hex", hex) end)
            end
            if effects.Glitch and RNG:NextInteger(1,10)==1 then
                local g=GetFromPool("Glitch","Frame")
                g.Size=UDim2.new(0,RNG:NextInteger(20,100),0,2); g.Position=UDim2.new(RNG:NextNumber(0,1),0,RNG:NextNumber(0,1),0)
                g.BackgroundColor3=effectColors.Glitch; g.BackgroundTransparency=0.5; g.BorderSizePixel=0; g.ZIndex=1; g.Parent=mainFrame
                task.spawn(function() for i=1,3 do if not g or not g.Parent then break end; g.BackgroundTransparency = (i%2==0 and 0.5 or 1); task.wait(0.03) end end)
                task.delay(0.12, function() ReturnToPool("Glitch", g) end)
            end
            if effects.Blob and os.clock() - lastBlob > 0.12 then
                lastBlob = os.clock()
                local blob=GetFromPool("Blob","ImageLabel")
                blob.Size=UDim2.new(RNG:NextInteger(2,5)/10,0,RNG:NextInteger(2,5)/10,0); blob.Position=UDim2.new(RNG:NextNumber(-0.1,0.9),0,RNG:NextNumber(-0.1,0.9),0)
                blob.Image="rbxassetid://232918622"; blob.ImageColor3=effectColors.Blob; blob.BackgroundTransparency=1; blob.ImageTransparency=0.93; blob.ZIndex=1; blob.Parent=mainFrame
                task.spawn(function()
                    local start=os.clock()
                    while os.clock()-start < 2.5 do
                        if Window._destroyed or not blob or not blob.Parent or not effects.Blob then break end
                        local cur = UserInputService:GetMouseLocation()
                        local center = blob.AbsolutePosition + blob.AbsoluteSize/2
                        local diff = center - cur
                        if diff.Magnitude < 260 and diff.Magnitude > 2 then
                            local push = diff.Unit * (1 - diff.Magnitude/260) * 8 -- pixels
                            -- convert push (pixels) to scale+offset: we use offset only
                            blob.Position = UDim2.new(blob.Position.X.Scale, blob.Position.X.Offset + push.X*0.45, blob.Position.Y.Scale, blob.Position.Y.Offset + push.Y*0.45)
                        end
                        task.wait()
                    end
                    ReturnToPool("Blob", blob)
                end)
            end
        end
    end)

    local function StyleButton(btn)
        if not btn then return end
        btn.BackgroundColor3 = theme.Button
        btn.TextColor3 = Color3.new(0,0,0)
        btn.Font = theme.Font
        pcall(function() Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6) end)
        local stroke = Instance.new("UIStroke")
        stroke.Color = theme.ButtonOutline; stroke.Thickness=1; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=btn
        table.insert(uiCache.ButtonOutline, stroke); table.insert(uiCache.Button, btn); CacheText( btn)
        local baseSize = btn.Size
        btn.MouseEnter:Connect(function() SafeTween(btn, ANIM.Fast, {BackgroundTransparency=0.15}); SafeTween(stroke, ANIM.Fast, {Thickness=2}) end)
        btn.MouseLeave:Connect(function() SafeTween(btn, ANIM.Fast, {BackgroundTransparency=0}); SafeTween(stroke, ANIM.Fast, {Thickness=1}) end)
    end

    function Window:Notify(titleText, descText, duration)
        duration = math.clamp(tonumber(duration) or 3, 1, 10)
        if #activeNotifs >= 4 then
            local oldest=table.remove(activeNotifs,1)
            if oldest and oldest.Parent then
                SafeTween(oldest, ANIM.FadeOut, {Position=UDim2.new(1,50,0,0), BackgroundTransparency=1})
                for _,child in ipairs(oldest:GetDescendants()) do if child:IsA("TextLabel") then SafeTween(child, ANIM.Fast, {TextTransparency=1}) elseif child:IsA("UIStroke") then SafeTween(child, ANIM.Fast, {Transparency=1}) end end
                task.delay(0.3, function() pcall(function() if oldest and oldest.Parent then oldest:Destroy() end end) end)
            end
        end
        local notif=Instance.new("Frame")
        notif.Size=UDim2.new(1,0,0,0); notif.BackgroundColor3=theme.Shade; notif.BackgroundTransparency=1; notif.Position=UDim2.new(1,50,0,0); notif.ZIndex=105
        Instance.new("UICorner", notif).CornerRadius=UDim.new(0,8)
        local stroke=Instance.new("UIStroke", notif); stroke.Color=theme.Outline; stroke.Thickness=2; stroke.Transparency=1
        local tLbl=Instance.new("TextLabel", notif); tLbl.Size=UDim2.new(1,-20,0,25); tLbl.Position=UDim2.new(0,10,0,5); tLbl.BackgroundTransparency=1; tLbl.Text=tostring(titleText); tLbl.TextColor3=theme.Main; tLbl.TextXAlignment=Enum.TextXAlignment.Left; tLbl.Font=theme.Font; tLbl.TextSize=14; tLbl.TextTransparency=1; tLbl.ZIndex=106
        local dLbl=Instance.new("TextLabel", notif); dLbl.Size=UDim2.new(1,-20,0,25); dLbl.Position=UDim2.new(0,10,0,30); dLbl.BackgroundTransparency=1; dLbl.Text=tostring(descText); dLbl.TextColor3=Color3.new(1,1,1); dLbl.TextXAlignment=Enum.TextXAlignment.Left; dLbl.Font=theme.Font; dLbl.TextSize=12; dLbl.TextTransparency=1; dLbl.ZIndex=106
        local progressBar=Instance.new("Frame"); progressBar.Size=UDim2.new(1,0,0,3); progressBar.Position=UDim2.new(0,0,1,-3); progressBar.BackgroundColor3=theme.Main; progressBar.BorderSizePixel=0; progressBar.ZIndex=107; progressBar.Parent=notif; progressBar.BackgroundTransparency=1
        notif.Parent=notifContainer; table.insert(activeNotifs, notif)
        SafeTween(notif, ANIM.Bounce, {Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,65), BackgroundTransparency=0.08})
        SafeTween(stroke, ANIM.Smooth, {Transparency=0}); SafeTween(tLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency=0}); SafeTween(dLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency=0})
        task.delay(0.2, function() if progressBar.Parent then SafeTween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,3)}) end end)
        SafeTween(progressBar, TweenInfo.new(0.15), {BackgroundTransparency=0})
        task.delay(duration, function()
            if not notif or not notif.Parent then return end
            for i,v in ipairs(activeNotifs) do if v==notif then table.remove(activeNotifs,i) break end end
            SafeTween(notif, ANIM.FadeOut, {Position=UDim2.new(1,50,0,0), BackgroundTransparency=1, Size=UDim2.new(1,0,0,0)})
            SafeTween(stroke, ANIM.Fast, {Transparency=1}); SafeTween(tLbl, ANIM.Fast, {TextTransparency=1}); SafeTween(dLbl, ANIM.Fast, {TextTransparency=1}); SafeTween(progressBar, ANIM.Fast, {BackgroundTransparency=1})
            task.delay(0.5, function() pcall(function() if notif and notif.Parent then notif:Destroy() end end) end)
        end)
    end

    function Window:AddTab(name)
        if type(name)~="string" or name=="" then name="Tab"..tostring(tabCount+1) end
        tabCount+=1
        local tabID=tabCount
        local tabBtn=Instance.new("TextButton")
        tabBtn.Name=name.."_Tab"
        tabBtn.Size=UDim2.new(1,0,0,0)
        tabBtn.BackgroundColor3=theme.Button
        tabBtn.Text=name
        tabBtn.TextColor3=Color3.new(1,1,1)
        tabBtn.Font=theme.Font
        tabBtn.TextSize=13
        tabBtn.LayoutOrder=tabID
        tabBtn.Parent=tabContainer
        tabBtn.TextTransparency=1
        tabBtn.AutoButtonColor=false
        Instance.new("UICorner", tabBtn).CornerRadius=UDim.new(0,8)
        table.insert(uiCache.Button, tabBtn); CacheText( tabBtn)
        local btnStroke=Instance.new("UIStroke", tabBtn); btnStroke.Color=theme.ButtonOutline; btnStroke.Thickness=1; table.insert(uiCache.ButtonOutline, btnStroke)
        SafeTween(tabBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.05*tabID), {Size=UDim2.new(1,0,0,40), TextTransparency=0})
        tabBtn.MouseEnter:Connect(function() if tabs[tabID] and tabs[tabID].Page and not tabs[tabID].Page.Visible then SafeTween(tabBtn, ANIM.Fast, {BackgroundTransparency=0.15}); SafeTween(btnStroke, ANIM.Fast, {Thickness=2}) end end)
        tabBtn.MouseLeave:Connect(function() if tabs[tabID] and tabs[tabID].Page and not tabs[tabID].Page.Visible then SafeTween(tabBtn, ANIM.Fast, {BackgroundTransparency=0}); SafeTween(btnStroke, ANIM.Fast, {Thickness=1}) end end)

        local page=Instance.new("ScrollingFrame")
        page.Name=name.."_Page"
        page.Size=UDim2.new(1,0,1,0)
        page.BackgroundTransparency=1
        page.ScrollBarThickness=3
        page.ScrollBarImageColor3=theme.Main
        page.Visible=(tabID==1)
        page.Parent=contentFrame
        page.CanvasSize=UDim2.new(0,0,0,0)
        page.ScrollingDirection=Enum.ScrollingDirection.Y
        page.ClipsDescendants=true
        page.AutomaticCanvasSize=Enum.AutomaticSize.None
        local layout=Instance.new("UIListLayout", page)
        layout.Padding=UDim.new(0,10)
        layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
        layout.SortOrder=Enum.SortOrder.LayoutOrder
        local pad=Instance.new("UIPadding", page); pad.PaddingTop=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,10)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize=UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 18) end)

        local searchFrame=Instance.new("Frame")
        searchFrame.Size=UDim2.new(1,-20,0,0)
        searchFrame.BackgroundColor3=theme.Shade
        searchFrame.BackgroundTransparency=0.5
        searchFrame.LayoutOrder=-9999
        searchFrame.Parent=page
        Instance.new("UICorner", searchFrame).CornerRadius=UDim.new(0,8)
        table.insert(uiCache.Shade, searchFrame)
        local searchIcon=Instance.new("TextLabel"); searchIcon.Size=UDim2.new(0,30,0,30); searchIcon.Position=UDim2.new(0,8,0.5,-15); searchIcon.BackgroundTransparency=1; searchIcon.Text="🔍"; searchIcon.TextSize=14; searchIcon.Font=Enum.Font.SourceSansBold; searchIcon.TextColor3=Color3.new(1,1,1); searchIcon.Parent=searchFrame
        local searchBox=Instance.new("TextBox"); searchBox.Size=UDim2.new(1,-50,0,30); searchBox.Position=UDim2.new(0,40,0.5,-15); searchBox.BackgroundTransparency=1; searchBox.Text=""; searchBox.PlaceholderText="Search..."; searchBox.TextColor3=Color3.new(1,1,1); searchBox.PlaceholderColor3=Color3.fromRGB(150,150,150); searchBox.Font=theme.Font; searchBox.TextSize=13; searchBox.ClearTextOnFocus=false; searchBox.Parent=searchFrame
        SafeTween(searchFrame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,44)})
        local tabElements={}

        tabs[tabID]={Page=page, Btn=tabBtn}
        tabBtn.MouseButton1Click:Connect(function()
            for _,v in pairs(tabs) do
                if v.Page.Visible then SafeTween(v.Page, ANIM.Fast, {Position=UDim2.new(-0.05,0,0,0)}); task.delay(0.12, function() if not Window._destroyed then v.Page.Visible=false; v.Page.Position=UDim2.new(0,0,0,0) end end) end
                SafeTween(v.Btn, ANIM.Fast, {BackgroundColor3=theme.Button})
            end
            page.Visible=true; page.Position=UDim2.new(0.08,0,0,0); SafeTween(page, ANIM.Smooth, {Position=UDim2.new(0,0,0,0)})
            SafeTween(tabBtn, ANIM.Spring, {BackgroundColor3=Color3.fromRGB(200,200,200)})
        end)
        if tabID==1 then tabBtn.BackgroundColor3=Color3.fromRGB(200,200,200) end

        local Tab={}
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query=searchBox.Text:lower()
            for _, entry in ipairs(tabElements) do if entry.frame and entry.frame.Parent then entry.frame.Visible = (query=="" or entry.searchText:lower():find(query,1,true)~=nil) end end
            task.defer(function() if layout and page.Parent then page.CanvasSize=UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 18) end end)
        end)

        function Tab:AddLabel(text)
            local l=Instance.new("TextLabel")
            l.Size=UDim2.new(1,-20,0,0); l.BackgroundColor3=theme.Shade; l.Text=tostring(text); l.TextColor3=Color3.new(1,1,1); l.Font=theme.Font; l.TextSize=14; l.Parent=page; l.TextTransparency=1; l.BackgroundTransparency=1
            Instance.new("UICorner", l).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade,l); CacheText(l)
            SafeTween(l, ANIM.Bounce, {Size=UDim2.new(1,-20,0,40), TextTransparency=0, BackgroundTransparency=0})
            table.insert(tabElements, {frame=l, searchText=tostring(text)}); return l
        end
        function Tab:AddParagraph(title, content)
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=theme.Shade; frame.BackgroundTransparency=1; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade,frame)
            local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-20,0,25); t.Position=UDim2.new(0,10,0,5); t.BackgroundTransparency=1; t.Text=tostring(title); t.TextColor3=theme.Main; t.Font=theme.Font; t.TextSize=14; t.TextXAlignment=Enum.TextXAlignment.Left; t.TextTransparency=1; t.Parent=frame; CacheText(t)
            local c=Instance.new("TextLabel"); c.Size=UDim2.new(1,-20,0,40); c.Position=UDim2.new(0,10,0,30); c.BackgroundTransparency=1; c.Text=tostring(content); c.TextColor3=Color3.fromRGB(200,200,200); c.Font=theme.Font; c.TextSize=12; c.TextXAlignment=Enum.TextXAlignment.Left; c.TextWrapped=true; c.TextTransparency=1; c.Parent=frame; CacheText(c)
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,80), BackgroundTransparency=0}); SafeTween(t, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0}); SafeTween(c, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.15), {TextTransparency=0})
            table.insert(tabElements, {frame=frame, searchText=tostring(title).." "..tostring(content)})
        end
        function Tab:AddButton(text, callback, description)
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=theme.Shade; frame.BackgroundTransparency=0.5; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade,frame)
            local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,-16,1,-16); btn.Position=UDim2.new(0,8,0,8); btn.BackgroundColor3=theme.Button; btn.Text=tostring(text); btn.TextColor3=Color3.new(0,0,0); btn.Font=theme.Font; btn.TextSize=13; btn.Parent=frame; btn.AutoButtonColor=false; StyleButton(btn)
            AttachTooltip(frame, description, screenGui, Window._connections)
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,50)}); table.insert(tabElements, {frame=frame, searchText=tostring(text)})
            btn.MouseButton1Down:Connect(function() SafeTween(btn, ANIM.Fast, {BackgroundColor3=Color3.new(1,1,1)}); CreateRipple(btn, Vector2.new(btn.AbsoluteSize.X/2, btn.AbsoluteSize.Y/2)) end)
            btn.MouseButton1Up:Connect(function() SafeTween(btn, ANIM.Spring, {BackgroundColor3=theme.Button}) end)
            btn.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
            return btn
        end
        function Tab:AddToggle(text, default, callback, description, stateLabels)
            local key=tostring(text)
            local saved=loadedConfig.toggles and loadedConfig.toggles[key]
            local enabled=(saved~=nil) and not not saved or (default or false)
            saveData.toggles[key]=enabled
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=Color3.new(0,0,0); frame.BackgroundTransparency=1; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8)
            local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-60,1,0); lb.Position=UDim2.new(0,15,0,0); lb.Text=key; lb.TextColor3=Color3.new(1,1,1); lb.Font=theme.Font; lb.TextSize=14; lb.BackgroundTransparency=1; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.TextTransparency=1; lb.Parent=frame; CacheText(lb)
            local bg=Instance.new("TextButton"); bg.Name="ToggleBG"; bg.Size=UDim2.new(0,45,0,25); bg.Position=UDim2.new(1,-55,0.5,-12); bg.BackgroundColor3=enabled and theme.Button or theme.Shade; bg.Text=""; bg.AutoButtonColor=false; bg.Parent=frame; Instance.new("UICorner", bg).CornerRadius=UDim.new(1,0)
            local ball=Instance.new("Frame"); ball.Size=UDim2.new(0,17,0,17); ball.Position=enabled and UDim2.new(1,-21,0.5,-8) or UDim2.new(0,4,0.5,-8); ball.BackgroundColor3=Color3.new(1,1,1); ball.Parent=bg; Instance.new("UICorner", ball).CornerRadius=UDim.new(1,0)
            local ballGlow=Instance.new("UIStroke", ball); ballGlow.Color=enabled and theme.Button or theme.Shade; ballGlow.Thickness=2; ballGlow.Transparency=0.5
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,50), BackgroundTransparency=0.5}); SafeTween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0})
            AttachTooltip(frame, description, screenGui, Window._connections); table.insert(tabElements, {frame=frame, searchText=key})
            uiRegistry.toggles[key]={enabled=enabled, bg=bg, ball=ball, ballGlow=ballGlow, callback=callback, lb=lb}
            bg.MouseButton1Click:Connect(function()
                enabled=not enabled; saveData.toggles[key]=enabled; uiRegistry.toggles[key].enabled=enabled; DebouncedSave()
                local targetColor=enabled and theme.Button or theme.Shade
                SafeTween(bg, ANIM.Normal, {BackgroundColor3=targetColor}); SafeTween(ball, ANIM.Spring, {Position=enabled and UDim2.new(1,-21,0.5,-8) or UDim2.new(0,4,0.5,-8)}); SafeTween(ballGlow, ANIM.Normal, {Color=targetColor})
                if stateLabels and type(stateLabels)=="table" then lb.Text = enabled and (stateLabels.On or key) or (stateLabels.Off or key) elseif type(stateLabels)=="string" then lb.Text = enabled and (stateLabels.." [ON]") or (stateLabels.." [OFF]") end
                if callback then pcall(callback, enabled) end
            end)
            if stateLabels then
                if type(stateLabels)=="table" then lb.Text = enabled and (stateLabels.On or key) or (stateLabels.Off or key) elseif type(stateLabels)=="string" then lb.Text = enabled and (stateLabels.." [ON]") or (stateLabels.." [OFF]") end
            end
            if enabled and callback then task.defer(function() pcall(callback, true) end) end
        end
        function Tab:AddSlider(text, min, max, default, callback, description)
            local key=tostring(text)
            min=tonumber(min) or 0; max=tonumber(max) or 100; if min>max then min,max=max,min end
            local saved=loadedConfig.sliders and loadedConfig.sliders[key]
            local value = math.clamp(tonumber(saved) or tonumber(default) or min, min, max)
            saveData.sliders[key]=value
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=Color3.new(0,0,0); frame.BackgroundTransparency=1; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8)
            local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-20,0,25); lb.Position=UDim2.new(0,15,0,5); lb.BackgroundTransparency=1; lb.Text=key..": "..tostring(value); lb.TextColor3=Color3.new(1,1,1); lb.Font=theme.Font; lb.TextSize=13; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.TextTransparency=1; lb.Parent=frame; CacheText(lb)
            local track=Instance.new("Frame"); track.Size=UDim2.new(1,-30,0,8); track.Position=UDim2.new(0,15,0,35); track.BackgroundColor3=theme.Shade; track.Parent=frame; Instance.new("UICorner", track).CornerRadius=UDim.new(1,0)
            local fill=Instance.new("Frame"); fill.Size=UDim2.new(max==min and 0 or (value-min)/(max-min),0,1,0); fill.BackgroundColor3=theme.Button; fill.BorderSizePixel=0; fill.Parent=track; Instance.new("UICorner", fill).CornerRadius=UDim.new(1,0)
            local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,14,0,14); knob.Position=UDim2.new(max==min and 0 or (value-min)/(max-min), -7, 0.5,-7); knob.BackgroundColor3=Color3.new(1,1,1); knob.Parent=track; Instance.new("UICorner", knob).CornerRadius=UDim.new(1,0)
            local knobStroke=Instance.new("UIStroke", knob); knobStroke.Color=theme.Button; knobStroke.Thickness=2
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,60), BackgroundTransparency=0.5}); SafeTween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0})
            AttachTooltip(frame, description, screenGui, Window._connections); table.insert(tabElements, {frame=frame, searchText=key})
            uiRegistry.sliders[key]={value=value, lb=lb, fill=fill, knob=knob, track=track, min=min, max=max, callback=callback}
            local dragging=false
            local conA=track.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; SafeTween(knob, ANIM.Fast, {Size=UDim2.new(0,18,0,18)}); SafeTween(knobStroke, ANIM.Fast, {Thickness=3}) end end)
            local conB=UserInputService.InputEnded:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then dragging=false; SafeTween(knob, ANIM.Spring, {Size=UDim2.new(0,14,0,14)}); SafeTween(knobStroke, ANIM.Fast, {Thickness=2}) end end)
            local conC=UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                    if track.AbsoluteSize.X < 1 then return end
                    local pos=math.clamp((input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
                    value = math.floor(min + pos*(max-min))
                    saveData.sliders[key]=value; uiRegistry.sliders[key].value=value; lb.Text=key..": "..tostring(value)
                    SafeTween(fill, ANIM.Fast, {Size=UDim2.new(pos,0,1,0)}); SafeTween(knob, ANIM.Fast, {Position=UDim2.new(pos,-7,0.5,-7)})
                    if callback then pcall(callback, value) end
                    DebouncedSave()
                end
            end)
            table.insert(Window._connections, conA); table.insert(Window._connections, conB); table.insert(Window._connections, conC)
            if callback then task.defer(function() pcall(callback, value) end) end
        end
        function Tab:AddDropdown(text, options, callback, description)
            local key=tostring(text)
            if type(options)~="table" or #options==0 then options={"None"} end
            local saved=loadedConfig.dropdowns and loadedConfig.dropdowns[key]
            local selected=tostring(saved or options[1] or "")
            local found=false; for _,o in ipairs(options) do if tostring(o)==selected then found=true break end end; if not found then selected=tostring(options[1]) end
            saveData.dropdowns[key]=selected
            local open=false
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=Color3.new(0,0,0); frame.BackgroundTransparency=1; frame.Parent=page; frame.ClipsDescendants=false; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8)
            local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-160,1,0); lb.Position=UDim2.new(0,15,0,0); lb.Text=key; lb.TextColor3=Color3.new(1,1,1); lb.Font=theme.Font; lb.TextSize=14; lb.BackgroundTransparency=1; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.TextTransparency=1; lb.Parent=frame; CacheText(lb)
            local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,120,0,30); btn.Position=UDim2.new(1,-135,0.5,-15); btn.BackgroundColor3=theme.Shade; btn.Text=selected; btn.TextColor3=Color3.new(1,1,1); btn.Font=theme.Font; btn.TextSize=12; btn.AutoButtonColor=false; btn.Parent=frame; Instance.new("UICorner", btn).CornerRadius=UDim.new(0,6); table.insert(uiCache.Shade, btn); CacheText( btn)
            local arrow=Instance.new("TextLabel"); arrow.Size=UDim2.new(0,20,0,20); arrow.Position=UDim2.new(1,-22,0,5); arrow.BackgroundTransparency=1; arrow.Text="▼"; arrow.TextColor3=Color3.new(1,1,1); arrow.TextSize=10; arrow.Font=Enum.Font.SourceSansBold; arrow.Parent=btn
            -- dropdown popup parented to screenGui to avoid clipping
            local dropFrame=Instance.new("Frame"); dropFrame.Size=UDim2.new(0,120,0,0); dropFrame.BackgroundColor3=theme.Shade; dropFrame.BackgroundTransparency=1; dropFrame.ClipsDescendants=true; dropFrame.ZIndex=50; dropFrame.Visible=false; dropFrame.Parent=screenGui; Instance.new("UICorner", dropFrame).CornerRadius=UDim.new(0,6)
            local dropStroke=Instance.new("UIStroke", dropFrame); dropStroke.Color=theme.Outline; dropStroke.Thickness=1; dropStroke.Transparency=1
            local dropList=Instance.new("UIListLayout", dropFrame); dropList.Padding=UDim.new(0,2)
            local optionButtons={}
            for i,opt in ipairs(options) do
                local optBtn=Instance.new("TextButton"); optBtn.Size=UDim2.new(1,0,0,28); optBtn.BackgroundTransparency=1; optBtn.Text=tostring(opt); optBtn.TextColor3=Color3.new(1,1,1); optBtn.Font=theme.Font; optBtn.TextSize=12; optBtn.TextTransparency=1; optBtn.ZIndex=51; optBtn.Parent=dropFrame; optBtn.LayoutOrder=i; table.insert(optionButtons, optBtn)
                optBtn.MouseEnter:Connect(function() SafeTween(optBtn, ANIM.Fast, {BackgroundTransparency=0.7, BackgroundColor3=theme.Button, TextColor3=Color3.new(0,0,0)}) end)
                optBtn.MouseLeave:Connect(function() SafeTween(optBtn, ANIM.Fast, {BackgroundTransparency=1, TextColor3=Color3.new(1,1,1)}) end)
                optBtn.MouseButton1Click:Connect(function()
                    selected=tostring(opt); saveData.dropdowns[key]=selected; DebouncedSave(); btn.Text=selected; open=false
                    SafeTween(dropFrame, ANIM.Normal, {Size=UDim2.new(0,120,0,0), BackgroundTransparency=1}); SafeTween(dropStroke, ANIM.Fast, {Transparency=1}); SafeTween(arrow, ANIM.Fast, {Rotation=0})
                    for _,ob in ipairs(optionButtons) do SafeTween(ob, ANIM.Fast, {TextTransparency=1}) end
                    task.delay(0.25, function() if not open then dropFrame.Visible=false end end)
                    if callback then pcall(callback, selected) end
                end)
            end
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,50), BackgroundTransparency=0.5}); SafeTween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0})
            AttachTooltip(frame, description, screenGui, Window._connections); table.insert(tabElements, {frame=frame, searchText=key})
            uiRegistry.dropdowns[key]={selected=selected, btn=btn, callback=callback}
            local function toggle()
                open=not open
                if open then
                    local abs=btn.AbsolutePosition; local absSize=btn.AbsoluteSize
                    dropFrame.Position=UDim2.new(0, abs.X, 0, abs.Y + absSize.Y + 4)
                    dropFrame.Visible=true
                    local h=math.clamp(#options*30, 0, 150)
                    SafeTween(dropFrame, ANIM.Normal, {Size=UDim2.new(0,120,0,h), BackgroundTransparency=0}); SafeTween(dropStroke, ANIM.Fast, {Transparency=0}); SafeTween(arrow, ANIM.Spring, {Rotation=180})
                    for _,ob in ipairs(optionButtons) do SafeTween(ob, ANIM.Fast, {TextTransparency=0}) end
                else
                    SafeTween(dropFrame, ANIM.Normal, {Size=UDim2.new(0,120,0,0), BackgroundTransparency=1}); SafeTween(dropStroke, ANIM.Fast, {Transparency=1}); SafeTween(arrow, ANIM.Spring, {Rotation=0})
                    for _,ob in ipairs(optionButtons) do SafeTween(ob, ANIM.Fast, {TextTransparency=1}) end
                    task.delay(0.25, function() if not open then dropFrame.Visible=false end end)
                end
            end
            btn.MouseButton1Click:Connect(toggle)
            -- close when clicking elsewhere
            local closeConn
            closeConn = UserInputService.InputBegan:Connect(function(input)
                if open and input.UserInputType==Enum.UserInputType.MouseButton1 then
                    local m=UserInputService:GetMouseLocation()
                    local p=dropFrame.AbsolutePosition; local s=dropFrame.AbsoluteSize
                    local bpos=btn.AbsolutePosition; local bsize=btn.AbsoluteSize
                    local inDrop = m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+s.Y
                    local inBtn = m.X>=bpos.X and m.X<=bpos.X+bsize.X and m.Y>=bpos.Y and m.Y<=bpos.Y+bsize.Y
                    if not inDrop and not inBtn then toggle() end
                end
            end)
            table.insert(Window._connections, closeConn)
            -- cleanup popup on destroy
            local anc=screenGui.AncestryChanged:Connect(function(_,p) if not p then pcall(function() dropFrame:Destroy() end) end end)
            table.insert(Window._connections, anc)
            btn.MouseEnter:Connect(function() SafeTween(btn, ANIM.Fast, {BackgroundColor3=LightenColor(theme.Shade, 20)}) end)
            btn.MouseLeave:Connect(function() SafeTween(btn, ANIM.Fast, {BackgroundColor3=theme.Shade}) end)
            if callback then task.defer(function() pcall(callback, selected) end) end
        end
        function Tab:AddInput(text, default, callback, description)
            local key=tostring(text)
            local saved=loadedConfig.inputs and loadedConfig.inputs[key]
            local inputDefault=tostring(saved~=nil and saved or default or "")
            saveData.inputs[key]=inputDefault
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,50); frame.BackgroundColor3=Color3.new(0,0,0); frame.BackgroundTransparency=0.5; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8)
            local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-160,1,0); lb.Position=UDim2.new(0,15,0,0); lb.Text=key; lb.TextColor3=Color3.new(1,1,1); lb.Font=theme.Font; lb.TextSize=14; lb.BackgroundTransparency=1; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=frame; CacheText( lb)
            local box=Instance.new("TextBox"); box.Size=UDim2.new(0,120,0,30); box.Position=UDim2.new(1,-135,0.5,-15); box.BackgroundColor3=theme.Shade; box.Text=inputDefault; box.TextColor3=Color3.new(1,1,1); box.Font=theme.Font; box.TextSize=12; box.ClearTextOnFocus=false; box.Parent=frame; Instance.new("UICorner", box).CornerRadius=UDim.new(0,6); table.insert(uiCache.Shade, box); CacheText( box)
            local boxStroke=Instance.new("UIStroke", box); boxStroke.Color=theme.Outline; boxStroke.Thickness=1; AttachTooltip(frame, description, screenGui, Window._connections); table.insert(tabElements, {frame=frame, searchText=key})
            uiRegistry.inputs[key]={box=box, callback=callback}
            box.Focused:Connect(function() SafeTween(box, ANIM.Normal, {BackgroundColor3=LightenColor(theme.Shade, 15)}); SafeTween(boxStroke, ANIM.Normal, {Thickness=2, Color=theme.Main}); SafeTween(box, ANIM.Spring, {Size=UDim2.new(0,130,0,34), Position=UDim2.new(1,-140,0.5,-17)}) end)
            box.FocusLost:Connect(function(enter)
                saveData.inputs[key]=box.Text; DebouncedSave()
                SafeTween(box, ANIM.Normal, {BackgroundColor3=theme.Shade}); SafeTween(boxStroke, ANIM.Normal, {Thickness=1, Color=theme.Outline}); SafeTween(box, ANIM.Spring, {Size=UDim2.new(0,120,0,30), Position=UDim2.new(1,-135,0.5,-15)})
                if callback then pcall(callback, box.Text, enter) end
            end)
            if callback and inputDefault~="" then task.defer(function() pcall(callback, inputDefault) end) end
        end
        function Tab:AddKeybind(text, defaultKey, callback, description)
            local key=tostring(text)
            local saved=loadedConfig.keybinds and loadedConfig.keybinds[key]
            local currentKey
            if type(saved)=="string" then local ok,k=pcall(function() return Enum.KeyCode[saved] end); currentKey = (ok and k) and k or defaultKey else currentKey = defaultKey or Enum.KeyCode.Unknown end
            if not currentKey then currentKey=Enum.KeyCode.Unknown end
            saveData.keybinds[key]=currentKey.Name
            local listening=false
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=Color3.new(0,0,0); frame.BackgroundTransparency=1; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8)
            local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-160,1,0); lb.Position=UDim2.new(0,15,0,0); lb.Text=key; lb.TextColor3=Color3.new(1,1,1); lb.Font=theme.Font; lb.TextSize=14; lb.BackgroundTransparency=1; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.TextTransparency=1; lb.Parent=frame; CacheText( lb)
            local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,120,0,30); btn.Position=UDim2.new(1,-135,0.5,-15); btn.BackgroundColor3=theme.Shade; btn.Text=currentKey.Name; btn.TextColor3=Color3.new(1,1,1); btn.Font=theme.Font; btn.TextSize=12; btn.AutoButtonColor=false; btn.TextTransparency=1; btn.Parent=frame; Instance.new("UICorner", btn).CornerRadius=UDim.new(0,6); table.insert(uiCache.Shade, btn); CacheText( btn)
            local btnStroke=Instance.new("UIStroke", btn); btnStroke.Color=theme.Outline; btnStroke.Thickness=1; btnStroke.Transparency=1
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,50), BackgroundTransparency=0.5}); SafeTween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0}); SafeTween(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.15), {TextTransparency=0}); SafeTween(btnStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.2), {Transparency=0})
            AttachTooltip(frame, description, screenGui, Window._connections); table.insert(tabElements, {frame=frame, searchText=key})
            uiRegistry.keybinds[key]={currentKey=currentKey, btn=btn, callback=callback}
            local listenConn
            btn.MouseButton1Click:Connect(function()
                if listening then return end
                listening=true; btn.Text="..."; btn.TextColor3=theme.Button
                SafeTween(btn, ANIM.Spring, {Size=UDim2.new(0,130,0,34), Position=UDim2.new(1,-140,0.5,-17)}); SafeTween(btnStroke, ANIM.Normal, {Color=theme.Button, Thickness=2})
                if listenConn then pcall(function() listenConn:Disconnect() end) end
                listenConn = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.UserInputType==Enum.UserInputType.Keyboard then
                        pcall(function() listenConn:Disconnect() end); listenConn=nil; listening=false
                        currentKey=input.KeyCode; saveData.keybinds[key]=currentKey.Name; uiRegistry.keybinds[key].currentKey=currentKey; DebouncedSave()
                        btn.Text=currentKey.Name; btn.TextColor3=Color3.new(1,1,1)
                        SafeTween(btn, ANIM.Spring, {Size=UDim2.new(0,120,0,30), Position=UDim2.new(1,-135,0.5,-15)}); SafeTween(btnStroke, ANIM.Normal, {Color=theme.Outline, Thickness=1})
                        if callback then pcall(callback, currentKey) end
                    elseif input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputSource~=btn then
                        -- allow cancelling by clicking elsewhere? keep listening
                    end
                end)
                table.insert(Window._connections, listenConn)
                -- timeout after 5s
                task.delay(5, function() if listening then if listenConn then pcall(function() listenConn:Disconnect() end) end; listening=false; btn.Text=currentKey.Name; btn.TextColor3=Color3.new(1,1,1); SafeTween(btn, ANIM.Spring, {Size=UDim2.new(0,120,0,30), Position=UDim2.new(1,-135,0.5,-15)}); SafeTween(btnStroke, ANIM.Normal, {Color=theme.Outline, Thickness=1}) end end)
            end)
            btn.MouseEnter:Connect(function() if not listening then SafeTween(btn, ANIM.Fast, {BackgroundColor3=LightenColor(theme.Shade,15)}) end end)
            btn.MouseLeave:Connect(function() if not listening then SafeTween(btn, ANIM.Fast, {BackgroundColor3=theme.Shade}) end end)
            if callback and currentKey~=Enum.KeyCode.Unknown then task.defer(function() pcall(callback, currentKey) end) end
        end
        function Tab:AddColorPicker(text, defaultColor, callback, description)
            local key=tostring(text)
            local saved=loadedConfig.colors and loadedConfig.colors[key]
            if saved and type(saved)=="table" and saved.R then defaultColor=Color3.fromRGB(ClampRGB(saved.R), ClampRGB(saved.G), ClampRGB(saved.B)) end
            defaultColor=defaultColor or Color3.fromRGB(255,255,255)
            local curH,curS,curV = defaultColor:ToHSV()
            saveData.colors[key]=ColorToTable(defaultColor)
            local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-20,0,0); frame.BackgroundColor3=theme.Shade; frame.BackgroundTransparency=1; frame.Parent=page; Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade, frame)
            local lb=Instance.new("TextLabel"); lb.Size=UDim2.new(1,-60,1,0); lb.Position=UDim2.new(0,15,0,0); lb.Text=key; lb.TextColor3=Color3.new(1,1,1); lb.Font=theme.Font; lb.TextSize=14; lb.BackgroundTransparency=1; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.TextTransparency=1; lb.Parent=frame; CacheText( lb)
            local preview=Instance.new("TextButton"); preview.Size=UDim2.new(0,0,0,0); preview.Position=UDim2.new(1,-40,0.5,-15); preview.BackgroundColor3=defaultColor; preview.Text=""; preview.AutoButtonColor=false; preview.Parent=frame; Instance.new("UICorner", preview).CornerRadius=UDim.new(0,6)
            local previewStroke=Instance.new("UIStroke", preview); previewStroke.Color=theme.Outline; previewStroke.Thickness=2
            SafeTween(frame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,50), BackgroundTransparency=0}); SafeTween(lb, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0}); SafeTween(preview, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out,0,false,0.15), {Size=UDim2.new(0,30,0,30)})
            AttachTooltip(frame, description, screenGui, Window._connections); table.insert(tabElements, {frame=frame, searchText=key})
            local entry={preview=preview, callback=callback, curH=curH, curS=curS, curV=curV}
            uiRegistry.colors[key]=entry
            local popup=Instance.new("Frame"); popup.Size=UDim2.new(0,0,0,0); popup.BackgroundColor3=Color3.fromRGB(25,25,25); popup.ZIndex=1000; popup.Visible=false; popup.Active=true; popup.Parent=screenGui; Instance.new("UICorner", popup).CornerRadius=UDim.new(0,6)
            local pStroke=Instance.new("UIStroke", popup); pStroke.Color=theme.Outline; pStroke.Thickness=0
            local box=Instance.new("ImageButton"); box.Size=UDim2.new(0,150,0,150); box.Position=UDim2.new(0,10,0,10); box.Image="rbxassetid://4155801252"; box.AutoButtonColor=false; box.ZIndex=1001; box.Parent=popup; box.ImageTransparency=1
            local cursorSV=Instance.new("Frame"); cursorSV.Size=UDim2.new(0,6,0,6); cursorSV.BackgroundColor3=Color3.new(1,1,1); cursorSV.ZIndex=1002; cursorSV.Parent=box; cursorSV.BackgroundTransparency=1; Instance.new("UICorner", cursorSV).CornerRadius=UDim.new(1,0); local cStroke=Instance.new("UIStroke", cursorSV); cStroke.Color=Color3.new(0,0,0); cStroke.Thickness=1
            local hue=Instance.new("TextButton"); hue.Size=UDim2.new(0,20,0,150); hue.Position=UDim2.new(0,170,0,10); hue.BackgroundColor3=Color3.new(1,1,1); hue.Text=""; hue.AutoButtonColor=false; hue.ZIndex=1001; hue.Parent=popup; hue.BackgroundTransparency=1
            local grad=Instance.new("UIGradient", hue); grad.Rotation=90; grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.167,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(0.333,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.667,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(0.833,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})
            local cursorHue=Instance.new("Frame"); cursorHue.Size=UDim2.new(1,4,0,3); cursorHue.Position=UDim2.new(0,-2,0,0); cursorHue.BackgroundColor3=Color3.new(1,1,1); cursorHue.ZIndex=1002; cursorHue.Parent=hue; cursorHue.BackgroundTransparency=1; local hStroke=Instance.new("UIStroke", cursorHue); hStroke.Color=Color3.new(0,0,0); hStroke.Thickness=1
            local txt=Instance.new("TextLabel"); txt.Size=UDim2.new(1,-20,0,30); txt.Position=UDim2.new(0,10,0,165); txt.BackgroundTransparency=1; txt.TextColor3=Color3.new(0.8,0.8,0.8); txt.Font=Enum.Font.Code; txt.TextSize=12; txt.TextXAlignment=Enum.TextXAlignment.Left; txt.ZIndex=1001; txt.TextTransparency=1; txt.Parent=popup; CacheText( txt)
            local function updateUI()
                local c=Color3.fromHSV(entry.curH, entry.curS, entry.curV)
                box.BackgroundColor3=Color3.fromHSV(entry.curH,1,1); preview.BackgroundColor3=c
                cursorSV.Position=UDim2.new(entry.curS,-3, 1-entry.curV,-3); cursorHue.Position=UDim2.new(0,-2, entry.curH,-1)
                local r,g,b=ClampRGB(c.R*255),ClampRGB(c.G*255),ClampRGB(c.B*255)
                txt.Text=string.format("#%02X%02X%02X   %d, %d, %d", r,g,b,r,g,b)
                saveData.colors[key]={R=r,G=g,B=b}; DebouncedSave()
                if callback then pcall(callback, c) end
            end
            entry.update = function() curH,curS,curV = entry.curH, entry.curS, entry.curV; updateUI() end -- for ApplyConfig refresh
            -- sync entry fields wrapper
            local function syncFromEntry() curH,curS,curV = entry.curH, entry.curS, entry.curV end
            local function syncToEntry() entry.curH,entry.curS,entry.curV = curH,curS,curV end
            -- override update to use locals
            updateUI()
            -- patch entry to keep in sync when ApplyConfig changes curH etc
            local origUpdate = updateUI
            entry.update = function()
                curH,curS,curV = entry.curH, entry.curS, entry.curV
                local c=Color3.fromHSV(curH,curS,curV)
                box.BackgroundColor3=Color3.fromHSV(curH,1,1); preview.BackgroundColor3=c
                cursorSV.Position=UDim2.new(curS,-3,1-curV,-3); cursorHue.Position=UDim2.new(0,-2,curH,-1)
                local r,g,b=ClampRGB(c.R*255),ClampRGB(c.G*255),ClampRGB(c.B*255); txt.Text=string.format("#%02X%02X%02X   %d, %d, %d",r,g,b,r,g,b)
            end
            preview.MouseButton1Click:Connect(function()
                popup.Visible=not popup.Visible
                if popup.Visible then
                    local abs=preview.AbsolutePosition
                    local popX=math.clamp(abs.X+15, 10, math.max(screenGui.AbsoluteSize.X-210,10))
                    local popY=math.clamp(abs.Y+40, 10, math.max(screenGui.AbsoluteSize.Y-210,10))
                    popup.Position=UDim2.new(0,popX,0,popY)
                    popup.Size=UDim2.new(0,0,0,0)
                    SafeTween(popup, ANIM.Bounce, {Size=UDim2.new(0,200,0,200)}); SafeTween(pStroke, ANIM.Normal, {Thickness=2})
                    SafeTween(box, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {ImageTransparency=0})
                    SafeTween(cursorSV, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.15), {BackgroundTransparency=0})
                    SafeTween(cursorHue, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.15), {BackgroundTransparency=0})
                    SafeTween(hue, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {BackgroundTransparency=0})
                    SafeTween(txt, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.2), {TextTransparency=0})
                else
                    SafeTween(popup, ANIM.Fast, {Size=UDim2.new(0,0,0,0)}); SafeTween(pStroke, ANIM.Fast, {Thickness=0})
                    task.delay(0.22, function() if not popup.Visible then popup.Visible=false end end)
                end
            end)
            local dragHue, dragSV=false,false
            local dragLoop
            local function updateHSV()
                if dragHue then curH=math.clamp((UserInputService:GetMouseLocation().Y - hue.AbsolutePosition.Y)/math.max(hue.AbsoluteSize.Y,1),0,1)
                elseif dragSV then
                    curS=math.clamp((UserInputService:GetMouseLocation().X - box.AbsolutePosition.X)/math.max(box.AbsoluteSize.X,1),0,1)
                    curV=1-math.clamp((UserInputService:GetMouseLocation().Y - box.AbsolutePosition.Y)/math.max(box.AbsoluteSize.Y,1),0,1)
                end
                entry.curH, entry.curS, entry.curV = curH,curS,curV
                local c=Color3.fromHSV(curH,curS,curV)
                box.BackgroundColor3=Color3.fromHSV(curH,1,1); preview.BackgroundColor3=c
                cursorSV.Position=UDim2.new(curS,-3,1-curV,-3); cursorHue.Position=UDim2.new(0,-2,curH,-1)
                local r,g,b=ClampRGB(c.R*255),ClampRGB(c.G*255),ClampRGB(c.B*255); txt.Text=string.format("#%02X%02X%02X   %d, %d, %d",r,g,b,r,g,b)
                saveData.colors[key]={R=r,G=g,B=b}; DebouncedSave()
                if callback then pcall(callback, c) end
            end
            local function startDrag() if dragLoop then pcall(function() dragLoop:Disconnect() end) end; dragLoop=RunService.RenderStepped:Connect(updateHSV); table.insert(Window._connections, dragLoop) end
            local function stopDrag() if dragLoop then pcall(function() dragLoop:Disconnect() end); dragLoop=nil end end
            hue.MouseButton1Down:Connect(function() dragHue=true; startDrag() end)
            box.MouseButton1Down:Connect(function() dragSV=true; startDrag() end)
            local cEnd=UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragHue=false; dragSV=false; stopDrag() end end)
            table.insert(Window._connections, cEnd)
            local cBegan=UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 and popup.Visible then
                    local mx,my=UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
                    local px,py=popup.AbsolutePosition.X, popup.AbsolutePosition.Y
                    local bx,by=preview.AbsolutePosition.X, preview.AbsolutePosition.Y
                    local inPopup = mx>=px and mx<=px+popup.AbsoluteSize.X and my>=py and my<=py+popup.AbsoluteSize.Y
                    local inBtn = mx>=bx and mx<=bx+preview.AbsoluteSize.X and my>=by and my<=by+preview.AbsoluteSize.Y
                    if not inPopup and not inBtn then SafeTween(popup, ANIM.Fast, {Size=UDim2.new(0,0,0,0)}); SafeTween(pStroke, ANIM.Fast, {Thickness=0}); task.delay(0.22, function() popup.Visible=false end) end
                end
            end)
            table.insert(Window._connections, cBegan)
            if callback then task.defer(function() pcall(callback, Color3.fromHSV(curH,curS,curV)) end) end
        end
        return Tab
    end

    function Window:MakeTab(cfg)
        cfg=cfg or {}
        local name=cfg.Name or "Tab"
        local icon=cfg.Icon or ""
        local Tab=self:AddTab(name)
        if icon~="" then
            local tabData=tabs[tabCount]
            if tabData and tabData.Btn then
                local btn=tabData.Btn
                local iconImg=Instance.new("ImageLabel"); iconImg.Name="TabIcon"; iconImg.Size=UDim2.new(0,20,0,20); iconImg.Position=UDim2.new(0,8,0.5,-10); iconImg.BackgroundTransparency=1; iconImg.Image=icon; iconImg.ZIndex=btn.ZIndex+1; iconImg.Parent=btn
                btn.TextXAlignment=Enum.TextXAlignment.Left; btn.Text="            "..name
            end
        end
        return Tab
    end

    -- Settings Tab
    if hasSettings then
        local settingsTab=Window:AddTab("Settings")
        local settingsData=tabs[tabCount]
        settingsData.Btn.LayoutOrder=999999
        local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,-10,0,1); sep.BackgroundColor3=theme.Outline; sep.BackgroundTransparency=0.6; sep.LayoutOrder=999998; sep.Parent=tabContainer; Instance.new("UICorner", sep).CornerRadius=UDim.new(1,0)
        local sp=Instance.new("Frame"); sp.Size=UDim2.new(1,0,0,4); sp.BackgroundTransparency=1; sp.LayoutOrder=999997; sp.Parent=tabContainer
        settingsTab:AddLabel("XeNOX v2.3 — Config Manager")
        settingsTab:AddParagraph("Manage Configs", "All your saved configurations appear below. Click LOAD to apply instantly.")
        settingsTab:AddToggle("Auto Save", autoSave, function(t) autoSave=t; saveData._autoSave=t; DebouncedSave() end)
        local allConfigs=ListConfigs(); if #allConfigs==0 then allConfigs={"default"} end
        settingsTab:AddDropdown("Auto Save Target", allConfigs, function(s) autoSaveTarget=s; saveData._autoSaveTarget=s; DebouncedSave() end, "Which config auto-save writes to")
        settingsTab:AddToggle("Auto Load", autoLoad, function(t) autoLoad=t; saveData._autoLoad=t; DebouncedSave() end)
        settingsTab:AddDropdown("Auto Load Target", allConfigs, function(s) autoLoadTarget=s; saveData._autoLoadTarget=s; DebouncedSave() end, "Which config auto-load reads on startup")
        local activeCard=Instance.new("Frame"); activeCard.Size=UDim2.new(1,-20,0,0); activeCard.BackgroundColor3=theme.Shade; activeCard.BackgroundTransparency=1; activeCard.Parent=settingsData.Page; Instance.new("UICorner", activeCard).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade, activeCard)
        local activeStroke=Instance.new("UIStroke", activeCard); activeStroke.Color=theme.Main; activeStroke.Thickness=2; activeStroke.Transparency=1
        local activeHeader=Instance.new("TextLabel"); activeHeader.Size=UDim2.new(1,-20,0,18); activeHeader.Position=UDim2.new(0,10,0,6); activeHeader.BackgroundTransparency=1; activeHeader.Text="CURRENTLY ACTIVE"; activeHeader.TextColor3=theme.Main; activeHeader.Font=theme.Font; activeHeader.TextSize=11; activeHeader.TextXAlignment=Enum.TextXAlignment.Left; activeHeader.TextTransparency=1; activeHeader.Parent=activeCard; CacheText( activeHeader)
        local activeNameLbl=Instance.new("TextLabel"); activeNameLbl.Size=UDim2.new(1,-20,0,28); activeNameLbl.Position=UDim2.new(0,10,0,24); activeNameLbl.BackgroundTransparency=1; activeNameLbl.Text=activeConfigName; activeNameLbl.TextColor3=Color3.new(1,1,1); activeNameLbl.Font=theme.Font; activeNameLbl.TextSize=16; activeNameLbl.TextXAlignment=Enum.TextXAlignment.Left; activeNameLbl.TextTransparency=1; activeNameLbl.Parent=activeCard; CacheText( activeNameLbl)
        SafeTween(activeCard, ANIM.Bounce, {Size=UDim2.new(1,-20,0,58), BackgroundTransparency=0}); SafeTween(activeStroke, ANIM.Smooth, {Transparency=0}); SafeTween(activeHeader, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.1), {TextTransparency=0}); SafeTween(activeNameLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.15), {TextTransparency=0})
        settingsTab:AddLabel("Saved Configs")
        local listContainer=Instance.new("Frame"); listContainer.Size=UDim2.new(1,-20,0,0); listContainer.BackgroundTransparency=1; listContainer.Parent=settingsData.Page
        local listLayout=Instance.new("UIListLayout", listContainer); listLayout.Padding=UDim.new(0,6); listLayout.SortOrder=Enum.SortOrder.LayoutOrder
        local configRows={}
        local function RefreshConfigList()
            for _,row in ipairs(configRows) do pcall(function() if row and row.Parent then row:Destroy() end end) end; configRows={}
            local list=ListConfigs(); if #list==0 then list={"default"} end
            for i,name in ipairs(list) do
                local cfgName=name
                local isActive=(cfgName==activeConfigName)
                local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,46); row.BackgroundColor3=isActive and theme.Button or theme.Shade; row.BackgroundTransparency=1; row.LayoutOrder=i; row.Parent=listContainer; Instance.new("UICorner", row).CornerRadius=UDim.new(0,8); if not isActive then table.insert(uiCache.Shade, row) end
                local rowStroke=Instance.new("UIStroke", row); rowStroke.Color=isActive and theme.ButtonOutline or theme.Outline; rowStroke.Thickness=isActive and 2 or 1; rowStroke.Transparency=1
                local nameLbl=Instance.new("TextLabel"); nameLbl.Size=UDim2.new(1,-200,1,0); nameLbl.Position=UDim2.new(0,14,0,0); nameLbl.BackgroundTransparency=1; nameLbl.Text=cfgName..(isActive and "  ●" or ""); nameLbl.TextColor3=Color3.new(1,1,1); nameLbl.Font=theme.Font; nameLbl.TextSize=13; nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTransparency=1; nameLbl.Parent=row; CacheText( nameLbl)
                local selBtn=Instance.new("TextButton"); selBtn.Size=UDim2.new(0,46,0,28); selBtn.Position=UDim2.new(1,-168,0.5,-14); selBtn.BackgroundColor3=isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(120,120,120); selBtn.Text="SEL"; selBtn.TextColor3=Color3.new(0,0,0); selBtn.Font=theme.Font; selBtn.TextSize=10; selBtn.AutoButtonColor=false; selBtn.Parent=row; Instance.new("UICorner", selBtn).CornerRadius=UDim.new(0,6)
                local loadBtn=Instance.new("TextButton"); loadBtn.Size=UDim2.new(0,52,0,28); loadBtn.Position=UDim2.new(1,-114,0.5,-14); loadBtn.BackgroundColor3=Color3.fromRGB(80,220,120); loadBtn.Text="LOAD"; loadBtn.TextColor3=Color3.new(0,0,0); loadBtn.Font=theme.Font; loadBtn.TextSize=10; loadBtn.AutoButtonColor=false; loadBtn.Parent=row; Instance.new("UICorner", loadBtn).CornerRadius=UDim.new(0,6)
                local delBtn=Instance.new("TextButton"); delBtn.Size=UDim2.new(0,52,0,28); delBtn.Position=UDim2.new(1,-56,0.5,-14); delBtn.BackgroundColor3=Color3.fromRGB(255,70,70); delBtn.Text="DEL"; delBtn.TextColor3=Color3.new(0,0,0); delBtn.Font=theme.Font; delBtn.TextSize=10; delBtn.AutoButtonColor=false; delBtn.Parent=row; Instance.new("UICorner", delBtn).CornerRadius=UDim.new(0,6)
                selBtn.MouseButton1Click:Connect(function() activeConfigName=cfgName; saveData._activeConfigName=cfgName; activeNameLbl.Text=cfgName; Window:Notify("Config Selected", "'"..cfgName.."' is now active.",2); task.defer(RefreshConfigList) end)
                loadBtn.MouseButton1Click:Connect(function() local d=LoadConfig(cfgName); if d then loadedConfig=d; Window._loadedConfig=d; activeConfigName=cfgName; saveData._activeConfigName=cfgName; ApplyConfig(d); activeNameLbl.Text=cfgName; Window:Notify("Config Loaded","Applied '"..cfgName.."' live!",3); task.defer(RefreshConfigList) else Window:Notify("Error","Failed to load '"..cfgName.."'",2) end end)
                delBtn.MouseButton1Click:Connect(function() if cfgName=="default" then Window:Notify("Error","Cannot delete default config.",2); return end; if DeleteConfig(cfgName) then Window:Notify("Deleted","'"..cfgName.."' removed.",2); if activeConfigName==cfgName then activeConfigName="default"; saveData._activeConfigName="default"; activeNameLbl.Text="default" end; task.defer(RefreshConfigList) else Window:Notify("Error","'"..cfgName.."' not found.",2) end end)
                SafeTween(row, ANIM.Bounce, {BackgroundTransparency=0}); SafeTween(rowStroke, ANIM.Smooth, {Transparency=0}); SafeTween(nameLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,0,false,0.05*i), {TextTransparency=0})
                table.insert(configRows, row)
            end
            listContainer.Size=UDim2.new(1,-20,0, math.max(#list*52, 0))
            task.defer(function() if settingsData.Page and listLayout then settingsData.Page.CanvasSize=UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y+18) end end)
        end
        settingsTab:AddLabel("Config Actions")
        settingsTab:AddParagraph("Create New", "Type a name below, then click CREATE NEW to save current settings as a brand new config file.")
        local newConfigName=""
        settingsTab:AddInput("New Config Name", "", function(txt) newConfigName=tostring(txt):gsub("[^%w_]","_") end)
        local createFrame=Instance.new("Frame"); createFrame.Size=UDim2.new(1,-20,0,0); createFrame.BackgroundColor3=theme.Shade; createFrame.BackgroundTransparency=0.5; createFrame.Parent=settingsData.Page; Instance.new("UICorner", createFrame).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade, createFrame)
        local createBtn=Instance.new("TextButton"); createBtn.Size=UDim2.new(1,-16,1,-16); createBtn.Position=UDim2.new(0,8,0,8); createBtn.BackgroundColor3=Color3.fromRGB(0,180,255); createBtn.Text="  CREATE NEW CONFIG  "; createBtn.TextColor3=Color3.new(0,0,0); createBtn.Font=theme.Font; createBtn.TextSize=13; createBtn.Parent=createFrame; createBtn.AutoButtonColor=false; Instance.new("UICorner", createBtn).CornerRadius=UDim.new(0,6)
        createBtn.MouseButton1Click:Connect(function() if newConfigName=="" then Window:Notify("Error","Please enter a valid config name.",2); return end; activeConfigName=newConfigName; saveData._activeConfigName=activeConfigName; SaveConfig(activeConfigName); activeNameLbl.Text=activeConfigName; Window:Notify("Config Created","Saved as '"..activeConfigName.."'",2); RefreshConfigList() end)
        SafeTween(createFrame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,54)})
        settingsTab:AddParagraph("Save Active", "Click below to overwrite the currently active config with your current settings.")
        local saveActiveFrame=Instance.new("Frame"); saveActiveFrame.Size=UDim2.new(1,-20,0,0); saveActiveFrame.BackgroundColor3=theme.Shade; saveActiveFrame.BackgroundTransparency=0.5; saveActiveFrame.Parent=settingsData.Page; Instance.new("UICorner", saveActiveFrame).CornerRadius=UDim.new(0,8); table.insert(uiCache.Shade, saveActiveFrame)
        local saveActiveBtn=Instance.new("TextButton"); saveActiveBtn.Size=UDim2.new(1,-16,1,-16); saveActiveBtn.Position=UDim2.new(0,8,0,8); saveActiveBtn.BackgroundColor3=Color3.fromRGB(80,220,120); saveActiveBtn.Text="  SAVE ACTIVE CONFIG  "; saveActiveBtn.TextColor3=Color3.new(0,0,0); saveActiveBtn.Font=theme.Font; saveActiveBtn.TextSize=13; saveActiveBtn.Parent=saveActiveFrame; saveActiveBtn.AutoButtonColor=false; Instance.new("UICorner", saveActiveBtn).CornerRadius=UDim.new(0,6)
        saveActiveBtn.MouseButton1Click:Connect(function() SaveConfig(activeConfigName); Window:Notify("Config Saved","Overwritten '"..activeConfigName.."' with current settings!",3) end)
        SafeTween(saveActiveFrame, ANIM.Bounce, {Size=UDim2.new(1,-20,0,54)})
        RefreshConfigList()
        settingsTab:AddLabel("BACKGROUND EFFECTS")
        settingsTab:AddToggle("Enable Rain", effects.Rain, function(t) effects.Rain=t; saveData.effects.Rain=t; DebouncedSave() end)
        settingsTab:AddColorPicker("Rain Color", effectColors.Rain, function(c) effectColors.Rain=c; saveData.effectColors.Rain=ColorToTable(c); DebouncedSave() end)
        settingsTab:AddToggle("Enable Mouse Trail", effects.Trail, function(t) effects.Trail=t; saveData.effects.Trail=t; DebouncedSave() end)
        settingsTab:AddColorPicker("Trail Color", effectColors.Trail, function(c) effectColors.Trail=c; saveData.effectColors.Trail=ColorToTable(c); DebouncedSave() end)
        settingsTab:AddToggle("Enable Interactive Blobs", effects.Blob, function(t) effects.Blob=t; saveData.effects.Blob=t; DebouncedSave() end)
        settingsTab:AddColorPicker("Blob Color", effectColors.Blob, function(c) effectColors.Blob=c; saveData.effectColors.Blob=ColorToTable(c); DebouncedSave() end)
        settingsTab:AddToggle("Enable Matrix Rain", effects.Matrix, function(t) effects.Matrix=t; saveData.effects.Matrix=t; DebouncedSave() end)
        settingsTab:AddColorPicker("Matrix Color", effectColors.Matrix, function(c) effectColors.Matrix=c; saveData.effectColors.Matrix=ColorToTable(c); DebouncedSave() end)
        settingsTab:AddToggle("Enable Floating Hexagons", effects.Hex, function(t) effects.Hex=t; saveData.effects.Hex=t; DebouncedSave() end)
        settingsTab:AddColorPicker("Hex Color", effectColors.Hex, function(c) effectColors.Hex=c; saveData.effectColors.Hex=ColorToTable(c); DebouncedSave() end)
        settingsTab:AddToggle("Enable Glitch Blocks", effects.Glitch, function(t) effects.Glitch=t; saveData.effects.Glitch=t; DebouncedSave() end)
        settingsTab:AddColorPicker("Glitch Color", effectColors.Glitch, function(c) effectColors.Glitch=c; saveData.effectColors.Glitch=ColorToTable(c); DebouncedSave() end)
        settingsTab:AddLabel("APPEARANCE")
        settingsTab:AddToggle("Enable Window Glow", glowEnabled, function(t) glowEnabled=t; saveData.glowEnabled=t; DebouncedSave(); if mainGlow and mainGlow.Parent then SafeTween(mainGlow, ANIM.Normal, {ImageTransparency = t and (1-glowOpacity) or 1}) end end, "Toggles a soft glow around the main window")
        settingsTab:AddColorPicker("Glow Color", glowColor, function(c) glowColor=c; saveData.glowColor=ColorToTable(c); DebouncedSave(); if mainGlow and mainGlow.Parent then SafeTween(mainGlow, ANIM.Normal, {ImageColor3=c}) end end, "Changes the color of the window glow")
        settingsTab:AddSlider("Glow Opacity", 0, 100, math.floor(glowOpacity*100), function(val) glowOpacity=val/100; saveData.glowOpacity=glowOpacity; DebouncedSave(); if mainGlow and mainGlow.Parent then SafeTween(mainGlow, ANIM.Normal, {ImageTransparency = glowEnabled and (1-glowOpacity) or 1}) end end, "0 = invisible, 100 = solid")
        settingsTab:AddKeybind("Menu Toggle Key", menuKey, function(newKey) menuKey=newKey; saveData.menuKey=newKey.Name; DebouncedSave() end)
        local fontNames=BuildFontList()
        settingsTab:AddDropdown("Global Font", fontNames, function(selected) SetGlobalFont(selected); DebouncedSave() end, "Changes font across the UI (incl. BuilderSans, GothamSSm, Montserrat, Arimo)")
        settingsTab:AddColorPicker("Main Theme", theme.Main, function(c) theme.Main=c; saveData.theme.Main=ColorToTable(c); DebouncedSave(); SafeTween(mainFrame, ANIM.Normal, {BackgroundColor3=c}); if titleLbl then titleLbl.TextColor3=GetContrastColor(c) end; SafeTween(mainStroke, ANIM.Normal, {Color=c}) end)
        settingsTab:AddColorPicker("UI Outline Color", theme.Outline, function(c) theme.Outline=c; saveData.theme.Outline=ColorToTable(c); DebouncedSave(); SafeTween(mainStroke, ANIM.Normal, {Color=c}); for _,v in ipairs(uiCache.ButtonOutline) do if v and v.Parent then SafeTween(v, ANIM.Normal, {Color=c}) end end end)
        settingsTab:AddColorPicker("Shade Color", theme.Shade, function(c) theme.Shade=c; saveData.theme.Shade=ColorToTable(c); DebouncedSave(); for _,v in ipairs(uiCache.Shade) do if v and v.Parent then SafeTween(v, ANIM.Normal, {BackgroundColor3=c}) end end end)
        settingsTab:AddColorPicker("Button Color", theme.Button, function(c) theme.Button=c; saveData.theme.Button=ColorToTable(c); DebouncedSave(); for _,v in ipairs(uiCache.Button) do if v and v.Parent then SafeTween(v, ANIM.Normal, {BackgroundColor3=c}) end end end)
        settingsTab:AddColorPicker("Button Outline Color", theme.ButtonOutline, function(c) theme.ButtonOutline=c; saveData.theme.ButtonOutline=ColorToTable(c); DebouncedSave(); for _,v in ipairs(uiCache.ButtonOutline) do if v and v.Parent then SafeTween(v, ANIM.Normal, {Color=c}) end end end)
        settingsTab:AddLabel("INTRO APPEARANCE")
        settingsTab:AddColorPicker("Intro Background Color", introBackgroundColor, function(c) introBackgroundColor=c; saveData.introBackgroundColor=ColorToTable(c); DebouncedSave() end, "Background color of loading intro")
        settingsTab:AddColorPicker("Intro Text Color", introTextColor, function(c) introTextColor=c; saveData.introTextColor=ColorToTable(c); DebouncedSave() end, "Text color of loading intro")
    end

    function Window:SaveConfig(name) SaveConfig(name) end
    function Window:LoadConfig(name) return LoadConfig(name) end
    function Window:DeleteConfig(name) return DeleteConfig(name) end
    function Window:ListConfigs() return ListConfigs() end
    function Window:SetActiveConfig(name) if type(name)=="string" and name~="" then activeConfigName=name end end
    function Window:GetActiveConfig() return activeConfigName end
    function Window:ResetConfig()
        local path=GetConfigPath(activeConfigName)
        pcall(function() if isfile and isfile(path) then delfile(path) end end)
        saveData.toggles={}; saveData.sliders={}; saveData.dropdowns={}; saveData.inputs={}; saveData.keybinds={}; saveData.colors={}; saveData.theme={}; saveData.effects={}; saveData.effectColors={}; saveData.menuKey=nil
        ApplyConfig({toggles={},sliders={},dropdowns={},inputs={},keybinds={},colors={},effects={},effectColors={},theme={},glowEnabled=false,glowOpacity=0.4}); Window:Notify("Config Reset","Active config wiped and UI reset.",3)
    end
    function Window:GetConfigPath(name) return GetConfigPath(name or activeConfigName) end
    if autoLoad then local data=LoadConfig(autoLoadTarget); if data then loadedConfig=data; Window._loadedConfig=data; activeConfigName=autoLoadTarget; ApplyConfig(data); Window:Notify("Auto Load","Applied config '"..autoLoadTarget.."' automatically!",3) end end
    function Window:SetCustomData(key, value) if type(key)~="string" then return end; saveData.custom[key]=value; DebouncedSave() end
    function Window:GetCustomData(key, default) if saveData.custom[key]~=nil then return saveData.custom[key] end; return default end
    function Window:GetAllCustomData() local copy={}; for k,v in pairs(saveData.custom) do copy[k]=v end; return copy end
    function Window:OnConfigLoaded(callback) if type(callback)=="function" then table.insert(Window._configCallbacks, callback) end end
    function Window:ForceSave() SaveConfig(activeConfigName) end
    function Window:ForceLoad(name) name=name or activeConfigName; local data=LoadConfig(name); if data then loadedConfig=data; Window._loadedConfig=data; activeConfigName=name; ApplyConfig(data); return true end; return false end

    return Window
end

local function CreateXELIB(config) return XELIB:MakeWindow(config) end
XELIB.Create = CreateXELIB
XELIB.MakeWindow = XELIB.MakeWindow
return XELIB
