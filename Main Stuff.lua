local player = game.Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
local plrMouse = player:GetMouse()
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local menuKey = Enum.KeyCode.RightControl
local mainTheme = Color3.fromRGB(0, 255, 255)
local shadeColor = Color3.fromRGB(25, 55, 95)
local outlineColor = Color3.fromRGB(0, 255, 255)
local buttonColor = Color3.fromRGB(0, 200, 255)
local buttonOutlineColor = Color3.fromRGB(0, 255, 255)
local globalFont = Enum.Font.SourceSansBold

local starsEnabled = false
local trailsEnabled = false
local blobsEnabled = false
local matrixEnabled = false
local hexEnabled = false
local glitchEnabled = false 

local rainCol = Color3.fromRGB(255, 255, 255)
local trailCol = Color3.fromRGB(0, 255, 255)
local blobCol = Color3.fromRGB(0, 20, 100)
local matrixCol = Color3.fromRGB(0, 255, 0)
local hexCol = Color3.fromRGB(0, 255, 255)
local glitchCol = Color3.fromRGB(255, 255, 255)

local TITLE_SIZE = 22
local TAB_SIZE = 16
local LABEL_SIZE = 18

local uiCache = {
    Shade = {},
    Button = {},
    ButtonOutline = {},
    TextElements = {}
}

local pool = { Star = {}, Trail = {}, Matrix = {}, Hex = {}, Glitch = {}, Blob = {} }

local function GetFromPool(effectType, instanceType)
    if #pool[effectType] > 0 then
        local obj = table.remove(pool[effectType])
        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("TextLabel") then
            obj.BackgroundTransparency = 0
            obj.Size = UDim2.new(0, 0, 0, 0)
        end
        if obj:IsA("TextLabel") then obj.TextTransparency = 0 end
        if obj:IsA("ImageLabel") then obj.ImageTransparency = 0 end
        obj.Visible = true
        return obj
    else
        return Instance.new(instanceType)
    end
end

local function ReturnToPool(effectType, obj)
    obj.Visible = false
    obj.Parent = nil
    table.insert(pool[effectType], obj)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = HttpService:GenerateGUID(false) 
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 

if gethui then
    screenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = pGui
else
    screenGui.Parent = pGui
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = HttpService:GenerateGUID(false)
mainFrame.Size = UDim2.new(0, 1000, 0, 750)
mainFrame.Position = UDim2.new(0.5, -500, 0.5, -375)
mainFrame.BackgroundColor3 = mainTheme
mainFrame.BackgroundTransparency = 0.4
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local uiScale = Instance.new("UIScale")
uiScale.Parent = mainFrame
uiScale.Scale = 1

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = outlineColor
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Parent = mainFrame

local function ApplyButtonStroke(btn)
    local stroke = Instance.new("UIStroke")
    stroke.Name = "ButtonStroke"
    stroke.Color = buttonOutlineColor
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn
    table.insert(uiCache.ButtonOutline, stroke)
end

local function ApplyButtonInteraction(btn)
    btn.MouseEnter:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    end)
end

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "XeNOX Library"
title.TextColor3 = mainTheme
title.TextSize = TITLE_SIZE
title.Font = Enum.Font.LuckiestGuy
title.ZIndex = 5
title.Active = true
title.Parent = mainFrame

local dragging, dragInput, dragStart, startPos
local dragConnection

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        dragConnection = uis.InputChanged:Connect(function(changedInput)
            if changedInput == dragInput and dragging then
                local delta = changedInput.Position - dragStart
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = false 
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
    end
end)

local titleGlow = Instance.new("UIStroke")
titleGlow.Thickness = 0
titleGlow.Color = mainTheme
titleGlow.Transparency = 1
titleGlow.Enabled = false
titleGlow.Parent = title

task.spawn(function()
    while task.wait() do
        if titleGlow.Enabled then
            local pulse = (math.sin(tick() * 5) + 1) / 2
            titleGlow.Thickness = 1 + (pulse * 5)
            titleGlow.Transparency = 0.1 + (pulse * 0.5)
        end
    end
end)

local function UpdateGlobalFont(newFont)
    globalFont = newFont
    local valid = {}
    for _, v in ipairs(uiCache.TextElements) do
        if v and v.Parent then
            v.Font = newFont
            table.insert(valid, v)
        end
    end
    uiCache.TextElements = valid
end

local function UpdateUITheme(color)
    mainTheme = color
    mainFrame.BackgroundColor3 = color
    title.TextColor3 = color
    titleGlow.Color = color
end

local function UpdateOutlineTheme(color)
    outlineColor = color
    uiStroke.Color = color
end

local function UpdateButtonTheme(color)
    buttonColor = color
    local valid = {}
    for _, v in ipairs(uiCache.Button) do
        if v and v.Parent then
            v.BackgroundColor3 = color
            table.insert(valid, v)
        end
    end
    uiCache.Button = valid
end

local function UpdateButtonOutlineTheme(color)
    buttonOutlineColor = color
    local valid = {}
    for _, v in ipairs(uiCache.ButtonOutline) do
        if v and v.Parent then
            v.Color = color
            table.insert(valid, v)
        end
    end
    uiCache.ButtonOutline = valid
end

local function UpdateShadeTheme(newShade)
    shadeColor = newShade
    local valid = {}
    for _, v in ipairs(uiCache.Shade) do
        if v and v.Parent then
            v.BackgroundColor3 = newShade
            table.insert(valid, v)
        end
    end
    uiCache.Shade = valid
end

local folderName = "XeNOX_Configs"
pcall(function()
    if writefile and not isfolder(folderName) then makefolder(folderName) end
end)
local selectedConfig = ""
local function GetPath(name) return folderName .. "/" .. name .. ".json" end

local function SaveSettings(name)
    if name == "" then return end
    local data = {
        Keybind = menuKey.Name,
        Theme = {mainTheme.R, mainTheme.G, mainTheme.B},
        Shade = {shadeColor.R, shadeColor.G, shadeColor.B},
        Outline = {outlineColor.R, outlineColor.G, outlineColor.B},
        Button = {buttonColor.R, buttonColor.G, buttonColor.B},
        ButtonOutline = {buttonOutlineColor.R, buttonOutlineColor.G, buttonOutlineColor.B},
        Font = globalFont.Name,
        States = { Rain = starsEnabled, Trail = trailsEnabled, Blob = blobsEnabled, Matrix = matrixEnabled, Hex = hexEnabled, Glitch = glitchEnabled },
        Colors = { Rain = {rainCol.R, rainCol.G, rainCol.B}, Trail = {trailCol.R, trailCol.G, trailCol.B}, Blob = {blobCol.R, blobCol.G, blobCol.B}, Matrix = {matrixCol.R, matrixCol.G, matrixCol.B}, Hex = {hexCol.R, hexCol.G, hexCol.B}, Glitch = {glitchCol.R, glitchCol.G, glitchCol.B} }
    }
    pcall(function() writefile(GetPath(name), HttpService:JSONEncode(data)) end)
end

task.spawn(function()
    while task.wait(0.03) do 
        if not screenGui.Parent then break end
        if not mainFrame.Visible then continue end

        local mLoc = uis:GetMouseLocation()

        if starsEnabled then
            local star = GetFromPool("Star", "Frame")
            star.Size = UDim2.new(0, 1, 0, math.random(30, 80))
            star.Position = UDim2.new(math.random(0, 100)/100, 0, -0.2, 0)
            star.BackgroundColor3 = rainCol
            star.ZIndex = 1
            star.Parent = mainFrame
            tweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0), BackgroundTransparency = 1}):Play()
            task.delay(0.6, function() ReturnToPool("Star", star) end)
        end

        if trailsEnabled then
            local trail = GetFromPool("Trail", "Frame")
            local corner = trail:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", trail)
            corner.CornerRadius = UDim.new(1, 0)
            trail.Size = UDim2.new(0, 10, 0, 10)
            trail.Position = UDim2.new(0, mLoc.X - mainFrame.AbsolutePosition.X - 5, 0, mLoc.Y - mainFrame.AbsolutePosition.Y - 5)
            trail.BackgroundColor3 = trailCol
            trail.ZIndex = 2
            trail.Parent = mainFrame
            tweenService:Create(trail, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}):Play()
            task.delay(0.4, function() ReturnToPool("Trail", trail) end)
        end

        if matrixEnabled and math.random(1, 5) == 1 then
            local char = GetFromPool("Matrix", "TextLabel")
            char.Size = UDim2.new(0, 20, 0, 20)
            char.Position = UDim2.new(math.random(0, 100)/100, 0, -0.1, 0)
            char.BackgroundTransparency = 1
            char.Text = string.char(math.random(33, 126))
            char.TextColor3 = matrixCol
            char.Font = Enum.Font.Code
            char.TextSize = 15
            char.ZIndex = 1
            char.Parent = mainFrame
            tweenService:Create(char, TweenInfo.new(math.random(1, 3), Enum.EasingStyle.Linear), {Position = UDim2.new(char.Position.X.Scale, 0, 1.1, 0), TextTransparency = 1}):Play()
            task.delay(3, function() ReturnToPool("Matrix", char) end)
        end

        if hexEnabled and math.random(1, 15) == 1 then
            local hex = GetFromPool("Hex", "ImageLabel")
            hex.Size = UDim2.new(0, 0, 0, 0)
            hex.Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0)
            hex.Image = "rbxassetid://6073628820"
            hex.ImageColor3 = hexCol
            hex.BackgroundTransparency = 1
            hex.ImageTransparency = 0.8
            hex.Rotation = 0
            hex.ZIndex = 1
            hex.Parent = mainFrame
            local size = math.random(50, 150)
            tweenService:Create(hex, TweenInfo.new(2), {Size = UDim2.new(0, size, 0, size), ImageTransparency = 1, Rotation = 180}):Play()
            task.delay(2, function() ReturnToPool("Hex", hex) end)
        end

        if glitchEnabled and math.random(1, 10) == 1 then
            local g = GetFromPool("Glitch", "Frame")
            g.Size = UDim2.new(0, math.random(20, 100), 0, 2)
            g.Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0)
            g.BackgroundColor3 = glitchCol
            g.BackgroundTransparency = 0.5
            g.Parent = mainFrame
            task.delay(0.1, function() ReturnToPool("Glitch", g) end)
        end

        if blobsEnabled then
            local blob = GetFromPool("Blob", "ImageLabel")
            blob.Size = UDim2.new(math.random(2, 5)/10, 0, math.random(2, 5)/10, 0)
            blob.Position = UDim2.new(math.random(-1, 9)/10, 0, math.random(-1, 9)/10, 0)
            blob.Image = "rbxassetid://232918622"
            blob.ImageColor3 = blobCol
            blob.BackgroundTransparency = 1
            blob.ImageTransparency = 0.93
            blob.ZIndex = 1
            blob.Parent = mainFrame
            task.spawn(function()
                local start = tick()
                while tick() - start < 3 do
                    if not blob or not blob.Parent or not blobsEnabled then break end
                    local currentMouse = uis:GetMouseLocation()
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

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundTransparency = 1; closeBtn.Text = "-"; closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.TextSize = 35; closeBtn.Font = Enum.Font.SourceSansBold; closeBtn.ZIndex = 20; closeBtn.Parent = mainFrame

local isMin = false
closeBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    uiStroke.Enabled = not isMin
    titleGlow.Enabled = isMin
    title.ZIndex = isMin and 25 or 5
    mainFrame:TweenSize(isMin and UDim2.new(0, 1000, 0, 50) or UDim2.new(0, 1000, 0, 750), "Out", "Quad", 0.3, true)
end)

local notifContainer = Instance.new("Frame")
notifContainer.Name = "NotifContainer"
notifContainer.Size = UDim2.new(0, 300, 1, -40)
notifContainer.Position = UDim2.new(1, -320, 0, 20)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 100
notifContainer.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 10)
notifLayout.Parent = notifContainer

_G.XeNOX = {}
local activeNotifs = {}

function _G.XeNOX:Notify(titleText, descText, duration)
    duration = duration or 3
    
    if #activeNotifs >= 4 then
        local oldest = table.remove(activeNotifs, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 65)
    notif.BackgroundColor3 = shadeColor
    notif.BackgroundTransparency = 1 
    notif.Position = UDim2.new(1, 50, 0, 0)
    notif.ZIndex = 105
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", notif)
    stroke.Color = outlineColor
    stroke.Thickness = 2
    stroke.Transparency = 1

    local titleLbl = Instance.new("TextLabel", notif)
    titleLbl.Size = UDim2.new(1, -20, 0, 25)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.TextColor3 = mainTheme
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Font = globalFont
    titleLbl.TextSize = 18
    titleLbl.TextTransparency = 1
    titleLbl.ZIndex = 106

    local desc = Instance.new("TextLabel", notif)
    desc.Size = UDim2.new(1, -20, 0, 25)
    desc.Position = UDim2.new(0, 10, 0, 30)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Color3.new(1, 1, 1)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Font = globalFont
    desc.TextSize = 14
    desc.TextTransparency = 1
    desc.ZIndex = 106

    notif.Parent = notifContainer
    table.insert(activeNotifs, notif)

    local tIn = tweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.1})
    tweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
    tweenService:Create(titleLbl, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    tweenService:Create(desc, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    tIn:Play()

    task.delay(duration, function()
        if not notif or not notif.Parent then return end
        table.remove(activeNotifs, table.find(activeNotifs, notif) or 1)
        local tOut = tweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1})
        tweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
        tweenService:Create(titleLbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        tweenService:Create(desc, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        tOut:Play()
        tOut.Completed:Wait()
        notif:Destroy()
    end)
end

local tabs = {}
local tabCount = 0

function _G.XeNOX:CreateTab(name)
    tabCount = tabCount + 1
    local tabID = tabCount
    
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "TabBtn" 
    tabBtn.Size = UDim2.new(0, 160, 0, 45)
    tabBtn.Position = UDim2.new(0, 15, 0, 50 + (tabCount - 1) * 50)
    tabBtn.BackgroundColor3 = buttonColor 
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.Font = globalFont
    tabBtn.TextSize = TAB_SIZE
    tabBtn.Parent = mainFrame
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
    
    table.insert(uiCache.Button, tabBtn)
    table.insert(uiCache.TextElements, tabBtn)
    ApplyButtonStroke(tabBtn)
    ApplyButtonInteraction(tabBtn)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"; page.Size = UDim2.new(0, 780, 0, 670); page.Position = UDim2.new(0, 195, 0, 55)
    page.BackgroundTransparency = 1; page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = mainTheme; page.Visible = (tabID == 1); page.Parent = mainFrame

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end)
    
    tabs[tabID] = {Page = page, Btn = tabBtn}
    tabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(tabs) do v.Page.Visible = false end
        page.Visible = true
    end)

    local tabObj = {}

    function tabObj:CreateButton(text, callback)
        local btnFrame = Instance.new("Frame")
        btnFrame.Name = "ButtonRow"
        btnFrame.Size = UDim2.new(1, -20, 0, 50)
        btnFrame.BackgroundColor3 = shadeColor
        btnFrame.BackgroundTransparency = 0.5
        btnFrame.Parent = page
        Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, btnFrame)

        local btn = Instance.new("TextButton")
        btn.Name = "CustomButton"
        btn.Size = UDim2.new(1, -16, 1, -16) 
        btn.Position = UDim2.new(0, 8, 0, 8) 
        btn.BackgroundColor3 = buttonColor
        btn.Text = text
        btn.TextColor3 = Color3.new(0, 0, 0)
        btn.Font = globalFont
        btn.TextSize = TAB_SIZE
        btn.Parent = btnFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        table.insert(uiCache.Button, btn)
        table.insert(uiCache.TextElements, btn)
        ApplyButtonStroke(btn)
        ApplyButtonInteraction(btn)

        btn.MouseButton1Click:Connect(function()
            local originalColor = btn.BackgroundColor3
            tweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
            task.delay(0.1, function()
                tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
            end)
            callback()
        end)
    end
    
    function tabObj:CreateLabel(text)
        local l = Instance.new("TextLabel")
        l.Name = "LabelElement"; l.Size = UDim2.new(1, -20, 0, 45); l.BackgroundColor3 = shadeColor; l.Text = text; l.TextColor3 = Color3.new(1,1,1); l.Font = globalFont; l.TextSize = LABEL_SIZE; l.Parent = page
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
        
        table.insert(uiCache.Shade, l)
        table.insert(uiCache.TextElements, l)
    end

    function tabObj:CreateToggle(text, default, callback)
        local enabled = default
        local tgl = Instance.new("Frame")
        tgl.Size = UDim2.new(1, -20, 0, 50); tgl.BackgroundColor3 = Color3.new(0,0,0); tgl.BackgroundTransparency = 0.5; tgl.Parent = page; Instance.new("UICorner", tgl).CornerRadius = UDim.new(0, 8)
        
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -60, 1, 0); lb.Position = UDim2.new(0, 15, 0, 0); lb.Text = text; lb.TextColor3 = Color3.new(1,1,1); lb.Font = globalFont; lb.TextSize = LABEL_SIZE; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = tgl
        table.insert(uiCache.TextElements, lb)
        
        local bg = Instance.new("TextButton")
        bg.Name = "ToggleBG"; bg.Size = UDim2.new(0, 45, 0, 25); bg.Position = UDim2.new(1, -55, 0.5, -12); bg.BackgroundColor3 = enabled and buttonColor or shadeColor; bg.Text = ""; bg.Parent = tgl; Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
        ApplyButtonStroke(bg)
        ApplyButtonInteraction(bg)

        local ball = Instance.new("Frame")
        ball.Size = UDim2.new(0, 17, 0, 17); ball.Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8); ball.BackgroundColor3 = Color3.new(1,1,1); ball.Parent = bg; Instance.new("UICorner", ball).CornerRadius = UDim.new(1,0)
        
        bg.MouseButton1Click:Connect(function()
            enabled = not enabled
            tweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = enabled and buttonColor or shadeColor}):Play()
            ball:TweenPosition(enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8), "Out", "Quad", 0.2, true)
            callback(enabled)
        end)
    end

    function tabObj:CreateKeybind(text, defaultKey, callback)
        local currentKey = defaultKey
        local listening = false

        local kbFrame = Instance.new("Frame")
        kbFrame.Size = UDim2.new(1, -20, 0, 50); kbFrame.BackgroundColor3 = Color3.new(0,0,0); kbFrame.BackgroundTransparency = 0.5; kbFrame.Parent = page; Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0, 8)
        
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -160, 1, 0); lb.Position = UDim2.new(0, 15, 0, 0); lb.Text = text; lb.TextColor3 = Color3.new(1,1,1); lb.Font = globalFont; lb.TextSize = LABEL_SIZE; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = kbFrame
        table.insert(uiCache.TextElements, lb)
        
        local btn = Instance.new("TextButton")
        btn.Name = "BindBtn"; btn.Size = UDim2.new(0, 120, 0, 30); btn.Position = UDim2.new(1, -135, 0.5, -15); btn.BackgroundColor3 = shadeColor; btn.Text = currentKey.Name; btn.TextColor3 = Color3.new(1,1,1); btn.Font = globalFont; btn.TextSize = TAB_SIZE; btn.Parent = kbFrame; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        table.insert(uiCache.Shade, btn)
        table.insert(uiCache.TextElements, btn)
        ApplyButtonStroke(btn)
        ApplyButtonInteraction(btn)

        btn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            btn.Text = "..."
            btn.TextColor3 = buttonColor
            
            local connection
            connection = uis.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    connection:Disconnect()
                    currentKey = input.KeyCode
                    btn.Text = currentKey.Name
                    btn.TextColor3 = Color3.new(1,1,1)
                    listening = false
                    callback(currentKey)
                end
            end)
        end)
    end

    function tabObj:CreateFontPicker(text, callback)
        local fp = Instance.new("Frame")
        fp.Size = UDim2.new(1, -20, 0, 120); fp.BackgroundColor3 = Color3.new(0,0,0); fp.BackgroundTransparency = 0.5; fp.Parent = page; Instance.new("UICorner", fp).CornerRadius = UDim.new(0, 8)
        
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -20, 0, 30); lb.Position = UDim2.new(0, 10, 0, 5); lb.Text = text; lb.TextColor3 = Color3.new(1,1,1); lb.Font = globalFont; lb.TextSize = LABEL_SIZE; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = fp
        table.insert(uiCache.TextElements, lb)
        
        local container = Instance.new("ScrollingFrame")
        container.Size = UDim2.new(1, -20, 0, 70); container.Position = UDim2.new(0, 10, 0, 40); container.BackgroundTransparency = 0.8; container.BackgroundColor3 = Color3.new(0,0,0); container.ScrollBarThickness = 4; container.CanvasSize = UDim2.new(2, 0, 0, 0); container.Parent = fp
        local listLayout = Instance.new("UIListLayout", container); listLayout.FillDirection = Enum.FillDirection.Horizontal; listLayout.Padding = UDim.new(0, 10)
        local fonts = {Enum.Font.SourceSansBold, Enum.Font.Roboto, Enum.Font.GothamBold, Enum.Font.Arcade, Enum.Font.Code, Enum.Font.SciFi}
        for _, f in pairs(fonts) do
            local b = Instance.new("TextButton")
            b.Name = "ActionBtn"
            b.Size = UDim2.new(0, 100, 0, 40); b.Text = f.Name; b.Font = f; b.BackgroundColor3 = buttonColor; b.TextColor3 = Color3.new(0,0,0); b.Parent = container; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            
            table.insert(uiCache.Button, b)
            table.insert(uiCache.TextElements, b)
            ApplyButtonStroke(b)
            ApplyButtonInteraction(b)
            b.MouseButton1Click:Connect(function() callback(f) end)
        end
    end

    function tabObj:CreateColorPicker(text, defaultColor, callback)
        local cpRow = Instance.new("Frame")
        cpRow.Name = "ColorRow"
        cpRow.Size = UDim2.new(1, -20, 0, 45)
        cpRow.BackgroundColor3 = shadeColor
        cpRow.Parent = page
        Instance.new("UICorner", cpRow).CornerRadius = UDim.new(0, 8)
        table.insert(uiCache.Shade, cpRow)
        
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -60, 1, 0)
        lb.Position = UDim2.new(0, 15, 0, 0)
        lb.Text = text
        lb.TextColor3 = Color3.new(1, 1, 1)
        lb.Font = globalFont
        lb.TextSize = LABEL_SIZE
        lb.BackgroundTransparency = 1
        lb.TextXAlignment = "Left"
        lb.Parent = cpRow
        table.insert(uiCache.TextElements, lb)
        
        local previewBtn = Instance.new("TextButton")
        previewBtn.Name = "PreviewBtn"
        previewBtn.Size = UDim2.new(0, 30, 0, 30)
        previewBtn.Position = UDim2.new(1, -40, 0.5, -15)
        previewBtn.BackgroundColor3 = defaultColor
        previewBtn.Text = ""
        previewBtn.Parent = cpRow
        Instance.new("UICorner", previewBtn).CornerRadius = UDim.new(0, 6)
        ApplyButtonStroke(previewBtn)
        ApplyButtonInteraction(previewBtn)

        local popup = Instance.new("Frame")
        popup.Size = UDim2.new(0, 200, 0, 200)
        popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25) 
        popup.ZIndex = 100
        popup.Visible = false
        popup.Active = true 
        popup.Parent = mainFrame
        Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)

        local popupStroke = Instance.new("UIStroke")
        popupStroke.Color = outlineColor
        popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        popupStroke.Parent = popup

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
        local cursorSVStroke = Instance.new("UIStroke", cursorSV)
        cursorSVStroke.Color = Color3.new(0, 0, 0)
        cursorSVStroke.Thickness = 1

        local hue = Instance.new("TextButton")
        hue.Size = UDim2.new(0, 20, 0, 150)
        hue.Position = UDim2.new(0, 170, 0, 10)
        hue.BackgroundColor3 = Color3.new(1, 1, 1)
        hue.Text = ""
        hue.AutoButtonColor = false
        hue.ZIndex = 101
        hue.Parent = popup
        
        local hueGradient = Instance.new("UIGradient")
        hueGradient.Rotation = 90
        hueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))
        })
        hueGradient.Parent = hue
        
        local cursorHue = Instance.new("Frame")
        cursorHue.Size = UDim2.new(1, 4, 0, 3)
        cursorHue.Position = UDim2.new(0, -2, 0, 0)
        cursorHue.BackgroundColor3 = Color3.new(1, 1, 1)
        cursorHue.ZIndex = 102
        cursorHue.Parent = hue
        local cursorHueStroke = Instance.new("UIStroke", cursorHue)
        cursorHueStroke.Color = Color3.new(0, 0, 0)
        cursorHueStroke.Thickness = 1

        local textDisplay = Instance.new("TextLabel")
        textDisplay.Size = UDim2.new(1, -20, 0, 30)
        textDisplay.Position = UDim2.new(0, 10, 0, 165)
        textDisplay.BackgroundTransparency = 1
        textDisplay.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        textDisplay.Font = Enum.Font.Code
        textDisplay.TextSize = 14
        textDisplay.TextXAlignment = Enum.TextXAlignment.Left
        textDisplay.ZIndex = 101
        textDisplay.Parent = popup
        table.insert(uiCache.TextElements, textDisplay)

        local curH, curS, curV = defaultColor:ToHSV()
        
        local function upd()
            local c = Color3.fromHSV(curH, curS, curV)
            box.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
            previewBtn.BackgroundColor3 = c
            
            cursorSV.Position = UDim2.new(curS, -3, 1 - curV, -3)
            cursorHue.Position = UDim2.new(0, -2, curH, -1) 
            
            local r, g, b = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
            textDisplay.Text = string.format("#%02X%02X%02X   %d, %d, %d", r, g, b, r, g, b)
            
            callback(c)
        end
        upd()

        previewBtn.MouseButton1Click:Connect(function()
            popup.Visible = not popup.Visible
            if popup.Visible then
                local absPos = previewBtn.AbsolutePosition - mainFrame.AbsolutePosition
                popup.Position = UDim2.new(0, absPos.X - 180, 0, absPos.Y + 40)
            end
        end)

        local draggingHue, draggingSV = false, false
        local dragLoop

        local function updateHSV()
            if draggingHue then
                curH = math.clamp((plrMouse.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
            elseif draggingSV then
                curS = math.clamp((plrMouse.X - box.AbsolutePosition.X) / box.AbsoluteSize.X, 0, 1)
                curV = 1 - math.clamp((plrMouse.Y - box.AbsolutePosition.Y) / box.AbsoluteSize.Y, 0, 1)
            end
            upd()
        end

        local function startDrag()
            if dragLoop then dragLoop:Disconnect() end
            dragLoop = runService.RenderStepped:Connect(updateHSV)
        end
        
        local function stopDrag()
            if dragLoop then dragLoop:Disconnect(); dragLoop = nil end
        end

        hue.MouseButton1Down:Connect(function() draggingHue = true; startDrag() end)
        box.MouseButton1Down:Connect(function() draggingSV = true; startDrag() end)

        uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingHue = false
                draggingSV = false
                stopDrag()
            end
        end)

        uis.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and popup.Visible then
                local mx, my = plrMouse.X, plrMouse.Y
                local px, py = popup.AbsolutePosition.X, popup.AbsolutePosition.Y
                local bx, by = previewBtn.AbsolutePosition.X, previewBtn.AbsolutePosition.Y
                
                local inPopup = (mx >= px and mx <= px + popup.AbsoluteSize.X and my >= py and my <= py + popup.AbsoluteSize.Y)
                local inBtn = (mx >= bx and mx <= bx + previewBtn.AbsoluteSize.X and my >= by and my <= by + previewBtn.AbsoluteSize.Y)
                
                if not inPopup and not inBtn then
                    popup.Visible = false
                end
            end
        end)
    end

    function tabObj:CreateConfigManager()
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 340); container.BackgroundColor3 = Color3.new(0,0,0); container.BackgroundTransparency = 0.5; container.Parent = page; Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        
        local status = Instance.new("TextLabel"); status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25); status.BackgroundTransparency = 1; status.Text = "Status: Idle"; status.TextColor3 = Color3.new(0.7,0.7,0.7); status.Font = globalFont; status.TextSize = 14; status.Parent = container
        table.insert(uiCache.TextElements, status)
        
        local input = Instance.new("TextBox"); input.Size = UDim2.new(0.6, 0, 0, 40); input.Position = UDim2.new(0, 10, 0, 10); input.PlaceholderText = "New Config Name..."; input.BackgroundColor3 = Color3.fromRGB(30,30,30); input.TextColor3 = Color3.new(1,1,1); input.Font = globalFont; input.TextSize = 20; input.Parent = container; Instance.new("UICorner", input).CornerRadius = UDim.new(0, 2)
        table.insert(uiCache.TextElements, input)
        
        local save = Instance.new("TextButton"); save.Name = "ActionBtn"; save.Size = UDim2.new(0.35, -5, 0, 40); save.Position = UDim2.new(0.6, 15, 0, 10); save.Text = "CREATE"; save.BackgroundColor3 = buttonColor; save.TextColor3 = Color3.new(0,0,0); save.Font = globalFont; save.TextSize = 20; save.Parent = container; Instance.new("UICorner", save).CornerRadius = UDim.new(0, 2)
        table.insert(uiCache.Button, save)
        table.insert(uiCache.TextElements, save)
        ApplyButtonStroke(save)
        ApplyButtonInteraction(save)

        local list = Instance.new("ScrollingFrame"); list.Size = UDim2.new(1, -20, 0, 130); list.Position = UDim2.new(0, 10, 0, 60); list.BackgroundTransparency = 0.8; list.BackgroundColor3 = Color3.new(0,0,0); list.ScrollBarThickness = 4; list.Parent = container; Instance.new("UIListLayout", list)
        
        local function refreshList()
            for _, v in pairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            pcall(function()
                if listfiles then
                    local files = listfiles(folderName)
                    for _, file in pairs(files) do
                        local name = file:gsub(folderName.."/", ""):gsub(".json", ""):gsub(folderName.."\\", "")
                        local b = Instance.new("TextButton"); b.Name = "ConfigBtn"; b.Size = UDim2.new(1, 0, 0, 35); b.Text = name; b.BackgroundColor3 = buttonColor; b.TextColor3 = Color3.new(0,0,0); b.Font = globalFont; b.Parent = list; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
                        
                        table.insert(uiCache.Button, b)
                        table.insert(uiCache.TextElements, b)
                        ApplyButtonStroke(b)
                        ApplyButtonInteraction(b)
                        b.MouseButton1Click:Connect(function() selectedConfig = name; for _, x in pairs(list:GetChildren()) do if x:IsA("TextButton") then x.BackgroundColor3 = buttonColor end end; b.BackgroundColor3 = Color3.fromRGB(200, 200, 200); status.Text = "Selected: " .. name end)
                    end
                end
            end)
        end
        local actions = { Load = {Pos = UDim2.new(0, 10, 0, 210), Text = "LOAD"}, Update = {Pos = UDim2.new(0.34, 10, 0, 210), Text = "UPDATE"}, Delete = {Pos = UDim2.new(0.68, 10, 0, 210), Text = "DELETE"} }
        for i, info in pairs(actions) do
            local btn = Instance.new("TextButton"); btn.Name = "ActionBtn"; btn.Size = UDim2.new(0.3, 0, 0, 45); btn.Position = info.Pos; btn.Text = info.Text; btn.BackgroundColor3 = buttonColor; btn.TextColor3 = Color3.new(0,0,0); btn.Font = globalFont; btn.Parent = container; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            
            table.insert(uiCache.Button, btn)
            table.insert(uiCache.TextElements, btn)
            ApplyButtonStroke(btn)
            ApplyButtonInteraction(btn)
            btn.MouseButton1Click:Connect(function()
                if selectedConfig == "" then 
                    status.Text = "Error: Select a config first!" 
                    _G.XeNOX:Notify("Error", "Please select a config to interact with.", 3)
                    return 
                end
                local path = GetPath(selectedConfig)
                
                if i == "Load" and isfile(path) then
                    local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
                    if not success or not data then
                        status.Text = "Error: Config corrupted!"
                        _G.XeNOX:Notify("Error", "Config profile structure is corrupted or unreadable.", 3)
                        return
                    end
                    
                    UpdateUITheme(Color3.new(unpack(data.Theme))); UpdateShadeTheme(Color3.new(unpack(data.Shade))); UpdateOutlineTheme(Color3.new(unpack(data.Outline))); UpdateGlobalFont(Enum.Font[data.Font])
                    if data.Button then UpdateButtonTheme(Color3.new(unpack(data.Button))) end
                    if data.ButtonOutline then UpdateButtonOutlineTheme(Color3.new(unpack(data.ButtonOutline))) end
                    starsEnabled = data.States.Rain; trailsEnabled = data.States.Trail; blobsEnabled = data.States.Blob; matrixEnabled = data.States.Matrix; hexEnabled = data.States.Hex; glitchEnabled = data.States.Glitch
                    rainCol = Color3.new(unpack(data.Colors.Rain)); trailCol = Color3.new(unpack(data.Colors.Trail)); blobCol = Color3.new(unpack(data.Colors.Blob)); matrixCol = Color3.new(unpack(data.Colors.Matrix)); hexCol = Color3.new(unpack(data.Colors.Hex)); glitchCol = Color3.new(unpack(data.Colors.Glitch))
                    if data.Keybind then menuKey = Enum.KeyCode[data.Keybind] end
                    status.Text = "Status: Loaded " .. selectedConfig
                    _G.XeNOX:Notify("Loaded", "Successfully loaded " .. selectedConfig, 3)
                elseif i == "Update" then 
                    SaveSettings(selectedConfig); status.Text = "Status: Updated " .. selectedConfig 
                    _G.XeNOX:Notify("Updated", "Successfully updated " .. selectedConfig, 3)
                elseif i == "Delete" then 
                    if isfile(path) then pcall(delfile, path) end; status.Text = "Status: Deleted " .. selectedConfig; selectedConfig = ""; refreshList() 
                    _G.XeNOX:Notify("Deleted", "Deleted config successfully.", 3)
                end
            end)
        end
        save.MouseButton1Click:Connect(function() 
            if input.Text ~= "" then 
                SaveSettings(input.Text); 
                _G.XeNOX:Notify("Created", "Successfully created config: " .. input.Text, 3)
                input.Text = ""; 
                refreshList() 
            else
                _G.XeNOX:Notify("Error", "Config name cannot be empty.", 3)
            end 
        end)
        refreshList()
    end
    
    return tabObj
end

local m = _G.XeNOX:CreateTab("Main")
m:CreateLabel("Welcome to XeNOX Library")
m:CreateButton("Example Button", function() 
    _G.XeNOX:Notify("Test", "Example button clicked successfully", 3)
end)

local s = _G.XeNOX:CreateTab("Settings")
s:CreateConfigManager()
s:CreateLabel("BACKGROUND EFFECTS")
s:CreateToggle("Enable Rain", false, function(t) starsEnabled = t end)
s:CreateColorPicker("Rain Color", rainCol, function(c) rainCol = c end)
s:CreateToggle("Enable Mouse Trail", false, function(t) trailsEnabled = t end)
s:CreateColorPicker("Trail Color", trailCol, function(c) trailCol = c end)
s:CreateToggle("Enable Interactive Blobs", false, function(t) blobsEnabled = t end)
s:CreateColorPicker("Blob Color", blobCol, function(c) blobCol = c end)
s:CreateToggle("Enable Matrix Rain", false, function(t) matrixEnabled = t end)
s:CreateColorPicker("Matrix Color", matrixCol, function(c) matrixCol = c end)
s:CreateToggle("Enable Floating Hexagons", false, function(t) hexEnabled = t end)
s:CreateColorPicker("Hex Color", hexCol, function(c) hexCol = c end)
s:CreateToggle("Enable Glitch Blocks", false, function(t) glitchEnabled = t end)
s:CreateColorPicker("Glitch Color", glitchCol, function(c) glitchCol = c end)

s:CreateLabel("APPEARANCE")
s:CreateKeybind("Menu Toggle Key", menuKey, function(newKey) menuKey = newKey end)
s:CreateFontPicker("Global Font", function(f) UpdateGlobalFont(f) end)
s:CreateColorPicker("Main Theme", mainTheme, function(c) UpdateUITheme(c) end)
s:CreateColorPicker("UI Outline Color", outlineColor, function(c) UpdateOutlineTheme(c) end)
s:CreateColorPicker("Shade Color", shadeColor, function(c) UpdateShadeTheme(c) end)
s:CreateColorPicker("Button Color", buttonColor, function(c) UpdateButtonTheme(c) end)
s:CreateColorPicker("Button Outline Color", buttonOutlineColor, function(c) UpdateButtonOutlineTheme(c) end)

local menuOpen = true
uis.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == menuKey then 
        menuOpen = not menuOpen 
        if menuOpen then
            mainFrame.Visible = true
            uiScale.Scale = 0.8
            tweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            tweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
        else
            local closeTw = tweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
            tweenService:Create(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            closeTw:Play()
            closeTw.Completed:Wait()
            if not menuOpen then mainFrame.Visible = false end
        end
    end
end)
