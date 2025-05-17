-- See LICENSE for terms

local CanSaveGame = CanSaveGame

local mod_EnableMod
local mod_AutosaveInterval
local mod_MaxAutosaves

local function LoadModData()
	local settings
	if LocalStorage.ModPersistentData[CurrentModId] then
		settings = LocalStorage.ModPersistentData[CurrentModId]
	end

	if not settings or not next(settings) then
		settings = {
			AutosaveNumber = 0,
			AutosaveThread = false,
		}
	end

	return settings
end

local function SaveModData()
	local settings = UIColony and UIColony.ChoGGi_AutosaveTweaks or LoadModData()

	LocalStorage.ModPersistentData[CurrentModId] = settings
	SaveLocalStorage()
end

local err
local function StartupCode()
	if not UIColony or g_Tutorial then
		return
	end

	-- Load up mod saved data (so far just autosave number)
	if not UIColony.ChoGGi_AutosaveTweaks then
		UIColony.ChoGGi_AutosaveTweaks = LoadModData()
	end

	local settings = UIColony.ChoGGi_AutosaveTweaks

	CreateRealTimeThread(function()
		local city = MainCity
		while true do

			Sleep(mod_AutosaveInterval)
			if mod_EnableMod then

				-- If you load a save it won't remove the old thread
				if city ~= MainCity then
					break
				end

				while not CanSaveGame() do
					Sleep(1000)
				end

				Msg("AutosaveStart")
				LoadingScreenOpen("idAutosaveScreen", "save savegame")

				-- Make sure bad things don't happen (ripped from Autosave())
				local igi = GetInGameInterface()
				if igi and not igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					igi:SetMode("selection")
				end

				-- Get number to use for Autosave
				settings.AutosaveNumber = settings.AutosaveNumber + 1
				if settings.AutosaveNumber > mod_MaxAutosaves then
					settings.AutosaveNumber = 1
				end
				SaveModData()
				local savename = "Autosave" .. settings.AutosaveNumber

				local savename_filename = savename .. ".savegame.sav"

				-- I should save the game as a temp name then move it after saving works, but that's blacklisted
				DeleteGame(savename_filename)

				err, savename_filename = SaveAutosaveGame(savename)

				Msg("AutosaveEnd")
				if err then
					print("Autosave Tweaks: ", savename_filename, err)

					LoadingScreenClose("idAutosaveScreen", "save savegame")
					local preset
					if err == "Disk Full" or err == "orbis1gb" then
						preset = "AutosaveFailedNoSpace"
					else
						preset = "AutosaveFailedGeneric"
					end
					WaitPopupNotification(preset, {error_code = T{err}})
					return
				end

				-- Where I should move temp save to overwrite existing

				LoadingScreenClose("idAutosaveScreen", "save savegame")
			end
		end -- while
	end)
end

-- New games
OnMsg.CityStart = StartupCode
-- Saved ones
OnMsg.LoadGame = StartupCode

-- Update mod options
local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	mod_EnableMod = CurrentModOptions:GetProperty("EnableMod")
	mod_MaxAutosaves = CurrentModOptions:GetProperty("MaxAutosaves")
	-- 10 * 60 * 1000 == 10 minutes (1000 ticks = 1 second in in-game time at normal speed)
	mod_AutosaveInterval = CurrentModOptions:GetProperty("AutosaveInterval") * 60 * 1000
--~ 	mod_AutosaveInterval = 10000

	StartupCode()
end
-- Load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- Fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions
