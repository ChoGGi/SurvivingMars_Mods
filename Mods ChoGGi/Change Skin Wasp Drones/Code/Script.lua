-- See LICENSE for terms

if not g_AvailableDlc.gagarin then
	print(CurrentModDef.title, ": Space Race DLC not installed! Abort!")
	return
end

--~ local skins = {}
--~ local c = 0
--~ local EntityData = EntityData
--~ for key in pairs(EntityData) do
--~ 	if key:find("DroneJapanFlying") then
--~ 		c = c + 1
--~ 		skins[c] = key
--~ 	end
--~ end

local skins = {
	"DroneJapanFlying",
	"DroneJapanFlying_02",
	"DroneJapanFlying_03",
}

function FlyingDrone:GetSkins()
	return skins
end
