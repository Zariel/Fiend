local addon = CreateFrame("Frame")
addon:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
addon:RegisterEvent("ADDON_LOADED")

local UnitAffectingCombat = UnitAffectingCombat
local UnitInVehicle = UnitInVehicle
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName

local timer = 0
local OnUpdate = function(self, elapsed)
	timer = timer + elapsed

	if timer > 0.5 then
		for i, d in pairs(self.displays) do
			d:OnUpdate(timer)
		end

		timer = 0
	end
end

local ldb
local band = bit.band
local filter = COMBATLOG_OBJECT_AFFILIATION_RAID + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_MINE

local events = {
	["SWING_DAMAGE"] = "Damage",
	["RANGE_DAMAGE"] = "Damage",
	["SPELL_DAMAGE"] = "Damage",
	["SPELL_PERIODIC_DAMAGE"] = "Damage",

	["SPELL_HEAL"] = "Healing",
	["SPELL_PERIDOIC_HEAL"] = "Healing",

	["SPELL_SUMMON"] = true,
}

function addon:ADDON_LOADED(name)
	if name ~= "Fiend" then return end

	self:UnregisterEvent("ADDON_LOADED")

	self.displays = {}

	self.combatTime = {}
	self.inCombat = {}

	self.printNum = 10

	self:CreateDropDown()

        local win = self:NewDisplay("main")
        local damage = win:NewView("Damage", {
		"SWING_DAMAGE",
		"RANGE_DAMAGE",
		"SPELL_DAMAGE",
		"SPELL_PERIODIC_DAMAGE",
	}, 16, { 0.6, 0.2, 0.2 })

	damage:Activate()

        --[[
	self.Display("Healing", 16, { 0.2, 0.6, 0.2 }, "hps")
	self.Display("OverHealing", 16, { 0.2, 0.6, 0.5 }, "hps")
]]
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self:Show()

	ldb = LibStub("LibDataBroker-1.1", true)
	if ldb then
		local obj = ldb:NewDataObject("Fiend", {
			type = "launcher",
			icon = [[Interface\Icons\Ability_BullRush]],
			OnClick = function(self, button)
				if button == "RightButton" then
					ToggleDropDownMenu(1, nil, addon.dropDown, "cursor")
				else
					if addon.frame:IsShown() then
						addon.frame:Hide()
					else
						addon.frame:Show()
					end
				end
			end,
		})

		self.dataObj = obj
	end

	self:SetScript("OnUpdate", OnUpdate)

	self.ADDON_LOADED = nil
end

local spellId, spellName, spellSchool, ammount, over, school, resist
function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if not events[event] or not band(sourceFlags, filter) then return end

	if event == "SWING_DAMAGE" then
		ammount, over, school, resist = ...
	elseif event == "SPELL_SUMMON" then
		-- This is to get summoned pets like totems etc
		return self:AddPet(destGUID, sourceGUID)
	else
		spellId, spellName, spellSchool, ammount, over, school, resist = ...
	end

	-- Bail, ususaly because the unit is in a vehicle and we dont have its
	-- GUID mapping
	if not self:GetUnit(sourceGUID) then return end

	ammount = ammount or 0
	resist = resist or 0
	over = over or 0

	-- Track over kill ?
	local damage = ammount - (over + resist)

        local overHeal
	if (event == "SPELL_HEAL" or event == "SPELL_PERIDOIC_HEAL") and over > 0 then
                overHeal = over
	end

	if damage > 0 or overHeal then
		local pet = self:IsPet(sourceGUID)

		if pet then
			sourceGUID = pet
			sourceName = UnitName(self:GetUnit(pet))
		end

                for name, display in pairs(self.displays) do
			display:CombatEvent(event, sourceGUID, damage, sourceName, overHeal)
		end
	end
end

function addon:CreateDropDown()

end

_G.Fiend = addon
