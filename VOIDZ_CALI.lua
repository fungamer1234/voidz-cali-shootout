--[[
  VOIDZ HUB — Cali Shootout
  Build 2026-08-23-1.0.0  |  Key: VOIDZHUB  |  RightShift toggle

  Feature set merged from public Cali scripts (Express/_scripts, Teeksaw, YNC, MikeyHub, Airflow):
  combat god (invincible + still shoot), silent aim, gun mods, farms, ESP, teleports.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = workspace

local LP = Players.LocalPlayer
while not LP do task.wait() LP = Players.LocalPlayer end
local Mouse = LP:GetMouse()
local Camera = Workspace.CurrentCamera

local HUB_NAME = "VOIDZ  CALI"
local BUILD = "2026-08-23-1.0.0"
local ACCESS_KEY = "VOIDZHUB"
local PLACE_ID = 12077443856

local C = {
	bg = Color3.fromRGB(10, 8, 16),
	bg2 = Color3.fromRGB(16, 12, 26),
	card = Color3.fromRGB(26, 18, 40),
	cardHov = Color3.fromRGB(36, 26, 54),
	accent = Color3.fromRGB(150, 70, 255),
	accent2 = Color3.fromRGB(190, 120, 255),
	text = Color3.fromRGB(240, 236, 255),
	muted = Color3.fromRGB(140, 125, 165),
	border = Color3.fromRGB(55, 40, 80),
	success = Color3.fromRGB(70, 210, 130),
	danger = Color3.fromRGB(210, 55, 80),
	warn = Color3.fromRGB(255, 190, 70),
}

local S = {
	toggles = {},
	conns = {},
	walkSpeed = 22,
	flySpeed = 80,
	hitboxSize = 8,
	silentFov = 180,
	killRange = 80,
	selected = nil,
	esp = {},
}

local function tw(o, props, t)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function corner(i, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = i
	return c
end
local function stroke(i, col, th, tr)
	local s = Instance.new("UIStroke")
	s.Color = col or C.border
	s.Thickness = th or 1
	s.Transparency = tr or 0.35
	s.Parent = i
	return s
end

local function notify(title, text, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or HUB_NAME,
			Text = text or "",
			Duration = dur or 2.2,
		})
	end)
end

local function char()
	return LP.Character
end
local function hrp()
	local c = char()
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
	local c = char()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function tp(cf)
	local r = hrp()
	if r then
		pcall(function()
			r.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
		end)
	end
end

local function pickGuiParent()
	local ok, cg = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

local function addConn(id, conn)
	if S.conns[id] then
		pcall(function() S.conns[id]:Disconnect() end)
	end
	S.conns[id] = conn
end
local function dropConn(id)
	if S.conns[id] then
		pcall(function() S.conns[id]:Disconnect() end)
		S.conns[id] = nil
	end
end

local function aliveP(p)
	if not p or p == LP then return false end
	local c = p.Character
	if not c then return false end
	local h = c:FindFirstChildOfClass("Humanoid")
	local r = c:FindFirstChild("HumanoidRootPart")
	if not h or not r then return false end
	if h.Health <= 0 then return false end
	return true
end

local function cashOf(p)
	local n = 0
	pcall(function()
		local ls = p:FindFirstChild("leaderstats")
		if ls then
			for _, name in ipairs({ "Cash", "Money", "Bank", "Wallet", "Dollars" }) do
				local v = ls:FindFirstChild(name)
				if v and tonumber(v.Value) then
					n = math.max(n, tonumber(v.Value) or 0)
				end
			end
		end
		for _, a in ipairs({ "Cash", "Money", "Bank" }) do
			local v = p:GetAttribute(a)
			if tonumber(v) then n = math.max(n, tonumber(v)) end
		end
	end)
	return n
end

-- ── Combat God: stay alive AND keep guns ───────────────────────
-- No ForceField, no PlatformStand, no Sit — those stop shooting.
local function applyCombatGod(h, c)
	if not h then return end
	pcall(function()
		h.BreakJointsOnDeath = false
		h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		h:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		h.PlatformStand = false
		h.Sit = false
		if h.Health < h.MaxHealth then
			h.Health = h.MaxHealth
		end
	end)
	if not c then return end
	pcall(function()
		for _, name in ipairs({ "Downed", "Knocked", "Ragdolled", "Stunned", "Dead", "KO", "Incapacitated" }) do
			local v = c:FindFirstChild(name, true) or h:FindFirstChild(name)
			if v and (v:IsA("BoolValue") or v:IsA("IntValue")) then
				v.Value = false
			end
			if c:GetAttribute(name) == true then
				c:SetAttribute(name, false)
			end
			if LP:GetAttribute(name) == true then
				LP:SetAttribute(name, false)
			end
		end
		local ff = c:FindFirstChildOfClass("ForceField")
		if ff then ff:Destroy() end
	end)
end

local function setCombatGod(on)
	S.toggles.combatGod = on == true
	dropConn("combatGodHB")
	dropConn("combatGodHealth")
	if not on then
		notify(HUB_NAME, "Combat God OFF", 1.2)
		return
	end
	notify(HUB_NAME, "Combat God ON — invincible, guns still work", 2)
	local function bind(h)
		if not h then return end
		dropConn("combatGodHealth")
		addConn("combatGodHealth", h.HealthChanged:Connect(function()
			if S.toggles.combatGod then
				applyCombatGod(h, char())
			end
		end))
	end
	bind(hum())
	LP.CharacterAdded:Connect(function(c)
		task.wait(0.2)
		if S.toggles.combatGod then bind(c:FindFirstChildOfClass("Humanoid")) end
	end)
	addConn("combatGodHB", RunService.Heartbeat:Connect(function()
		if not S.toggles.combatGod then return end
		applyCombatGod(hum(), char())
	end))
end

-- ── Gun mods ───────────────────────────────────────────────────
local GUN_KEYS = {
	"Recoil", "recoil", "Spread", "spread", "Accuracy", "FireRate", "Firerate",
	"Cooldown", "Debounce", "Delay", "Ammo", "MaxAmmo", "Clip", "Magazine",
	"JamChance", "Jam", "Range", "Damage", "Knockback", "Shake", "Bloom",
}

local function eachGunValue(fn)
	local c = char()
	if not c then return end
	local tools = {}
	for _, t in ipairs(c:GetChildren()) do
		if t:IsA("Tool") then tools[#tools + 1] = t end
	end
	local bp = LP:FindFirstChildOfClass("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then tools[#tools + 1] = t end
		end
	end
	for _, tool in ipairs(tools) do
		pcall(fn, tool)
		for _, d in ipairs(tool:GetDescendants()) do
			pcall(fn, d)
		end
	end
end

local function applyGunMods()
	eachGunValue(function(obj)
		if S.toggles.noRecoil then
			for _, k in ipairs({ "Recoil", "recoil", "Shake", "Bloom" }) do
				if obj:GetAttribute(k) ~= nil then pcall(function() obj:SetAttribute(k, 0) end) end
				if obj:IsA("NumberValue") or obj:IsA("IntValue") then
					local n = obj.Name:lower()
					if n:find("recoil") or n:find("shake") or n:find("bloom") then
						obj.Value = 0
					end
				end
			end
		end
		if S.toggles.noSpread then
			if obj:IsA("NumberValue") or obj:IsA("IntValue") then
				local n = obj.Name:lower()
				if n:find("spread") or n:find("accuracy") then
					if n:find("accuracy") then obj.Value = 1 else obj.Value = 0 end
				end
			end
		end
		if S.toggles.infAmmo then
			if obj:IsA("NumberValue") or obj:IsA("IntValue") then
				local n = obj.Name:lower()
				if n:find("ammo") or n:find("clip") or n:find("mag") then
					if obj.Value < 30 then obj.Value = 999 end
				end
			end
		end
		if S.toggles.noJam then
			if obj:IsA("BoolValue") and obj.Name:lower():find("jam") then obj.Value = false end
			if obj:IsA("NumberValue") and obj.Name:lower():find("jam") then obj.Value = 0 end
		end
		if S.toggles.rapidFire then
			if obj:IsA("NumberValue") or obj:IsA("IntValue") then
				local n = obj.Name:lower()
				if n:find("cooldown") or n:find("debounce") or n:find("delay") then
					obj.Value = 0
				elseif n:find("firerate") or n:find("fire_rate") then
					obj.Value = math.max(obj.Value, 20)
				end
			end
		end
		if S.toggles.oneShot then
			if obj:IsA("NumberValue") or obj:IsA("IntValue") then
				local n = obj.Name:lower()
				if n:find("damage") then obj.Value = 9e4 end
			end
			if obj:GetAttribute("Damage") then pcall(function() obj:SetAttribute("Damage", 9e4) end) end
		end
	end)
end

-- ── Silent aim / aimbot ────────────────────────────────────────
local function worldToScreen(pos)
	local v, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), on, v.Z
end

local function closestInFov()
	local best, bestAng = nil, math.rad(S.silentFov or 180)
	local mpos = UserInputService:GetMouseLocation()
	for _, p in ipairs(Players:GetPlayers()) do
		if aliveP(p) then
			local head = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
			if head then
				local sp, on = worldToScreen(head.Position)
				if on then
					local d = (sp - mpos).Magnitude
					local ang = math.atan2(d, 400)
					if ang < bestAng then
						bestAng, best = ang, p
					end
				end
			end
		end
	end
	return best
end

local silentHooked = false
local function installSilentAim()
	if silentHooked then return end
	silentHooked = true
	local hmm = hookmetamethod or (syn and syn.hook_metamethod)
	if type(hmm) == "function" then
		pcall(function()
			local old
			old = hmm(game, "__index", function(self, k)
				if S.toggles.silentAim and self == Mouse then
					local t = closestInFov()
					local part = t and t.Character and (t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart"))
					if part then
						if k == "Hit" then return CFrame.new(part.Position) end
						if k == "Target" then return part end
					end
				end
				return old(self, k)
			end)
		end)
	end
end

local function setAimbot(on)
	S.toggles.aimbot = on == true
	dropConn("aimbot")
	if not on then return end
	addConn("aimbot", RunService.RenderStepped:Connect(function()
		if not S.toggles.aimbot then return end
		local t = closestInFov()
		if not t then return end
		local head = t.Character and t.Character:FindFirstChild("Head")
		if head then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
		end
	end))
end

-- ── Hitboxes ───────────────────────────────────────────────────
local hitboxOrig = {}
local function setHitboxes(on)
	S.toggles.hitbox = on == true
	dropConn("hitbox")
	if not on then
		for part, sz in pairs(hitboxOrig) do
			pcall(function()
				if part and part.Parent then part.Size = sz end
			end)
		end
		hitboxOrig = {}
		return
	end
	addConn("hitbox", RunService.Heartbeat:Connect(function()
		if not S.toggles.hitbox then return end
		local sz = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
		for _, p in ipairs(Players:GetPlayers()) do
			if aliveP(p) then
				for _, n in ipairs({ "HumanoidRootPart", "Head", "UpperTorso", "Torso" }) do
					local part = p.Character:FindFirstChild(n)
					if part and part:IsA("BasePart") then
						if not hitboxOrig[part] then hitboxOrig[part] = part.Size end
						part.Size = sz
						part.Transparency = 0.7
						part.CanCollide = false
						part.Massless = true
					end
				end
			end
		end
	end))
end

-- ── Kill aura ──────────────────────────────────────────────────
local function fireGun()
	local c = char()
	if not c then return end
	local tool = c:FindFirstChildOfClass("Tool")
	if tool then
		pcall(function() tool:Activate() end)
	end
	pcall(function()
		VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
		VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
	end)
end

local function setKillAura(on)
	S.toggles.killAura = on == true
	dropConn("killAura")
	if not on then return end
	addConn("killAura", RunService.Heartbeat:Connect(function()
		if not S.toggles.killAura then return end
		local me = hrp()
		if not me then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if aliveP(p) then
				local r = p.Character.HumanoidRootPart
				if (r.Position - me.Position).Magnitude <= (S.killRange or 80) then
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, r.Position + Vector3.new(0, 1.4, 0))
					fireGun()
				end
			end
		end
	end))
end

-- ── Movement ───────────────────────────────────────────────────
local function setNoclip(on)
	S.toggles.noclip = on == true
	dropConn("noclip")
	if not on then return end
	addConn("noclip", RunService.Stepped:Connect(function()
		if not S.toggles.noclip then return end
		local c = char()
		if not c then return end
		for _, p in ipairs(c:GetChildren()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end))
end

local function setFly(on)
	S.toggles.fly = on == true
	local r = hrp()
	if r then
		local old = r:FindFirstChild("VOIDZ_Fly")
		if old then old:Destroy() end
		old = r:FindFirstChild("VOIDZ_FlyG")
		if old then old:Destroy() end
	end
	dropConn("fly")
	if not on or not r then return end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "VOIDZ_Fly"
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Velocity = Vector3.zero
	bv.Parent = r
	local bg = Instance.new("BodyGyro")
	bg.Name = "VOIDZ_FlyG"
	bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bg.P = 9000
	bg.Parent = r
	addConn("fly", RunService.RenderStepped:Connect(function()
		if not S.toggles.fly then return end
		r = hrp()
		if not r then return end
		if not bv.Parent then bv.Parent = r end
		if not bg.Parent then bg.Parent = r end
		local cam = Workspace.CurrentCamera
		bg.CFrame = cam.CFrame
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
		bv.Velocity = dir.Magnitude > 0.05 and dir.Unit * S.flySpeed or Vector3.zero
	end))
end

local function setInfJump(on)
	S.toggles.infJump = on == true
	dropConn("infJump")
	if not on then return end
	addConn("infJump", UserInputService.JumpRequest:Connect(function()
		if not S.toggles.infJump then return end
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end))
end

local function setSpeedLoop(on)
	S.toggles.speed = on == true
	dropConn("speed")
	if not on then return end
	addConn("speed", RunService.Heartbeat:Connect(function()
		if not S.toggles.speed then return end
		local h = hum()
		if h then h.WalkSpeed = S.walkSpeed end
	end))
end

-- ── Instant prompts + farms ────────────────────────────────────
local function firePrompt(pr)
	pcall(function()
		if fireproximityprompt then
			fireproximityprompt(pr)
		else
			pr.HoldDuration = 0
			pr:InputHoldBegin()
			pr:InputHoldEnd()
		end
	end)
end

local function setInstantPrompt(on)
	S.toggles.instantPrompt = on == true
	dropConn("prompt")
	if not on then return end
	addConn("prompt", ProximityPromptService.PromptButtonHoldBegan:Connect(function(pr)
		if S.toggles.instantPrompt then
			pr.HoldDuration = 0
			firePrompt(pr)
		end
	end))
	task.spawn(function()
		while S.toggles.instantPrompt do
			pcall(function()
				for _, d in ipairs(Workspace:GetDescendants()) do
					if d:IsA("ProximityPrompt") then
						d.HoldDuration = 0
						d.MaxActivationDistance = math.max(d.MaxActivationDistance, 18)
					end
				end
			end)
			task.wait(1.2)
		end
	end)
end

local function promptBlob(pr)
	local bits = {
		pr.Name,
		pr.ActionText or "",
		pr.ObjectText or "",
		pr.Parent and pr.Parent.Name or "",
	}
	return table.concat(bits, " "):lower()
end

local function farmOnce(keys)
	local me = hrp()
	if not me then return end
	local best, bd
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local blob = promptBlob(d)
			local ok = false
			for _, k in ipairs(keys) do
				if blob:find(k, 1, true) then ok = true break end
			end
			if ok then
				local part = d.Parent
				if part:IsA("BasePart") or (part.Parent and part.Parent:IsA("BasePart")) then
					local pos = (part:IsA("BasePart") and part.Position) or (part.Parent.Position)
					local dist = (pos - me.Position).Magnitude
					if not bd or dist < bd then
						best, bd = d, dist
					end
				end
			end
		end
	end
	if not best then return false end
	local part = best.Parent:IsA("BasePart") and best.Parent or best.Parent.Parent
	if part and part:IsA("BasePart") then
		tp(part.CFrame + Vector3.new(0, 3, 0))
		task.wait(0.12)
	end
	firePrompt(best)
	return true
end

local function startFarm(id, keys)
	S.toggles[id] = true
	task.spawn(function()
		while S.toggles[id] do
			pcall(farmOnce, keys)
			task.wait(0.35)
		end
	end)
end
local function stopFarm(id)
	S.toggles[id] = false
end

-- ── ESP ────────────────────────────────────────────────────────
local function clearESP()
	for p, gui in pairs(S.esp) do
		pcall(function() gui:Destroy() end)
		S.esp[p] = nil
	end
end

local function setESP(on)
	S.toggles.esp = on == true
	dropConn("esp")
	if not on then
		clearESP()
		return
	end
	addConn("esp", RunService.Heartbeat:Connect(function()
		if not S.toggles.esp then return end
		local me = hrp()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
				local gui = S.esp[p]
				if not gui or not gui.Parent then
					gui = Instance.new("BillboardGui")
					gui.Name = "VOIDZ_ESP"
					gui.Size = UDim2.fromOffset(160, 42)
					gui.AlwaysOnTop = true
					gui.StudsOffset = Vector3.new(0, 2.6, 0)
					local tl = Instance.new("TextLabel")
					tl.BackgroundTransparency = 1
					tl.Size = UDim2.fromScale(1, 1)
					tl.Font = Enum.Font.GothamBold
					tl.TextSize = 12
					tl.TextColor3 = C.accent2
					tl.TextStrokeTransparency = 0.4
					tl.Parent = gui
					gui.Parent = p.Character.Head
					S.esp[p] = gui
				end
				local h = p.Character:FindFirstChildOfClass("Humanoid")
				local r = p.Character:FindFirstChild("HumanoidRootPart")
				local dist = (me and r) and math.floor((me.Position - r.Position).Magnitude) or 0
				local cash = cashOf(p)
				local label = gui:FindFirstChildOfClass("TextLabel")
				if label then
					label.Text = string.format("%s  [%d hp]\n%d studs  $%s",
						p.DisplayName ~= "" and p.DisplayName or p.Name,
						h and math.floor(h.Health) or 0,
						dist,
						tostring(cash))
				end
			elseif S.esp[p] then
				pcall(function() S.esp[p]:Destroy() end)
				S.esp[p] = nil
			end
		end
	end))
end

local function setFullbright(on)
	S.toggles.fullbright = on == true
	if on then
		Lighting.Brightness = 4
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e9
		Lighting.GlobalShadows = false
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
	end
end

-- ── Teleports ──────────────────────────────────────────────────
local TPS = {
	{ "Gun Shop", Vector3.new(-1633.5, 7.2, -92.4) },
	{ "Gas / Bank", Vector3.new(-1928.4, 5.1, 89.2) },
	{ "Car Dealership", Vector3.new(-1415.4, 5.5, -115.2) },
	{ "IceBox", Vector3.new(-1986.2, 0.5, 43.8) },
	{ "Box Job", Vector3.new(-1920.6, 1.7, -51.2) },
	{ "Janitor Job", Vector3.new(-1655.2, 5.0, 39.4) },
	{ "Shop", Vector3.new(-1881.4, 0.6, 91.4) },
	{ "Nightclub", Vector3.new(-1194.6, 5.5, -75.8) },
	{ "Nightclub Safe", Vector3.new(-1169.9, -13.5, -118.2) },
	{ "Nightclub Drop", Vector3.new(-1305.3, 1.8, -191.5) },
	{ "Chase Bank", Vector3.new(-2367.2, 5.5, 100.6) },
	{ "Chase Safe", Vector3.new(-2324.1, 2.8, 131.7) },
	{ "Chase Drop", Vector3.new(-2369.0, 5.8, -20.2) },
	{ "ATM 1", Vector3.new(-1800.2, 0.2, -34.2) },
	{ "ATM 2", Vector3.new(-1900.1, 5.1, 103.2) },
	{ "ATM 3", Vector3.new(-1685.7, 2.5, 126.2) },
	{ "Card Clone", Vector3.new(-1531.1, 2.4, -309.5) },
	{ "Apartments / Check", Vector3.new(-2452.8, 110.3, -214.4) },
	{ "Check 2", Vector3.new(-2452.3, 109.8, -222.7) },
	{ "Check Cashout", Vector3.new(-2361.0, 5, 132.7) },
	{ "Diamond Heist", Vector3.new(-2352, -25, -752) },
	{ "Turf YGG", Vector3.new(-1642.4, 0.4, -537.0) },
	{ "Turf OP", Vector3.new(-1224.6, 0.5, 76.4) },
	{ "Turf EOK", Vector3.new(-2272.5, 2.1, -424.2) },
	{ "Turf STB", Vector3.new(-1832.1, 2.2, 561.7) },
	{ "Turf GM", Vector3.new(-1656.1, 2.1, 606.1) },
}

-- ── Anti AFK / server ──────────────────────────────────────────
local function setAntiAfk(on)
	S.toggles.antiAfk = on == true
	if not on then return end
	task.spawn(function()
		while S.toggles.antiAfk do
			pcall(function()
				local vu = game:GetService("VirtualUser")
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
			task.wait(60)
		end
	end)
end

-- ── KEY GATE ───────────────────────────────────────────────────
do
	local gui = Instance.new("ScreenGui")
	gui.Name = "VOIDZ_CALI_KEY"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 200000
	gui.Parent = pickGuiParent()
	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(340, 220)
	root.BackgroundColor3 = C.bg
	root.BorderSizePixel = 0
	root.Parent = gui
	corner(root, 16)
	stroke(root, C.accent, 1.4, 0.2)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 34)
	t.Position = UDim2.fromOffset(0, 22)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 20
	t.TextColor3 = C.accent2
	t.Text = "VOIDZ  CALI"
	t.Parent = root
	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Size = UDim2.new(1, 0, 0, 18)
	s.Position = UDim2.fromOffset(0, 56)
	s.Font = Enum.Font.Gotham
	s.TextSize = 12
	s.TextColor3 = C.muted
	s.Text = "Cali Shootout hub  ·  enter key"
	s.Parent = root
	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(220, 34)
	box.Position = UDim2.new(0.5, -110, 0, 90)
	box.BackgroundColor3 = C.card
	box.Text = ""
	box.PlaceholderText = "Key"
	box.PlaceholderColor3 = C.muted
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 14
	box.TextColor3 = C.text
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = root
	corner(box, 8)
	stroke(box, C.border, 1, 0.3)
	local err = Instance.new("TextLabel")
	err.BackgroundTransparency = 1
	err.Size = UDim2.new(1, 0, 0, 16)
	err.Position = UDim2.fromOffset(0, 128)
	err.Font = Enum.Font.Gotham
	err.TextSize = 11
	err.TextColor3 = C.danger
	err.Text = ""
	err.Parent = root
	local go = Instance.new("TextButton")
	go.Size = UDim2.fromOffset(220, 34)
	go.Position = UDim2.new(0.5, -110, 0, 152)
	go.BackgroundColor3 = C.accent
	go.Text = "Unlock"
	go.Font = Enum.Font.GothamBold
	go.TextSize = 14
	go.TextColor3 = C.text
	go.BorderSizePixel = 0
	go.Parent = root
	corner(go, 8)
	local ok = false
	local function submit()
		local k = tostring(box.Text or ""):gsub("%s+", "")
		if k:upper() == ACCESS_KEY then
			ok = true
			gui:Destroy()
		else
			err.Text = "Wrong key"
		end
	end
	go.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(e)
		if e then submit() end
	end)
	while not ok do task.wait(0.08) end
end

-- ── UI ─────────────────────────────────────────────────────────
pcall(function()
	local old = pickGuiParent():FindFirstChild("VOIDZ_CALI_HUB")
	if old then old:Destroy() end
end)

local screen = Instance.new("ScreenGui")
screen.Name = "VOIDZ_CALI_HUB"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
screen.Parent = pickGuiParent()

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(560, 560)
Main.Position = UDim2.new(0.5, -280, 0.5, -280)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = screen
corner(Main, 14)
stroke(Main, C.accent, 1.2, 0.25)

local glow = Instance.new("Frame")
glow.Size = UDim2.new(1, 0, 0, 3)
glow.BackgroundColor3 = C.accent
glow.BorderSizePixel = 0
glow.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.Position = UDim2.fromOffset(0, 3)
Header.BackgroundColor3 = C.bg2
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 26)
Title.Position = UDim2.fromOffset(14, 4)
Title.BackgroundTransparency = 1
Title.Text = HUB_NAME
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.TextColor3 = C.accent
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -50, 0, 14)
Sub.Position = UDim2.fromOffset(14, 28)
Sub.BackgroundTransparency = 1
Sub.Text = "Build " .. BUILD .. "  ·  RightShift hide"
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 10
Sub.TextColor3 = C.muted
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(26, 26)
CloseBtn.Position = UDim2.new(1, -36, 0, 12)
CloseBtn.BackgroundColor3 = C.danger
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = C.text
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
corner(CloseBtn, 8)
CloseBtn.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 32)
TabBar.Position = UDim2.fromOffset(8, 56)
TabBar.BackgroundColor3 = C.bg2
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
corner(TabBar, 8)

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1, -4, 1, -4)
TabScroll.Position = UDim2.fromOffset(2, 2)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 0
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
TabScroll.ScrollingDirection = Enum.ScrollingDirection.X
TabScroll.Parent = TabBar
local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 4)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Parent = TabScroll

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -100)
Content.Position = UDim2.fromOffset(8, 94)
Content.BackgroundColor3 = C.bg2
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = Main
corner(Content, 10)

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -8, 1, -8)
ContentScroll.Position = UDim2.fromOffset(4, 4)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = C.accent
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.Parent = Content
local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 4)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

local tabFrames = {}
local orderN = 0
local function n()
	orderN += 1
	return orderN
end

local function makeSection(parent, text)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 20)
	f.BackgroundTransparency = 1
	f.LayoutOrder = n()
	f.Parent = parent
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = string.upper(text)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextColor3 = C.accent
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = f
end

local function makeButton(parent, text, cb)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = C.card
	btn.Text = ""
	btn.BorderSizePixel = 0
	btn.LayoutOrder = n()
	btn.Parent = parent
	corner(btn, 6)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -12, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = C.text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = btn
	btn.MouseButton1Click:Connect(function()
		if cb then cb() end
	end)
end

local function makeToggle(parent, text, key, fn)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = C.card
	btn.Text = ""
	btn.BorderSizePixel = 0
	btn.LayoutOrder = n()
	btn.Parent = parent
	corner(btn, 6)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -56, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = C.text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = btn
	local ind = Instance.new("Frame")
	ind.Size = UDim2.fromOffset(36, 16)
	ind.Position = UDim2.new(1, -46, 0.5, -8)
	ind.BackgroundColor3 = C.danger
	ind.BorderSizePixel = 0
	ind.Parent = btn
	corner(ind, 8)
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(12, 12)
	dot.Position = UDim2.fromOffset(2, 2)
	dot.BackgroundColor3 = C.text
	dot.BorderSizePixel = 0
	dot.Parent = ind
	corner(dot, 6)
	local function paint()
		local on = S.toggles[key]
		ind.BackgroundColor3 = on and C.success or C.danger
		dot.Position = on and UDim2.new(1, -14, 0, 2) or UDim2.fromOffset(2, 2)
	end
	btn.MouseButton1Click:Connect(function()
		local on = not S.toggles[key]
		if fn then fn(on) else S.toggles[key] = on end
		paint()
	end)
	paint()
end

local function makeSlider(parent, text, min, max, getter, setter)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.BackgroundColor3 = C.card
	frame.BorderSizePixel = 0
	frame.LayoutOrder = n()
	frame.Parent = parent
	corner(frame, 6)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 0, 14)
	lbl.Position = UDim2.fromOffset(10, 5)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextColor3 = C.text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame
	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0.45, -10, 0, 14)
	val.Position = UDim2.new(0.55, 0, 0, 5)
	val.BackgroundTransparency = 1
	val.Text = tostring(getter())
	val.Font = Enum.Font.GothamBold
	val.TextSize = 11
	val.TextColor3 = C.accent2
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = frame
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 6)
	bar.Position = UDim2.fromOffset(10, 26)
	bar.BackgroundColor3 = C.border
	bar.BorderSizePixel = 0
	bar.Parent = frame
	corner(bar, 3)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp((getter() - min) / (max - min), 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = C.accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	corner(fill, 3)
	local dragging = false
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local r = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor(min + (max - min) * r)
			fill.Size = UDim2.new(r, 0, 1, 0)
			val.Text = tostring(v)
			setter(v)
		end
	end)
end

local function makeInput(parent, placeholder, cb)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 28)
	box.BackgroundColor3 = C.card
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = C.muted
	box.Text = ""
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextColor3 = C.text
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.LayoutOrder = n()
	box.Parent = parent
	corner(box, 6)
	box.FocusLost:Connect(function()
		if cb then cb(box.Text) end
	end)
	return box
end

local function createTab(name)
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.fromOffset(72, 28)
	tab.BackgroundColor3 = C.card
	tab.Text = ""
	tab.BorderSizePixel = 0
	tab.Parent = TabScroll
	corner(tab, 6)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextColor3 = C.muted
	lbl.Parent = tab
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = ContentScroll
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 3)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = frame
	tabFrames[name] = { frame = frame, tab = tab, lbl = lbl }
	tab.MouseButton1Click:Connect(function()
		for _, pack in pairs(tabFrames) do
			pack.frame.Visible = false
			pack.tab.BackgroundColor3 = C.card
			pack.lbl.TextColor3 = C.muted
		end
		frame.Visible = true
		tab.BackgroundColor3 = C.accent
		lbl.TextColor3 = C.text
	end)
	return frame
end

local home = createTab("Home")
local combat = createTab("Combat")
local guns = createTab("Guns")
local farm = createTab("Farm")
local move = createTab("Move")
local vis = createTab("Visuals")
local tps = createTab("TPs")
local ply = createTab("Players")
local misc = createTab("Misc")
tabFrames["Home"].frame.Visible = true
tabFrames["Home"].tab.BackgroundColor3 = C.accent
tabFrames["Home"].lbl.TextColor3 = C.text

-- HOME
makeSection(home, "VOIDZ CALI SHOOTOUT")
makeButton(home, "PlaceId " .. tostring(game.PlaceId), function() end)
makeButton(home, "Build " .. BUILD, function() end)
makeButton(home, "Key VOIDZHUB  ·  RightShift hide", function() end)
if game.PlaceId ~= PLACE_ID then
	makeButton(home, "Warning: this is not Cali Shootout PlaceId", function() end)
end
makeSection(home, "QUICK")
makeToggle(home, "Combat God (shoot while invincible)", "combatGod", setCombatGod)
makeToggle(home, "Silent Aim", "silentAim", function(on)
	S.toggles.silentAim = on
	if on then installSilentAim() end
end)
makeToggle(home, "ESP + wallet spy", "esp", setESP)

-- COMBAT
makeSection(combat, "SURVIVE")
makeToggle(combat, "Combat God — invincible + still shoot", "combatGod", setCombatGod)
makeToggle(combat, "Anti Ragdoll / KO flags", "antiRagdoll", function(on)
	S.toggles.antiRagdoll = on
	dropConn("antiRag")
	if not on then return end
	addConn("antiRag", RunService.Heartbeat:Connect(function()
		if not S.toggles.antiRagdoll then return end
		applyCombatGod(hum(), char())
	end))
end)
makeSection(combat, "AIM")
makeToggle(combat, "Silent Aim", "silentAim", function(on)
	S.toggles.silentAim = on
	if on then installSilentAim() notify(HUB_NAME, "Silent Aim ON", 1.2) end
end)
makeToggle(combat, "Hard Aimbot (camera)", "aimbot", setAimbot)
makeSlider(combat, "Silent FOV", 20, 360, function() return S.silentFov end, function(v) S.silentFov = v end)
makeSection(combat, "HITBOX / AURA")
makeToggle(combat, "Hitbox Expander", "hitbox", setHitboxes)
makeSlider(combat, "Hitbox Size", 2, 25, function() return S.hitboxSize end, function(v) S.hitboxSize = v end)
makeToggle(combat, "Kill Aura (look + fire)", "killAura", setKillAura)
makeSlider(combat, "Aura Range", 10, 250, function() return S.killRange end, function(v) S.killRange = v end)
makeButton(combat, "Kill All (TP + fire burst)", function()
	task.spawn(function()
		local homeCF = hrp() and hrp().CFrame
		for _, p in ipairs(Players:GetPlayers()) do
			if aliveP(p) then
				local r = p.Character.HumanoidRootPart
				tp(r.CFrame * CFrame.new(0, 0, 3))
				for _ = 1, 8 do
					fireGun()
					task.wait(0.05)
				end
			end
		end
		if homeCF then tp(homeCF) end
		notify(HUB_NAME, "Kill-all pass done", 1.4)
	end)
end)

-- GUNS
makeSection(guns, "GUN MODS")
makeToggle(guns, "No Recoil", "noRecoil", function(on) S.toggles.noRecoil = on end)
makeToggle(guns, "No Spread", "noSpread", function(on) S.toggles.noSpread = on end)
makeToggle(guns, "Infinite Ammo", "infAmmo", function(on) S.toggles.infAmmo = on end)
makeToggle(guns, "Never Jam", "noJam", function(on) S.toggles.noJam = on end)
makeToggle(guns, "Rapid Fire / no cooldown", "rapidFire", function(on) S.toggles.rapidFire = on end)
makeToggle(guns, "One Shot Damage", "oneShot", function(on) S.toggles.oneShot = on end)
addConn("guns", RunService.Heartbeat:Connect(function()
	if S.toggles.noRecoil or S.toggles.noSpread or S.toggles.infAmmo
		or S.toggles.noJam or S.toggles.rapidFire or S.toggles.oneShot then
		applyGunMods()
	end
end))

-- FARM
makeSection(farm, "AUTOFARM")
makeToggle(farm, "Instant Prompts", "instantPrompt", setInstantPrompt)
makeToggle(farm, "Auto Box / Crate", "farmBox", function(on)
	if on then startFarm("farmBox", { "box", "crate", "package", "parcel" }) else stopFarm("farmBox") end
end)
makeToggle(farm, "Auto Garbage / Trash", "farmTrash", function(on)
	if on then startFarm("farmTrash", { "trash", "garbage", "bag", "dump" }) else stopFarm("farmTrash") end
end)
makeToggle(farm, "Auto Janitor / Mop / Clean", "farmMop", function(on)
	if on then startFarm("farmMop", { "mop", "clean", "janitor", "spill" }) else stopFarm("farmMop") end
end)
makeToggle(farm, "Auto Car Rob / Lockpick", "farmCar", function(on)
	if on then startFarm("farmCar", { "car", "lock", "steal", "vehicle", "hotwire" }) else stopFarm("farmCar") end
end)
makeToggle(farm, "Auto Grass / Leaf", "farmGrass", function(on)
	if on then startFarm("farmGrass", { "grass", "leaf", "weed", "plant" }) else stopFarm("farmGrass") end
end)
makeSection(farm, "CHECK PRINTER")
makeButton(farm, "TP Check 1", function() tp(CFrame.new(-2397.8, 109.8, -220.8)) end)
makeButton(farm, "TP Check 2", function() tp(CFrame.new(-2452.3, 109.8, -222.7)) end)
makeButton(farm, "TP Check Cashout", function() tp(CFrame.new(-2361, 5, 132.7)) end)

-- MOVE
makeSection(move, "MOVEMENT")
makeToggle(move, "WalkSpeed Override", "speed", setSpeedLoop)
makeSlider(move, "WalkSpeed", 16, 200, function() return S.walkSpeed end, function(v)
	S.walkSpeed = v
	local h = hum()
	if h then h.WalkSpeed = v end
end)
makeToggle(move, "Fly (WASD Space/Shift)", "fly", setFly)
makeSlider(move, "Fly Speed", 20, 250, function() return S.flySpeed end, function(v) S.flySpeed = v end)
makeToggle(move, "Noclip", "noclip", setNoclip)
makeToggle(move, "Infinite Jump", "infJump", setInfJump)
makeToggle(move, "Ctrl + Click TP", "ctrlTp", function(on)
	S.toggles.ctrlTp = on
end)
addConn("ctrlTp", Mouse.Button1Down:Connect(function()
	if not S.toggles.ctrlTp then return end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		tp(CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)))
	end
end))

-- VISUALS
makeSection(vis, "ESP")
makeToggle(vis, "Player ESP (name / hp / cash / dist)", "esp", setESP)
makeToggle(vis, "Fullbright", "fullbright", setFullbright)

-- TPS
makeSection(tps, "CALI MAP")
for _, row in ipairs(TPS) do
	local name, pos = row[1], row[2]
	makeButton(tps, name, function() tp(CFrame.new(pos + Vector3.new(0, 3, 0))) end)
end

-- PLAYERS
makeSection(ply, "TARGET")
local searchBox
searchBox = makeInput(ply, "Name / display", function(text)
	text = tostring(text or ""):lower()
	S.selected = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and (p.Name:lower():find(text, 1, true) or p.DisplayName:lower():find(text, 1, true)) then
			S.selected = p
			notify(HUB_NAME, "Selected " .. p.Name, 1.2)
			break
		end
	end
end)
makeButton(ply, "TP to selected", function()
	local p = S.selected
	if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		tp(p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
	else
		notify(HUB_NAME, "No player selected", 1.2)
	end
end)
makeButton(ply, "Spectate selected", function()
	local p = S.selected
	if p and p.Character then
		local h = p.Character:FindFirstChildOfClass("Humanoid")
		if h then Camera.CameraSubject = h end
	end
end)
makeButton(ply, "Unspectate", function()
	local h = hum()
	if h then Camera.CameraSubject = h end
end)

-- MISC
makeSection(misc, "SERVER")
makeToggle(misc, "Anti AFK", "antiAfk", setAntiAfk)
makeButton(misc, "Rejoin", function()
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
end)
makeButton(misc, "Server hop", function()
	pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
end)
makeSection(misc, "CLEAN")
makeButton(misc, "Unload all", function()
	setCombatGod(false)
	setAimbot(false)
	setHitboxes(false)
	setKillAura(false)
	setNoclip(false)
	setFly(false)
	setInfJump(false)
	setSpeedLoop(false)
	setESP(false)
	setFullbright(false)
	setInstantPrompt(false)
	setAntiAfk(false)
	for k in pairs(S.toggles) do S.toggles[k] = false end
	notify(HUB_NAME, "Unloaded", 1.4)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		screen.Enabled = not screen.Enabled
	end
end)

notify(HUB_NAME, "Loaded " .. BUILD .. "  ·  Combat God keeps you shooting", 3)
print("[VOIDZ CALI] " .. BUILD .. "  -- hi im voidz")
