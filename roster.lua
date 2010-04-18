-- Rosters ;<
local fiend = _G.Fiend

local UnitExists = UnitExists
local UnitInRaid = UnitInRaid
local UnitGUID = UnitGUID

local playerGUID

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

		if guid then
			if revPets[guid] then
				pets[revPets[guid]] = nil
				revPets[guid] = nil
			end

			guids[guid] = nil
			units[unit] = nil
		end
	end
end

local UpdateRoster = function(base, num)
	local unit, guid

	for i = 1, num do
		unit = base .. i

		if UnitExists(unit) then
			guid = UnitGUID(unit)

			if guid == playerGUID then
				unit = "player"
			end

			units[unit] = guid
			guids[guid] = unit

			fiend:UNIT_PET(unit)
		elseif units[unit] then
			guids[units[unit]] = nil
			units[unit] = nil
			fiend:UNIT_PET(unit)
		end
	end
end

function fiend:RAID_ROSTER_UPDATE()
	if not UnitInRaid("player") then
		return Clean("raid", 40)
	end

	UpdateRoster("raid", 40)
end

function fiend:PARTY_MEMBERS_CHANGED(...)
	if not UnitExists("party1") then
		return Clean("party", 4)
	end

	UpdateRoster("party", 4)
end

function fiend:PLAYER_ENTERING_WORLD()
	playerGUID = playerGUID or UnitGUID("player")

	units.player = playerGUID
	guids[playerGUID] = "player"

	self:UNIT_PET("player")
	self:RAID_ROSTER_UPDATE()
	self:PARTY_MEMBERS_CHANGED()
end

function fiend:UNIT_PET(unit)
	local guid = UnitGUID(unit)
	local pet = unit .. "pet"
	if UnitExists(pet) then
		local pguid = UnitGUID(pet)
		pets[pguid] = guid
		revPets[guid] = pguid

		units[pet] = pguid
		guids[pguid] = pet
	elseif revPets[guid] then
		pets[revPets[guid]] = nil
		revPets[guid] = nil

		-- Does this still exist here?
		if units[pet] then
			guids[units[pet]] = nil
			units[pet] = nil
		end
	end
end

fiend:RegisterEvent("RAID_ROSTER_UPDATE")
fiend:RegisterEvent("PARTY_MEMBERS_CHANGED")
fiend:RegisterEvent("PLAYER_ENTERING_WORLD")
fiend:RegisterEvent("UNIT_PET")
fiend:RegisterEvent("ZONE_CHANGED_NEW_AREA")

fiend.ZONE_CHANGED_NEW_AREA = fiend.PARTY_MEMBERS_CHANGED

function fiend:IsPet(guid)
	return pets[guid]
end

function fiend:GetUnit(guid)
	return pets[guid] and guids[pets[guid]] or guids[guid]
end

function fiend:AddPet(guid, parent)
	pets[guid] = parent
	revPets[parent] = guid
end

function fiend:IterateUnitRoster()
	return next, units, nil
end

