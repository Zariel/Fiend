local addon = CreateFrame("Frame")
addon:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

addon:RegisterEvent("ADDON_LOADED")

local events = {
	["SWING_DAMAGE"] = 1,
	["RANGE_DAMAGE"] = 2,
	["SPELL_DAMAGE"] = 4,
	["SPELL_PERIODIC_DAMAGE"] = 8,
	["SPELL_HEAL"] = 16,
	["SPELL_PERIDOIC_HEAL"] = 32,
}

local displays = {
	[15] = "damage",
	[48] = "healing",
}

function addon:ADDON_LOADED(name)
	if name ~= "Fiend" then return end

	self:UnregisterEvent("ADDON_LOADED")

	local frame = CreateFrame("Frame", "FiendDamage", UIParent)
	frame:SetHeight(250)
	frame:SetWidth(300)
	frame:SetPoint("CENTER")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:SetClampedToScreen(true)
	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
		end
	end)

	frame:SetScript("OnMouseDown", function(self, button)
		if IsModifiedClick("ALT") and button == "LeftButton" then
			self:StartMoving()
		end
	end)

	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		--edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
		insets = {left = -1, right = -1, top = -1, bottom = -1},
	})

	frame:SetBackdropColor(0, 0, 0, 0.8)

	self.frame = frame

	self.displays = {}

	self.Display("Damage", 16)
	self.Display("Healing", 16)

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self.ADDON_LOADED = nil
end

local spellId, spellName, spellSchool, ammount, over, school, resist
function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if not events[event] then return end

	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= COMBATLOG_OBJECT_AFFILIATION_MINE or
	bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) ~= COMBATLOG_OBJECT_AFFILIATION_RAID then
		return
	end


	if event == "SWING_DAMAGE" then
		ammount, over, school, resist = ...
	else
		spellId, spellName, spellSchool, ammount, over, school, resist = ...
	end

	ammount = ammount or 0
	resist = resist or 0
	over = over or 0

	local damage = ammount - (over + resist)

	if damage > 0 then
		local display
		if events[event] > 8 then
			display = self.displays.Healing
		else
			display = self.displays.Damage
		end

		display:Update(sourceName, damage)
	end
end

_G.Fiend = addon
