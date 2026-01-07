local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "Helicopter_ESP" then
        v:Destroy()
    end
end

local HeliESPfolder = Instance.new("Folder")
HeliESPfolder.Name = "Helicopter_ESP"
HeliESPfolder.Parent = CoreGui

local EXCLUDED_HELICOPTERS = {
    ["UH-72B Lakota"] = true,
    ["UH72B Lakota"] = true,
    ["Lakota"] = true
}

local function getHelicopterWorkspace()
    local gameSystems = workspace:FindFirstChild("Game Systems")
    if not gameSystems then return nil end
    return gameSystems:FindFirstChild("Helicopter Workspace")
end

local function findAllHelicopters()
    local heliWorkspace = getHelicopterWorkspace()
    if not heliWorkspace then return {} end
    
    local foundHelicopters = {}
    
    for _, heliModel in pairs(heliWorkspace:GetChildren()) do
        if heliModel:IsA("Model") then
            if EXCLUDED_HELICOPTERS[heliModel.Name] then
                continue
            end
            
            local primaryPart = heliModel.PrimaryPart or heliModel:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                table.insert(foundHelicopters, {
                    model = heliModel,
                    name = heliModel.Name,
                    primaryPart = primaryPart
                })
            end
        end
    end
    
    return foundHelicopters
end

local function createHelicopterESP(heliData)
    if not heliData.model or not heliData.primaryPart then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Helicopter_Highlight"
    highlight.Adornee = heliData.model
    highlight.FillColor = Color3.fromRGB(100, 200, 100)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = heliData.model
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = heliData.name .. "_ESP"
    billboard.Adornee = heliData.primaryPart
    billboard.Size = UDim2.new(0, 250, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 15, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 20000
    billboard.Parent = HeliESPfolder
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "🚁 " .. heliData.name .. "\nLoading..."
    textLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.2
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 16
    textLabel.TextWrapped = true
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Parent = billboard
    
    return {
        highlight = highlight,
        billboard = billboard,
        textLabel = textLabel,
        model = heliData.model,
        primaryPart = heliData.primaryPart,
        name = heliData.name
    }
end

local function updateHelicopterESP(espData)
    if not espData.model or not espData.model.Parent then
        if espData.highlight then espData.highlight:Destroy() end
        if espData.billboard then espData.billboard:Destroy() end
        return false
    end
    
    local healthValue = 100
    local maxHealthValue = 100
    
    local health = espData.model:FindFirstChild("Health")
    local maxHealth = espData.model:FindFirstChild("MaxHealth")
    
    if not health then
        for _, child in pairs(espData.model:GetDescendants()) do
            if child.Name == "Health" and child:IsA("NumberValue") then
                health = child
                break
            end
        end
    end
    
    if not maxHealth then
        for _, child in pairs(espData.model:GetDescendants()) do
            if child.Name == "MaxHealth" and child:IsA("NumberValue") then
                maxHealth = child
                break
            end
        end
    end
    
    if health then healthValue = health.Value end
    if maxHealth then maxHealthValue = maxHealth.Value end
    
    if maxHealthValue == 100 then
        maxHealthValue = 3000
    end
    
    local distance = 0
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and espData.primaryPart then
        distance = (LocalPlayer.Character.PrimaryPart.Position - espData.primaryPart.Position).Magnitude
    end
    
    local healthPercent = math.floor((healthValue / maxHealthValue) * 100)
    
    espData.textLabel.Text = string.format("%s %s\n❤ HP: %d%%\n📏 %d studs", 
        "🚁",
        espData.name,
        healthPercent,
        math.floor(distance)
    )
    
    if healthPercent < 30 then
        espData.textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        espData.highlight.FillColor = Color3.fromRGB(255, 50, 50)
    elseif healthPercent < 60 then
        espData.textLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
        espData.highlight.FillColor = Color3.fromRGB(255, 255, 50)
    else
        espData.textLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        espData.highlight.FillColor = Color3.fromRGB(100, 200, 100)
    end
    
    return true
end

local trackedHelicopters = {}

local function mainHelicopterESP()
    local foundHelis = findAllHelicopters()
    
    for _, heliData in pairs(foundHelis) do
        if not trackedHelicopters[heliData.model] then
            local espData = createHelicopterESP(heliData)
            if espData then
                trackedHelicopters[heliData.model] = espData
            end
        end
    end
    
    for model, espData in pairs(trackedHelicopters) do
        if not updateHelicopterESP(espData) then
            trackedHelicopters[model] = nil
        end
    end
end

local connection
local function startHelicopterESP()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        pcall(mainHelicopterESP)
    end)
end

wait(1)
startHelicopterESP()

print("heli esp loaded")
