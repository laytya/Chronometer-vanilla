--<< ====================================================================== >>--
-- Setup Timers                                                               --
--<< ====================================================================== >>--
local BS = AceLibrary("Babble-Spell-2.2")
local BR = AceLibrary("Babble-Race-2.2")

function Chronometer:RacialSetup()

	local lr, race = UnitRace("player")
	
	if race == "Dwarf" then
		self:AddTimer(self.SPELL, BS["Stoneform"],              8, 0,1,1, { cl="RACIAL" })
	elseif race == "Human" then
		self:AddTimer(self.SPELL, BS["Perception"],             20, 0,1,1, { cl="RACIAL" })
	elseif race == "Orc" then
		self:AddTimer(self.SPELL, BS["Blood Fury"],             15, 0,1,1, { cl="RACIAL" })
	elseif race == "Tauren" then
		self:AddTimer(self.SPELL, BS["War Stomp"],              2, 0,0,0, { cl="RACIAL" })
	elseif race == "Troll" then
		self:AddTimer(self.SPELL, BS["Berserking"],             10, 0,1,1, { cl="RACIAL" })
	elseif race == "Undead" then
		self:AddTimer(self.SPELL, BS["Will of the Forsaken"],   5, 0,1,1, { cl="RACIAL" })
	end

end

table.insert(Chronometer.dataSetup, Chronometer.RacialSetup)
