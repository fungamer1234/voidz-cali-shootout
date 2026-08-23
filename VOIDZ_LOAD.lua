-- VOIDZ Cali loader (MacSploit-safe). Shows a banner, then runs the hub.
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
while not LP do
	task.wait()
	LP = Players.LocalPlayer
end
local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui")
pcall(function()
	local old = pg:FindFirstChild("VOIDZ_BOOT")
	if old then old:Destroy() end
end)
local sg = Instance.new("ScreenGui")
sg.Name = "VOIDZ_BOOT"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999999999
pcall(function()
	sg.ClipToDeviceSafeArea = false
end)
sg.Parent = pg
local t = Instance.new("TextLabel")
t.Size = UDim2.new(1, 0, 0, 54)
t.BackgroundColor3 = Color3.fromRGB(88, 20, 200)
t.TextColor3 = Color3.fromRGB(255, 255, 255)
t.Font = Enum.Font.SourceSansBold
t.TextSize = 22
t.Text = "VOIDZ: fetching hub..."
t.Parent = sg
print("[VOIDZ] loader banner parent=" .. tostring(sg.Parent))

local urls = {
	"https://raw.githubusercontent.com/fungamer1234/voidz-cali-shootout/main/VOIDZ_CALI.lua",
	"https://raw.githubusercontent.com/fungamer1234/voidz-cali-shootout/a6471c557525ef324c4b8b45628f2c1992ce5538/VOIDZ_CALI.lua",
	"https://cdn.jsdelivr.net/gh/fungamer1234/voidz-cali-shootout@a6471c557525ef324c4b8b45628f2c1992ce5538/VOIDZ_CALI.lua",
}

local function httpget(u)
	local ok, body = pcall(function()
		return game:HttpGet(u)
	end)
	if ok and type(body) == "string" and #body > 1000 then
		return body
	end
	local req = request or http_request or (syn and syn.request) or (http and http.request)
	if type(req) == "function" then
		local ok2, res = pcall(req, { Url = u, Method = "GET" })
		if ok2 and type(res) == "table" then
			return res.Body or res.body
		end
	end
	return nil
end

local src
for i, u in ipairs(urls) do
	t.Text = "VOIDZ: fetch " .. i .. "/" .. #urls
	print("[VOIDZ] fetch", i, u)
	local body = httpget(u)
	print("[VOIDZ] bytes", type(body) == "string" and #body or tostring(body))
	if type(body) == "string" and body:find("VOIDZ HUB", 1, true) then
		src = body
		break
	end
end

if type(src) ~= "string" then
	t.Text = "VOIDZ DOWNLOAD FAILED — see output"
	error("VOIDZ download failed")
end

t.Text = "VOIDZ: running " .. tostring(#src) .. " bytes"
local fn, err = loadstring(src)
if not fn then
	t.Text = "VOIDZ PARSE ERROR"
	error(err)
end
local ok, runErr = pcall(fn)
if not ok then
	t.Text = "VOIDZ ERROR: " .. tostring(runErr):sub(1, 70)
	warn(runErr)
	error(runErr)
end
t.Text = "VOIDZ running — key VOIDZHUB"
task.delay(6, function()
	pcall(function()
		if sg then sg:Destroy() end
	end)
end)
