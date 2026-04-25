local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local pGui = player:WaitForChild("PlayerGui")
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Configuration & Defaults
local menuKey = Enum.KeyCode.RightControl
local mainTheme = Color3.fromRGB(0, 255, 255)
local shadeColor = Color3.fromRGB(25, 55, 95)
local blobColor = Color3.fromRGB(0, 20, 100)

-- ORIGINAL FONT SIZES
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

-- Theme Management Functions
local function UpdateUITheme(color)
    mainTheme = color
    mainFrame.BackgroundColor3 = color
    for _, v in pairs(mainFrame:GetDescendants()) do
        if v:IsA("TextLabel") and v.Name == "Title" then v.TextColor3 = color end
    end
end

local function UpdateShadeTheme(newShade)
    shadeColor = newShade
    for _, v in pairs(mainFrame:GetDescendants()) do
        if v.Name == "TabBtn" or v.Name == "LabelElement" or v.Name == "ConfigBtn" then
            v.BackgroundColor3 = shadeColor
        end
    end
end

-- FILE SYSTEM (MULTIPLE CONFIGS + DELETE)
local folderName = "XeNOX_Configs"
if writefile and not isfolder(folderName) then makefolder(folderName) end

local selectedConfig = ""

local function SaveSettings(name)
    if name == "" then return end
    local data = {
        Keybind = menuKey.Name,
        Theme = {mainTheme.R, mainTheme.G, mainTheme.B},
        Shade = {shadeColor.R, shadeColor.G, shadeColor.B},
        Blob = {blobColor.R, blobColor.G, blobColor.B}
    }
    if writefile then
        writefile(folderName .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end
end

local function LoadSettings(name)
    local path = folderName .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success then
            menuKey = Enum.KeyCode[data.Keybind]
            UpdateUITheme(Color3.new(unpack(data.Theme)))
            UpdateShadeTheme(Color3.new(unpack(data.Shade)))
            blobColor = Color3.new(unpack(data.Blob))
        end
    end
end

local function DeleteConfig(name)
    local path = folderName .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        delfile(path)
        selectedConfig = ""
    end
end

-- Minimize Button ("-")
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Minimize"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "-"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 35
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.ZIndex = 20
closeBtn.Parent = mainFrame

local isMinimized = false
closeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    mainFrame:TweenSize(isMinimized and UDim2.new(0, 1000, 0, 50) or UDim2.new(0, 1000, 0, 750), "Out", "Quad", 0.3, true)
end)

-- Toggle Listener
uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == menuKey then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- VFX (RAIN, BLOBS, TRAILS)
task.spawn(function()
    while task.wait(0.02) do 
        if not screenGui.Parent then break end
        
        -- Rain
        local star = Instance.new("Frame")
        star.Size = UDim2.new(0, 1, 0, math.random(30, 80))
        star.Position = UDim2.new(math.random(0, 100)/100, 0, -0.2, 0)
        star.BackgroundColor3 = Color3.new(1,1,1)
        star.BackgroundTransparency = 0.7
        star.ZIndex = 1
        star.Parent = mainFrame
        tweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0), BackgroundTransparency = 1}):Play()
        game:GetService("Debris"):AddItem(star, 0.6)

        -- Trail
        local trail = Instance.new("Frame")
        trail.Size = UDim2.new(0, 10, 0, 10)
        trail.Position = UDim2.new(0, mouse.X - mainFrame.AbsolutePosition.X - 5, 0, mouse.Y - mainFrame.AbsolutePosition.Y - 5)
        trail.BackgroundColor3 = mainFrame.BackgroundColor3
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

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "XeNOX Library"
title.TextColor3 = mainTheme
title.TextSize = TITLE_SIZE
title.Font = Enum.Font.SourceSansBold
title.ZIndex = 10
title.Parent = mainFrame

_G.XeNOX = {}
local tabs = {}
local tabCount = 0

function _G.XeNOX:CreateTab(name)
    tabCount = tabCount + 1
    local tabID = tabCount
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "TabBtn"
    tabBtn.Size = UDim2.new(0, 160, 0, 45)
    tabBtn.Position = UDim2.new(0, 15, 0, 50 + (tabCount - 1) * 50)
    tabBtn.BackgroundColor3 = shadeColor
    tabBtn.BackgroundTransparency = 0.2
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.TextSize = TAB_SIZE
    tabBtn.Parent = mainFrame
    Instance.new("UICorner", tabBtn)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(0, 780, 0, 670)
    page.Position = UDim2.new(0, 195, 0, 55)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 0
    page.Visible = (tabID == 1)
    page.Parent = mainFrame
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
    
    tabs[tabID] = {Page = page, Btn = tabBtn}
    tabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(tabs) do v.Page.Visible = false end
        page.Visible = true
    end)

    local tabObj = {}
    
    function tabObj:CreateConfigManager()
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 270)
        container.BackgroundTransparency = 0.5
        container.BackgroundColor3 = Color3.new(0,0,0)
        container.Parent = page
        Instance.new("UICorner", container)

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.6, 0, 0, 40)
        input.Position = UDim2.new(0, 10, 0, 10)
        input.PlaceholderText = "Config Name..."
        input.Text = ""
        input.BackgroundColor3 = Color3.fromRGB(30,30,30)
        input.TextColor3 = Color3.new(1,1,1)
        input.Font = Enum.Font.SourceSansBold
        input.TextSize = LABEL_SIZE
        input.Parent = container
        Instance.new("UICorner", input)

        local save = Instance.new("TextButton")
        save.Name = "LabelElement"
        save.Size = UDim2.new(0.35, -5, 0, 40)
        save.Position = UDim2.new(0.6, 15, 0, 10)
        save.Text = "SAVE"
        save.BackgroundColor3 = shadeColor
        save.TextColor3 = Color3.new(1,1,1)
        save.Font = Enum.Font.SourceSansBold
        save.Parent = container
        Instance.new("UICorner", save)

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.new(1, -20, 0, 130)
        list.Position = UDim2.new(0, 10, 0, 60)
        list.BackgroundTransparency = 0.8
        list.BackgroundColor3 = Color3.new(0,0,0)
        list.ScrollBarThickness = 2
        list.Parent = container
        local layout = Instance.new("UIListLayout", list)

        local function refreshList()
            for _, v in pairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            if listfiles then
                for _, file in pairs(listfiles(folderName)) do
                    local name = file:match("([^/]+)%.json$")
                    if name then
                        local b = Instance.new("TextButton")
                        b.Name = "ConfigBtn"
                        b.Size = UDim2.new(1, 0, 0, 30)
                        b.Text = name
                        b.BackgroundColor3 = shadeColor
                        b.TextColor3 = Color3.new(1,1,1)
                        b.Font = Enum.Font.SourceSansBold
                        b.Parent = list
                        b.MouseButton1Click:Connect(function()
                            selectedConfig = name
                            for _, x in pairs(list:GetChildren()) do if x:IsA("TextButton") then x.BackgroundTransparency = 0 end end
                            b.BackgroundTransparency = 0.5
                        end)
                    end
                end
            end
        end

        local load = Instance.new("TextButton")
        load.Name = "LabelElement"
        load.Size = UDim2.new(0.45, 0, 0, 40)
        load.Position = UDim2.new(0, 10, 0, 210)
        load.Text = "LOAD"
        load.BackgroundColor3 = shadeColor
        load.TextColor3 = Color3.new(1,1,1)
        load.Font = Enum.Font.SourceSansBold
        load.Parent = container
        Instance.new("UICorner", load)

        local delete = Instance.new("TextButton")
        delete.Size = UDim2.new(0.45, 0, 0, 40)
        delete.Position = UDim2.new(0.5, 5, 0, 210)
        delete.Text = "DELETE"
        delete.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        delete.TextColor3 = Color3.new(1,1,1)
        delete.Font = Enum.Font.SourceSansBold
        delete.Parent = container
        Instance.new("UICorner", delete)

        save.MouseButton1Click:Connect(function() SaveSettings(input.Text) refreshList() end)
        load.MouseButton1Click:Connect(function() if selectedConfig ~= "" then LoadSettings(selectedConfig) end end)
        delete.MouseButton1Click:Connect(function() if selectedConfig ~= "" then DeleteConfig(selectedConfig) refreshList() end end)
        refreshList()
    end

    function tabObj:CreateLabel(text)
        local l = Instance.new("TextLabel")
        l.Name = "LabelElement"
        l.Size = UDim2.new(1, -10, 0, 50)
        l.BackgroundColor3 = shadeColor
        l.BackgroundTransparency = 0.1
        l.Text = text
        l.TextColor3 = Color3.new(1,1,1)
        l.Font = Enum.Font.SourceSansBold
        l.TextSize = LABEL_SIZE
        l.Parent = page
        Instance.new("UICorner", l)
    end

    function tabObj:CreateKeybind(text, default, callback)
        local kbFrame = Instance.new("Frame")
        kbFrame.Size = UDim2.new(1, -10, 0, 50)
        kbFrame.BackgroundTransparency = 0.5
        kbFrame.BackgroundColor3 = Color3.new(0,0,0)
        kbFrame.Parent = page
        Instance.new("UICorner", kbFrame)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = LABEL_SIZE
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = kbFrame

        local bindBtn = Instance.new("TextButton")
        bindBtn.Size = UDim2.new(0, 100, 0, 30)
        bindBtn.Position = UDim2.new(1, -110, 0.5, -15)
        bindBtn.Text = menuKey.Name
        bindBtn.Parent = kbFrame
        Instance.new("UICorner", bindBtn)
        bindBtn.MouseButton1Click:Connect(function()
            bindBtn.Text = "..."
            local con; con = uis.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    menuKey = i.KeyCode
                    bindBtn.Text = i.KeyCode.Name
                    con:Disconnect()
                    callback(i.KeyCode)
                end
            end)
        end)
    end

    function tabObj:CreateColorPicker(text, defaultColor, callback)
        local cpFrame = Instance.new("Frame")
        cpFrame.Size = UDim2.new(1, -10, 0, 200)
        cpFrame.BackgroundColor3 = Color3.new(0,0,0)
        cpFrame.BackgroundTransparency = 0.3
        cpFrame.Parent = page
        Instance.new("UICorner", cpFrame)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 30)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = LABEL_SIZE
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = cpFrame

        local box = Instance.new("ImageLabel")
        box.Size = UDim2.new(0, 140, 0, 140)
        box.Position = UDim2.new(0, 10, 0, 45)
        box.Image = "rbxassetid://4155801252"
        box.Parent = cpFrame
        local hue = Instance.new("ImageLabel")
        hue.Size = UDim2.new(0, 20, 0, 140)
        hue.Position = UDim2.new(0, 160, 0, 45)
        hue.Image = "rbxassetid://3641079629"
        hue.Parent = cpFrame
        local currH, currS, currV = defaultColor:ToHSV()
        local dragH, dragSV = false, false
        local function update()
            local c = Color3.fromHSV(currH, currS, currV)
            box.ImageColor3 = Color3.fromHSV(currH, 1, 1)
            callback(c)
        end
        hue.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragH = true end end)
        box.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true end end)
        uis.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragH, dragSV = false, false end end)
        runService.RenderStepped:Connect(function()
            if dragH then
                currH = 1 - math.clamp((mouse.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
                update()
            elseif dragSV then
                currS = math.clamp((mouse.X - box.AbsolutePosition.X) / box.AbsoluteSize.X, 0, 1)
                currV = 1 - math.clamp((mouse.Y - box.AbsolutePosition.Y) / box.AbsoluteSize.Y, 0, 1)
                update()
            end
        end)
    end
    return tabObj
end

-- Initialize Library
local mainTab = _G.XeNOX:CreateTab("Main")
mainTab:CreateLabel("SYSTEMS ONLINE")

local settings = _G.XeNOX:CreateTab("Settings")
settings:CreateConfigManager()
settings:CreateKeybind("Menu Toggle Key", menuKey, function(new) menuKey = new end)
settings:CreateColorPicker("Main Theme Color", mainTheme, function(c) UpdateUITheme(c) end)
settings:CreateColorPicker("Shade Color Accent", shadeColor, function(c) UpdateShadeTheme(c) end)
settings:CreateColorPicker("Background Blob Color", blobColor, function(c) blobColor = c end)

print("XeNOX: Config Manager with Delete & Color Labels loaded.")
