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
		if self.currentDisplay and self.currentDisplay.dirty then
			self.currentDisplay:UpdateDisplay()
		end

		-- Dont throttle this ?
		for unit, guid in self:IterateUnitRoster() do
			if UnitAffectingCombat(unit) then
				self.inCombat[guid] = true
				self.combatTime[guid] = (self.combatTime[guid] or 0) + timer
			elseif self.inCombat[guid] then
				self.inCombat[guid] = false
			end
		end

		if self.currentDisplay.tip then
			self.OnEnter(GameTooltip:GetOwner())
		end

		timer = 0
	end
end

addon:Show()

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
			if IsModifiedClick("SHIFT") then
				self.currentDisplay:RemoveAllBars()
			else
				ToggleDropDownMenu(1, nil, addon.dropDown, self)
			end
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

	self.combatTime = {}
	self.inCombat = {}

	self.printNum = nil

	local damage = self.Display("Damage", 16, { 0.6, 0.2, 0.2 })
	damage:Activate()

	--self.Display("Healing", 18)

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self:SetScript("OnUpdate", OnUpdate)

	self:CreateDropDown()

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

	local damage = ammount - (over + resist)

	if damage > 0 then
		local display = self.displays[events[event]]
		if display then

			local pet = self:IsPet(sourceGUID)
			if pet then
				sourceGUID = pet
			end

			display:Update(sourceGUID, damage)
		end
	end
end

function addon:CHAT_MSG_ADDON(prefix, msg, chan, from)
	if not prefix:match("Fiend") then return end

	local guid, time = msg:split(";")
	self.sync[guid] = true

	if prefix == "FiendCombatStart" then
		self.combatStart[guid] = tonumber(time)
	elseif prefix == "FiendCombatStop" then
		self.combatStop[guid] = tonumber(time)
	elseif prefix == "FiendCombatSync" then
	end
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
								addon.currentDisplay:Output(addon.printNum, "GUILD")
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

		local disabled = self.printNum == i
		menu[1][3].menuList[1].menuList[count] = {
			text = i or "All",
			value = count,
			func = function()
				addon.printNum = i
				print("Set the output limit to " .. i or "All")
			end,
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
