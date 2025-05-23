-- See LICENSE for terms

local ChoGGi_Funcs = ChoGGi_Funcs
local what_game = ChoGGi.what_game

-- To go along with empty_func
function return_true_func()
	return true
end
function return_false_func()
	return false
end

function toboolean(str)
	if str == "true" or str == true then
		return true
	elseif str == "false" or str == false or not str then
		return false
	end
--~ 	return 0/0
end

-- Allows you to call ApplyModOptions without having a dialog window to use to get the mod options
-- ex:
-- CurrentModOptions:SetProperty("ExampleModOption", true)
-- ApplyModOptions(CurrentModId)
local ChoOrig_GetDialogModeParam = GetDialogModeParam
function GetDialogModeParam(id_or_win, ...)
	-- Fake it till you make it
	local mod = Mods and Mods[id_or_win]
	if mod then
		-- This will only be an issue if there's a dialog named the same as the mod_id
		return mod
	end

	return ChoOrig_GetDialogModeParam(id_or_win, ...)
end

-- add PostSaveGame to be a companion for SaveGame
local ChoOrig_ReportPersistErrors = ReportPersistErrors
ChoGGi_Funcs.Common.AddToOriginal("ReportPersistErrors")
function ReportPersistErrors(...)
	local _, errors, warnings = pcall(ChoOrig_ReportPersistErrors, ...)
	-- be useful for restarting threads, see if devs will add it (yeah I think that isn't happening after two dev teams are gone)
	Msg("PostSaveGame")
	-- the assert in PersistGame() attempts to concat a nil value
	return errors, warnings
end

if what_game == "Mars" then
	local ChoOrig_SetUserUIScale = SetUserUIScale
	ChoGGi_Funcs.Common.AddToOriginal("SetUserUIScale")
	function SetUserUIScale(val, ...)
		ChoOrig_SetUserUIScale(val, ...)

		local UIScale = (val + 0.0) / 100
		-- update existing dialogs
		local ChoGGi_dlgs_opened = ChoGGi_dlgs_opened
		for dlg in pairs(ChoGGi_dlgs_opened) do
			dlg.dialog_width_scaled = dlg.dialog_width * UIScale
			dlg.dialog_height_scaled = dlg.dialog_height * UIScale
			dlg.header_scaled = dlg.header * UIScale

			-- make sure the size i use is below the res w/h
			local _, _, x, y = GetSafeAreaBox():xyxy()
			if dlg.dialog_width_scaled > x then
				dlg.dialog_width_scaled = x - 50
			end
			if dlg.dialog_height_scaled > y then
				dlg.dialog_height_scaled = y - 50
			end

			dlg:SetSize(dlg.dialog_width_scaled, dlg.dialog_height_scaled)
		end
		-- might as well update this now (used to be in an OnMsg)
		ChoGGi.Temp.UIScale = UIScale
	end

elseif what_game == "JA3" then
	-- Log spam reduce from shortcuts in main menu
	local ChoOrig_GetOperationsInSector = GetOperationsInSector
	function GetOperationsInSector(...)
		if gv_Sectors then
			return ChoOrig_GetOperationsInSector(...)
		end
	end

end

-- Copied from GedPropEditors.lua. it's normally only called when GED is loaded, but we need it for the colour picker (among others)
if not rawget(_G, "CreateNumberEditor") then
	local IconScale = point(500, 500)
	local IconColor = RGB(0, 0, 0)
	local RolloverBackground = RGB(204, 232, 255)
	local PressedBackground = RGB(121, 189, 241)
	local Background = RGBA(0, 0, 0, 0)
	local DisabledIconColor = RGBA(0, 0, 0, 128)
	local padding1 = box(1, 2, 1, 1)
	local padding2 = box(1, 1, 1, 2)

	function CreateNumberEditor(parent, id, up_pressed, down_pressed, skip_edit)
		local g_Classes = g_Classes

		local button_panel = g_Classes.XWindow:new({
			Dock = "right",
		}, parent)
		local top_btn = g_Classes.XTextButton:new({
			Dock = "top",
			OnPress = up_pressed,
			Padding = padding1,
			Icon = "CommonAssets/UI/arrowup-40.tga",
			IconScale = IconScale,
			IconColor = IconColor,
			DisabledIconColor = DisabledIconColor,
			Background = Background,
			DisabledBackground = Background,
			RolloverBackground = RolloverBackground,
			PressedBackground = PressedBackground,
		}, button_panel, nil, nil, "NumberArrow")
		local bottom_btn = g_Classes.XTextButton:new({
			Dock = "bottom",
			OnPress = down_pressed,
			Padding = padding2,
			Icon = "CommonAssets/UI/arrowdown-40.tga",
			IconScale = IconScale,
			IconColor = IconColor,
			DisabledIconColor = DisabledIconColor,
			Background = Background,
			DisabledBackground = Background,
			RolloverBackground = RolloverBackground,
			PressedBackground = PressedBackground,
		}, button_panel, nil, nil, "NumberArrow")
		local edit
		if not skip_edit then
			edit = g_Classes.XEdit:new({
				Id = id,
				Dock = "box",
			}, parent)

		end
		return edit, top_btn, bottom_btn
	end
end

-- Add some shortened func names
MapGetC = ChoGGi_Funcs.Common.MapGet
so = ChoGGi_Funcs.Common.SelObject
trans = ChoGGi_Funcs.Common.Translate
