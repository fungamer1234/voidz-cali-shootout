-- VOIDZ Player Snipe — join anyone by username
-- MacSploit: loadstring(game:HttpGet(url))()  -- one argument only

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
while not LP do
	task.wait()
	LP = Players.LocalPlayer
end

local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui")
pcall(function()
	local old = pg:FindFirstChild("VOIDZ_SNIPE")
	if old then old:Destroy() end
end)

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "VOIDZ SNIPE",
			Text = tostring(text or ""),
			Duration = 2.4,
		})
	end)
	print("[VOIDZ SNIPE] " .. tostring(text))
end

local function httpReq(url, method, body)
	local req = request or http_request or (syn and syn.request) or (http and http.request)
	if type(req) ~= "function" then
		return nil, "no request()"
	end
	local ok, res = pcall(req, {
		Url = url,
		Method = method or "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Accept"] = "application/json",
		},
		Body = body,
	})
	if not ok or type(res) ~= "table" then
		return nil, tostring(res)
	end
	return res.Body or res.body, res.StatusCode or res.statusCode
end

local function joinUser(name, status)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		status.Text = "Type a username"
		notify("Type a username")
		return
	end
	task.spawn(function()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and (string.lower(p.Name) == string.lower(name) or string.lower(p.DisplayName) == string.lower(name)) then
				status.Text = "Already in this server"
				notify("Already here: " .. p.Name)
				local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if r and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
					pcall(function()
						LP.Character:PivotTo(r.CFrame * CFrame.new(0, 0, 3))
					end)
				end
				return
			end
		end

		status.Text = "Looking up " .. name .. "..."
		local uid
		local okId = pcall(function()
			uid = Players:GetUserIdFromNameAsync(name)
		end)
		if not okId or not uid then
			status.Text = "User not found"
			notify("No Roblox user named " .. name)
			return
		end

		status.Text = "Finding server..."
		local payload = HttpService:JSONEncode({ userIds = { uid } })
		local raw = httpReq("https://presence.roblox.com/v1/presence/users", "POST", payload)
		if type(raw) ~= "string" or raw == "" then
			raw = httpReq("https://presence.roproxy.com/v1/presence/users", "POST", payload)
		end
		if type(raw) ~= "string" or raw == "" then
			status.Text = "HTTP failed — executor needs request()"
			notify("Need request() for presence")
			return
		end

		local okJ, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		local pres = okJ and data and data.userPresences and data.userPresences[1]
		if not pres then
			status.Text = "Couldn't read presence"
			notify("Presence parse failed")
			return
		end

		local ptype = tonumber(pres.userPresenceType) or 0
		local placeId = tonumber(pres.placeId or pres.rootPlaceId)
		local rootPlaceId = tonumber(pres.rootPlaceId or pres.placeId)
		local jobId = pres.gameId or pres.GameId or pres.gameInstanceId or pres.instanceId
		if type(jobId) == "string" and (jobId == "" or jobId == "null") then
			jobId = nil
		end

		-- Official JobId (works when Roblox lets you follow them)
		pcall(function()
			local _ok, _err, p2, j2 = TeleportService:GetPlayerPlaceInstanceAsync(uid)
			if p2 then
				placeId = tonumber(p2) or placeId
			end
			if type(j2) == "string" and j2 ~= "" and j2 ~= "null" then
				jobId = j2
			end
		end)

		if ptype ~= 2 or not placeId then
			status.Text = name .. " is not in a game"
			notify(name .. " is not in a game")
			return
		end
		if not jobId then
			status.Text = "Server hidden (join privacy)"
			notify("They hid their server")
			return
		end
		jobId = tostring(jobId)
		if tostring(game.JobId) == jobId then
			status.Text = "Already in that server"
			notify("Already in that server")
			return
		end

		local function tryTP(pid, jid)
			pid = tonumber(pid)
			jid = tostring(jid)
			if not pid or jid == "" then
				return false, "bad ids"
			end
			-- Client must not pass Player as 3rd arg (that 773-restricts)
			local ok1, e1 = pcall(function()
				local opt = Instance.new("TeleportOptions")
				opt.ServerInstanceId = jid
				TeleportService:TeleportAsync(pid, { LP }, opt)
			end)
			if ok1 then
				return true
			end
			local ok2, e2 = pcall(function()
				TeleportService:TeleportToPlaceInstance(pid, jid)
			end)
			if ok2 then
				return true
			end
			return false, tostring(e1 or e2)
		end

		status.Text = "Joining " .. name .. "..."
		notify("Joining " .. name .. "'s server")

		-- Warm the join ticket the website uses
		pcall(function()
			httpReq("https://gamejoin.roblox.com/v1/join-game-instance", "POST", HttpService:JSONEncode({
				placeId = placeId,
				gameId = jobId,
				isTeleport = true,
			}))
		end)

		local okTp, tpErr = tryTP(placeId, jobId)
		if not okTp and rootPlaceId and rootPlaceId ~= placeId then
			okTp, tpErr = tryTP(rootPlaceId, jobId)
		end
		if not okTp then
			local link = "roblox://experiences/start?placeId=" .. tostring(placeId) .. "&gameInstanceId=" .. jobId
			pcall(function()
				if setclipboard then
					setclipboard(link)
				end
			end)
			status.Text = "Restricted — copied join link"
			notify("Teleport blocked. Join link copied if clipboard works.")
			print("[VOIDZ SNIPE] " .. tostring(tpErr))
			print("[VOIDZ SNIPE] " .. link)
		end
	end)
end

local sg = Instance.new("ScreenGui")
sg.Name = "VOIDZ_SNIPE"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999999
sg.Parent = pg
pcall(function()
	sg.ClipToDeviceSafeArea = false
end)

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(320, 168)
card.Position = UDim2.new(0.5, -160, 0.18, 0)
card.BackgroundColor3 = Color3.fromRGB(18, 12, 32)
card.BorderSizePixel = 0
card.Active = true
card.Parent = sg
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = card
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(168, 108, 255)
	s.Thickness = 1.4
	s.Parent = card
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 0, 28)
title.Position = UDim2.fromOffset(12, 8)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "VOIDZ SNIPE"
title.Parent = card

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(22, 22)
close.Position = UDim2.new(1, -30, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(50, 20, 40)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 180, 190)
close.Font = Enum.Font.SourceSansBold
close.TextSize = 14
close.Parent = card
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = close
end
close.MouseButton1Click:Connect(function()
	sg:Destroy()
end)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -24, 0, 34)
box.Position = UDim2.fromOffset(12, 44)
box.BackgroundColor3 = Color3.fromRGB(36, 26, 62)
box.Text = ""
box.PlaceholderText = "Roblox username"
box.PlaceholderColor3 = Color3.fromRGB(170, 160, 190)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.SourceSans
box.TextSize = 16
box.ClearTextOnFocus = false
box.Parent = card
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = box
end

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -24, 0, 18)
status.Position = UDim2.fromOffset(12, 84)
status.Font = Enum.Font.SourceSans
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(210, 196, 255)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Enter a username, then Join"
status.Parent = card

local go = Instance.new("TextButton")
go.Size = UDim2.new(1, -24, 0, 36)
go.Position = UDim2.fromOffset(12, 112)
go.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
go.Text = "Join / Snipe"
go.TextColor3 = Color3.fromRGB(255, 255, 255)
go.Font = Enum.Font.SourceSansBold
go.TextSize = 16
go.AutoButtonColor = false
go.Parent = card
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = go
end

go.MouseButton1Click:Connect(function()
	joinUser(box.Text, status)
end)
box.FocusLost:Connect(function(enter)
	if enter then
		joinUser(box.Text, status)
	end
end)

local dragging, startIn, startPos
card.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		startIn = input.Position
		startPos = card.Position
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - startIn
		card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		sg.Enabled = not sg.Enabled
	end
end)

notify("Type a username and hit Join")
print("[VOIDZ SNIPE] ready")
