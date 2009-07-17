local addon = CreateFrame("Frame")
addon:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
local timer = 0
local OnUpdate = function(self, elapsed)
	timer = timer + elapsed

	if timer > 1 then
		for name, display in pairs(self.displays) do
			if display.dirty and display.isActive then
				display:UpdateDisplay()
			end
		end
		timer = 0
	end
end
addon:Show()

local band = bit.band
local filter = COMBATLOG_OBJECT_AFFILIATION_RAID + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_MINE

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
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background.tga]], tile = true, tileSize = 16,
		edgeFile = [[Interface\AddOns\Fiend\media\otravi-semi-full-border.tga]], edgeSize = 32,
		insets = {left = 0, right = 0, top = 20, bottom = 0},
	})

	frame:SetBackdropColor(0, 0, 0, 0.8)
	frame:SetBackdropBorderColor(0.3, 0.3, 0.3)

	self.frame = frame

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFont(STANDARD_TEXT_FONT, 16)
	title:SetText("Fiend")
	title:SetJustifyH("CENTER")
	title:SetPoint("CENTER")
	title:SetPoint("TOP", 0, - 12)
	frame.title = title

	self.displays = {}
	self.displayCount = 0

	local damage = self.Display("Damage", 16)
	damage:Activate()

	--self.Display("Healing", 18)

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:SetScript("OnUpdate", OnUpdate)

	self.ADDON_LOADED = nil
end

local spellId, spellName, spellSchool, ammount, over, school, resist
function addon:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if not events[event] then return end

	if band(sourceFlags, filter) == 0 then
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

		if display then
			display:Update(sourceName, damage)
		end
	end
end

_G.Fiend = addon
