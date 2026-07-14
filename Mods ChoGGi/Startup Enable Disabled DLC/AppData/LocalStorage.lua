
-- load settings before anything else (for anything in /Code that uses them)
local new_settings_file = "AppData/LocalStorage_Settings.lua"
local settings = dofile(new_settings_file)
g_LocalStorageFile = new_settings_file
LocalStorage = settings

-- Issues if you run it in mod editor mode (editor opens another copy of the exe)
if Platform.ged then
	return settings
end

-- skip
--~ do return settings end

-- any "mods" that need to be loaded before the game is loaded (skip logos, etc)
dofolder_files("AppData/BinAssets/Code")

-- local some globals
local setmetatable, pairs, rawget = setmetatable, pairs, rawget
-- a less restrictive env (okay, not at all restrictive)
local ChoOrig_G = _G
local mod_env = {
	__index = function(_, key)
		return ChoOrig_G[key]
	end,
	__newindex = function(_, key, value)
		ChoOrig_G[key] = value
	end,
}
local ChoOrig_OnMsg = getmetatable(ChoOrig_G.OnMsg)
local function LuaModEnv(env)
	env = env or {}
	env._G = ChoOrig_G
	setmetatable(env, mod_env)
	if env.OnMsg then
		env.OnMsg.__newindex = ChoOrig_OnMsg.__newindex
	end
	return env
end

local warning_msg = [[Warning: The blacklist function has been removed for this mod!
This means it has no limitations and can access your Steam name, Friends list, run any files on your computer, and so on.

]]

-- thread needed for WaitMsg
CreateRealTimeThread(function()
	-- needs an inf loop, so it fires whenever mod defs are loaded
	while true do
		-- wait till mods are loaded
		WaitMsg("ModDefsLoaded")

		-- build a list of ids from lua files in "Mod Ids"
		local mod_ids = {}
		local err, files = AsyncListFiles("AppData/BinAssets/Mod Ids", "*.lua")
		if not err and #files > 0 then
			local AsyncFileToString = AsyncFileToString
			for i = 1, #files do
				local err, id = AsyncFileToString(files[i])
				if not err then
					mod_ids[id] = true
				end
			end
		end

		-- remove blacklist for any mods in "Mod Ids"
		local Mods = Mods
		for _, mod in pairs(Mods) do
			if mod_ids[mod.steam_id] then
				-- mods can see if funcs are blacklisted or not (or just check a func)
				mod.no_blacklist = true
				-- restore unlimited env
				local env = mod.env
				for key in pairs(env) do
					-- we need to use the original __newindex from OnMsg instead of replacing it, or mod OnMsgs don't work
					if key ~= "OnMsg" then
						local g_key = rawget(ChoOrig_G, key)
						-- skip CurrentMod*
						if g_key then
							env[key] = g_key
						end
					end
				end
				-- and a few others (_G, OnMsg)
				mod.env = LuaModEnv(env)

				if GetUsername() == "ChoGGi" then
					-- Skip adding warning for me
				else
					-- add a warning to any mods without a blacklist, so user knows something is up
					mod.title = mod.title .. " (Warning)"
					mod.description = warning_msg .. mod.description
				end
			end
		end

		-- just in case anything needs it
		Msg("ChoGGi_Blacklist")
	end
end)

-- and done (we need to return settings so LocalStorage.lua works fine)
return settings
