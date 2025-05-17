-- See LICENSE for terms

if not g_AvailableDlc.gagarin then
	print(CurrentModDef.title, ": Space Race DLC not installed! Abort!")
	return
end

-- gotta list them manually
local building_to_tech = {
	AdvancedStirlingGenerator = "StirlingGenerator",
--~ 	AutomaticMetalsExtractor = "",
--~ 	ConcretePlant = "",
	CorporateOffice = "BehavioralShaping",
	GameDeveloper = "CreativeRealities",
	JumperShuttleHub = "CO2JetPropulsion",
	LowGLab = "MartianInstituteOfScience",
	MegaMall = "GravityEngineering",
--~ 	MetalsRefinery = "",
--~ 	RareMetalsRefinery = "",
--~ 	RCConstructorBuilding = "DronePrinting",
--~ 	RCDrillerBuilding = "DronePrinting",
--~ 	RCHarvesterBuilding = "DronePrinting",
--~ 	RCSensorBuilding = "DronePrinting",
--~ 	RCSolarBuilding = "DronePrinting",
	SolarArray = "DustRepulsion",
--~ 	TaiChiGarden = "",
	Temple = "Arcology",
}
local tech_to_building = {
	StirlingGenerator = "AdvancedStirlingGenerator",
	BehavioralShaping = "CorporateOffice",
	CreativeRealities = "GameDeveloper",
	CO2JetPropulsion = "JumperShuttleHub",
	MartianInstituteOfScience = "LowGLab",
	GravityEngineering = "MegaMall",
	DustRepulsion = "SolarArray",
	Arcology = "Temple",
}
-- Not locked behind tech
local always_unlock = {
	AutomaticMetalsExtractor = true,
	ConcretePlant = true,
	MetalsRefinery = true,
	RareMetalsRefinery = true,
	TaiChiGarden = true,
	-- ResupplyItemDefinitions doesn't use "Building"
	RCConstructor = true,
	RCDriller = true,
	RCHarvester = true,
	RCSensor = true,
	RCSolar = true,
}

local table = table
local IsTechResearched = IsTechResearched

-- we need to store the list of sponsor locked buildings
local sponsor_buildings = {}

local mod_options = {}

-- build options list
local BuildingTemplates = BuildingTemplates
for id, bld in pairs(BuildingTemplates) do
	for i = 1, 3 do
		if sponsor_buildings[id] or bld["sponsor_name" .. i] ~= "" then
			mod_options["ChoGGi_" .. id] = false
			mod_options["ChoGGi_Tech_" .. id] = false
			sponsor_buildings[id] = true
			break
		end
	end
end

-- Set what shows up in resupply dialog (rockets)
local function UpdateCargoDefs()
	local ingame = UIColony

	local defs = ResupplyItemDefinitions
	for i = 1, #defs do
		local def = defs[i]

		local name = def.id
		if name:sub(1, 2) == "RC" then
			name = name .. "Building"
		end

		local unlocked_building = mod_options["ChoGGi_" .. name]

		if unlocked_building
			and (always_unlock[name] or mod_options["ChoGGi_Tech_" .. name])
		then
			-- If tech researched than unlock
			local tech_id = building_to_tech[name]
			if always_unlock[name] or ingame and IsTechResearched(tech_id) then
				def.locked = false
			else
				-- update for in-session games
				def.locked = true
			end
		elseif unlocked_building then
			def.locked = false
		end
		--
	end
	--
end

local ChoOrig_GetMissionInitialLoadout = GetMissionInitialLoadout
function GetMissionInitialLoadout(pregame, ...)
	local items = ChoOrig_GetMissionInitialLoadout(pregame, ...)
	if pregame then
		UpdateCargoDefs()
	end
	return items
end

function OnMsg.TechResearched(tech_id)
	local building_id = tech_to_building[tech_id]
	if not building_id then
		return
	end

	local idx = table.find(ResupplyItemDefinitions, "id", building_id)
	if idx then
		local def = ResupplyItemDefinitions[idx]
		def.locked = false
	end
end

local function StartupCode()
	-- v1.8?
	BuildingTemplates.ShuttleHub.sponsor_name1 = ""
	BuildingTemplates.ShuttleHub.sponsor_status1 = false

	for bld_id, tech_id in pairs(building_to_tech) do
		if mod_options["ChoGGi_Tech_" .. bld_id] then
				-- build menu
			BuildingTechRequirements[bld_id] = {{ tech = tech_id, hide = false, }}
			-- add an entry to unlock it with the tech
			local tech = TechDef[tech_id]
			if not table.find(tech, "Building", bld_id) then
				tech[#tech+1] = PlaceObj("Effect_TechUnlockBuilding", {
					Building = bld_id,
				})
			end
		else
			if BuildingTechRequirements[bld_id] then
				BuildingTechRequirements[bld_id] = nil
			end
		end
	end

	UpdateCargoDefs()
end

OnMsg.CityStart = StartupCode
OnMsg.LoadGame = StartupCode

-- fired when settings are changed/init
local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	local options = CurrentModOptions
	for id in pairs(mod_options) do
		mod_options[id] = options:GetProperty(id)
	end

	local BuildingTechRequirements = BuildingTechRequirements
--~ ex{"sponsor_buildings",sponsor_buildings}
	local BuildingTemplates = BuildingTemplates
	for id, bld in pairs(BuildingTemplates) do
		if not sponsor_buildings[id] then
			goto continue
		end

		-- Set each status to false if it isn't
		for i = 1, 3 do
			local str = "sponsor_status" .. i
			if mod_options["ChoGGi_" .. id] then
				bld[str] = false
			elseif bld[str] ~= "" then
				bld[str] = "required"
			end
		end

		-- and this bugger screws me over on GetBuildingTechsStatus when using RCs
		local name = id
		if name:sub(1, 2) == "RC" and name:sub(-8) == "Building" then
			name = name:gsub("Building", "")
		end

		local reqs = BuildingTechRequirements[id]
		local idx = table.find(reqs, "check_supply", name)
		if idx then
			table.remove(reqs, idx)
		end

		::continue::
	end

	-- Make sure we're in-game
	if not UIColony then
		return
	end

	StartupCode()
end
-- load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions

-- Not sure which Msg I need to use to have this show up for new game, so I'm being lazy.
local ChoOrig_ResupplyItemsInit = ResupplyItemsInit
function ResupplyItemsInit(...)
	-- it doesn't have a return value, but if another mod adds one.
	local ret = ChoOrig_ResupplyItemsInit(...)

	UpdateCargoDefs()

	return ret
end
