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
    local dragging, dragInput, dragStart, startPos, connection
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            connection = UserInputService.InputChanged:Connect(function(changed)
                if changed == dragInput and dragging then
                    local delta = changed.Position - dragStart
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
function XELIB:MakeWindow(config)
    config = config or {}
    local Window = {}
    setmetatable(Window, {__index = XELIB})
    local winName = config.Name or "XeNOX Library"
    local subTitle = config.SubTitle or ""
    local hasSettings = config.Setting ~= false
    local hasIntro = config.Intro == true
    local introText = config.IntroText or "LOADING"
    local introIcon = config.IntroIcon or ""
    local introSpeed = config.IntroSpeed or 1
    local hasToggle = config.Toggle ~= false
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
    getgenv().XELIB_ActiveGui = screenGui
    if hasIntro then
        local introGui = Instance.new("ScreenGui")
        introGui.Name = RandomString(12)
        introGui.ResetOnSpawn = false
        introGui.IgnoreGuiInset = true
        introGui.Parent = screenGui.Parent
        getgenv().XELIB_ActiveIntro = introGui
        local introFrame = Instance.new("Frame")
        introFrame.Size = UDim2.new(1, 0, 1, 0)
        introFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        introFrame.Parent = introGui
        local introCorner = Instance.new("UICorner", introFrame)
        introCorner.CornerRadius = UDim.new(0, 0)
        local introStroke = Instance.new("UIStroke", introFrame)
        introStroke.Thickness = 2
        introStroke.Color = theme.Main
        if rainbowMain then
            RainbowStroke(introStroke)
        end
        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 80, 0, 80)
        iconImg.Position = UDim2.new(0.5, -40, 0.4, -40)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = introIcon
        iconImg.Parent = introFrame
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, 0, 0, 40)
        titleLbl.Position = UDim2.new(0, 0, 0.55, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = introText
        titleLbl.TextColor3 = theme.Main
        titleLbl.Font = Enum.Font.LuckiestGuy
        titleLbl.TextSize = 32
        titleLbl.Parent = introFrame
        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, 0, 0, 25)
        subLbl.Position = UDim2.new(0, 0, 0.62, 0)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = winName
        subLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        subLbl.Font = theme.Font
        subLbl.TextSize = 18
        subLbl.Parent = introFrame
        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(0, 200, 0, 6)
        barBg.Position = UDim2.new(0.5, -100, 0.7, 0)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        barBg.Parent = introFrame
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = theme.Main
        barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
        Tween(barFill, TweenInfo.new(introSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        task.wait(introSpeed + 0.2)
        Tween(introFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        Tween(iconImg, TweenInfo.new(0.3), {ImageTransparency = 1})
        Tween(titleLbl, TweenInfo.new(0.3), {TextTransparency = 1})
        Tween(subLbl, TweenInfo.new(0.3), {TextTransparency = 1})
        Tween(barBg, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        Tween(barFill, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        task.wait(0.35)
        introGui:Destroy()
    end
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = RandomString(16)
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = theme.Main
    mainFrame.BackgroundTransparency = 0.4
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = mainFrame
    uiScale.Scale = 1
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 2
    mainStroke.Color = theme.Outline
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    if rainbowMain then
        RainbowStroke(mainStroke)
    end
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 5
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
        if rainbowSub then
            local sStroke = Instance.new("UIStroke", subLbl)
            sStroke.Thickness = 1
            RainbowStroke(sStroke)
        end
    end
    if iconAsset ~= "" then
        local winIcon = Instance.new("ImageLabel")
        winIcon.Size = UDim2.new(0, 24, 0, 24)
        winIcon.Position = UDim2.new(1, -80, 0, 10)
        winIcon.BackgroundTransparency = 1
        winIcon.Image = iconAsset
        winIcon.ZIndex = 5
        winIcon.Parent = titleBar
    end
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "-"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 28
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.ZIndex = 20
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 700, 0, 45)})
        else
            Tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 700, 0, 500)})
        end
    end)
    local destroyBtn = Instance.new("TextButton")
    destroyBtn.Size = UDim2.new(0, 30, 0, 30)
    destroyBtn.Position = UDim2.new(1, -70, 0, 8)
    destroyBtn.BackgroundTransparency = 1
    destroyBtn.Text = "X"
    destroyBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    destroyBtn.TextSize = 20
    destroyBtn.Font = Enum.Font.SourceSansBold
    destroyBtn.ZIndex = 20
    destroyBtn.Parent = titleBar
    destroyBtn.MouseButton1Click:Connect(function()
        if type(closeCallback) == "function" then
            closeCallback()
        end
        getgenv().XELIB_ActiveGui = nil
        getgenv().XELIB_ToggleBtn = nil
        screenGui:Destroy()
    end)
    MakeDraggable(mainFrame, titleBar)
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 150, 1, -55)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 8)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Parent = tabContainer
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -180, 1, -60)
    contentFrame.Position = UDim2.new(0, 170, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
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
    if hasToggle then
        local toggleBtn = Instance.new("ImageButton")
        toggleBtn.Size = UDim2.new(0, 40, 0, 40)
        toggleBtn.Position = UDim2.new(0, 20, 0, 20)
        toggleBtn.BackgroundColor3 = theme.Shade
        toggleBtn.Image = toggleIcon
        toggleBtn.BackgroundTransparency = 0.2
        toggleBtn.ZIndex = 50
        toggleBtn.Parent = screenGui
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
        getgenv().XELIB_ToggleBtn = toggleBtn
        local tStroke = Instance.new("UIStroke", toggleBtn)
        tStroke.Color = theme.Outline
        tStroke.Thickness = 2
        toggleBtn.MouseButton1Click:Connect(function()
            menuOpen = not menuOpen
            if menuOpen then
                mainFrame.Visible = true
                uiScale.Scale = 0.8
                Tween(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                Tween(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
            else
                local tw = Tween(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
                Tween(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                tw:Play()
                tw.Completed:Wait()
                if not menuOpen then mainFrame.Visible = false end
            end
        end)
    end
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == menuKey then
            menuOpen = not menuOpen
            if menuOpen then
                mainFrame.Visible = true
                uiScale.Scale = 0.8
                Tween(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                Tween(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
            else
                local tw = Tween(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
                Tween(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                tw:Play()
                tw.Completed:Wait()
                if not menuOpen then mainFrame.Visible = false end
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
                star.ZIndex = 1
                star.Parent = mainFrame
                Tween(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0), BackgroundTransparency = 1}):Play()
                task.delay(0.6, function() ReturnToPool("Star", star) end)
            end
            if effects.Trail then
                local trail = GetFromPool("Trail", "Frame")
                local corner = trail:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", trail)
                corner.CornerRadius = UDim.new(1, 0)
                trail.Size = UDim2.new(0, 10, 0, 10)
                trail.Position = UDim2.new(0, mLoc.X - mainFrame.AbsolutePosition.X - 5, 0, mLoc.Y - mainFrame.AbsolutePosition.Y - 5)
                trail.BackgroundColor3 = effectColors.Trail
                trail.ZIndex = 2
                trail.Parent = mainFrame
                Tween(trail, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}):Play()
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
                char.ZIndex = 1
                char.Parent = mainFrame
                Tween(char, TweenInfo.new(math.random(1, 3), Enum.EasingStyle.Linear), {Position = UDim2.new(char.Position.X.Scale, 0, 1.1, 0), TextTransparency = 1}):Play()
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
                Tween(hex, TweenInfo.new(2), {Size = UDim2.new(0, size, 0, size), ImageTransparency = 1, Rotation = 180}):Play()
                task.delay(2, function() ReturnToPool("Hex", hex) end)
            end
            if effects.Glitch and math.random(1, 10) == 1 then
                local g = GetFromPool("Glitch", "Frame")
                g.Size = UDim2.new(0, math.random(20, 100), 0, 2)
                g.Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0)
                g.BackgroundColor3 = effectColors.Glitch
                g.BackgroundTransparency = 0.5
                g.Parent = mainFrame
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
            Tween(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
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
            if oldest and oldest.Parent then oldest:Destroy() end
        end
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(1, 0, 0, 65)
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
        notif.Parent = notifContainer
        table.insert(activeNotifs, notif)
        Tween(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.1}):Play()
        Tween(stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
        Tween(tLbl, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
        Tween(dLbl, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
        task.delay(duration, function()
            if not notif or not notif.Parent then return end
            local idx = table.find(activeNotifs, notif)
            if idx then table.remove(activeNotifs, idx) end
            local tOut = Tween(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1})
            Tween(stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
            Tween(tLbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            Tween(dLbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            tOut:Play()
            tOut.Completed:Wait()
            if notif and notif.Parent then notif:Destroy() end
        end)
    end
    function Window:AddTab(name)
        tabCount = tabCount + 1
        local tabID = tabCount
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = name .. "_Tab"
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.BackgroundColor3 = theme.Button
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.Font = theme.Font
        tabBtn.TextSize = 16
        tabBtn.LayoutOrder = tabID
        tabBtn.Parent = tabContainer
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Button, tabBtn)
        table.insert(uiCache.Text, tabBtn)
        local btnStroke = Instance.new("UIStroke", tabBtn)
        btnStroke.Color = theme.ButtonOutline
        btnStroke.Thickness = 1
        table.insert(uiCache.ButtonOutline, btnStroke)
        tabBtn.MouseEnter:Connect(function()
            Tween(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        end)
        tabBtn.MouseLeave:Connect(function()
            Tween(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        end)
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
                v.Page.Visible = false
                v.Btn.BackgroundColor3 = theme.Button
            end
            page.Visible = true
            tabBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
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
            table.insert(uiCache.Shade, l)
            table.insert(uiCache.Text, l)
            return l
        end
        function Tab:AddParagraph(title, content)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 80)
            frame.BackgroundColor3 = theme.Shade
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
            c.Parent = frame
            table.insert(uiCache.Text, c)
        end
        function Tab:AddButton(text, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
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
            StyleButton(btn)
            btn.MouseButton1Click:Connect(function()
                local orig = btn.BackgroundColor3
                Tween(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
                task.delay(0.1, function()
                    Tween(btn, TweenInfo.new(0.2), {BackgroundColor3 = orig}):Play()
                end)
                if callback then callback() end
            end)
        end
        function Tab:AddToggle(text, default, callback)
            local enabled = default or false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 0.5
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
            lb.Parent = frame
            table.insert(uiCache.Text, lb)
            local bg = Instance.new("TextButton")
            bg.Name = "ToggleBG"
            bg.Size = UDim2.new(0, 45, 0, 25)
            bg.Position = UDim2.new(1, -55, 0.5, -12)
            bg.BackgroundColor3 = enabled and theme.Button or theme.Shade
            bg.Text = ""
            bg.Parent = frame
            Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
            local ball = Instance.new("Frame")
            ball.Size = UDim2.new(0, 17, 0, 17)
            ball.Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
            ball.BackgroundColor3 = Color3.new(1, 1, 1)
            ball.Parent = bg
            Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
            bg.MouseButton1Click:Connect(function()
                enabled = not enabled
                Tween(bg, TweenInfo.new(0.2), {BackgroundColor3 = enabled and theme.Button or theme.Shade}):Play()
                ball:TweenPosition(enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8), "Out", "Quad", 0.2, true)
                if callback then callback(enabled) end
            end)
        end
        function Tab:AddSlider(text, min, max, default, callback)
            local value = default or min
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 60)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 0.5
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
            local dragging = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (pos * (max - min)))
                    lb.Text = text .. ": " .. tostring(value)
                    fill.Size = UDim2.new(pos, 0, 1, 0)
                    knob.Position = UDim2.new(pos, -7, 0.5, -7)
                    if callback then callback(value) end
                end
            end)
        end
        function Tab:AddDropdown(text, options, callback)
            local selected = options[1] or ""
            local open = false
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
            btn.Parent = frame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            table.insert(uiCache.Shade, btn)
            table.insert(uiCache.Text, btn)
            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(0, 120, 0, 0)
            dropFrame.Position = UDim2.new(1, -135, 0.5, 15)
            dropFrame.BackgroundColor3 = theme.Shade
            dropFrame.ClipsDescendants = true
            dropFrame.ZIndex = 10
            dropFrame.Parent = frame
            Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
            local dropList = Instance.new("UIListLayout", dropFrame)
            dropList.Padding = UDim.new(0, 2)
            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundTransparency = 1
                optBtn.Text = opt
                optBtn.TextColor3 = Color3.new(1, 1, 1)
                optBtn.Font = theme.Font
                optBtn.TextSize = 14
                optBtn.ZIndex = 11
                optBtn.Parent = dropFrame
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    btn.Text = selected
                    open = false
                    Tween(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 120, 0, 0)}):Play()
                    if callback then callback(selected) end
                end)
            end
            btn.MouseButton1Click:Connect(function()
                open = not open
                local h = math.min(#options * 30, 150)
                Tween(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 120, 0, open and h or 0)}):Play()
            end)
        end
        function Tab:AddInput(text, default, callback)
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
            lb.Parent = frame
            table.insert(uiCache.Text, lb)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 120, 0, 30)
            box.Position = UDim2.new(1, -135, 0.5, -15)
            box.BackgroundColor3 = theme.Shade
            box.Text = default or ""
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = theme.Font
            box.TextSize = 14
            box.ClearTextOnFocus = false
            box.Parent = frame
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
            table.insert(uiCache.Shade, box)
            table.insert(uiCache.Text, box)
            box.FocusLost:Connect(function()
                if callback then callback(box.Text) end
            end)
        end
        function Tab:AddKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.Unknown
            local listening = false
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
            btn.Parent = frame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            table.insert(uiCache.Shade, btn)
            table.insert(uiCache.Text, btn)
            btn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                btn.Text = "..."
                btn.TextColor3 = theme.Button
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        conn:Disconnect()
                        currentKey = input.KeyCode
                        btn.Text = currentKey.Name
                        btn.TextColor3 = Color3.new(1, 1, 1)
                        listening = false
                        if callback then callback(currentKey) end
                    end
                end)
            end)
        end
        function Tab:AddColorPicker(text, defaultColor, callback)
            defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
            local curH, curS, curV = defaultColor:ToHSV()
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 50)
            frame.BackgroundColor3 = theme.Shade
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
            lb.Parent = frame
            table.insert(uiCache.Text, lb)
            local preview = Instance.new("TextButton")
            preview.Size = UDim2.new(0, 30, 0, 30)
            preview.Position = UDim2.new(1, -40, 0.5, -15)
            preview.BackgroundColor3 = defaultColor
            preview.Text = ""
            preview.Parent = frame
            Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
            local popup = Instance.new("Frame")
            popup.Size = UDim2.new(0, 200, 0, 200)
            popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            popup.ZIndex = 100
            popup.Visible = false
            popup.Active = true
            popup.Parent = mainFrame
            Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)
            local pStroke = Instance.new("UIStroke", popup)
            pStroke.Color = theme.Outline
            pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            local box = Instance.new("ImageButton")
            box.Size = UDim2.new(0, 150, 0, 150)
            box.Position = UDim2.new(0, 10, 0, 10)
            box.Image = "rbxassetid://4155801252"
            box.ImageColor3 = Color3.new(1, 1, 1)
            box.AutoButtonColor = false
            box.ZIndex = 101
            box.Parent = popup
            local cursorSV = Instance.new("Frame")
            cursorSV.Size = UDim2.new(0, 6, 0, 6)
            cursorSV.BackgroundColor3 = Color3.new(1, 1, 1)
            cursorSV.ZIndex = 102
            cursorSV.Parent = box
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
            hue.ZIndex = 101
            hue.Parent = popup
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
            cursorHue.ZIndex = 102
            cursorHue.Parent = hue
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
            txt.ZIndex = 101
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
                if callback then callback(c) end
            end
            update()
            preview.MouseButton1Click:Connect(function()
                popup.Visible = not popup.Visible
                if popup.Visible then
                    local abs = preview.AbsolutePosition - mainFrame.AbsolutePosition
                    popup.Position = UDim2.new(0, abs.X - 180, 0, abs.Y + 40)
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
                        popup.Visible = false
                    end
                end
            end)
        end
        return Tab
    end
    if hasSettings then
        local settingsTab = Window:AddTab("Settings")
        settingsTab:AddLabel("BACKGROUND EFFECTS")
        settingsTab:AddToggle("Enable Rain", false, function(t) effects.Rain = t end)
        settingsTab:AddColorPicker("Rain Color", effectColors.Rain, function(c) effectColors.Rain = c end)
        settingsTab:AddToggle("Enable Mouse Trail", false, function(t) effects.Trail = t end)
        settingsTab:AddColorPicker("Trail Color", effectColors.Trail, function(c) effectColors.Trail = c end)
        settingsTab:AddToggle("Enable Interactive Blobs", false, function(t) effects.Blob = t end)
        settingsTab:AddColorPicker("Blob Color", effectColors.Blob, function(c) effectColors.Blob = c end)
        settingsTab:AddToggle("Enable Matrix Rain", false, function(t) effects.Matrix = t end)
        settingsTab:AddColorPicker("Matrix Color", effectColors.Matrix, function(c) effectColors.Matrix = c end)
        settingsTab:AddToggle("Enable Floating Hexagons", false, function(t) effects.Hex = t end)
        settingsTab:AddColorPicker("Hex Color", effectColors.Hex, function(c) effectColors.Hex = c end)
        settingsTab:AddToggle("Enable Glitch Blocks", false, function(t) effects.Glitch = t end)
        settingsTab:AddColorPicker("Glitch Color", effectColors.Glitch, function(c) effectColors.Glitch = c end)
        settingsTab:AddLabel("APPEARANCE")
        settingsTab:AddKeybind("Menu Toggle Key", menuKey, function(newKey) menuKey = newKey end)
        local fonts = {Enum.Font.SourceSansBold, Enum.Font.Roboto, Enum.Font.GothamBold, Enum.Font.Arcade, Enum.Font.Code, Enum.Font.SciFi}
        local fontNames = {}
        for _, f in ipairs(fonts) do table.insert(fontNames, f.Name) end
        settingsTab:AddDropdown("Global Font", fontNames, function(selected)
            for _, f in ipairs(fonts) do
                if f.Name == selected then
                    theme.Font = f
                    for _, v in ipairs(uiCache.Text) do
                        if v and v.Parent then v.Font = f end
                    end
                    break
                end
            end
        end)
        settingsTab:AddColorPicker("Main Theme", theme.Main, function(c)
            theme.Main = c
            mainFrame.BackgroundColor3 = c
            titleLbl.TextColor3 = c
            mainStroke.Color = c
        end)
        settingsTab:AddColorPicker("UI Outline Color", theme.Outline, function(c)
            theme.Outline = c
            mainStroke.Color = c
            for _, v in ipairs(uiCache.ButtonOutline) do
                if v and v.Parent then v.Color = c end
            end
        end)
        settingsTab:AddColorPicker("Shade Color", theme.Shade, function(c)
            theme.Shade = c
            for _, v in ipairs(uiCache.Shade) do
                if v and v.Parent then v.BackgroundColor3 = c end
            end
        end)
        settingsTab:AddColorPicker("Button Color", theme.Button, function(c)
            theme.Button = c
            for _, v in ipairs(uiCache.Button) do
                if v and v.Parent then v.BackgroundColor3 = c end
            end
        end)
        settingsTab:AddColorPicker("Button Outline Color", theme.ButtonOutline, function(c)
            theme.ButtonOutline = c
            for _, v in ipairs(uiCache.ButtonOutline) do
                if v and v.Parent then v.Color = c end
            end
        end)
    end
    return Window
end
return XELIB
