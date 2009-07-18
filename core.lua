local addon = CreateFrame("Frame")
addon:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
addon:RegisterEvent("ADDON_LOADED")

local timer = 0
local OnUpdate = function(self, elapsed)
	timer = timer + elapsed

	if timer > 0.5 then
		if self.currentDisplay and self.currentDisplay.dirty then
			self.currentDisplay:UpdateDisplay()
		end
		timer = 0
	end
end

addon:Show()

local pets = {}

local ldb
local band = bit.band
local filter = COMBATLOG_OBJECT_AFFILIATION_RAID + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_MINE

local combatStart = {}
local combatEnd = {}

local events = {
	["SWING_DAMAGE"] = 1,
	["RANGE_DAMAGE"] = 2,
	["SPELL_DAMAGE"] = 4,
	["SPELL_PERIODIC_DAMAGE"] = 8,
	["SPELL_HEAL"] = 16,
	["SPELL_PERIDOIC_HEAL"] = 32,
	["SPELL_SUMMON"] = 64,
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
	--frame:SetHitRectInsets(

	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
		end
	end)

	frame:SetScript("OnMouseDown", function(self, button)
		if IsModifiedClick("ALT") and button == "LeftButton" then
			self:StartMoving()
		elseif button == "RightButton" then
			ToggleDropDownMenu(1, nil, addon.dropDown)
		end
	end)

	frame:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background.tga]], tile = true, tileSize = 16,
		edgeFile = [[Interface\AddOns\Fiend\media\otravi-semi-full-border.tga]], edgeSize = 32,
		insets = {left = 0, right = 0, top = 20, bottom = 0},
	})

	frame:SetBackdropColor(0, 0, 0, 0.8)

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
	self.combatTime = 0

	local damage = self.Display("Damage", 16, { 0.6, 0.2, 0.2 })
	damage:Activate()

	--self.Display("Healing", 18)

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("RAID_MEMBERS_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_UPDATE")
	self.UNIT_PET = self.RAID_MEMBERS_UPDATE
	self.PARTY_MEMBERS_UPDATE = self.RAID_MEMBERS_UPDATE
	self:RegisterEvent("UNIT_PET")

	self:SetScript("OnUpdate", OnUpdate)

	self:CreateDropDown()

	self:RAID_MEMBERS_UPDATE()

	ldb = LibStub("LibDataBroker-1.1", true)
	if ldb then
	end

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
	elseif event == "SPELL_SUMMON" then
		-- This is to get summoned pets like totems etc
		pets[destGUID] = sourceName
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

			--[[
			if UnitIsEffectingCombat(sourceName) then
				combatStart[sourceName] = combatStart[sourceName] or GetTime()
			elseif combatStart[sourceName] then
				combatEnd[sourceName] = GetTime()
			end
			]]
		else
			display = self.displays.Damage
		end

		if pets[sourceGUID] then
			sourceName = pets[sourceGUID]
		end

		if display then
			display:Update(sourceName, damage)
		end
	end
end

-- Just update pet roster
function addon:RAID_MEMBERS_UPDATE()
	local unit, punit

	for k, v in pairs(pets) do pets[k] = nil end

	if UnitInRaid("player") then
		for i = 1, GetNumRaidMembers() do
			unit = "raid" .. i
			punit = "raid" .. i .. "pet"
			if UnitExists(punit) and not UnitInVehicle(unit) then
				pets[UnitGUID(punit)] = UnitName(unit)
			end
		end
	else
		for i = 1, 4 do
			unit = "party" .. i
			punit = unit .. "pet"
			if UnitExists(punit) and not UnitInVehicle(unit) then
				pets[UnitGUID(punit)] = UnitName(unit)
			end
		end
	end

	if UnitExists("playerpet") then
		pets[UnitGUID("playerpet")] = UnitName("player")
	end
end

function addon:isInCombat(name)
end

function addon:CreateDropDown()
	local drop = CreateFrame("Frame", "FiendDropDown", UIParent, "UIDropDownMenuTemplate")

	-- </3
	local menu = {
		{
			{
				text = "Fiend",
				value = 0,
				owner = drop,
				isTitle = true,
			}, {
				text = "Reset",
				value = 1,
				owner = drop,
				func = function()
					if addon.currentDisplay then
						addon.currentDisplay:RemoveAllBars()
					end
				end,
			}, {
				text = "Output",
				value = 2,
				owner = drop,
				hasArrow = true,
				menuList = {
					{
						text = "Count",
						owner = drop,
						hasArrow = true,
						menuList = {
						}
					}, {
						text = "Guild",
						owner = drop,
						func = function()
							if addon.currentDisplay then
								-- Later make this have a count
								addon.currentDisplay:Output(addon.printNum "GUILD")
							end
						end,
					}, {
						text = "Print",
						value = 0,
						owner = drop,
						func = function()
							if addon.currentDisplay then
								addon.currentDisplay:Output(addon.printNum)
							end
						end
					},
				},
			}
		},
	}

	local count = 0
	for i = 0, 26, 5 do
		count = count + 1
		if i == 0 then i = nil end

		menu[1][3].menuList[1].menuList[count] = {
			text = i or "All",
			value = count,
			func = function()
				addon.printNum = i
				print("Set the output limit to " .. i)
			end
		}
	end

	UIDropDownMenu_Initialize(drop, function(self, level, menuList)
		if not (menuList or menu[level]) then return end
		for k, v in ipairs(menuList or menu[level]) do
			v.value = k
			UIDropDownMenu_AddButton(v, level)
		end
	end, "MENU", 1)

	self.dropDown = drop

	return drop
end

_G.Fiend = addon
