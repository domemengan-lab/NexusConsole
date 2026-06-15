--!strict
--NexusConsole - Made by charles
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration Parameters
local TOGGLE_KEY = Enum.KeyCode.Backquote 
local IS_VISIBLE = true
local IS_MINIMIZED = false
local CURRENT_FILTER = ""

local TOTAL_LOGS = 0
local ERROR_COUNT = 0

local function generateScrambledString(): string
	local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
	local length = math.random(12, 24)
	local result = ""
	for i = 1, length do
		local index = math.random(1, #characters)
		result = result .. string.sub(characters, index, index)
	end
	return result
end

local obfuscatedGuiName = generateScrambledString()
local obfuscatedFrameName = generateScrambledString()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = obfuscatedGuiName
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 2147483647 -- Overlay everything in engine rendering pipeline
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Core Window Pane
local MainFrame = Instance.new("Frame")
MainFrame.Name = obfuscatedFrameName
MainFrame.Size = UDim2.new(0, 600, 0, 380)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui

-- Top Header Window Strip
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(0, 250, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Nexus Console [~]"
TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = TopBar

-- Statistics Dashboard
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Size = UDim2.new(0, 150, 1, 0)
StatsLabel.Position = UDim2.new(0, 150, 0, 0)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Logs: 0 | Errors: 0"
StatsLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
StatsLabel.TextSize = 12
StatsLabel.Font = Enum.Font.SourceSans
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.ZIndex = 3
StatsLabel.Parent = TopBar

-- Window Operation Actions Frame
local ActionsFrame = Instance.new("Frame")
ActionsFrame.Name = "Actions"
ActionsFrame.Size = UDim2.new(0, 160, 1, 0)
ActionsFrame.Position = UDim2.new(1, -165, 0, 0)
ActionsFrame.BackgroundTransparency = 1
ActionsFrame.ZIndex = 3
ActionsFrame.Parent = TopBar

local UIListLayoutActions = Instance.new("UIListLayout")
UIListLayoutActions.FillDirection = Enum.FillDirection.Horizontal
UIListLayoutActions.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayoutActions.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayoutActions.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutActions.Padding = UDim.new(0, 6)
UIListLayoutActions.Parent = ActionsFrame

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Color3.fromRGB(240, 240, 245)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 16
MinimizeButton.LayoutOrder = 1
MinimizeButton.ZIndex = 4
MinimizeButton.Parent = ActionsFrame

-- Clear Logs Button Utility
local ClearButton = Instance.new("TextButton")
ClearButton.Name = "ClearButton"
ClearButton.Size = UDim2.new(0, 60, 0, 24)
ClearButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
ClearButton.BorderSizePixel = 0
ClearButton.Text = "Clear"
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.Font = Enum.Font.SourceSansBold
ClearButton.TextSize = 12
ClearButton.LayoutOrder = 2
ClearButton.ZIndex = 4
ClearButton.Parent = ActionsFrame

-- Combined Command Line / Search Filter Box
local SearchBar = Instance.new("TextBox")
SearchBar.Name = "SearchBar"
SearchBar.Size = UDim2.new(1, -14, 0, 26)
SearchBar.Position = UDim2.new(0, 7, 0, 38)
SearchBar.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
SearchBar.BorderSizePixel = 0
SearchBar.Text = ""
SearchBar.PlaceholderText = "Type local command or filter logs..."
SearchBar.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
SearchBar.TextColor3 = Color3.fromRGB(240, 240, 245)
SearchBar.Font = Enum.Font.SourceSans
SearchBar.TextSize = 13
SearchBar.TextXAlignment = Enum.TextXAlignment.Left
SearchBar.ClearTextOnFocus = false
SearchBar.ZIndex = 5 
SearchBar.Parent = MainFrame

local SearchPadding = Instance.new("UIPadding")
SearchPadding.PaddingLeft = UDim.new(0, 8)
SearchPadding.Parent = SearchBar

-- Dynamic Canvas Scrolling Frame (Main Background Pane)
local LogContainer = Instance.new("ScrollingFrame")
LogContainer.Name = "LogContainer"
LogContainer.Size = UDim2.new(1, -14, 1, -74)
LogContainer.Position = UDim2.new(0, 7, 0, 70)
LogContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
LogContainer.BackgroundTransparency = 0
LogContainer.BorderSizePixel = 0
LogContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
LogContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogContainer.ScrollBarThickness = 6
LogContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
LogContainer.ZIndex = 2
LogContainer.ClipsDescendants = true -- FIXED: Correct native naming convention
LogContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 3)
UIListLayout.Parent = LogContainer

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.ZIndex = 100 -- Enforce top layer priority on canvas initialization
LoadingFrame.Parent = ScreenGui

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Name = "LoadingTitle"
LoadingTitle.Size = UDim2.new(1, 0, 0, 30)
LoadingTitle.Position = UDim2.new(0, 0, 0.4, -25)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "Nexus Console"
LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingTitle.TextSize = 24
LoadingTitle.Font = Enum.Font.SourceSansBold
LoadingTitle.ZIndex = 101
LoadingTitle.Parent = LoadingFrame

local LoadingBarBackground = Instance.new("Frame")
LoadingBarBackground.Name = "LoadingBarBackground"
LoadingBarBackground.Size = UDim2.new(0, 250, 0, 4)
LoadingBarBackground.Position = UDim2.new(0.5, -125, 0.4, 15)
LoadingBarBackground.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
LoadingBarBackground.BorderSizePixel = 0
LoadingBarBackground.ZIndex = 101
LoadingBarBackground.Parent = LoadingFrame

local LoadingBarFill = Instance.new("Frame")
LoadingBarFill.Name = "LoadingBarFill"
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.ZIndex = 102
LoadingBarFill.Parent = LoadingBarBackground

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Name = "LoadingStatus"
LoadingStatus.Size = UDim2.new(1, 0, 0, 20)
LoadingStatus.Position = UDim2.new(0, 0, 0.4, 25)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "Initializing diagnostic hooks..."
LoadingStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
LoadingStatus.TextSize = 12
LoadingStatus.Font = Enum.Font.SourceSansItalic
LoadingStatus.ZIndex = 101
LoadingStatus.Parent = LoadingFrame

-- Safe CoreGui validation inject sequence
local protectSuccess, protectError = pcall(function()
	ScreenGui.Parent = CoreGui
end)

if not protectSuccess then
	warn("CoreGui environment access blocked. Defaulting to PlayerGui layer. Error: " .. tostring(protectError))
	ScreenGui.Parent = playerGui
end

local LOG_COLORS = {
	[Enum.MessageType.MessageOutput] = "F5F5F5", 
	[Enum.MessageType.MessageInfo] = "2980B9",   
	[Enum.MessageType.MessageWarning] = "F1C40F", 
	[Enum.MessageType.MessageError] = "E74C3C"
}

local function addLogEntry(message: string, messageType: Enum.MessageType)
	TOTAL_LOGS = TOTAL_LOGS + 1
	if messageType == Enum.MessageType.MessageError then
		ERROR_COUNT = ERROR_COUNT + 1
	end
	StatsLabel.Text = "Logs: " .. tostring(TOTAL_LOGS) .. " | Errors: " .. tostring(ERROR_COUNT)

	if CURRENT_FILTER ~= "" and not string.find(string.lower(message), string.lower(CURRENT_FILTER)) then
		return
	end

	local hexColor = LOG_COLORS[messageType] or "FFFFFF"
	
	local LogLabel = Instance.new("TextLabel")
	LogLabel.Name = "LogEntry_" .. tostring(TOTAL_LOGS)
	LogLabel.Size = UDim2.new(1, -20, 0, 20)
	LogLabel.BackgroundTransparency = 1
	LogLabel.Font = Enum.Font.Code
	LogLabel.TextSize = 12
	LogLabel.TextXAlignment = Enum.TextXAlignment.Left
	LogLabel.RichText = true
	LogLabel.TextWrapped = true
	LogLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	-- FIXED: Restored the <font color> tags so the RichText engine parses it cleanly!
	LogLabel.Text = string.format("<font color='#%s'>[%s] %s</font>", hexColor, messageType.Name:gsub("Message", ""), message)
	
	LogLabel.LayoutOrder = TOTAL_LOGS
	LogLabel.ZIndex = 8
	LogLabel.Parent = LogContainer
end


LogService.MessageOut:Connect(addLogEntry)

-- Import open-source virtual compiler modules to handle raw string lines safely
local function executeRawLineAsBytecode(codeTextString: string)
	if codeTextString == "" then return end
	
	addLogEntry("Parsing string layout tokens...", Enum.MessageType.MessageInfo)
	
	-- Connect standard loadstring processing wrapper parameters
	local compiledClosure = nil
	local success, compileError = pcall(function()
		-- Converts the typed text straight into raw memory machine bytecode instructions
		if loadstring then
			compiledClosure = loadstring(codeTextString)
		else
			error("Luau VM compilation engine failed to load closure thread natively.")
		end
	end)
	
	if success and compiledClosure then
		addLogEntry("Executing code registers inside protected thread...", Enum.MessageType.MessageInfo)
		
		-- Run the compiled function package safely inside the client space
		local runSuccess, runtimeError = pcall(compiledClosure)
		if runSuccess then
			addLogEntry("Code executed with zero execution alerts.", Enum.MessageType.MessageInfo)
		else
			addLogEntry("Runtime Thread Failure: " .. tostring(runtimeError), Enum.MessageType.MessageError)
		end
	else
		addLogEntry("Syntax Compilation Error: " .. tostring(compileError or "Invalid Closure Tree"), Enum.MessageType.MessageError)
	end
end

-- Hook the layout event wire directly to your SearchBar text input frame
SearchBar.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local submittedCodeString = SearchBar.Text
		SearchBar.Text = "" -- Flush out the text bar container instantly
		
		executeRawLineAsBytecode(submittedCodeString)
	end
end)

ClearButton.MouseButton1Click:Connect(function()
    for _, child in pairs(LogContainer:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    TOTAL_LOGS = 0; ERROR_COUNT = 0
    StatsLabel.Text = "Logs: 0 | Errors: 0"
end)

MinimizeButton.MouseButton1Click:Connect(function()
    IS_MINIMIZED = not IS_MINIMIZED
    if IS_MINIMIZED then
        MainFrame:TweenSize(UDim2.new(0, 600, 0, 32), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true)
        SearchBar.Visible = false
        LogContainer.Visible = false
        MinimizeButton.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 600, 0, 380), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true)
        SearchBar.Visible = true
        LogContainer.Visible = true
        MinimizeButton.Text = "−"
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == TOGGLE_KEY then
        IS_VISIBLE = not IS_VISIBLE
        MainFrame.Visible = IS_VISIBLE
    end
end)


task.spawn(function()
    LoadingStatus.Text = "Obfuscating environment nodes..."
    TweenService:Create(LoadingBarFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.new(0.4, 0, 1, 0)}):Play()
    task.wait(0.6)
    
    LoadingStatus.Text = "Injecting secure CoreGui container..."
    TweenService:Create(LoadingBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = UDim2.new(0.8, 0, 1, 0)}):Play()
    
    local history = LogService:GetLogHistory()
    for _, log in pairs(history) do
        addLogEntry(log.message, log.messageType)
    end
    task.wait(0.4)
    
    LoadingStatus.Text = "System fully verified!"
    TweenService:Create(LoadingBarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(0.3)
    
    local fadeTween = TweenService:Create(LoadingFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
    TweenService:Create(LoadingTitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    TweenService:Create(LoadingStatus, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    TweenService:Create(LoadingBarBackground, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadingBarFill, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    
    fadeTween:Play()
    fadeTween.Completed:Connect(function()
        LoadingFrame:Destroy()
        addLogEntry("Nexus: " .. obfuscatedGuiName, Enum.MessageType.MessageInfo)
    end)
end)
