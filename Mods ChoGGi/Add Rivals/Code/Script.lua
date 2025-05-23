-- See LICENSE for terms

if not g_AvailableDlc.gagarin then
	print(CurrentModDef.title, ": Space Race DLC not installed! Abort!")
	return
end

-- Replace local func
local debug
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	debug = env.debug
end

-- Needed for LukeH's Meat and Booze.
local PickUnusedAISponsor = ChoGGi_Funcs.Common.PickUnusedAISponsor

local mod_EnableMod
local mod_AddRivals
local mod_RivalSpawnSol

-- list of rivals user picked to use
local custom_rivals = false

local rivals = Presets.DumbAIDef.MissionSponsors
local rival_mod_options = {}
for i = 1, #rivals do
	local rival = rivals[i]
	if rival.id ~= "none" and rival.id ~= "random" then
		rival_mod_options[rival.id] = false
	end
end

ChoGGi_AddRivals_FixedThreads = false

local function AddRivals()
	-- Fix haywire threads
	if not ChoGGi_AddRivals_FixedThreads then
		print("Add Rivals: Starting thread cleanup")
		local DeleteThread = DeleteThread
		local GetThreadStatus = GetThreadStatus
		local ThreadsRegister = ThreadsRegister
		for thread in pairs(ThreadsRegister) do
			if GetThreadStatus(thread) == "WaitMsg" then
				local info = debug.getinfo(thread, 1)
				local upvalue2 = debug.getupvalue(info.func, 2)
				if upvalue2 == "mod_RivalSpawnSol" then
					DeleteThread(thread)
				end
			end
		end
		ChoGGi_AddRivals_FixedThreads = true
		print("Add Rivals: Finished thread cleanup")
	end

	if not mod_EnableMod then
		return
	end

	-- wait for new sol msg if it's too early
	if UIColony.day < mod_RivalSpawnSol then
		return
	end

	-- The devs added a check for non-existant keys in the hr table (and _G, but that's another story)
	-- using rawset bypasses the check and prevents log spam (Trying to create new value hr.PlanetColony5Longitude)
	local hr = hr
	if not rawget(hr, "PlanetColony5Longitude") then
		local rawset = rawset
		for i = 5, 20 do
			rawset(hr, "PlanetColony" .. i .. "Longitude", 0)
			rawset(hr, "PlanetColony" .. i .. "Latitude", 0)
		end
	end

	-- add stuff missing from saves
	if not g_CurrentMissionParams.idRivalColonies then
		g_CurrentMissionParams.idRivalColonies = {
			"random",
			"random",
			"random"
		}
	end
	if not RivalAIs then
		RivalAIs = {}
	end

	local RivalAIs = RivalAIs
	local SpawnRivalAI = SpawnRivalAI
	local rivals = Presets.DumbAIDef.MissionSponsors

	-- Custom rivals
	if custom_rivals then
		for id in pairs(rival_mod_options) do
			if rival_mod_options[id] and not RivalAIs[id] then
				SpawnRivalAI(rivals[id])
			end
		end
	else
	-- Random rivals
		local rival_count = table.count(RivalAIs)
		local def_count = #rivals
		-- Already maxed out
		if rival_count == def_count then
			return
		end

		for _ = 1, def_count do
			-- Stop spawning when we're maxed out
			if rival_count >= def_count or rival_count >= mod_AddRivals then
				break
			end

			local sponsor = PickUnusedAISponsor()
			if sponsor then
				SpawnRivalAI(sponsor)
			end

			rival_count = rival_count + 1
		end
	end

end

function OnMsg.NewDay(sol)
	if mod_RivalSpawnSol >= sol then
		AddRivals()
	end
end

-- New games
OnMsg.CityStart = AddRivals
-- Saved ones
OnMsg.LoadGame = AddRivals

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	local options = CurrentModOptions

	for id in pairs(rival_mod_options) do
		rival_mod_options[id] = options:GetProperty(id)
		-- enable if any rival is turned on
		if rival_mod_options[id] then
			custom_rivals = true
		end
	end

	mod_EnableMod = options:GetProperty("EnableMod")
	mod_AddRivals = options:GetProperty("AddRivals")
	mod_RivalSpawnSol = options:GetProperty("RivalSpawnSol")

	if options:GetProperty("RivalSpawnSolRandom") then
		mod_RivalSpawnSol = AsyncRand(mod_RivalSpawnSol) + 1
	end

	-- make sure we're in-game
	if not UIColony then
		return
	end

	AddRivals()
end
-- Load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- Fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions
