-- See LICENSE for terms

-- Used to examine objects

local ChoGGi_Funcs = ChoGGi_Funcs
local what_game = ChoGGi.what_game

--[[
-- to add a clickable link use:
XXXXX = {
	ChoGGi_AddHyperLink = true,
	name = "do something",
	hint = "do somethings",
	func = function(self, button, obj, argument, hyperlink_box, pos) end,
}

~obj
ex(obj, pos/parent, title)

ex(obj, "str") -- examine a string obj ("SunAboveHorizon" / "table.find" / etc) with auto-refresh
ex("g_LastGeneratedApplicantTime", "str")

ex(obj, {
	has_params = true,
	parent = self,
	auto_refresh = true,
	-- fired when left clicking on a table
	exec_tables = function (obj, self) end,
	-- shows image in path in tooltip
	tooltip_info = function (obj, self) end,
	title = "hello",
	-- skip prefix
	override_title = true,
})
]]
-- store opened examine dialogs
if not rawget(_G, "ChoGGi_dlgs_examine") then
	ChoGGi_dlgs_examine = {}
end
-- stores list of ex dlgs that have replaced funcs
if not rawget(_G, "ChoGGi_dlgs_examine_funcs") then
	ChoGGi_dlgs_examine_funcs = {}
end

-- maybe make them stored settings...
local width, height

-- local some globals
local pairs, type, tostring, tonumber = pairs, type, tostring, tonumber
local getmetatable, rawget, next, table = getmetatable, rawget, next, table
local CmpLower = CmpLower
local CreateRealTimeThread = CreateRealTimeThread
local DeleteThread = DeleteThread
local GetStateName = GetStateName
local IsKindOf = IsKindOf
local IsT = IsT
local T = T
local IsPoint = IsPoint
local IsValid = IsValid
local IsValidEntity = IsValidEntity
local IsValidThread = IsValidThread
local Msg = Msg
local PropObjGetProperty = PropObjGetProperty
local Sleep = Sleep
local XCreateRolloverWindow = XCreateRolloverWindow
local XDestroyRolloverWindow = XDestroyRolloverWindow
local XFlashWindow = XFlashWindow
local TMeta = TMeta
local TConcatMeta = TConcatMeta

local Translate = ChoGGi_Funcs.Common.Translate
local IsControlPressed = ChoGGi_Funcs.Common.IsControlPressed
local IsShiftPressed = ChoGGi_Funcs.Common.IsShiftPressed
local RetName = ChoGGi_Funcs.Common.RetName
local SetWinObjectVis = ChoGGi_Funcs.Common.SetWinObjectVis
local RetMapType = ChoGGi_Funcs.Common.RetMapType
local IsValidXWin = ChoGGi_Funcs.Common.IsValidXWin
local RetParamsParents = ChoGGi_Funcs.Common.RetParamsParents
local RetObjMapId = ChoGGi_Funcs.Common.RetObjMapId

local InvalidPos = ChoGGi.Consts.InvalidPos
local missing_text = ChoGGi.Temp.missing_text
local testing = ChoGGi.testing
local blacklist = ChoGGi.blacklist

-- Backwards Compat for now... (needs? to be cleared out of Examine)
-- Maybe just rename it?
objlist = rawget(_G, "objlist") or {}
function IsObjlist(list)
	return type(list) == "table" and getmetatable(list) == objlist
end
local IsObjlist = IsObjlist
function objlist:new(o)
  if IsObjlist(o) then
    local o1 = table.icopy(o)
    setmetatable(o1, self)
    return o1
  else
    o = o or {}
    setmetatable(o, self)
    return o
  end
end
function objlist:Destroy()
	ChoGGi_Funcs.Common.objlist_Destroy(self)
	OpenExamine(debug.getinfo(2)) -- OpenExamine
	print("Please tell me if you see this, and a screenshot of the examine dialog would help.")
end
function objlist:Clear()
  table.iclear(self)
	OpenExamine(debug.getinfo(2)) -- OpenExamine
	print("Please tell me if you see this, and a screenshot of the examine dialog would help.")
end
-- objlist end

local g_env, debug
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	blacklist = false
	g_env, debug = env, env.debug
end

local GetParentOfKind = ChoGGi_Funcs.Common.GetParentOfKind
local function GetRootDialog(dlg)
	return dlg.parent_dialog or GetParentOfKind(dlg, "ChoGGi_DlgExamine")
end
DefineClass.ChoGGi_DlgExamine = {
	__parents = {"ChoGGi_XWindow"},

	-- what we're examining
	obj = false,
	-- sent by examine func
	varargs = false,
	-- all examine dlgs opened by another dlg will have the same id (batch close)
	parent_id = false,
	-- whatever RetName is
	name = false,
	-- If we're examining a string we want to convert to an object
	str_object = false,
	-- we store the str_object > obj here
	obj_ref = false,
--~ 	-- used to store visibility of obj
--~ 	orig_vis_flash = false,
--~ 	flashing_thread = false,
	-- get list of all values from metatables
	show_all_values = false,
	-- list values from EnumVars()
	show_enum_values = false,
	-- stores enummed list
	enum_vars = false,
	-- going in through the backdoor
	sort_dir = false,
	-- If TaskRequest then store flags here
	obj_flags = false,
	-- stores obj entity string
	obj_entity = false,
	-- delay between updating for autoref
	autorefresh_delay = 1000,
	-- any objs from this examine that were marked with a sphere/colour
	marked_objects = false,
	-- skip adding prefix to title
	override_title = false,
	-- close links
	hyperlink_end = "</h></color>",
	-- up/down arrow keys in exec code
	history_queue_idx = false,
	-- IsValid()
	is_valid_obj = false,
	-- examine children in same dialog
	child_lock = false,
	child_lock_dlg = false,
	-- Figure out what to use for JA3 instead of UICity
	city_object = false,


	-- strings called repeatedly
	string_Loadingresources = false,
	string_Classname = false,
	string_BuildingTemplate = false,
	string_Entity = false,
	string_Class = false,
	string_Object = false,
	string_State = false,
	-- local some str concats since we call ConvertValueToInfo a fair amount
	string_cvti_ex_colour_str = false,
	string_cvti_ex_colour_num = false,
	string_cvti_ex_colour_bool = false,
	string_cvti_ex_colour_boolfalse = false,
	string_cvti_ex_colour_nil = false,
	string_cvti_data = false,
	string_cvti_slash_data = false,

	-- only chinese goes slow as molasses for some reason (whatever text rendering they do?)
	-- I added this to stop the game from freezing till obj is examined
	-- that way you can at least close the dlg if it's taking too long (There's also a warning after 25K?)
	is_chinese = false,

--~ 	-- if someone wants the old toggle visible then we can use this.
--~ 	flash_rect = true,

	-- change default leftclick action for tables
	exec_tables = false,
	-- show image in some tooltips
	tooltip_info = false,

	idAutoRefresh_update_str = T{"<refresh>\n<click_info>\n<current>: <color 100 255 100><auto_refresh></color>",
		refresh = T(302535920001257--[[Auto-refresh list every second.]]),
		click_info = T(302535920001422--[[<right_click> to change refresh delay.]]),
		current = T(302535920000106--[[Current]]),
	},

	dialog_width = 666.0,
	dialog_height = 850.0,

	-- add some random numbers as ids so when you click a popup of the same name from another examine it'll close then open the new one
	idAttachesMenu = false,
	idParentsMenu = false,
	idToolsMenu = false,
	idObjectsMenu = false,
	-- tables
	parents_menu_popup = false,
	attaches_menu_popup = false,
	attaches_menu_popup_hint = false,
	tools_menu_popup = false,
	objects_menu_popup = false,

	pmenu_skip_dupes = false,
	parents = false,
	ancestors = false,
	menu_added = false,
	menu_list_items = false,
	-- clickable purple text
	onclick_funcs = false,
	onclick_name = false,
	onclick_objs = false,
	onclick_count = false,
	hex_shape_tables = false,
}

function ChoGGi_DlgExamine:Init(parent, context)
	if what_game == "Mars" then
		self.city_object = UICity
	elseif what_game == "JA3" then
		self.city_object = Game
	end


	local g_Classes = g_Classes
	self.ChoGGi = ChoGGi
	self.obj = context.obj

	-- ECM isn't installed
	if testing then
		local us = self.ChoGGi.UserSettings
		us.ExamineColourNum = "ChoGGi_yellow_ex"
		us.ExamineColourBool = "ChoGGi_blue_ex"
		us.ExamineColourBoolFalse = "ChoGGi_red_ex"
		us.ExamineColourStr = "ChoGGi_white_ex"
		us.ExamineColourNil = "ChoGGi_gray_ex"
	elseif not self.ChoGGi.UserSettings.ExamineColourNum then
		local us = self.ChoGGi.UserSettings
		us.ExamineColourNum = "255 255 0"
		us.ExamineColourBool = "0 255 0"
		us.ExamineColourBoolFalse = "255 150 150"
		us.ExamineColourStr = "255 255 255"
		us.ExamineColourNil = "175 175 175"
		us.EnableToolTips = true
	end

	-- my popup func checks for ids and "refreshs" a popup with the same id, so random it is
	self.idAttachesMenu = ChoGGi_Funcs.Common.Random()
	self.idParentsMenu = ChoGGi_Funcs.Common.Random()
	self.idToolsMenu = ChoGGi_Funcs.Common.Random()
	self.idObjectsMenu = ChoGGi_Funcs.Common.Random()
	-- add a parent id if there isn't one
	self.parent_id = context.parent_id or ChoGGi_Funcs.Common.Random()

	self.attaches_menu_popup = {}
	self.attaches_menu_popup_hint = {}
	self.parents_menu_popup = {}
	self.pmenu_skip_dupes = {}
	self.parents = {}
	self.ancestors = {}
	self.menu_added = {}
	self.menu_list_items = {}
	self.onclick_funcs = {}
	self.onclick_name = {}
	self.onclick_objs = {}
	self.onclick_count = 0
	self.info_list_obj_str = {}
	self.info_list_sort_obj = {}
	self.info_list_sort_num = {}
	self.info_list_skip_dupes = {}
	self.info_list_data_meta = {}
	self.marked_objects = {}
	self.title = context.title
	self.override_title = context.override_title
	self.varargs = context.varargs
	self.prefix = Translate(302535920000069--[[Examine]])
	self.exec_tables = context.exec_tables
	self.tooltip_info = context.tooltip_info

	-- these are used during SetObj, so we trans once to speed up autorefresh
	self.string_Loadingresources = Translate(302535920001680--[[Loading resources]])
	self.string_Classname = Translate(302535920001681--[[Class name]])
	self.string_BuildingTemplate = Translate(302535920001682--[[Building Template]])
	self.string_Entity = Translate(302535920001683--[[Entity]])
	self.string_Class = Translate(302535920001684--[[Class]])
	self.string_Object = Translate(302535920001685--[[Object]])
	self.string_State = Translate(302535920001686--[[State]])

	self.string_cvti_ex_colour_str = "'<color " .. self.ChoGGi.UserSettings.ExamineColourStr .. "><tags off>"
	self.string_cvti_ex_colour_num = "<color " .. self.ChoGGi.UserSettings.ExamineColourNum .. ">"
	self.string_cvti_ex_colour_bool = "<color " .. self.ChoGGi.UserSettings.ExamineColourBool .. ">"
	self.string_cvti_ex_colour_boolfalse = "<color " .. self.ChoGGi.UserSettings.ExamineColourBoolFalse .. ">"
	self.string_cvti_ex_colour_nil = "<color " .. self.ChoGGi.UserSettings.ExamineColourNil .. ">nil</color>"
	self.string_cvti_data = Translate(302535920001057--[[Data]])
	self.string_cvti_slash_data = " / " .. self.string_cvti_data

	-- If we're examining a string we want to convert to an object
	if type(self.obj) == "string" then
		if context.parent == "str" then
			self.str_object = context.parent == "str" and true
			context.parent = nil
			-- on by default for it seems good
			context.auto_refresh = true
		elseif not blacklist then
			local err, files = g_env.AsyncListFiles(self.obj)
			if not err and #files > 0 then
				self.obj = files
			end
		end
	end

	-- w/h are updated when a dialog is closed
	width = width or self.dialog_width
	height = height or self.dialog_height
	self.dialog_width = width
	self.dialog_height = height

	-- examining list
	ChoGGi_dlgs_examine[self.obj] = self
	-- obj name
	self.name = RetName(self.str_object and self.obj or self.obj)
	-- By the Power of Grayskull!
	self:AddElements(parent, context)

	-- Ignoring scaling, this will bump the size of the next examine opened
	self.idSizeControl.OnMouseButtonUp = function(size_obj, pt, button, ...)
		if button == "L" then
			local x,y = self:GetSize():xy()
			local UIScale = self.ChoGGi.Temp.UIScale
			width = x + (x * UIScale)
			height = y + (y * UIScale)
			self.dialog_width = width
			self.dialog_height = height
		end
		return XSizeControl.OnMouseButtonUp(size_obj, pt, button, ...)
	end

	do -- toolbar area
		-- everything grouped gets a window to go in
		self.idToolbarArea = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idToolbarArea",
			Dock = "top",
			DrawOnTop = true,
		}, self.idDialog)

		--
		self.idToolbarButtons = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idToolbarButtons",
			Dock = "left",
			LayoutMethod = "HList",
			DrawOnTop = true,
		}, self.idToolbarArea)

		-- add all the toolbar buttons than toggle vis when we set the menu
		self.idButRefresh = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButRefresh",
			Image = "CommonAssets/UI/Menu/reload.tga",
			RolloverTitle = T(302535920001687--[[Refresh]]),
			RolloverText = T(302535920000092--[[Updates list with any changed values.]]),
			OnPress = self.idButRefresh_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButMouseExamine = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButMouseExamine",
			Image = "CommonAssets/UI/Menu/select_objects.tga",
			RolloverTitle = T(302535920001321--[[UI Click To Examine]]),
			RolloverText = T(302535920001322--[[Examine UI controls by clicking them.]]),
			OnPress = function()
				ChoGGi_Funcs.Common.TerminalRolloverMode(true, self)
			end,
		}, self.idToolbarButtons)
		--
		self.idButMouseExamine = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButCopyAllText",
			Image = "CommonAssets/UI/Menu/ExportImageSequence.tga",
			RolloverTitle = T(302535920000865--[[Copy All Text]]),
			RolloverText = T(302535920001674--[[Copies dialog text to clipboard.]]),
			OnPress = self.idButCopyAllText_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButClear = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButClear",
			Image = "CommonAssets/UI/Menu/NoblePreview.tga",
			RolloverTitle = T(302535920001688--[[Clear]]),
			RolloverText = T(302535920000016--[["Remove any coloured spheres/reset coloured objects
Press once to clear this examine, again to clear all."]]),
			OnPress = self.idButClear_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButMarkObject = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButMarkObject",
			Image = "CommonAssets/UI/Menu/DisableEyeSpec.tga",
			RolloverTitle = T(302535920000057--[[Mark Object]]),
			RolloverText = T(302535920000021--[[Mark object with coloured sphere and/or paint.]]),
			OnPress = self.idButMarkObject_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButDeleteObj = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButDeleteObj",
			Image = "CommonAssets/UI/Menu/delete_objects.tga",
			RolloverTitle = T(302535920001689--[[Delete]]),
			RolloverText = T{302535920000414--[["Are you sure you wish to delete <color ChoGGi_red><str></color>?"]],
				str = self.name,
			},
			OnPress = self.idButDeleteObj_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButClearTable = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButClearTable",
			Image = "CommonAssets/UI/Menu/clear_debug_texture.tga",
			RolloverTitle = T(302535920001741--[[Clear Table]]),
			RolloverText = T(302535920001742--[["Remove all entries from this table."]]),
			OnPress = self.idButClearTable_OnPress,
		}, self.idToolbarButtons)
		self.idButClearTable:SetVisible(false)
		--
		self.idButDeleteAllObj = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButDeleteAllObj",
			Image = "CommonAssets/UI/Menu/remove_water.tga",
			RolloverTitle = T(302535920001675--[[Delete All Objects]]),
			RolloverText = T{302535920001676--[["Are you sure you wish to delete all <color ChoGGi_red><str></color> objects? (from active map)"]],
				str = self.name,
			},
			OnPress = self.idButDeleteAllObj_OnPress,
		}, self.idToolbarButtons)
		self.idButDeleteAllObj:SetVisible(false)
		--

		-- objlist stuff
		self.idButSetObjlist = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButSetObjlist",
			Image = "CommonAssets/UI/Menu/toggle_post.tga",
			RolloverTitle = T(302535920001558--[[Toggle Objlist]]),
			RolloverText = T(302535920001559--[[Toggle setting the metatable for this table to an objlist (for using mark/delete all).]]),
			OnPress = self.idButToggleObjlist_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButMarkAll = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButMarkAll",
			Image = "CommonAssets/UI/Menu/ExportImageSequence.tga",
			RolloverTitle = T(302535920000058--[[Mark All Objects]]),
			RolloverText = T(302535920000056--[[Mark all items in objlist with coloured spheres.]]),
			OnPress = self.idButMarkAll_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButMarkAllLine = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButMarkAllLine",
			Image = "CommonAssets/UI/Menu/ShowOcclusion.tga",
			RolloverTitle = T(302535920001512--[[Mark All Objects (Line)]]),
			RolloverText = T(302535920001513--[[Add a line connecting all items in list.]]),
			OnPress = self.idButMarkAllLine_OnPress,
		}, self.idToolbarButtons)
		--
		self.idButDeleteAll = g_Classes.ChoGGi_XToolbarButton:new({
			Id = "idButDeleteAll",
			Image = "CommonAssets/UI/Menu/UnlockCollection.tga",
			RolloverTitle = T(302535920001690--[[Destroy all?]]),
			RolloverText = T(302535920000059--[[Destroy all objects in objlist!]]),
			OnPress = self.idButDeleteAll_OnPress,
		}, self.idToolbarButtons)
		-- objlist stuff

		-- far right side
		self.idToolbarButtonsRightRefresh = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idToolbarButtonsRightRefresh",
			Dock = "right",
			LayoutMethod = "HList",
			DrawOnTop = true,
		}, self.idToolbarArea)

		self.idAutoRefresh = g_Classes.ChoGGi_XCheckButton:new({
			Id = "idAutoRefresh",
			Dock = "right",
			Text = T(302535920000084--[[Auto-Refresh]]),
			RolloverText = T{self.idAutoRefresh_update_str, auto_refresh = self.autorefresh_delay},
			RolloverHint = T(302535920001425--[["<left_click> Toggle, <right_click> Set Delay"]]),
			OnChange = self.idAutoRefresh_OnChange,
			OnMouseButtonDown = self.idAutoRefresh_OnMouseButtonDown,
		}, self.idToolbarButtonsRightRefresh)

		self.idAutoRefreshDelay = g_Classes.ChoGGi_XTextInput:new({
			Id = "idAutoRefreshDelay",
			Dock = "left",
			MinWidth = 50,
			Margins = box(0, 0, 6, 0),
			FoldWhenHidden = true,
			RolloverText = T(302535920000967--[[Delay in ms between updating text.]]),
			OnTextChanged = self.idAutoRefreshDelay_OnTextChanged,
		}, self.idToolbarButtonsRightRefresh)
		-- vis is toggled when rightclicking autorefresh checkbox
		self.idAutoRefreshDelay:SetVisible(false)
		self.idAutoRefreshDelay:SetText(tostring(self.autorefresh_delay))

		-- mid right
		self.idToolbarButtonsRight = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idToolbarButtonsRight",
			Dock = "right",
			LayoutMethod = "HList",
			DrawOnTop = true,
		}, self.idToolbarArea)

		if ChoGGi.what_game == "Mars" then
			--
			self.idViewEnum = g_Classes.ChoGGi_XCheckButton:new({
				Id = "idViewEnum",
				MinWidth = 0,
				Text = T(302535920001442--[[Enum]]),
				RolloverText = T(302535920001443--[[Show values from EnumVars(obj).]]),
				OnChange = self.idViewEnum_OnChange,
			}, self.idToolbarButtonsRight)
		end
		--
		self.idShowAllValues = g_Classes.ChoGGi_XCheckButton:new({
			Id = "idShowAllValues",
			MinWidth = 0,
			Text = T(302535920001691--[[All]]),
			RolloverText = T(302535920001391--[[Show all values: getmetatable(obj).]]),
			OnChange = self.idShowAllValues_OnChange,
		}, self.idToolbarButtonsRight)
		--
		self.idSortDir = g_Classes.ChoGGi_XCheckButton:new({
			Id = "idSortDir",
			Text = T(302535920001692--[[Sort]]),
			RolloverText = T(302535920001248--[[Sort normally or backwards.]]),
			OnChange = self.idSortDir_OnChange,
		}, self.idToolbarButtonsRight)
		--
		self.idChildLock = g_Classes.ChoGGi_XCheckButton:new({
			Id = "idChildLock",
			Text = T(302535920001693--[[Child]]),
			RolloverTitle = T(302535920001694--[[Child Lock]]),
			RolloverText = T{302535920000920--[[Examining objs from this dlg will <color ChoGGi_red><var></color>examine them all in a single dlg.]],
				var = T(302535920001695--[[NOT]]),
			},
			OnChange = self.idChildLock_OnChange,
		}, self.idToolbarButtonsRight)
		--

	end -- toolbar area

	do -- search area
		self.idSearchArea = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idSearchArea",
			Dock = "top",
		}, self.idDialog)
		--
		self.idSearchText = g_Classes.ChoGGi_XTextInput:new({
			Id = "idSearchText",
			RolloverText = T(302535920000043--[["Press <color 0 200 0>Enter</color> to scroll to next found text, <color 0 200 0>Ctrl-Enter</color> to scroll to previous found text, <color 0 200 0>Arrow Keys</color> to scroll to each end."]]),
			Hint = Translate(302535920001696--[[Search]]),
			OnKbdKeyDown = self.idSearchText_OnKbdKeyDown,
		}, self.idSearchArea)
		--
		self.idSearch = g_Classes.ChoGGi_XButton:new({
			Id = "idSearch",
			Text = T(302535920001696--[[Search]]),
			Dock = "right",
			RolloverAnchor = "right",
			RolloverHint = T(302535920001424--[["<left_click> Next, <right_click> Previous, <middle_click> Top"]]),
			RolloverText = T(302535920000045--[["Scrolls down one line or scrolls between text in "Search".
Right-click <right_click> to go up, middle-click <middle_click> to scroll to the top."]]),
			OnMouseButtonDown = self.idSearch_OnMouseButtonDown,
		}, self.idSearchArea)
	end

	do -- tools area
		self.idMenuArea = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idMenuArea",
			Dock = "top",
		}, self.idDialog)
		--
		self.tools_menu_popup = self:BuildToolsMenuPopup()
		self.idTools = g_Classes.ChoGGi_XComboButton:new({
			Id = "idTools",
			Text = T(302535920000239--[[Tools]]),
			RolloverText = T(302535920001426--[[Various tools to use.]]),
			OnMouseButtonDown = self.idTools_OnMouseButtonDown,
			Dock = "left",
		}, self.idMenuArea)
		--
		self.objects_menu_popup = self:BuildObjectMenuPopup()
		self.idObjects = g_Classes.ChoGGi_XComboButton:new({
			Id = "idObjects",
			Text = self.string_Object,
			RolloverText = T(302535920001530--[[Various object tools to use.]]),
			OnMouseButtonDown = self.idObjects_OnMouseButtonDown,
			Dock = "left",
			FoldWhenHidden = true,
		}, self.idMenuArea)
		self.idObjects:SetVisible(false)
		--
		self.idParents = g_Classes.ChoGGi_XComboButton:new({
			Id = "idParents",
			Text = T(302535920000520--[[Parents]]),
			RolloverText = T(302535920000553--[[Examine parent and ancestor classes.]]),
			OnMouseButtonDown = self.idParents_OnMouseButtonDown,
			Dock = "left",
			FoldWhenHidden = true,
		}, self.idMenuArea)
		self.idParents:SetVisible(false)
		--
		self.idAttaches = g_Classes.ChoGGi_XComboButton:new({
			Id = "idAttaches",
			Text = T(302535920000053--[[Attaches]]),
			RolloverText = T(302535920000054--[[Any objects attached to this object.]]),
			OnMouseButtonDown = self.idAttaches_OnMouseButtonDown,
			Dock = "left",
			FoldWhenHidden = true,
		}, self.idMenuArea)
		self.idAttaches:SetVisible(false)
		--
		self.idToggleExecCode = g_Classes.ChoGGi_XCheckButton:new({
			Id = "idToggleExecCode",
			Dock = "right",
			Text = T(302535920000040--[[Exec Code]]),
			RolloverText = T(302535920001514--[[Toggle visibility of an input box for executing code.]])
				.. "\n" .. T(302535920001517--[[Use <green>o</green> as a reference to the examined object: <yellow>IsValid(</yellow><green>o</green><yellow>)</yellow>.]]),
			OnChange = self.idToggleExecCode_OnChange,
		}, self.idMenuArea)
		--
	end -- tools area

	do -- exec code area
		self.idExecCodeArea = g_Classes.ChoGGi_XDialogSection:new({
			Id = "idExecCodeArea",
			Dock = "top",
		}, self.idDialog)
		self.idExecCodeArea:SetVisible(false)
		--
		self.idExecCode = g_Classes.ChoGGi_XTextInput:new({
			Id = "idExecCode",
			RolloverText = T{302535920001515, [[Press <color ChoGGi_green><enter></color> to execute code.
Use <color ChoGGi_green><up></color>/<color ChoGGi_green><down></color> to select console history.
<extra_info>]],
				enter = T(302535920001697--[[Enter]]),
				up = T(302535920001698--[[Up]]),
				down = T(302535920001699--[[Down]]),
				extra_info = T(302535920001517--[[Use <green>o</green> as a reference to the examined object: <yellow>IsValid(</yellow><green>o</green><yellow>)</yellow>.]]),
			},
			Hint = Translate(302535920001516--[[o = examined object]]),
			OnKbdKeyDown = self.idExecCode_OnKbdKeyDown,
		}, self.idExecCodeArea)
		--
		self.idToggleExecCodeGroup = g_Classes.ChoGGi_XCheckButton:new({
			Id = "idToggleExecCodeGroup",
			Dock = "right",
			Margins = box(4, 0, 0, 0),
			Text = T(302535920000590--[[Batch]]),
			RolloverText = T(302535920000841--[["If examining a table then exec this code for each entry.
If it's an associative table then o = value."]]),
			OnChange = self.idToggleExecCodeGroup_OnChange,
		}, self.idExecCodeArea)

	end -- exec code area

	do -- everything else
		-- text box with obj info in it
		self:AddScrollText()

		self.idText.OnHyperLink = self.idText_OnHyperLink
		self.idText.OnHyperLinkRollover = self.idText_OnHyperLinkRollover

		-- no need to have it fire one than once per dialog
		self.is_chinese = GetLanguage():find("chinese")

		-- make sure up/down history works
		if not dlgConsole then
			CreateConsole()
		end
		local console = dlgConsole
		if not console.history_queue or #console.history_queue == 0 then
			console:ReadHistory()
		end

		-- do the magic
		if self:SetObj(true) and not IsKindOf(self.obj_ref, "InGameInterface") then
			self:FlashWindow()
		end

		if IsValid(self.obj_ref) then
			self.idButDeleteAllObj:SetVisible(true)
		end

		if context.auto_refresh then
			self.idAutoRefresh_OnChange(self.idAutoRefresh)
		end
		if context.toggle_sort then
			self:idSortDir_OnChange()
			self.idSortDir:SetIconRow(2)
		end

		-- certain funcs need to have an override so we can examine stuff
		self:SafeExamine(true)

		if IsPoint(context.parent) then
			self:PostInit(nil, context.parent)
		else
			self:PostInit(context.parent)
		end
	end -- everything else


	-- Hide it "till" I fix it
	self.idChildLock:SetVisible(false)
end

do -- SafeExamine
	-- some funcs don't check for an existing value (or something)
	-- so we replace those while we're examining
	-- backup any funcs we replace (while dialog(s) are opened)
	local ChoOrig_TFormat_Stat = TFormat.Stat

	local function Enable(self, replaced, name)
		if replaced[name] then
			-- already exists, so don't rereplace func, just add new dlg
			replaced[name][self.obj] = true
		else
			-- add what we use to distinguish between ex dialogs
			replaced[name] = {[self.obj] = true}

			-- TFormat.Stat doesn't check if value is a number, or not nil
			function TFormat.Stat(context_obj, value, ...)
				value = value or 0
				return ChoOrig_TFormat_Stat(context_obj, value, ...)
			end
		end

	end

	local function Disable(self, replaced, name)
		if replaced[name] then
			replaced[name][self.obj] = nil
			if not next(replaced[name]) then
				-- don't need this table anymore
				replaced[name] = nil
				-- no more dlgs left in table, so we can unreplace the func
				TFormat.Stat = ChoOrig_TFormat_Stat
			end
		else
			-- should never happen (tm)
			printC("EXAMINE ERROR! SafeExamine can't find dialog for disable:", name)
		end
	end

	function ChoGGi_DlgExamine:SafeExamine(enable)

		local replaced = ChoGGi_dlgs_examine_funcs
		if enable then
			if IsKindOf(self.obj_ref, "XTemplateTemplate") then
				Enable(self, replaced, "TFormat.Stat")
			end
		else
			if IsKindOf(self.obj_ref, "XTemplateTemplate") then
				Disable(self, replaced, "TFormat.Stat")
			end
		end

	end
end -- do

function ChoGGi_DlgExamine:ViewSourceCode()
	self = GetRootDialog(self)
	-- add link to view lua source
	local info = debug.getinfo(self.obj_ref, "S")
	-- =[C] is 4 chars (huh?)
	local str, path = ChoGGi_Funcs.Common.RetSourceFile(info.source)
	path = ConvertToOSPath(path)
	if not str then
		local msg = T{302535920001521--[[Lua source file not found: <str>]],
			str = info.source,
		}
		ChoGGi_Funcs.Common.MsgPopup(
			msg,
			T(302535920001519--[[View Source]])
		)
		print(Translate(msg))
		return
	end

	ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
		parent = self,
		checkbox = true,
		text = str,
		code = true,
		scrollto = info.linedefined,
		title = T(302535920001519--[[View Source]]) .. " " .. info.source,
		hint_ok = T{302535920000047--[["View Text/Object, and optionally dumps text to <color ChoGGi_yellow><path>logs\DumpedExamine.lua</color>."]],
			path = ConvertToOSPath("AppData/"),
		},
		file_path = path,
		_G = _G,
		custom_func = function(overwrite)
			ChoGGi_Funcs.Common.Dump("\n" .. str, overwrite, "DumpedSource", "lua")
		end,
	}
end

function ChoGGi_DlgExamine:AddDistToRollover(c, roll_text, idx, idx_value, obj, obj_value)
	if IsPoint(idx) then
		c = c + 1
		roll_text[c] = obj
		c = c + 1
		roll_text[c] = ":Dist2D("
		c = c + 1
		roll_text[c] = idx_value
		c = c + 1
		roll_text[c] = ") = "
		c = c + 1
		roll_text[c] = obj_value:Dist2D(idx)
		c = c + 1
		roll_text[c] = "\n"
	end
	return c
end

-- hover (link, hyperlink_box, pos)
function ChoGGi_DlgExamine:idText_OnHyperLinkRollover(link)
	self = GetRootDialog(self)

	if not self.ChoGGi.UserSettings.EnableToolTips then
		return
	end
	if not link then
		-- close opened tooltip
		if RolloverWin then
			XDestroyRolloverWindow()
		end
		return
	end

	link = tonumber(link)
	local obj = self.onclick_objs[link]
	if not obj then
		return
	end

	local obj_name = RetName(obj)
	local roll_text = {}
	local c = 0

	local title, obj_str, obj_type
	if self.obj_type == "table" or self.obj_type == "userdata"
		or self.obj_type == "string" or self.obj_type == "number"
	then
		local obj_value = self.obj_type == "table"
			and ChoGGi_Funcs.Common.RetTableValue(self.obj_ref, obj)
		local obj_value_type = type(obj_value)
		local hovered_obj_type = type(obj)

		if obj_value_type ~= "nil" then
			obj_str, obj_type = ChoGGi_Funcs.Common.ValueToStr(obj_value)
			if obj_value_type == "function" then
				obj_str = obj_str .. "\n" .. ChoGGi_Funcs.Common.DebugGetInfo(obj_value)
			-- check for and add dist from idx-1 and +1 (show hex count instead?)
			elseif IsPoint(obj_value) and hovered_obj_type == "number" then
				c = self:AddDistToRollover(c, roll_text, self.obj_ref[obj-1], obj-1, obj, obj_value)
				c = self:AddDistToRollover(c, roll_text, self.obj_ref[obj+1], obj+1, obj, obj_value)
			end
		-- translate T()
		elseif hovered_obj_type == "table" then

			-- display any text in tooltip
			if obj.text and obj.text ~= "" then
				c = c + 1
				roll_text[c] = Translate(obj.text)
				c = c + 1
				roll_text[c] = "\n\n"

			-- translate text
			elseif IsT(obj) then
				local meta = getmetatable(obj)
				if meta == TMeta then
					obj_type = "TMeta"
				elseif meta == TConcatMeta then
					obj_type = "TConcatMeta"
				else
					obj_type = "LocId"
				end
				c = c + 1
				roll_text[c] = Translate(obj)
				c = c + 1
				roll_text[c] = "\n\n"

			-- add tooltip info
			elseif self.tooltip_info then
				-- make sure breaks are "sorted" and at the top
				local b_count = #obj
				for i = 1, b_count do
					c = c + 1
					roll_text[c] = self:ConvertValueToInfo(obj[i]):gsub("'", "")
					if i ~= b_count then
						c = c + 1
						roll_text[c] = ", "
					end
				end

				-- sort list of other values
				local values = {}
				local values_c = 0
				local values_temp = {"\n",""," ", ""}

				for key, value in pairs(obj) do
					-- breakthroughs
					if type(key) ~= "number" then

						values_temp[2] = self:ConvertValueToInfo(key):gsub("'", "")
						values_temp[4] = self:ConvertValueToInfo(value):gsub("'", "")
						values_c = values_c + 1
						values[values_c] = table.concat(values_temp)
					end
				end
				table.sort(values)
				c = c + 1
				roll_text[c] = "\n"
				c = c + 1
				roll_text[c] = table.concat(values)
				c = c + 1
				roll_text[c] = "\n\n<image "
				c = c + 1
				roll_text[c] = self.tooltip_info(obj, self)
				c = c + 1
				roll_text[c] = ">\n\n"

			elseif IsValid(obj) then
				c = c + 1
				roll_text[c] = Translate(302535920001700--[[Map]])
				c = c + 1
				roll_text[c] = ": "
				c = c + 1
				roll_text[c] = RetObjMapId(obj, true)
				c = c + 1
				roll_text[c] = "\n\n"

			else
				-- ...

			end
		elseif hovered_obj_type == "function" then
			obj_type = hovered_obj_type
			c = c + 1
			roll_text[c] = self:RetFuncArgs(obj)
			c = c + 1
			roll_text[c] = "\n\n"
		else
			obj_str, obj_type = ChoGGi_Funcs.Common.ValueToStr(obj)
		end

		if obj_type then
			title = T(302535920000069--[[Examine]]) .. " (" .. obj_type .. ")"
		end
	else
		-- for anything that isn't a table
		title = T(302535920000069--[[Examine]])
	end

	if self.onclick_funcs[link] == self.OpenListMenu then
		if obj_type then
			title = obj_name .. " " .. T(302535920001701--[[Menu]]) .. " (" .. obj_type .. ")"
		else
			title = obj_name .. " " .. T(302535920001701--[[Menu]])
		end

		-- stick info at the top of list
		table.insert(roll_text, 1, T{
				302535920001540--[[Show context menu for <green><menu></green>.]],
				menu = obj_name,
			} .. "\n"
		)
		-- add the value to the key tooltip
		table.insert(roll_text, 2, obj_str .. "\n\n")
		c = c + 2

		-- If it's an image then add 'er to the text
		if ChoGGi_Funcs.Common.ValidateImage(obj_str) then
			c = c + 1
			roll_text[c] = "\n\n<image "
			c = c + 1
			roll_text[c] = obj_str
			c = c + 1
			roll_text[c] = ">"
		end
	else
		c = c + 1
		roll_text[c] = obj_name
	end

	XCreateRolloverWindow(self.idDialog, RolloverGamepad, true, {
		RolloverTitle = title,
		RolloverText = self.onclick_name[link] or table.concat(roll_text),
		RolloverHint = T(302535920001079--[[<left_click> Default Action <right_click> Examine]]),
	})
end

-- clicked
function ChoGGi_DlgExamine:idText_OnHyperLink(link, argument, hyperlink_box, pos, button)
	self = GetRootDialog(self)

	link = tonumber(link)
	local obj = self.onclick_objs[link]

	-- we always examine on right-click
	if button == "R" then
		ChoGGi_Funcs.Common.OpenInExamineDlg(obj, {
			has_params = true,
			parent = self,
		})
	else
		local func = self.onclick_funcs[link]
		if func then
			func(self, button, obj, argument, hyperlink_box, pos, link)
		end
	end

end
-- create
function ChoGGi_DlgExamine:HyperLink(obj, func, name)
	local c = self.onclick_count
	c = c + 1

	self.onclick_count = c
	self.onclick_objs[c] = obj
	self.onclick_funcs[c] = func
	if name then
		self.onclick_name[c] = name
	end

	return "<color ChoGGi_turquoise><h " .. c .. " 230 195 50>", c
end

function ChoGGi_DlgExamine:BatchExecCode(text)
	-- proper table?
	if self.obj_type ~= "table"
			or self.obj_type == "table" and not next(self.obj_ref)
	then
		return
	end
	local dlgConsole = dlgConsole

	local count = #self.obj_ref
	if count > 0 then
		for i = 1, count do
			o = self.obj_ref[i]
			dlgConsole:Exec(text)
		end
	else
		for _, value in pairs(self.obj_ref) do
			o = value
			dlgConsole:Exec(text)
		end
	end
end

function ChoGGi_DlgExamine:idExecCode_OnKbdKeyDown(vk, ...)
	-- console exec code
	if vk == const.vkEnter then
		local text = self:GetText()
		if text ~= "" then
			self = GetRootDialog(self)
			if self.idToggleExecCodeGroup:GetCheck() then
				-- fire on each entry
				self:BatchExecCode(text)
			else
				-- update global obj
				o = self.obj_ref
				-- fire!
				dlgConsole:Exec(text)
				-- update examine
				self:SetObj()
			end
		end
		return "break"

	elseif vk == const.vkDown or vk == const.vkUp then
		local con = dlgConsole
		local dlg = GetRootDialog(self)
		-- use current ex dlg pos or actual con pos
		dlg.history_queue_idx = dlg.history_queue_idx or con.history_queue_idx

		if vk == const.vkDown then
			if dlg.history_queue_idx <= 1 then
				dlg.history_queue_idx = #con.history_queue
			else
				dlg.history_queue_idx = dlg.history_queue_idx - 1
			end
		else
			if dlg.history_queue_idx + 1 <= #con.history_queue then
				dlg.history_queue_idx = dlg.history_queue_idx + 1
			else
				dlg.history_queue_idx = 1
			end
		end

		local text = con.history_queue[dlg.history_queue_idx] or ""
		self:SetText(text)
		self:SetCursor(1, #text)
		return "break"

	end

	return g_Classes.ChoGGi_XTextInput.OnKbdKeyDown(self, vk, ...)
end

function ChoGGi_DlgExamine:idToggleExecCode_OnChange(visible)
	self = GetRootDialog(self)
	local vis = self.idExecCodeArea:GetVisible()
	if vis ~= visible then
		self.idExecCodeArea:SetVisible(not vis)
		if self.idExecCode:GetVisible() then
			self.idExecCode:SetFocus()
		end
		self.idToggleExecCode:SetCheck(not vis)
	end
end
function ChoGGi_DlgExamine:idToggleExecCodeGroup_OnChange(visible)
	local check = self
	self = GetRootDialog(self)

	-- block check from true if not indexed table
	if visible and self.obj_type ~= "table"
			or self.obj_type == "table" and not next(self.obj_ref)
	then
		check:SetCheck(false)
	end
end

function ChoGGi_DlgExamine:idButCopyAllText_OnPress()
	self = GetRootDialog(self)
	local text = self:GetCleanText()
	CopyToClipboard(text)
end

function ChoGGi_DlgExamine:idButRefresh_OnPress()
	self = GetRootDialog(self)

	self:SetObj()
	-- This was being called when clicking on a func in an object, so added a type check for whatever happened?
	if type(self.obj_ref) == "table" and self.obj_ref.class ~= "InGameInterface" then
		self:FlashWindow()
	end
end
function ChoGGi_DlgExamine:idChildLock_OnChange(visible)
	self = GetRootDialog(self)

	self.child_lock = visible

	if visible then
		visible = ""
	else
		visible = T(302535920001695--[[NOT]]) .. " "
	end

	self.idChildLock:SetRolloverText(T{302535920000920--[[Examining objs from this dlg will <color ChoGGi_red><var></color>examine them all in a single dlg.]],
		var = visible,
	})
end
-- stable name for external use
function ChoGGi_DlgExamine:RefreshExamine()
	self:idButRefresh_OnPress()
end

function ChoGGi_DlgExamine:idButClear_OnPress()
	self = GetRootDialog(self)
	-- clear marked objs for this examine
	local count = #self.marked_objects
	if count > 0 then
		for i = 1, count do
			ChoGGi_Funcs.Common.ClearShowObj(self.marked_objects[i])
		end
	else
		-- clear all spheres
		ChoGGi_Funcs.Common.ClearShowObj(true)
		-- If this has a custom colour
		ChoGGi_Funcs.Common.ClearShowObj(self.obj_ref)
		-- clear all bboxes
		local boxes = self.ChoGGi.Temp.Examine_BBoxes
		if boxes then
			for i = #boxes, 1, -1 do
				boxes[i]:delete()
				table.remove(boxes, i)
			end
		end
	end
	table.iclear(self.marked_objects)

	self:CleanupCustomObjs(self.obj_ref, true)
end

function ChoGGi_DlgExamine:idButMarkObject_OnPress()
	self = GetRootDialog(self)
	if IsValid(self.obj_ref) then
		-- I don't use AddSphere since that won't add the ColourObj
		local c = #self.marked_objects
		local sphere = ChoGGi_Funcs.Common.ShowPoint(self.obj_ref)
		if IsValid(sphere) then
			c = c + 1
			self.marked_objects[c] = sphere
		end
		local obj = ChoGGi_Funcs.Common.ColourObj(self.obj_ref)
		if IsValid(obj) then
			c = c + 1
			self.marked_objects[c] = obj
		end
	else
		local c = #self.marked_objects
		for _, v in pairs(self.obj_ref) do
			if IsPoint(v) or IsValid(v) then
				c = self:AddSphere(v, c)
			end
		end
	end
end

function ChoGGi_DlgExamine:idButDeleteAllObj_OnPress()
	self = GetRootDialog(self)
	ChoGGi_Funcs.Common.DeleteAllObjectQuestion(self.obj_ref.class)
end

function ChoGGi_DlgExamine:idButClearTable_OnPress()
	self = GetRootDialog(self)
	ChoGGi_Funcs.Common.DoSomethingQuestion(self.obj_ref, table.clear)
end
function ChoGGi_DlgExamine:idButDeleteObj_OnPress()
	self = GetRootDialog(self)
	ChoGGi_Funcs.Common.DeleteObjectQuestion(self.obj_ref)
end

function ChoGGi_DlgExamine:idButDeleteAll_OnPress()
	self = GetRootDialog(self)
	ChoGGi_Funcs.Common.QuestionBox(
		T(302535920000059--[[Destroy all objects in objlist!]]),
		function(answer)
			if answer then
				SuspendPassEdits("ChoGGi_DlgExamine:idButDeleteAll_OnPress")
				for _, obj in pairs(self.obj_ref) do
					if IsValid(obj) then
						-- true skips dust plume
						ChoGGi_Funcs.Common.DeleteObject(obj, true)
					elseif obj.delete then
						obj:delete()
					end
				end
				ResumePassEdits("ChoGGi_DlgExamine:idButDeleteAll_OnPress")
				-- force a refresh on the list, so people can see something as well
				self:SetObj()
			end
		end,
		T(302535920001702--[[Destroy]])
	)
end
function ChoGGi_DlgExamine:idViewEnum_OnChange()
	self = GetRootDialog(self)
	self.show_enum_values = not self.show_enum_values
	self:SetObj()
end

function ChoGGi_DlgExamine:idButMarkAllLine_OnPress()
	self = GetRootDialog(self)
	ChoGGi_Funcs.Common.ObjListLines_Toggle(self.obj_ref)
end

function ChoGGi_DlgExamine:idButMarkAll_OnPress()
	self = GetRootDialog(self)
	local c = #self.marked_objects
	-- suspending makes it faster to add objects
	SuspendPassEdits("ChoGGi_DlgExamine:idButMarkAll_OnPress")
	for _, v in pairs(self.obj_ref) do
		if IsValid(v) or IsPoint(v) then
			c = self:AddSphere(v, c, nil, true, true)
		end
	end
	ResumePassEdits("ChoGGi_DlgExamine:idButMarkAll_OnPress")
	ChoGGi_Funcs.Common.TableCleanDupes(self.marked_objects)
end

function ChoGGi_DlgExamine:idButToggleObjlist_OnPress()
	self = GetRootDialog(self)

	local meta = getmetatable(self.obj_ref)
	if meta == objlist then
		setmetatable(self.obj_ref, nil)
	elseif not meta then
		setmetatable(self.obj_ref, objlist)
	end
	-- update view
	self:SetObj()
end

function ChoGGi_DlgExamine:AddSphere(obj, c, colour, skip_view, skip_colour)
	-- check if it's using on-map coords or hex, if it's hex then convert so we're not placing a marker in the bottom right of map
	if IsPoint(obj) and WorldToHex(obj) == 0 then
		local q, r = obj:xy()
		obj = point(HexToWorld(q, r))
	end
	local sphere = ChoGGi_Funcs.Common.ShowObj(obj, colour, skip_view, skip_colour)
	if IsValid(sphere) then
		c = (c or #self.marked_objects) + 1
		self.marked_objects[c] = sphere
	end
	return c
end

function ChoGGi_DlgExamine:idAutoRefresh_OnChange()
	local checked = self:GetCheck()
	self = GetRootDialog(self)

	-- If already running then stop and return
	if IsValidThread(self.autorefresh_thread) then

		if checked then
			self.idAutoRefresh:SetCheck(false)
		end
		DeleteThread(self.autorefresh_thread)
		return
	end

	-- otherwise fire it up
	self.autorefresh_thread = CreateRealTimeThread(function()
		if not checked then
			self.idAutoRefresh:SetCheck(true)
		end
		-- thread killed when dlg closed or check unchecked
		while true do
			self:SetObj()
			Sleep(self.autorefresh_delay)
			-- msg any of my monitoring funcs
			Msg("ChoGGi_dlgs_examine_autorefresh", self)
		end
	end)
end
-- stable name for external use
function ChoGGi_DlgExamine:EnableAutoRefresh()
	self.idAutoRefresh_OnChange(self.idAutoRefresh)
end
function ChoGGi_DlgExamine:idAutoRefresh_OnMouseButtonDown(pt, button, ...)
	g_Classes.ChoGGi_XCheckButton.OnMouseButtonDown(self, pt, button, ...)
	if button == "R" then

		self = GetRootDialog(self)
		local visible = self.idAutoRefreshDelay:GetVisible()
		self.idAutoRefreshDelay:SetVisible(not visible)
		if visible then
			self.idMoveControl:SetFocus()
		end
		local num = tonumber(self.idAutoRefreshDelay:GetText())
		if num then
			self.ChoGGi.UserSettings.ExamineRefreshTime = num
			ChoGGi_Funcs.Settings.WriteSettings()
		end

	end
end

function ChoGGi_DlgExamine:idAutoRefreshDelay_OnTextChanged()
	local num = tonumber(self:GetText())
	-- someone always enters a non-number...
	if num then
		-- probably best to keep it above this (just in case it's a large table)
		if num < 10 then
			num = 10
		end
		self = GetRootDialog(self)
		self.autorefresh_delay = num
		self.idAutoRefresh:SetRolloverText(T{self.idAutoRefresh_update_str, auto_refresh = num})
	end
end

function ChoGGi_DlgExamine:idSortDir_OnChange()
	self = GetRootDialog(self)
	self.sort_dir = not self.sort_dir
	self:SetObj()
end

function ChoGGi_DlgExamine:idShowAllValues_OnChange()
	self = GetRootDialog(self)
	self.show_all_values = not self.show_all_values
	self:SetObj()
end

function ChoGGi_DlgExamine:DumpExamineText(text, name, ext, overwrite)
	name = name or "DumpedExamine"
	ext = ext or "lua"

	-- If it gets called from MultiLineTextDlg and the examine dialog was closed
	local ChoGGi = self.ChoGGi or ChoGGi

	if ChoGGi.UserSettings.ExamineAppendDump then
		ChoGGi_Funcs.Common.Dump("\n" .. text, overwrite, name, ext)
	else
		ChoGGi_Funcs.Common.Dump(text, overwrite, name, ext, nil, true)
	end
end

function ChoGGi_DlgExamine:BuildObjectMenuPopup()
	return {
		{name = T(302535920001703--[[Select Target]]),
			hint = T(302535920001667--[[Selects examine object]]),
			image = "CommonAssets/UI/Menu/select_objects.tga",
			clicked = function()
        SelectObj(self.obj_ref)
			end,
		},
		{name = T(302535920000457--[[Anim State Set]]),
			hint = T(302535920000458--[[Make object dance on command.]]),
			image = "CommonAssets/UI/Menu/UnlockCamera.tga",
			clicked = function()
				ChoGGi_Funcs.Common.SetAnimState(self.obj_ref)
			end,
		},
		{name = T(302535920000682--[[Change Entity]]),
			hint = T{302535920001151--[[Set Entity For <entity>]],
				entity = self.name,
			},
			image = "CommonAssets/UI/Menu/SetCamPos&Loockat.tga",
			clicked = function()
				ChoGGi_Funcs.Common.EntitySpawner(self.obj_ref, {
					skip_msg = true,
					list_type = 7,
					title_postfix = RetName(self.name),
				})
			end,
		},
		{name = T(302535920000129--[[Set]]) .. " " .. T(302535920001184--[[Particles]]),
			hint = T(302535920001421--[[Shows a list of particles you can use on the selected obj.]]),
			image = "CommonAssets/UI/Menu/place_particles.tga",
			clicked = function()
				ChoGGi_Funcs.Common.SetParticles(self.obj_ref)
			end,
		},
		{name = T(302535920001476--[[Edit Flags]]),
			hint = T(302535920001447--[[Show and toggle the list of flags for selected object.]]),
			image = "CommonAssets/UI/Menu/JoinGame.tga",
			clicked = function()
				-- task requests have flags too, ones that aren't listed in the Flags table... (just const.rf*)
				if self.obj_flags then
					ChoGGi_Funcs.Common.ObjFlagsList_TR(self.obj_ref, self)
				else
					ChoGGi_Funcs.Common.ObjFlagsList(self.obj_ref, self)
				end
			end,
		},
		{is_spacer = true},
		{name = T(302535920001472--[[BBox Toggle]]),
			hint = T(302535920001473--[[Toggle showing object's bbox (changes depending on movement).]]),
			image = "CommonAssets/UI/Menu/SelectionEditor.tga",
			clicked = function()
				self:ShowBBoxList()
			end,
		},
		{name = T(302535920001522--[[Hex Shape Toggle]]),
			hint = T(302535920001523--[[Toggle showing shapes for the object.]]),
			image = "CommonAssets/UI/Menu/SetCamPos&Loockat.tga",
			clicked = function()
				self:ShowHexShapeList()
			end,
		},
		{name = T(302535920000449--[[Entity Spots Toggle]]),
			hint = T(302535920000450--[[Toggle showing attachment spots on selected object.]]),
			image = "CommonAssets/UI/Menu/ShowAll.tga",
			clicked = function()
				self:ShowEntitySpotsList()
			end,
		},
		{name = T(302535920000459--[[Anim Debug Toggle]]),
			hint = T(302535920000460--[[Attaches text to each object showing animation info (or just to selected object).]]),
			image = "CommonAssets/UI/Menu/CameraEditor.tga",
			clicked = function()
				ChoGGi_Funcs.Common.ShowAnimDebug_Toggle(self.obj_ref)
			end,
		},
		{name = T(302535920001551--[[Surfaces Toggle]]),
			hint = T(302535920001552--[[Show a list of surfaces and draw lines over them (GetRelativeSurfaces).]]),
			image = "CommonAssets/UI/Menu/ToggleCollisions.tga",
			clicked = function()
				self:ShowSurfacesList()
			end,
		},
		{is_spacer = true},
		{name = T(302535920000235--[[Entity Spots]]),
			hint = T(302535920001445--[[Shows list of attaches for use with .ent files.]]),
			image = "CommonAssets/UI/Menu/ListCollections.tga",
			clicked = function()
				ChoGGi_Funcs.Common.ExamineEntSpots(self.obj_ref, self)
			end,
		},
		{name = T(302535920001458--[[Material Properties]]),
			hint = T(302535920001459--[[Shows list of material settings/.dds files for use with .mtl files.]]),
			image = "CommonAssets/UI/Menu/ConvertEnvironment.tga",
			clicked = function()
				ChoGGi_Funcs.Common.GetMaterialProperties(self.obj_entity, self)
			end,
		},
		{name = T(302535920001524--[[Entity Surfaces]]),
			hint = T(302535920001525--[[Shows list of surfaces for the object entity.]]),
			image = "CommonAssets/UI/Menu/ToggleOcclusion.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenInExamineDlg(ChoGGi_Funcs.Common.RetSurfaceMasks(self.obj_ref), {
					has_params = true,
					parent = self,
					title = T(302535920001524--[[Entity Surfaces]]) .. ": " .. self.name,
				})
			end,
		},
	}
end

function ChoGGi_DlgExamine:BuildToolsMenuPopup()
	local list = {
		{name = T(302535920001467--[[Append Dump]]),
			hint = T(302535920001468--[["Append text to same file, or create a new file each time."]]),
			clicked = function()
				self.ChoGGi.UserSettings.ExamineAppendDump = not self.ChoGGi.UserSettings.ExamineAppendDump
				ChoGGi_Funcs.Settings.WriteSettings()
			end,
			value = "ChoGGi.UserSettings.ExamineAppendDump",
			class = "ChoGGi_XCheckButtonMenu",
		},

		{name = self.ChoGGi.UserSettings.ExamineTextType and T(302535920001704--[[Text]]) or self.string_Object,
			hint = T(302535920001620--[["Click to toggle between Text or Object (View/Dump).
<green>Text</green> is what you see, <green>Object</green> is the text created from ValueToLuaCode(obj)."]]),
			clicked = function(item)
				self.ChoGGi.UserSettings.ExamineTextType = not self.ChoGGi.UserSettings.ExamineTextType
				ChoGGi_Funcs.Settings.WriteSettings()

				-- change this item name
				if self.ChoGGi.UserSettings.ExamineTextType then
					item.name = T(302535920001704--[[Text]])
				else
					item.name = self.string_Object
				end
			end,
			value = "ChoGGi.UserSettings.ExamineTextType",
			class = "ChoGGi_XCheckButtonMenu",
		},

		{name = T(302535920000004--[[Dump]]),
			hint = T{302535920000046--[["Dumps Text/Object to <color ChoGGi_yellow><path>logs\DumpedExamine.lua</color>."]],
				path = ConvertToOSPath("AppData/"),
			}	.. "\n\n" .. T(302535920001027--[[Object can take time on something like the ""Building"" class object.]]),
			image = "CommonAssets/UI/Menu/change_height_down.tga",
			clicked = function()
				local str, name
				if self.ChoGGi.UserSettings.ExamineTextType then
					str = self:GetCleanText()
					name = "DumpedExamineText"
				else
					str = ValueToLuaCode(self.obj_ref)
					name = "DumpedExamineObject"
				end
				self:DumpExamineText(str, name)
			end,
		},
		{name = T(302535920000048--[[View]]),
			hint = T{302535920000047--[["View Text/Object, and optionally dumps text to <color ChoGGi_yellow><path>logs\DumpedExamine.lua</color>."]],
				path = ConvertToOSPath("AppData/"),
			}	.. "\n\n" .. T(302535920001027--[[Object can take time on something like the ""Building"" class object.]]),
			image = "CommonAssets/UI/Menu/change_height_up.tga",
			clicked = function()
				-- pure text string
				local str, name, scrolled_text, title
				if self.ChoGGi.UserSettings.ExamineTextType then
					str, scrolled_text = self:GetCleanText(true)
					name = "DumpedExamineText"
					title = T(302535920000048--[[View]]) .. "/" .. T(302535920000004--[[Dump]]) .. " " .. T(302535920001704--[[Text]])
				else
					str = ValueToLuaCode(self.obj_ref)
					name = "DumpedExamineObject"
					title = T(302535920000048--[[View]]) .. "/" .. T(302535920000004--[[Dump]]) .. " " .. self.string_Object
				end

				ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
					parent = self,
					overwrite_check = not not self.ChoGGi.UserSettings.ExamineAppendDump,
					text = str,
					update_func = function()
						if self.ChoGGi.UserSettings.ExamineTextType then
							return self:GetCleanText()
						else
							return ValueToLuaCode(self.obj_ref)
						end
					end,
					scrollto = scrolled_text,
					title = title,
					hint_ok = T{302535920000047--[["View Text/Object, and optionally dumps text to <color ChoGGi_yellow><path>logs\DumpedExamine.lua</color>."]],
						path = ConvertToOSPath("AppData/"),
					},
					custom_func = function(overwrite)
						self:DumpExamineText(str, name, overwrite and "w")
					end,
				}
			end,
		},
		{is_spacer = true},
		{name = T(302535920001239--[[Functions]]),
			hint = T(302535920001240--[[Show all functions of this object and parents/ancestors.]]),
			image = "CommonAssets/UI/Menu/gear.tga",
			clicked = function()
				if self.parents[1] or self.ancestors[1] then
					table.clear(self.menu_added)
					table.clear(self.menu_list_items)

					-- add examiner object with some spaces so it's at the top
					self:BuildFuncList(self.obj_ref.class, "  ")
					if self.parents[1] then
						self:ProcessList(self.parents, " " .. Translate(302535920000520--[[Parents]]) .. ": ")
					end
					if self.ancestors[1] then
						self:ProcessList(self.ancestors, Translate(302535920000525--[[Ancestors]]) .. ": ")
					end
					-- If Object hasn't been added, then add CObject (O has a few more funcs than CO)
					if not self.menu_added.Object and self.menu_added.CObject then
						self:BuildFuncList("CObject", self.menu_added.CObject)
					end
					ChoGGi_Funcs.Common.OpenInExamineDlg(self.menu_list_items, {
						has_params = true,
						parent = self,
						title = T(302535920001239--[[Functions]]) .. ": " .. self.name,
					})
				else
					local msg = T(302535920001705--[[No objects matching current filters.]])
					ChoGGi_Funcs.Common.MsgPopup(msg, T(302535920001706--[[Error]]))
					print(msg)
				end
			end,
		},
		{name = T(302535920001707--[[Edit]]) .. " " .. self.string_Object,
			hint = T(302535920000050--[[Opens object in Object Manipulator.]]),
			image = "CommonAssets/UI/Menu/AreaProperties.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenInObjectEditorDlg(self.obj_ref, self)
			end,
		},
		{name = T(302535920001708--[[Color Modifier]]),
			hint = T(302535920000693--[[Select/mouse over an object to change the colours
Use Shift- or Ctrl- for random colours/reset colours.]]),
			image = "CommonAssets/UI/Menu/toggle_dtm_slots.tga",
			clicked = function()
				ChoGGi_Funcs.Common.ChangeObjectColour(self.obj_ref)
			end,
		},
		{name = T(302535920001305--[[Find Within]]),
			hint = T{302535920001303--[["Search for text within <color ChoGGi_green><str></color>."]],
				str = self.name,
			},
			image = "CommonAssets/UI/Menu/EV_OpenFirst.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenInFindValueDlg(self.obj_ref, self)
			end,
		},
		{name = T(302535920000040--[[Exec Code]]),
			hint = T(302535920000052--[["Execute code (using console for output). o is whatever object is opened in examiner.
Which you can then mess around with some more in the console."]]),
			image = "CommonAssets/UI/Menu/AlignSel.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenInExecCodeDlg(self.obj_ref, self)
			end,
		},
		{is_spacer = true},
		{name = T(302535920001709--[[Modified property]]),
			hint = T(302535920001384--[[Get properties different from base/parent object?]]),
			image = "CommonAssets/UI/Menu/SelectByClass.tga",
			clicked = function()
				if self.obj_ref.IsKindOf and self.obj_ref:IsKindOf("PropertyObject") then
					ChoGGi_Funcs.Common.OpenInExamineDlg(GetModifiedProperties(self.obj_ref), {
						has_params = true,
						parent = self,
						title = T(302535920001709--[[Modified property]]) .. ": " .. self.name,
						override_title = true,
					})
				else
					self:InvalidMsgPopup()
				end
			end,
		},
		{name = T(302535920001389--[[All Properties]]),
			hint = T(302535920001390--[[Get all properties.]]),
			image = "CommonAssets/UI/Menu/CollectionsEditor.tga",
			clicked = function()
				-- give em some hints
				if self.obj_ref.IsKindOf and self.obj_ref:IsKindOf("PropertyObject") then
					local props = self.obj_ref:GetProperties()
					local props_list = {
						___readme = T(302535920001397--[["Not the actual properties (see ___properties for those).

Use obj:GetProperty(""NAME"") and obj:SetProperty(""NAME"", value)
You can access a default value with obj:GetDefaultPropertyValue(""NAME"")
"]]),
						___properties = self.obj_ref.properties,
					}
					for i = 1, #props do
						props_list[props[i].id] = self.obj_ref:GetProperty(props[i].id)
					end
					ChoGGi_Funcs.Common.OpenInExamineDlg(props_list, {
						has_params = true,
						parent = self,
						title = T(302535920001389--[[All Properties]]) .. ": " .. self.name,
					})
				else
					self:InvalidMsgPopup()
				end
			end,
		},
		{name = T(302535920001369--[[Ged Editor]]),
			hint = T(302535920000482--[["Shows some info about the object, and so on. Some buttons may make camera wonky (use Game>Camera>Reset)."]]),
			image = "CommonAssets/UI/Menu/UIDesigner.tga",
			clicked = function()
				if IsValid(self.obj_ref) then
					GedObjectEditor = false
					OpenGedGameObjectEditor{self.obj_ref}
				else
					self:InvalidMsgPopup()
				end
			end,
		},
		{name = T(302535920000067--[[Ged Inspect]]),
			hint = T(302535920001075--[[Open this object in the Ged inspector.]]),
			image = "CommonAssets/UI/Menu/EV_OpenFromInputBox.tga",
			clicked = function()
				Inspect(self.obj_ref)
			end,
		},
		{is_spacer = true},
		{name = T(302535920001321--[[UI Click To Examine]]),
			hint = T(302535920001322--[[Examine UI controls by clicking them.]]),
			image = "CommonAssets/UI/Menu/select_objects.tga",
			clicked = function()
				ChoGGi_Funcs.Common.TerminalRolloverMode(true, self)
			end,
		},
		{name = T(302535920000970--[[UI Flash]]),
			hint = T(302535920000972--[[Flash visibility of the UI object being examined.]]),
			clicked = function()
				self.ChoGGi.UserSettings.FlashExamineObject = not self.ChoGGi.UserSettings.FlashExamineObject
				ChoGGi_Funcs.Settings.WriteSettings()
			end,
			value = "ChoGGi.UserSettings.FlashExamineObject",
			class = "ChoGGi_XCheckButtonMenu",
		},
	}
	if testing then

		-- maybe i'll finish this one day :)
		table.insert(list, 8, {name = T(302535920001707--[[Edit]]) .. " "
				.. self.string_Object .. " " .. T(302535920001432--[[3D]]),
			hint = T(302535920001433--[[Fiddle with object angle/axis/pos and so forth.]]),
			image = "CommonAssets/UI/Menu/Axis.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenIn3DManipulatorDlg(self.obj_ref, self)
			end,
		})

		-- view raw text with tags visible
		table.insert(list, 5, {name = T(302535920000048--[[View]]) .. " Tags",
			image = "CommonAssets/UI/Menu/SelectByClass.tga",
			clicked = function()
				-- pure text string
				local str = self.idText:GetText()

				ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
					parent = self,
					overwrite_check = not self.ChoGGi.UserSettings.ExamineAppendDump,
					text = str,
					update_func = function()
						return self.idText:GetText()
					end,
					title = T(302535920000048--[[View]]) .. "/"
							.. T(302535920000004--[[Dump]]) .. " "
							.. T(302535920001704--[[Text]]),
					custom_func = function(overwrite)
						self:DumpExamineText(str, "DumpedExamine", overwrite and "w")
					end,
				}
			end,
		})

	end

	return list
end

local function CallMenu(self, popup_id, items, pt, button, ...)
	if pt then
		g_Classes.ChoGGi_XComboButton.OnMouseButtonDown(self, pt, button, ...)
	end
	if button == "L" then
		local dlg = self
		self = GetRootDialog(self)
		-- same colour as bg of icons :)
		self[items].Background = -9868951
		self[items].FocusedBackground = -9868951
		self[items].PressedBackground = -12500671
		self[items].TextStyle = "ChoGGi_CheckButtonMenuOpp"
		ChoGGi_Funcs.Common.PopupToggle(dlg, self[popup_id], self[items], "bottom")
	end
end

function ChoGGi_DlgExamine:idTools_OnMouseButtonDown(pt, button, ...)
	CallMenu(self, "idToolsMenu", "tools_menu_popup", pt, button, ...)
end
function ChoGGi_DlgExamine:idObjects_OnMouseButtonDown(pt, button, ...)
	CallMenu(self, "idObjectsMenu", "objects_menu_popup", pt, button, ...)
end

function ChoGGi_DlgExamine:idParents_OnMouseButtonDown(pt, button, ...)
	CallMenu(self, "idParentsMenu", "parents_menu_popup", pt, button, ...)
end

function ChoGGi_DlgExamine:idAttaches_OnMouseButtonDown(pt, button, ...)
	CallMenu(self, "idAttachesMenu", "attaches_menu_popup", pt, button, ...)
end

function ChoGGi_DlgExamine:idSearch_OnMouseButtonDown(pt, button, ...)
	g_Classes.ChoGGi_XButton.OnMouseButtonDown(self, pt, button, ...)
	self = GetRootDialog(self)
	if button == "L" then
		self:FindNext()
	elseif button == "R" then
		self:FindNext(nil, true)
	else
		self.idScrollArea:ScrollTo(0, 0)
	end
end

function ChoGGi_DlgExamine:idSearchText_OnKbdKeyDown(vk, ...)
	local old_self = self
	self = GetRootDialog(self)

	local c = const
	if vk == c.vkEnter then
		if IsControlPressed() then
			self:FindNext(nil, true)
		else
			self:FindNext()
		end
		return "break"

	elseif vk == c.vkUp then
		self.idScrollArea:ScrollTo(nil, 0)
		return "break"

	elseif vk == c.vkDown then
		local v = self.idScrollV
		if v:IsVisible() then
			self.idScrollArea:ScrollTo(nil, v.Max - (v.FullPageAtEnd and v.PageSize or 0))
		end
		return "break"

	elseif vk == c.vkRight then
		local h = self.idScrollH
		if h:IsVisible() then
			self.idScrollArea:ScrollTo(h.Max - (h.FullPageAtEnd and h.PageSize or 0))
		end
		-- break doesn't work for left/right

	elseif vk == c.vkLeft then
		self.idScrollArea:ScrollTo(0)
		-- break doesn't work for left/right

	elseif vk == c.vkV then
		if IsControlPressed() then
			CreateRealTimeThread(function()
				WaitMsg("OnRender")
				self:FindNext()
			end)
		end

	elseif vk == c.vkEsc then
		self.idCloseX:OnPress()
		return "break"

	end

	return g_Classes.ChoGGi_XTextInput.OnKbdKeyDown(old_self, vk, ...)
end

-- adds class name then list of functions below
function ChoGGi_DlgExamine:BuildFuncList(obj_name, prefix)
	if not prefix then
		prefix = ""
	end
	local class = _G[obj_name]

	if class then
		local skip = true
		for key, value in pairs(class) do
			if type(value) == "function" and type(key) == "string" then
				self.menu_list_items[prefix .. obj_name .. "." .. key .. ": "] = value
				skip = false
			end
		end
		if not skip then
			self.menu_list_items[prefix .. obj_name] = "\n\n\n"
		end
	end
end

function ChoGGi_DlgExamine:ProcessList(list, prefix)
	for i = 1, #list do
		local item = list[i]
		if not self.menu_added[item] then
			-- CObject and Object are pretty much the same (Object has a couple more funcs)
			if item == "CObject" then
				-- keep it for later (for the rare objects that use CObject, but not Object)
				self.menu_added[item] = prefix
			else
				self.menu_added[item] = true
				self:BuildFuncList(item, prefix)
			end
		end
	end
end

function ChoGGi_DlgExamine:InvalidMsgPopup(msg, title)
	ChoGGi_Funcs.Common.MsgPopup(
		msg or T(302535920001526--[[Not a valid object]]),
		title or T(302535920000069--[[Examine]])
	)
end

--~ function ChoGGi_DlgExamine:CleanTextForView(str)
--~ 	-- remove html tags (any </*> closing tags, <left>, <color *>, <h *>, and * added by the context menus)
-- merge gsubs if I ever use this for something else
--~ 	return str:gsub("</[%s%a%d]*>", ""):gsub("<left>", ""):gsub("<color [%s%a%d]*>", ""):gsub("<h [%s%a%d]*>", ""):gsub("%* '", "'")
--~ end
-- scrolled_text is modified from a boolean to the scrolled text and sent back
-- skip_ast = i added an * to use for the context menu marker (defaults to true)
function ChoGGi_DlgExamine:GetCleanText(scrolled_text, skip_ast)
	if skip_ast ~= false then
		skip_ast = true
	end
	local cache = self.idText.draw_cache or {}

	-- get the cache number of scrolled text
	if scrolled_text then
		-- PendingOffsetY == scrolled number in cached text table
		if cache[self.idScrollArea.PendingOffsetY or 0] then
			scrolled_text = self.idScrollArea.PendingOffsetY or 0
		else
			-- If it's nil we're between lines
			-- we send "" or it'll try to use the search text
			self:FindNext("")
			-- no need to test if it's in the cache
			scrolled_text = self.idScrollArea.PendingOffsetY or 0
		end
	end

	-- first get a list of cached text (unordered) and merge the text chunks into one line
	local cache_temp = {}
	local c = 0

	local text_temp = {}
	for line, list in pairs(cache) do
		-- we stick all the text chunks into a table to concat after
		table.iclear(text_temp)
		for i = 1, #list do
			local text = list[i].text
			if i == 1 and skip_ast and text == "* " then
				text_temp[i] = ""
			else
				text_temp[i] = text or ""
			end
		end

		c = c + 1
		cache_temp[c] = {
			line = line,
			text = table.concat(text_temp),
		}
	end

	-- sort by line group
	table.sort(cache_temp, function(a, b)
		return a.line < b.line
	end)

	-- change line/text to just line, and grab scroll text if it's around
	for i = 1, #cache_temp do
		local item = cache_temp[i]
		if item.line == scrolled_text then
			scrolled_text = item.text
		end
		cache_temp[i] = item.text
	end

	return table.concat(cache_temp, "\n"), scrolled_text
end

function ChoGGi_DlgExamine:FindNext(text, previous)
	text = text or self.idSearchText:GetText()
	local current_y = self.idScrollArea.OffsetY
	local min_match, closest_match = false, false

	local text_table = {}
	local cache = self.idText.draw_cache or {}
	-- see about getting previous working better
	for y, list_draw_info in pairs(cache) do
		table.iclear(text_table)
		for i = 1, #list_draw_info do
			text_table[i] = list_draw_info[i].text or ""
		end

		if table.concat(text_table):find_lower(text) or text == "" then
			if not min_match or y < min_match then
				min_match = y
			end

			if previous then
				if y < current_y and (not closest_match or y > closest_match) then
					closest_match = y
				end
			else
				if y > current_y and (not closest_match or y < closest_match) then
					closest_match = y
				end
			end
		end
	end

	local match = closest_match or min_match
	if match then
		self.idScrollArea:ScrollTo(nil, match)
	end
end

function ChoGGi_DlgExamine:FlashWindow()
	if not self.ChoGGi.UserSettings.FlashExamineObject
		-- doesn't lead to good stuff
		or not self.obj_ref.desktop
		-- skip any not XWindows
		or not IsKindOf(self.obj_ref, "XWindow")
	then
		return
	end


	-- white rectangle
--~ 	if self.flash_rect then
		XFlashWindow(self.obj_ref)
		return
--~ 	end

--~ 	-- always kill off old thread first
--~ 	DeleteThread(self.flashing_thread)

--~ 	-- don't want to end up with something invis when it shouldn't be
--~ 	if self.orig_vis_flash then
--~ 		self.obj_ref:SetVisible(self.orig_vis_flash)
--~ 	else
--~ 		self.orig_vis_flash = self.obj_ref:GetVisible()
--~ 	end

--~ 	self.flashing_thread = CreateRealTimeThread(function()

--~ 		local vis
--~ 		for _ = 1, 5 do
--~ 			if not IsValidXWin(self.obj_ref) then
--~ 				break
--~ 			end
--~ 			self.obj_ref:SetVisible(vis)
--~ 			Sleep(125)
--~ 			vis = not vis
--~ 		end

--~ 		if IsValidXWin(self.obj_ref) then
--~ 			self.obj_ref:SetVisible(self.orig_vis_flash)
--~ 		end

--~ 	end)
end

function ChoGGi_DlgExamine:ShowHexShapeList()
	local obj = self.obj_ref
	if not IsValidEntity(self.obj_entity) then
		return self:InvalidMsgPopup(nil, self.string_Entity)
	end

	ChoGGi_Funcs.Common.ObjHexShape_Clear(obj)

	self.hex_shape_tables = self.hex_shape_tables or {
		"HexBuildShapes",
		"HexBuildShapesInversed",
		"HexCombinedShapes",
		"HexInteriorShapes",
		"HexOutlineShapes",
		"HexPeripheralShapes",
	}
	self.hex_shape_funcs = self.hex_shape_funcs or {
		"GetExtractionShape",
		"GetExtractionShapeExtended",
		"GetShapePoints",
		"GetRotatedShapePoints",
	}

	local item_list = {
		{
			text = " " .. T(302535920001688--[[Clear]]),
			value = "Clear",
		},
		{
			text = "HexNeighbours (" .. T(302535920001570--[[Fallback]]) .. ")",
			value = HexNeighbours,
		},
		{
			text = "HexSurroundingsCheckShape (" .. T(302535920001570--[[Fallback]]) .. ")",
			value = HexSurroundingsCheckShape,
		},
		{
			text = "FallbackOutline (" .. T(302535920001570--[[Fallback]]) .. ")",
			value = FallbackOutline,
		},
	}
	local c = #item_list

	if type(obj.splat_shape) == "table" and #obj.splat_shape > 0 then
		c = c + 1
		item_list[c] = {
			text = "splat_shape",
			value = obj.splat_shape,
		}
	end
	if type(obj.periphery_shape) == "table" and #obj.periphery_shape > 0 then
		c = c + 1
		item_list[c] = {
			text = "periphery_shape",
			value = obj.periphery_shape,
		}
	end

	for i = 1, #self.hex_shape_funcs do
		local shape_list = self.hex_shape_funcs[i]
		local shape = obj[shape_list] and obj[shape_list](obj)

		if shape and #shape > 0 then
			c = c + 1
			item_list[c] = {
				text = shape_list,
				value = shape,
			}
		end
	end

	for i = 1, #self.hex_shape_tables do
		local shape_list = self.hex_shape_tables[i]
		local shape = g_env[shape_list][self.obj_entity]
		if shape and #shape > 0 then
			c = c + 1
			item_list[c] = {
				text = shape_list,
				value = shape,
			}
		end
	end

	local surfs = ChoGGi_Funcs.Common.RetHexSurfaces(self.obj_entity, true, true)
	for i = 1, #surfs do
		local s = surfs[i]
		c = c + 1
		item_list[c] = {
			text = "GetSurfaceHexShapes(), " .. s.name .. ", mask: " .. s.id
				.. " (" .. s.mask .. ") state:" .. s.state,
			value = s.shape,
		}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]
		if choice.value == "Clear" then
			ChoGGi_Funcs.Common.ObjHexShape_Clear(obj)
		elseif type(choice.value) == "table" then
			ChoGGi_Funcs.Common.ObjHexShape_Toggle(obj, {
				shape = choice.value,
				skip_return = true,
				depth_test = choice.check1,
				hex_pos = choice.check2,
				skip_clear = choice.check3,
			})
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001522--[[Hex Shape Toggle]]) .. ": " .. self.name,
		skip_sort = true,
		custom_type = 7,
		checkboxes = {
			{
				title = T(302535920001553--[[Depth Test]]),
				hint = T(302535920001554--[[If enabled lines will hide behind occluding walls (not glass).]]),
				checked = false,
			},
			{
				title = T(302535920000461--[[Position]]),
				hint = T(302535920001076--[[Shows the hex position of the spot: (-1, 5).]]),
				checked = true,
			},
			{
				title = T(302535920001560--[[Skip Clear]]),
				hint = T(302535920001561--[[Info objects will stay instead of being removed when activating a different option.]]),
				checked = false,
			},
		},
	}
end

function ChoGGi_DlgExamine:BuildBBoxListItem(item_list, obj, text)
	local bbox
	if IsBox(obj) then
		bbox = obj
	else
		bbox = obj[text]
		if bbox then
			bbox = bbox(obj)
		end
	end

	-- make sure it's on the map, and isn't 0 sized
	if bbox and ChoGGi_Funcs.Common.IsPosInMap(bbox:Center())
			and tostring(bbox:max()) ~= tostring(bbox:min()) then
		item_list[#item_list+1] = {
			text = text,
			bbox = bbox,
		}
	end
end

function ChoGGi_DlgExamine:ShowBBoxList()
	local obj = self.obj_ref
	if not IsValidEntity(self.obj_entity) then
		return self:InvalidMsgPopup(nil, self.string_Entity)
	end

-- might be useful?
--~ ToBBox(pos, prefab.size, angle)

	ChoGGi_Funcs.Common.BBoxLines_Clear(obj)

	local item_list = {
		{text = " " .. T(302535920001688--[[Clear]]), value = "Clear"},
		-- relative
--~ 		{text = "GetEntityBBox", bbox = s:GetEntityBBox()},
--~ 		{text = "GetEntitySurfacesBBox", bbox = HexStoreToWorld(obj:GetEntitySurfacesBBox())},
		-- needs entity string as 2 arg
--~ 		{text = "GetEntityBoundingBox", value = "GetEntityBoundingBox", args = "use_entity"},
	}

	self:BuildBBoxListItem(item_list, obj, "GetBBox")
	self:BuildBBoxListItem(item_list, obj, "GetObjectBBox")
	self:BuildBBoxListItem(item_list, obj, "GetSurfacesBBox")
	self:BuildBBoxListItem(item_list, ObjectHierarchyBBox(obj), "ObjectHierarchyBBox")
	self:BuildBBoxListItem(item_list, ObjectHierarchyBBox(obj, const.efCollision), "ObjectHierarchyBBox + efCollision")

	-- add to examine bbox toggle
	local landscape = Landscapes[obj.mark]
	if landscape and IsBox(landscape.bbox) then
		item_list[#item_list+1] = {
			text = T(302535920001710--[[Landscape]]) .. " bbox",
			bbox = HexStoreToWorld(landscape.bbox),
		}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		if choice.value == "Clear" then
			ChoGGi_Funcs.Common.BBoxLines_Clear(obj)
		else
			ChoGGi_Funcs.Common.BBoxLines_Toggle(obj, {
				bbox = choice.bbox,
				args = choice.args,
				skip_return = true,
				depth_test = choice.check1,
			})
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001472--[[BBox Toggle]]) .. ": " .. self.name,
		hint = T(302535920000264--[[Defaults to obj:GetObjectBBox() if it can't find a func.]]),
		skip_sort = true,
		custom_type = 7,
		checkboxes = {
			{
				title = T(302535920001553--[[Depth Test]]),
				hint = T(302535920001554--[[If enabled lines will hide behind occluding walls (not glass).]]),
				checked = false,
			},
		},
	}
end

function ChoGGi_DlgExamine:ShowEntitySpotsList()
	local obj = self.obj_ref

	ChoGGi_Funcs.Common.EntitySpots_Clear(obj)

	if not IsValidEntity(self.obj_entity) then
		return self:InvalidMsgPopup(nil, self.string_Entity)
	end

	local item_list = {
		{text = " " .. T(302535920001691--[[All]]), value = "All"},
		{text = " " .. T(302535920001688--[[Clear]]), value = "Clear"},
	}
	local c = #item_list

	local dupes = {}
	local id_start, id_end = obj:GetAllSpots(obj:GetState())
	if not id_end then
		return self:InvalidMsgPopup(nil, self.string_Entity)
	end

	local GetSpotNameByType = GetSpotNameByType
	local str_spotid = T(302535920001573--[[Spot Id]])

	for i = id_start, id_end do
		local spot_name = GetSpotNameByType(obj:GetSpotsType(i))
		local spot_annot = obj:GetSpotAnnotation(i) or ""

		-- remove waypoints from chain points so they count as one
		if spot_annot:find("chain") then
			spot_annot = spot_annot:gsub(",%s?waypoint=%d", "")
		end

		local name = spot_name .. (spot_annot ~= "" and ";" .. spot_annot or "")
		if not dupes[name] then
			dupes[name] = true
			c = c + 1
			item_list[c] = {
				text = name .. " (" .. str_spotid .. ": " .. i .. ")",
				name = spot_name,
				value = spot_annot,
				hint = spot_annot,
			}
		end
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		if choice.value == "All" then
			ChoGGi_Funcs.Common.EntitySpots_Toggle(obj, {
				skip_return = true,
				depth_test = choice.check1,
				show_pos = choice.check2,
				skip_clear = choice.check3,
			})
		elseif choice.value == "Clear" then
			ChoGGi_Funcs.Common.EntitySpots_Clear(obj)
		else
			ChoGGi_Funcs.Common.EntitySpots_Toggle(obj, {
				spot_type = choice.name,
				annotation = choice.value,
				skip_return = true,
				depth_test = choice.check1,
				show_pos = choice.check2,
				skip_clear = choice.check3,
			})
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000449--[[Entity Spots Toggle]]) .. ": " .. self.name,
		hint = T(302535920000450--[[Toggle showing attachment spots on selected object.]]),
		custom_type = 7,
		skip_icons = true,
		checkboxes = {
			{
				title = T(302535920001553--[[Depth Test]]),
				hint = T(302535920001554--[[If enabled lines will hide behind occluding walls (not glass).]]),
				checked = false,
			},
			{
				title = T(302535920000461--[[Position]]),
				hint = T(302535920000463--[[Add spot offset pos from Origin.]]),
				checked = false,
			},
			{
				title = T(302535920001560--[[Skip Clear]]),
				hint = T(302535920001561--[[Info objects will stay instead of being removed when activating a different option.]]),
				checked = false,
			},
		},
	}
end

function ChoGGi_DlgExamine:ShowSurfacesList()
	local obj = self.obj_ref

	ChoGGi_Funcs.Common.SurfaceLines_Clear(obj)

	if not IsValidEntity(self.obj_entity) then
		return self:InvalidMsgPopup(nil, self.string_Entity)
	end

	local item_list = {
		{text = " " .. T(302535920001688--[[Clear]]), value = "Clear"},
		{
			text = "0: " .. T(302535920000968--[[Collisions]]),
			value = 0,
			hint = "Relative Surface index: 0",
		},
	}
	local c = #item_list

	local GetRelativeSurfaces = GetRelativeSurfaces
	local str_hexshape = ": " .. T(302535920000422--[[Hex Shape]])
	local str_selectionarea = ": " .. T(302535920001562--[[Selection Area]])

	-- yep, no idea what GetRelativeSurfaces uses, so 1024 it'll be (from what i've seen nothing above 10, but...)
	for i = 1, 1024 do
		local surfs = GetRelativeSurfaces(obj, i)
		if surfs[1] then
			c = c + 1
			item_list[c] = {
				text = i .. "",
				value = i,
				surfs = surfs,
				hint = "Relative Surface index: " .. i,
			}
			if i == 5 then
				item_list[c].text = item_list[c].text .. str_hexshape
			elseif i == 7 then
				item_list[c].text = item_list[c].text .. str_selectionarea
			end
		end
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		if choice.value == "Clear" then
			ChoGGi_Funcs.Common.SurfaceLines_Clear(obj)
		else
			ChoGGi_Funcs.Common.SurfaceLines_Toggle(obj, {
				surface_mask = choice.value,
				skip_return = true,
				surfs = choice.surfs,
				depth_test = choice.check1,
				skip_clear = choice.check2,
			})
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920001551--[[Surfaces Toggle]]) .. ": " .. self.name,
		hint = T(302535920001552--[[Show a list of surfaces and draw lines over them (GetRelativeSurfaces).]]),
		custom_type = 7,
		checkboxes = {
			{
				title = T(302535920001553--[[Depth Test]]),
				hint = T(302535920001554--[[If enabled lines will hide behind occluding walls (not glass).]]),
				checked = false,
			},
			{
				title = T(302535920001560--[[Skip Clear]]),
				hint = T(302535920001561--[[Info objects will stay instead of being removed when activating a different option.]]),
				checked = false,
			},
		},
	}
end
--
local function Show_ConvertValueToInfo(self, button, obj)
	-- not ingame = no sense in using ShowObj
	if button == "L" and self.city_object and (IsValid(obj) or IsPoint(obj)) then
		self:AddSphere(obj)
	else
		ChoGGi_Funcs.Common.OpenInExamineDlg(obj, {
			has_params = true,
			parent = self,
		})
	end
end

local function Examine_ConvertValueToInfo(self, button, obj, _, _, _, link)
	-- not ingame = no sense in using ShowObj
	if button == "L" then
		if self.exec_tables then
			self.exec_tables(obj, self)
			return
		end

		local title = RetName(obj)
		-- use key name if there's no proper RetName
		if title:find("^[function:|thread:|table:|userdata:]") then
			-- needed for index tables
			title = tostring(self.onclick_objs[link-1])
		end
		ChoGGi_Funcs.Common.OpenInExamineDlg(obj, {
			has_params = true,
			parent = self,
			title = title,
		})
	else
		self:AddSphere(obj)
	end
end

function ChoGGi_DlgExamine:ShowExecCodeWithCode(code)
	-- open exec code and paste "o.obj_name = value"
	self:idToggleExecCode_OnChange(true)
	self.idExecCode:SetText(code)
	-- set focus and cursor to end of text
	self.idExecCode:SetFocus()
	self.idExecCode:SetCursor(1, #self.idExecCode:GetText())
end

function ChoGGi_DlgExamine:OpenListMenu(_, obj, _, hyperlink_box)
	-- Id for PopupToggle
	self.opened_list_menu_id = self.opened_list_menu_id or ChoGGi_Funcs.Common.Random()

	local obj_name = RetName(obj)
	-- I need to know if it's a number or string and so on
	local obj_key, obj_type = ChoGGi_Funcs.Common.RetProperType(obj)

	local obj_value = self.obj_ref[obj_key]
	local obj_value_str = tostring(obj_value)
	local obj_value_type = type(obj_value)

	local list = {
		{name = obj_name,
			hint = T(302535920001538--[[Close this menu.]]),
			image = "CommonAssets/UI/Menu/default.tga",
			clicked = function()
				local popup = terminal.desktop[self.opened_list_menu_id]
				if popup then
					popup:Close()
				end
			end,
		},
		{is_spacer = true},
		{name = T(302535920001711--[[Delete Item]]),
			hint = T{302535920001536--[["Remove the ""<key_name>"" key from <table_name>."]],
				key_name = obj_name,
				table_name = self.name,
			},
			image = "CommonAssets/UI/Menu/DeleteArea.tga",
			clicked = function()
				local str1, str2 = "o[\"", "\"] = nil"
				if obj_type == "number" then
					str1, str2 = "table.remove(o, ", ")"
				end
				self:ShowExecCodeWithCode(str1 .. obj_name .. str2)
			end,
		},
		{name = T(302535920001535--[[Set Value]]),
			hint = T{302535920001539--[["Change the value of <color ChoGGi_green><obj_name></color>."]],
				obj_name = obj_name,
			},
			image = "CommonAssets/UI/Menu/SelectByClassName.tga",
			clicked = function()
				-- numbers don't need ""
				if obj_type == "number" then
					obj_name = "o[" .. obj_name .. "] = "
				else
					obj_name = "o[\"" .. obj_name .. "\"] = "
				end

				if obj_value_type == "string" then
					-- add quotes to strings
					obj_value_str = "\"" .. obj_value_str .. "\""
				elseif obj_value_type == "userdata" then
					if IsPoint(obj_value) then
						-- add point to points
						obj_value_str = "point" .. obj_value_str
					elseif IsBox(obj_value) then
						-- box to boxes, as well as subbing )-( to ,
						obj_value_str = "box" .. obj_value_str:gsub("%)%-%(", ", ")
					end
				end

				self:ShowExecCodeWithCode(obj_name .. obj_value_str)
			end,
		},
	}
	if type(obj_value) == "table" then
		list[#list+1] = {
			name = T(302535920001741--[[Clear Table]]),
			hint = T(302535920001742--[[Remove all entries from this table.]]),
			image = "CommonAssets/UI/Menu/new_city.tga",
			clicked = function()
				local str1, str2 = "table.clear(o[\"", "\"])"
				if tonumber(obj_name) then
					str1, str2 = "table.clear(o[", "])"
				end
				self:ShowExecCodeWithCode(str1 .. obj_name .. str2)
			end,
		}
	-- ValueToLuaCode doesn't work on threads
	elseif type(obj_value) ~= "thread" then
		list[#list+1] = {
			name = T(302535920000664--[[Clipboard]]),
			hint = T(302535920001566--[[Copy ValueToLuaCode(value) to clipboard.]]),
			image = "CommonAssets/UI/Menu/Mirror.tga",
			clicked = function()
				CopyToClipboard(obj_name .. " = " .. ValueToLuaCode(obj_value))
			end,
		}
	end

	local c_orig = #list
	local c = c_orig

	-- If it's an image path then we add an image viewer
	if ChoGGi_Funcs.Common.ImageExts()[obj_value_str:sub(-3):lower()] then
		c = c + 1
		list[c] = {name = T(302535920001469--[[Image Viewer]]),
			hint = T(302535920001470--[["Open a dialog with a list of images from object (.dds, .tga, .png)."]]),
			image = "CommonAssets/UI/Menu/light_model.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenInImageViewerDlg(obj_value_str, self)
			end,
		}
	end

	-- add a mat props list
	if obj_value_str:sub(-3):lower() == "mtl" then
		c = c + 1
		list[c] = {name = T(302535920001458--[[Material Properties]]),
			hint = T(302535920001459--[[Shows list of material settings/.dds files for use with .mtl files.]]),
			image = "CommonAssets/UI/Menu/AreaProperties.tga",
			clicked = function()
				ChoGGi_Funcs.Common.OpenInExamineDlg(GetMaterialProperties(obj_value_str), {
					has_params = true,
					parent = self,
					title = T(302535920001458--[[Material Properties]]),
				})
			end,
		}
	end

	if obj_value_type == "number" then
		c = c + 1
		list[c] = {name = T(302535920001564--[[Double Number]]),
			hint = T{302535920001563--[["Set amount to <color ChoGGi_green><new_amt></color>."]],
				new_amt = obj_value * 2,
			},
			image = "CommonAssets/UI/Menu/change_height_up.tga",
			clicked = function()
				self:ShowExecCodeWithCode("o." .. obj_name .. " = " .. (obj_value * 2))
			end,
		}
		c = c + 1
		list[c] = {name = T(302535920001565--[[Halve Number]]),
			hint = T{302535920001563--[["Set amount to <color ChoGGi_green><new_amt></color>."]],
				new_amt = obj_value / 2,
			},
			image = "CommonAssets/UI/Menu/change_height_down.tga",
			clicked = function()
				self:ShowExecCodeWithCode("o." .. obj_name .. " = " .. (obj_value / 2))
			end,
		}

	elseif obj_value_type == "boolean" then
		c = c + 1
		list[c] = {name = T(302535920001069--[[Toggle Boolean]]),
			hint = T(302535920001567--[[false to true and true to false.]]),
			image = "CommonAssets/UI/Menu/ToggleSelectionOcclusion.tga",
			clicked = function()
				self:ShowExecCodeWithCode("o." .. obj_name .. " = " .. tostring(not obj_value))
			end,
		}
		c = c + 1
		list[c] = {name = T(302535920001568--[[Boolean To Table]]),
			hint = T(302535920001569--[[Set the value to a new table: {}.]]),
			image = "CommonAssets/UI/Menu/SelectionFilter.tga",
			clicked = function()
				self:ShowExecCodeWithCode("o." .. obj_name .. " = {}")
			end,
		}

	elseif obj_value_type == "function" then
		c = c + 1
		list[c] = {is_spacer = true}

		c = c + 1
		list[c] = {name = T(302535920000625--[[Exec Func]]),
			hint = T(302535920000627--[[Show func name in exec code line.]]),
			image = "CommonAssets/UI/Menu/SelectByClassName.tga",
			clicked = function()
				-- no "" for numbers
				local quote = obj_type == "number" and "" or "\""
				-- can we ref it with .name (i'm ignoring _123 since i'm lazy)
				local is_dot = tostring(obj_name):find("[%a_]")
				-- If it's a cls obj then make sure to use the obj
				local is_class = self.obj_ref.class and g_Classes[self.obj_ref.class] or self.obj_type == "userdata" or self.obj_type == "string"

				local code
				if is_class then
					if is_dot then
						code = "o:" .. obj_name .. "()"
					else
						code = "o[" .. quote .. obj_name .. quote .. "](o)"
					end
				else
					if is_dot then
						code = "o." .. obj_name .. "()"
					else
						code = "o[" .. quote .. obj_name .. quote .. "]()"
					end
				end
				self:ShowExecCodeWithCode(code)
			end,
		}
		c = c + 1
		list[c] = {name = T(302535920000110--[[Function Results]]),
			hint = T(302535920000168--[[Continually call this function while showing results in an examine dialog.]]),
			image = "CommonAssets/UI/Menu/EV_OpenFromInputBox.tga",
			clicked = function()
				-- If it's a class object then add self ref
				if self.obj_ref.class and g_Classes[self.obj_ref.class] or self.obj_type == "userdata" or self.obj_type == "string" then
					self:ShowExecCodeWithCode("MonitorFunc(o[" .. obj_name .. "], o)")
				else
					self:ShowExecCodeWithCode("MonitorFunc(o[" .. obj_name .. "])")
				end
			end,
		}
		if self.obj_type ~= "userdata" and self.obj_type ~= "string" then
			c = c + 1
			list[c] = {name = T(302535920000524--[[Print Func]]),
				hint = T(302535920000906--[[Print func name when this func is called.]]),
				image = "CommonAssets/UI/Menu/Action.tga",
				clicked = function()
					ChoGGi_Funcs.Common.PrintToFunc_Add(
						obj_value, -- func to print
						obj_key, -- func name
						self.obj_ref, -- parent
						self.name .. "." .. obj_key -- printed name
					)
				end,
			}
			c = c + 1
			list[c] = {name = T(302535920000745--[[Print Func Params]]),
				hint = T(302535920000906) .. "\n\n" .. T(302535920000984--[[Also prints params (if this func is attached to a class obj then the first arg will only return the name).]]),
				image = "CommonAssets/UI/Menu/ApplyWaterMarkers.tga",
				clicked = function()
					ChoGGi_Funcs.Common.PrintToFunc_Add(obj_value, obj_key, self.obj_ref, self.name .. "." .. obj_key, true)
				end,
			}
			c = c + 1
			list[c] = {name = T(302535920000900--[[Print Reset]]),
				hint = T(302535920001067--[[Remove print from func.]]),
				image = "CommonAssets/UI/Menu/reload.tga",
				clicked = function()
					ChoGGi_Funcs.Common.PrintToFunc_Remove(obj_key, self.obj_ref)
				end,
			}
		end
	end

	if c ~= c_orig and not list[6].is_spacer then
		table.insert(list, 6, {is_spacer = true})
	end

	-- style it like the other examine menus
	list.Background = -9868951
	list.FocusedBackground = -9868951
	list.PressedBackground = -12500671
	list.TextStyle = "ChoGGi_CheckButtonMenuOpp"
	-- make a fake anchor for PopupToggle to use (
	self.list_menu_table = self.list_menu_table or {}
	self.list_menu_table.ChoGGi_self = self
	self.list_menu_table.box = hyperlink_box
	ChoGGi_Funcs.Common.PopupToggle(
		self.list_menu_table, self.opened_list_menu_id, list, "left"
	)
end

-- the secondary main "one"
function ChoGGi_DlgExamine:ConvertValueToInfo(obj, is_indexed)
	local obj_type = type(obj)

	if obj_type == "string" then
		if obj == "" then
			-- tags off doesn't like ""
			return "''"
		else
			return self.string_cvti_ex_colour_str .. obj .. "<tags on></color>'"
		end
	end
	--
	if obj_type == "number" then
		return self.string_cvti_ex_colour_num .. obj .. "</color>"
	end
	--
	if obj_type == "boolean" then
		if obj then
			return self.string_cvti_ex_colour_bool .. tostring(obj) .. "</color>"
		else
			return self.string_cvti_ex_colour_boolfalse .. tostring(obj) .. "</color>"
		end
	end
	--
	if obj_type == "table" then
		-- acts weird with main menu movie xlayer, so we check for GetVisualPos
		if IsValid(obj) and obj.GetVisualPos then
			return self:HyperLink(obj, Examine_ConvertValueToInfo)
				.. RetName(obj) .. self.hyperlink_end
				.. self:HyperLink(obj, function()
					SelectObj(obj)
				end) .. " @ " .. self.hyperlink_end
				.. self:ConvertValueToInfo(obj:GetVisualPos())
				.. " <color ChoGGi_palegreen>" .. (RetMapType(obj) or "nil") .. "</color>"
		else
			local len = #obj
			local obj_metatable = getmetatable(obj)

			-- If it's an objlist then we return a list of the objects
			if obj_metatable and IsObjlist(obj_metatable) then
				local res = {
					self:HyperLink(obj, Examine_ConvertValueToInfo),
					"objlist",
					self.hyperlink_end,
					"{",
				}
				local c = #res
				for i = 1, Min(len, 3) do
					c = c + 1
					res[c] = i
					c = c + 1
					res[c] = "="
					c = c + 1
					res[c] = self:ConvertValueToInfo(obj[i])
					c = c + 1
					res[c] = ", "
				end
				if len > 3 then
					c = c + 1
					res[c] = "..."
				end
				c = c + 1
				res[c] = "}"
				-- remove last ,
				return table.concat(res):gsub(", }", "}")

			elseif rawget(obj, "ChoGGi_AddHyperLink") and obj.ChoGGi_AddHyperLink then
				if obj.colour then
					return "<color " .. obj.colour .. ">" .. (obj.name or "") .. "</color> "
						.. self:HyperLink(obj, obj.func, obj.hint) .. "@" .. self.hyperlink_end
				else
					return (obj.name or "") .. "</color> "
						.. self:HyperLink(obj, obj.func, obj.hint) .. "@" .. self.hyperlink_end
				end

			else

				-- regular table
				local is_next = type(next(obj)) ~= "nil"

				local table_data
				-- not sure how to check if it's an index non-ass table
				if len > 0 and is_next then
					-- next works for both
					table_data = len .. self.string_cvti_slash_data
				elseif is_next then
					-- ass based
					table_data = self.string_cvti_data
				else
					-- blank table
					table_data = len
				end
				--
				local name_orig = RetName(obj)
				local name = Translate(name_orig):gsub("[<>/]", "")
				--
				name = "<tags off>" .. name .. "<tags on>"

				if obj.class and name_orig ~= obj.class then
					if is_indexed then
						name = obj.class .. " (len: " .. table_data .. ") " .. name
					else
						name = obj.class .. " (len: " .. table_data .. ")"
					end
				else
					name = name .. " (len: " .. table_data .. ")"
				end

				return self:HyperLink(obj, Examine_ConvertValueToInfo) .. name .. self.hyperlink_end
			end
		end
	end
	--
	if obj_type == "userdata" then

		if IsPoint(obj) then
			-- InvalidPos()
			if obj == InvalidPos then
				-- show off map for tables and the point for points
				if self.obj_type == "userdata" then
					return self:HyperLink(obj, Show_ConvertValueToInfo)
						.. "point" .. tostring(InvalidPos) .. self.hyperlink_end
				else
					return self:HyperLink(obj, Show_ConvertValueToInfo)
						.. Translate(302535920000066--[[<color 203 120 30>Off-Map</color>]])
						.. self.hyperlink_end
				end
			else
				return self:HyperLink(obj, Show_ConvertValueToInfo)
					.. "point" .. tostring(obj) .. self.hyperlink_end
			end

		else

			-- show translated text if possible and return a clickable link
			local trans_str
			if IsT(obj) then
				trans_str = Translate(obj)
				if trans_str == missing_text then
					trans_str = tostring(obj)
				end
			else
				trans_str = tostring(obj)
			end

			local meta = getmetatable(obj)

			-- tags off doesn't like ""
			if trans_str == "" then
				trans_str = trans_str
					.. self:HyperLink(obj, Examine_ConvertValueToInfo) .. " *"
			else
				trans_str = "<tags off>" .. trans_str .. "<tags on>"
					.. self:HyperLink(obj, Examine_ConvertValueToInfo) .. " *"
			end

			-- If meta name then add it
			if meta and meta.__name then
				-- add TaskRequest res name
				if obj.GetResource then
					trans_str = trans_str .. "(" .. obj:GetResource() .. ", " .. meta.__name .. ")"
				else
					trans_str = trans_str .. "(" .. meta.__name .. ")"
				end
			else
				trans_str = trans_str .. tostring(obj)
			end

			return trans_str .. self.hyperlink_end
		end
	end
	--
	if obj_type == "function" then
		return self:HyperLink(obj, Examine_ConvertValueToInfo)
			.. RetName(obj) .. self.hyperlink_end
	end
	--
	if obj_type == "thread" then
		return self:HyperLink(obj, Examine_ConvertValueToInfo)
			.. tostring(obj) .. self.hyperlink_end
	end
	--
	if obj_type == "nil" then
		return self.string_cvti_ex_colour_nil
	end

	-- just in case
	return tostring(obj)
end

-- ------------------------------------------------------------------------------------------------------------------
function ChoGGi_DlgExamine:RetDebugUpValue(obj, list, c, nups)
	for i = 1, nups do
		local name, value = debug.getupvalue(obj, i)
		if name then
			c = c + 1
			name = name ~= "" and name or Translate(302535920000723--[[Lua]])

			list[c] = "getupvalue(" .. i .. "): " .. name .. " = "
				.. self:ConvertValueToInfo(value)
		end
	end
	return c
end

function ChoGGi_DlgExamine:RetDebugGetInfo(obj)
	self.RetDebugInfo_table = self.RetDebugInfo_table or {}
	local temp = self.RetDebugInfo_table
	ChoGGi_Funcs.Common.objlist_Destroy(temp)

	local c = 0
	local info = debug.getinfo(obj, "Slfunt")
	for key, value in pairs(info) do
		c = c + 1
		temp[c] = key .. ": " .. self:ConvertValueToInfo(value)
	end
	-- since pairs doesn't have an order we need a sort
	table.sort(temp)

	table.insert(temp, 1, "\ngetinfo(): ")
	return table.concat(temp, "\n")
end
function ChoGGi_DlgExamine:RetFuncArgs(obj)
	if blacklist then
		return "params: (?)"
	end
	self.RetDebugInfo_table = self.RetDebugInfo_table or {}
	local temp = self.RetDebugInfo_table
	ChoGGi_Funcs.Common.objlist_Destroy(temp)

	local info = debug.getinfo(obj, "u")
	if info.nparams > 0 then
		for i = 1, info.nparams do
			temp[i] = debug.getlocal(obj, i)
		end

		table.insert(temp, 1, "params: ")
		local args = table.concat(temp, ", ")

		-- remove extra , from concat and add ... if it has a vararg
		return args:gsub(": , ", ": (") .. (info.isvararg and ", ...)" or ")")
	elseif info.isvararg then
		return "params: (...)"
	else
		return "params: ()"
	end
end

function ChoGGi_DlgExamine:ToggleBBox(_, bbox)
	if self.spawned_bbox then
		-- the clear func expects it this way
		self.spawned_bbox.ChoGGi_bboxobj = self.spawned_bbox
		ChoGGi_Funcs.Common.BBoxLines_Clear(self.spawned_bbox)
		self.spawned_bbox = false
	else
		self.spawned_bbox = ChoGGi_Funcs.Common.BBoxLines_Toggle(bbox)
		if not self.ChoGGi.Temp.Examine_BBoxes then
			self.ChoGGi.Temp.Examine_BBoxes = {}
		end
		self.ChoGGi.Temp.Examine_BBoxes[#self.ChoGGi.Temp.Examine_BBoxes+1] = self.spawned_bbox
	end
end

function ChoGGi_DlgExamine:SortInfoList(list, list_sort_num)
	list_sort_num = list_sort_num or self.info_list_sort_num
	local list_sort_obj = self.info_list_sort_obj
	-- sort backwards
	if self.sort_dir then
		table.sort(list, function(a, b)
			-- strings
			local c, d = list_sort_obj[a], list_sort_obj[b]
			if c and d then
				return CmpLower(d, c)
			end
			-- numbers
			c, d = list_sort_num[a], list_sort_num[b]
			if c and d then
				return c > d
			end
			if c or d then
				return d and true
			end
			-- just in case
			return CmpLower(b, a)
		end)
	-- sort normally
	else
		table.sort(list, function(a, b)

			-- strings
			local c, d = list_sort_obj[a], list_sort_obj[b]
			if c and d then
				return CmpLower(c, d)
			end

			-- numbers
			c, d = list_sort_num[a], list_sort_num[b]
			if c and d then
				return c < d
			end

			if c or d then
				return c and true
			end

			-- just in case
			return CmpLower(a, b)
		end)
	end
end

function ChoGGi_DlgExamine:AddItemsToInfoList(obj, c, list, skip_dupes, list_obj_str, is_enum)
	local list_sort_obj = self.info_list_sort_obj
	local list_obj_str = list_obj_str or self.info_list_obj_str

	for k, v in pairs(list) do
		if is_enum then
			-- remove the . at the start
			k = k:sub(2)
		end
		local name = self:ConvertValueToInfo(k)
		local sort = name
		name = self:HyperLink(k, self.OpenListMenu, nil, true) .. "* " .. self.hyperlink_end .. name

		if not skip_dupes[sort] then
			skip_dupes[sort] = true
			local str_tmp = name .. " = " .. self:ConvertValueToInfo(obj[k] or v)
			c = c + 1
			list_obj_str[c] = str_tmp
			list_sort_obj[str_tmp] = sort
		end
	end
	return c
end

-- the main "one"
function ChoGGi_DlgExamine:ConvertObjToInfo(obj, obj_type)
	-- the list we return with concat
	local list_obj_str = self.info_list_obj_str
	-- list of strs to sort with
	local list_sort_obj = self.info_list_sort_obj
	-- list of nums to sort with
	local list_sort_num = self.info_list_sort_num
	-- dupe list for the "All" checkbox
	local skip_dupes = self.info_list_skip_dupes

	table.iclear(list_obj_str)
	table.clear(list_sort_obj)
	table.clear(list_sort_num)
	table.clear(skip_dupes)

	local obj_metatable = getmetatable(obj)
	local c = 0
	local str_not_translated
	local show_all_values = self.show_all_values

	if obj_type == "table" then
		-- close enough
		local is_indexed = #obj > 0
		-- chinese is super slow
		local is_chinese = self.is_chinese

		local function BuildObjTable(k, v)
			-- sorely needed delay for chinese (or it "freezes" the game when loading something like _G)
			-- I assume unicode/text rendering is slower for the chars, 'cause examine is "really" slow with them.
			if is_chinese then
				Sleep(1)
			end

			local name = self:ConvertValueToInfo(k)
			local sort = name
			-- append context menu link
			name = self:HyperLink(k, self.OpenListMenu, nil, true) .. "* " .. self.hyperlink_end .. name

			-- store the names if we're doing all props
			if show_all_values then
				skip_dupes[sort] = true
			end
			c = c + 1
			local str_tmp = name .. " <color ChoGGi_orange>=</color> " .. self:ConvertValueToInfo(v, is_indexed)
			list_obj_str[c] = str_tmp

			if type(k) == "number" then
				list_sort_num[str_tmp] = k
			else
				list_sort_obj[str_tmp] = sort:gsub("<.->", "")
			end
		end
		--
		-- change value to be more helpful then just another true
		if obj == ThreadsRegister then
			for k, v in pairs(obj) do
				if v == true then
					local name = RetName(k)
					if name:sub(1, 7) == "thread:" then
						BuildObjTable(k, v)
					else
						BuildObjTable(k, name)
					end
				else
					BuildObjTable(k, v)
				end
			end
		else
			for k, v in pairs(obj) do
				BuildObjTable(k, v)
			end
		end
		-- show _something_ for Cargo objs
		if IsKindOf(obj, "Cargo") then
			BuildObjTable("id", obj.id)
		end

		-- keep looping through metatables till we run out
		if obj_metatable and show_all_values then
			local meta_temp = obj_metatable
			while meta_temp do
				c = self:AddItemsToInfoList(obj, c, meta_temp, skip_dupes, list_obj_str)
				if type(meta_temp.__index) == "table" then
					-- add the index
					c = self:AddItemsToInfoList(obj, c, meta_temp.__index, skip_dupes, list_obj_str)
					-- and the index metatable
					local meta = getmetatable(meta_temp.__index)
					if meta then
						c = self:AddItemsToInfoList(obj, c, meta, skip_dupes, list_obj_str)
					end
				end

				meta_temp = getmetatable(meta_temp)
			end
		end

		-- pretty rare occurrence
		if self.show_enum_values and self.enum_vars then
			c = self:AddItemsToInfoList(obj, c, self.enum_vars, skip_dupes, list_obj_str, true)
		end

		-- the regular getmetatable will use __metatable if it exists, so we check this as well
		if testing and not blacklist then
			local dbg_metatable = debug.getmetatable(obj)
			if dbg_metatable and dbg_metatable ~= obj_metatable then
				print("'testing' ECM Sez DIFFERENT METATABLE", self.name, "\nmeta:", obj_metatable, "\ndbg:", dbg_metatable, "")
			end
		end

	elseif obj_type == "function" then
		c = c + 1
		list_obj_str[c] = self:ConvertValueToInfo(tostring(obj))

		c = c + 1
		list_obj_str[c] = self:HyperLink(obj, function()
			ChoGGi_Funcs.Common.OpenInExamineDlg(obj, {
				has_params = true,
				parent = self,
			})
		end) .. RetName(obj) .. self.hyperlink_end
	end

	self:SortInfoList(list_obj_str, list_sort_num)

	-- cobjects, not property objs
	if self.is_valid_obj and obj:IsKindOf("CObject") then
		local entity = ChoGGi_Funcs.Common.RetObjectEntity(obj)

		table.insert(list_obj_str, 1, "\t--"
			.. self:HyperLink(obj, function()
				ChoGGi_Funcs.Common.OpenInExamineDlg(getmetatable(obj), {
					has_params = true,
					parent = self,
				})
			end)
			.. obj.class .. self.hyperlink_end

			.. self:HyperLink(obj, function()
				SelectObj(obj)
			end) .. " @ " .. self.hyperlink_end

			.. self:ConvertValueToInfo(obj:GetVisualPos())
			.. " <color ChoGGi_palegreen>" .. RetMapType(obj) .. "</color> --"
		)
		-- add the particle name
		if obj:IsKindOf("ParSystem") then
			local par_name = obj:GetParticlesName()
			if par_name ~= "" then
				table.insert(list_obj_str, 2, "GetParticlesName(): " .. self:ConvertValueToInfo(par_name) .. "\n")
			end
		end

		-- stuff that changes anim state?
		local state_added
		if obj:IsValidPos() and entity and 0 < obj:GetAnimDuration() then
			state_added = true
			-- add pathing table
			local current_pos = obj:GetVisualPos()
			local going_to = current_pos + obj:GetStepVector() * obj:TimeToAnimEnd() / obj:GetAnimDuration()
			local path = obj.GetPath and obj:GetPath()
			if path then
				local path_c = #path
				for i = 1, path_c do
					path[i] = path[i]:SetTerrainZ()
				end
				path[path_c+1] = going_to
				-- make it an objlist, so mark all works
				setmetatable(path, objlist)
			else
				path = going_to
			end

			-- step vector
			local state = obj:GetState()
			local step_vector = obj:GetStepVector(state, 0)
			if tostring(step_vector) == "(0, 0, 0)" then
				step_vector = ""
			else
				step_vector =	", step: " .. self:ConvertValueToInfo(step_vector) .. "\n"
			end
			-- pathing
			if current_pos ~= going_to then
				path = Translate(T{302535920001545--[["Going to <color ChoGGi_green><loc></color>"]],
					loc = self:ConvertValueToInfo(path),
				}) .. "\n"
			else
				path = ""
			end
			-- If neither then add a newline
			if path == "" and step_vector == "" then
				path = "\n"
			end

			table.insert(list_obj_str, 2, self.string_State .. ": "
				.. GetStateName(state) .. step_vector .. path
			)

		end

		-- parent object of attached obj
		local parent = obj:GetParent()
		if IsValid(parent) then
			table.insert(list_obj_str, 2, "\nGetParent(): " .. self:ConvertValueToInfo(parent)
				.. "\nGetAttachOffset(): " .. self:ConvertValueToInfo(obj:GetAttachOffset())
				.. "\nGetAttachAxis(): " .. self:ConvertValueToInfo(obj:GetAttachAxis())
				.. "\nGetAttachAngle(): " .. self:ConvertValueToInfo(obj:GetAttachAngle())
				.. "\nGetAttachSpot(): " .. self:ConvertValueToInfo(obj:GetAttachSpot())
				.. "\nAttachSpotName: " .. self:ConvertValueToInfo(parent:GetSpotName(obj:GetAttachSpot()))
				.. (state_added and "" or "\n")
			)
		end

		if entity then
			local ver_tris = ""
			-- CRASH warning! calling GetNumTris/GetNumVertices on InvisibleObject (and other stuff without mesh/material) == CTD
			if entity ~= "PointLight" and GetStateMaterial(entity, 0, 0) ~= "" then
				ver_tris = "\nGetNumTris(): " .. self:ConvertValueToInfo(obj:GetNumTris())
				.. ", GetNumVertices(): " .. self:ConvertValueToInfo(obj:GetNumVertices())
			end

			-- some entity details as well
			table.insert(list_obj_str, 2, "GetEntity(): " .. self:ConvertValueToInfo(entity)
				.. ver_tris
				.. "\nGetAxis(): " .. self:ConvertValueToInfo(obj:GetAxis())
				.. "\nGetAngle(): " .. self:ConvertValueToInfo(obj:GetAngle())
				.. ", GetScale(): " .. self:ConvertValueToInfo(obj:GetScale())
				.. ((parent or state_added) and "" or "\n")
			)
		end
	end -- valid obj

	if obj_type == "number" or obj_type == "boolean" or (obj_type == "string" and not show_all_values) then
		if obj == "nil" then
			return Translate(302535920000417--[[Null reference]])
		end
		c = c + 1
		list_obj_str[c] = self:ConvertValueToInfo(obj)

	elseif obj_type == "userdata" or (obj_type == "string" and show_all_values) then
		c = c + 1
		list_obj_str[c] = self:ConvertValueToInfo(obj)

		-- add any functions from getmetatable to the (scant) list
		if obj_metatable then
			local data_meta = self.info_list_data_meta
			table.clear(data_meta)
			table.clear(skip_dupes)
			table.clear(list_sort_obj)

			local m_c = 0
			mc = self:AddItemsToInfoList(empty_table, m_c, obj_metatable, skip_dupes, data_meta)
			-- any extras from __index (most show index in metatable, not all
			if type(obj_metatable.__index) == "table" then
				mc = self:AddItemsToInfoList(empty_table, m_c, obj_metatable.__index, skip_dupes, data_meta)
			end

			self:SortInfoList(data_meta, empty_table)

			-- add some info for HGE. stuff
			local name = obj_metatable.__name
			if name == "HGE.TaskRequest" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "Unpack(): "
					.. self:HyperLink(obj, function()
						ChoGGi_Funcs.Common.OpenInExamineDlg({obj:Unpack()}, {
							has_params = true,
							parent = self,
							title = Translate(302535920000885--[[Unpacked]]),
						})
					end)
					.. Translate(302535920000048--[[View]]) .. self.hyperlink_end
				)
				-- we use this with Object>Flags
				self.obj_flags = obj:GetFlags()
				table.insert(data_meta, 1, "GetFlags(): " .. self:ConvertValueToInfo(self.obj_flags)
					.. self:ConvertValueToInfo({
						ChoGGi_AddHyperLink = true,
						hint = Translate(302535920001447--[[Shows list of flags set for selected object.-]]),
						func = function(ex_dlg)
							ChoGGi_Funcs.Common.ObjFlagsList_TR(obj, ex_dlg)
						end,
					})
				)
				table.insert(data_meta, 1, "GetReciprocalRequest(): " .. self:ConvertValueToInfo(obj:GetReciprocalRequest()))
				table.insert(data_meta, 1, "GetLastServiced(): " .. self:ConvertValueToInfo(obj:GetLastServiced()))
				table.insert(data_meta, 1, "GetFreeUnitSlots(): " .. self:ConvertValueToInfo(obj:GetFreeUnitSlots()))
				table.insert(data_meta, 1, "GetFillIndex(): " .. self:ConvertValueToInfo(obj:GetFillIndex()))
				table.insert(data_meta, 1, "GetTargetAmount(): " .. self:ConvertValueToInfo(obj:GetTargetAmount()))
				table.insert(data_meta, 1, "GetDesiredAmount(): " .. self:ConvertValueToInfo(obj:GetDesiredAmount()))
				table.insert(data_meta, 1, "GetActualAmount(): " .. self:ConvertValueToInfo(obj:GetActualAmount()))
				table.insert(data_meta, 1, "GetWorkingUnits(): " .. self:ConvertValueToInfo(obj:GetWorkingUnits()))
				table.insert(data_meta, 1, "GetResource(): " .. self:ConvertValueToInfo(obj:GetResource()))
				table.insert(data_meta, 1, "\nGetBuilding(): " .. self:ConvertValueToInfo(obj:GetBuilding()))

			elseif name == "HGE.Grid" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "get_default(): " .. self:ConvertValueToInfo(obj:get_default()))
				table.insert(data_meta, 1, "max_value(): " .. self:ConvertValueToInfo(obj:max_value()))
				table.insert(data_meta, 1, "bits(): " .. self:ConvertValueToInfo(obj:bits()))
				local size = {obj:size()}
				if size[1] then
					table.insert(data_meta, 1, "\nsize(): " .. self:ConvertValueToInfo(size[1])
						.. " " .. self:ConvertValueToInfo(size[2]))
				end

			elseif name == "HGE.XMGrid" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "GridGetAllocSize(): " .. self:ConvertValueToInfo(GridGetAllocSize(obj) or 0))
				local minmax = {obj:minmax()}
				if minmax[1] then
					table.insert(data_meta, 1, "minmax(): " .. self:ConvertValueToInfo(minmax[1]) .. " "
						.. self:ConvertValueToInfo(minmax[2]))
				end
				-- this takes a few seconds to load, so it's in a clickable link
				table.insert(data_meta, 1, self:ConvertValueToInfo({
					ChoGGi_AddHyperLink = true,
					hint = Translate(302535920001124--[[Will take a few seconds to complete.]]),
					name = "levels(true, 1):",
					func = function()
						ChoGGi_Funcs.Common.OpenInExamineDlg({obj:levels(true, 1)}, {
							has_params = true,
							parent = self,
						})
					end,
				}))

				table.insert(data_meta, 1, "GetPositiveCells(): " .. self:ConvertValueToInfo(obj:GetPositiveCells()))
				table.insert(data_meta, 1, "EnumZones(): " .. self:ConvertValueToInfo(obj:EnumZones()))
				table.insert(data_meta, 1, "size(): " .. self:ConvertValueToInfo(obj:size()))
				table.insert(data_meta, 1, "packing(): " .. self:ConvertValueToInfo(obj:packing()))
				-- crashing tendencies
-- 				table.insert(data_meta, 1, "histogram(): " .. self:ConvertValueToInfo({obj:histogram()}))
				-- freeze screen with render error in log ex(Flight_Height:GetBinData())
				table.insert(data_meta, 1, "\nCenterOfMass(): " .. self:ConvertValueToInfo(obj:CenterOfMass()))

			elseif name == "HGE.Box" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				local points2d = {obj:ToPoints2D()}
				if points2d[1] then
					table.insert(data_meta, 1, "ToPoints2D(): " .. self:ConvertValueToInfo(points2d[1])
						.. " " .. self:ConvertValueToInfo(points2d[2])
						.. "\n" .. self:ConvertValueToInfo(points2d[3])
						.. " " .. self:ConvertValueToInfo(points2d[4])
					)
				end
				local bsphere = {obj:GetBSphere()}
				if bsphere[1] then
					table.insert(data_meta, 1, "GetBSphere(): "
						.. self:ConvertValueToInfo(bsphere[1]) .. " "
						.. self:ConvertValueToInfo(bsphere[2]))
				end
				local center = obj:Center()
				table.insert(data_meta, 1, "Center(): " .. self:ConvertValueToInfo(center))
				table.insert(data_meta, 1, "IsEmpty(): " .. self:ConvertValueToInfo(obj:IsEmpty()))
				local Radius = obj:Radius()
				local Radius2D = obj:Radius2D()
				table.insert(data_meta, 1, "Radius(): " .. self:ConvertValueToInfo(Radius))
				if Radius ~= Radius2D then
					table.insert(data_meta, 1, "Radius2D(): " .. self:ConvertValueToInfo(Radius2D))
				end
				table.insert(data_meta, 1, "IsValidZ(): " .. self:ConvertValueToInfo(obj:IsValidZ()))
				table.insert(data_meta, 1, "IsValid(): " .. self:ConvertValueToInfo(obj:IsValid()))
				table.insert(data_meta, 1, "max(): " .. self:ConvertValueToInfo(obj:max()))
				local min = obj:size()
				if min:z() then
					table.insert(data_meta, 1, "min() x, y, z: " .. self:ConvertValueToInfo(min))
				else
					table.insert(data_meta, 1, "min() x, y: " .. self:ConvertValueToInfo(min))
				end
				local size = obj:size()
				if size:z() then
					table.insert(data_meta, 1, "\nsize() w, h, d: " .. self:ConvertValueToInfo(size))
				else
					table.insert(data_meta, 1, "\nsize() w, h: " .. self:ConvertValueToInfo(size))
				end
				if MainCity and center:InBox2D(ChoGGi_Funcs.Common.ConstructableArea()) then
					table.insert(data_meta, 1, self:HyperLink(obj, self.ToggleBBox, Translate(302535920001550--[[Toggle viewing BBox.]])) .. Translate(302535920001549--[[View BBox]]) .. self.hyperlink_end)
				end

			elseif name == "HGE.Point" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "__unm(): " .. self:ConvertValueToInfo(obj:__unm()))
				local x, y, z = obj:xyz()
				local xyz = "x: " .. self:ConvertValueToInfo(x)
					.. ", y: " .. self:ConvertValueToInfo(y)
				if z then
					xyz = xyz .. ", z: " .. self:ConvertValueToInfo(z)
				end
				table.insert(data_meta, 1, xyz)
				table.insert(data_meta, 1, "IsValidZ(): " .. self:ConvertValueToInfo(obj:IsValidZ()))
				table.insert(data_meta, 1, "\nIsValid(): " .. self:ConvertValueToInfo(obj:IsValid()))

			elseif name == "HGE.RandState" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "Last(): " .. self:ConvertValueToInfo(obj:Last()))
				table.insert(data_meta, 1, "GetStable(): " .. self:ConvertValueToInfo(obj:GetStable()))
				table.insert(data_meta, 1, "Get(): " .. self:ConvertValueToInfo(obj:Get()))
				table.insert(data_meta, 1, "\nCount(): " .. self:ConvertValueToInfo(obj:Count()))

			elseif name == "HGE.Quaternion" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "Norm(): " .. self:ConvertValueToInfo(obj:Norm()))
				table.insert(data_meta, 1, "Inv(): " .. self:ConvertValueToInfo(obj:Inv()))
				local roll, pitch, yaw = obj:GetRollPitchYaw()
				table.insert(data_meta, 1, "GetRollPitchYaw(): "
					.. self:ConvertValueToInfo(roll)
					.. " " .. self:ConvertValueToInfo(pitch)
					.. " " .. self:ConvertValueToInfo(yaw))
				table.insert(data_meta, 1, "\nGetAxisAngle(): " .. self:ConvertValueToInfo(obj:GetAxisAngle()))

			elseif name == "LuaPStr" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "hash(): " .. self:ConvertValueToInfo(obj:hash()))
				table.insert(data_meta, 1, "str(): " .. self:ConvertValueToInfo(obj:str()))
				table.insert(data_meta, 1, "parseTuples(): " .. self:ConvertValueToInfo(obj:parseTuples()))
				table.insert(data_meta, 1, "getInt(): " .. self:ConvertValueToInfo(obj:getInt()))
				table.insert(data_meta, 1, "\nsize(): " .. self:ConvertValueToInfo(obj:size()))
			elseif name == "HGE.TerrainRef" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "GetAllTerrainTypes(): " .. self:ConvertValueToInfo(obj:GetAllTerrainTypes()))
				table.insert(data_meta, 1, "GetAreaHeight(): " .. self:ConvertValueToInfo(obj:GetAreaHeight()))
				table.insert(data_meta, 1, "GetMapSize(): " .. self:ConvertValueToInfo(obj:GetMapSize()))
				table.insert(data_meta, 1, "GetHeightGrid(): " .. self:ConvertValueToInfo(obj:GetHeightGrid()))
			elseif name == "HGE.RealmRef" then
				table.insert(data_meta, 1, "\ngetmetatable():")
				table.insert(data_meta, 1, "GetMapBox(): " .. self:ConvertValueToInfo(obj:GetMapBox()))
--~ 			elseif name == "HGE.File" then
--~ 			elseif name == "HGE.ForEachReachable" then
--~ 			elseif name == "RSAKey" then
--~ 			elseif name == "lpeg-pattern" then

			else
				table.insert(data_meta, 1, "\ngetmetatable():")

				local is_t = IsT(obj)
				if is_t then
					table.insert(data_meta, 1, "THasArgs(): " .. self:ConvertValueToInfo(THasArgs(obj)))
					-- IsT returns the string id, but we'll just call it TGetID() to make it more obvious for people
					table.insert(data_meta, 1, "\nTGetID(): " .. TGetID(obj))
					if str_not_translated and not self.city_object then
						table.insert(data_meta, 1, Translate(302535920001500--[[userdata object probably needs self.city_object to translate.]]))
					end
				end
			end


			c = c + 1
			list_obj_str[c] = table.concat(data_meta, "\n")
		end

	-- add some extra info for funcs
	elseif obj_type == "function" then
		if blacklist then
			c = c + 1
			list_obj_str[c] = "\ngetinfo(): " .. ChoGGi_Funcs.Common.DebugGetInfo(obj)
		else
			c = c + 1
			list_obj_str[c] = "\n"

			local info = debug.getinfo(obj, "Su")

			-- link to source code
			if info.what == "Lua" then
				c = c + 1
				list_obj_str[c] = self:HyperLink(obj, self.ViewSourceCode, T{302535920001520--[["Opens source code in text viewer (if it exists):
Mod code works as is, HG github game code needs to be placed at:
<color ChoGGi_green><path>Source</color>
Example: <color ChoGGi_yellow>Source/Lua/_const.lua</color>

Decompiled code won't scroll correctly as the line numbers are different."]],
					path = ConvertToOSPath("AppData/"),
				}) .. Translate(302535920001519--[[View Source]]) .. self.hyperlink_end
			end
			-- list args
			local args = self:RetFuncArgs(obj)
			if args then
				c = c + 1
				list_obj_str[c] = args
			end
			-- and upvalues
			local nups = info.nups
			if nups > 0 then
				c = self:RetDebugUpValue(obj, list_obj_str, c, nups)
			end
			-- lastly list anything from debug.getinfo()
			c = c + 1
			list_obj_str[c] = self:RetDebugGetInfo(obj)
		end

	elseif obj_type == "thread" then

		c = c + 1
		list_obj_str[c] = "<color 255 255 255>"
			.. Translate(302535920001353--[[Thread info]])
			.. ":\nIsValidThread(): "
		local is_valid = IsValidThread(obj)
		if is_valid then
			list_obj_str[c] = list_obj_str[c]
				.. self:ConvertValueToInfo(is_valid or nil)
				.. "\nGetThreadStatus(): "
				.. self:ConvertValueToInfo(GetThreadStatus(obj) or nil)
				.. "\nIsGameTimeThread(): "
				.. self:ConvertValueToInfo(IsGameTimeThread(obj))
				.. "\nIsRealTimeThread(): "
				.. self:ConvertValueToInfo(IsRealTimeThread(obj))
				.. "\nThreadHasFlags(), Persist: "
				.. self:ConvertValueToInfo(ThreadHasFlags(obj, 1048576) or false)
				.. " OnMap: "
				.. self:ConvertValueToInfo(ThreadHasFlags(obj, 2097152) or false)
				.. "\n"
		else
			list_obj_str[c] = list_obj_str[c]
				.. self:ConvertValueToInfo(is_valid or nil)
				.. "\n"
		end

		local info_list = ChoGGi_Funcs.Common.RetThreadInfo(obj)
		-- needed for the table that's returned if blacklist is enabled (it starts at 1, getinfo starts at 0)
		local starter = info_list[0] and 0 or 1

		for i = starter, #info_list do
			local info = info_list[i]
			c = c + 1
			list_obj_str[c] = "\ngetinfo(level " .. info.level .. "): "

			c = c + 1
			list_obj_str[c] = "func: " .. info.name .. ", "
				.. self:ConvertValueToInfo(info.func)

			if info.getlocal then
				for j = 1, #info.getlocal do
					local v = info.getlocal[j]
					c = c + 1
					list_obj_str[c] = "getlocal(" .. v.level .. ", " .. j .. "): " .. v.name .. ", "
						.. self:ConvertValueToInfo(v.value)
				end
			end

			if info.getupvalue then
				for j = 1, #info.getupvalue do
					local v = info.getupvalue[j]
					c = c + 1
					list_obj_str[c] = "getupvalue(" .. j .. "): " .. v.name .. ", "
						.. self:ConvertValueToInfo(v.value)
				end
			end
		end
		if info_list.gethook then
			c = c + 1
			list_obj_str[c] = self:ConvertValueToInfo(info_list.gethook)
		end

	end

		-- try to add translated string if it's one of these
	if obj_metatable == TMeta or obj_metatable == TConcatMeta then
		c = c + 1
		local translated_str = Translate(302535920000986--[[Translated]])
		list_obj_str[c] = (obj_metatable == TMeta
			and "\nTMeta " .. translated_str .. ": \n"
			or "\nTConcatMeta " .. translated_str .. ": \n")
			.. Translate(obj)
	end

	-- do we add a metatable to it?
	if not (obj == "nil" or self.is_valid_obj or obj_type == "userdata") and obj_metatable
			or self.is_valid_obj and obj:IsKindOf("BaseSocket")
			or self.is_valid_obj and obj:IsKindOf("XControl")
		then

		table.insert(list_obj_str, 1, "\t-- metatable: " .. self:ConvertValueToInfo(obj_metatable) .. " --")

		if self.enum_vars and next(self.enum_vars) then
			list_obj_str[1] = list_obj_str[1] .. self:HyperLink(obj, function()
				ChoGGi_Funcs.Common.OpenInExamineDlg(self.enum_vars, {
					has_params = true,
					parent = self,
					title = Translate(302535920001442--[[Enum]]),
				})
			end)
			.. " enum" .. self.hyperlink_end
		end

	end

	-- Check for not strings
	for i = 1, c do
		if type(list_obj_str[i]) ~= "string" and not obj.__mtl then
			--  obj.__mtl == one of mine
			if testing then
				OpenExamine{list_obj_str, list_obj_str[i]} -- OpenExamine
				print("Check for not strings")
				print(i, list_obj_str[i])
			else
				-- I'll fix what I can find, but for enduser just make it work
				list_obj_str[i] = tostring(list_obj_str[i])
			end
		end
	end

	return table.concat(list_obj_str, "\n")
end
-- ------------------------------------------------------------------------------------------------------------------

do -- BuildAttachesPopup
	local function ParentClicked(item, _, _, button)
		if button == "R" then
			CopyToClipboard(item.showobj.class)
		else
			ChoGGi_Funcs.Common.ClearShowObj(item.showobj)
			ChoGGi_Funcs.Common.OpenInExamineDlg(item.showobj, {
				has_params = true,
				parent = item.dlg,
			})
		end
	end
	local function SortList(a, b)
		return CmpLower(a.name, b.name)
	end

	function ChoGGi_DlgExamine:BuildAttachesPopup(obj)
		table.iclear(self.attaches_menu_popup)
		local attaches = ChoGGi_Funcs.Common.GetAllAttaches(obj, true)
		local attach_amount = #attaches


		local str_rclick = Translate{302535920000904--[["<right_click> to copy <color ChoGGi_yellow><str></color> to clipboard."]],
			str = self.string_Classname,
		}
		local str_attached = Translate(302535920001544--[[Attached to]])
		local str_handle = Translate(302535920000955--[[Handle]])
		local str_position = Translate(302535920000461--[[Position]])
		local str_particle = Translate(302535920001622--[[Particle]])
		local str_hint_bottom = T(302535920000589--[[<left_click> Examine <right_click> Clipboard]])

		for i = 1, attach_amount do
			local a = attaches[i]
			local pos = a.GetVisualPos and a:GetVisualPos()

			local name = RetName(a)
			if name ~= a.class then
				name = name .. ": " .. a.class
			end

			-- build hint
			table.iclear(self.attaches_menu_popup_hint)
			local c = 1
			self.attaches_menu_popup_hint[c] = self.string_Classname .. ": " .. a.class
			c = c + 1
			self.attaches_menu_popup_hint[c] = str_rclick

			-- attached to name
			if a.ChoGGi_Marked_Attach then
				c = c + 1
				self.attaches_menu_popup_hint[c] = str_attached .. ": " .. a.ChoGGi_Marked_Attach
				a.ChoGGi_Marked_Attach = nil
			end
			if a.handle then
				c = c + 1
				self.attaches_menu_popup_hint[c] = str_handle .. ": " .. a.handle
			end
			c = c + 1
			self.attaches_menu_popup_hint[c] = str_position .. ": " .. tostring(pos)

			if a:IsKindOf("ParSystem") then
				local par_name = a:GetParticlesName()
				if par_name ~= "" then
					c = c + 1
					self.attaches_menu_popup_hint[c] = str_particle .. ": " .. par_name
				end
			elseif a:IsKindOf("CObject") then
				local entity = ChoGGi_Funcs.Common.RetObjectEntity(a)
				if entity then
					c = c + 1
					self.attaches_menu_popup_hint[c] = self.string_Entity .. ": " .. entity
				end
			end

			self.attaches_menu_popup[i] = {
				name = name,
				hint = table.concat(self.attaches_menu_popup_hint, "\n"),
				-- used for ref above as well
				showobj = a,
				hint_bottom = str_hint_bottom,
				mouseup = ParentClicked,
				dlg = self,
			}
		end

		if attach_amount > 0 then
			table.sort(self.attaches_menu_popup, SortList)
			SetWinObjectVis(self.idAttaches, true)
			self.idAttaches.RolloverText = T{302535920000070--[["Shows list of attachments. This <color ChoGGi_green><str1></color> has <color ChoGGi_yellow><str2></color>.

Press <color ChoGGi_green><str3></color> to hide green markers."]],
				str1 = self.name,
				str2 = attach_amount,
				str3 = "<image CommonAssets/UI/Menu/NoblePreview.tga 2500>",
			}
		else
			SetWinObjectVis(self.idAttaches)
		end
	end
end -- do

function ChoGGi_DlgExamine:SetToolbarVis(obj, obj_metatable)
	-- always hide all by default
	SetWinObjectVis(self.idChildLock)
	SetWinObjectVis(self.idButMarkObject)
	SetWinObjectVis(self.idButMarkAll)
	SetWinObjectVis(self.idButMarkAllLine)
	SetWinObjectVis(self.idButSetObjlist)
	SetWinObjectVis(self.idViewEnum)
	SetWinObjectVis(self.idButDeleteObj)
	SetWinObjectVis(self.idButDeleteAll)
	-- not a toolbar button, but since we're already calling IsValid then good enough
	SetWinObjectVis(self.idObjects)

	-- no sense in showing it in mainmenu/new game screens
	SetWinObjectVis(self.idButClear, self.city_object)

	SetWinObjectVis(self.idShowAllValues, obj_metatable and self.obj_type ~= "userdata")

	if self.obj_type == "table" then
		SetWinObjectVis(self.idChildLock, true)

		-- none of this works on _G, and i'll take any bit of speed for _G
		if self.name ~= "_G" then

			-- pretty much any class object
			SetWinObjectVis(self.idButDeleteObj, PropObjGetProperty(obj, "delete"))

			self.is_valid_obj = IsValid(obj)

			-- can't mark if it isn't an object, and no sense in marking something off the map
			if obj ~= _G and obj.GetPos then
				SetWinObjectVis(self.idButMarkObject, self.is_valid_obj and obj:GetPos() ~= InvalidPos)
			end

			if not self.obj_entity and PropObjGetProperty(obj, "GetEntity") then
				local entity = obj:GetEntity()
				if IsValidEntity(entity) then
					self.obj_entity = entity
				end
			end
			-- not a toolbar button, but since we're already calling IsValid then good enough
			SetWinObjectVis(self.idObjects, self.obj_entity or self.is_valid_obj)

			-- objlist objects let us do some easy for each
			if IsObjlist(obj) then
				SetWinObjectVis(self.idButMarkAll, true)
				SetWinObjectVis(self.idButMarkAllLine, true)
				SetWinObjectVis(self.idButDeleteAll, true)
				-- we only want to show it for objlist or non-metatables, because I don't want to save/restore them
				SetWinObjectVis(self.idButSetObjlist, true)
			elseif not obj_metatable then
				SetWinObjectVis(self.idButSetObjlist, true)
			else
				SetWinObjectVis(self.idButMarkAll)
				SetWinObjectVis(self.idButMarkAllLine)
				SetWinObjectVis(self.idButDeleteAll)
				SetWinObjectVis(self.idButSetObjlist)
			end

			if ChoGGi.what_game == "Mars" then
				-- pretty rare occurrence
				self.enum_vars = EnumVars(self.name)
				SetWinObjectVis(self.idViewEnum, self.enum_vars and next(self.enum_vars))
			end
		end

	elseif self.obj_type == "thread" then
		SetWinObjectVis(self.idButDeleteObj, true)
	end

end

function ChoGGi_DlgExamine.ParentClicked(item, _, _, button)
	if button == "R" then
		CopyToClipboard(item.name)
	else
		ChoGGi_Funcs.Common.OpenInExamineDlg(g_Classes[item.name], {
			has_params = true,
			parent = item.dlg,
		})
	end
end
function ChoGGi_DlgExamine.ParentClickedTemplate(item, _, _, button)
	if button == "R" then
		CopyToClipboard("BuildingTemplates." ..item.name)
	else
		ChoGGi_Funcs.Common.OpenInExamineDlg(BuildingTemplates[item.name], {
			has_params = true,
			parent = item.dlg,
		})
	end
end

function ChoGGi_DlgExamine:BuildParentsMenu(list, list_type, title, sort_type)
	if list and next(list) then
		list = ChoGGi_Funcs.Common.RetSortTextAssTable(list, sort_type)
		self[list_type] = list
		local c = #self.parents_menu_popup

		c = c + 1
		self.parents_menu_popup[c] = {
			name = "-- " .. title .. " --",
			disable = true,
			centred = true,
		}

		for i = 1, #list do
			local item = list[i]
			-- no sense in having an item in parents and ancestors
			if self.pmenu_skip_dupes[item] then
				goto continue
			end

			local parent_hint = T{"<left_click> <examineN> <classN> <objectN> : <color 100 255 100><itemN></color>\n <info>",
				examineN = T(302535920000069--[[Examine]]),
				classN = self.string_Class,
				objectN = self.string_Object,
				itemN = item,
				info = T{302535920000904--[["<right_click> to copy <color ChoGGi_yellow><str></color> to clipboard."]],
					str = self.string_Classname,
				},
			}

			self.pmenu_skip_dupes[item] = true
			c = c + 1
			self.parents_menu_popup[c] = {
				name = item,
				hint = parent_hint,
				hint_bottom = T(302535920000589--[[<left_click> Examine <right_click> Clipboard]]),
				mouseup = self.ParentClicked,
				dlg = self,
			}
			--
			::continue::
		end
	end
end
-- startup
function ChoGGi_DlgExamine:SetObj(startup)
	local obj = self.obj

	-- Reset the hyperlinks
	table.iclear(self.onclick_funcs)
	table.iclear(self.onclick_objs)
	self.onclick_count = 0

	if self.str_object then
		-- Get whatever the obj leads to (if anything)
		local obj_ref = ChoGGi_Funcs.Common.DotPathToObject(obj)
		-- set title
		self.override_title = true
		self.title = "str: " .. obj
		-- If it is then we use that as the obj to examine
		if type(obj_ref) == "function" then
			obj = {obj_ref(self.varargs)}
		else
			obj = obj_ref
		end
	end
	-- so we can access the obj elsewhere
	self.obj_ref = obj

	local obj_type = type(obj)
	self.obj_type = obj_type
	local obj_class

	local name = RetName(self.str_object and obj or obj)
	self.name = name

	local obj_metatable = getmetatable(obj)
	self.obj_metatable = obj_metatable

	self:SetToolbarVis(obj, obj_metatable)

	self.idText:SetText(self.string_Loadingresources)

	if obj_type == "table" then
		self.idButClearTable:SetVisible(true)

		obj_class = g_Classes[obj.class]

		-- add table length to title
		if obj ~= _G and obj[1] then
			name = name .. " (" .. #obj .. ")"
		end

		-- build parents/ancestors menu
		if obj_class then
			table.iclear(self.parents_menu_popup)
			table.clear(self.pmenu_skip_dupes)
			-- build menu list
			self:BuildParentsMenu(obj.__parents, "parents", T(302535920000520--[[Parents]]))
			self:BuildParentsMenu(obj.__ancestors, "ancestors", T(302535920000525--[[Ancestors]]), true)

			table.insert(self.parents_menu_popup, 1, {
				name = "-- " .. self.string_Class .. " --",
				disable = true,
				centred = true,
			})

			local parent_hint = T{"<left_click> <examineN> <classN> <objectN> : <color 100 255 100><class></color>\n <info>",
				examineN = T(302535920000069--[[Examine]]),
				classN = self.string_Class,
				objectN = self.string_Object,
				class = obj.class,
				info = T{302535920000904--[["<right_click> to copy <color ChoGGi_yellow><str></color> to clipboard."]],
					str = self.string_Classname,
				},
			}

			table.insert(self.parents_menu_popup, 2, {
				name = obj.class,
				hint = parent_hint,
				hint_bottom = T(302535920000589--[[<left_click> Examine <right_click> Clipboard]]),
				mouseup = self.ParentClicked,
				dlg = self,
			})

			-- Add template name so I don't need to go looking for it (mostly just depots)
			local template_name = obj.template_name
			if template_name and template_name ~= "" and template_name ~= obj.class then

				local template_hint = T{"<left_click> <examineN> <classN> <objectN> : <color 100 255 100><template></color>\n <info>",
					examineN = T(302535920000069--[[Examine]]),
					classN = self.string_Class,
					objectN = self.string_Object,
					template = template_name,
					info = T{302535920000904--[["<right_click> to copy <color ChoGGi_yellow><str></color> to clipboard."]],
						str = template_name,
					}
				}

				table.insert(self.parents_menu_popup, 3, {
					name = template_name,
					hint = template_hint,
					hint_bottom = T(302535920000589--[[<left_click> Examine <right_click> Clipboard]]),
					mouseup = self.ParentClickedTemplate,
					dlg = self,
				})
			end

			-- If anything was added to the list then add to the menu
			if self.parents_menu_popup[1] then
				SetWinObjectVis(self.idParents, true)
			end
		end

		-- attaches button/menu
		self:BuildAttachesPopup(obj)

	end -- Istable

	local title = ""
	if obj == "nil" or obj == nil then
		title = "nil"
	else
		if self.override_title then
			title = self.title
		else
			local name_type = obj_type .. ": "
			title = name_type .. tostring(self.title or name or obj):gsub(name_type, "")
		end
	end
	self.idCaption:SetTitle(self, title)

	-- we add a slight delay; useful for bigger lists like _G or MapGet(true)
	-- so the dialog shows up (progress is happening user)
		if startup or self.is_chinese then
			-- the chinese text render is slow as molasses, so we have a Sleep in ConvertObjToInfo to keep ui stuff accessible
			CreateRealTimeThread(function()
				WaitMsg("OnRender")
--~ ChoGGi_Funcs.Common.TickStart("Examine")
				local status, result = pcall(self.ConvertObjToInfo, self, obj, obj_type)
				if status then
					self:SetTextTest(result)
				elseif testing then
--~ 					local _,str1 = string.find(result," at index ")
--~ 					local str2 = string.find(result," in table for ")
--~ 					local idx = string.sub(result, str1 + 1, str2 - 1)
--~ 					OpenExamine(result) -- OpenExamine
					print(result)
				end
--~ ChoGGi_Funcs.Common.TickEnd("Examine", self.name)
			end)
		else
			-- we normally don't want it in a thread with OnRender else it'll mess up my scroll pos (and stuff)
			local status, result = pcall(self.ConvertObjToInfo, self, obj, obj_type)
			if status then
				self:SetTextTest(result)
			else
				print(result)
			end
		end

	-- comments are good for stuff like this...
	return obj_class
end

function ChoGGi_DlgExamine:SetTextTest(text)
	text = Translate(text)
	-- \0 = non-text chars (ParseText ralphs)
	self.idText:SetText(text:gsub("\0", ""))
	-- Also SelectionShapes which is full of EncodePointsToString(shape), but that's the only table in the game so...

	-- [LUA ERROR] CommonLua/X/XText.lua:191: pattern too complex
	CreateRealTimeThread(function()
		WaitMsg("OnRender")
		if self.idText:GetText() == self.string_Loadingresources then
			ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
				parent = self,
				text = text,
				title = T(302535920001461--[[XText:ParseText() just ralphed.]]),
			}
		end
	end)
end

local function PopupClose(name)
	local popup = terminal.desktop[name]
	if popup then
		popup:Close()
	end
end

function ChoGGi_DlgExamine:CleanupCustomObjs(obj, force)
	-- can't have game objs in main menu (and log spam)
	if not self.city_object then
		return
	end

	obj = obj or self.obj_ref
	if self.obj_entity or IsValid(obj) then
		ChoGGi_Funcs.Common.BBoxLines_Clear(obj)
		ChoGGi_Funcs.Common.ObjHexShape_Clear(obj)
		ChoGGi_Funcs.Common.EntitySpots_Clear(obj)
		ChoGGi_Funcs.Common.SurfaceLines_Clear(obj)
	elseif IsObjlist(obj) or force then
		ChoGGi_Funcs.Common.ObjListLines_Clear(obj)
	end

	if self.spawned_bbox then
		ChoGGi_Funcs.Common.BBoxLines_Clear(self.spawned_bbox)
	end
end

function ChoGGi_DlgExamine:CloseXButtonFunc()
	-- close all ecm dialogs
	if IsControlPressed() then
		ChoGGi_Funcs.Common.CloseDialogsECM(self)
	-- close all parent examine dialogs
	elseif IsShiftPressed() then
		ChoGGi_Funcs.Common.CloseChildExamineDlgs(self)
		-- abort closing window
		return true
	end
end

function ChoGGi_DlgExamine:AddCloseXButton()
	return ChoGGi_XWindow.AddCloseXButton(self, {
		rollover = T(302535920000628--[["Close the examine dialog
	Hold Shift to close all ""parent"" examine dialogs.
	Hold Ctrl to close all ECM dialogs."]]),
	})
end

function ChoGGi_DlgExamine:Done()
	-- revert funcs
	self:SafeExamine()

	local obj = self.obj_ref
	-- stop refreshing
	if IsValidThread(self.autorefresh_thread) then
		DeleteThread(self.autorefresh_thread)
	end
	-- close any opened popup menus (they'll do it auto, but this looks quicker)
	PopupClose(self.idAttachesMenu)
	PopupClose(self.idParentsMenu)
	PopupClose(self.idToolsMenu)
	-- any circles/lines added
	if self.obj_type == "table" and self.name ~= "_G" then
		self:CleanupCustomObjs(obj)
	end
	-- clear any spheres/colour marked objs
	if self.marked_objects[1] then
		self:idButClear_OnPress()
	end
	-- remove this dialog from list of examine dialogs
	local dlgs = ChoGGi_dlgs_examine or empty_table
	dlgs[self.obj] = nil
	dlgs[obj] = nil
end
--
--
--
-- Used to open a dialog
local red = red
local function FlashTitlebar(title)
	title:SetBackground(red)
	Sleep(500)
	title:SetBackground(g_Classes.ChoGGi_XMoveControl.Background)
end

function ChoGGi_Funcs.Common.OpenInExamineDlg(obj, parent, title, ...)
	local params, parent_type

	params, parent, parent_type = RetParamsParents(parent, params, ...)
	-- preserve the orig params
	params.obj = obj
	if parent then
		params.parent = parent
	end
	if params.title or title then
		if title then
			params.title = Translate(title)
		else
			params.title = Translate(params.title)
		end
		params.override_title = true
	end

	-- check if the parent has an id and use it
	if params.parent and parent_type == "table" and params.parent.parent_id then
		params.parent_id = params.parent.parent_id
	end

	-- workaround for ChoGGi_dlgs_examine
	if type(params.obj) == "nil" then
		params.obj = "nil"
	end

	-- already examining? if so focus and return ( :new() doesn't return the opened dialog).
	local opened = ChoGGi_dlgs_examine[params.obj]

	if opened then
		-- dialog was closed, but ref remains
		if not IsValidXWin(opened) then
			ChoGGi_dlgs_examine[params.obj] = nil
		-- examine gets confused with children (first examined one that is)
		elseif not params.parent
			or params.parent and not (params.parent.child_lock and params.parent.child_lock_dlg)
		then
			-- hit refresh, cause i'm that kinda guy
			opened:RefreshExamine()
			-- and flash the titlebar
			CreateRealTimeThread(FlashTitlebar, opened.idMoveControl)
			return opened
		end
	end

	if params.parent ~= "str" and not (IsKindOf(params.parent, "XWindow") or IsPoint(params.parent)) then
		params.parent = nil
	end
	if type(params.title) ~= "string" then
		params.title = nil
	end

	-- are we using child lock?
	local new_child_lock_dlg
	if params.skip_child then
		if params.parent and IsKindOf(params.parent, "ChoGGi_DlgExamine") then
			params.parent.idChildLock:SetVisible()
		end
	else
		parent = params.parent

		if parent and IsKindOf(parent, "ChoGGi_DlgExamine") and parent.child_lock then
			local child = parent.child_lock_dlg
			if not IsValidXWin(child) then
				parent.child_lock_dlg = false
			else
				-- It's valid so update with new obj
				child.obj = params.obj
				child:SetObj()
				-- no need for a new window
				return
			end

			-- child_lock_dlg is invalid or not opened yet
			new_child_lock_dlg = true
		end
	end

	local dlg = ChoGGi_DlgExamine:new({}, terminal.desktop, params)

	-- update parent examine with new child
	if new_child_lock_dlg then
		parent.child_lock_dlg = dlg
	end

	return dlg
end

local OpenInExamineDlg = ChoGGi_Funcs.Common.OpenInExamineDlg
-- Mostly used for console rules, so we can get around it spamming the log
function OpenExamine(...)
	OpenInExamineDlg(...)
end
-- Returns the examine dialog
OpenExamineReturn = OpenInExamineDlg
-- short n sweet (only use in console/testing code, don't use in mods)
ex = OpenExamine
exr = OpenExamineReturn

-- Queue up stuff for examine (that happens before examine is ready)
local stored_objs = {}
local stored_objs_c = 0
function OnMsg.ClassesPostprocess()
	for i = 1, stored_objs_c do
		OpenInExamineDlg(table.unpack(stored_objs[i]))
	end
	table.iclear(stored_objs)
	stored_objs_c = 0
end
function OpenExamineDelayed(...)
	stored_objs_c = stored_objs_c + 1
	stored_objs[stored_objs_c] = {...}
end
