local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local pGui = player:WaitForChild("PlayerGui")
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local menuKey = Enum.KeyCode.RightControl
local mainTheme = Color3.fromRGB(0, 255, 255)
local shadeColor = Color3.fromRGB(25, 55, 95)
local blobColor = Color3.fromRGB(0, 20, 100)
local outlineColor = Color3.fromRGB(0, 255, 255)

local TITLE_SIZE = 22
local TAB_SIZE = 16
local LABEL_SIZE = 18

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XENOX_LIBRARY"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 1000, 0, 750)
mainFrame.Position = UDim2.new(0.5, -500, 0.5, -375)
mainFrame.BackgroundColor3 = mainTheme
mainFrame.BackgroundTransparency = 0.4
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = outlineColor
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Parent = mainFrame

-- // THEME UPDATERS //
local function UpdateUITheme(color)
    mainTheme = color
    mainFrame.BackgroundColor3 = color
    for _, v in pairs(mainFrame:GetDescendants()) do
        if v:IsA("TextLabel") and v.Name == "Title" then v.TextColor3 = color end
    end
end

local function UpdateOutlineTheme(color)
    outlineColor = color
    uiStroke.Color = color
end

local function UpdateShadeTheme(newShade)
    shadeColor = newShade
    for _, v in pairs(mainFrame:GetDescendants()) do
        if v.Name == "TabBtn" or v.Name == "LabelElement" or v.Name == "ConfigBtn" or v.Name == "ToggleBG" then
            v.BackgroundColor3 = shadeColor
        end
    end
end

-- // CONFIG SYSTEM //
local folderName = "XeNOX_Configs"
if writefile and not isfolder(folderName) then makefolder(folderName) end
local selectedConfig = ""
local function GetPath(name) return folderName .. "/" .. name .. ".json" end

local function SaveSettings(name)
    if name == "" then return end
    local data = {
        Keybind = menuKey.Name,
        Theme = {mainTheme.R, mainTheme.G, mainTheme.B},
        Shade = {shadeColor.R, shadeColor.G, shadeColor.B},
        Blob = {blobColor.R, blobColor.G, blobColor.B},
        Outline = {outlineColor.R, outlineColor.G, outlineColor.B}
    }
    writefile(GetPath(name), HttpService:JSONEncode(data))
end

-- // DYNAMIC BACKGROUND & MOUSE EFFECTS //
task.spawn(function()
    while task.wait(0.02) do 
        if not screenGui.Parent then break end
        -- Falling Stars
        local star = Instance.new("Frame")
        star.Size = UDim2.new(0, 1, 0, math.random(30, 80))
        star.Position = UDim2.new(math.random(0, 100)/100, 0, -0.2, 0)
        star.BackgroundColor3 = Color3.new(1,1,1)
        star.ZIndex = 1
        star.Parent = mainFrame
        tweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0), BackgroundTransparency = 1}):Play()
        game:GetService("Debris"):AddItem(star, 0.6)

        -- Mouse Trail
        local trail = Instance.new("Frame")
        trail.Size = UDim2.new(0, 10, 0, 10)
        trail.Position = UDim2.new(0, mouse.X - mainFrame.AbsolutePosition.X - 5, 0, mouse.Y - mainFrame.AbsolutePosition.Y - 5)
        trail.BackgroundColor3 = mainTheme
        trail.ZIndex = 2
        trail.Parent = mainFrame
        Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)
        tweenService:Create(trail, TweenInfo.new(0.4), {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}):Play()
        game:GetService("Debris"):AddItem(trail, 0.4)

        -- Blobs
        local blob = Instance.new("ImageLabel")
        blob.Size = UDim2.new(math.random(2,5)/10, 0, math.random(2,5)/10, 0)
        blob.Position = UDim2.new(math.random(-1, 9)/10, 0, math.random(-1, 9)/10, 0)
        blob.Image = "rbxassetid://232918622"
        blob.ImageColor3 = blobColor
        blob.BackgroundTransparency = 1
        blob.ImageTransparency = 0.93
        blob.ZIndex = 1
        blob.Parent = mainFrame
        task.spawn(function()
            local start = tick()
            while tick() - start < 3 do
                if not blob or not blob.Parent then break end
                local diff = (blob.AbsolutePosition + blob.AbsoluteSize/2) - Vector2.new(mouse.X, mouse.Y)
                if diff.Magnitude < 250 then
                    local push = diff.Unit * (1 - (diff.Magnitude / 250)) * 0.18
                    blob.Position = blob.Position:Lerp(UDim2.new(blob.Position.X.Scale + push.X, 0, blob.Position.Y.Scale + push.Y, 0), 0.45)
                end
                task.wait()
            end
            if blob then blob:Destroy() end
        end)
    end
end)

-- // HEADER //
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "-"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 35
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.ZIndex = 20
closeBtn.Parent = mainFrame

local isMin = false
closeBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    uiStroke.Enabled = not isMin
    mainFrame:TweenSize(isMin and UDim2.new(0, 1000, 0, 50) or UDim2.new(0, 1000, 0, 750), "Out", "Quad", 0.3, true)
end)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "XeNOX Library"
title.TextColor3 = mainTheme
title.TextSize = TITLE_SIZE
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- // LIBRARY CORE //
_G.XeNOX = {}
local tabs = {}
local tabCount = 0

-- Function to keep Keybind button updated across all tabs
local function UpdateKeybindDisplay(key)
    for _, tab in pairs(tabs) do
        for _, v in pairs(tab.Page:GetChildren()) do
            if v:IsA("Frame") and v:FindFirstChild("KeybindLabel") then
                if v.KeybindLabel.Text == "Menu Toggle" then
                    v.KeybindBtn.Text = key.Name
                end
            end
        end
    end
end

function _G.XeNOX:CreateTab(name)
    tabCount = tabCount + 1
    local tabID = tabCount
    
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "TabBtn"
    tabBtn.Size = UDim2.new(0, 160, 0, 45)
    tabBtn.Position = UDim2.new(0, 15, 0, 50 + (tabCount - 1) * 50)
    tabBtn.BackgroundColor3 = shadeColor
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.TextSize = TAB_SIZE
    tabBtn.Parent = mainFrame
    Instance.new("UICorner", tabBtn)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(0, 780, 0, 670)
    page.Position = UDim2.new(0, 195, 0, 55)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = mainTheme
    page.Visible = (tabID == 1)
    page.Parent = mainFrame

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    tabs[tabID] = {Page = page, Btn = tabBtn}
    tabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(tabs) do v.Page.Visible = false end
        page.Visible = true
    end)

    local tabObj = {}
    
    function tabObj:CreateLabel(text)
        local l = Instance.new("TextLabel")
        l.Name = "LabelElement"
        l.Size = UDim2.new(1, -20, 0, 45)
        l.BackgroundColor3 = shadeColor
        l.Text = text
        l.TextColor3 = Color3.new(1,1,1)
        l.Font = Enum.Font.SourceSansBold
        l.TextSize = LABEL_SIZE
        l.Parent = page
        Instance.new("UICorner", l)
    end

    function tabObj:CreateToggle(text, default, callback)
        local enabled = default
        local tgl = Instance.new("Frame")
        tgl.Size = UDim2.new(1, -20, 0, 50)
        tgl.BackgroundColor3 = Color3.new(0,0,0); tgl.BackgroundTransparency = 0.5
        tgl.Parent = page; Instance.new("UICorner", tgl)

        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -60, 1, 0); lb.Position = UDim2.new(0, 15, 0, 0)
        lb.Text = text; lb.TextColor3 = Color3.new(1,1,1); lb.Font = Enum.Font.SourceSansBold
        lb.TextSize = LABEL_SIZE; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = tgl

        local bg = Instance.new("TextButton")
        bg.Name = "ToggleBG"
        bg.Size = UDim2.new(0, 45, 0, 25); bg.Position = UDim2.new(1, -55, 0.5, -12)
        bg.BackgroundColor3 = enabled and mainTheme or shadeColor
        bg.Text = ""; bg.Parent = tgl; Instance.new("UICorner", bg, {CornerRadius = UDim.new(1,0)})

        local ball = Instance.new("Frame")
        ball.Size = UDim2.new(0, 17, 0, 17); ball.Position = enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
        ball.BackgroundColor3 = Color3.new(1,1,1); ball.Parent = bg; Instance.new("UICorner", ball, {CornerRadius = UDim.new(1,0)})

        bg.MouseButton1Click:Connect(function()
            enabled = not enabled
            tweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = enabled and mainTheme or shadeColor}):Play()
            ball:TweenPosition(enabled and UDim2.new(1, -21, 0.5, -8) or UDim2.new(0, 4, 0.5, -8), "Out", "Quad", 0.2, true)
            callback(enabled)
        end)
    end

    function tabObj:CreateSlider(text, min, max, default, callback)
        local sld = Instance.new("Frame")
        sld.Size = UDim2.new(1, -20, 0, 65); sld.BackgroundColor3 = Color3.new(0,0,0); sld.BackgroundTransparency = 0.5
        sld.Parent = page; Instance.new("UICorner", sld)

        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -20, 0, 30); lb.Position = UDim2.new(0, 15, 0, 5)
        lb.Text = text .. ": " .. default; lb.TextColor3 = Color3.new(1,1,1); lb.Font = Enum.Font.SourceSansBold
        lb.TextSize = LABEL_SIZE - 2; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = sld

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -40, 0, 6); bar.Position = UDim2.new(0, 20, 0, 45)
        bar.BackgroundColor3 = shadeColor; bar.Parent = sld; Instance.new("UICorner", bar)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = mainTheme; fill.Parent = bar; Instance.new("UICorner", fill)

        local dragging = false
        local function update()
            local percent = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * percent)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            lb.Text = text .. ": " .. val
            callback(val)
        end

        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
        uis.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        runService.RenderStepped:Connect(function() if dragging then update() end end)
    end

    function tabObj:CreateKeybind(text, default, callback)
        local kb = Instance.new("Frame")
        kb.Size = UDim2.new(1,-20,0,50); kb.BackgroundColor3 = Color3.new(0,0,0); kb.BackgroundTransparency = 0.5
        kb.Parent = page; Instance.new("UICorner", kb)
        
        local lb = Instance.new("TextLabel")
        lb.Name = "KeybindLabel"; lb.Size = UDim2.new(1,-110,1,0); lb.Position = UDim2.new(0,15,0,0)
        lb.Text = text; lb.TextColor3 = Color3.new(1,1,1); lb.Font = Enum.Font.SourceSansBold
        lb.TextSize = LABEL_SIZE; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = kb
        
        local btn = Instance.new("TextButton")
        btn.Name = "KeybindBtn"; btn.Size = UDim2.new(0,100,0,30); btn.Position = UDim2.new(1,-110,0.5,-15)
        btn.Text = default.Name; btn.Parent = kb; Instance.new("UICorner", btn)
        
        btn.MouseButton1Click:Connect(function()
            btn.Text = "..."
            local connection
            connection = uis.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    btn.Text = input.KeyCode.Name
                    connection:Disconnect()
                    callback(input.KeyCode)
                end
            end)
        end)
    end

    function tabObj:CreateColorPicker(text, defaultColor, callback)
        local cp = Instance.new("Frame")
        cp.Size = UDim2.new(1,-20,0,200); cp.BackgroundColor3 = Color3.new(0,0,0); cp.BackgroundTransparency = 0.3
        cp.Parent = page; Instance.new("UICorner", cp)

        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1,-10,0,30); lb.Position = UDim2.new(0,10,0,5)
        lb.Text = text; lb.TextColor3 = Color3.new(1,1,1); lb.Font = Enum.Font.SourceSansBold
        lb.TextSize = LABEL_SIZE; lb.BackgroundTransparency = 1; lb.TextXAlignment = "Left"; lb.Parent = cp

        local box = Instance.new("ImageLabel")
        box.Size = UDim2.new(0,140,0,140); box.Position = UDim2.new(0,10,0,45)
        box.Image = "rbxassetid://4155801252"; box.Parent = cp

        local hue = Instance.new("ImageLabel")
        hue.Size = UDim2.new(0,20,0,140); hue.Position = UDim2.new(0,160,0,45)
        hue.Image = "rbxassetid://3641079629"; hue.Parent = cp

        local curH, curS, curV = defaultColor:ToHSV()
        local function upd()
            local c = Color3.fromHSV(curH, curS, curV)
            box.ImageColor3 = Color3.fromHSV(curH, 1, 1); callback(c)
        end

        local dH, dSV = false, false
        hue.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dH = true end end)
        box.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dSV = true end end)
        uis.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dH, dSV = false end end)
        
        runService.RenderStepped:Connect(function()
            if dH then curH = 1 - math.clamp((mouse.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1); upd()
            elseif dSV then curS = math.clamp((mouse.X - box.AbsolutePosition.X) / box.AbsoluteSize.X, 0, 1)
                curV = 1 - math.clamp((mouse.Y - box.AbsolutePosition.Y) / box.AbsoluteSize.Y, 0, 1); upd() end
        end)
    end

    function tabObj:CreateConfigManager()
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 340)
        container.BackgroundColor3 = Color3.new(0,0,0); container.BackgroundTransparency = 0.5
        container.Parent = page; Instance.new("UICorner", container)

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, 0, 0, 20); status.Position = UDim2.new(0, 0, 1, -25)
        status.BackgroundTransparency = 1; status.Text = "Status: Idle"; status.TextColor3 = Color3.new(0.7,0.7,0.7)
        status.Font = Enum.Font.SourceSansItalic; status.TextSize = 14; status.Parent = container

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.6, 0, 0, 40); input.Position = UDim2.new(0, 10, 0, 10)
        input.PlaceholderText = "New Config Name..."; input.BackgroundColor3 = Color3.fromRGB(30,30,30)
        input.TextColor3 = Color3.new(1,1,1); input.Font = Enum.Font.SourceSansBold; input.TextSize = LABEL_SIZE
        input.Parent = container; Instance.new("UICorner", input)

        local save = Instance.new("TextButton")
        save.Size = UDim2.new(0.35, -5, 0, 40); save.Position = UDim2.new(0.6, 15, 0, 10)
        save.Text = "CREATE"; save.BackgroundColor3 = shadeColor; save.TextColor3 = Color3.new(1,1,1)
        save.Font = Enum.Font.SourceSansBold; save.Parent = container; Instance.new("UICorner", save)

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.new(1, -20, 0, 130); list.Position = UDim2.new(0, 10, 0, 60)
        list.BackgroundTransparency = 0.8; list.BackgroundColor3 = Color3.new(0,0,0)
        list.ScrollBarThickness = 4; list.Parent = container; Instance.new("UIListLayout", list)

        local function refreshList()
            for _, v in pairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            if listfiles then
                local files = listfiles(folderName)
                for _, file in pairs(files) do
                    local name = file:gsub(folderName.."/", ""):gsub(".json", ""):gsub(folderName.."\\", "")
                    local b = Instance.new("TextButton")
                    b.Name = "ConfigBtn"; b.Size = UDim2.new(1, 0, 0, 35); b.Text = name
                    b.BackgroundColor3 = shadeColor; b.TextColor3 = Color3.new(1,1,1)
                    b.Font = Enum.Font.SourceSansBold; b.Parent = list
                    b.MouseButton1Click:Connect(function()
                        selectedConfig = name
                        for _, x in pairs(list:GetChildren()) do if x:IsA("TextButton") then x.BackgroundColor3 = shadeColor end end
                        b.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                        status.Text = "Selected: " .. name
                    end)
                end
            end
        end

        local actions = {
            Load = {Pos = UDim2.new(0, 10, 0, 210), Text = "LOAD"},
            Update = {Pos = UDim2.new(0.34, 10, 0, 210), Text = "UPDATE"},
            Delete = {Pos = UDim2.new(0.68, 10, 0, 210), Text = "DELETE", Color = Color3.fromRGB(150, 0, 0)}
        }

        for i, info in pairs(actions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.3, 0, 0, 45); btn.Position = info.Pos; btn.Text = info.Text
            btn.BackgroundColor3 = info.Color or shadeColor; btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.SourceSansBold; btn.Parent = container; Instance.new("UICorner", btn)

            btn.MouseButton1Click:Connect(function()
                if selectedConfig == "" then status.Text = "Error: Select a config first!" return end
                local path = GetPath(selectedConfig)
                
                if i == "Load" then
                    if isfile(path) then
                        local data = HttpService:JSONDecode(readfile(path))
                        menuKey = Enum.KeyCode[data.Keybind]
                        UpdateKeybindDisplay(menuKey)
                        UpdateUITheme(Color3.new(unpack(data.Theme)))
                        UpdateShadeTheme(Color3.new(unpack(data.Shade)))
                        blobColor = Color3.new(unpack(data.Blob))
                        if data.Outline then UpdateOutlineTheme(Color3.new(unpack(data.Outline))) end
                        status.Text = "Status: Loaded " .. selectedConfig
                    end
                elseif i == "Update" then
                    SaveSettings(selectedConfig); status.Text = "Status: Updated " .. selectedConfig
                elseif i == "Delete" then
                    if isfile(path) then delfile(path) end
                    status.Text = "Status: Deleted " .. selectedConfig; selectedConfig = ""; task.wait(0.1); refreshList()
                end
            end)
        end

        save.MouseButton1Click:Connect(function() 
            if input.Text ~= "" then 
                SaveSettings(input.Text); status.Text = "Status: Created " .. input.Text
                input.Text = ""; task.wait(0.1); refreshList() 
            end 
        end)
        refreshList()
    end

    return tabObj
end

-- // INITIALIZATION //
local m = _G.XeNOX:CreateTab("Main")
m:CreateLabel("SYSTEM INITIALIZED")

local s = _G.XeNOX:CreateTab("Settings")
s:CreateConfigManager()
s:CreateKeybind("Menu Toggle", menuKey, function(k) menuKey = k end)
s:CreateColorPicker("Main Theme", mainTheme, function(c) UpdateUITheme(c) end)
s:CreateColorPicker("Outline Color", outlineColor, function(c) UpdateOutlineTheme(c) end)
s:CreateColorPicker("Shade Color", shadeColor, function(c) UpdateShadeTheme(c) end)
s:CreateColorPicker("Blob Color", blobColor, function(c) blobColor = c end)

uis.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == menuKey then mainFrame.Visible = not mainFrame.Visible end
end)
