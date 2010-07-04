--[[
Copyright (c) 2009, 2010 Chris Bannister
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local lib = LibStub and LibStub:NewLibrary("ZeeRoster-1.0", 1)

if(not lib) then
	return
end

local UnitExists = UnitExists
local UnitInRaid = UnitInRaid
local UnitGUID = UnitGUID

local playerGUID

local pary_size = 1

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
			party_size = i

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

function lib:AddPet(guid, parent)
	pets[guid] = parent
	revPets[parent] = guid
end

function lib:IsPet(guid)
	return pets[guid]
end

function lib:GetUnit(guid)
	return pets[guid] and guids[pets[guid]] or guids[guid]
end

function lib:IterateUnitRoster()
	return next, units, nil
end

function lib:InRaid()
	return party_size > 5
end

function lib:InRaid()
	return party_size > 1 and party_size < 6
end
