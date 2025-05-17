
-- Load mods in mainmenu
--~ local load_mods = true
local load_mods = false

-- Start in Load game dialog
local load_dialog = false
--~ local load_dialog = true

function OnMsg.DesktopCreated()

	-- stop intro videos
	PlayInitialMovies = empty_func
	-- get rid of mod manager warnings (not the reboot one though)
	ParadoxBuildsModManagerWarning = true

  CreateRealTimeThread(function()
		local WaitMsg = WaitMsg
		local Dialogs = Dialogs

		-- Wait for it (otherwise stuff below won't work right)
		while not Dialogs.PGMainMenu do
			WaitMsg("OnRender")
		end

		if load_mods then
			-- Load mods (figure out how to skip loading mod entity in main menu?)
			ModsReloadItems()
			WaitMsg("OnRender")
		end

		if load_dialog then
			-- Show load game dialog
			Dialogs.PGMainMenu:SetMode("Load")
		end
  end)


end
