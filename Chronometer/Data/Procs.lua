--<< ====================================================================== >>--
-- Setup Timers                                                               --
--<< ====================================================================== >>--
local BS = AceLibrary("Babble-Spell-2.2")

function Chronometer:ProcsSetup()

	local _, eclass = UnitClass("player")
	
	if eclass == "PALADIN" or eclass == "WARRIOR" or eclass == "ROGUE" or eclass == "SHAMAN" then
		
		self:AddTimer(self.EVENT, BS["Holy Strength"],             15, 0,1,1, { cr="YELLOW", a=1 })
		
	end
	
end

table.insert(Chronometer.dataSetup, Chronometer.ProcsSetup)
