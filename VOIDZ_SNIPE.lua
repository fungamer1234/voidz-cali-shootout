-- VOIDZ Player Snipe — join by username or JobId (standalone)
-- MacSploit: loadstring(game:HttpGet(url))()  -- one argument only

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

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

local cachedCookie, cookieTried
local function cookieHeader()
	if cookieTried then
		return cachedCookie
	end
	cookieTried = true
	local found
	local function consider(v)
		if found or v == nil then
			return
		end
		if type(v) == "string" and #v > 10 then
			if string.find(string.upper(v), "ROBLOSECURITY") then
				found = v
			elseif #v > 80 then
				found = ".ROBLOSECURITY=" .. v
			end
		elseif type(v) == "table" then
			for k, val in pairs(v) do
				local ks, vs = tostring(k), tostring(val)
				if string.find(string.upper(ks), "ROBLOSECURITY")
					or string.find(string.upper(vs), "ROBLOSECURITY")
					or string.find(vs, "_|WARNING") then
					if string.find(string.upper(vs), "ROBLOSECURITY") then
						found = vs
					else
						found = ".ROBLOSECURITY=" .. vs
					end
					return
				end
				if type(val) == "table" then
					consider(val)
				end
			end
		end
	end
	local tries = {
		function()
			return getcookies(".roblox.com")
		end,
		function()
			return getcookies("roblox.com")
		end,
		function()
			return getcookies("https://www.roblox.com")
		end,
		function()
			return getcookies("https://presence.roblox.com")
		end,
		function()
			return getcookie(".ROBLOSECURITY")
		end,
		function()
			return getcookie("https://www.roblox.com")
		end,
		function()
			return syn.get_cookie()
		end,
		function()
			return syn.get_cookies()
		end,
	}
	for i = 1, #tries do
		local ok, res = pcall(tries[i])
		if ok then
			consider(res)
		end
		if found then
			break
		end
	end
	cachedCookie = found
	return found
end

local function cookieTable()
	local tries = {
		function()
			return getcookies(".roblox.com")
		end,
		function()
			return getcookies("https://www.roblox.com")
		end,
		function()
			return getcookies("roblox.com")
		end,
	}
	for i = 1, #tries do
		local ok, res = pcall(tries[i])
		if ok and type(res) == "table" then
			return res
		end
	end
	return nil
end

local function httpReq(url, method, body)
	method = method or "GET"
	local req = request or http_request or (syn and syn.request) or (http and http.request)
	local cookie = cookieHeader()
	local cookies = cookieTable()
	if type(req) == "function" then
		local variants = {}
		if cookies then
			table.insert(variants, {
				Url = url,
				Method = method,
				Body = body,
				Headers = {
					["Content-Type"] = "application/json",
					["Accept"] = "application/json",
				},
				Cookies = cookies,
			})
		end
		if type(cookie) == "string" then
			table.insert(variants, {
				Url = url,
				Method = method,
				Body = body,
				Headers = {
					["Content-Type"] = "application/json",
					["Accept"] = "application/json",
					["Cookie"] = cookie,
				},
			})
		end
		table.insert(variants, {
			Url = url,
			Method = method,
			Body = body,
			Headers = {
				["Content-Type"] = "application/json",
				["Accept"] = "application/json",
			},
		})
		table.insert(variants, {
			Url = url,
			Method = method,
			Body = body,
		})
		for i = 1, #variants do
			local ok, res = pcall(req, variants[i])
			if ok and type(res) == "table" then
				local raw = res.Body or res.body
				if type(raw) == "string" and raw ~= "" then
					return raw
				end
			end
		end
	end
	if method == "GET" then
		local ok, body2 = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body2) == "string" then
			return body2
		end
	end
	return nil
end

local function decodeJson(raw)
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

local function resolveUserId(name)
	local uid
	pcall(function()
		uid = Players:GetUserIdFromNameAsync(name)
	end)
	if tonumber(uid) then
		return tonumber(uid)
	end
	local payload = HttpService:JSONEncode({ usernames = { name }, excludeBannedUsers = false })
	local data = decodeJson(httpReq("https://users.roblox.com/v1/usernames/users", "POST", payload))
		or decodeJson(httpReq("https://users.roproxy.com/v1/usernames/users", "POST", payload))
	if data and data.data then
		for i = 1, #data.data do
			local row = data.data[i]
			if row and tonumber(row.id) then
				return tonumber(row.id)
			end
		end
	end
	local q = name
	pcall(function()
		q = HttpService:UrlEncode(name)
	end)
	data = decodeJson(httpReq("https://users.roblox.com/v1/users/search?keyword=" .. q .. "&limit=10", "GET"))
		or decodeJson(httpReq("https://users.roproxy.com/v1/users/search?keyword=" .. q .. "&limit=10", "GET"))
	if data and data.data then
		local want = string.lower(name)
		for i = 1, #data.data do
			local row = data.data[i]
			if row and (string.lower(tostring(row.name or "")) == want or string.lower(tostring(row.displayName or "")) == want) then
				return tonumber(row.id)
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
	if s == "00000000-0000-0000-0000-000000000000" then
		return false
	end
	return string.find(s, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") ~= nil
end

local function jobFromRow(row)
	if type(row) ~= "table" then
		return nil
	end
	local j = row.gameId or row.GameId or row.gameInstanceId or row.GameInstanceId or row.instanceId
	if looksLikeJobId(j) then
		return tostring(j)
	end
	return nil
end

local function presenceFromHttp(uid)
	local payload = HttpService:JSONEncode({ userIds = { uid } })
	local urls = {
		"https://presence.roblox.com/v1/presence/users",
		"https://presence.roproxy.com/v1/presence/users",
	}
	local best
	local withJob
	for i = 1, #urls do
		local data = decodeJson(httpReq(urls[i], "POST", payload))
		local list = data and (data.userPresences or data.UserPresences)
		if type(list) == "table" then
			local row
			for j = 1, #list do
				if tonumber(list[j].userId or list[j].UserId) == tonumber(uid) then
					row = list[j]
					break
				end
			end
			row = row or list[1]
			if row then
				local ptype = tonumber(row.userPresenceType or row.UserPresenceType)
				local placeId = tonumber(row.placeId or row.PlaceId or row.rootPlaceId or row.RootPlaceId)
				local loc = row.lastLocation or row.LastLocation
				local stub = ptype == 0 and (loc == "Website" or loc == "website" or loc == nil or loc == "")
				if jobFromRow(row) then
					return row
				end
				if not stub then
					best = row
					if ptype == 2 or placeId then
						withJob = withJob or row
					end
				elseif not best then
					best = row
				end
			end
		end
	end
	return withJob or best
end

local function presenceFromFriends(uid, name)
	local list
	pcall(function()
		list = LP:GetFriendsOnline()
	end)
	if type(list) ~= "table" then
		return nil
	end
	local want = string.lower(tostring(name or ""))
	for i = 1, #list do
		local f = list[i]
		if type(f) == "table" then
			local id = tonumber(f.VisitorId or f.UserId or f.Id)
			local uname = string.lower(tostring(f.UserName or f.Username or f.Name or ""))
			if id == tonumber(uid) or (want ~= "" and uname == want) then
				return f
			end
		end
	end
	return nil
end

local function presenceFromEngine(uid)
	local poke, a, b, c, d = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(uid)
	end)
	print("[VOIDZ SNIPE] engine", poke, a, b, c, d)
	if not poke then
		return nil
	end
	local placeId, jobId
	local vals = { a, b, c, d }
	for i = 1, #vals do
		local v = vals[i]
		if looksLikeJobId(tostring(v or "")) then
			jobId = tostring(v)
		else
			local n = tonumber(v)
			if n and n > 10000 then
				placeId = n
			end
		end
	end
	if not placeId then
		return nil
	end
	return placeId, jobId
end

local function readPresence(uid, name)
	local out = {
		ptype = nil,
		placeId = nil,
		jobId = nil,
		universeId = nil,
		lastLocation = nil,
		source = nil,
	}
	local engPlace, engJob = presenceFromEngine(uid)
	if engPlace then
		out.ptype = 2
		out.placeId = engPlace
		if looksLikeJobId(engJob) then
			out.jobId = engJob
		end
		out.source = "engine"
	end
	local fr = presenceFromFriends(uid, name)
	if fr then
		local locType = tonumber(fr.LocationType)
		local fPlace = tonumber(fr.PlaceId or fr.placeId)
		local fJob = fr.GameId or fr.gameId
		-- GetFriendsOnline: 1 mobile game, 4 PC game, 5 Xbox. 2 = website.
		if fPlace then
			out.ptype = 2
			out.placeId = out.placeId or fPlace
			if looksLikeJobId(fJob) then
				out.jobId = out.jobId or tostring(fJob)
			end
			out.lastLocation = fr.LastLocation or fr.lastLocation or out.lastLocation
			out.source = out.source or "friends"
		elseif locType == 3 or locType == 6 then
			if not out.ptype then
				out.ptype = 3
				out.source = "friends"
			end
		elseif locType == 2 or locType == 0 then
			if not out.ptype then
				out.ptype = 1
				out.source = "friends"
			end
		end
	end
	local row = presenceFromHttp(uid)
	if row then
		local ptype = tonumber(row.userPresenceType or row.UserPresenceType)
		local placeId = tonumber(row.placeId or row.PlaceId or row.rootPlaceId or row.RootPlaceId)
		local jobId = jobFromRow(row)
		local loc = row.lastLocation or row.LastLocation
		local stub = ptype == 0 and (loc == "Website" or loc == "website") and not placeId
		if not stub then
			if ptype and ptype > (out.ptype or -1) then
				out.ptype = ptype
				out.source = "http"
			elseif out.ptype == nil and ptype then
				out.ptype = ptype
				out.source = "http"
			end
			out.placeId = out.placeId or placeId
			if looksLikeJobId(jobId) then
				out.jobId = out.jobId or tostring(jobId)
			end
			if type(loc) == "string" and loc ~= "" and loc ~= "Website" then
				out.lastLocation = out.lastLocation or loc
			end
			out.universeId = tonumber(row.universeId or row.UniverseId)
		end
		-- HTTP can still fill JobId/place even when engine already set InGame
		if placeId then
			out.placeId = out.placeId or placeId
		end
		if looksLikeJobId(jobId) then
			out.jobId = out.jobId or tostring(jobId)
		end
		if out.ptype == 2 or placeId then
			if type(loc) == "string" and loc ~= "" and loc ~= "Website" then
				out.lastLocation = out.lastLocation or loc
			end
		end
	end
	if out.placeId and (out.ptype == nil or out.ptype == 0 or out.ptype == 4) then
		out.ptype = 2
	end
	return out
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

local function runMacOpen(url)
	url = tostring(url or "")
	local cmd = '/usr/bin/open ' .. string.format("%q", url)
	pcall(function()
		os.execute(cmd)
	end)
	pcall(function()
		if getrenv and getrenv().os and getrenv().os.execute then
			getrenv().os.execute(cmd)
		end
	end)
	pcall(function()
		local f = io.popen(cmd)
		if f then
			f:close()
		end
	end)
	pcall(function()
		os.execute("/usr/bin/osascript -e 'open location \"" .. url .. "\"'")
	end)
end

local lastSnipeUid = nil

-- Non-friends: only placeId + gameInstanceId works. userId follow is friends-only
-- and was overwriting the good join. Open the link AFTER this client dies.
local function nativeLaunch(placeId, jobId)
	placeId = tonumber(placeId)
	jobId = tostring(jobId or ""):gsub("%s+", "")
	if not placeId or not looksLikeJobId(jobId) then
		return nil
	end
	local proto = "roblox://experiences/start?placeId=" .. tostring(placeId) .. "&gameInstanceId=" .. jobId
	local web = "https://www.roblox.com/games/start?placeId=" .. tostring(placeId) .. "&gameInstanceId=" .. jobId
	copyText(web)
	local bg = "(sleep 2; /usr/bin/open " .. string.format("%q", proto)
		.. "; sleep 0.4; /usr/bin/open " .. string.format("%q", web)
		.. ") >/dev/null 2>&1 &"
	pcall(function()
		os.execute(bg)
	end)
	pcall(function()
		if getrenv and getrenv().os and getrenv().os.execute then
			getrenv().os.execute(bg)
		end
	end)
	pcall(function()
		local f = io.popen(bg)
		if f then
			f:close()
		end
	end)
	runMacOpen(proto)
	runMacOpen(web)
	print("[VOIDZ SNIPE] join link " .. web)
	return web
end

local function joinJob(placeId, jobId, status)
	placeId = tonumber(placeId)
	jobId = tostring(jobId or ""):gsub("%s+", "")
	if not placeId then
		status.Text = "Need a PlaceId"
		return
	end
	if not looksLikeJobId(jobId) then
		status.Text = "No JobId — they hide servers from non-friends"
		notify("Can't join without a JobId")
		return
	end
	if tostring(game.JobId) == jobId then
		status.Text = "Already in that JobId"
		return
	end

	status.Text = "Joining their server..."
	notify("Joining " .. jobId)
	nativeLaunch(placeId, jobId)
	status.Text = "Closing Roblox — it will join that server next"
	notify("Leaving so Roblox can join their server")
	task.delay(0.8, function()
		pcall(function()
			game:Shutdown()
		end)
	end)
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
		local uid = resolveUserId(name)
		if not uid then
			status.Text = "User not found"
			return
		end

		status.Text = "Checking if they're in a game..."
		lastSnipeUid = uid
		local pres = readPresence(uid, name)
		local tries = 0
		while tries < 3 and not looksLikeJobId(pres.jobId) do
			tries = tries + 1
			status.Text = "Retrying JobId (" .. tostring(tries) .. "/3)..."
			task.wait(0.4)
			pres = readPresence(uid, name)
		end
		local ptype = tonumber(pres.ptype)
		local placeId = tonumber(pres.placeId)
		local jobId = pres.jobId
		if not looksLikeJobId(jobId) then
			jobId = nil
		end
		print("[VOIDZ SNIPE] " .. name .. " uid=" .. tostring(uid)
			.. " type=" .. tostring(ptype)
			.. " place=" .. tostring(placeId)
			.. " job=" .. tostring(jobId and "yes" or "no")
			.. " src=" .. tostring(pres.source))

		if placeId then
			placeBox.Text = tostring(placeId)
		end
		if jobId then
			jobBox.Text = tostring(jobId)
		end

		local gname = pres.lastLocation
		if type(gname) ~= "string" or gname == "" or gname == "Website" then
			gname = gameNameFromIds(pres.universeId, placeId)
		end
		if ptype == 3 then
			if gameLbl then gameLbl.Text = "Game  ·  Roblox Studio" end
			status.Text = name .. " is in Studio"
			return
		end
		if gname and gname ~= "Website" then
			if gameLbl then gameLbl.Text = "Game  ·  " .. gname end
		elseif placeId then
			if gameLbl then gameLbl.Text = "Game  ·  Place " .. tostring(placeId) end
		end

		if not jobId or not placeId then
			if gameLbl and not placeId then
				gameLbl.Text = "Game  ·  no server id"
			end
			status.Text = "No JobId — they hide servers from non-friends"
			notify("Need a JobId to join non-friends")
			return
		end
		status.Text = "In " .. tostring(gname or placeId) .. " — opening join link..."
		joinJob(placeId, jobId, status)
	end)
end

local function buildSnipeUi()
	local C = {
		bg = Color3.fromRGB(12, 8, 24),
		bg2 = Color3.fromRGB(22, 14, 42),
		card = Color3.fromRGB(36, 26, 62),
		input = Color3.fromRGB(28, 20, 52),
		stroke = Color3.fromRGB(168, 108, 255),
		strokeSoft = Color3.fromRGB(92, 68, 140),
		accent = Color3.fromRGB(186, 132, 255),
		accent2 = Color3.fromRGB(230, 196, 255),
		muted = Color3.fromRGB(186, 176, 214),
		text = Color3.fromRGB(255, 255, 255),
		good = Color3.fromRGB(72, 196, 148),
		danger = Color3.fromRGB(255, 150, 170),
		warn = Color3.fromRGB(255, 214, 130),
	}

	local function mix3(a, b, t)
		t = tonumber(t) or 0.5
		return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end

	local function tw(obj, props, t, style, dir)
		local ti = TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
		local tws = TweenService:Create(obj, ti, props)
		tws:Play()
		return tws
	end

	local function loopTw(obj, props, t, style)
		local ti = TweenInfo.new(t or 1.4, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local tws = TweenService:Create(obj, ti, props)
		tws:Play()
		return tws
	end

	local function corner(obj, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 10)
		c.Parent = obj
		return c
	end

	local function stroke(obj, col, th, tr)
		local s = Instance.new("UIStroke")
		s.Color = col or C.stroke
		s.Thickness = th or 1
		s.Transparency = tr ~= nil and tr or 0.35
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = obj
		return s
	end

	local function pad(obj, l, r)
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, l or 12)
		p.PaddingRight = UDim.new(0, r or l or 12)
		p.Parent = obj
		return p
	end

	local function shineSweep(btn)
		btn.ClipsDescendants = true
		local gloss = Instance.new("Frame")
		gloss.Name = "Shine"
		gloss.BackgroundColor3 = Color3.new(1, 1, 1)
		gloss.BackgroundTransparency = 0.84
		gloss.BorderSizePixel = 0
		gloss.Size = UDim2.new(0, 42, 1.4, 0)
		gloss.Position = UDim2.new(0, -48, 0, -6)
		gloss.Rotation = 18
		gloss.ZIndex = (btn.ZIndex or 1) + 1
		gloss.Parent = btn
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = gloss
		local function run()
			if not gloss.Parent then
				return
			end
			gloss.Position = UDim2.new(0, -56, 0, -6)
			local twn = tw(gloss, { Position = UDim2.new(1, 20, 0, -6) }, 0.85, Enum.EasingStyle.Quad)
			twn.Completed:Connect(function()
				task.delay(2.4, run)
			end)
		end
		task.delay(0.7, run)
	end

	local function styleBtn(btn, col)
		local sc = Instance.new("UIScale")
		sc.Scale = 1
		sc.Parent = btn
		local st = stroke(btn, mix3(col, C.accent2, 0.35), 1, 0.5)
		local idle = col
		local hover = mix3(col, Color3.new(1, 1, 1), 0.14)
		btn.MouseEnter:Connect(function()
			tw(btn, { BackgroundColor3 = hover }, 0.16)
			tw(sc, { Scale = 1.03 }, 0.2, Enum.EasingStyle.Back)
			tw(st, { Transparency = 0.18 }, 0.16)
		end)
		btn.MouseLeave:Connect(function()
			tw(btn, { BackgroundColor3 = idle }, 0.2)
			tw(sc, { Scale = 1 }, 0.18)
			tw(st, { Transparency = 0.5 }, 0.2)
		end)
		btn.MouseButton1Down:Connect(function()
			tw(sc, { Scale = 0.95 }, 0.07, Enum.EasingStyle.Quad)
		end)
		btn.MouseButton1Up:Connect(function()
			tw(sc, { Scale = 1.03 }, 0.16, Enum.EasingStyle.Back)
		end)
	end

	local function styleBox(box)
		local st = stroke(box, C.strokeSoft, 1, 0.55)
		box.Focused:Connect(function()
			tw(st, { Transparency = 0.08, Color = C.accent, Thickness = 1.4 }, 0.18)
			tw(box, { BackgroundColor3 = mix3(C.input, C.accent, 0.12) }, 0.18)
		end)
		box.FocusLost:Connect(function()
			tw(st, { Transparency = 0.55, Color = C.strokeSoft, Thickness = 1 }, 0.22)
			tw(box, { BackgroundColor3 = C.input }, 0.22)
		end)
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "VOIDZ_SNIPE"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 999999
	sg.Parent = pg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.ZIndex = 1
	dim.Parent = sg

	local shadow = Instance.new("Frame")
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Size = UDim2.fromOffset(392, 438)
	shadow.Position = UDim2.new(0.5, 0, 0.48, 18)
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 1
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 2
	shadow.Parent = sg
	corner(shadow, 20)

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.fromOffset(372, 420)
	card.Position = UDim2.new(0.5, 0, 0.48, 28)
	card.BackgroundColor3 = C.bg
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Active = true
	card.ClipsDescendants = true
	card.ZIndex = 3
	card.Parent = sg
	corner(card, 16)
	local cardStroke = stroke(card, C.accent, 1.3, 1)
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, mix3(C.accent, C.bg2, 0.42)),
			ColorSequenceKeypoint.new(0.5, C.bg),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 6, 20)),
		})
		g.Rotation = 118
		g.Parent = card
	end

	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 0.84
	cardScale.Parent = card

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundColor3 = C.bg2
	header.BackgroundTransparency = 0.15
	header.BorderSizePixel = 0
	header.ZIndex = 4
	header.Parent = card
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, mix3(C.accent, C.bg2, 0.38)),
			ColorSequenceKeypoint.new(1, C.bg2),
		})
		g.Rotation = 8
		g.Parent = header
	end

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(0, 0, 0, 2)
	topBar.BackgroundColor3 = Color3.new(1, 1, 1)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 6
	topBar.Parent = header
	local topGrad = Instance.new("UIGradient")
	topGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.accent),
		ColorSequenceKeypoint.new(0.5, C.accent2),
		ColorSequenceKeypoint.new(1, C.accent),
	})
	topGrad.Parent = topBar
	TweenService:Create(
		topGrad,
		TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
		{ Rotation = 360 }
	):Play()

	local headerLine = Instance.new("Frame")
	headerLine.Size = UDim2.new(1, 0, 0, 1)
	headerLine.Position = UDim2.new(0, 0, 1, -1)
	headerLine.BackgroundColor3 = C.strokeSoft
	headerLine.BackgroundTransparency = 0.45
	headerLine.BorderSizePixel = 0
	headerLine.ZIndex = 6
	headerLine.Parent = header

	local mark = Instance.new("Frame")
	mark.Size = UDim2.fromOffset(36, 36)
	mark.Position = UDim2.fromOffset(12, 9)
	mark.BackgroundColor3 = Color3.new(0, 0, 0)
	mark.BorderSizePixel = 0
	mark.ClipsDescendants = true
	mark.ZIndex = 7
	mark.Parent = header
	corner(mark, 10)
	stroke(mark, C.accent2, 1.2, 0.28)
	local markScale = Instance.new("UIScale")
	markScale.Scale = 1
	markScale.Parent = mark
	task.delay(0.6, function()
		if markScale.Parent then
			loopTw(markScale, { Scale = 1.06 }, 1.7)
		end
	end)
	local mv = Instance.new("TextLabel")
	mv.BackgroundTransparency = 1
	mv.Size = UDim2.fromScale(1, 1)
	mv.Font = Enum.Font.GothamBlack
	mv.TextSize = 15
	mv.TextColor3 = Color3.new(1, 1, 1)
	mv.Text = "V"
	mv.ZIndex = 8
	mv.Parent = mark
	local logo = Instance.new("ImageLabel")
	logo.BackgroundTransparency = 1
	logo.Size = UDim2.fromScale(1, 1)
	logo.Image = ""
	logo.ScaleType = Enum.ScaleType.Crop
	logo.ZIndex = 9
	logo.Parent = mark
	corner(logo, 10)

	local function httpBytes(url)
		local req = request or http_request or (syn and syn.request) or (http and http.request)
		if type(req) == "function" then
			local ok, res = pcall(req, { Url = url, Method = "GET" })
			if ok and type(res) == "table" then
				local body = res.Body or res.body
				if type(body) == "string" and #body > 64 then
					return body
				end
			end
		end
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body) == "string" and #body > 64 then
			return body
		end
		return nil
	end

	local function applyCustomImage(imageLabel, bytes, fileName)
		if type(bytes) ~= "string" or #bytes < 64 then
			return false
		end
		if bytes:sub(1, 4) ~= "\137PNG" then
			return false
		end
		pcall(function()
			if makefolder and (not isfolder or not isfolder("voidz")) then
				makefolder("voidz")
			end
		end)
		local path = "voidz/" .. fileName
		local wrote = pcall(function()
			writefile(path, bytes)
		end)
		if not wrote then
			path = fileName
			wrote = pcall(function()
				writefile(path, bytes)
			end)
		end
		if not wrote then
			return false
		end
		local getters = {
			function()
				return getcustomasset(path)
			end,
			function()
				return getcustomasset(path, true)
			end,
			function()
				return syn.getcustomasset(path)
			end,
			function()
				return getcustomasset("voidz/" .. fileName)
			end,
		}
		for i = 1, #getters do
			local ok, asset = pcall(getters[i])
			if ok and type(asset) == "string" and asset ~= "" then
				imageLabel.Image = asset
				return true
			end
		end
		return false
	end

	task.spawn(function()
		local urls = {
			"https://raw.githubusercontent.com/fungamer1234/voidz-cali-shootout/f77d8149d2fd25368eec95aa17f67cb0894c0bf2/voidz_logo.png",
			"https://raw.githubusercontent.com/fungamer1234/voidz-cali-shootout/main/voidz_logo.png",
			"https://cdn.jsdelivr.net/gh/fungamer1234/voidz-cali-shootout@main/voidz_logo.png",
		}
		for i = 1, #urls do
			local bytes = httpBytes(urls[i])
			if applyCustomImage(logo, bytes, "voidz_logo.png") then
				mv.Text = ""
				return
			end
		end
	end)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -96, 0, 16)
	title.Position = UDim2.fromOffset(56, 10)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 14
	title.TextColor3 = C.text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "VOIDZ"
	title.ZIndex = 7
	title.Parent = header

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, -90, 0, 13)
	sub.Position = UDim2.fromOffset(56, 28)
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 10
	sub.TextColor3 = C.accent2
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Text = "SNIPE  ·  RightShift hide"
	sub.ZIndex = 7
	sub.Parent = header

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(24, 24)
	close.Position = UDim2.new(1, -38, 0, 15)
	close.BackgroundColor3 = Color3.fromRGB(56, 24, 42)
	close.Text = "×"
	close.TextColor3 = C.danger
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.AutoButtonColor = false
	close.ZIndex = 8
	close.Parent = header
	corner(close, 7)
	styleBtn(close, Color3.fromRGB(56, 24, 42))

	local function sectionLabel(text, y)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, -36, 0, 12)
		l.Position = UDim2.fromOffset(18, y)
		l.Font = Enum.Font.GothamBold
		l.TextSize = 10
		l.TextColor3 = C.muted
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTransparency = 1
		l.Text = string.upper(text)
		l.ZIndex = 4
		l.Parent = card
		return l
	end

	local function makeBox(y, placeholder, defaultText)
		local b = Instance.new("TextBox")
		b.Size = UDim2.new(1, -36, 0, 34)
		b.Position = UDim2.fromOffset(18, y)
		b.BackgroundColor3 = C.input
		b.BackgroundTransparency = 1
		b.Text = defaultText or ""
		b.PlaceholderText = placeholder
		b.PlaceholderColor3 = Color3.fromRGB(130, 118, 158)
		b.TextColor3 = C.text
		b.TextTransparency = 1
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 13
		b.ClearTextOnFocus = false
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.BorderSizePixel = 0
		b.ZIndex = 4
		b.Parent = card
		corner(b, 9)
		pad(b, 12)
		styleBox(b)
		return b
	end

	local function makeBtn(text, y, h, col, x, w)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(w or 336, h or 34)
		b.Position = UDim2.fromOffset(x or 18, y)
		b.BackgroundColor3 = col
		b.BackgroundTransparency = 1
		b.Text = text
		b.TextColor3 = C.text
		b.TextTransparency = 1
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.AutoButtonColor = false
		b.BorderSizePixel = 0
		b.ZIndex = 4
		b.Parent = card
		corner(b, 9)
		styleBtn(b, col)
		return b
	end

	local labTarget = sectionLabel("Target", 64)
	local nameBox = makeBox(80, "Roblox username", "")
	local goName = makeBtn("Snipe user", 122, 36, C.accent)
	shineSweep(goName)

	local gameChip = Instance.new("Frame")
	gameChip.Size = UDim2.new(1, -36, 0, 28)
	gameChip.Position = UDim2.fromOffset(18, 166)
	gameChip.BackgroundColor3 = Color3.fromRGB(40, 28, 64)
	gameChip.BackgroundTransparency = 1
	gameChip.BorderSizePixel = 0
	gameChip.ZIndex = 4
	gameChip.Parent = card
	corner(gameChip, 8)
	stroke(gameChip, C.strokeSoft, 1, 0.55)
	local chipDot = Instance.new("Frame")
	chipDot.Size = UDim2.fromOffset(7, 7)
	chipDot.Position = UDim2.fromOffset(10, 11)
	chipDot.BackgroundColor3 = C.warn
	chipDot.BackgroundTransparency = 1
	chipDot.BorderSizePixel = 0
	chipDot.ZIndex = 5
	chipDot.Parent = gameChip
	corner(chipDot, 4)
	local gameLbl = Instance.new("TextLabel")
	gameLbl.BackgroundTransparency = 1
	gameLbl.Size = UDim2.new(1, -28, 1, 0)
	gameLbl.Position = UDim2.fromOffset(22, 0)
	gameLbl.Font = Enum.Font.GothamBold
	gameLbl.TextSize = 11
	gameLbl.TextColor3 = C.warn
	gameLbl.TextTransparency = 1
	gameLbl.TextXAlignment = Enum.TextXAlignment.Left
	gameLbl.Text = "Game  ·  waiting"
	pcall(function()
		gameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	end)
	gameLbl.ZIndex = 5
	gameLbl.Parent = gameChip

	local labServer = sectionLabel("Server", 204)
	local placeBox = makeBox(220, "PlaceId", tostring(game.PlaceId))
	local jobBox = makeBox(260, "JobId", "")

	local goJob = makeBtn("Join JobId", 302, 32, Color3.fromRGB(92, 68, 168), 18, 160)
	local copyJob = makeBtn("Copy JobId", 302, 32, Color3.fromRGB(48, 36, 82), 194, 160)
	local openBtn = makeBtn("Open in Roblox", 342, 36, C.good)
	shineSweep(openBtn)

	local statusBar = Instance.new("Frame")
	statusBar.Size = UDim2.new(1, 0, 0, 0)
	statusBar.Position = UDim2.new(0, 0, 1, -38)
	statusBar.BackgroundColor3 = Color3.fromRGB(16, 10, 30)
	statusBar.BorderSizePixel = 0
	statusBar.ZIndex = 5
	statusBar.Parent = card
	local live = Instance.new("Frame")
	live.Size = UDim2.fromOffset(6, 6)
	live.Position = UDim2.fromOffset(16, 16)
	live.BackgroundColor3 = C.accent
	live.BackgroundTransparency = 1
	live.BorderSizePixel = 0
	live.ZIndex = 6
	live.Parent = statusBar
	corner(live, 3)
	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Size = UDim2.new(1, -40, 1, 0)
	status.Position = UDim2.fromOffset(28, 0)
	status.Font = Enum.Font.Gotham
	status.TextSize = 11
	status.TextColor3 = C.muted
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = "Snipe a user, then Roblox hops you in."
	pcall(function()
		status.TextTruncate = Enum.TextTruncate.AtEnd
	end)
	status.ZIndex = 6
	status.Parent = statusBar

	local function setStatus(msg)
		tw(status, { TextTransparency = 1 }, 0.08)
		task.delay(0.08, function()
			if not status.Parent then
				return
			end
			status.Text = tostring(msg or "")
			tw(status, { TextTransparency = 0 }, 0.2)
		end)
	end

	local function pulseChip()
		tw(gameChip, { BackgroundColor3 = Color3.fromRGB(78, 52, 118) }, 0.1)
		task.delay(0.12, function()
			if gameChip.Parent then
				tw(gameChip, { BackgroundColor3 = Color3.fromRGB(40, 28, 64) }, 0.32)
			end
		end)
	end

	local function setGameText(msg)
		tw(gameLbl, { TextTransparency = 1 }, 0.08)
		pulseChip()
		task.delay(0.08, function()
			if not gameLbl.Parent then
				return
			end
			gameLbl.Text = tostring(msg or "")
			tw(gameLbl, { TextTransparency = 0 }, 0.22)
		end)
	end

	local function bindText(label, onSet)
		return setmetatable({}, {
			__index = function(_, k)
				return label[k]
			end,
			__newindex = function(_, k, v)
				if k == "Text" then
					onSet(v)
				else
					label[k] = v
				end
			end,
		})
	end

	local statusRef = bindText(status, setStatus)
	local gameRef = bindText(gameLbl, setGameText)

	local function reveal(obj, delay, bgTo, txtTo)
		task.delay(delay, function()
			if not obj.Parent then
				return
			end
			local props = {}
			if bgTo ~= nil then
				props.BackgroundTransparency = bgTo
			end
			if txtTo ~= nil then
				props.TextTransparency = txtTo
			end
			tw(obj, props, 0.32, Enum.EasingStyle.Quart)
		end)
	end

	-- entrance
	tw(dim, { BackgroundTransparency = 0.52 }, 0.38)
	tw(shadow, { BackgroundTransparency = 0.62, Position = UDim2.new(0.5, 0, 0.48, 10) }, 0.42, Enum.EasingStyle.Quart)
	tw(card, { BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0.48, 0) }, 0.48, Enum.EasingStyle.Back)
	tw(cardScale, { Scale = 1 }, 0.5, Enum.EasingStyle.Back)
	tw(cardStroke, { Transparency = 0.28 }, 0.45)
	task.delay(0.1, function()
		tw(topBar, { Size = UDim2.new(1, 0, 0, 2) }, 0.5, Enum.EasingStyle.Quart)
		tw(statusBar, { Size = UDim2.new(1, 0, 0, 38) }, 0.38, Enum.EasingStyle.Quart)
	end)
	reveal(labTarget, 0.16, nil, 0)
	reveal(nameBox, 0.2, 0, 0)
	reveal(goName, 0.26, 0, 0)
	reveal(gameChip, 0.3, 0, nil)
	reveal(chipDot, 0.34, 0, nil)
	reveal(gameLbl, 0.34, nil, 0)
	reveal(labServer, 0.36, nil, 0)
	reveal(placeBox, 0.4, 0, 0)
	reveal(jobBox, 0.44, 0, 0)
	reveal(goJob, 0.48, 0, 0)
	reveal(copyJob, 0.5, 0, 0)
	reveal(openBtn, 0.54, 0, 0)
	reveal(live, 0.42, 0, nil)
	task.delay(0.7, function()
		if chipDot.Parent then
			loopTw(chipDot, { BackgroundTransparency = 0.4 }, 1.15)
		end
		if live.Parent then
			loopTw(live, { BackgroundTransparency = 0.5 }, 1.05)
		end
	end)

	local animGen = 0
	local function hidePanel(destroy)
		animGen = animGen + 1
		local gen = animGen
		tw(dim, { BackgroundTransparency = 1 }, 0.2)
		tw(shadow, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 14) }, 0.2)
		tw(cardScale, { Scale = 0.9 }, 0.2, Enum.EasingStyle.Quad)
		tw(card, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.52, 0) }, 0.22)
		tw(cardStroke, { Transparency = 1 }, 0.18)
		task.delay(0.22, function()
			if gen ~= animGen then
				return
			end
			if destroy then
				if sg then
					sg:Destroy()
				end
			else
				sg.Enabled = false
			end
		end)
	end

	local function showPanel()
		animGen = animGen + 1
		sg.Enabled = true
		cardScale.Scale = 0.92
		dim.BackgroundTransparency = 1
		card.BackgroundTransparency = 0.2
		card.Position = UDim2.new(0.5, 0, 0.5, 12)
		shadow.BackgroundTransparency = 1
		tw(dim, { BackgroundTransparency = 0.52 }, 0.24)
		tw(shadow, { BackgroundTransparency = 0.62, Position = UDim2.new(0.5, 0, 0.48, 10) }, 0.28)
		tw(card, { BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0.48, 0) }, 0.32, Enum.EasingStyle.Back)
		tw(cardScale, { Scale = 1 }, 0.34, Enum.EasingStyle.Back)
		tw(cardStroke, { Transparency = 0.28 }, 0.28)
	end

	close.MouseButton1Click:Connect(function()
		hidePanel(true)
	end)

	goName.MouseButton1Click:Connect(function()
		pulseChip()
		snipeName(nameBox.Text, statusRef, jobBox, placeBox, gameRef)
	end)
	nameBox.FocusLost:Connect(function(enter)
		if enter then
			pulseChip()
			snipeName(nameBox.Text, statusRef, jobBox, placeBox, gameRef)
		end
	end)
	goJob.MouseButton1Click:Connect(function()
		joinJob(placeBox.Text, jobBox.Text, statusRef)
	end)
	copyJob.MouseButton1Click:Connect(function()
		if jobBox.Text ~= "" then
			copyText(jobBox.Text)
			setStatus("JobId copied")
		end
	end)
	openBtn.MouseButton1Click:Connect(function()
		joinJob(placeBox.Text, jobBox.Text, statusRef)
	end)

	local dragging, startIn, startPos, startShadow
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startIn = input.Position
			startPos = card.Position
			startShadow = shadow.Position
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
			shadow.Position = UDim2.new(startShadow.X.Scale, startShadow.X.Offset + d.X, startShadow.Y.Scale, startShadow.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.RightShift then
			if sg.Enabled then
				hidePanel(false)
			else
				showPanel()
			end
		end
	end)

	notify("Snipe ready")
	print("[VOIDZ SNIPE] ready")
end

buildSnipeUi()
