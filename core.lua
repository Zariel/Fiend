local parent, ns = ...
local fiend = CreateFrame("Frame")
ns.fiend = fiend
ns.L = setmetatable(fiend.L or {}, { __index = function(t, s) t[s] = s return s end })

local L = ns.L
local R = LibStub("ZeeRoster-1.0")

fiend:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
fiend:RegisterEvent("ADDON_LOADED")

local UnitAffectingCombat = UnitAffectingCombat
local UnitInVehicle = UnitInVehicle
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local pairs = pairs
local time = time

local timer = 0
local OnUpdate = function(self, elapsed)
	timer = timer + elapsed

	if(timer > 0.5) then
		for i, d in pairs(self.displays) do
			d:OnUpdate(timer)
		end

		timer = 0
	end
end

local ldb
local band = bit.band
local filter = bit.bor(COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_MINE)

local events = {
	["SWING_DAMAGE"] = "Damage",
	["RANGE_DAMAGE"] = "Damage",
	["SPELL_DAMAGE"] = "Damage",
	["SPELL_PERIODIC_DAMAGE"] = "Damage",

	["SPELL_HEAL"] = "Healing",
	["SPELL_PERIDOIC_HEAL"] = "Healing",

	["SPELL_SUMMON"] = true,
}

local lastAction = {}

-- [[ DPS TRACKING ENABLE HERE ]]
fiend.trackDPS = true

function fiend:ADDON_LOADED(name)
	if(name ~= "Fiend") then return end

	ldb = LibStub and LibStub("LibDataBroker-1.1", true)

	if(ldb) then
		self:initDropDown()

		local obj = ldb:NewDataObject("Fiend", {
			type = "launcher",
			icon = [[Interface\Icons\Ability_BullRush]],
			OnClick = function(self, button)
				if button == "RightButton" then
					ToggleDropDownMenu(1, nil, fiend.dropDown, "cursor")
				end
			end,
		})

		self.dataObj = obj
	end

	self.displays = {}

	self.printNum = 10

	-- Displays are the windows
	local win = self:NewDisplay("main")
	-- View syntax:
	-- Display:NewView(String name, String[] events, int barSize, int[]
	-- headerColor, int[] barColor, bool dps)
	-- Only name, events and size are required.
	local damage = win:NewView(L["Damage"], {
		"SWING_DAMAGE",
		"RANGE_DAMAGE",
		"SPELL_DAMAGE",
		"SPELL_PERIODIC_DAMAGE",
	}, 16, { 0.6, 0.2, 0.2 })

	local heal = win:NewView(L["Healing"], { "SPELL_HEAL", "SPELL_PERIDOIC_HEAL" }, 16, { 0.2, 0.6, 0.2 })

	local overHeal = win:NewView(L["OverHealing"], { "SPELL_HEAL", "SPELL_PERIDOIC_HEAL" }, 16, { 0.2, 0.6, 0.5 })
	overHeal.overHeal = true

	local dps = win:NewView(L["DPS"], {
		"SWING_DAMAGE",
		"RANGE_DAMAGE",
		"SPELL_DAMAGE",
		"SPELL_PERIODIC_DAMAGE",
	}, 16, { 0.2, 0.6, 0.5 }, nil, true)

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self:Show()

	self:SetScript("OnUpdate", OnUpdate)

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil
end

local spellId, spellName, spellSchool, ammount, over, school, resist
function fiend:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	if not(events[event] and band(sourceFlags, filter) > 0) then return end

	if event == "SWING_DAMAGE" then
		ammount, over, school, resist = ...
	elseif event == "SPELL_SUMMON" then
		-- This is to get summoned pets like totems etc
		return R:AddPet(destGUID, sourceGUID)
	else
		spellId, spellName, spellSchool, ammount, over, school, resist = ...
	end

	-- Bail, ususaly because the unit is in a vehicle and we dont have its
	-- GUID mapping
	local unit = R:GetUnit(sourceGUID)
	if(not unit) then return end

	ammount = ammount or 0
	resist = resist or 0
	over = over or 0

	-- Track over kill ?
	local damage = ammount - (over + resist)
	--local damage = ammount

	local overHeal
	if(event == "SPELL_HEAL" or event == "SPELL_PERIDOIC_HEAL") and over > 0 then
		overHeal = over
	end

	if(damage > 0 or overHeal) then
		local pet = R:IsPet(sourceGUID)

		if(pet) then
			sourceGUID = pet
			sourceName = UnitName(R:GetUnit(pet))
		end

		if(self.trackDPS) then
			lastAction[sourceGUID] = timeStamp
		end

		for name, display in pairs(self.displays) do
			display:CombatEvent(event, sourceGUID, damage, sourceName, overHeal)
		end
	end
end

if(fiend.trackDPS) then
	local time = time
	function fiend:InCombat(guid)
		return time() - (lastAction[guid] or 0) < 3
	end
end

function fiend:initDropDown()
	local drop = CreateFrame("Frame", "FiendDropDown", UIParent, "UIDropDownMenuTemplate")
	self.menu = {
		{
			{
				text = "Fiend",
				owner = drop,
				isTitle = true,
			}, {
				text = L["Windows"],
				owner = drop,
				hasArrow = true,
				menuList = {
				},
			}
		}
	}

	UIDropDownMenu_Initialize(drop, function(horse, level, menuList)
		if not (menuList or self.menu[level]) then return end
		for k, v in ipairs(menuList or self.menu[level]) do
			v.value = k
			UIDropDownMenu_AddButton(v, level)
		end
	end, "MENU", 1)

	self.dropDown = drop
end
