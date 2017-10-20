--[[
Name: ParserLib
Revision: $Revision: 27050 $
Author(s): rophy (rophy123@gmail.com)
Website: http://www.wowace.com/index.php/ParserLib
Documentation: http://www.wowace.com/index.php/ParserLib
SVN: http://svn.wowace.com/wowace/trunk/ParserLib
Description: An embedded combat log parser, which works on all localizations.
Dependencies: None
]]

---------------------------------------------------------------------------
--	To Get an instance of ParserLib, call this:
-- 	local parser = ParserLib:GetInstance(version)
-- 	where the version is the variable 'vmajor' you see here.
---------------------------------------------------------------------------
local vmajor, vminor = "1.1", tonumber(string.sub("$Revision: 27050 $", 12, -3))

local stubvarname = "TekLibStub"
local libvarname = "ParserLib"

local _G = getfenv(0)

-- Check to see if an update is needed
-- if not then just return out now before we do anything
local libobj = _G[libvarname]
if libobj and not libobj:NeedsUpgraded(vmajor, vminor) then return end

local function print(msg, r, g, b)
	ChatFrame1:AddMessage(string.format("<%s-%s-%s> %s", libvarname, vmajor, vminor, msg), r, g, b)
end

---------------------------------------------------------------------------
-- Embedded Library Registration Stub
-- Written by Iriel <iriel@vigilance-committee.org>
-- Version 0.1 - 2006-03-05
-- Modified by Tekkub <tekkub@gmail.com>
---------------------------------------------------------------------------

local stubobj = _G[stubvarname]
if not stubobj then
	stubobj = {}
	setglobal(stubvarname, stubobj)

	-- Instance replacement method, replace contents of old with that of new
	function stubobj:ReplaceInstance(old, new)
		for k,v in pairs(old) do old[k]=nil end
		for k,v in pairs(new) do old[k]=v end
	end

	-- Get a new copy of the stub
	function stubobj:NewStub(name)
		local newStub = {}
		self:ReplaceInstance(newStub, self)
		newStub.libName = name
		newStub.lastVersion = ''
		newStub.versions = {}
		return newStub
	end

	-- Get instance version
	function stubobj:NeedsUpgraded(vmajor, vminor)
		local versionData = self.versions[vmajor]
		if not versionData or versionData.minor < vminor then return true end
	end

	-- Get instance version
	function stubobj:GetInstance(version)
		if not version then version = self.lastVersion end
		local versionData = self.versions[version]
		if not versionData then print(string.format("<%s> Cannot find library version: %s", self.libName, version or "")) return end
		return versionData.instance
	end

	-- Register new instance
	function stubobj:Register(newInstance)
		local version,minor = newInstance:GetLibraryVersion()
		self.lastVersion = version
		local versionData = self.versions[version]
		if not versionData then
				-- This one is new!
				versionData = {
					instance = newInstance,
					minor = minor,
					old = {},
				}
				self.versions[version] = versionData
				newInstance:LibActivate(self)
				return newInstance
		end
		-- This is an update
		local oldInstance = versionData.instance
		local oldList = versionData.old
		versionData.instance = newInstance
		versionData.minor = minor
		local skipCopy = newInstance:LibActivate(self, oldInstance, oldList)
		table.insert(oldList, oldInstance)
		if not skipCopy then
				for i, old in ipairs(oldList) do self:ReplaceInstance(old, newInstance) end
		end
		return newInstance
	end
end

if not libobj then
	libobj = stubobj:NewStub(libvarname)
	setglobal(libvarname, libobj)
end

local lib = {}

-- Return the library's current version
function lib:GetLibraryVersion()
	return vmajor, vminor
end

-- Activate a new instance of this library
function lib:LibActivate(stub, oldLib, oldList)
	local maj, min = self:GetLibraryVersion()

	if oldLib then
		local omaj, omin = oldLib:GetLibraryVersion()
		----------------------------------------------------
		-- ********************************************** --
		-- **** Copy over any old data you need here **** --
		-- ********************************************** --
		----------------------------------------------------
		self.frame = oldLib.frame
		self:OnLoad()

		if omin < 11 and oldLib.clients then
			for event in pairs(oldLib.clients) do
				for i in pairs(oldLib.clients[event]) do
					if type(oldLib.clients[event][i]["func"]) == "string" then
						oldLib.clients[event][i]["func"] = _G[oldLib.clients[event][i]["func"]]
					end
				end
			end
		end
		self.clients = oldLib.clients
	else
		---------------------------------------------------
		-- ********************************************* --
		-- **** Do any initialization you need here **** --
		-- ********************************************* --
		---------------------------------------------------
		self:OnLoad()
	end
	-- nil return makes stub do object copy
end

----------------------------------------------
--          *ParserLib Public Methods*      --
----------------------------------------------

-- Currently supported event list.
local supportedEvents = {
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
	"CHAT_MSG_COMBAT_FACTION_CHANGE",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES",
	"CHAT_MSG_COMBAT_FRIENDLY_DEATH",
	"CHAT_MSG_COMBAT_HONOR_GAIN",
	"CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS",
	"CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES",
	"CHAT_MSG_COMBAT_HOSTILE_DEATH",
	"CHAT_MSG_COMBAT_PARTY_HITS",
	"CHAT_MSG_COMBAT_PARTY_MISSES",
	"CHAT_MSG_COMBAT_PET_HITS",
	"CHAT_MSG_COMBAT_PET_MISSES",
	"CHAT_MSG_COMBAT_SELF_HITS",
	"CHAT_MSG_COMBAT_SELF_MISSES",
	"CHAT_MSG_COMBAT_XP_GAIN",
	"CHAT_MSG_SPELL_AURA_GONE_OTHER",
	"CHAT_MSG_SPELL_AURA_GONE_SELF",
	"CHAT_MSG_SPELL_AURA_GONE_PARTY",
	"CHAT_MSG_SPELL_BREAK_AURA",
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
	"CHAT_MSG_SPELL_FAILED_LOCALPLAYER",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_ITEM_ENCHANTMENTS",
	"CHAT_MSG_SPELL_PARTY_BUFF",
	"CHAT_MSG_SPELL_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PET_BUFF",
	"CHAT_MSG_SPELL_PET_DAMAGE",
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
	"CHAT_MSG_SPELL_TRADESKILLS",
}

-- Register an event to ParserLib.
function lib:RegisterEvent(addonID, event, handler)

	local eventExist
	for i, v in pairs(supportedEvents) do
		if v == event then
			eventExist = true
			break
		end
	end

	if not eventExist then
		self:Print( string.format("Event %s is not supported. (AddOnID %s)", event, addonID), 1, 0, 0 )
		return
	end

	-- self:Print(string.format("Registering %s for addon %s.", event, addonID) ) -- debug

	if type(handler) == "string" then handler = _G[handler] end

	-- if not handler then self:Print("nil handler from " .. addonID, 1, 0, 0) end -- debug

	if self.clients[event] == nil then
		self.clients[event] = {}
	end

	table.insert(self.clients[event], {
		id = addonID,
		func = handler
	})
	self.frame:RegisterEvent(event)
end

-- Check if you have registered an event.
function lib:IsEventRegistered(addonID, event)
	if self.clients[event] then
		for i, v in pairs(self.clients[event]) do
			if v.id == addonID then return true end
		end
	end
end

-- Unregister an event.
function lib:UnregisterEvent(addonID, event)
	local empty = true

	if not self.clients[event] then return end

	for i, v in pairs(self.clients[event]) do
		if v.id == addonID then
			-- self:Print( format("Removing %s from %s", v.id, event) ) -- debug
			table.remove(self.clients[event], i)
		else
			empty = false
		end
	end

	if empty then
		-- self:Print("Unregistering event " .. event) -- debug
		self.frame:UnregisterEvent(event)
		self.clients[event] = nil
	end
end

-- Unregister all events.
function lib:UnregisterAllEvents(addonID)
	local event
	for event in pairs(self.clients) do
		self:UnregisterEvent(addonID, event)
	end
end

local customPatterns = {}
-- Parse custom messages, check documentation.html for more info.
function lib:Deformat(text, pattern)
	if not customPatterns[pattern] then
		customPatterns[pattern] = self:Curry(pattern)
	end
	return customPatterns[pattern](text)
end

--------------------------------------------------------
--       Methods to control ParserLib behaviour       --
--------------------------------------------------------

---------------------------------------------------
--     *End of ParserLib Public Methods*         --
---------------------------------------------------

----------------------------------------------
--     ParserLib Private Methods            --
----------------------------------------------

local eventTable = nil
local patternTable = nil
local info = nil
local rInfo = nil
local timer = nil
local cache = nil
local trailers = nil

-- Constants
ParserLib_SELF = 103
ParserLib_MELEE = 112
ParserLib_DAMAGESHIELD = 113

-- lib.timing = true -- timer

-- Stub function called by frame.OnEvent
local function ParserOnEvent() lib:OnEvent() end

-- Sort the pattern so that they can be parsed in a correct sequence, will only do once for each registered event.
local function PatternCompare(a, b)

	local pa = _G[a]
	local pb = _G[b]

	if not pa then ChatFrame1:AddMessage("|cffff0000Nil pattern: ".. a.."|r") end
	if not pb then ChatFrame1:AddMessage("|cffff0000Nil pattern: ".. b.."|r") end

	local ca=0
	for _ in string.gfind(pa,"%%%d?%$?[sd]") do ca=ca+1 end
	local cb=0
	for _ in string.gfind(pb,"%%%d?%$?[sd]") do cb=cb+1 end

	pa = string.gsub(pa,"%%%d?%$?[sd]", "")
	pb = string.gsub(pb,"%%%d?%$?[sd]", "")

	if string.len(pa) == string.len(pb) then
		return ca < cb
	else
		return string.len(pa) > string.len(pb)
	end
end

local FindString = {
	[0] = function(m,p,t) return string.find(m,p), t end,
	[1] = function(m,p,t) _,_,t[1] = string.find(m,p) if t[1] then return true, t else return false, t end end,
	[2] = function(m,p,t) _,_,t[1],t[2] = string.find(m,p) if t[2] then return true, t else return false, t end end,
	[3] = function(m,p,t) _,_,t[1],t[2],t[3] = string.find(m,p) if t[3] then return true, t else return false, t end end,
	[4] = function(m,p,t) _,_,t[1],t[2],t[3],t[4] = string.find(m,p) if t[4] then return true, t else return false, t end end,
	[5] = function(m,p,t) _,_,t[1],t[2],t[3],t[4],t[5] = string.find(m,p) if t[5] then return true, t else return false, t end end,
	[6] = function(m,p,t) _,_,t[1],t[2],t[3],t[4],t[5],t[6] = string.find(m,p) if t[6] then return true, t else return false, t end end,
	[7] = function(m,p,t) _,_,t[1],t[2],t[3],t[4],t[5],t[6],t[7] = string.find(m,p) if t[7] then return true, t else return false, t end end,
	[8] = function(m,p,t) _,_,t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8] = string.find(m,p) if t[8] then return true, t else return false, t end end,
	[9] = function(m,p,t) _,_,t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9] = string.find(m,p) if t[9] then return true, t else return false, t end end,
}

local keywordTable = nil

if GetLocale() == "enUS" then
	keywordTable = {
		AURAADDEDOTHERHARMFUL = "afflict",
		AURAADDEDOTHERHELPFUL = "gain",
		AURAADDEDSELFHARMFUL = "afflict",
		AURAADDEDSELFHELPFUL = "gain",
		AURAAPPLICATIONADDEDOTHERHARMFUL = "afflict",
		AURAAPPLICATIONADDEDOTHERHELPFUL = "gain",
		AURAAPPLICATIONADDEDSELFHARMFUL = "afflict",
		AURAAPPLICATIONADDEDSELFHELPFUL = "gain",
		AURADISPELOTHER = "remove",
		AURADISPELSELF = "remove",
		AURAREMOVEDOTHER = "fade",
		AURAREMOVEDSELF = "fade",
		COMBATHITCRITOTHEROTHER = "crit",
		COMBATHITCRITOTHERSELF = "crit",
		COMBATHITCRITSELFOTHER = "crit",
		COMBATHITCRITSELFSELF = "crit",
		COMBATHITCRITSCHOOLOTHEROTHER = "crit",
		COMBATHITCRITSCHOOLOTHERSELF = "crit",
		COMBATHITCRITSCHOOLSELFOTHER = "crit",
		COMBATHITCRITSCHOOLSELFSELF = "crit",
		COMBATHITOTHEROTHER = "hit",
		COMBATHITOTHERSELF = "hit",
		COMBATHITSELFOTHER = "hit",
		COMBATHITSELFSELF = "hit",
		COMBATHITSCHOOLOTHEROTHER = "hit",
		COMBATHITSCHOOLOTHERSELF = "hit",
		COMBATHITSCHOOLSELFOTHER = "hit",
		COMBATHITSCHOOLSELFSELF = "hit",
		DAMAGESHIELDOTHEROTHER = "reflect",
		DAMAGESHIELDOTHERSELF = "reflect",
		DAMAGESHIELDSELFOTHER = "reflect",
		DISPELFAILEDOTHEROTHER = "fail",
		DISPELFAILEDOTHERSELF = "fail",
		DISPELFAILEDSELFOTHER = "fail",
		DISPELFAILEDSELFSELF = "fail",
		HEALEDCRITOTHEROTHER = "crit",
		HEALEDCRITOTHERSELF = "crit",
		HEALEDCRITSELFOTHER = "crit",
		HEALEDCRITSELFSELF = "crit",
		HEALEDOTHEROTHER = "heal",
		HEALEDOTHERSELF = "heal",
		HEALEDSELFOTHER = "heal",
		HEALEDSELFSELF = "heal",
		IMMUNESPELLOTHEROTHER = "immune",
		IMMUNESPELLSELFOTHER = "immune",
		IMMUNESPELLOTHERSELF = "immune",
		IMMUNESPELLSELFSELF = "immune",
		ITEMENCHANTMENTADDOTHEROTHER = "cast",
		ITEMENCHANTMENTADDOTHERSELF = "cast",
		ITEMENCHANTMENTADDSELFOTHER = "cast",
		ITEMENCHANTMENTADDSELFSELF = "cast",
		MISSEDOTHEROTHER = "miss",
		MISSEDOTHERSELF = "miss",
		MISSEDSELFOTHER = "miss",
		MISSEDSELFSELF = "miss",
		OPEN_LOCK_OTHER = "perform",
		OPEN_LOCK_SELF = "perform",
		PARTYKILLOTHER = "slain",
		PERIODICAURADAMAGEOTHEROTHER = "suffer",
		PERIODICAURADAMAGEOTHERSELF = "suffer",
		PERIODICAURADAMAGESELFOTHER = "suffer",
		PERIODICAURADAMAGESELFSELF = "suffer",
		PERIODICAURAHEALOTHEROTHER = "gain",
		PERIODICAURAHEALOTHERSELF = "gain",
		PERIODICAURAHEALSELFOTHER = "gain",
		PERIODICAURAHEALSELFSELF = "gain",
		POWERGAINOTHEROTHER = "gain",
		POWERGAINOTHERSELF = "gain",
		POWERGAINSELFSELF = "gain",
		POWERGAINSELFOTHER = "gain",
		PROCRESISTOTHEROTHER = "resist",
		PROCRESISTOTHERSELF = "resist",
		PROCRESISTSELFOTHER = "resist",
		PROCRESISTSELFSELF = "resist",
		SIMPLECASTOTHEROTHER = "cast",
		SIMPLECASTOTHERSELF = "cast",
		SIMPLECASTSELFOTHER = "cast",
		SIMPLECASTSELFSELF = "cast",
		SIMPLEPERFORMOTHEROTHER = "perform",
		SIMPLEPERFORMOTHERSELF = "perform",
		SIMPLEPERFORMSELFOTHER = "perform",
		SIMPLEPERFORMSELFSELF = "perform",
		SPELLBLOCKEDOTHEROTHER = "block",
		SPELLBLOCKEDOTHERSELF = "block",
		SPELLBLOCKEDSELFOTHER = "block",
		SPELLBLOCKEDSELFSELF = "block",
		SPELLCASTOTHERSTART = "begin",
		SPELLCASTSELFSTART = "begin",
		SPELLDEFLECTEDOTHEROTHER = "deflect",
		SPELLDEFLECTEDOTHERSELF = "deflect",
		SPELLDEFLECTEDSELFOTHER = "deflect",
		SPELLDEFLECTEDSELFSELF = "deflect",
		SPELLDODGEDOTHEROTHER = "dodge",
		SPELLDODGEDOTHERSELF = "dodge",
		SPELLDODGEDSELFOTHER = "dodge",
		SPELLEVADEDOTHEROTHER = "evade",
		SPELLEVADEDOTHERSELF = "evade",
		SPELLEVADEDSELFOTHER = "evade",
		SPELLEVADEDSELFSELF = "evade",
		SPELLEXTRAATTACKSOTHER = "extra",
		SPELLEXTRAATTACKSOTHER_SINGULAR = "extra",
		SPELLEXTRAATTACKSSELF = "extra",
		SPELLEXTRAATTACKSSELF_SINGULAR = "extra",
		SPELLFAILCASTSELF = "fail",
		SPELLFAILPERFORMSELF = "fail",
		SPELLIMMUNEOTHEROTHER = "immune",
		SPELLIMMUNEOTHERSELF = "immune",
		SPELLIMMUNESELFOTHER = "immune",
		SPELLIMMUNESELFSELF = "immune",
		SPELLINTERRUPTOTHEROTHER = "interrupt",
		SPELLINTERRUPTOTHERSELF = "interrupt",
		SPELLINTERRUPTSELFOTHER = "interrupt",
		SPELLLOGABSORBOTHEROTHER = "absorb",
		SPELLLOGABSORBOTHERSELF = "absorb",
		SPELLLOGABSORBSELFOTHER = "absorb",
		SPELLLOGABSORBSELFSELF = "absorb",
		SPELLLOGCRITOTHEROTHER = "crit",
		SPELLLOGCRITOTHERSELF = "crit",
		SPELLLOGCRITSCHOOLOTHEROTHER = "crit",
		SPELLLOGCRITSCHOOLOTHERSELF = "crit",
		SPELLLOGCRITSCHOOLSELFOTHER = "crit",
		SPELLLOGCRITSCHOOLSELFSELF = "crit",
		SPELLLOGCRITSELFOTHER = "crit",
		SPELLLOGOTHEROTHER = "hit",
		SPELLLOGOTHERSELF = "hit",
		SPELLLOGOTHERSELF = "hit",
		SPELLLOGSCHOOLOTHEROTHER = "hit",
		SPELLLOGSCHOOLOTHERSELF = "hit",
		SPELLLOGSCHOOLSELFOTHER = "hit",
		SPELLLOGSCHOOLSELFSELF = "hit",
		SPELLLOGSELFOTHER = "hit",
		SPELLMISSOTHEROTHER = "miss",
		SPELLMISSOTHERSELF = "miss",
		SPELLMISSSELFOTHER = "miss",
		SPELLPARRIEDOTHEROTHER = "parr",
		SPELLPARRIEDOTHERSELF = "parr",
		SPELLPARRIEDSELFOTHER = "parr",
		SPELLPERFORMOTHERSTART = "begin",
		SPELLPERFORMSELFSTART = "begin",
		SPELLPOWERDRAINOTHEROTHER = "drain",
		SPELLPOWERDRAINOTHERSELF = "drain",
		SPELLPOWERDRAINSELFOTHER = "drain",
		SPELLPOWERLEECHOTHEROTHER = "drain",
		SPELLPOWERLEECHOTHERSELF = "drain",
		SPELLPOWERLEECHSELFOTHER = "drain",
		SPELLREFLECTOTHEROTHER = "reflect",
		SPELLREFLECTOTHERSELF = "reflect",
		SPELLREFLECTSELFOTHER = "reflect",
		SPELLREFLECTSELFSELF = "reflect",
		SPELLRESISTOTHEROTHER = "resist",
		SPELLRESISTOTHERSELF = "resist",
		SPELLRESISTSELFOTHER = "resist",
		SPELLRESISTSELFSELF = "resist",
		SPELLSPLITDAMAGESELFOTHER = "cause",
		SPELLSPLITDAMAGEOTHEROTHER = "cause",
		SPELLSPLITDAMAGEOTHERSELF = "cause",
		SPELLTERSEPERFORM_OTHER = "perform",
		SPELLTERSEPERFORM_SELF = "perform",
		SPELLTERSE_OTHER = "cast",
		SPELLTERSE_SELF = "cast",
		VSABSORBOTHEROTHER = "absorb",
		VSABSORBOTHERSELF = "absorb",
		VSABSORBSELFOTHER = "absorb",
		VSBLOCKOTHEROTHER = "block",
		VSBLOCKOTHERSELF = "block",
		VSBLOCKSELFOTHER = "block",
		VSBLOCKSELFSELF = "block",
		VSDEFLECTOTHEROTHER = "deflect",
		VSDEFLECTOTHERSELF = "deflect",
		VSDEFLECTSELFOTHER = "deflect",
		VSDEFLECTSELFSELF = "deflect",
		VSDODGEOTHEROTHER = "dodge",
		VSDODGEOTHERSELF = "dodge",
		VSDODGESELFOTHER = "dodge",
		VSDODGESELFSELF = "dodge",
		VSENVIRONMENTALDAMAGE_FALLING_OTHER = "fall",
		VSENVIRONMENTALDAMAGE_FALLING_SELF = "fall",
		VSENVIRONMENTALDAMAGE_FIRE_OTHER = "fire",
		VSENVIRONMENTALDAMAGE_FIRE_SELF = "fire",
		VSENVIRONMENTALDAMAGE_LAVA_OTHER = "lava",
		VSENVIRONMENTALDAMAGE_LAVA_SELF = "lava",
		VSEVADEOTHEROTHER = "evade",
		VSEVADEOTHERSELF = "evade",
		VSEVADESELFOTHER = "evade",
		VSEVADESELFSELF = "evade",
		VSIMMUNEOTHEROTHER = "immune",
		VSIMMUNEOTHERSELF = "immune",
		VSIMMUNESELFOTHER = "immune",
		VSPARRYOTHEROTHER = "parr",
		VSPARRYOTHERSELF = "parr",
		VSPARRYSELFOTHER = "parr",
		VSRESISTOTHEROTHER = "resist",
		VSRESISTOTHERSELF = "resist",
		VSRESISTSELFOTHER = "resist",
		VSRESISTSELFSELF = "resist",
		VSENVIRONMENTALDAMAGE_FATIGUE_OTHER = "exhaust",
		VSENVIRONMENTALDAMAGE_FIRE_OTHER = "fire",
		VSENVIRONMENTALDAMAGE_SLIME_OTHER = "slime",
		VSENVIRONMENTALDAMAGE_SLIME_SELF = "slime",
		VSENVIRONMENTALDAMAGE_DROWNING_OTHER = "drown",
		UNITDIESSELF = "die",
		UNITDIESOTHER = "die",
		UNITDESTROYEDOTHER = "destroy",
	}

elseif GetLocale() == "koKR" then

	keywordTable = {
		AURAADDEDOTHERHARMFUL = "걸렸습니다.",
		AURAADDEDOTHERHELPFUL = "효과를 얻었습니다.",
		AURAADDEDSELFHARMFUL = "걸렸습니다.",
		AURAADDEDSELFHELPFUL = "효과를 얻었습니다.",
		AURAAPPLICATIONADDEDOTHERHARMFUL = "걸렸습니다. (%d)",
		AURAAPPLICATIONADDEDOTHERHELPFUL = "효과를 얻었습니다. (%d)",
		AURAAPPLICATIONADDEDSELFHARMFUL = "걸렸습니다. (%d)",
		AURAAPPLICATIONADDEDSELFHELPFUL = "효과를 얻었습니다. (%d)",
		AURADISPELOTHER = "효과가 사라집니다.",
		AURADISPELSELF = "효과가 사라집니다.",
		AURAREMOVEDOTHER = "효과가 사라졌습니다.",
		AURAREMOVEDSELF = "효과가 사라졌습니다.",
		COMBATHITCRITOTHEROTHER = "치명상 피해를 입혔습니다.",
		COMBATHITCRITOTHERSELF = "치명상 피해를 입혔습니다.",
		COMBATHITCRITSELFOTHER = "치명상 피해를 입혔습니다.",
		--COMBATHITCRITSELFSELF = "crit",
		COMBATHITCRITSCHOOLOTHEROTHER = "치명상 피해를 입혔습니다.",
		COMBATHITCRITSCHOOLOTHERSELF = "치명상 피해를 입혔습니다.",
		COMBATHITCRITSCHOOLSELFOTHER = "치명상 피해를 입혔습니다.",
		--COMBATHITCRITSCHOOLSELFSELF = "crit",
		COMBATHITOTHEROTHER = "피해를 입혔습니다.",
		COMBATHITOTHERSELF = "피해를 입혔습니다.",
		COMBATHITSELFOTHER = "피해를 입혔습니다.",
		--COMBATHITSELFSELF = "hit",
		COMBATHITSCHOOLOTHEROTHER = "피해를 입혔습니다.",
		COMBATHITSCHOOLOTHERSELF = "피해를 입혔습니다.",
		COMBATHITSCHOOLSELFOTHER = "피해를 입혔습니다.",
		--COMBATHITSCHOOLSELFSELF = "hit",
		DAMAGESHIELDOTHEROTHER = "반사했습니다.",
		DAMAGESHIELDOTHERSELF = "반사했습니다.",
		DAMAGESHIELDSELFOTHER = "반사했습니다.",
		DISPELFAILEDOTHEROTHER = "무효화하지 못했습니다.",
		DISPELFAILEDOTHERSELF = "무효화하지 못했습니다.",
		DISPELFAILEDSELFOTHER = "무효화하지 못했습니다.",
		DISPELFAILEDSELFSELF = "무효화하지 못했습니다.",
		HEALEDCRITOTHEROTHER = "극대화 효과를 발휘하여",
		HEALEDCRITOTHERSELF = "극대화 효과를 발휘하여 당신의 생명력이",
		HEALEDCRITSELFOTHER = "극대화 효과를 발휘하여",
		HEALEDCRITSELFSELF = "극대화 효과를 발휘하여 생명력이",
		HEALEDOTHEROTHER = "회복되었습니다.",
		HEALEDOTHERSELF = "회복되었습니다.",
		HEALEDSELFOTHER = "회복되었습니다.",
		HEALEDSELFSELF = "회복되었습니다.",
		IMMUNESPELLOTHEROTHER = "면역입니다.",
		IMMUNESPELLSELFOTHER = "면역입니다.",
		IMMUNESPELLOTHERSELF = "면역입니다.",
		IMMUNESPELLSELFSELF = "면역입니다.",
		ITEMENCHANTMENTADDOTHEROTHER = "사용합니다.",
		ITEMENCHANTMENTADDOTHERSELF = "사용합니다.",
		ITEMENCHANTMENTADDSELFOTHER = "사용합니다.",
		ITEMENCHANTMENTADDSELFSELF = "시전합니다.",
		MISSEDOTHEROTHER = "공격했지만 적중하지 않았습니다.",
		MISSEDOTHERSELF = "당신을 공격했지만 적중하지 않았습니다.",
		MISSEDSELFOTHER = "공격했지만 적중하지 않았습니다.",
		--MISSEDSELFSELF = "miss",
		OPEN_LOCK_OTHER = "사용했습니다.",
		OPEN_LOCK_SELF = "사용했습니다.",
		PARTYKILLOTHER = "죽였습니다!",
		PERIODICAURADAMAGEOTHEROTHER = "피해를 입었습니다.",
		PERIODICAURADAMAGEOTHERSELF = "피해를 입었습니다.",
		PERIODICAURADAMAGESELFOTHER = "피해를 입었습니다.",
		PERIODICAURADAMAGESELFSELF = "피해를 입었습니다.",
		PERIODICAURAHEALOTHEROTHER = "만큼 회복시켰습니다.",
		PERIODICAURAHEALOTHERSELF = "만큼 회복되었습니다.",
		PERIODICAURAHEALSELFOTHER = "만큼 회복시켰습니다.",
		PERIODICAURAHEALSELFSELF = "만큼 회복되었습니다.",
		POWERGAINOTHEROTHER = "얻었습니다.",
		POWERGAINOTHERSELF = "얻었습니다.",
		POWERGAINSELFSELF = "얻었습니다.",
		POWERGAINSELFOTHER = "얻었습니다.",
		PROCRESISTOTHEROTHER = "저항했습니다.",
		PROCRESISTOTHERSELF = "저항했습니다.",
		PROCRESISTSELFOTHER = "저항했습니다.",
		PROCRESISTSELFSELF = "저항했습니다.",
		SIMPLECASTOTHEROTHER = "시전합니다.",
		SIMPLECASTOTHERSELF = "시전합니다.",
		SIMPLECASTSELFOTHER = "시전합니다.",
		SIMPLECASTSELFSELF = "시전합니다.",
		SIMPLEPERFORMOTHEROTHER = "사용했습니다.",
		SIMPLEPERFORMOTHERSELF = "사용했습니다.",
		SIMPLEPERFORMSELFOTHER = "사용했습니다.",
		SIMPLEPERFORMSELFSELF = "사용했습니다.",
		SPELLBLOCKEDOTHEROTHER = "공격했지만 방어했습니다.",
		SPELLBLOCKEDOTHERSELF = "공격했지만 방어했습니다.",
		SPELLBLOCKEDSELFOTHER = "공격했지만 방어했습니다.",
		--SPELLBLOCKEDSELFSELF = "block",
		SPELLCASTOTHERSTART = "시전을 시작합니다.",
		SPELLCASTSELFSTART = "시전을 시작합니다.",
		SPELLDEFLECTEDOTHEROTHER = "공격했지만 빗맞았습니다.",
		SPELLDEFLECTEDOTHERSELF = "공격했지만 빗맞았습니다.",
		SPELLDEFLECTEDSELFOTHER = "공격했지만 빗맞았습니다.",
		SPELLDEFLECTEDSELFSELF = "흘려보냈습니다.",
		SPELLDODGEDOTHEROTHER = "공격했지만 교묘히 피했습니다.",
		SPELLDODGEDOTHERSELF = "공격했지만 교묘히 피했습니다.",
		SPELLDODGEDSELFOTHER = "공격했지만 교묘히 피했습니다.",
		SPELLEVADEDOTHEROTHER = "공격했지만 빗나갔습니다.",
		SPELLEVADEDOTHERSELF = "공격했지만 빗나갔습니다.",
		SPELLEVADEDSELFOTHER = "공격했지만 빗나갔습니다.",
		SPELLEVADEDSELFSELF = "피했습니다.",
		SPELLEXTRAATTACKSOTHER = "추가 공격 기회를 얻었습니다.",
		SPELLEXTRAATTACKSOTHER_SINGULAR = "추가 공격 기회를 얻었습니다.",
		SPELLEXTRAATTACKSSELF = "추가 공격 기회를 얻었습니다.",
		SPELLEXTRAATTACKSSELF_SINGULAR = "추가 공격 기회를 얻었습니다.",
		SPELLFAILCASTSELF = "시전을 실패했습니다:",
		SPELLFAILPERFORMSELF = "사용을 실패했습니다:",
		SPELLIMMUNEOTHEROTHER = "면역입니다.",
		SPELLIMMUNEOTHERSELF = "당신은 면역입니다.",
		SPELLIMMUNESELFOTHER = "면역입니다.",
		SPELLIMMUNESELFSELF = "당신은 면역입니다.",
		SPELLINTERRUPTOTHEROTHER = "차단했습니다.",
		SPELLINTERRUPTOTHERSELF = "차단했습니다.",
		SPELLINTERRUPTSELFOTHER = "차단했습니다.",
		SPELLLOGABSORBOTHEROTHER = "흡수했습니다.",
		SPELLLOGABSORBOTHERSELF = "흡수했습니다.",
		SPELLLOGABSORBSELFOTHER = "흡수했습니다.",
		SPELLLOGABSORBSELFSELF = "흡수했습니다.",
		SPELLLOGCRITOTHEROTHER = "치명상 피해를 입혔습니다.",
		SPELLLOGCRITOTHERSELF = "치명상 피해를 입혔습니다.",
		SPELLLOGCRITSCHOOLOTHEROTHER = "치명상 피해를 입혔습니다.",
		SPELLLOGCRITSCHOOLOTHERSELF = "치명상 피해를 입혔습니다.",
		SPELLLOGCRITSCHOOLSELFOTHER = "치명상 피해를 입혔습니다.",
		SPELLLOGCRITSCHOOLSELFSELF = "치명상 피해를 입었습니다.",
		SPELLLOGCRITSELFOTHER = "치명상 피해를 입혔습니다.",
		SPELLLOGOTHEROTHER = "피해를 입혔습니다.",
		SPELLLOGOTHERSELF = "피해를 입혔습니다.",
		SPELLLOGOTHERSELF = "피해를 입혔습니다.",
		SPELLLOGSCHOOLOTHEROTHER = "피해를 입혔습니다.",
		SPELLLOGSCHOOLOTHERSELF = "피해를 입혔습니다.",
		SPELLLOGSCHOOLSELFOTHER = "피해를 입혔습니다.",
		SPELLLOGSCHOOLSELFSELF = "피해를 입었습니다.",
		SPELLLOGSELFOTHER = "피해를 입혔습니다.",
		SPELLMISSOTHEROTHER = "공격했지만 적중하지 않았습니다.",
		SPELLMISSOTHERSELF = "공격했지만 적중하지 않았습니다.",
		SPELLMISSSELFOTHER = "공격했지만 적중하지 않았습니다.",
		SPELLPARRIEDOTHEROTHER = "공격했지만 막았습니다.",
		SPELLPARRIEDOTHERSELF = "공격했지만 막았습니다.",
		SPELLPARRIEDSELFOTHER = "공격했지만 막았습니다.",
		SPELLPERFORMOTHERSTART = "사용을 시작합니다.",
		SPELLPERFORMSELFSTART = "사용을 시작합니다.",
		SPELLPOWERDRAINOTHEROTHER = "소진시켰습니다.",
		SPELLPOWERDRAINOTHERSELF = "소진시켰습니다.",
		SPELLPOWERDRAINSELFOTHER = "소진시켰습니다.",
		SPELLPOWERLEECHOTHEROTHER = "소진시켰습니다.",
		SPELLPOWERLEECHOTHERSELF = "소진시켰습니다.",
		SPELLPOWERLEECHSELFOTHER = "소진시켰습니다.",
		SPELLREFLECTOTHEROTHER = "공격했지만 반사했습니다.",
		SPELLREFLECTOTHERSELF = "반사했습니다.",
		SPELLREFLECTSELFOTHER = "공격했지만 반사했습니다.",
		SPELLREFLECTSELFSELF = "반사했습니다.",
		SPELLRESISTOTHEROTHER = "공격했지만 저항했습니다.",
		SPELLRESISTOTHERSELF = "공격했지만 저항했습니다.",
		SPELLRESISTSELFOTHER = "공격했지만 저항했습니다.",
		SPELLRESISTSELFSELF = "저항했습니다.",
		SPELLSPLITDAMAGESELFOTHER = "피해를 입혔습니다.",
		SPELLSPLITDAMAGEOTHEROTHER = "피해를 입혔습니다.",
		SPELLSPLITDAMAGEOTHERSELF = "피해를 입혔습니다.",
		SPELLTERSEPERFORM_OTHER = "사용했습니다.",
		SPELLTERSEPERFORM_SELF = "사용했습니다.",
		SPELLTERSE_OTHER = "시전합니다.",
		SPELLTERSE_SELF = "시전합니다.",
		VSABSORBOTHEROTHER = "공격했지만 모든 피해를 흡수했습니다.",
		VSABSORBOTHERSELF = "당신을 공격했지만 모든 피해를 흡수했습니다.",
		VSABSORBSELFOTHER = "공격했지만 모든 피해를 흡수했습니다.",
		VSBLOCKOTHEROTHER = "공격했지만 방어했습니다.",
		VSBLOCKOTHERSELF = "당신을 공격했지만 방어했습니다.",
		VSBLOCKSELFOTHER = "공격했지만 방어했습니다.",
		--VSBLOCKSELFSELF = "block",
		VSDEFLECTOTHEROTHER = "공격했지만 빗맞았습니다.",
		VSDEFLECTOTHERSELF = "당신을 공격했지만 빗맞았습니다.",
		VSDEFLECTSELFOTHER = "공격했지만 빗맞았습니다.",
		--VSDEFLECTSELFSELF = "deflect",
		VSDODGEOTHEROTHER = "공격했지만 교묘히 피했습니다.",
		VSDODGEOTHERSELF = "당신을 공격했지만 교묘히 피했습니다.",
		VSDODGESELFOTHER = "공격했지만 교묘히 피했습니다.",
		--VSDODGESELFSELF = "dodge",
		VSENVIRONMENTALDAMAGE_FALLING_OTHER = "낙하할 때의 충격으로",
		VSENVIRONMENTALDAMAGE_FALLING_SELF = "당신은 낙하할 때의 충격으로",
		VSENVIRONMENTALDAMAGE_FIRE_OTHER = "화염 피해를 입었습니다.",
		VSENVIRONMENTALDAMAGE_FIRE_SELF = "화염 피해를 입었습니다.",
		VSENVIRONMENTALDAMAGE_LAVA_OTHER = "용암의 열기로 인해",
		VSENVIRONMENTALDAMAGE_LAVA_SELF = "당신은 용암의 열기로 인해",
		VSEVADEOTHEROTHER = "공격했지만 빗나갔습니다.",
		VSEVADEOTHERSELF = "당신을 공격했지만 빗나갔습니다.",
		VSEVADESELFOTHER = "공격했지만 빗나갔습니다.",
		--VSEVADESELFSELF = "evade",
		VSIMMUNEOTHEROTHER = "공격했지만 면역입니다.",
		VSIMMUNEOTHERSELF = "당신을 공격했지만 면역입니다.",
		VSIMMUNESELFOTHER = "공격했지만 면역입니다.",
		VSPARRYOTHEROTHER = "공격했지만 막았습니다.",
		VSPARRYOTHERSELF = "당신을 공격했지만 막았습니다.",
		VSPARRYSELFOTHER = "공격했지만 막았습니다.",
		VSRESISTOTHEROTHER = "공격했지만 모든 피해를 저항했습니다.",
		VSRESISTOTHERSELF = "당신을 공격했지만 모든 피해를 저항했습니다.",
		VSRESISTSELFOTHER = "공격했지만 모든 피해를 저항했습니다.",
		--VSRESISTSELFSELF = "resist",
		VSENVIRONMENTALDAMAGE_FATIGUE_OTHER = "너무 기진맥진하여",
		VSENVIRONMENTALDAMAGE_FIRE_OTHER = "화염 피해를 입었습니다.",
		VSENVIRONMENTALDAMAGE_SLIME_OTHER = "독성으로 인해",
		VSENVIRONMENTALDAMAGE_SLIME_SELF = "당신은 독성으로 인해",
		VSENVIRONMENTALDAMAGE_DROWNING_OTHER = "숨을 쉴 수 없어",
		UNITDIESSELF = "당신은 죽었습니다.",
		UNITDIESOTHER = "죽었습니다.",
		UNITDESTROYEDOTHER = "파괴되었습니다.",
}

elseif GetLocale() == "zhTW" then

	keywordTable = {
		AURAADDEDOTHERHARMFUL = "受到",
		AURAADDEDOTHERHELPFUL = "獲得了",
		AURAADDEDSELFHARMFUL = "受到了",
		AURAADDEDSELFHELPFUL = "獲得了",
		AURAAPPLICATIONADDEDOTHERHARMFUL = "受到了",
		AURAAPPLICATIONADDEDOTHERHELPFUL = "獲得了",
		AURAAPPLICATIONADDEDSELFHARMFUL = "受到了",
		AURAAPPLICATIONADDEDSELFHELPFUL = "獲得了",
		AURADISPELOTHER = "移除",
		AURADISPELSELF = "移除",
		AURAREMOVEDOTHER = "消失",
		AURAREMOVEDSELF = "消失了",
		COMBATHITCRITOTHEROTHER = "致命一擊",
		COMBATHITCRITOTHERSELF = "致命一擊",
		COMBATHITCRITSELFOTHER = "致命一擊",
		COMBATHITCRITSELFSELF = "致命一擊",
		COMBATHITCRITSCHOOLOTHEROTHER = "致命一擊",
		COMBATHITCRITSCHOOLOTHERSELF = "致命一擊",
		COMBATHITCRITSCHOOLSELFOTHER = "致命一擊",
		COMBATHITCRITSCHOOLSELFSELF = "致命一擊",
		COMBATHITOTHEROTHER = "擊中",
		COMBATHITOTHERSELF = "擊中",
		COMBATHITSELFOTHER = "擊中",
		COMBATHITSELFSELF = "擊中",
		COMBATHITSCHOOLOTHEROTHER = "擊中",
		COMBATHITSCHOOLOTHERSELF = "擊中",
		COMBATHITSCHOOLSELFOTHER = "擊中",
		COMBATHITSCHOOLSELFSELF = "擊中",
		DAMAGESHIELDOTHEROTHER = "反射",
		DAMAGESHIELDOTHERSELF = "反彈",
		DAMAGESHIELDSELFOTHER = "反彈",
		DISPELFAILEDOTHEROTHER = "未能",
		DISPELFAILEDOTHERSELF = "未能",
		DISPELFAILEDSELFOTHER = "未能",
		DISPELFAILEDSELFSELF = "無法",
		HEALEDCRITOTHEROTHER = "發揮極效",
		HEALEDCRITOTHERSELF = "發揮極效",
		HEALEDCRITSELFOTHER = "極效治療",
		HEALEDCRITSELFSELF = "極效治療",
		HEALEDOTHEROTHER = "恢復",
		HEALEDOTHERSELF = "恢復",
		HEALEDSELFOTHER = "治療",
		HEALEDSELFSELF = "治療",
		IMMUNESPELLOTHEROTHER = "免疫",
		IMMUNESPELLSELFOTHER = "免疫",
		IMMUNESPELLOTHERSELF = "免疫",
		IMMUNESPELLSELFSELF = "免疫",
		ITEMENCHANTMENTADDOTHEROTHER = "施放",
		ITEMENCHANTMENTADDOTHERSELF = "施放",
		ITEMENCHANTMENTADDSELFOTHER = "施放",
		ITEMENCHANTMENTADDSELFSELF = "施放",
		MISSEDOTHEROTHER = "沒有擊中",
		MISSEDOTHERSELF = "沒有擊中",
		MISSEDSELFOTHER = "沒有擊中",
		MISSEDSELFSELF = "沒有擊中",
		OPEN_LOCK_OTHER = "使用",
		OPEN_LOCK_SELF = "使用",
		PARTYKILLOTHER = "幹掉",
		PERIODICAURADAMAGEOTHEROTHER = "受到了",
		PERIODICAURADAMAGEOTHERSELF = "受到",
		PERIODICAURADAMAGESELFOTHER = "受到了",
		PERIODICAURADAMAGESELFSELF = "受到",
		PERIODICAURAHEALOTHEROTHER = "獲得",
		PERIODICAURAHEALOTHERSELF = "獲得了",
		PERIODICAURAHEALSELFOTHER = "獲得",
		PERIODICAURAHEALSELFSELF = "獲得了",
		POWERGAINOTHEROTHER = "獲得",
		POWERGAINOTHERSELF = "獲得了",
		POWERGAINSELFSELF = "獲得了",
		POWERGAINSELFOTHER = "獲得",
		PROCRESISTOTHEROTHER = "抵抗了",
		PROCRESISTOTHERSELF = "抵抗了",
		PROCRESISTSELFOTHER = "抵抗了",
		PROCRESISTSELFSELF = "抵抗了",
		SIMPLECASTOTHEROTHER = "施放了",
		SIMPLECASTOTHERSELF = "施放了",
		SIMPLECASTSELFOTHER = "施放了",
		SIMPLECASTSELFSELF = "施放了",
		SIMPLEPERFORMOTHEROTHER = "使用",
		SIMPLEPERFORMOTHERSELF = "使用",
		SIMPLEPERFORMSELFOTHER = "使用",
		SIMPLEPERFORMSELFSELF = "使用",
		SPELLBLOCKEDOTHEROTHER = "格擋",
		SPELLBLOCKEDOTHERSELF = "格擋",
		SPELLBLOCKEDSELFOTHER = "格擋",
		SPELLBLOCKEDSELFSELF = "格擋",
		SPELLCASTOTHERSTART = "開始",
		SPELLCASTSELFSTART = "開始",
		SPELLDEFLECTEDOTHEROTHER = "偏斜",
		SPELLDEFLECTEDOTHERSELF = "偏斜",
		SPELLDEFLECTEDSELFOTHER = "偏斜",
		SPELLDEFLECTEDSELFSELF = "偏斜",
		SPELLDODGEDOTHEROTHER = "閃躲",
		SPELLDODGEDOTHERSELF = "閃躲",
		SPELLDODGEDSELFOTHER = "閃躲",
		SPELLEVADEDOTHEROTHER = "閃避",
		SPELLEVADEDOTHERSELF = "閃避",
		SPELLEVADEDSELFOTHER = "閃避",
		SPELLEVADEDSELFSELF = "閃避",
		SPELLEXTRAATTACKSOTHER = "額外",
		SPELLEXTRAATTACKSOTHER_SINGULAR = "額外",
		SPELLEXTRAATTACKSSELF = "額外",
		SPELLEXTRAATTACKSSELF_SINGULAR = "額外",
		SPELLFAILCASTSELF = "失敗",
		SPELLFAILPERFORMSELF = "失敗",
		SPELLIMMUNEOTHEROTHER = "免疫",
		SPELLIMMUNEOTHERSELF = "免疫",
		SPELLIMMUNESELFOTHER = "免疫",
		SPELLIMMUNESELFSELF = "免疫",
		SPELLINTERRUPTOTHEROTHER = "打斷了",
		SPELLINTERRUPTOTHERSELF = "打斷了",
		SPELLINTERRUPTSELFOTHER = "打斷了",
		SPELLLOGABSORBOTHEROTHER = "吸收了",
		SPELLLOGABSORBOTHERSELF = "吸收了",
		SPELLLOGABSORBSELFOTHER = "吸收了",
		SPELLLOGABSORBSELFSELF = "吸收了",
		SPELLLOGCRITOTHEROTHER = "致命一擊",
		SPELLLOGCRITOTHERSELF = "致命一擊",
		SPELLLOGCRITSCHOOLOTHEROTHER = "致命一擊",
		SPELLLOGCRITSCHOOLOTHERSELF = "致命一擊",
		SPELLLOGCRITSCHOOLSELFOTHER = "致命一擊",
		SPELLLOGCRITSCHOOLSELFSELF = "致命一擊",
		SPELLLOGCRITSELFOTHER = "致命一擊",
		SPELLLOGOTHEROTHER = "擊中",
		SPELLLOGOTHERSELF = "擊中",
		SPELLLOGOTHERSELF = "擊中",
		SPELLLOGSCHOOLOTHEROTHER = "擊中",
		SPELLLOGSCHOOLOTHERSELF = "擊中",
		SPELLLOGSCHOOLSELFOTHER = "擊中",
		SPELLLOGSCHOOLSELFSELF = "擊中",
		SPELLLOGSELFOTHER = "擊中",
		SPELLMISSOTHEROTHER = "沒有擊中",
		SPELLMISSOTHERSELF = "沒有擊中",
		SPELLMISSSELFOTHER = "沒有擊中",
		SPELLPARRIEDOTHEROTHER = "招架",
		SPELLPARRIEDOTHERSELF = "招架",
		SPELLPARRIEDSELFOTHER = "招架",
		SPELLPERFORMOTHERSTART = "開始",
		SPELLPERFORMSELFSTART = "開始",
		SPELLPOWERDRAINOTHEROTHER = "吸取",
		SPELLPOWERDRAINOTHERSELF = "吸收",
		SPELLPOWERDRAINSELFOTHER = "吸收",
		SPELLPOWERLEECHOTHEROTHER = "吸取",
		SPELLPOWERLEECHOTHERSELF = "吸取",
		SPELLPOWERLEECHSELFOTHER = "吸取",
		SPELLREFLECTOTHEROTHER = "反彈",
		SPELLREFLECTOTHERSELF = "反彈",
		SPELLREFLECTSELFOTHER = "反彈",
		SPELLREFLECTSELFSELF = "反彈",
		SPELLRESISTOTHEROTHER = "抵抗",
		SPELLRESISTOTHERSELF = "抵抗",
		SPELLRESISTSELFOTHER = "抵抗",
		SPELLRESISTSELFSELF = "抵抗",
		SPELLSPLITDAMAGESELFOTHER = "造成了",
		SPELLSPLITDAMAGEOTHEROTHER = "造成了",
		SPELLSPLITDAMAGEOTHERSELF = "造成了",
		SPELLTERSEPERFORM_OTHER = "使用",
		SPELLTERSEPERFORM_SELF = "使用",
		SPELLTERSE_OTHER = "施放了",
		SPELLTERSE_SELF = "施放了",
		VSABSORBOTHEROTHER = "吸收了",
		VSABSORBOTHERSELF = "吸收了",
		VSABSORBSELFOTHER = "吸收了",
		VSBLOCKOTHEROTHER = "格擋住了",
		VSBLOCKOTHERSELF = "格擋住了",
		VSBLOCKSELFOTHER = "格擋住了",
		VSBLOCKSELFSELF = "格擋住了",
		VSDEFLECTOTHEROTHER = "閃開了",
		VSDEFLECTOTHERSELF = "閃開了",
		VSDEFLECTSELFOTHER = "閃開了",
		VSDEFLECTSELFSELF = "閃開了",
		VSDODGEOTHEROTHER = "閃躲開了",
		VSDODGEOTHERSELF = "閃躲開了",
		VSDODGESELFOTHER = "閃開了",
		VSDODGESELFSELF = "dodge",
		VSENVIRONMENTALDAMAGE_FALLING_OTHER = "高處掉落",
		VSENVIRONMENTALDAMAGE_FALLING_SELF = "火焰",
		VSENVIRONMENTALDAMAGE_FIRE_OTHER = "火焰",
		VSENVIRONMENTALDAMAGE_FIRE_SELF = "火焰",
		VSENVIRONMENTALDAMAGE_LAVA_OTHER = "岩漿",
		VSENVIRONMENTALDAMAGE_LAVA_SELF = "岩漿",
		VSEVADEOTHEROTHER = "閃避",
		VSEVADEOTHERSELF = "閃避",
		VSEVADESELFOTHER = "閃避",
		VSEVADESELFSELF = "閃避",
		VSIMMUNEOTHEROTHER = "免疫",
		VSIMMUNEOTHERSELF = "免疫",
		VSIMMUNESELFOTHER = "免疫",
		VSPARRYOTHEROTHER = "招架",
		VSPARRYOTHERSELF = "招架",
		VSPARRYSELFOTHER = "招架",
		VSRESISTOTHEROTHER = "抵抗",
		VSRESISTOTHERSELF = "抵抗",
		VSRESISTSELFOTHER = "抵抗",
		VSRESISTSELFSELF = "抵抗",
		VSENVIRONMENTALDAMAGE_FATIGUE_OTHER = "精疲力竭",
		VSENVIRONMENTALDAMAGE_FIRE_OTHER = "火焰",
		VSENVIRONMENTALDAMAGE_SLIME_OTHER = "泥漿",
		VSENVIRONMENTALDAMAGE_SLIME_SELF = "泥漿",
		VSENVIRONMENTALDAMAGE_DROWNING_OTHER = "溺水狀態",
		UNITDIESSELF = "死亡",
		UNITDIESOTHER = "死亡",
		UNITDESTROYEDOTHER = "摧毀",
	}
end

-- Convert "%s hits %s for %d." to "(.+) hits (.+) for (%d+)."
-- Will additionaly return the sequence of tokens, for example:
--  "%2$s reflects %3$d %4$s damage to %1$s." will return:
--    "(.-) reflects (%+) (.-) damage to (.-)%.", 4 1 2 3.
--  (    [1]=2,[2]=3,[3]=4,[4]=1  Reverting indexes and become  [1]=4, [2]=[1],[3]=2,[4]=3. )
function lib:ConvertPattern(pattern, anchor)

	local seq

	-- Add % to escape all magic characters used in LUA pattern matching, except $ and %
	pattern = string.gsub(pattern,"([%^%(%)%.%[%]%*%+%-%?])","%%%1")

	-- Do these AFTER escaping the magic characters.
	pattern = string.gsub(pattern,"%%s","(.-)") -- %s to (.-)
	pattern = string.gsub(pattern,"%%d","(%-?%%d+)") -- %d to (%d+)

	if string.find(pattern,"%$") then
		seq = {} -- fills with ordered list of $s as they appear
		local idx = 1 -- incremental index into field[]

		local tmpSeq = {}
		for i in string.gfind(pattern,"%%(%d)%$.") do
			tmpSeq[idx] = tonumber(i)
			idx = idx + 1
		end
		for i, j in ipairs(tmpSeq) do
			seq[j] = i
		end
		pattern = string.gsub(pattern,"%%%d%$s","(.-)") -- %1$s to (.-)
		pattern = string.gsub(pattern,"%%%d%$d","(%-?%%d+)") -- %1$d to (%d+)
	end

	-- Escape $ now.
	pattern = string.gsub(pattern,"%$","%%$")

	-- Anchor tag can improve string.find() performance by 100%.
	if anchor then pattern = "^"..pattern end

	-- If the pattern ends with (.-), replace it with (.+), or the capsule will be lost.
	if string.sub(pattern,-4) == "(.-)" then
		pattern = string.sub(pattern,0, -5) .. "(.+)"
	end

	if not seq then return pattern end

	return pattern, seq[1], seq[2], seq[3], seq[4], seq[5], seq[6], seq[7], seq[8], seq[9], seq[10]
end

function lib:OnLoad()

	-- Both table starts out empty, and load the data only when required.
	eventTable = {}
	patternTable = {}

	-- Used to store parsed results.
	info = {}

	-- Usd to clone the info table, to prevent clients from modifying the result.
	rInfo = {}

	if self.timing then
		timer = {
			ParseMessage_LoadPatternList = 0,
			ParseMessage_FindPattern = 0,
			ParseMessage_FindPattern_Regexp = 0,
			ParseMessage_FindPattern_Regexp_FindString = 0,
			ParseMessage_FindPattern_LoadPatternInfo = 0,
			ParseMessage_ParseInformation = 0,
			ParseMessage_ParseTrailers = 0,
			ParseMessage_ConvertTypes = 0,
			NotifyClients = 0,
		}
	end

	if not self.clients then self.clients = {} end

	if not self.frame then
		self.frame = CreateFrame("FRAME", "ParserLibFrame")
		self.frame:SetScript("OnEvent", ParserOnEvent )
		self.frame:Hide()
	end
end

function lib:OnEvent(e, a1)

	if not e then e = event end
	if not a1 then a1 = arg1 end

	-- self:Print("Event: |cff3333ff"..e.."|r") -- debug

	-- Titan Honor+ was changing the global events... just change it back.
	if e == "CHAT_MSG_HONORPLUS" then e = "CHAT_MSG_COMBAT_HONOR_GAIN" end

	if self:ParseMessage(a1, e) then

-- 		local timer = GetTime() -- timer
		self:NotifyClients(e)
-- 		timer.NotifyClients = timer.NotifyClients + GetTime() - timer -- timer

	end
end

function lib:NotifyClients(event)

	if not self.clients or not self.clients[event] then
		-- self:Print(event .. " has no client to notify.") -- debug
		return
	end

	-- Noneed to recycle the table if there is only one client.
	if table.getn(self.clients[event]) == 1 then
		-- self:Print(event .. ", calling " .. self.clients[event][1].id) -- debug
		self.clients[event][1].func(event, info)
		return
	end

	if not cache then
		cache = setmetatable({}, {
			__index = function(_, k)
				return info[k]
			end,
			__newindex = function () end,
		})
	end

	for i, client in pairs(self.clients[event]) do
		client.func(event, cache)
	end
end

--[[
function lib:NotifyClients(event)

	if not self.clients or not self.clients[event] then
		-- self:Print(event .. " has no client to notify.") -- debug
		return
	end

	-- Noneed to recycle the table if there is only one client.
	if table.getn(self.clients[event]) == 1 then
		-- self:Print(event .. ", calling " .. self.clients[event][1].id) -- debug
		self.clients[event][1].func(event, info)
		return
	end

	for i, client in pairs(self.clients[event]) do
		-- self:Print(event .. ", calling " .. client.id) -- debug

		-- I can just do a compost:Recycle() here, but I hope this can improve the performance.
		for j in pairs(rInfo) do if not info[j] then rInfo[j] = nil end end
		for j, v in pairs(info) do rInfo[j] = v end

		client.func(event, rInfo)
	end

	-- Clean up the table.
-- 	timer = GetTime() -- timer
	for k in pairs(rInfo) do
		rInfo[k] = nil
	end
-- 	timer.reclaim = GetTime() - timer + timer.reclaim -- timer
end]]

lib.Print = function(self, msg) print(msg) end

-- message : the arg1 in the event
-- event : name says it all.
-- return : true if pattern found and parsed, nil otherwise.
function lib:ParseMessage(message, event)

-- --	local currTime -- timer

-- 	currTime = GetTime() -- timer
	if not eventTable[event] then eventTable[event] = self:LoadPatternList(event) end -- loaded by registering already
	local list = eventTable[event]
-- 	timer.ParseMessage_LoadPatternList = timer.ParseMessage_LoadPatternList + GetTime() - currTime -- timer

	if not list then return end

	-- Cleans the table.
	for k in pairs(info) do
		info[k] = nil
	end

-- 	currTime = GetTime() -- timer
	local pattern = self:FindPattern(message, list)
-- 	timer.ParseMessage_FindPattern = GetTime() - currTime + timer.ParseMessage_FindPattern -- timer

	if not pattern then
		-- create "unknown" event type.
		info.type = "unknown"
		info.message = message
		return true
	end

-- 	currTime = GetTime() -- timer
	self:ParseInformation(pattern)
-- 	timer.ParseMessage_ParseInformation = GetTime() - currTime + timer.ParseMessage_ParseInformation -- timer

-- 	currTime = GetTime() -- timer
	if info.type == "hit" or info.type == "environment" then
		self:ParseTrailers(message)
	end
-- 	timer.ParseMessage_ParseTrailers = GetTime() - currTime + timer.ParseMessage_ParseTrailers -- timer

-- 	currTime = GetTime() -- timer
	self:ConvertTypes(info)
-- 	timer.ParseMessage_ConvertTypes = GetTime() - currTime + timer.ParseMessage_ConvertTypes -- timer

	return true
end

-- Search for pattern in 'patternList' which matches 'message', parsed tokens will be stored in table info
function lib:FindPattern(message, patternList)

	local pt, timer, found

	for i, v in pairs(patternList) do

-- 		timer = GetTime() -- timer
		if not patternTable[v] then
			patternTable[v] = self:LoadPatternInfo(v)
			if not patternTable[v] then return end
		end -- loaded by registering already
-- 		timer.ParseMessage_FindPattern_LoadPatternInfo = GetTime() - timer + timer.ParseMessage_FindPattern_LoadPatternInfo -- timer

		pt = patternTable[v]

-- 		timer = GetTime() -- timer
		if self:OptimizerCheck(message, v) then
-- 			timer = GetTime() -- timer
			found, info = FindString[pt.tc](message, pt.pattern, info)
-- 			timer.ParseMessage_FindPattern_Regexp_FindString = GetTime() - timer + timer.ParseMessage_FindPattern_Regexp_FindString -- timer
		end
-- 		timer.ParseMessage_FindPattern_Regexp = GetTime() - timer + timer.ParseMessage_FindPattern_Regexp -- timer

		if found then
			-- self:Print(message.." = " .. v .. ":" .. pt.pattern) -- debug
			return v
		end
	end
end

-- Parses for trailers.
function lib:ParseTrailers(message)
	local found, amount

	if not trailers then
		trailers = {
			CRUSHING_TRAILER = self:ConvertPattern(CRUSHING_TRAILER),
			GLANCING_TRAILER = self:ConvertPattern(GLANCING_TRAILER),
			ABSORB_TRAILER = self:ConvertPattern(ABSORB_TRAILER),
			BLOCK_TRAILER = self:ConvertPattern(BLOCK_TRAILER),
			RESIST_TRAILER = self:ConvertPattern(RESIST_TRAILER),
			VULNERABLE_TRAILER = self:ConvertPattern(VULNERABLE_TRAILER),
		}
	end

	found = string.find(message,trailers.CRUSHING_TRAILER)
	if found then
		info.isCrushing = true
	end
	found = string.find(message,trailers.GLANCING_TRAILER)
	if found then
		info.isGlancing = true
	end
	found, _, amount = string.find(message,trailers.ABSORB_TRAILER)
	if found then
		info.amountAbsorb = amount
	end
	found, _, amount = string.find(message,trailers.BLOCK_TRAILER)
	if found then
		info.amountBlock = amount
	end
	found, _, amount = string.find(message,trailers.RESIST_TRAILER)
	if found then
		info.amountResist = amount
	end
	found, _, amount = string.find(message,trailers.VULNERABLE_TRAILER)
	if found then
		info.amountVulnerable = amount
	end
end

function lib:ParseInformation(patternName)

	local patternInfo = patternTable[patternName]

	-- Create an info table from pattern table, copies everything except the pattern string
	for i, v in pairs(patternInfo) do
		if i == 1 then
			info.type = v
		elseif type(i) == "number" then
			local field = self:GetInfoFieldName( patternTable[patternName][1], i)
			if not field then print(patternName .. "," .. i) end
			if type(v) == "number" and v < 100 then
				info[field] = info[v]
			else
				info[field] = v
			end
		end
	end

	if info.type == "honor" and not info.amount then
		info.isDishonor = true

	elseif info.type == "durability" and not info.item then
		info.isAllItems = true
	end

	for i in ipairs(info) do
		info[i] = nil
	end
end

function lib:ConvertTypes(info)
	for i in pairs(info) do
		if string.find(i,"^amount") then info[i] = tonumber(info[i]) end
	end
end

function lib:OptimizerCheck(message, patternName)
	if not keywordTable or not keywordTable[patternName] or string.find(message,keywordTable[patternName], 1, true) then
		return true
	else
		return false
	end
end

-- Most of the parts were learnt from BabbleLib by chknight, so credits goes to him.
function lib:Curry(pattern)
	local cp, tt, n, f, o, _
	local DoNothing = function(tok) return tok end

	tt = {}
	for tk in string.gfind(pattern,"%%%d?%$?([sd])") do
		table.insert(tt, tk)
	end

	cp = { self:ConvertPattern(pattern, true) }
	cp.p = cp[1]

	n = table.getn(cp)
	for i=1,n-1 do
		cp[i] = cp[i+1]
	end
	table.remove(cp, n)

	f = {}
	o = {}
	n = table.getn(tt)
	for i=1, n do
		if tt[i] == "s" then
			f[i] = DoNothing
		else
			f[i] = tonumber
		end
	end

	if not cp[1] then
		if n == 0 then
			return function() end
		elseif n == 1 then
			return function(text)
				_, _, o[1] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1])
				end
			end
		elseif n == 2 then
			return function(text)
				_, _, o[1], o[2]= string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2])
				end
			end
		elseif n == 3 then
			return function(text)
				_, _, o[1], o[2], o[3] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3])
				end
			end
		elseif n == 4 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3]), f[4](o[4])
				end
			end
		elseif n == 5 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3]), f[4](o[4]), f[5](o[5])
				end
			end
		elseif n == 6 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3]), f[4](o[4]), f[5](o[5]), f[6](o[6])
				end
			end
		elseif n == 7 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6], o[7] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3]), f[4](o[4]), f[5](o[5]), f[6](o[6]), f[7](o[7])
				end
			end
		elseif n == 8 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6], o[7], o[8] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3]), f[4](o[4]), f[5](o[5]), f[6](o[6]), f[7](o[7]), f[8](o[8])
				end
			end
		elseif n == 9 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6], o[7], o[8], o[9] = string.find(text,cp.p)
				if o[1] then
					return f[1](o[1]), f[2](o[2]), f[3](o[3]), f[4](o[4]), f[5](o[5]), f[6](o[6]), f[7](o[7]), f[8](o[8]), f[9](o[9])
				end
			end
		end
	else
		if n == 0 then
			return function() end
		elseif n == 1 then
			return function(text)
				_, _, o[1] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]])
				end
			end
		elseif n == 2 then
			return function(text)
				_, _, o[1], o[2] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]])
				end
			end
		elseif n == 3 then
			return function(text)
				_, _, o[1], o[2], o[3] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]])
				end
			end
		elseif n == 4 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]]), f[cp[4]](o[cp[4]])
				end
			end
		elseif n == 5 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]]), f[cp[4]](o[cp[4]]), f[cp[5]](o[cp[5]])
				end
			end
		elseif n == 6 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]]), f[cp[4]](o[cp[4]]), f[cp[5]](o[cp[5]]), f[cp[6]](o[cp[6]])
				end
			end
		elseif n == 7 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6], o[7] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]]), f[cp[4]](o[cp[4]]), f[cp[5]](o[cp[5]]), f[cp[6]](o[cp[6]]), f[cp[7]](o[cp[7]])
				end
			end
		elseif n == 8 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6], o[7], o[8] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]]), f[cp[4]](o[cp[4]]), f[cp[5]](o[cp[5]]), f[cp[6]](o[cp[6]]), f[cp[7]](o[cp[7]]), f[cp[8]](o[cp[8]])
				end
			end
		elseif n == 9 then
			return function(text)
				_, _, o[1], o[2], o[3], o[4], o[5], o[6], o[7], o[8], o[9] = string.find(text,cp.p)
				if o[1] then
					return f[cp[1]](o[cp[1]]), f[cp[2]](o[cp[2]]), f[cp[3]](o[cp[3]]), f[cp[4]](o[cp[4]]), f[cp[5]](o[cp[5]]), f[cp[6]](o[cp[6]]), f[cp[7]](o[cp[7]]), f[cp[8]](o[cp[8]]), f[cp[9]](o[cp[9]])
				end
			end
		end
	end
end

-- Used to test the correcteness of ParserLib on different languages.
function lib:TestPatterns(sendToClients)

	self:LoadEverything()

	-- Creating the combat messages.
	local testNumber = 123
	local message
	local messages = {}
	for patternName in pairs(patternTable) do
		messages[patternName] = {}
		messages[patternName].message = _G[patternName]
		for i, v in pairs(patternTable[patternName]) do
			if i ~= "tc" and type(v) == "number" and v < 100 and i~=1 then
				messages[patternName][v] = self:GetInfoFieldName(patternTable[patternName][1], i)
			end
		end
		for i, v in ipairs(messages[patternName]) do
			if string.find(v,"^amount") then
				messages[patternName].message = string.gsub(messages[patternName].message,"%%%d?%$?d", testNumber, 1)
			else
				messages[patternName].message = string.gsub(messages[patternName].message,"%%%d?%$?s", string.upper(v), 1)
			end
		end
	end

	-- Begin the test.

	local msg
	local startTime = GetTime()
	local startMem = collectgarbage("count")

	local function PrintTable(args)
		for k, v in pairs(args) do
			ChatFrame1:AddMessage(tostring(k) .. " = " .. tostring(v))
		end
		ChatFrame1:AddMessage("")
	end

	for _, event in pairs(supportedEvents) do
		for _, pattern in pairs(self:LoadPatternList(event)) do
			if not messages[pattern] then ChatFrame1:AddMessage(pattern) end
			msg = messages[pattern].message
			if sendToClients then self:OnEvent(event, msg)	end
			if self:ParseMessage(msg, event) then
				for i, v in ipairs(messages[pattern]) do
					if not info[v]
					or ( string.find(v,"^amount") and info[v] ~= testNumber )
					or ( not string.find(v,"^amount") and info[v] ~= string.upper(v) ) then
						self:Print("Event: " .. event)
						self:Print("Pattern: " .. pattern)
						self:Print("Message: " .. msg)
						PrintTable(messages[pattern])
						PrintTable(info)
					end
				end
			end
		end
	end

	self:Print( string.format("Test completed in %.4fs, memory cost %.2fKB.", GetTime() - startTime, collectgarbage("count") - startMem) )
end

function lib:LoadEverything()

	-- Load all patterns and events.
	for _, v in pairs(supportedEvents) do
		for _, w in pairs(self:LoadPatternList(v)) do
			if not patternTable[w] then
				patternTable[w] = self:LoadPatternInfo(w)
			end
		end
	end
end

-- Used to load eventTable elements on demand.
function lib:LoadPatternList(eventName)
	local list

--------------- Melee Hits ----------------

	if eventName == "CHAT_MSG_COMBAT_SELF_HITS" then

		if not eventTable["CHAT_MSG_COMBAT_SELF_HITS"] then

			eventTable["CHAT_MSG_COMBAT_SELF_HITS"] =
				self:LoadPatternCategoryTree(
				{
					"HitSelf",
					"EnvSelf",
				}
			)

		end

		list = eventTable["CHAT_MSG_COMBAT_SELF_HITS"]

	elseif eventName == "CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS"
	or eventName == "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS"
	or eventName == "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"
	or eventName == "CHAT_MSG_COMBAT_PARTY_HITS"
	or eventName == "CHAT_MSG_COMBAT_PET_HITS" then

		if not eventTable["CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"] then
			eventTable["CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"] =
				self:LoadPatternCategoryTree( {
					"HitOtherOther",
					"EnvOther",
				} )
		end
		list = eventTable["CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"]

	elseif eventName == "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS"
	or eventName == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" then

		if not eventTable["CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS"] then
			eventTable["CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS"] =
				self:LoadPatternCategoryTree( {
					{
						"HitOtherOther",
						"HitOtherSelf",
					},
					"EnvOther",
				} )
		end
		list = eventTable["CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS"]

--------------- Melee Misses ----------------

	elseif eventName == "CHAT_MSG_COMBAT_SELF_MISSES" then
		if not eventTable["CHAT_MSG_COMBAT_SELF_MISSES"] then
			eventTable["CHAT_MSG_COMBAT_SELF_MISSES"] =
				self:LoadPatternCategoryTree( {
					"MissSelf",
				} )
		end
		list = eventTable["CHAT_MSG_COMBAT_SELF_MISSES"]

	elseif eventName == "CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES"
	or eventName == "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES"
	or eventName == "CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES"
	or eventName == "CHAT_MSG_COMBAT_PARTY_MISSES"
	or eventName == "CHAT_MSG_COMBAT_PET_MISSES" then

		if not eventTable["CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES"] then
			eventTable["CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES"] = self:LoadPatternCategoryTree( { "MissOtherOther", } )
		end
		list = eventTable["CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES"]
	elseif eventName == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES"
	or eventName == "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES" then

		if not eventTable["CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES"] then
			eventTable["CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES"] =
			self:LoadPatternCategoryTree( {
				{
					"MissOtherOther",
					"MissOtherSelf",
				}
			} )
		end

		list = eventTable["CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES"]

--------------- Spell Buffs ----------------
	elseif eventName == "CHAT_MSG_SPELL_SELF_BUFF" then
		if not eventTable["CHAT_MSG_SPELL_SELF_BUFF"] then

			if GetLocale() ~= "deDE" then
			eventTable["CHAT_MSG_SPELL_SELF_BUFF"] = self:LoadPatternCategoryTree(
				{
					"HealSelf",
					"EnchantSelf",
					"CastSelf",
					"PerformSelf",
					"DispelFailSelf",
					"SPELLCASTSELFSTART",
					"SPELLPERFORMSELFSTART",
					{
						"DrainSelf",
						"PowerGainSelf",
						"ExtraAttackSelf",
					},
					"SPELLSPLITDAMAGESELFOTHER",
					{
						"ProcResistSelf",
						"SpellMissSelf",
					}
				}
			)

			else
			eventTable["CHAT_MSG_SPELL_SELF_BUFF"] = self:LoadPatternCategoryTree(
				{
					"HealSelf",
					"CastSelf",
					"PerformSelf",
					"DispelFailSelf",
					"SPELLCASTSELFSTART",
					"SPELLPERFORMSELFSTART",
					{
						"DrainSelf",
						"PowerGainSelf",
						"ExtraAttackSelf",
					},
					"SPELLSPLITDAMAGESELFOTHER",
					{
						"ProcResistSelf",
						"SpellMissSelf",
					}
				}
			)
			end

		end

		list = eventTable["CHAT_MSG_SPELL_SELF_BUFF"]

	elseif eventName == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF"
	or eventName == "CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF"
	or eventName == "CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF"
	or eventName == "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF"
	or eventName == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"
	or eventName == "CHAT_MSG_SPELL_PARTY_BUFF"
	or eventName == "CHAT_MSG_SPELL_PET_BUFF" then

		if not eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"] then
			if GetLocale() ~= "deDE" then
				eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"] = self:LoadPatternCategoryTree(
					{
						{
							"HealOther",
							"PowerGainOther",
							"ExtraAttackOther",
							"DrainOther",
						},
						"SPELLCASTOTHERSTART",
						{
							"EnchantOther",
							"CastOther",
							"PerformOther",
						},
						"SPELLPERFORMOTHERSTART",
						"SpellMissOther",
						"ProcResistOther",
						"SplitDamageOther",
						"DispelFailOther",
					}
				)

			else -- Remove "EnchantOther" from German, since it's 100% ambiguous with SIMPLECASTOTHEROTHER, which is unsolvable.
				eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"] = self:LoadPatternCategoryTree(
					{
						{
							"HealOther",
							"PowerGainOther",
							"ExtraAttackOther",
							"DrainOther",
						},
						"SPELLCASTOTHERSTART",
						{
							"CastOther",
							"PerformOther",
						},
						"SPELLPERFORMOTHERSTART",
						"SpellMissOther",
						"ProcResistOther",
						"SplitDamageOther",
						"DispelFailOther",
					}
				)
			end
		end

		list = eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"]

--------------- Spell Damages ----------------

	elseif eventName == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		if not eventTable["CHAT_MSG_SPELL_SELF_DAMAGE"] then
			eventTable["CHAT_MSG_SPELL_SELF_DAMAGE"] =
				self:LoadPatternCategoryTree( {
					"SpellHitSelf",
					{
						"CastSelf",
						"DurabilityDamageSelf",
					},
					"PerformSelf",
					"SpellMissSelf",
					"SPELLCASTSELFSTART",
					"SPELLPERFORMSELFSTART",
					"InterruptSelf",
					"DispelFailSelf",
					"ExtraAttackSelf",
					"DrainSelf",
				} )

		end
		list = eventTable["CHAT_MSG_SPELL_SELF_DAMAGE"]

	elseif eventName == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_PARTY_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_PET_DAMAGE" then

		if not eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"] then
			eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"] =
				self:LoadPatternCategoryTree( {
					"SpellHitOther",
					"SPELLCASTOTHERSTART",
					"SPELLPERFORMOTHERSTART",
					"DrainOther",
					"SpellMissOther",
					{
						"INSTAKILLOTHER",
						"INSTAKILLSELF",
					},
					{
						"PROCRESISTOTHEROTHER",
						"PROCRESISTOTHERSELF",
					},
					"SplitDamageOther",
					{
						"CastOther",
						"InterruptOther",
						"DurabilityDamageOther",
					},
					"PerformOther",
					"ExtraAttackOther",
					{
						"DISPELFAILEDOTHEROTHER",
						"DISPELFAILEDOTHERSELF",
					},
				})

		end
		list = eventTable["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"]

--------------- Periodic Buffs ----------------

	elseif eventName == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then

		if not eventTable["CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"] then
			eventTable["CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"] =
				self:LoadPatternCategoryTree( {
					{
						"HotOther",
						"HotSelf",
					},
					{
						"BuffSelf",
						"BuffOther",
						"PowerGainOther",
						"PowerGainSelf",
					},
					"DrainSelf",
					"DotSelf",	-- Don't think this will hapen but add it anyway.
				} )
		end
		list = eventTable["CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"]

	elseif eventName == "CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS"
	or eventName == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS"
	or eventName == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"
	or eventName == "CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS" then

		if not eventTable["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"] then
			eventTable["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"] =
				self:LoadPatternCategoryTree( {
					{
						"HotOther",
--						"DrainOther",	-- Dont think this would happen but add it anyway.
					},
					{
						"BuffOther",
						"PowerGainOther",
						"DrainOther",	-- When other players use Skull of Impending Doom.
					},
					"DotOther",	-- Dont think this will happen but add anyway.
					"DebuffOther", -- Was fired on older WoW version.
				} )
		end

		list = eventTable["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"]

--------------- Periodic Damages ----------------

	elseif eventName == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
		if not eventTable["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"] then

			eventTable["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"] =
				self:LoadPatternCategoryTree( {
					{
						"DotSelf",
						"DotOther",
					},
					{
						"DebuffSelf",
						"DebuffOther",
					},
					{
						"SPELLLOGABSORBOTHEROTHER",
						"SPELLLOGABSORBOTHERSELF",
						"SPELLLOGABSORBSELFSELF",
						"SPELLLOGABSORBSELFOTHER",
					},
					"DrainSelf",
				}	)
		end
		list = eventTable["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"]

	elseif eventName == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"
	or eventName == "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE" then

		if not eventTable["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"] then
			eventTable["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"] =
				self:LoadPatternCategoryTree( {
					"DebuffOther",
					"DotOther",
					{
						"SPELLLOGABSORBOTHEROTHER",
						"SPELLLOGABSORBSELFOTHER",
					},
					"DrainOther",
					{
						"PowerGainOther",
						"BuffOther", -- Was fired on older WoW version.
					}
				} )
		end
		list = eventTable["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"]

--------------- Damage Shields ----------------

	elseif eventName == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
		if not eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"] then
			eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"] = {
				"SPELLRESISTOTHEROTHER",
				"SPELLRESISTSELFOTHER",
				"DAMAGESHIELDOTHEROTHER",
				"DAMAGESHIELDSELFOTHER",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"]

	elseif eventName == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS" then
		if not eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS"] then
			eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS"] = {
				"SPELLRESISTOTHEROTHER",
				"SPELLRESISTOTHERSELF",
				"DAMAGESHIELDOTHEROTHER",
				"DAMAGESHIELDOTHERSELF",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS"]

--------------- Auras ----------------

	elseif eventName == "CHAT_MSG_SPELL_AURA_GONE_PARTY"
	or eventName == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then

		if not eventTable["CHAT_MSG_SPELL_AURA_GONE_OTHER"] then
			eventTable["CHAT_MSG_SPELL_AURA_GONE_OTHER"] = {
				"AURAREMOVEDOTHER",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_AURA_GONE_OTHER"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_AURA_GONE_OTHER"]

	elseif eventName == "CHAT_MSG_SPELL_AURA_GONE_SELF" then

		if not eventTable["CHAT_MSG_SPELL_AURA_GONE_SELF"] then
			eventTable["CHAT_MSG_SPELL_AURA_GONE_SELF"] = {
				"AURAREMOVEDOTHER",
				"AURAREMOVEDSELF",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_AURA_GONE_SELF"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_AURA_GONE_SELF"]

	elseif eventName == "CHAT_MSG_SPELL_BREAK_AURA" then

		if not eventTable["CHAT_MSG_SPELL_BREAK_AURA"] then
			eventTable["CHAT_MSG_SPELL_BREAK_AURA"] = {
				"AURADISPELSELF",
				"AURADISPELOTHER",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_BREAK_AURA"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_BREAK_AURA"]

	elseif eventName == "CHAT_MSG_SPELL_ITEM_ENCHANTMENTS" then

		if not eventTable["CHAT_MSG_SPELL_ITEM_ENCHANTMENTS"] then
			eventTable["CHAT_MSG_SPELL_ITEM_ENCHANTMENTS"] = {
				"ITEMENCHANTMENTADDSELFSELF",
				"ITEMENCHANTMENTADDSELFOTHER",
				"ITEMENCHANTMENTADDOTHEROTHER",
				"ITEMENCHANTMENTADDOTHERSELF",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_ITEM_ENCHANTMENTS"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_ITEM_ENCHANTMENTS"]

--------------- Trade Skills ----------------

	elseif eventName == "CHAT_MSG_SPELL_TRADESKILLS" then
		if not eventTable["CHAT_MSG_SPELL_TRADESKILLS"] then
			eventTable["CHAT_MSG_SPELL_TRADESKILLS"] = {
				"TRADESKILL_LOG_FIRSTPERSON",
				"TRADESKILL_LOG_THIRDPERSON",
				"FEEDPET_LOG_FIRSTPERSON",
				"FEEDPET_LOG_THIRDPERSON",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_TRADESKILLS"], PatternCompare )
		end
		list = eventTable["CHAT_MSG_SPELL_TRADESKILLS"]
		list = eventTable["CHAT_MSG_SPELL_TRADESKILLS"]

	elseif eventName == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" then

		if not eventTable["CHAT_MSG_SPELL_FAILED_LOCALPLAYER"] then
			eventTable["CHAT_MSG_SPELL_FAILED_LOCALPLAYER"] = {
				"SPELLFAILPERFORMSELF",
				"SPELLFAILCASTSELF",
			}
			table.sort(eventTable["CHAT_MSG_SPELL_FAILED_LOCALPLAYER"], PatternCompare)
		end
		list = eventTable["CHAT_MSG_SPELL_FAILED_LOCALPLAYER"]

	elseif eventName == "CHAT_MSG_COMBAT_FACTION_CHANGE" then

		if not eventTable["CHAT_MSG_COMBAT_FACTION_CHANGE"] then

			eventTable["CHAT_MSG_COMBAT_FACTION_CHANGE"] = {
				"FACTION_STANDING_CHANGED",
				"FACTION_STANDING_DECREASED",
				"FACTION_STANDING_INCREASED",
			}
			table.sort(eventTable["CHAT_MSG_COMBAT_FACTION_CHANGE"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_COMBAT_FACTION_CHANGE"]

	elseif eventName == "CHAT_MSG_COMBAT_HONOR_GAIN" then

		if not eventTable["CHAT_MSG_COMBAT_HONOR_GAIN"] then
			eventTable["CHAT_MSG_COMBAT_HONOR_GAIN"] = {
			"COMBATLOG_HONORAWARD",
			"COMBATLOG_HONORGAIN",
			"COMBATLOG_DISHONORGAIN",
			}
			table.sort(eventTable["CHAT_MSG_COMBAT_HONOR_GAIN"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_COMBAT_HONOR_GAIN"]
	elseif eventName == "CHAT_MSG_COMBAT_XP_GAIN" then

		if not eventTable["CHAT_MSG_COMBAT_XP_GAIN"] then
			eventTable["CHAT_MSG_COMBAT_XP_GAIN"] = {
				"COMBATLOG_XPGAIN",
				"COMBATLOG_XPGAIN_EXHAUSTION1",
				"COMBATLOG_XPGAIN_EXHAUSTION1_GROUP",
				"COMBATLOG_XPGAIN_EXHAUSTION1_RAID",
				"COMBATLOG_XPGAIN_EXHAUSTION2",
				"COMBATLOG_XPGAIN_EXHAUSTION2_GROUP",
				"COMBATLOG_XPGAIN_EXHAUSTION2_RAID",
				"COMBATLOG_XPGAIN_EXHAUSTION4",
				"COMBATLOG_XPGAIN_EXHAUSTION4_GROUP",
				"COMBATLOG_XPGAIN_EXHAUSTION4_RAID",
				"COMBATLOG_XPGAIN_EXHAUSTION5",
				"COMBATLOG_XPGAIN_EXHAUSTION5_GROUP",
				"COMBATLOG_XPGAIN_EXHAUSTION5_RAID",
				"COMBATLOG_XPGAIN_FIRSTPERSON",
				"COMBATLOG_XPGAIN_FIRSTPERSON_GROUP",
				"COMBATLOG_XPGAIN_FIRSTPERSON_RAID",
				"COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED",
				"COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP",
				"COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID",
				"COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED",
			}
			table.sort(eventTable["CHAT_MSG_COMBAT_XP_GAIN"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_COMBAT_XP_GAIN"]

	elseif eventName == "CHAT_MSG_COMBAT_FRIENDLY_DEATH"
	or eventName == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then

		if not eventTable["CHAT_MSG_COMBAT_HOSTILE_DEATH"] then
			eventTable["CHAT_MSG_COMBAT_HOSTILE_DEATH"] = {
				"SELFKILLOTHER",
				"PARTYKILLOTHER",
				"UNITDESTROYEDOTHER",
				"UNITDIESOTHER",
				"UNITDIESSELF",
			}

			table.sort(eventTable["CHAT_MSG_COMBAT_HOSTILE_DEATH"] , PatternCompare)
		end
		list = eventTable["CHAT_MSG_COMBAT_HOSTILE_DEATH"]

	end

	if not list then
		-- self:Print(string.format("Event '%s' not found.", eventName), 1, 0,0) -- debug
	end

	return list
end

function lib:LoadPatternCategory(category)

	local list

	if category == "AuraChange" then list = {
			"AURACHANGEDOTHER",
			"AURACHANGEDSELF",
		}
	elseif category == "AuraDispel" then list = {
			"AURADISPELOTHER",
			"AURADISPELSELF",
		}
	elseif category == "BuffOther" then list = {
			"AURAADDEDOTHERHELPFUL",
			"AURAAPPLICATIONADDEDOTHERHELPFUL",
		}
	elseif category == "BuffSelf" then list = {
			"AURAADDEDSELFHELPFUL",
			"AURAAPPLICATIONADDEDSELFHELPFUL",
		}
	elseif category == "CastOther" then list = {
			"SIMPLECASTOTHEROTHER",
			"SIMPLECASTOTHERSELF",
			"SPELLTERSE_OTHER",
		}
	elseif category == "CastSelf" then list = {
			"SIMPLECASTSELFOTHER",
			"SIMPLECASTSELFSELF",
			"SPELLTERSE_SELF",
		}
	elseif category == "DebuffOther" then list = {
			"AURAADDEDOTHERHARMFUL",
			"AURAAPPLICATIONADDEDOTHERHARMFUL",
		}
	elseif category == "DebuffSelf" then list = {
			"AURAADDEDSELFHARMFUL",
			"AURAAPPLICATIONADDEDSELFHARMFUL",
		}
	elseif category == "DispelFailOther" then list = {
			"DISPELFAILEDOTHEROTHER",
			"DISPELFAILEDOTHERSELF",

		}
	elseif category == "DispelFailSelf" then list = {
			"DISPELFAILEDSELFOTHER",
			"DISPELFAILEDSELFSELF",
		}
	elseif category == "DmgShieldOther" then list = {
			"DAMAGESHIELDOTHEROTHER",
			"DAMAGESHIELDOTHERSELF",
		}
	elseif category == "DmgShieldSelf" then list = {
			"DAMAGESHIELDSELFOTHER",
		}
	elseif category == "DurabilityDamageSelf" then list = {
			"SPELLDURABILITYDAMAGEALLSELFOTHER",
			"SPELLDURABILITYDAMAGESELFOTHER",
	}
	elseif category == "DurabilityDamageOther" then list = {
			"SPELLDURABILITYDAMAGEALLOTHEROTHER",
			"SPELLDURABILITYDAMAGEALLOTHERSELF",
			"SPELLDURABILITYDAMAGEOTHEROTHER",
			"SPELLDURABILITYDAMAGEOTHERSELF",
	}
	elseif category == "EnchantOther" then list = {
			"ITEMENCHANTMENTADDOTHEROTHER",
			"ITEMENCHANTMENTADDOTHERSELF",
		}
	elseif category == "EnchantSelf" then list = {
			"ITEMENCHANTMENTADDSELFOTHER",
			"ITEMENCHANTMENTADDSELFSELF",
		}
	elseif category == "ExtraAttackOther" then list = {
			"SPELLEXTRAATTACKSOTHER",
			"SPELLEXTRAATTACKSOTHER_SINGULAR",
		}
	elseif category == "ExtraAttackSelf" then list = {
			"SPELLEXTRAATTACKSSELF",
			"SPELLEXTRAATTACKSSELF_SINGULAR",
		}
	elseif category == "Fade" then list = {
			"AURAREMOVEDOTHER",
			"AURAREMOVEDSELF",
		}
	elseif category == "HealOther" then list = {
			"HEALEDCRITOTHEROTHER",
			"HEALEDCRITOTHERSELF",
			"HEALEDOTHEROTHER",
			"HEALEDOTHERSELF",
		}
	elseif category == "HealSelf" then list = {
			"HEALEDCRITSELFOTHER",
			"HEALEDCRITSELFSELF",
			"HEALEDSELFOTHER",
			"HEALEDSELFSELF",
		}
	elseif category == "HitOtherOther" then list = {
			"COMBATHITCRITOTHEROTHER",
			"COMBATHITCRITSCHOOLOTHEROTHER",
			"COMBATHITOTHEROTHER",
			"COMBATHITSCHOOLOTHEROTHER",
			"SPELLLOGCRITOTHEROTHER",
			"SPELLLOGCRITSCHOOLOTHEROTHER",
			"SPELLLOGOTHEROTHER",
			"SPELLLOGSCHOOLOTHEROTHER",
		}
	elseif category == "HitOtherSelf" then list = {

			"COMBATHITCRITOTHERSELF",
			"COMBATHITCRITSCHOOLOTHERSELF",
			"COMBATHITOTHERSELF",
			"COMBATHITSCHOOLOTHERSELF",
			"SPELLLOGCRITOTHERSELF",
			"SPELLLOGCRITSCHOOLOTHERSELF",
			"SPELLLOGOTHERSELF",
			"SPELLLOGSCHOOLOTHERSELF",
		}
	elseif category == "HitSelf" then list = {
			"COMBATHITSCHOOLSELFOTHER",
			"COMBATHITSELFOTHER",
			"COMBATHITCRITSCHOOLSELFOTHER",
			"COMBATHITCRITSELFOTHER",
			"SPELLLOGSELFOTHER",
			"SPELLLOGCRITSELFOTHER",
			"SPELLLOGSCHOOLSELFOTHER",
			"SPELLLOGCRITSCHOOLSELFOTHER",
		}
	elseif category == "MissOtherOther" then list = {
			"MISSEDOTHEROTHER",
			"VSABSORBOTHEROTHER",
			"VSBLOCKOTHEROTHER",
			"VSDEFLECTOTHEROTHER",
			"VSDODGEOTHEROTHER",
			"VSEVADEOTHEROTHER",
			"VSIMMUNEOTHEROTHER",
			"VSPARRYOTHEROTHER",
			"VSRESISTOTHEROTHER",
			"IMMUNEDAMAGECLASSOTHEROTHER",
			"IMMUNEOTHEROTHER",

		}
	elseif category == "MissOtherSelf" then list = {
			"MISSEDOTHERSELF",
			"VSABSORBOTHERSELF",
			"VSBLOCKOTHERSELF",
			"VSDEFLECTOTHERSELF",
			"VSDODGEOTHERSELF",
			"VSEVADEOTHERSELF",
			"VSIMMUNEOTHERSELF",
			"VSPARRYOTHERSELF",
			"VSRESISTOTHERSELF",
			"IMMUNEDAMAGECLASSOTHERSELF",
			"IMMUNEOTHERSELF",
		}
	elseif category == "MissSelf" then list = {
				"MISSEDSELFOTHER",
				"VSABSORBSELFOTHER",
				"VSBLOCKSELFOTHER",
				"VSDEFLECTSELFOTHER",
				"VSDODGESELFOTHER",
				"VSEVADESELFOTHER",
				"VSIMMUNESELFOTHER",
				"VSPARRYSELFOTHER",
				"VSRESISTSELFOTHER",
				"IMMUNEDAMAGECLASSSELFOTHER",
				"IMMUNESELFOTHER",
				"IMMUNESELFSELF",
				"SPELLMISSSELFOTHER",
		}
	elseif category == "PowerGainOther" then list = {
			"POWERGAINOTHEROTHER",
			"POWERGAINOTHERSELF",
		}
	elseif category == "PerformOther" then list = {
			"OPEN_LOCK_OTHER",
			"SIMPLEPERFORMOTHEROTHER",
			"SIMPLEPERFORMOTHERSELF",
			"SPELLTERSEPERFORM_OTHER",
		}
	elseif category == "PerformSelf" then list = {
			"OPEN_LOCK_SELF",
			"SIMPLEPERFORMSELFOTHER",
			"SIMPLEPERFORMSELFSELF",
			"SPELLTERSEPERFORM_SELF",
		}
	elseif category == "ProcResistOther" then list = {
			"PROCRESISTOTHEROTHER",
			"PROCRESISTOTHERSELF",
		}
	elseif category == "ProcResistSelf" then list = {
			"PROCRESISTSELFOTHER",
			"PROCRESISTSELFSELF",
		}
	elseif category == "EnvOther" then list = {
			"VSENVIRONMENTALDAMAGE_DROWNING_OTHER",
			"VSENVIRONMENTALDAMAGE_FALLING_OTHER",
			"VSENVIRONMENTALDAMAGE_FATIGUE_OTHER",
			"VSENVIRONMENTALDAMAGE_FIRE_OTHER",
			"VSENVIRONMENTALDAMAGE_LAVA_OTHER",
			"VSENVIRONMENTALDAMAGE_SLIME_OTHER",
		}
	elseif category == "EnvSelf" then list = {
			"VSENVIRONMENTALDAMAGE_DROWNING_SELF",
			"VSENVIRONMENTALDAMAGE_FALLING_SELF",
			"VSENVIRONMENTALDAMAGE_FATIGUE_SELF",
			"VSENVIRONMENTALDAMAGE_FIRE_SELF",
			"VSENVIRONMENTALDAMAGE_LAVA_SELF",
			"VSENVIRONMENTALDAMAGE_SLIME_SELF",
		}
	-- HoT effects on others. (not casted by others)
	elseif category == "HotOther" then list = {
			"PERIODICAURAHEALOTHEROTHER",
			"PERIODICAURAHEALSELFOTHER",
		}
	-- HoT effects on you. (not casted by you)
	elseif category == "HotSelf" then list = {
			"PERIODICAURAHEALSELFSELF",
			"PERIODICAURAHEALOTHERSELF",
		}
	elseif category == "PowerGainSelf" then list = {
			"POWERGAINSELFSELF",
			"POWERGAINSELFOTHER",
		}
	elseif category == "BuffOther" then list = {
		"AURAAPPLICATIONADDEDOTHERHELPFUL",
		"AURAADDEDOTHERHELPFUL",
		}
	elseif category == "BuffSelf" then list = {
			"AURAADDEDSELFHELPFUL",
			"AURAAPPLICATIONADDEDSELFHELPFUL",
		}
	elseif category == "DrainSelf" then list = {
			"SPELLPOWERLEECHSELFOTHER",
			"SPELLPOWERDRAINSELFOTHER",
			"SPELLPOWERDRAINSELFSELF",
		}
	elseif category == "DrainOther" then list = {
			"SPELLPOWERLEECHOTHEROTHER",
			"SPELLPOWERLEECHOTHERSELF",
			"SPELLPOWERDRAINOTHEROTHER",
			"SPELLPOWERDRAINOTHERSELF",
		}
	-- DoT effects on others (not casted by others)
	elseif category == "DotOther" then list = {
			"PERIODICAURADAMAGEOTHEROTHER",
			"PERIODICAURADAMAGESELFOTHER",
			--"PERIODICAURADAMAGEOTHER",
		}
	-- DoT effects on you (not casted by you)
	elseif category == "DotSelf" then list = {
			"PERIODICAURADAMAGEOTHERSELF",
			"PERIODICAURADAMAGESELFSELF",
			--"PERIODICAURADAMAGESELF",
		}
	elseif category == "SpellHitOther" then list = {
			"SPELLLOGCRITOTHEROTHER",
			"SPELLLOGCRITOTHERSELF",
			"SPELLLOGCRITSCHOOLOTHEROTHER",
			"SPELLLOGCRITSCHOOLOTHERSELF",
			"SPELLLOGOTHEROTHER",
			"SPELLLOGOTHERSELF",
			"SPELLLOGSCHOOLOTHEROTHER",
			"SPELLLOGSCHOOLOTHERSELF",
		}
	elseif category == "SpellHitSelf" then list = {
			"SPELLLOGCRITSELFOTHER",
			"SPELLLOGCRITSELFSELF",
			"SPELLLOGCRITSCHOOLSELFOTHER",
			"SPELLLOGCRITSCHOOLSELFSELF",
			"SPELLLOGSELFOTHER",
			"SPELLLOGSELFSELF",
			"SPELLLOGSCHOOLSELFOTHER",
			"SPELLLOGSCHOOLSELFSELF",
		}
	elseif category == "SpellMissSelf" then list = {
			"IMMUNESPELLSELFOTHER",
			"IMMUNESPELLSELFSELF",
			"SPELLBLOCKEDSELFOTHER",
			"SPELLDEFLECTEDSELFOTHER",
			"SPELLDEFLECTEDSELFSELF",
			"SPELLDODGEDSELFOTHER",
			"SPELLDODGEDSELFSELF",
			"SPELLEVADEDSELFOTHER",
			"SPELLEVADEDSELFSELF",
			"SPELLIMMUNESELFOTHER",
			"SPELLIMMUNESELFSELF",
			"SPELLLOGABSORBSELFOTHER",
			"SPELLLOGABSORBSELFSELF",
			"SPELLMISSSELFOTHER",
			"SPELLMISSSELFSELF",
			"SPELLPARRIEDSELFOTHER",
			"SPELLPARRIEDSELFSELF",
			"SPELLREFLECTSELFOTHER",
			"SPELLREFLECTSELFSELF",
			"SPELLRESISTSELFOTHER",
			"SPELLRESISTSELFSELF",
		}
	elseif category == "SpellMissOther" then list = {
			"IMMUNESPELLOTHEROTHER",
			"IMMUNESPELLOTHERSELF",
			"SPELLBLOCKEDOTHEROTHER",
			"SPELLBLOCKEDOTHERSELF",
			"SPELLDODGEDOTHEROTHER",
			"SPELLDODGEDOTHERSELF",
			"SPELLDEFLECTEDOTHEROTHER",
			"SPELLDEFLECTEDOTHERSELF",
			"SPELLEVADEDOTHEROTHER",
			"SPELLEVADEDOTHERSELF",
			"SPELLIMMUNEOTHEROTHER",
			"SPELLIMMUNEOTHERSELF",
			"SPELLLOGABSORBOTHEROTHER",
			"SPELLLOGABSORBOTHERSELF",
			"SPELLMISSOTHEROTHER",
			"SPELLMISSOTHERSELF",
			"SPELLPARRIEDOTHEROTHER",
			"SPELLPARRIEDOTHERSELF",
			"SPELLREFLECTOTHEROTHER",
			"SPELLREFLECTOTHERSELF",
			"SPELLRESISTOTHEROTHER",
			"SPELLRESISTOTHERSELF",
		}
	elseif category == "InterruptOther" then list = {
			"SPELLINTERRUPTOTHEROTHER",
			"SPELLINTERRUPTOTHERSELF",
		}
	elseif category == "InterruptSelf" then list = {
			"SPELLINTERRUPTSELFOTHER",
		}
	elseif category == "SplitDamageOther" then list = {
		"SPELLSPLITDAMAGEOTHEROTHER",
		"SPELLSPLITDAMAGEOTHERSELF",
	}
	else return { category }
	end

	return list
end

-- Load categories recursively. First layer will not be sorted.
function lib:LoadPatternCategoryTree(catTree, reSort)
	if type(catTree) ~= "table" then return end

	local resultList = {}
	local list

	for i, v in pairs(catTree) do

		if type(v) == "table" then
			list = self:LoadPatternCategoryTree(v, true)
		else -- should be string
			list = self:LoadPatternCategory(v)
			table.sort(list, PatternCompare)
		end

		for j, w in pairs(list) do
			table.insert(resultList, w)
		end

	end

	if reSort then
		table.sort(resultList, PatternCompare)
	end

	return resultList
end

-- Used to load patternTable elements on demand.
function lib:LoadPatternInfo(patternName)

	local patternInfo

	-- buff = { "victim", "skill", "amountRank" },
	if patternName == "AURAADDEDOTHERHELPFUL" then
		patternInfo = { "buff", 1, 2, nil, }
	elseif patternName == "AURAADDEDSELFHELPFUL" then
		patternInfo = { "buff", ParserLib_SELF, 1, nil, }
	elseif patternName == "AURAAPPLICATIONADDEDOTHERHELPFUL" then
		patternInfo = { "buff", 1, 2, 3, }
	elseif patternName == "AURAAPPLICATIONADDEDSELFHELPFUL" then
		patternInfo = { "buff", ParserLib_SELF, 1, 2, }

	-- cast = { "source", "skill", "victim", "isBegin", "isPerform" },
	elseif patternName == "OPEN_LOCK_OTHER" then
		patternInfo = { "cast", 1, 2, 3, nil, true, }
	elseif patternName == "OPEN_LOCK_SELF" then
		patternInfo = { "cast", ParserLib_SELF, 1, 2, nil, true, }
	elseif patternName == "SIMPLECASTOTHEROTHER" then
		patternInfo = { "cast", 1, 2, 3, nil, nil, }
	elseif patternName == "SIMPLECASTOTHERSELF" then
		patternInfo = { "cast", 1, 2, ParserLib_SELF, nil, nil, }
	elseif patternName == "SIMPLECASTSELFOTHER" then
		patternInfo = { "cast", ParserLib_SELF, 1, 2, nil, nil, }
	elseif patternName == "SIMPLECASTSELFSELF" then
		patternInfo = { "cast", ParserLib_SELF, 1, ParserLib_SELF, nil, nil, }
	elseif patternName == "SIMPLEPERFORMOTHEROTHER" then
		patternInfo = { "cast", 1, 2, 3, nil, true, }
	elseif patternName == "SIMPLEPERFORMOTHERSELF" then
		patternInfo = { "cast", 1, 2, ParserLib_SELF, nil, true, }
	elseif patternName == "SIMPLEPERFORMSELFOTHER" then
		patternInfo = { "cast", ParserLib_SELF, 1, 2, nil, true, }
	elseif patternName == "SIMPLEPERFORMSELFSELF" then
		patternInfo = { "cast", ParserLib_SELF, 1, ParserLib_SELF, nil, true, }
	elseif patternName == "SPELLCASTOTHERSTART" then
		patternInfo = { "cast", 1, 2, nil, true, nil, }
	elseif patternName == "SPELLCASTSELFSTART" then
		patternInfo = { "cast", ParserLib_SELF, 1, nil, true, nil, }
	elseif patternName == "SPELLPERFORMOTHERSTART" then
		patternInfo = { "cast", 1, 2, nil, true, true, }
	elseif patternName == "SPELLPERFORMSELFSTART" then
		patternInfo = { "cast", ParserLib_SELF, 1, nil, true, true, }
	elseif patternName == "SPELLTERSEPERFORM_OTHER" then
		patternInfo = { "cast", 1, 2, nil, nil, true, }
	elseif patternName == "SPELLTERSEPERFORM_SELF" then
		patternInfo = { "cast", ParserLib_SELF, 1, nil, nil, true, }
	elseif patternName == "SPELLTERSE_OTHER" then
		patternInfo = { "cast", 1, 2, nil, nil, nil, }
	elseif patternName == "SPELLTERSE_SELF" then
		patternInfo = { "cast", ParserLib_SELF, 1, nil, nil, nil, }

	-- create = { "source", "item" },
	elseif patternName == "TRADESKILL_LOG_FIRSTPERSON" then
		patternInfo = { "create", ParserLib_SELF, 1, }
	elseif patternName == "TRADESKILL_LOG_THIRDPERSON" then
		patternInfo = { "create", 1, 2, }

	-- death = { "victim", "source", "skill", "isItem" },
	elseif patternName == "PARTYKILLOTHER" then
		patternInfo = { "death", 1, 2, nil, nil, }
	elseif patternName == "SELFKILLOTHER" then
		patternInfo = { "death", 1, ParserLib_SELF, nil, nil, }
	elseif patternName == "UNITDESTROYEDOTHER" then
		patternInfo = { "death", 1, nil, nil, true }
	elseif patternName == "UNITDIESOTHER" then
		patternInfo = { "death", 1, nil, nil, nil, }
	elseif patternName == "UNITDIESSELF" then
		patternInfo = { "death", ParserLib_SELF, nil, nil, nil, }
	elseif patternName == "INSTAKILLOTHER" then
		patternInfo = { "death", 1, nil, 2, nil, }
	elseif patternName == "INSTAKILLSELF" then
		patternInfo = { "death", ParserLib_SELF, nil, 1, nil }

	-- debuff = { "victim", "skill", "amountRank" },
	elseif patternName == "AURAADDEDOTHERHARMFUL" then
		patternInfo = { "debuff", 1, 2, nil, }
	elseif patternName == "AURAADDEDSELFHARMFUL" then
		patternInfo = { "debuff", ParserLib_SELF, 1, nil, }
	elseif patternName == "AURAAPPLICATIONADDEDOTHERHARMFUL" then
		patternInfo = { "debuff", 1, 2, 3, }
	elseif patternName == "AURAAPPLICATIONADDEDSELFHARMFUL" then
		patternInfo = { "debuff", ParserLib_SELF, 1, 2, }

	-- dispel = { "victim", "skill", "source", "isFailed" },
	elseif patternName == "AURADISPELOTHER" then
		patternInfo = { "dispel", 1, 2, nil, nil, }
	elseif patternName == "AURADISPELSELF" then
		patternInfo = { "dispel", ParserLib_SELF, 1, nil, nil, }
	elseif patternName == "DISPELFAILEDOTHEROTHER" then
		patternInfo = { "dispel", 2, 3, 1, true, }
	elseif patternName == "DISPELFAILEDOTHERSELF" then
		patternInfo = { "dispel", ParserLib_SELF, 2, 1, true, }
	elseif patternName == "DISPELFAILEDSELFOTHER" then
		patternInfo = { "dispel", 1, 2, ParserLib_SELF, true, }
	elseif patternName == "DISPELFAILEDSELFSELF" then
		patternInfo = { "dispel", ParserLib_SELF, 1, ParserLib_SELF, true, }
	-- WoW2.0 new patterns : more info needed.
	--[[
			SPELLPOWERDRAINOTHER = "%s drains %d %s from %s."
			SPELLPOWERDRAINSELF = "%s drains %d %s from you."
	]]

	-- drain = { "source", "victim", "skill", "amount", "attribute" },
	elseif patternName == "SPELLPOWERDRAINOTHEROTHER" then
		patternInfo = { "drain", 1, 5, 2, 3, 4, }
	elseif patternName == "SPELLPOWERDRAINOTHERSELF" then
		patternInfo = { "drain", 1, ParserLib_SELF, 2, 3, 4, }
	elseif patternName == "SPELLPOWERDRAINSELFOTHER" then
		patternInfo = { "drain", ParserLib_SELF, 4, 1, 2, 3, }
	elseif patternName == "SPELLPOWERDRAINSELFSELF" then
		patternInfo = { "drain", ParserLib_SELF, ParserLib_SELF, 1, 2, 3, }

	-- 	durability = { "source", "skill", "victim", "item" }, -- is not item then isAllItems = true
	elseif patternName == "SPELLDURABILITYDAMAGEALLOTHEROTHER" then
		patternInfo = { "durability", 1, 2, 3, nil, }
	elseif patternName == "SPELLDURABILITYDAMAGEALLOTHERSELF" then
		patternInfo = { "durability", 1, 2, ParserLib_SELF, nil, }
	elseif patternName == "SPELLDURABILITYDAMAGEALLSELFOTHER" then
		patternInfo = { "durability", ParserLib_SELF, 1, 2, nil, }
	elseif patternName == "SPELLDURABILITYDAMAGEOTHEROTHER" then
		patternInfo = { "durability", 1, 2, 3, 4, }
	elseif patternName == "SPELLDURABILITYDAMAGEOTHERSELF" then
		patternInfo = { "durability", 1, 2, ParserLib_SELF, 3, }
	elseif patternName == "SPELLDURABILITYDAMAGESELFOTHER" then
		patternInfo = { "durability", ParserLib_SELF, 1, 2, 3, }

	-- enchant = { "source", "victim", "skill", "item" },
	elseif patternName == "ITEMENCHANTMENTADDOTHEROTHER" then
		patternInfo = { "enchant", 1, 3, 2, 4, }
	elseif patternName == "ITEMENCHANTMENTADDOTHERSELF" then
		patternInfo = { "enchant", 1, ParserLib_SELF, 2, 3, }
	elseif patternName == "ITEMENCHANTMENTADDSELFOTHER" then
		patternInfo = { "enchant", ParserLib_SELF, 2, 1, 3, }
	elseif patternName == "ITEMENCHANTMENTADDSELFSELF" then
		patternInfo = { "enchant", ParserLib_SELF, ParserLib_SELF, 1, 2, }

	-- environment = { "victim", "amount", "damageType" },
	elseif patternName == "VSENVIRONMENTALDAMAGE_DROWNING_OTHER" then
		patternInfo = { "environment", 1, 2, "drown", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_DROWNING_SELF" then
		patternInfo = { "environment", ParserLib_SELF, 1, "drown", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_FALLING_OTHER" then
		patternInfo = { "environment", 1, 2, "fall", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_FALLING_SELF" then
		patternInfo = { "environment", ParserLib_SELF, 1, "fall", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_FATIGUE_OTHER" then
		patternInfo = { "environment", 1, 2, "exhaust", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_FATIGUE_SELF" then
		patternInfo = { "environment", ParserLib_SELF, 1, "exhaust", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_FIRE_OTHER" then
		patternInfo = { "environment", 1, 2, "fire", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_FIRE_SELF" then
		patternInfo = { "environment", ParserLib_SELF, 1, "fire", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_LAVA_OTHER" then
		patternInfo = { "environment", 1, 2, "lava", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_LAVA_SELF" then
		patternInfo = { "environment", ParserLib_SELF, 1, "lava", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_SLIME_OTHER" then
		patternInfo = { "environment", 1, 2, "slime", }
	elseif patternName == "VSENVIRONMENTALDAMAGE_SLIME_SELF" then
		patternInfo = { "environment", ParserLib_SELF, 1, "slime", }

	-- experience = { "amount", "source", "bonusAmount", "bonusType", "penaltyAmount", "penaltyType", "amountRaidPenalty", "amountGroupBonus", "victim" },
	elseif patternName == "COMBATLOG_XPGAIN" then
		patternInfo = { "experience", 2, nil, nil, nil, nil, nil, nil, nil, 1, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION1" then
		patternInfo = { "experience", 2, 1, 3, 4, nil, nil, nil, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION1_GROUP" then
		patternInfo = { "experience", 2, 1, 3, 4, nil, nil, nil, 5, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION1_RAID" then
		patternInfo = { "experience", 2, 1, 3, 4, nil, nil, 5, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION2" then
		patternInfo = { "experience", 2, 1, 3, 4, nil, nil, nil, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION2_GROUP" then
		patternInfo = { "experience", 2, 1, 3, 4, nil, nil, nil, 5, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION2_RAID" then
		patternInfo = { "experience", 2, 1, 3, 4, nil, nil, 5, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION4" then
		patternInfo = { "experience", 2, 1, nil, nil, 3, 4, nil, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION4_GROUP" then
		patternInfo = { "experience", 2, 1, nil, nil, 3, 4, nil, 5, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION4_RAID" then
		patternInfo = { "experience", 2, 1, nil, nil, 3, 4, 5, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION5" then
		patternInfo = { "experience", 2, 1, nil, nil, 3, 4, nil, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION5_GROUP" then
		patternInfo = { "experience", 2, 1, nil, nil, 3, 4, nil, 5, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_EXHAUSTION5_RAID" then
		patternInfo = { "experience", 2, 1, nil, nil, 3, 4, 5, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_FIRSTPERSON" then
		patternInfo = { "experience", 2, 1, nil, nil, nil, nil, nil, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_FIRSTPERSON_GROUP" then
		patternInfo = { "experience", 2, 1, nil, nil, nil, nil, nil, 3, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_FIRSTPERSON_RAID" then
		patternInfo = { "experience", 2, 1, nil, nil, nil, nil, 3, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED" then
		patternInfo = { "experience", 1, nil, nil, nil, nil, nil, nil, nil, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP" then
		patternInfo = { "experience", 1, nil, nil, nil, nil, nil, nil, 2, nil, }
	elseif patternName == "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID" then
		patternInfo = { "experience", 1, nil, nil, nil, nil, nil, 2, nil, nil, }
	elseif patternName == "COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED" then
		patternInfo = { "experience", 1, nil, nil, nil, nil, nil, nil, nil, nil, }

	-- extraattack = { "victim", "skill", "amount" },
	elseif patternName == "SPELLEXTRAATTACKSOTHER" then
		patternInfo = { "extraattack", 1, 3, 2, }
	elseif patternName == "SPELLEXTRAATTACKSOTHER_SINGULAR" then
		patternInfo = { "extraattack", 1, 3, 2, }
	elseif patternName == "SPELLEXTRAATTACKSSELF" then
		patternInfo = { "extraattack", ParserLib_SELF, 2, 1, }
	elseif patternName == "SPELLEXTRAATTACKSSELF_SINGULAR" then
		patternInfo = { "extraattack", ParserLib_SELF, 2, 1, }

	-- fade = { "victim", "skill" },
	elseif patternName == "AURAREMOVEDOTHER" then
		patternInfo = { "fade", 2, 1, }
	elseif patternName == "AURAREMOVEDSELF" then
		patternInfo = { "fade", ParserLib_SELF, 1, }

	-- fail = { "source", "skill", "reason" },
	elseif patternName == "SPELLFAILCASTSELF" then
		patternInfo = { "fail", ParserLib_SELF, 1, 2, }
	elseif patternName == "SPELLFAILPERFORMSELF" then
		patternInfo = { "fail", ParserLib_SELF, 1, 2, }

	-- feedpet = { "victim", "item" },
	elseif patternName == "FEEDPET_LOG_FIRSTPERSON" then
		patternInfo = { "feedpet", ParserLib_SELF, 1, }
	elseif patternName == "FEEDPET_LOG_THIRDPERSON" then
		patternInfo = { "feedpet", 1, 2, }

	-- gain = { "source", "victim", "skill", "amount", "attribute" },
	elseif patternName == "POWERGAINOTHEROTHER" then
		patternInfo = { "gain", 4, 1, 5, 2, 3, }
	elseif patternName == "POWERGAINOTHERSELF" then
		patternInfo = { "gain", 3, ParserLib_SELF, 4, 1, 2, }
	elseif patternName == "POWERGAINSELFOTHER" then
		patternInfo = { "gain", ParserLib_SELF, 1, 4, 2, 3, }
	elseif patternName == "POWERGAINSELFSELF" then
		patternInfo = { "gain", ParserLib_SELF, ParserLib_SELF, 3, 1, 2, }
	-- WoW2.0 new patterns : more info needed.
	--[[
	POWERGAINOTHER = "%s gains %d %s from %s."
	POWERGAINSELF = "You gain %d %s from %s."
	]]

	-- heal = { "source", "victim", "skill", "amount", "isCrit", "isDOT" },
	elseif patternName == "HEALEDCRITOTHEROTHER" then
		patternInfo = { "heal", 1, 3, 2, 4, true, nil, }
	elseif patternName == "HEALEDCRITOTHERSELF" then
		patternInfo = { "heal", 1, ParserLib_SELF, 2, 3, true, nil, }
	elseif patternName == "HEALEDCRITSELFOTHER" then
		patternInfo = { "heal", ParserLib_SELF, 2, 1, 3, true, nil, }
	elseif patternName == "HEALEDCRITSELFSELF" then
		patternInfo = { "heal", ParserLib_SELF, ParserLib_SELF, 1, 2, true, nil, }
	elseif patternName == "HEALEDOTHEROTHER" then
		patternInfo = { "heal", 1, 3, 2, 4, nil, nil, }
	elseif patternName == "HEALEDOTHERSELF" then
		patternInfo = { "heal", 1, ParserLib_SELF, 2, 3, nil, nil, }
	elseif patternName == "HEALEDSELFOTHER" then
		patternInfo = { "heal", ParserLib_SELF, 2, 1, 3, nil, nil, }
	elseif patternName == "HEALEDSELFSELF" then
		patternInfo = { "heal", ParserLib_SELF, ParserLib_SELF, 1, 2, nil, nil, }
	elseif patternName == "PERIODICAURAHEALOTHEROTHER" then
		patternInfo = { "heal", 3, 1, 4, 2, nil, true, }
	elseif patternName == "PERIODICAURAHEALOTHERSELF" then
		patternInfo = { "heal", 2, ParserLib_SELF, 3, 1, nil, true, }
	elseif patternName == "PERIODICAURAHEALSELFOTHER" then
		patternInfo = { "heal", ParserLib_SELF, 1, 3, 2, nil, true, }
	elseif patternName == "PERIODICAURAHEALSELFSELF" then
		patternInfo = { "heal", ParserLib_SELF, ParserLib_SELF, 2, 1, nil, true, }
	-- WoW2.0 new patterns - more info needed.
	--[[
	HEALEDCRITOTHER = "%s critically heals %s for %d."
	HEALEDCRITSELF = "%s critically heals you for %d."
	HEALEDOTHER = "%s heals %s for %d."
	HEALEDSELF = "%s's %s heals you for %d."
	PERIODICAURAHEALOTHER = "%s gains %d health from %s."
	PERIODICAURAHEALSELF = "You gain %d health from %s."
	]]

	-- hit = { "source", "victim", "skill", "amount", "element", "isCrit", "isDOT", "isSplit" },
	elseif patternName == "COMBATHITCRITOTHEROTHER" then
		patternInfo = { "hit", 1, 2, ParserLib_MELEE, 3, nil, true, nil, nil, }
	elseif patternName == "COMBATHITCRITOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, ParserLib_MELEE, 2, nil, true, nil, nil, }
	elseif patternName == "COMBATHITCRITSCHOOLOTHEROTHER" then
		patternInfo = { "hit", 1, 2, ParserLib_MELEE, 3, 4, true, nil, nil, }
	elseif patternName == "COMBATHITCRITSCHOOLOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, ParserLib_MELEE, 2, 3, true, nil, nil, }
	elseif patternName == "COMBATHITCRITSCHOOLSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 1, ParserLib_MELEE, 2, 3, true, nil, nil, }
	elseif patternName == "COMBATHITCRITSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 1, ParserLib_MELEE, 2, nil, true, nil, nil, }
	elseif patternName == "COMBATHITOTHEROTHER" then
		patternInfo = { "hit", 1, 2, ParserLib_MELEE, 3, nil, nil, nil, nil, }
	elseif patternName == "COMBATHITOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, ParserLib_MELEE, 2, nil, nil, nil, nil, }
	elseif patternName == "COMBATHITSCHOOLOTHEROTHER" then
		patternInfo = { "hit", 1, 2, ParserLib_MELEE, 3, 4, nil, nil, nil, }
	elseif patternName == "COMBATHITSCHOOLOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, ParserLib_MELEE, 2, 3, nil, nil, nil, }
	elseif patternName == "COMBATHITSCHOOLSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 1, ParserLib_MELEE, 2, 3, nil, nil, nil, }
	elseif patternName == "COMBATHITSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 1, ParserLib_MELEE, 2, nil, nil, nil, nil, }
	elseif patternName == "DAMAGESHIELDOTHEROTHER" then
		patternInfo = { "hit", 1, 4, ParserLib_DAMAGESHIELD, 2, 3, nil, nil, nil, }
	elseif patternName == "DAMAGESHIELDOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, ParserLib_DAMAGESHIELD, 2, 3, nil, nil, nil, }
	elseif patternName == "DAMAGESHIELDSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 3, ParserLib_DAMAGESHIELD, 1, 2, nil, nil, nil, }
	elseif patternName == "PERIODICAURADAMAGEOTHEROTHER" then
		patternInfo = { "hit", 4, 1, 5, 2, 3, nil, true, nil, }
	elseif patternName == "PERIODICAURADAMAGEOTHERSELF" then
		patternInfo = { "hit", 3, ParserLib_SELF, 4, 1, 2, nil, true, nil, }
	elseif patternName == "PERIODICAURADAMAGESELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 1, 4, 2, 3, nil, true, nil, }
	elseif patternName == "PERIODICAURADAMAGESELFSELF" then
		patternInfo = { "hit", ParserLib_SELF, ParserLib_SELF, 3, 1, 2, nil, true, nil, }
	elseif patternName == "SPELLLOGCRITOTHEROTHER" then
		patternInfo = { "hit", 1, 3, 2, 4, nil, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, 2, 3, nil, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITSCHOOLOTHEROTHER" then
		patternInfo = { "hit", 1, 3, 2, 4, 5, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITSCHOOLOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, 2, 3, 4, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITSCHOOLSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 2, 1, 3, 4, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITSCHOOLSELFSELF" then
		patternInfo = { "hit", ParserLib_SELF, ParserLib_SELF, 1, 2, 3, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 2, 1, 3, nil, true, nil, nil, }
	elseif patternName == "SPELLLOGCRITSELFSELF" then
		patternInfo = { "hit", ParserLib_SELF, ParserLib_SELF, 1, 2, nil, true, nil, nil, }
	elseif patternName == "SPELLLOGOTHEROTHER" then
		patternInfo = { "hit", 1, 3, 2, 4, nil, nil, nil, nil, }
	elseif patternName == "SPELLLOGOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, 2, 3, nil, nil, nil, nil, }
	elseif patternName == "SPELLLOGSCHOOLOTHEROTHER" then
		patternInfo = { "hit", 1, 3, 2, 4, 5, nil, nil, nil, }
	elseif patternName == "SPELLLOGSCHOOLOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, 2, 3, 4, nil, nil, nil, }
	elseif patternName == "SPELLLOGSCHOOLSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 2, 1, 3, 4, nil, nil, nil, }
	elseif patternName == "SPELLLOGSCHOOLSELFSELF" then
		patternInfo = { "hit", ParserLib_SELF, ParserLib_SELF, 1, 2, 3, nil, nil, nil, }
	elseif patternName == "SPELLLOGSELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 2, 1, 3, nil, nil, nil, nil, }
	elseif patternName == "SPELLLOGSELFSELF" then
		patternInfo = { "hit", ParserLib_SELF, ParserLib_SELF, 1, 2, nil, nil, nil, nil, }
	elseif patternName == "SPELLSPLITDAMAGEOTHEROTHER" then
		patternInfo = { "hit", 1, 3, 2, 4, nil, nil, nil, true, }
	elseif patternName == "SPELLSPLITDAMAGEOTHERSELF" then
		patternInfo = { "hit", 1, ParserLib_SELF, 2, 3, nil, nil, nil, true, }
	elseif patternName == "SPELLSPLITDAMAGESELFOTHER" then
		patternInfo = { "hit", ParserLib_SELF, 2, 1, 3, nil, nil, nil, true, }
	-- WoW2.0 new patterns.
	elseif patternName == "PERIODICAURADAMAGEOTHER" then -- "%s suffers %d %s damage from %s."
		patternInfo = { "hit", 1, 1, 4, 2, 3, nil, true, nil, }
	elseif patternName == "PERIODICAURADAMAGESELF" then -- "You suffer %d %s damage from %s."
		patternInfo = { "hit", ParserLib_SELF, ParserLib_SELF, 3, 1, 2, nil, true, nil, }
	-- WoW2.0 new patterns : more info needed.
	--[[
		SPELLLOGCRITSCHOOLOTHER = "%s crits %s for %d %s damage."
		SPELLLOGCRITSCHOOLSELF = "%s crits you for %d %s damage."
		SPELLLOGCRITSELF = "%s crits you for %d."
		SPELLLOGOTHER = "%s hits %s for %d."
		SPELLLOGSCHOOLOTHER = "%s hits %s for %d %s damage."
		SPELLLOGSCHOOLSELF = "%s hits you for %d %s damage."
		SPELLLOGSELF = "%s hits you for %d."
	]]

	-- honor = { "amount", "source", "sourceRank" }, -- if amount == nil then isDishonor = true.
	elseif patternName == "COMBATLOG_DISHONORGAIN" then
		patternInfo = { "honor", nil, 1, nil, }
	elseif patternName == "COMBATLOG_HONORAWARD" then
		patternInfo = { "honor", 1, nil, nil, }
	elseif patternName == "COMBATLOG_HONORGAIN" then
		patternInfo = { "honor", 3, 1, 2, }

	-- interrupt = { "source", "victim", "skill" },
	elseif patternName == "SPELLINTERRUPTOTHEROTHER" then
		patternInfo = { "interrupt", 1, 2, 3, }
	elseif patternName == "SPELLINTERRUPTOTHERSELF" then
		patternInfo = { "interrupt", 1, ParserLib_SELF, 2, }
	elseif patternName == "SPELLINTERRUPTSELFOTHER" then
		patternInfo = { "interrupt", ParserLib_SELF, 1, 2, }

	-- leech = { "source", "victim", "skill", "amount", "attribute", "sourceGained", "amountGained", "attributeGained" },
	elseif patternName == "SPELLPOWERLEECHOTHEROTHER" then
		patternInfo = { "leech", 1, 5, 2, 3, 4, 6, 7, 8, }
	elseif patternName == "SPELLPOWERLEECHOTHERSELF" then
		patternInfo = { "leech", 1, ParserLib_SELF, 2, 3, 4, 5, 6, 7, }
	elseif patternName == "SPELLPOWERLEECHSELFOTHER" then
		patternInfo = { "leech", ParserLib_SELF, 4, 1, 2, 3, ParserLib_SELF, 5, 6, }

	-- miss = { "source", "victim", "skill", "missType" },
	elseif patternName == "IMMUNEDAMAGECLASSOTHEROTHER" then
		patternInfo = { "miss", 2, 1, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNEDAMAGECLASSOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNEDAMAGECLASSSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNEOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNEOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNESELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNESELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, ParserLib_MELEE, "immune", }
	elseif patternName == "IMMUNESPELLOTHEROTHER" then
		patternInfo = { "miss", 2, 1, 3, "immune", }
	elseif patternName == "IMMUNESPELLOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "immune", }
	elseif patternName == "IMMUNESPELLSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, 2, "immune", }
	elseif patternName == "IMMUNESPELLSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "immune", }
	elseif patternName == "MISSEDOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "miss", }
	elseif patternName == "MISSEDOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "miss", }
	elseif patternName == "MISSEDSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "miss", }
	elseif patternName == "PROCRESISTOTHEROTHER" then
		patternInfo = { "miss", 2, 1, 3, "resist", }
	elseif patternName == "PROCRESISTOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "resist", }
	elseif patternName == "PROCRESISTSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, 2, "resist", }
	elseif patternName == "PROCRESISTSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "resist", }
	elseif patternName == "SPELLBLOCKEDOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "block", }
	elseif patternName == "SPELLBLOCKEDOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "block", }
	elseif patternName == "SPELLBLOCKEDSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "block", }
	elseif patternName == "SPELLDEFLECTEDOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "deflect", }
	elseif patternName == "SPELLDEFLECTEDOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "deflect", }
	elseif patternName == "SPELLDEFLECTEDSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "deflect", }
	elseif patternName == "SPELLDEFLECTEDSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "deflect", }
	elseif patternName == "SPELLDODGEDOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "dodge", }
	elseif patternName == "SPELLDODGEDOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "dodge", }
	elseif patternName == "SPELLDODGEDSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "dodge", }
	elseif patternName == "SPELLDODGEDSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "dodge", }
	elseif patternName == "SPELLEVADEDOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "evade", }
	elseif patternName == "SPELLEVADEDOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "evade", }
	elseif patternName == "SPELLEVADEDSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "evade", }
	elseif patternName == "SPELLEVADEDSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "evade", }
	elseif patternName == "SPELLIMMUNEOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "immune", }
	elseif patternName == "SPELLIMMUNEOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "immune", }
	elseif patternName == "SPELLIMMUNESELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "immune", }
	elseif patternName == "SPELLIMMUNESELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "immune", }
	elseif patternName == "SPELLLOGABSORBOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "absorb", }
	elseif patternName == "SPELLLOGABSORBOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "absorb", }
	elseif patternName == "SPELLLOGABSORBSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "absorb", }
	elseif patternName == "SPELLLOGABSORBSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "absorb", }
	elseif patternName == "SPELLMISSOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "miss", }
	elseif patternName == "SPELLMISSOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "miss", }
	elseif patternName == "SPELLMISSSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "miss", }
	elseif patternName == "SPELLMISSSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "miss", }
	elseif patternName == "SPELLPARRIEDOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "parry", }
	elseif patternName == "SPELLPARRIEDOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "parry", }
	elseif patternName == "SPELLPARRIEDSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "parry", }
	elseif patternName == "SPELLPARRIEDSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "parry", }
	elseif patternName == "SPELLREFLECTOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "reflect", }
	elseif patternName == "SPELLREFLECTOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "reflect", }
	elseif patternName == "SPELLREFLECTSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "reflect", }
	elseif patternName == "SPELLREFLECTSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "reflect", }
	elseif patternName == "SPELLRESISTOTHEROTHER" then
		patternInfo = { "miss", 1, 3, 2, "resist", }
	elseif patternName == "SPELLRESISTOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, 2, "resist", }
	elseif patternName == "SPELLRESISTSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 2, 1, "resist", }
	elseif patternName == "SPELLRESISTSELFSELF" then
		patternInfo = { "miss", ParserLib_SELF, ParserLib_SELF, 1, "resist", }
	elseif patternName == "VSABSORBOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "absorb", }
	elseif patternName == "VSABSORBOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "absorb", }
	elseif patternName == "VSABSORBSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "absorb", }
	elseif patternName == "VSBLOCKOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "block", }
	elseif patternName == "VSBLOCKOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "block", }
	elseif patternName == "VSBLOCKSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "block", }
	elseif patternName == "VSDEFLECTOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "deflect", }
	elseif patternName == "VSDEFLECTOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "deflect", }
	elseif patternName == "VSDEFLECTSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "deflect", }
	elseif patternName == "VSDODGEOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "dodge", }
	elseif patternName == "VSDODGEOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "dodge", }
	elseif patternName == "VSDODGESELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "dodge", }
	elseif patternName == "VSEVADEOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "evade", }
	elseif patternName == "VSEVADEOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "evade", }
	elseif patternName == "VSEVADESELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "evade", }
	elseif patternName == "VSIMMUNEOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "immune", }
	elseif patternName == "VSIMMUNEOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "immune", }
	elseif patternName == "VSIMMUNESELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "immune", }
	elseif patternName == "VSPARRYOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "parry", }
	elseif patternName == "VSPARRYOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "parry", }
	elseif patternName == "VSPARRYSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "parry", }
	elseif patternName == "VSRESISTOTHEROTHER" then
		patternInfo = { "miss", 1, 2, ParserLib_MELEE, "resist", }
	elseif patternName == "VSRESISTOTHERSELF" then
		patternInfo = { "miss", 1, ParserLib_SELF, ParserLib_MELEE, "resist", }
	elseif patternName == "VSRESISTSELFOTHER" then
		patternInfo = { "miss", ParserLib_SELF, 1, ParserLib_MELEE, "resist", }
	-- WoW2.0 new patterns : more info needed.
	--[[
		IMMUNESPELLOTHER = "%s is immune to %s."
		IMMUNESPELLSELF = "You are immune to %s."
		SPELLIMMUNEOTHER = "%s fails. %s is immune."
		SPELLIMMUNESELF = "%s failed. You are immune."
		SPELLLOGABSORBOTHER = "%s is absorbed by %s."
		SPELLLOGABSORBSELF = "You absorb %s."
		SPELLRESISTOTHER = "%s was resisted by %s."
		SPELLRESISTSELF = "%s was resisted."
	]]

	-- reputation = { "faction", "amount", "rank", "isNegative" },
	elseif patternName == "FACTION_STANDING_CHANGED" then
		patternInfo = { "reputation", 2, nil, 1, nil, }
	elseif patternName == "FACTION_STANDING_DECREASED" then
		patternInfo = { "reputation", 1, 2, nil, true, }
	elseif patternName == "FACTION_STANDING_INCREASED" then
		patternInfo = { "reputation", 1, 2, nil, nil, }
	end

	if not patternInfo then
		-- self:Print("LoadPatternInfo(): Cannot find " .. patternName ) -- debug
		return
	end

	-- Get the pattern from GlobalStrings.lua
	local pattern = _G[patternName]

	-- How many regexp tokens in this pattern?
	local tc = 0
	for _ in string.gfind(pattern,"%%%d?%$?([sd])") do tc = tc + 1 end

	-- Convert string.format tokens into LUA regexp tokens.
	pattern = { self:ConvertPattern(pattern, true) }

	local n = table.getn(pattern)
	if n > 1 then	-- Extra return values are the remapped token sequences.

		for j in pairs(patternInfo) do
			if type(patternInfo[j]) == "number" and patternInfo[j] < 100 then
				patternInfo[j] = pattern[patternInfo[j]+1]	-- Remap to correct token sequence.
			end
		end

	end

	patternInfo.tc = tc
	patternInfo.pattern = pattern[1]

	return patternInfo
end

-- Fields of the patternTable.
local infoMap = {
	hit = { "source", "victim", "skill", "amount", "element", "isCrit", "isDOT", "isSplit" },
	heal = { "source", "victim", "skill", "amount", "isCrit", "isDOT" },
	miss = { "source", "victim", "skill", "missType" },
	death = { "victim", "source", "skill", "isItem" },
	debuff = { "victim", "skill", "amountRank" },
	buff = { "victim", "skill", "amountRank" },
	fade = { "victim", "skill" },
	cast = { "source", "skill", "victim", "isBegin", "isPerform" },
	gain = { "source", "victim", "skill", "amount", "attribute" },
	drain = { "source", "victim", "skill", "amount", "attribute" },
	leech = { "source", "victim", "skill", "amount", "attribute", "sourceGained", "amountGained", "attributeGained" },
	dispel = { "victim", "skill", "source", "isFailed" },
	extraattack = { "victim", "skill", "amount" },
	environment = { "victim", "amount", "damageType" },
	experience = { "amount", "source", "bonusAmount", "bonusType", "penaltyAmount", "penaltyType", "amountRaidPenalty", "amountGroupBonus", "victim" },
	reputation = { "faction", "amount", "rank", "isNegative" },
	feedpet = { "victim", "item" },
	enchant = { "source", "victim", "skill", "item" },
	fail = { "source", "skill", "reason" },
	interrupt = { "source", "victim", "skill" },
	create = { "source", "item" },
	honor = { "amount", "source", "sourceRank" }, -- if amount == nil then isDishonor = true.
	durability = { "source", "skill", "victim", "item" }, -- is not item then isAllItems = true
	unknown = { "message" },
}

function lib:GetInfoFieldName(infoType, fieldIndex)
	if infoMap[infoType] then
		return infoMap[infoType][fieldIndex-1]	-- Skip the first field in patternTable which is 'type'.
	end
end

--------------------------------
--      Load this bitch!      --
--------------------------------
libobj:Register(lib)

