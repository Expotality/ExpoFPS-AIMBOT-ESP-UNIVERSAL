--[[
    ╔══════════════════════════════════════════════════════════╗
    ║   ExpoFPS  v6  •  Solara / UNC Executor                  ║
    ║   Head lock • Wallcheck • ESP • Collapsible              ║
    ╚══════════════════════════════════════════════════════════╝
]]

--===================== SERVICES =====================--
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

--===================== CAPABILITY CHECK =============--
local HAS_MOUSE = (type(mousemoverel) == "function")
local HAS_HUI   = (type(gethui) == "function")
local HAS_DRAW  = (type(Drawing) == "table")
local EXCLUDE   = Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Blacklist

--===================== CONFIG =======================--
local Config = {
	Enabled      = false,
	WallCheck    = true,
	TeamCheck    = true,
	MouseAim     = HAS_MOUSE,
	PauseOverUI  = true,
	ShowFOV      = true,
	HoldMode     = false,
	ESP          = true,
	ESPAll       = false,
	Smoothness   = 0.85,
	FOV          = 10,
	Range        = 2000,
	Key          = Enum.KeyCode.z,
	MouseKey     = nil,
	CollapseKey  = Enum.KeyCode.RightShift,
}

--===================== THEME ========================--
local ACCENT   = Color3.fromRGB(150, 115, 255)
local ACCENT2  = Color3.fromRGB(90, 200, 255)
local BG       = Color3.fromRGB(17, 17, 23)
local BG_SOFT  = Color3.fromRGB(26, 26, 34)
local TEXT     = Color3.fromRGB(238, 238, 248)
local SUBTEXT  = Color3.fromRGB(148, 148, 165)
local TRACKOFF = Color3.fromRGB(46, 46, 58)

local ESP_ENEMY = Color3.fromRGB(255, 70, 70)
local ESP_ALLY  = Color3.fromRGB(70, 235, 120)

--===================== STATE ========================--
local holding = false   -- true while the hold key is down

--===================== HELPERS ======================--
local function create(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then obj[k] = v end
	end
	obj.Parent = parent
	return obj
end

local function corner(radius, parent)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

--===================== GUI ROOT =====================--
local guiParent = game:GetService("CoreGui")
if HAS_HUI then
	local ok, hui = pcall(gethui)
	if ok and hui then guiParent = hui end
end

for _, name in ipairs({ "ExpoFPS", "ExpoESP", "VeniceAim", "VeniceESP" }) do
	local old = guiParent:FindFirstChild(name)
	if old then old:Destroy() end
end
pcall(function() RunService:UnbindFromRenderStep("ExpoFPS") end)

local gui = create("ScreenGui", {
	Name = "ExpoFPS",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, guiParent)

--===================== MAIN FRAME ===================--
local main = create("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(330, 560),
	Position = UDim2.new(0.5, -165, 0.5, -280),
	BackgroundColor3 = BG,
	BorderSizePixel = 0,
}, gui)
corner(14, main)
create("UIStroke", { Color = Color3.fromRGB(48, 48, 62), Thickness = 1 }, main)

local glow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 96),
	BackgroundColor3 = ACCENT,
	BackgroundTransparency = 0.87,
	BorderSizePixel = 0,
	ZIndex = 0,
}, main)
corner(14, glow)
create("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Rotation = 90,
}, glow)

--===================== TOP BAR ======================--
local topbar = create("Frame", {
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
}, main)

local accentBar = create("Frame", {
	Size = UDim2.fromOffset(4, 22),
	Position = UDim2.new(0, 14, 0, 15),
	BackgroundColor3 = ACCENT,
	BorderSizePixel = 0,
}, topbar)
corner(3, accentBar)
create("UIGradient", { Color = ColorSequence.new(ACCENT, ACCENT2), Rotation = 90 }, accentBar)

create("TextLabel", {
	Size = UDim2.new(1, -70, 0, 18),
	Position = UDim2.new(0, 26, 0, 12),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "ExpoFPS",
	TextColor3 = TEXT,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topbar)

create("TextLabel", {
	Size = UDim2.new(1, -70, 0, 14),
	Position = UDim2.new(0, 26, 0, 28),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "head lock • wallcheck • esp",
	TextColor3 = SUBTEXT,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
}, topbar)

local dotBtn = create("TextButton", {
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -32, 0, 13),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
}, topbar)

local statusDot = create("Frame", {
	Size = UDim2.fromOffset(9, 9),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = Color3.fromRGB(70, 70, 85),
	BorderSizePixel = 0,
}, dotBtn)
corner(5, statusDot)

--===================== CONTENT ======================--
local content = create("ScrollingFrame", {
	Size = UDim2.new(1, -28, 1, -96),
	Position = UDim2.new(0, 14, 0, 56),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Color3.fromRGB(60, 60, 78),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, main)

create("UIListLayout", {
	Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

local hintLbl = create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 1, -26),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Press Right Shift to close",
	TextColor3 = SUBTEXT,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Center,
}, main)

--===================== WIDGETS ======================--
local function makeToggle(label, default, callback)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
	}, content)

	create("TextLabel", {
		Size = UDim2.new(1, -56, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = label,
		TextColor3 = TEXT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local track = create("Frame", {
		Size = UDim2.fromOffset(40, 21),
		Position = UDim2.new(1, -40, 0.5, -10.5),
		BackgroundColor3 = TRACKOFF,
		BorderSizePixel = 0,
	}, row)
	corner(11, track)

	local knob = create("Frame", {
		Size = UDim2.fromOffset(15, 15),
		Position = UDim2.new(0, 3, 0.5, -7.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, track)
	corner(8, knob)

	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, track)

	local value = default

	local function render(animate)
		local goalPos = value and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5)
		local goalCol = value and ACCENT or TRACKOFF
		if animate then
			TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = goalPos }):Play()
			TweenService:Create(track, TweenInfo.new(0.16), { BackgroundColor3 = goalCol }):Play()
		else
			knob.Position = goalPos
			track.BackgroundColor3 = goalCol
		end
	end

	button.MouseButton1Click:Connect(function()
		value = not value
		render(true)
		if callback then callback(value) end
	end)

	render(false)

	return {
		get = function() return value end,
		set = function(v)
			value = v
			render(true)
			if callback then callback(v) end
		end,
	}
end

local function makeSlider(label, minV, maxV, defaultV, fmt, callback)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
	}, content)

	create("TextLabel", {
		Size = UDim2.new(1, -70, 0, 15),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = label,
		TextColor3 = TEXT,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local valLbl = create("TextLabel", {
		Size = UDim2.new(1, -70, 0, 15),
		Position = UDim2.new(0, 70, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = fmt(defaultV),
		TextColor3 = ACCENT,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)

	local hit = create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 18),
		BackgroundTransparency = 1,
	}, row)

	local bar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0.5, -3),
		BackgroundColor3 = Color3.fromRGB(42, 42, 54),
		BorderSizePixel = 0,
	}, hit)
	corner(3, bar)

	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
	}, bar)
	corner(3, fill)
	create("UIGradient", { Color = ColorSequence.new(ACCENT, ACCENT2) }, fill)

	local knob = create("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, hit)
	corner(7, knob)
	create("UIStroke", { Color = ACCENT, Thickness = 2 }, knob)

	local value    = defaultV
	local dragging = false

	local function render()
		local t = math.clamp((value - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(t, 0, 1, 0)
		knob.Position = UDim2.new(t, 0, 0.5, 0)
		valLbl.Text = fmt(value)
	end

	local function updateFromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		value = minV + (maxV - minV) * rel
		render()
		if callback then callback(value) end
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	render()

	return {
		get = function() return value end,
		set = function(v)
			value = math.clamp(v, minV, maxV)
			render()
			if callback then callback(value) end
		end,
	}
end

--===================== BUILD UI =====================--
local enableToggle = makeToggle("Enabled", Config.Enabled, function(v) Config.Enabled = v end)
local wallToggle   = makeToggle("Wallcheck", Config.WallCheck, function(v) Config.WallCheck = v end)
local teamToggle   = makeToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
local mouseToggle  = makeToggle("Move Mouse (off = camera)", Config.MouseAim, function(v) Config.MouseAim = v end)
local pauseToggle  = makeToggle("Pause Over UI", Config.PauseOverUI, function(v) Config.PauseOverUI = v end)
local fovToggle    = makeToggle("FOV Circle", Config.ShowFOV, function(v) Config.ShowFOV = v end)
local holdToggle   = makeToggle("Hold Mode (key)", Config.HoldMode, function(v)
	Config.HoldMode = v
	if not v then holding = false end
end)

local espToggle    = makeToggle("ESP", Config.ESP, function(v) Config.ESP = v end)
local espAllToggle = makeToggle("ESP: All Players", Config.ESPAll, function(v) Config.ESPAll = v end)

local smoothSlider = makeSlider("Smoothness", 0, 1, Config.Smoothness,
	function(v) return string.format("%.2f", v) end,
	function(v) Config.Smoothness = v end)

local fovSlider = makeSlider("FOV", 1, 90, Config.FOV,
	function(v) return string.format("%d deg", math.floor(v + 0.5)) end,
	function(v) Config.FOV = v end)

local rangeSlider = makeSlider("Range (studs)", 50, 2000, Config.Range,
	function(v) return string.format("%d", math.floor(v + 0.5)) end,
	function(v) Config.Range = v end)

-- keybind row
local keyRow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
}, content)

create("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	Text = "Aim Key",
	TextColor3 = TEXT,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
}, keyRow)

local keyBtn = create("TextButton", {
	Size = UDim2.fromOffset(60, 24),
	Position = UDim2.new(1, -60, 0.5, -12),
	BackgroundColor3 = BG_SOFT,
	Text = Config.Key.Name,
	TextColor3 = TEXT,
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	AutoButtonColor = false,
}, keyRow)
corner(8, keyBtn)
create("UIStroke", { Color = Color3.fromRGB(55, 55, 70), Thickness = 1 }, keyBtn)

local statusLbl = create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Standby",
	TextColor3 = SUBTEXT,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
}, content)

--===================== COLLAPSED PILL ===============--
local mini = create("Frame", {
	Name = "Mini",
	Size = UDim2.fromOffset(250, 40),
	Position = main.Position,
	BackgroundColor3 = BG,
	BorderSizePixel = 0,
	Visible = false,
}, gui)
corner(12, mini)
create("UIStroke", { Color = Color3.fromRGB(48, 48, 62), Thickness = 1 }, mini)

local miniDot = create("Frame", {
	Size = UDim2.fromOffset(8, 8),
	Position = UDim2.new(0, 14, 0.5, -4),
	BackgroundColor3 = ESP_ALLY,
	BorderSizePixel = 0,
}, mini)
corner(4, miniDot)

local miniBtn = create("TextButton", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "Press Right Shift to open",
	TextColor3 = SUBTEXT,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	AutoButtonColor = false,
}, mini)

local collapsed = false

local function setCollapsed(state)
	if collapsed == state then return end
	collapsed = state
	if collapsed then
		mini.Position = main.Position
		main.Visible = false
		mini.Visible = true
	else
		main.Position = mini.Position
		mini.Visible = false
		main.Visible = true
	end
end

dotBtn.MouseButton1Click:Connect(function() setCollapsed(true) end)
miniBtn.MouseButton1Click:Connect(function() setCollapsed(false) end)

dotBtn.MouseEnter:Connect(function()
	TweenService:Create(statusDot, TweenInfo.new(0.12), { Size = UDim2.fromOffset(12, 12) }):Play()
end)
dotBtn.MouseLeave:Connect(function()
	TweenService:Create(statusDot, TweenInfo.new(0.12), { Size = UDim2.fromOffset(9, 9) }):Play()
end)

--===================== DRAGGING =====================--
local dragging, dragStart, startPos = false, nil, nil

local function attachDrag(handle)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = input.Position
			startPos  = main.Position
		end
	end)
end

attachDrag(topbar)
attachDrag(mini)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		main.Position = newPos
		mini.Position = newPos
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--===================== WALLCHECK ====================--
local rayParams = RaycastParams.new()
rayParams.FilterType  = EXCLUDE
rayParams.IgnoreWater = true

local function isVisible(part)
	local cam = Workspace.CurrentCamera
	if not cam or not part then return false end

	local ignore = {}
	if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
	if part.Parent then table.insert(ignore, part.Parent) end
	rayParams.FilterDescendantsInstances = ignore

	local origin = cam.CFrame.Position
	local hit = Workspace:Raycast(origin, part.Position - origin, rayParams)
	return hit == nil
end

--===================== TEAM / TARGETING =============--
local function isTeammate(plr)
	if not plr.Team or not LocalPlayer.Team then return false end
	return plr.Team == LocalPlayer.Team
end

local function inFOV(worldPos, cam, maxDeg)
	local dir  = (worldPos - cam.CFrame.Position).Unit
	local look = cam.CFrame.LookVector
	local ang  = math.deg(math.acos(math.clamp(dir:Dot(look), -1, 1)))
	return ang <= maxDeg
end

local function getTarget()
	local cam = Workspace.CurrentCamera
	if not cam then return nil end

	local camPos = cam.CFrame.Position
	local best, bestDist = nil, math.huge

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not (Config.TeamCheck and isTeammate(plr)) then
			local char = plr.Character
			if char then
				local head = char:FindFirstChild("Head")
				local hum  = char:FindFirstChildOfClass("Humanoid")
				if head and hum and hum.Health > 0 then
					local dist = (head.Position - camPos).Magnitude
					if dist < bestDist and dist <= Config.Range and inFOV(head.Position, cam, Config.FOV) then
						if not Config.WallCheck or isVisible(head) then
							best, bestDist = head, dist
						end
					end
				end
			end
		end
	end

	return best
end

--===================== ESP ==========================--
local espGui = create("ScreenGui", {
	Name = "ExpoESP",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local markers = {}

local function removeMarker(plr)
	local m = markers[plr]
	if m then
		m.Box:Destroy()
		m.Label:Destroy()
		markers[plr] = nil
	end
end

local function hideMarker(plr)
	local m = markers[plr]
	if m then
		m.Box.Visible = false
		m.Label.Visible = false
	end
end

local function createMarker(plr)
	if markers[plr] then return markers[plr] end

	local box = create("Frame", {
		Name = "ESPBox",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	}, espGui)
	local stroke = create("UIStroke", { Color = ESP_ENEMY, Thickness = 2 }, box)

	local label = create("TextLabel", {
		Name = "ESPName",
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextStrokeTransparency = 0,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Size = UDim2.fromOffset(240, 18),
		AnchorPoint = Vector2.new(0.5, 1),
		Visible = false,
	}, espGui)

	markers[plr] = { Box = box, Label = label, Stroke = stroke }
	return markers[plr]
end

local function getScreenBounds(camera, character)
	local cf, size = character:GetBoundingBox()
	local half = size / 2

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local count = 0

	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local worldPosition = cf:PointToWorldSpace(
					Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
				)
				local sp = camera:WorldToViewportPoint(worldPosition)
				if sp.Z <= 0 then return nil end
				count += 1
				minX = math.min(minX, sp.X)
				minY = math.min(minY, sp.Y)
				maxX = math.max(maxX, sp.X)
				maxY = math.max(maxY, sp.Y)
			end
		end
	end

	if count ~= 8 or maxX <= minX or maxY <= minY then return nil end
	return minX, minY, maxX, maxY
end

local function updateESP(plr, camera)
	if plr == LocalPlayer then return end

	local char = plr.Character
	if not char or not char.Parent then
		hideMarker(plr)
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		hideMarker(plr)
		return
	end

	local ally = isTeammate(plr)

	if not Config.ESPAll and ally then
		hideMarker(plr)
		return
	end

	local minX, minY, maxX, maxY = getScreenBounds(camera, char)
	if not minX then
		hideMarker(plr)
		return
	end

	local viewport = camera.ViewportSize
	if maxX < 0 or minX > viewport.X or maxY < 0 or minY > viewport.Y then
		hideMarker(plr)
		return
	end

	local marker = createMarker(plr)
	marker.Stroke.Color = ally and ESP_ALLY or ESP_ENEMY

	marker.Box.Position = UDim2.fromOffset(minX, minY)
	marker.Box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
	marker.Box.Visible = true

	local dist = math.floor((char:GetPivot().Position - camera.CFrame.Position).Magnitude)
	marker.Label.Text = string.format("%s [%d]", plr.DisplayName, dist)
	marker.Label.Position = UDim2.fromOffset((minX + maxX) * 0.5, minY - 3)
	marker.Label.Visible = true
end

Players.PlayerRemoving:Connect(removeMarker)

--===================== FOV CIRCLE ===================--
local fovCircle
if HAS_DRAW then
	local ok, circle = pcall(function()
		local c = Drawing.new("Circle")
		c.Thickness    = 1.5
		c.NumSides     = 72
		c.Filled       = false
		c.Color        = ACCENT
		c.Transparency = 0.85
		c.Visible      = false
		return c
	end)
	if ok then fovCircle = circle end
end

--===================== KEYBIND ======================--
local listening = false

keyBtn.MouseButton1Click:Connect(function()
	listening = true
	keyBtn.Text = "..."
	keyBtn.TextColor3 = ACCENT
end)

local function isAimInput(input)
	if Config.MouseKey then
		return input.UserInputType == Config.MouseKey
	end
	return Config.Key ~= nil and input.KeyCode == Config.Key
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if listening then
		listening = false
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3 then
			Config.MouseKey = input.UserInputType
			Config.Key = nil
			keyBtn.Text = input.UserInputType.Name:gsub("MouseButton", "Mouse")
		elseif input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.Key = input.KeyCode
			Config.MouseKey = nil
			keyBtn.Text = input.KeyCode.Name
		end
		keyBtn.TextColor3 = TEXT
		return
	end

	if input.KeyCode == Config.CollapseKey then
		setCollapsed(not collapsed)
		return
	end

	if isAimInput(input) then
		if Config.HoldMode then
			holding = true
		else
			enableToggle.set(not enableToggle.get())
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if Config.HoldMode and isAimInput(input) then
		holding = false
	end
end)

--===================== AIM ==========================--
local function isActive()
	if Config.HoldMode then return holding end
	return Config.Enabled
end

local function getMouseViewportPos()
	local inset = GuiService:GetGuiInset()
	local m = UserInputService:GetMouseLocation()
	return Vector2.new(m.X - inset.X, m.Y - inset.Y)
end

local function mouseOverUI()
	if not Config.PauseOverUI then return false end
	local frame = collapsed and mini or main
	if not frame.Visible then return false end

	local m = getMouseViewportPos()
	local p, s = frame.AbsolutePosition, frame.AbsoluteSize
	return m.X >= p.X and m.X <= p.X + s.X
		and m.Y >= p.Y and m.Y <= p.Y + s.Y
end

local function aimWithMouse(targetPos)
	if not HAS_MOUSE then return end
	local cam = Workspace.CurrentCamera
	if not cam then return end

	local sp, onScreen = cam:WorldToViewportPoint(targetPos)
	if not onScreen or sp.Z <= 0 then return end

	-- Aim at the CROSSHAIR (viewport centre). Using the free cursor as the
	-- reference made the camera travel only half way to the target, so the
	-- crosshair settled short / under the player.
	local vp     = cam.ViewportSize
	local centre = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
	local delta  = Vector2.new(sp.X, sp.Y) - centre

	if delta.Magnitude < 0.5 then return end

	local factor = 1 - math.clamp(Config.Smoothness, 0, 0.98)
	mousemoverel(delta.X * factor, delta.Y * factor)
end

local function aimWithCamera(targetPos, dt)
	local cam = Workspace.CurrentCamera
	if not cam then return end

	local alpha = 1 - math.clamp(Config.Smoothness, 0, 0.98)
	alpha = 1 - (1 - alpha) ^ (dt * 60)

	if Config.Smoothness <= 0.001 then
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
	else
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, targetPos), alpha)
	end
end

--===================== MAIN LOOP ====================--
RunService:BindToRenderStep("ExpoFPS", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local cam = Workspace.CurrentCamera
	if not cam then return end

	local active = isActive()

	statusDot.BackgroundColor3 = active and ESP_ALLY or Color3.fromRGB(70, 70, 85)

	if Config.ESP then
		for _, plr in ipairs(Players:GetPlayers()) do
			updateESP(plr, cam)
		end
	else
		for plr in pairs(markers) do
			hideMarker(plr)
		end
	end

	if fovCircle then
		if Config.ShowFOV and active then
			local vp = cam.ViewportSize
			local radius = math.tan(math.rad(Config.FOV * 0.5))
				/ math.tan(math.rad(cam.FieldOfView * 0.5))
				* (vp.Y * 0.5)
			fovCircle.Radius   = radius
			fovCircle.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
			fovCircle.Visible  = true
		else
			fovCircle.Visible = false
		end
	end

	if not active then
		statusLbl.Text = "Standby"
		statusLbl.TextColor3 = SUBTEXT
		return
	end

	if mouseOverUI() then
		statusLbl.Text = "Paused (UI)"
		statusLbl.TextColor3 = SUBTEXT
		return
	end

	local target = getTarget()
	if not target then
		statusLbl.Text = "Searching..."
		statusLbl.TextColor3 = SUBTEXT
		return
	end

	statusLbl.Text = "Locked: " .. target.Parent.Name
	statusLbl.TextColor3 = ACCENT

	if Config.MouseAim and HAS_MOUSE then
		aimWithMouse(target.Position)
	else
		aimWithCamera(target.Position, dt)
	end
end)

--===================== NOTIFY =======================--
print(("[ExpoFPS v6] Loaded | mouse=%s | draw=%s | key=%s | collapse=%s")
	:format(tostring(HAS_MOUSE), tostring(HAS_DRAW), keyBtn.Text, Config.CollapseKey.Name))
