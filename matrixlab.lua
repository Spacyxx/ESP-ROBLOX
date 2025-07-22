-- Charge la UI Library (Rayfield)
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configuration
local config = {
    box = true,
    boxFilled = false,
    snapLine = true,
    skeleton = true,
    name = true,
    showDistance = true,
    useTeamColor = true,
    maxDistance = 500,
    colors = {
        box = Color3.fromRGB(255, 0, 0),
        boxFilled = Color3.fromRGB(255, 0, 0),
        snapLine = Color3.fromRGB(0, 255, 0),
        skeleton = Color3.fromRGB(0, 170, 255),
        text = Color3.fromRGB(255, 255, 255)
    }
}

-- Stockage dessins
local drawings = {}

local function clearDrawings()
    for _, d in pairs(drawings) do
        for _, v in pairs(d) do
            if typeof(v) == "table" then
                for _, part in pairs(v) do
                    if part.Remove then part:Remove() end
                end
            elseif v.Remove then
                v:Remove()
            end
        end
    end
    drawings = {}
end

local function drawESP()
    clearDrawings()

    RunService:BindToRenderStep("ESP", Enum.RenderPriority.Camera.Value + 1, function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not hrp or not head or not humanoid then continue end

                local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
                if distance > config.maxDistance or humanoid.Health <= 0 then continue end

                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local sizeY = (Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y)
                local size = Vector2.new(sizeY / 2, sizeY)

                if not onScreen then continue end

                drawings[player] = drawings[player] or {}

                local teamColor = config.useTeamColor and player.TeamColor.Color or nil
                local colorBox = teamColor or config.colors.box
                local colorLine = teamColor or config.colors.snapLine
                local colorSkel = teamColor or config.colors.skeleton
                local colorText = config.colors.text

                -- Box
                if config.box then
                    drawings[player].box = drawings[player].box or Drawing.new("Square")
                    local box = drawings[player].box
                    box.Size = size
                    box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                    box.Visible = true
                    box.Color = colorBox
                    box.Thickness = 1
                elseif drawings[player].box then
                    drawings[player].box.Visible = false
                end

                -- Filled box
                if config.boxFilled then
                    drawings[player].fill = drawings[player].fill or Drawing.new("Square")
                    local fill = drawings[player].fill
                    fill.Size = size
                    fill.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                    fill.Visible = true
                    fill.Color = colorBox
                    fill.Transparency = 0.2
                    fill.Filled = true
                elseif drawings[player].fill then
                    drawings[player].fill.Visible = false
                end

                -- Snapline
                if config.snapLine then
                    drawings[player].line = drawings[player].line or Drawing.new("Line")
                    local line = drawings[player].line
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Visible = true
                    line.Color = colorLine
                    line.Thickness = 1
                elseif drawings[player].line then
                    drawings[player].line.Visible = false
                end

                -- Name + Distance
                if config.name or config.showDistance then
                    drawings[player].text = drawings[player].text or Drawing.new("Text")
                    local text = drawings[player].text
                    text.Text = (config.name and player.Name or "") .. (config.showDistance and (" [" .. math.floor(distance) .. "m]") or "")
                    text.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 15)
                    text.Visible = true
                    text.Size = 13
                    text.Color = colorText
                    text.Center = true
                    text.Outline = true
                elseif drawings[player].text then
                    drawings[player].text.Visible = false
                end

                -- Skeleton
                if config.skeleton then
                    local function drawBone(p1, p2)
                        local p1v, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        local p2v, vis2 = Camera:WorldToViewportPoint(p2.Position)
                        if vis1 and vis2 then
                            local line = Drawing.new("Line")
                            line.From = Vector2.new(p1v.X, p1v.Y)
                            line.To = Vector2.new(p2v.X, p2v.Y)
                            line.Color = colorSkel
                            line.Thickness = 1
                            line.Transparency = 1
                            line.Visible = true
                            table.insert(drawings[player], line)
                        end
                    end
                    local parts = {
                        {"Head", "UpperTorso"},
                        {"UpperTorso", "LowerTorso"},
                        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                    }
                    for _, pair in ipairs(parts) do
                        local p1 = char:FindFirstChild(pair[1])
                        local p2 = char:FindFirstChild(pair[2])
                        if p1 and p2 then drawBone(p1, p2) end
                    end
                end
            end
        end
    end)
end

-- Interface via Rayfield
Rayfield:CreateWindow({
    Name = "MatrixLab ESP",
    LoadingTitle = "MatrixLab ESP",
    LoadingSubtitle = "by spacyxx",
    ConfigurationSaving = {
        Enabled = false,
    }
})

local mainTab = Rayfield:CreateTab("ESP Settings", 4483362458)

Rayfield:CreateSection("Toggle Elements", mainTab)

for _, v in pairs({"box", "boxFilled", "snapLine", "skeleton", "name", "showDistance", "useTeamColor"}) do
    Rayfield:CreateToggle({
        Name = "Show " .. v,
        CurrentValue = config[v],
        Callback = function(state)
            config[v] = state
        end
    })
end

Rayfield:CreateSlider({
    Name = "Max Distance",
    Range = {50, 2000},
    Increment = 50,
    Suffix = "m",
    CurrentValue = config.maxDistance,
    Callback = function(value)
        config.maxDistance = value
    end
})

Rayfield:CreateSection("Color Settings", mainTab)

for name, default in pairs(config.colors) do
    Rayfield:CreateColorPicker({
        Name = "Color: " .. name,
        Color = default,
        Callback = function(color)
            config.colors[name] = color
        end
    })
end

drawESP()
