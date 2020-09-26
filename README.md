# ns_zoneTravel
ns_zoneTravel is a plugin for NutScript framework  
It was developed and tested using NutScript 1.1B and mysqloo  

The plugin brings crosserver travel to NutScript. In order to make it work you have to do the following:  
1. Setup at least two servers
2. Setup a MySQL database and a mysql module (preferably mysqloo)
3. Each server is a different zone, register the zones with PLUGIN:RegisterZone function
4. Each zone has at least one travel point, register travel points with PLUGIN:RegisterTravelPoint function
5. One of the zones is a starting zone, meaning that players are able to create characters only being on a certain server. Set a starting zone with PLUGIN:SetStartingZone function

# Functions
## Server
### PLUGIN:RegisterZone( uid, name, ip )
uid - unique ID, similar to map's name  
name - a name that is being displayed when a player tries to travel to it   
ip - server's address in a form of ip:port 

### PLUGIN:RegisterTravelPoint( inZone, toZone, toTravelPoint, uid, minVector, maxVector, ... )
inZone - uid of a zone where this travelPoint is located  
toZone - uid of a zone where this travelPoint leads  
toTravelPoint - uid of a travelPoint to which this travelPoint leads  
uid - unique id for this travelPoint  
minVector, maxVector - coords to build travelPoint borders. You can get them with a TravelPoint helper tool, the process is similar to nut.area   

## Shared
### PLUGIN:SetStartingZone(uid)
uid - uid of an existing zone. Players are able to create characters only being on a server corresponding to starting zone

# Example

Check out sh_plugin.lua and sv_zonetravel.lua files to see the implementation
