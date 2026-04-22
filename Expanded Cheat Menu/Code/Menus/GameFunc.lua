-- See LICENSE for terms

if ChoGGi.what_game ~= "Mars" then
	return
end

local ChoGGi_Funcs = ChoGGi_Funcs
local next, type, tostring, table = next, type, tostring, table
local GetCursorWorldPos = GetCursorWorldPos
local T = T
local Translate = ChoGGi_Funcs.Common.Translate
local GetActiveRealm = GetActiveRealm

local MsgPopup = ChoGGi_Funcs.Common.MsgPopup
local RetName = ChoGGi_Funcs.Common.RetName
local RetIcon = ChoGGi_Funcs.Common.RetIcon
local RetHint = ChoGGi_Funcs.Common.RetHint
local Random = ChoGGi_Funcs.Common.Random

function ChoGGi_Funcs.Menus.UseAllLoadingScreens_Toggle()
	local setting = not ChoGGi.UserSettings.AllLoadingScreens
	ChoGGi.UserSettings.AllLoadingScreens = setting

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(setting),
		T(302535920001737--[[Toggle Use All Loading Screens]])
	)

end

function ChoGGi_Funcs.Menus.InfopanelToolbarConstrain_Toggle()
	local setting = not ChoGGi.UserSettings.InfopanelToolbarConstrain
	ChoGGi.UserSettings.InfopanelToolbarConstrain = setting

	ChoGGi_Funcs.Common.InfopanelToolbarConstrain_Toggle(setting)

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(setting),
		T(302535920001665--[[Toggle Infopanel Toolbar Constrain]])
	)
end

function ChoGGi_Funcs.Menus.DeleteBushesTrees()
	local function CallBackFunc(answer)
		if answer then
			local realm = GetActiveRealm()
			realm:SuspendPassEdits("ChoGGi_Funcs.Menus.DeleteBushesTrees")
			realm:MapDelete("map", "VegetationBillboardObject")
			ChoGGi_Funcs.Common.UpdateGrowthThreads()
			realm:ResumePassEdits("ChoGGi_Funcs.Menus.DeleteBushesTrees")
		end
	end
	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. T(302535920001258--[[Cleans your Mars of alien shrubbery.]]),
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " .. T(302535920000855--[[Last chance before deletion!]])
	)
end

function ChoGGi_Funcs.Menus.VerticalCheatMenu_Toggle()
	local setting = not ChoGGi.UserSettings.VerticalCheatMenu
	ChoGGi.UserSettings.VerticalCheatMenu = setting

	ChoGGi_Funcs.Common.VerticalCheatMenu_Toggle(setting)

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(setting),
		T(302535920001660--[[Toggle Vertical Cheat Menu]])
	)
end

function ChoGGi_Funcs.Menus.SelectionPanelResize_Toggle()
	ChoGGi.UserSettings.StopSelectionPanelResize = not ChoGGi.UserSettings.StopSelectionPanelResize

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.StopSelectionPanelResize),
		T(302535920001653--[[Toggle Selection Panel Resize]])
	)
end

function ChoGGi_Funcs.Menus.ScrollSelectionPanel_Toggle()
	ChoGGi.UserSettings.ScrollSelectionPanel = not ChoGGi.UserSettings.ScrollSelectionPanel

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.ScrollSelectionPanel),
		T(302535920001655--[[Toggle Scroll Selection Panel]])
	)
end

function ChoGGi_Funcs.Menus.UnlockOverview_Toggle()
	ChoGGi.UserSettings.UnlockOverview = not ChoGGi.UserSettings.UnlockOverview

	ActiveMapData.IsAllowedToEnterOverview = ChoGGi.UserSettings.UnlockOverview

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.UnlockOverview),
		T(302535920001651--[[Unlock Overview]])
	)
end

function ChoGGi_Funcs.Menus.SetTimeFactor()
	local item_list = {
		{text = Translate(1000121--[[Default]]) .. ": " .. 1000, value = 1000},
		{text = 0, value = 0, hint = T(6869--[[Pause]])},
		{text = 100, value = 100},
		{text = 150, value = 150},
		{text = 250, value = 250},
		{text = 500, value = 500},
		{text = 1000, value = 1000, hint = T(4020--[[Play at normal speed.]])},
		{text = 2500, value = 2500},
		{text = 3000, value = 3000, hint = T(4023--[[Play at three times normal speed.]])},
		{text = 5000, value = 5000, hint = T(4025--[[Play at five times normal speed.]])},
		{text = 10000, value = 10000},
		{text = 25000, value = 25000},
		{text = 100000, value = 100000},
	}

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		local value = choice.value
		if type(value) == "number" and value > -1 then
			-- making the time factor neg = inf loop

			SetTimeFactor(value)

			MsgPopup(
				choice.text,
				T(302535920000356--[[Time Factor]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000356--[[Time Factor]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. GetTimeFactor(),
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.ShowAutoUnpinObjectList()

	local item_list = {
		{text = Translate(547--[[Colonists]]), value = "Colonist"},
		{text = Translate(1120--[[Space Elevator]]), value = "SpaceElevator"},
		{text = Translate(3518--[[Drone Hub]]), value = "DroneHub"},
		{text = Translate(1685--[[Rocket]]), value = "SupplyRocket"},

		{text = Translate(5017--[[Basic Dome]]), value = "DomeBasic"},
		{text = Translate(5146--[[Medium Dome]]), value = "DomeMedium"},
		{text = Translate(5152--[[Mega Dome]]), value = "DomeMega"},
		{text = Translate(5188--[[Oval Dome]]), value = "DomeOval"},
		{text = Translate(5093--[[Geoscape Dome]]), value = "GeoscapeDome"},
		{text = Translate(9000--[[Micro Dome]]), value = "DomeMicro"},
		{text = Translate(9003--[[Trigon Dome]]), value = "DomeTrigon"},
		{text = Translate(9009--[[Mega Trigon Dome]]), value = "DomeMegaTrigon"},
		{text = Translate(9012--[[Diamond Dome]]), value = "DomeDiamond"},
		{text = Translate(302535920000347--[[Star Dome]]), value = "DomeStar"},
		{text = Translate(302535920000351--[[Hexa Dome]]), value = "DomeHexa"},
	}
	local c = #item_list

	-- build list with .
	local g_Classes = g_Classes
	for key,value in pairs(g_Classes) do
		-- It adds them all and i just check .class
		if value.pin_on_start and key ~= "BaseRover" and key ~= "SpaceElevator" then
			c = c + 1
			item_list[c] = {
				text = value.display_name and T(value.display_name) or key,
				value = key,
				icon = value.display_icon,
			}
		end
	end

	local UserSettings = ChoGGi.UserSettings
	UserSettings.UnpinObjects = UserSettings.UnpinObjects or {}

	-- add hints to enabled
	for i = 1, #item_list do
		local item = item_list[i]
		if UserSettings.UnpinObjects[item] then
			item.hint = T(12227--[[Enabled]])
		end
	end

	local function CallBackFunc(choices)
		if choices.nothing_selected then
			return
		end
		local checks = choices[1]

		local pins = UserSettings.UnpinObjects
		if checks.check1 then
			for i = 1, #choices do
				pins[choices[i].value] = true
			end
		elseif checks.check2 then
			for i = 1, #choices do
				pins[choices[i].value] = nil
			end
		end

		--if it's empty then remove setting
		if not next(UserSettings.UnpinObjects) then
			UserSettings.UnpinObjects = nil
		end
		ChoGGi_Funcs.Settings.WriteSettings()
		MsgPopup(
			Translate(302535920001093--[[Toggled: %s pinnable objects.]]):format(#choices),
			T(302535920000686--[[Auto Unpin Objects]])
		)
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000686--[[Auto Unpin Objects]]),
		hint = T(302535920001097--[[Enter a class name (SelectedObj.class) to add a custom entry.]]),
		multisel = true,
		sortby = "value",
		checkboxes = {
			at_least_one = true,
			only_one = true,
			{
				title = T(302535920001098--[[Add to list]]),
				hint = T(302535920001099--[[Add these items to the unpin list.]]),
				checked = true,
			},
			{
				title = T(302535920001100--[[Remove from list]]),
				hint = T(302535920001101--[[Remove these items from the unpin list.]]),
			},
		},
	}
end

--~ 	SetTimeFactor(1000) = normal speed
-- use GetTimeFactor() to check time for changing it so it can be paused?
function ChoGGi_Funcs.Menus.SetGameSpeed()
	local speeds = {
		[3] = 	Translate(1000121--[[Default]]),
		[6] = 	Translate(302535920001126--[[Double]]),
		[9] = 	Translate(302535920001127--[[Triple]]),
		[12] = 	Translate(302535920001128--[[Quadruple]]),
		[24] = 	Translate(302535920001129--[[Octuple]]),
		[48] = 	Translate(302535920001130--[[Sexdecuple]]),
		[96] = 	Translate(302535920001131--[[Duotriguple]]),
		[192] = Translate(302535920001132--[[Quattuorsexaguple]]),
		[300] = Translate(302535920000483--[[Centuple]]),

		[750] = Translate(0000, "*250"),
		[1500] = Translate(0000, "*500"),
		[3000] = Translate(0000, "*1000"),
		[15000] = Translate(0000, "*5000"),
	}

	local hint_str = Translate(302535920000523--[[How many to multiple the default speed by: <color 0 200 0>%s</color>]])
	local item_list = {
		{text = speeds[3], value = 1, hint = hint_str:format(1)},
		{text = speeds[6], value = 2, hint = hint_str:format(2)},
		{text = speeds[9], value = 3, hint = hint_str:format(3)},
		{text = speeds[12], value = 4, hint = hint_str:format(4)},
		{text = speeds[24], value = 8, hint = hint_str:format(8)},
		{text = speeds[48], value = 16, hint = hint_str:format(16)},
		{text = speeds[96], value = 32, hint = hint_str:format(32)},
		{text = speeds[192], value = 64, hint = hint_str:format(64)},
		{text = speeds[300], value = 100, hint = hint_str:format(100)},

		{text = speeds[750], value = 250, hint = hint_str:format(250)},
		{text = speeds[1500], value = 500, hint = hint_str:format(500)},
		{text = speeds[3000], value = 1000, hint = hint_str:format(1000)},
		{text = speeds[15000], value = 5000, hint = hint_str:format(5000)},
	}

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		local value = choice[1].value
		if type(value) == "number" then
			local const = const
			ChoGGi_Funcs.Common.SetSavedConstSetting("mediumGameSpeed", value)
			ChoGGi_Funcs.Common.SetSavedConstSetting("fastGameSpeed", value)

			-- update values that are checked when speed is changed
			const.mediumGameSpeed = ChoGGi.Consts.mediumGameSpeed * value
			const.fastGameSpeed = ChoGGi.Consts.fastGameSpeed * value
			-- so it changes the speed immediately
			if UISpeedState == "pause" then
				ChangeGameSpeedState(1)
				ChangeGameSpeedState(-1)
			else
				ChangeGameSpeedState(-1)
				ChangeGameSpeedState(1)
			end

			-- update saved settings
			if const.mediumGameSpeed == ChoGGi.Consts.mediumGameSpeed then
				ChoGGi.UserSettings.mediumGameSpeed = nil
				ChoGGi.UserSettings.fastGameSpeed = nil
			else
				ChoGGi.UserSettings.mediumGameSpeed = const.mediumGameSpeed
				ChoGGi.UserSettings.fastGameSpeed = const.fastGameSpeed
			end

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				Translate(302535920001135--[[%s: Excusa! Esta too mucho rapido for the eyes to follow? I'll show you in el slow motiono.]]):format(choice[1].text),
				T(5505--[[Game Speed]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(5505--[[Game Speed]]),
		hint = T{302535920000933--[["Current speed: <color ChoGGi_green><str></color>"]],
			str = speeds[const.mediumGameSpeed],
		} .. "\n" .. T{302535920001134--[["<str1> = base number <color ChoGGi_green><str2></color> multipled by custom value amount."]],
				str1 = T(302535920000078--[[Custom Value]]),
				str2 = const.mediumGameSpeed,
			},
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.ChangeLightmodelList(action)
	if not action then
		return
	end

	local setting_func = action.setting_func
	local setting_title = action.setting_title

	local item_list = {}
	local c = 0

	local LightmodelLists = LightmodelLists
	for key in pairs(LightmodelLists) do
		if key == "TheMartian" then
			c = c + 1
			item_list[c] = {text = " " .. key, value = key, hint = T(1000121--[[Default]])}
		elseif key ~= "*" then
			c = c + 1
			item_list[c] = {text = key, value = key}
		end
	end
	-- only disaster can be false
	if setting_title == T(302535920001625--[[List Disaster]]) then
		c = c + 1
		item_list[c] = {text = " " .. T(302535920001084--[[Reset]]), value = false}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		if type(choice.value) == "string" or choice.value == false then
			setting_func(choice.value)

			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(choice.text),
				setting_title
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = setting_title,
		hint = T(302535920001627--[[This is only visual; this won't affect the game state (unless something uses the list to check).]])
			.. "\n\n" .. T(302535920000106--[[Current]]) .. ": " .. tostring(GetCurrentLightmodelList()),
		custom_type = 6,
		custom_func = function(value)
			if type(value) == "string" then
				setting_func(value)
			end
		end,
	}
end

function ChoGGi_Funcs.Menus.ReloadMap()
	local function CallBackFunc(answer)
		if answer then
			ReloadMap()
		end
	end

	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. ": " .. T(302535920001488--[[Reloads map as new game.]]),
		CallBackFunc,
		T(302535920001487--[[Reload Map]])
	)
end

function ChoGGi_Funcs.Menus.GUIDockSide_Toggle()
	local XTemplates = XTemplates

	if ChoGGi.UserSettings.GUIDockSide then
		ChoGGi.UserSettings.GUIDockSide = false
		-- command center and such
		XTemplates.NewOverlayDlg[1].Dock = "left"
		-- save/load screens
		XTemplates.SaveLoadContentWindow[1].Dock = "left"
		ChoGGi_Funcs.Common.SetTableValue(XTemplates.SaveLoadContentWindow[1], "Dock", "right", "Dock", "left")
		-- photomode
		XTemplates.PhotoMode[1].Dock = "left"
	else
		ChoGGi.UserSettings.GUIDockSide = true
		XTemplates.NewOverlayDlg[1].Dock = "right"
		XTemplates.SaveLoadContentWindow[1].Dock = "right"
		ChoGGi_Funcs.Common.SetTableValue(XTemplates.SaveLoadContentWindow[1], "Dock", "left", "Dock", "right")
		XTemplates.PhotoMode[1].Dock = "right"
	end

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi.UserSettings.GUIDockSide and T(302535920001715--[[Right]]) or T(302535920001716--[[Left]]),
		T(302535920001412--[[GUI Dock Side]])
	)
end

function ChoGGi_Funcs.Menus.ShowHints_Toggle()
	local mapdata = ActiveMapData

	if ChoGGi.UserSettings.DisableHints then
		ChoGGi.UserSettings.DisableHints = false
		mapdata.DisableHints = false
		HintsEnabled = true
	else
		ChoGGi.UserSettings.DisableHints = true
		mapdata.DisableHints = true
		HintsEnabled = false
	end

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.DisableHints),
		T(302535920000670--[[Toggle Show Hints]])
	)
end

function ChoGGi_Funcs.Menus.OnScreenHints_Reset()
	g_ShownOnScreenHints = {}
	UpdateOnScreenHintDlg()
	MsgPopup(
		"true",
		T(302535920000668--[[Reset on-screen hints]])
	)
end

function ChoGGi_Funcs.Menus.OnScreenHints_Toggle()
	HintsEnabled = not HintsEnabled
	SetHintNotificationsEnabled(HintsEnabled)
	ActiveMapData.DisableHints = not HintsEnabled
	UpdateOnScreenHintDlg()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(HintsEnabled),
		T(302535920000666--[[Toggle on-screen hints]])
	)
end

function ChoGGi_Funcs.Menus.ShowInterfaceInScreenshots_Toggle()
	hr.InterfaceInScreenshot = hr.InterfaceInScreenshot ~= 0 and 0 or 1
	-- needs default
	ChoGGi.UserSettings.ShowInterfaceInScreenshots = not ChoGGi.UserSettings.ShowInterfaceInScreenshots

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.ShowInterfaceInScreenshots),
		T(302535920000661--[[Show Interface in Screenshots]])
	)
end

function ChoGGi_Funcs.Menus.TakeScreenshot(action)
	if not action then
		return
	end

	local which = action.setting_mask

	CreateRealTimeThread(function()
		local filename, created
		if which == 1 then
				WaitNextFrame(3)
				LockCamera("Screenshot")
				filename = ChoGGi_Funcs.Common.GenerateScreenshotFilename("SSAA", "AppData/", "tga")
				MovieWriteScreenshot(filename, 0, 64, false)
				UnlockCamera("Screenshot")
		else
			filename = ChoGGi_Funcs.Common.GenerateScreenshotFilename("SS", "AppData/", "tga")
			created = WriteScreenshot(filename)
		end

		-- MovieWriteScreenshot doesn't return jack, so
		if created or which == 1 then
			-- slight delay so it doesn't show up in the screenshot
			WaitMsg("OnRender")
			local msg = ConvertToOSPath(filename)
			print("TakeScreenshot:", msg)
			MsgPopup(
				msg,
				T(302535920000657--[[Screenshot]])
			)
		end
	end)
end

function ChoGGi_Funcs.Menus.MapEdgeLimit_Toggle()
	if ChoGGi.UserSettings.MapEdgeLimit then
		ChoGGi.UserSettings.MapEdgeLimit = false
		hr.CameraRTSBorderAtMinZoom = -1000
		hr.CameraRTSBorderAtMaxZoom = -1000
	else
		ChoGGi.UserSettings.MapEdgeLimit = true
		hr.CameraRTSBorderAtMinZoom = 1000
		hr.CameraRTSBorderAtMaxZoom = 1000
	end

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.MapEdgeLimit),
		T(302535920001489--[[Toggle Map Edge Limit]])
	)
end

function ChoGGi_Funcs.Menus.ResetCamera()
	SetMouseDeltaMode(false)
	cameraRTS.Activate(1)
	engineShowMouseCursor()
	ChoGGi_Funcs.Common.SetCameraSettings()
end

function ChoGGi_Funcs.Menus.WhiterRocks()
	-- less brown rocks
	local realm = GetActiveRealm()
	realm:SuspendPassEdits("ChoGGi_Funcs.Menus.WhiterRocks")
	local white = white
	realm:MapForEach("map", {"Deposition", "WasteRockObstructorSmall", "WasteRockObstructor", "StoneSmall"}, function(o)
		if o.class:find("Dark") then
			o:SetColorModifier(white)
		end
	end)
	realm:ResumePassEdits("ChoGGi_Funcs.Menus.WhiterRocks")
end

function ChoGGi_Funcs.Menus.SetObjectOpacity()
	if not MainCity then
		return
	end

	local obj = ChoGGi_Funcs.Common.SelObject()

	local item_list = {
		{text = Translate(302535920001084--[[Reset]]) .. ": " .. Translate(3984--[[Anomalies]]), value = "Anomaly", hint = T{302535920001109--[["Loops though and makes all <color ChoGGi_green><str></color> visible."]],
				str = T(3984--[[Anomalies]]),
		}},
		{text = Translate(302535920001084--[[Reset]]) .. ": " .. Translate(3980--[[Buildings]]), value = "Building", hint = T{302535920001109--[[snipped]],
				str = T(3980--[[Buildings]]),
		}},
		{text = Translate(302535920001084--[[Reset]]) .. ": " .. Translate(302535920000157--[[Cables & Pipes]]), value = "GridElements", hint = T{302535920001109--[[snipped]],
				str = T(302535920000157--[[Cables & Pipes]]),
		}},
		{text = Translate(302535920001084--[[Reset]]) .. ": " .. Translate(547--[[Colonists]]), value = "Colonists", hint = T{302535920001109--[[snipped]],
				str = T(547--[[Colonists]]),
		}},
		{text = Translate(302535920001084--[[Reset]]) .. ": " .. Translate(5438--[[Rovers]]) .. " & " .. Translate(517--[[Drones]]), value = "Unit", hint = T{302535920001109--[[snipped]],
				str = T(5438--[[Rovers]]) .. " & " .. T(517--[[Drones]]),
		}},
		{text = Translate(302535920001084--[[Reset]]) .. ": " .. Translate(3982--[[Deposits]]), value = "SurfaceDeposit", hint = T{302535920001109--[[snipped]],
				str = T(3982--[[Deposits]]),
		}},
	}

	local c = #item_list
	if obj then
		c = c + 1
		item_list[c] = {text = 0, value = 0}
		c = c + 1
		item_list[c] = {text = 50, value = 50}
		c = c + 1
		item_list[c] = {text = 75, value = 75}
		c = c + 1
		item_list[c] = {text = 100, value = 100}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		local value = choice.value
		if type(value) == "number" then
			obj:SetOpacity(value)
		elseif type(value) == "string" then
			local function SettingOpacity(label)
				local objs = ChoGGi_Funcs.Common.MapGet(label)
				for i = 1, #objs do
					objs[i]:SetOpacity(100)
				end
			end
			SettingOpacity(value)
			-- extra ones
			if value == "Building" then
				SettingOpacity("AllRockets")
			elseif value == "Anomaly" then
				SettingOpacity("SubsurfaceAnomalyMarker")
			elseif value == "SurfaceDeposit" then
				SettingOpacity("SubsurfaceDeposit")
				SettingOpacity("TerrainDeposit")
			end
		end
		MsgPopup(
			ChoGGi_Funcs.Common.SettingState(choice.text),
			T(302535920000694--[[Set Opacity]])
		)
	end
	local hint = T(302535920001118--[[You can still select items after making them invisible (0), but it may take some effort :).]])
	if obj then
		hint = T(302535920000106--[[Current]]) .. ": " .. obj:GetOpacity() .. "\n\n" .. hint
	end

	local name = RetName(obj)
	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000694--[[Set Opacity]]) .. (name ~= "nil" and ": " .. name or ""),
		hint = hint,
		skip_sort = true,
		skip_icons = true,
	}
end

do -- ListAllObjects
	local IsValid = IsValid
	local CmpLower = CmpLower
	local function ViewAndSelectObject(choice)
		if choice.nothing_selected then
			return
		end
		ViewObjectMars(choice[1].obj)
		SelectObj(choice[1].obj)
	end

	local function BuildItemList_Class(value)
		local handles = {}

		-- build our list of objects (we use an ass table of handles to skip dupes)
		if value == T(302535920000306--[[Everything]]) then
			local labels = UICity.labels or empty_table
			for id, label in pairs(labels) do
				if id ~= "Consts" then
					for i = 1, #label do
						local obj = label[i]
						if IsValid(obj) and not handles[obj.handle] then
							handles[obj.handle] = obj
						end
					end
				end
			end
		else
			-- don't need to dupe skip these, but I'm lazy and it's quick enough
			local labels = UICity.labels[value] or ""
			for i = 1, #labels do
				local obj = labels[i]
				if IsValid(obj) and not handles[obj.handle] then
					handles[obj.handle] = obj
				end
			end
		end

		-- and build the ass table into an idx one
		local item_list = {}
		local c = 0
		for _, obj in pairs(handles) do
			local name = RetName(obj)
			local class = obj.class
			if name ~= class then
				name = class .. ": " .. name
			end
			local icon, icon_scale = RetIcon(obj)
			c = c + 1
			item_list[c] = {
				text = name,
				value = tostring(obj:GetVisualPos()),
				obj = obj,
				hint = RetHint(obj),
				icon = icon,
				icon_scale = icon_scale,
			}
		end
		return item_list
	end

	local function CallBackFunc_List(choice)
		if choice.nothing_selected then
			return
		end
		local value = choice[1].value
		local item_list = BuildItemList_Class(value)

		-- and display them
		ChoGGi_Funcs.Common.OpenInListChoice{
			callback = ViewAndSelectObject,
			items = item_list,
			title = T(302535920001292--[[List All Objects]]) .. ": " .. value,
			custom_type = 1,
			checkboxes = {
				{
					title = T(302535920001687--[[Refresh]]),
					hint = T(302535920000548--[[List is updated each time you click this.]]),
					func = function(dlg)
						item_list = BuildItemList_Class(value)
						table.sort(item_list, function(a, b)
							return CmpLower(a.text, b.text)
						end)

						dlg.items = item_list
						dlg:BuildList(true)
					end,
				},
			},
		}
	end

	local function BuildItemList_All()
		local item_list = {
			{
			text = " " .. T(302535920000306--[[Everything]]),
			value = T(302535920000306--[[Everything]]), hint = T(302535920001294--[[Laggy]]),
			},
		}
		local c = #item_list
		local labels = UICity.labels or empty_table
		for label, list in pairs(labels) do
			if label ~= "Consts" and #list > 0 then
				local item = list[1]
				local icon, icon_scale = RetIcon(item)
				c = c + 1
				item_list[c] = {
					text = label .. ": " .. #list,
					value = label,
					hint = RetHint(item),
					icon = icon,
					icon_scale = icon_scale,
				}
			end
		end
		return item_list
	end

	function ChoGGi_Funcs.Menus.ListAllObjects()
		if not MainCity then
			return
		end

		local item_list = BuildItemList_All()

		ChoGGi_Funcs.Common.OpenInListChoice{
			callback = CallBackFunc_List,
			items = item_list,
			title = T(302535920001292--[[List All Objects]]),
			custom_type = 1,
			height = 800,
			checkboxes = {
				{
					title = T(302535920001687--[[Refresh]]),
					hint = T(302535920000548--[[List is updated each time you click this.]]),
					func = function(dlg)
						item_list = BuildItemList_All()
						table.sort(item_list, function(a, b)
							return CmpLower(a.text, b.text)
						end)

						dlg.items = item_list
						dlg:BuildList(true)
					end,
				},
			},
		}
	end
end -- do

function ChoGGi_Funcs.Menus.DisableTextureCompression_Toggle()
	ChoGGi.UserSettings.DisableTextureCompression = ChoGGi_Funcs.Common.ToggleValue(ChoGGi.UserSettings.DisableTextureCompression)
	hr.TR_ToggleTextureCompression = 1

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.DisableTextureCompression),
		T(302535920000641--[[Disable Texture Compression]])
	)
end

do -- FlattenGround
	local ToggleCollisions = ChoGGi_Funcs.Common.ToggleCollisions
	local Sleep = Sleep
	local guic = guic
	local white = white

	local are_we_flattening
	local visual_circle
	local flatten_height
	local size
	local radius

	local temp_height
	local function ToggleHotkeys(bool)
		if bool then
			local us = ChoGGi.UserSettings
			local XAction = XAction
			local XShortcutsTarget = XShortcutsTarget

			XShortcutsTarget:AddAction(XAction:new{
				ActionId = "ChoGGi_FlattenGround_RaiseHeight",
				OnAction = function()
					temp_height = flatten_height + us.FlattenGround_HeightDiff or 100
					-- guess i found the ceiling limit
					if temp_height > 65535 then
						temp_height = 65535
					end
					flatten_height = temp_height
				end,
				ActionShortcut = "Shift-Up",
			})
			XShortcutsTarget:AddAction(XAction:new{
				ActionId = "ChoGGi_FlattenGround_LowerHeight",
				OnAction = function()
					temp_height = flatten_height - (us.FlattenGround_HeightDiff or 100)
					-- and the floor limit (oh look 0 go figure)
					if temp_height < 0 then
						temp_height = 0
					end
					flatten_height = temp_height
				end,
				ActionShortcut = "Shift-Down",
			})
			XShortcutsTarget:AddAction(XAction:new{
				ActionId = "ChoGGi_FlattenGround_WidenRadius",
				OnAction = function()
					us.FlattenGround_Radius = (us.FlattenGround_Radius or 2500) + (us.FlattenGround_RadiusDiff or 100)
					size = us.FlattenGround_Radius
					visual_circle:SetRadius(size)
					radius = size * guic
				end,
				ActionShortcut = "Shift-Right",
			})
			XShortcutsTarget:AddAction(XAction:new{
				ActionId = "ChoGGi_FlattenGround_ShrinkRadius",
				OnAction = function()
					us.FlattenGround_Radius = (us.FlattenGround_Radius or 2500) - (us.FlattenGround_RadiusDiff or 100)
					size = us.FlattenGround_Radius
					visual_circle:SetRadius(size)
					radius = size * guic
				end,
				ActionShortcut = "Shift-Left",
			})
		else
			ReloadShortcuts()
		end
	end

	function ChoGGi_Funcs.Menus.FlattenTerrain_Toggle(square)
		if are_we_flattening then
			-- disable shift-arrow keys
			ToggleHotkeys()
			DeleteThread(are_we_flattening)
			are_we_flattening = false
			visual_circle:delete()
			-- update saved settings (from hotkeys)
			ChoGGi_Funcs.Settings.WriteSettings()

			MsgPopup(
				T(302535920001164--[[Flattening has been stopped, now updating buildable.]]),
				T(302535920000485--[[Terrain Flatten Toggle]])
			)
			-- disable collisions on pipes beforehand, so they don't get marked as uneven terrain
			ToggleCollisions("LifeSupportGridElement")
--~ 			-- update uneven terrain checker thingy
--~ 			ActiveGameMap:RefreshBuildableGrid()
			-- and back on when we're done
			ToggleCollisions("LifeSupportGridElement")

		else
			-- have to set it here after settings are loaded or it'll be default radius till user adjusts it
			size = ChoGGi.UserSettings.FlattenGround_Radius or 2500
			radius = size * guic

			ToggleHotkeys(true)
			flatten_height = ActiveGameMap.terrain:GetHeight(GetCursorWorldPos())
			MsgPopup(
				Translate(302535920001163--[[Flatten height has been choosen %s, press shortcut again to update buildable.]]):format(flatten_height),
				T(302535920000485--[[Terrain Flatten Toggle]])
			)
			visual_circle = Circle:new()
			visual_circle:SetRadius(size)
			visual_circle:SetColor(white)

			local terrain = ActiveGameMap.terrain
--~ 			local terrain_type_idx = GetTerrainTextureIndex("Grass_02")
			are_we_flattening = CreateRealTimeThread(function()
				-- thread gets deleted, but just in case
				local hsDefault = const.hsDefault
				while are_we_flattening do
					local cursor = GetCursorWorldPos()
					visual_circle:SetPos(cursor)
					local outer
					if square == true then
						outer = radius / 2
					end

					terrain:SetHeightCircle(cursor, radius, outer or radius, flatten_height, hsDefault)
--~ 					terrain:SetTypeCircle(cursor, radius, terrain_type_idx)
					-- used to set terrain type (see above)
					Sleep(10)
				end
			end)
		end
	end

end

--~ -- we'll get more concrete one of these days
--~ local terrain_type_idx = GetTerrainTextureIndex("Regolith")
--~ ActiveGameMap.terrain:SetTypeCircle(GetCursorWorldPos(), 5000, terrain_type_idx)
function ChoGGi_Funcs.Menus.ChangeMap()
	local lookup_table = {
		[Translate(3474--[[Mission Sponsor]])] = "idMissionSponsor",
		[Translate(3478--[[Commander Profile]])] = "idCommanderProfile",
		[Translate(3486--[[Mystery]])] = "idMystery",
		[Translate(3482--[[Colony Logo]])] = "idMissionLogo",
		ResPreset_Concrete = "ResPreset_Concrete",
		ResPreset_Metals = "ResPreset_Metals",
		ResPreset_Polymers = "ResPreset_Polymers",
		ResPreset_PreciousMetals = "ResPreset_PreciousMetals",
		ResPreset_Water = "ResPreset_Water",
		Map = "Map",
--~ 		ResTag_Concrete = "ResTag_Concrete",
--~ 		ResTag_Metals = "ResTag_Metals",
--~ 		ResTag_Polymers = "ResTag_Polymers",
--~ 		ResTag_PreciousMetals = "ResTag_PreciousMetals",
--~ 		ResTag_Water = "ResTag_Water",
	}
	local custom_params = {
		idGameRules = {},
	}

	-- open a list dialog to set g_CurrentMissionParams
	local itemlist = {
		{text = "Map", value = "BlankBig_01"},
		{text = Translate(3474--[[Mission Sponsor]]), value = "IMM", hint = T{302535920001386--[["Can be changed after in <str1>><str2>><str3>."]],
			str1 = T(302535920000002--[[ECM]]),
			str2 = T(1635--[[Mission]]),
			str3 = T(302535920000712--[[Set Sponsor]]),
		}},
		{text = Translate(3478--[[Commander Profile]]), value = "rocketscientist", hint = T{302535920001386--[[snipped]],
			str1 = T(302535920000002--[[ECM]]),
			str2 = T(1635--[[Mission]]),
			str3 = T(302535920000716--[[Set Commander]]),
		}},
		{text = Translate(3486--[[Mystery]]), value = "random", hint = T{302535920001386--[[snipped]],
			str1 = T(27--[[Cheats]]),
			str2 = T(302535920000331--[[Mystery Start]]),
			str3 = "",
		}},
		{text = Translate(3482--[[Colony Logo]]), value = "MarsExpress", hint = T{302535920001386--[[snipped]],
			str1 = T(302535920000002--[[ECM]]),
			str2 = T(1635--[[Mission]]),
			str3 = T(302535920000710--[[Change Logo]]),
		}},
		{text = Translate(8800--[[Game Rules]]), value = "", hint = T(302535920000803--[[For rules separate with spaces: Hunger ColonyPrefab (or leave blank for none).]])},
		{text = "ResPreset_Concrete", value = ""},
		{text = "ResPreset_Metals", value = ""},
		{text = "ResPreset_Polymers", value = ""},
		{text = "ResPreset_PreciousMetals", value = ""},
		{text = "ResPreset_Water", value = ""},
		-- not sure what the difference between the two is, so it sets both
--~ 		{text = "ResTag_Concrete", value = ""},
--~ 		{text = "ResTag_Metals", value = ""},
--~ 		{text = "ResTag_Polymers", value = ""},
--~ 		{text = "ResTag_PreciousMetals", value = ""},
--~ 		{text = "ResTag_Water", value = ""},
	}

	-- shows the mission param info for people to look at

	local MapData = MapDataPresets

	local info_lists = {
		[-1] = T(302535920001385--[[Use these lists to find the correct ids.]]),
		table.icopy(MissionParams.idCommanderProfile.items),
		table.icopy(MissionParams.idMissionSponsor.items),
		table.icopy(MissionParams.idMissionLogo.items),
		table.icopy(MissionParams.idGameRules.items),
		table.icopy(MissionParams.idMystery.items),
		table.icopy(DataInstances.ResourcePreset),
		MapData,
	}
	info_lists[1].name = T(3478--[[Commander Profile]])
	info_lists[2].name = T(3474--[[Mission Sponsor]])
	info_lists[3].name = T(3482--[[Colony Logo]])
	info_lists[4].name = T(8800--[[Game Rules]])
	info_lists[5].name = T(3486--[[Mystery]])
	info_lists[6].name = T(692--[[Resources]])
	info_lists[6].name = T(3996--[[Map Overview]])

	local dlg_has_params = OpenExamineReturn(info_lists, {
		has_params = true,
		override_title = true,
		title = T(302535920001717--[[Info]]) .. ": " .. T(10892--[[MISSION PARAMETERS]]),
	})

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		for i = 1, #choice do
			local text = choice[i].text
			local value = choice[i].value

			-- only game rules needs something something, the rest can use the lookup_table
			if text == T(8800--[[Game Rules]]) then
				-- If more than one entry
				if value:find(" ") then
					for i in value:gmatch("%S+") do
						custom_params.idGameRules[i] = true
					end
				-- just the one
				elseif value ~= "" then
					custom_params.idGameRules[value] = true
				end
			else
				custom_params[lookup_table[text]] = value
			end
		end

		-- close dialogs we opened
		dlg_has_params:Close()
		-- close any ex opened from has_params
		ChoGGi_Funcs.Common.CloseChildExamineDlgs(dlg_has_params)

		-- cleans out missions params
		InitNewGameMissionParams()
		-- rocket name
		GenerateRandomMapParams()

		-- select new MissionParams
		g_CurrentMissionParams.idMissionSponsor = custom_params.idMissionSponsor or "IMM"
		g_CurrentMissionParams.idCommanderProfile = custom_params.idCommanderProfile or "rocketscientist"
		g_CurrentMissionParams.idMystery = custom_params.idMystery or "random"
		g_CurrentMissionParams.idMissionLogo = custom_params.idMissionLogo or "MarsExpress"
		g_CurrentMissionParams.idGameRules = custom_params.idGameRules or {}
		g_CurrentMissionParams.GameSessionID = srp.random_encode64(96)

		-- this is a mostly copy of GenerateCurrentRandomMap()
		-- .rand returns 1+ args, and we just want the first one (or it screws up GetModifiedProperties)
		local rand_props = table.rand(DataInstances.RandomMapPreset)
		local props = GetModifiedProperties(rand_props)

		local gen = RandomMapGenerator:new()
		gen:SetProperties(props)
		FillRandomMapProps(gen)

		-- add any custom res values
		for key, value in pairs(custom_params) do
			if value ~= "" and key:sub(1, 10) == "ResPreset_" then
				gen[key] = value
				gen["ResTag_" .. key:sub(11)] = value
			end
		end

--~ if ChoGGi.testing then
--~ 	ex(gen)
--~ end
--~ gen.ResPreset_Concrete = "Concrete_VeryLow"
--~ gen.ResPreset_Metals = "Metals_VeryLow"
--~ gen.ResPreset_Polymers = "Polymers_VeryLow"
--~ gen.ResPreset_PreciousMetals = "PreciousMetals_VeryLow"
--~ gen.ResPreset_Water = "Water_VeryHigh"
--~ gen.ResTag_Concrete = "Concrete_VeryLow"
--~ gen.ResTag_Metals = "Metals_VeryLow"
--~ gen.ResTag_Polymers = "Polymers_VeryLow"
--~ gen.ResTag_PreciousMetals = "PreciousMetals_VeryLow"
--~ gen.ResTag_Water = "Water_VeryHigh"

--~ gen.ResPreset_Concrete = "Concrete_VeryHigh"
--~ gen.ResPreset_Metals = "Metals_VeryHigh"
--~ gen.ResPreset_Polymers = "Polymers_VeryHigh"
--~ gen.ResPreset_PreciousMetals = "PreciousMetals_VeryHigh"
--~ gen.ResPreset_Water = "Water_VeryLow"
--~ gen.ResTag_Concrete = "Concrete_VeryHigh"
--~ gen.ResTag_Metals = "Metals_VeryHigh"
--~ gen.ResTag_Polymers = "Polymers_VeryHigh"
--~ gen.ResTag_PreciousMetals = "PreciousMetals_VeryHigh"
--~ gen.ResTag_Water = "Water_VeryLow"

		-- add the name of map we want
		gen.BlankMap = custom_params.Map
		-- generates/loads map
		gen:Generate()
		-- update local store
		LocalStorage.last_map = custom_params.Map
		SaveLocalStorage()

	end

	local dlg_list_MissionParams = ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = itemlist,
		title = T(302535920000868--[[Choose Map]]),
		custom_type = 4,
	}

	dlg_list_MissionParams:SetPos(point(450, 75))
	dlg_has_params:SetPos(point(10, 75))
end

function ChoGGi_Funcs.Menus.PulsatingPins_Toggle()
	ChoGGi.UserSettings.DisablePulsatingPinsMotion = not ChoGGi.UserSettings.DisablePulsatingPinsMotion

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.DisablePulsatingPinsMotion),
		T(302535920000265--[[Toggle Pulsating Pins]])
	)
end

function ChoGGi_Funcs.Menus.TerrainTextureRemap()
	local TerrainTextures = TerrainTextures
	local GetTerrainTextureIndex = GetTerrainTextureIndex
	local hint_str = T{302535920000973--[["Change the value (-1) to an index number from Terrain Textures.
Open <color ChoGGi_green><str></color> to see all the textures, the tooltips show the texture index."]],
		str = T(302535920000623--[[Terrain Texture Change]]),
	}
	local item_list = {}
	local c = 0

	local used = ChoGGi_Funcs.Common.UsedTerrainTextures(true)
	for name, count in pairs(used) do
		local index = GetTerrainTextureIndex(name)
		local terrain = TerrainTextures[index]
		c = c + 1
		item_list[c] = {
			text = terrain.name,
			-- we could just leave this as the same index, but that means replacing a texture with the same texture (useless time waste)
			value = -1,
			count = count,
			index = index,
			icon = "<image " .. terrain.texture .. " 100>",
			hint = Translate(302535920001313--[[Amount used on map: %s]]):format(f)
				.. "\n" .. hint_str .. "\n\n\n<image " .. terrain.texture .. ">\n\n",
		}
	end

	local function CallBackFunc(choices)
		local map = {}
		for i = 1, #choices do
			local choice = choices[i]
			-- make sure it's a valid	terrain texture id
			if TerrainTextures[choice.value] then
				-- existing texture index id to new id
				map[choice.index] = choice.value
			end
		end
--~ 		ex(map)
		local realm = GetActiveRealm()
		realm:SuspendPassEdits("ChoGGi_Funcs.Menus.TerrainTextureRemap")
		ActiveGameMap.terrain:RemapType(map)
		realm:ResumePassEdits("ChoGGi_Funcs.Menus.TerrainTextureRemap")
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001237--[[Terrain Texture Remap]]),
		sortby = "count",
		hint = hint_str,

		-- can only make it 9 if i figure out a way to upload the index numbers
--~ 			custom_type = 9,
		custom_type = 4,
	}
end

function ChoGGi_Funcs.Menus.TerrainTextureChange()
	local function RestoreSkins(label, temp_skin, idx)
		for i = 1, #(label or "") do
			local o = label[i]
			-- If i don't set waste skins to the ground texture then it won't be the right texture for GetCurrentSkin
			-- got me
			if temp_skin then
				o.orig_terrain1 = idx
				o.orig_terrain2 = nil
--~ local _, terrain1, _, terrain2 = TerrainDeposit_CountTiles(o:GetBuildShape(), o:GetPos())
--~ orig_terrain1 = terrain1
--~ orig_terrain2 = terrain2

				o:ChangeSkin("Terrain" .. temp_skin)
			end
			o:ChangeSkin(o:GetCurrentSkin())
		end
	end

	local GridOpFree = GridOpFree
--~ 	local AsyncSetTypeGrid = AsyncSetTypeGrid
	local MulDivRound = MulDivRound
	local sqrt = sqrt

	local NoisePreset = DataInstances.NoisePreset
	local guim = guim

	local item_list = {}
	local TerrainTextures = TerrainTextures
	for i = 1, #TerrainTextures do
		local terrain = TerrainTextures[i]
		item_list[i] = {
			text = terrain.name,
			value = i,
			icon = "<image " .. terrain.texture .. " 100>",
			hint = "<image " .. terrain.texture .. ">\n\n",
		}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		if TerrainTextures[choice.value] then
			local gamemap = GameMaps[MainMapID]
			local terrain = gamemap.terrain

			gamemap.realm:SuspendPassEdits("ChoGGi_Funcs.Menus.TerrainTextureChange")
			terrain:SetTerrainType{type = choice.value}

			-- add back dome grass
			RestoreSkins(MainCity.labels.Dome)
			-- restore waste piles
			RestoreSkins(MainCity.labels.WasteRockDumpSite, choice.text, choice.value)

			-- re-build concrete marker textures
			local texture_idx1 = GetTerrainTextureIndex("Regolith") + 1
			local texture_idx2 = GetTerrainTextureIndex("Regolith_02") + 1

			local deposits = MainCity.labels.TerrainDeposit or ""
			for i = 1, #deposits do
				local d = deposits[i]
				if IsValid(d) then
					local pattern = NoisePreset.ConcreteForm:GetNoise(128, Random())
					pattern:land_i(NoisePreset.ConcreteNoise:GetNoise(128, Random()))
					-- any over 1000 get the more noticeable texture
					if d.max_amount > 1000000 then
						pattern:mul_i(texture_idx2, 1)
					else
						pattern:mul_i(texture_idx1, 1)
					end
					-- blend in with surrounding ground
					pattern:sub_i(1, 1)
					-- ?
					pattern = GridOpFree(pattern, "repack", 8)
					-- paint deposit
					terrain:SetTypeGrid{
--~ 					AsyncSetTypeGrid{
						type_grid = pattern,
						pos = d:GetPos(),
						scale = sqrt(MulDivRound(10000, d.max_amount / guim, d.radius_max)),
						centered = true,
						invalid_type = -1,
					}
				end
			end -- for

			gamemap.realm:ResumePassEdits("ChoGGi_Funcs.Menus.TerrainTextureChange")
		end -- If TerrainTextures

	end -- CallBackFunc


	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000623--[[Terrain Texture Change]]),
		hint = Translate(302535920000974--[[Map default: %s]]):format(ActiveMapData.BaseLayer),
		custom_type = 7,
	}
end

function ChoGGi_Funcs.Menus.ChangeLightmodel()
	local item_list = {}
	local c = 0

	local LightmodelPresets = LightmodelPresets
	for key in pairs(LightmodelPresets) do
		c = c + 1
		item_list[c] = {
			text = key,
			value = key,
		}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		local value = choice.value
		if type(value) == "string" then
			-- If perm isn't checked then remove the saved setting
			if not choice.check1 then
				ChoGGi.UserSettings.Lightmodel = nil
			end

			if choice.check1 then
				ChoGGi.UserSettings.Lightmodel = value
				SetLightmodelOverride(1, value)
			else
				SetLightmodelOverride(1)
				SetLightmodel(1, value)
			end

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(choice.text),
				T(911432559058, "Light model")
			)
		end
	end

	local hint = {
		T(302535920000987--[[If you used Permanent; you must choose default to remove the setting (or it'll set the lightmodel next time you start the game).]]),
	}
	c = #hint

	local lightmodel = ChoGGi.UserSettings.Lightmodel
	if lightmodel then
		c = c + 1
		hint[c] = T(302535920000988--[[Permanent]]) .. ": " .. lightmodel
	end

	c = c + 1
	hint[c] = T(302535920000991--[[Double right-click to preview lightmodel without closing dialog.]])

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(911432559058--[[Light model]]),
		hint = table.concat(hint, "\n\n"),
		custom_type = 6,
		custom_func = function(choice_value)
			SetLightmodelOverride(1)
			SetLightmodel(1,
				type(choice_value) == "string" and choice_value or choice_value[1].value
			)
		end,
		checkboxes = {
			{
				title = T(302535920000988--[[Permanent]]),
				hint = T(302535920000989--[[Make it stay at selected light model all the time (including reboots).]]),
			},
		},
	}
end

function ChoGGi_Funcs.Menus.TransparencyUI_Toggle()
	ChoGGi.UserSettings.TransparencyToggle = not ChoGGi.UserSettings.TransparencyToggle

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.TransparencyToggle),
		T(302535920000631--[[UI Transparency Mouseover]])
	)
end

do -- SetTransparencyUI
	local function GetTrans(cls)
		local t = ChoGGi.UserSettings.Transparency[cls]
		return t or 0
	end

	local function GetSetTrans(mask, cls, desk, igi, which)
		local name = ChoGGi.UserSettings.Transparency[cls]
		if not which and name then
			return name
		end

		local uilist
		if mask == 1 then
			uilist = desk
		else
			if not igi or not igi:GetVisible() then
				return 0
			end
			uilist = igi
		end

		for i = 1, #uilist do
			local ui = uilist[i]
			if ui:IsKindOf(cls) then
				if which then
					ui:SetTransparency(which)
				else
					return ui:GetTransparency()
				end
			end
		end
	end

	function ChoGGi_Funcs.Menus.SetTransparencyUI()
		local desk = terminal.desktop
		local igi = Dialogs.InGameInterface

		local menu_func = "XShortcutsHost"
		if what_game == "MarsR" or what_game == "JA3" then
			menu_func = "DeveloperInterface"
		end

		local item_list = {
			{text = "ConsoleLog", value = GetSetTrans(1, "ConsoleLog", desk, igi), hint = T(302535920000994--[[Console logging text]])},
			{text = "Console", value = GetSetTrans(1, "Console", desk, igi), hint = T(302535920000996--[[Console text input]])},
			{text = menu_func, value = GetSetTrans(1, menu_func, desk, igi), hint = T(302535920000998--[[Cheat Menu]])},

			{text = "HUD", value = GetSetTrans(2, "HUD", desk, igi), hint = T(302535920001000--[[Buttons at bottom]])},
			{text = "XBuildMenu", value = GetSetTrans(2, "XBuildMenu", desk, igi), hint = T(302535920000993--[[Build menu]])},
			{text = "InfopanelDlg", value = GetSetTrans(2, "InfopanelDlg", desk, igi), hint = T(302535920000995--[[Infopanel (selection)]])},
			{text = "PinsDlg", value = GetSetTrans(2, "PinsDlg", desk, igi), hint = T(302535920000997--[[Pins menu]])},

			{text = "XRolloverWindow", value = GetTrans("XRolloverWindow"), hint = T(302535920001679--[[Tool Tips]])},
		}

		local function CallBackFunc(choice)
			if choice.nothing_selected then
				return
			end
			for i = 1, #choice do
				local value = choice[i].value
				local text = choice[i].text

				if type(value) == "number" then

					if text ~= "XRolloverWindow" then
						if text == menu_func or text == "Console" or text == "ConsoleLog" then
							GetSetTrans(1, text, desk, igi, value)
						else
							GetSetTrans(2, text, desk, igi, value)
						end
					end

					if value == 0 then
						ChoGGi.UserSettings.Transparency[text] = nil
					else
						ChoGGi.UserSettings.Transparency[text] = value
					end

				end
			end

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				T(302535920000999--[[Transparency has been updated.]]),
				T(302535920000629--[[UI Transparency]])
			)
		end

		ChoGGi_Funcs.Common.OpenInListChoice{
			callback = CallBackFunc,
			items = item_list,
			title = T(302535920000629--[[Set UI Transparency]]),
			hint = T(302535920001002--[["For some reason they went opposite day with this one: 255 is invisible and 0 is visible.
Set value to 0 to remove setting."]]),
			custom_type = 4,
		}
	end
end -- do

function ChoGGi_Funcs.Menus.SetLightsRadius()
	local hr = hr
	local item_list = {
		{text = Translate(1000121--[[Default]]), value = T(1000121--[[Default]]), hint = T(302535920001003--[[restart to enable]])},
		{text = Translate(302535920001004--[[01 Lowest (25)]]), value = 25},
		{text = Translate(302535920001005--[[02 Lower (50)]]), value = 50},
		{text = Translate(302535920001006--[[03 Low (90)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 90},
		{text = Translate(302535920001007--[[04 Medium (95)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 95},
		{text = Translate(302535920001008--[[05 High (100)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 100},
		{text = Translate(302535920001009--[[06 Ultra (200)]]), value = 200},
		{text = Translate(302535920001010--[[07 Ultra-er (400)]]), value = 400},
		{text = Translate(302535920001011--[[08 Ultra-er (600)]]), value = 600},
		{text = Translate(302535920001012--[[09 Ultra-er (1000)]]), value = 1000},
		{text = Translate(302535920001013--[[10 Laggy (10000)]]), value = 10000},
	}

	local function CallBackFunc(choice)
		choice = choice[1]

		local value = choice.value
		if not value then
			return
		end
		if type(value) == "number" then
			if value > 100000 then
				value = 100000
			end
			hr.LightsRadiusModifier = value
			ChoGGi_Funcs.Common.SetSavedConstSetting("LightsRadius", value)
		else
			ChoGGi.UserSettings.LightsRadius = nil
		end

		ChoGGi_Funcs.Settings.WriteSettings()
		MsgPopup(
			ChoGGi_Funcs.Common.SettingState(choice.text),
			T(302535920000633--[[Lights Radius]])
		)
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001016--[[Set Lights Radius]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hr.LightsRadiusModifier
			.. "\n\n" .. T(302535920001017--[[Turns up the radius for light bleedout, doesn't seem to hurt FPS much.]]),
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.SetTerrainDetail()
	local item_list = {
		{text = Translate(1000121--[[Default]]), value = T(1000121--[[Default]]), hint = T(302535920001003--[[restart to enable]])},
		{text = Translate(302535920001004--[[01 Lowest (25)]]), value = 25},
		{text = Translate(302535920001005--[[02 Lower (50)]]), value = 50},
		{text = Translate(302535920001021--[[03 Low (100)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 100},
		{text = Translate(302535920001022--[[04 Medium (150)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 150},
		{text = Translate(302535920001008--[[05 High (100)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 100},
		{text = Translate(302535920001024--[[06 Ultra (200)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 200},
		{text = Translate(302535920001010--[[07 Ultra-er (400)]]), value = 400},
		{text = Translate(302535920001011--[[08 Ultra-er (600)]]), value = 600},
		{text = Translate(302535920001012--[[09 Ultraist (1000)]]), value = 1000, hint = "\n" .. T(302535920001018--[[Above 1000 will add a long delay to loading (and might crash).]])},
	}

	local function CallBackFunc(choice)
		choice = choice[1]

		local value = choice.value
		if not value then
			return
		end
		if type(value) == "number" then
			if value > 1000 then
				value = 1000
			end
			hr.TR_MaxChunks = value
			ChoGGi_Funcs.Common.SetSavedConstSetting("TerrainDetail", value)
		else
			ChoGGi.UserSettings.TerrainDetail = nil
		end

		ChoGGi_Funcs.Settings.WriteSettings()
		MsgPopup(
			ChoGGi_Funcs.Common.SettingState(choice.text),
			T(302535920000635--[[Terrain Detail]])
		)
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000129--[[Set]]) .. " " .. T(302535920000635--[[Terrain Detail]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hr.TR_MaxChunks .. "\n" .. T(302535920001030--[["Doesn't seem to use much CPU, but load times will probably increase. I've limited max to 1000, if you've got a Nvidia Volta and want to use more memory then do it through the settings file.

And yes Medium is using a higher setting than High..."]]),
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.SetVideoMemory()
	local item_list = {
		{text = Translate(1000121--[[Default]]), value = T(1000121--[[Default]]), hint = T(302535920001003--[[restart to enable]])},
		{text = Translate(302535920001031--[[1 Crap (32)]]), value = 32},
		{text = Translate(302535920001032--[[2 Crap (64)]]), value = 64},
		{text = Translate(302535920001033--[[3 Crap (128)]]), value = 128},
		{text = Translate(302535920001034--[[4 Low (256)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 256},
		{text = Translate(302535920001035--[[5 Medium (512)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 512},
		{text = Translate(302535920001036--[[6 High (1024)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 1024},
		{text = Translate(302535920001037--[[7 Ultra (2048)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 2048},
		{text = Translate(302535920001038--[[8 Ultra-er (4096)]]), value = 4096},
		{text = Translate(302535920001039--[[9 Ultra-er-er (8192)]]), value = 8192},
	}

	local function CallBackFunc(choice)
		choice = choice[1]

		local value = choice.value
		if not value then
			return
		end
		if type(value) == "number" then
			hr.DTM_VideoMemory = value
			ChoGGi_Funcs.Common.SetSavedConstSetting("VideoMemory", value)
		else
			ChoGGi.UserSettings.VideoMemory = nil
		end

		ChoGGi_Funcs.Settings.WriteSettings()
		MsgPopup(
			ChoGGi_Funcs.Common.SettingState(choice.text),
			T(302535920000637--[[Video Memory]])
		)
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001041--[[Set Video Memory Use]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hr.DTM_VideoMemory,
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.SetShadowmapSize()
	local hint_highest = T(6779--[[Warning]]) .. ": " .. T(302535920001042--[[Highest uses vram (one gig for starter base, a couple for large base).]])
	local item_list = {
		{text = Translate(1000121--[[Default]]), value = T(1000121--[[Default]]), hint = T(302535920001003--[[restart to enable]])},
		{text = Translate(302535920001043--[[1 Crap (256)]]), value = 256},
		{text = Translate(302535920001044--[[2 Lower (512)]]), value = 512},
		{text = Translate(302535920001045--[[3 Low (1536)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 1536},
		{text = Translate(302535920001046--[[4 Medium (2048)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 2048},
		{text = Translate(302535920001047--[[5 High (4096)]]) .. " < " .. Translate(302535920001065--[[Menu Option]]), value = 4096},
		{text = Translate(302535920001048--[[6 Higher (8192)]]), value = 8192, hint = T(302535920001645, "May cause crashing!")},
		{text = Translate(302535920001049--[[7 Highest (16384)]]), value = 16384, hint = hint_highest .. "\n\n" .. T(302535920001645, "May cause crashing!")},
	}

	local function CallBackFunc(choice)
		choice = choice[1]

		local value = choice.value
		if not value then
			return
		end

		if type(value) == "number" then
			if value > 16384 then
				value = 16384
			end
			hr.ShadowmapSize = value
			ChoGGi_Funcs.Common.SetSavedConstSetting("ShadowmapSize", value)
		else
			ChoGGi.UserSettings.ShadowmapSize = nil
		end

		ChoGGi_Funcs.Settings.WriteSettings()
		MsgPopup(
			ChoGGi_Funcs.Common.SettingState(choice.text),
			T(302535920000639--[[Shadow Map]])
		)
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001051--[[Set Shadowmap Size]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hr.ShadowmapSize .. "\n\n" .. hint_highest .. "\n\n" .. T(302535920001052--[[Max limited to 16384 (or crashing).]]),
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.HigherShadowDist_Toggle()
	ChoGGi.UserSettings.HigherShadowDist = not ChoGGi.UserSettings.HigherShadowDist

	hr.ShadowRangeOverride = ChoGGi_Funcs.Common.ValueRetOpp(hr.ShadowRangeOverride, 0, 1000000)
	hr.ShadowFadeOutRangePercent = ChoGGi_Funcs.Common.ValueRetOpp(hr.ShadowFadeOutRangePercent, 30, 0)

	ChoGGi_Funcs.Settings.WriteSettings()
	MsgPopup(
		ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.HigherShadowDist),
		T(302535920000645--[[Higher Shadow Distance]])
	)
end

function ChoGGi_Funcs.Menus.HigherRenderDist_Toggle()
	local default_setting = ChoGGi.Consts.HigherRenderDist or ChoGGi.UserSettings.HigherRenderDist or 120
	local hint_min = T(302535920001054--[[Minimal FPS hit on large base]])
	local hint_small = T(302535920001055--[[Small FPS hit on large base]])
	local hint_fps = T(302535920001056--[[FPS hit]])
	local item_list = {
		{text = Translate(1000121--[[Default]]) .. ": " .. default_setting, value = default_setting},
		{text = 240, value = 240, hint = hint_min},
		{text = 360, value = 360, hint = hint_min},
		{text = 480, value = 480, hint = hint_min},
		{text = 600, value = 600, hint = hint_small},
		{text = 720, value = 720, hint = hint_small},
		{text = 840, value = 840, hint = hint_fps},
		{text = 960, value = 960, hint = hint_fps},
		{text = 1080, value = 1080, hint = hint_fps},
		{text = 1200, value = 1200, hint = hint_fps},
	}

	local hint = default_setting
	if ChoGGi.UserSettings.HigherRenderDist then
		hint = tostring(ChoGGi.UserSettings.HigherRenderDist)
	end

	--callback
	local function CallBackFunc(choice)
		local value = choice[1].value
		if not value then
			return
		end
		if type(value) == "number" then
			hr.LODDistanceModifier = value
			ChoGGi_Funcs.Common.SetSavedConstSetting("HigherRenderDist", value)

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(ChoGGi.UserSettings.HigherRenderDist),
				T(302535920000643--[[Higher Render Distance]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000643--[[Higher Render Distance]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hint,
		skip_sort = true,
	}
end


--use hr.FarZ = 7000000 for viewing full map with 128K zoom
do -- CameraFree_Toggle
	-- used to keep pos/lookat/zoom
	local cur_pos, cur_la, zoom
	function ChoGGi_Funcs.Menus.CameraFree_Toggle()
		if cameraFly.IsActive() then
			SetMouseDeltaMode(false)
			cameraRTS.Activate(1)
			-- since we used engineHideMouseCursor, we need this as well
			engineShowMouseCursor()
			-- restore pos/zoom
			if cur_pos and cur_la and zoom then
				cameraRTS.SetCamera(cur_pos, cur_la)
				cameraRTS.SetZoom(zoom)
			end
			-- make sure camera uses our settings after fly is done
			ChoGGi_Funcs.Common.SetCameraSettings()
			MsgPopup(
				T(302535920001059--[[RTS]]),
				T(302535920000651--[[Toggle Free Camera]])
			)
		else
			cur_pos, cur_la = cameraRTS.GetPosLookAt()
			zoom = cameraRTS.GetZoom()
			cameraFly.Activate(1)
			SetMouseDeltaMode(true)
			-- IsMouseCursorHidden works by checking whatever this sets
			engineHideMouseCursor()
			MsgPopup(
				T(302535920001060--[[Fly]]),
				T(302535920000651--[[Toggle Free Camera]])
			)
		end
		-- resets zoom so...
		ChoGGi_Funcs.Common.SetCameraSettings()
	end

	function ChoGGi_Funcs.Menus.CameraFollow_Toggle()
		-- It was on the free camera so
		if not ActiveMapData.GameLogic then
			return
		end

		-- turn it off
		if camera3p.IsActive() then
			SetMouseDeltaMode(false)
			cameraRTS.Activate(1)
			engineShowMouseCursor()
			-- reset camera fov settings
			if ChoGGi.cameraFovX then
				camera.SetFovX(ChoGGi.cameraFovX)
			end
			-- show log again if it was hidden
			if ChoGGi.UserSettings.ConsoleToggleHistory then
				cls() --if it's going to spam the log, might as well clear it
				ChoGGi_Funcs.Common.ToggleConsoleLog()
			end
			-- restore pos/zoom
			if cur_pos and cur_la and zoom then
				cameraRTS.SetCamera(cur_pos, cur_la)
				cameraRTS.SetZoom(zoom)
			end
			-- reset camera zoom settings
			ChoGGi_Funcs.Common.SetCameraSettings()
		else
			-- crashes game if we attach to "false"
			local obj = ChoGGi_Funcs.Common.SelObject()
			if not obj then
				return
			end

			-- let user know the camera mode
			MsgPopup(
				T(302535920001061--[[Follow]]),
				T(302535920000653--[[Toggle Follow Camera]])
			)

			-- save pos/zoom
			cur_pos, cur_la = cameraRTS.GetPosLookAt()
			zoom = cameraRTS.GetZoom()
			-- we only want to follow one object
			if ChoGGi.LastFollowedObject then
				camera3p.DetachObject(ChoGGi.LastFollowedObject)
			end
			-- save for DetachObject
			ChoGGi.LastFollowedObject = obj
			-- save for fovX reset
			ChoGGi.cameraFovX = camera.GetFovX()
			-- zoom further out unless it's a colonist
			if not obj:IsKindOf("Colonist") then
				-- up the horizontal fov so we're further away from object
				camera.SetFovX(8400)
			end
			-- consistent zoom level
			cameraRTS.SetZoom(8000)
			-- activate it
			camera3p.Activate(1)
			camera3p.AttachObject(obj)
			camera3p.SetLookAtOffset(point(0, 0, -1500))
			camera3p.SetEyeOffset(point(0, 0, -1000))
			-- moving mouse moves camera
			camera3p.EnableMouseControl(true)
			-- IsMouseCursorHidden works by checking whatever this sets
			engineHideMouseCursor()

			-- toggle showing console history as console spams transparent something (and it'd be annoying to replace that function)
			if ChoGGi.UserSettings.ConsoleToggleHistory then
				ChoGGi_Funcs.Common.ToggleConsoleLog()
			end

			-- If it's a rover then stop the ctrl control mode from being active (from pressing ctrl-shift-f)
			if type(obj.SetControlMode) == "function" then
				obj:SetControlMode(false)
			end
		end
	end

end -- do

-- LogCameraPos(print)
function ChoGGi_Funcs.Menus.CursorVisible_Toggle()
	if IsMouseCursorHidden() then
		SetMouseDeltaMode(false)
		engineShowMouseCursor()
	else
		SetMouseDeltaMode(true)
		-- IsMouseCursorHidden works by checking whatever this sets
		engineHideMouseCursor()
	end
end

function ChoGGi_Funcs.Menus.SetBorderScrolling()
	local default_setting = 5
	local hint_down = T(302535920001062--[[Down scrolling may not work (dependant on aspect ratio?).]])
	local item_list = {
		{text = Translate(1000121--[[Default]]), value = default_setting, hint = T(1000121--[[Default]]) .. ": " .. default_setting},
		{text = -1, value = -1, hint = T(302535920001063--[[disable mouse border scrolling, WASD still works fine.]])},
		{text = 0, value = 0, hint = hint_down},
		{text = 1, value = 1, hint = hint_down},
		{text = 2, value = 2, hint = hint_down},
		{text = 3, value = 3},
		{text = 4, value = 4},
		{text = 10, value = 10},
	}

	local hint = default_setting
	if ChoGGi.UserSettings.BorderScrollingArea then
		hint = tostring(ChoGGi.UserSettings.BorderScrollingArea)
	end

	local function CallBackFunc(choice)
		choice = choice[1]

		local value = choice.value
		if not value then
			return
		end
		if type(value) == "number" then
			ChoGGi_Funcs.Common.SetSavedConstSetting("BorderScrollingArea", value)
			ChoGGi_Funcs.Common.SetCameraSettings()

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(choice.value),
				T(302535920000647--[[Border Scrolling]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000129--[[Set]]) .. " " .. T(302535920000647--[[Border Scrolling]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hint,
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.SetCameraLookatDist()
	local default_setting = ChoGGi.Consts.CameraLookatDist or ChoGGi.UserSettings.CameraLookatDist or 0
	local item_list = {
		{text = Translate(1000121--[[Default]]) .. ": " .. default_setting, value = default_setting},
		{text = 10, value = 10},
		{text = 20, value = 20},
		{text = 30, value = 30},
		{text = 50, value = 50},
		{text = 60, value = 60},
		{text = 70, value = 70},
		{text = 80, value = 80},
		{text = 90, value = 90},
		{text = 100, value = 100},
	}
	local hint = default_setting
	if ChoGGi.UserSettings.CameraLookatDist then
		hint = tostring(ChoGGi.UserSettings.CameraLookatDist)
	end

	local function CallBackFunc(choice)
		choice = choice[1]

		local value = choice.value
		if not value then
			return
		end
		if type(value) == "number" then
			ChoGGi_Funcs.Common.SetSavedConstSetting("CameraLookatDist", value)
			ChoGGi_Funcs.Common.SetCameraSettings()

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(choice.text),
				T(302535920001375--[[Bird's Eye]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001375--[[Bird's Eye]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hint,
		skip_sort = true,
	}
end

function ChoGGi_Funcs.Menus.SetCameraZoom()
	-- where did this const come from?
--~ 	local default_setting = ChoGGi.Consts.CameraZoomToggle or ChoGGi.UserSettings.CameraZoomToggle or 24000
	local default_setting = ChoGGi.UserSettings.CameraZoomToggle or 24000
	local item_list = {
		{text = Translate(1000121--[[Default]]) .. ": " .. default_setting, value = default_setting},
		{text = 16000, value = 16000},
		{text = 20000, value = 20000},
		{text = 24000, value = 24000, hint = T(1000121--[[Default]])},
		{text = 32000, value = 32000},
		{text = 64000, value = 64000},
		{text = 128000, value = 128000},
		{text = 256000, value = 256000},
	}

	local hint = default_setting
	if ChoGGi.UserSettings.CameraZoomToggle then
		hint = tostring(ChoGGi.UserSettings.CameraZoomToggle)
	end

	local function CallBackFunc(choice)
		local value = choice[1].value
		if not value then
			return
		end
		if type(value) == "number" then
			ChoGGi_Funcs.Common.SetSavedConstSetting("CameraZoomToggle", value)
			ChoGGi_Funcs.Common.SetCameraSettings()

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				choice[1].text,
				T(302535920000649--[[Zoom Distance]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000649--[[Zoom Distance]]),
		hint = T(302535920000106--[[Current]]) .. ": " .. hint,
		skip_sort = true,
	}
end
