PLUGIN.name = "Zone Travel"
PLUGIN.author = "Sample Name"
PLUGIN.desc = "Crosserver zone travel"

nut.util.include("sv_zonetravel.lua")
nut.util.include("derma/cl_travelpoint.lua")

local PLUGIN = PLUGIN;
PLUGIN.StartingZone = ""

function PLUGIN:SetStartingZone(uid)
	PLUGIN.StartingZone = uid
end

nut.char.registerVar("zone_uid", {
    isLocal = true,
    default = "gm_construct"
})

function PLUGIN:CanPlayerCreateCharacter(client)
	if game.GetMap() == PLUGIN.StartingZone then 
		return true
	else
		return false
	end
end

if SERVER then
	function PLUGIN:CanPlayerUseChar(client, char)
		local zone = char:getData("zone_uid", {})

		if zone == PLUGIN.Zones[game.GetMap()].uid or PLUGIN.TravelPoints[zone] and PLUGIN.TravelPoints[zone].inZone == PLUGIN.Zones[game.GetMap()].uid then 
			return true
		else
			return false, "@zoneTravel_wrongZone"
		end
	end
end

PLUGIN:SetStartingZone("rp_stalker_mixed")