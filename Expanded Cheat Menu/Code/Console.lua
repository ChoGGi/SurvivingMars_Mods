-- See LICENSE for terms

local ChoGGi_Funcs = ChoGGi_Funcs
local what_game = ChoGGi.what_game

-- menus/buttons added to the Console
local table = table
local CmpLower = CmpLower
local print, type, rawget = print, type, rawget
local FlushLogFile = FlushLogFile

-- rebuild list of objects to examine when user changes settings
OnMsg.ChoGGi_SettingsUpdated = ChoGGi_Funcs.Console.BuildExamineMenu
-- update UICity list
OnMsg.ChangeMapDone = ChoGGi_Funcs.Console.BuildExamineMenu

local T = T
local OpenExamine = OpenExamine
local Translate = ChoGGi_Funcs.Common.Translate
local PopupToggle = ChoGGi_Funcs.Common.PopupToggle
local DotPathToObject = ChoGGi_Funcs.Common.DotPathToObject
local RetFilesInFolder = ChoGGi_Funcs.Common.RetFilesInFolder
local blacklist = ChoGGi.blacklist
local testing = ChoGGi.testing

local g_env, debug
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	blacklist = false
	g_env, debug = env, env.debug
end

-- store list of undefined globals
ChoGGi.Temp.UndefinedGlobals = {}

local function UpdateConsoleText(text)
	local edit = dlgConsole.idEdit
	edit:SetFocus()
	edit:SetText(text)
	edit:SetCursor(1, #text + 1)
end

local ToolsMenuPopupToggle_list = {
	{name = T(302535920000040--[[Exec Code]]),
		hint = T(302535920001287--[[Instead of a single line, you can enter/execute code in a textbox.]]),
		clicked = function()
			ChoGGi_Funcs.Common.OpenInExecCodeDlg()
		end,
	},
	{name = T(302535920001497--[[Show Blacklist]]),
		hint = "Show blacklisted objects",
		clicked = function()
			if blacklist then
				ChoGGi_Funcs.Common.BlacklistMsg(T(302535920001497))
				return
			end
			-- lib should always have the blacklist enabled
			local _, bl = debug.getupvalue(getmetatable(ChoGGi.def_lib.env).__index, 1)
			bl[" " .. T(302535920000313--[[OnMsg/Msg blacklist]])] = ModMsgBlacklist
			OpenExamine(bl, nil, T(302535920001497))
		end,
	},
	{is_spacer = true},
	{name = T(302535920000734--[[Clear Log]]),
		hint = T(302535920001152--[[Clear out the console log (F9 also works).]]),
		clicked = cls,
	},
	{name = T(302535920000563--[[View Log Text]]),
		hint = T(302535920001154--[[Displays the log text in a window you can copy sections from.]]),
		clicked = function()
			ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
				width = 1600,
				height = 1000,
				text = LoadLogfile(),
				title = T(302535920000563--[[View Log Text]]),
				update_func = LoadLogfile,
			}
		end,
	},
	{name = T(302535920000473--[[Flush Log]]),
		hint = T(302535920000474--[[Flushes log to file.]]),
		clicked = function()
			FlushLogFile()
			print(Translate(T(302535920001734--[[Log file flushed]])))
		end,
	},
	{name = T(302535920000071--[[Show Mods Log]]),
		hint = T(302535920001123--[[Shows any mod msgs in the log.]]),
		clicked = function()
			ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
				text = table.concat(ModMessageLog, "\n"),
				title = T(302535920000071--[[Show Mods Log]]),
				update_func = ModMessageLog,
			}
		end,
	},
	{is_spacer = true},
	{name = T(302535920000853--[[Monitor]]) .. ": _G",
		hint = "ChoGGi_Funcs.Common.MonitorTableLength(_G)",
		mouseup = function(_, _, _, button)
			if button == "R" then
				UpdateConsoleText("ChoGGi_Funcs.Common.MonitorTableLength()")
			else
				ChoGGi_Funcs.Common.MonitorTableLength()
			end
		end,
	},
	{name = T(302535920000853--[[Monitor]]) .. ": ThreadsRegister",
		hint = "ChoGGi_Funcs.Common.MonitorThreads()",
		mouseup = function(_, _, _, button)
			if button == "R" then
				UpdateConsoleText("ChoGGi_Funcs.Common.MonitorThreads()")
			else
				ChoGGi_Funcs.Common.MonitorThreads()
			end
		end,
	},
	{name = T(302535920000234--[[Monitor Func Calls]]),
		hint = T(302535920000300--[["Collects a list of func calls from ""@AppData/Mods/""
Usage: Call it once to start and again to stop, it'll then show a list of func calls.

Call it manually with:
ChoGGi_Funcs.Common.ToggleFuncHook(path, line, mask, count)
https://www.lua.org/manual/5.3/manual.html#pdf-debug.sethook"]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.Temp.FunctionsHooked",
		mouseup = function(_, _, _, button)
			if button == "R" then
				UpdateConsoleText("ChoGGi_Funcs.Common.ToggleFuncHook(\"@AppData/Mods/\")")
			else
				ChoGGi_Funcs.Common.ToggleFuncHook("@AppData/Mods/")
			end
		end,
	},
	{is_spacer = true},
	{name = T(302535920001321--[[UI Click To Examine]]),
		hint = T(302535920001322--[[Examine UI controls by clicking them.]]),
--~ 		image = "CommonAssets/UI/Menu/select_objects.tga",
		clicked = function()
			ChoGGi_Funcs.Common.TerminalRolloverMode(true)
		end,
	},
	{name = T(302535920001378--[[XWindow Inspector]]),
		hint = T(302535920001379--[[Opens up the window inspector with terminal.desktop.]]),
		clicked = function()
			ChoGGi_Funcs.Common.OpenGedApp("XWindowInspector")
		end,
	},
}
-- created when we create the controls controls the first time
local ExamineMenuToggle_list = {}
-- to add each item
local function BuildExamineItem(name, title)
	if not name then
		return
	end
	local obj = DotPathToObject(name)
	local func = type(obj) == "function"
	local disp = title or name .. (func and "()" or "")
	return {
		name = disp,
		hint = T(302535920000491--[[Examine Object]]) .. ": " .. name,
		hint_bottom = T(302535920000407--[[<left_click> Execute <right_click> Paste]]),
		mouseup = function(_, _, _, button)
			if button == "R" then
				dlgConsole.idEdit:SetFocus()
				dlgConsole.idEdit:SetText("~" .. name)
				dlgConsole.idEdit:SetCursor(1, #name + 1)
			else
				-- funcs
				if func then
					if name == "GetLuaSaveGameData" then
						OpenExamine({obj()}, nil, name)
					else
						OpenExamine(obj(), nil, name)
					end
				else
				-- funcs

				-- values
					if name == "OnMsg" then
						-- Gotta do a little metatable/upvalue digging
						local meta_table = getmetatable(g_env.OnMsg).__newindex
						local _, value = debug.getupvalue(meta_table, 1)
						OpenExamine(value, nil, name)
					else
						OpenExamine(name, "str", name)
					end
				-- values

				end
			end
		end,
	}
end
ChoGGi_Funcs.Console.BuildExamineItem = BuildExamineItem
--
local function AddSubmenu(name, title, ...)
	local submenu = table.find(ExamineMenuToggle_list, "name", name)
	if submenu then
		local temp_menu = ExamineMenuToggle_list[submenu]
		temp_menu.hint = nil
		if title then
			temp_menu.name = title
		end
		-- add the parent item for people that didn't figure out you can just click the menu
		temp_menu.submenu = {BuildExamineItem(name)}
		local c = #temp_menu.submenu

		local params = {...}
		for i = 1, #params do
			c = c + 1
			temp_menu.submenu[c] = BuildExamineItem(params[i])
		end

	end
end
ChoGGi_Funcs.Console.AddSubmenu = AddSubmenu

--~ 	function ChoGGi_Funcs.Console.AddMonitor(name, submenu, idx)
--~ 		table.insert(submenu, idx or 2, {
--~ 			name = T(302535920000853--[[Monitor]]) .. ": " .. name,
--~ 			hint = "ChoGGi_Funcs.Common.MonitorTableLength(" .. name .. ")",
--~ 			clicked = function()
--~ 				if name == "_G" then
--~ 					ChoGGi_Funcs.Common.MonitorTableLength(DotPathToObject(name), nil, nil, nil, name)
--~ 				else
--~ 					ChoGGi_Funcs.Common.MonitorTableLength(DotPathToObject(name), 0, nil, nil, name)
--~ 				end
--~ 			end,
--~ 		})
--~ 	end

-- build list of objects to examine
function ChoGGi_Funcs.Console.BuildExamineMenu()
	table.iclear(ExamineMenuToggle_list)

	local list = ChoGGi.UserSettings.ConsoleExamineList or ""
	local submenu

	-- add saved examine items
	table.sort(list, CmpLower)
	for i = 0, #list do
		ExamineMenuToggle_list[i] = BuildExamineItem(list[i])
	end

	-- add submenus to certain items

	--
	submenu = table.find(list, "Presets")
	if submenu then
		-- remove hint from "submenu" menu
		ExamineMenuToggle_list[submenu].hint = nil

		-- build a list of Descendants of Preset
		local submenu_table = {}
		local c = 0
		-- dupe skipper
		local names_list = {}
		ClassDescendantsList("Preset", function(_, cls)
			if cls.GlobalMap and cls.GlobalMap ~= "" and not names_list[cls.GlobalMap] then
				names_list[cls.GlobalMap] = true
				c = c + 1
				submenu_table[c] = BuildExamineItem(cls.GlobalMap)
			end
		end)
		-- and any stored in Presets table
		local Presets = Presets
		for id in pairs(Presets) do
			names_list[id] = true
			c = c + 1
			submenu_table[c] = BuildExamineItem("Presets." .. id, id .. " *")
		end

		table.sort(submenu_table,
			function(a, b)
				-- damn eunuchs
				return CmpLower(a.name, b.name)
			end
		)
		-- add orig to the menu (we want it at start so no sorting)
		table.insert(submenu_table, 1, BuildExamineItem("Presets"))
		-- and done
		ExamineMenuToggle_list[submenu].submenu = submenu_table
	end
	--
	submenu = table.find(list, "DataInstances")
	if submenu and what_game == "Mars" then
		ExamineMenuToggle_list[submenu].hint = nil
		-- we need to build a list
		local submenu_table = {}
		local c = 0
		-- same for DataInstances
		local DataInstances = DataInstances
		for key in pairs(DataInstances) do
			c = c + 1
			submenu_table[c] = BuildExamineItem("DataInstances." .. key, key)
		end

		table.sort(submenu_table,
			function(a, b)
				-- damn eunuchs
				return CmpLower(a.name, b.name)
			end
		)

		-- add orig to the menu (we want it at start so no sorting)
		table.insert(submenu_table, 1, BuildExamineItem("DataInstances"))
		-- and done
		ExamineMenuToggle_list[submenu].submenu = submenu_table
	end
	-- do this for UIColony.city_labels.labels as well
	submenu = table.find(list, "Cities")
	if submenu and what_game == "Mars" then
		local labels_name = "UICity.labels"
		table.insert(ExamineMenuToggle_list, submenu+1, {
			name = labels_name,
			hint = labels_name,
			submenu = {},
			clicked = function()
				OpenExamine(labels_name, "str", labels_name)
			end,
			-- mouseover fires before building submenu, so we can update submenu list
			mouseover = function()
				local UICity = UICity
				if not UICity then
					return
				end

				local list = {}
				local c = 0
				local labels = DotPathToObject(labels_name)
				for key, value in pairs(labels) do
					if value[1] then
						c = c + 1
						list[c] = key
					end
				end
				table.sort(list, CmpLower)
				local temp_menu = ExamineMenuToggle_list[table.find(ExamineMenuToggle_list, "name", labels_name)]

				table.iclear(temp_menu.submenu)
				for i = 1, c do
					local name = list[i]
					temp_menu.submenu[i] = BuildExamineItem(
						labels_name .. "." .. name,
						name .. "\t(" .. #labels[name] .. ")"
					)
				end
			end,
		})
	end
	--
	AddSubmenu("_G", nil, "AccountStorage", "__cobjectToCObject", "FlagsByBits", "HandleToObject", "TranslationTable", "DeletedCObjects", "Flight_MarkedObjs", "debug.getregistry")
	AddSubmenu("ThreadsRegister", nil, "ThreadsMessageToThreads", "ThreadsThreadToMessage", "s_SeqListPlayers", "GameInitThreads", "OnMsg")
	AddSubmenu("Consts", nil, "g_Consts", "const", "ModifiablePropScale", "const.TagLookupTable", "const.Scale")
	AddSubmenu("Dialogs", nil, "terminal.desktop", "GetInGameInterface", "XShortcutsTarget")
	AddSubmenu("GlobalVars", nil, "GlobalVarValues", "PersistableGlobals", "GetLuaSaveGameData", "GetLuaLoadGamePermanents", "GlobalObjs", "GlobalObjClasses", "GlobalGameTimeThreads", "GlobalGameTimeThreadFuncs", "GlobalRealTimeThreads", "GlobalRealTimeThreadFuncs")
	AddSubmenu("EntityData", nil, "GetAllEntities", "EntityStates", "EntitySurfaces", "HexOutlineShapes", "HexInteriorShapes", "HexOutlineByHash", "HexBuildShapes", "HexBuildShapesInversed", "HexPeripheralShapes", "HexCombinedShapes", "PrefabMarkers")
	AddSubmenu("g_Classes", nil, "ClassTemplates.Building", "BuildingTemplates", "Attaches", "FXRules", "FXLists")
	AddSubmenu("g_CObjectFuncs", nil, "hr", "pf", "terrain", "UIL", "DTM", "lpeg", "srp", "camera", "camera3p", "cameraMax", "cameraRTS", "string", "table", "package", "debug", "lfs")
	AddSubmenu("StoryBits", "Story Bits", "g_StoryBitsLog", "StoryBitCategories", "StoryBitTriggersCombo", "g_StoryBitActive", "g_StoryBitCategoryStates", "g_StoryBitStates")
	AddSubmenu("Cities", nil, "GameMaps", "UICity", "MainCity", "UIColony", "UIColony.city_labels.labels", "UIColony.tech_status", "ResupplyItemDefinitions", "BuildMenuPrerequisiteOverrides", "BuildingTechRequirements", "g_ApplicantPool", "g_CurrentMissionParams", "UICity.MapSectors", "RivalAIs", "TaskRequesters", "LRManagerInstance")
	AddSubmenu("Mods", nil, "ModsLoaded", "ModsList")

--~ 	-- bonus addition at the top
--~ 	table.insert(ExamineMenuToggle_list, 1, {
--~ 		name = T(302535920001376--[[Auto Update List]]),
--~ 		hint = T(302535920001377--[[Update this list when ECM updates it.]]),
--~ 		class = "ChoGGi_XCheckButtonMenu",
--~ 		value = "ChoGGi.UserSettings.ConsoleExamineListUpdate",
--~ 		clicked = function()
--~ 			ChoGGi.UserSettings.ConsoleExamineListUpdate = not ChoGGi.UserSettings.ConsoleExamineListUpdate
--~ 			ChoGGi_Funcs.Settings.WriteSettings()
--~ 		end,
--~ 	})
end

do -- ToggleLogErrors
	local GetStack = GetStack
	local UserSettings = ChoGGi.UserSettings
	local Temp_Original = {}

	local UndefinedGlobals = ChoGGi.Temp.UndefinedGlobals
	local UndefinedGlobals_c = #UndefinedGlobals
	local function UndefinedGlobalUpdate(msg, stack)
		UndefinedGlobals_c = UndefinedGlobals_c + 1
		UndefinedGlobals[UndefinedGlobals_c] = msg .. "\n" .. stack
		if testing and UserSettings.ConsoleSkipUndefinedGlobals then
			print("<color ChoGGi_red>", msg, "</color>")
		else
			if not UserSettings.ConsoleSkipUndefinedGlobals then
				print(msg, "\n", stack)
			end
		end
	end

	local funcs = {"error", "OutputDebugString", "ThreadErrorHandler", "DlcErrorHandler", "syntax_error", "RecordError", "StoreErrorSource"}
--~ 	local funcs = {}
--~ 	local funcs = {"error", "OutputDebugString", "DlcErrorHandler", "syntax_error", "RecordError", "StoreErrorSource"}


	local function UpdateLogErrors(name)
		-- replace the error reporting funcs with our own
		_G[name] = function(msg, ...)
			-- devs may care about undefined globals, but i certainly don't
			if name == "error" and type(msg) == "string" and msg:sub(1, 36) == "Attempt to use an undefined global '" then
					UndefinedGlobalUpdate(msg, GetStack(2, false, "\t") or "")
				return
			end

			local func_name = T(302535920001077--[[Error from function]]) .. [[ "]] .. name .. [[" = ]]
			local stack_trace = GetStack(2, false, "\t")
			print(func_name, msg, ..., "\nGetStack():\n", stack_trace)

			local stack_trace2
			if not blacklist then
				stack_trace2 = debug.traceback(nil, 2)
				if stack_trace2 and stack_trace2 ~= "" then
					print("\ndebug.traceback():\n", stack_trace2)
				end
			end

			if UserSettings.ExamineErrors then
				-- I only care to see threads (i don't think funcs show up?)
				if testing then
					local err_type = type(msg)
					-- not sure if it can ever be a func...?
					if err_type == "thread" or err_type == "function" then
						OpenExamine({
							(err_type == "function" and err_type .. " " or "") .. func_name,
							..., stack_trace, stack_trace2,
						}, nil, T(302535920001479--[[Examine Errors]]))
					end
				else
					OpenExamine(
						{func_name, msg, ..., stack_trace, stack_trace2, },
						nil, T(302535920001479--[[Examine Errors]])
					)
				end
			end

			-- send back the orig func
			return Temp_Original[name](msg, ...)
		end

	end

	-- save orig funcs (if toggling happens)
	local DebugGetInfo = ChoGGi_Funcs.Common.DebugGetInfo
	local lookup_table = ChoGGi_lookup_names
	for i = 1, #funcs do
		local name = funcs[i]
		if rawget(_G, name) then
			local func = _G[name]
			Temp_Original[name] = func
			if not lookup_table[func] then
				if DebugGetInfo(func) == "[C](-1)" then
					lookup_table[func] = name .. " *C"
				else
					lookup_table[func] = name
				end
			end
		end
	end

	function ChoGGi_Funcs.Console.ToggleLogErrors(enable)
		-- stop "Attempt to create a new global " errors, though I'm not sure why they happen since they're not "new"
		local ChoOrig_Loading = Loading
		Loading = true

		for i = 1, #funcs do
			local name = funcs[i]
			if rawget(_G, name) then
				if enable then
					UpdateLogErrors(name)
				else
					if name == "error" then
						_G.error = function(msg, ...)
							-- skip the one annoying "error"
--~ 							if type(msg) == "string" and msg:sub(1, 36) == "Attempt to use an undefined global '" then
--~ 								UndefinedGlobalUpdate(msg, GetStack(2, false, "\t") or "")
--~ 								return
--~ 							end
--~ 							--
							if type(msg) == "string" then
								if msg:sub(1, 36) == "Attempt to use an undefined global '" then
									UndefinedGlobalUpdate(msg, GetStack(2, false, "\t") or "")
									return
								end
								if testing and msg:sub(1, 30) == "Attempt to create a new global" then
									UndefinedGlobalUpdate(msg, GetStack(2, false, "\t") or "")
									return
								end
							end
							--
							return Temp_Original[name](msg, ...)
						end
					else
						_G[name] = Temp_Original[name]
					end
				end
			end
		end

		Loading = ChoOrig_Loading
	end

	-- print logged errors to console/skip annoying "error"
	ChoGGi_Funcs.Console.ToggleLogErrors(UserSettings.ConsoleErrors)
end -- do

-- The one OnMsg outside my Msgs file for speed
local FlushLogConstantly = ChoGGi.UserSettings.FlushLogConstantly
function OnMsg.OnRender()
	if FlushLogConstantly then
		FlushLogFile()
	end
end

local ConsoleMenuPopupToggle_list = {
	{name = T(302535920001479--[[Errors In Console]]),
		hint = Translate(302535920001480--[[Print (some) lua errors in the console (needs %s enabled).]]):format(Translate(302535920001112--[[Console Log]])),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.ConsoleErrors",
		clicked = function()
			ChoGGi.UserSettings.ConsoleErrors = not ChoGGi.UserSettings.ConsoleErrors
			ChoGGi_Funcs.Settings.WriteSettings()
			ChoGGi_Funcs.Console.ToggleLogErrors(ChoGGi.UserSettings.ConsoleErrors)
		end,
	},
	{name = T(302535920001102--[[Examine Errors]]),
		hint = T(302535920001104--[[Open (some) errors in an examine dialog (shows stack trace and sometimes a thread).]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.ExamineErrors",
		clicked = function()
			ChoGGi.UserSettings.ExamineErrors = not ChoGGi.UserSettings.ExamineErrors
			ChoGGi_Funcs.Settings.WriteSettings()
		end,
	},
	{name = T(302535920000310--[[Skip Undefined Globals]]),
		hint = T(302535920000311--[["Stop the ""Attempt to use an undefined global"" msgs.

The number is a count of stored msgs, right-click to view the list."]]),
		hint_bottom = T(302535920001444--[[<left_click> Activate <right_click> Alt Activate]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.ConsoleSkipUndefinedGlobals",
		mouseup = function(_, _, _, button)
			if button == "R" then
				OpenExamine(ChoGGi.Temp.UndefinedGlobals, nil, T(302535920000310--[[Skip Undefined Globals]]))
			else
				ChoGGi.UserSettings.ConsoleSkipUndefinedGlobals = not ChoGGi.UserSettings.ConsoleSkipUndefinedGlobals
				-- clear when re-enabled, not if disabled accidentally
				if ChoGGi.UserSettings.ConsoleSkipUndefinedGlobals then
					table.iclear(ChoGGi.Temp.UndefinedGlobals)
				end
				ChoGGi_Funcs.Settings.WriteSettings()
			end
		end,
	},
	{name = T(302535920001112--[[Console Log]]),
		hint = T(302535920001119--[[Show console log text in-game (probably an annoyance to non-modders).]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.ConsoleToggleHistory",
		clicked = function()
			ChoGGi.UserSettings.ConsoleToggleHistory = not ChoGGi.UserSettings.ConsoleToggleHistory
			ChoGGi_Funcs.Settings.WriteSettings()
			if ChoGGi.UserSettings.ConsoleToggleHistory then
				ShowConsoleLog(true)
				ChoGGi_Funcs.Common.UpdateConsoleMargins(true)
				print("ShowConsoleLog: true")
			else
				DestroyConsoleLog()
				print("ShowConsoleLog: false")
			end
		end,
	},
	{name = T(302535920000473--[[Flush Log]]),
		hint = T(302535920001342--[[Dumps the log to disk on startup, and every new Sol (good for some crashes).]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.FlushLog",
		clicked = function()
			ChoGGi.UserSettings.FlushLog = not ChoGGi.UserSettings.FlushLog
			ChoGGi_Funcs.Settings.WriteSettings()
		end,
	},
	{name = T(302535920001635--[[Flush Log Hourly]]),
		hint = T(302535920001636--[[Call FlushLogFile() every in-game hour.]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.FlushLogHourly",
		clicked = function()
			ChoGGi.UserSettings.FlushLogHourly = not ChoGGi.UserSettings.FlushLogHourly
			ChoGGi_Funcs.Settings.WriteSettings()
		end,
	},
	{name = T(302535920001349--[[Flush Log Constantly]]),
		hint = T(302535920001414--[[Call FlushLogFile() every render update!]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.FlushLogConstantly",
		clicked = function()
			ChoGGi.UserSettings.FlushLogConstantly = not ChoGGi.UserSettings.FlushLogConstantly
			ChoGGi_Funcs.Settings.WriteSettings()
			-- update local var
			FlushLogConstantly = ChoGGi.UserSettings.FlushLogConstantly
		end,
	},
	{name = T(302535920001576--[[Show Log When Console Active]]),
		hint = T{302535920001575--[[Show console log text when console is active (needs <log> enabled).]],
			log = T(302535920001112--[[Console Log]]),
		},
		class = "ChoGGi_XCheckButtonMenu",
		value = "ChoGGi.UserSettings.ConsoleShowLogWhenActive",
		clicked = function()
			ChoGGi.UserSettings.ConsoleShowLogWhenActive = not ChoGGi.UserSettings.ConsoleShowLogWhenActive
			ChoGGi_Funcs.Settings.WriteSettings()
		end,
	},
	{name = T(302535920001120--[[Console Window]]),
		hint = T(302535920001133--[[Show the console text in an independant window.]]),
		class = "ChoGGi_XCheckButtonMenu",
		value = "dlgChoGGi_DlgConsoleLogWin",
		clicked = function()
			ChoGGi.UserSettings.ConsoleHistoryWin = not ChoGGi.UserSettings.ConsoleHistoryWin
			ChoGGi_Funcs.Settings.WriteSettings()
			ChoGGi_Funcs.Common.ShowConsoleLogWin(ChoGGi.UserSettings.ConsoleHistoryWin)
		end,
	},
}

function ChoGGi_Funcs.Console.HistoryPopup(self)
	local dlgConsole = dlgConsole
	local ConsoleHistoryMenuLength = ChoGGi.UserSettings.ConsoleHistoryMenuLength or 50
	local items = {}
	if dlgConsole.history_queue[1] then
		local history = dlgConsole.history_queue
		for i = 1, #history do
			local text = tostring(history[i])
			items[i] = {
				-- these can get long so keep 'em short
				name = text:sub(1, ConsoleHistoryMenuLength),
				hint = T(302535920001138--[["Execute this command in the console, Right-click to paste code in console."]]) .. "\n\n<left>" .. text,
				hint_bottom = T(302535920000407--[[<left_click> Execute <right_click> Paste]]),
				mouseup = function(_, _, _, button)
					if button == "R" then
						dlgConsole.idEdit:SetFocus()
						dlgConsole.idEdit:SetText(text)
						dlgConsole.idEdit:SetCursor(1, #text)
					else
						dlgConsole:Exec(text)
					end
				end,
			}
		end
	end
	PopupToggle(self, "idHistoryMenuPopup", items, "top")
end

function ChoGGi_Funcs.Console.ConsoleControls(dlgConsole)
	local g_Classes = g_Classes

	-- make some space for the close button
	dlgConsole.idEdit:SetMargins(box(10, 0, 30, 5))
	ChoGGi_Funcs.Common.UpdateConsoleMargins(dlgConsole:GetVisible())

	-- IdBottomContainer isn't added when i normally setup the console stuff (ModsReloaded)
	local bottom = XShortcutsTarget.idBottomContainer
	if bottom and bottom.HAlign ~= "left" then
		bottom:SetHAlign("left")
	end

	-- add close button
	g_Classes.ChoGGi_XCloseButton:new({
		Id = "idClose",
		OnPress = function()
			dlgConsole:Show()
		end,
		Margins = box(0, 0, 0, -24),
		Dock = "bottom",
		VAlign = "bottom",
		HAlign = "right",
	}, dlgConsole)

	-- stick everything in
	dlgConsole.idContainer = g_Classes.XWindow:new({
		Id = "idContainer",
		Margins = box(6, 0, 0, 5),
		HAlign = "left",
		Dock = "bottom",
		LayoutMethod = "HList",
		Image = "CommonAssets/UI/round-frame-20.tga",
	}, dlgConsole)

-- -----------------------------Console popup
	dlgConsole.idConsoleMenu = g_Classes.ChoGGi_XConsoleButton:new({
		Id = "idConsoleMenu",
		RolloverText = T(302535920001089--[[Settings & Commands for the console.]]),
		Text = T(302535920001308--[[Settings]]),
		OnPress = function()
			-- update value
			local idx = table.find(ConsoleMenuPopupToggle_list, "value", "ChoGGi.UserSettings.ConsoleSkipUndefinedGlobals")
			if #ChoGGi.Temp.UndefinedGlobals > 0 then
				ConsoleMenuPopupToggle_list[idx].name = T(302535920000310--[[Skip Undefined Globals]]) .. " (" .. #ChoGGi.Temp.UndefinedGlobals .. ")"
			else
				ConsoleMenuPopupToggle_list[idx].name = T(302535920000310--[[Skip Undefined Globals]])
			end
			PopupToggle(dlgConsole.idConsoleMenu, "idConsoleMenuPopup", ConsoleMenuPopupToggle_list, "top")
		end,
	}, dlgConsole.idContainer)

	dlgConsole.idToolsMenu = g_Classes.ChoGGi_XConsoleButton:new({
		Id = "idToolsMenu",
		RolloverText = T(302535920000127--[[Various tools to use.]]),
		Text = T(302535920000239--[[Tools]]),
		OnPress = function()
			PopupToggle(dlgConsole.idToolsMenu, "idToolsMenuPopup", ToolsMenuPopupToggle_list, "top")
		end,
	}, dlgConsole.idContainer)

	dlgConsole.idExamineMenu = g_Classes.ChoGGi_XConsoleButton:new({
		Id = "idExamineMenu",
		RolloverText = T(302535920000491--[[Examine Object]]),
		Text = T(302535920000069--[[Examine]]),
		OnPress = function()
			PopupToggle(dlgConsole.idExamineMenu, "idExamineMenuPopup", ExamineMenuToggle_list, "top")
		end,
	}, dlgConsole.idContainer)

	dlgConsole.idHistoryMenu = g_Classes.ChoGGi_XConsoleButton:new({
		Id = "idHistoryMenu",
		RolloverText = T(302535920001080--[[Console history items (mouse-over to see code).]]),
		Text = T(302535920000793--[[History]]),
		OnPress = ChoGGi_Funcs.Console.HistoryPopup,
	}, dlgConsole.idContainer)

	if not blacklist then
		dlgConsole.idScripts = g_Classes.XWindow:new({
			Id = "idScripts",
			LayoutMethod = "HList",
		}, dlgConsole.idContainer)
	end

	-- changed examine list to a saved one instead of one made of .lua files
	ChoGGi_Funcs.Console.BuildExamineMenu()
end

local function BuildSciptButton(console, folder)
	ChoGGi_XConsoleButton:new({
		RolloverText = folder.RolloverText,
		Text = folder.Text,
		OnPress = function(self)
			-- build list of scripts to show
			local items = {}
			local files = RetFilesInFolder(folder.script_path, ".lua")
			if files then
				for i = 1, #files do
					local err, script = g_env.AsyncFileToString(files[i].path)
					if not err then
						items[i] = {
							name = files[i].name,
							hint = T(302535920001138--[["Execute this command in the console, Right-click to paste code in console."]]) .. "\n\n" .. script,
							hint_bottom = T(302535920000407--[[<left_click> Execute <right_click> Paste]]),
							mouseup = function(_, _, _, button)
								if button == "R" then
									dlgConsole.idEdit:SetFocus()
									dlgConsole.idEdit:SetText(script)
									dlgConsole.idEdit:SetCursor(1, #script)
								else
									if script:find("-- rem echo on") then
										console:Exec(script)
									else
										console:Exec(script, true)
									end
								end
							end,
						}
					end
				end
				PopupToggle(self, folder.id, items, "top")
			else
				print(Translate(591853191640--[[Empty list]]))
			end
		end,
	}, console.idScripts)
end

-- only check for ECM Scripts once per load
local script_files_added
-- rebuild menu toolbar buttons
function ChoGGi_Funcs.Console.RebuildConsoleToolbar(dlg)
	if blacklist then
		return
	end

	if not dlg then
		dlg = dlgConsole
	end

	if not dlg.idScripts then
		-- we're in the select new map stuff screen
		return
	end

	-- add example script files if folder is missing
	if not script_files_added then
		ChoGGi_Funcs.Console.BuildScriptFiles()
		script_files_added = true
	end

	-- clear out old buttons first
	for i = #dlg.idScripts, 1, -1 do
		dlg.idScripts[i]:Close()
	end

	-- add my testing funcs
	if testing then
		ChoGGi_XConsoleButton:new({
			RolloverText = "Funcs in ChoGGi.testing",
			Text = "Testing",
			OnPress = function(self)
				-- build list of scripts to show
				local items = {}
				local c = 0
				local funcs = ChoGGi.testing
				for id, func in pairs(funcs) do
					c = c + 1
					items[c] = {
						name = id,
						hint = T(302535920001138--[["Execute this command in the console, Right-click to paste code in console."]]),
						hint_bottom = T(302535920000407--[[<left_click> Execute <right_click> Paste]]),
						mouseup = func,
					}
				end
				table.sort(items, function(a, b)
					CmpLower(a.name, b.name)
				end)
				PopupToggle(self, "ChoGGi_Testing_Funcs", items, "top")
			end,
		}, dlg.idScripts)
	end

	-- build Scripts button
	if RetFilesInFolder(ChoGGi.scripts, ".lua") then
		BuildSciptButton(dlg, {
			Text = T(302535920000353--[[Scripts]]),
			RolloverText = Translate(302535920000881--[[Place .lua files in <green>%s</green> to have them show up in the ""Scripts"" list. You can also create sub-folders for sorting.]]):format(ChoGGi.scripts),
			id = "idScriptsMenuPopup",
			script_path = ChoGGi.scripts,
		})
	end

	-- check for any folders with lua files in ECM Scripts
	local folders = ChoGGi_Funcs.Common.RetFoldersInFolder(ChoGGi.scripts)
	if folders then
		local hint_str = Translate(302535920001159--[[Any .lua files in %s.]])
		for i = 1, #folders do
			local folder = folders[i]
			if RetFilesInFolder(folder.path, ".lua") then
				BuildSciptButton(dlg, {
					Text = folder.name,
					RolloverText = hint_str:format(folder.path),
					id = "id" .. folder.name .. "MenuPopup",
					script_path = folder.path,
				})
			end
		end
	end
end

function ChoGGi_Funcs.Console.BuildScriptFiles()
	local script_path = ChoGGi.scripts
	-- create folder and some example scripts if folder doesn't exist
	if not ChoGGi_Funcs.Common.FileExists(script_path .. "/readme.txt") then
		g_env.AsyncCreatePath(script_path .. "/Functions")
		-- print some info
		print(Translate(302535920000881--[["Place .lua files in %s to have them show up in the ""Scripts"" list, you can then use the list to execute them (you can also create sub-folders for sorting)."]]):format(ConvertToOSPath(script_path)))
		-- add some example files and a readme
		g_env.AsyncStringToFile(script_path .. "/readme.txt", T(302535920000888--[[Any .lua files in here will be part of a list that you can execute in-game from the console menu.]]))
		g_env.AsyncStringToFile(script_path .. "/Read Me.lua", [[ChoGGi_Funcs.Common.MsgWait(ChoGGi_Funcs.Common.Translate(302535920000881):format(ChoGGi.scripts))]])
		g_env.AsyncStringToFile(script_path .. "/Functions/Amount of colonists.lua", [[#(UICity.labels.Colonist or "")]])
		g_env.AsyncStringToFile(script_path .. "/Functions/Toggle Working SelectedObj.lua", [[SelectedObj:ToggleWorking()]])
	end
end
