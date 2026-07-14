-- See LICENSE for terms

-- go away... (mostly just benchmarking funcs, though there is the func i use for "Map Images Pack" to make them, probably should put it in Common)

--~ ChoGGi_Funcs.Common.TickStart("Tick.1")
--~ ChoGGi_Funcs.Common.TickEnd("Tick.1")

if not ChoGGi.testing then
	return
end


--~ -- spam me please
--~ function PopsTelemetrySend(...)
--~ 	print("<color ChoGGi_green>PopsTel</color>", ...)
--~ end

local ChoGGi_Funcs = ChoGGi_Funcs
local what_game = ChoGGi.what_game
local Translate = ChoGGi_Funcs.Common.Translate

local g_env, debug
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	g_env, debug = env, env.debug

--~ 	-- Load up my bug fixes mod
--~ 	CurrentModDef.options.EnableMod = true
--~ 	CurrentModDef.options.PlanetaryAnomalyBreakthroughs = true
--~ 	g_env.loadfile("AppData/Mods/Mods ChoGGi/Fix Bugs/Code/Script.lua", "run_test_script" , CurrentModDef.env)
--~ 	print("Fix Bugs code enabled!")
end

-- I fucking hate modal windows
XWindow.SetModal = empty_func

if what_game == "Mars" then

--~ 	-- Close enough
--~ 	local ChoOrig_AchievementUnlock = AchievementUnlock
--~ 	function AchievementUnlock(xplayer, achievement,  ...)
--~ 		print("AchievementUnlock", achievement)
--~ 		return ChoOrig_AchievementUnlock(xplayer, achievement, ...)
--~ 	end

	-- No more blue overlay when paused
	DialogsHidingPauseDlg.HUD = true

	-- override till they fix double click select all of type
	local orig_OnMouseButtonDoubleClick = SelectionModeDialog.OnMouseButtonDoubleClick
	function SelectionModeDialog:OnMouseButtonDoubleClick(pt, button, ...)
		if button ~= "L" then
			return orig_OnMouseButtonDoubleClick(self, pt, button, ...)
		end

		-- from orig func:
		local result = UnitDirectionModeDialog.OnMouseButtonDoubleClick(self, pt, button)
		if result == "break" then
			return result
		end

		-- we already checked what button it is above, so no need to check again

		local obj = SelectionMouseObj()
		-- copied SelectObj(obj) up here so SelectedObj == obj works...
		SelectedObj = obj

		if obj and SelectedObj == obj and IsKindOf(obj, "SupplyGridSwitch") and obj.is_switch then
			obj:Switch()
		end
		if obj and SelectedObj == obj then
			local selection_class = GetSelectionClass(obj)
			local new_objs = GatherObjectsOnScreen(obj, selection_class)
			if new_objs and 1 < #new_objs then
				obj = MultiSelectionWrapper:new({selection_class = selection_class, objects = new_objs})
			end
		end
		-- Why am I sometimes getting "Attempt to use an undefined global 'SelectedObj'" from here when closing a bunch of ecm dialogs?
		SelectObj(obj)
		return "break"
	end


	-- Log spam from trains dlc
	if g_AvailableDlc.prunariu then
		TrainsLogging.error = empty_func
	end
end

local table = table

-- -------------------

--~ if LuaRevision <= 1001514 then
--~ local Colonist = Colonist
--~ local funcs = {
--~ 	"LogStatClear",
--~ 	"AddToLog",
--~ }
--~ for i = 1, #funcs do
--~ 	local func = Colonist[funcs[i]]
--~ 	Colonist[funcs[i]] = function(self, log, ...)
--~ 		if log then
--~ 			return func(self, log, ...)
--~ 		end
--~ 	end
--~ end

-- -------------------
--~ function IsDevelopmentSandbox()
--~ 	return true
--~ end

--~ end


-- load up onmsg prints
--~ dofile("AppData/Mods/Mods ChoGGi/OnMsg Print/Code/Script.lua")

-- hopefully they'll report "LUA ERROR"s one of these days
function OnMsg.OnLuaError(err, stack, ...)
	print("OnLuaError", err, stack, ...)
end
function OnMsg.OnModLuaError(err, stack, ...)
	print("OnModLuaError", err, stack, ...)
end

-- for some annoying reason my account settings are sometimes reset, so (probably something to do with some pop funcs I block)
if not ChoGGi.blacklist then
	local as = AccountStorage
	as.Options.AutoPinDomes = false
	as.Options.AutoPinDroneHubs = false
	as.Options.AutoPinFounders = false
	as.Options.AutoPinRareColonists = false
	as.Options.AutoPinRovers = false
	as.Options.Autosave = false
	as.Options.HintsEnabled = false
	as.Options.TerraformingHintsEnabled = false
	as.CompletedTutorials = as.CompletedTutorials or {}
	as.CompletedTutorials.Tutorial1 = true
	as.Shortcuts["ECM.Debug.Object.Delete Object(s)"] = {"Ctrl-Shift-D"}
end

local function StartUp()
	-- print startup msgs to console log
	local msgs = ChoGGi.Temp.StartupMsgs
	for i = 1, #msgs do
		print(msgs[i])
	end
	table.iclear(msgs)

	print("<color 200 200 200>ECM</color>: <color 128 255 128>Testing Enabled</color>")
end

OnMsg.LoadGame = StartUp
OnMsg.CityStart = StartUp

do -- ExportTranslatedStrings (CSV FILES)
	local CmpLower = CmpLower
	local TGetID = TGetID
	local table_sort = table.sort

	local function SortList(list)
		table_sort(list, function(a, b)
			return CmpLower(a.name_en, b.name_en)
		end)
		return list
	end

	local csv_columns = {
		-- used this to find strs in picard.csv
--~ 		"str_id",
		"name_en",
		"name_br",
		"name_fr",
		"name_ge",
		"name_po",
		"name_ru",
		"name_sc",
		"name_sp",
		"name_tr",
	}
	local csv_columns_br = table.icopy(csv_columns)
	table.insert(csv_columns_br, 1, "break_id")


	local langs
	local Translate = ChoGGi_Funcs.Common.Translate

	local function GetStr(locale_id, str_id)
		-- I could make this less ugly, but
		if langs[locale_id][str_id] then
			return langs[locale_id][str_id]
		elseif langs[locale_id .. "_p"][str_id] then
			return langs[locale_id .. "_p"][str_id]
		else
			-- in other csv file, needs to be manually copied into "main" one for each lang :(
			print("MISSING STR ID", locale_id, str_id)
		end
	end

	-- export csv files containing translated strings (csv files need to be in game profile (where saves are)
	-- csv files can be found in game dir\Local\*.hpk
	function ChoGGi.testing.ExportTranslatedStrings()
		-- lists of str_id > string
		langs = {
			en = TranslationTable,
			br = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Brazilian.csv"),
			fr = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/French.csv"),
			ge = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/German.csv"),
			po = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Polish.csv"),
			ru = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Russian.csv"),
			sc = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Schinese.csv"),
			sp = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Spanish.csv"),
			tr = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Turkish.csv"),
			-- picard (B&B)
			br_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Brazilian_p.csv"),
			fr_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/French_p.csv"),
			ge_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/German_p.csv"),
			po_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Polish_p.csv"),
			ru_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Russian_p.csv"),
			sc_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Schinese_p.csv"),
			sp_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Spanish_p.csv"),
			tr_p = ChoGGi_Funcs.Common.RetLangTable("AppData/csv/Turkish_p.csv"),
		}

		local time = os.time()

		-- breakthroughs
		local export_bt_names, export_bt_desc = {}, {}
		local breakthroughs = Presets.TechPreset.Breakthroughs
		for i = 1, #breakthroughs do
			local tech = breakthroughs[i]
			local str_id = TGetID(tech.display_name)
			export_bt_names[i] = {
--~ 				str_id = str_id,
				break_id = tech.id,
				name_en = langs.en[str_id],
				name_br = GetStr("br", str_id),
				name_fr = GetStr("fr", str_id),
				name_ge = GetStr("ge", str_id),
				name_po = GetStr("po", str_id),
				name_ru = GetStr("ru", str_id),
				name_sc = GetStr("sc", str_id),
				name_sp = GetStr("sp", str_id),
				name_tr = GetStr("tr", str_id),
			}

			str_id = TGetID(tech.description)
			export_bt_desc[i] = {
				-- we need to add the tech as context to update the string params
--~ 				str_id = str_id,
				break_id = tech.id,
				name_en = Translate(langs.en[str_id],tech),
				name_br = Translate(GetStr("br", str_id),tech),
				name_fr = Translate(GetStr("fr", str_id),tech),
				name_ge = Translate(GetStr("ge", str_id),tech),
				name_po = Translate(GetStr("po", str_id),tech),
				name_ru = Translate(GetStr("ru", str_id),tech),
				name_sc = Translate(GetStr("sc", str_id),tech),
				name_sp = Translate(GetStr("sp", str_id),tech),
				name_tr = Translate(GetStr("tr", str_id),tech),
			}
		end
--~ ex(export_bt_names)
--~ ex(export_bt_desc)
		SaveCSV("AppData/csv/export_bt_names-" .. time .. ".csv", export_bt_names, csv_columns_br, csv_columns_br)
		SaveCSV("AppData/csv/export_bt_desc-" .. time .. ".csv", export_bt_desc, csv_columns_br, csv_columns_br)

		-- location names
		local export_data_locations = {}
		local MarsLocales = MarsLocales
		local c = 0
		for  _, location in pairs(MarsLocales) do
			local str_id = TGetID(location)
			c = c + 1
			export_data_locations[c] = {
--~ 				str_id = str_id,
				name_en = langs.en[str_id],
				name_br = GetStr("br", str_id),
				name_fr = GetStr("fr", str_id),
				name_ge = GetStr("ge", str_id),
				name_po = GetStr("po", str_id),
				name_ru = GetStr("ru", str_id),
				name_sc = GetStr("sc", str_id),
				name_sp = GetStr("sp", str_id),
				name_tr = GetStr("tr", str_id),
			}
		end
		SortList(export_data_locations)
		SaveCSV("AppData/csv/export_locations-" .. time .. ".csv", export_data_locations, csv_columns, csv_columns)
--~ ex(export_data_locations)

		-- location info
		local export_data_misc = {}
		local export_misc = {
				-- topography
				4154,-- Relatively Flat
				4155,-- Rough
				4156,-- Steep
				4157,-- Mountainous
				-- threats
				4142,-- Dust Devils
				4148,-- Cold Waves
				4144,-- Dust Storms
				4146,-- Meteors
				-- resources
				3514,-- Metals
				4139,-- Rare Metals
				3513,-- Concrete
				681,-- Water
				-- misc
				284813068603,-- Topography
				7396,-- Location
				11457,-- Coordinates
				11451,-- Breakthrough
				4141,-- Temperature
				4135,-- Altitude
				692,-- Resources
				4271,-- THREATS
				10941,-- Rating (ASC)
				10943,-- Rating (DESC)
		}
		for i = 1, #export_misc do
			local str_id = export_misc[i]
			export_data_misc[i] = {
--~ 				str_id = str_id,
				name_en = langs.en[str_id],
				name_br = GetStr("br", str_id),
				name_fr = GetStr("fr", str_id),
				name_ge = GetStr("ge", str_id),
				name_po = GetStr("po", str_id),
				name_ru = GetStr("ru", str_id),
				name_sc = GetStr("sc", str_id),
				name_sp = GetStr("sp", str_id),
				name_tr = GetStr("tr", str_id),
			}
		end
		SaveCSV("AppData/csv/export_misc-" .. time .. ".csv", export_data_misc, csv_columns, csv_columns)
--~ ex(export_data_misc)

	end
end -- do

function ChoGGi.testing.ExportBuildingFootprints()
	if not UICity then
		return
	end

	-- show position grid
--~ 	local action = XAction:new()
--~ 	action.setting_mask = "position"
--~ 	ChoGGi_Funcs.Common.BuildableHexGrid(action)

--~ 	LightmodelPresets.TheMartian1_Night.exterior_envmap = nil
--~ 	SetLightmodelOverride(1, "TheMartian1_Night")
	hr.FarZ = 7000000
	local cam_params = {GetCamera()}
	cam_params[4] = 5000
	SetCamera(table.unpack(cam_params))

	local obj = ChoGGi_OBuildingEntityClass:new()


	local parent = Dialogs.HUD
	if not parent.ChoGGi_TempBuildingName then
		parent.ChoGGi_TempBuildingName = XWindow:new({
			Id = "ChoGGi_TempBuildingName",
		}, parent)
	end
	parent = parent.ChoGGi_TempBuildingName
	local text_dlg = XText:new({
		TextStyle = "LandingPosNameAlt",
--~ 		Padding = padding_box,
--~ 		Margins = c == 3 and margin_box_trp or c == 2 and margin_box_dbl or margin_box,
--~ 		Background = background,
		Dock = "box",
		HAlign = "left",
		VAlign = "top",
		Clip = false,
		UseClipBox = false,
		HandleMouse = false,
	}, parent)
	text_dlg:SetVisible(true)
	text_dlg:AddDynamicPosModifier{
		id = "sector_info",
		target = obj,
	}

--~ 	ex(text_dlg)


	-- crash prevention
	obj:SetState("idle")
	obj:SetPos(GetCursorWorldPos())
	obj:SetGameFlags(const.gofPermanent+const.gofUnderConstruction)

	local print = print
	local WriteScreenshot = WriteScreenshot
	local WaitMsg = WaitMsg
	local Sleep = Sleep
	local SetCamera = SetCamera
	local ObjHexShape_Toggle = ChoGGi_Funcs.Common.ObjHexShape_Toggle

	local HexOutlineShapes = HexOutlineShapes

	local zoom_out = {
		DomeDiamond = true,
		DomeMega = true,
		DomeMegaTrigon = true,
		DomeTrigon = true,
		GeoscapeDome = true,
		OpenCity = true,
		OpenFarm = true,
		TheExcavator = true,
	}

	CreateRealTimeThread(function()
--~	local c = 0
	local BuildingTemplates = BuildingTemplates
		for id, template in pairs(BuildingTemplates) do
--~ 			c = c + 1
--~ 			if c == 25 then
--~ 				break
--~ 			end

			text_dlg:SetText(id)

			local entity = template.construction_entity ~= "" and template.construction_entity
				or template.entity

			obj:ChangeEntity(entity)
			obj.entity = entity

			ObjHexShape_Toggle(obj, {
				shape = HexOutlineShapes[entity] or empty_table,
				skip_return = true,
--~ 				depth_test = choice.check1,
--~ 				hex_pos = true,
--~ 				skip_clear = choice.check3,
				colour1 = white,
--~ 				colour2 = red,
			})
			-- build and place hexes to mark ground

			if id:sub(1, 9) ~= "Landscape" then
				if zoom_out[id] then
					cam_params[4] = 10000
				else
					cam_params[4] = 5000
				end
				SetCamera(table.unpack(cam_params))

				Sleep(50)

				WaitMsg("OnRender")

				local name = "AppData/BUILDING_" .. id .. ".tga"
				WriteScreenshot(name)
				WaitMsg("OnRender")
				print(name)
			end


		end

			Sleep(50)
			ChoGGi_Funcs.Common.ObjHexShape_Clear(obj)
			ChoGGi_Funcs.Common.DeleteObject(obj)
	end)

end

local function Screenie(map)
	-- a mystery without anything visible added to the ground
	g_CurrentMissionParams.idMystery = "BlackCubeMystery"
	local gen = RandomMapGenerator:new()
	gen.BlankMap = map
	-- see PrefabMarker.lua for these
	gen.AnomEventCount = 0
	gen.AnomTechUnlockCount = 0
	gen.AnomFreeTechCount = 0
	gen.FeaturesRatio = 0
	-- load the map
	gen:Generate()

	-- don't fire the rest till map is good n loaded
	WaitMsg("MessageBoxOpened")
	-- close welcome to mars msg
	if Dialogs.PopupNotification then
		Dialogs.PopupNotification:Close()
	end

--~ 	-- pause it for now (it helps it not freeze)
--~ 	SetGameSpeedState("pause")
--~ 	-- wait a bit till we're sure the map is around
--~ 	Sleep(1000)

	-- wait a bit till we're sure the map is around
	local UICity = UICity
	while not UICity do
		Sleep(1000)
	end
--~ 	local GameState = GameState
--~ 	while not GameState.gameplay do
--~ 		Sleep(1000)
--~ 	end

	-- hide signs (just in case any are in the currently exposed sector)
	SetSignsVisible(false)
	-- hide all the sector markers
	local sectors = UICity.MapSectors
	for sector in pairs(sectors) do
		if type(sector) ~= "number" and sector.decal then
--~ 			sector.decal:SetVisible(false)
			sector.decal:delete()
		end
	end

	-- remove black curtains on the sides
	table.remove_entry(terminal.desktop, XTemplate, "OverviewMapCurtains")
	-- and the rest of the ui
	local Dialogs = Dialogs
	for _, value in pairs(Dialogs) do
		if type(value) ~= "string" then
			value:delete()
		end
	end

	-- lightmodel
	LightmodelPresets.TheMartian1_Night.exterior_envmap = nil
	SetLightmodelOverride(1, "TheMartian1_Night")
	-- underground
	hr.RenderRevealDarkness = 0

--~ 	if not cam_params then
--~ 	print("cam_params",cam_params)
		-- larger render dist (we zoom out a fair bit)
		hr.FarZ = 7000000
		-- zoom out for the whole map (more purple)
--~ 		cam_params = {GetCamera()}
		local cam_params = {GetCamera()}
		cam_params[4] = 10500
		-- manually load map, zoom in then use these
--~ 		-- asteroids
--~ 		cam_params[4] = 96000
--~ 		cam_params[5].MaxZoom = 96000
--~ 		-- undergound
--~ 		cam_params[4] = 128000
--~ 		cam_params[5].MaxZoom = 128000
		SetCamera(table.unpack(cam_params))
--~ 	end

	ChoGGi_Funcs.Common.CloseDialogsECM()
	-- and a bit more delay
	Sleep(1000)
	WaitMsg("OnRender")

	local name = "AppData/" .. map .. ".tga"
	WriteScreenshot(name)
	WaitMsg("OnRender")
	print(name)
end
--~ ChoGGi.testing.LoadMapForScreenShot("BlankBigCanyonCMix_04")
-- you'll need to load this from main menu (doesn't work from within the game yet)
function ChoGGi.testing.LoadMapForScreenShot(map)
	if CurrentThread() then
		Screenie(map)
	else
		CreateRealTimeThread(Screenie, map)
	end
end

-- just needs the save file name
-- ExportSave("NOMODS")
function ChoGGi.testing.ExportSave(name)
	-- LoadWithBackup needs a thread
	CreateRealTimeThread(function()
		name = name .. ".savegame.sav"

		-- make sure the folder exists
		g_env.AsyncDeletePath("AppData/ExportedSave")
		g_env.AsyncCreatePath("AppData/ExportedSave")

		local err = MountPack("exported", "AppData/ExportedSave/" .. name, "create, compress")
		if err then
			print(err)
			return
		end
		Savegame.LoadWithBackup(name, function(folder)
			local err, files = g_env.AsyncListFiles(folder, "*", "relative")
			if err then
				print(err)
				return
			end
			for i = 1, #files do
				local file = files[i]
				g_env.AsyncCopyFile(folder .. file, "AppData/ExportedSave/" .. file, "raw")
			end
		end)

		Unmount("exported")
		print("Exported", name)
	end)
end
--[[
MountPack("exported", "AppData/ExportedSave/NAME.savegame.sav")
CreateRealTimeThread(function()
Savegame.LoadWithBackup("NAME.savegame.sav", function(folder, ...)
print(folder, ...)
local err, files = io.listfiles(folder, "*", "relative")
if err then
	print(err)
end
for i = 1, #files do
	print(folder, files[i])
end
end)
end)
]]
--~ 	local size = io.getsize("D:/SteamGames/steamapps/common/Surviving Mars/!profile/ExportedSave/persist")
--~ 	local str = select(2,
--~ 	AsyncFileToString("D:/SteamGames/steamapps/common/Surviving Mars/!profile/ExportedSave/persist", size, 0, "string", "raw")
--~ 	)
--~ 	print(AsyncDecompress(str))
--~
--~ 	ChoGGi_Funcs.Common.Dump(str, nil, "DumpedLua", "lua")



-- benchmarking stuff
function ChoGGi.testing.Sleeping()
	CreateRealTimeThread(function()
		local Sleep = Sleep
		local WaitMsg = WaitMsg

		ChoGGi_Funcs.Common.TickStart("Sleeping.1.Tick")
			for _ = 1, 100 do
				Sleep(1)
			end
		ChoGGi_Funcs.Common.TickEnd("Sleeping.1.Tick")

		ChoGGi_Funcs.Common.TickStart("Sleeping.2.Tick")
			for _ = 1, 100 do
				WaitMsg("OnRender")
			end
		ChoGGi_Funcs.Common.TickEnd("Sleeping.2.Tick")
	end)
end

function ChoGGi.testing.ConcatvsT()
	ChoGGi_Funcs.Common.TickStart("ConcatvsT.1.Tick")
	for _ = 1, 100000 do
		local str = "1" .. "2" .. "a" .. "b" .. "g" .. "7" .. "k" .. "0"
		Translate(str)
	end
	ChoGGi_Funcs.Common.TickEnd("ConcatvsT.1.Tick")

	ChoGGi_Funcs.Common.TickStart("ConcatvsT.2.Tick")
	for _ = 1, 100000 do
		local str = T{"<str1><str2><str3><str4><str5><str6><str7><str8>",
			str1 = "1",
			str2 = "2",
			str3 = "a",
			str4 = "b",
			str5 = "g",
			str6 = "7",
			str7 = "k",
			str8 = "0",
		}
		Translate(str)
	end

	ChoGGi_Funcs.Common.TickEnd("ConcatvsT.2.Tick")
end

function ChoGGi.testing.ConcatingTables()
	ChoGGi_Funcs.Common.TickStart("ConcatingTables.1.Tick")
	for i = 1, 100000 do
		local str = "AAAA" .. "BBBB" .. "CCCCC" .. "DDDDD" .. i .. "FFFFFFF" .. "GGGGGGGG" .. "EEEEEEEEE" .. "JJJJJJJJJJ"
    if str then
    end
	end
	ChoGGi_Funcs.Common.TickEnd("ConcatingTables.1.Tick")

	ChoGGi_Funcs.Common.TickStart("ConcatingTables.2.Tick")
	local text_table = {"AAAA","BBBB","CCCCC","","DDDDD","FFFFFFF","GGGGGGGG","EEEEEEEEE","JJJJJJJJJJ",}
	for i = 1, 100000 do
		text_table[5] = i
		local str = table.concat(text_table)
    if str then
    end
  end
	ChoGGi_Funcs.Common.TickEnd("ConcatingTables.2.Tick")
end

function ChoGGi.testing.NearestObjFromList()
	if #ChoGGi_Funcs.Common.GetCityLabels("Building") == 0 then
		print("NearestObjFromList: NO BUILDINGS ABORT")
		return
	end

	local objs = ChoGGi_Funcs.Common.GetCityLabels("Building")
	local base_obj = table.rand(objs)
	local obj_pos = base_obj:GetPos()

	ChoGGi_Funcs.Common.TickStart("NearestObjFromList.1.Tick")
	local FindNearestObject = FindNearestObject
	local function NotSelf(obj)
		return obj ~= base_obj
	end

	for _ = 1, 1000 do
		FindNearestObject(objs, base_obj, NotSelf)
	end
	ChoGGi_Funcs.Common.TickEnd("NearestObjFromList.1.Tick")

	ChoGGi_Funcs.Common.TickStart("NearestObjFromList.2.Tick")
	local max_int = max_int

	for _ = 1, 1000 do
		local length = max_int
		local nearest = objs[1]
		local new_length, spot
		for i = 1, #objs do
			spot = objs[i]
			new_length = spot:GetPos():Dist2D(obj_pos)
			if new_length < length then
				length = new_length
				nearest = spot
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("NearestObjFromList.2.Tick")

end

function ChoGGi.testing.TableSortVsLoop()
	local obj_pos = GetRandomPassablePoint(AsyncRand())
	local objs = ChoGGi_Funcs.Common.GetCityLabels("SurfaceDepositMarker")

	-- faster
	ChoGGi_Funcs.Common.TickStart("TableSortVsLoop.1.Tick")
	for _ = 1, 1000 do
		local temp_table = table.icopy(objs)
		local length = max_int
		local nearest = temp_table[1]
		local new_length, spot
		for i = 1, #temp_table do
			spot = temp_table[i]:GetPos()
			new_length = spot:Dist2D(obj_pos)
			if new_length < length then
				length = new_length
				nearest = spot
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("TableSortVsLoop.1.Tick")

	ChoGGi_Funcs.Common.TickStart("TableSortVsLoop.2.Tick")
		local function SortNearest(a, b)
			return a:GetDist2D(obj_pos) < b:GetDist2D(obj_pos)
		end
		for _ = 1, 1000 do
			table.sort(table.icopy(objs), SortNearest)
		end
	ChoGGi_Funcs.Common.TickEnd("TableSortVsLoop.2.Tick")

end

function ChoGGi.testing.TableCountVsFirst()
	local list = MapGet(true)

	ChoGGi_Funcs.Common.TickStart("TableCountVsFirst.1.Tick")
	for _ = 1, 1000000 do
		if #list > 0 then
		end
	end
	ChoGGi_Funcs.Common.TickEnd("TableCountVsFirst.1.Tick")

	-- faster
	ChoGGi_Funcs.Common.TickStart("TableCountVsFirst.2.Tick")
	for _ = 1, 1000000 do
		if list[1] then
		end
	end
	ChoGGi_Funcs.Common.TickEnd("TableCountVsFirst.2.Tick")

end

function ChoGGi.testing.NegNumber()
	local num = 6565421
  local temp

	ChoGGi_Funcs.Common.TickStart("NegNumber.Tick.1")
	for _ = 1, 100000000 do
		temp = 0 - num
	end
	ChoGGi_Funcs.Common.TickEnd("NegNumber.Tick.1")

	-- maybe faster?
	ChoGGi_Funcs.Common.TickStart("NegNumber.Tick.2")
	for _ = 1, 100000000 do
		temp = -num
	end
	ChoGGi_Funcs.Common.TickEnd("NegNumber.Tick.2")

end

function ChoGGi.testing.LengthLocal()
	local objs = ChoGGi_Funcs.Common.GetCityLabels("SurfaceDepositMarker")

	ChoGGi_Funcs.Common.TickStart("LengthLocal.Tick.1")
	for _ = 1, 1000000 do
		local count = #objs
		if count > 0 then
			for i = 1, count do
				if objs[i] then
				end
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("LengthLocal.Tick.1")

	-- maybe faster?
	ChoGGi_Funcs.Common.TickStart("LengthLocal.Tick.2")
	for _ = 1, 1000000 do
		for i = 1, #objs do
			if objs[i] then
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("LengthLocal.Tick.2")

end

function ChoGGi.testing.IsKindOfSub()

	ChoGGi_Funcs.Common.TickStart("IsKindOfSub.Tick.1")
	local objs = ChoGGi_Funcs.Common.GetCityLabels("SurfaceDepositMarker")
	for _ = 1, 100000 do
		for i = #objs, 1, -1 do
			local obj = objs[i]
			if obj:IsKindOf("ElectricityGridElement") then
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("IsKindOfSub.Tick.1")

	-- faster
	ChoGGi_Funcs.Common.TickStart("IsKindOfSub.Tick.2")
	objs = ChoGGi_Funcs.Common.GetCityLabels("SurfaceDepositMarker")
	for _ = 1, 100000 do
		for i = #objs, 1, -1 do
			local obj = objs[i]
			if obj.entity:sub(1, 5) == "Cable" then
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("IsKindOfSub.Tick.2")

end

function ChoGGi.testing.LocalLoops()

	local AsyncRand = AsyncRand

	-- faster
	ChoGGi_Funcs.Common.TickStart("LocalLoops.Tick.1")
	for _ = 1, 100000000 do
		local x = AsyncRand()
		if x then
		end
	end
	ChoGGi_Funcs.Common.TickEnd("LocalLoops.Tick.1")

	ChoGGi_Funcs.Common.TickStart("LocalLoops.Tick.2")
	local x
	for _ = 1, 100000000 do
		x = AsyncRand()
		if x then
		end
	end
	ChoGGi_Funcs.Common.TickEnd("LocalLoops.Tick.2")

end

function ChoGGi.testing.StringVsDot()
	-- same

	local lookup_table = {a = true,b = true,c = true,d = true,e = true,f = true}

	ChoGGi_Funcs.Common.TickStart("StringVsDot.Tick.1")
	for _ = 1, 100000000 do
		if lookup_table["d"] then
		end
	end
	ChoGGi_Funcs.Common.TickEnd("StringVsDot.Tick.1")

	ChoGGi_Funcs.Common.TickStart("StringVsDot.Tick.2")
	for _ = 1, 100000000 do
		if lookup_table.d then
		end
	end
	ChoGGi_Funcs.Common.TickEnd("StringVsDot.Tick.2")

end


function ChoGGi.testing.LocalVsTableLookup()
	local lookup_table = {}
	for i = 1, 10000 do
		lookup_table[i] = true
	end

	local nothing
	ChoGGi_Funcs.Common.TickStart("LocalVsTableLookup.Tick.1")
	for _ = 1, 100000000 do
		local lookuped = lookup_table[12345]
		if lookuped then
			nothing = lookuped
		end
	end
	ChoGGi_Funcs.Common.TickEnd("LocalVsTableLookup.Tick.1")

	-- faster
	ChoGGi_Funcs.Common.TickStart("LocalVsTableLookup.Tick.2")
	for _ = 1, 100000000 do
		if lookup_table[12345] then
			nothing = lookup_table[12345]
		end
	end
	ChoGGi_Funcs.Common.TickEnd("LocalVsTableLookup.Tick.2")

end

function ChoGGi.testing.ToStr()

	-- faster
	ChoGGi_Funcs.Common.TickStart("ToStr.Tick.1")
	for _ = 1, 2000000 do
		local num = 12345
		num = num .. ""
	end
	ChoGGi_Funcs.Common.TickEnd("ToStr.Tick.1")

	ChoGGi_Funcs.Common.TickStart("ToStr.Tick.2")
	local tostring = tostring
	for _ = 1, 2000000 do
		local num = 12345
		num = tostring(num)
	end
	ChoGGi_Funcs.Common.TickEnd("ToStr.Tick.2")

end

function ChoGGi.testing.Attaches(obj)
	-- tables < 100
	-- local ForEachAttach(function(a), ForEachAttach, GetAttaches
	-- > 100 = GetAttaches

	obj = obj or ChoGGi_Funcs.Common.SelObject()
	if not IsValid(obj) then
		print("Test.Attaches invalid obj")
		return
	end

	-- faster
	ChoGGi_Funcs.Common.TickStart("Attaches.Tick.1")
	local function foreach(a)
		if a.handle then
		end
	end
	for _ = 1, 500000 do
		obj:ForEachAttach(foreach)
	end
	ChoGGi_Funcs.Common.TickEnd("Attaches.Tick.1")

	-- faster
	ChoGGi_Funcs.Common.TickStart("Attaches.Tick.2")
	for _ = 1, 500000 do
		obj:ForEachAttach(function(a)
			if a.handle then
			end
		end)
	end
	ChoGGi_Funcs.Common.TickEnd("Attaches.Tick.2")

	ChoGGi_Funcs.Common.TickStart("Attaches.Tick.3")
	for _ = 1, 500000 do
		local attaches = obj:GetAttaches() or ""
		for i = 1, #attaches do
			local a = attaches[i]
			if a.handle then
			end
		end
	end
	ChoGGi_Funcs.Common.TickEnd("Attaches.Tick.3")
end

function ChoGGi.testing.TextExamine()
	local OpenExamineReturn = OpenExamineReturn
	local WaitMsg = WaitMsg
	local list = MapGet(true)

	CreateRealTimeThread(function()
		ChoGGi_Funcs.Common.TickStart("TextExamine.Tick")
		for _ = 1, 10 do
			ChoGGi_Funcs.Common.TickStart("TextExamine.1.Tick")
			local dlg = OpenExamineReturn(list)
			WaitMsg("OnRender")
			dlg:delete()
			ChoGGi_Funcs.Common.TickEnd("TextExamine.1.Tick")
		end
		ChoGGi_Funcs.Common.TickEnd("TextExamine.Tick")
	end)

end

function ChoGGi.testing.TableIterate()
	-- not ipairs

	local list = MapGet(true)
	collectgarbage()

	ChoGGi_Funcs.Common.TickStart("TableIterate.1.Tick")
	for _ = 1, 1000 do
		for i = 1, #list do
			local id = list[i]
			type(id)
		end
	end
	ChoGGi_Funcs.Common.TickEnd("TableIterate.1.Tick")

	collectgarbage()
	local ipairs = ipairs

	ChoGGi_Funcs.Common.TickStart("TableIterate.2.Tick")
	for _ = 1, 1000 do
		for _, value in ipairs(list) do
			type(value)
		end
	end
	ChoGGi_Funcs.Common.TickEnd("TableIterate.2.Tick")

end

function ChoGGi.testing.TableInsert()

	-- faster
	ChoGGi_Funcs.Common.TickStart("TableInsert.1.Tick")
	local t1 = {}
	local c = 0
	for i = 0, 10000000 do
		c = c + 1
		t1[c] = i
	end
	ChoGGi_Funcs.Common.TickEnd("TableInsert.1.Tick")

	ChoGGi_Funcs.Common.TickStart("TableInsert.2.Tick")
	local rawset = rawset
	local t2 = {}
	local c2 = 0
	for i = 0, 10000000 do
		c2 = c2 + 1
		rawset(t2, c2, i)
	end
	ChoGGi_Funcs.Common.TickEnd("TableInsert.2.Tick")

end

-- compare compression speed/size
function ChoGGi.testing.Compress(amount)
	-- uncompressed TableToLuaCode(TranslationTable)
	-- #786351

	-- lz4 compressed to #407672
	-- 50 loops of AsyncDecompress(lz4_data)
	-- 155 ticks
	-- 50 loops of AsyncCompress(lz4_data)
	-- 1404 ticks
	-- 50 loops of compress/decompress
	-- 1512, 1491, 1491 ticks (did it three times)

	-- zstd compressed to #251660
	-- 50 loops of AsyncDecompress(zstd_data)
	-- 205 ticks
	-- 50 loops of AsyncCompress(zstd_data)
	-- 1508 ticks
	-- 50 loops of compress/decompress
	-- 1650, 1676, 1691 ticks (did it three times)

	local TableToLuaCode = TableToLuaCode
	local TranslationTable = TranslationTable
	local AsyncCompress = AsyncCompress
	local AsyncDecompress = AsyncDecompress

	ChoGGi_Funcs.Common.TickStart("Compress_lz4.Tick")
	for _ = 1, amount or 50 do
		local _, lz4_data = AsyncCompress(TableToLuaCode(TranslationTable), false, "lz4")
		AsyncDecompress(lz4_data)
	end
	ChoGGi_Funcs.Common.TickEnd("Compress_lz4.Tick")

	ChoGGi_Funcs.Common.TickStart("Compress_zstd.Tick")
	for _ = 1, amount or 50 do
		local _, zstd_data = AsyncCompress(TableToLuaCode(TranslationTable), false, "zstd")
		AsyncDecompress(zstd_data)
	end
	ChoGGi_Funcs.Common.TickEnd("Compress_zstd.Tick")

end

function ChoGGi.testing.RandomColour(amount)
	local RandomColour = ChoGGi_Funcs.Common.RandomColour
	local RandomColour2 = ChoGGi_Funcs.Common.RandomColour2

	local TickStart = ChoGGi_Funcs.Common.TickStart
	local TickEnd = ChoGGi_Funcs.Common.TickEnd
	TickStart("RandomColour.1.Total")
	for _ = 1, amount or 5 do
		TickStart("RandomColour.1.Tick")
		RandomColour(1000000)
		TickEnd("RandomColour.1.Tick")
	end
	TickEnd("RandomColour.1.Total")

	print("\n\n")
	TickStart("RandomColour2.Total")
	for _ = 1, amount or 5 do
		TickStart("RandomColour.2.Tick")
		RandomColour2(1000000)
		TickEnd("RandomColour.2.Tick")
	end
	TickEnd("RandomColour2.Total")
end


--~ -- for some reason this doesn't work on the selection panel when it's in Generate...
--~ if Mods.ChoGGi_testing then
--~ 	-- centred hud
--~ 	local GetScreenSize = UIL.GetScreenSize
--~ 	local margins = box(2560, 0, 2560, 0)
--~ 	local ChoOrig_GetSafeMargins = GetSafeMargins
--~ 	function GetSafeMargins(win_box)
--~ 		if win_box then
--~ 			return ChoOrig_GetSafeMargins(win_box)
--~ 		end
--~ 		-- If lookup table doesn't have width we fire orginal func
--~ 		return GetScreenSize():x() == 5760 and margins or ChoOrig_GetSafeMargins()
--~ 	end
--~ end
--~ do -- TraceCall/Trace (commented out in CommonLua\PropertyObject.lua)
--~ -- g_traceMeta
--~ -- g_traceEntryMeta
--~ 	-- needs to be true for traces to be active (see CommonLua\Classes\StateObject.lua)
--~ 	StateObject.so_debug_triggers = true
--~ 	-- CommonLua\Movable.lua
--~ 	function Movable:SetSpeed(speed)
--~ 		pf.SetSpeed(self, speed)
--~ 	end

--~ 	local GetStack = GetStack
--~ 	local GameTime = GameTime
--~ 	local rawget, rawset = rawget, rawset
--~ 	local setmetatable = setmetatable

--~ 	function PropertyObject:TraceCall(member)
--~ 		print("PropertyObject:TraceCall", self.class)
--~ 		local ChoOrig_member_fn = self[member]
--~ 		self[member] = function(self, ...)
--~ 			self:Trace("[Call]", member, GetStack(2), ...)
--~ 			return ChoOrig_member_fn(self, ...)
--~ 		end
--~ 	end
--~ 	function PropertyObject:Trace(...)
--~ 		print("PropertyObject:Trace", self.class)
--~ 		local t = rawget(self, "trace_log")
--~ 		if not t then
--~ 			t = {}
--~ 			setmetatable(t, g_traceMeta)
--~ 			rawset(self, "trace_log", t)
--~ 		end
--~ 		local threshold = GameTime() - (3000)
--~ 		while #t >= 50 and threshold > t[#t][1] do
--~ 			table.remove(t)
--~ 		end
--~ 		local data = {
--~ 			GameTime(),
--~ 			...
--~ 		}
--~ 		setmetatable(data, g_traceEntryMeta)
--~ 		table.insert(t, 1, data)
--~ 	end

--~ 	function SetCommandErrorChecks(self, command, ...)
--~ 		print("SetCommandErrorChecks", self.class)
--~ 		local destructors = self.command_destructors
--~ 		if command == "->Idle" and destructors and destructors[1] > 0 then
--~ 			print("Command", self.class .. "." .. tostring(self.command), "remaining destructors:")
--~ 			for i = 1, destructors[1] do
--~ 				local destructor = destructors[i + 1]
--~ 				local info = debug.getinfo(destructor, "S") or empty_table
--~ 				local source = info.source or "Unknown"
--~ 				local line = info.linedefined or -1
--~ 				printf("\t%d. %s(%d)", i, source, line)
--~ 			end
--~ 			error(string.format("Command %s.%s did not pop its destructors.", self.class, tostring(self.command)), 2)
--~ 		end
--~ 		if command and command ~= "->Idle" then
--~ 			if type(command) ~= "function" and not self:HasMember(command) then
--~ 				error(string.format("Invalid command %s:%s", self.class, tostring(command)), 3)
--~ 			end
--~ 			if IsBeingDestructed(self) then
--~ 				error(string.format("%s:SetCommand('%s') called from Done() or delete()", self.class, tostring(command)), 3)
--~ 			end
--~ 		end
--~ 		self.command_call_stack = GetStack(3)
--~ 		if self.trace_setcmd then
--~ 			if self.trace_setcmd == "log" then
--~ 				self:Trace("SetCommand", tostring(command), self.command_call_stack, ...)
--~ 			else
--~ 				error(string.format("%s:SetCommand(%s) time %d, old command %s", self.class, concat_params(", ", tostring(command), ...), GameTime(), tostring(self.command)), 3)
--~ 			end
--~ 		end
--~ 	end

--~ end -- do


--~ 		-- ParseText is picky about the text it'll parse
--~ 		local orig = XText.ParseText
--~ 		function XText:ParseText(...)
--~ 			local varargs = {...}
--~ 			local ret
--~ 			if not procall(function()
--~ 				ret = orig(self, table.unpack(varargs))
--~ 			end) then
--~ 				ChoGGi_Funcs.Common.Dump(self.text, "w", "ParseText", "lua", nil, true)
--~ 			end
--~ 			return ret
--~ 		end

--~ 		local ChoOrig_XImage_DrawContent = XImage.DrawContent
--~ 		local RetName = ChoGGi_Funcs.Common.RetName
--~ 		function XImage:DrawContent(...)
--~ 			local image = self:GetImage()
--~ 			-- unless it is bitching about memorysavegame :)
--~ 			if image ~= "" and not image:find("memorysavegame") and not ChoGGi_Funcs.Common.FileExists(image) then
--~ 				print(RetName(self.parent), image, "DC")
--~ 			end
--~ 			return ChoOrig_XImage_DrawContent(self, ...)
--~ 		end

--~ 		-- stop welcome to mars msg for LoadMapForScreenShot
--~ 		ShowStartGamePopup = empty_func
-- this is just for Map Images Pack. it loads the map, positions camera to fixed pos, and takes named screenshot
--~ ChoGGi.testing.LoadMapForScreenShot("BlankBigTerraceCMix_13")
--~ if false then
--~ 	CreateRealTimeThread(function()
--~ 		local MapData = MapDataPresets
--~ 		for map in pairs(MapData) do
--~ 			if map:sub(1, 5) == "Blank" then
--~ 				ChoGGi.testing.LoadMapForScreenShot(map)
--~ 				print(map)
--~ 			end
--~ 		end
--~ 	end)
--~ end
--~ LoadMapForScreenShot_cam_params = false


-- ---------------------------------------------------------------------------------------
--~ 	function OnMsg.ClassesGenerate()

--~ 	 end -- ClassesGenerate
-- ---------------------------------------------------------------------------------------
function OnMsg.ClassesPreprocess()
	-- removes some spam from logs (might cause weirdness so just for me)
	local umc = UnpersistedMissingClass
	local empty_func = empty_func
	umc.CanReserveResidence = empty_func
	umc.GetEntrance = empty_func
	umc.GetEntrancePoints = empty_func
	umc.GetUIStatusOverrideForWorkCommand = empty_func
	umc.HasFreeVisitSlots = empty_func
	umc.RefreshNightLightsState = empty_func
	umc.RemoveCommandCenter = empty_func
	umc.RemoveResident = empty_func
	umc.RemoveWorker = empty_func
	umc.SetIsNightLightPossible = empty_func
	umc.Unassign = empty_func
	umc.UpdateAttachedSigns = empty_func
--~ 	umc.SetCount = empty_func
--~ 	umc.GetFreeSpace = empty_func
--~ 	umc.GetFreeWorkSlots = empty_func

--~ 		-- fix the arcology dome spot
--~ 		OrigFunc("SpireBase", "GameInit")
--~ 		function SpireBase:GameInit()
--~ 			local dome = IsObjInDome(self)
--~ 			if self.spire_frame_entity ~= "none" and IsValidEntity(self.spire_frame_entity) then
--~ 				local frame = PlaceObjectIn("Shapeshifter", MainMapID)
--~ 				frame:ChangeEntity(self.spire_frame_entity)
--~ 				local spot = dome:GetNearestSpot("idle", "Spireframe", self)

--~ 				local pos = self:GetSpotPos(spot or 1)

--~ 				frame:SetAttachOffset(pos - self:GetPos())
--~ 				self:Attach(frame, self:GetSpotBeginIndex("Origin"))
--~ 			end
--~ 		end
-- ---------------------------------------------------------------------------------------
end -- ClassesPreprocess

--~ 		-- where we add new BuildingTemplates
--~ function OnMsg.ClassesPostprocess()

--~ end -- ClassesPostprocess
-- ---------------------------------------------------------------------------------------
--~ function OnMsg.ClassesBuilt()

--~ 		-- add an overlay for dead rover
--~ 		OrigFunc("PinsDlg", "GetPinConditionImage")
--~ 		function PinsDlg:GetPinConditionImage(obj)
--~ 			local ret = ChoGGi_Funcs.Original.PinsDlg_GetPinConditionImage(self, obj)
--~ 			if obj.command == "Dead" and not obj.working then
--~ 				print(obj.class)
--~ 				return "UI/Icons/pin_not_working.tga"
--~ 			else
--~ 				return ret
--~ 			end
--~ 		end

--~ local list = {}
--~ local c = 0
--~ local dlg
--~ local function hookTick(...)
--~ 	if not dlg then
--~ 		dlg = OpenExamineReturn(list, {
--~ 			has_params = true,
--~ 			auto_refresh = true,
--~ 	})
--~ 	end
--~ 	c = c + 1
--~ 	list[c] = {...}
--~ 	if c > 100 then
--~ 		table.iclear(list)
--~ 		c = 0
--~ 	end
--~ end

--~ function SetThreadDebugHookX(hook)
--~ 	local set_hook = hook or debug.sethook
--~ 	for thread in pairs(ThreadsRegister) do
--~ 		set_hook(thread, hookTick, "c", 10)
--~ 	end
--~ 	ThreadsEnableDebugHook(hook)
--~ 	ThreadDebugHook = hook or false
--~ end
--~ function DisableThreadDebugHookX(hook)
--~ 	local set_hook = hook or debug.sethook
--~ 	for thread in pairs(ThreadsRegister) do
--~ 		set_hook(thread)
--~ 	end
--~ 	ThreadsEnableDebugHook(hook)
--~ 	ThreadDebugHook = hook or false
--~ end

--~ if false then
--~ 	SetThreadDebugHookX(DebuggerSetHook)
--~ 	DebuggerSetHook()
--~ -- ThreadDebugHook
--~ end

-- load needed debug files
--~ 		local config = config
--~ 		config.TraceEnable = true
--~ 		config.LuaDebugger = true
--~ 		FirstLoad = true
--~ 		Loading = true
--~ 		Platform.developer = true
--~ 		dofile("CommonLua/Core/luasocket.lua")
--~ 		dofile("CommonLua/Core/luadebugger.lua")
--~ 		dofile("CommonLua/Core/luaDebuggerOutput.lua")
--~ 		dofile("CommonLua/Core/ProjectSync.lua")
--~ 		Platform.developer = false
--~ 		FirstLoad = false
--~ 		Loading = false
--[[
	-- don't expect much, unless you've got a copy of Haerald around
	outputSocket = false
	local function Mine_luadebugger_Start(self)
		if self.started then
			print("Already started")
			return
		end
		print("Starting the Lua debugger...")
		DebuggerInit()
		DebuggerClearBreakpoints()
		self.started = true
		local server = self.server
		local debugger_port = controller_port + 2
		controller_host = not Platform.pc and config.Haerald and config.Haerald.ip or "localhost"
		server:connect(controller_host, debugger_port)
		server:update()
		if not server:isconnected() then
			if Platform.pc then
				local processes = os.enumprocesses()
				local running = false
				for i = 1, #processes do
					if string.find(processes[i], "Haerald.exe") then
						running = true
						break
					end
				end
				if not running then
					local os_path = ConvertToOSPath(config.LuaDebuggerPath)
					local exit_code, std_out, std_error = os.exec(os_path)
					if exit_code ~= 0 then
					print("Could not launch Haerald Debugger from:", os_path, "\n\nExec error:", std_error , std_out)

print(0, "stop")
						self:Stop()
						return
					end
				end
			end
			local total_timeout = 6000
			local retry_timeout = Platform.pc and 100 or 2000
			local steps_before_reset = Platform.pc and 10 or 1
			local num_retries = total_timeout / retry_timeout
			for i = 1, num_retries do
				server:update()
				if not server:isconnected() then
					if not server:isconnecting() or i % steps_before_reset == 0 then
						server:close()
						server:connect(controller_host, debugger_port, retry_timeout)
					end
					os.sleep(retry_timeout)
				end
			end
			if not server:isconnected() then
				print("Could not connect to debugger at " .. controller_host .. ":" .. debugger_port)
print(1, "stop")
				self:Stop()
				return
			end
		end
		server.timeout = 5000
		self.watches = {}
		self.handle_to_obj = {}
		self.obj_to_handle = {}
		local PathRemapping
		if not Platform.pc then
			PathRemapping = config.Haerald and config.Haerald.PathRemapping or {}
		else
			PathRemapping = config.Haerald and config.Haerald.PathRemapping or {
				CommonLua = "CommonLua",
				Lua = Platform.cmdline and "" or "Lua",
				Data = Platform.cmdline and "" or "Data",
				Dlc = Platform.cmdline and "" or "Data/../Dlc",
				HGO = "HGO",
				Build = "CommonLua/../Tools/Build",
				Server = "Lua/../Tools/Server/Project",
				Shaders = "Shaders",
				ProjectShaders = "ProjectShaders"
			}
			for key, value in pairs(PathRemapping) do
				if value ~= "" then
					local game_path = value .. "/."
					local os_path, failed = ConvertToOSPath(game_path)
					if failed or not io.exists(os_path) then
						os_path = ""
					end
					PathRemapping[key] = os_path
				end
			end
		end
			local FileDictionaryPath = {
				"CommonLua",
				"Lua",
				"Dlc",
				"HGO",
				"Server",
				"Build"
			}
			local FileDictionaryExclude = {
				".svn",
				"__load.lua",
				".prefab.lua",
				".designer.lua",
				"/UIDesignerData/",
				"/Storage/"
			}
			local FileDictionaryIgnore = {
				"^exec$",
				"^items$",
				"^filter$",
				"^action$",
				"^state$",
				"^f$",
				"^func$",
				"^no_edit$"
			}
			local SearchExclude = {
				".svn",
				"/Prefabs/",
				"/Storage/",
				"/Collections/",
				"/BuildCache/"
			}
		local TablesToKeys = {}
			local TableDictionary = {
				"const",
				"config",
				"hr",
				"Platform",
				"EntitySurfaces",
				"terrain",
				"ShadingConst",
				"table",
				"coroutine",
				"debug",
				"io",
				"os",
				"string"
			}
		for i = 1, #TableDictionary do
			local name = TableDictionary[i]
			local t = rawget(_G, name)
			local keys = type(t) == "table" and table.keys(t) or ""
			if type(keys) == "table" then
				local vars = EnumVars(name .. ".")
				for key in pairs(vars) do
					keys[#keys + 1] = key
				end
				if #keys > 0 then
					table.sort(keys)
					TablesToKeys[name] = keys
				end
			end
		end
		local InitPacket = {
			Event = "InitPacket",
			PathRemapping = PathRemapping,
			ExeFileName = string.gsub(GetExecName(), "/", "\\"),
			ExePath = string.gsub(GetExecDirectory(), "/", "\\"),
			CurrentDirectory = Platform.pc and string.gsub(GetCWD(), "/", "\\") or "",
			FileDictionaryPath = FileDictionaryPath,
			FileDictionaryExclude = FileDictionaryExclude,
			FileDictionaryIgnore = FileDictionaryIgnore,
			SearchExclude = SearchExclude,
			TablesToKeys = TablesToKeys,
			ConsoleHistory = rawget(_G, "LocalStorage") and LocalStorage.history_log or {}
		}
		InitPacket.Platform = GetDebuggeePlatform()
	--~	 if Platform.console or Platform.ios then
	--~		 InitPacket.UploadData = "true"
	--~		 InitPacket.UploadPartSize = config.Haerald and config.Haerald.UploadPartSize or 2097152
	--~		 InitPacket.UploadFolders = config.Haerald and config.Haerald.UploadFolders or {}
	--~	 end
		local project_name = const.HaeraldProjectName
		if not project_name then
--~ 				local dir, filename, ext = SplitPath(GetExecName())
			local _, filename = SplitPath(GetExecName())
			project_name = filename or "unknown"
		end
		InitPacket.ProjectName = project_name
		self:Send(InitPacket)
		for _ = 1, 500 do
			if self:DebuggerTick() and not self.init_packet_received then
				os.sleep(10)
			end
		end
		SetThreadDebugHook(DebuggerSetHook)
		DebuggerSetHook()
--~ ThreadDebugHook
--~ 			local coroutine_resume, coroutine_status = coroutine.resume, coroutine.status
--~ 			local IsValidThread = IsValidThread
--~ 			self.garbage_thread = CreateRealTimeThread(function(thread)
--~ 				collectgarbage("stop")
--~ 				DebuggerPreThreadResume(thread)
--~ 				local r1, r2 = coroutine_resume(thread)
--~ 				local time = DebuggerPostThreadYield(thread)
--~ 				collectgarbage("restart")
--~ 				if coroutine_status(thread) ~= "suspended" then
--~ 					DebuggerClearThreadHistory(thread)
--~ 				end
--~ 				return r1, r2
--~ 			end)

		DeleteThread(self.update_thread)
		self.update_thread = CreateRealTimeThread(function()
			print("Debugger connected.")
			while self:DebuggerTick() do
				Sleep(25)
			end
print(2, "stop")
			self:Stop()
		end)

	end -- :Start()

--~ 		function dfggfhgfhgfh()
--~ 			return 0/0
--~ 		end

	local function AddHooks()
		function hookBreakLuaDebugger()
			if g_LuaDebugger then
				print("Break")
				g_LuaDebugger:Break()
			end
		end
		function hookTickLuaDebugger()
			if g_LuaDebugger then
--~ 					print("DebuggerTick")
				g_LuaDebugger:DebuggerTick()
			end
		end
	end

	local debug_enabled
	function ChoGGi.testing.StartDebugger()
		if debug_enabled then
			StopDebugger()
			debug_enabled = false
			return
		end
		debug_enabled = true

		AddHooks()

		local ReadPacket = luadebugger.ReadPacket
		function luadebugger:ReadPacket(packet)
			print(packet)
			return ReadPacket(self, packet)
		end

		config.Haerald = {
			platform = GetDebuggeePlatform(),
			ip = "localhost",
			RemoteRoot = "",
			ProjectFolder = "",
		}
		SetupRemoteDebugger(
			config.Haerald.ip,
			config.Haerald.RemoteRoot,
			config.Haerald.ProjectFolder
		)
		if not luadebugger.Start_ORIG then
			luadebugger.Start_ORIG = luadebugger.Start
			luadebugger.Start = Mine_luadebugger_Start
		end
		StartDebugger()
	--~	 ProjectSync()
	end
]]
--~ end -- ClassesBuilt
-- ---------------------------------------------------------------------------------------

function OnMsg.ModsReloaded()
	-- print any mod error msgs in console
	local startup = ChoGGi.Temp.StartupMsgs
	local c = #startup

	local log = ModMessageLog
	for i = 1, #log do
		local msg = log[i]
		if msg:find("Error loading") then
			c = c + 1
			startup[c] = msg
		end
	end
	print(table.concat(ChoGGi.Temp.StartupMsgs))
	table.iclear(ChoGGi.Temp.StartupMsgs)
end
