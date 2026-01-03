-- HELICOPTER ESP (Clean version - No UH-72B Lakota)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Очистка старых ESP
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "Helicopter_ESP" then
        v:Destroy()
    end
end

-- Создаём папку для ESP
local HeliESPfolder = Instance.new("Folder")
HeliESPfolder.Name = "Helicopter_ESP"
HeliESPfolder.Parent = CoreGui

-- Исключения (не показывать эти модели)
local EXCLUDED_HELICOPTERS = {
    ["UH-72B Lakota"] = true,
    ["UH72B Lakota"] = true,
    ["Lakota"] = true
}

-- Находим папку с вертолётами
local function getHelicopterWorkspace()
    local gameSystems = workspace:FindFirstChild("Game Systems")
    if not gameSystems then return nil end
    
    return gameSystems:FindFirstChild("Helicopter Workspace")
end

-- Ищем все вертолёты
local function findAllHelicopters()
    local heliWorkspace = getHelicopterWorkspace()
    if not heliWorkspace then return {} end
    
    local foundHelicopters = {}
    
    for _, heliModel in pairs(heliWorkspace:GetChildren()) do
        if heliModel:IsA("Model") then
            -- Пропускаем исключённые вертолёты
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

-- Создаём ESP для вертолёта
local function createHelicopterESP(heliData)
    if not heliData.model or not heliData.primaryPart then return nil end
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "Helicopter_Highlight"
    highlight.Adornee = heliData.model
    highlight.FillColor = Color3.fromRGB(100, 200, 100)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = heliData.model
    
    -- BillboardGui
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

-- Обновляем ESP
local function updateHelicopterESP(espData)
    if not espData.model or not espData.model.Parent then
        if espData.highlight then espData.highlight:Destroy() end
        if espData.billboard then espData.billboard:Destroy() end
        return false
    end
    
    -- Ищем здоровье
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
    
    -- Если MaxHealth не найден
    if maxHealthValue == 100 then
        maxHealthValue = 3000
    end
    
    -- Дистанция
    local distance = 0
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and espData.primaryPart then
        distance = (LocalPlayer.Character.PrimaryPart.Position - espData.primaryPart.Position).Magnitude
    end
    
    -- Процент здоровья
    local healthPercent = math.floor((healthValue / maxHealthValue) * 100)
    
    -- Обновляем текст
    espData.textLabel.Text = string.format("%s %s\n❤ HP: %d%%\n📏 %d studs", 
        "🚁",
        espData.name,
        healthPercent,
        math.floor(distance)
    )
    
    -- Цвет по проценту здоровья
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

-- Основной цикл
local trackedHelicopters = {}
local initialized = false

local function mainHelicopterESP()
    -- Ищем вертолёты
    local foundHelis = findAllHelicopters()
    
    -- Добавляем новые
    for _, heliData in pairs(foundHelis) do
        if not trackedHelicopters[heliData.model] then
            local espData = createHelicopterESP(heliData)
            if espData then
                trackedHelicopters[heliData.model] = espData
                if not initialized then
                    initialized = true
                end
            end
        end
    end
    
    -- Обновляем и удаляем старые
    for model, espData in pairs(trackedHelicopters) do
        if not updateHelicopterESP(espData) then
            trackedHelicopters[model] = nil
        end
    end
end

-- Запуск
local connection
local function startHelicopterESP()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.Heartbeat:Connect(function()
        pcall(mainHelicopterESP)
    end)
end

local function stopHelicopterESP()
    if connection then
        connection:Disconnect()
    end
    
    -- Очищаем всё
    for model, espData in pairs(trackedHelicopters) do
        if espData.highlight then 
            pcall(function() espData.highlight:Destroy() end) 
        end
        if espData.billboard then 
            pcall(function() espData.billboard:Destroy() end) 
        end
    end
    
    trackedHelicopters = {}
    
    if HeliESPfolder then
        HeliESPfolder:Destroy()
    end
end

-- Автостарт
wait(1)
startHelicopterESP()

-- Управление
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F4 then
        stopHelicopterESP()
        wait(0.1)
        startHelicopterESP()
    elseif input.KeyCode == Enum.KeyCode.F5 then
        stopHelicopterESP()
    end
end)

print("Helicopter ESP loaded")
print("Excluding: UH-72B Lakota")
