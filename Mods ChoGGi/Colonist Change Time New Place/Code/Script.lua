-- See LICENSE for terms

local ChoGGi_Funcs = ChoGGi_Funcs

local mod_EnableMod
local mod_ForcedByUserLockTimeout

local five_sols = 5 * const.Scale.sols
local function StartupCode()
	if mod_EnableMod then
		ChoGGi_Funcs.Common.SetConsts("ForcedByUserLockTimeout", mod_ForcedByUserLockTimeout)
	elseif Consts.ForcedByUserLockTimeout ~= five_sols then
		-- If user turns off during gameplay.
		ChoGGi_Funcs.Common.SetConsts("ForcedByUserLockTimeout", five_sols)
	end
end

-- New games
OnMsg.CityStart = StartupCode
-- Saved ones
OnMsg.LoadGame = StartupCode
-- Switch between different maps (happens before UICity)
OnMsg.ChangeMapDone = StartupCode

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	mod_EnableMod = CurrentModOptions:GetProperty("EnableMod")
	mod_ForcedByUserLockTimeout = CurrentModOptions:GetProperty("ForcedByUserLockTimeout") * const.Scale.sols

	-- Make sure we're in-game
	if not UIColony then
		return
	end

	StartupCode()
end
-- Load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- Fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions
