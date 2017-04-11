--[[
Name: CandyBar-2.0
Revision: 16003
Author: Ammo (wouter@muze.nl)
Backport to vanilla: laytya (@gmail.com)
Website: https://github.com/laytya/LibCandyBar/
Documentation: http://web.archive.org/web/20070314234510/http://wowace.com/wiki/CandyBar-2.0
Description: A timer bars library.
Dependencies: AceLibrary, AceOO-2.0, PaintChips-2.0
]]
local match = string.match
local getn,setn,tinsert = table.getn, table.setn,table.insert
local vmajor, vminor = "CandyBar-2.0", "$Revision: 16003 $" 

if not AceLibrary then error(vmajor .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(vmajor, vminor) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(vmajor .. " requires AceOO-2.0") end
--if not AceLibrary:HasInstance("PaintChips-2.0") then error(vmajor .. " requires PaintChips-2.0") end

local paint,compost = nil,nil

if AceLibrary:HasInstance("Compost-2.0") then compost = AceLibrary:GetInstance("Compost-2.0") end

local AceOO = AceLibrary:GetInstance("AceOO-2.0")
local Mixin = AceOO.Mixin
local CandyBar = Mixin {
	"RegisterCandyBar",
	"UnregisterCandyBar",
	"IsCandyBarRegistered",
	"StartCandyBar",
	"StopCandyBar",
	"PauseCandyBar",
	"CandyBarStatus",
	"SetCandyBarTexture",
	"SetCandyBarTime",
	"SetCandyBarColor",
	"SetCandyBarText",
	"SetCandyBarIcon",
	"SetCandyBarIconPosition",
	"SetCandyBarWidth",
	"SetCandyBarHeight",
	"SetCandyBarBackgroundColor",
	"SetCandyBarTextColor",
	"SetCandyBarTimerTextColor",
	"SetCandyBarFontSize",
	"SetCandyBarPoint",
	"GetCandyBarPoint",
	"GetCandyBarCenter",
	"GetCandyBarOffsets",
	"GetCandyBarEffectiveScale",
	"SetCandyBarGradient",
	"SetCandyBarScale",
	"SetCandyBarTimeFormat",
	"SetCandyBarTimeLeft",
	"SetCandyBarCompletion",
	"SetCandyBarFade",
	"RegisterCandyBarGroup",
	"UnregisterCandyBarGroup",
	"IsCandyBarGroupRegistered",
	"SetCandyBarGroupPoint",
	"SetCandyBarGroupGrowth",
	"SetCandyBarGroupVerticalSpacing",
	"UpdateCandyBarGroup",
	"GetCandyBarNextBarPointInGroup",
	"RegisterCandyBarWithGroup",
	"UnregisterCandyBarWithGroup",
	"IsCandyBarRegisteredWithGroup",
	"SetCandyBarReversed",
	"IsCandyBarReversed",
	"SetCandyBarOnClick",
	"SetCandyBarOnSizeGroup",
}

local defaults = {
	texture = "Interface\\TargetingFrame\\UI-StatusBar",
	width = 200,
	height = 16,
	scale = 1,
	point = "CENTER",
	rframe = UIParent,
	rpoint = "CENTER",
	iconpos = "LEFT",
	xoffset = 0,
	yoffset = 0,
	fontsize = 11,
	color = {1, 0, 1, 1},
	bgcolor = {0, 0.5, 0.5, 0.5},
	textcolor = {1, 1, 1, 1},
	timertextcolor = {1, 1, 1, 1},
    stayonscreen = false,
}

local getArgs
do
	local numargs
	local function _get(t, str, i, ...)
		if i<=numargs then
			return t[format("%s%d", str, i)],  _get(t, str, i+1, unpack(arg))
		end
		return (unpack(arg))
	end

	function getArgs(t, str, ...)
		numargs = t[str.."#" or 0]
		return _get(t,str,1, unpack(arg))
	end
end

local function setArgs(t, str, ...)
	local n = getn(arg)
	for i=1,n do
	  t[format("%s%d",str,i)]=arg[i]
	end
	for i=n+1, (t[str.."#"] or 0) do
		t[format("%s%d",str,i)]=nil
	end
	t[str.."#"] = n
end

local new, del
if  compost then
	new =  function() return compost:Acquire() end 
	del =  function(t) compost:Reclaim(t) end
else
	local list = setmetatable({}, {__mode = "k"})
	function new()
		local t = next(list)
		if not t then
			return {}
		end
		list[t] = nil
		return t
	end

	function del(t)
		setmetatable(t, nil)
		for k in pairs(t) do
			t[k] = nil
		end
		setn(t,0)
		list[t] = true
	end
end

-- Registers a new candy bar
-- name - A unique identifier for your bar.
-- time - Time for the bar
-- text - text displayed on the bar [defaults to the name if not set]
-- icon - icon off the bar [optional]
-- c1 - c10 - color of the bar [optional]
-- returns true on a succesful register
function CandyBar:Register(name, time, text, icon, c1, c2, c3, c4, ...)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(time, 3, "number")
	CandyBar:argCheck(text, 4, "string", "nil")
	CandyBar:argCheck(icon, 5, "string", "nil")
	CandyBar:argCheck(c1, 6, "string", "number", "nil")
	CandyBar:argCheck(c2, 7, "string", "number", "nil")
	CandyBar:argCheck(c3, 8, "string", "number", "nil")
	CandyBar:argCheck(c4, 9, "string", "number", "nil")
	if not text then text = name end
	if CandyBar.handlers[name] then
		self:Unregister(name)
	end
	local handler = new()
	handler.name, handler.time, handler.text, handler.icon = name, time, text or name, icon
	handler.texture = defaults.texture
	local c1Type = type(c1)
	if c1Type ~= "number" and not paint then
		CandyBar:error("You need the PaintChips-2.0 library if you don't pass in RGB pairs as colors.")
	end
	if c1Type == "nil" or (c1Type ~= "number" and paint and not paint:GetRGBPercent(c1)) then
		c1 = "green"
	end
	handler.color = new()
	if c1Type == "number" then
		handler.color[1] = c1
		handler.color[2] = c2
		handler.color[3] = c3
	else
		local _
		_, handler.color[1], handler.color[2], handler.color[3] =  paint:GetRGBPercent(c1)
	end
	handler.color[4] = 1
	handler.running = nil
	handler.endtime = 0
	handler.reversed = nil
	CandyBar.handlers[name] = handler
	handler.frame = CandyBar:AcquireBarFrame(name)
	if (c1Type == "number" and c4) or (c1Type == "string" and c2) then
		CandyBar:SetGradient(name, c1, c2, c3, c4, unpack(arg))
	end
	handler.stayonscreen = defaults.stayonscreen
	return true
end


-- Removes a candy bar
-- a1 - a10 handlers that you wish to remove
-- returns true upon sucessful removal
function CandyBar:Unregister(a1, ...)
	CandyBar:argCheck(a1, 2, "string")
	if not CandyBar.handlers[a1] then
		return
	end
	CandyBar:UnregisterWithGroup(a1)
	CandyBar:ReleaseBarFrame(a1)
	local handler = CandyBar.handlers[a1]
	CandyBar.handlers[a1] = nil
	if handler.color then
		handler.color = del(handler.color)
	end
	if handler.bgcolor then
		handler.bgcolor = del(handler.bgcolor)
	end
	if handler.textcolor then
		handler.textcolor = del(handler.textcolor)
	end
	if handler.timertextcolor then
		handler.timertextcolor = del(handler.timertextcolor)
	end
	if handler.gradienttable then
		for i,v in ipairs(handler.gradienttable) do
			v = del(v)
		end
		handler.gradienttable = del(handler.gradienttable)
	end
	handler = del(handler)
	if getn(arg)>0 then
		CandyBar:Unregister(unpack(arg))
	elseif not CandyBar:HasHandlers() then
		CandyBar.frame:Hide()
	end
	return true
end

-- Checks if a candy bar is registered
-- Args: name - name of the candybar
-- returns true if a the candybar is registered
function CandyBar:IsRegistered(name)
	CandyBar:argCheck(name, 2, "string")
	if CandyBar.handlers[name] then
		return true
	end
	return false
end

-- Start a bar
-- Args:  name - the candybar you want to start
--		fireforget [optional] - pass true if you want the bar to unregister upon completion
-- returns true if succesful
function CandyBar:Start(name, fireforget)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(fireforget, 3, "boolean", "nil")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	local t = GetTime()
	if handler.paused then
		local pauseoffset = t - handler.pausetime
		handler.endtime = handler.endtime + pauseoffset
		handler.starttime = handler.starttime + pauseoffset
	elseif handler.elapsed and not handler.running then
		handler.endtime = t + handler.time - handler.elapsed
		handler.starttime = t - handler.elapsed
	else
		-- bar hasn't elapsed a second.
		handler.elapsed = 0
		handler.endtime = t + handler.time
		handler.starttime = t
	end
	handler.fireforget = fireforget
	handler.running = true
	handler.paused = nil
	handler.fading = nil
	CandyBar:AcquireBarFrame(name) -- this will reset the barframe incase we were fading out when it was restarted
	handler.frame:Show()
	if handler.group then
		CandyBar:UpdateGroup(handler.group) -- update the group
	end
	CandyBar.frame:Show()
	return true
end

-- Stop a bar
-- Args:  name - the candybar you want to stop
-- returns true if succesful
function CandyBar:Stop(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	
	if not handler then
		return
	end

	handler.running = nil
	handler.paused = nil
	handler.elapsed = 0

	if handler.fadeout then
		handler.frame.spark:Hide()
		if not handler.stayonscreen then
			handler.fading = true
			handler.fadeelapsed = 0
			local t = GetTime()
			if handler.endtime > t then
				handler.endtime = t
			end
		end
	else
		handler.frame:Hide()
		handler.starttime = nil
		handler.endtime = 0
		if handler.group then
			CandyBar:UpdateGroup(handler.group)
		end
		if handler.fireforget then
			return CandyBar:Unregister(name)
		end
	end
	if not CandyBar:HasHandlers() then
		CandyBar.frame:Hide()
	end
	return true
end

-- Pause a bar
-- Name - the candybar you want to pause
-- returns true if succesful
function CandyBar:Pause(name)
	CandyBar:argCheck(name, 2, "string")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	handler.pausetime = GetTime()
	handler.paused = true
	handler.running = nil
end

-- Query a timer's status
-- Args: name - the schedule you wish to look up
-- Returns: registered - true if a schedule exists with this name
--		time	- time for this bar
--		  elapsed - time elapsed for this bar
--		  running - true if this schedule is currently running
function CandyBar:Status(name)
	CandyBar:argCheck(name, 2, "string")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	return true, handler.time, handler.elapsed, handler.running, handler.paused
end


-- Set the time for a bar.
-- Args: name - the candybar name
--	 time - the new time for this bar
-- returns true if succesful
function CandyBar:SetTime(name, time)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(time, 3, "number")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	handler.time = time
	if handler.starttime and handler.endtime then
		handler.endtime = handler.starttime + time 
	end
	return true
end

-- Set the time left for a bar.
-- Args: name - the candybar name
--	   time - time left on the bar
-- returns true if succesful

function CandyBar:SetTimeLeft(name, time)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(time, 3, "number")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	if handler.time < time or time < 0 then
		return
	end

	local e = handler.time - time
	if handler.starttime and handler.endtime then
		local d = handler.elapsed - e
		handler.starttime = handler.starttime + d
		handler.endtime = handler.endtime + d
	end

	handler.elapsed = e

	if handler.group then
		CandyBar:UpdateGroup(handler.group)
	end

	return true
end

-- Sets smooth coloring of the bar depending on time elapsed
-- Args: name - the candybar name
--	   c1 - c10 color order of the gradient
-- returns true when succesful
local cachedgradient = new() 
function CandyBar:SetGradient(name, c1, c2, ...)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(c1, 3, "string", "number", "nil")
	CandyBar:argCheck(c2, 4, "string", "number", "nil")

	local handler = CandyBar.handlers[name]

	if not handler then
		return
	end

	local gtable = new()
	local gradientid = nil
	local gmax = 0
	-- We got string values passed in, which means they're not rgb values
	-- directly, but a color most likely registered with paintchips
	if type(c1) == "string" then
		if not paint then
			CandyBar:error("You need the PaintChips-2.0 library if you don't pass in RGB pairs as colors.")
		end
		if not paint:GetRGBPercent(c1) then c1 = "green" end
		if not paint:GetRGBPercent(c2) then c2 = "red" end

		gtable[1] = new()
		gtable[2] = new()
	
		gradientid = c1 .. "_" .. c2
		local _
		_, gtable[1][1], gtable[1][2], gtable[1][3] =  paint:GetRGBPercent(c1)
		_, gtable[2][1], gtable[2][2], gtable[2][3] =  paint:GetRGBPercent(c2)
		gmax  = 2
		for i = 1, getn(arg) do 
			local c = arg[i] 
			if not c or not paint:GetRGBPercent(c) then
				break
			end
			gmax = gmax + 1
			gtable[gmax] = new() 
			local _
			_, gtable[gmax][1], gtable[gmax][2], gtable[gmax][3] = paint:GetRGBPercent(c)
			gradientid = gradientid .. "_" .. c
		end
		
	elseif type(c1) == "number" then
		-- It's a number, which means we should expect r,g,b values
		local n = getn(arg) -- select("#", ...)
		if n < 4 then CandyBar:error("Not enough extra arguments to :SetGradient, need at least 2 RGB pairs.") end
		gtable[1] = new()
		gtable[1][1] = c1
		gtable[1][2] = c2
		gtable[1][3] = arg[1] -- select(1, ...)
		gradientid = string.format("%d%d%d", c1, c2, gtable[1][3])
		gmax = 1
		
		local i = 2,2
		while i < n do --for i = 2, n, 3 do
			local r, g, b = arg[i], arg[i+1], arg[i+3] --select(i, ...)
			if r and g and b then
				gmax = gmax + 1
				gtable[gmax] = new()
				gtable[gmax][1], gtable[gmax][2], gtable[gmax][3] = r, g, b
				gradientid = string.format("%s_%d%d%d", gradientid, r, g, b)
			else
				break
			end
			i = i + 3
		end
	end

	for i = 1, gmax do
		if not gtable[i][4] then
			gtable[i][4] = 1
		end
		gtable[i][5] = (i-1) / (gmax-1)
	end
	
	if handler.gradienttable then
		for i,v in ipairs(handler.gradienttable) do
			v = del(v)
		end
		handler.gradienttable = del(handler.gradienttable)
	end
	handler.gradienttable = gtable
	handler.gradient = true
	handler.gradientid = gradientid
	if not cachedgradient[gradientid] then
		cachedgradient[gradientid] = new() 
	end
	handler.frame.statusbar:SetStatusBarColor(unpack(gtable[1], 1, 4))
	return true
end

local function setColor(color, alpha, b, a)
	CandyBar:argCheck(color, 3, "string", "number")
	local ctable = new()
	local _, rr, gg, bb, aa
	if type(color) == "string" then
		if not paint then
			CandyBar:error("You need the PaintChips-2.0 library if you don't pass in RGB pairs as colors.")
		end
		if not paint:GetRGBPercent(color) then
			return
		end
		CandyBar:argCheck(alpha, 4, "number", "nil")
		_, rr, gg, bb = paint:GetRGBPercent(color)
		aa = alpha and alpha or 1
	else
		CandyBar:argCheck(alpha, 4, "number")
		CandyBar:argCheck(b, 5, "number")
		CandyBar:argCheck(a, 6, "number", "nil")
		rr, gg, bb = color, alpha, b
		aa = a and a or 1 
	end
	tinsert(ctable,rr)
	tinsert(ctable,gg)
	tinsert(ctable,bb)
	tinsert(ctable,aa)
	return ctable
end

-- Set the color of the bar
-- Args: name - the candybar name
--	 color - new color of the bar
--	 alpha - new alpha of the bar
-- Setting the color will override smooth settings.
function CandyBar:SetColor(name, color, alpha, b, a)
	CandyBar:argCheck(name, 2, "string")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.color then
		handler.color = del(handler.color)
	end
	handler.color = t
	handler.gradient = nil
	
	handler.frame.statusbar:SetStatusBarColor(unpack(t, 1, 4))
	return true
end

-- Set the color of background of the bar
-- Args: name - the candybar name
--	 color - new color of the bar
-- 	 alpha - new alpha of the bar
-- Setting the color will override smooth settings.
function CandyBar:SetBackgroundColor(name, color, alpha, b, a)
	CandyBar:argCheck(name, 2, "string")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.bgcolor then
		handler.bgcolor = del(handler.bgcolor)
	end
	handler.bgcolor = t
	handler.frame.statusbarbg:SetStatusBarColor(unpack(t, 1, 4))

	return true
end

-- Set the color for the bar text
-- Args: name - name of the candybar
--	 color - new color of the text
--	 alpha - new alpha of the text
-- returns true when succesful
function CandyBar:SetTextColor(name, color, alpha, b, a)
	CandyBar:argCheck(name, 2, "string")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.textcolor then
		handler.textcolor = del(handler.textcolor)
	end
	handler.textcolor = t
	handler.frame.text:SetTextColor(unpack(t, 1, 4))

	return true
end

-- Set the color for the timer text
-- Args: name - name of the candybar
--	 color - new color of the text
--	 alpha - new alpha of the text
-- returns true when succesful
function CandyBar:SetTimerTextColor(name, color, alpha, b, a)
	CandyBar:argCheck(name, 2, "string")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	local t = setColor(color, alpha, b, a)
	if not t then return end

	if handler.timertextcolor then
		handler.timertextcolor = del(handler.timertextcolor)
	end
	handler.timertextcolor = t
	handler.frame.timertext:SetTextColor(unpack(t, 1, 4))

	return true
end

-- Set the text for the bar
-- Args: name - name of the candybar
--	   text - text to set it to
-- returns true when succesful
function CandyBar:SetText(name, text)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(text, 3, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	handler.text = text
	handler.frame.text:SetText(text)

	return true
end

-- Set the fontsize
-- Args: name - name of the candybar
-- 		 fontsize - new fontsize
-- returns true when succesful
function CandyBar:SetFontSize(name, fontsize)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(fontsize, 3, "number")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	
	local font, _, style = GameFontHighlight:GetFont()
	local timertextwidth = fontsize * 3.6
	local width = handler.width or defaults.width
	local f = handler.frame
	
	handler.fontsize = fontsize
	f.timertext:SetFont(font, fontsize, style)
	f.text:SetFont(font, fontsize, style)
	f.timertext:SetWidth(timertextwidth)
	f.text:SetWidth((width - timertextwidth) * .9)
	
	return true
end


-- Set the point where a bar should be anchored
-- Args: name -- name of the bar
-- 	 point -- anchor point
-- 	 rframe -- relative frame
-- 	 rpoint -- relative point
-- 	 xoffset -- x offset
-- 	 yoffset -- y offset
-- returns true when succesful
function CandyBar:SetPoint(name, point, rframe, rpoint, xoffset, yoffset)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(point, 3, "string")
	CandyBar:argCheck(rframe, 4, "table", "string", "nil")
	CandyBar:argCheck(rpoint, 5, "string", "nil")
	CandyBar:argCheck(xoffset, 6, "number", "nil")
	CandyBar:argCheck(yoffset, 7, "number", "nil")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	handler.point = point
	handler.rframe = rframe
	handler.rpoint = rpoint
	handler.xoffset = xoffset
	handler.yoffset = yoffset

	handler.frame:ClearAllPoints()
	handler.frame:SetPoint(point, rframe, rpoint, xoffset, yoffset)

	return true
end

function CandyBar:GetPoint(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	
	return handler.point, handler.rframe, handler.rpoint, handler.xoffset, handler.yoffset
end

function CandyBar:GetCenter(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	return handler.frame:GetCenter()
end

function CandyBar:GetOffsets(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	
	local bottom = handler.frame:GetBottom()
	local top = handler.frame:GetTop()
	local left = handler.frame:GetLeft()
	local right = handler.frame:GetRight()
	
	return left, top, bottom, right
end

function CandyBar:GetEffectiveScale(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	return handler.frame:GetEffectiveScale()
end

-- Set the width for a bar
-- Args: name - name of the candybar
--	   width - new width of the candybar
-- returns true when succesful
function CandyBar:SetWidth(name, width)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(width, 3, "number")

	local handler = CandyBar.handlers[name]
	if not CandyBar.handlers[name] then
		return
	end

	local height = handler.height or defaults.height
	local fontsize = handler.fontsize or defaults.fontsize
	local timertextwidth = fontsize * 3.6
	local f = handler.frame
	f:SetWidth(width + height)
	f.statusbar:SetWidth(width)
	f.statusbarbg:SetWidth(width)

	f.timertext:SetWidth(timertextwidth)
	f.text:SetWidth((width - timertextwidth) * .9)

	handler.width = width

	return true
end

-- Set the height for a bar
-- Args: name - name of the candybar
--	   height - new height for the bar
-- returs true when succesful
function CandyBar:SetHeight(name, height)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(height, 3, "number")

	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	
	local width = handler.width or defaults.width
	local f = handler.frame
	
	f:SetWidth(width + height)
	f:SetHeight(height)
	f.icon:SetWidth(height)
	f.icon:SetHeight(height)
	f.statusbar:SetHeight(height)
	f.statusbarbg:SetHeight(height)
	f.spark:SetHeight(height + 25)

	f.statusbarbg:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)
	f.statusbar:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)

	handler.height = height

	return true
end

-- Set the scale for a bar
-- Args: name - name of the candybar
-- 	 scale - new scale of the bar
-- returns true when succesful
function CandyBar:SetScale(name, scale)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(scale, 3, "number")

	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	handler.scale = scale

	handler.frame:SetScale(scale)

	return true
end

-- Set the time formatting function for a bar
-- Args: name - name of the candybar
--	   func - function that returns the formatted string
-- 		 a1-a10 - optional arguments to that function
-- returns true when succesful

function CandyBar:SetTimeFormat(name, func, ...)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(func, 3, "function")

	local handler = CandyBar.handlers[name]

	if not handler then
		return
	end
	handler.timeformat = func
	setArgs(handler, "timeformat", unpack(arg))

	return true
end

-- Set the completion function for a bar
-- Args: name - name of the candybar
--		   func - function to call upon ending of the bar
--	   a1 - a10 - arguments to pass to the function
-- returns true when succesful
function CandyBar:SetCompletion(name, func, ...)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(func, 3, "function")
	
	local handler = CandyBar.handlers[name]
	
	if not handler then
		return
	end
	handler.completion = func
	setArgs(handler, "completion", unpack(arg))
	
	return true
end

local function onClick()
	CandyBar:OnClick()
end

-- Set the on click function for a bar
-- Args: name - name of the candybar
--		   func - function to call when the bar is clicked
--	   a1 - a10 - arguments to pass to the function
-- returns true when succesful
function CandyBar:SetOnClick(name, func, ...)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(func, 3, "function", "nil")

	local handler = CandyBar.handlers[name]
	
	if not handler then
		return
	end
	handler.onclick = func
	setArgs(handler, "onclick", unpack(arg))
	
	local frame = handler.frame
	if func then
		-- enable mouse
		frame:EnableMouse(true)
		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up", "RightButtonDown")
		frame:SetScript("OnClick", onClick)
		frame.icon:EnableMouse(true)
		frame.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up", "RightButtonDown")
		frame.icon:SetScript("OnClick", onClick)
	else
		frame:EnableMouse(false)
		frame:RegisterForClicks()
		frame:SetScript("OnClick", nil)
		frame.icon:EnableMouse(false)
		frame.icon:RegisterForClicks()
		frame.icon:SetScript("OnClick", nil)
	end

	return true

end

-- Set the "on size" function for a group
-- Args: name - name of the candybar
--		   func - function to call when a group changes size
--	     ...  - arguments to pass to the function
--              (the new size of the bar, in pixels, will be appended last)
-- returns true when succesful
function CandyBar:SetOnSizeGroup(name, func, ...)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(func, 3, "function", "nil")

	local group = assert(CandyBar.groups[name])

	group.onsize = func
	setArgs(group, "onsize", unpack(arg))
end


-- Set the texture for a bar
-- Args: name - name of the candybar
--	 texture - new texture, if passed nil, the texture is reset to default
-- returns true when succesful
function CandyBar:SetTexture(name, texture)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(texture, 3, "string", "nil")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	if not texture then
		texture = defaults.texture
	end

	handler.texture = texture

	handler.frame.statusbar:SetStatusBarTexture(texture)
	handler.frame.statusbarbg:SetStatusBarTexture(texture)

	return true
end

-- Set the icon on a bar
-- Args: name - name of the candybar
-- 	 icon - icon path, nil removes the icon
--   left, right, top, bottom - optional texture coordinates
-- returns true when succesful
function CandyBar:SetIcon(name, icon, left, right, top, bottom)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(icon, 3, "string", "nil")
	CandyBar:argCheck(left, 4, "number", "nil")
	CandyBar:argCheck(right, 5, "number", "nil")
	CandyBar:argCheck(top, 6, "number", "nil")
	CandyBar:argCheck(bottom, 7, "number", "nil")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	handler.icon = icon

	if not icon then
		handler.frame.icon:Hide()
	else
		left = left or 0.07
		right = right or 0.93
		top = top or 0.07
		bottom = bottom or 0.93
		handler.frame.icon:SetNormalTexture(icon)
		handler.frame.icon:GetNormalTexture():SetTexCoord(left, right, top, bottom)
		handler.frame.icon:Show()
	end

	return true
end

-- Set the icon position on bar
-- Args: name - name of the candybar
--	 position  - icon position, "LEFT" or "RIGHT"
-- returns true when succesful
function CandyBar:SetIconPosition(name, position)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(position, 3, "string", "LEFT", "RIGHT")

	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	handler.iconpos = position
	if handler.running then
		handler.frame.icon:SetPoint("LEFT", handler.frame, position, 0, 0)
	end
	return true
end

-- Sets the fading style of a candybar
-- args: name - name of the candybar
--			 time - duration of the fade (default .5 seconds), negative to keep the bar on screen
-- returns true when succesful
function CandyBar:SetFade(name, time)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(time, 3, "number")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	handler.fadetime = time
	handler.fadeout = true
	handler.stayonscreen = (handler.fadetime < 0)
    
	return true
end

function CandyBar:SetReversed(name, reversed)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(reversed, 3, "boolean", "nil")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	
	handler.reversed = reversed
	return true
end

function CandyBar:IsReversed(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	return handler.reversed
end


-- Registers a candybar with a certain candybar group
-- args: name - name of the candybar
--	   group - group to register the bar with
-- returns true when succesful
function CandyBar:RegisterWithGroup(name, group)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(group, 3, "string")
	
	local handler = CandyBar.handlers[name]
	local gtable = CandyBar.groups[group]
	if not handler or not gtable then
		return
	end

	CandyBar:UnregisterWithGroup(name)

	tinsert(gtable.bars, name)
	-- CandyBar.groups[group].bars[name] = name
	handler.group = group
	CandyBar:UpdateGroup(group)

	return true
end

-- Unregisters a candybar from its group
-- args: name - name of the candybar
-- returns true when succesful

function CandyBar:UnregisterWithGroup(name)
	CandyBar:argCheck(name, 2, "string")
	
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	--if not CandyBar.handlers[name].group then return end

	local group = handler.group
	local gtable = CandyBar.groups[group]
	if not gtable then
		return
	end

	for k,v in pairs(gtable.bars) do
		if v == name then
			table.remove(gtable.bars, k)
		end
	end
	-- CandyBar.groups[group].bars[name] = nil
	handler.group = nil

	CandyBar:UpdateGroup(group)

	return true
end

-- Register a Candybar group
-- Args: name - name of the candybar group
-- returns true when succesful
function CandyBar:RegisterGroup(name)
	CandyBar:argCheck(name, 2, "string")
	
	if CandyBar.groups[name] then
		return
	end

	local t = new()

	t.point = "CENTER"
	t.rframe = UIParent
	t.rpoint = "CENTER"
	t.xoffset = 0
	t.yoffset = 0
	t.bars = new()
	t.height = -1

	CandyBar.groups[name] = t
	return true
end

-- Unregister a candybar group
-- Args: a1-a2 candybar group ids
-- returns true when succesful
function CandyBar:UnregisterGroup(a1, ...)
	CandyBar:argCheck(a1, 2, "string")
	if not CandyBar.groups[a1] then
		return
	end
	CandyBar.groups[a1].bars = del(CandyBar.groups[a1].bars)
	CandyBar.groups[a1] = del(CandyBar.groups[a1])

	if getn(arg) > 0 then
		CandyBar:UnregisterGroup(unpack(arg))
	end

	return true
end

-- Checks if a group is registered
-- Args: name - Candybar group
-- returns true if the candybar group is registered
function CandyBar:IsGroupRegistered(name)
	CandyBar:argCheck(name, 2, "string")
	return CandyBar.groups[name] and true or false
end

-- Checks if a bar is registered with a group
-- Args: name - Candybar name
--	   group - group id [optional]
-- returns true is the candybar is registered with a/the group
function CandyBar:IsRegisteredWithGroup(name, group)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(group, 3, "string", "nil")
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	if group then
		if not CandyBar.groups[group] then
			return false
		end
		if handler.group == group then
			return true
		end
	elseif handler.group then
		return true
	end
	return false
end


-- Set the point for a CandyBargroup
-- 	 point -- anchor point
-- 	 rframe -- relative frame
-- 	 rpoint -- relative point
-- 	 xoffset [optional] -- x offset
-- 	 yoffset [optional] -- y offset
-- The first bar of the group will be anchored at the anchor.
-- returns true when succesful
function CandyBar:SetGroupPoint(name, point, rframe, rpoint, xoffset, yoffset)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(point, 3, "string")
	CandyBar:argCheck(rframe, 4, "string", "table", "nil")
	CandyBar:argCheck(rpoint, 5, "string", "nil")
	CandyBar:argCheck(xoffset, 6, "number", "nil")
	CandyBar:argCheck(yoffset, 6, "number", "nil")
	
	local group = CandyBar.groups[name]
	if not group then
		return
	end

	group.point = point
	group.rframe = rframe
	group.rpoint = rpoint
	group.xoffset = xoffset
	group.yoffset = yoffset
	CandyBar:UpdateGroup(name)
	return true
end

-- SetGroupGrowth - sets the group to grow up or down
-- Args: name - name of the candybar group
--	   growup - true if growing up, false for growing down
-- returns true when succesful
function CandyBar:SetGroupGrowth(name, growup)
	CandyBar:argCheck(name, 2, "string")
	CandyBar:argCheck(growup, 3, "boolean")
	
	local group = CandyBar.groups[name]
	if not group then
		return
	end

	group.growup = growup

	CandyBar:UpdateGroup(name)

	return true
end

-- SetGroupVerticalSpacing - sets a vertical spacing between the bars of the group
-- Args: name - name of the candybar group
--	   spacing - y offset for the bars
-- returns true when succesful
function CandyBar:SetGroupVerticalSpacing(name, spacing)
	CandyBar:argCheck(name, 2, "string");
	CandyBar:argCheck(spacing, 3, "number");
	
	local group = CandyBar.groups[name]
	if not group then
		return
	end

	group.vertspacing = spacing;

	CandyBar:UpdateGroup(name)

	return true
end

local mysort = function(a, b)
	return CandyBar.handlers[a].endtime < CandyBar.handlers[b].endtime
end
function CandyBar:SortGroup(name)
	local group = CandyBar.groups[name]
	if not group then
		return
	end
	table.sort(group.bars, mysort)
end

-- internal method
-- UpdateGroup - updates the location of bars in a group
-- Args: name - name of the candybar group
-- returns true when succesful

function CandyBar:UpdateGroup(name)
	local group = CandyBar.groups[name]
	if not CandyBar.groups[name] then
		return
	end

	local point = group.point
	local rframe = group.rframe
	local rpoint = group.rpoint
	local xoffset = group.xoffset
	local yoffset = group.yoffset
	local m = -1
	if group.growup then
		m = 1
	end
	local vertspacing = group.vertspacing or 0

	local bar = 0
	local barh = 0

	CandyBar:SortGroup(name)

	for c,n in pairs(group.bars) do
		local handler = CandyBar.handlers[n]
		if handler then
			if handler.frame:IsShown() then
				CandyBar:SetPoint(n, point, rframe, rpoint, xoffset, yoffset + (m * bar))
				barh = handler.height or defaults.height
				bar = bar + barh + vertspacing
			end
		end
	end
	
	if group.height ~= bar then
		group.height = bar
		if group.onsize then
			group.onsize(getArgs(group, "onsize", bar))
		end
	end
	
	return true
end

function CandyBar:GetNextBarPointInGroup(name)
	CandyBar:argCheck(name, 2, "string")
	
	local group = CandyBar.groups[name]
	if not CandyBar.groups[name] then
		return
	end
	
	local xoffset = group.xoffset
	local yoffset = group.yoffset
	local m = -1
	if group.growup then
		m = 1
	end
	
	local bar = 0
	local barh = 0
	
	local vertspacing = group.vertspacing or 0
	
	for c,n in pairs(group.bars) do
		local handler = CandyBar.handlers[n]
		if handler then
			if handler.frame:IsShown() then
				barh = handler.height or defaults.height
				bar = bar + barh + vertspacing
			end
		end
	end
	
	return xoffset, yoffset + (m * bar)
end

-- Internal Method
-- Update a bar on screen
function CandyBar:Update(name)
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	local t = handler.time - handler.elapsed
	handler.slow = t>11

	local timetext
	if handler.timeformat then
		timetext = handler.timeformat(t, getArgs(handler, "timeformat"))
	else
		local h = floor(t/3600)
		local m = t - (h*3600)
		m = floor(m/60)
		local s = t - ((h*3600) + (m*60))
		if h > 0 then
			timetext = ("%d:%02d"):format(h, m)
		elseif m > 0 then
			timetext = string.format("%d:%02d", m, floor(s))
		elseif s < 10 then
			timetext = string.format("%1.1f", s)
		else
			timetext = string.format("%.0f", floor(s))
		end
	end
	handler.frame.timertext:SetText(timetext)

	local perc = t / handler.time

	local reversed = handler.reversed
	handler.frame.statusbar:SetValue(reversed and 1-perc or perc)

	local width = handler.width or defaults.width

	local sp = width * perc
	sp = reversed and -sp or sp
	handler.frame.spark:SetPoint("CENTER", handler.frame.statusbar, reversed and "RIGHT" or "LEFT", sp, 0)

	if handler.gradient then
		local p = floor( (handler.elapsed / handler.time) * 100 ) / 100
		local currentGradient = cachedgradient[handler.gradientid][p]
		if currentGradient==nil then
			-- find the appropriate start/end
			local gstart, gend, gp
			for i = 1, getn(handler.gradienttable) - 1 do
				if handler.gradienttable[i][5] < p and p <= handler.gradienttable[i+1][5] then
					-- the bounds are to assure no divide by zero error here.
	
					gstart = handler.gradienttable[i]
					gend = handler.gradienttable[i+1]
					gp = (p - gstart[5]) / (gend[5] - gstart[5])
				end
			end
			if gstart and gend then
				-- calculate new gradient
				currentGradient = new()
				for i = 1, 4 do
					-- these may be the same.. but I'm lazy to make sure.
					tinsert(currentGradient, gstart[i]*(1-gp) + gend[i]*(gp))
				end
				cachedgradient[handler.gradientid][p] = currentGradient
			end
		end
		if currentGradient~=nil then
			handler.frame.statusbar:SetStatusBarColor(unpack(currentGradient))
		end
	end
end

-- Intenal Method
-- Fades the bar out when it's complete.
function CandyBar:UpdateFade(name)
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	if not handler.fading then
		return
	end
	if handler.stayonscreen then
		return
	end

	-- if the fade is done go and keel the bar.
	if handler.fadeelapsed > handler.fadetime then
		handler.fading = nil
		handler.starttime = nil
		handler.endtime = 0
		handler.frame:Hide()
		if handler.group then
			CandyBar:UpdateGroup(handler.group)
		end
		if handler.fireforget then
			return CandyBar:Unregister(name)
		end
	else -- we're fading, set the alpha for the texts, statusbar and background. fade from default to 0 in the time given.
		local t = handler.fadetime - CandyBar.handlers[name].fadeelapsed
		local p = t / handler.fadetime
		local color = handler.color or defaults.color
		local bgcolor = handler.bgcolor or defaults.bgcolor
		local textcolor = handler.textcolor or defaults.textcolor
		local timertextcolor = handler.timertextcolor or defaults.timertextcolor
		local colora = color[4] * p
		local bgcolora = bgcolor[4] * p
		local textcolora = textcolor[4] * p
		local timertextcolora = timertextcolor[4] * p

		handler.frame.statusbarbg:SetStatusBarColor(bgcolor[1], bgcolor[2], bgcolor[3], bgcolora)
		handler.frame.statusbar:SetStatusBarColor(color[1], color[2], color[3], colora)
		handler.frame.text:SetTextColor(textcolor[1], textcolor[2], textcolor[3], textcolora)
		handler.frame.timertext:SetTextColor(timertextcolor[1], timertextcolor[2], timertextcolor[3], timertextcolora)
		handler.frame.icon:SetAlpha(p)
	end
	return true
end

-- Internal Method
-- Create and return a new bar frame, recycles where needed
-- Name - which candybar is this for
-- Returns the frame
function CandyBar:AcquireBarFrame(name)
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end

	local f = handler.frame

	local color = handler.color or defaults.color
	local bgcolor = handler.bgcolor or defaults.bgcolor
	local icon = handler.icon or nil
	local iconpos = handler.iconpos or defaults.iconpos
	local texture = handler.texture or defaults.texture
	local width = handler.width or defaults.width
	local height = handler.height or defaults.height
	local point = handler.point or defaults.point
	local rframe = handler.rframe or defaults.rframe
	local rpoint = handler.rpoint or defaults.rpoint
	local xoffset = handler.xoffset or defaults.xoffset
	local yoffset = handler.yoffset or defaults.yoffset
	local text = handler.text or defaults.text
	local fontsize = handler.fontsize or defaults.fontsize
	local textcolor = handler.textcolor or defaults.textcolor
	local timertextcolor = handler.timertextcolor or defaults.timertextcolor
	local scale = handler.scale or defaults.scale
	if not scale then
		scale = 1
	end
	local timertextwidth = fontsize * 3.6
	local font, _, style = GameFontHighlight:GetFont()

	if not f and getn(CandyBar.framepool) > 0 then
		f = table.remove(CandyBar.framepool)
	end

	if not f then
		f = CreateFrame("Button", nil, UIParent)
	end
	f:Hide()
	f.owner = name
	-- yes we add the height to the width for the icon.
	f:SetWidth(width + height)
	f:SetHeight(height)
	f:ClearAllPoints()
	f:SetPoint(point, rframe, rpoint, xoffset, yoffset)
	-- disable mouse
	f:EnableMouse(false)
	f:RegisterForClicks()
	f:SetScript("OnClick", nil)
	f:SetScale(scale)

	if not f.icon then
		f.icon = CreateFrame("Button", nil, f)
	end
	f.icon:ClearAllPoints()
	f.icon.owner = name
	f.icon:EnableMouse(false)
	f.icon:RegisterForClicks()
	f.icon:SetScript("OnClick", nil)
	-- an icno is square and the height of the bar, so yes 2x height there
	f.icon:SetHeight(height)
	f.icon:SetWidth(height)
	f.icon:SetPoint("LEFT", f, iconpos, 0, 0)
	f.icon:SetNormalTexture(icon)
	if f.icon:GetNormalTexture() then 
		f.icon:GetNormalTexture():SetTexCoord( 0.07, 0.93, 0.07, 0.93)
	end 
	f.icon:SetAlpha(1)
	f.icon:Show()

	if not f.statusbarbg then
		f.statusbarbg = CreateFrame("StatusBar", nil, f)
		f.statusbarbg:SetFrameLevel(f.statusbarbg:GetFrameLevel() - 1)
	end
	f.statusbarbg:ClearAllPoints()
	f.statusbarbg:SetHeight(height)
	f.statusbarbg:SetWidth(width)
	-- offset the height of the frame on the x-axis for the icon.
	f.statusbarbg:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)
	f.statusbarbg:SetStatusBarTexture(texture)
	f.statusbarbg:SetStatusBarColor(bgcolor[1],bgcolor[2],bgcolor[3],bgcolor[4])
	f.statusbarbg:SetMinMaxValues(0,100)
	f.statusbarbg:SetValue(100)

	if not f.statusbar then
		f.statusbar = CreateFrame("StatusBar", nil, f)
	end
	f.statusbar:ClearAllPoints()
	f.statusbar:SetHeight(height)
	f.statusbar:SetWidth(width)
	-- offset the height of the frame on the x-axis for the icon.
	f.statusbar:SetPoint("TOPLEFT", f, "TOPLEFT", height, 0)
	f.statusbar:SetStatusBarTexture(texture)
	f.statusbar:SetStatusBarColor(color[1], color[2], color[3], color[4])
	f.statusbar:SetMinMaxValues(0,1)
	f.statusbar:SetValue(1)


	if not f.spark then
		f.spark = f.statusbar:CreateTexture(nil, "OVERLAY")
	end
	f.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	f.spark:SetWidth(16)
	f.spark:SetHeight(height + 25)
	f.spark:SetBlendMode("ADD")
	f.spark:Show()

	if not f.timertext then
		f.timertext = f.statusbar:CreateFontString(nil, "OVERLAY")
	end
	f.timertext:SetFontObject(GameFontHighlight)
	f.timertext:SetFont(font, fontsize, style)
	f.timertext:SetHeight(height)
	f.timertext:SetWidth(timertextwidth)
	f.timertext:SetPoint("LEFT", f.statusbar, "LEFT", 0, 0)
	f.timertext:SetJustifyH("RIGHT")
	f.timertext:SetText("")
	f.timertext:SetTextColor(timertextcolor[1], timertextcolor[2], timertextcolor[3], timertextcolor[4])

	if not f.text then
		f.text = f.statusbar:CreateFontString(nil, "OVERLAY")
	end
	f.text:SetFontObject(GameFontHighlight)
	f.text:SetFont(font, fontsize, style)
	f.text:SetHeight(height)
	f.text:SetWidth((width - timertextwidth) *.9)
	f.text:SetPoint("RIGHT", f.statusbar, "RIGHT", 0, 0)
	f.text:SetJustifyH("LEFT")
	f.text:SetText(text)
	f.text:SetTextColor(textcolor[1], textcolor[2], textcolor[3], textcolor[4])

	if handler.onclick then
		f:EnableMouse(true)
		f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up", "RightButtonDown")
		f:SetScript("OnClick", onClick)
		f.icon:EnableMouse(true)
		f.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up", "RightButtonDown")
		f.icon:SetScript("OnClick", onClick)
	end
	
	return f
end

-- Internal Method
-- Releases a bar frame into the pool
-- Name - which candybar's frame are we're releasing
-- Returns true when succesful
function CandyBar:ReleaseBarFrame(name)
	local handler = CandyBar.handlers[name]
	if not handler then
		return
	end
	if not handler.frame then
		return
	end
	handler.frame:Hide()
	tinsert(CandyBar.framepool, handler.frame)
	return true
end

-- Internal Method
-- Executes the OnClick function of a bar
function CandyBar:OnClick()
	if not this.owner then
		return
	end
	local handler = CandyBar.handlers[this.owner]
	if not handler then
		return
	end
	if not handler.onclick then
		return
	end
	-- pass the name of the handlers first, and the button clicked as the second argument
	local button = arg1
	handler.onclick(this.owner, button, getArgs(handler, "onclick"))
	return true
end

-- Internal Method
-- on update handler
local lastSlow = 0
function CandyBar:OnUpdate()
	local doslow
	lastSlow = lastSlow + arg1
	if lastSlow > 0.04 then
		doslow = true
		lastSlow = 0
	end

	local t
	for i,v in pairs(this.owner.handlers) do
		if not t then t = GetTime() end
		if (not doslow) and v.slow then
			-- nada
		elseif v.running then
			v.elapsed = t - v.starttime
			if v.endtime <= t then
				local c = this.owner.handlers[i]
				if c.completion then
					if not c.completion(getArgs(c, "completion")) then
						this.owner:Stop(i)
					end
				else
					this.owner:Stop(i)
				end
			else
				this.owner:Update(i)
			end
		elseif v.fading and not v.stayonscreen then
			v.fadeelapsed = (t - v.endtime)
			this.owner:UpdateFade(i)
		end
	end
end

-- Internal Method
-- returns true if we have any handlers
function CandyBar:HasHandlers()
	return next(CandyBar.handlers) and true
end

------------------------------
--	  Mixins Methods	  --
------------------------------

CandyBar.IsCandyBarRegistered = CandyBar.IsRegistered
CandyBar.StartCandyBar = CandyBar.Start
CandyBar.StopCandyBar = CandyBar.Stop
CandyBar.PauseCandyBar = CandyBar.Pause
CandyBar.CandyBarStatus = CandyBar.Status
CandyBar.SetCandyBarTexture = CandyBar.SetTexture
CandyBar.SetCandyBarTime = CandyBar.SetTime
CandyBar.SetCandyBarColor = CandyBar.SetColor
CandyBar.SetCandyBarText = CandyBar.SetText
CandyBar.SetCandyBarIcon = CandyBar.SetIcon
CandyBar.SetCandyBarIconPosition = CandyBar.SetIconPosition
CandyBar.SetCandyBarBackgroundColor = CandyBar.SetBackgroundColor
CandyBar.SetCandyBarTextColor = CandyBar.SetTextColor
CandyBar.SetCandyBarTimerTextColor = CandyBar.SetTimerTextColor
CandyBar.SetCandyBarFontSize = CandyBar.SetFontSize
CandyBar.SetCandyBarPoint = CandyBar.SetPoint
CandyBar.GetCandyBarPoint = CandyBar.GetPoint
CandyBar.GetCandyBarCenter = CandyBar.GetCenter
CandyBar.GetCandyBarOffsets = CandyBar.GetOffsets
CandyBar.GetCandyBarEffectiveScale = CandyBar.GetEffectiveScale
CandyBar.SetCandyBarScale = CandyBar.SetScale
CandyBar.SetCandyBarTimeFormat = CandyBar.SetTimeFormat
CandyBar.SetCandyBarTimeLeft = CandyBar.SetTimeLeft
CandyBar.SetCandyBarCompletion = CandyBar.SetCompletion
CandyBar.RegisterCandyBarGroup = CandyBar.RegisterGroup
CandyBar.UnregisterCandyBarGroup = CandyBar.UnregisterGroup
CandyBar.IsCandyBarGroupRegistered = CandyBar.IsGroupRegistered
CandyBar.SetCandyBarGroupPoint = CandyBar.SetGroupPoint
CandyBar.SetCandyBarGroupGrowth = CandyBar.SetGroupGrowth
CandyBar.SetCandyBarGroupVerticalSpacing = CandyBar.SetGroupVerticalSpacing
CandyBar.UpdateCandyBarGroup = CandyBar.UpdateGroup
CandyBar.GetCandyBarNextBarPointInGroup = CandyBar.GetNextBarPointInGroup
CandyBar.SetCandyBarOnClick = CandyBar.SetOnClick
CandyBar.SetCandyBarFade = CandyBar.SetFade
CandyBar.RegisterCandyBarWithGroup = CandyBar.RegisterWithGroup
CandyBar.UnregisterCandyBarWithGroup = CandyBar.UnregisterWithGroup
CandyBar.IsCandyBarRegisteredWithGroup = CandyBar.IsRegisteredWithGroup
CandyBar.SetCandyBarReversed = CandyBar.SetReversed
CandyBar.IsCandyBarReversed = CandyBar.IsReversed
CandyBar.SetCandyBarOnClick = CandyBar.SetOnClick
CandyBar.SetCandyBarHeight = CandyBar.SetHeight
CandyBar.SetCandyBarWidth = CandyBar.SetWidth
CandyBar.SetCandyBarOnSizeGroup = CandyBar.SetOnSizeGroup

function CandyBar:RegisterCandyBar(name, time, text, icon, ...)
	if not CandyBar.addons[self] then
		CandyBar.addons[self] = new()
	end
	CandyBar.addons[self][name] = CandyBar:Register(name, time, text, icon, unpack(arg))
end

function CandyBar:UnregisterCandyBar(a1, ...)
	CandyBar:argCheck(a1, 2, "string")
	if CandyBar.addons[self] then
		CandyBar.addons[self][a1] = nil
	end
	CandyBar:Unregister(a1)
	if getn(arg)>0 then
		self:UnregisterCandyBar(unpack(arg))
	end
end

function CandyBar:OnEmbedDisable(target)
	if self.addons[target] then
		for i in pairs(self.addons[target]) do
			self:Unregister(i)
		end
	end
end

--------------------------------
--    Load this bitch!        --
--------------------------------

local function activate(self, oldLib, oldDeactivate)
	CandyBar = self

	self.frame = oldLib and (oldLib.frame or oldLib.var and oldLib.var.frame)
	if not self.frame then
		self.frame = CreateFrame("Frame")
		self.frame:Hide()
		self.frame.name = "CandyBar-2.0 Frame"
	end

	self.handlers = oldLib and (oldLib.handlers or oldLib.var and oldLib.var.handlers) or {}
	self.groups = oldLib and (oldLib.groups or oldLib.var and oldLib.var.groups) or {}
	self.framepool = oldLib and (oldLib.framepool or oldLib.var and oldLib.var.framepool) or {}
	self.addons = oldLib and (oldLib.addons or oldLib.var and oldLib.var.addons) or {}

	self.frame:SetScript("OnUpdate", self.OnUpdate)
	self.frame.owner = self

	self:activate(oldLib, oldDeactivate)

	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

local function external(self, major, instance)
	if major == "PaintChips-2.0" then
		paint = instance
	end
end

AceLibrary:Register(CandyBar, vmajor, vminor, activate, nil, external)

