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
				self.combatTime[guid] = (self.combatTime[guid] or 0) + timer
			end
		end

		if self.currentDisplay and self.currentDisplay.tip then
			self.OnEnter(GameTooltip:GetOwner())
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

        local win = self:NewDisplay(title)
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

	self:SetScript("OnUpdate", OnUpdate)
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
	local drop = CreateFrame("Frame", "FiendDropDown", UIParent, "UIDropDownMenuTemplate")

	-- </3
	self.menu = {
		{
			{
				text = "Fiend",
				owner = drop,
				isTitle = true,
			}, {
				text = "Reset",
				owner = drop,
				func = function()
					if addon.currentDisplay then
						addon.currentDisplay:RemoveAllBars()
					end
				end,
			}, {
				text = "Windows",
				owner = drop,
				hasArrow = true,
				menuList = {
				},
			}, {
				text = "Output",
				owner = drop,
				hasArrow = true,
				menuList = {
					{
						text = "Guild",
						owner = drop,
						func = function()
							if addon.currentDisplay then
								-- Later make this have a count
								addon.currentDisplay:Output(addon.printNum, "GUILD")
							end
						end,
					}, {
						text = "Party",
						owner = drop,
						func = function()
							if addon.currentDisplay then
								addon.currentDisplay:Output(addon.printNum, "PARTY")
							end
						end,
					}, {
						text = "Say",
						owner = drop,
						func = function()
							if addon.currentDisplay then
								addon.currentDisplay:Output(addon.printNum, "SAY")
							end
						end
					}, {
						text = "Whisper",
						owner = drop,
						func = function()
						end,
					}, {
						text = "Print",
						owner = drop,
						func = function()
							if addon.currentDisplay then
								addon.currentDisplay:Output(addon.printNum)
							end
						end
					}, {
						text = "Count",
						owner = drop,
						hasArrow = true,
						menuList = {
						},
					},
				},
			}, {
				text = "hide",
				owner = drop,
				func = function()
					addon.frame:Hide()
				end,
			}
		},
	}

	local count = 0
	for i = 5, 26, 5 do
		count = count + 1

		self.menu[1][4].menuList[6].menuList[count] = {
			text = i or "All",
			value = count,
			func = function()
				addon.printNum = i
				print("Set the output limit to " .. i)
			end,
		}
	end

	self.menu[1][4].menuList[6].menuList[count + 1] = {
		text = "All",
		value = count + 1,
		func = function()
			addon.printNum = nil
			print("Set the output limit to All")
		end,
	}

	UIDropDownMenu_Initialize(drop, function(self, level, menuList)
		if not (menuList or addon.menu[level]) then return end
		for k, v in ipairs(menuList or addon.menu[level]) do
			v.value = k
			UIDropDownMenu_AddButton(v, level)
		end
	end, "MENU", 1)

	self.dropDown = drop

	return drop
end

_G.Fiend = addon
