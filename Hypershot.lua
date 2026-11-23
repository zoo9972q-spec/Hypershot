-- HyperShot Dark-Cyan Utility UI v8 (Mobile Auto-Fire + Zero Recoil/Spread + Head/Body Lock)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local existingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("HyperShotCyanHub")
if existingGui then
	existingGui:Destroy()
end

pcall(function()
	RunService:UnbindFromRenderStep("HyperShotCyanAimLock")
end)

local State = {
	AimMode = "OFF",       -- "OFF" | "HEAD" | "BODY"
	AutoShoot = false,     -- ยิงอัตโนมัติเมื่อศัตรูโผล่เข้ามาในวง FOV
	NoRecoil = false,      -- ลดแรงดีดปืน + บีบกระสุนให้นิ่งตรง
	HideName = false,      -- ซ่อนชื่อตัวเอง
	Minimized = false,     -- พับเก็บหน้าต่าง
	FOVRadius = 110,       -- รัศมีวงกลมตรงกลางจอ
	AimSmooth = 0.88,      -- ความไวในการล็อคเข้าเป้า (0.1 - 1.0)
	DefaultWalkSpeed = 16,
	LastFireTime = 0,
	FireInterval = 0.06
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HyperShotCyanHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- วงกลม FOV ตรงกลางจอทาบเป๊ะกับเป้ากากบาท
local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FovCircle.Size = UDim2.new(0, State.FOVRadius * 2, 0, State.FOVRadius * 2)
FovCircle.BackgroundTransparency = 1
FovCircle.Visible = true
FovCircle.Active = false
FovCircle.Parent = ScreenGui

local FovCorner = Instance.new("UICorner")
FovCorner.CornerRadius = UDim.new(1, 0)
FovCorner.Parent = FovCircle

local FovStroke = Instance.new("UIStroke")
FovStroke.Color = Color3.fromRGB(0, 210, 255)
FovStroke.Thickness = 1.5
FovStroke.Transparency = 0.2
FovStroke.Parent = FovCircle

local function syncFovCircle()
	local sizePx = State.FOVRadius * 2
	FovCircle.Size = UDim2.new(0, sizePx, 0, sizePx)
end

-- หน้าต่างหลัก สีดำ-ฟ้า ขนาดกะทัดรัดไม่บังจอ
local FULL_WIDTH = 242
local FULL_HEIGHT = 248
local BAR_HEIGHT = 36

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, FULL_WIDTH, 0, FULL_HEIGHT)
MainFrame.Position = UDim2.new(0.5, -121, 0.24, -70)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 16, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 11)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 195, 255)
MainStroke.Thickness = 1.4
MainStroke.Transparency = 0.25
MainStroke.Parent = MainFrame

-- แถบหัวข้อสำหรับลากย้ายและพับเก็บ
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
TopBar.BackgroundColor3 = Color3.fromRGB(16, 26, 43)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 11)
TopCorner.Parent = TopBar

local TopFlat = Instance.new("Frame")
TopFlat.Size = UDim2.new(1, 0, 0, 10)
TopFlat.Position = UDim2.new(0, 0, 1, -10)
TopFlat.BackgroundColor3 = Color3.fromRGB(16, 26, 43)
TopFlat.BorderSizePixel = 0
TopFlat.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -44, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "HYPERSHOT // CYAN v8"
TitleLabel.TextColor3 = Color3.fromRGB(110, 225, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12.5
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 26, 0, 24)
ToggleBtn.Position = UDim2.new(1, -33, 0.5, -12)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 42, 68)
ToggleBtn.Text = "-"
ToggleBtn.TextColor3 = Color3.fromRGB(130, 235, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 15
ToggleBtn.ZIndex = 5
ToggleBtn.Parent = TopBar

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -16, 1, -(BAR_HEIGHT + 12))
ContentFrame.Position = UDim2.new(0, 8, 0, BAR_HEIGHT + 6)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local function makeButton(name, labelText, yPos, strokeColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 33)
	btn.Position = UDim2.new(0, 0, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(18, 28, 45)
	btn.Text = labelText
	btn.TextColor3 = Color3.fromRGB(225, 245, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11.8
	btn.Parent = ContentFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 1.1
	stroke.Transparency = 0.45
	stroke.Parent = btn

	return btn, stroke
end

local HeadBtn, HeadStroke = makeButton("HeadBtn", "ล็อคหัว : ปิด", 0, Color3.fromRGB(0, 195, 255))
local BodyBtn, BodyStroke = makeButton("BodyBtn", "ล็อคตัว : ปิด", 38, Color3.fromRGB(0, 155, 225))
local AutoBtn, AutoStroke = makeButton("AutoBtn", "ยิงในวงอัตโนมัติ : ปิด", 76, Color3.fromRGB(34, 211, 238))
local RecoilBtn, RecoilStroke = makeButton("RecoilBtn", "ลดแรงดีด+กระสุนนิ่ง : ปิด", 114, Color3.fromRGB(14, 165, 233))
local HideNameBtn, HideNameStroke = makeButton("HideNameBtn", "ซ่อนชื่อตัวเอง : ปิด", 152, Color3.fromRGB(56, 189, 248))

-- แถบปรับขนาดวง FOV (- / +)
local FovBar = Instance.new("Frame")
FovBar.Name = "FovBar"
FovBar.Size = UDim2.new(1, 0, 0, 24)
FovBar.Position = UDim2.new(0, 0, 0, 190)
FovBar.BackgroundColor3 = Color3.fromRGB(15, 24, 39)
FovBar.BorderSizePixel = 0
FovBar.Parent = ContentFrame

local FovBarCorner = Instance.new("UICorner")
FovBarCorner.CornerRadius = UDim.new(0, 7)
FovBarCorner.Parent = FovBar

local FovDown = Instance.new("TextButton")
FovDown.Size = UDim2.new(0, 32, 1, 0)
FovDown.Position = UDim2.new(0, 0, 0, 0)
FovDown.BackgroundColor3 = Color3.fromRGB(22, 38, 62)
FovDown.Text = "-"
FovDown.TextColor3 = Color3.fromRGB(125, 225, 255)
FovDown.Font = Enum.Font.GothamBold
FovDown.TextSize = 14
FovDown.Parent = FovBar

local FovDownCorner = Instance.new("UICorner")
FovDownCorner.CornerRadius = UDim.new(0, 7)
FovDownCorner.Parent = FovDown

local FovText = Instance.new("TextLabel")
FovText.Size = UDim2.new(1, -64, 1, 0)
FovText.Position = UDim2.new(0, 32, 0, 0)
FovText.BackgroundTransparency = 1
FovText.Text = "FOV : " .. tostring(State.FOVRadius)
FovText.TextColor3 = Color3.fromRGB(185, 235, 255)
FovText.Font = Enum.Font.GothamBold
FovText.TextSize = 11.5
FovText.Parent = FovBar

local FovUp = Instance.new("TextButton")
FovUp.Size = UDim2.new(0, 32, 1, 0)
FovUp.Position = UDim2.new(1, -32, 0, 0)
FovUp.BackgroundColor3 = Color3.fromRGB(22, 38, 62)
FovUp.Text = "+"
FovUp.TextColor3 = Color3.fromRGB(125, 225, 255)
FovUp.Font = Enum.Font.GothamBold
FovUp.TextSize = 14
FovUp.Parent = FovBar

local FovUpCorner = Instance.new("UICorner")
FovUpCorner.CornerRadius = UDim.new(0, 7)
FovUpCorner.Parent = FovUp

-- ระบบลากย้ายหน้าต่างบนมือถือและพีซี
local dragging = false
local dragStartPos = Vector2.zero
local frameStartPos = UDim2.new()

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
		frameStartPos = MainFrame.Position
	end
end)

TopBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local deltaX = input.Position.X - dragStartPos.X
		local deltaY = input.Position.Y - dragStartPos.Y
		MainFrame.Position = UDim2.new(
			frameStartPos.X.Scale,
        
