-- MatrixLab Script complet
-- UI Noir/Violet + ESP + Troll + FreeCam + Spectate + Settings + Danses
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

-- Variables d'état
local UIVisible = true
local currentTab = "ESP"
local ESPEnabled = false
local ShowBox = true
local ShowName = true
local ShowDistance = true
local ShowSnapline = true
local ShowSkeleton = false
local ESPColor = Color3.fromRGB(170, 85, 255) -- violet

local ESPFOV = 120
local ESPMaxDistance = 1000

local TrollStates = {
	Spinbot = false,
	Fly = false,
	Speed = false,
	NoClip = false,
	Invisible = false,
}

local FreeCamEnabled = false
local FreeCamSpeed = 50
local FreeCamCamera = nil
local FreeCamControls = {Forward=false, Backward=false, Left=false, Right=false, Up=false, Down=false}

local IsSpectating = false
local SpectateTarget = nil

local ShowWatermark = true

-- Watermark vars
local lastPing = 0
local lastFPS = 0
local lastTick = tick()

-- Fonctions utilitaires UI
local function roundCorners(frame)
	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(0, 10)
	uicorner.Parent = frame
	local uistroke = Instance.new("UIStroke")
	uistroke.Color = Color3.fromRGB(128, 0, 255)
	uistroke.Thickness = 2
	uistroke.Parent = frame
end

local function createText(parent,text,posY,size,font,color)
	local lbl = Instance.new("TextLabel")
	lbl.Parent = parent
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0,10,0,posY)
	lbl.Size = size or UDim2.new(1,-20,0,25)
	lbl.Font = font or Enum.Font.GothamBold
	lbl.TextColor3 = color or Color3.fromRGB(170,85,255)
	lbl.TextSize = 20
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function createButton(parent,text,posY,callback)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.BackgroundColor3 = Color3.fromRGB(60, 20, 100)
	btn.Position = UDim2.new(0,10,0,posY)
	btn.Size = UDim2.new(1,-20,0,35)
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = text
	btn.MouseButton1Click:Connect(callback)
	roundCorners(btn)
	return btn
end

local function createCheckbox(parent,text,posY,default,callback)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.Size = UDim2.new(1,-20,0,30)
	btn.Position = UDim2.new(0,10,0,posY)
	btn.BackgroundColor3 = Color3.fromRGB(40, 15, 80)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.TextColor3 = Color3.new(1,1,1)
	local checked = default
	local function updateText()
		btn.Text = (checked and "☑ " or "☐ ") .. text
	end
	updateText()
	btn.MouseButton1Click:Connect(function()
		checked = not checked
		updateText()
		if callback then callback(checked) end
	end)
	roundCorners(btn)
	return btn
end

local function createTextBox(parent,label,posY,placeholder,callback)
	local lbl = Instance.new("TextLabel")
	lbl.Parent = parent
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.new(0,10,0,posY)
	lbl.Size = UDim2.new(1,-20,0,20)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 18
	lbl.TextColor3 = Color3.fromRGB(200,200,200)
	lbl.Text = label
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local txt = Instance.new("TextBox")
	txt.Parent = parent
	txt.Position = UDim2.new(0,10,0,posY+20)
	txt.Size = UDim2.new(1,-20,0,30)
	txt.BackgroundColor3 = Color3.fromRGB(30,10,70)
	txt.TextColor3 = Color3.fromRGB(220,220,220)
	txt.Font = Enum.Font.Gotham
	txt.TextSize = 18
	txt.ClearTextOnFocus = false
	txt.PlaceholderText = placeholder or ""
	txt.Text = placeholder or ""
	txt.FocusLost:Connect(function(enter)
		if enter and callback then
			callback(txt.Text)
		end
	end)
	roundCorners(txt)
	return txt
end

-- Création UI principale
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MatrixLabGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = UIVisible

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 460)
MainFrame.Position = UDim2.new(0.5,0,0.5,0)
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 50)
MainFrame.BorderSizePixel = 0
roundCorners(MainFrame)
MainFrame.Active = true
MainFrame.Draggable = true

-- Titre
local Title = createText(MainFrame,"MatrixLab",10,UDim2.new(1,0,0,40),Enum.Font.GothamBold,ESPColor)
Title.TextSize = 36
Title.TextXAlignment = Enum.TextXAlignment.Center

-- Barre onglets
local TabsFrame = Instance.new("Frame", MainFrame)
TabsFrame.Size = UDim2.new(1,0,0,45)
TabsFrame.Position = UDim2.new(0,0,0,60)
TabsFrame.BackgroundTransparency = 1

local TabButtons = {}
local ContentFrames = {}

local function createTab(name, posX)
	local btn = Instance.new("TextButton", TabsFrame)
	btn.Size = UDim2.new(0, 95, 1, 0)
	btn.Position = UDim2.new(0, posX, 0, 0)
	btn.Text = name
	btn.BackgroundColor3 = Color3.fromRGB(60, 10, 120)
	btn.TextColor3 = Color3.fromRGB(220, 220, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.AutoButtonColor = false
	btn.Name = name .. "Tab"

	local frame = Instance.new("Frame", MainFrame)
	frame.Size = UDim2.new(1, -30, 1, -120)
	frame.Position = UDim2.new(0, 15, 0, 110)
	frame.BackgroundColor3 = Color3.fromRGB(30, 10, 80)
	frame.Visible = false
	roundCorners(frame)

	local scroll = Instance.new("ScrollingFrame", frame)
	scroll.Size = UDim2.new(1, -20, 1, -20)
	scroll.Position = UDim2.new(0, 10, 0, 10)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 8
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	btn.MouseButton1Click:Connect(function()
		currentTab = name
		for n, data in pairs(ContentFrames) do
			data.frame.Visible = (n == name)
			TabButtons[n].BackgroundColor3 = (n == name) and ESPColor or Color3.fromRGB(60,10,120)
		end
	end)

	TabButtons[name] = btn
	ContentFrames[name] = {frame = frame, scroll = scroll}
	return scroll
end

local espScroll = createTab("ESP", 0)
local trollScroll = createTab("TROLL", 100)
local playersScroll = createTab("PLAYERS", 200)
local spectateScroll = createTab("SPECTATE", 300)
local settingsScroll = createTab("SETTINGS", 400)

-- Ouvre onglet par défaut
TabButtons[currentTab].BackgroundColor3 = ESPColor
ContentFrames[currentTab].frame.Visible = true

-- UI helpers (Checkbox, Button, Textbox)
-- (réutilisation des fonctions créées ci-dessus)

-- ESP Tab
local yEsp = 0
local espEnableCB = createCheckbox(espScroll, "Activer ESP", yEsp, false, function(val) ESPEnabled = val end)
yEsp = yEsp + 40
local boxCB = createCheckbox(espScroll, "Afficher Box", yEsp, true, function(val) ShowBox = val end)
yEsp = yEsp + 40
local snaplineCB = createCheckbox(espScroll, "Afficher Snapline", yEsp, true, function(val) ShowSnapline = val end)
yEsp = yEsp + 40
local nameCB = createCheckbox(espScroll, "Afficher Nom", yEsp, true, function(val) ShowName = val end)
yEsp = yEsp + 40
local distCB = createCheckbox(espScroll, "Afficher Distance", yEsp, true, function(val) ShowDistance = val end)
yEsp = yEsp + 40
local skeletonCB = createCheckbox(espScroll, "Afficher Skeleton ESP", yEsp, false, function(val) ShowSkeleton = val end)
yEsp = yEsp + 50

local espColorHex = "#AA55FF"
local function hexToColor3(hex)
	hex = hex:gsub("#", "")
	if #hex ~= 6 then return Color3.fromRGB(170, 85, 255) end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if r and g and b then return Color3.fromRGB(r, g, b) end
	return Color3.fromRGB(170, 85, 255)
end

local function updateESPColor(hex)
	local c = hexToColor3(hex)
	ESPColor = c
	Title.TextColor3 = c
	-- Met à jour les couleurs ESP aussi
	for _, esp in pairs(espObjects) do
		if esp.box then esp.box.Color = c end
		if esp.nameText then esp.nameText.Color = c end
		if esp.distText then esp.distText.Color = c end
		if esp.snapline then esp.snapline.Color = c end
		for _, line in pairs(esp.skeletonLines or {}) do
			line.Color = c
		end
	end
end

local colorInput = createTextBox(espScroll, "Couleur ESP (hex):", yEsp, espColorHex, function(val)
	if val:match("^#%x%x%x%x%x%x$") then
		espColorHex = val
		updateESPColor(val)
	else
		warn("Hex invalide, format attendu : #RRGGBB")
	end
end)
yEsp = yEsp + 60
espScroll.CanvasSize = UDim2.new(0,0,0,yEsp)

-- TROLL Tab
local yTroll = 0
local trollNames = {"Spinbot", "Fly", "Speed", "NoClip", "Invisible"}
for i, name in ipairs(trollNames) do
	createCheckbox(trollScroll, name, yTroll, false, function(val)
		TrollStates[name] = val
	end)
	yTroll = yTroll + 40
end
trollScroll.CanvasSize = UDim2.new(0,0,0,yTroll)

-- PLAYERS Tab
local yPlayers = 0
local fovValue = ESPFOV
local distValue = ESPMaxDistance

createTextBox(playersScroll, "FOV ESP (degrés):", yPlayers, tostring(fovValue), function(val)
	local n = tonumber(val)
	if n and n >= 10 and n <= 360 then ESPFOV = n else warn("FOV invalide") end
end)
yPlayers = yPlayers + 60

createTextBox(playersScroll, "Distance Max ESP:", yPlayers, tostring(distValue), function(val)
	local n = tonumber(val)
	if n and n >= 100 and n <= 5000 then ESPMaxDistance = n else warn("Distance invalide") end
end)
yPlayers = yPlayers + 60

local freeCamToggle = createCheckbox(playersScroll, "FreeCam",  yPlayers, false, function(val)
	FreeCamEnabled = val
	if val then
		if not FreeCamCamera then
			FreeCamCamera = Camera
		end
		Camera.CameraType = Enum.CameraType.Scriptable
	else
		Camera.CameraType = Enum.CameraType.Custom
	end
end)
yPlayers = yPlayers + 40

local freeCamSpeedBox = createTextBox(playersScroll, "FreeCam Speed:", yPlayers, tostring(FreeCamSpeed), function(val)
	local n = tonumber(val)
	if n and n > 0 and n <= 500 then FreeCamSpeed = n else warn("Speed invalide") end
end)
yPlayers = yPlayers + 60
playersScroll.CanvasSize = UDim2.new(0,0,0,yPlayers)

-- SPECTATE Tab
local spectateFrame = spectateScroll

local spectateList = Instance.new("UIListLayout", spectateFrame)
spectateList.Padding = UDim.new(0,5)
spectateList.SortOrder = Enum.SortOrder.LayoutOrder

local function refreshSpectateList()
	-- Nettoyer ancien contenu
	for _, child in pairs(spectateFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local btn = Instance.new("TextButton", spectateFrame)
			btn.Text = plr.Name
			btn.Size = UDim2.new(1,-20,0,35)
			btn.BackgroundColor3 = Color3.fromRGB(60,10,120)
			btn.Font = Enum.Font.GothamBold
			btn.TextColor3 = Color3.new(1,1,1)
			btn.AutoButtonColor = false
			roundCorners(btn)
			btn.MouseButton1Click:Connect(function()
				IsSpectating = true
				SpectateTarget = plr
				FreeCamEnabled = false
				Camera.CameraType = Enum.CameraType.Custom
			end)
		end
	end
end

refreshSpectateList()

-- SETTINGS Tab
local ySettings = 0
createCheckbox(settingsScroll, "Afficher Watermark (FPS/Ping/Tick)", ySettings, true, function(val) ShowWatermark = val end)
ySettings = ySettings + 40
settingsScroll.CanvasSize = UDim2.new(0,0,0,ySettings)

-- ESP Drawing

local espObjects = {}

-- Fonction pour créer l'ESP sur un joueur
local function createESP(plr)
	local esp = {}

	local box = Drawing.new("Square")
	box.Color = ESPColor
	box.Thickness = 2
	box.Filled = false
	box.Transparency = 1
	esp.box = box

	local snapline = Drawing.new("Line")
	snapline.Color = ESPColor
	snapline.Thickness = 1
	esp.snapline = snapline

	local nameText = Drawing.new("Text")
	nameText.Color = ESPColor
	nameText.Size = 16
	nameText.Center = true
	nameText.Outline = true
	nameText.Font = 2
	esp.nameText = nameText

	local distText = Drawing.new("Text")
	distText.Color = ESPColor
	distText.Size = 14
	distText.Center = true
	distText.Outline = true
	distText.Font = 2
	esp.distText = distText

	esp.skeletonLines = {}

	return esp
end

-- Fonction pour mettre à jour l'ESP d'un joueur
local function updateESP(plr, esp)
	if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
		-- Cache tout
		if esp.box then esp.box.Visible = false end
		if esp.snapline then esp.snapline.Visible = false end
		if esp.nameText then esp.nameText.Visible = false end
		if esp.distText then esp.distText.Visible = false end
		for _, line in pairs(esp.skeletonLines) do
			line.Visible = false
		end
		return
	end

	local hrp = plr.Character.HumanoidRootPart
	local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		for _, line in pairs(esp.skeletonLines) do
			line.Visible = false
		end
		if esp.box then esp.box.Visible = false end
		if esp.snapline then esp.snapline.Visible = false end
		if esp.nameText then esp.nameText.Visible = false end
		if esp.distText then esp.distText.Visible = false end
		return
	end

	local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
	if onScreen and pos.Z > 0 and (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
		local localPos = LocalPlayer.Character.HumanoidRootPart.Position
		local dist = (hrp.Position - localPos).Magnitude
		if dist <= ESPMaxDistance then
			-- FOV check
			local camCF = Camera.CFrame
			local lookVec = camCF.LookVector
			local dirToPlayer = (hrp.Position - camCF.Position).Unit
			local dot = lookVec:Dot(dirToPlayer)
			local fovAngle = math.deg(math.acos(dot))
			if fovAngle <= ESPFOV then
				-- Box
				if ShowBox and esp.box then
					local size = 10000 / dist
					esp.box.Size = Vector2.new(size, size*2)
					esp.box.Position = Vector2.new(pos.X - esp.box.Size.X/2, pos.Y - esp.box.Size.Y/2)
					esp.box.Color = ESPColor
					esp.box.Visible = true
				else
					esp.box.Visible = false
				end

				-- Snapline
				if ShowSnapline and esp.snapline then
					esp.snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
					esp.snapline.To = Vector2.new(pos.X, pos.Y)
					esp.snapline.Color = ESPColor
					esp.snapline.Visible = true
				else
					esp.snapline.Visible = false
				end

				-- Name
				if ShowName and esp.nameText then
					esp.nameText.Position = Vector2.new(pos.X, pos.Y - esp.box.Size.Y/2 - 15)
					esp.nameText.Text = plr.Name
					esp.nameText.Color = ESPColor
					esp.nameText.Visible = true
				else
					esp.nameText.Visible = false
				end

				-- Distance
				if ShowDistance and esp.distText then
					esp.distText.Position = Vector2.new(pos.X, pos.Y + esp.box.Size.Y/2 + 5)
					esp.distText.Text = string.format("%.1f", dist) .. " studs"
					esp.distText.Color = ESPColor
					esp.distText.Visible = true
				else
					esp.distText.Visible = false
				end

				-- TODO: Skeleton ESP lines if enabled
				-- Clear old lines first
				for _, line in pairs(esp.skeletonLines) do
					line.Visible = false
				end
				if ShowSkeleton then
					-- Skeleton joints (Head, Torso, Arms, Legs)
					local char = plr.Character
					local joints = {
						Head = char:FindFirstChild("Head"),
						Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
						LeftArm = char:FindFirstChild("LeftUpperArm"),
						RightArm = char:FindFirstChild("RightUpperArm"),
						LeftLeg = char:FindFirstChild("LeftUpperLeg"),
						RightLeg = char:FindFirstChild("RightUpperLeg"),
					}
					if joints.Head and joints.Torso then
						local function project(part)
							local p, vis = Camera:WorldToViewportPoint(part.Position)
							return Vector2.new(p.X, p.Y), vis and p.Z > 0
						end

						local points = {}
						local validPoints = true
						for _, part in pairs(joints) do
							if part then
								local pos2d, vis = project(part)
								if not vis then validPoints = false end
								table.insert(points, pos2d)
							else
								validPoints = false
							end
						end

						if validPoints then
							-- Draw lines torso->head, torso->arms, torso->legs
							local linesNeeded = {
								{points[2], points[1]}, -- Torso -> Head
								{points[2], points[3]}, -- Torso -> LeftArm
								{points[2], points[4]}, -- Torso -> RightArm
								{points[2], points[5]}, -- Torso -> LeftLeg
								{points[2], points[6]}, -- Torso -> RightLeg
							}
							-- Reuse lines or create new ones
							for i, linePoints in pairs(linesNeeded) do
								local line = esp.skeletonLines[i]
								if not line then
									line = Drawing.new("Line")
									line.Color = ESPColor
									line.Thickness = 2
									esp.skeletonLines[i] = line
								end
								line.From = linePoints[1]
								line.To = linePoints[2]
								line.Visible = true
							end
						end
					end
				end
				return
			end
		end
	end
	-- Pas visible
	if esp.box then esp.box.Visible = false end
	if esp.snapline then esp.snapline.Visible = false end
	if esp.nameText then esp.nameText.Visible = false end
	if esp.distText then esp.distText.Visible = false end
	for _, line in pairs(esp.skeletonLines) do
		line.Visible = false
	end
end

-- Crée ESP pour tous joueurs au début
for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		espObjects[plr] = createESP(plr)
	end
end

Players.PlayerAdded:Connect(function(plr)
	if plr ~= LocalPlayer then
		espObjects[plr] = createESP(plr)
		refreshSpectateList()
	end
end)
Players.PlayerRemoving:Connect(function(plr)
	if espObjects[plr] then
		local esp = espObjects[plr]
		if esp.box then esp.box:Remove() end
		if esp.snapline then esp.snapline:Remove() end
		if esp.nameText then esp.nameText:Remove() end
		if esp.distText then esp.distText:Remove() end
		for _, line in pairs(esp.skeletonLines) do
			line:Remove()
		end
		espObjects[plr] = nil
	end
	refreshSpectateList()
end)

-- Fonction Troll Spinbot
local function runSpinbot()
	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180 * tick()), 0)
end

-- Fonction Troll Fly simple
local flySpeed = 50
local flyVelocity = nil
local flying = false

local function startFly()
	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.PlatformStand = true
	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyVelocity.Velocity = Vector3.new()
	flyVelocity.Parent = hrp
	flying = true
end
local function stopFly()
	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.PlatformStand = false
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	flying = false
end

-- FreeCam movement
local freeCamCFrame = Camera.CFrame
local function updateFreeCam(dt)
	if not FreeCamEnabled then return end
	local moveDir = Vector3.new(0,0,0)
	if FreeCamControls.Forward then moveDir = moveDir + FreeCamCamera.CFrame.LookVector end
	if FreeCamControls.Backward then moveDir = moveDir - FreeCamCamera.CFrame.LookVector end
	if FreeCamControls.Left then moveDir = moveDir - FreeCamCamera.CFrame.RightVector end
	if FreeCamControls.Right then moveDir = moveDir + FreeCamCamera.CFrame.RightVector end
	if FreeCamControls.Up then moveDir = moveDir + Vector3.new(0,1,0) end
	if FreeCamControls.Down then moveDir = moveDir - Vector3.new(0,1,0) end
	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
		freeCamCFrame = freeCamCFrame + moveDir * FreeCamSpeed * dt
		FreeCamCamera.CFrame = freeCamCFrame
	end
end

-- NoClip
local function updateNoClip()
	if TrollStates.NoClip and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide == true then
				part.CanCollide = false
			end
		end
	elseif LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide == false then
				part.CanCollide = true
			end
		end
	end
end

-- Invisible
local function updateInvisible()
	if TrollStates.Invisible and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			elseif part:IsA("Decal") then
				part.Transparency = 1
			end
		end
	else
		if LocalPlayer.Character then
			for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
				elseif part:IsA("Decal") then
					part.Transparency = 0
				end
			end
		end
	end
end

-- Speed toggle (simple)
local function updateSpeed()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if TrollStates.Speed then
		humanoid.WalkSpeed = 50
	else
		humanoid.WalkSpeed = 16
	end
end

-- Spectate update
local function updateSpectate()
	if IsSpectating and SpectateTarget and SpectateTarget.Character and SpectateTarget.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = SpectateTarget.Character.HumanoidRootPart
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = hrp.CFrame * CFrame.new(0,3,10)
	else
		IsSpectating = false
		SpectateTarget = nil
		Camera.CameraType = Enum.CameraType.Custom
	end
end

-- Watermark
local fpsCounter = Instance.new("TextLabel", ScreenGui)
fpsCounter.BackgroundTransparency = 1
fpsCounter.Position = UDim2.new(0, 5, 0, 5)
fpsCounter.Size = UDim2.new(0, 220, 0, 25)
fpsCounter.Font = Enum.Font.GothamBold
fpsCounter.TextSize = 18
fpsCounter.TextColor3 = ESPColor
fpsCounter.TextXAlignment = Enum.TextXAlignment.Left
fpsCounter.TextYAlignment = Enum.TextYAlignment.Top

local function updateWatermark()
	if not ShowWatermark then
		fpsCounter.Visible = false
		return
	end
	fpsCounter.Visible = true
	local currentTick = tick()
	local dt = currentTick - lastTick
	lastTick = currentTick
	lastFPS = math.floor(1/dt)
	lastPing = math.random(30, 70) -- Fake ping, tu peux remplacer par un vrai ping si tu veux
	fpsCounter.Text = string.format("MatrixLab | FPS: %d | Ping: %d ms | Tick: %.2f", lastFPS, lastPing, currentTick)
end

-- Animations danses rigolotes (emotes)
local Animations = {
	["Dance1"] = "rbxassetid://178130996", -- exemple danse
	["Dance2"] = "rbxassetid://3068293580", -- autre danse
	["Dance3"] = "rbxassetid://494888251", -- encore une danse
}
local currentAnimTrack = nil
local function playDance(name)
	if not LocalPlayer.Character then return end
	local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if currentAnimTrack then
		currentAnimTrack:Stop()
		currentAnimTrack = nil
	end
	local animId = Animations[name]
	if animId then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		local track = humanoid:LoadAnimation(anim)
		currentAnimTrack = track
		track:Play()
	end
end

-- Ajout dans tab Troll boutons danses
local yDance = yTroll + 20
for danceName, _ in pairs(Animations) do
	createButton(trollScroll, "Jouer " .. danceName, yDance, function()
		playDance(danceName)
	end)
	yDance = yDance + 40
end
trollScroll.CanvasSize = UDim2.new(0,0,0,yDance)

-- Input FreeCam
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if FreeCamEnabled then
		if input.KeyCode == Enum.KeyCode.W then FreeCamControls.Forward = true end
		if input.KeyCode == Enum.KeyCode.S then FreeCamControls.Backward = true end
		if input.KeyCode == Enum.KeyCode.A then FreeCamControls.Left = true end
		if input.KeyCode == Enum.KeyCode.D then FreeCamControls.Right = true end
		if input.KeyCode == Enum.KeyCode.Space then FreeCamControls.Up = true end
		if input.KeyCode == Enum.KeyCode.LeftControl then FreeCamControls.Down = true end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if FreeCamEnabled then
		if input.KeyCode == Enum.KeyCode.W then FreeCamControls.Forward = false end
		if input.KeyCode == Enum.KeyCode.S then FreeCamControls.Backward = false end
		if input.KeyCode == Enum.KeyCode.A then FreeCamControls.Left = false end
		if input.KeyCode == Enum.KeyCode.D then FreeCamControls.Right = false end
		if input.KeyCode == Enum.KeyCode.Space then FreeCamControls.Up = false end
		if input.KeyCode == Enum.KeyCode.LeftControl then FreeCamControls.Down = false end
	end
end)

-- Loop principal
RunService.RenderStepped:Connect(function(dt)
	updateWatermark()
	if ESPEnabled then
		for plr, esp in pairs(espObjects) do
			updateESP(plr, esp)
		end
	else
		-- Cache tout si pas activé
		for _, esp in pairs(espObjects) do
			if esp.box then esp.box.Visible = false end
			if esp.snapline then esp.snapline.Visible = false end
			if esp.nameText then esp.nameText.Visible = false end
			if esp.distText then esp.distText.Visible = false end
			for _, line in pairs(esp.skeletonLines) do
				line.Visible = false
			end
		end
	end

	-- Trolls
	if TrollStates.Spinbot then runSpinbot() end
	if TrollStates.Fly and not flying then startFly() elseif not TrollStates.Fly and flying then stopFly() end
	updateNoClip()
	updateInvisible()
	updateSpeed()
	updateSpectate()
	updateFreeCam(dt)
end)

-- Toggle UI avec Insert
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Insert then
		UIVisible = not UIVisible
		ScreenGui.Enabled = UIVisible
	end
end)

print("[MatrixLab] Script chargé ! Appuie sur Insert pour ouvrir/fermer le menu.")
