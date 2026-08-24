-- VOIDZ Player Snipe — join by username or JobId (standalone)
-- MacSploit: loadstring(game:HttpGet(url))()  -- one argument only

local Players = game:GetService("Players")
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
			Duration = 2.5,
		})
	end)
	print("[VOIDZ SNIPE] " .. tostring(text))
end

local function httpReq(url, method, body)
	local req = request or http_request or (syn and syn.request) or (http and http.request)
	if type(req) == "function" then
		local opts = {
			Url = url,
			Method = method or "GET",
			Headers = {
				["Content-Type"] = "application/json",
				["Accept"] = "application/json",
			},
		}
		if body then
			opts.Body = body
		end
		local ok, res = pcall(req, opts)
		if ok and type(res) == "table" then
			return res.Body or res.body
		end
	end
	if (method or "GET") == "GET" then
		local ok, body2 = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body2) == "string" then
			return body2
		end
	end
	return nil
end

local function gameNameFromIds(universeId, placeId)
	universeId = tonumber(universeId)
	placeId = tonumber(placeId)
	if universeId then
		local raw = httpReq("https://games.roblox.com/v1/games?universeIds=" .. tostring(universeId), "GET")
			or httpReq("https://games.roproxy.com/v1/games?universeIds=" .. tostring(universeId), "GET")
		if type(raw) == "string" then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if ok and data and data.data and data.data[1] and data.data[1].name then
				return tostring(data.data[1].name)
			end
		end
	end
	if placeId then
		local raw = httpReq("https://games.roblox.com/v1/games/multiget-place-details?placeIds=" .. tostring(placeId), "GET")
			or httpReq("https://games.roproxy.com/v1/games/multiget-place-details?placeIds=" .. tostring(placeId), "GET")
		if type(raw) == "string" then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if ok and type(data) == "table" then
				local row = data[1] or (data.data and data.data[1])
				if row and (row.name or row.Name) then
					return tostring(row.name or row.Name)
				end
			end
		end
	end
	return nil
end

local function looksLikeJobId(s)
	s = tostring(s or "")
	if #s < 32 then
		return false
	end
	return string.find(s, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") ~= nil
end

local function copyText(s)
	s = tostring(s or "")
	pcall(function()
		if setclipboard then
			setclipboard(s)
		end
	end)
end

local lastFail = ""
pcall(function()
	TeleportService.TeleportInitFailed:Connect(function(_, result, errMsg)
		lastFail = tostring(result) .. " " .. tostring(errMsg)
		notify("Teleport failed: " .. lastFail)
	end)
end)

local function nativeLaunch(placeId, jobId)
	placeId = tostring(placeId)
	jobId = tostring(jobId)
	local proto = "roblox://experiences/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId
	local web = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId
	copyText(web)
	-- Mac: open the Roblox app to that instance (bypasses TeleportService 773)
	pcall(function()
		os.execute('open "' .. proto .. '"')
	end)
	pcall(function()
		os.execute("open '" .. proto .. "'")
	end)
	pcall(function()
		if syn and syn.open_url then
			syn.open_url(proto)
		end
	end)
	pcall(function()
		if fluxus and fluxus.open_url then
			fluxus.open_url(proto)
		end
	end)
	pcall(function()
		game:GetService("GuiService"):OpenBrowserWindow(web)
	end)
	return web
end

local function joinJob(placeId, jobId, status, universeId)
	placeId = tonumber(placeId)
	jobId = tostring(jobId or ""):gsub("%s+", "")
	if not placeId then
		status.Text = "Need a PlaceId"
		return
	end
	if not looksLikeJobId(jobId) then
		status.Text = "JobId must be a server GUID"
		notify("Bad JobId")
		return
	end
	if tostring(game.JobId) == jobId then
		status.Text = "Already in that JobId"
		return
	end

	status.Text = "Joining JobId..."
	notify("Joining " .. jobId)

	pcall(function()
		httpReq("https://gamejoin.roblox.com/v1/join-game-instance", "POST", HttpService:JSONEncode({
			placeId = placeId,
			gameId = jobId,
			isTeleport = true,
			gameJoinAttemptId = HttpService:GenerateGUID(false),
		}))
	end)

	local sameGame = tonumber(universeId) and tonumber(universeId) == tonumber(game.GameId)
	if not universeId then
		sameGame = tonumber(placeId) == tonumber(game.PlaceId)
	end

	-- Same experience: in-game teleport is allowed.
	-- Other games: TeleportService is 773 (third-party / restricted). Use roblox:// instead.
	if sameGame then
		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(placeId, jobId)
		end)
		if ok then
			return
		end
	end

	local web = nativeLaunch(placeId, jobId)
	status.Text = "Opened Roblox join (773 bypass). Link copied."
	print("[VOIDZ SNIPE] " .. web)
end

local function snipeName(name, status, jobBox, placeBox, gameLbl)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		status.Text = "Type a username"
		return
	end
	task.spawn(function()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and (string.lower(p.Name) == string.lower(name) or string.lower(p.DisplayName) == string.lower(name)) then
				status.Text = "Already in this server — TPing"
				local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if r and LP.Character then
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
			return
		end

		status.Text = "Fetching JobId..."
		local payload = HttpService:JSONEncode({ userIds = { uid } })
		local raw = httpReq("https://presence.roblox.com/v1/presence/users", "POST", payload)
		if type(raw) ~= "string" or raw == "" then
			raw = httpReq("https://presence.roproxy.com/v1/presence/users", "POST", payload)
		end
		if type(raw) ~= "string" then
			status.Text = "Need request() for presence"
			return
		end

		local okJ, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		local pres = okJ and data and data.userPresences and data.userPresences[1]
		if not pres then
			status.Text = "Couldn't read presence"
			print(raw)
			return
		end

		local ptype = tonumber(pres.userPresenceType) or 0
		local placeId = tonumber(pres.placeId or pres.rootPlaceId)
		local jobId = pres.gameId or pres.gameInstanceId
		if not looksLikeJobId(jobId) then
			jobId = nil
		end

		if ptype == 0 then
			status.Text = name .. " is offline"
			if gameLbl then gameLbl.Text = "Game: offline" end
			return
		end
		if ptype == 1 then
			status.Text = name .. " is on the website, not in a game"
			if gameLbl then gameLbl.Text = "Game: Roblox website" end
			return
		end
		if ptype == 3 then
			status.Text = name .. " is in Studio"
			if gameLbl then gameLbl.Text = "Game: Roblox Studio" end
			return
		end
		if ptype ~= 2 or not placeId then
			status.Text = name .. " is not in a game"
			if gameLbl then gameLbl.Text = "Game: unknown" end
			return
		end

		local gname = pres.lastLocation
		if type(gname) ~= "string" or gname == "" then
			gname = gameNameFromIds(pres.universeId, placeId)
		end
		gname = gname or ("Place " .. tostring(placeId))
		if gameLbl then
			gameLbl.Text = "Game: " .. gname
		end
		notify(name .. " is in " .. gname)

		if not jobId then
			status.Text = "In " .. gname .. " — no JobId (privacy)"
			placeBox.Text = tostring(placeId)
			return
		end

		jobBox.Text = tostring(jobId)
		placeBox.Text = tostring(placeId)
		copyText(tostring(jobId))
		status.Text = "In " .. gname .. " — JobId copied, joining..."
		joinJob(placeId, jobId, status, pres.universeId)
	end)
end

local sg = Instance.new("ScreenGui")
sg.Name = "VOIDZ_SNIPE"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999999
sg.Parent = pg

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(340, 314)
card.Position = UDim2.new(0.5, -170, 0.14, 0)
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

local function lab(text, y)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -24, 0, 16)
	l.Position = UDim2.fromOffset(12, y)
	l.Font = Enum.Font.SourceSansBold
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(210, 196, 255)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = card
	return l
end

local function boxAt(y, placeholder, defaultText)
	local b = Instance.new("TextBox")
	b.Size = UDim2.new(1, -24, 0, 28)
	b.Position = UDim2.fromOffset(12, y)
	b.BackgroundColor3 = Color3.fromRGB(36, 26, 62)
	b.Text = defaultText or ""
	b.PlaceholderText = placeholder
	b.PlaceholderColor3 = Color3.fromRGB(170, 160, 190)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.SourceSans
	b.TextSize = 14
	b.ClearTextOnFocus = false
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = card
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	return b
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 0, 24)
title.Position = UDim2.fromOffset(12, 6)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "VOIDZ SNIPE"
title.Parent = card

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(22, 22)
close.Position = UDim2.new(1, -30, 0, 6)
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

lab("Username", 32)
local nameBox = boxAt(48, "Roblox username", "")

local goName = Instance.new("TextButton")
goName.Size = UDim2.new(1, -24, 0, 30)
goName.Position = UDim2.fromOffset(12, 80)
goName.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
goName.Text = "Snipe username"
goName.TextColor3 = Color3.fromRGB(255, 255, 255)
goName.Font = Enum.Font.SourceSansBold
goName.TextSize = 15
goName.Parent = card
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = goName
end

local gameLbl = Instance.new("TextLabel")
gameLbl.BackgroundTransparency = 1
gameLbl.Size = UDim2.new(1, -24, 0, 18)
gameLbl.Position = UDim2.fromOffset(12, 114)
gameLbl.Font = Enum.Font.SourceSansBold
gameLbl.TextSize = 14
gameLbl.TextColor3 = Color3.fromRGB(255, 220, 140)
gameLbl.TextXAlignment = Enum.TextXAlignment.Left
gameLbl.Text = "Game: —"
gameLbl.Parent = card

lab("PlaceId  /  JobId  (filled after snipe, or paste)", 134)
local placeBox = boxAt(150, "PlaceId", tostring(game.PlaceId))
local jobBox = boxAt(182, "JobId (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)", "")

local goJob = Instance.new("TextButton")
goJob.Size = UDim2.new(0.48, -8, 0, 30)
goJob.Position = UDim2.fromOffset(12, 216)
goJob.BackgroundColor3 = Color3.fromRGB(90, 70, 180)
goJob.Text = "Join JobId"
goJob.TextColor3 = Color3.fromRGB(255, 255, 255)
goJob.Font = Enum.Font.SourceSansBold
goJob.TextSize = 14
goJob.Parent = card
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = goJob
end

local copyJob = Instance.new("TextButton")
copyJob.Size = UDim2.new(0.48, -8, 0, 30)
copyJob.Position = UDim2.new(0.52, 4, 0, 216)
copyJob.BackgroundColor3 = Color3.fromRGB(50, 40, 90)
copyJob.Text = "Copy JobId"
copyJob.TextColor3 = Color3.fromRGB(230, 210, 255)
copyJob.Font = Enum.Font.SourceSansBold
copyJob.TextSize = 14
copyJob.Parent = card
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = copyJob
end

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -24, 0, 36)
status.Position = UDim2.fromOffset(12, 252)
status.Font = Enum.Font.SourceSans
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(210, 196, 255)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.Text = "Snipe fills PlaceId + JobId. Friends-only privacy = no JobId. RightShift hide."
status.Parent = card

goName.MouseButton1Click:Connect(function()
	snipeName(nameBox.Text, status, jobBox, placeBox, gameLbl)
end)
nameBox.FocusLost:Connect(function(enter)
	if enter then
		snipeName(nameBox.Text, status, jobBox, placeBox, gameLbl)
	end
end)
goJob.MouseButton1Click:Connect(function()
	joinJob(placeBox.Text, jobBox.Text, status)
end)
copyJob.MouseButton1Click:Connect(function()
	if jobBox.Text ~= "" then
		copyText(jobBox.Text)
		status.Text = "JobId copied"
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

notify("Snipe ready — username or JobId")
print("[VOIDZ SNIPE] ready")
