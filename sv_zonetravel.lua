local playerMeta = FindMetaTable("Player")
local PLUGIN = PLUGIN

PLUGIN.StartingZone = PLUGIN.StartingZone or ""
PLUGIN.Zones = {}
PLUGIN.TravelPoints = {}

--[[
	uid - unique id for this zone, matches map's name
	name - name for this zone, any
	ip - address in ip:port format
--]]
function PLUGIN:RegisterZone( uid, name, ip )
	PLUGIN.Zones[ uid ] = { ['uid'] = uid, ['name'] = name, ['ip'] = ip }
end

-- Get server's current zone UID
function PLUGIN:GetCurrentZoneUID()
	return PLUGIN.Zones[game.GetMap()].uid or "Wrong Zone!"
end

function PLUGIN:OnCharCreated(client, character)
	character:setData("zone_uid", PLUGIN:GetCurrentZoneUID())
end

-- Whether a character is currently travelling to this zone
function PLUGIN:CharTravelsToCurrentZone(character)
	local travelPoint = character:getData("zone_uid", {})
	
	if PLUGIN.TravelPoints[travelPoint] and PLUGIN.TravelPoints[travelPoint].inZone == PLUGIN:GetCurrentZoneUID() then 
		return true
	else
		return false 
	end
end

--[[
	inZone - uid of a zone where this travelPoint is located
	toZone - uid of a zone where this travelPoint leads
	toTravelPoint - uid of a travelPoint to which this travelPoint leads
	uid - unique id for this travelPoint
	minVector, maxVector - xyz coords to build travelPoint borders. You can get them with a TravelPoint helper tool
--]]
function PLUGIN:RegisterTravelPoint( inZone, toZone, toTravelPoint, uid, minVector, maxVector, ... )
	-- There are going to be lots of travel points, we only need to initialize those that are placed on current zone
	if game.GetMap() != inZone then return end 

	local spawnPosAng = {...}

	PLUGIN.TravelPoints[ uid ] = { 
		['inZone'] = inZone,
		['toZone'] = toZone, 
		['toTravelPoint'] = toTravelPoint,
		['uid'] = uid, 
		['minVector'] = util.StringToType(minVector, "Vector"),
		['maxVector'] = util.StringToType(maxVector, "Vector"),
		spawnPoints = {} 
	}
	-- We don't need to store spawnPoints on client
	local vectors
	for k, v in pairs( spawnPosAng ) do
		vectors = string.Split(v, ";")
		PLUGIN.TravelPoints[ uid ].spawnPoints[k] = { pos = util.StringToType(vectors[1], "Vector"), ang = util.StringToType(vectors[2], "Angle")}
	end

end

function PLUGIN:getTravelPoint(TravelPointUID)
	return PLUGIN.TravelPoints[TravelPointUID]
end

function PLUGIN:getAllTravelPoints()
	return PLUGIN.TravelPoints
end

-- This is for single check (ex: TravelPoint items, checking TravelPoint in commands)
function playerMeta:isInTravelPoint(TravelPointUID)
	local TravelPointData = PLUGIN:getTravelPoint(TravelPointUID)

	if (!TravelPointData) then
		return false, "TravelPoint you specified is not valuid."
	end

	local char = v:getChar()

	if (!char) then
		return false, "Your character is not valid."
	end

	local clientPos = self:GetPos() + self:OBBCenter()
	return clientPos:WithinAABox(TravelPointData.minVector, TravelPointData.maxVector), TravelPointData
end

-- This is for continous check
function playerMeta:getTravelPoint()
	return self.curTravelPoint
end

function PLUGIN:PlayerLoadedChar(client, character, lastChar)
	client.curTravelPoint = nil
end

function PLUGIN:PlayerDeath(client)
	client.curTravelPoint = nil
end

function PLUGIN:PlayerSpawn(client)
	client.curTravelPoint = nil
end

local function sortVector(vector1, vector2)
	local minVector = Vector(0, 0, 0)
	local maxVector = Vector(0, 0, 0)

	for i = 1, 3 do
		if (vector1[i] >= vector2[i]) then
			maxVector[i] = vector1[i]
			minVector[i] = vector2[i]
		else
			maxVector[i] = vector2[i]
			minVector[i] = vector1[i]
		end
	end

	return minVector, maxVector
end

-- Timer instead of heavy think.
timer.Create("nutTravelPointController", 2, 0, function()
	for k, v in ipairs(player.GetAll()) do
		local char = v:getChar()

		if (char and v:Alive()) then
			local TravelPoint = v:getTravelPoint()
			for uid, TravelPointData in pairs(PLUGIN:getAllTravelPoints()) do
				local clientPos = v:GetPos() + v:OBBCenter()

				if (clientPos:WithinAABox(TravelPointData.minVector, TravelPointData.maxVector)) then
					if (TravelPoint != uid) then
						v.curTravelPoint = uid

						hook.Run("OnPlayerTravelPointChanged", v, uid)
					end
				else
					v.curTravelPoint = nil
				end
			end
		end
	end
end)

function PLUGIN:OnPlayerTravelPointChanged(client, TravelPointUID)
	local TravelPointData = PLUGIN:getTravelPoint(TravelPointUID)

	if (client:Alive()) then
		netstream.Start(client, "nutTravelPoint_onEnter", PLUGIN.Zones[TravelPointData.toZone].uid, PLUGIN.Zones[TravelPointData.toZone].name, TravelPointData.toTravelPoint)
	end
end

-- For testing purposes, remove later!
function PLUGIN:PlayerLoadedChar(client)
    local character = client:getChar()

    print(character:getData("zone_uid", {}))
end

-- Called after the player's loadout has been set.
function PLUGIN:PlayerLoadedChar(client, character, lastChar)
	timer.Simple(0, function()
		if (IsValid(client)) then

			local position = {}
			if PLUGIN:CharTravelsToCurrentZone(character) then
				local spawnPoint = table.Random(PLUGIN.TravelPoints[character:getData("zone_uid", {})].spawnPoints)
				position[1] = spawnPoint.pos
				position[2] = spawnPoint.ang
				position[3] = PLUGIN.TravelPoints[character:getData("zone_uid", {})].inZone
			else
				position = character:getData("pos")
			end

			-- Check if the position was set.
			if (position) then
				if (position[3] and position[3]:lower() == game.GetMap():lower()) then
					-- Restore the player to that position.
					client:SetPos(position[1].x and position[1] or client:GetPos())
					client:SetEyeAngles(position[2].p and position[2] or Angle(0, 0, 0))
				end

				-- Remove the position data since it is no longer needed; set new current zone UID
				character:setData("pos", nil)
				character:setData("zone_uid", PLUGIN:GetCurrentZoneUID())
			end
		end
	end)
end

netstream.Hook("nutTravelPoint_onTravel", function(client, zone, travelPoint)
	if !client:Alive() then return end
	
	-- Checks for security purposes
	if PLUGIN.TravelPoints[client:getTravelPoint()].toTravelPoint != travelPoint then return end
	if PLUGIN.TravelPoints[client:getTravelPoint()].toZone != zone then return end

	local ip = PLUGIN.Zones[zone].ip
	client:getChar():setData("zone_uid", travelPoint)
	client:SendLua( "LocalPlayer():ConCommand( 'connect ".. ip .. "' ) " )
end)

-- Register all the zones first, after that register travelPoints
PLUGIN:RegisterZone("rp_stalker_mixed", "Восточный Рыжий Лес", "37.230.162.191:27015")
PLUGIN:RegisterZone("rp_redforest", "Рыжий Лес", "192.168.1.33:27016")
PLUGIN:RegisterTravelPoint("rp_stalker_mixed", "rp_redforest", "RedForest_RedForestEast", "RedForestEast_RedForest", 
	"-2818.226807 -1049.105591 -11958.913086", 
	"-2577.279785 -2450.358398 -12222.087891", 
	"-2489.352051 -1941.417603 -12198.518555;2.526 -41.413 0.000",
	"-2398.714844 -1580.931030 -12065.471680;3.577364 -44.352718 0.000000",
	"-2495.693848 -2305.364746 -12090.927734;3.973364 -9.372717 0.000000"
)
PLUGIN:RegisterTravelPoint("rp_redforest", "rp_stalker_mixed", "RedForestEast_RedForest", "RedForest_RedForestEast", 
	"4388.248047 6895.833496 116.345764", 
	"3932.979004 6824.904785 253.212158", 
	"4090.192139 6697.564453 212.031250;1.319942 -90.911369 0.000000",
	"4245.619141 6685.732910 212.031250;1.187942 -90.779358 0.000000"
)