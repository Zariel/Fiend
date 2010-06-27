-- Rosters ;<

local lib = LibStub and LibStub:NewLibrary("ZeeRoster-1.0", 1)

if(not lib) then
	return
end

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

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

local Clean = function(base, num)
	local unit, guid
	for i = 1, num do
		unit = base .. i
		guid = guids[unit]

		if(guid) then
			if(revPets[guid]) then
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

		if(UnitExists(unit)) then
			guid = UnitGUID(unit)

			if guid == playerGUID then
				unit = "player"
			end

			units[unit] = guid
			guids[guid] = unit

			f:UNIT_PET(unit)
		elseif(units[unit]) then
			guids[units[unit]] = nil
			units[unit] = nil

			f:UNIT_PET(unit)
		end
	end
end

function f:RAID_ROSTER_UPDATE()
	if(not UnitInRaid("player")) then
		return Clean("raid", 40)
	end

	UpdateRoster("raid", 40)
end

function f:PARTY_MEMBERS_CHANGED(...)
	if(not UnitExists("party1")) then
		return Clean("party", 4)
	end

	UpdateRoster("party", 4)
end

function f:PLAYER_ENTERING_WORLD()
	playerGUID = playerGUID or UnitGUID("player")

	units.player = playerGUID
	guids[playerGUID] = "player"

	self:UNIT_PET("player")
	self:RAID_ROSTER_UPDATE()
	self:PARTY_MEMBERS_CHANGED()
end

function f:UNIT_PET(unit)
	local guid = UnitGUID(unit)
	local pet = unit .. "pet"

	if(UnitExists(pet)) then
		local pguid = UnitGUID(pet)
		pets[pguid] = guid
		revPets[guid] = pguid

		units[pet] = pguid
		guids[pguid] = pet
	elseif(revPets[guid]) then
		pets[revPets[guid]] = nil
		revPets[guid] = nil

		-- Does this still exist here?
		if(units[pet]) then
			guids[units[pet]] = nil
			units[pet] = nil
		end
	end
end

f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_PET")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f.ZONE_CHANGED_NEW_AREA = f.PARTY_MEMBERS_CHANGED


function lib:IsPet(guid)
	return pets[guid]
end

function lib:GetUnit(guid)
	return pets[guid] and guids[pets[guid]] or guids[guid]
end

function lib:IterateUnitRoster()
	return next, units, nil
end
