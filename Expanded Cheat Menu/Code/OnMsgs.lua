-- See LICENSE for terms

local what_game = ChoGGi.what_game

-- OnMsgs (most of them)

local ChoGGi_Funcs = ChoGGi_Funcs
local table = table
local type, pairs = type, pairs
local FlushLogFile = FlushLogFile
local Msg = Msg
local OnMsg = OnMsg
local IsKindOf = IsKindOf
local CreateRealTimeThread = CreateRealTimeThread
local T = T

-- no sense in localing it, but I keep forgetting the name...
local ClassDescendantsList = ClassDescendantsList

local MsgPopup = ChoGGi_Funcs.Common.MsgPopup
local RetName = ChoGGi_Funcs.Common.RetName
local AttachToNearestDome = ChoGGi_Funcs.Common.AttachToNearestDome
local IsValidXWin = ChoGGi_Funcs.Common.IsValidXWin
local UpdateDepotCapacity = ChoGGi_Funcs.Common.UpdateDepotCapacity
local IsUniversalStorageDepot = ChoGGi_Funcs.Common.IsUniversalStorageDepot
local Translate = ChoGGi_Funcs.Common.Translate
local GetCityLabels = ChoGGi_Funcs.Common.GetCityLabels

local blacklist = ChoGGi.blacklist
local testing = ChoGGi.testing

do -- custom msgs

	-- make sure they use with our new values
	function OnMsg.ChoGGi_SpawnedProducer(obj, prod_type)
		local prod = ChoGGi.UserSettings.BuildingSettings[obj.template_name]
		if prod and prod.production then
			obj[prod_type] = prod.production
		end
	end

	function OnMsg.ChoGGi_SpawnedDrone(obj)
		local UserSettings = ChoGGi.UserSettings
		if UserSettings.SpeedDrone then
			if IsKindOf(obj, "FlyingDrone") then
				if UserSettings.SpeedWaspDrone then
					obj:SetBase("move_speed", UserSettings.SpeedWaspDrone)
				end
			else
				obj:SetBase("move_speed", UserSettings.SpeedDrone)
			end
		end

		if UserSettings.DroneBatteryMax then
			obj.battery_max = UserSettings.DroneBatteryMax
		end
	end

end -- do

-- stops crashing with certain missing pinned objects
if ChoGGi.UserSettings.FixMissingModBuildings then
	local umc = UnpersistedMissingClass
	ChoGGi_Funcs.Common.AddParentToClass(umc, "AutoAttachObject")
	ChoGGi_Funcs.Common.AddParentToClass(umc, "PinnableObject")
	umc.entity = "ErrorAnimatedMesh"
end

-- use this message to mess with the classdefs (before classes are built)
function OnMsg.ClassesGenerate()

	--
	if ChoGGi.UserSettings.AllLoadingScreens then
		g_FirstLoadingScreen = false

		g_LoadingScreens = {
			"UI/SplashScreen.dds",
			"UI/LoadingScreens/002.tga",
			"UI/LoadingScreens/003.tga",
			"UI/LoadingScreens/004.tga",
			"UI/LoadingScreens/005.tga",
			"UI/LoadingScreens/006.tga",
			"UI/LoadingScreens/007.tga",
			"UI/LoadingScreens/008.tga",
			"UI/LoadingScreens/009.tga",
			"UI/LoadingScreens/010.tga",
			"UI/LoadingScreens/011.tga",
			-- These were included in main game
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_01_Worlds.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_02_Pillars.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_03_Picnic.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_04_StarLake.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_05_Fireworks.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_06_Rain.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_07_Pines.tga",
			"UI/LoadingScreens/GP_Green_Mars_Loading_Screen_08_Sand.tga",
		}
		-- These were not
		if g_AvailableDlc.picard then
			local screens = g_LoadingScreens
			local c = #g_LoadingScreens
			c = c + 1
			screens[c] = "UI/LoadingScreens/asteroid_01.tga"
			c = c + 1
			screens[c] = "UI/LoadingScreens/asteroid_02.tga"
			c = c + 1
			screens[c] = "UI/LoadingScreens/asteroid_03.tga"
			c = c + 1
			screens[c] = "UI/LoadingScreens/underground_01.tga"
			c = c + 1
			screens[c] = "UI/LoadingScreens/underground_02.tga"
			c = c + 1
			screens[c] = "UI/LoadingScreens/underground_03.tga"
		end
	end

	if ChoGGi.UserSettings.FlushLog then
		FlushLogFile()
	end
end

-- use this message to do some processing to the already final classdefs (still before classes are built)
function OnMsg.ClassesPreprocess()
	if what_game == "Mars" then
		-- Add default Consts/const values to ChoGGi.Consts
		if not ChoGGi.Tables.Consts_names then
			local cConsts = ChoGGi.Consts
			local names = {}

			local c = 0
			local Consts = Consts
			for key,value in pairs(Consts) do
				if type(value) == "number" then
					c = c + 1
					names[c] = key
					cConsts[key] = value
				end
			end
			ChoGGi.Tables.Consts_names = names

			local const_names = ChoGGi.Tables.const_names
			for i = 1, #const_names do
				local name = const_names[i]
				cConsts[name] = const[name]
			end
			cConsts.InvalidPos = InvalidPos()
		end
	end

	if ChoGGi.UserSettings.FlushLog then
		FlushLogFile()
	end
end

-- where we can add new BuildingTemplates, and other PlaceObjs
-- use this message to make modifications to the built classes (before they are declared final)
function OnMsg.ClassesPostprocess()
	local XTemplates = XTemplates
	local ChoGGi = ChoGGi
	local UserSettings = ChoGGi.UserSettings

	if what_game == "Mars" then
		for key, template in pairs(XTemplates) do
			local xt = template[1]
			-- add some ids to make it easier to fiddle with selection panel (making sure to skip the repeatable ones)
			if key:sub(1, 7) == "section" and key:sub(-3) ~= "Row" then
				if xt and not xt.Id then
					xt.Id = "id" .. template.id .. "_ChoGGi"
				end
			-- add cheats section to stuff without it
			elseif key:sub(1, 2) == "ip" and not table.find(xt, "__template", "sectionCheats") then
				xt[#xt+1] = PlaceObj("XTemplateTemplate", {
					"__template", "sectionCheats",
				})
			end
		end

		-- no sense in firing the func without cheats pane enabled
		XTemplates.sectionCheats[1].__condition = function(parent, context)
			return config.BuildingInfopanelCheats and context:CreateCheatActions(parent)
		end

		-- remove all that spacing between buttons
		XTemplates.sectionCheats[1][1].LayoutHSpacing = 10

		-- add rollovers to cheats toolbar
		XTemplates.EditorToolbarButton[1].RolloverTemplate = "Rollover"

		-- left? right? who cares? I do... *&^%$#@$ designers
		if UserSettings.GUIDockSide then
			XTemplates.NewOverlayDlg[1].Dock = "right"
			XTemplates.SaveLoadContentWindow[1].Dock = "right"
			ChoGGi_Funcs.Common.SetTableValue(XTemplates.SaveLoadContentWindow[1], "Dock", "left", "Dock", "right")
			XTemplates.PhotoMode[1].Dock = "right"
		end

		-- add HiddenX cat for Hidden items
		local bc = BuildCategories
		if UserSettings.Building_hide_from_build_menu and not table.find(bc, "id", "HiddenX") then
			bc[#bc+1] = {
				id = "HiddenX",
				name = T(1000155--[[Hidden]]),
				image = "UI/Icons/bmc_placeholder.tga",
				highlight = "UI/Icons/bmc_placeholder_shine.tga",
			}
		end

	end -- what_game

--~ 	-- fiddle with mod options
--~ 	if not table.find(ModsLoaded, "id", "ChoGGi_ModOptionsExpanded") then
--~ 		ChoGGi_Funcs.Common.ExpandModOptions(XTemplates)
--~ 	end

	-- Sometime in between picard content update 1 and rev 1009657 they hid the toobar buttons from cheat menu
	local function true_return()
		return true
	end
	XTemplates.EditorToolbarButton[1].__condition = true_return
	XTemplates.EditorToolbarToggleButton[1].__condition = true_return

	if UserSettings.FlushLog then
		FlushLogFile()
	end
end

-- use this message to perform post-built actions on the final classes
function OnMsg.ClassesBuilt()
	if ChoGGi.UserSettings.FlushLog then
		FlushLogFile()
	end
end

-- fired when settings are changed/init
local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	-- I check mod options earlier than I should, so this prevents blank mod options (somehow)
	CurrentModOptions:GetProperties()

	-- Rebuild cheats menu to hide items
	local desktop = terminal.desktop
	for i = 1, #desktop do
		local dlg = desktop[i].idMenuBar
		if dlg and dlg.MenuEntries == "DevMenu" then
			dlg:RebuildActions(dlg:GetActionsHost())
		end
	end

end

function OnMsg.ApplyModOptions(id)
	ModOptions(id)
	-- Awkward looking, but we only want to reset settings in mod options
	if id ~= CurrentModId then
		return
	end
	if CurrentModOptions:GetProperty("ResetSettings") then
		CreateRealTimeThread(function()
			ChoGGi_Funcs.Menus.ResetECMSettings()
		end)
		CurrentModOptions:SetProperty("ResetSettings", false)
	end
end

function OnMsg.ReloadLua()
	CreateRealTimeThread(function()
		-- needs a bit for console msg to render on reload?
		WaitMsg("OnRender")

		local size = ChoGGi.UserSettings.ConsoleLogWin_Size
		if size then
			local dlg = dlgChoGGi_DlgConsoleLogWin
			-- reload lua does stuff
			if IsValidXWin(dlg) then
				WaitMsg("OnRender")
--~ 			print(type(dlg.SetSize),dlg.window_state,"window_state")
				dlg:SetSize(size)
			end
		end
	end)
end

function OnMsg.ModsReloaded()
	-- load default/saved settings
	ModOptions()

	local ChoGGi = ChoGGi
	local UserSettings = ChoGGi.UserSettings

	if UserSettings.FlushLogConstantly then
		print("<color 255 75 75>", Translate(302535920001349--[[Flush Log Constantly]]), "</color>", Translate(302535920001414--[[Call FlushLogFile() every render update!]]))
	end

	-- added this here, as it's early enough to load during the New Game Menu
	local Actions = ChoGGi.Temp.Actions
	if UserSettings.DisableECM then
		-- remove all my actions from ecm
		for i = #Actions, 1, -1 do
			local a = Actions[i]
			-- If it's a . than we haven't updated it yet
			if a.ActionId:sub(1, 1) == "." then
				table.remove(Actions, i)
			end
		end
	else
		local c = #Actions

		c = c + 1
		Actions[c] = {
			ActionMenubar = "ECM.Debug",
			ActionName = T(302535920001074--[[Ged Presets]]),
			ActionId = ".Ged Presets",
			ActionIcon = "CommonAssets/UI/Menu/folder.tga",
			OnActionEffect = "popup",
		}

		-- add preset menu items
		local Presets = Presets
		ClassDescendantsList("Preset", function(name, class)
			if not name:find("ChoGGi") then
				c = c + 1
				Actions[c] = {
					ActionMenubar = "ECM.Debug.Ged Presets",
					ActionName = name,
					ActionId = "." .. name,
					ActionIcon = "CommonAssets/UI/Menu/SelectByClassName.tga",
					RolloverText = T(302535920000733--[[Open a preset in the editor.]]),
					OnAction = function()
						OpenGedApp(class.GedEditor, Presets[name], {
							PresetClass = name,
							SingleFile = class.SingleFile
						})
					end,
				}
			end
		end)

		-- add the defaults we skipped to my actions
		for i = 1, c do
			local a = Actions[i]
			-- If it's a . than we haven't updated it yet
			if a.ActionId:sub(1, 1) == "." then
				a.ActionTranslate = false
				a.replace_matching_id = true
				a.ActionId = (a.ActionMenubar ~= "" and a.ActionMenubar or "ECM") .. a.ActionId
				a.ChoGGi_ECM = true
			end
		end
		-- add ged presets to menu right away (this only affects those that use ECM from startup mods)
		ChoGGi_Funcs.Common.Rebuildshortcuts()

		-- show console log history
		if UserSettings.ConsoleToggleHistory or ChoGGi_Funcs.Common.ModEditorActive() then
			ShowConsoleLog(true)
		end

		if UserSettings.ConsoleHistoryWin then
			ChoGGi_Funcs.Common.ShowConsoleLogWin(true)
		end

		-- dim that console bg
		if UserSettings.ConsoleDim then
			config.ConsoleDim = 1
		end

		-- build console buttons
		local dlgConsole = dlgConsole
		if dlgConsole and not dlgConsole.ChoGGi_MenuAdded then
			local edit = dlgConsole.idEdit

			-- add a context menu
			edit.OnKillFocus = g_Classes.ChoGGi_XInputContextMenu.OnKillFocus
			edit.OnMouseButtonDown = g_Classes.ChoGGi_XInputContextMenu.OnMouseButtonDown
			edit.RetContextList = g_Classes.ChoGGi_XInputContextMenu.RetContextList

			-- removes comments from code, and adds a space to each newline, so pasting multi line works
			local XEditEditOperation = XEdit.EditOperation
			local StripComments = ChoGGi_Funcs.Common.StripComments
			function edit:EditOperation(insert_text, is_undo_redo, cursor_to_text_start, ...)
				if type(insert_text) == "string" then
					insert_text = StripComments(insert_text)
					insert_text = insert_text:gsub("\n", " \n")
				end
				return XEditEditOperation(self, insert_text, is_undo_redo, cursor_to_text_start, ...)
			end

			edit.RolloverTemplate = "Rollover"
			edit.RolloverTitle = T(302535920001073--[[Console]]) .. " " .. T(487939677892--[[Help]])
			-- add tooltip
			edit.RolloverText = T(302535920001440--[["~obj opens object in examine dlg.
~~obj opens object's attachments in examine dlg.

<green>&</green><yellow>handle</yellow> examine object using handle id.

@GetMissionSponsor prints file name and line number of function.

@@EntityData prints type(EntityData).

%""UI/Vignette.tga"" opens image in image viewer.

$123 or $EffectDeposit.display_name prints translated string.

""*r Sleep(1000) print(""sleeping"")"" to wrap in a real time thread (or *g or *m).

!UICity.labels.TerrainDeposit[1] move camera and select obj.

delcls(class_name) remove all objects of a certain class.

s = SelectedObj, c() = GetCursorWorldPos(), restart() = quit(""restart"")"]])
			edit.Hint = Translate(302535920001439--[["~obj, @func, @@type, %image, *r/*g/*m threads. Hover mouse for more info."]])

			-- and buttons
			ChoGGi_Funcs.Console.ConsoleControls(dlgConsole)

			dlgConsole.ChoGGi_MenuAdded = true
		end

		if what_game == "Mars" then
			-- show cheat pane in selection panel
			if UserSettings.InfopanelCheats then
				config.BuildingInfopanelCheats = true
			end

			-- remove some uselessish Cheats to clear up space
			if UserSettings.CleanupCheatsInfoPane then
				ChoGGi_Funcs.InfoPane.InfopanelCheatsCleanup()
			end
		end -- what_game

		-- cheats menu fun
		local XShortcutsTarget = XShortcutsTarget
		if XShortcutsTarget then

			for i = 1, #XShortcutsTarget do
				local item = XShortcutsTarget[i]
				-- yeah... i don't need the menu taking up the whole width of my screen
				item:SetHAlign("left")

				-- add some ids for easier selection later on
				if IsKindOf(item, "XMenuBar") then
					XShortcutsTarget.idMenuBar = item
				elseif IsKindOf(item, "XWindow") then
					XShortcutsTarget.idToolbar = item
					break
				end
			end

			-- add a hint about rightclicking
			if UserSettings.EnableToolTips then
				local toolbar = XShortcutsTarget.idMenuBar
				toolbar:SetRolloverTemplate("Rollover")
				toolbar:SetRolloverTitle(T(302535920001717--[[Info]]))
				toolbar:SetRolloverText(T(302535920000503--[[Right-click an item/submenu to add/remove it from the quickbar.]]))
				toolbar:SetRolloverHint(T(302535920001441--[["<left_click> Activate MenuItem <right_click> Add/Remove"]]))
			end

			-- always show menu
			XShortcutsTarget:SetVisible(true)

			-- that info text about right-clicking expands the menu instead of just hiding or something
			for i = 1, #XShortcutsTarget.idToolbar do
				if IsKindOf(XShortcutsTarget.idToolbar[i], "XText") then
					XShortcutsTarget.idToolbar[i]:delete()
				end
			end

			-- add a little spacer to the top of cheats menu you can drag around
			ChoGGi_Funcs.Common.DraggableCheatsMenu(
				UserSettings.DraggableCheatsMenu
			)

			-- If no delay then you can't drag it around after setdock
			CreateRealTimeThread(function()
				Sleep(100)
				if UserSettings.KeepCheatsMenuPosition then
					XShortcutsTarget:SetDock("ignore")
					XShortcutsTarget:SetPos(UserSettings.KeepCheatsMenuPosition)
				end
			end)

		end

	end -- DisableECM

	if what_game == "Mars" then
		local SponsorBuildingLimits = UserSettings.SponsorBuildingLimits
		local Building_hide_from_build_menu = UserSettings.Building_hide_from_build_menu

		local BuildingTechRequirements = BuildingTechRequirements
		local BuildingTemplates = BuildingTemplates
		for id, bld in pairs(BuildingTemplates) do

			-- remove sponsor limits on buildings
			if SponsorBuildingLimits then
				-- set each status to false if it isn't
				for i = 1, 3 do
					local str = "sponsor_status" .. i
					local status = bld[str]
					if status ~= false then
						bld["sponsor_status" .. i .. "_ChoGGi_orig"] = status
						bld[str] = false
					end
				end

				-- and this bugger screws me over on GetBuildingTechsStatus (probably need to update if they add sponsor locked buildable rockets)
				local name = id
				if name:sub(1, 2) == "RC" and name:sub(-8) == "Building" then
					name = name:gsub("Building", "")
				end
				local reqs = BuildingTechRequirements[id]
				local idx = table.find(reqs, "check_supply", name)
				if idx then
					table.remove(reqs, idx)
				end
			end

			-- make hidden buildings visible
			if Building_hide_from_build_menu then
				if bld.id ~= "LifesupportSwitch" and bld.id ~= "ElectricitySwitch" then
					bld.hide_from_build_menu_ChoGGi = bld.hide_from_build_menu
					bld.hide_from_build_menu = false
				end
				if bld.group == "Hidden" and bld.id ~= "RocketLandingSite" and bld.id ~= "ForeignTradeRocket" then
					bld.build_category = "HiddenX"
				end
			end
		end

		-- unlock buildings that cannot rotate
		if UserSettings.RotateDuringPlacement then
			local buildings = ClassTemplates.Building
			for _, bld in pairs(buildings) do
				if bld.can_rotate_during_placement == false then
					bld.can_rotate_during_placement_ChoGGi_orig = true
					bld.can_rotate_during_placement = true
				end
			end
		end

	end -- what_game
	-- limit width of infopanel toolbar buttons
	ChoGGi_Funcs.Common.InfopanelToolbarConstrain_Toggle(UserSettings.InfopanelToolbarConstrain)

	-- slight delay for vertical menu
	CreateRealTimeThread(function()
		WaitMsg("OnRender")
		ChoGGi_Funcs.Common.VerticalCheatMenu_Toggle(UserSettings.VerticalCheatMenu)

		-- no dlc and the menu flickers on then turns off (for some reason)
		Sleep(1000)
		XShortcutsTarget:SetVisible(true)
	end)

	if UserSettings.ShowLuaRevision then
		local PGVideoBackground = Dialogs.PGVideoBackground
		if PGVideoBackground then
			local text_dlg = XText:new({
				TextStyle = "AchievementTitle",
				Dock = "box",
				HAlign = "right",
				VAlign = "bottom",
				Clip = false,
				UseClipBox = false,
				HandleMouse = false,
			}, PGVideoBackground[1])
			text_dlg:SetText(T(12356, "Revision") .. ": " .. LuaRevision)
			text_dlg:SetVisible(true)
		end
	end
	--
end -- ModsReloaded

function OnMsg.PersistPostLoad()
	if ChoGGi.UserSettings.FixMissingModBuildings then
		-- [LUA ERROR] Mars/Lua/Construction.lua:860: attempt to index a boolean value (global 'ControllerMarkers')
		if type(ControllerMarkers) == "boolean" then
			ControllerMarkers = {}
		end

		-- [LUA ERROR] Mars/Lua/Heat.lua:65: attempt to call a nil value (method 'ApplyForm')
		local s_Heaters = s_Heaters or {}
		for obj in pairs(s_Heaters) do
			if IsKindOf(obj, "UnpersistedMissingClass") then
				s_Heaters[obj] = nil
			end
		end

		-- If there's a missing id print/return a warning
		local printit = ChoGGi.UserSettings.FixMissingModBuildingsLog
		-- GetFreeSpace, GetFreeLivingSpace, GetFreeWorkplaces, GetFreeWorkplacesAround
		local Cities = Cities
		-- needed for pre-picard saves
		for i = 1, #Cities do
			local city = Cities[i]
			local labels = city.labels
			for label_id, label in pairs(labels) do
				if label_id ~= "Consts" then
					for j = #label, 1, -1 do
						local obj = label[j]
						if IsKindOf(obj, "UnpersistedMissingClass") then
							if printit then
								print(Translate(302535920001401--[["Removed missing mod building from %s: %s, entity: %s, handle: %s"]]):format(label_id, RetName(obj), obj:GetEntity(), obj.handle))
							end
							obj:delete()
							table.remove(label, j)
						end
					end
				end
			end
		end


	end -- If FixMissingModBuildings
end

-- for instant build
function OnMsg.BuildingPlaced(obj)
	if IsKindOf(obj, "Building") then
		ChoGGi.Temp.LastPlacedObject = obj
	end
end --OnMsg

do -- ConstructionSitePlaced/ConstructionPrefabPlaced
	local function SitePlaced(obj)
		if IsKindOf(obj, "Building") then
			ChoGGi.Temp.LastPlacedObject = obj
		end

		-- use a delay, so domes don't screw up
		CreateRealTimeThread(function()
			WaitMsg("OnRender")
			-- some issue bypass?
			if ChoGGi.UserSettings.Building_instant_build and (not obj.construction_group
					or obj.construction_group and obj.construction_group[1] == obj) then
				obj:Complete("quick_build")
			end
			-- spire needs a pointy end
			if IsKindOf(obj.building_class_proto, "Temple") then
				local frame = obj:GetAttaches("SpireFrame")
				if not frame then
					frame = ChoGGi_Funcs.Common.AttachSpireFrame(obj)
					frame:SetGameFlags(const.gofUnderConstruction)
				end
				ChoGGi_Funcs.Common.AttachSpireFrameOffset(frame)
			end
		end)
	end --OnMsg

	OnMsg.ConstructionSitePlaced = SitePlaced
	OnMsg.ConstructionPrefabPlaced = SitePlaced
end -- do

-- some upgrades change amounts, so reset them to ours
function OnMsg.BuildingUpgraded(obj)
	if IsKindOf(obj, "ElectricityProducer") then
		Msg("ChoGGi_SpawnedProducer", obj, "electricity_production")
	elseif IsKindOf(obj, "AirProducer") then
		Msg("ChoGGi_SpawnedProducer", obj, "air_production")
	elseif IsKindOf(obj, "WaterProducer") then
		Msg("ChoGGi_SpawnedProducer", obj, "water_production")
	elseif IsKindOf(obj, "SingleResourceProducer") then
		Msg("ChoGGi_SpawnedProducer", obj, "production_per_day")
--~ 	else
--~ 		Msg("ChoGGi_SpawnedBaseBuilding", obj)
	end
	Msg("ChoGGi_SpawnedBaseBuilding", obj)
end

-- :GameInit() (Msg.BuildingInit only does Building, not BaseBuilding)
function OnMsg.ChoGGi_SpawnedBaseBuilding(obj)
	local UserSettings = ChoGGi.UserSettings

	if IsKindOf(obj, "ConstructionSite")
			or IsKindOf(obj, "ConstructionSiteWithHeightSurfaces") then
		return
	end

	-- not working code from when trying to have passages placed in entrances
--~ 	-- If it's a fancy dome then we allow building in the removed entrances
--~ 	if IsKindOf(obj, "Dome") then
--~ 		local id_start, id_end = obj:GetAllSpots(obj:GetState())
--~ 		for i = id_start, id_end do
--~ 			if obj:GetSpotName(i) == "Entrance" or obj:GetSpotAnnotation(i) == "att, DomeRoad_04, show" then
--~ 				print(111)
--~ 			end
--~ 		end
--~ 	end

	if UserSettings.CommandCenterMaxRadius and IsKindOf(obj, "DroneHub") then
		-- we set it from the func itself
		obj:SetWorkRadius()

	elseif UserSettings.ServiceWorkplaceFoodStorage
			and (IsKindOf(obj, "Grocery") or IsKindOf(obj, "Diner")) then
		-- for some reason InitConsumptionRequest always adds 5 to it
		local storedv = UserSettings.ServiceWorkplaceFoodStorage - (5 * const.ResourceScale)
		obj.consumption_stored_resources = storedv
		obj.consumption_max_storage = UserSettings.ServiceWorkplaceFoodStorage

	elseif UserSettings.RocketMaxExportAmount and IsKindOf(obj, "RocketBase") then
		obj.max_export_storage = UserSettings.RocketMaxExportAmount

	elseif IsKindOf(obj, "BaseRover") then
		if UserSettings.RCTransportStorageCapacity and IsKindOf(obj, "RCTransport") then
			obj.max_shared_storage = UserSettings.RCTransportStorageCapacity
		elseif UserSettings.RCRoverMaxRadius and IsKindOf(obj, "RCRover") then
			-- I override the func so no need to send a value here
			obj:SetWorkRadius()
		end
		-- applied to all rovers
		if UserSettings.SpeedRC then
			obj:SetBase("move_speed", UserSettings.SpeedRC)
		end

	elseif IsKindOf(obj, "CargoShuttle") then
		if UserSettings.StorageShuttle then
			obj.max_shared_storage = UserSettings.StorageShuttle
		end
		if UserSettings.SpeedShuttle then
			obj:SetBase("move_speed", UserSettings.SpeedShuttle)
		end

	elseif IsKindOf(obj, "UniversalStorageDepot") then
		local uni_depot = IsUniversalStorageDepot(obj)
		if UserSettings.StorageUniversalDepot and uni_depot then
			obj.max_storage_per_resource = UserSettings.StorageUniversalDepot
			UpdateDepotCapacity(obj)
		elseif UserSettings.StorageOtherDepot and not uni_depot then
			obj.max_storage_per_resource = UserSettings.StorageOtherDepot
			UpdateDepotCapacity(obj)
		end

	elseif UserSettings.StorageMechanizedDepot and IsKindOf(obj, "MechanizedDepot") then
		obj.max_storage_per_resource = UserSettings.StorageMechanizedDepot
		UpdateDepotCapacity(obj)

	elseif UserSettings.StorageWasteDepot and IsKindOf(obj, "WasteRockDumpSite") then
		obj.max_amount_WasteRock = UserSettings.StorageWasteDepot
		obj:CheatEmpty()
--~ 		UpdateDepotCapacity(obj)

	elseif UserSettings.ShuttleHubFuelStorage and IsKindOf(obj, "ShuttleHub") then
		obj.consumption_max_storage = UserSettings.ShuttleHubFuelStorage

	elseif UserSettings.SchoolTrainAll and IsKindOf(obj, "School") then
		local list = ChoGGi.Tables.PositiveTraits
		for i = 1, #list do
			obj:SetTrait(i, list[i])
		end

	elseif UserSettings.SanatoriumCureAll and IsKindOf(obj, "Sanatorium") then
		local list = ChoGGi.Tables.NegativeTraits
		for i = 1, #list do
			obj:SetTrait(i, list[i])
		end

	elseif IsKindOf(obj, "Temple") then
		CreateRealTimeThread(function()
			local frame = obj:GetAttaches("SpireFrame")
			if not frame then
				-- spire needs a pointy end
				frame = ChoGGi_Funcs.Common.AttachSpireFrame(obj)
				for i = 1, 4 do
					frame:SetColorizationMaterial(i, obj:GetColorizationMaterial(i))
				end
			end
			ChoGGi_Funcs.Common.AttachSpireFrameOffset(frame)
		end)

	elseif UserSettings.StorageMechanizedDepotsTemp
			and IsKindOf(obj, "ResourceStockpileLR")
			and IsKindOf(obj.parent, "MechanizedDepot") then
		-- attached temporary resource depots
		ChoGGi_Funcs.Common.SetMechanizedDepotTempAmount(obj.parent)
	end

	-- If an inside building is placed outside of dome, attach it to nearest dome (if there is one)
	if obj:GetDefaultPropertyValue("dome_required") then
		-- a slight delay is needed
		CreateRealTimeThread(function()
			if not IsValid(obj.parent_dome) then
				-- we use this to update the parent_dome (if there's a working/closer one)
				obj.city:AddToLabel("ChoGGi_InsideForcedOutDome", obj)

				AttachToNearestDome(obj)
			end
		end)
	end

	if UserSettings.InsideBuildingsNoMaintenance and IsKindOf(obj, "Constructable") then
		obj.ChoGGi_InsideBuildingsNoMaintenance = true
		obj.maintenance_build_up_per_hr = -10000
	end

	if UserSettings.RemoveMaintenanceBuildUp and IsKindOf(obj, "RequiresMaintenance") then
		obj.ChoGGi_RemoveMaintenanceBuildUp = true
		obj.maintenance_build_up_per_hr = -10000
	end

	-- saved building settings
	local bs = UserSettings.BuildingSettings[obj.template_name]
	if type(bs) == "table" then
		if next(bs) then
			-- saved settings for capacity, shuttles
			if bs.capacity then
				if obj.base_capacity then
					obj.capacity = bs.capacity
				elseif obj.base_air_capacity then
					obj.air_capacity = bs.capacity
				elseif obj.base_water_capacity then
					obj.water_capacity = bs.capacity
				elseif obj.base_max_shuttles then
					obj.max_shuttles = bs.capacity
				end
			end
			-- max visitors
			if bs.visitors and obj.base_max_visitors then
				obj.max_visitors = bs.visitors
			end
			-- max workers
			if bs.workers then
				obj.max_workers = bs.workers
			end
			-- no power needed
			if bs.nopower then
				ChoGGi_Funcs.Common.RemoveBuildingElecConsump(obj)
			end
			if bs.noair then
				ChoGGi_Funcs.Common.RemoveBuildingAirConsump(obj)
			end
			if bs.nowater then
				ChoGGi_Funcs.Common.RemoveBuildingWaterConsump(obj)
			end
			-- large protect_range for defence buildings
			if bs.protect_range then
				obj.protect_range = bs.protect_range
				obj.shoot_range = bs.protect_range * guim
			end
			-- fully auto building
			if bs.auto_performance then
--~ 				obj.max_workers = 0
				obj.automation = 1
				obj.auto_performance = bs.auto_performance
			end
			-- legacy setting
			-- changed saving as performance to auto_performance, get rid of this in a few months
			if bs.performance then
--~ 				obj.max_workers = 0
				obj.automation = 1
				obj.auto_performance = bs.performance
			end
			-- just perf boost
			if bs.performance_notauto then
				obj.performance = bs.performance_notauto
			end
			-- space ele export amount
			if bs.max_export_storage then
				obj.max_export_storage = bs.max_export_storage
			end
			-- space ele import amount
			if bs.cargo_capacity then
				obj.cargo_capacity = bs.cargo_capacity
			end
			-- service comforts
			if bs.service_stats and next(bs.service_stats) then
				ChoGGi_Funcs.Common.UpdateServiceComfortBld(obj, bs.service_stats)
			end
			-- training points
			if bs.evaluation_points then
				obj.evaluation_points = bs.evaluation_points
			end
			-- need to wait a sec for the grid objects to be created
			CreateRealTimeThread(function()
				-- dis/charge rates
				local prod_type = obj.GetStoredAir and "air"
					or obj.GetStoredWater and "water"
					or obj.GetStoredPower and "electricity"
				while not obj[prod_type] do
					Sleep(100)
				end
				if bs.charge then
					obj[prod_type].max_charge = bs.charge
					obj["max_" .. prod_type .. "_charge"] = bs.charge
				end
				if bs.discharge then
					obj[prod_type].max_discharge = bs.discharge
					obj["max_" .. prod_type .. "_discharge"] = bs.discharge
				end
			end)

		else
			-- empty table so remove
			UserSettings.BuildingSettings[obj.template_name] = nil
		end
	end
end --OnMsg

do -- ColonistCreated
	local function ColonistCreated(obj, skip)
		local UserSettings = ChoGGi.UserSettings

		if UserSettings.NewColonistGender then
			ChoGGi_Funcs.Common.ColonistUpdateGender(obj, UserSettings.NewColonistGender)
		end
		if UserSettings.NewColonistAge then
			ChoGGi_Funcs.Common.ColonistUpdateAge(obj, UserSettings.NewColonistAge)
		end
		-- children don't have spec models so they get black cube
		if UserSettings.NewColonistSpecialization and not skip then
			ChoGGi_Funcs.Common.ColonistUpdateSpecialization(obj, UserSettings.NewColonistSpecialization)
		end
		if UserSettings.NewColonistRace then
			ChoGGi_Funcs.Common.ColonistUpdateRace(obj, UserSettings.NewColonistRace)
		end
		if UserSettings.NewColonistTraits then
			ChoGGi_Funcs.Common.ColonistUpdateTraits(obj, true, UserSettings.NewColonistTraits)
		end
		if UserSettings.SpeedColonist then
			obj:SetBase("move_speed", UserSettings.SpeedColonist)
		end
		if UserSettings.DeathAgeColonist then
			obj.death_age = UserSettings.DeathAgeColonist
		end

	end

	OnMsg.ColonistArrived = ColonistCreated
	OnMsg.ColonistBorn = ColonistCreated
end -- do

--~ function OnMsg.SelectionAdded(obj)
function OnMsg.SelectedObjChange(obj)
	-- update selection shortcut
	s = obj
	-- update last placed (or selected)
	if IsKindOf(obj, "Building") then
		ChoGGi.Temp.LastPlacedObject = obj
	end
end

function OnMsg.SelectionRemoved()
	-- remove selected obj when nothing selected
	s = false
end

function OnMsg.ChangeMap()
	-- show how long loading takes
	if testing or ChoGGi.UserSettings.ShowStartupTicks then
		ChoGGi.Temp.StartupTicks = GetPreciseTicks()
	end

end

function OnMsg.ChangeMapDone(map)
	if ChoGGi.UserSettings.UnlockOverview then
		local mapdata = ChoGGi.is_gp and mapdata or ActiveMapData
		mapdata.IsAllowedToEnterOverview = true
	end

	-- first time run info
	if map == "PreGame" and ChoGGi.UserSettings.FirstRun ~= false then
		ChoGGi.UserSettings.FirstRun = false
		DestroyConsoleLog()
		ChoGGi_Funcs.Settings.WriteSettings()

		ChoGGi_Funcs.Common.MsgWait(
			T(302535920001400--[["F2 to toggle Cheats Menu (Ctrl-F2 for Cheats Pane), and F9 to clear console log text.
If this isn't a new install, then see Menu>Help>Changelog and search for ""To import your old settings""."]])
				.. "\n\n" .. T{302535920000030--[["To toggle the console log text; press Tilde or Enter and click the ""<settings>"" button then make sure ""<log>"" is checked."]],
					settings = T(302535920001308--[[Settings]]),
					log = T(302535920001112--[[Console Log]]),
				},
				T(10126--[[Installed Mods]]) .. ": " .. T(302535920000000--[[Expanded Cheat Menu]]),
			ChoGGi.mod_path .. "Preview.png",
			T(302535920001465--[[Stop talking and start cheating!]])
		)
	end
end

-- const.DayDuration is 720 000 ticks (GameTime)
function OnMsg.NewDay() -- NewSol...
--~ 	Msg("NewSol")
	local ChoGGi = ChoGGi

	-- remove any closed examine dialogs from the list
	local ChoGGi_dlgs_examine = ChoGGi_dlgs_examine or empty_table
	for obj, dlg in pairs(ChoGGi_dlgs_examine) do
		if not IsValidXWin(dlg) then
			ChoGGi_dlgs_examine[obj] = nil
		end
	end

	-- sorts cc list by dist to building
	if ChoGGi.UserSettings.SortCommandCenterDist then
		local objs = GetCityLabels("Building")
		for i = 1, #objs do
			local obj = objs[i]
			-- no sense in doing it with only one center
			if obj.command_centers[2] then
				table.sort(obj.command_centers, function(a, b)
					return obj:GetVisualDist2D(a) < obj:GetVisualDist2D(b)
				end)
			end
		end
	end

	-- dump log to disk
	if ChoGGi.UserSettings.FlushLog then
		FlushLogFile()
	end

	-- loop through and remove any old popups
	local IsValidXWin = ChoGGi_Funcs.Common.IsValidXWin
	local popups = ChoGGi.Temp.MsgPopups or ""
	for i = #popups, 1, -1 do
		if not IsValidXWin(popups[i]) then
			table.remove(popups, i)
		end
	end

	local objs = GetCityLabels("ChoGGi_InsideForcedOutDome")
	for i = #objs, 1, -1 do
		local obj = objs[i]
		-- got removed or something
		if not IsValid(obj) then
			obj.city:RemoveFromLabel("ChoGGi_InsideForcedOutDome", obj)
		else
			-- check if there's a nearer dome
			AttachToNearestDome(obj)
		end
	end

end

-- const.HourDuration is 30 000 ticks (GameTime)
function OnMsg.NewHour()
	local UserSettings = ChoGGi.UserSettings

	if UserSettings.FlushLogHourly then
		FlushLogFile()
	end

	-- Make them lazy drones stop abusing electricity (we need to have an hourly update if people are using large prod amounts/low amount of drones)
	if UserSettings.DroneResourceCarryAmountFix then
		local FuckingDrones = ChoGGi_Funcs.Common.FuckingDrones

		-- Hey. Do I preach at you when you're lying stoned in the gutter? No!
		local prods = GetCityLabels("ResourceProducer")
		for i = 1, #prods do
			local prod = prods[i]
			-- Most are fine with GetProducerObj, but some like water extractor don't have one
			local obj = prod:GetProducerObj() or prod
			local func = obj.GetStoredAmount and "GetStoredAmount" or obj.GetAmountStored and "GetAmountStored"
			if obj[func](obj) > 1000 then
				FuckingDrones(obj)
			end
			obj = prod.wasterock_producer
			if obj and obj:GetStoredAmount() > 1000 then
				FuckingDrones(obj, "single")
			end
		end

		prods = GetCityLabels("BlackCubeStockpiles")
		for i = 1, #prods do
			local obj = prods[i]
			if obj:GetStoredAmount() > 1000 then
				FuckingDrones(obj)
			end
		end

	end

	-- pathing? pathing in domes works great... watch out for that invisible wall!
	-- update: seems like this is an issue from one of those smarter work ai mods
	if UserSettings.ColonistsStuckOutsideServiceBuildings then
		ChoGGi_Funcs.Common.ResetHumanCentipedes()
	end
end

--~ -- const.MinuteDuration is 500 ticks (GameTime)
--~ function OnMsg.NewMinute()
--~ end

function OnMsg.AfterLightmodelChange()
	if ChoGGi.UserSettings.Lightmodel then
		SetLightmodelOverride(1, ChoGGi.UserSettings.Lightmodel)
	end
end

function OnMsg.ResearchQueueChange(city, tech_id)
	if ChoGGi.UserSettings.InstantResearch then
		CreateRealTimeThread(function()
			Sleep(100)
			GrantResearchPoints(city.tech_status[tech_id].cost)
			-- updates the researchdlg by toggling it.
			if GetDialog("ResearchDlg") then
				CloseDialog("ResearchDlg")
				OpenDialog("ResearchDlg")
			end
		end)
	end
end

-- If you pick a mystery from the cheat menu
function OnMsg.MysteryBegin()
	if ChoGGi.UserSettings.ShowMysteryMsgs then
		MsgPopup(
			ChoGGi.Tables.Mystery[UICity.mystery_id].name .. ": "
				.. T(302535920000729--[[You've started a mystery!]]),
			T(3486--[[Mystery]])
		)
	end
end
function OnMsg.MysteryChosen()
	if ChoGGi.UserSettings.ShowMysteryMsgs then
		MsgPopup(
			ChoGGi.Tables.Mystery[UICity.mystery_id].name .. ": "
				.. T(302535920000730--[[You've chosen a mystery!]]),
			T(3486--[[Mystery]])
		)
	end
end
function OnMsg.MysteryEnd(outcome)
	if ChoGGi.UserSettings.ShowMysteryMsgs then
		MsgPopup(
			ChoGGi.Tables.Mystery[UICity.mystery_id].name .. ": "
				.. tostring(outcome),
			T(3486--[[Mystery]])
		)
	end
end

-- fired when cheats menu is toggled
function OnMsg.DevMenuVisible(visible)
	if visible then
		CreateRealTimeThread(function()
			WaitMsg("OnRender")
			ChoGGi_Funcs.Common.SetCheatsMenuPos()
		end)
	end
end

local once_ApplicationQuit
function OnMsg.ApplicationQuit()
	if once_ApplicationQuit then
		return
	end
	once_ApplicationQuit = true

	-- from GedSocket.lua
	local desktop = terminal.desktop
	for i = #desktop, 1, -1 do
		local window = desktop[i]
		if IsKindOf(window, "GedApp") then
			window:Close()
		end
	end

	-- resetting settings?
	if ChoGGi.Temp.ResetECMSettings then
		return
	end
	if testing then
		return
	end

	-- save menu pos
	if ChoGGi.UserSettings.KeepCheatsMenuPosition then
		ChoGGi.UserSettings.KeepCheatsMenuPosition = XShortcutsTarget:GetPos()
	end

	-- console window settings
	local dlg = dlgChoGGi_DlgConsoleLogWin
	if dlg then
		Msg("ChoGGi_DlgConsoleLogWin_SizePos", dlg)
	end

	-- save any unsaved settings on exit
	ChoGGi_Funcs.Settings.WriteSettings()
end

function OnMsg.ChoGGi_TogglePinnableObject(obj)
	CreateRealTimeThread(function()
		WaitMsg("OnRender")
		if not (obj:IsPinned() and obj:CanBeUnpinned()) then
			return
		end
		local UnpinObjects = ChoGGi.UserSettings.UnpinObjects
		if type(UnpinObjects) == "table" and next(UnpinObjects) then
			if UnpinObjects[obj.class] then
				obj:TogglePin(true)
			end
		end
	end)
end

--~ -- hidden milestones
--~ function OnMsg.ChoGGi_DaddysLittleHitler()
--~ 	local MilestoneCompleted = MilestoneCompleted
--~ 	PlaceObj("Milestone", {
--~ 		base_score = 0,
--~ 		display_name = T(302535920000731--[[Deutsche Gesellschaft für Rassenhygiene]]),
--~ 		group = "Default",
--~ 		id = "DaddysLittleHitler"
--~ 	})
--~ 	if not MilestoneCompleted.DaddysLittleHitler then
--~ 		MilestoneCompleted.DaddysLittleHitler = 3025359200000
--~ 	end
--~ end

function OnMsg.ChoGGi_Childkiller()
	local MilestoneCompleted = MilestoneCompleted
	PlaceObj("Milestone", {
		base_score = 0,
		display_name = T(302535920000732--[[Childkiller (You evil, evil person.)]]),
		group = "Default",
		id = "Childkiller"
	})
	if not MilestoneCompleted.Childkiller then
		MilestoneCompleted.Childkiller = 479000000
	end
end

do -- LoadGame/CityStart
--~ 	local function SetMissionBonuses(UserSettings, Presets, preset, which, Func)
--~ 		local list = Presets[preset].Default or ""
--~ 		for i = 1, #list do
--~ 			local id = list[i].id
--~ 			if UserSettings[which .. id] then
--~ 				Func(id)
--~ 			end
--~ 		end
--~ 	end
	local function UpdateLabelSpeed(speed, label)
		local objs = ChoGGi_Funcs.Common.GetCityLabels(label)
		for i = 1, #objs do
			objs[i]:SetBase("move_speed", speed)
		end
	end

	-- Saved game is loaded
	-- If you see (MainCity or UICity) that's for older saves (it updates them, but later then I check in LoadGame)
	function OnMsg.LoadGame()
		Msg("ChoGGi_Loaded", "LoadGame")
	end
	-- New game is loaded
	--[[
	This fires before the map terrain is created
	You can use OnMsg.MapGenerated, but that fires for underground/asteroids as well
	You'll need to check for that, maybe set a value on CityStart then check for that value on MapGenerated
	Don't forget to nil the value
	]]
	function OnMsg.CityStart()
		-- Reset my mystery msgs to hidden
		ChoGGi.UserSettings.ShowMysteryMsgs = nil
		Msg("ChoGGi_Loaded", "CityStart")
	end

	function OnMsg.ChoGGi_Loaded(event)
		local ChoGGi = ChoGGi
		local UserSettings = ChoGGi.UserSettings

--~ 		if testing then
--~ 			Platform.developer = true
--~ 			print("Turn on Platform.developer for more log msgs maybe, check if it bugs out after loading/new game same session")
--~ 		end

		local UIColony = UIColony
		local g_Classes = g_Classes
		local const = const
		local hr = hr
		-- needed for pre-picard saves
--~ 		local labels = UIColony and UIColony.city_labels.labels or UICity.labels

		local sponsor = GetMissionSponsor()

		-- late enough that I can set g_Consts.
		ChoGGi_Funcs.Settings.SetConstsToSaved()

		-- any saved Consts settings (from the Consts menu)
		local SetConsts = ChoGGi_Funcs.Common.SetConsts
		local ChoGGi_Consts = UserSettings.Consts
		for key, value in pairs(ChoGGi_Consts) do
			SetConsts(key, value)
		end
		-- think about removing other Consts from other menus

		-- needed for DroneResourceCarryAmount (set in Consts)
		UpdateDroneResourceUnits()

		-- clear out Temp settings
		ChoGGi.Temp.UnitPathingHandles = {}

		-- re-binding is now an in-game thing, so keys are just defaults
		UserSettings.KeyBindings = nil

--~ 		SetMissionBonuses(UserSettings, Presets, "MissionSponsorPreset", "Sponsor", ChoGGi_Funcs.Common.SetSponsorBonuses)
--~ 		SetMissionBonuses(UserSettings, Presets, "CommanderProfilePreset", "Commander", ChoGGi_Funcs.Common.SetCommanderBonuses)




-- ------------------do the above stuff before the below stuff

		if testing then
			-- Consistently sort build menu
			ChoGGi_Funcs.Common.SortBuildMenuItems()

			-- make them happen more often
--~ 			g_StoryBitTesting = true
		end

		-- storybit info in log (see also g_StoryBitsLog g_StoryBitsScopeStack)
		if ChoGGi.UserSettings.StoryBitLogPrints then
			config.StoryBitLogPrints = true
		end
		-- build whatever realmever
		if ChoGGi.UserSettings.RemoveRealmLimits then
			ChoGGi_Funcs.Common.DisableBuildingsDie()
		end
		-- vertical menu
		if UserSettings.VerticalCheatMenu then
			ChoGGi_Funcs.Common.VerticalCheatMenu_Toggle(UserSettings.VerticalCheatMenu)
		end
		-- update pod price
		if type(UserSettings.PodPrice) == "number" then
			sponsor.pod_price = UserSettings.PodPrice
		end
		-- use ark pass pod with any sponsor
		if UserSettings.PassengerArkPod then
			sponsor.passenger_pod_class = "ArkPod"
		end
		-- allow camera closer to edge
		if UserSettings.MapEdgeLimit then
			hr.CameraRTSBorderAtMinZoom = 1000
			hr.CameraRTSBorderAtMaxZoom = 1000
		end

		-- Existing objs
		if event == "LoadGame" then

			-- update existing speeds
			if UserSettings.SpeedColonist then
				UpdateLabelSpeed(UserSettings.SpeedColonist, "Colonist")
			end
			if UserSettings.SpeedRC then
				UpdateLabelSpeed(UserSettings.SpeedRC, "Rover")
			end

			if UserSettings.SpeedShuttle then
				local speed = UserSettings.SpeedShuttle
				local objs = ChoGGi_Funcs.Common.GetCityLabels("CargoShuttle")
				for i = 1, #objs do
					objs[i]:SetBase("move_speed", speed)
				end
			end
			-- I figure looping through it twice is better then some complicated if else
			if UserSettings.SpeedWaspDrone or UserSettings.SpeedDrone then
				local objs = ChoGGi_Funcs.Common.GetCityLabels("Drone")
				if UserSettings.SpeedWaspDrone then
					local speed = UserSettings.SpeedWaspDrone
					for i = 1, #objs do
						local obj = objs[i]
						if IsKindOf(obj, "FlyingDrone") then
							obj:SetBase("move_speed", speed)
						end
					end
				end

				if UserSettings.SpeedDrone then
					local speed = UserSettings.SpeedDrone
					for i = 1, #objs do
						local obj = objs[i]
						if not IsKindOf(obj, "FlyingDrone") then
							obj:SetBase("move_speed", speed)
						end
					end
				end
			end

			-- not sure why this would be false on a dome
			local domes = ChoGGi_Funcs.Common.GetCityLabels("Dome")
			for i = 1, #domes do
				local dome = domes[i]
				if dome.achievement == "FirstDome" and type(dome.connected_domes) ~= "table" then
					dome.connected_domes = {}
				end
			end

			-- something messed up if storage is negative (usually setting an amount then lowering it)
			local storages = ChoGGi_Funcs.Common.GetCityLabels("Storages")
			procall(function()
				for i = 1, #storages do
					local obj = storages[i]
					if obj.GetStoredAmount and not IsKindOf(obj, "ConstructionSite") and obj:GetStoredAmount() < 0 then
						-- we have to empty it first (just filling doesn't fix the issue)
						obj:CheatEmpty()
						obj:CheatFill()
					end
				end
			end)

		end -- event

		if UserSettings.DroneResourceCarryAmount then
			if UserSettings.DroneResourceCarryAmount == 1 then
				UserSettings.DroneResourceCarryAmountFix = nil
			else
				-- damn drones, pick yer crap up
				UserSettings.DroneResourceCarryAmountFix = true
			end
		end

		if type(UserSettings.UnpinObjects) == "table" and #UserSettings.UnpinObjects > 0 then
			local new = {}
			for i = 1, #UserSettings.UnpinObjects do
				new[UserSettings.UnpinObjects[i]] = true
			end
			UserSettings.UnpinObjects = new
			ChoGGi.Temp.WriteSettings = true
		end

		if UserSettings.FrameCounterLocation then
			hr.FpsCounterPos = UserSettings.FrameCounterLocation
		end

		if UserSettings.mediumGameSpeed then
			const.mediumGameSpeed = UserSettings.mediumGameSpeed
		end
		if UserSettings.fastGameSpeed then
			const.fastGameSpeed = UserSettings.fastGameSpeed
		end

		-- make hidden buildings visible
		if UserSettings.Building_hide_from_build_menu then
			local bmpo = BuildMenuPrerequisiteOverrides
			for key, value in pairs(bmpo) do
				if value == "hide" then
					bmpo[key] = true
				end
			end
			bmpo.StorageMysteryResource = true
			bmpo.MechanizedDepotMysteryResource = true
		end

		-- show all traits in trainable popup
		if UserSettings.SanatoriumSchoolShowAllTraits then
			g_SchoolTraits = ChoGGi.Tables.PositiveTraits
			g_SanatoriumTraits = ChoGGi.Tables.NegativeTraits
		end

		-- all yours XxUnkn0wnxX
		if not blacklist then
			local autoexec = ChoGGi.scripts .. "/autoexec.lua"
			if ChoGGi_Funcs.Common.FileExists(autoexec) then
				print("ECM auto-executing: ", ConvertToOSPath(autoexec))
				dofile(autoexec)
			end
		end

		-- bloody hint popups
		if UserSettings.DisableHints then
			local mapdata = ChoGGi.is_gp and mapdata or ActiveMapData
			if mapdata.DisableHints == false then
				mapdata.DisableHints = true
			end
			HintsEnabled = false
		end


		-- some stuff needs a delay (like UIColony)
		CreateRealTimeThread(function()
			Sleep(1000)

--~ 		-- show completed hidden milestones
--~ 		if UIColony.ChoGGi.DaddysLittleHitler then
--~ 			PlaceObj("Milestone", {
--~ 				base_score = 0,
--~ 				display_name = T(302535920000731--[[Deutsche Gesellschaft für Rassenhygiene]]),
--~ 				group = "Default",
--~ 				id = "DaddysLittleHitler"
--~ 			})
--~ 			if not MilestoneCompleted.DaddysLittleHitler then
--~ 				MilestoneCompleted.DaddysLittleHitler = 3025359200000 -- hitler's birthday
--~ 			end
--~ 		end

		if UIColony and UIColony.ChoGGi and UIColony.ChoGGi.Childkiller then
			PlaceObj("Milestone", {
				base_score = 0,
				display_name = T(302535920000732--[[Childkiller (You evil, evil person.)]]),
				group = "Default",
				id = "Childkiller"
			})
			--it doesn't hurt
			if not MilestoneCompleted.Childkiller then
				MilestoneCompleted.Childkiller = 479000000 -- 666
			end
		end
		--
	end)

		-- If there's a lightmodel name saved
		if UserSettings.Lightmodel then
			SetLightmodelOverride(1, UserSettings.Lightmodel)
		end

		-- long arsed cables
		if UserSettings.UnlimitedConnectionLength then
			g_Classes.GridConstructionController.max_hex_distance_to_allow_build = 1000
			const.PassageConstructionGroupMaxSize = 1000
		end

		-- render settings
		if UserSettings.ShadowmapSize then
			hr.ShadowmapSize = UserSettings.ShadowmapSize
		end
		if UserSettings.VideoMemory then
			hr.DTM_VideoMemory = UserSettings.VideoMemory
		end
		if UserSettings.TerrainDetail then
			hr.TR_MaxChunks = UserSettings.TerrainDetail
		end
		if UserSettings.LightsRadius then
			hr.LightsRadiusModifier = UserSettings.LightsRadius
		end
		if UserSettings.DisableTextureCompression then
			-- uses more vram (1 toggles it, not sure what 0 does...)
			hr.TR_ToggleTextureCompression = 1
		end

		if UserSettings.HigherRenderDist then
			-- lot of lag for some small rocks in distance
			-- hr.AutoFadeDistanceScale = 2200 --def 2200

			-- render objects from further away (going to 960 makes a minimal difference, other than FPS on bigger cities)
			if type(UserSettings.HigherRenderDist) == "number" then
				hr.DistanceModifier = UserSettings.HigherRenderDist
				hr.LODDistanceModifier = UserSettings.HigherRenderDist
			else
				hr.DistanceModifier = 600
				hr.LODDistanceModifier = 600
			end
		end

		if UserSettings.HigherShadowDist then
			if type(UserSettings.HigherShadowDist) == "number" then
				hr.ShadowRangeOverride = UserSettings.HigherShadowDist
			else
				-- shadow cutoff dist
				hr.ShadowRangeOverride = 1000000 --def 0
			end
			-- no shadow fade out when zooming
			hr.ShadowFadeOutRangePercent = 0 --def 30
		end

		-- default to showing interface in ss
		if UserSettings.ShowInterfaceInScreenshots then
			hr.InterfaceInScreenshot = 1
		end

		-- so we can change the max_amount for concrete
		local terr_props = g_Classes.TerrainDepositConcrete.properties or ""
		for i = 1, #terr_props do
			local prop = terr_props[i]
			if prop.id == "max_amount" then
				prop.read_only = nil
			end
		end

		-- show all traits
		if UserSettings.SanatoriumSchoolShowAll then
			g_Classes.Sanatorium.max_traits = #ChoGGi.Tables.NegativeTraits
			g_Classes.School.max_traits = #ChoGGi.Tables.PositiveTraits
		end

		-- everyone loves a new titlebar, unless they don't
		if UserSettings.ChangeWindowTitle then
			terminal.SetOSWindowTitle(Translate(1079--[[Surviving Mars]]) .. ": " .. Translate(302535920000002--[[ECM]]) .. " " .. ChoGGi._VERSION)
		end

		-- first time run info
		if UserSettings.FirstRun ~= false then
			UserSettings.FirstRun = false
			DestroyConsoleLog()
			ChoGGi.Temp.WriteSettings = true
			ChoGGi_Funcs.Common.MsgWait(
				T(302535920001400--[["F2 to toggle Cheats Menu (Ctrl-F2 for Cheats Pane), and F9 to clear console log text.
If this isn't a new install, then see Menu>Help>Changelog and search for ""To import your old settings""."]])
					.. "\n\n" .. T{302535920000030--[["To toggle the console log text; press Tilde or Enter and click the ""%s"" button then make sure ""%s"" is checked."]],
						settings = T(302535920001308--[[Settings]]),
						log = T(302535920001112--[[Console Log]]),
					},
				T(10126--[[Installed Mods]]) .. ": " .. T(302535920000000--[[Expanded Cheat Menu]]),
				ChoGGi.mod_path .. "Preview.png",
				T(302535920001465--[[Stop talking and start cheating!]])
			)
		end

		-- added ifs and pcall for xbox (for some reason settings aren't being saved)

		-- set zoom/border scrolling
		if SetMouseDeltaMode then
			SetMouseDeltaMode(false)
		end
		if cameraRTS and cameraRTS.Activate then
			cameraRTS.Activate(1)
		end
		if engineShowMouseCursor then
			engineShowMouseCursor()
		end
		pcall(function()
			ChoGGi_Funcs.Common.SetCameraSettings()
		end)



		-- ---------------------------- always fired last



		-- make sure to save anything we changed above
		if ChoGGi.Temp.WriteSettings then
			ChoGGi_Funcs.Settings.WriteSettings()
			ChoGGi.Temp.WriteSettings = nil
		end

		if UserSettings.FlushLog then
			FlushLogFile()
		end

		-- used to check when game has started and it's safe to print() etc
		ChoGGi.Temp.GameLoaded = true

		-- anything that needs a thread/delay
		CreateRealTimeThread(function()
--~ 			-- always pause on start (for saves with missing mod buildings)
--~ 			if testing and game_type == "Load" then
--~ 				Sleep(100)
--~ 				if UISpeedState ~= "pause" then
--~ 					UIColony:SetGameSpeed(0)
--~ 					UISpeedState = "pause"
--~ 				end
--~ 			end

			-- clean up my old notifications (doesn't actually matter if there's a few left, but it can spam log)
			local shown = g_ShownOnScreenNotifications or empty_table
			for key in pairs(shown) do
				if type(key) == "number" or tostring(key):find("ChoGGi_") then
					shown[key] = nil
				end
			end

			-- remove any dialogs we opened
			if UserSettings.CloseDialogsECM then
				ChoGGi_Funcs.Common.CloseDialogsECM()
			end

		end)

		-- how long startup takes
		if testing or UserSettings.ShowStartupTicks then
			print("<color 200 200 200>", Translate(302535920000002--[[ECM]]), "</color>:", Translate(302535920000247--[[Startup ticks]]), ":", GetPreciseTicks() - ChoGGi.Temp.StartupTicks)
		end
	end --OnMsg
end -- do

-- If i need to do something on a new game that needs the map (or objs on the map)
--~ function OnMsg.MapSectorsReady()
--~ end
-- you can also do a thread and a WaitMsg for DepositsSpawned or Resume
-- or MessageBoxOpened/MessageBoxClosed (the welcome msg)
-- even later
--~ function OnMsg.DepositsSpawned()
--~ end
