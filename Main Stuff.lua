local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local pGui = player:WaitForChild("PlayerGui")
local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XENOX_LIBRARY"
screenGui.ResetOnSpawn = false
screenGui.Parent = pGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 1000, 0, 750)
mainFrame.Position = UDim2.new(0.5, -500, 0.5, -375)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
mainFrame.BackgroundTransparency = 0.4
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local blobColor = Color3.fromRGB(0, 20, 100)

local function UpdateUITheme(color)
    mainFrame.BackgroundColor3 = color
    for _, v in pairs(mainFrame:GetDescendants()) do
        if v:IsA("TextButton") and v.Name == "TabBtn" then
            v.BackgroundColor3 = color
        elseif v:IsA("TextLabel") and v.Name == "Title" then
            v.TextColor3 = color
        end
    end
end

task.spawn(function()
    while task.wait(0.02) do 
        local blob = Instance.new("ImageLabel")
        local size = math.random(2, 5) / 10
        blob.Size = UDim2.new(size, 0, size, 0)
        blob.Position = UDim2.new(math.random(-1, 9)/10, 0, math.random(-1, 9)/10, 0)
        blob.Image = "rbxassetid://232918622"
        blob.ImageColor3 = blobColor
        blob.BackgroundTransparency = 1
        blob.ImageTransparency = 0.93
        blob.ZIndex = 1
        blob.Parent = mainFrame

        local star = Instance.new("Frame")
        star.Size = UDim2.new(0, 1, 0, math.random(30, 80))
        star.Position = UDim2.new(math.random(0, 100)/100, 0, -0.2, 0)
        star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        star.BackgroundTransparency = 0.7
        star.BorderSizePixel = 0
        star.ZIndex = 1
        star.Parent = mainFrame
        
        local trail = Instance.new("Frame")
        trail.Size = UDim2.new(0, 10, 0, 10)
        trail.Position = UDim2.new(0, mouse.X - mainFrame.AbsolutePosition.X - 5, 0, mouse.Y - mainFrame.AbsolutePosition.Y - 5)
        trail.BackgroundColor3 = mainFrame.BackgroundColor3
        trail.BorderSizePixel = 0
        trail.ZIndex = 2
        trail.Parent = mainFrame
        Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)

        tweenService:Create(star, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
            Position = UDim2.new(star.Position.X.Scale, 0, 1.2, 0), 
            BackgroundTransparency = 1
        }):Play()
        game:GetService("Debris"):AddItem(star, 0.6)
        
        tweenService:Create(trail, TweenInfo.new(0.4), {
            BackgroundTransparency = 1, 
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        game:GetService("Debris"):AddItem(trail, 0.4)

        task.spawn(function()
            local life = 3
            local startTick = tick()
            while tick() - startTick < life do
                if not blob or not blob.Parent then break end
                local blobPos = Vector2.new(blob.AbsolutePosition.X + (blob.AbsoluteSize.X/2), blob.AbsolutePosition.Y + (blob.AbsoluteSize.Y/2))
                local mousePos = Vector2.new(mouse.X, mouse.Y)
                local diff = blobPos - mousePos
                local dist = diff.Magnitude
                
                if dist < 250 then
                    local force = (1 - (dist / 250)) * 0.18 
                    local pushDir = diff.Unit
                    local newX = blob.Position.X.Scale + (pushDir.X * force)
                    local newY = blob.Position.Y.Scale + (pushDir.Y * force)
                    blob.Position = blob.Position:Lerp(UDim2.new(newX, 0, newY, 0), 0.45)
                    blob.ImageTransparency = 0.98
                else
                    blob.ImageTransparency = 0.93
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
title.TextColor3 = Color3.fromRGB(25, 55, 95)
title.TextSize = 22
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
    tabBtn.BackgroundColor3 = Color3.fromRGB(25, 55, 95)
    tabBtn.BackgroundTransparency = 0.2
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.TextSize = 16
    tabBtn.ZIndex = 10
    tabBtn.Parent = mainFrame
    Instance.new("UICorner", tabBtn)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(0, 780, 0, 670)
    page.Position = UDim2.new(0, 195, 0, 55)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 0
    page.Visible = (tabID == 1)
    page.ZIndex = 10
    page.Parent = mainFrame
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 8)
    
    tabs[tabID] = {Page = page, Btn = tabBtn}
    tabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(tabs) do v.Page.Visible = false end
        page.Visible = true
    end)

    local tabObj = {}
    function tabObj:CreateLabel(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 0, 50)
        l.BackgroundColor3 = Color3.fromRGB(25, 55, 95)
        l.BackgroundTransparency = 0.1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.Font = Enum.Font.SourceSansBold
        l.TextSize = 18
        l.ZIndex = 15
        l.Parent = page
        Instance.new("UICorner", l)
    end

    function tabObj:CreateColorPicker(text, defaultColor, callback)
        local cpFrame = Instance.new("Frame")
        cpFrame.Size = UDim2.new(1, -10, 0, 200)
        cpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        cpFrame.BackgroundTransparency = 0.3
        cpFrame.Parent = page
        Instance.new("UICorner", cpFrame)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -200, 0, 40)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 18
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = cpFrame

        local box = Instance.new("ImageLabel")
        box.Size = UDim2.new(0, 140, 0, 140)
        box.Position = UDim2.new(0, 10, 0, 45)
        box.Image = "rbxassetid://4155801252"
        box.Parent = cpFrame

        local selectCircle = Instance.new("Frame")
        selectCircle.Size = UDim2.new(0, 10, 0, 10)
        selectCircle.BackgroundColor3 = Color3.new(1,1,1)
        selectCircle.BorderSizePixel = 2
        selectCircle.BorderColor3 = Color3.new(0,0,0)
        selectCircle.ZIndex = 5
        selectCircle.Parent = box
        Instance.new("UICorner", selectCircle).CornerRadius = UDim.new(1, 0)

        local hue = Instance.new("ImageLabel")
        hue.Size = UDim2.new(0, 20, 0, 140)
        hue.Position = UDim2.new(0, 160, 0, 45)
        hue.Image = "rbxassetid://3641079629"
        hue.Parent = cpFrame

        local hueArrow = Instance.new("Frame")
        hueArrow.Size = UDim2.new(1.4, 0, 0, 4)
        hueArrow.Position = UDim2.new(-0.2, 0, 0.5, 0)
        hueArrow.BackgroundColor3 = Color3.new(1,1,1)
        hueArrow.BorderSizePixel = 1
        hueArrow.ZIndex = 5
        hueArrow.Parent = hue

        local preview = Instance.new("Frame")
        preview.Size = UDim2.new(0, 40, 0, 40)
        preview.Position = UDim2.new(1, -50, 0, 10)
        preview.BackgroundColor3 = defaultColor
        preview.Parent = cpFrame
        Instance.new("UICorner", preview)

        local currH, currS, currV = defaultColor:ToHSV()
        local dragH, dragSV = false, false

        local function update()
            local c = Color3.fromHSV(currH, currS, currV)
            box.ImageColor3 = Color3.fromHSV(currH, 1, 1)
            preview.BackgroundColor3 = c
            selectCircle.Position = UDim2.new(currS, -5, 1-currV, -5)
            hueArrow.Position = UDim2.new(-0.2, 0, 1-currH, -2)
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
        update()
    end
    return tabObj
end

local mainTab = _G.XeNOX:CreateTab("Main")
mainTab:CreateLabel("TEXT LABEL")

local settings = _G.XeNOX:CreateTab("Settings")
settings:CreateColorPicker("UI Color Picker", Color3.fromRGB(0, 255, 255), function(color)
    UpdateUITheme(color)
end)

settings:CreateColorPicker("Blob Color Picker", Color3.fromRGB(0, 20, 100), function(color)
    blobColor = color
end)

print("the thing loaded")
