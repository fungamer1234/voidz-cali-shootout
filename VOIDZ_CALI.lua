--[[
  VOIDZ HUB — Cali Shootout
  Build 2026-08-23-1.4.1  |  Key: VOIDZHUB  |  RightShift toggle
  Places: 12077443856 (main) + 16940099758 (Voice Chat)
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

local HUB_NAME = "VOIDZ"
local BUILD = "2026-08-23-1.4.1"
local ACCESS_KEY = "VOIDZHUB"
local CALI_UNIVERSE = 4263576532
local PLACE_MAIN = 12077443856
local PLACE_VC = 16940099758

-- Same Purple glass as VOIDZ HUB (FTAP)
local C = {
	bg = Color3.fromRGB(12, 8, 24), bg2 = Color3.fromRGB(22, 14, 42),
	card = Color3.fromRGB(36, 26, 62), card2 = Color3.fromRGB(52, 38, 88),
	stroke = Color3.fromRGB(168, 108, 255), strokeSoft = Color3.fromRGB(92, 68, 140),
	accent = Color3.fromRGB(186, 132, 255), accent2 = Color3.fromRGB(230, 196, 255),
	accentDim = Color3.fromRGB(78, 48, 132), text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(214, 206, 236), danger = Color3.fromRGB(72, 24, 42),
	dangerText = Color3.fromRGB(255, 168, 186), dangerStroke = Color3.fromRGB(230, 90, 130),
	success = Color3.fromRGB(110, 240, 180), warn = Color3.fromRGB(255, 214, 120),
	black = Color3.fromRGB(0, 0, 0), tip = Color3.fromRGB(20, 14, 36),
}

local function isCaliPlace()
	if tonumber(game.GameId) == CALI_UNIVERSE then return true end
	local pid = tonumber(game.PlaceId)
	return pid == PLACE_MAIN or pid == PLACE_VC
end
local function isVoiceServer()
	return tonumber(game.PlaceId) == PLACE_VC
		or tostring(game.PlaceId) == tostring(PLACE_VC)
end

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
	espNameColor = Color3.new(1, 1, 1),
	espBoxColor = Color3.new(1, 1, 1),
	espDistColor = Color3.new(1, 1, 1),
	espHpColor = Color3.fromRGB(80, 255, 130),
	espChamsColor = Color3.new(1, 1, 1),
	camFov = 90,
	carAccel = 0.04,
	carSpeed = 180,
	carFlySpeed = 90,
	godCF = nil,
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
	s.Color = col or C.strokeSoft
	s.Thickness = th or 1
	s.Transparency = tr ~= nil and tr or 0.35
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = i
	return s
end
local function pad(i, a, b, c, d)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, a or 8)
	p.PaddingRight = UDim.new(0, b or 8)
	p.PaddingBottom = UDim.new(0, c or 8)
	p.PaddingLeft = UDim.new(0, d or 8)
	p.Parent = i
	return p
end
local function mix3(a, b, t)
	t = tonumber(t) or 0.5
	a, b = a or Color3.new(), b or Color3.new()
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
local function glass(i)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, mix3(C.accent, C.card2, 0.45)),
		ColorSequenceKeypoint.new(0.5, C.card2),
		ColorSequenceKeypoint.new(1, C.card),
	})
	g.Rotation = 22
	g.Parent = i
	return g
end
local function panelWash(i)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, mix3(C.accent, C.bg2, 0.42)),
		ColorSequenceKeypoint.new(1, C.bg2),
	})
	g.Rotation = 8
	g.Parent = i
	return g
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
	if typeof(cf) ~= "CFrame" then
		cf = CFrame.new(cf)
	end
	local c = char()
	if not c then return end
	pcall(function()
		if c.PivotTo then
			c:PivotTo(cf)
		elseif c.PrimaryPart then
			c:SetPrimaryPartCFrame(cf)
		else
			local r = c:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = cf end
		end
	end)
end

local function firePrompt(pr)
	if not pr then return end
	pcall(function()
		pr.HoldDuration = 0
		pr.MaxActivationDistance = math.max(pr.MaxActivationDistance, 20)
	end)
	local fired = false
	pcall(function()
		if type(fireproximityprompt) == "function" then
			fireproximityprompt(pr)
			fired = true
		end
	end)
	if not fired then
		pcall(function()
			pr:InputHoldBegin()
			task.wait(0.05)
			pr:InputHoldEnd()
		end)
	end
end

local function zeroAllPrompts()
	pcall(function()
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ProximityPrompt") then
				v.HoldDuration = 0
			end
		end
	end)
end

local function equipNamed(name)
	local c = char()
	local bp = LP:FindFirstChildOfClass("Backpack")
	if not c or not bp then return end
	name = tostring(name):lower()
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") and t.Name:lower() == name then
			pcall(function() t.Parent = c end)
		end
	end
end

local function childPath(root, ...)
	local n = root
	for i = 1, select("#", ...) do
		if not n then return nil end
		n = n:FindFirstChild(select(i, ...))
	end
	return n
end

local function promptIn(inst)
	if not inst then return nil end
	if inst:IsA("ProximityPrompt") then return inst end
	return inst:FindFirstChildOfClass("ProximityPrompt")
		or inst:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function pickGuiParent()
	local hui
	pcall(function()
		if type(gethui) == "function" then hui = gethui() end
	end)
	if hui then return hui end
	local ok, cg = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

pcall(function()
	local q = (type(queue_on_teleport) == "function" and queue_on_teleport)
		or (syn and (syn.queue_on_teleport or syn.queue_on_teleport))
	if type(q) == "function" then
		q([[loadstring(game:HttpGet("https://raw.githubusercontent.com/fungamer1234/voidz-cali-shootout/main/VOIDZ_CALI.lua", true))()]])
	end
end)
pcall(function()
	game:GetService("VoiceChatService")
end)

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

-- ── Combat God (FE humanoid clone + health/armor refill) ───────
-- Cali damage is server-sided. Setting Humanoid.Health locally does nothing.
-- Clone-god (Infinite Yield style): server kills the old Humanoid, you keep
-- a new one named "Humanoid" so tools still shoot.
local function refillVitals(c, h)
	if h then
		pcall(function()
			h.BreakJointsOnDeath = false
			h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			h:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
			h.MaxHealth = math.max(h.MaxHealth, 100)
			h.Health = h.MaxHealth
			h.PlatformStand = false
		end)
	end
	if not c then return end
	pcall(function()
		for _, d in ipairs(c:GetDescendants()) do
			local n = d.Name:lower()
			if d:IsA("NumberValue") or d:IsA("IntValue") then
				if n == "health" or n == "hp" or n == "armor" or n == "shield" or n == "stam" or n == "stamina" then
					local mx = d.Parent and (d.Parent:FindFirstChild("Max" .. d.Name) or d.Parent:FindFirstChild("max" .. d.Name))
					d.Value = mx and mx.Value or math.max(tonumber(d.Value) or 0, 100)
				end
			elseif d:IsA("BoolValue") and (n == "downed" or n == "knocked" or n == "ragdolled" or n == "dead" or n == "ko" or n == "stunned") then
				d.Value = false
			end
		end
		for _, a in ipairs({ "Downed", "Knocked", "Ragdolled", "Stunned", "Dead", "KO", "Health", "Armor" }) do
			local v = c:GetAttribute(a)
			if v == true then c:SetAttribute(a, false) end
			if type(v) == "number" and v < 100 then c:SetAttribute(a, 100) end
			v = LP:GetAttribute(a)
			if v == true then LP:SetAttribute(a, false) end
		end
	end)
end

local function ensureForceField(c)
	if not c then return end
	local ff = c:FindFirstChildOfClass("ForceField")
	if not ff then
		ff = Instance.new("ForceField")
		ff.Name = "VOIDZ_FF"
		ff.Visible = false
		ff.Parent = c
	end
	ff.Visible = false
end

-- Ghost gun: keep the Tool equipped (so Activate still fires) but the
-- game never draws the mesh — same look as the Cali clip (gun in hands, invisible).
local ghostOrig = {}
local function ghostOne(d)
	pcall(function()
		if d:IsA("BasePart") then
			if ghostOrig[d] == nil then
				ghostOrig[d] = { t = d.Transparency, l = d.LocalTransparencyModifier }
			end
			d.Transparency = 1
			d.LocalTransparencyModifier = 1
		elseif d:IsA("Decal") or d:IsA("Texture") then
			if ghostOrig[d] == nil then ghostOrig[d] = { t = d.Transparency } end
			d.Transparency = 1
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
			or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
			d.Enabled = false
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			d.Enabled = false
		end
	end)
end

local function ghostGunVisuals(c)
	c = c or char()
	if not c then return end
	for _, tool in ipairs(c:GetChildren()) do
		if tool:IsA("Tool") then
			for _, d in ipairs(tool:GetDescendants()) do
				ghostOne(d)
			end
		end
	end
end

local function restoreGhostGuns()
	for inst, o in pairs(ghostOrig) do
		pcall(function()
			if inst and inst.Parent then
				if o.t ~= nil and inst.Transparency then inst.Transparency = o.t end
				if o.l ~= nil and inst.LocalTransparencyModifier then
					inst.LocalTransparencyModifier = o.l
				end
			end
		end)
	end
	ghostOrig = {}
end

local function keepToolEquipped(c)
	c = c or char()
	if not c then return end
	if c:FindFirstChildOfClass("Tool") then return end
	local bp = LP:FindFirstChildOfClass("Backpack")
	if not bp then return end
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") then
			pcall(function() t.Parent = c end)
			break
		end
	end
end

local function applyCombatGod(h, c)
	c = c or char()
	h = h or (c and c:FindFirstChildOfClass("Humanoid"))
	ensureForceField(c)
	refillVitals(c, h)
	keepToolEquipped(c)
	ghostGunVisuals(c)
	if h then
		pcall(function()
			h.TakeDamage = function() end
		end)
	end
end

local godHooksOn = false
local function installGodHooks()
	if godHooksOn then return end
	godHooksOn = true
	pcall(function()
		local hmm = hookmetamethod or (syn and syn.hook_metamethod)
		if type(hmm) ~= "function" then return end
		local ncm = getnamecallmethod or (debug and debug.getinfo)
		local old
		old = hmm(game, "__namecall", function(self, ...)
			local method = ""
			pcall(function()
				method = (getnamecallmethod and getnamecallmethod()) or ""
			end)
			if S.toggles.combatGod and (method == "TakeDamage" or method == "takeDamage") then
				return
			end
			return old(self, ...)
		end)
	end)
	pcall(function()
		local hmm = hookmetamethod or (syn and syn.hook_metamethod)
		if type(hmm) ~= "function" then return end
		local old
		old = hmm(game, "__newindex", function(self, k, v)
			if S.toggles.combatGod and typeof(self) == "Instance" and self:IsA("Humanoid")
				and self:IsDescendantOf(LP.Character or self) then
				if k == "Health" and type(v) == "number" and v < (self.MaxHealth or 100) then
					v = self.MaxHealth or 100
				end
			end
			return old(self, k, v)
		end)
	end)
end

local function setCombatGod(on)
	S.toggles.combatGod = on == true
	dropConn("combatGodHB")
	dropConn("combatGodStep")
	dropConn("combatGodDied")
	if not on then
		restoreGhostGuns()
		local c = char()
		if c then
			local ff = c:FindFirstChild("VOIDZ_FF")
			if ff then pcall(function() ff:Destroy() end) end
		end
		notify(HUB_NAME, "Combat God OFF", 1.2)
		return
	end
	notify(HUB_NAME, "Combat God ON — ForceField + health lock + ghost gun", 2)
	installGodHooks()
	applyCombatGod(hum(), char())
	pcall(function()
		local hf = hookfunction
		local h = hum()
		if type(hf) == "function" and h and h.TakeDamage then
			hf(h.TakeDamage, function() end)
		end
	end)
	local h = hum()
	if h then
		addConn("combatGodDied", h.Died:Connect(function()
			if not S.toggles.combatGod then return end
			S.godCF = hrp() and hrp().CFrame
		end))
	end
	if not S._godCharHook then
		S._godCharHook = true
		LP.CharacterAdded:Connect(function(c)
			if not S.toggles.combatGod then return end
			local cf = S.godCF
			task.defer(function()
				local r = c:WaitForChild("HumanoidRootPart", 4)
				local nh = c:WaitForChild("Humanoid", 4)
				if cf and r then pcall(function() r.CFrame = cf end) end
				applyCombatGod(nh, c)
			end)
		end)
	end
	addConn("combatGodHB", RunService.Heartbeat:Connect(function()
		if not S.toggles.combatGod then return end
		local c, h = char(), hum()
		if hrp() then S.godCF = hrp().CFrame end
		applyCombatGod(h, c)
	end))
	addConn("combatGodStep", RunService.Stepped:Connect(function()
		if not S.toggles.combatGod then return end
		local c = char()
		if not c then return end
		ensureForceField(c)
		keepToolEquipped(c)
		ghostGunVisuals(c)
		local h = hum()
		if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
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
		local n = (obj.Name or ""):lower()
		pcall(function()
			if obj.GetAttribute then
				for _, k in ipairs(GUN_KEYS) do
					local v = obj:GetAttribute(k)
					if v ~= nil then
						if S.toggles.noRecoil and (k:lower():find("recoil") or k:lower():find("shake") or k:lower():find("bloom")) then
							obj:SetAttribute(k, 0)
						elseif S.toggles.noSpread and k:lower():find("spread") then
							obj:SetAttribute(k, 0)
						elseif S.toggles.noSpread and k:lower():find("accuracy") then
							obj:SetAttribute(k, 1)
						elseif S.toggles.infAmmo and (k:lower():find("ammo") or k:lower():find("clip") or k:lower():find("mag")) then
							obj:SetAttribute(k, 999)
						elseif S.toggles.rapidFire and (k:lower():find("cool") or k:lower():find("delay") or k:lower():find("debounce")) then
							obj:SetAttribute(k, 0)
						elseif S.toggles.oneShot and k:lower():find("damage") then
							obj:SetAttribute(k, 9e4)
						end
					end
				end
			end
		end)
		if not (obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("BoolValue")) then return end
		if S.toggles.noRecoil and (n:find("recoil") or n:find("shake") or n:find("bloom") or n:find("kick") or n:find("cam")) then
			obj.Value = 0
		end
		if S.toggles.noSpread then
			if n:find("spread") or n:find("bloom") then obj.Value = 0
			elseif n:find("accuracy") then obj.Value = typeof(obj.Value) == "number" and 1 or obj.Value
			end
		end
		if S.toggles.infAmmo and (n:find("ammo") or n:find("clip") or n:find("mag") or n:find("bullet") or n:find("round")) then
			if typeof(obj.Value) == "number" and obj.Value < 999 then obj.Value = 999 end
		end
		if S.toggles.noJam and n:find("jam") then
			obj.Value = typeof(obj.Value) == "boolean" and false or 0
		end
		if S.toggles.rapidFire then
			if n:find("cooldown") or n:find("debounce") or n:find("delay") or n:find("firerate") or n:find("rpm") then
				if n:find("rate") or n:find("rpm") then
					if typeof(obj.Value) == "number" then obj.Value = math.max(obj.Value, 30) end
				else
					obj.Value = 0
				end
			end
		end
		if S.toggles.oneShot and n:find("damage") then
			obj.Value = 9e4
		end
	end)
	if S.toggles.noRecoil then
		local h = hum()
		if h then pcall(function() h.CameraOffset = Vector3.zero end) end
	end
end

local function patchGunTables()
	pcall(function()
		local gc = getgc or debug and debug.getregistry
		if type(getgc) ~= "function" then return end
		for _, v in ipairs(getgc(true)) do
			if type(v) == "table" then
				pcall(function()
					if S.toggles.noRecoil then
						if v.Recoil ~= nil then v.Recoil = 0 end
						if v.recoil ~= nil then v.recoil = 0 end
						if v.CameraShake ~= nil then v.CameraShake = 0 end
						if v.Kick ~= nil then v.Kick = 0 end
					end
					if S.toggles.noSpread then
						if v.Spread ~= nil then v.Spread = 0 end
						if v.spread ~= nil then v.spread = 0 end
						if v.Bloom ~= nil then v.Bloom = 0 end
					end
					if S.toggles.infAmmo then
						if type(v.Ammo) == "number" then v.Ammo = 999 end
						if type(v.ammo) == "number" then v.ammo = 999 end
						if type(v.Clip) == "number" then v.Clip = 999 end
						if type(v.Mag) == "number" then v.Mag = 999 end
					end
					if S.toggles.rapidFire then
						if v.FireRate ~= nil then v.FireRate = 0.02 end
						if v.Cooldown ~= nil then v.Cooldown = 0 end
						if v.Delay ~= nil then v.Delay = 0 end
						if v.Debounce ~= nil then v.Debounce = 0 end
					end
					if S.toggles.oneShot then
						if type(v.Damage) == "number" then v.Damage = 9e4 end
					end
				end)
			end
		end
	end)
end

local lastCamLook
addConn("gunCam", RunService.RenderStepped:Connect(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if S.toggles.noRecoil then
		local h = hum()
		if h then h.CameraOffset = Vector3.zero end
		if lastCamLook then
			local look = cam.CFrame.LookVector
			if math.abs(look.Y - lastCamLook.Y) > 0.012 then
				local dir = Vector3.new(look.X, lastCamLook.Y, look.Z)
				if dir.Magnitude > 0.05 then
					cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir)
				end
			end
		end
	end
	lastCamLook = cam.CFrame.LookVector
	if S.toggles.rapidFire and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		local c = char()
		local tool = c and c:FindFirstChildOfClass("Tool")
		if tool then pcall(function() tool:Activate() end) end
	end
end))

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
		local holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			or UserInputService:IsKeyDown(Enum.KeyCode.E)
		if not holding then return end
		local t = closestInFov()
		if not t or not t.Character then return end
		local part = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
		if part then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
		end
	end))
end

local function setTriggerbot(on)
	S.toggles.triggerbot = on == true
	dropConn("trigger")
	if not on then return end
	addConn("trigger", RunService.RenderStepped:Connect(function()
		if not S.toggles.triggerbot then return end
		local tgt = Mouse.Target
		if not tgt then return end
		local model = tgt.Parent
		local pl = model and Players:GetPlayerFromCharacter(model)
		if not pl then
			pl = model and model.Parent and Players:GetPlayerFromCharacter(model.Parent)
		end
		if pl and pl ~= LP and aliveP(pl) then
			fireGun()
		end
	end))
end

-- ── Hitboxes (Express: HRP only, loop 0.1s) ───────────────────
local hitboxOrig = {}
local function setHitboxes(on)
	S.toggles.hitbox = on == true
	dropConn("hitbox")
	if not on then
		for part, sz in pairs(hitboxOrig) do
			pcall(function()
				if part and part.Parent then
					part.Size = sz
					part.Transparency = 0
					part.CanCollide = true
				end
			end)
		end
		hitboxOrig = {}
		return
	end
	addConn("hitbox", RunService.Heartbeat:Connect(function()
		if not S.toggles.hitbox then return end
		local sz = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local part = p.Character:FindFirstChild("HumanoidRootPart")
				if part and part:IsA("BasePart") then
					if not hitboxOrig[part] then hitboxOrig[part] = part.Size end
					part.Size = sz
					part.Transparency = 0.7
					part.CanCollide = false
				end
			end
		end
	end))
end

-- ── Kill aura ──────────────────────────────────────────────────
local function fireGun()
	local c = char()
	if c then
		local tool = c:FindFirstChildOfClass("Tool")
		if tool then pcall(function() tool:Activate() end) end
	end
	pcall(function()
		if mouse1click then mouse1click() return end
	end)
	pcall(function()
		VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
		task.wait()
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
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end))
end

local function setFly(on)
	S.toggles.fly = on == true
	dropConn("fly")
	if not on then return end
	addConn("fly", RunService.RenderStepped:Connect(function(dt)
		if not S.toggles.fly then return end
		local r = hrp()
		if not r then return end
		local cam = Workspace.CurrentCamera
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
		pcall(function()
			r.AssemblyLinearVelocity = Vector3.zero
			if dir.Magnitude > 0.05 then
				r.CFrame = CFrame.new(r.Position + dir.Unit * (S.flySpeed or 80) * math.max(dt, 1 / 60)) * (cam.CFrame - cam.CFrame.Position)
			else
				r.CFrame = CFrame.new(r.Position) * (cam.CFrame - cam.CFrame.Position)
			end
		end)
	end))
end

local function getCarSeat()
	local h = hum()
	local seat = h and h.SeatPart
	if seat and seat:IsA("VehicleSeat") then return seat end
	return nil
end

local function getCarModel(seat)
	seat = seat or getCarSeat()
	if not seat then return nil end
	return seat:FindFirstAncestor(LP.Name .. "'s Car")
		or (seat:FindFirstAncestor("Body") and seat:FindFirstAncestor("Body").Parent)
		or seat:FindFirstAncestorWhichIsA("Model")
end

local function setCarAccel(on)
	S.toggles.carAccel = on == true
	dropConn("carAccel")
	if not on then return end
	addConn("carAccel", RunService.Heartbeat:Connect(function()
		if not S.toggles.carAccel then return end
		local seat = getCarSeat()
		if not seat then return end
		pcall(function()
			seat.MaxSpeed = S.carSpeed or 180
			seat.Torque = 1e5
			seat.TurnSpeed = math.max(seat.TurnSpeed, 2)
		end)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			local m = 1 + (S.carAccel or 0.04)
			local vel = seat.AssemblyLinearVelocity
			seat.AssemblyLinearVelocity = Vector3.new(vel.X * m, vel.Y, vel.Z * m)
		end
	end))
end

local function setCarFly(on)
	S.toggles.carFly = on == true
	dropConn("carFly")
	if not on then return end
	addConn("carFly", RunService.RenderStepped:Connect(function()
		if not S.toggles.carFly then return end
		local seat = getCarSeat()
		if not seat then return end
		local cam = Workspace.CurrentCamera
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
		if dir.Magnitude > 0.05 then
			seat.AssemblyLinearVelocity = dir.Unit * (S.carFlySpeed or 90)
		end
	end))
end

local function setInfJump(on)
	S.toggles.infJump = on == true
	dropConn("infJump")
	if not on then return end
	addConn("infJump", UserInputService.JumpRequest:Connect(function()
		if not S.toggles.infJump then return end
		local h = hum()
		local r = hrp()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		if r then r.Velocity = Vector3.new(r.Velocity.X, 50, r.Velocity.Z) end
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

-- ── Instant prompts + farms (Express Hub Job System paths) ─────
local function setInstantPrompt(on)
	S.toggles.instantPrompt = on == true
	dropConn("prompt")
	dropConn("promptAdd")
	if not on then return end
	zeroAllPrompts()
	addConn("promptAdd", Workspace.DescendantAdded:Connect(function(d)
		if S.toggles.instantPrompt and d:IsA("ProximityPrompt") then
			d.HoldDuration = 0
		end
	end))
	addConn("prompt", ProximityPromptService.PromptButtonHoldBegan:Connect(function(pr)
		if S.toggles.instantPrompt then
			pr.HoldDuration = 0
			firePrompt(pr)
		end
	end))
	task.spawn(function()
		while S.toggles.instantPrompt do
			zeroAllPrompts()
			task.wait(1)
		end
	end)
end

local function fireJob(folderNames)
	local jobs = Workspace:FindFirstChild("Job System")
	if not jobs then return false end
	local n = jobs
	for _, name in ipairs(folderNames) do
		n = n and n:FindFirstChild(name)
	end
	local pr = promptIn(n)
	if pr then
		firePrompt(pr)
		return true
	end
	return false
end

local function startFarm(id, runner)
	S.toggles[id] = true
	task.spawn(function()
		while S.toggles[id] do
			pcall(runner)
			task.wait(0.15)
		end
	end)
end
local function stopFarm(id)
	S.toggles[id] = false
end

local function farmBoxTick()
	zeroAllPrompts()
	tp(CFrame.new(-1943.448, 3.408, -48.731))
	task.wait(0.15)
	fireJob({ "BoxPickingJob", "BOX1" })
	equipNamed("BOX")
	task.wait(0.25)
	tp(CFrame.new(-1925.296, 3.108, -22.599))
	task.wait(0.35)
	equipNamed("BOX")
	-- drop-off prompt near second pad
	pcall(function()
		local job = childPath(Workspace, "Job System", "BoxPickingJob")
		if job then
			for _, d in ipairs(job:GetDescendants()) do
				if d:IsA("ProximityPrompt") then firePrompt(d) end
			end
		end
	end)
end

local function farmTrashTick()
	zeroAllPrompts()
	tp(CFrame.new(-1384.322, 3.408, 24.332))
	task.wait(0.15)
	fireJob({ "GarbageJob", "BOX1" })
	equipNamed("Garbage")
	task.wait(0.25)
	tp(CFrame.new(-1409.782, 3.384, 28.312))
	task.wait(0.35)
	equipNamed("Garbage")
	pcall(function()
		local job = childPath(Workspace, "Job System", "GarbageJob")
		if job then
			for _, d in ipairs(job:GetDescendants()) do
				if d:IsA("ProximityPrompt") then firePrompt(d) end
			end
		end
	end)
end

local function farmMopTick()
	pcall(function()
		local r = game:GetService("ReplicatedStorage"):FindFirstChild("giveMop")
		if r then r:FireServer() end
	end)
	equipNamed("Mop")
	local dirt = childPath(Workspace, "Cleaning_System", "Dirt_Spawn")
	if not dirt then
		tp(CFrame.new(-1655.082, 3.508, 42.390))
		task.wait(0.4)
		dirt = childPath(Workspace, "Cleaning_System", "Dirt_Spawn")
	end
	if not dirt then return end
	for _, d in ipairs(dirt:GetDescendants()) do
		if not S.toggles.farmMop then return end
		if d:IsA("ProximityPrompt") then
			local part = d.Parent
			if part and part:IsA("BasePart") then
				tp(part.CFrame + Vector3.new(0, 3, 0))
				task.wait(0.2)
			end
			firePrompt(d)
			task.wait(0.15)
		end
	end
end

local function farmCarTick()
	local folder = Workspace:FindFirstChild("CarRobberys") or Workspace:FindFirstChild("CarRobberies")
	if not folder then return end
	for _, d in ipairs(folder:GetDescendants()) do
		if not S.toggles.farmCar then return end
		if d:IsA("ProximityPrompt") then
			local part = d.Parent
			if part and part:IsA("BasePart") then
				tp(CFrame.new(part.Position + Vector3.new(0, 3, 0)))
				task.wait(0.35)
			end
			firePrompt(d)
			task.wait(0.4)
		end
	end
end

local GRASS_CFS = {
	CFrame.new(-1989.464, 6.795, 182.809),
	CFrame.new(-1981.864, 6.795, 182.809),
	CFrame.new(-1985.765, 6.795, 182.809),
	CFrame.new(-1975.265, 6.795, 182.809),
	CFrame.new(-1967.664, 6.795, 182.809),
	CFrame.new(-1971.565, 6.795, 182.809),
}
local GRASS_SELL = CFrame.new(-2005.133, 3.490, 196.952)

local function firePromptAt(cf)
	tp(cf)
	task.wait(0.12)
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and (part.Position - cf.Position).Magnitude < 4 then
			local pr = part:FindFirstChildOfClass("ProximityPrompt")
			if pr then firePrompt(pr) end
		end
	end
end

local function farmGrassTick()
	for _, cf in ipairs(GRASS_CFS) do
		if not S.toggles.farmGrass then return end
		equipNamed("Grass")
		firePromptAt(cf)
		task.wait(0.35)
		equipNamed("Grass")
		firePromptAt(GRASS_SELL)
		task.wait(0.35)
	end
end

local CHECK_CFS = {
	CFrame.new(-2405.317, 3.408, -42.879),
	CFrame.new(-2454.812, 109.807, -218.502),
	CFrame.new(-2450.308, 109.807, -218.224),
	CFrame.new(-2358.493, 3.536, 131.445),
}

local function farmCheckTick()
	zeroAllPrompts()
	tp(CHECK_CFS[1])
	task.wait(0.4)
	local prompts = {
		childPath(Workspace, "OtherItems", "CheckTable", "CloneC", "ProximityPrompt1"),
		childPath(Workspace, "OtherItems", "CheckTable", "ActivateC", "ProximityPrompt2"),
	}
	pcall(function()
		local oi = Workspace:FindFirstChild("OtherItems")
		if oi then
			for _, d in ipairs(oi:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					local blob = (d.Name .. " " .. (d.Parent and d.Parent.Name or "")):lower()
					if blob:find("vender") or blob:find("vendor") or blob:find("check") then
						prompts[#prompts + 1] = d
					end
				end
			end
		end
	end)
	for i, pr in ipairs(prompts) do
		if not S.toggles.farmCheck then return end
		local cf = CHECK_CFS[math.min(i + 1, #CHECK_CFS)]
		tp(cf)
		task.wait(0.25)
		firePrompt(pr)
		task.wait(0.5)
	end
end

-- ── ESP (Express Hub: name / box / distance / health / chams) ──
local nameDrawings = {}
local boxAdorns = {}
local distGuis = {}
local hpGuis = {}

local hasDrawing = false
pcall(function()
	hasDrawing = Drawing ~= nil and type(Drawing.new) == "function"
end)

local function destroyNameESP()
	for _, d in pairs(nameDrawings) do
		pcall(function()
			if d.Remove then d:Remove() else d:Destroy() end
		end)
	end
	nameDrawings = {}
end

local function setNameESP(on)
	S.toggles.espName = on == true
	dropConn("espName")
	destroyNameESP()
	if not on then return end
	addConn("espName", RunService.RenderStepped:Connect(function()
		if not S.toggles.espName then return end
		local cam = Workspace.CurrentCamera
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local head = p.Character:FindFirstChild("Head")
				local hrpP = p.Character:FindFirstChild("HumanoidRootPart")
				local part = head or hrpP
				if part then
					local v, onScreen = cam:WorldToViewportPoint(part.Position)
					local d = nameDrawings[p]
					if hasDrawing then
						if not d then
							d = Drawing.new("Text")
							d.Size = 14
							d.Center = true
							d.Outline = true
							d.Transparency = 0.15
							nameDrawings[p] = d
						end
						d.Text = p.Name
						d.Color = S.espNameColor
						d.Position = Vector2.new(v.X, v.Y - 25)
						d.Visible = onScreen
					else
						if not d or not d.Parent then
							d = Instance.new("BillboardGui")
							d.Name = "VOIDZ_NameESP"
							d.Size = UDim2.fromOffset(120, 18)
							d.AlwaysOnTop = true
							d.StudsOffset = Vector3.new(0, 2.4, 0)
							local tl = Instance.new("TextLabel")
							tl.BackgroundTransparency = 1
							tl.Size = UDim2.fromScale(1, 1)
							tl.Font = Enum.Font.GothamBold
							tl.TextSize = 12
							tl.TextStrokeTransparency = 0.4
							tl.Parent = d
							d.Parent = part
							nameDrawings[p] = d
						end
						local tl = d:FindFirstChildOfClass("TextLabel")
						if tl then
							tl.Text = p.Name
							tl.TextColor3 = S.espNameColor
						end
						if d.Parent ~= part then d.Parent = part end
					end
				end
			elseif nameDrawings[p] then
				pcall(function()
					local d = nameDrawings[p]
					if d.Remove then d:Remove() elseif d.Destroy then d:Destroy() end
				end)
				nameDrawings[p] = nil
			end
		end
	end))
end

local function removeBoxESP(p)
	local b = boxAdorns[p]
	if b then pcall(function() b:Destroy() end) boxAdorns[p] = nil end
end

local function setBoxESP(on)
	S.toggles.espBox = on == true
	dropConn("espBox")
	if not on then
		for p in pairs(boxAdorns) do removeBoxESP(p) end
		return
	end
	addConn("espBox", RunService.Heartbeat:Connect(function()
		if not S.toggles.espBox then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local box = boxAdorns[p]
				if not box or not box.Parent then
					box = Instance.new("BoxHandleAdornment")
					box.Name = "VOIDZ_BoxESP"
					box.Size = Vector3.new(2, 5, 1)
					box.AlwaysOnTop = true
					box.ZIndex = 2
					box.Transparency = 0.5
					box.Parent = p.Character
					boxAdorns[p] = box
				end
				box.Adornee = p.Character.HumanoidRootPart
				box.Color3 = S.espBoxColor
			else
				removeBoxESP(p)
			end
		end
	end))
end

local function setDistanceESP(on)
	S.toggles.espDist = on == true
	if not on then
		for p, g in pairs(distGuis) do
			pcall(function() g:Destroy() end)
			distGuis[p] = nil
		end
		dropConn("espDist")
		return
	end
	dropConn("espDist")
	addConn("espDist", RunService.RenderStepped:Connect(function()
		if not S.toggles.espDist then return end
		local cam = Workspace.CurrentCamera
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local r = p.Character:FindFirstChild("HumanoidRootPart")
				if r then
					local g = distGuis[p]
					if not g or not g.Parent then
						g = Instance.new("BillboardGui")
						g.Name = "VOIDZ_DistESP"
						g.Size = UDim2.fromOffset(70, 28)
						g.AlwaysOnTop = true
						g.StudsOffset = Vector3.new(3, 0, 0)
						g.Adornee = r
						g.Parent = r
						local tl = Instance.new("TextLabel")
						tl.BackgroundTransparency = 1
						tl.Size = UDim2.fromScale(1, 1)
						tl.Font = Enum.Font.GothamBold
						tl.TextScaled = true
						tl.TextStrokeTransparency = 0.5
						tl.Parent = g
						distGuis[p] = g
					end
					local tl = g:FindFirstChildOfClass("TextLabel")
					if tl then
						tl.TextColor3 = S.espDistColor
						tl.Text = string.format("Distance: %d", math.floor((r.Position - cam.CFrame.Position).Magnitude))
					end
					if g.Parent ~= r then g.Parent = r g.Adornee = r end
				end
			elseif distGuis[p] then
				pcall(function() distGuis[p]:Destroy() end)
				distGuis[p] = nil
			end
		end
	end))
end

local function setHealthESP(on)
	S.toggles.espHp = on == true
	if not on then
		for p, g in pairs(hpGuis) do
			pcall(function() g:Destroy() end)
			hpGuis[p] = nil
		end
		dropConn("espHp")
		return
	end
	dropConn("espHp")
	addConn("espHp", RunService.RenderStepped:Connect(function()
		if not S.toggles.espHp then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local head = p.Character:FindFirstChild("Head")
				local humP = p.Character:FindFirstChildOfClass("Humanoid")
				if head and humP then
					local g = hpGuis[p]
					if not g or not g.Parent or not g:FindFirstChild("FillTrack") then
						if g then pcall(function() g:Destroy() end) end
						g = Instance.new("BillboardGui")
						g.Name = "VOIDZ_HpESP"
						g.Size = UDim2.fromOffset(78, 20)
						g.AlwaysOnTop = true
						g.StudsOffset = Vector3.new(0, 3.15, 0)
						g.Adornee = head
						g.Parent = head
						local tl = Instance.new("TextLabel")
						tl.Name = "Txt"
						tl.BackgroundTransparency = 1
						tl.Size = UDim2.new(1, 0, 0, 11)
						tl.Font = Enum.Font.GothamBold
						tl.TextScaled = true
						tl.TextStrokeTransparency = 0.35
						tl.Parent = g
						local track = Instance.new("Frame")
						track.Name = "FillTrack"
						track.Size = UDim2.new(1, 0, 0, 6)
						track.Position = UDim2.fromOffset(0, 12)
						track.BackgroundColor3 = Color3.fromRGB(16, 10, 22)
						track.BackgroundTransparency = 0.12
						track.BorderSizePixel = 0
						track.Parent = g
						corner(track, 2)
						local fill = Instance.new("Frame")
						fill.Name = "Fill"
						fill.Size = UDim2.fromScale(1, 1)
						fill.BackgroundColor3 = S.espHpColor
						fill.BorderSizePixel = 0
						fill.Parent = track
						corner(fill, 2)
						hpGuis[p] = g
					end
					local tl = g:FindFirstChild("Txt")
					local fill = g:FindFirstChild("FillTrack") and g.FillTrack:FindFirstChild("Fill")
					local hp = math.max(0, math.floor(humP.Health))
					local mx = math.max(1, math.floor(humP.MaxHealth))
					local frac = math.clamp(hp / mx, 0, 1)
					local healthy = S.espHpColor or Color3.fromRGB(80, 255, 130)
					local col = healthy:Lerp(Color3.fromRGB(255, 70, 70), 1 - frac)
					if tl then
						tl.Text = string.format("HP %d/%d", hp, mx)
						tl.TextColor3 = col
					end
					if fill then
						fill.Size = UDim2.fromScale(frac, 1)
						fill.BackgroundColor3 = col
					end
					if g.Parent ~= head then
						g.Parent = head
						g.Adornee = head
					end
				end
			elseif hpGuis[p] then
				pcall(function() hpGuis[p]:Destroy() end)
				hpGuis[p] = nil
			end
		end
	end))
end

local function destroyChams(c)
	if not c then return end
	for _, part in ipairs(c:GetChildren()) do
		if part:IsA("BasePart") then
			local a = part:FindFirstChild("Chams")
			local b = part:FindFirstChild("Glow")
			if a then a:Destroy() end
			if b then b:Destroy() end
		end
	end
end

local function applyChams(c)
	if not c then return end
	for _, part in ipairs(c:GetChildren()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			if not part:FindFirstChild("Chams") then
				local ch = Instance.new("BoxHandleAdornment")
				ch.Name = "Chams"
				ch.AlwaysOnTop = true
				ch.ZIndex = 4
				ch.Adornee = part
				ch.Transparency = 0.1
				ch.Size = part.Size + Vector3.new(0.02, 0.02, 0.02)
				ch.Color3 = S.espChamsColor
				ch.Parent = part
				local glow = Instance.new("BoxHandleAdornment")
				glow.Name = "Glow"
				glow.AlwaysOnTop = false
				glow.ZIndex = 3
				glow.Adornee = part
				glow.Size = ch.Size + Vector3.new(0.13, 0.13, 0.13)
				glow.Color3 = S.espChamsColor
				glow.Parent = part
			else
				part.Chams.Color3 = S.espChamsColor
				local g = part:FindFirstChild("Glow")
				if g then g.Color3 = S.espChamsColor end
			end
		end
	end
end

local function setChamsESP(on)
	S.toggles.espChams = on == true
	dropConn("espChams")
	if not on then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then destroyChams(p.Character) end
		end
		return
	end
	addConn("espChams", RunService.Heartbeat:Connect(function()
		if not S.toggles.espChams then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid")
				and p.Character.Humanoid.Health > 0 then
				applyChams(p.Character)
			end
		end
	end))
end

local function setESP(on)
	setNameESP(on)
	setBoxESP(on)
	setDistanceESP(on)
	setHealthESP(on)
	setChamsESP(on)
	S.toggles.esp = on == true
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
	{ "Gun Shop", Vector3.new(-1667.94, 3.39, -73.62) },
	{ "Bank", Vector3.new(-2370.30, 3.39, 70.32) },
	{ "Car Dealer", Vector3.new(-1416.14, 3.41, -108.81) },
	{ "Nightclub", Vector3.new(-1212.19, 3.39, -62.61) },
	{ "Swipe / Cards", Vector3.new(-1539.55, 3.49, -321.10) },
	{ "Mop Job", Vector3.new(-1687.66, 3.41, 32.11) },
	{ "Box Job", Vector3.new(-1935.62, 3.01, -28.73) },
	{ "Grass Job", Vector3.new(-2016.40, 3.41, 181.18) },
	{ "Shop", Vector3.new(-1891.92, 3.41, 91.45) },
	{ "Police / Diamond", Vector3.new(-2375.46, 3.41, 530.62) },
	{ "Fake Check Station", Vector3.new(-2453.07, 109.81, -218.50) },
	{ "Check Cashout", Vector3.new(-2358.49, 3.54, 131.45) },
	{ "Nightclub Safe", Vector3.new(-1169.9, -13.5, -118.2) },
	{ "IceBox", Vector3.new(-1986.2, 0.5, 43.8) },
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

addConn("guns", RunService.Heartbeat:Connect(function()
	if S.toggles.noRecoil or S.toggles.noSpread or S.toggles.infAmmo
		or S.toggles.noJam or S.toggles.rapidFire or S.toggles.oneShot then
		applyGunMods()
	end
end))
task.spawn(function()
	while true do
		if S.toggles.noRecoil or S.toggles.noSpread or S.toggles.infAmmo
			or S.toggles.rapidFire or S.toggles.oneShot then
			patchGunTables()
		end
		task.wait(1)
	end
end)


-- ── KEY GATE (FTAP-style void panel) ───────────────────────────
do
	local gui = Instance.new("ScreenGui")
	gui.Name = "VOIDZ_CALI_KEY"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 200000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pickGuiParent()
	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = C.black
	dim.BackgroundTransparency = 0.25
	dim.BorderSizePixel = 0
	dim.Parent = gui
	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(360, 248)
	root.BackgroundColor3 = C.bg
	root.BorderSizePixel = 0
	root.Parent = gui
	corner(root, 16)
	stroke(root, C.accent, 1.5, 0.18)
	panelWash(root)
	local mark = Instance.new("Frame")
	mark.Size = UDim2.fromOffset(36, 36)
	mark.Position = UDim2.new(0.5, -18, 0, 22)
	mark.BackgroundColor3 = C.accent
	mark.BorderSizePixel = 0
	mark.Parent = root
	corner(mark, 10)
	stroke(mark, C.accent2, 1, 0.4)
	local mv = Instance.new("TextLabel")
	mv.BackgroundTransparency = 1
	mv.Size = UDim2.fromScale(1, 1)
	mv.Font = Enum.Font.GothamBlack
	mv.TextSize = 16
	mv.TextColor3 = Color3.new(1, 1, 1)
	mv.Text = "V"
	mv.Parent = mark
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 22)
	t.Position = UDim2.fromOffset(0, 66)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 18
	t.TextColor3 = C.text
	t.Text = "VOIDZ"
	t.Parent = root
	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Size = UDim2.new(1, 0, 0, 16)
	s.Position = UDim2.fromOffset(0, 90)
	s.Font = Enum.Font.GothamMedium
	s.TextSize = 11
	s.TextColor3 = C.accent2
	s.Text = isVoiceServer() and "CALI  ·  VOICE CHAT SERVER" or "CALI SHOOTOUT"
	s.Parent = root
	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(240, 34)
	box.Position = UDim2.new(0.5, -120, 0, 118)
	box.BackgroundColor3 = C.card
	box.Text = ""
	box.PlaceholderText = "VOIDZHUB"
	box.PlaceholderColor3 = C.muted
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 13
	box.TextColor3 = C.text
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = root
	corner(box, 8)
	stroke(box, C.strokeSoft, 1, 0.35)
	local err = Instance.new("TextLabel")
	err.BackgroundTransparency = 1
	err.Size = UDim2.new(1, 0, 0, 14)
	err.Position = UDim2.fromOffset(0, 156)
	err.Font = Enum.Font.Gotham
	err.TextSize = 11
	err.TextColor3 = C.dangerText
	err.Text = ""
	err.Parent = root
	local go = Instance.new("TextButton")
	go.Size = UDim2.fromOffset(240, 34)
	go.Position = UDim2.new(0.5, -120, 0, 178)
	go.BackgroundColor3 = C.accent
	go.Text = "Unlock"
	go.Font = Enum.Font.GothamBold
	go.TextSize = 13
	go.TextColor3 = Color3.new(1, 1, 1)
	go.AutoButtonColor = false
	go.BorderSizePixel = 0
	go.Parent = root
	corner(go, 8)
	stroke(go, C.accent2, 1, 0.45)
	local ok = false
	local function submit()
		local k = tostring(box.Text or ""):gsub("%s+", "")
		if k:upper() == ACCESS_KEY then
			ok = true
			gui:Destroy()
		else
			err.Text = "Wrong key"
			tw(box, { Position = UDim2.new(0.5, -128, 0, 118) }, 0.05)
			task.wait(0.05)
			tw(box, { Position = UDim2.new(0.5, -112, 0, 118) }, 0.05)
			task.wait(0.05)
			tw(box, { Position = UDim2.new(0.5, -120, 0, 118) }, 0.08)
		end
	end
	go.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(e) if e then submit() end end)
	while not ok do task.wait(0.08) end
end

-- ── HUB CHROME (matches VOIDZ FTAP) ────────────────────────────
pcall(function()
	local old = pickGuiParent():FindFirstChild("VOIDZ_CALI_HUB")
	if old then old:Destroy() end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "VOIDZ_CALI_HUB"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.DisplayOrder = 120000
sg.Parent = pickGuiParent()

local MAIN_W, MAIN_H = 720, 500
local SIDE_W = 158
local HEADER_H, FOOTER_H = 56, 26

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
root.BackgroundColor3 = C.bg
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = sg
corner(root, 16)
stroke(root, C.stroke, 1.2, 0.28)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = C.bg2
header.BorderSizePixel = 0
header.ZIndex = 5
header.Parent = root
panelWash(header)
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 2)
top.BackgroundColor3 = Color3.new(1, 1, 1)
top.BorderSizePixel = 0
top.ZIndex = 6
top.Parent = header
local topGrad = Instance.new("UIGradient")
topGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accent),
	ColorSequenceKeypoint.new(0.5, C.accent2),
	ColorSequenceKeypoint.new(1, C.accent),
})
topGrad.Parent = top
local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, -1)
headerLine.BackgroundColor3 = C.strokeSoft
headerLine.BackgroundTransparency = 0.45
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 6
headerLine.Parent = header

local logoMark = Instance.new("Frame")
logoMark.Size = UDim2.fromOffset(30, 30)
logoMark.Position = UDim2.fromOffset(14, 13)
logoMark.BackgroundColor3 = C.accent
logoMark.BorderSizePixel = 0
logoMark.ZIndex = 7
logoMark.Parent = header
corner(logoMark, 9)
stroke(logoMark, C.accent2, 1, 0.45)
local logoMarkTx = Instance.new("TextLabel")
logoMarkTx.BackgroundTransparency = 1
logoMarkTx.Size = UDim2.fromScale(1, 1)
logoMarkTx.Font = Enum.Font.GothamBlack
logoMarkTx.TextSize = 15
logoMarkTx.TextColor3 = Color3.new(1, 1, 1)
logoMarkTx.Text = "V"
logoMarkTx.ZIndex = 8
logoMarkTx.Parent = logoMark

local logo = Instance.new("TextLabel")
logo.BackgroundTransparency = 1
logo.Position = UDim2.fromOffset(54, 0)
logo.Size = UDim2.new(0, 160, 1, -18)
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 14
logo.TextColor3 = C.text
logo.TextXAlignment = Enum.TextXAlignment.Left
logo.TextYAlignment = Enum.TextYAlignment.Bottom
logo.Text = "VOIDZ"
logo.ZIndex = 7
logo.Parent = header

local verL = Instance.new("TextLabel")
verL.BackgroundTransparency = 1
verL.Position = UDim2.fromOffset(54, HEADER_H - 20)
verL.Size = UDim2.fromOffset(220, 14)
verL.Font = Enum.Font.GothamMedium
verL.TextSize = 9
verL.TextColor3 = C.accent2
verL.TextXAlignment = Enum.TextXAlignment.Left
verL.Text = isVoiceServer() and "CALI  ·  VC  ·  v1.4.1" or "CALI  ·  HUB  ·  v1.4.1"
verL.ZIndex = 7
verL.Parent = header

local statusBg = Instance.new("Frame")
statusBg.Size = UDim2.fromOffset(72, 24)
statusBg.Position = UDim2.new(1, -122, 0.5, -12)
statusBg.BackgroundColor3 = C.card
statusBg.BackgroundTransparency = 0.12
statusBg.BorderSizePixel = 0
statusBg.ZIndex = 6
statusBg.Parent = header
corner(statusBg, 8)
stroke(statusBg, C.strokeSoft, 1, 0.5)
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(6, 6)
statusDot.Position = UDim2.fromOffset(8, 9)
statusDot.BackgroundColor3 = isCaliPlace() and C.success or C.warn
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 7
statusDot.Parent = statusBg
corner(statusDot, 3)
local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -18, 1, 0)
status.Position = UDim2.fromOffset(16, 0)
status.Font = Enum.Font.GothamBold
status.TextSize = 9
status.TextColor3 = C.text
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = isVoiceServer() and "VC" or "CALI"
status.ZIndex = 7
status.Parent = statusBg

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -40, 0.5, -14)
close.BackgroundColor3 = C.card
close.Text = "×"
close.TextColor3 = C.muted
close.Font = Enum.Font.GothamBold
close.TextSize = 15
close.ZIndex = 8
close.AutoButtonColor = false
close.Parent = header
corner(close, 14)
local closeStroke = stroke(close, C.strokeSoft, 1, 0.5)
close.MouseButton1Click:Connect(function() sg.Enabled = false end)
close.MouseEnter:Connect(function()
	tw(close, { BackgroundColor3 = C.danger, TextColor3 = Color3.new(1, 1, 1) }, 0.12)
	tw(closeStroke, { Color = C.dangerText, Transparency = 0 }, 0.12)
end)
close.MouseLeave:Connect(function()
	tw(close, { BackgroundColor3 = C.card, TextColor3 = C.muted }, 0.16)
	tw(closeStroke, { Color = C.strokeSoft, Transparency = 0.45 }, 0.16)
end)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = root.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

local side = Instance.new("ScrollingFrame")
side.Size = UDim2.new(0, SIDE_W, 1, -(HEADER_H + FOOTER_H))
side.Position = UDim2.fromOffset(0, HEADER_H)
side.BackgroundColor3 = C.bg
side.BackgroundTransparency = 0.15
side.BorderSizePixel = 0
side.ScrollBarThickness = 2
side.ScrollBarImageColor3 = C.accent
side.AutomaticCanvasSize = Enum.AutomaticSize.Y
side.CanvasSize = UDim2.new()
side.ZIndex = 5
side.Parent = root
pad(side, 8, 8, 10, 8)
local sideLay = Instance.new("UIListLayout")
sideLay.Padding = UDim.new(0, 3)
sideLay.SortOrder = Enum.SortOrder.LayoutOrder
sideLay.Parent = side

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -SIDE_W, 1, -(HEADER_H + FOOTER_H + 28))
content.Position = UDim2.fromOffset(SIDE_W, HEADER_H)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.ZIndex = 5
content.Parent = root

local tipBar = Instance.new("TextLabel")
tipBar.Size = UDim2.new(1, -SIDE_W - 16, 0, 22)
tipBar.Position = UDim2.new(0, SIDE_W + 8, 1, -(FOOTER_H + 24))
tipBar.BackgroundTransparency = 1
tipBar.Font = Enum.Font.Gotham
tipBar.TextSize = 10
tipBar.TextColor3 = C.muted
tipBar.TextXAlignment = Enum.TextXAlignment.Left
tipBar.TextTruncate = Enum.TextTruncate.AtEnd
tipBar.Text = ""
tipBar.ZIndex = 6
tipBar.Parent = root
local function showTip(t)
	tipBar.Text = t or ""
end

local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_H)
footer.BackgroundColor3 = C.bg2
footer.BorderSizePixel = 0
footer.ZIndex = 5
footer.Parent = root
local footL = Instance.new("TextLabel")
footL.BackgroundTransparency = 1
footL.Size = UDim2.new(0.5, -10, 1, 0)
footL.Position = UDim2.fromOffset(12, 0)
footL.Font = Enum.Font.GothamMedium
footL.TextSize = 9
footL.TextColor3 = C.muted
footL.TextXAlignment = Enum.TextXAlignment.Left
footL.Text = "RightShift hide  ·  VOIDZHUB"
footL.Parent = footer
local footR = Instance.new("TextLabel")
footR.BackgroundTransparency = 1
footR.Size = UDim2.new(0.5, -10, 1, 0)
footR.Position = UDim2.new(0.5, 0, 0, 0)
footR.Font = Enum.Font.GothamMedium
footR.TextSize = 9
footR.TextColor3 = C.muted
footR.TextXAlignment = Enum.TextXAlignment.Right
footR.Text = ""
footR.Parent = footer
task.spawn(function()
	while footer.Parent do
		local tag = isVoiceServer() and "VC" or "main"
		footR.Text = #Players:GetPlayers() .. " online  ·  " .. tag .. "  ·  1.4.1"
		task.wait(2)
	end
end)

local function makeScroll(parent)
	local sc = Instance.new("ScrollingFrame")
	sc.Size = UDim2.fromScale(1, 1)
	sc.BackgroundTransparency = 1
	sc.BorderSizePixel = 0
	sc.ScrollBarThickness = 3
	sc.ScrollBarImageColor3 = C.accent
	sc.ScrollBarImageTransparency = 0.35
	sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sc.CanvasSize = UDim2.new()
	sc.Parent = parent
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 7)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = sc
	pad(sc, 12, 12, 16, 12)
	return sc
end

local orderN = 0
local function n()
	orderN += 1
	return orderN
end

local function section(parent, text)
	local wrap = Instance.new("Frame")
	wrap.LayoutOrder = n()
	wrap.Size = UDim2.new(1, -4, 0, 24)
	wrap.BackgroundTransparency = 1
	wrap.Parent = parent
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(10, 2)
	bar.Position = UDim2.fromOffset(2, 11)
	bar.BackgroundColor3 = C.accent
	bar.BorderSizePixel = 0
	bar.Parent = wrap
	corner(bar, 1)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -22, 1, 0)
	l.Position = UDim2.fromOffset(16, 0)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 10
	l.TextColor3 = C.accent2
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = tostring(text or ""):upper()
	l.Parent = wrap
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -16, 0, 1)
	line.Position = UDim2.new(0, 14, 1, -1)
	line.BackgroundColor3 = C.strokeSoft
	line.BackgroundTransparency = 0.62
	line.BorderSizePixel = 0
	line.Parent = wrap
end

local function makeButton(parent, opts)
	opts = opts or {}
	local wrap = Instance.new("Frame")
	wrap.LayoutOrder = n()
	wrap.Size = UDim2.new(1, -6, 0, 36)
	wrap.BackgroundColor3 = opts.danger and C.danger or C.card
	wrap.BorderSizePixel = 0
	wrap.Parent = parent
	corner(wrap, 10)
	local bStroke = stroke(wrap, opts.danger and C.dangerStroke or C.strokeSoft, 1, opts.danger and 0.2 or 0.4)
	if not opts.danger then glass(wrap) end
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromScale(1, 1)
	b.BackgroundTransparency = 1
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = opts.danger and C.dangerText or Color3.new(1, 1, 1)
	b.Text = opts.title or "Run"
	b.AutoButtonColor = false
	b.Parent = wrap
	if opts.tip then
		b.MouseEnter:Connect(function() showTip(opts.tip) end)
		b.MouseLeave:Connect(function() showTip("") end)
	end
	b.MouseEnter:Connect(function()
		tw(wrap, { BackgroundColor3 = opts.danger and Color3.fromRGB(90, 32, 52) or C.card2 }, 0.12)
		tw(bStroke, { Transparency = 0.12, Color = opts.danger and C.dangerStroke or C.accent }, 0.12)
	end)
	b.MouseLeave:Connect(function()
		tw(wrap, { BackgroundColor3 = opts.danger and C.danger or C.card }, 0.16)
		tw(bStroke, { Transparency = opts.danger and 0.2 or 0.4, Color = opts.danger and C.dangerStroke or C.strokeSoft }, 0.16)
	end)
	b.MouseButton1Click:Connect(function()
		if opts.callback then
			local ok, err = pcall(opts.callback)
			if not ok then notify(HUB_NAME, "Err: " .. tostring(err):sub(1, 50), 3) end
		end
	end)
end

local function makeToggle(parent, opts)
	opts = opts or {}
	local id = opts.id
	local rowH = opts.desc and 46 or 38
	local row = Instance.new("Frame")
	row.LayoutOrder = n()
	row.Size = UDim2.new(1, -6, 0, rowH)
	row.BackgroundColor3 = C.card
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 10)
	local rowStroke = stroke(row, C.strokeSoft, 1, 0.58)
	glass(row)
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -90, 0, 14)
	title.Position = UDim2.fromOffset(12, opts.desc and 6 or 11)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 12
	title.TextColor3 = C.text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = opts.title or "Toggle"
	title.Parent = row
	if opts.desc then
		local d = Instance.new("TextLabel")
		d.BackgroundTransparency = 1
		d.Size = UDim2.new(1, -90, 0, 12)
		d.Position = UDim2.fromOffset(12, 22)
		d.Font = Enum.Font.Gotham
		d.TextSize = 10
		d.TextColor3 = C.muted
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.Text = opts.desc
		d.Parent = row
	end
	if opts.tip then
		row.MouseEnter:Connect(function() showTip(opts.tip) end)
		row.MouseLeave:Connect(function() showTip("") end)
	end
	local pillW, pillH, knobS = 40, 20, 16
	local pill = Instance.new("TextButton")
	pill.Size = UDim2.fromOffset(pillW, pillH)
	pill.Position = UDim2.new(1, -(pillW + 12), 0.5, -pillH / 2)
	pill.BackgroundColor3 = C.bg
	pill.Text = ""
	pill.AutoButtonColor = false
	pill.Parent = row
	corner(pill, pillH / 2)
	local pillStroke = stroke(pill, C.strokeSoft, 1, 0.4)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(knobS, knobS)
	knob.Position = UDim2.fromOffset(2, (pillH - knobS) / 2)
	knob.BackgroundColor3 = C.muted
	knob.BorderSizePixel = 0
	knob.Parent = pill
	corner(knob, knobS / 2)
	local knobOff = UDim2.fromOffset(2, (pillH - knobS) / 2)
	local knobOn = UDim2.fromOffset(pillW - knobS - 2, (pillH - knobS) / 2)
	local function render()
		local on = S.toggles[id] == true
		if on then
			tw(pill, { BackgroundColor3 = C.accent }, 0.14)
			tw(knob, { Position = knobOn, BackgroundColor3 = Color3.new(1, 1, 1) }, 0.14)
			tw(pillStroke, { Color = C.accent2, Transparency = 0.15 }, 0.14)
			rowStroke.Color = C.accent
			rowStroke.Transparency = 0.42
		else
			tw(pill, { BackgroundColor3 = C.bg }, 0.14)
			tw(knob, { Position = knobOff, BackgroundColor3 = C.muted }, 0.14)
			tw(pillStroke, { Color = C.strokeSoft, Transparency = 0.4 }, 0.14)
			rowStroke.Color = C.strokeSoft
			rowStroke.Transparency = 0.58
		end
	end
	render()
	pill.MouseButton1Click:Connect(function()
		local on = not (S.toggles[id] == true)
		if opts.callback then
			local ok, err = pcall(opts.callback, on)
			if not ok then notify(HUB_NAME, "Err: " .. tostring(err):sub(1, 40), 2) end
		else
			S.toggles[id] = on
		end
		render()
	end)
end

local function makeSlider(parent, opts)
	opts = opts or {}
	local min, max = opts.min or 0, opts.max or 100
	local row = Instance.new("Frame")
	row.LayoutOrder = n()
	row.Size = UDim2.new(1, -6, 0, 50)
	row.BackgroundColor3 = C.card
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 10)
	stroke(row, C.strokeSoft, 1, 0.58)
	glass(row)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.65, 0, 0, 14)
	label.Position = UDim2.fromOffset(12, 8)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 11
	label.TextColor3 = C.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = opts.title or "Slider"
	label.Parent = row
	local val = Instance.new("TextLabel")
	val.BackgroundTransparency = 1
	val.Size = UDim2.new(0.3, -10, 0, 14)
	val.Position = UDim2.new(0.68, 0, 0, 8)
	val.Font = Enum.Font.GothamBold
	val.TextSize = 11
	val.TextColor3 = C.accent2
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Text = tostring(opts.get and opts.get() or min)
	val.Parent = row
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 6)
	track.Position = UDim2.fromOffset(12, 32)
	track.BackgroundColor3 = C.bg
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, 4)
	local frac0 = ((opts.get and opts.get() or min) - min) / math.max(max - min, 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(frac0, 0, 1, 0)
	fill.BackgroundColor3 = C.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 4)
	local dragging = false
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local r = math.clamp((i.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor(min + (max - min) * r)
			fill.Size = UDim2.new(r, 0, 1, 0)
			val.Text = tostring(v)
			if opts.set then opts.set(v) end
		end
	end)
end

local function makeInput(parent, placeholder, cb)
	local box = Instance.new("TextBox")
	box.LayoutOrder = n()
	box.Size = UDim2.new(1, -6, 0, 34)
	box.BackgroundColor3 = C.card
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = C.muted
	box.Text = ""
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextColor3 = C.text
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = parent
	corner(box, 10)
	stroke(box, C.strokeSoft, 1, 0.5)
	pad(box, 6, 10, 6, 10)
	box.FocusLost:Connect(function() if cb then cb(box.Text) end end)
	return box
end

local function makeColorRow(parent, title, get, set)
	local row = Instance.new("Frame")
	row.LayoutOrder = n()
	row.Size = UDim2.new(1, -6, 0, 34)
	row.BackgroundColor3 = C.card
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 10)
	stroke(row, C.strokeSoft, 1, 0.58)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.4, 0, 1, 0)
	lbl.Position = UDim2.fromOffset(12, 0)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextColor3 = C.text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = title
	lbl.Parent = row
	local cols = {
		Color3.new(1, 1, 1),
		C.accent,
		Color3.fromRGB(255, 70, 80),
		Color3.fromRGB(80, 255, 130),
		Color3.fromRGB(80, 170, 255),
		Color3.fromRGB(255, 220, 70),
	}
	for i, col in ipairs(cols) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(18, 18)
		b.Position = UDim2.new(1, -10 - (#cols - i + 1) * 22, 0.5, -9)
		b.BackgroundColor3 = col
		b.Text = ""
		b.AutoButtonColor = false
		b.Parent = row
		corner(b, 5)
		stroke(b, Color3.new(1, 1, 1), 1, 0.65)
		b.MouseButton1Click:Connect(function()
			set(col)
		end)
	end
end

local TAB_DEFS = {
	{ id = "home", icon = "HO", label = "Home" },
	{ id = "combat", icon = "CB", label = "Combat" },
	{ id = "guns", icon = "GN", label = "Guns" },
	{ id = "farm", icon = "FM", label = "Farm" },
	{ id = "move", icon = "MV", label = "Move" },
	{ id = "cars", icon = "CR", label = "Cars" },
	{ id = "visuals", icon = "VI", label = "Visuals" },
	{ id = "tps", icon = "TP", label = "TPs" },
	{ id = "players", icon = "PL", label = "Players" },
	{ id = "misc", icon = "MS", label = "Misc" },
}

local panels, tabBtns = {}, {}
local function switchTab(id)
	for tid, p in pairs(panels) do
		p.Visible = tid == id
	end
	for tid, btn in pairs(tabBtns) do
		local on = tid == id
		btn:SetAttribute("activeTab", on)
		btn.BackgroundTransparency = on and 0.15 or 1
		btn.BackgroundColor3 = on and C.card or C.bg
		local rail = btn:FindFirstChild("Rail")
		if rail then rail.BackgroundTransparency = on and 0 or 1 end
		local badge = btn:FindFirstChild("Badge")
		if badge then
			badge.BackgroundColor3 = on and C.accentDim or C.bg
		end
	end
end

for i, def in ipairs(TAB_DEFS) do
	local btnH = 30
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = i
	btn.Size = UDim2.new(1, 0, 0, btnH)
	btn.BackgroundColor3 = C.bg
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 5
	btn.Parent = side
	corner(btn, 8)
	local tabRail = Instance.new("Frame")
	tabRail.Name = "Rail"
	tabRail.Size = UDim2.new(0, 2, 0, 12)
	tabRail.Position = UDim2.fromOffset(3, (btnH - 12) / 2)
	tabRail.BackgroundColor3 = C.accent
	tabRail.BackgroundTransparency = 1
	tabRail.BorderSizePixel = 0
	tabRail.ZIndex = 6
	tabRail.Parent = btn
	corner(tabRail, 1)
	btn.MouseEnter:Connect(function()
		if not btn:GetAttribute("activeTab") then
			tw(btn, { BackgroundTransparency = 0.62, BackgroundColor3 = C.card }, 0.12)
		end
	end)
	btn.MouseLeave:Connect(function()
		if not btn:GetAttribute("activeTab") then
			tw(btn, { BackgroundTransparency = 1, BackgroundColor3 = C.bg }, 0.12)
		end
	end)
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(18, 18)
	badge.Position = UDim2.fromOffset(10, btnH / 2 - 9)
	badge.BackgroundColor3 = C.bg
	badge.BackgroundTransparency = 0.1
	badge.BorderSizePixel = 0
	badge.ZIndex = 6
	badge.Parent = btn
	corner(badge, 6)
	stroke(badge, C.strokeSoft, 1, 0.7)
	local badgeTx = Instance.new("TextLabel")
	badgeTx.BackgroundTransparency = 1
	badgeTx.Size = UDim2.fromScale(1, 1)
	badgeTx.Font = Enum.Font.GothamBold
	badgeTx.TextSize = 8
	badgeTx.TextColor3 = C.accent2
	badgeTx.Text = def.icon
	badgeTx.ZIndex = 7
	badgeTx.Parent = badge
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.new(1, -36, 1, 0)
	lab.Position = UDim2.fromOffset(34, 0)
	lab.Font = Enum.Font.GothamMedium
	lab.TextSize = 11
	lab.TextColor3 = C.text
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.Text = def.label
	lab.ZIndex = 6
	lab.Parent = btn
	tabBtns[def.id] = btn
	local panel = Instance.new("Frame")
	panel.Name = def.id
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.ZIndex = 5
	panel.Parent = content
	panels[def.id] = panel
	local sc = makeScroll(panel)
	panels[def.id] = panel
	btn.MouseButton1Click:Connect(function() switchTab(def.id) end)
	def._sc = sc
end

local prem = Instance.new("Frame")
prem.LayoutOrder = 999
prem.Size = UDim2.new(1, 0, 0, 38)
prem.BackgroundColor3 = C.card
prem.BackgroundTransparency = 0.08
prem.BorderSizePixel = 0
prem.Parent = side
corner(prem, 10)
stroke(prem, C.accent, 1, 0.6)
glass(prem)
local premMark = Instance.new("Frame")
premMark.Size = UDim2.fromOffset(22, 22)
premMark.Position = UDim2.fromOffset(8, 9)
premMark.BackgroundColor3 = C.accentDim
premMark.BorderSizePixel = 0
premMark.Parent = prem
corner(premMark, 11)
local premV = Instance.new("TextLabel")
premV.BackgroundTransparency = 1
premV.Size = UDim2.fromScale(1, 1)
premV.Font = Enum.Font.GothamBlack
premV.TextSize = 11
premV.TextColor3 = C.accent2
premV.Text = "V"
premV.Parent = premMark
local premL = Instance.new("TextLabel")
premL.BackgroundTransparency = 1
premL.Size = UDim2.new(1, -40, 1, 0)
premL.Position = UDim2.fromOffset(36, 0)
premL.Font = Enum.Font.GothamMedium
premL.TextSize = 9
premL.TextColor3 = C.muted
premL.TextXAlignment = Enum.TextXAlignment.Left
premL.TextWrapped = true
premL.Text = "FULL\nVOIDZHUB"
premL.Parent = prem

local home = TAB_DEFS[1]._sc
local combat = TAB_DEFS[2]._sc
local guns = TAB_DEFS[3]._sc
local farm = TAB_DEFS[4]._sc
local move = TAB_DEFS[5]._sc
local cars = TAB_DEFS[6]._sc
local vis = TAB_DEFS[7]._sc
local tps = TAB_DEFS[8]._sc
local ply = TAB_DEFS[9]._sc
local misc = TAB_DEFS[10]._sc

-- HOME
section(home, "WELCOME")
do
	local hero = Instance.new("Frame")
	hero.LayoutOrder = n()
	hero.Size = UDim2.new(1, -6, 0, 92)
	hero.BackgroundColor3 = C.card
	hero.BorderSizePixel = 0
	hero.Parent = home
	corner(hero, 14)
	stroke(hero, C.accent, 1, 0.5)
	local rail = Instance.new("Frame")
	rail.Size = UDim2.new(0, 3, 1, -24)
	rail.Position = UDim2.fromOffset(12, 12)
	rail.BackgroundColor3 = C.accent
	rail.BorderSizePixel = 0
	rail.Parent = hero
	corner(rail, 2)
	local ht = Instance.new("TextLabel")
	ht.BackgroundTransparency = 1
	ht.Size = UDim2.new(1, -36, 0, 26)
	ht.Position = UDim2.fromOffset(24, 16)
	ht.Font = Enum.Font.GothamBlack
	ht.TextSize = 20
	ht.TextColor3 = C.text
	ht.TextXAlignment = Enum.TextXAlignment.Left
	ht.Text = "VOIDZ  CALI"
	ht.Parent = hero
	local hs = Instance.new("TextLabel")
	hs.BackgroundTransparency = 1
	hs.Size = UDim2.new(1, -36, 0, 36)
	hs.Position = UDim2.fromOffset(24, 44)
	hs.Font = Enum.Font.Gotham
	hs.TextSize = 12
	hs.TextColor3 = C.muted
	hs.TextXAlignment = Enum.TextXAlignment.Left
	hs.TextWrapped = true
	hs.Text = isVoiceServer()
		and "Voice Chat server  ·  same tools as main  ·  Combat God still shoots"
		or "Main map  ·  Combat God keeps you shooting  ·  RightShift hide"
	hs.Parent = hero
end
section(home, "QUICK")
makeToggle(home, {
	id = "combatGod", title = "Combat God",
	desc = "ForceField + health lock + ghost gun",
	tip = "Invisible ForceField blocks TakeDamage. If you still drop, you snap back on respawn.",
	callback = setCombatGod,
})
makeToggle(home, {
	id = "silentAim", title = "Silent Aim",
	tip = "Redirects shots at the closest head in FOV.",
	callback = function(on) S.toggles.silentAim = on if on then installSilentAim() end end,
})
makeToggle(home, {
	id = "esp", title = "All Express ESP",
	tip = "Name + box + distance + health + chams.",
	callback = setESP,
})

-- COMBAT
section(combat, "SURVIVE")
makeToggle(combat, {
	id = "combatGod", title = "Combat God",
	desc = "ForceField + health lock + ghost gun",
	callback = setCombatGod,
})
makeToggle(combat, {
	id = "antiRagdoll", title = "Anti Ragdoll / KO",
	callback = function(on)
		S.toggles.antiRagdoll = on
		dropConn("antiRag")
		if not on then return end
		addConn("antiRag", RunService.Heartbeat:Connect(function()
			if not S.toggles.antiRagdoll then return end
			applyCombatGod(hum(), char())
		end))
	end,
})
section(combat, "AIM")
makeToggle(combat, {
	id = "silentAim", title = "Silent Aim",
	callback = function(on) S.toggles.silentAim = on if on then installSilentAim() end end,
})
makeToggle(combat, {
	id = "aimbot", title = "Aimbot (hold RMB / E)",
	tip = "Express-style camera lock while holding right click.",
	callback = setAimbot,
})
makeToggle(combat, {
	id = "triggerbot", title = "Triggerbot",
	tip = "Clicks when your mouse is on a player.",
	callback = setTriggerbot,
})
makeSlider(combat, { title = "Silent FOV", min = 20, max = 360, get = function() return S.silentFov end, set = function(v) S.silentFov = v end })
section(combat, "HITBOX / AURA")
makeToggle(combat, { id = "hitbox", title = "Hitbox Expander", callback = setHitboxes })
makeSlider(combat, { title = "Hitbox Size", min = 2, max = 25, get = function() return S.hitboxSize end, set = function(v) S.hitboxSize = v end })
makeToggle(combat, { id = "killAura", title = "Kill Aura", callback = setKillAura })
makeSlider(combat, { title = "Aura Range", min = 10, max = 250, get = function() return S.killRange end, set = function(v) S.killRange = v end })
makeButton(combat, {
	title = "Kill All (TP + fire)",
	tip = "Walks every player, fires, returns home.",
	callback = function()
		task.spawn(function()
			local homeCF = hrp() and hrp().CFrame
			for _, p in ipairs(Players:GetPlayers()) do
				if aliveP(p) then
					local r = p.Character.HumanoidRootPart
					tp(r.CFrame * CFrame.new(0, 0, 3))
					for _ = 1, 8 do fireGun() task.wait(0.05) end
				end
			end
			if homeCF then tp(homeCF) end
			notify(HUB_NAME, "Kill-all pass done", 1.4)
		end)
	end,
})

-- GUNS
section(guns, "GUN MODS")
makeToggle(guns, { id = "noRecoil", title = "No Recoil", callback = function(on) S.toggles.noRecoil = on end })
makeToggle(guns, { id = "noSpread", title = "No Spread", callback = function(on) S.toggles.noSpread = on end })
makeToggle(guns, { id = "infAmmo", title = "Infinite Ammo", callback = function(on) S.toggles.infAmmo = on end })
makeToggle(guns, { id = "noJam", title = "Never Jam", callback = function(on) S.toggles.noJam = on end })
makeToggle(guns, { id = "rapidFire", title = "Rapid Fire / no cooldown", callback = function(on) S.toggles.rapidFire = on end })
makeToggle(guns, { id = "oneShot", title = "One Shot Damage", callback = function(on) S.toggles.oneShot = on end })
makeToggle(guns, {
	id = "ghostGun", title = "Ghost Gun (invisible, still shoots)",
	tip = "Hides the gun mesh. Tool stays equipped so you can fire.",
	callback = function(on)
		S.toggles.ghostGun = on
		dropConn("ghostGun")
		if not on then
			if not S.toggles.combatGod then restoreGhostGuns() end
			return
		end
		addConn("ghostGun", RunService.RenderStepped:Connect(function()
			if S.toggles.ghostGun or S.toggles.combatGod then
				keepToolEquipped(char())
				ghostGunVisuals(char())
			end
		end))
	end,
})

-- FARM
section(farm, "AUTOFARM")
makeToggle(farm, { id = "instantPrompt", title = "Instant Prompts", callback = setInstantPrompt })
makeToggle(farm, {
	id = "farmBox", title = "Auto Box",
	tip = "Job System.BoxPickingJob — Express path.",
	callback = function(on) if on then startFarm("farmBox", farmBoxTick) else stopFarm("farmBox") end end,
})
makeToggle(farm, {
	id = "farmTrash", title = "Auto Garbage",
	tip = "Job System.GarbageJob.",
	callback = function(on) if on then startFarm("farmTrash", farmTrashTick) else stopFarm("farmTrash") end end,
})
makeToggle(farm, {
	id = "farmMop", title = "Auto Mop / Janitor",
	tip = "giveMop remote + Dirt_Spawn prompts.",
	callback = function(on) if on then startFarm("farmMop", farmMopTick) else stopFarm("farmMop") end end,
})
makeToggle(farm, {
	id = "farmCar", title = "Auto Car Rob",
	tip = "workspace.CarRobberys prompts.",
	callback = function(on) if on then startFarm("farmCar", farmCarTick) else stopFarm("farmCar") end end,
})
makeToggle(farm, {
	id = "farmGrass", title = "Auto Grass",
	callback = function(on) if on then startFarm("farmGrass", farmGrassTick) else stopFarm("farmGrass") end end,
})
makeToggle(farm, {
	id = "farmCheck", title = "Auto Fake Checks",
	tip = "Go near the bank first if it stalls.",
	callback = function(on) if on then startFarm("farmCheck", farmCheckTick) else stopFarm("farmCheck") end end,
})
section(farm, "CHECK PRINTER")
makeButton(farm, { title = "TP Check Station", callback = function() tp(CFrame.new(-2453.07, 109.81, -218.50)) end })
makeButton(farm, { title = "TP Check Cashout", callback = function() tp(CFrame.new(-2358.49, 3.54, 131.45)) end })

-- MOVE
section(move, "MOVEMENT")
makeToggle(move, { id = "speed", title = "WalkSpeed Override", callback = setSpeedLoop })
makeSlider(move, { title = "WalkSpeed", min = 16, max = 200, get = function() return S.walkSpeed end, set = function(v)
	S.walkSpeed = v
	local h = hum()
	if h then h.WalkSpeed = v end
end })
makeToggle(move, { id = "fly", title = "Fly (WASD Space/Shift)", callback = setFly })
makeSlider(move, { title = "Fly Speed", min = 20, max = 250, get = function() return S.flySpeed end, set = function(v) S.flySpeed = v end })
makeToggle(move, { id = "noclip", title = "Noclip", callback = setNoclip })
makeToggle(move, { id = "infJump", title = "Infinite Jump", callback = setInfJump })
makeToggle(move, { id = "ctrlTp", title = "Ctrl + Click TP", callback = function(on) S.toggles.ctrlTp = on end })

-- CARS (Express Hub accel: multiply VehicleSeat velocity while W)
section(cars, "SPEED")
makeToggle(cars, {
	id = "carAccel",
	title = "Enable Acceleration (hold W)",
	tip = "Express method: multiplies your car's velocity while W is down.",
	callback = setCarAccel,
})
makeSlider(cars, {
	title = "Acceleration", min = 1, max = 80,
	get = function() return math.floor((S.carAccel or 0.04) * 1000) end,
	set = function(v) S.carAccel = v / 1000 end,
})
makeSlider(cars, {
	title = "Max Speed", min = 40, max = 400,
	get = function() return S.carSpeed end,
	set = function(v)
		S.carSpeed = v
		local s = getCarSeat()
		if s then pcall(function() s.MaxSpeed = v end) end
	end,
})
section(cars, "FLY")
makeToggle(cars, {
	id = "carFly",
	title = "Car Fly (WASD Space/Shift)",
	callback = setCarFly,
})
makeSlider(cars, {
	title = "Car Fly Speed", min = 20, max = 250,
	get = function() return S.carFlySpeed end,
	set = function(v) S.carFlySpeed = v end,
})
section(cars, "SPRINGS")
makeToggle(cars, {
	id = "carSprings",
	title = "Show Springs",
	callback = function(on)
		S.toggles.carSprings = on
		local seat = getCarSeat()
		local veh = getCarModel(seat)
		if not veh then return end
		for _, sc in ipairs(veh:GetDescendants()) do
			if sc:IsA("SpringConstraint") then
				pcall(function() sc.Visible = on end)
			end
		end
	end,
})

-- VISUALS (Express Hub layout)
section(vis, "NAME ESP")
makeToggle(vis, { id = "espName", title = "Name Esp", callback = setNameESP })
makeColorRow(vis, "Name Color", function() return S.espNameColor end, function(c) S.espNameColor = c end)
section(vis, "BOX ESP")
makeToggle(vis, { id = "espBox", title = "Box Esp", callback = setBoxESP })
makeColorRow(vis, "Box Color", function() return S.espBoxColor end, function(c) S.espBoxColor = c end)
section(vis, "DISTANCE ESP")
makeToggle(vis, { id = "espDist", title = "Distance Esp", callback = setDistanceESP })
makeColorRow(vis, "Distance Color", function() return S.espDistColor end, function(c) S.espDistColor = c end)
section(vis, "HEALTH ESP")
makeToggle(vis, { id = "espHp", title = "Health Esp", callback = setHealthESP })
makeColorRow(vis, "Health Color", function() return S.espHpColor end, function(c) S.espHpColor = c end)
section(vis, "CHAMS ESP")
makeToggle(vis, { id = "espChams", title = "Chams Esp", callback = setChamsESP })
makeColorRow(vis, "Chams Color", function() return S.espChamsColor end, function(c)
	S.espChamsColor = c
	if S.toggles.espChams then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then applyChams(p.Character) end
		end
	end
end)
section(vis, "WORLD")
makeToggle(vis, { id = "fullbright", title = "Fullbright", callback = setFullbright })
makeSlider(vis, {
	title = "FOV", min = 70, max = 120,
	get = function() return S.camFov end,
	set = function(v)
		S.camFov = v
		local cam = Workspace.CurrentCamera
		if cam then cam.FieldOfView = v end
	end,
})
makeToggle(vis, {
	id = "alwaysDay", title = "Always Day",
	callback = function(on)
		S.toggles.alwaysDay = on
		dropConn("day")
		if not on then return end
		addConn("day", RunService.Heartbeat:Connect(function()
			if S.toggles.alwaysDay then Lighting:SetMinutesAfterMidnight(720) end
		end))
	end,
})
makeToggle(vis, {
	id = "alwaysNight", title = "Always Night",
	callback = function(on)
		S.toggles.alwaysNight = on
		dropConn("night")
		if not on then return end
		addConn("night", RunService.Heartbeat:Connect(function()
			if S.toggles.alwaysNight then Lighting:SetMinutesAfterMidnight(0) end
		end))
	end,
})

-- TPS
section(tps, "CALI MAP")
makeButton(tps, {
	title = "Hop to Voice Chat server",
	tip = "Teleports you into Cali's VC-only place. Hub reloads after hop.",
	callback = function()
		pcall(function() TeleportService:Teleport(PLACE_VC, LP) end)
	end,
})
makeButton(tps, {
	title = "Hop to main map",
	callback = function()
		pcall(function() TeleportService:Teleport(PLACE_MAIN, LP) end)
	end,
})
for _, row in ipairs(TPS) do
	local name, pos = row[1], row[2]
	makeButton(tps, { title = name, callback = function() tp(CFrame.new(pos + Vector3.new(0, 3, 0))) end })
end

-- PLAYERS
section(ply, "TARGET")
makeInput(ply, "Name / display", function(text)
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
makeButton(ply, { title = "TP to selected", callback = function()
	local p = S.selected
	if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
		tp(p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
	else
		notify(HUB_NAME, "No player selected", 1.2)
	end
end })
makeButton(ply, { title = "Spectate selected", callback = function()
	local p = S.selected
	if p and p.Character then
		local h = p.Character:FindFirstChildOfClass("Humanoid")
		if h then Camera.CameraSubject = h end
	end
end })
makeButton(ply, { title = "Unspectate", callback = function()
	local h = hum()
	if h then Camera.CameraSubject = h end
end })

-- MISC
section(misc, "TEAMS / CODES")
makeButton(misc, { title = "Team: Civilian", callback = function()
	pcall(function()
		game:GetService("ReplicatedStorage"):WaitForChild("TeamChangeRequestEvent"):FireServer("Civilian")
	end)
end })
makeButton(misc, { title = "Team: Prisoner", callback = function()
	pcall(function()
		game:GetService("ReplicatedStorage"):WaitForChild("TeamChangeRequestEvent"):FireServer("Prisoner")
	end)
end })
makeButton(misc, { title = "Team: Police", callback = function()
	pcall(function()
		game:GetService("ReplicatedStorage"):WaitForChild("TeamChangeRequestEvent"):FireServer("Police")
	end)
end })
makeButton(misc, {
	title = "Redeem promo codes",
	tip = "codeEvent — Aim, SPIN, JEWELRY, NIGHTCLUB, WINTER, ELECTRIC",
	callback = function()
		task.spawn(function()
			local ev = game:GetService("ReplicatedStorage"):FindFirstChild("codeEvent")
			if not ev then notify(HUB_NAME, "No codeEvent", 1.5) return end
			for _, code in ipairs({ "Aim", "AIM", "SPIN", "JEWELRY", "NIGHTCLUB", "WINTER", "ELECTRIC", "ELECTRICTRIC", "BOSS" }) do
				pcall(function() ev:FireServer(code) end)
				task.wait(0.4)
			end
			notify(HUB_NAME, "Codes fired", 1.4)
		end)
	end,
})
section(misc, "SERVER")
makeToggle(misc, { id = "antiAfk", title = "Anti AFK", callback = setAntiAfk })
makeButton(misc, { title = "Rejoin", callback = function()
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
end })
makeButton(misc, { title = "Server hop", callback = function()
	pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
end })
section(misc, "CLEAN")
makeButton(misc, {
	title = "Unload all",
	danger = true,
	callback = function()
		setCombatGod(false)
		setAimbot(false)
		setHitboxes(false)
		setKillAura(false)
		setNoclip(false)
		setFly(false)
		setCarAccel(false)
		setCarFly(false)
		setInfJump(false)
		setSpeedLoop(false)
		setESP(false)
		setNameESP(false)
		setBoxESP(false)
		setDistanceESP(false)
		setHealthESP(false)
		setChamsESP(false)
		setFullbright(false)
		setInstantPrompt(false)
		setAntiAfk(false)
		for k in pairs(S.toggles) do S.toggles[k] = false end
		notify(HUB_NAME, "Unloaded", 1.4)
	end,
})

switchTab("home")

pcall(function()
	Mouse.Button1Down:Connect(function()
		if not S.toggles.ctrlTp then return end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			tp(CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)))
		end
	end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		sg.Enabled = not sg.Enabled
	end
end)

notify(HUB_NAME, "Cali " .. (isVoiceServer() and "VC" or "main") .. "  ·  " .. BUILD, 3)
print("[VOIDZ CALI] " .. BUILD .. "  -- hi im voidz")
