-- See LICENSE for terms

--~ ChoGGi_Funcs.Common.TickStart()
--~ ChoGGi_Funcs.Common.TickEnd()

local ChoGGi_Funcs = ChoGGi_Funcs
local blacklist = ChoGGi.blacklist
local testing = ChoGGi.testing
local what_game = ChoGGi.what_game

-- Strings.lua
local Translate = ChoGGi_Funcs.Common.Translate
local T = T

local pairs, tonumber, type, tostring = pairs, tonumber, type, tostring
local table, setmetatable = table, setmetatable
local AsyncRand = AsyncRand
local AveragePoint2D = AveragePoint2D
local box = box
local ClassDescendantsList = ClassDescendantsList
local FindNearestObject = FindNearestObject -- (list,obj) or (list,pos,filterfunc)
local GameTime = GameTime
local guic = guic
local IsBox = IsBox
local IsKindOf = IsKindOf
local IsPoint = IsPoint
local IsT = IsT
local IsValid = IsValid
local MapGet = MapGet
local Max = Max
local OpenDialog = OpenDialog
local point = point
local point20 = point20
local PropObjGetProperty = PropObjGetProperty
local ResumePassEdits = ResumePassEdits
local RGB = RGB
local SelectionGamepadObj = SelectionGamepadObj
local SelectionMouseObj = SelectionMouseObj
local Sleep = Sleep
local SuspendPassEdits = SuspendPassEdits
local ViewAndSelectObject = ViewAndSelectObject
local WaitMsg = WaitMsg
local XDestroyRolloverWindow = XDestroyRolloverWindow
local CmpLower = CmpLower


-- JA3 no likey
local GetMapSectorXY = GetMapSectorXY
local HexGetNearestCenter = HexGetNearestCenter
local HexGridGetObject = HexGridGetObject
local HexToWorld = HexToWorld
local IsInMapPlayableArea = IsInMapPlayableArea
local IsPointNearBuilding = IsPointNearBuilding
local UseGamepadUI = UseGamepadUI
local ViewObjectMars = ViewObjectMars
local WorldToHex = WorldToHex


-- Remove some log spam on older versions
local is_gp = ChoGGi.is_gp
local GetBuildableGrid = not is_gp and GetBuildableGrid
local GetObjectHexGrid = not is_gp and GetObjectHexGrid
local GetCursorWorldPos = not is_gp and GetCursorWorldPos or function()
	return UseGamepadUI() and GetTerrainGamepadCursor() or GetTerrainCursor()
end

local g_CObjectFuncs = g_CObjectFuncs

local InvalidPos = ChoGGi.Consts.InvalidPos

local g_env = _G
local rawget, getmetatable = rawget, getmetatable
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	g_env = env
	-- make sure we use the actual funcs if we can
	rawget = env.rawget
	getmetatable = env.getmetatable
	blacklist = false
end

-- "table.table.table.etc" try to find and return "etc" as actual object (default starts from _G)
-- Use .number for index based tables ("terminal.desktop.1.box")
-- root is where we start looking (defaults to _G).
-- create is a boolean to add tables if the path .name is absent.
--[[
DotPathToObject("terminal.desktop")
DotPathToObject("SnapToTarget", TunnelConstructionController)
]]
local function DotPathToObject(dot_path, root, create)

	-- parent always starts out as "root"
	local parent = root or g_env

	-- https://www.lua.org/pil/14.1.html
	-- [] () + ? . act like regexp ones
	-- % escape special chars
	-- ^ complement of the match (the "opposite" of the match)
	local matches = dot_path:gmatch("([^%.]+)(.?)")
	for name, match in matches do
		-- If dot_path included .number we need to make it a number or [name] won't work
		local num = tonumber(name)
		if num then
			name = num
		end

		-- rawget == Workaround for "Attempt to use an undefined global" msg the devs added
		local obj_child = root and parent[name] or rawget(parent, name)

		-- . means we're not at the end yet
		if match == "." then
			-- We're not adding a new table, and there's no match
			if not obj_child and not create then
				-- Our treasure hunt is cut short, so return nadda
				return false
			end
			-- Change the parent to the child (create table if absent, this'll only fire when create)
			parent = obj_child or {}
		else
			-- No more . so we return as conquering heroes with the obj
			return obj_child
		end

	end
end
ChoGGi_Funcs.Common.DotPathToObject = DotPathToObject

-- ChoGGi_Funcs.Common.RetName_lookup_table()
do -- RetName
	local DebugGetInfo = ChoGGi_Funcs.Common.DebugGetInfo
	local IsT = IsT
	local missing_text = ChoGGi.Temp.missing_text
	local TMeta = TMeta
	local TConcatMeta = TConcatMeta

	local g = _G
	-- we use this table to display names of objects for RetName
	if not rawget(g, "ChoGGi_lookup_names") then
		g.ChoGGi_lookup_names = {}
	end
	local lookup_table = g.ChoGGi_lookup_names

	local function AddFuncToList(key, value, name)
		if not lookup_table[value] then

			if type(value) == "function" then
				if DebugGetInfo(value) == "[C](-1)" then
					lookup_table[value] = name .. "." .. key .. " *C"
				else
					lookup_table[value] = name .. "." .. key
				end
			end
		end
	end

	do -- add stuff we can add now
		lookup_table = g.ChoGGi_lookup_names or {}
		local function AddFuncsUserData(meta, name)
			for key, value in pairs(meta) do
				AddFuncToList(key, value, name)
			end
		end
		-- some userdata funcs
		local userdata_tables = {
			range = __range_meta,
			set = getmetatable(set()),
			pstr = getmetatable(pstr()),
			grid = getmetatable(NewGrid(0, 0, 1)),
			point = getmetatable(point20),
			box = getmetatable(empty_box),
		}
		if what_game == "Mars" then
			userdata_tables.TaskRequest = Request_GetMeta()
			userdata_tables.quaternion = getmetatable(quaternion(point20, 0))
			userdata_tables.RandState = getmetatable(RandState())
			userdata_tables.xmgrid = getmetatable(grid(0, 0))
		end

		for name, meta in pairs(userdata_tables) do
			AddFuncsUserData(meta, name)
		end
	end -- do

	local function AddFuncs(name)
		local list
		if name:find("%.") then
			list = DotPathToObject(name)
		else
			list = g_env[name]
		end
		if not list then
			return
		end

		for key, value in pairs(list) do
			AddFuncToList(key, value, name)
		end
	end
--~ 	local func_tables = {
--~ 		"g_CObjectFuncs", "camera", "camera3p", "cameraMax", "cameraRTS",
--~ 		"pf", "string", "table", "UIL", "editor",
--~ 		"terrain", "terminal", "TFormat", "XInput",
--~ 	}
--~ 	if what_game == "Mars" then
--~ 		func_tables[#func_tables+1] = "DTM"
--~ 		func_tables[#func_tables+1] = "srp"
--~ 	end

--~ 	for i = 1, #func_tables do
--~ 		AddFuncs(func_tables[i])
--~ 	end

	local values_lookup = {
		"title",
		"Title",
		"ActionName",
		"encyclopedia_id",
		"id",
		"Id",
		"ActionId",
		"template_name",
		"template_class",
		"__class",
		"__template",
		"template",
		"__mtl",
		"text",
		"value",
		"name",
		-- most stuff has a class
		"class",
	}

	do -- stuff we need to be in-game for
		local function AddFuncsChoGGi(name, skip)
			local list = ChoGGi_Funcs[name]
			for key, value in pairs(list) do
				if not lookup_table[value] then
					if skip then
						lookup_table[value] = key
					else
						lookup_table[value] = "ChoGGi_Funcs." .. name .. "." .. key
					end
				end
			end
		end

		local function BuildNameList(update_trans)
			local g = _G

			lookup_table = ChoGGi_lookup_names or {}
			-- Emergency Lua GC fix (thanks Tremualin)
			table.clear(lookup_table)

			-- Manually add a few
			for i = 1, 999 do
				-- .. "" make sure they're strings (.. "" is faster than tostring)
				lookup_table[i] = i .. ""
			end
			lookup_table[0] = "0"
			lookup_table[-3] = "-3"
			lookup_table[_G] = "_G"
			lookup_table[g.empty_func] = "empty_func"
			lookup_table[g.terminal.desktop] = "terminal.desktop"

			-- I was calling these too early, so they mostly showed up as [C](-1)
			local func_tables = {
				"lfs", "debug", "coroutine", "lpeg", "io", "os", "package",
				"package.searchers", "camera", "camera3p", "cameraMax",
				"cameraRTS", "pf", "string", "table", "UIL", "editor", "terminal",
				"XInput",
			}
			if what_game == "Mars" then
				func_tables[#func_tables+1] = "DTM"
				func_tables[#func_tables+1] = "srp"
			end

			for i = 1, #func_tables do
				AddFuncs(func_tables[i])
			end

			-- ECM func names (some are added by ecm, so we want to update list when it's called again)
			func_tables = {
				"Common", "Console", "InfoPane", "Menus", "Settings",
			}
			for i = 1, #func_tables do
				AddFuncsChoGGi(func_tables[i])
			end
			AddFuncsChoGGi("Original", true)

			for key, value in pairs(g.ChoGGi) do
				if not lookup_table[value] then
					if type(value) == "table" then
						lookup_table[value] = "ChoGGi." .. key
					end
				end
			end

			-- any tables/funcs in _G
			for key, value in pairs(g) do
				-- no need to add tables already added
				if not lookup_table[value] then
					local t = type(value)
					if t == "table" or t == "userdata" then
						lookup_table[value] = key
					elseif t == "function" then
						if DebugGetInfo(value) == "[C](-1)" then
							lookup_table[value] = key .. " *C"
						else
							lookup_table[value] = key
						end
					end
				end
			end

			-- and any g_Classes funcs
			for class_id, class_obj in pairs(g.g_Classes) do
--~ 				if blacklist then
					local g_value = rawget(g, class_id)
--~ 					local g_value = g_env[class_id]
					if g_value then
						lookup_table[g_value] = class_id
					end
--~ 				end
				for key, value in pairs(class_obj) do
					-- why it has a false is beyond me (something to do with that object[true] = userdata?)
					if key ~= false and not lookup_table[value] then
						if type(value) == "function" then
							local name = DebugGetInfo(value)
							if name == "[C](-1)" then
								lookup_table[value] = key .. " *C"
							else
								-- need to reverse string so it finds the last /, since find looks ltr
								local slash = name:reverse():find("/")
								if slash then
									-- Unit.lua(75),Unit:MoveSleep()
--~ 									lookup_table[value] = name:sub(-slash + 1) .. "," .. class_id .. ":" .. key .. "()"
									-- Unit.lua(75),MoveSleep()
									lookup_table[value] = name:sub(-slash + 1) .. "," .. key .. "()"
								else
									-- the name'll be [string ""](8):
									lookup_table[value] = "string():" .. key
								end

							end
						end
					end
				end
			end

			-- Presets
			for preset_id, preset in pairs(g.Presets) do
				lookup_table[preset] = "Presets." .. preset_id
				for id, item in pairs(preset) do
					lookup_table[item] = "Presets." .. preset_id .. "." .. id
				end
			end
			-- eh?
			g.ClassDescendantsList("Preset", function(_, cls)
				if cls.GlobalMap and cls.GlobalMap ~= "" then
					local g_value = rawget(g, cls.GlobalMap)
--~ 					local g_value = g_env[cls.GlobalMap]
					if g_value then
						-- only needed for blacklist, but whatever it's quick
						lookup_table[g_value] = cls.GlobalMap

						for k, v in pairs(g_value) do
							if update_trans or not lookup_table[v] then
								if v.name and v.name ~= "" then
									lookup_table[v] = Translate(v.name)
								elseif v.display_name and v.display_name ~= "" then
									lookup_table[v] = Translate(v.display_name)
								else
									lookup_table[v] = k
								end
							end
						end
					end

				end
			end)

				lookup_table[g.g_Classes] = "g_Classes"
				if what_game == "Mars" then
					for i = 1, #g.GlobalVars do
						local var = g.GlobalVars[i]
						local obj = g_env[var]
						if not lookup_table[obj] then
							lookup_table[obj] = var
						end
				end
			end

			if not blacklist then
				local registry = g_env.debug.getregistry()
				local name = "debug.getregistry()"
				for key, value in pairs(registry) do
					local t = type(value)
					if t == "function" then
						AddFuncToList(key, value, name)
					elseif t == "table" then
						-- we get _G later
						if value ~= g then
							for key2, value2 in pairs(value) do
								if type(key) ~= "number" then
									AddFuncToList(key2, value2, key)
								end
							end
						end
					end
				end
			end

		end -- BuildNameList

		-- so they work in the main menu
		BuildNameList()

		-- called from onmsgs for citystart/loadgame
		ChoGGi_Funcs.Common.RetName_Update = BuildNameList

		if ChoGGi.testing then
			function ChoGGi_Funcs.Common.RetName_lookup_table()
				return lookup_table
			end
		end
	end -- do

	-- try to return a decent name for the obj, failing that return a string
	function ChoGGi_Funcs.Common.RetName(obj)

		-- booleans and nil are easy enough
		if not obj then
			return obj == false and "false" or "nil"
		elseif obj == true then
			return "true"
		end

		-- Got me...
		if obj == g_LastBuildItem then
			return g_LastBuildItem
		end

		-- any of the _G tables
		local lookuped = lookup_table[obj]
		if lookuped then
			return lookuped
		end

		local name
		local obj_type = type(obj)

		if obj_type == "string" then
			return obj
		elseif obj_type == "number" or obj_type == "boolean" then
			return tostring(obj)

		elseif obj_type == "table" then
			-- cities
			if IsKindOf(obj, "City") and obj.map_id ~= "" then
				return Translate(302535920001700--[[Map]]) .. ": " .. obj.map_id
			end

			-- we check in order of less generic "names"
--~ 			local name_type = rawget(obj, "name") and type(obj.name)
			local name_type = type(obj.name)

			-- custom name from user (probably)
			if name_type == "string" and obj.name ~= "" then
				name = obj.name
			-- colonist names
			elseif name_type == "table" then
				name = Translate(obj.name)

			-- display
--~ 			elseif rawget(obj, "display_name") and obj.display_name ~= "" then
			elseif obj.display_name and obj.display_name ~= "" then
				if TGetID(obj.display_name) == 9 --[[Anomaly]] then
					name = obj.class
				else
					name = Translate(obj.display_name)
				end
			else
				-- we need to use rawget to check (seems more consistent then rawget), as some stuff like mod.env uses the metatable from _G.__index and causes sm to log an error msg
				local index = getmetatable(obj)
				index = index and index.__index

				for i = 1, #values_lookup do
					local value_name = values_lookup[i]
--~ 					if index and rawget(obj, value_name) or not index and obj[value_name] then
					if index and obj[value_name] or not index and obj[value_name] then
						local value = obj[value_name]
						if value ~= "" then
							name = value
							break
						end
					end
				end
				--

				local meta = getmetatable(name)
				if meta == TMeta or meta == TConcatMeta or type(name) == "userdata" then
					name = Translate(name)
				end
--~ 				if not name and rawget(obj, "GetDisplayName") then
				if not name and obj.GetDisplayName then
					name = Translate(obj:GetDisplayName())
				end

			end -- If

		elseif obj_type == "userdata" then
			if IsT(obj) then
				local trans_str = Translate(obj)
				-- missing text is from internaltranslate, i check the str length before calling the func as it has to be at least 16 chars
				if trans_str == missing_text then
					return tostring(obj)
				end
				return trans_str
			else
				return tostring(obj)
			end

		elseif obj_type == "function" then
			return DebugGetInfo(obj)

		end -- if obj_type ==

		-- just in case...
		return type(name) == "string" and name or tostring(name or obj)
	end
end -- do
local RetName = ChoGGi_Funcs.Common.RetName

local function IsValidXWin(win)
	-- function XFlashWindow()
	-- last checked 1011030
	if win and (win.window_state ~= "destroying" and (win.interaction_box or win.box)) then
		return true
	end
end
ChoGGi_Funcs.Common.IsValidXWin = IsValidXWin

-- Copied in Fix Bugs
function ChoGGi_Funcs.Common.GetCityLabels(label)
	local UIColony = UIColony
	local labels = UIColony and UIColony.city_labels.labels or UICity.labels
	return labels[label] or empty_table
end
local GetCityLabels = ChoGGi_Funcs.Common.GetCityLabels

function ChoGGi_Funcs.Common.RetIcon(obj)
	-- most icons
	if obj.display_icon and obj.display_icon ~= "" then
		return obj.display_icon

	elseif obj.pin_icon and obj.pin_icon ~= "" then
		-- colonist
		return obj.pin_icon

	else
		-- generic icon (and scale as it isn't same size as the usual icons)
		return "UI/Icons/console_encyclopedia.tga", 150
	end
end

function ChoGGi_Funcs.Common.RetHint(obj)
	if type(obj.description) == "userdata" then
		return obj.description

	elseif obj.GetDescription then
		return obj:GetDescription()

	else
		-- eh
		return T(302535920001726--[[NONE]])
	end
end

local function GetParentOfKind(win, cls)
	while win and not win:IsKindOf(cls) do
		win = win.parent
	end
	return win
end
ChoGGi_Funcs.Common.GetParentOfKind = GetParentOfKind

do -- ImageExts
	-- easier to keep them in one place
	local ext_list = {
		dds = true,
		tga = true,
		png = true,
		jpg = true,
		jpeg = true,
	}
	-- ImageExts()[str:sub(-3):lower()]
	function ChoGGi_Funcs.Common.ImageExts()
		return ext_list
	end
end -- do
local ImageExts = ChoGGi_Funcs.Common.ImageExts

do -- ValidateImage
	local Measure = UIL.MeasureImage

	function ChoGGi_Funcs.Common.ValidateImage(image)
		if not image then
			return
		end

		-- UIL.MeasureImage can crash if you send it a line of text with a <> and probably others
		if not ImageExts()[string.sub(image, -3):lower()] then
			return
		end

		local x, y = Measure(image)
		if x > 0 and y > 0 then
			return image
		end
	end
end
local ValidateImage = ChoGGi_Funcs.Common.ValidateImage

-- notification thing
do -- MsgPopup
	local temp_params = {}

	-- shows a popup msg with the rest of the notifications
	-- params:
	-- params.objects can be a single obj, or {obj1, obj2, ...}
	-- expiration in ms or -1
	-- size = true = long width
	-- cycle_objs indexed table of in-game objs
	-- callback func to call when left clicked (fires with args: c_obj,cycle_obj,dlg)

	function ChoGGi_Funcs.Common.MsgPopup(text, title, params)
		-- notifications only show up in-game (UI stuff is missing)
		if not UIColony then
			return
		end

		local ChoGGi = ChoGGi
		if not ChoGGi.Temp.MsgPopups then
			ChoGGi.Temp.MsgPopups = {}
		end

		if not params then
			table.clear(temp_params)
			params = temp_params
		end

		-- how many ms it stays open for
		if not params.expiration then
--~ 			params.expiration = -1,
			params.expiration = 10
			if params.size then
				params.expiration = 25
			end
		end
		-- change to ticks (seconds)
		if params.expiration > -1 then
			params.expiration = params.expiration * 1000
		end

--~ 		-- close on left click
--~ 		params.close_on_read = true
--~ 		-- close on right click
--~ 		params.dismissable = false

		-- If there's no interface then we probably shouldn't open the popup
		local dlg = Dialogs.OnScreenNotificationsDlg
		if not dlg then
			local igi = Dialogs.InGameInterface
			if not igi then
				return
			end
			dlg = OpenDialog("OnScreenNotificationsDlg", igi)
		end

		local preset = {
			id = "popup" .. AsyncRand() .. ActiveMapID,
			title = type(title) == "number" and tostring(title) or title or "",
			text = type(text) == "number" and tostring(text) or text or T(302535920001726--[[NONE]]),
			image = params.image and ValidateImage(params.image) or ChoGGi.library_path .. "UI/TheIncal.png",
		}

		table.set_defaults(preset, params)
		table.set_defaults(preset, OnScreenNotificationPreset)

		-- click icon to view obj
		if params.objects then
			-- If it's a single obj
			if IsValid(params.objects) then
				params.cycle_objs = {params.objects}
			else
				params.cycle_objs = params.objects
			end
		end

		-- needed in Sagan update
		local aosn = g_ActiveOnScreenNotifications
		local idx = table.find(aosn, 1, preset.id) or #aosn + 1
		aosn[idx] = {preset.id}

		-- and show the popup
		CreateRealTimeThread(function()
			local popup = OnScreenNotification:new({}, dlg.idNotifications)
			popup:FillData(preset.id, preset, params.callback, params, params.cycle_objs)
			popup:Open()
			dlg:ResolveRelativeFocusOrder()
			ChoGGi.Temp.MsgPopups[#ChoGGi.Temp.MsgPopups+1] = popup

			-- wide amount of text option
			if params.size then
				local frame = GetParentOfKind(popup.idText, "XFrame")
				if frame then
					frame:SetMaxWidth(params.max_width or 1000)
				end
--~ 				popup.idText:SetMaxHeight(params.max_height or 250)
			end

		end)
		-- If we need the popup notification_id
		return preset.id
	end
end -- do
local MsgPopup = ChoGGi_Funcs.Common.MsgPopup

do -- ShowObj
	local OVector, OSphere

	-- we just use a few noticeable colours for rand
	local rand_colours = {
		green, yellow, cyan, white,
		-46777, -- lighter red than "red"
		-65369, -- pink
		-39680, -- slightly darker orange (don't want it blending in to the ground as much as -23296)
	}
	local function rand_c()
		-- local it to skip rand sending back the idx
		local colour = table.rand(rand_colours)
		return colour
	end
	ChoGGi_Funcs.Common.RandomColourLimited = rand_c

	local markers = {}
	function ChoGGi_Funcs.Common.RetObjMarkers()
		return markers
	end

	local function ClearMarker(k, v)
		v = v or markers[k]
		if IsValid(k) then
			if k.ChoGGi_ShowObjColour then
				k:SetColorModifier(k.ChoGGi_ShowObjColour)
				k.ChoGGi_ShowObjColour = nil
			elseif v == "vector" or k:IsKindOf("ChoGGi_OSphere") then
				k:delete()
			end
		end

		if IsValid(v) and v:IsKindOf("ChoGGi_OSphere") then
			v:delete()
		end

		markers[k] = nil
	end

	function ChoGGi_Funcs.Common.ClearShowObj(obj_or_bool)
		SuspendPassEdits("ChoGGi_Funcs.Common.ClearShowObj")

		-- any markers in the list
		if obj_or_bool == true then
			for k, v in pairs(markers) do
				ClearMarker(k, v)
			end
			table.clear(markers)
			ResumePassEdits("ChoGGi_Funcs.Common.ClearShowObj")
			return
		end

		-- try and clean up obj
		local is_valid = IsValid(obj_or_bool)
		local is_point = IsPoint(obj_or_bool)
		if is_valid or is_point then

			if is_valid then
				-- could be stored as obj ref or stringed pos ref
				local pos = is_valid and tostring(obj_or_bool:GetVisualPos())
				if markers[pos] or markers[obj_or_bool] or obj_or_bool.ChoGGi_ShowObjColour then
					ClearMarker(pos)
					ClearMarker(obj_or_bool)
				end
			elseif is_point then
				-- or just a point
				local pt_obj = is_point and tostring(obj_or_bool)
				if markers[pt_obj] then
					ClearMarker(pt_obj)
				end
			end
		end

--~ 		printC("overkill")
--~ 		-- overkill: could be from a saved game so remove any objects on the map (they shouldn't be left in a normal game)
--~ 		MapDelete(true, {"ChoGGi_OVector", "ChoGGi_OSphere"})
		ResumePassEdits("ChoGGi_Funcs.Common.ClearShowObj")
	end

	function ChoGGi_Funcs.Common.ColourObj(obj, colour)
		local is_valid = IsValid(obj)
		if not is_valid or is_valid and not obj:IsKindOf("ColorizableObject") then
			return
		end

		obj.ChoGGi_ShowObjColour = obj.ChoGGi_ShowObjColour or obj:GetColorModifier()
		markers[obj] = obj.ChoGGi_ShowObjColour
		obj:SetColorModifier(colour or rand_c())
		return obj
	end

	local function AddSphere(pt, colour, size)
		local pos = tostring(pt)
		if not IsValid(markers[pos]) then
			markers[pos] = nil
		end

		if markers[pos] then
			-- update with new colour
			markers[pos]:SetColor(colour)
		else
			local sphere = OSphere:new()
			sphere:SetPos(pt)
			sphere:SetRadius((size or 50) * guic)
			sphere:SetColor(colour)
			markers[pos] = sphere
		end
		return markers[pos]
	end

	function ChoGGi_Funcs.Common.ShowPoint(obj, colour, size)
		OSphere = OSphere or ChoGGi_OSphere
		colour = colour or rand_c()
		-- single pt
		if IsPoint(obj) and InvalidPos ~= obj then
			return AddSphere(obj, colour, size)
		end
		-- obj to pt
		if IsValid(obj) then
			local pt = obj:GetVisualPos()
			if IsValid(obj) and InvalidPos ~= pt then
				return AddSphere(pt, colour, size)
			end
		end

		-- two points
		if type(obj) ~= "table" then
			return
		end
		if IsPoint(obj[1]) and IsPoint(obj[2]) and InvalidPos ~= obj[1] and InvalidPos ~= obj[2] then
			OVector = OVector or ChoGGi_OVector
			local vector = OVector:new()
			vector:Set(obj[1], obj[2], colour or rand_c())
			markers[vector] = "vector"
			return vector
		end
	end

	-- marks pt of obj and optionally colours/moves camera
	local function ShowObj(obj, colour, skip_view, skip_colour)
		if markers[obj] then
			return markers[obj]
		end
		local is_valid = IsValid(obj)
		local is_point = IsPoint(obj)
		if not (is_valid or is_point) then
			return
		end
		OSphere = OSphere or ChoGGi_OSphere
		colour = colour or rand_c()
		local vis_pos = is_valid and obj:GetVisualPos()

		local pt = is_point and obj or vis_pos
		local sphere_obj
		if pt and pt ~= InvalidPos and not markers[pt] then
			sphere_obj = AddSphere(pt, colour)
		end

		if is_valid and not skip_colour then
			obj.ChoGGi_ShowObjColour = obj.ChoGGi_ShowObjColour or obj:GetColorModifier()
			markers[obj] = obj.ChoGGi_ShowObjColour
			obj:SetColorModifier(colour)
		end

		pt = pt or vis_pos
		if not skip_view and pt ~= InvalidPos then
			ViewObjectMars(pt)
		end

		return sphere_obj
	end
	ChoGGi_Funcs.Common.ShowObj = ShowObj
	-- I could add it to ShowObj, but too much fiddling
	function ChoGGi_Funcs.Common.ShowQR(q, r, ...)
		if not (q or r) then
			return
		end
		return ShowObj(point(HexToWorld(q, r)), ...)
	end

end -- do
local ShowPoint = ChoGGi_Funcs.Common.ShowPoint
local ShowObj = ChoGGi_Funcs.Common.ShowObj
local ColourObj = ChoGGi_Funcs.Common.ColourObj
local ClearShowObj = ChoGGi_Funcs.Common.ClearShowObj
local RandomColourLimited = ChoGGi_Funcs.Common.RandomColourLimited

function ChoGGi_Funcs.Common.PopupSubMenu(menu, name, item)
	local popup = menu.popup

	-- build the new one/open it
	local submenu = g_Classes.ChoGGi_XPopupList:new({
		Opened = true,
		Id = "ChoGGi_submenu_popup",
		popup_parent = popup,
		AnchorType = "smart",
		Anchor = menu.box,
	}, terminal.desktop)
	-- Item == opened from PopupBuildMenu
	if item then
		ChoGGi_Funcs.Common.PopupBuildMenu(item.submenu, submenu)
	else
		ChoGGi_Funcs.Common.PopupBuildMenu(submenu, popup)
	end
	submenu:Open()
	-- add it to the popup
	popup[name] = submenu
end

function ChoGGi_Funcs.Common.PopupBuildMenu(items, popup)
	local g_Classes = g_Classes
	--JA3
--~ 	local ViewObjectMars = ViewObjectMars
	local IsPoint = IsPoint

	local dark_menu = items.TextStyle == "ChoGGi_CheckButtonMenuOpp"
	for i = 1, #items do
		local item = items[i]

		if item.is_spacer then
			item.name = "~~~"
			item.disable = true
			item.centred = true
		end

		-- "ChoGGi_XCheckButtonMenu"
		local cls = g_Classes[item.class or "ChoGGi_XButtonMenu"]
		local button = cls:new({
			RolloverTitle = item.hint_title and item.hint_title or item.obj and RetName(item.obj) or T(302535920001717--[[Info]]),
			RolloverText = item.hint or "",
			RolloverHint = item.hint_bottom or T(302535920001718--[[<left_click> Activate]]),
			Text = item.name,
			Background = items.Background,
			PressedBackground = items.PressedBackground,
			FocusedBackground = items.FocusedBackground,
			TextStyle = item.disable and
				(dark_menu and "ChoGGi_ButtonMenuDisabled" or "ChoGGi_ButtonMenuDisabledDarker")
				or items.TextStyle or cls.TextStyle,
			HAlign = item.centred and "center" or "stretch",

			popup = popup,
		}, popup.idContainer)

		if items.IconPadding then
			button.idIcon:SetPadding(items.IconPadding)
		end

		if item.disable then
			button.idLabel.RolloverTextColor = button.idLabel.TextColor
			button.RolloverBackground = items.Background
			button.PressedBackground = items.Background
			button.RolloverZoom = g_Classes.XWindow.RolloverZoom
			button.MouseCursor = "UI/Cursors/cursor.tga"
		end

		if item.image then
			button.idIcon:SetImage(item.image)
			if item.image_scale then
				button.idIcon:SetImageScale(IsPoint(item.image_scale) and item.image_scale or point(item.image_scale, item.image_scale))
			end
		end

		if item.clicked then
			function button.OnPress(...)
				cls.OnPress(...)
				item.clicked(item, ...)
				popup:Close()
			end
		-- "disable" stops the menu from closing when clicked
		elseif not item.disable then
			function button.OnPress(...)
				cls.OnPress(...)
				popup:Close()
			end
		end

		if item.mouseup then
			function button:OnMouseButtonUp(pt, button, ...)
				cls.OnMouseButtonUp(self, pt, button, ...)
				-- make sure cursor was in button area when mouse released
				if pt:InBox2D(self.box) then
					item.mouseup(item, self, pt, button, ...)
					popup:Close()
				end
			end
		end

		-- checkboxes (with a value (naturally))
		if item.value then

			local is_vis
			local value = DotPathToObject(item.value)

			-- dlgConsole.visible i think? damn me and my lazy commenting
			if type(value) == "table" then
				if value.visible then
					is_vis = true
				end
			else
				if value then
					is_vis = true
				end
			end

			-- oh yeah, you toggle that check
			if is_vis then
				button:SetCheck(true)
			else
				button:SetCheck(false)
			end
		end

		local showobj_func
		if item.showobj then
			showobj_func = function()
				ClearShowObj(true)
				ShowObj(item.showobj, nil, true)
			end
		end

		local colourobj_func
		if item.colourobj then
			colourobj_func = function()
				ClearShowObj(true)
				ColourObj(item.colourobj)
			end
		end

		local pos_func
		if item.pos then
			pos_func = function()
				ViewObjectMars(item.pos)
			end
		end

		-- my ugly submenu hack
		local submenu_func
		if item.submenu then
			-- add the ...
			g_Classes.ChoGGi_XLabel:new({
				Dock = "right",
				text = "...",
				TextStyle = items.TextStyle or cls.TextStyle,
			}, button)

			local name = "ChoGGi_submenu_" .. item.name
			submenu_func = function(self)
				ChoGGi_Funcs.Common.PopupSubMenu(self, name, item)
			end
		end

		-- add our mouseenter funcs
		if item.mouseover or showobj_func or colourobj_func or pos_func or submenu_func then
			function button:OnMouseEnter(pt, child, ...)
				cls.OnMouseEnter(self, pt, child, ...)
				if showobj_func then
					showobj_func()
				end
				if colourobj_func then
					colourobj_func()
				end
				if pos_func then
					pos_func()
				end
				if item.mouseover then
					item.mouseover(self, pt, child, item, ...)
				end
				if submenu_func then
					submenu_func(self, pt, child, item, ...)
				end
			end

		end
	end
end

function ChoGGi_Funcs.Common.PopupToggle(parent, popup_id, items, anchor, reopen, submenu)
	local popup = terminal.desktop[popup_id]
	if popup then
		popup:Close()
		submenu = submenu or terminal.desktop.ChoGGi_submenu_popup
		if submenu then
			submenu:Close()
		end
	end

	if not parent then
		return
	end

	if not popup or reopen then
		local cls = ChoGGi_XPopupList

		items.Background = items.Background or cls.Background
		items.FocusedBackground = items.FocusedBackground or cls.FocusedBackground
		items.PressedBackground = items.PressedBackground or cls.PressedBackground

		popup = cls:new({
			Opened = true,
			Id = popup_id,
			AnchorType = anchor or "smart",
			-- "none", "drop", "drop-right", "smart", "left", "right", "top", "bottom", "center-top", "center-bottom", "mouse"
			Anchor = parent.box,
			Background = items.Background,
			FocusedBackground = items.FocusedBackground,
			PressedBackground = items.PressedBackground,
		}, terminal.desktop)

		popup.items = items

		ChoGGi_Funcs.Common.PopupBuildMenu(items, popup)

		-- when i send parent as a table with self and box coords
		parent = parent.ChoGGi_self or parent

		-- hide popup when parent closes
		CreateRealTimeThread(function()
			while IsValidXWin(popup) and IsValidXWin(parent) do
				Sleep(500)
			end
			popup:Close()
		end)

		popup:Open()

	end

	-- If we need to fiddle with it
	return popup
end

local function GetCursorOrGamePadSelectObj()
	return UseGamepadUI() and SelectionGamepadObj() or SelectionMouseObj()
end
ChoGGi_Funcs.Common.GetCursorOrGamePadSelectObj = GetCursorOrGamePadSelectObj

do -- Circle
	local OCircle

	-- show a circle for time and delete it
	function ChoGGi_Funcs.Common.Circle(pos, radius, colour, time, override_height)
		if not OCircle then
			OCircle = ChoGGi_OCircle
		end

		local circle = OCircle:new()
		if override_height then
			circle:SetPos(pos or GetCursorWorldPos())
		else
			circle:SetPos(pos and pos:SetTerrainZ(10 * guic) or GetCursorWorldPos())
		end

		circle:SetRadius(radius or 1000)
		circle:SetColor(colour or RandomColourLimited())

		CreateRealTimeThread(function()
			Sleep(time or 50000)
			if IsValid(circle) then
				circle:delete()
			end
		end)
	end

	-- show a sphere for time and delete it
	function ChoGGi_Funcs.Common.Sphere(pos, colour, time, override_height)
		local orb
		if override_height then
			orb = ShowPoint(pos or GetCursorWorldPos(), colour)
		else
			orb = ShowPoint(pos and pos:SetTerrainZ(10 * guic) or GetCursorWorldPos(), colour)
		end

		CreateRealTimeThread(function()
			Sleep(time or 50000)
			if IsValid(orb) then
				orb:delete()
			end
		end)
	end
end -- do
local Sphere = ChoGGi_Funcs.Common.Sphere

function ChoGGi_Funcs.Common.PlacePolyline(points, colours, set_default_pos)
	local line = ChoGGi_OPolyline:new{
		max_vertices = #points
	}
	line:SetMesh(points, colours)
	-- objects spawn off-map
	if set_default_pos then
		line:SetPos(AveragePoint2D(line.vertices))
	end
	return line
end
local PlacePolyline = ChoGGi_Funcs.Common.PlacePolyline

-- this is a question box without a question (WaitPopupNotification only works in-game, not main menu)
function ChoGGi_Funcs.Common.MsgWait(text, title, image, ok_text, context, parent, template, thread)
	-- thread needed for WaitMarsMsg
	if not CurrentThread() and thread ~= "skip" then
		return CreateRealTimeThread(ChoGGi_Funcs.Common.MsgWait, text, title, image, ok_text, context, parent, template, "skip")
	end

	if UIColony then
		PauseGame()
	end

--~ function CreateMarsMessageBox(caption, text, ok_text, parent, image, context, template)
	CreateMarsMessageBox(
		type(title) == "number" and tostring(title) or title or T(302535920001726--[[Title]]),
		type(text) == "number" and tostring(text) or text or T(302535920001727--[[NONE]]),
		type(ok_text) == "number" and tostring(ok_text) or ok_text,
		parent,
		image and ValidateImage(image) or ChoGGi.library_path .. "UI/message_picture_01.png",
		context, template
	)
	if UIColony then
		ResumeGame()
	end
end


-- well that's the question isn't it?
function ChoGGi_Funcs.Common.QuestionBox(text, func, title, ok_text, cancel_text, image, context, parent, template, thread)
	-- thread needed for WaitMarsQuestion
	if not CurrentThread() and thread ~= "skip" then
		return CreateRealTimeThread(ChoGGi_Funcs.Common.QuestionBox, text, func, title, ok_text, cancel_text, image, context, parent, template, "skip")
	end

	if not image then
		image = ChoGGi.library_path .. "UI/message_picture_01.png"
	end

	if WaitMarsQuestion(
		parent,
		type(title) == "number" and tostring(title) or title or T(302535920001726--[[Title]]),
		type(text) == "number" and tostring(text) or text or T(302535920001727--[[NONE]]),
		type(ok_text) == "number" and tostring(ok_text) or ok_text,
		type(cancel_text) == "number" and tostring(cancel_text) or cancel_text,
		image and ValidateImage(image) or ChoGGi.library_path .. "UI/message_picture_01.png",
		context, template
	) == "ok" then
		if func then
			func(true, context)
		end
		return "ok"
	else
		-- user canceled / closed it
		if func then
			func(false, context)
		end
		return "cancel"
	end

end

-- positive or 1 return TrueVar || negative or 0 return FalseVar
-- ChoGGi.Consts.X = ChoGGi_Funcs.Common.NumRetBool(ChoGGi.Consts.X, 0, ChoGGi.Consts.X)
function ChoGGi_Funcs.Common.NumRetBool(num, true_var, false_var)
	if type(num) ~= "number" then
		return
	end
	local bool = true
	if num < 1 then
		bool = false
	end
	return bool and true_var or false_var
end

-- return opposite value or first value if neither
function ChoGGi_Funcs.Common.ValueRetOpp(setting, value1, value2)
	if setting == value1 then
		return value2
--~ 	elseif setting == value2 then
--~ 		return value1
	end
	return value1
end

-- return as num
function ChoGGi_Funcs.Common.BoolRetNum(bool)
	if bool == true then
		return 1
	end
	return 0
end

-- toggle 0/1
function ChoGGi_Funcs.Common.ToggleBoolNum(n)
	if n == 0 then
		return 1
	end
	return 0
end

-- toggle true/nil (so it doesn't add setting to file as = false
function ChoGGi_Funcs.Common.ToggleValue(value)
	if value then
		return
	end
	return true
end

-- return equal or higher amount
function ChoGGi_Funcs.Common.CompareAmounts(a, b)
	--if ones missing then just return the other
	if not a then
		return b
	elseif not b then
		return a
	-- else return equal or higher amount
	elseif a >= b then
		return a
	elseif b >= a then
		return b
	end
end

--[[
table.sort(s.command_centers, function(a, b)
	return ChoGGi_Funcs.Common.CompareTableFuncs(a, b, "GetDist2D", s)
end)
]]
function ChoGGi_Funcs.Common.CompareTableFuncs(a, b, func, obj)
	if not a and not b then
		return
	end
	if obj then
		return obj[func](obj, a) < obj[func](obj, b)
	else
		return a[func](a, b) < b[func](b, a)
	end
end

-- check for and remove broken objects from *city.labels
function ChoGGi_Funcs.Common.RemoveMissingLabelObjects(label)
	local list = GetCityLabels(label)
	for i = #list, 1, -1 do
		if not IsValid(list[i]) then
			table.remove(city.labels[label], i)
		end
	end
end

function ChoGGi_Funcs.Common.RemoveMissingTableObjects(list, obj)
	if obj then
		for i = #list, 1, -1 do
			if #list[i][list] == 0 then
				table.remove(list, i)
			end
		end
	else
		for i = #list, 1, -1 do
			if not IsValid(list[i]) then
				table.remove(list, i)
			end
		end
	end
	return list
end

function ChoGGi_Funcs.Common.RemoveFromLabel(label, obj)
	local list = GetCityLabels(label)
	for i = #list, 1, -1 do
		if list[i] and list[i].handle and list[i] == obj.handle then
			table.remove(city.labels[label], i)
		end
	end
end

-- tries to convert "65" to 65, "boolean" to boolean, "nil" to nil, or just returns "str" as "str"
local function RetProperType(value)
	-- boolean
	if value == "true" or value == true then
		return true, "boolean"
	elseif value == "false" or value == false then
		return false, "boolean"
	end
	-- nil
	if value == "nil" then
		return nil, "nil"
	end
	-- number
	local num = tonumber(value)
	if num then
		return num, "number"
	end
	-- then it's a string (probably)
	return value, "string"
end
ChoGGi_Funcs.Common.RetProperType = RetProperType

do -- RetType
	-- used to check for some SM objects (Points/Boxes)
	if what_game == "Mars" then
		local IsQuaternion = IsQuaternion
		local IsRandState = IsRandState
		local IsGrid = IsGrid
		local IsPStr = IsPStr

		function ChoGGi_Funcs.Common.RetType(obj)
			if getmetatable(obj) then
				if IsPoint(obj) then
					return "Point"
				end
				if IsBox(obj) then
					return "Box"
				end
				if IsQuaternion(obj) then
					return "Quaternion"
				end
				if IsRandState(obj) then
					return "RandState"
				end
				if IsGrid(obj) then
					return "Grid"
				end
				if IsPStr(obj) then
					return "PStr"
				end
			end
			return type(obj)
		end
	else -- JA3
		local IsQuaternion = IsQuaternion
		local IsPStr = IsPStr

		function ChoGGi_Funcs.Common.RetType(obj)
			if getmetatable(obj) then
				if IsPoint(obj) then
					return "Point"
				end
				if IsBox(obj) then
					return "Box"
				end
				if IsQuaternion(obj) then
					return "Quaternion"
				end
				if IsPStr(obj) then
					return "PStr"
				end
			end
			return type(obj)
		end
	end
end -- do

-- takes "example1 example2" and returns {[1] = "example1", [2] = "example2"}
function ChoGGi_Funcs.Common.StringToTable(str)
	local temp = {}
	for i in str:gmatch("%S+") do
		temp[i] = i
	end
	return temp
end

function ChoGGi_Funcs.Common.SetConsts(id, value)
	-- we only want to change it if user set value
	if value then
		-- some mods check Consts or g_Consts, so we'll just do both to be sure
		Consts[id] = value
		if g_Consts then
			g_Consts[id] = value
		end
	end
end
-- obsolete
ChoGGi_Funcs.Common.SetConstsG = ChoGGi_Funcs.Common.SetConsts

function ChoGGi_Funcs.Common.SetPropertyProp(obj, prop_id, value_id, value)
	if not obj or obj and not obj:IsKindOf("PropertyObject") then
		return
	end

	local props = obj.properties
	local idx = table.find(props, "id", prop_id)
	if not idx then
		return
	end

	props[idx][value_id] = value
end

-- If value is the same as stored then make it false instead of default value, so it doesn't apply next time
function ChoGGi_Funcs.Common.SetSavedConstSetting(setting, value)
	value = value or const[setting] or Consts[setting]
	local ChoGGi = ChoGGi
	-- If setting is the same as the default then remove it
	if ChoGGi.Consts[setting] == value then
		ChoGGi.UserSettings[setting] = nil
	else
		ChoGGi.UserSettings[setting] = value
	end
end

do -- TableCleanDupes
	local dupe_t = {}
	local temp_t = {}
	function ChoGGi_Funcs.Common.TableCleanDupes(list)
		local c = 0

		-- quicker to make a new list on large tables
		if list[10000] then
			dupe_t = {}
			temp_t = {}
		else
			table.iclear(temp_t)
			table.clear(dupe_t)
		end

		for i = 1, #list do
			local item = list[i]
			if not dupe_t[item] then
				c = c + 1
				temp_t[c] = item
				dupe_t[item] = true
			end
		end

		-- Instead of returning a new table we clear the old and add the values
		table.iclear(list)
		for i = 1, #temp_t do
			list[i] = temp_t[i]
		end
	end
end -- do

-- ChoGGi_Funcs.Common.RemoveFromTable(sometable, "class", "SelectionArrow")
function ChoGGi_Funcs.Common.RemoveFromTable(list, cls, text)
	if type(list) ~= "table" then
		return empty_table
	end
	local tempt = {}
	local c = 0

	list = list or ""
	for i = 1, #list do
		if list[i][cls] ~= text then
			c = c + 1
			tempt[c] = list[i]
		end
	end
	return tempt
end

-- ChoGGi_Funcs.Common.FilterFromTable(MainCity.labels.Building, {ParSystem = true, ResourceStockpile = true}, nil, "class")
-- ChoGGi_Funcs.Common.FilterFromTable(MainCity.labels.Unit, nil, nil, "working")
function ChoGGi_Funcs.Common.FilterFromTable(list, exclude_list, include_list, name)
	if type(list) ~= "table" then
		return {}
	end
	return MapFilter(list, function(o)
		if exclude_list or include_list then
			if exclude_list and include_list then
				if not exclude_list[o[name]] then
					return true
				elseif include_list[o[name]] then
					return true
				end
			elseif exclude_list then
				if not exclude_list[o[name]] then
					return true
				end
			elseif include_list then
				if include_list[o[name]] then
					return true
				end
			end
		else
			if o[name] then
				return true
			end
		end
	end)
end

-- ChoGGi_Funcs.Common.FilterFromTableFunc(MainCity.labels.Building, "IsKindOf", "Residence")
-- ChoGGi_Funcs.Common.FilterFromTableFunc(MainCity.labels.Unit, "IsValid", nil, true)
function ChoGGi_Funcs.Common.FilterFromTableFunc(list, func, value, is_bool)
	if type(list) ~= "table" then
		return {}
	end
	return MapFilter(list, function(o)
		if is_bool then
			if g_env[func](o) then
				return true
			end
		elseif o[func](o, value) then
			return true
		end
	end)
end

-- return a string setting/text for menus
function ChoGGi_Funcs.Common.SettingState(setting, text)
	if type(setting) == "string" and setting:find("%.") then
		-- some of the menu items passed are "table.table.exists?.setting"
		local obj = DotPathToObject(setting)
		if obj then
			setting = obj
		else
			setting = false
		end
	end

	-- we want it to return false instead of nil
	if type(setting) == "nil" then
		setting = false
	end

	if text then
		if setting then
			return "<color ChoGGi_green>" .. tostring(setting) .. "</color>: " .. text
		else
			return "<color ChoGGi_red>" .. tostring(setting) .. "</color>: " .. text
		end
	end

	return tostring(setting)
end

-- get all objects, then filter for ones within *radius*, returned sorted by dist, or *sort* for name
-- OpenExamine(ReturnAllNearby(1000, "class"))
function ChoGGi_Funcs.Common.ReturnAllNearby(radius, sort, pt)
	radius = radius or 5000
	pt = pt or GetCursorWorldPos()

	-- get all objects within radius
	local list = MapGet(pt, radius)

	-- sort list custom
	if sort then
		table.sort(list, function(a, b)
			return a[sort] < b[sort]
		end)
	else
		-- sort nearest
		table.sort(list, function(a, b)
			return a:GetVisualDist2D(pt) < b:GetVisualDist2D(pt)
		end)
	end

	return list
end

 -- RetObjectAtPos/RetObjectsAtPos
if what_game == "Mars" then
	local HexGridGetObject = HexGridGetObject
	local HexGridGetObjects = HexGridGetObjects

	-- q can be pt or q
	function ChoGGi_Funcs.Common.RetObjectAtPos(q, r)
		if not r then
			q, r = WorldToHex(q)
		end
		return HexGridGetObject(ActiveGameMap.object_hex_grid.grid, q, r)
	end

	function ChoGGi_Funcs.Common.RetObjectsAtPos(q, r)
		if not r then
			q, r = WorldToHex(q)
		end
		return HexGridGetObjects(ActiveGameMap.object_hex_grid.grid, q, r)
	end
end -- do

function ChoGGi_Funcs.Common.RetSortTextAssTable(list, for_type)
	local temp_table = {}
	local c = 0
	list = list or empty_table

	-- add
	if for_type then
		for k in pairs(list) do
			c = c + 1
			temp_table[c] = k
		end
	else
		for _, v in pairs(list) do
			c = c + 1
			temp_table[c] = v
		end
	end

	-- and send back sorted
	table.sort(temp_table)
	return temp_table
end

do -- Ticks
	local times = {}
	local GetPreciseTicks = GetPreciseTicks
	local max_int = max_int

	local function TickStart(id)
		if not id then
			id = "temp"
		end
		times[id] = GetPreciseTicks()
	end
	local function TickEnd(id, name)
		if not id then
			id = "temp"
		end
		print(id, ":", GetPreciseTicks() - (times[id] or max_int), name)
		times[id] = nil
	end
	ChoGGi_Funcs.Common.TickStart = TickStart
	ChoGGi_Funcs.Common.TickEnd = TickEnd

	function ChoGGi_Funcs.Common.PrintFuncTime(func, ...)
		local id = "PrintFuncTime " .. AsyncRand()
		local varargs = {...}
		pcall(function()
			TickStart(id)
			func(table.unpack(varargs))
			TickEnd(id)
		end)
	end
end -- do

function ChoGGi_Funcs.Common.UpdateDataTablesCargo()
	if what_game ~= "Mars" then
		return
	end

	local Tables = ChoGGi.Tables

	-- update cargo resupply
	table.clear(Tables.Cargo)
	local ResupplyItemDefinitions = ResupplyItemDefinitions or ""
	for i = 1, #ResupplyItemDefinitions do
		local def = ResupplyItemDefinitions[i]
		Tables.Cargo[i] = def
		Tables.Cargo[def.id] = def
	end

	local settings = ChoGGi.UserSettings.CargoSettings or empty_table
	for id, cargo in pairs(settings) do
		local cargo_table = Tables.Cargo[id]
		if cargo_table then
			if cargo.pack then
				cargo_table.pack = cargo.pack
			end
			if cargo.kg then
				cargo_table.kg = cargo.kg
			end
			if cargo.price then
				cargo_table.price = cargo.price
			end
			if type(cargo.locked) == "boolean" then
				cargo_table.locked = cargo.locked
			end
		end
	end
end

do -- UpdateDataTables
	-- I should look around for a way
	local mystery_images = {
		MarsgateMystery = "UI/Messages/marsgate_mystery_01.tga",
		BlackCubeMystery = "UI/Messages/power_of_three_mystery_01.tga",
		LightsMystery = "UI/Messages/elmos_fire_mystery_01.tga",
		AIUprisingMystery = "UI/Messages/artificial_intelligence_mystery_01.tga",
		UnitedEarthMystery = "UI/Messages/beyond_earth_mystery_01.tga",
		TheMarsBug = "UI/Messages/wildfire_mystery_01.tga",
		WorldWar3 = "UI/Messages/the_last_war_mystery_01.tga",
		MetatronMystery = "UI/Messages/metatron_mystery_01.tga",
		DiggersMystery = "UI/Messages/dredgers_mystery_01.tga",
		DreamMystery = "UI/Messages/inner_light_mystery_01.tga",
		CrystalsMystery = "UI/Messages/phylosophers_stone_mystery_01.tga",
		MirrorSphereMystery = "UI/Messages/sphere_mystery_01.tga",
	}

	local function UpdateProfile(preset,list)
		for id, preset_p in pairs(preset) do
			if id ~= "None" and id ~= "random" then
				list[id] = {}
				local profile = list[id]
				for key, value in pairs(preset_p) do
					profile[key] = value
				end
			end
		end
	end

	-- make copies of spon/comm profiles
	function ChoGGi_Funcs.Common.UpdateTablesSponComm()
		if what_game ~= "Mars" then
			return
		end

		local Tables = ChoGGi.Tables
		local Presets = Presets

		table.clear(Tables.Sponsors)
		table.clear(Tables.Commanders)
		UpdateProfile(Presets.MissionSponsorPreset.Default,Tables.Sponsors)
		UpdateProfile(Presets.CommanderProfilePreset.Default,Tables.Commanders)
	end

	function ChoGGi_Funcs.Common.UpdateDataTables()
		if what_game ~= "Mars" then
			return
		end

		local c

		local Tables = ChoGGi.Tables
		table.clear(Tables.CargoPresets)
		table.clear(Tables.ColonistAges)
		table.clear(Tables.ColonistBirthplaces)
		table.clear(Tables.ColonistGenders)
		table.clear(Tables.ColonistSpecializations)
		table.clear(Tables.Mystery)
		table.clear(Tables.NegativeTraits)
		table.clear(Tables.OtherTraits)
		table.clear(Tables.PositiveTraits)
		table.clear(Tables.Resources)
		Tables.SchoolTraits = const.SchoolTraits
		Tables.SanatoriumTraits = const.SanatoriumTraits

-- ----------- mysteries
		c = 0
		-- build mysteries list (sometimes we need to reference Mystery_1, sometimes BlackCubeMystery
		local g_Classes = g_Classes
		ClassDescendantsList("MysteryBase", function(class)
			local cls_obj = g_Classes[class]
			local scenario_name = cls_obj.scenario_name or T(302535920000009--[[Missing Scenario Name]])
			local display_name = Translate(cls_obj.display_name) or T(302535920000010--[[Missing Name]])
			local description = Translate(cls_obj.rollover_text) or T(302535920000011--[[Missing Description]])

			local temptable = {
				class = class,
				number = scenario_name,
				name = display_name,
				description = description,
				image = mystery_images[class],
			}
			-- we want to be able to access by for loop, Mystery 7, and WorldWar3
			Tables.Mystery[scenario_name] = temptable
			Tables.Mystery[class] = temptable
			c = c + 1
			Tables.Mystery[c] = temptable
		end)

-- -------- colonists
		--add as index and associative tables for ease of filtering
		local c1, c2, c3, c4, c5, c6 = 0, 0, 0, 0, 0, 0
		local TraitPresets = TraitPresets
		for id, t in pairs(TraitPresets) do
			if t.group == "Positive" then
				c1 = c1 + 1
				Tables.PositiveTraits[c1] = id
				Tables.PositiveTraits[id] = true
			elseif t.group == "Negative" then
				c2 = c2 + 1
				Tables.NegativeTraits[c2] = id
				Tables.NegativeTraits[id] = true
			elseif t.group == "other" then
				c3 = c3 + 1
				Tables.OtherTraits[c3] = id
				Tables.OtherTraits[id] = true
			elseif t.group == "Age Group" then
				c4 = c4 + 1
				Tables.ColonistAges[c4] = id
				Tables.ColonistAges[id] = true
			elseif t.group == "Gender" then
				c5 = c5 + 1
				Tables.ColonistGenders[c5] = id
				Tables.ColonistGenders[id] = true
			elseif t.group == "Specialization" and id ~= "none" and id ~= "Tourist" then
				c6 = c6 + 1
				Tables.ColonistSpecializations[c6] = id
				Tables.ColonistSpecializations[id] = true
			end
		end

		local Nations = Nations
		for i = 1, #Nations do
			local temptable = {
				flag = Nations[i].flag,
				text = Nations[i].text,
				value = Nations[i].value,
			}
			if Nations[i].value == "Mars" then
				-- eh, close enough
				temptable.flag = "UI/Flags/flag_northkorea.tga"
			end
			Tables.ColonistBirthplaces[i] = temptable
			Tables.ColonistBirthplaces[Nations[i].value] = temptable
		end

-- ---------- cargo

		-- used to check defaults for cargo
		c = 0
		local CargoPreset = CargoPreset
		for cargo_id, cargo in pairs(CargoPreset) do
			c = c + 1
			Tables.CargoPresets[c] = cargo
			Tables.CargoPresets[cargo_id] = cargo
		end

-- ----------- resources
		local AllResourcesList = AllResourcesList
		for i = 1, #AllResourcesList do
			Tables.Resources[i] = AllResourcesList[i]
			Tables.Resources[AllResourcesList[i]] = true
		end
	end
end -- do

local function Random(m, n)
	-- Hopefully it fixes whatever this is from :(
	--[[
[LUA ERROR] PackedMods/ChoGGi'sLibrary/Code/CommonFunctions.lua:1828: attempt to perform arithmetic on a nil value
(639):  <>
[C](-1): global sprocall
C:\Program Files (x86)\Steam\steamapps\common\Surviving Mars\CommonLua\Classes\CommandObject.lua(118):  <>
        -- end of stack
	]]
	if type(m) ~= "number" then
		return AsyncRand()
	end

	return
		-- m = min, n = max
		(n and (AsyncRand(n - m + 1) + m))
		-- OR if not n then m = max, min = 0
		or (m and AsyncRand(m))
		-- OR number between 0 and max_int
		or AsyncRand()
end
ChoGGi_Funcs.Common.Random = Random

--~ function ChoGGi_Funcs.Common.OpenKeyPresserDlg()
--~ 	ChoGGi_KeyPresserDlg:new({}, terminal.desktop, {})
--~ end

function ChoGGi_Funcs.Common.CreateSetting(str, setting_type)
	local setting = DotPathToObject(str, nil, true)
	if type(setting) == setting_type then
		return true
	end
end

-- SelObject/SelObjects
local radius4h = 250
if what_game == "Mars" then
	radius4h = const.HexSize / 4
end

-- returns whatever is selected > moused over > nearest object to cursor
-- single selection
function ChoGGi_Funcs.Common.SelObject(radius, pt)
	if not UIColony then
		return
	end
	-- single selection
	local obj = SelectedObj or GetCursorOrGamePadSelectObj()

	if obj then
		-- If it's multi then return the first one
		if obj:IsKindOf("MultiSelectionWrapper") then
			return obj.objects[1]
		end
	else
		-- radius selection
		pt = pt or GetCursorWorldPos()
		obj = MapFindNearest(pt, pt, radius or radius4h)
	end

	return obj
end

-- returns an indexed table of objects, add a radius to get objs close to cursor
function ChoGGi_Funcs.Common.SelObjects(radius, pt)
	if not UIColony then
		return empty_table
	end
	local objs = SelectedObj or GetCursorOrGamePadSelectObj()

	if not radius and objs then
		if objs:IsKindOf("MultiSelectionWrapper") then
			return objs.objects
		else
			return {objs}
		end
	end

	pt = pt or GetCursorWorldPos()
	return MapGet(pt, radius or radius4h, "attached", false)
end
local SelObject = ChoGGi_Funcs.Common.SelObject or empty_func
local SelObjects = ChoGGi_Funcs.Common.SelObjects or empty_func

do -- Rebuildshortcuts
	local _InternalTranslate = _InternalTranslate

	-- we want to only remove certain actions from the actual game, not ones added by modders, so list building time...
	local remove_lookup = {
		ChangeMapEmpty = true,
		ChangeMapPocMapAlt1 = true,
		ChangeMapPocMapAlt2 = true,
		ChangeMapPocMapAlt3 = true,
		ChangeMapPocMapAlt4 = true,
		Cheats = true,

		["Cheats.StoryBits"] = true,
		CheatSpawnPlanetaryAnomalies = true,

		["Cheats.Change Map"] = true,
		["Cheats.Map Exploration"] = true,
		["Cheats.Research"] = true,
		["Cheats.Spawn Colonist"] = true,
		["Cheats.Start Mystery"] = true,
		["Cheats.Trigger Disaster"] = true,
		["Cheats.Trigger Disaster Cold Wave"] = true,
		["Cheats.Trigger Disaster Dust Devil"] = true,
		["Cheats.Trigger Disaster Dust Devil Major"] = true,
		["Cheats.Trigger Disaster Dust Storm"] = true,
		["Cheats.Trigger Disaster Dust Storm Electrostatic"] = true,
		["Cheats.Trigger Disaster Dust Storm Great"] = true,
		["Cheats.Trigger Disaster Meteor"] = true,
		["Cheats.Trigger Disaster Meteor Multi Spawn"] = true,
		["Cheats.Trigger Disaster Meteor Storm"] = true,
		["Cheats.Workplaces"] = true,
		-- debug stuff that doesn't work
		DbgToggleBuildableGrid = true,
		MapSettingsEditor = true,
		DE_HexBuildGridToggle = true,
		DE_ToggleTerrainDepositGrid = true,
		actionPOCMapAlt0 = true,
		actionPOCMapAlt1 = true,
		actionPOCMapAlt2 = true,
		actionPOCMapAlt3 = true,
		actionPOCMapAlt4 = true,
		actionPOCMapAlt5 = true,
		-- added in kuiper modders beta (uses tilde to toggle menu instead of f2)
		DE_Menu = true,
		-- I need to override so i can reset zoom and other settings.
		FreeCamera = true,
		-- we def don't want this
		G_CompleteConstructions = true,
		-- I got my own bindable version
		G_ToggleInGameInterface = true,
		G_ToggleSigns = true,
		-- not cheats
--~ 		G_ToggleOnScreenHints = true,
--~ 		G_UnpinAll = true,
		G_AddFunding = true,
		G_CheatClearForcedWorkplaces = true,
		G_CheatUpdateAllWorkplaces = true,
		G_CompleteWiresPipes = true,
		G_ModsEditor = true,
		-- maybe this is used somewhere, hard to call it a cheat...
		G_OpenPregameMenu = true,
		G_ResearchAll = true,
		G_ResearchCurrent = true,
		G_ResetOnScreenHints = true,
		G_ToggleAllShifts = true,
		G_ToggleInfopanelCheats = true,
		G_UnlockAllBuildings = true,
		["G_UnlockАllТech"] = true,
		MapExplorationDeepScan = true,
		MapExplorationScan = true,
		SpawnColonist1 = true,
		SpawnColonist10 = true,
		SpawnColonist100 = true,
		StartMysteryAIUprisingMystery = true,
		StartMysteryBlackCubeMystery = true,
		StartMysteryCrystalsMystery = true,
		StartMysteryDiggersMystery = true,
		StartMysteryDreamMystery = true,
		StartMysteryLightsMystery = true,
		StartMysteryMarsgateMystery = true,
		StartMysteryMetatronMystery = true,
		StartMysteryMirrorSphereMystery = true,
		StartMysteryTheMarsBug = true,
		StartMysteryUnitedEarthMystery = true,
		StartMysteryWorldWar3 = true,
		TriggerDisasterColdWave = true,
		TriggerDisasterDustDevil = true,
		TriggerDisasterDustDevilMajor = true,
		TriggerDisasterDustStormElectrostatic = true,
		TriggerDisasterDustStormGreat = true,
		TriggerDisasterDustStormNormal = true,
		TriggerDisasterMeteorsMultiSpawn = true,
		TriggerDisasterMeteorsSingle = true,
		TriggerDisasterMeteorsStorm = true,
		TriggerDisasterStop = true,
		UnlockAllBreakthroughs = true,
		UpsampledScreenshot = true,
		DE_ToggleScreenshotInterface = true,
		-- EditorShortcuts.lua
		EditOpsHistory = true,
		["Editors.Random Map"] = true,
		DE_SaveDefaultMapEntityList = true,
		E_TurnSelectionToTemplates = true,
		DE_SaveDefaultMap = true,
		Editors = true,
		-- CommonShortcuts.lua
		DE_Console = true,
		DisableUIL = true,
		DE_UpsampledScreenshot = true,
		DE_Screenshot = true,
		DE_BugReport = true,
		Tools = true,
		["Tools.Extras"] = true,
	}
	-- don't care about the actions/want to leave them in editor menu, but we don't want the keys
	local removekey_lookup = {
		E_FlagsEditor = true,
		E_AttachEditor = true,
		CheckGameRevision = true,
		E_ResetZRelative = true,
		E_SmoothBrush = true,
		E_PlaceObjectsAdd = true,
		E_DeleteObjects = true,
		E_MoveGizmo = true,
	}
	-- auto-add all the TriggerDisaster ones
	local ass = XShortcutsTarget.actions
	for i = 1, #ass do
		local a = ass[i]
		if a.ActionId and a.ActionId:sub(1,15) == "TriggerDisaster" then
			remove_lookup[a.ActionId] = true
		end
	end
-- re-add dev stuff to check
--~ XTemplateSpawn("CommonShortcuts", XShortcutsTarget)
--~ XTemplateSpawn("EditorShortcuts", XShortcutsTarget)
--~ XTemplateSpawn("DeveloperShortcuts", XShortcutsTarget)
--~ XTemplateSpawn("SimShortcuts", XShortcutsTarget)
--~ XTemplateSpawn("GameShortcuts", XShortcutsTarget)

	local is_list_sorted
	function ChoGGi_Funcs.Common.Rebuildshortcuts()
		local XShortcutsTarget = XShortcutsTarget

		-- too soon?
		if type(XShortcutsTarget.UpdateToolbar) ~= "function" then
			return
		end

		-- remove unwanted actions
		local ass = XShortcutsTarget.actions
		for i = #ass, 1, -1 do
			local a = ass[i]
			-- [LUA ERROR] CommonLua/X/XShortcuts.lua:136: attempt to compare string with table
			a.ActionName = _InternalTranslate(a.ActionName)

			if a.ChoGGi_ECM or remove_lookup[a.ActionId] then
				a:delete()
				table.remove(XShortcutsTarget.actions, i)
--~ 			else
--~ 				-- hide any menuitems added from devs
--~ 				a.ActionMenubar = nil
--~ 				print(a.ActionId)
			elseif removekey_lookup[a.ActionId] then
				a.ActionShortcut = nil
				a.ActionShortcut2 = nil
			end



		end

		if testing then
			-- goddamn annoying key
			local idx = table.find(XShortcutsTarget.actions, "ActionId", "actionToggleFullscreen")
			if idx then
				XShortcutsTarget.actions[idx]:delete()
				table.remove(XShortcutsTarget.actions, idx)
			end
		end

		-- and add mine
		local XAction = XAction
		local Actions = ChoGGi.Temp.Actions

		-- make my entries sorted in the keybindings menu
		if not is_list_sorted then
			table.sort(Actions, function(a, b)
				return CmpLower(a.ActionId, b.ActionId)
			end)
			is_list_sorted = true
		end

--~ 		Actions = {}
--~ 		Actions[#Actions+1] = {
--~ 			ActionId = "ChoGGi_ShowConsole",
--~ 			OnAction = function()
--~ 				local dlgConsole = dlgConsole
--~ 				if dlgConsole then
--~ 					ShowConsole(not dlgConsole:GetVisible())
--~ 				end
--~ 			end,
--~ 			ActionShortcut = "~",
--~ 			ActionShortcut2 = "Enter",
--~ 		}

		local func_name = "AddAction"
		if what_game == "JA3" then
			func_name = "_InternalAddAction"
		end -- what_game

		local DisableECM = ChoGGi.UserSettings.DisableECM
		for i = 1, #Actions do
			local a = Actions[i]

			-- [LUA ERROR] CommonLua/X/XShortcuts.lua:136: attempt to compare string with table
			a.ActionName = _InternalTranslate(a.ActionName)

			-- added by ECM
			if a.ChoGGi_ECM then
				-- Can we enable ECM actions?
				if not DisableECM then
--~ 					XShortcutsTarget:AddAction(XAction:new(a))
					XShortcutsTarget[func_name](XShortcutsTarget, XAction:new(a))
				end
			else
--~ 				XShortcutsTarget:AddAction(XAction:new(a))
				XShortcutsTarget[func_name](XShortcutsTarget, XAction:new(a))
			end
		end

		-- Add a key binding to options to re-enable ECM
		if DisableECM then
			local name = T(754117323318--[[Enable]]) .. " " .. T(302535920000002--[[ECM]])
--~ 			XShortcutsTarget:AddAction(XAction:new{
			XShortcutsTarget[func_name](XShortcutsTarget, XAction:new{
				ActionName = name,
				ActionId = name,
				OnAction = function()
					ChoGGi.UserSettings.DisableECM = false
					ChoGGi_Funcs.Settings.WriteSettings()
					print(name, ":", Translate(302535920001070--[[Restart to take effect.]]))
					ChoGGi_Funcs.Common.MsgWait(
						T(302535920001070--[[Restart to take effect.]]),
						name
					)
				end,
				ActionShortcut = "Ctrl-Alt-0",
				ActionBindable = true,
			})
			print(Translate(302535920001411--[["ECM has been disabled.
Use %s to enable it, or change DisableECM to false in %s.
See the bottom of Gameplay>Controls if you've changed the key binding."]])
				:format("Ctrl-Alt-0", ConvertToOSPath("AppData/LocalStorage.lua"))
			)
		end

		-- Add rightclick action to menuitems
		XShortcutsTarget:UpdateToolbar()
		-- got me
		XShortcutsThread = false

		if DisableECM == false then
			-- I forget why I'm toggling this...
			local dlgConsole = dlgConsole
			if dlgConsole then
				ShowConsole(not dlgConsole:GetVisible())
				ShowConsole(not dlgConsole:GetVisible())
			end
		end

	end
end -- do

do -- AttachToNearestDome
	local function CanWork(obj)
		return obj:CanWork()
	end

	-- If building requires a dome and that dome is borked then assign it to nearest dome
	function ChoGGi_Funcs.Common.AttachToNearestDome(obj, force)
		if force ~= "force" and not obj:GetDefaultPropertyValue("dome_required") then
			return
		end

		-- find the nearest working dome
		local city = obj.city or UICity
		local realm = GameMaps[city.map_id].realm
		local working_domes = realm:MapFilter(city.labels.Dome, CanWork)
		local dome = FindNearestObject(working_domes, obj)

		-- remove from old dome (assuming it's a different dome), or the dome is invalid
		local current_dome_valid = IsValid(obj.parent_dome)
		if obj.parent_dome and not current_dome_valid
				or (current_dome_valid and dome and dome.handle ~= obj.parent_dome.handle) then
			local current_dome = obj.parent_dome
			-- remove from dome labels
			current_dome:RemoveFromLabel("InsideBuildings", obj)
			if obj:IsKindOf("Workplace") then
				current_dome:RemoveFromLabel("Workplace", obj)
			elseif obj:IsKindOf("Residence") then
				current_dome:RemoveFromLabel("Residence", obj)
			end

			if obj:IsKindOf("NetworkNode") then
				current_dome:SetLabelModifier("BaseResearchLab", "NetworkNode")
			end
			obj.parent_dome = false
		end

		-- no need to fire if there's no dome, or the above didn't remove it
		if dome and not IsValid(obj.parent_dome) then
			obj:SetDome(dome)

			-- add to dome labels
			dome:AddToLabel("InsideBuildings", obj)
			if obj:IsKindOf("Workplace") then
				dome:AddToLabel("Workplace", obj)
			elseif obj:IsKindOf("Residence") then
				dome:AddToLabel("Residence", obj)
			end

			-- spires
			if obj:IsKindOf("NetworkNode") then
				dome:SetLabelModifier("BaseResearchLab", "NetworkNode", obj.modifier)
			end
		end
	end

end -- do

-- toggle working status
function ChoGGi_Funcs.Common.ToggleWorking(obj)
	if IsValid(obj) then
		CreateRealTimeThread(function()
			obj:ToggleWorking()
			Sleep(5)
			obj:ToggleWorking()
		end)
	end
end

do -- SetCameraSettings
	local cameraRTS = cameraRTS
	function ChoGGi_Funcs.Common.SetCameraSettings()
		local ChoGGi = ChoGGi
		-- cameraRTS.GetProperties(1)

		-- size of activation area for border scrolling
		if ChoGGi.UserSettings.BorderScrollingArea then
			cameraRTS.SetProperties(1, {ScrollBorder = ChoGGi.UserSettings.BorderScrollingArea})
		else
			-- default
			cameraRTS.SetProperties(1, {ScrollBorder = ChoGGi.Consts.CameraScrollBorder})
		end

		if ChoGGi.UserSettings.CameraLookatDist then
			cameraRTS.SetProperties(1, {LookatDist = ChoGGi.UserSettings.CameraLookatDist})
		else
			-- default
			cameraRTS.SetProperties(1, {LookatDist = ChoGGi.Consts.CameraLookatDist})
		end

		-- zoom
		-- camera.GetFovY()
		-- camera.GetFovX()
		if ChoGGi.UserSettings.CameraZoomToggle then
			if type(ChoGGi.UserSettings.CameraZoomToggle) == "number" then
				cameraRTS.SetZoomLimits(0, ChoGGi.UserSettings.CameraZoomToggle)
			else
				cameraRTS.SetZoomLimits(0, 24000)
			end

			-- 5760x1080 doesn't get the correct zoom size till after zooming out
			if UIL.GetScreenSize():x() == 5760 then
				camera.SetFovY(2580)
				camera.SetFovX(7745)
			end
		else
			-- default
			cameraRTS.SetZoomLimits(ChoGGi.Consts.CameraMinZoom, ChoGGi.Consts.CameraMaxZoom)
		end

		--
		if ChoGGi.UserSettings.MapEdgeLimit then
			hr.CameraRTSBorderAtMinZoom = -1000
			hr.CameraRTSBorderAtMaxZoom = -1000
		else
			hr.CameraRTSBorderAtMinZoom = 1000
			hr.CameraRTSBorderAtMaxZoom = 1000
		end

		-- cameraRTS.SetProperties(1, {HeightInertia = 0})
	end
end -- do

function ChoGGi_Funcs.Common.ColonistUpdateAge(c, age)
	if not IsValid(c) or type(age) ~= "string" then
		return
	end

	local ages = ChoGGi.Tables.ColonistAges
	if age == T(3490--[[Random]]) then
		age = ages[Random(1, 6)]
	end
	-- remove all age traits
	for i = 1, #ages do
		local ageT = ages[i]
		if c.traits[ageT] then
			c:RemoveTrait(ageT)
		end
	end
	-- add new age trait
	c:AddTrait(age, true)

	-- needed for comparison
	local orig_age = c.age_trait
	-- needed for updating entity
	c.age_trait = age

	if age == "Retiree" then
		c.age = 65 -- why isn't there a MinAge_Retiree...
	else
		c.age = c:GetClassValue("MinAge_" .. age)
	end

	if age == "Child" then
		-- there aren't any child specialist entities
		c.specialist = "none"
		-- children live in nurseries
		if orig_age ~= "Child" then
			c:SetResidence(false)
		end
	end
	-- children live in nurseries
	if orig_age == "Child" and age ~= "Child" then
		c:SetResidence(false)
	end
	-- now we can set the new entity
	c:ChooseEntity()
	-- and (hopefully) prod them into finding a new residence
	c:UpdateWorkplace()
	c:UpdateResidence()
end

function ChoGGi_Funcs.Common.ColonistUpdateGender(c, gender)
	if not IsValid(c) or type(gender) ~= "string" then
		return
	end

	local genders = ChoGGi.Tables.ColonistGenders
	local male_female = {"Male", "Female"}

	if gender == T(3490--[[Random]]) then
		gender = genders[Random(1, 3)]
	elseif gender == T(302535920000800--[[MaleOrFemale]]) then
		gender = table.rand(male_female)
	end
	-- remove all gender traits
	for i = 1, #genders do
		c:RemoveTrait(genders[i])
	end
	-- add new gender trait
	c:AddTrait(gender, true)
	-- needed for updating entity
	c.gender = gender
	-- set entity gender
	if gender == "OtherGender" then
		c.entity_gender = Random(1, 100) <= 50 and "Male" or "Female"
		c.fx_actor_class = c.entity_gender == "Male" and "ColonistFemale" or "ColonistMale"
	else
		c.entity_gender = gender
	end
	-- now we can set the new entity
	c:ChooseEntity()
end

function ChoGGi_Funcs.Common.ColonistUpdateSpecialization(c, spec)
	if not IsValid(c) or type(spec) ~= "string" then
		return
	end

	-- children don't have spec models so they get black cubed
	if c.age_trait ~= "Child" then
		if spec == T(3490--[[Random]]) then
			spec = ChoGGi.Tables.ColonistSpecializations[Random(1, 6)]
		end
		if c.specialist ~= "none" then
			c:RemoveTrait(c.specialist)
		end
		c:AddTrait(spec)
--~ 		c:SetSpecialization(spec)

		c:ChangeWorkplacePerformance()
		c:UpdateWorkplace()
		--randomly fails on colonists from rockets
		--c:TryToEmigrate()
	end
end

function ChoGGi_Funcs.Common.ColonistUpdateTraits(c, bool, traits)
	if not IsValid(c) or type(traits) ~= "table" then
		return
	end

	local func
	if bool == true then
		func = "AddTrait"
	else
		func = "RemoveTrait"
	end
	for i = 1, #traits do
		c[func](c, traits[i], true)
	end
end

function ChoGGi_Funcs.Common.ColonistUpdateRace(c, race)
	local race_type = type(race)
	if (race_type ~= "number" and race_type ~= "string") or not IsValid(c) then
		return
	end

	if race == T(3490--[[Random]]) then
		race = Random(1, 5) -- max amount of races
	end
	c.race = race
	c:ChooseEntity()
end


do -- FuckingDrones
	--[[
		fucking drones because if you assign more than one resource cube to be picked up
		the drones won't pick up any if that number isn't available for pickup
		try that breakthrough where they carry two, and get a depot (at a factory/mine/etc) with one resource left in i
		yes it took awhile to figure it out, hence the name...
	]]

	local function GetNearestIdleDrone(bld)
		-- Make sure building has a list of cc (if it doesn't then there's no drones near enough)
		if not bld or (bld and not bld.command_centers) then
			if bld.parent.command_centers then
				bld = bld.parent
			end
		end
		-- (add example of a building with a .parent)
		if not bld or (bld and not bld.command_centers) then
			return false
		end

		local cc = FindNearestObject(
			bld.command_centers,
			bld:GetPos(),
			function(center)
				return center:GetIdleDronesCount() > 0
			end
		)
		if cc then
			cc = cc.drones
		else
			-- No free drones
			return false
		end

		-- Get an idle drone
		local idle_idx = table.find(cc, "command", "Idle")
		if idle_idx then
			return cc[idle_idx]
		end
		-- There's probably a way to search for both in one go, but I'm lazy
		idle_idx = table.find(cc, "command", "WaitCommand")
		if idle_idx then
			return cc[idle_idx]
		end

		-- All done
	end
	ChoGGi_Funcs.Common.GetNearestIdleDrone = GetNearestIdleDrone

	function ChoGGi_Funcs.Common.FuckingDrones(obj, single)
		if not IsValid(obj) then
			return
		end

		-- Come on, Bender. Grab a jack. I told these guys you were cool.
		-- Well, if jacking on will make strangers think I'm cool, I'll do it.

		local is_single = single == "single" or obj:IsKindOf("SingleResourceProducer")
		local stored = obj:GetStoredAmount()
		-- 1000
		local rs = const.ResourceScale

		-- Only fire if more then one resource
		if stored > rs then
			local parent
			local request
			local resource
			if is_single then
				parent = obj.parent
				request = obj.stockpiles[obj:GetNextStockpileIndex()].supply_request
				resource = obj.resource_produced
			else
				parent = obj
				request = obj.supply_request
				resource = obj.resource
			end

			local drone = GetNearestIdleDrone(parent)
			if not drone then
				return
			end

			-- Force drones to pickup from pile even if they have a carry cap larger then the amount stored
			local carry = g_Consts.DroneResourceCarryAmount * rs
			-- Round to nearest 1000 (don't want uneven stacks)
			stored = (stored - stored % rs) / rs * rs
			-- If carry is smaller then stored then they may not pickup (depends on storage)
			if carry < stored or
				-- No picking up more then they can carry
				stored > carry then
					stored = carry
			end
			-- Pretend it's the user doing it (for more priority?)
			drone:SetCommandUserInteraction(
				"PickUp", request, false, resource, stored
			)
		end
	end
end -- do

function ChoGGi_Funcs.Common.SetMechanizedDepotTempAmount(obj, amount)
	amount = amount or 10
	local resource = obj.resource
	local io_stockpile = obj.stockpiles[obj:GetNextStockpileIndex()]
	local io_supply_req = io_stockpile.supply[resource]
	local io_demand_req = io_stockpile.demand[resource]

	io_stockpile.max_z = amount
	amount = (amount * 10) * const.ResourceScale
	io_supply_req:SetAmount(amount)
	io_demand_req:SetAmount(amount)
end

do -- GetAllAttaches
	local attach_dupes = {}
	local attaches_list, attaches_count
	local parent_obj
--~ 	local skip = {"GridTile", "GridTileWater", "BuildingSign", "ExplorableObject", "TerrainDeposit", "DroneBase", "Dome"}
	local skip = {"ExplorableObject", "TerrainDeposit", "DroneBase", "Dome"}

	local function AddAttaches(obj, only_include)
		for _, a in pairs(obj) do
			if not attach_dupes[a] and IsValid(a) and a ~= parent_obj
				and (not only_include or only_include and a:IsKindOf(only_include))
				and not a:IsKindOfClasses(skip)
			then
				attach_dupes[a] = true
				attaches_count = attaches_count + 1
				attaches_list[attaches_count] = a
			end
		end
	end

	local mark
	local function ForEach(a, parent_cls, only_include)
		if not attach_dupes[a] and a ~= parent_obj
			and (not only_include or only_include and a:IsKindOf(only_include))
			and not a:IsKindOfClasses(skip)
		then
			attach_dupes[a] = true
			attaches_count = attaches_count + 1
			attaches_list[attaches_count] = a
			if mark then
				a.ChoGGi_Marked_Attach = parent_cls
			end
			-- add level limit?
			if a.ForEachAttach then
				a:ForEachAttach(ForEach, a.class)
			end
		end
	end

	function ChoGGi_Funcs.Common.GetAllAttaches(obj, mark_attaches, only_include, safe)
		mark = mark_attaches

		table.clear(attach_dupes)
		if not IsValid(obj) then
			-- I always use #attach_list so "" is fine by me
			return ""
		end

		-- we use objlist instead of {} for delete all button in examine
		attaches_list = {}
		attaches_count = 0
		parent_obj = obj

		-- add regular attachments
		if obj.ForEachAttach then
			obj:ForEachAttach(ForEach, obj.class, only_include)
		end

		if safe then
			local attaches = obj:GetAttaches() or ""
			for i = 1, #attaches do
				local a = attaches[i]
				ForEach(a, a.class, only_include)
			end

		else
			-- add any non-attached attaches (stuff that's kinda attached, like the concrete arm thing)
			AddAttaches(obj, only_include)
			-- and the anim_obj added in gagarin
			if IsValid(obj.anim_obj) then
				AddAttaches(obj.anim_obj, only_include)
			end
			-- pastures
			if obj.current_herd then
				AddAttaches(obj.current_herd, only_include)
			end
		end

		-- remove original obj if it's in the list
		local idx = table.find(attaches_list, obj)
		if idx then
			table.remove(attaches_list, idx)
		end

		return attaches_list
	end
end -- do
local GetAllAttaches = ChoGGi_Funcs.Common.GetAllAttaches

-- I've seen better func names
local function MapGet_ChoGGi(label, area, city, ...)
	local objs = (city or UICity).labels[label] or {}
--~ 	local objs = GetCityLabels(label)
	if #objs == 0 then
		local g_cls = g_Classes[label]
		-- If it isn't in g_Classes and isn't a CObject then MapGet will return *everything* (think gary oldman in professional)
		if g_cls and g_cls:IsKindOf("CObject") then
			-- area can be: true, "map", "detached", "outsiders" (see Surviving Mars/ModTools/Docs/LuaMapEnumeration.md.html)
			local realm = GetRealmByID(city and city.map_id or ActiveMapID)
			return realm and realm:MapGet(area or true, label, ...)
			-- use obj:SetPos(pos) to move objs to map (and away with pos = InvalidPos())
		end
	end
	return objs
end
ChoGGi_Funcs.Common.MapGet = MapGet_ChoGGi
-- just the "fix" no labels
function ChoGGi_Funcs.Common.MapGet_fixed(area, class, city, ...)
	local g_cls = g_Classes[class]
	-- If it isn't in g_Classes and isn't a CObject then MapGet will return *everything* (think gary oldman in professional)
	if g_cls and g_cls:IsKindOf("CObject") then
		return GetRealmByID(city and city.map_id or ActiveMapID):MapGet(area, class, ...)
	end
	return {}
end

do -- SaveOldPalette/RestoreOldPalette/GetPalette/RandomColour/ObjectColourRandom/ObjectColourDefault/ChangeObjectColour
	local color_ass = {}
	local colour_funcs = {}

	local function SaveOldPalette(obj)
		if not IsValid(obj) then
			return
		end
		if not obj.ChoGGi_origcolors and obj:IsKindOf("ColorizableObject") then
			obj.ChoGGi_origcolors = {
				{obj:GetColorizationMaterial(1)},
				{obj:GetColorizationMaterial(2)},
				{obj:GetColorizationMaterial(3)},
				{obj:GetColorizationMaterial(4)},
			}
			obj.ChoGGi_origcolors[-1] = obj:GetColorModifier()
		end
	end
	ChoGGi_Funcs.Common.SaveOldPalette = SaveOldPalette
	colour_funcs.SetColours = function(obj, choice)
		SaveOldPalette(obj)
		for i = 1, 4 do
			obj:SetColorizationMaterial(i,
				choice[i].value,
				choice[i+8].value,
				choice[i+4].value
			)
		end
		obj:SetColorModifier(choice[13].value)
	end

	local function SetChoGGiPalette(obj, c)
		obj:SetColorModifier(c[-1])
		-- object, 1-4 , Color, Roughness, Metallic
		obj:SetColorizationMaterial(1, c[1][1], c[1][2], c[1][3])
		obj:SetColorizationMaterial(2, c[2][1], c[2][2], c[2][3])
		obj:SetColorizationMaterial(3, c[3][1], c[3][2], c[3][3])
		obj:SetColorizationMaterial(4, c[4][1], c[4][2], c[4][3])
	end
	ChoGGi_Funcs.Common.SetChoGGiPalette = SetChoGGiPalette

	local function RestoreOldPalette(obj)
		if not IsValid(obj) then
			return
		end
		if obj.ChoGGi_origcolors then
			SetChoGGiPalette(obj, obj.ChoGGi_origcolors)
			obj.ChoGGi_origcolors = nil
		end
	end
	ChoGGi_Funcs.Common.RestoreOldPalette = RestoreOldPalette
	colour_funcs.RestoreOldPalette = RestoreOldPalette

	local function GetPalette(obj)
		if not IsValid(obj) then
			return
		end
		local pal = {}
		pal.Color1, pal.Roughness1, pal.Metallic1 = obj:GetColorizationMaterial(1)
		pal.Color2, pal.Roughness2, pal.Metallic2 = obj:GetColorizationMaterial(2)
		pal.Color3, pal.Roughness3, pal.Metallic3 = obj:GetColorizationMaterial(3)
		pal.Color4, pal.Roughness4, pal.Metallic4 = obj:GetColorizationMaterial(4)
		return pal
	end
	ChoGGi_Funcs.Common.GetPalette = GetPalette

	local function RandomColour(amount)
		if amount and type(amount) == "number" and amount > 1 then
			-- temp associative table of colour ids
			table.clear(color_ass)
			-- Indexed list of colours we return
			local colour_list = {}
			-- when this reaches amount we return the list
			local c = 0
			-- loop through the amount once
			for _ = 1, amount do
				-- 16777216: https://en.wikipedia.org/wiki/Color_depth#True_color_(24-bit)
				-- we skip the alpha values
				local colour = AsyncRand(16777217) + -16777216
				if not color_ass[colour] then
					color_ass[colour] = true
					c = c + 1
				end
			end
			-- then make sure we're at count (
			while c < amount do
				local colour = AsyncRand(16777217) + -16777216
				if not color_ass[colour] then
					color_ass[colour] = true
					c = c + 1
				end
			end
			-- convert ass to idx list
			c = 0
			for colour in pairs(color_ass) do
				c = c + 1
				colour_list[c] = colour
			end

			return colour_list
		end

		-- return a single colour
		return AsyncRand(16777217) + -16777216
	end
	ChoGGi_Funcs.Common.RandomColour = RandomColour

	function ChoGGi_Funcs.Common.ObjectColourRandom(obj)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = SelObject()
		else
			obj = obj or SelObject()
		end

		if not IsValid(obj) or obj and not obj:IsKindOf("ColorizableObject") then
			return
		end
		local attaches = {}
		local c = 0

		local a_list = GetAllAttaches(obj)
		for i = 1, #a_list do
			local a = a_list[i]
			if a:IsKindOf("ColorizableObject") then
				c = c + 1
				attaches[c] = {obj = a, c = {}}
			end
		end

		-- random is random after all, so lets try for at least slightly different colours
		-- you can do a max of 4 colours on each object
		local colours = RandomColour((c * 4) + 4)
		-- attach obj to list
		c = c + 1
		attaches[c] = {obj = obj, c = {}}

		-- add colours to each colour table attached to each obj
		local obj_count = 0
		local att_count = 1
		for i = 1, #colours do
			-- add 1 to colour count
			obj_count = obj_count + 1
			-- add colour to attach colours
			attaches[att_count].c[obj_count] = colours[i]

			if obj_count == 4 then
				-- when we get to four increment attach colours num, and reset colour count
				obj_count = 0
				att_count = att_count + 1
			end
		end

		-- now we loop through all the objects and apply the colours
		for i = 1, c do
			obj = attaches[i].obj
			local c = attaches[i].c

			SaveOldPalette(obj)

			-- can only change basecolour
			if obj:GetMaxColorizationMaterials() == 0 then
				obj:SetColorModifier(c[1])
			else
				-- object, 1-4 , Color, Roughness, Metallic
				obj:SetColorizationMaterial(1, c[1], Random(-128, 127), Random(-128, 127))
				obj:SetColorizationMaterial(2, c[2], Random(-128, 127), Random(-128, 127))
				obj:SetColorizationMaterial(3, c[3], Random(-128, 127), Random(-128, 127))
				obj:SetColorizationMaterial(4, c[4], Random(-128, 127), Random(-128, 127))
			end
		end

	end

	function ChoGGi_Funcs.Common.ObjectColourDefault(obj)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = SelObject()
		else
			obj = obj or SelObject()
		end

		if not obj then
			return
		end

		if IsValid(obj) and obj:IsKindOf("ColorizableObject") then
			RestoreOldPalette(obj)
		end

		local attaches = GetAllAttaches(obj)
		for i = 1, #attaches do
			RestoreOldPalette(attaches[i])
		end

	end

	-- make sure we're in the same grid
	local function CheckGrid(fake_parent, func, obj, obj_bld, choice, c_air, c_water, c_elec)
		-- this is ugly, i should clean it up
		if not c_air and not c_water and not c_elec then
			colour_funcs[func](obj, choice)
		else
			if c_air and obj_bld.air and fake_parent.air and obj_bld.air.grid.elements[1].building == fake_parent.air.grid.elements[1].building then
				colour_funcs[func](obj, choice)
			end
			if c_water and obj_bld.water and fake_parent.water and obj_bld.water.grid.elements[1].building == fake_parent.water.grid.elements[1].building then
				colour_funcs[func](obj, choice)
			end
			if c_elec and obj_bld.electricity and fake_parent.electricity and obj_bld.electricity.grid.elements[1].building == fake_parent.electricity.grid.elements[1].building then
				colour_funcs[func](obj, choice)
			end
		end
	end

	function ChoGGi_Funcs.Common.ChangeObjectColour(obj, parent, dialog)
		if not obj or obj and not obj:IsKindOf("ColorizableObject") then
			MsgPopup(
				Translate(302535920000015--[[Can't colour %s.]]):format(RetName(obj)),
				T(3595--[[Color]])
			)
			return
		end
		local pal = GetPalette(obj)

		local item_list = {}
		local c = 0
		for i = 1, 4 do
			local text = "Color" .. i
			c = c + 1
			item_list[c] = {
				text = text,
				value = pal[text],
				hint = T(302535920000017--[[Use the colour picker (dbl right-click for instant change).]]),
			}
			text = "Roughness" .. i
			c = c + 1
			item_list[c] = {
				text = text,
				value = pal[text],
				hint = T(302535920000018--[[Don't use the colour picker: Numbers range from -128 to 127.]]),
			}
			text = "Metallic" .. i
			c = c + 1
			item_list[c] = {
				text = text,
				value = pal[text],
				hint = T(302535920000018--[[Don't use the colour picker: Numbers range from -128 to 127.]]),
			}
		end
		c = c + 1
		item_list[c] = {
			text = "X_BaseColor",
			value = 6579300,
			obj = obj,
			hint = T(302535920000019--[["Single colour for object (this colour will interact with the other colours).
	If you want to change the colour of an object you can't with 1-4."]]),
		}

		local function CallBackFunc(choice)
			if choice.nothing_selected then
				return
			end

			if choice[13] then

				-- needed to set attachment colours
				local label = obj.class
				local fake_parent
				if parent then
					label = parent.class
					fake_parent = parent
				else
					fake_parent = choice[1].parentobj
				end
				if not fake_parent then
					fake_parent = obj
				end

				-- sort table so it's the same as was displayed
				table.sort(choice, function(a, b)
					return a.text < b.text
				end)

				-- used to check for grid connections
				local choice1 = choice[1]
				local c_air = choice1.list_checkair
				local c_water = choice1.list_checkwater
				local c_elec = choice1.list_checkelec

				local colour_func = "SetColours"
				if choice1.check2 then
					colour_func = "RestoreOldPalette"
				end

				-- all of type checkbox
				if choice1.check1 then
					local labels = MapGet_ChoGGi(label)
					for i = 1, #labels do
						local lab_obj = labels[i]
						if parent then
							local attaches = GetAllAttaches(lab_obj)
							for j = 1, #attaches do
								CheckGrid(fake_parent, colour_func, attaches[j], lab_obj, choice, c_air, c_water, c_elec)
							end
						else
							CheckGrid(fake_parent, colour_func, lab_obj, lab_obj, choice, c_air, c_water, c_elec)
						end
					end

				-- single building change
				else
					CheckGrid(fake_parent, colour_func, obj, obj, choice, c_air, c_water, c_elec)
				end

				MsgPopup(
					Translate(302535920000020--[[Colour is set on %s]]):format(RetName(obj)),
					T(3595--[[Color]]),
					{objects = obj}
				)
			end
		end

		ChoGGi_Funcs.Common.OpenInListChoice{
			callback = CallBackFunc,
			items = item_list,
			title = T(302535920001708--[[Color Modifier]]) .. ": " .. RetName(obj),
			hint = T(302535920000022--[["If number is 8421504 then you probably can't change that colour.

You can copy and paste numbers if you want."]]),
			parent = dialog,
			custom_type = 2,
			checkboxes = {
				{
					title = T(302535920000023--[[All of type]]),
					hint = T(302535920000024--[[Change all objects of the same type.]]),
				},
				{
					title = T(302535920000025--[[Default Colour]]),
					hint = T(302535920000026--[[if they're there; resets to default colours.]]),
				},
			},
		}
	end
end -- do

function ChoGGi_Funcs.Common.BuildMenu_Toggle()
	local dlg = Dialogs.XBuildMenu
	if not dlg then
		return
	end

	CreateRealTimeThread(function()
		CloseXBuildMenu()
		Sleep(250)
		OpenXBuildMenu()
	end)
end

do -- DeleteObject
	local DeleteThread = DeleteThread
	--JA3
--~ 	local DestroyBuildingImmediate = DestroyBuildingImmediate
--~ 	local FlattenTerrainInBuildShape = FlattenTerrainInBuildShape
	local HasAnySurfaces = HasAnySurfaces
	local ApplyAllWaterObjects = ApplyAllWaterObjects
	local EntitySurfaces_Height = EntitySurfaces.Height
	local procall = procall

	local DeleteObject

	local function DeleteLabelObjs(obj, label)
		SuspendPassEdits("ChoGGi_Funcs.Common.DeleteLabelObjs")
		local objs = obj.labels[label] or ""
		for i = #objs, 1, -1 do
			local obj = objs[i]
			if not obj.passage_obj then
				DeleteObject(obj, true)
			end
		end
		ResumePassEdits("ChoGGi_Funcs.Common.DeleteLabelObjs")
	end

	local function ExecFunc(obj, funcname, ...)
		if type(obj[funcname]) == "function" then
			local status, result = pcall(obj[funcname], obj, ...)
			if not status then
				print("DeleteObject", funcname, obj[funcname], result)
			end
--~ 			obj[funcname](obj, ...)
		end
	end

	-- skip_demo == dust plume resource drop
	local function DeleteFunc(obj, skip_demo)
		if not IsValid(obj) then
			return
		end

		-- buildings, colonists, and passages need to be removed first
		if obj:IsKindOf("Dome") and not obj:CanDemolish() then
			local connected_domes = obj.connected_domes or ""

			if #connected_domes == 0 then
				DeleteLabelObjs(obj, "Building")
				DeleteLabelObjs(obj, "Colonist")
				for bad_obj in pairs(connected_domes) do
					if not IsValid(bad_obj) then
						-- remove invalid obj from dome list
						table.remove_entry(connected_domes[bad_obj], "handle", bad_obj.handle)
					-- obj stuck outside the map area ("holding area" for off planet rockets and so on)
					elseif (bad_obj:GetPos() or point20) == InvalidPos and not (bad_obj:IsKindOf("Colonist") and IsValid(bad_obj.holder)) then
						DeleteObject(bad_obj)
					end
				end
				-- try deleting again
				DeleteObject(obj)
			else
				MsgPopup(
					Translate(302535920001354--[["<green>%s</green> is a Dome with stuff still in it (crash if deleted)."]]):format(RetName(obj)),
					T(302535920000489--[["Delete Object(s)"]])
				)
				return
			end
		end

		-- actually delete the whole passage
		if obj:IsKindOf("Passage") then
			for i = #obj.elements, 1, -1 do
				DeleteObject(obj.elements[i], true)
			end
			for i = #obj.elements_under_construction, 1, -1 do
				DeleteObject(obj.elements_under_construction[i], true)
			end
		end

		local is_deposit = obj:IsKindOf("Deposit")
		local is_water = obj:IsKindOf("TerrainWaterObject")
		local is_waterspire = obj:IsKindOf("WaterReclamationSpire") and not IsValid(obj.parent_dome)

		if not is_waterspire then
			-- some stuff will leave holes in the world if they're still working
			procall(ExecFunc, obj, "SetWorking")
		end

--~ 		procall(ExecFunc, obj, "RecursiveCall", true, "Done")

		local gamemap = GetGameMap(obj)

		-- remove leftover water
		if is_water then
			if IsValid(obj.water_obj) then
				gamemap.terrain:UpdateWaterGridFromObject(obj.water_obj)
			end
			ApplyAllWaterObjects()
		end

		-- stop any threads (reduce log spam)
		for _, value in pairs(obj) do
			if type(value) == "thread" then
				DeleteThread(value)
			end
		end

		-- surface metal
		if is_deposit and obj.group then
			for i = #obj.group, 1, -1 do
				obj.group[i]:delete()
			end
		end

		procall(ExecFunc, obj, "ChangeWorkingStateAnim", false)
--~ 		procall(ExecFunc, obj, "OnDemolish")
		-- ground n whatnot
		procall(ExecFunc, obj, "RestoreTerrain")
		procall(ExecFunc, obj, "Destroy")

		-- do we need to flatten the ground beneath
		if obj.GetFlattenShape then
			local shape = obj:GetFlattenShape()
			if shape ~= FallbackOutline then
				if HasAnySurfaces(obj, EntitySurfaces_Height, true)
				and not gamemap.terrain:HasRestoreHeight() then
					FlattenTerrainInBuildShape(shape, obj)
				end
			end
		end

		procall(ExecFunc, obj, "SetDome", false)
		procall(ExecFunc, obj, "RemoveFromLabels")

		procall(ExecFunc, obj, "Gossip", "done")
		procall(ExecFunc, obj, "SetHolder", false)

		-- demo to the rescue
		obj.can_demolish = true
		obj.indestructible = false
		if not skip_demo and obj.DoDemolish then
			DestroyBuildingImmediate(obj)
		end

		-- I did ask nicely
		if IsValid(obj) then
			obj:delete()
		end
	end

	-- skip_demo == dust plume resource drop
	function ChoGGi_Funcs.Common.DeleteObject(objs, skip_demo)
		if not DeleteObject then
			DeleteObject = ChoGGi_Funcs.Common.DeleteObject
		end

		if IsKindOf(objs, "XAction") then
			objs = SelObjects()
		else
			objs = objs or SelObjects()
		end

		if IsValid(objs) then
			CreateRealTimeThread(DeleteFunc, objs, skip_demo)
		else
			CreateRealTimeThread(function()
				-- If it's a string, then it's probably a class name
				if type(objs) == "string" then
					-- Returns a table
					objs = MapGet_ChoGGi(objs)
				end
				-- Clear tables
				if type(objs) == "table" then
					SuspendPassEdits("ChoGGi_Funcs.Common.DeleteObject")
					for i = #objs, 1, -1 do
						DeleteFunc(objs[i], skip_demo)
					end
					ResumePassEdits("ChoGGi_Funcs.Common.DeleteObject")
				end
			end)
		end

--~ 		-- hopefully i can remove all log spam one of these days
--~ 		local name = RetName(obj)
--~ 		if name then
--~ 			printC("DeleteObject", name, "DeleteObject")
--~ 		end

	end
end -- do
local DeleteObject = ChoGGi_Funcs.Common.DeleteObject

do -- EmptyMechDepot
	local angle_x = {
		[0] = 500,
		[3600] = 500,
		[7200] = 0,
		[10800] = -600,
		[14400] = 0,
		[18000] = 500,
	}
	local angle_y = {
		[0] = 0,
		[3600] = 500,
		[7200] = 500,
		[10800] = 0,
		[14400] = -500,
		[18000] = -500,
	}
	-- sticks small depot in front of mech depot and moves all resources to it (max of 20 000)
	function ChoGGi_Funcs.Common.EmptyMechDepot(obj, skip_delete)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = SelObject()
		else
			obj = IsKindOf(obj, "MechanizedDepot") and obj or SelObject()
		end

		if not obj or not IsKindOf(obj, "MechanizedDepot") then
			return
		end

		local res = obj.resource
		local amount = obj["GetStored_" .. res](obj)
		-- not good to be larger then this when game is saved (height limit of map objects seems to be 65536)
		if amount > 20000000 then
			amount = amount
		end
		local stock = obj.stockpiles[obj:GetNextStockpileIndex()]
		local angle = obj:GetAngle()
		-- new pos based on angle of old depot (so it's in front not inside)
		local newx = angle_x[angle]
		local newy = angle_y[angle]

		-- yeah guys. lets have two names for a resource and use them interchangeably, it'll be fine...
		local res2 = res
		if res == "PreciousMetals" then
			res2 = "RareMetals"
		end

		local x, y, z = stock:GetVisualPosXYZ()
		-- so it doesn't look weird make sure it's on a hex point

		-- create new depot, and set max amount to stored amount of old depot
		local newobj = PlaceObj("UniversalStorageDepot", {
			"template_name", "Storage" .. res2,
			"storable_resources", {res},
			"max_storage_per_resource", amount,
			-- so it doesn't look weird make sure it's on a hex point
			"Pos", HexGetNearestCenter(point(x + newx, y + newy, z)),
		})

		-- make it align with the depot
		newobj:SetAngle(angle)
		-- clean out old depot
		obj:CheatEmpty()
		-- give it a bit before filling
		CreateGameTimeThread(function()
			local time = 0
			repeat
				Sleep(250)
				time = time + 25
			until type(newobj.requester_id) == "number" or time > 5000
			-- since we set new depot max amount to old amount we can just CheatFill it
			newobj:CheatFill()
			-- goodbye to old depot
			if not skip_delete then
				Sleep(250)
				DeleteObject(obj)
			end
		end)

	end
end -- do

function ChoGGi_Funcs.Common.DeleteAllAttaches(obj)
	if obj.DestroyAttaches then
		obj:DestroyAttaches()
	end
end

do -- RetNearestResource/FindNearestResource
	local res_funcs = {}
	local res_mechdepot = {}
	--JA3
--~ 	local AllResourcesList = AllResourcesList
--~ 	for i = 1, #AllResourcesList do
--~ 		local res = AllResourcesList[i]
--~ 		res_funcs[res] = "GetStored_" .. res
--~ 		res_mechdepot[res] = "MechanizedDepot" .. res
--~ 	end

	local stockpiles_table = {}
	local stockpiles
	local function RetNearestResourceDepot(resource, obj, list, amount, skip_stocks)
		local GetStored = res_funcs[resource] or "GetStored_" .. resource
		local res_resource = resource
		local res_amount

		if list then
			stockpiles = list
			res_amount = amount
		else
			-- all stockpiles (attached to building, abandoned, and regular depots)
			if skip_stocks then
				stockpiles = MapGet("map", "ResourceStockpileBase")
			else
				table.iclear(stockpiles_table)
				stockpiles = stockpiles_table
			end
			res_amount = amount or 1000

			local labels = (obj.city or UICity).labels
			-- every resource has a mech depot
			table.iappend(stockpiles, labels[res_mechdepot[resource] or "MechanizedDepot" .. resource])

			-- labels.UniversalStorageDepot includes the "other" depots, but not the below three
			if resource == "BlackCube" then
				table.iappend(stockpiles, labels.BlackCubeDumpSite)
			elseif resource == "MysteryResource" then
				table.iappend(stockpiles, labels.MysteryDepot)
			elseif resource == "WasteRock" then
				table.iappend(stockpiles, labels.WasteRockDumpSite)
			else
				table.iappend(stockpiles, labels.UniversalStorageDepot)
			end
		end

		return FindNearestObject(stockpiles, obj:GetPos():SetInvalidZ(), function(depot)
			-- check if depot has the resource
			if (depot.resource == res_resource or table.find(depot.resource, res_resource))
				-- check if depot has resource amount
				and (
					depot[GetStored] and depot[GetStored](depot) >= res_amount or
					depot[resource] and depot[resource] >= res_amount
				)
			then
				return true
			end
		end)
	end
	ChoGGi_Funcs.Common.RetNearestResourceDepot = RetNearestResourceDepot

	function ChoGGi_Funcs.Common.FindNearestResource(obj)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") or not obj then
			obj = SelObject()
		end

		if not IsValid(obj) then
			MsgPopup(
				T(302535920000027--[[Nothing selected]]),
				T(302535920000028--[[Find Resource]])
			)
			return
		end

		-- build list of resources
		local item_list = {}
		local ResourceDescription = ResourceDescription
		local res = ChoGGi.Tables.Resources
		local TagLookupTable = const.TagLookupTable
		for i = 1, #res do
			local item = ResourceDescription[table.find(ResourceDescription, "name", res[i])]
			item_list[i] = {
				text = Translate(item.display_name),
				value = item.name,
				icon = TagLookupTable["icon_" .. item.name],
			}
		end

		local function CallBackFunc(choice)
			if choice.nothing_selected then
				return
			end
			local value = choice[1].value
			if type(value) == "string" then
				local nearest = RetNearestResourceDepot(value, obj)
				-- If there's no resource then there's no "nearest"
				if nearest then
					-- the power of god
					ViewObjectMars(nearest)
					ChoGGi_Funcs.Common.AddBlinkyToObj(nearest)
				else
					MsgPopup(
						Translate(302535920000029--[[Error: Cannot find any %s.]]):format(choice[1].text),
						T(15--[[Resource]])
					)
				end

			end
		end

		ChoGGi_Funcs.Common.OpenInListChoice{
			callback = CallBackFunc,
			items = item_list,
			title = T(302535920000031--[[Find Nearest Resource]]) .. ": " .. RetName(obj),
			hint = T(302535920000032--[[Select a resource to find]]),
			skip_sort = true,
			custom_type = 7,
		}
	end
end

do -- BuildingConsumption
	local function AddConsumption(obj, name, class, override_name)
		if not obj:IsKindOf(class) then
			return
		end
		local tempname = "ChoGGi_mod_" .. name
		-- If this is here we know it has what we need so no need to check for mod/consump
		if obj[tempname] then
			local mod = obj.modifications[name]
			if mod[1] then
				mod = mod[1]
			end
			if mod.IsKindOf then
				local orig = obj[tempname]
				if mod:IsKindOf("ObjectModifier") then
					mod:Change(orig.amount, orig.percent)
				else
					mod.amount = orig.amount
					mod.percent = orig.percent
				end
			end
			obj[tempname] = nil
		end
		local amount = BuildingTemplates[obj.template_name][override_name or name]
		obj:SetBase(name, amount)
	end
	local function RemoveConsumption(obj, name, class)
		if not obj:IsKindOf(class) then
			return
		end
		local mods = obj.modifications
		if mods and mods[name] then
			local mod = obj.modifications[name]
			if mod[1] then
				mod = mod[1]
			end
			local tempname = "ChoGGi_mod_" .. name
			if not obj[tempname] then
				obj[tempname] = {
					amount = mod.amount,
					percent = mod.percent
				}
			end
			if mod.IsKindOf and mod:IsKindOf("ObjectModifier") then
				mod:Change(0, 0)
			end
		end
		obj:SetBase(name, 0)
	end

	function ChoGGi_Funcs.Common.RemoveBuildingWaterConsump(obj)
		RemoveConsumption(obj, "water_consumption", "LifeSupportConsumer")
		if obj:IsKindOf("LandscapeLake") then
			obj.irrigation = -obj:GetDefaultPropertyValue("irrigation")
			ChoGGi_Funcs.Common.ToggleWorking(obj)
		end
	end
	function ChoGGi_Funcs.Common.AddBuildingWaterConsump(obj)
		AddConsumption(obj, "water_consumption", "LifeSupportConsumer")
		if obj:IsKindOf("LandscapeLake") then
			obj.irrigation = obj:GetDefaultPropertyValue("irrigation")
			ChoGGi_Funcs.Common.ToggleWorking(obj)
		end
	end
	function ChoGGi_Funcs.Common.RemoveBuildingElecConsump(obj)
		RemoveConsumption(obj, "electricity_consumption", "ElectricityConsumer")
		if obj:IsKindOf("Elevator") then
			RemoveConsumption(obj, "electricity_base_consumption", "ElectricityConsumer")
		end
	end
	function ChoGGi_Funcs.Common.AddBuildingElecConsump(obj)
		AddConsumption(obj, "electricity_consumption", "ElectricityConsumer")
		if obj:IsKindOf("Elevator") then
			AddConsumption(obj, "electricity_base_consumption", "ElectricityConsumer", "electricity_consumption")
		end
	end
	function ChoGGi_Funcs.Common.RemoveBuildingAirConsump(obj)
		RemoveConsumption(obj, "air_consumption", "LifeSupportConsumer")
	end
	function ChoGGi_Funcs.Common.AddBuildingAirConsump(obj)
		AddConsumption(obj, "air_consumption", "LifeSupportConsumer")
	end
end -- do

function ChoGGi_Funcs.Common.CollisionsObject_Toggle(obj, skip_msg)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = SelObject()
		skip_msg = nil
	else
		obj = obj or SelObject()
	end

	if not IsValid(obj) then
		if not skip_msg then
			MsgPopup(
				T(302535920000027--[[Nothing selected]]),
				T(302535920000968--[[Collisions]])
			)
		end
		return
	end
	local collision = const.efCollision + const.efApplyToGrids

	local which
	-- hopefully give it a bit more speed
	SuspendPassEdits("ChoGGi_Funcs.Common.CollisionsObject_Toggle")
	-- re-enable col on obj and any attaches
	if obj.ChoGGi_CollisionsDisabled then
		-- collision on object
		obj:SetEnumFlags(collision)
		-- and any attaches
		if obj.ForEachAttach then
			obj:ForEachAttach(function(a)
				a:SetEnumFlags(collision)
			end)
		end
		obj.ChoGGi_CollisionsDisabled = nil
		which = Translate(12227--[[Enabled]])
	else
		obj:ClearEnumFlags(collision)
		if obj.ForEachAttach then
			obj:ForEachAttach(function(a)
				a:ClearEnumFlags(collision)
			end)
		end
		obj.ChoGGi_CollisionsDisabled = true
		which = Translate(847439380056--[[Disabled]])
	end
	ResumePassEdits("ChoGGi_Funcs.Common.CollisionsObject_Toggle")

	if not skip_msg then
		MsgPopup(
			Translate(302535920000969--[[Collisions %s on %s]]):format(which, RetName(obj)),
			T(302535920000968--[[Collisions]]),
			{objects = obj}
		)
	end
end

function ChoGGi_Funcs.Common.ToggleCollisions(cls)
	-- pretty much the only thing I use it for, but just in case
	if not cls then
		cls = "LifeSupportGridElement"
	end
	local CollisionsObject_Toggle = ChoGGi_Funcs.Common.CollisionsObject_Toggle
	-- hopefully give it a bit more speed
	SuspendPassEdits("ChoGGi_Funcs.Common.ToggleCollisions")
	MapForEach("map", cls, function(o)
		CollisionsObject_Toggle(o, true)
	end)
	ResumePassEdits("ChoGGi_Funcs.Common.ToggleCollisions")
end

do -- AddXTemplate/RemoveXTemplateSections
	local function RemoveTableItem(list, name, value)
		local idx = table.find(list, name, value)
		if idx then
			if not type(list[idx]) == "function" then
				list[idx]:delete()
			end
			table.remove(list, idx)
		end
	end
	ChoGGi_Funcs.Common.RemoveTableItem = RemoveTableItem

	-- check for and remove old object (XTemplates are created on new game/new dlc ?)
	local function RemoveXTemplateSections(list, name, value)
		RemoveTableItem(list, name, value or true)
	end
	ChoGGi_Funcs.Common.RemoveXTemplateSections = RemoveXTemplateSections

	local empty_func = empty_func
	local function RetTrue()
		return true
	end
	local function RetParent(self)
		return self.parent
	end
	local function AddTemplate(xt, name, pos, list)
		if not xt or not name or not list then
			local f = ObjPropertyListToLuaCode
			print(Translate(302535920001383--[[AddXTemplate borked template name: %s template: %s list: %s]]):format(name and f(name), template and f(template), list and f(list)))
			return
		end
		local stored_name = "ChoGGi_Template_" .. name

		RemoveXTemplateSections(xt, stored_name)
		pos = pos or #xt
		if pos < 1 then
			pos = 1
		end
		table.insert(xt, pos, PlaceObj("XTemplateTemplate", {
			-- legacy ref
			stored_name, true,
			-- new ref
			"Id", stored_name,
			"__condition", list.__condition or RetTrue,
			"__context_of_kind", list.__context_of_kind or "",
			"__template", list.__template or "InfopanelActiveSection",
			"Title", list.Title or T(302535920001726--[[Title]]),
			"Icon", list.Icon or "UI/Icons/gpmc_system_shine.tga",
			"RolloverTitle", list.RolloverTitle or T(302535920001717--[[Info]]),
			"RolloverText", list.RolloverText or T(302535920001717--[[Info]]),
			"RolloverHint", list.RolloverHint or "",
			"OnContextUpdate", list.OnContextUpdate or empty_func,
		}, {
			PlaceObj("XTemplateFunc", {
				"name", "OnActivate(self, context)",
				"parent", RetParent,
				"func", list.func or empty_func,
			})
		}))
	end

	-- new	xt, 		name, 		pos, 	list
		--~ AddXTemplate(XTemplates.ipColonist[1], "LockworkplaceColonist", nil, {
	-- old: name, template, list, toplevel
		--~ AddXTemplate("SolariaTelepresence_sectionWorkplace1", "sectionWorkplace", {
	function ChoGGi_Funcs.Common.AddXTemplate(xt, name, pos, list)
		if type(xt) == "string" then
			if list then
				AddTemplate(XTemplates[name], xt, nil, pos)
			else
				AddTemplate(XTemplates[name][1], xt, nil, pos)
			end
		else
			AddTemplate(xt, name, pos, list)
		end
	end
end -- do

local function CheatsMenu_Toggle()
	local menu = XShortcutsTarget
	if ChoGGi.UserSettings.KeepCheatsMenuPosition then
		ChoGGi.UserSettings.KeepCheatsMenuPosition = menu:GetPos()
	end
	if menu:GetVisible() then
		menu:SetVisible()
	else
		menu:SetVisible(true)
	end
	ChoGGi_Funcs.Common.SetCheatsMenuPos()
end
ChoGGi_Funcs.Common.CheatsMenu_Toggle = CheatsMenu_Toggle

do -- UpdateConsoleMargins
	local IsEditorActive = IsEditorActive
	local box = box

	local margins
	if what_game == "Mars" then
		margins = GetSafeMargins()
	else
		--JA3
		margins = GetSafeAreaBox()
	end

	-- normally visible
	local margin_vis = box(10, 80, 10, 65) + margins
	-- console hidden
	local margin_hidden = box(10, 80, 10, 10) + margins
	local margin_vis_editor_log = box(10, 80, 10, 45) + margins
	local margin_vis_con_log = box(10, 80, 10, 115) + margins
	local con_margin_editor = box(0, 0, 0, 50) + margins
	local con_margin_norm = box(0, 0, 0, 0) + margins
--~ box(left/x, top/y, right/w, bottom/h) :minx() :miny() :sizex() :sizey()
	if Platform.durango then
		margin_vis = box(60, 80, 10, 65) + margins
		margin_hidden = box(60, 80, 10, 10) + margins
		margin_vis_editor_log = box(60, 80, 10, 45) + margins
		margin_vis_con_log = box(60, 80, 10, 115) + margins
		con_margin_norm = box(50, -50, 0, 0) + margins
	end

	function ChoGGi_Funcs.Common.UpdateConsoleMargins(console_vis)
		local e = IsEditorActive()
		-- editor mode adds a toolbar to the bottom, so we go above it
		if dlgConsole then
			dlgConsole:SetMargins(e and con_margin_editor or con_margin_norm)
		end
		-- move log text above the buttons i added and make sure log text stays below the cheat menu
		if dlgConsoleLog then
			if console_vis then
				dlgConsoleLog.idText:SetMargins(e and margin_vis_con_log or margin_vis)
			else
				dlgConsoleLog.idText:SetMargins(e and margin_vis_editor_log or margin_hidden)
			end
		end
	end
end -- do

do -- Editor toggle
	local editor_active

	-- These are from Commonlua\core\const.lua
	local const = const
	const.ebtTerrainType = 0
	const.ebtRoadType = 1
	const.ebtTerrainSetHeight = 2
	const.ebtTerrainChangeHeight = 3
	const.ebtTerrainSmoothHeight = 4
	const.ebtObjects = 7
	const.ebtDeleteObjects = 8
	const.ebtPlaceObjects = 9
	const.ebtPlaceSingleObject = 10
	const.ebtGizmoMove = 11
	const.ebtGizmoScale = 12
	const.ebtGizmoRotate = 13
	const.ebtZBrush = 14
	const.ebtEnrichTerrain = 15
	const.ebtVertexPushHeight = 16
	const.ebtTerrainMakePath = 17
	const.ebtTerrainRamp = 18
	const.ebtPassability = 19
	const.ebtNull = 20
	const.ebtCombine = 21
	const.ebtTerrainErodeHeight = 22
	const.ErodeIterations = 3
	const.ErodeAmount = 50
	const.ErodePersist = 5
	const.ErodeThreshold = 50
	const.ErodeCoefDiag = 500
	const.ErodeCoefRect = 1000
	const.RenderGizmoScreenDist = "20.0"
	const.AxisCylinderRadius = "0.10"
	const.AxisCylinderHeight = "2.0"
	const.AxisCylinderSlices = 10
	const.AxisConusRadius = "0.35"
	const.AxisConusHeight = "1.0"
	const.AxisConusSlices = 10
	const.PlaneLineRadius = "0.05"
	const.PlaneLineHeight = "1.5"
	const.PlaneLineSlices = 10
	const.XAxisColor = RGB(192, 0, 0)
	const.YAxisColor = RGB(0, 192, 0)
	const.ZAxisColor = RGB(0, 0, 192)
	const.XAxisColorSelected = RGB(255, 255, 0)
	const.YAxisColorSelected = RGB(255, 255, 0)
	const.ZAxisColorSelected = RGB(255, 255, 0)
	const.PlaneColor = RGBA(255, 255, 0, 200)
	const.MaxSingleScale = "3.0"
	const.PyramidSize = "0.5"
	const.PyramidSideRadius = "0.07"
	const.PyramidSideSlices = 10
	const.PyramidColor = RGB(0, 192, 192)
	const.SelectedSideColor = RGBA(255, 255, 0, 200)
	const.MapDirections = 8
	const.AxisRadius = "0.05"
	const.AxisLength = "1.5"
	const.AxisSlices = 5
	const.TorusRadius1 = "1.30"
	const.TorusRadius2 = "0.1"
	const.TorusRings = 15
	const.TorusSlices = 10
	const.TangentRadius = "0.1"
	const.TangentLength = "2.5"
	const.TangentSlices = 5
	const.TangentColor = RGB(255, 0, 255)
	const.TangentConusHeight = "0.50"
	const.TangentConusRadius = "0.30"
	const.BigTorusColor = RGB(0, 192, 192)
	const.BigTorusColorSelected = RGB(255, 255, 0)
	const.SphereColor = RGBA(128, 128, 128, 100)
	const.SphereRings = 15
	const.SphereSlices = 15
	const.BigTorusRadius = "2.0"
	const.BigTorusRadius2 = "0.10"
	const.BigTorusRings = 15
	const.BigTorusSlices = 10
	const.SnapRadius = 20
	const.SnapBoxSize = "0.1"
	const.SnapDistXYTolerance = 10
	const.SnapDistZTolerance = 2
	const.SnapScaleTolerance = 200
	const.SnapAngleTolerance = 720
	const.SnapDistXYCoef = 1
	const.SnapDistZCoef = 3
	const.SnapAngleCoef = 3
	const.SnapScaleCoef = 2
	const.SnapDrawWarningFitnessTreshold = 4000
	const.MinBrushDensity = 30
	const.MaxBrushDensity = 97

	function ChoGGi_Funcs.Common.Editor_Toggle()
		if Platform.durango then
			local str = T(302535920001574--[[Crashes on XBOX!]])
			print(str)
			MsgPopup(str)
			return
		end

		-- force editor to toggle once (makes status text work properly the "first" toggle instead of the second)
		local idx = table.find(terminal.desktop, "class", "EditorInterface")
		if not idx then
			EditorState(1, 1)
			EditorDeactivate()
		end

		if IsEditorActive() then
			EditorDeactivate()
			editor_active = false
			Platform.developer = false
			-- restore cheats menu
			XShortcutsTarget:SetVisible()
			XShortcutsTarget:SetVisible(true)
		else
			editor_active = true
			Platform.developer = true
			table.change(hr, "Editor", {
				ResolutionPercent = 100,
				DynResTargetFps = 0,
				EnablePreciseSelection = 1,
				ObjectCounter = 1,
				VerticesCounter = 1,
				FarZ = 1500000,
			})
			XShortcutsSetMode("Editor", function()
				EditorDeactivate()
			end)
			EditorState(1, 1)
		end

		ChoGGi_Funcs.Common.UpdateConsoleMargins()

		camera.Unlock(1)
		ChoGGi_Funcs.Common.SetCameraSettings()
	end

	function ChoGGi_Funcs.Common.TerrainEditor_Toggle()
		if Platform.durango then
			local str = T(302535920001574--[[Crashes on XBOX!]])
			print(str)
			MsgPopup(str)
			return
		end
		ChoGGi_Funcs.Common.Editor_Toggle()
		local ToggleCollisions = ChoGGi_Funcs.Common.ToggleCollisions
		if editor_active then
			editor.ClearSel()
			-- need to set it to something
			SetEditorBrush(const.ebtTerrainType)
		else
			-- disable collisions on pipes beforehand, so they don't get marked as uneven terrain
			ToggleCollisions()
--~ 			-- update uneven terrain checker thingy
--~ 			ActiveGameMap:RefreshBuildableGrid()
			-- and back on when we're done
			ToggleCollisions()
			-- close dialog
			if Dialogs.TerrainBrushesDlg then
				Dialogs.TerrainBrushesDlg:delete()
			end
			-- update flight grid so shuttles don't fly into newly added mountains
			FlightCaches[ActiveMapID]:OnHeightChanged()

		end
	end

	function ChoGGi_Funcs.Common.PlaceObjects_Toggle()
		if Platform.durango then
			local str = T(302535920001574--[[Crashes on XBOX!]])
			print(str)
			MsgPopup(str)
			return
		end
		ChoGGi_Funcs.Common.Editor_Toggle()
		if editor_active then
			editor.ClearSel()
			-- place rocks/etc
			SetEditorBrush(const.ebtPlaceSingleObject)
		else
			-- close dialog
			if Dialogs.PlaceObjectDlg then
				Dialogs.PlaceObjectDlg:delete()
			end
		end
	end
end -- do

-- set task request to new amount (for some reason changing the "limit" will also boost the stored amount)
-- this will reset it back to whatever it was after changing it.
function ChoGGi_Funcs.Common.SetTaskReqAmount(obj, value, task, setting, task_num)
--~ ChoGGi_Funcs.Common.SetTaskReqAmount(rocket, value, "export_requests", "max_export_storage")
	-- If it's in a table, it's almost always [1], i'm sure i'll have lots of crap to fix on any update anyways, so screw it
	if type(obj[task]) == "userdata" then
		task = obj[task]
	else
		task = obj[task][task_num or 1]
	end

	-- get stored amount
	local amount = obj[setting] - task:GetActualAmount()
	-- set new amount
	obj[setting] = value
	-- and reset 'er
	task:ResetAmount(obj[setting])
	-- then add stored, but don't set to above new limit or it'll look weird (and could mess stuff up)
	if amount > obj[setting] then
		task:AddAmount(-obj[setting])
	else
		task:AddAmount(-amount)
	end
end

function ChoGGi_Funcs.Common.ReturnEditorType(list, key, value)
	local idx = table.find(list, key, value)
	value = list[idx].editor
	-- I use it to compare to type() so
	if value == "bool" then
		return "boolean"
	elseif value == "text" or value == "combo" then
		return "string"
	else
		-- at least number is number, and i don't give a crap about the rest
		return value
	end
end

do -- AddBlinkyToObj
	local DeleteThread = DeleteThread
	local IsValid = IsValid
	local blinky_obj
	local blinky_thread

	function ChoGGi_Funcs.Common.AddBlinkyToObj(obj, timeout)
		if not IsValid(obj) then
			return
		end
		-- If it was attached to something deleted, or fresh start
		if not IsValid(blinky_obj) then
			blinky_obj = RotatyThing:new()
		end
		blinky_obj.ChoGGi_blinky = true
		-- stop any previous countdown
		DeleteThread(blinky_thread)
		-- make it visible in case it isn't
		blinky_obj:SetVisible(true)
		-- pick a spot to show it
		local spot
		local offset = 0
		if obj:HasSpot("Top") then
			spot = obj:GetSpotBeginIndex("Top")
		else
			spot = obj:GetSpotBeginIndex("Origin")
			offset = obj:GetEntityBBox():sizey()
			-- If it's larger then a dome, but isn't a BaseBuilding then we'll just ignore it (DomeGeoscapeWater)
			if offset > 10000 and not obj:IsKindOf("BaseBuilding") or offset < 250 then
				offset = 250
			end
		end
		-- attach blinky so it's noticeable
		obj:Attach(blinky_obj, spot)
		blinky_obj:SetAttachOffset(point(0, 0, offset))
		-- hide blinky after we select something else or timeout, we don't delete since we move it from obj to obj
		blinky_thread = CreateRealTimeThread(function()
			WaitMsg("SelectedObjChange", timeout or 5000)
			blinky_obj:SetVisible()
		end)
	end
end -- do

function ChoGGi_Funcs.Common.PlaceLastSelectedConstructedBld()
	local obj = ChoGGi_Funcs.Common.SelObject()
	local Temp = ChoGGi.Temp

	if obj then
		Temp.LastPlacedObject = obj
	elseif Temp.LastPlacedObject then
		obj = Temp.LastPlacedObject
	else
		obj = UICity and UICity.LastConstructedBuilding
	end

	if obj and obj.class then
		local obj_class = ChoGGi_Funcs.Common.RetTemplateOrClass(obj)
		if obj_class == "ConstructionSite" then
			obj_class = obj.building_class
		end
		ChoGGi_Funcs.Common.ConstructionModeSet(obj_class)
	end
end

-- place item under the mouse for construction
function ChoGGi_Funcs.Common.ConstructionModeSet(itemname)
	-- make sure it's closed so we don't mess up selection
	if GetDialog("XBuildMenu") then
		CloseDialog("XBuildMenu")
	end
	-- fix up some names
	itemname = ChoGGi.Tables.ConstructionNamesListFix[itemname] or itemname

	-- n all the rest
	local igi = Dialogs.InGameInterface
	if not igi or not igi:GetVisible() then
		return
	end

	local bld_template = BuildingTemplates[itemname]
	if not bld_template then
		return
	end
	local _, _, can_build, action = UIGetBuildingPrerequisites(bld_template.build_category, bld_template, true)

	local dlg = Dialogs.XBuildMenu
	local name = bld_template.id ~= "" and bld_template.id or bld_template.template_name or bld_template.template_class
	if action then
		action(dlg, {
			enabled = can_build,
			name = name,
			construction_mode = bld_template.construction_mode
		})
	-- ?
	else
		igi:SetMode("construction", {
			template = name,
			selected_dome = dlg and dlg.context.selected_dome
		})
	end
	CloseDialog("XBuildMenu")
end

function ChoGGi_Funcs.Common.DeleteLargeRocks()
	local function CallBackFunc(answer)
		if answer then
			SuspendPassEdits("ChoGGi_Funcs.Common.DeleteLargeRocks")
			MapDelete("map", {"Deposition", "WasteRockObstructorSmall", "WasteRockObstructor"})
			ResumePassEdits("ChoGGi_Funcs.Common.DeleteLargeRocks")
		end
	end
	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. T(302535920001238--[[Removes rocks for that smooth map feel.]]),
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " .. T(302535920000855--[[Last chance before deletion!]])
	)
end

function ChoGGi_Funcs.Common.DeleteSmallRocks()
	local function CallBackFunc(answer)
		if answer then
			SuspendPassEdits("ChoGGi_Funcs.Common.DeleteSmallRocks")
			MapDelete("map", "StoneSmall")
			ResumePassEdits("ChoGGi_Funcs.Common.DeleteSmallRocks")
		end
	end
	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. T(302535920001238--[[Removes rocks for that smooth map feel.]]),
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " ..T(302535920000855--[[Last chance before deletion!]])
	)
end

do -- UpdateGrowthThreads
	-- clean up any invalid veg objs with just deleted objs in the animator thread obj lists
	local lists = {
		"managed_beautification_objects",
		"managed_objects",
	}
	function ChoGGi_Funcs.Common.UpdateGrowthThreads()

		-- I mean someone could make a mod to grow trees underground
		local GameMaps = GameMaps
		for _, map in pairs(GameMaps) do

			local objs = map.realm:MapGet("map", "VegetationAnimator")

			for i = 1, #objs do
				local obj = objs[i]

				for j = 1, #lists do
					local threads = obj[lists[j]]
					for k = #threads, 1, -1 do
						if not IsValid(threads[k]) then
							table.remove(threads, k)
						end
					end
				end

				if #obj.managed_beautification_objects + #obj.managed_objects == 0 then
					obj:delete()
				end

			end
		end

	end
end

-- build and show a list of attachments for changing their colours
function ChoGGi_Funcs.Common.CreateObjectListAndAttaches(obj)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = SelObject()
	else
		obj = obj or SelObject()
	end

	if not obj or obj and not obj:IsKindOf("ColorizableObject") then
		MsgPopup(
			T(302535920001105--[[Select/mouse over an object (buildings, vehicles, signs, rocky outcrops).]]),
			T(3595--[[Color]])
		)
		return
	end

	local item_list = {}
	local c = 0

	-- has no Attaches so just open as is
	if obj.CountAttaches and obj:CountAttaches() == 0 then
		ChoGGi_Funcs.Common.ChangeObjectColour(obj)
		return
	else
		c = c + 1
		item_list[c] = {
			text = " " .. obj.class,
			value = obj.class,
			obj = obj,
			hint = T(302535920001106--[[Change main object colours.]]),
		}

		local attaches = GetAllAttaches(obj)
		for i = 1, #attaches do
			local a = attaches[i]
			if a:IsKindOf("ColorizableObject") then
				c = c + 1
				item_list[c] = {
					text = a.class,
					value = a.class,
					parentobj = obj,
					obj = a,
					hint = T(302535920001107--[[Change colours of an attached object.]]) .. "\n"
						.. T(302535920000955--[[Handle]]) .. ": " .. (a.handle or ""),
				}
			end
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		items = item_list,
		title = T(302535920001708--[[Color Modifier]]) .. ": " .. RetName(obj),
		hint = T(302535920001108--[[Double click to open object/attachment to edit (select to flash object).]]),
		custom_type = 1,
		custom_func = function(sel, dialog)
			ChoGGi_Funcs.Common.ChangeObjectColour(sel[1].obj, sel[1].parentobj, dialog)
		end,
		select_flash = true,
	}
end

function ChoGGi_Funcs.Common.OpenGedApp(template, root, context, id)
	if type(template) ~= "string" then
		template = "XWindowInspector"
	end
	(ChoGGi_Funcs.Original.OpenGedApp or OpenGedApp)(template, root or terminal.desktop, context, id)
end

do -- MovePointAwayXY
	local CalcZForInterpolation = CalcZForInterpolation
	local SetLen = SetLen
	-- this is the same as MovePointAway, but uses Z from src
	function ChoGGi_Funcs.Common.MovePointAwayXY(src, dest, dist)
		dest, src = CalcZForInterpolation(dest, src)

		local v = dest - src
		v = SetLen(v, dist)
		v = src - v
		return v:SetZ(src:z())
	end
	-- this is the same as MovePoint, but uses Z from src
	function ChoGGi_Funcs.Common.MovePointXY(src, dest, dist)
		dest, src = CalcZForInterpolation(dest, src)
		local v = dest - src
		if dist < v:Len() then
			v = SetLen(v, dist)
		end
		v = src + v
		return v:SetZ(src:z())
	end
end -- do

-- updates buildmenu with un/locked buildings if it's opened
-- RefreshXBuildMenu() doesn't add newly unlocked buildings
function ChoGGi_Funcs.Common.UpdateBuildMenu()
	local dlg = GetDialog("XBuildMenu")
	-- can't update what isn't there
	if dlg then
		-- only update categories if we need to
		local cats = dlg:GetCategories()
		local old_cats = dlg.idCategoryList.idCategoriesList
		local old_cats_c = #old_cats
		-- - 1 for the hidden cat
		if (#cats - 1) ~= old_cats_c then
			-- clear out old categories
			for i = old_cats_c, 1, -1 do
				old_cats[i]:delete()
			end
			-- add all new stuffs
			dlg:CreateCategoryItems(cats)
		end

		-- update item list (RefreshXBuildMenu())
		dlg:SelectCategory(dlg.category)
	end
end

function ChoGGi_Funcs.Common.SetTableValue(tab, id, id_name, item, value)
	local idx = table.find(tab, id, id_name)
	if idx then
		tab[idx][item] = value
		return tab[idx]
	end
end

do -- PadNumWithZeros
	local pads = {}
	-- 100, 00000 = "00100"
	function ChoGGi_Funcs.Common.PadNumWithZeros(num, pad)
		if pad then
			pad = pad .. ""
		else
			pad = "00000"
		end
		num = num .. ""

		-- build a table of string 0
		table.iclear(pads)
		local diff = #pad - #num
		for i = 1, diff do
			pads[i] = "0"
		end
		pads[diff+1] = num

		return table.concat(pads)
	end
end -- do

function ChoGGi_Funcs.Common.RemoveObjsAllMaps(class)
	local GameMaps = GameMaps
	for _, map in pairs(GameMaps) do
		map.realm:MapDelete(true, class)
	end
end

-- ChoGGi_Funcs.Common.RemoveObjs("VegetationAnimator")
function ChoGGi_Funcs.Common.RemoveObjs(class, skip_suspend, skip_all_maps)
	if not skip_suspend then
		-- suspending pass edits makes deleting much faster
		SuspendPassEdits("ChoGGi_Funcs.Common.RemoveObjs")
	end

	local RemoveObjsAllMaps = ChoGGi_Funcs.Common.RemoveObjsAllMaps

	if type(class) == "table" then
		local g_Classes = g_Classes

		for _ = 1, #class do
			-- If it isn't a valid class then Map* will return all objects :(
			if g_Classes[class] then
				if skip_all_maps then
					MapDelete(true, class)
				else
					RemoveObjsAllMaps(class)
				end
			end
		end
	else
		if g_Classes[class] then
			if skip_all_maps then
				MapDelete(true, class)
			else
				RemoveObjsAllMaps(class)
			end
		end
	end

	if not skip_suspend then
		ResumePassEdits("ChoGGi_Funcs.Common.RemoveObjs")
	end
end
ChoGGi_Funcs.Common.MapDelete = ChoGGi_Funcs.Common.RemoveObjs

-- SpawnColonist
if what_game == "Mars" then
	local Msg = Msg
	local GenerateColonistData = GenerateColonistData

	function ChoGGi_Funcs.Common.SpawnColonist(old_c, building, pos, city)
		city = city or UICity

		local colonist
		if old_c then
			colonist = GenerateColonistData(city, old_c.age_trait, false, {
				gender = old_c.gender,
				entity_gender = old_c.entity_gender,
				no_traits	=	"no_traits",
				no_specialization = true,
			})
			-- we set all the set gen doesn't (it's more for random gen after all
			colonist.birthplace = old_c.birthplace
			colonist.death_age = old_c.death_age
			colonist.name = old_c.name
			colonist.race = old_c.race
			for trait_id in pairs(old_c.traits) do
				if trait_id and trait_id ~= "" then
					colonist.traits[trait_id] = true
				end
			end
		else
			-- GenerateColonistData(city, age_trait, martianborn, gender, entity_gender, no_traits)
			colonist = GenerateColonistData(city)
		end

		Colonist:new(colonist)
		Msg("ColonistBorn", colonist)

		-- can't fire till after :new()
		if old_c then
			if old_c.specialist ~= "none" then
				old_c:RemoveTrait(old_c.specialist)
			end
			old_c:AddTrait(old_c.specialist)
--~ 			colonist:SetSpecialization(old_c.specialist)
		end
		local realm = GetRealm(colonist)
		colonist:SetPos((pos
			or building and realm:GetPassablePointNearby(building:GetPos())
			or realm:GetRandomPassablePoint()):SetTerrainZ()
		)

		-- If age/spec is different this updates to new entity
		colonist:ChooseEntity()

		return colonist
	end
end -- what_game

do -- IsControlPressed/IsShiftPressed/IsAltPressed
	local IsKeyPressed = terminal.IsKeyPressed
	local vkControl = const.vkControl
	local vkShift = const.vkShift
	local vkAlt = const.vkAlt
	local vkLwin = const.vkLwin
	local osx = Platform.osx
	local XInput_IsControllerConnected = XInput.IsControllerConnected
	local XInput_IsCtrlButtonPressed = XInput.IsCtrlButtonPressed

	local function IsControlPressed()
		return IsKeyPressed(vkControl) or osx and IsKeyPressed(vkLwin)
	end
	ChoGGi_Funcs.Common.IsControlPressed = IsControlPressed
	ChoGGi_Funcs.Common.IsCtrlPressed = IsControlPressed
	function ChoGGi_Funcs.Common.IsShiftPressed()
		return IsKeyPressed(vkShift)
	end
	function ChoGGi_Funcs.Common.IsAltPressed()
		return IsKeyPressed(vkAlt)
	end
	function ChoGGi_Funcs.Common.IsGamepadButtonPressed(button)
		return XInput_IsCtrlButtonPressed(XInput_IsControllerConnected(s_XInputControllersConnected-1), button)
	end
end -- do

-- if it's an object than we can Clone() it, otherwise copy it
function ChoGGi_Funcs.Common.CopyTable(list)
	local new
	if list.class and g_Classes[list.class] then
		new = list:Clone()
	else
		new = {}
	end

	for key, value in pairs(list) do
		new[key] = value
	end
	return new
end

-- associative tables only, otherwise table.is_iequal(t1, t1)
function ChoGGi_Funcs.Common.TableIsEqual(t1, t2)
	-- see which one is longer, we use that as the looper
	local c1, c2 = 0, 0
	for _ in pairs(t1) do
		c1 = c1 + 1
	end
	for _ in pairs(t2) do
		c1 = c1 + 1
	end

	local is_equal = true
	if c1 >= c2 then
		for key, value in pairs(t1) do
			if value ~= t2[key] then
				is_equal = false
				break
			end
		end
	else
		for key, value in pairs(t2) do
			if value ~= t1[key] then
				is_equal = false
				break
			end
		end
	end

	return is_equal
end

-- LoadEntity
if what_game == "Mars" then
	-- no sense in making a new one for each entity
	local entity_templates = {
		decal = {
			category_Decors = true,
			entity = {
				fade_category = "Never",
				material_type = "Metal",
			},
		},
		building = {
			category_Buildings = true,
			entity = {
				class_parent = "BuildingEntityClass",
				fade_category = "Never",
				material_type = "Metal",
			},
		},
		terrain = {
			category_StonesRocksCliffs = true,
			entity = {
				material_type = "Rock",
			},
		},
	}

	-- local instead of global is quicker
	local EntityData = EntityData
	local EntityLoadEntities = EntityLoadEntities
	local SetEntityFadeDistances = SetEntityFadeDistances

	function ChoGGi_Funcs.Common.LoadEntity(name, path, mod, template)
		EntityData[name] = entity_templates[template or "decal"]

		EntityLoadEntities[#EntityLoadEntities + 1] = {
			mod,
			name,
			path
		}
		SetEntityFadeDistances(name, -1, -1)
	end
end -- do


-- this only adds a parent, no ___BuildingUpdate/__Init or anything
-- ChoGGi_Funcs.Common.AddParentToClass(DontBuildHere, "InfopanelObj")
--~ ChoGGi_Funcs.Common.AddParentToClass(Electrolyzer, "LifeSupportConsumer")
function ChoGGi_Funcs.Common.AddParentToClass(class_obj, parent_name)
	local p = class_obj.__parents
	if p and not table.find(p, parent_name) then
		p[#p+1] = parent_name
	end
end

function ChoGGi_Funcs.Common.Add___Func(class_obj, ___key, func)
	local funcs = class_obj[___key]
	if funcs and not table.find(funcs, func) then
		funcs[#funcs+1] = func
	else
		print("Add___Func: Can't find class func:", ___key)
	end
end

function ChoGGi_Funcs.Common.RetSpotPos(obj, building, spot)
	local nearest = building:GetNearestSpot("idle", spot or "Origin", obj)
	return building:GetSpotPos(nearest)
end

function ChoGGi_Funcs.Common.RetSpotNames(obj)
	if not obj:HasEntity() then
		return
	end
	local names = {}
	local id_start, id_end = obj:GetAllSpots(obj:GetState())
	for i = id_start, id_end do
		local spot_annotation = obj:GetSpotAnnotation(i)
		local text_str = obj:GetSpotName(i) or "MISSING SPOT NAME"
		if spot_annotation then
			text_str = text_str .. ";" .. spot_annotation
		end
		names[i] = text_str
	end
	return names
end

do -- ConstructableArea
	local ConstructableArea
	function ChoGGi_Funcs.Common.ConstructableArea()
		if not ConstructableArea then
			local sizex, sizey = ActiveGameMap.terrain:GetMapSize()
			local border = 1000 or const.ConstructBorder
			ConstructableArea = box(border, border, (sizex or 0) - border, (sizey or 0) - border)
		end
		return ConstructableArea
	end
end -- do

function ChoGGi_Funcs.Common.RetTemplateOrClass(obj)
	if obj then
		return obj.template_name ~= "" and obj.template_name or obj.class
	end
	return ""
end

do -- ToggleBldFlags
	local function ToggleBldFlags(obj, flag)
		local func
		if obj:GetGameFlags(flag) == flag then
			func = "ClearGameFlags"
		else
			func = "SetGameFlags"
		end

		obj[func](obj, flag)
		local attaches = GetAllAttaches(obj)
		for i = 1, #attaches do
			local a = attaches[i]
			if not (a:IsKindOf("BuildingSign") or a:IsKindOf("GridTile") or a:IsKindOf("GridTileWater")) then
				a[func](a, flag)
			end
		end
	end
	ChoGGi_Funcs.Common.ToggleBldFlags = ToggleBldFlags

	function ChoGGi_Funcs.Common.ToggleConstructEntityView(obj)
		ToggleBldFlags(obj, 65536)
	end
	function ChoGGi_Funcs.Common.ToggleEditorEntityView(obj)
		ToggleBldFlags(obj, 2)
	end
end -- do

function ChoGGi_Funcs.Common.DoSomethingQuestion(obj, func, vars, warning)
	if not obj or not func then
		return
	end

	local name = RetName(obj)

	local function CallBackFunc(answer)
		if answer then
			func(obj, vars)
		end
	end

	if not warning then
		warning = T{302535920001740--[["Are you sure you want to proceed with <str>?"]],
			str = Translate(name),
		}
	end

	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. warning,
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " .. T(302535920001739--[[Last chance!]]),
		T(6779--[[Warning]]) .. ": " .. name,
		T(302535920001713--[[Cancel]])
	)
end

function ChoGGi_Funcs.Common.DeleteObjectQuestion(obj)
	local name = RetName(obj)

	local function CallBackFunc(answer)
		if answer then
			-- remove select from it
			if SelectedObj == obj then
				SelectObj()
			end

			if IsValidThread(obj) then
				DeleteThread(obj)
			-- map objects
			elseif IsValid(obj) then
				DeleteObject(obj)
			-- xwindows
			elseif obj.Close then
				obj:Close()
			-- whatever
			else
				obj:delete()
			end

		end
	end

	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. T{302535920000414--[["Are you sure you wish to delete <color ChoGGi_red><str></color>?"]],
			str = name,
		} .. "?",
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " .. T(302535920000855--[[Last chance before deletion!]]),
		T(5451--[[DELETE]]) .. ": " .. name,
		T(302535920001713--[[Cancel]]) .. " " .. T(302535920001689--[[Delete]])
	)
end

function ChoGGi_Funcs.Common.DeleteAllObjectQuestion(obj)
	if not UIColony then
		return
	end

	local objs
	if type(obj) == "string" then
		objs = MapGet_ChoGGi(obj)
		if #objs == 0 then
			objs = nil
		else
			obj = objs[1]
		end
	end

	local name = RetName(obj)
	local function CallBackFunc(answer)
		if answer then
			-- remove select from it
			SelectObj()

			if IsValidThread(obj) then
				for i = 1, #objs do
					DeleteThread(objs[i])
				end
			-- map objects
			elseif IsValid(obj) then
				-- DeleteObject calls SuspendPassEdits, so only :delete() below needs it
				DeleteObject(objs, true)
			-- xwindows
			elseif obj.Close then
				for i = 1, #objs do
					objs[i]:Close()
				end
			-- whatever
			else
				SuspendPassEdits("ChoGGi_Funcs.Common.DeleteAllObjectQuestion")
				for i = 1, #objs do
					objs[i]:delete()
				end
				ResumePassEdits("ChoGGi_Funcs.Common.DeleteAllObjectQuestion")
			end

		end
	end

	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. T{302535920001676--[["Are you sure you wish to delete all <color ChoGGi_red><str></color> objects? (from active map)"]],
			str = name,
		} .. "?",
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " .. T(302535920000855--[[Last chance before deletion!]]),
		T(5451--[[DELETE]]) .. ": " .. name,
		T(302535920001713--[[Cancel]]) .. " " .. T(302535920001689--[[Delete]])
	)
end

function ChoGGi_Funcs.Common.RuinObjectQuestion(obj)
	local name = RetName(obj)
	local obj_type
	if obj:IsKindOf("BaseRover") then
		obj_type = T(7825--[[Destroy this Rover.]])
	elseif obj:IsKindOf("Drone") then
		obj_type = T(7824--[[Destroy this Drone.]])
	else
		obj_type = T(7822--[[Destroy this building.]])
	end

	local function CallBackFunc(answer)
		if answer then
			if obj:IsKindOf("Dome") and #(obj.connected_domes or "") > 0 and not obj:CanDemolish() then
				MsgPopup(
					Translate(302535920001354--[["<green>%s</green> is a dome with passages (crash if deleted)."]]):format(name),
					T(302535920000489--[[Delete Object(s)]])
				)
				return
			end

			obj.can_demolish = true
			obj.indestructible = false
			obj.demolishing_countdown = 0
			obj.demolishing = true
			obj:DoDemolish()
			-- probably not needed
			DestroyBuildingImmediate(obj)

		end
	end
	ChoGGi_Funcs.Common.QuestionBox(
		T(6779--[[Warning]]) .. "!\n" .. obj_type .. "\n" .. name,
		CallBackFunc,
		T(6779--[[Warning]]) .. ": " .. obj_type,
		obj_type .. " " .. name,
		T(1176--[[Cancel Destroy]])
	)
end

do -- IsPosInMap
	local construct

	function ChoGGi_Funcs.Common.IsPosInMap(pt)
		construct = construct or ChoGGi_Funcs.Common.ConstructableArea()
		return pt:InBox2D(construct)
	end
end -- do

do -- PolylineSetParabola
	-- copy n pasta from Lua/Dev/MapTools.lua
	local Min = Min
	local ValueLerp = ValueLerp
	local function parabola(x)
		return 4 * x - x * x / 25
	end
	local guim10 = 10 * guim
	local white = white
	local vertices = {}

	function ChoGGi_Funcs.Common.PolylineSetParabola(line, from, to, colour)
		if not line then
			return
		end
		local parabola_h = Min(from:Dist(to), guim10)
		local pos_lerp = ValueLerp(from, to, 100)
		local steps = 10
		local c = 0
		table.iclear(vertices)

		for i = 0, steps do
			local x = i * (100 / steps)
			local pos = pos_lerp(x)
			pos = pos:AddZ(parabola(x) * parabola_h / 100)
			c = c + 1
			vertices[c] = pos
		end
		line:SetMesh(vertices, colour or white)
	end
end -- do

-- "idLeft", "idMiddle", "idRight"
function ChoGGi_Funcs.Common.RetHudButton(side)
	side = side or "idLeft"

	local xt = XTemplates
	local idx = table.find(xt.HUD[1], "Id", "idBottom")
	if not idx then
		print("ChoGGi RetHudButton: Missing HUD control idBottom")
		return
	end
	xt = xt.HUD[1][idx]
	idx = table.find(xt, "Id", side)
	if not idx then
		print("ChoGGi RetHudButton: Missing HUD control " .. side)
		return
	end
	return xt[idx][1]
end

-- RetMapSettings/RetMapBreakthroughs/RetObjectEntity
if what_game == "Mars" then
	-- RetMapSettings
	local GetRandomMapGenerator = GetRandomMapGenerator
	local FillRandomMapProps = FillRandomMapProps

	function ChoGGi_Funcs.Common.RetMapSettings(gen, params, ...)
		if not params then
			params = g_CurrentMapParams
		end
		if gen == true then
			gen = GetRandomMapGenerator() or {}
		end

		return FillRandomMapProps(gen, params, ...), params, gen
	end

-- RetMapBreakthroughs
--~ 	local function UnlockAnoms()
--~ 		local objs = UICity.labels.Anomaly or ""
--~ 		local c = 0
--~ 		for i = #objs, 1, -1 do
--~ 			local obj = objs[i]
--~ 			if obj:IsKindOf("SubsurfaceAnomaly_breakthrough") then
--~ 				print(obj.breakthrough_tech)
--~ 				obj:CheatScan()
--~ 				c = c + 1
--~ 			end
--~ 		end
--~ 		print("Anomaly Count", c)
--~ 		-- 8 on ground
--~ 		-- 3 omega
--~ 		-- 4 planetary
--~		-- Paradox sponsor 2-4
--~ 		-- other 5 from meteors?
--~ 	end
--~ 	UnlockAnoms()

	local StableShuffle = StableShuffle
	local CreateRand = CreateRand

	local orig_break_list
	local translated_tech
	local table_copy = table.copy

	function ChoGGi_Funcs.Common.RetMapBreakthroughs(gen, limit_count)
		-- build list of names once
		if not translated_tech then
			translated_tech = {}
			local TechDef = TechDef
			for tech_id, tech in pairs(TechDef) do
				if tech.group == "Breakthroughs" then
					translated_tech[tech_id] = Translate(tech.display_name)
				end
			end
			orig_break_list = table.imap(Presets.TechPreset.Breakthroughs, "id")
		end

		-- breakthroughs per map are 4 planetary, 3 omega, 9-13 on the ground, 5 Storybits?
		-- 13 is safe (in the sense of def getting them): 9 ground + 4 planetary
		local breakthrough_count = 13
--~ 		local breakthrough_count = const.BreakThroughTechsPerGame
--~ 		-- + const.OmegaTelescopeBreakthroughsCount, it's seed based but it shuffles the list of unregistered breakthroughs
--~ 		+ (g_Consts and g_Consts.PlanetaryBreakthroughCount or Consts.PlanetaryBreakthroughCount)
		-- g_ is the in-game object
--~ 		if limit_count and type(limit_count) == "number" then
		if limit_count and type(limit_count) == "number" then
			breakthrough_count = limit_count
		end

		-- start with a clean copy of breaks
		local break_order = table_copy(orig_break_list)
		-- Shuffle as the game does for proper order
		StableShuffle(break_order, CreateRand(true, gen.Seed, "ShuffleBreakThroughTech"), 100)
		--
		while #break_order > breakthrough_count do
			break_order[#break_order] = nil
		end

		tech_list = {}
		remove_added = {}

		local c = #break_order
		for i = 1, c do
			local id = break_order[i]
			-- translate tech
			tech_list[i] = translated_tech[id]
			remove_added[id] = true
		end

		return tech_list
	end

-- RetObjectEntity
	local GetSpecialistEntity = GetSpecialistEntity
	local IsValidEntity = IsValidEntity

	function ChoGGi_Funcs.Common.RetObjectEntity(obj)
		if not (obj and obj:IsKindOf("CObject")) then
			return
		end

		local entity
		if obj:IsKindOf("Colonist") then
			entity = GetSpecialistEntity(obj.specialist, obj.entity_gender, obj.race, obj.age_trait, obj.traits)
		else
			entity = obj:GetEntity()
		end

		if IsValidEntity(entity) then
			return entity
		end
	end
end -- do

function ChoGGi_Funcs.Common.DisastersStop()
	CheatStopDisaster()

	local missles = g_IncomingMissiles or empty_table
	for missle in pairs(missles) do
		missle:ExplodeInAir()
	end

	if g_DustStorm then
		g_DustStormDuration = 0
		StopDustStorm()
		-- (is it from a bug?)
		g_DustStormType = false
	end

	if g_ColdWave then
		StopColdWave()
		g_ColdWave = false
	end

	if g_AccessibleDlc.armstrong and g_RainDisaster then
		StopRainsDisaster()
		g_RainDisaster = false
	end

	local objs

	objs = g_DustDevils or ""
	for i = #objs, 1, -1 do
		objs[i]:delete()
	end

	objs = g_MeteorsPredicted or ""
	for i = #objs, 1, -1 do
		local o = objs[i]
		Msg("MeteorIntercepted", o)
		o:ExplodeInAir()
	end

	if g_AccessibleDlc.contentpack1 then
		objs = g_IonStorms or ""
		for i = #objs, 1, -1 do
			local obj = objs[i]
			DeleteThread(obj.storm_thread)
			obj:delete()
			table.remove(g_IonStorms, i)
		end
	end

	if g_AccessibleDlc.armstrong then
		if g_RainDisaster then
			StopRainsDisaster()
		end

		-- make sure rains stop (remove this after an update or two)
		local rain_type = "toxic"
		local disaster_data = RainsDisasterThreads[rain_type]
		if not disaster_data then
			return
		end
		DeleteThread(disaster_data.soil_thread)
		DeleteThread(disaster_data.main_thread)
		DeleteThread(disaster_data.activation_thread)
		disaster_data.activation_thread = false
		FinishRainProcedure(rain_type)
	end
end

function ChoGGi_Funcs.Common.RetTableValue(obj, key)
	local meta = getmetatable(obj)
	if meta and meta.__index then
		-- some stuff like mod.env uses the metatable from _G.__index and causes sm to log an error (still works fine though)
		if type(key) == "string" then
			-- PropObjGetProperty works better on class funcs, but it can mess up on some tables so only use it for strings)
			return PropObjGetProperty(obj, key)
		else
			return rawget(obj, key)
--~ 			return obj.key
		end
	else
		return obj[key]
	end
end

-- BuildableHexGrid
if what_game == "Mars" then
	-- this is somewhat from Lua\hex.lua: debug_build_grid()
	-- sped up to work with being attached to the mouse pos

	local UnbuildableZ = buildUnbuildableZ()
	local grid_objs = {}
	local grid_objs_c = 0
	local Temp = ChoGGi.Temp
	local OHexSpot, XText
	-- for uneven terrain in construction
	local shape_data = {
		point(-1, 0),
		point(-1, 1),
		point(0, -1),
		point(0, 0),
		point(0, 1),
		point(1, -1),
		point(1, 0),
	}
	local shape_data_c = #shape_data
	-- stripped down version of function IsTerrainFlatForPlacement(buildable_grid, shape_data, pos, angle)
	local function IsTerrainNotFlatForPlacement(buildable_z_grid, q_i, r_i)
		local original_z = false
		for i = 1, shape_data_c do
			local q, r = shape_data[i]:xy()
			q, r = q_i+q, r_i+r

			local z = buildable_z_grid:get(q+r/2, r)
			if not original_z then
				original_z = z
			end

			if z == UnbuildableZ or z ~= original_z then
				return true
			end
		end
	end

	local function CleanUp()
		-- kill off thread
		if IsValidThread(Temp.grid_thread) then
			DeleteThread(Temp.grid_thread)
		end
		-- just in case
		Temp.grid_thread = false

		-- SuspendPassEdits errors out if there's no map
		if UICity then
			SuspendPassEdits("ChoGGi_Funcs.Common.BuildableHexGrid_CleanUp")
			for i = 1, grid_objs_c do
				local o = grid_objs[i]
				if IsValid(o) then
					o:delete()
				end
			end
			ResumePassEdits("ChoGGi_Funcs.Common.BuildableHexGrid_CleanUp")
			-- clear out xwin text
			local parent = terminal.desktop.ChoGGi_BuildableHexGrid
			if IsValidXWin(parent) then
				parent:Close()
			end
		end
--~ 		table.iclear(grid_objs)
	end

	-- If grid is left on when map changes it gets real laggy
	OnMsg.ChangeMap = CleanUp
	-- make sure grid isn't saved in persist
	OnMsg.SaveGame = CleanUp

	function ChoGGi_Funcs.Common.BuildableHexGrid(action)
		local is_valid_thread = IsValidThread(Temp.grid_thread)

		local u = ChoGGi.UserSettings
		local grid_pos

		-- If not fired from action
		if IsKindOf(action, "XAction") then
			if action.setting_mask == "position" then
				grid_pos = type(u.DebugGridPosition) == "number" and u.DebugGridPosition or 0
			end
		else
			-- always start clean
			if is_valid_thread then
				CleanUp()
				is_valid_thread = false
			end
			-- If it's false then we don't want to start it again
			if action == false then
				return
			end
		end

		if not OHexSpot then
			OHexSpot = ChoGGi_OHexSpot
		end
		if not XText then
			XText = ChoGGi_XText_Follow
		end

		local grid_opacity = type(u.DebugGridOpacity) == "number" and u.DebugGridOpacity or 15
		local grid_size = type(u.DebugGridSize) == "number" and u.DebugGridSize or 25

--~ 		-- 125 = 47251 objects (had a crash at 250, and it's not like you need one that big)
--~ 		if grid_size > 256 then
--~ 			grid_size = 256
--~ 		end

		-- already running
		if is_valid_thread then
			CleanUp()
		else
			-- this loop section is just a way of building the table and applying the settings once instead of over n over in the while loop

			grid_objs_c = 0

			local parent = terminal.desktop
			if not IsValidXWin(parent.ChoGGi_BuildableHexGrid) then
				parent.ChoGGi_BuildableHexGrid = XWindow:new({
					Id = "ChoGGi_BuildableHexGrid",
				}, parent)
			end
			parent = parent.ChoGGi_BuildableHexGrid

			local q, r = 1, 1
			local z = -q - r
			SuspendPassEdits("ChoGGi_Funcs.Common.BuildHexGrid")
			local colour = RandomColourLimited()
			-- margins don't work great with the grids (or at least the ones I used)
			for q_i = q - grid_size, q + grid_size do
				for r_i = r - grid_size, r + grid_size do
					for z_i = z - grid_size, z + grid_size do
						if q_i + r_i + z_i == 0 then
							local hex = OHexSpot:new()
							hex:SetOpacity(grid_opacity)
--~ 							hex:SetNoDepthTest(true)
							grid_objs_c = grid_objs_c + 1
							grid_objs[grid_objs_c] = hex
							-- add text_obj
							if grid_pos then
								local text_obj = XText:new(nil, parent)
								text_obj:SetTextColor(colour)
								text_obj:FollowObj(hex)
								-- easy access
								hex.text_obj = text_obj
							end
						end
					end
				end
			end
			ResumePassEdits("ChoGGi_Funcs.Common.BuildHexGrid")

			if testing then
				print("BuildHexGrid count", grid_objs_c)
			end

			-- off we go
			Temp.grid_thread = CreateRealTimeThread(function()
				local ActiveGameMap = ActiveGameMap
--~ 				-- update uneven terrain checker thingy
--~ 				ActiveGameMap:RefreshBuildableGrid()

-- maybe add it back?
--~ 	-- Speed up
--~ 	SuspendPassEdits("ChoGGi_FixBBBugs_UnevenTerrain")
--~ 	SuspendTerrainInvalidations("ChoGGi_FixBBBugs_UnevenTerrain")

--~ 	game_map:RefreshBuildableGrid()

--~ 	ResumePassEdits("ChoGGi_FixBBBugs_UnevenTerrain")
--~ 	ResumeTerrainInvalidations("ChoGGi_FixBBBugs_UnevenTerrain")

				-- local all the globals we use more than once for some speed
				local buildable_z_grid = ActiveGameMap.buildable.z_grid

				local terrain = ActiveGameMap.terrain


				local VegetationGrid = VegetationGrid
				local forbid_growth = forbid_growth

				local red = red
				local green = green
				local blue = blue
				local yellow = yellow
				local white = white

				local object_hex_grid = ActiveGameMap.object_hex_grid.grid
				local const_HexSize = const.HexSize

				local g_DontBuildHere = g_DontBuildHere[ActiveMapID]

				local last_q, last_r
				-- 0, 0 to make sure it updates the first time
				local old_pt, pt = point(0, 0)

				while Temp.grid_thread do
					-- only update if cursor moved a hex
					pt = GetCursorWorldPos()
					if old_pt:Dist2D(pt) > const_HexSize then
						old_pt = pt

						local q, r = WorldToHex(pt)
						if last_q ~= q or last_r ~= r then
							local z = -q - r
							local c = 0

							for q_i = q - grid_size, q + grid_size do
								for r_i = r - grid_size, r + grid_size do
									for z_i = z - grid_size, z + grid_size do
										if q_i + r_i + z_i == 0 then
											-- get next hex marker from list, and move it to pos
											c = c + 1
											local hex = grid_objs[c]
											local pos = point(HexToWorld(q_i, r_i))
											hex:SetPos(pos)

											-- green = pass/build, yellow = no pass/build, blue = pass/no build, red = no pass/no build

											local obj = HexGridGetObject(object_hex_grid, q_i, r_i)
											-- skip! (CameraObj, among others?)
											if obj and obj.GetEntity and obj:GetEntity() == "InvisibleObject" then
												obj = nil
											end
											-- showing position grid instead of buildable grid
											if grid_pos then
												if grid_pos == 0 then
													hex.text_obj:SetText((q_i-q) .. "," .. (r_i-r))
												else
													hex.text_obj:SetText(q_i .. "," .. r_i)
												end
											else
												-- geysers
												if obj == g_DontBuildHere then
													hex:SetColorModifier(blue)
												else
													-- returns UnbuildableZ if it isn't buildable
													local q_hex_stor = q_i + r_i / 2
													local build_z = buildable_z_grid:get(q_hex_stor, r_i)
													-- check adjacent hexes for height diff, and slopes over 1024? aren't passable (let alone buildable)
													if build_z == UnbuildableZ or IsTerrainNotFlatForPlacement(buildable_z_grid, q_i, r_i) or HexSlope(q_i, r_i) > 1024 then
														hex:SetColorModifier(red)
													-- stuff that can be pathed? (or dump sites which IsPassable returns false for)
													elseif terrain:IsPassable(pos) or obj and obj.class == "WasteRockDumpSite" then
														if build_z ~= UnbuildableZ and not obj then
															hex:SetColorModifier(green)

															-- no veg here
															if testing and VegetationGrid:get(q_hex_stor, r_i) & forbid_growth == forbid_growth then
																hex:SetColorModifier(white)
															end
															-- no veg here

														else
															hex:SetColorModifier(blue)
														end
													-- any objs left aren't passable
													elseif obj then
														hex:SetColorModifier(red)
													else
														hex:SetColorModifier(yellow)
													end
												end
											end

										end
									end -- z_i
								end -- r_i
							end -- q_i

							last_q = q
							last_r = r
						else
							WaitMsg("OnRender")
						end
					end -- pt ~= old_pt

					-- might as well make it smoother (and suck up some yummy cpu), i assume nobody is going to leave it on
					WaitMsg("OnRender")
				end -- while
			end) -- grid_thread
		end
	end
end

function ChoGGi_Funcs.Common.SetWinObjectVis(obj, visible)
	if not obj then
		return
	end

	-- XWindow:GetVisible()
	if obj.target_visible then
		-- It's visible and we don't want it visible
		if not visible then
			obj:SetVisible()
		end
	else
		-- It's not visible and we want it visible
		if visible then
			obj:SetVisible(true)
		end
	end
end

-- dbg_PlantRandomVegetation(choice.value) copy pasta
function ChoGGi_Funcs.Common.PlantRandomVegetation(amount)
	SuspendPassEdits("ChoGGi_Funcs.Common.PlantRandomVegetation")
	-- might help speed it up?
	SuspendTerrainInvalidations("ChoGGi_Funcs.Common.PlantRandomVegetation")

  local presets = {}
  local presets_c = 0
  local veg_preset_lookup = veg_preset_lookup
  for i = 1, #veg_preset_lookup do
		local veg = veg_preset_lookup[i]
    if veg.group ~= "Lichen" and veg.group ~= "Vegetable" then
			presets_c = presets_c + 1
			presets[presets_c] = veg
    end
  end

	local HexToWorld = HexToWorld
	local DoesContainVegetation = DoesContainVegetation
--~ 	local CanVegGrowAt_C = rawget(g_env, "Vegetation_CanVegetationGrowAt_C")
	local CanVegGrowAt_C = g_env.Vegetation_CanVegetationGrowAt_C
	local CanVegetationGrowAt = CanVegetationGrowAt
	local PlaceVegetation = PlaceVegetation

  local map_id = ActiveMapID
  local ActiveGameMap = ActiveGameMap
	local object_hex_grid = ActiveGameMap.object_hex_grid.grid
  local landscape_grid = ActiveGameMap.landscape_grid
  local twidth, theight = ActiveGameMap.terrain:GetMapSize()
	local VegetationGrid = VegetationGrid
	local HexMapWidth = HexMapWidth
  local total_elements = HexMapWidth * HexMapHeight

	-- stored placed
	local exists = {}

  amount = amount or 100
  for i = 1, amount do
    local idx = Random(99999999) % total_elements
    local x = idx % HexMapWidth
    local y = idx / HexMapWidth
		if not exists[x..y] then
			local q = x - y / 2
			local r = y
			local wx, wy = HexToWorld(q, r)
			if twidth > wx and theight > wy then
				local p = presets[Random(presets_c) + 1]
				local data = VegetationGrid:get(x, y)
				if not DoesContainVegetation(data)
						and CanVegGrowAt_C and CanVegGrowAt_C(object_hex_grid, landscape_grid, data, q, r)
						or CanVegetationGrowAt(map_id, data, q, r) then
					PlaceVegetation(map_id, q, r, p)
					exists[x..y] = true
				else
					i = i - 1
				end
			else
				i = i - 1
			end
		end
  end

	ResumePassEdits("ChoGGi_Funcs.Common.PlantRandomVegetation")
	ResumeTerrainInvalidations("ChoGGi_Funcs.Common.PlantRandomVegetation")
end

function ChoGGi_Funcs.Common.GetDialogECM(class)
	local ChoGGi_dlgs_opened = ChoGGi_dlgs_opened
	for dlg in pairs(ChoGGi_dlgs_opened) do
		if dlg:IsKindOf(class) then
			return dlg
		end
	end
end

function ChoGGi_Funcs.Common.CloseDialogsECM(skip)
	local desktop = terminal.desktop
	-- Always go backwards when removing stuff from an indexed table
	for i = #desktop, 1, -1 do
		local dlg = desktop[i]
		-- skip is usually self which is already being closed (and probably has some other stuff to do)
		if dlg ~= skip
			and dlg:IsKindOf("ChoGGi_XWindow")
			-- Don't close console log (it's more "perm" than others)
			and not dlg:IsKindOf("ChoGGi_DlgConsoleLogWin")
		then
			dlg:Close()
		end
	end
end

function ChoGGi_Funcs.Common.SetLandScapingLimits(force, skip_objs, out_of_bounds)
	local cs = ConstructionStatus
	if force or ChoGGi.UserSettings.RemoveLandScapingLimits then
		cs.LandscapeTooLarge.type = "warning"
		cs.LandscapeUnavailable.type = "warning"
		cs.LandscapeLowTerrain.type = "warning"
		cs.LandscapeRampUnlinked.type = "warning"
		-- some people don't want it I suppose
		if not skip_objs then
			cs.BlockingObjects.type = "warning"
		end
		-- can cause crashing
		if testing or out_of_bounds then
			cs.LandscapeOutOfBounds.type = "warning"
		end
	else
		-- restore originals
		local orig_cs = ChoGGi.Tables.ConstructionStatus
		cs.LandscapeTooLarge.type = orig_cs.LandscapeTooLarge.type
		cs.LandscapeUnavailable.type = orig_cs.LandscapeUnavailable.type
		cs.LandscapeLowTerrain.type = orig_cs.LandscapeLowTerrain.type
		cs.BlockingObjects.type = orig_cs.BlockingObjects.type
		cs.LandscapeRampUnlinked.type = orig_cs.LandscapeRampUnlinked.type
		cs.LandscapeOutOfBounds.type = orig_cs.LandscapeOutOfBounds.type
	end
end

do -- SetBuildingLimits
	-- needed for prunariu
	local skips = {
		TrackRequiresTwoStations = true,
		PassageAngleToSteep = true,
	}

	function ChoGGi_Funcs.Common.SetBuildingLimits(force)
		local cs = ConstructionStatus
		-- force is from my mods (or yours), usersettings is from ECM
		if force or ChoGGi.UserSettings.RemoveBuildingLimits then
			for id, status in pairs(cs) do
				if status.type == "error" and not skips[id] and id:sub(1, 9) ~= "Landscape" then
					status.type = "warning"
				end
			end
		else
			-- table created in Code\Settings.lua
			local orig_cs = ChoGGi.Tables.ConstructionStatus
			for id, status in pairs(cs) do
				if id:sub(1, 9) ~= "Landscape" and status.type == "warning" then
					-- Mod added status
					if orig_cs[id] then
						cs[id].type = orig_cs[id].type
					end
				end
			end
		end
	end
end -- do

-- bottom toolbar button in menus (new game, planetary, etc)
function ChoGGi_Funcs.Common.RetToolbarButton(params)
	return XTextButton:new({
		Id = params.id,
		Text = params.text or T(126095410863--[[Info]]),
		FXMouseIn = "ActionButtonHover",
		FXPress = "ActionButtonClick",
		FXPressDisabled = "UIDisabledButtonPressed",
		HAlign = "center",
		Background = 0,
		FocusedBackground = 0,
		RolloverBackground = 0,
		PressedBackground = 0,
		RolloverZoom = 1100,
		TextStyle = params.text_style or "Action",
		MouseCursor = "UI/Cursors/Rollover.tga",
		RolloverTemplate = "Rollover",
		RolloverTitle = params.roll_title,
		RolloverText = params.roll_text,
		OnPress = params.onpress,
	}, params.parent)
end

-- save a game with attachments (res cubes in storage depots) that have an origin point above 65535 and goodbye save game.
function ChoGGi_Funcs.Common.RemoveAttachAboveHeightLimit(obj)
	-- we only want to check attachments
	if obj:GetParent() and (obj:GetZ() + obj:GetAttachOffset():z()) > 65535 then
		obj:delete()
	end
end

-- idx can be 1, 2, or 3 (shortcut, shortcut2, gamepad)
function ChoGGi_Funcs.Common.GetShortcut(id, idx)
	if not id then
		return ""
	end
	-- just in case I change it or something
	id = "ECM" .. id

	local keys = GetShortcuts(id)
	if keys then
		return keys[idx or 1]
	end
	return ""
end

do -- CleanInfoAttachDupes
	local dupe_list = {}

	function ChoGGi_Funcs.Common.CleanInfoAttachDupes(list, cls)
		table.clear(dupe_list)
		SuspendPassEdits("ChoGGi_Funcs.Common.CleanInfoAttachDupes")

		-- clean up dupes in order of older
		for i = 1, #list do
			local mark = list[i]
			if not cls or cls and mark:IsKindOf(cls) then

				local pos = tostring(mark:GetPos())
				local dupe = dupe_list[pos]
				if dupe then
					dupe:delete()
				else
					dupe_list[pos] = mark
				end

			end
		end

		-- remove removed items
		ChoGGi_Funcs.Common.objlist_Validate(list)
		ResumePassEdits("ChoGGi_Funcs.Common.CleanInfoAttachDupes")
	end
	function ChoGGi_Funcs.Common.CleanInfoXwinDupes(list, cls)
		table.clear(dupe_list)

		-- clean up dupes in order of older
		for i = #list, 1, -1 do
			local mark = list[i]
			if not cls or cls and mark:IsKindOf(cls) then

				local pos = tostring(mark.FindModifier and mark:FindModifier("follow_obj").target:GetPos())
				if pos then
					local dupe = dupe_list[pos]
					if dupe then
						dupe:Close()
					else
						dupe_list[pos] = mark
					end
				end

			end
		end
	end
end -- do

-- ObjHexShape_Toggle
if what_game == "Mars" then
	local HexRotate = HexRotate
	local HexToWorld = HexToWorld
	local point = point

	local OHexSpot, XText
	local parent
	local FallbackOutline = FallbackOutline

	-- function Dome:GenerateWalkablePoints() (mostly)
	local function BuildShape(obj, shape, depth_test, hex_pos, colour1, colour2, offset)
		local dir = HexAngleToDirection(obj:GetAngle())
		local cq, cr = WorldToHex(obj)

		local c = #obj.ChoGGi_shape_obj
		for i = 1, #shape do
			local sq, sr = shape[i]:xy()
			local q, r = HexRotate(sq, sr, dir)
			local pt = point(HexToWorld(cq + q, cr + r)):SetTerrainZ(offset)

			local hex = OHexSpot:new()
			hex:SetOpacity(25)
			hex:SetPos(pt)

			if colour1 then
				hex:SetColorModifier(colour1)
			end

			-- wall hax off
			if not depth_test then
				hex:SetNoDepthTest(true)
			end

			-- pos text
			if hex_pos then
				local text_obj = XText:new(nil, parent)
				if colour2 then
					text_obj:SetTextColor(colour2)
				end
				text_obj:FollowObj(hex)

				-- easy access
				hex.text_obj = text_obj
				text_obj:SetText(sq .. "," .. sr)
			end

			c = c + 1
			obj.ChoGGi_shape_obj[c] = hex
		end
	end

	local function ObjHexShape_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		SuspendPassEdits("ChoGGi_Funcs.Common.ObjHexShape_Clear")
		if obj.ChoGGi_shape_obj then
			ChoGGi_Funcs.Common.objlist_Destroy(obj.ChoGGi_shape_obj)
			obj.ChoGGi_shape_obj = nil
			if IsValidXWin(obj.ChoGGi_shape_obj_xwin) then
				obj.ChoGGi_shape_obj_xwin:Close()
				obj.ChoGGi_shape_obj_xwin = nil
			end
			return true
		end
		ResumePassEdits("ChoGGi_Funcs.Common.ObjHexShape_Clear")
	end
	ChoGGi_Funcs.Common.ObjHexShape_Clear = ObjHexShape_Clear

	function ChoGGi_Funcs.Common.ObjHexShape_Toggle(obj, params)
		params = params or {shape = FallbackOutline}
		if not IsValid(obj) or not params.skip_return then
			return
		end
		if not params.skip_clear then
			if (ObjHexShape_Clear(obj) and not params.skip_return) then
				return
			end
		end

		obj.ChoGGi_shape_obj = obj.ChoGGi_shape_obj or {}
		params.colour1 = params.colour1 or RandomColourLimited()
		params.colour2 = params.colour2 or RandomColourLimited()
		params.offset = params.offset or 1

		if not OHexSpot then
			OHexSpot = ChoGGi_OHexSpot
		end
		if not XText then
			XText = ChoGGi_XText_Follow
		end

		if not IsValidXWin(obj.ChoGGi_shape_obj_xwin) then
			local parent = terminal.desktop
			local id = "ChoGGi_ObjHexShape_Toggle" .. obj.handle
			parent[id] = XWindow:new({Id = id}, parent)
			obj.ChoGGi_shape_obj_xwin = parent[id]
		end
		parent = obj.ChoGGi_shape_obj_xwin

		SuspendPassEdits("ChoGGi_Funcs.Common.ObjHexShape_Toggle")
		BuildShape(
			obj,
			params.shape,
			params.depth_test,
			params.hex_pos,
			params.colour1,
			params.colour2,
			params.offset
		)
		ResumePassEdits("ChoGGi_Funcs.Common.ObjHexShape_Toggle")
		if not params.skip_clear then
			ChoGGi_Funcs.Common.CleanInfoXwinDupes(obj.ChoGGi_shape_obj_xwin)
			ChoGGi_Funcs.Common.CleanInfoAttachDupes(obj.ChoGGi_shape_obj, "ChoGGi_OHexSpot")
		end

		return obj.ChoGGi_shape_obj
	end
end -- do

function ChoGGi_Funcs.Common.ModEditorActive()
	if what_game ~= "Mars" then
		return
	end

	local m = ActiveMapData
	-- you can save the mod map and play it, so we also check for other stuff
	if m.id == "Mod" and m.markers and m.NetHash then
		return true
	end
end

function ChoGGi_Funcs.Common.UpdateDepotCapacity(obj, max_store, storable)
	max_store = max_store or obj.max_storage_per_resource
	obj.max_storage_per_resource = max_store

	if not storable then
		storable = obj.storable_resources
	end
	for i = 1, #storable do
		local resource_name = storable[i]
		local demand = obj.demand
		if demand and demand[resource_name] then
			demand[resource_name]:SetAmount(0)
			demand[resource_name]:SetAmount(max_store)
		end
	end
end

function ChoGGi_Funcs.Common.IsUniversalStorageDepot(obj)
	return obj and obj.template_name == "UniversalStorageDepot"
end

function ChoGGi_Funcs.Common.GetModEnabled(mod_id)
	return table.find(ModsLoaded, "id", mod_id)
end

do -- SetBuildingTemplates
	local bt, ct
	function ChoGGi_Funcs.Common.SetBuildingTemplates(template, key, value)
		if not bt then
			bt = BuildingTemplates
			ct = ClassTemplates.Building
		end

		-- set value
		if bt[template] then
			bt[template][key] = value
		end
		-- and set value again, cause... (some stuff uses BuildingTemplates, other uses ClassTemplates)
		if ct[template] then
			ct[template][key] = value
		end
	end
end -- do

function ChoGGi_Funcs.Common.ReplaceClassFunc(class, func_name, func_to_call)
	-- ClassDescendantsList("BaseRover")
	class = ClassDescendantsList(class)
	-- shouldn't be any dupes?
	local orig_funcs = {}
	for i = 1, #class do
		-- get cls obj and backup the func we're hitchhiking on
		local cls_obj = g_env[class[i]]
		local orig_func = cls_obj[func_name]
		if not orig_funcs[orig_func] then
			orig_funcs[orig_func] = true
			-- actual func override
			cls_obj[func_name] = function(self, ...)
				-- return your func being called and send it the backuped func
				return func_to_call(orig_func, self, ...)
			end
		end
	end
end

do -- path markers
	local path_classes = {"Movable", "CargoShuttle"}
	local randcolours = {}
	local colourcount = 0
	local dupewppos = {}
	-- default height of waypoints
	local line_height = 50
	local OPolyline

	local function ShowWaypoints(waypoints, colour, obj, skip_height, obj_pos)
		colour = tonumber(colour) or RandomColourLimited()
		-- also used for line height
		if not skip_height then
			line_height = line_height + 4
		end

		obj_pos = obj_pos or obj:GetVisualPos()
		local obj_terrain = ActiveGameMap.terrain:GetHeight(obj_pos) or 0
		local obj_height = (obj:GetObjectBBox():sizez() / 2) or 0
		if obj:IsKindOf("CargoShuttle") then
			obj_height = obj_pos:z() - obj_terrain
		end

		-- some objects don't have pos as waypoint
		local wp_c = #waypoints
		if waypoints[wp_c] ~= obj_pos then
			wp_c = wp_c + 1
			waypoints[wp_c] = obj_pos
		end

		-- build a list of points that aren't high in the sky
		for i = 1, wp_c do
			local wp = waypoints[i]
			local z = wp:z()
			if not z or z and z < obj_terrain then
				waypoints[i] = wp:SetTerrainZ(obj_height + line_height)
			end
		end

--~ 		-- HGE::l_SetPos error hopeful fix

-- or not...?


--~ 		local avg_pos = AveragePoint2D(waypoints)
--~ 		if UIColony.underground_map_id ~= ActiveMapID and IsInMapPlayableArea(ActiveMapID, avg_pos:xy()) then
			-- and spawn the line
			local spawnline = OPolyline:new()
			spawnline:SetMesh(waypoints, colour)
--~ 			-- HGE::l_SetPos error
			spawnline:SetPos(AveragePoint2D(waypoints))

			obj.ChoGGi_Stored_Waypoints[#obj.ChoGGi_Stored_Waypoints+1] = spawnline
--~ 		end

	end -- end of ShowWaypoints

	local function SetWaypoint(obj, setcolour, skip_height)
		local path

		-- we need to build a path for shuttles (and figure out a way to get their dest properly...)
		local is_shuttle = obj:IsKindOf("CargoShuttle")
		if is_shuttle then
			path = {}

			-- going to pickup colonist
			if obj.command == "GoHome" then
				path[1] = obj.hub:GetPos()
			elseif obj.command == "Transport" then
				-- 2 is pickup loc, 3 is drop off
				path[1] = obj.transport_task and ((obj.transport_task[2] and obj.transport_task[2]:GetBuilding():GetPos()) or (obj.transport_task[3] and obj.transport_task[3]:GetBuilding():GetPos()))
			elseif obj.is_colonist_transport_task then
				path[1] = obj.transport_task and (obj.transport_task.dest_pos or obj.transport_task.colonist:GetPos())
			else
				path[1] = obj:GetDestination()
			end

			-- jumper shuttles after first leg
			if type(path[1]) ~= "userdata" then
				path[1] = obj:GetDestination()
			end

			local c = #path

			-- the next four points it's going to after current_spline
			if type(obj.next_spline) == "table" then
				for i = 1, #obj.next_spline do
					c = c + 1
					path[c] = obj.next_spline[i]
				end
			end

			-- where the line starts
			c = c + 1
			path[c] = obj:GetPos()

		else
			-- rovers/drones/colonists
			if obj.GetPath then
				path = obj:GetPath()

				-- add pathing table
				local going_to = obj:GetVisualPos() + obj:GetStepVector() * obj:TimeToAnimEnd() / obj:GetAnimDuration()
				if path then

					local path_c = #path
--~ 					for i = 1, path_c do
--~ 						path[i] = path[i]:SetTerrainZ()
--~ 					end
					path[path_c+1] = going_to
				else
					path = {going_to}
				end

			else
				OpenExamine(obj, nil, T(302535920000467--[[Path Markers]]))
				print(
					T(6779--[[Warning]]),
					":",
					Translate(302535920000869--[[This %s doesn't have GetPath function, something is probably borked.]]):format(RetName(obj))
				)
			end
		end

		-- we have a path so add some colours, and build the waypoints
		if path then
			local colour
			if setcolour then
				colour = setcolour
			else
				if #randcolours < 1 then
					colour = RandomColourLimited()
				else
					-- we want to make sure all grouped waypoints are a different colour (or at least slightly diff)
					colour = randcolours[#randcolours]
					randcolours[#randcolours] = nil
					-- table.remove(t) removes and returns the last value of the table
				end
			end

			if type(obj.ChoGGi_Stored_Waypoints) ~= "table" then
				obj.ChoGGi_Stored_Waypoints = {}
			end

			if not obj.ChoGGi_WaypointPathAdded then
				-- used to reset the colour later on
				obj.ChoGGi_WaypointPathAdded = obj:GetColorModifier()
				obj.ChoGGi_WaypointPathAdded_storedcolour = colour
			end

			-- colour it up
			obj:SetColorModifier(obj.ChoGGi_WaypointPathAdded_storedcolour or colour)

			-- and lastly make sure path is sorted correctly
			-- end is where the obj is, and start is where the dest is
			if is_shuttle then
				table.sort(path, function(a, b)
					return obj:GetVisualDist2D(a) > obj:GetVisualDist2D(b)
				end)
			end

			-- send path off to make wp
			ShowWaypoints(
				path,
				colour,
				obj,
				skip_height,
				obj.GetVisualPos and obj:GetVisualPos() or obj:GetPos()
			)
		end
	end
	ChoGGi_Funcs.Common.SetWaypoint = SetWaypoint

	local function SetPathMarkersGameTime_Thread(obj, handles, delay)
		local colour = RandomColourLimited()
		if type(obj.ChoGGi_Stored_Waypoints) ~= "table" then
			obj.ChoGGi_Stored_Waypoints = {}
		end

		while handles[obj.handle] do
			SuspendPassEdits("ChoGGi_Funcs.Common.SetPathMarkersGameTime_Thread")
			SetWaypoint(obj, colour, true)
			ResumePassEdits("ChoGGi_Funcs.Common.SetPathMarkersGameTime_Thread")
			if delay == 0 or delay == -1 then
				-- If we only do one then it'll be invis unless paused
				-- 2+ is too much ficker
				WaitMsg("OnRender")
				WaitMsg("OnRender")
				-- If you like bears then you'd figure the third is just right... ah well twofer
			else
				Sleep(delay)
			end

			if obj.ChoGGi_Stored_Waypoints then
				SuspendPassEdits("ChoGGi_Funcs.Common.SetPathMarkersGameTime_Thread")
				-- deletes all wp objs
				ChoGGi_Funcs.Common.objlist_Destroy(obj.ChoGGi_Stored_Waypoints)
				-- clears table list
				table.iclear(obj.ChoGGi_Stored_Waypoints)
				ResumePassEdits("ChoGGi_Funcs.Common.SetPathMarkersGameTime_Thread")
			end

			-- break thread when obj isn't valid
			if not IsValid(obj) then
				handles[obj.handle] = nil
				break
			end
		end
	end

	local function AddObjToGameTimeMarkers(obj, handles, delay, skip)
		if skip or obj:IsKindOfClasses(path_classes) then

			if handles[obj.handle] then
				-- already exists so remove thread
				handles[obj.handle] = nil
			elseif IsValid(obj) then
				-- continous loooop of object for pathing it
				handles[obj.handle] = CreateGameTimeThread(SetPathMarkersGameTime_Thread, obj, handles, delay)
			end
		end
	end

	local function SetPathMarkersGameTime(obj, menu_fired, menu_delay)
		if not OPolyline then
			OPolyline = ChoGGi_OPolyline
		end

		local delay = 500
		-- If fired from action menu (or shortcut)
		if IsKindOf(obj, "XAction") then
			obj = SelectedObj or SelObjects(1500)
			menu_fired = true
		else
			obj = obj or SelectedObj or SelObjects(1500)
			delay = type(menu_delay) == "number" and menu_delay or delay
		end
		if obj and obj.objects then
			obj = obj.objects
		end
		if not next(obj) then
			obj = nil
		end

		if obj then
			if not ChoGGi.Temp.UnitPathingHandles then
				ChoGGi.Temp.UnitPathingHandles = {}
			end
			local handles = ChoGGi.Temp.UnitPathingHandles
			if #obj == 1 then
				-- single obj
				obj = obj[1]
 			elseif obj[2] then
				-- multiselect
				for i = 1, #obj do
					AddObjToGameTimeMarkers(obj[i], handles, delay)
				end
				return
			end
			-- single not in a table list (true because we already checked the kindof)
			if obj:IsKindOfClasses(path_classes) then
				return AddObjToGameTimeMarkers(obj, handles, delay, true)
			end
		end

		if menu_fired then
			MsgPopup(
				T(302535920000871--[[Doesn't seem to be an object that moves.]]),
				T(302535920000872--[[Pathing]]),
				{objects = obj}
			)
		end
	end
	ChoGGi_Funcs.Common.SetPathMarkersGameTime = SetPathMarkersGameTime

	local function RemoveWPDupePos(cls, obj)
		if type(obj.ChoGGi_Stored_Waypoints) ~= "table" then
			return
		end

		-- remove dupe pos
		for i = 1, #obj.ChoGGi_Stored_Waypoints do
			local wp = obj.ChoGGi_Stored_Waypoints[i]

			if wp.class == cls then
				local pos = tostring(wp:GetPos())
				if dupewppos[pos] then
					dupewppos[pos]:SetColorModifier(6579300)
					wp:delete()
				else
					dupewppos[pos] = wp
				end
			end
		end
		-- remove removed
		ChoGGi_Funcs.Common.objlist_Validate(obj.ChoGGi_Stored_Waypoints)
	end

	local function ClearColourAndWP(cls, skip)
		-- remove all thread refs so they stop
		if ChoGGi.Temp.UnitPathingHandles then
			table.clear(ChoGGi.Temp.UnitPathingHandles)
		end
		-- and waypoints/colour
		local objs = MapGet_ChoGGi(cls)
		for i = 1, #objs do
			local obj = objs[i]

			if not skip and obj.ChoGGi_WaypointPathAdded then
				obj:SetColorModifier(obj.ChoGGi_WaypointPathAdded)
				obj.ChoGGi_WaypointPathAdded = nil
				obj.ChoGGi_WaypointPathAdded_storedcolour = nil
			end

			local stored = obj.ChoGGi_Stored_Waypoints
			if type(stored) == "table" then
				-- deletes all objs
				ChoGGi_Funcs.Common.objlist_Destroy(stored)
				-- clears table list
				table.iclear(stored)
			end
			-- remove ref
			obj.ChoGGi_Stored_Waypoints = nil

		end
	end

	-- remove any waypoints in the same pos
	local function ClearAllDupeWP(cls)
		local objs = MapGet_ChoGGi(cls)
		for i = 1, #objs do
			local obj = objs[i]
			if obj and obj.ChoGGi_Stored_Waypoints then
				RemoveWPDupePos("WayPoint", obj)
				RemoveWPDupePos("Sphere", obj)
			end
		end
	end
	local function CleanDupes()
		SuspendPassEdits("ChoGGi_Funcs.Common.Pathing_CleanDupes")
		ClearAllDupeWP("CargoShuttle")
		ClearAllDupeWP("Unit")
		ClearAllDupeWP("Colonist")
		ResumePassEdits("ChoGGi_Funcs.Common.Pathing_CleanDupes")
	end
	ChoGGi_Funcs.Common.Pathing_CleanDupes = CleanDupes

	local function StopAndRemoveAll(skip)
		if not skip then
			ChoGGi.Temp.PathMarkers_new_objs_loop = false
		end
		SuspendPassEdits("ChoGGi_Funcs.Common.Pathing_StopAndRemoveAll")

		-- reset all the base colours/waypoints
		ClearColourAndWP("CargoShuttle", skip)
		ClearColourAndWP("Unit", skip)
		ClearColourAndWP("Colonist", skip)
		-- and pets for Unit Thoughts (seems they're not "Unit"y enough)
--~ 		ClearColourAndWP("BasePet", skip)
		if #MapGet_ChoGGi("ChoGGi_Alien") > 0 then
			ClearColourAndWP("ChoGGi_Alien", skip)
		end

		-- remove any extra lines
		ChoGGi_Funcs.Common.RemoveObjs("ChoGGi_OPolyline", true)

		ResumePassEdits("ChoGGi_Funcs.Common.Pathing_StopAndRemoveAll")

		-- reset stuff
		line_height = 50
		randcolours = {}
		colourcount = 0
		dupewppos = {}
	end
	ChoGGi_Funcs.Common.Pathing_StopAndRemoveAll = StopAndRemoveAll

	local function SetMarkers(list, check, delay)
		if check then
			for i = 1, #list do
				SetPathMarkersGameTime(list[i], nil, delay)
			end
		else
			for i = 1, #list do
				SetWaypoint(list[i])
			end
		end
	end
	ChoGGi_Funcs.Common.Pathing_SetMarkers = SetMarkers

end -- do

-- Drone:GetTarget()
function ChoGGi_Funcs.Common.GetTarget(obj)
	local target = obj.target or obj.goto_target
	local text

	local is_point = IsPoint(target)
	if is_point or (type(target) == "table" and target[1]) then
		local q, r
		if is_point then
			q, r = WorldToHex(target)
		else
			-- when goto_target is a table (last one is dest)
			q, r = WorldToHex(target[#target])
		end

		text = q .. ", " .. r
	else
		while IsValid(target) and target:HasMember("parent") and target.parent and target.parent ~= target do
			target = target.parent
		end
		if target ~= false then
			text = RetName(target)
		end
	end

	if text then
		return "(" .. text .. ")"
	end
end

function ChoGGi_Funcs.Common.GetNearestObj(obj, list)
	local obj_pos = obj:GetVisualPos()

	-- get nearest
	local length = max_int
	local nearest = list[1]
	local new_length, spot
	for i = 1, #list do
		spot = list[i]
		new_length = spot:GetVisualPos():Dist2D(obj_pos)
		if new_length < length then
			length = new_length
			nearest = spot
		end
	end

	-- and done
	return nearest
end

function ChoGGi_Funcs.Common.ReloadLua()
	if not ModsLoaded then
		return
	end
	CreateRealTimeThread(function()
		-- get list of enabled mods
		local enabled = table.icopy(ModsLoaded)
		-- turn off all mods
		AllModsOff()
		-- re-enable ecm/lib (or we get black screen of nadda)
		TurnModOn(ChoGGi.id)
		TurnModOn(ChoGGi.id_lib)
		-- wait for it?
		WaitDisableAllPDXMods()
		g_ParadoxModsContextObj = false
		-- reload lua code
		ModsReloadItems()
		-- enable disabled mods
		for i = 1, #enabled do
			TurnModOn(enabled[i].id)
		end
		-- reload lua code
		ModsReloadItems()
	end)
end

-- needs an indexed list or a label
function ChoGGi_Funcs.Common.CycleSelectedObjects(list, count)
	if not count then
		list = UICity.labels[list] or empty_table
		count = #list
	end

	if list and count > 0 then
		local idx = SelectedObj and table.find(list, SelectedObj) or 0
		idx = (idx % count) + 1
		local next_obj = list[idx]

		ViewAndSelectObject(next_obj)
		XDestroyRolloverWindow()
	end
end

-- IsDroneIdle/GetIdleDrones/DroneHubLoad
if what_game == "Mars" then
	local idle_drone_cmds = {
		Idle = true,
		-- fresh drone (only lasts a little bit)
		Start = true,
		-- go back to controller
		GoHome = true,
		-- doesn't have a controller
		WaitingCommand = true,
	}
	local DroneLoadLowThreshold = const.DroneLoadLowThreshold
	local DroneLoadMediumThreshold = const.DroneLoadMediumThreshold
	local DroneLoadExtra = DroneLoadMediumThreshold * 100

	function ChoGGi_Funcs.Common.IsDroneIdle(drone)
		return idle_drone_cmds[drone.command]
	end
	local function IsDroneIdle(_, drone)
		return idle_drone_cmds[drone.command]
	end
	local function IsDroneWorking(_, drone)
		return not drone:IsDisabled()
	end
	function ChoGGi_Funcs.Common.GetIdleDrones()
		return table.ifilter(table.icopy(UICity.labels.Drone or empty_table), IsDroneIdle)
	end

	-- -1 = borked, 0 = low, 1 = medium, 2 = high, empty = 3
	-- higher the laptime the more load (use order = true to return lap_time first)
	function ChoGGi_Funcs.Common.DroneHubLoad(hub, order)
		local drone_load = -1
		local lap_time = -1
		if hub.working then
			-- no working drones / empty hub
			local drones = hub.drones
			if #drones == 0 or #table.ifilter(drones, IsDroneWorking) < 1 then
				drone_load = 3
				lap_time = DroneLoadExtra
			else
				lap_time = Max(hub.lap_time, GameTime() - hub.lap_start)
--~ 				local lap_time = hub:CalcLapTime()
				if lap_time < DroneLoadLowThreshold then
					drone_load = 0
				elseif lap_time < DroneLoadMediumThreshold then
					drone_load = 1
				else
					drone_load = 2
				end
			end
		end
		if order then
			return lap_time, drone_load
		end
		return drone_load, lap_time
	end
end

-- https://gist.github.com/Uradamus/10323382
function ChoGGi_Funcs.Common.FisherYates_Shuffle(list, min)
	-- I don't think there's any 0 based tables in SM, but just in case
	if not min then
		min = 1
	end
  for i = #list, 2, -1 do
    local j = Random(min, i)
    list[i], list[j] = list[j], list[i]
  end
end

-- input as text "0,0,0"
function ChoGGi_Funcs.Common.RGBtoColour(text)
	if not text then
		return 0
	end

	-- remove any spaces/newlines etc
	text = text:gsub("[%s%c]", "")
	-- grab the values
	local values = {}
	local c = 0

	-- loop through all the numbers
	for d in text:gmatch("%d+") do
		c = c + 1
		values[c] = tonumber(d)
	end

	local colour, obj_type
	if values[4] then
		colour, obj_type = RetProperType(RGBA(values[1], values[2], values[3], values[4]))
	else
		colour, obj_type = RetProperType(RGB(values[1], values[2], values[3]))
	end

	if obj_type == "number" then
		return colour
	else
		-- fallback
		return 0
	end
end

-- input as text "0,0,0,0"
function ChoGGi_Funcs.Common.StrToBox(text)
	if not text then
		return box(0,0,0,0)
	end

	-- remove any spaces/newlines etc
	text = text:gsub("[%s%c]", "")
	-- grab the values
	local values = {}
	local c = 0

	-- loop through all the numbers
	for d in text:gmatch("%d+") do
		c = c + 1
		values[c] = tonumber(d)
	end

	return box(values[1], values[2], values[3], values[4])
end

function ChoGGi_Funcs.Common.ResetHumanCentipedes()
	local objs = GetCityLabels("Colonist")
	for i = 1, #objs do
		local obj = objs[i]
		-- only need to do people walking outside (pathing issue), and if they don't have a path (not moving or walking into an invis wall)
		if obj:IsValidPos() and not obj:GetPath() then
			-- too close and they keep doing the human centipede
			obj:SetCommand("Goto",
				GetRealm(obj):GetPassablePointNearby(obj:GetPos()+point(Random(-1000, 1000), Random(-1000, 1000)))
			)
		end
	end
end

function ChoGGi_Funcs.Common.ToggleBreadcrumbs(obj, delay)
	if not IsValid(obj) then
		print("ToggleBreadcrumbs Not valid:", obj)
		return
	end

	if IsValidThread(obj.ChoGGi_breadcrumbThread) then
		DeleteThread(obj.ChoGGi_breadcrumbThread)
		obj.ChoGGi_breadcrumbThread = nil
		return
	end

	obj.ChoGGi_breadcrumbThread = CreateGameTimeThread(function()
		local colour = RandomColourLimited()
		local last_pos
		while true do
			local pos = obj:GetVisualPos()
			if tostring(last_pos) ~= tostring(pos) then
				Sphere(pos, colour, 15000, true)
				last_pos = pos
			end
			Sleep(delay or 1500)
		end
	end)
end

function ChoGGi_Funcs.Common.ToggleUnitPathing(obj, delay)
	if not IsValid(obj) then
		print("ToggleUnitPathing Not valid:", obj)
		return
	end

	-- Abort loop without leaving lines on map (they'll also be culled on loading a save so no biggie)
	if obj.ChoGGi_UnitPathingThread then
		obj.ChoGGi_UnitPathing_clearlines = true
		return
	end

	obj.ChoGGi_UnitPathingThread = CreateGameTimeThread(function()
		local line_params = {
			colour = RandomColourLimited(),
			obj = "",
		}

		local going_to_temp = {"", ""}
		while true do
			-- Always try to clear lines
			ChoGGi_Funcs.Common.ObjListLines_Clear(obj)
			-- Then check if we can abort
			if obj.ChoGGi_UnitPathing_clearlines then
				obj.ChoGGi_UnitPathingThread = nil
				obj.ChoGGi_UnitPathing_clearlines = nil
				DeleteThread(obj.ChoGGi_UnitPathingThread)
				-- Do I need a return if it's deleted?
				return
			end

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
				going_to_temp[1] = current_pos
				going_to_temp[2] = going_to
				path = going_to_temp
			end

			if path then
				line_params.obj = obj
				ChoGGi_Funcs.Common.ObjListLines_Toggle(path, line_params)
			end

			Sleep(delay or 1000)
		end
	end)
end

-- https://stackoverflow.com/questions/6077006/how-can-i-check-if-a-lua-table-contains-only-sequential-numeric-indices#answer-6080274
function ChoGGi_Funcs.Common.IsArray(list)
	local i = 0
	for _ in pairs(list) do
		i = i + 1
		if list[i] == nil then
			return false
		end
	end
	return true
end

local function RetParamsParents(parent, params, ...)
	local parent_type
	if parent then
		parent_type = type(parent)

		-- we only (somewhat) care about parent being a string, point, dialog
		if parent_type == "table" and parent.has_params then
			params = parent
			parent = nil
		elseif parent_type == "string" and parent == "str" then
			params = params or {}
			params.parent = parent
		elseif parent_type ~= "string" and parent_type ~= "table" and parent_type ~= "userdata" then
			parent = nil
		end
	end
	params = params or {}
	params.varargs = params.varargs or ...

	-- pass the marker along
	if params.parent and params.parent.dialog_marker then
		params.dialog_marker = params.parent.dialog_marker
	end

	return params, parent, parent_type
end
ChoGGi_Funcs.Common.RetParamsParents = RetParamsParents

do -- RetThreadInfo/FindThreadFunc
	local GedInspectorFormatObject = GedInspectorFormatObject
	local GedInspectedObjects_l

	local function DbgGetlocal(thread, level)
		local list = {}
		local idx = 1
		while true do
			local name, value = g_env.debug.getlocal(thread, level, idx)
			if name == nil then
				break
			end
			list[idx] = {
				name = name ~= "" and name or Translate(302535920000723--[[Lua]]),
				value = value,
				level = level,
			}
			idx = idx + 1
		end
		if next(list) then
			return list
		end
	end
	local function DbgGetupvalue(info)
		local list = {}
		local idx = 1
		while true do
			local name, value = g_env.debug.getupvalue(info.func, idx)
			if name == nil then
				break
			end
			list[idx] = {
				name = name ~= "" and name or Translate(302535920000723--[[Lua]]),
				value = value,
			}
			idx = idx + 1
		end
		if next(list) then
			return list
		end
	end

	-- returns some info if blacklist enabled
	function ChoGGi_Funcs.Common.RetThreadInfo(thread)
		if type(thread) ~= "thread" then
			return empty_table
		end
		local funcs = {}

		if blacklist then
			GedInspectedObjects_l = GedInspectedObjects_l or GedInspectedObjects
			-- func expects a table
			if GedInspectedObjects_l[thread] then
				table.clear(GedInspectedObjects_l[thread])
			else
				GedInspectedObjects_l[thread] = {}
			end
			-- returns a table of the funcs in the thread
			local threads = GedInspectorFormatObject(thread).members
			-- build a list of func name / level
			for i = 1, #threads do
				-- why'd i add the "= false"?
				local temp = {level = false, func = false, name = false}

				local t = threads[i]
				for key, value in pairs(t) do
					if key == "key" then
						temp.level = value
					elseif key == "value" then
						-- split "func(line num) name" into two
						local space = value:find(") ", 1, true)
						temp.func = value:sub(2, space)
						-- change unknown to Lua
						local n = value:sub(space + 2, -2)
						temp.name = n ~= "unknown name" and n or Translate(302535920000723--[[Lua]])
					end
				end

				funcs[i] = temp
			end

		else
			funcs.gethook = g_env.debug.gethook(thread)

			local info = g_env.debug.getinfo(thread, 0, "Slfunt")
			if info then
				local nups = info.nups
				if nups > 0 then
					-- we start info at 0, nups starts at 1
					nups = nups + 1

					for i = 0, nups do
						local info_got = g_env.debug.getinfo(thread, i)
						if info_got then
							local name = info_got.name or info_got.what or Translate(302535920000723--[[Lua]])
							funcs[i] = {
								name = name,
								func = info_got.func,
								level = i,
								getlocal = DbgGetlocal(thread, i),
								getupvalue = DbgGetupvalue(info_got),
							}
						end
					end
				end
			end
		end

		return funcs
	end

	-- find/return func if str in func name
	function ChoGGi_Funcs.Common.FindThreadFunc(thread, str)
		-- needs an empty table to work it's magic
		GedInspectedObjects[thread] = {}
		-- returns a table of the funcs in the thread
		local threads = GedInspectorFormatObject(thread).members
		for i = 1, #threads do
			for key, value in pairs(threads[i]) do
				if key == "value" and value:find_lower(str, 1, true) then
					return value
				end
			end
		end
	end

end -- do

do -- GetLowestPointEachSector
	local lowest_points
	function ChoGGi_Funcs.Common.GetLowestPointEachSector()
		local UICity = UICity

		-- max the z of the default points
		local max_point = point(0, 0, ActiveGameMap.terrain:GetMapHeight())
		-- build a list of sectors with it
		if not lowest_points then
			lowest_points = {}
			local sectors = UICity.MapSectors
			for sector in pairs(sectors) do
				if type(sector) ~= "number" then
					lowest_points[sector.id] = max_point
				end
			end
		-- or reset the list of sectors
		else
			for sector in pairs(lowest_points) do
				if lowest_points[sector.id] then
					lowest_points[sector.id] = max_point
				end
			end
		end

		local width, height = ConstructableArea:sizexyz()
		width = width / 1000
		height = height / 1000

		-- I dunno, grid size or something? (it's what I get for not commenting)
		for x = 100, width do
			for y = 10, height do

				local x1000, y1000 = x * 1000, y * 1000
				-- the area outside grids is counted as the nearest grid.
				if IsInMapPlayableArea(ActiveMapID, x1000, y1000) then
					local sector_id = GetMapSectorXY(UICity, x1000, y1000).id
					local pos = point(x1000, y1000):SetTerrainZ()
					-- current pos z is lower then stored z
					if pos:z() < lowest_points[sector_id]:z() then
						lowest_points[sector_id] = pos
					end
				end

			end
		end

	--~ 	ex(lowest_points)
		return lowest_points
	end

end -- do

function ChoGGi_Funcs.Common.SetBldMaintenance(obj, value)
	if not IsValid(obj) then
		return
	end

	if value then
		obj:SetBase("disable_maintenance", 1)
	else
		obj.accumulate_maintenance_points = true
		obj.maintenance_resource_type = BuildingTemplates[RetTemplateOrClass(obj)].maintenance_resource_type
		obj:SetBase("disable_maintenance", 0)
		obj:ResetMaintenanceState()
	end

end

do -- OneBuildingExists
	-- (at least one exists) scooped from UIGetBuildingPrerequisites as wonder code
	local function CheckConstructionLabel(label, template_name)
		local sites = UICity.labels[label] or ""
		for i = 1, #sites do
			if sites[i].building_class_proto.template_name == template_name then
				return true
			end
		end
	end

	function ChoGGi_Funcs.Common.OneBuildingExists(template_name)
		if #(UICity.labels[template_name] or "") > 0 then
			return true
		end
		return CheckConstructionLabel("ConstructionSite", template_name)
			or CheckConstructionLabel("ConstructionSiteWithHeightSurfaces", template_name)
			or false
	end
end -- do

-- close any examine dlgs opened from "parent" examine dlg
function ChoGGi_Funcs.Common.CloseChildExamineDlgs(self)
	local ChoGGi_dlgs_examine = ChoGGi_dlgs_examine or empty_table
	for _, dlg in pairs(ChoGGi_dlgs_examine) do
		if dlg ~= self and dlg.parent_id == self.parent_id then
			dlg:Close()
		end
	end
end

do -- ExamineEntSpots (Object>Entity Spots)
	local spots_str = [[		<attach name="%s" spot_note="%s" bone="%s" spot_pos="%s, %s, %s" spot_scale="%s" spot_rot="%s, %s, %s, %s"/>]]

	local RetOriginSurfaces
	local pts_c
	local pts_tmp = {}
	local suffix = [["/>]]
	local function BuildSurf(c, list, obj, name, surf)
		local prefix = [[		<surf type="]] .. name .. [[" points="]]

		local surfs = RetOriginSurfaces(obj, surf)
		for i = 1, #surfs do
			local pts = surfs[i]
			table.iclear(pts_tmp)
			pts_c = 0

			local count = #pts
			for j = 1, count do
				local x, y, z = pts[j]:xyz()
				pts_c = pts_c + 1
				pts_tmp[pts_c] = x
				pts_c = pts_c + 1
				pts_tmp[pts_c] = ", "
				pts_c = pts_c + 1
				pts_tmp[pts_c] = y
				pts_c = pts_c + 1
				pts_tmp[pts_c] = ", "
				pts_c = pts_c + 1
				pts_tmp[pts_c] = z
				if j ~= count then
					pts_c = pts_c + 1
					pts_tmp[pts_c] = ";"
				end
			end
			c = c + 1
			list[c] = prefix .. table.concat(pts_tmp) .. suffix
		end
		return c
	end

--~ local list = ChoGGi_Funcs.Common.ExamineEntSpots(s, true)
--~ list = table.concat(list, "\n")
--~ ChoGGi_Funcs.Common.Dump(list, nil, nil, "ent")
	function ChoGGi_Funcs.Common.ExamineEntSpots(obj, parent_or_ret)
		-- If fired from action menu

		if IsKindOf(obj, "XAction") then
			obj = ChoGGi_Funcs.Common.SelObject()
			parent_or_ret = nil
		else
			obj = obj or ChoGGi_Funcs.Common.SelObject()
		end

		local entity = obj and obj.GetEntity and obj:GetEntity()
		if not IsValidEntity(entity) then
			return
		end

		local origin = obj:GetSpotBeginIndex("Origin")
		local origin_pos_x, origin_pos_y, origin_pos_z = obj:GetSpotLocPosXYZ(origin)
		local id_start, id_end = obj:GetAllSpots(EntityStates.idle)
		if not id_end then
			return
		end

		CreateGameTimeThread(function()

			local list = {}
			local c = #list

			-- loop through each state and add sections for them
			local states_str = obj:GetStates()
			local states_num = EnumValidStates(obj)
			for i = 1, #states_str do
				local state_str = states_str[i]
				local state_num = states_num[i]
				obj:SetState(state_str)
				-- till i find something where the channel isn't 1
				while obj:GetAnim(1) ~= state_num do
					WaitMsg("OnRender")
				end

				-- this is our bonus eh
				local bbox = obj:GetEntityBBox()
				local x1, y1, z1 = bbox:minxyz()
				local x2, y2, z2 = bbox:maxxyz()
				local pos_x, pos_y, pos_z, radius = obj:GetBSphere(state_str, true)
				local anim_dur = obj:GetAnimDuration(state_str)
				local step_len = obj:GetStepLength(state_str)
	--~ 			local step_vec = obj:GetStepVector(state_str, obj:GetAngle(), 0, obj:GetAnimPhase())
				local step_vec = obj:GetStepVector(state_str, obj:GetAngle(), 0, anim_dur)
				local sv1, sv2, sv3 = step_vec:xyz()
	--~ Basketball_idle.hga
				c = c + 1
				list[c] = [[		<state id="]] .. state_str .. [[">
			<mesh_ref ref="mesh"/>
			<anim file="]] .. entity .. "_" .. state_str .. [[.hga" duration="]] .. anim_dur .. [["/>
			<bsphere value="]] .. (pos_x - origin_pos_x) .. ", "
					.. (pos_y - origin_pos_y) .. ", " .. (pos_z - origin_pos_z) .. ", "
					.. radius .. [["/>
			<box min="]] .. x1 .. ", " .. y1 .. ", " .. z1
					.. [[" max="]] .. x2 .. ", " .. y2 .. ", " .. z2 .. [["/>
			<step length="]] .. step_len .. [[" vector="]] .. sv1 .. ", " .. sv2 .. ", " .. sv3 ..  [["/>]]
				.. [[</state>]]
			-- ADD ME
			-- compensate="CME"

			end -- for states

			local mat = GetStateMaterial(entity, 0, 0)
			-- add the rest of the entity info
			c = c + 1
			list[c] = [[	<mesh_description id="mesh">
		<mesh file="]] .. mat:sub(1, -3) .. [[.hgm"/>
		<material file="]] .. mat .. [["/>]]
			-- eh, close enough

			-- stick with idle i guess?
			obj:SetState("idle")
			while obj:GetAnim(1) ~= 0 do
				WaitMsg("OnRender")
			end

			for i = id_start, id_end do
				local name = obj:GetSpotName(i)
				-- It isn't needed
				if name ~= "Origin" then
					-- make a copy to edit
					local spots_str_t = spots_str

					-- we don't want to fill the list with stuff we don't use
					local annot = obj:GetSpotAnnotation(i)
					if not annot then
						annot = ""
						spots_str_t = spots_str_t:gsub([[ spot_note="%%s"]], "%%s")
					end

					local bone = obj:GetSpotBone(i)
					if bone == "" then
						spots_str_t = spots_str_t:gsub([[ bone="%%s"]], "%%s")
					end

					-- axis, scale
					local _, _, _, _, axis_x, axis_y, axis_z = obj:GetSpotLocXYZ(i)

					-- 100 is default
					local scale = obj:GetSpotVisualScale(i)
					if scale == 100 then
						spots_str_t = spots_str_t:gsub([[ spot_scale="%%s"]], "%%s")
						scale = ""
					end

					local angle = obj:GetSpotVisualRotation(i)
					-- means nadda for spot_rot
					if angle == 0 and axis_x == 0 and axis_y == 0 and axis_z == 4096 then
						spots_str_t = spots_str_t:gsub([[ spot_rot="%%s, %%s, %%s, %%s"]], "%%s%%s%%s%%s")
						angle, axis_x, axis_y, axis_z = "", "", "", ""
					else
						axis_x = (axis_x + 0.0) / 100
						axis_y = (axis_y + 0.0) / 100
						axis_z = (axis_z + 0.0) / 100
						angle = (angle) / 60
--~ 						if angle > 360 then
--~ 							printC("ExamineEntSpots: angle > 360: ", angle)
--~ 							-- just gotta figure out how to turn 18000 or 3600 into 60 (21600)
--~ 							angle = 360 - angle
--~ 						end
					end

					local pos_x, pos_y, pos_z = obj:GetSpotPosXYZ(i)

					c = c + 1
					list[c] = spots_str_t:format(
						name, annot, bone,
						pos_x - origin_pos_x, pos_y - origin_pos_y, pos_z - origin_pos_z,
						scale, axis_x, axis_y, axis_z, angle
					)
				end

			end -- for spots

			-- add surfs
			RetOriginSurfaces = RetOriginSurfaces or ChoGGi_Funcs.Common.RetOriginSurfaces
			-- hex_shape
			c = BuildSurf(c, list, obj, "hex_shape", 5)
			-- selection
			c = BuildSurf(c, list, obj, "selection", 7)
			-- collision
			c = BuildSurf(c, list, obj, "collision", 0)

			-- opener
			table.insert(list, 1, Translate(302535920001068--[["The func I use for spot_rot rounds to two decimal points... (let me know if you find a better one).
Attachment bspheres are off (x and y are; z and rotate aren't).
Some of the file names are guesses. <anim> is a guess, try removing it."]])
				.. [[


<?xml version="1.0" encoding="UTF-8"?>
<entity path="">]])

			-- and the closer
			list[#list+1] = [[	</mesh_description>
</entity>]]

			if parent_or_ret == true then
				return table.concat(list, "\n")
			else
				ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
					parent = parent_or_ret,
					text = table.concat(list, "\n"),
					title = T(302535920000235--[[Entity Spots]]) .. ": " .. RetName(obj),
				}
			end

		end)
	end
end -- do

-- RetHexSurfaces
if what_game == "Mars" then
	local GetStates = GetStates
	local GetStateIdx = GetStateIdx
	local GetSurfaceHexShapes = GetSurfaceHexShapes
	local EntitySurfaces = EntitySurfaces

	local function AddToList(filter, list, c, shape, name, key, value, state, hash)
		if shape and (not filter or filter and #shape > 0) then
			c = c + 1
			list[c] = {
				name = name,
				shape = shape,
				id = key,
				mask = value,
				state = state,
				hash = hash,
			}
		end
		return c
	end

	function ChoGGi_Funcs.Common.RetHexSurfaces(entity, filter, parent_or_ret)
		local list = {}
		local c = 0

		local all_states = GetStates(entity)
		for i = 1, #all_states do
			local state = GetStateIdx(all_states[i])
			for key, value in pairs(EntitySurfaces) do
				local outline, interior, hash = GetSurfaceHexShapes(entity, state, value)
				c = AddToList(filter, list, c, outline, "outline", key, value, state, hash)
				c = AddToList(filter, list, c, interior, "interior", key, value, state, hash)
			end
		end

		if parent_or_ret == true then
			return list
		else
			OpenExamine(list, nil, "RetHexSurfaces")
		end
	end
end -- do

do -- GetMaterialProperties
	local GetMaterialProperties = GetMaterialProperties
	local GetStateMaterial = GetStateMaterial
	local GetStateIdx = GetStateIdx
	local GetStateLODCount = GetStateLODCount
	local GetStates = GetStates

	local channel_list = {
		RM = true,
		BaseColor = true,
		Dust = true,
		AO = true,
		Normal = true,
		Colorization = true,
		SI = true,
		RoughnessMetallic = true,
		Emissive = true,
	}
	local mtl_lookup = {
		AO = [[		<AmbientOcclusionMap Name="%s" mc="%s"/>]],
		BaseColor = [[		<BaseColorMap Name="%s" mc="%s"/>]],
		Colorization = [[		<ColorizationMap Name="%s" mc="%s"/>]],
		Dust = [[		<DustMap Name="%s" mc="%s"/>]],
		Emissive = [[		<EmissiveMap Name="%s" mc="%s"/>]],
		Normal = [[		<NormalMap Name="%s" mc="%s"/>]],
		RM = [[		<RMMap Name="%s" mc="%s"/>]],
		RoughnessMetallic = [[		<RoughnessMetallicMap Name="%s" mc="%s"/>]],
		SI = [[		<SIMap Name="%s" mc="%s"/>]],

		alphatest = [[		<Property AlphaTest="%s"/>]],
		animation_frames_x = [[		<Property AnimationFramesX="%s"/>]],
		animation_frames_y = [[		<Property AnimationFramesY="%s"/>]],
		animation_time = [[		<Property AnimationTime="%s"/>]],
		blend = [[		<Property AlphaBlend="%s"/>]],
		castshadow = [[		<Property CastShadow="%s"/>]],
		deposition = [[		<Property Deposition="%s"/>]],
		depthsmooth = [[		<Property DepthSmooth="%s"/>]],
		depthwrite = [[		<Property DepthWrite="%s"/>]],
		distortion = [[		<Property Distortion="%s"/>]],
		opacity = [[		<Property Opacity="%s"/>]],
		special = [[		<Property Special="%s"/>]],
		terraindistorted = [[		<Property TerrainDistortedMesh="%s"/>]],
		transparentdecal = [[		<Property TransparentDecal="%s"/>]],
		transparent = [[		<Property Transparent="%s"/>]],
		twosidedshading = [[		<Property TwoSidedShading="%s"/>]],
		wind = [[		<Property Wind="%s"/>]],
		flags = [[		<Property Flags="%s"/>]],
		emflags = [[		<Property EMFlags="%s"/>]],
		shader = [[		<Property shader="%s"/>]],

--~ 			XX = [[		<Property Anisotropic="%s"/>]],
--~ 			XX = [[		<Property DtmDisable="%s"/>]],
--~ 			XX = [[		<Property EnvMapped="%s"/>]],
--~ 			XX = [[		<Property GlossColor="%s"/>]],
--~ 			XX = [[		<Property MarkVolume="%s"/>]],
--~ 			XX = [[		<Property MaskedCM="%s"/>]],
--~ 			XX = [[		<Property NoDiffuse="%s"/>]],
--~ 			XX = [[		<Property NumInstances="%s"/>]],
--~ 			XX = [[		<Property SelfIllum="%s"/>]],
--~ 			XX = [[		<Property ShadowBlob="%s"/>]],
--~ 			XX = [[		<Property SpecularPower="%s"/>]],
--~ 			XX = [[		<Property SpecularPowerRGB="%s"/>]],
--~ 			XX = [[		<Property StretchFactor1="%s"/>]],
--~ 			XX = [[		<Property StretchFactor2="%s"/>]],
--~ 			XX = [[		<Property SunFacingShading="%s"/>]],
--~ 			XX = [[		<Property TexScrollTime="%s"/>]],
--~ 			XX = [[		<Property Translucency="%s"/>]],
--~ 			XX = [[		<Property TwoSided="%s"/>]],
--~ 			XX = [[		<Property UnitLighting="%s"/>]],
--~ 			XX = [[		<Property UOffset="%s"/>]],
--~ 			XX = [[		<Property USize="%s"/>]],
--~ 			XX = [[		<Property ViewDependentOpacity="%s"/>]],
--~ 			XX = [[		<Property VOffset="%s"/>]],
--~ 			XX = [[		<Property VSize="%s"/>]],
	}

	local function CleanupMTL(mat, list, c)
		list = list or {}
		c = c or #list

		for key, value in pairs(mat) do
			if value == true then
				value = 1
			elseif value == false then
				value = 0
			end

			local mtl = mtl_lookup[key]
			if mtl then
				if channel_list[key] then
					if value ~= "" then
						c = c + 1
						list[c] = mtl:format(value, mat[key .. "Channel"])
					end
				else
					c = c + 1
					list[c] = mtl:format(value)
				end
			end

		end
		return list, c
	end

	local function RetEntityMTLFile(mat)
		local list = {[[<?xml version="1.0" encoding="UTF-8"?>
<Materials>
	<Material>]]}
		local c = #list

		-- build main first
		list, c = CleanupMTL(mat, list, c)
		c = c + 1
		list[c] = [[	</Material>]]

		-- add any sub materials
		for key, sub_mat in pairs(mat) do
			if type(key) == "string" and key:sub(1, 19) == "_sub_material_index" then
				c = c + 1
				list[c] = [[	<Material>]]
				list, c = CleanupMTL(sub_mat, list, c)
				c = c + 1
				list[c] = [[	</Material>]]
			end
		end

		c = c + 1
		list[c] = [[</Materials>]]

		return table.concat(list, "\n")
	end
	ChoGGi_Funcs.Common.RetEntityMTLFile = RetEntityMTLFile

	local function ExamineExportMat(ex_dlg, mat)
		ChoGGi_Funcs.Common.OpenInMultiLineTextDlg{
			parent = ex_dlg,
			text = RetEntityMTLFile(mat),
			title = T(302535920001458--[[Material Properties]]) .. ": " .. mat.__mtl,
		}
	end

	local function RetEntityMats(entity, skip)
		-- some of these funcs can crash sm, so lets make sure it's valid
		if not skip and not IsValidEntity(entity) then
			return
		end

		local mats = {}
		local states = GetStates(entity) or ""
		for si = 1, #states do
			local state_str = states[si]
			local state = GetStateIdx(state_str)
			local num_lods = GetStateLODCount(entity, state) or 0
			for li = 1, num_lods do
				local mat_name = GetStateMaterial(entity, state, li - 1)
				local mat = GetMaterialProperties(mat_name, 0)

				-- add any sub materials
				local c = 1
				while true do
					local extra = GetMaterialProperties(mat_name, c)
					if not extra then
						break
					end
					mat["_sub_material_index" .. c] = extra
					c = c + 1
				end

				mat.__mtl = mat_name
				mat.__lod = li
				mat[1] = {
					ChoGGi_AddHyperLink = true,
					hint = T(302535920001174--[[Show an example .mtl file for this material (not complete).]]),
					name = T(302535920001177--[[Generate .mtl]]),
					func = function(ex_dlg)
						ExamineExportMat(ex_dlg, mat)
					end,
				}

				mats[mat_name .. ", LOD: " .. li .. ", State: " .. state_str .. " (" .. state .. ")"] = mat
			end
		end

		return mats
	end
	ChoGGi_Funcs.Common.RetEntityMats = RetEntityMats

	function ChoGGi_Funcs.Common.GetMaterialProperties(obj, parent_or_ret)
		if not UIColony then
			return
		end

		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi_Funcs.Common.SelObject()
			parent_or_ret = nil
		else
			obj = obj or ChoGGi_Funcs.Common.SelObject()
		end

		local materials

		if IsValidEntity(obj) then
			materials = RetEntityMats(obj, true)
		else
			local entity = obj and obj.GetEntity and obj:GetEntity()
			if IsValidEntity(entity) then
				materials = RetEntityMats(entity, true)
			else
				materials = {}
				local EntityData = EntityData
				for entity in pairs(EntityData) do
					materials[entity] = RetEntityMats(entity, true)
				end
			end
		end


		if parent_or_ret == true then
			return materials
		else
			OpenExamine(materials, parent_or_ret, T(302535920001458--[[Material Properties]]))
		end

	end
end -- do

do -- BBoxLines_Toggle
	local point = point
	local IsBox = IsBox

	-- stores line objects
	local bbox_lines

	local function SpawnBoxLine(bbox, list, depth_test, colour)
		local line = PlacePolyline(list, colour)
		if depth_test then
			line:SetDepthTest(true)
		end
		line:SetPos(bbox:Center())
		bbox_lines[#bbox_lines+1] = line
	end
	local pillar_table = {}
	local function SpawnPillarLine(pt, z, obj_height, depth_test, colour)
		ChoGGi_Funcs.Common.objlist_Destroy(pillar_table)
		pillar_table[1] = pt:SetZ(z)
		pillar_table[2] = pt:SetZ(z + obj_height)
		local line = PlacePolyline(pillar_table, colour)
		if depth_test then
			line:SetDepthTest(true)
		end
		line:SetPos(AveragePoint2D(line.vertices):SetZ(z))
		bbox_lines[#bbox_lines+1] = line
	end

	local function PlaceTerrainBox(bbox, pos, depth_test, colour)
		local obj_height = bbox:sizez() or 1500
		local z = pos:z()
		-- stores all line objs for deletion later
		bbox_lines = {}

		local edges = {bbox:ToPoints2D()}
		-- needed to complete the square (else there's a short blank space of a chunk of a line)
		edges[5] = edges[1]
		edges[6] = edges[2]

		-- we need a list of top/bottom box points
		local points_top, points_bot = {}, {}
		for i = 1, #edges - 1 do
			local edge = edges[i]
			if i < 5 then
				-- the four "pillars"
				SpawnPillarLine(edge, z, obj_height, depth_test, colour)
			end
			local x, y = edge:xy()
			points_top[#points_top + 1] = point(x, y, z + obj_height)
			points_bot[#points_bot + 1] = point(x, y, z)
		end
		SpawnBoxLine(bbox, points_top, depth_test, colour)
		SpawnBoxLine(bbox, points_bot, depth_test, colour)

		--[[
		-- make bbox follow ground height
		for i = 1, #edges - 1 do

			local pt1 = edges[i]
			local pt2 = edges[i + 1]
			local diff = pt2 - pt1
			local steps = Max(2, 1 + diff:Len2D() / step)

			for j = 1, steps do
				local pos = pt1 + MulDivRound(diff, j - 1, steps - 1)
				points_top[#points_top + 1] = pos:SetTerrainZ(offset + obj_height)
				points_bot[#points_bot + 1] = pos:SetTerrainZ(offset)
			end

			-- ... extra lines?
			-- this is what i get for not commenting it the first time.
			points_bot[#points_bot] = nil
			points_top[#points_top] = nil
		end

		SpawnBoxLine(bbox_lines, bbox, points_top, colour)
		SpawnBoxLine(bbox_lines, bbox, points_bot, colour)
		]]

		return bbox_lines
	end
	local function BBoxLines_Clear(obj, is_box)
		SuspendPassEdits("ChoGGi_Funcs.Common.BBoxLines_Clear")
		if not is_box and obj.ChoGGi_bboxobj then
			ChoGGi_Funcs.Common.objlist_Destroy(obj.ChoGGi_bboxobj)
			obj.ChoGGi_bboxobj = nil
			return true
		end
		ResumePassEdits("ChoGGi_Funcs.Common.BBoxLines_Clear")
	end
	ChoGGi_Funcs.Common.BBoxLines_Clear = BBoxLines_Clear

	function ChoGGi_Funcs.Common.BBoxLines_Toggle(obj, params)
		params = params or {}
		obj = obj or ChoGGi_Funcs.Common.SelObject()
		local is_box = IsBox(obj)

		if not (IsValid(obj) or is_box) or (BBoxLines_Clear(obj, is_box) and not params.skip_return) then
			return
		end

		local bbox = is_box and obj or params.bbox

		-- fallback to sel obj
		if not IsBox(bbox) then
			bbox = obj:GetObjectBBox()
		end

		if IsBox(bbox) then
			SuspendPassEdits("ChoGGi_Funcs.Common.BBoxLines_Toggle")
			local box = PlaceTerrainBox(
				bbox,
				bbox:Center():SetTerrainZ(),
				params.depth_test,
				params.colour or RandomColourLimited()
			)
			ResumePassEdits("ChoGGi_Funcs.Common.BBoxLines_Toggle")
			if not is_box then
				obj.ChoGGi_bboxobj = box
			end
			return box
		end
	end
end -- do

-- SurfaceLines_Toggle
if what_game == "Mars" then
	local GetRelativeSurfaces = GetRelativeSurfaces

	local function BuildLines(obj, params)
		local surfs = params.surfs or GetRelativeSurfaces(obj, params.surface_mask or 0)
		local c = #obj.ChoGGi_surfacelinesobj

		for i = 1, #surfs do
			local group = surfs[i]
			-- connect the lines
			group[#group+1] = group[1]

			local line = PlacePolyline(group, params.colour)
			if params.depth_test then
				line:SetDepthTest(true)
			end
			line:SetPos(AveragePoint2D(line.vertices):SetZ(group[1]:z()+params.offset))
			c = c + 1
			obj.ChoGGi_surfacelinesobj[c] = line
		end

		return obj.ChoGGi_surfacelinesobj
	end

	local function SurfaceLines_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		SuspendPassEdits("ChoGGi_Funcs.Common.SurfaceLines_Clear")
		if obj.ChoGGi_surfacelinesobj then
			ChoGGi_Funcs.Common.objlist_Destroy(obj.ChoGGi_surfacelinesobj)
			obj.ChoGGi_surfacelinesobj = nil
			return true
		end
		ResumePassEdits("ChoGGi_Funcs.Common.SurfaceLines_Clear")
	end
	ChoGGi_Funcs.Common.SurfaceLines_Clear = SurfaceLines_Clear

	function ChoGGi_Funcs.Common.SurfaceLines_Toggle(obj, params)

		params = params or {}
		local is_valid = IsValid(obj)
		if not is_valid or is_valid and not IsValidEntity(obj:GetEntity()) or not params.skip_return then
			return
		end
		if not params.skip_clear then
			if (SurfaceLines_Clear(obj) and not params.skip_return) then
				return
			end
		end

		obj.ChoGGi_surfacelinesobj = obj.ChoGGi_surfacelinesobj or {}

		params.colour = params.colour or RandomColourLimited()
		params.offset = params.offset or 1

		SuspendPassEdits("ChoGGi_Funcs.Common.SurfaceLines_Toggle")
		BuildLines(obj, params)
		ResumePassEdits("ChoGGi_Funcs.Common.SurfaceLines_Toggle")

		if not params.skip_clear then
			ChoGGi_Funcs.Common.CleanInfoAttachDupes(obj.ChoGGi_surfacelinesobj)
		end
		return obj.ChoGGi_surfacelinesobj
	end
end -- do

function ChoGGi_Funcs.Common.RetOriginSurfaces(obj, surf)
	-- collision (see also 5, 7)
	surf = surf or 0

	local surfs = GetRelativeSurfaces(obj, surf)
	local origin = obj:GetPos()
	for i = 1, #surfs do
		local pts = surfs[i]
		for j = 1, #pts do
			pts[j] = pts[j] - origin
		end
	end
	return surfs
end

function ChoGGi_Funcs.Common.RetSurfaceMasks(obj)

	if not IsValid(obj) then
		return
	end

	local list = {}

	local entity = obj:GetEntity()
	if not IsValidEntity(entity) then
		return list
	end

	local GetEntityNumSurfaces = GetEntityNumSurfaces

	local EntitySurfaces = EntitySurfaces
	for key, value in pairs(EntitySurfaces) do
		local surfs = GetEntityNumSurfaces(entity, value)
		local surf_bool = obj:HasAnySurfaces(value)

		if surfs > 0 then
			list[key .. " (mask: " .. value .. ", surfaces count: " .. surfs .. ")"] = surf_bool
		else
			list[key .. " (mask: " .. value .. ")"] = surf_bool
		end
	end
	return list
end

do -- EntitySpots_Toggle Entity Spots Toggle
	local GetSpotNameByType = GetSpotNameByType
	local old_remove_table = {"ChoGGi_OText", "ChoGGi_OOrientation"}
	local OText, OPolyline
	local offset_z = 150
	local annot_offset = point(0, 0, offset_z)

	local function EntitySpots_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		SuspendPassEdits("ChoGGi_Funcs.Common.EntitySpots_Clear")
		-- just in case (old way of doing it)
		if obj.ChoGGi_ShowAttachSpots == true then
			obj:DestroyAttaches(old_remove_table, function(a)
				if a.ChoGGi_ShowAttachSpots then
					a:delete()
				end
			end)
			obj.ChoGGi_ShowAttachSpots = nil
		ResumePassEdits("ChoGGi_Funcs.Common.EntitySpots_Clear")
			return true
		elseif obj.ChoGGi_ShowAttachSpots then
			ChoGGi_Funcs.Common.objlist_Destroy(obj.ChoGGi_ShowAttachSpots)
			obj.ChoGGi_ShowAttachSpots = nil
		ResumePassEdits("ChoGGi_Funcs.Common.EntitySpots_Clear")
			return true
		end

		ResumePassEdits("ChoGGi_Funcs.Common.EntitySpots_Clear")

	end
	ChoGGi_Funcs.Common.EntitySpots_Clear = EntitySpots_Clear

	local function EntitySpots_Add(obj, spot_type, annot, depth_test, show_pos, colour)
		local c = #obj.ChoGGi_ShowAttachSpots

--[[
		-- parent dialog storage
		local parent = Dialogs.HUD
		if not parent.ChoGGi_TempEntitySpots then
			parent.ChoGGi_TempEntitySpots = XWindow:new({
				Id = "ChoGGi_TempEntitySpots",
			}, parent)
		end
		parent = parent.ChoGGi_TempEntitySpots

		local text_dlg = ChoGGi_XText_Follow:new({
--~ 			TextStyle = text_style,
--~ 			Padding = padding_box,
--~ 			Margins = c == 3 and margin_box_trp or c == 2 and margin_box_dbl or margin_box,
--~ 			Background = background,
			Dock = "box",
			Clip = false,
			UseClipBox = false,
			HandleMouse = false,
		}, parent)

		text_dlg:SetText(tostring(obj:GetAngle()))
		text_dlg:FollowObj(obj)
		text_dlg:SetVisible(true)

		ex(text_dlg)
]]

		local obj_pos = obj:GetVisualPos()
		local start_id, id_end = obj:GetAllSpots(obj:GetState())
		for i = start_id, id_end do
--~ 			local type = o:GetSpotsType(i)
--~ 			local name = GetSpotNameByType(type)
			local spot_name = GetSpotNameByType(obj:GetSpotsType(i)) or ""
			if not spot_type or spot_name == spot_type then
				local spot_annot = obj:GetSpotAnnotation(i) or ""
				-- If it's a chain then we need to check for "annot, " so chain=2 doesn't include chain=20
				local chain = annot and annot:find("chain")
--~ printC(spot_type, "|", spot_annot, "|", annot, "|", chain, "|", spot_annot:sub(1, #annot+1) == annot .. ", ")
				if not annot or annot and (chain and spot_annot:sub(1, #annot+1) == annot .. ","
						or not chain and spot_annot:sub(1, #annot) == annot) then

					local text_str = obj:GetSpotName(i)
					text_str = i .. "." .. text_str
					if spot_annot ~= "" then
						text_str = text_str .. ";" .. spot_annot
					end
					if show_pos then
						text_str = text_str .. " " .. tostring(obj:GetSpotPos(i) - obj_pos)
					end

					local text_obj = OText:new()
					if depth_test then
						text_obj:SetDepthTest(true)
					end
					text_obj:SetText(text_str)
					text_obj:SetColor1(colour)
					obj:Attach(text_obj, i)
					text_obj:SetAttachOffset(annot_offset)
					c = c + 1
					obj.ChoGGi_ShowAttachSpots[c] = text_obj
					c = c + 1
					local point_obj = ShowPoint(text_obj, colour, 10)
					-- remove the offset
					point_obj:SetPos(point_obj:GetPos():AddZ(-offset_z))
					obj.ChoGGi_ShowAttachSpots[c] = point_obj


					-- append waypoint num for chains later on
					-- need to reverse string so it finds the last =, since find looks ltr
					local equal = spot_annot:reverse():find("=")
					if equal then
						-- we need a neg number for sub + 1 to remove the slash
						text_obj.order = tonumber(spot_annot:sub(-equal + 1))
					end

				end
			end
		end -- for
	end

	local function EntitySpots_Add_Annot(obj, depth_test, colour)
		local chain_c = 0
		local points = {}
		for i = 1, #obj.ChoGGi_ShowAttachSpots do
			local text = obj.ChoGGi_ShowAttachSpots[i]
			-- use order from above to sort by waypoint number
			if text.order then
				chain_c = chain_c + 1
				points[text.order] = text:GetPos()
			end
		end
		-- some stuff has order nums in another spotname?, (the door path for the diner)
		for i = 1, chain_c do
			if not points[i] then
				if points[i+1] then
					points[i] = points[i+1]
				elseif points[i-1] then
					points[i] = points[i-1]
				end
			end
		end

		if chain_c > 0 then
			local line_obj = OPolyline:new()
			if depth_test then
				line_obj:SetDepthTest(true)
			end
			line_obj.max_vertices = #points
			line_obj:SetMesh(points, colour)
			line_obj:SetPos(AveragePoint2D(points))

			obj.ChoGGi_ShowAttachSpots[#obj.ChoGGi_ShowAttachSpots + 1] = line_obj
		end

	end

	function ChoGGi_Funcs.Common.EntitySpots_Toggle(obj, params)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi_Funcs.Common.SelObject()
			params = {}
		else
			obj = obj or ChoGGi_Funcs.Common.SelObject()
		end

		params = params or {}
		local is_valid = IsValid(obj)
		local entity = obj and obj.GetEntity and obj:GetEntity()
		if not (is_valid or IsValidEntity(entity) or params.skip_return) then
			return
		end
		if not params.skip_clear then
			if EntitySpots_Clear(obj) and not params.skip_return then
				return
			end
		end

		obj.ChoGGi_ShowAttachSpots = obj.ChoGGi_ShowAttachSpots or {}

		params.colour = params.colour or RandomColourLimited()

		if not OPolyline then
			OPolyline = ChoGGi_OPolyline
		end
		if not OText then
			OText = ChoGGi_OText
		end
		SuspendPassEdits("ChoGGi_Funcs.Common.EntitySpots_Add")
		EntitySpots_Add(obj,
			params.spot_type,
			params.annotation,
			params.depth_test,
			params.show_pos,
			params.colour
		)

		local c = #obj.ChoGGi_ShowAttachSpots

		-- show obj angle
		local text_obj = OText:new()
		if params.depth_test then
			text_obj:SetDepthTest(true)
		end
		text_obj:SetText("Angle: " .. obj:GetAngle())
		-- maybe diff colour from annots
		text_obj:SetColor1(RandomColourLimited())
		local origin = -1
		obj:Attach(text_obj, origin)
		-- stick it above obj
		local obj_height = point(0, 0, obj:GetObjectBBox():sizez()):AddZ(250)
		text_obj:SetAttachOffset(obj_height)

		c = c + 1
		obj.ChoGGi_ShowAttachSpots[c] = text_obj

		ResumePassEdits("ChoGGi_Funcs.Common.EntitySpots_Add")

		if not params.skip_clear then
			ChoGGi_Funcs.Common.CleanInfoAttachDupes(obj.ChoGGi_ShowAttachSpots, "ChoGGi_OText")
		end

		-- play connect the dots if there's chains
		if obj.ChoGGi_ShowAttachSpots[2] and params.annotation and params.annotation:find("chain") then
			SuspendPassEdits("ChoGGi_Funcs.Common.EntitySpots_Add_Annot")
			EntitySpots_Add_Annot(obj, params.depth_test, RandomColourLimited())
			ResumePassEdits("ChoGGi_Funcs.Common.EntitySpots_Add_Annot")
		end

		if not params.skip_clear then
			ChoGGi_Funcs.Common.CleanInfoAttachDupes(obj.ChoGGi_ShowAttachSpots, "ChoGGi_OPolyline")
		end

		return obj.ChoGGi_ShowAttachSpots

	end
end -- do



do -- ObjFlagsList
--~ 		local IsFlagSet = IsFlagSet
	local const = const

	-- get list of const.rf* flags
	local rf_flags = {}
	local int_flags = {}
	for flag, value in pairs(const) do
		if flag:sub(1, 2) == "rf" and type(value) == "number" then
			rf_flags[flag] = value
		elseif flag:sub(1, 3) == "int" and type(value) == "number" then
			int_flags[flag] = value
		end
	end

	local flags_table
	local function CheckFlags(flags, obj, func_name)
		local get = "Get" .. func_name
		local set = "Set" .. func_name
		local clear = "Clear" .. func_name
		local us = ChoGGi.UserSettings

		for _, f in pairs(flags) do
			local mask = const[f]
			-- grumble efAlive grumble
			if mask then
				local flagged = obj[get](obj, mask) == mask
				if func_name == "ClassFlags" then
					flags_table[f .. " (" .. mask .. ")"] = flagged
				else
					flags_table[f .. " (" .. mask .. ")"] = {
						ChoGGi_AddHyperLink = true,
						hint = T(302535920001069--[[Toggle Boolean]]),
						name = tostring(flagged),
						colour = flagged and us.ExamineColourBool or us.ExamineColourBoolFalse,
						func = function(ex_dlg, _, list_obj)
							-- If flag is true
							if obj[get](obj, mask) == mask then
								obj[clear](obj, mask)
								list_obj.name = "false"
								list_obj.colour = us.ExamineColourBoolFalse
							else
								obj[set](obj, mask)
								list_obj.name = "true"
								list_obj.colour = us.ExamineColourBool
							end
							ex_dlg:RefreshExamine()
						end,
					}
				end
			end
		end
	end

	function ChoGGi_Funcs.Common.ObjFlagsList_TR(obj, parent_or_ret)
		if not obj or obj.__name ~= "HGE.TaskRequest" then
			return
		end
		flags_table = {}

		for flag, value in pairs(rf_flags) do
			flags_table[flag .. " (" .. value .. ")"] = obj:IsAnyFlagSet(value)
		end

		if parent_or_ret == true then
			return flags_table
		else
			OpenExamine(flags_table, parent_or_ret, RetName(obj))
		end
	end

	function ChoGGi_Funcs.Common.ObjFlagsList(obj, parent_or_ret)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi_Funcs.Common.SelObject()
			parent_or_ret = nil
		else
			obj = obj or ChoGGi_Funcs.Common.SelObject()
		end

		if not IsValid(obj) then
			return
		end

		flags_table = {}

		local FlagsByBits = FlagsByBits
		CheckFlags(FlagsByBits.Enum, obj, "EnumFlags")
		CheckFlags(FlagsByBits.Game, obj, "GameFlags")
		CheckFlags(FlagsByBits.Class, obj, "ClassFlags")
--~ 			CheckFlags(FlagsByBits.Component, obj, "ClassFlags")

		if parent_or_ret == true then
			return flags_table
		else
			OpenExamine(flags_table, parent_or_ret, RetName(obj))
		end

	end
end -- do

function ChoGGi_Funcs.Common.SetAnimState(obj)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi_Funcs.Common.SelObject()
	else
		obj = obj or ChoGGi_Funcs.Common.SelObject()
	end

	if not IsValid(obj) then
		return
	end

	local item_list = {}
	local states_str = obj:GetStates()
	local states_num = EnumValidStates(obj)

	if testing and #states_str ~= #states_num then
		print("SetAnimState: Different state amounts")
	end

	for i = 1, #states_str do
		local state = states_str[i]
		local idx = states_num[i]
		item_list[i] = {
			text = Translate(1000037--[[Name]]) .. ": " .. state .. ", " .. T(302535920000858--[[Index]]) .. ": " .. idx,
			value = state,
		}
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]

		local value = choice.value
		-- If user wants to play it again we'll need to have it set to another state and everything has idle
		obj:SetState("idle")

		if value ~= "idle" then
			obj:SetState(value)
			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(choice.text),
				T(302535920000859--[[Anim State]])
			)
		end
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = T(302535920000860--[[Set Anim State]]),
		hint = Translate(302535920000861--[[Current State: %s]]):format(obj:GetState()),
		custom_type = 7,
	}
end

function ChoGGi_Funcs.Common.LaunchHumanMeteor(entity, min, max, city)
	if not IsValidEntity(entity) then
		entity = "Unit_Astronaut_All_Child_01"
		min = 0
		max = 1
	end

	if not CurrentThread() then
		return CreateGameTimeThread(ChoGGi_Funcs.Common.LaunchHumanMeteor, entity, min, max, city)
	end

	--	1 to 4 sols
	Sleep(Random(
		min or const.DayDuration,
		max or const.DayDuration * 4
	))

	local data = DataInstances.MapSettings_Meteor.Meteor_VeryLow
	local descr = SpawnMeteor(data, nil, nil, GetRandomPassable(city or MainCity))

	-- I got a missle once, not sure why...
	if descr.meteor:IsKindOf("BombardMissile") then
		g_IncomingMissiles[descr.meteor] = nil
		if IsValid(descr.meteor) then
			descr.meteor:delete()
		end
		return
	end

	descr.meteor:Fall(descr.start)
	descr.meteor:ChangeEntity(entity)
	-- frozen meat popsicle (dark blue)
	descr.meteor:SetColorModifier(-16772609)
	-- It looks reasonable
	descr.meteor:SetState("sitSoftChairIdle")
	-- I don't maybe they swelled up from the heat and moisture permeating in space (makes it easier to see the popsicle)
	descr.meteor:SetScale(500)
end

do -- ValueToStr
	local missing_text = ChoGGi.Temp.missing_text

	function ChoGGi_Funcs.Common.ValueToStr(obj, obj_type)
		obj_type = obj_type or type(obj)

		if obj_type == "string" then
			-- strings with (object) don't work well with Translate
			if obj:find("%(") then
				return obj, obj_type
			-- If there's any <image, <color, etc tags
			elseif obj:find("[<>]") then
				return Translate(obj), obj_type
			else
				return obj, obj_type
			end
		end
		--
		if obj_type == "number" then
			-- faster than tostring()
			return obj .. "", obj_type
		end
		--
		if obj_type == "boolean" then
			return tostring(obj), obj_type
		end
		--
		if obj_type == "table" then
			return RetName(obj), obj_type
		end
		--
		if obj_type == "userdata" then
			if IsPoint(obj) then
				return "point" .. tostring(obj), obj_type
			elseif IsBox(obj) then
				return "box" .. tostring(obj), obj_type
			end
			-- show translated text if possible, otherwise check for metatable name
			if IsT(obj) then
				local trans_str = Translate(obj)
				if trans_str == missing_text then
					local meta = getmetatable(obj).__name
					return tostring(obj) .. (meta and " " .. meta or ""), obj_type
				end
				return trans_str, obj_type
			end
			--
			local meta = getmetatable(obj).__name
			return tostring(obj) .. (meta and " " .. meta or ""), obj_type
		end
		--
		if obj_type == "function" then
			return RetName(obj), obj_type
		end
		--
		if obj_type == "thread" then
			return tostring(obj), obj_type
		end
		--
		if obj_type == "nil" then
			return "nil", obj_type
		end

		-- just in case
		return tostring(obj), obj_type
	end
end -- do

function ChoGGi_Funcs.Common.UsedTerrainTextures(ret)
	if not UIColony then
		return
	end

	-- If fired from action menu
	if IsKindOf(ret, "XAction") then
		ret = nil
	end

	local MulDivRound = MulDivRound
	local TerrainTextures = TerrainTextures

	local tm = ActiveGameMap.terrain:GetTypeGrid()
	local _, levels_info = tm:levels(true, 1)
	local size = tm:size()
	local textures = {}
	for level, count in pairs(levels_info) do
		local texture = TerrainTextures[level]
		if texture then
			local perc = MulDivRound(100, count, size * size)
			if perc > 0 then
				textures[texture.name] = perc
			end
		end
	end

	if ret then
		return textures
	end
	OpenExamine(textures, nil, T(302535920001181--[[Used Terrain Textures]]))
end

local function RetObjMapId(obj, text, fallback)
	if obj then
		return obj.city and obj.city.map_id
			or obj.GetMapID and obj:GetMapID()
			or g_CObjectFuncs.GetMapID(obj)
			or fallback and ActiveMapID
			or text and "unknown" or ""
	end
	return fallback and ActiveMapID or text and "unknown" or ""
end
ChoGGi_Funcs.Common.RetObjMapId = RetObjMapId

--~ ChoGGi_Funcs.Common.RetMapType(nil, ActiveMapID)
function ChoGGi_Funcs.Common.RetMapType(obj, map_id, city)
	if not UIColony then
		return
	end

	if not map_id then
		if city then
			map_id = city.map_id
		end
		if not map_id then
			map_id = RetObjMapId(obj)
			if not map_id then
				map_id = ActiveMapID
			end
		end
	end

	if map_id == UIColony.surface_map_id then
		return "surface"
	elseif map_id == UIColony.underground_map_id then
		return "underground"
	else
		return "asteroid"
	end
end

function ChoGGi_Funcs.Common.RotateBuilding(objs, toggle, multiple)
	if multiple then
		for i = 1, #objs do
			local obj = objs[i]
			obj:SetAngle((obj:GetAngle() or 0) + (toggle and 1 or -1)*60*60)
		end
		return
	end

	objs:SetAngle((objs:GetAngle() or 0) + (toggle and 1 or -1)*60*60)
end

function ChoGGi_Funcs.Common.SetPosRandomBuildablePos(obj, city)
  local pfClass = 0
  city = city or UICity
  local object_hex_grid = GetObjectHexGrid(city)
  local buildable_grid = GetBuildableGrid(city)

	obj:SetPos(GetRealm(obj):GetRandomPassablePoint(city:Random(), pfClass, function(x, y)
		return buildable_grid:IsBuildableZone(x, y) and not IsPointNearBuilding(object_hex_grid, x, y)
	end))
end

function ChoGGi_Funcs.Common.CycleObjs(list)
	local count = #list
	if count > 0 then
		-- dunno why they localed it, instead of making it InfobarObj:CycleObjects()...
		local idx = SelectedObj and table.find(list, SelectedObj) or 0
		idx = (idx % count) + 1
		local next_obj = list[idx]

		ViewAndSelectObject(next_obj)
--~ 		XDestroyRolloverWindow()
	end
	return count
end

function ChoGGi_Funcs.Common.GetUnitsSamePlace(city)
	city = city or UICity
	local places = {}
	local objs = GetRealmByID(city.map_id):MapGet("map", "Unit")
	for i = 1, #objs do
		local obj = objs[i]
		local pos = tostring(obj:GetVisualPos())
		if places[pos] then
			places[pos][#places[pos]+1] = obj
		else
			places[pos] = {obj}
		end
	end
	local filtered = table.ifilter(places, function(list)
		if #list == 1 then
			return true
		end
	end)
	OpenExamine(filtered)
end
function ChoGGi_Funcs.Common.CountAllObjs()
	local count = 0
	local GameMaps = GameMaps
	for _, map in pairs(GameMaps) do
		count = count + map.realm:MapCount(true)
	end
	return count
end
function ChoGGi_Funcs.Common.MoveRealm(obj, map_id)
	local map = GameMaps[map_id]
	-- Skip removed asteroids
	if not map then
		return
	end

	local is_asteroid = ChoGGi_Funcs.Common.RetMapType(nil, map_id) == "asteroid"
	local pos
	if not is_asteroid then
		pos = obj:GetPos()
	end
	-- Move obj
	obj:TransferToMap(map_id)
	--
	if is_asteroid then
		-- Find some place with passable ground (if moving to asteroid).
		local deposit = FindNearestObject(Cities[map_id].labels.SubsurfaceDeposit, obj)
		if deposit then
			pos = GetRandomPassableAroundOnMap(map_id, deposit:GetPos(), 10000, 1000)
		else
			local rand_rock = table.rand(map.realm:MapGet("map", "WasteRockObstructor"))
			pos = GetRandomPassableAroundOnMap(map_id, rand_rock, 10000, 1000)
		end
	end
	--
	if pos then
		-- Used surface.terrain:GetHeight instead of just :SetTerrainZ() since that seems to be the active terrain
		obj:SetPos(pos:SetZ(map.terrain:GetHeight(pos)))
	end
end

function ChoGGi_Funcs.Common.GetNextTable(list, key, value)
	local idx = table.find(list, key, value)
	if idx then
		return list[idx]
	end
end

function ChoGGi_Funcs.Common.ObjectCloner(flat, obj, centre)
	if not IsValid(obj) then
		obj = ChoGGi_Funcs.Common.SelObject()
	end
	if not IsValid(obj) then
		return
	end

	local pos = GetCursorWorldPos()

	if obj:IsKindOf("Colonist") then
		ChoGGi_Funcs.Common.SpawnColonist(obj, nil, pos)
		return
	end

	local map_id = obj:GetMapID()
	local concrete = obj:IsKindOf("TerrainDepositConcrete")

	local clone
	-- make regolith work with Harvester
	if concrete then
		clone = PlaceObjectIn("TerrainDepositMarker", map_id)
		clone:CopyProperties(obj)
	-- clone dome = crashy
	elseif obj:IsKindOf("Dome") then
		clone = PlaceObjectIn(obj.class, map_id)
		-- if not default pos than grass is bugged for DomeHexa (and maybe others)
		ChoGGi_Funcs.Common.CopyProperties(clone, obj, nil, {Pos=true})
	else
		clone = obj:Clone()
	end

	if obj.GetEntity then
		clone.entity = obj:GetEntity()
	end

	-- got me banners are weird like that
	if obj:IsKindOf("Banner") then
		clone:ChangeEntity(obj:GetEntity())
	end

	-- we're already cheating by cloning, so fill 'er up
	if clone:IsKindOf("SubsurfaceDeposit") then
		if clone.CheatRefill then
			clone:CheatRefill()
		end
	end

	if centre then
		pos = HexGetNearestCenter(pos)
	end

	clone:SetPos(pos)

	if flat == true or flat and flat.flatten_to_ground == true then
		pos = pos:SetTerrainZ()
	end


	if concrete then
		clone:SpawnDeposit()
	end

	-- update flight grid for shuttles
--~ 	FlightCaches[RetObjMapId(clone, nil, true)]:OnHeightChanged()
	FlightCaches[map_id]:OnHeightChanged()

	return clone
end

function ChoGGi_Funcs.Common.PlainSortTable(tbl, value)
	if not value then
	 value = "name"
	end
	table.sort(tbl, function(a, b)
		return CmpLower(a[value], b[value])
	end)
	local str = "\n"
	for i = 1, #tbl do
		tbl[i] = tbl[i][value]
		str = str .. tbl[i] ..  "\n"
	end
	return tbl, str
end

-- This is a copy and paste from Dlc\gagarin\Code\RivalColonies.lua local function PickUnusedAISponsor()
-- LukeH overrides SpawnRivalAI(preset), but doesn't check if preset exists.
function ChoGGi_Funcs.Common.PickUnusedAISponsor()
  local filtered = {}
  ForEachPresetInGroup("DumbAIDef", "MissionSponsors", function(preset)
    local used = false
    if preset.id == "random" or preset.id == "none" or preset.id == g_CurrentMissionParams.idMissionSponsor then
      used = true
    end
    if not used then
      for id, _ in pairs(RivalAIs or empty_table) do
        if id == preset.id then
          used = true
          break
        end
      end
    end
    if not used then
      local colonies = g_CurrentMissionParams.idRivalColonies or empty_table
      for _, id in ipairs(colonies) do
        if id == preset.id then
          used = true
        end
      end
    end
    if not used then
      filtered[#filtered + 1] = preset
    end
  end)
	local results = table.rand(filtered)
  return results
end
-- Change cargo limits

--~ ChoGGi_Funcs.Common.ChangeCargoValue("Drone", key, value)
function ChoGGi_Funcs.Common.ChangeCargoValue(id, key, value)
	if not key or not value then
		print("missing key or value")
		return
	end

	local defs = ResupplyItemDefinitions
	local idx = table.find(defs, "id", id)
	if idx then
		defs[idx][key] = value
	end
end

do -- RetSourceFile
	local source_path = "AppData/Source/"

	function ChoGGi_Funcs.Common.RetSourceFile(path)
		if blacklist then
			ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.RetSourceFile")
			return
		end
--[[
source: '@CommonLua/PropertyObject.lua'
~PropertyObject.Clone
source: '@Mars/Lua/LifeSupportGrid.lua'
~WaterGrid.RemoveElement
source: '@Mars/Dlc/gagarin/Code/RCConstructor.lua'
~RCConstructor.CanInteractWithObject

~ChoGGi_Funcs.Common.RetSourceFile
]]
		-- remove @
		if path:sub(1, 1) == "@" then
			path = path:sub(2)
		end

		local err, code
		-- mods (we need to skip CommonLua else it'll open the luac file)
		local comlua = path:sub(1, 10)
		if comlua ~= "CommonLua/" and ChoGGi_Funcs.Common.FileExists(path) then
			err, code = g_env.AsyncFileToString(path)
			if not err then
				return code, path
			end
		end

		-- Return commonlua/dlc files (line numbers will usually be off as decompiled is different)
		if path:sub(1, 5) == "Mars/" then
			path = source_path .. path:sub(6)
			err, code = g_env.AsyncFileToString(path)
			if not err then
				return code, path
			end
		elseif comlua == "CommonLua/" then
			path = source_path .. path
			err, code = g_env.AsyncFileToString(path)
			if not err then
				return code, path
			end
		end

		return nil, (err and err .. "\n" or "") .. path

	end
end -- do

function ChoGGi_Funcs.Common.Dump(obj, overwrite, file, ext, skip_msg, gen_name)
	if blacklist then
		ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.Dump")
		return
	end

	-- If overwrite is nil then we append, if anything else we overwrite
	if overwrite then
		overwrite = nil
	else
		overwrite = "-1"
	end

	ext = ext or "txt"

	local filename
	if gen_name then
		filename = "AppData/logs/DumpedText-" .. os.date("%d%m%Y_%H%M%S")
			.. "_" .. AsyncRand() .. "." .. ext
	else
		filename = "AppData/logs/" .. (file or "DumpedText") .. "." .. ext
	end

	ThreadLockKey(filename)
	g_env.AsyncStringToFile(filename, obj, overwrite)
	ThreadUnlockKey(filename)

	-- let user know
	if not skip_msg then
		local msg = Translate(302535920000039--[[Dumped]]) .. ": " .. RetName(obj)
		print(filename, "\n", msg:sub(1, msg:find("\n") ) )
		MsgPopup(
			msg,
			filename
		)
	end
end

function ChoGGi_Funcs.Common.DumpLua(obj)
	ChoGGi_Funcs.Common.Dump(ChoGGi.newline .. ValueToLuaCode(obj), nil, "DumpedLua", "lua")
end

function ChoGGi_Funcs.Common.OpenIn3DManipulatorDlg(obj, parent)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi_Funcs.Common.SelObject()
		parent = nil
	else
		obj = obj or ChoGGi_Funcs.Common.SelObject()
	end

	if not obj then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_Dlg3DManipulator:new({}, terminal.desktop, {
		obj = obj,
		parent = parent,
	})
end

-- lua rev 1011166
-- copy pasta of function PropertyObject:CopyProperties(source, properties)
function ChoGGi_Funcs.Common.CopyProperties(to, from, properties, skip)
	if not skip then
		skip = empty_table
	end

  properties = properties or to:GetProperties()
  for i = 1, #properties do
    local prop = properties[i]
    if not prop.dont_save then
      local prop_id = prop.id
			if not skip[prop_id] then
				local value = from:GetProperty(prop_id)
				local is_default = false
				local default = to:GetDefaultPropertyValue(prop_id, prop)
				is_default = value == nil or value == default
				if not is_default then
					to:SetProperty(prop_id, value)
				end
			end
    end
  end
end

-- Be removed sometime (see Examine.lua)
function ChoGGi_Funcs.Common.EntitySpawner(obj, params)

	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		params = {}
		if obj.setting_planning then
			params.planning = true
		else
			params.planning = nil
		end
		obj = nil
	else
		params = params or {}
	end

	local const = const

	local title = params.planning and T(302535920000862--[[Object Planner]]) or T(302535920000475--[[Entity Spawner]])
	local hint = params.planning and T(302535920000863--[[Places fake construction site objects at mouse cursor (collision disabled).]]) or T(302535920000476--[["Shows list of objects, and spawns at mouse cursor."]])

	local default
	local item_list = {}
	local c = 0

	if IsValid(obj) and IsValidEntity(obj.ChoGGi_orig_entity) then
		default = T(1000121--[[Default]])
		item_list[1] = {
			text = " " .. default,
			value = default,
		}
		c = #item_list
	end

	if params.planning then
		local BuildingTemplates = BuildingTemplates
		for key, value in pairs(BuildingTemplates) do
			c = c + 1
			item_list[c] = {
				text = key,
				value = value.entity,
			}
		end
	else
		local EntityData = EntityData
		for key in pairs(EntityData) do
			c = c + 1
			item_list[c] = {
				text = key,
				value = key,
			}
		end
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]
		local value = choice.value

		if not obj then
			local cls = ChoGGi_OBuildingEntityClass
			if choice.check1 then
				cls = ChoGGi_OBuildingEntityClassAttach
			end

			obj = cls:new()
			obj:SetPos(GetCursorWorldPos())

			if params.planning then
				obj.planning = true
				obj:SetGameFlags(const.gofUnderConstruction)
			end
		end

		-- backup orig entity
		if not IsValidEntity(obj.ChoGGi_orig_entity) then
			obj.ChoGGi_orig_entity = obj:GetEntity()
		end

		-- crash prevention
		obj:SetState("idle")

		if value == default and IsValidEntity(obj.ChoGGi_orig_entity) then
			obj:ChangeEntity(obj.ChoGGi_orig_entity)
			obj.entity = obj.ChoGGi_orig_entity
		else
			obj:ChangeEntity(value)
			obj.entity = value
		end

		if SelectedObj == obj then
			ObjModified(obj)
		end

		-- needs to fire whenever entity changes
		obj:ClearEnumFlags(const.efCollision + const.efApplyToGrids)

		if not params.skip_msg then
			MsgPopup(
				choice.text .. ": " .. T(302535920000014--[[Spawned]]),
				title
			)
		end
	end

	local checkboxes
	if params.list_type ~= 7 then
		checkboxes = {
			{
				title = T(302535920001578--[[Auto-Attach]]),
				hint = T(302535920001579--[[Activate any auto-attach spots this entity has.]]),
			},
		}
	end

	if params.title_postfix then
		title = title .. ": " .. params.title_postfix
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = title,
		hint = hint,
		custom_type = params.list_type or 0,
		checkboxes = checkboxes,
	}
end

function ChoGGi_Funcs.Common.objlist_Destroy(objlist)
  for i = #objlist, 1, -1 do
    local o = objlist[i]
    objlist[i] = nil
    if IsValid(o) then
      o:delete()
    end
  end
end
function ChoGGi_Funcs.Common.objlist_Validate(objlist)
  local remove = table.remove
  local IsValid = IsValid
  for i = #objlist, 1, -1 do
    if not IsValid(objlist[i]) then
      remove(objlist, i)
    end
  end
  return objlist
end

do -- ToggleObjLines
	local function ObjListLines_Clear(obj)
		if type(obj) ~= "table" then
			return
		end
		if IsValid(obj.ChoGGi_ObjListLine) then
			obj.ChoGGi_ObjListLine:delete()
		end
		rawset(obj, "ChoGGi_ObjListLine", nil)
	end
	ChoGGi_Funcs.Common.ObjListLines_Clear = ObjListLines_Clear

	local function ObjListLines_Add(list, obj, colour)
		local vertices = {}
		local c = 0

		-- add any obj pos points of box centres
		for i = 1, #list do
			local o = list[i]
			if IsPoint(o) then
				if o:z() then
					c = c + 1
					vertices[c] = o
				else
					c = c + 1
					vertices[c] = o:SetTerrainZ()
				end
			elseif IsValid(o) then
				c = c + 1
				vertices[c] = o:GetVisualPos()
			elseif IsBox(o) then
				c = c + 1
				vertices[c] = o:Center()
			end
		end
		-- remove any invalid pos
		for i = #vertices, 1, -1 do
			if vertices[i] == InvalidPos then
				table.remove(vertices, i)
			end
		end

		local line = PlacePolyline(vertices, colour)
		line:SetPos(AveragePoint2D(line.vertices))

		obj.ChoGGi_ObjListLine = line
	end

	function ChoGGi_Funcs.Common.ObjListLines_Toggle(objs_list, params)
		params = params or {}
		params.obj = params.obj or objs_list

		if ObjListLines_Clear(params.obj) and not params.skip_return then
			return
		end

		SuspendPassEdits("ChoGGi_Funcs.Common.ObjListLines_Toggle")
		ObjListLines_Add(objs_list,
			params.obj,
			params.colour or RandomColourLimited()
		)
		ResumePassEdits("ChoGGi_Funcs.Common.ObjListLines_Toggle")
	end
end

-- Make build menu items consistently placed
function ChoGGi_Funcs.Common.SortBuildMenuItems()
	local templates = Presets.BuildingTemplate
	for i = 1, #templates do
		local items = templates[i]

		table.sort(items, function(a, b)
			return CmpLower(Translate(a.display_name), Translate(b.display_name))
		end)

		for j = 1, #items do
			items[j].build_pos = j
		end
	end
end

-- Show info when trying to open a blacklisted func
function ChoGGi_Funcs.Common.BlacklistMsg(name)
	local msg = T{302535920000242--[[<func_name> is blocked by SM function blacklist!]],
		func_name = name,
	}
	if not testing then
		MsgPopup(msg, T(302535920000000--[[Expanded Cheat Menu]]))
	end
	print(Translate(msg))
end

-- loop through all map sectors and fire this func
--~ function ChoGGi_Funcs.Common.LoopMapSectors(map_id, func)
--~ end
--~ local sector_nums = {
--~  [1] = true,
--~  [2] = true,
--~  [3] = true,
--~  [4] = true,
--~  [5] = true,
--~  [6] = true,
--~  [7] = true,
--~  [8] = true,
--~  [9] = true,
--~  [10] = true,
--~ }
--~ }
--~ local sectors = MainCity.MapSectors
--~ for sector in pairs(sectors) do
--~ 	if not sector_nums[sector] then


--
-- bugged
--~ function ChoGGi_Funcs.Common.SendDroneToCC(drone, new_hub)
--~ 	local old_hub = drone.command_center
--~ 	if old_hub == new_hub then
--~ 		return
--~ 	end
--~ 	-- ultra valid
--~ 	if IsValid(old_hub) and IsValid(new_hub) and IsValid(drone)
--~ 	-- if drone dist to new hub is further than dist to old hub than pack and unpack, otherwise SetCommandCenter() to drive over
--~ 		and drone:GetDist(old_hub) < drone:GetDist(new_hub)
--~ 	then
--~ 		-- DroneControl:ConvertDroneToPrefab()
--~ 		if drone.demolishing then
--~ 			drone:ToggleDemolish()
--~ 		end
--~ 		drone.can_demolish = false
--~ 		UICity.drone_prefabs = UICity.drone_prefabs + 1
--~ 		table.remove_entry(old_hub.drones, drone)
--~ 		SelectionArrowRemove(drone)
--~ 		drone:SetCommand("DespawnAtHub")

--~ 		-- wait till drone is sucked up
--~ 		while IsValid(drone) do
--~ 			Sleep(1000)
--~ 		end
--~ 		-- spawn drone from prefab at new hub
--~ 		if UICity.drone_prefabs > 0 then
--~ 			new_hub:UseDronePrefab()
--~ 		end
--~ 	else
--~ 		-- close enough to drive
--~ 		drone:SetCommandCenter(hub)
--~ 	end
--~ end


-- DEPRECATE (someday)


do -- AddToOriginal
	local Original = ChoGGi_Funcs.Original

	function ChoGGi_Funcs.Common.AddToOriginal(name)
		if not Original[name] then
			Original[name] = DotPathToObject(name)
		end
	end
end -- do
-- remove after next mass mod upload
-- backup orginal function for later use (checks if we already have a backup, or else inf problems)
local function SaveOrigFunc(class_or_func, func_name)
	local Original = ChoGGi_Funcs.Original
	-- If it's a class func
	if func_name then
		local newname = class_or_func .. "_" .. func_name
		if not Original[newname] then
			local class_obj = g_env[class_or_func]
			if class_obj then
				Original[newname] = class_obj[func_name]
			end
		end
	-- regular func
	else
		if not Original[class_or_func] then
			Original[class_or_func] = g_env[class_or_func]
		end
	end
end
ChoGGi_Funcs.Common.SaveOrigFunc = SaveOrigFunc

do -- AddMsgToFunc
	local Msg = Msg
	-- changes a function to also post a Msg for use with OnMsg
	function ChoGGi_Funcs.Common.AddMsgToFunc(class_name, func_name, msg_str, thread, ...)
		-- anything i want to pass onto the msg
		local varargs = {...}
		-- save orig
		SaveOrigFunc(class_name, func_name)
		-- we want to local this after SaveOrigFunc just in case
--~ 		local ChoGGi_Funcs.Original = ChoGGi_Funcs.Original
		-- redefine it
		local newname = class_name .. "_" .. func_name
		_G[class_name][func_name] = function(obj, ...)
			-- send obj along with any extra args i added
			if thread then
				-- calling it from a thread creates a slight delay
				CreateRealTimeThread(Msg, msg_str, obj, table.unpack(varargs))
			else
				Msg(msg_str, obj, table.unpack(varargs))
			end

--~ 			-- use to debug if getting an error
--~ 			local params = {...}
--~ 			-- pass on args to orig func
--~ 			if not pcall(function()
--~ 				return ChoGGi_Funcs.Original[class_name .. "_" .. func_name](table.unpack(params))
--~ 			end) then
--~ 				print("Function Error: ", class_name .. "_" .. func_name)
--~ 				OpenExamine({params}, nil, "AddMsgToFunc")
--~ 			end
--~ 			--
			return ChoGGi_Funcs.Original[newname](obj, ...)
		end
	end
end -- do
