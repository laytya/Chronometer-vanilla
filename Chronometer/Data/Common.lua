--<< ====================================================================== >>--
-- Setup Timers                                                               --
--<< ====================================================================== >>--
local BS = AceLibrary("Babble-Spell-2.2")

function Chronometer:CommonSetup()

	local _, eclass = UnitClass("player")
	
	if eclass == "PALADIN" or eclass == "WARRIOR" or eclass == "ROGUE" or eclass == "SHAMAN" then
	
		-- crusader enchant proc http://classicdb.ch/?item=16252
		self:AddTimer(self.EVENT, BS["Holy Strength"],         	15, 0,1,1, { cr="YELLOW", a=1 , cl="COMMON" })
		
	end
	-- zg casteer trinket http://classicdb.ch/?item=19950
	self:AddTimer(self.EVENT, BS["Unstable Power"],          	20, 0, 1, 1, { a=1, cr="CYAN", cl="COMMON" })
	self:AddTimer(self.EVENT, BS["Ephemeral Power"],          	15, 0, 1, 1, { a=1, cr="CYAN", cl="COMMON" })
	self:AddTimer(self.EVENT, "Mind Quickening",          		20, 0, 1, 1, { a=1, cr="CYAN", cl="COMMON",xn=BS["Critical Mass"]})
end

table.insert(Chronometer.dataSetup, Chronometer.CommonSetup)
