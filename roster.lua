-- Rosters ;<
local fiend = _G.Fiend

local UnitExists = UnitExists
local UnitInRaid = UnitInRaid
local UnitGUID = UnitGUID

-- owner guid -> pet guid
local revPets = {}
-- pet guid -> Owner guid
local pets = {}
-- unit -> guid
local units = {}
-- guid -> unit
local guids = {}

local Clean = function(base, num)
	local unit, guid
	for i = 1, num do
		unit = base .. i
		guid = guids[unit]

		if revPets[guid] then
			pets[revPets[guid]] = nil
			revPets[guid] = nil
		end

		guids[guid] = nil
		units[unit] = nil
	end
end

local UpdateRoster = function(base, num)
	local unit, pet, guid, pguid

	for i = 1, num do
		unit = base .. i

		if UnitExists(unit) then
			pet = unit .. "pet"
			guid = UnitGUID(unit)

			units[unit] = guid
			guids[guid] = unit

			fiend:UNIT_PET(unit)
		elseif units[unit] then
			guids[units[unit]] = nil
			units[unit] = nil
		end
	end
end

local UpdateRaidRoster = function(self)
	if not UnitInRaid("player") then
		return Clean("raid", 40)
	end

	UpdateRoster("raid", 40)
end

local UpdatePartyRoster = function(self)
	if not UnitExists("party1") then
		return Clean("party", 4)
	end

	UpdateRoster("party", 4)
end

function fiend:PLAYER_ENTERING_WORLD()
	local guid = UnitGUID("player")
	units.player = guid
	guids[guid] = "player"

	self:UNIT_PET("player")
end

function fiend:UNIT_PET(unit)
	local guid = UnitGUID(unit)
	if UnitExists(unit .. "pet") then
		local pguid = UnitGUID(unit .. "pet")
		pets[pguid] = guid
		revPets[guid] = pguid

		units[unit .. "pet"] = pguid
		guids[pguid] = unit .. "pet"
	elseif revPets[guid] then
		pets[revPets[guid]] = nil
		revPets[guid] = nil

		guids[units[unit .. "pet"]] = nil
		units[unit .. "pet"] = nil
	end
end

fiend.RAID_ROSTER_UPDATE = UpdateRoster
fiend.PARTY_MEMBERS_CHANGED = UpdateRoster
fiend:RegisterEvent("RAID_MEMBERS_UPDATE")
fiend:RegisterEvent("PARTY_MEMBERS_UPDATE")
fiend:RegisterEvent("PLAYER_ENTERING_WORLD")
fiend:RegisterEvent("UNIT_PET")

function fiend:IsPet(guid)
	return pets[guid]
end

function fiend:GetUnit(guid)
	return guids[guid]
end

function fiend:AddPet(guid, parent)
	pets[guid] = parent
	revPets[parent] = guid
end

