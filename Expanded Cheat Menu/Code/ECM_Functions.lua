-- See LICENSE for terms

local ChoGGi_Funcs = ChoGGi_Funcs
local what_game = ChoGGi.what_game

local table = table
local type, pairs, next, print, string = type, pairs, next, print, string
local tostring, tonumber, rawget, rawset = tostring, tonumber, rawget, rawset
local IsKindOf = IsKindOf
local IsValid = IsValid
local Max = Max
local Sleep = Sleep
local WaitMsg = WaitMsg
local T = T

local IsValidXWin = ChoGGi_Funcs.Common.IsValidXWin
local MsgPopup = ChoGGi_Funcs.Common.MsgPopup
local RandomColourLimited = ChoGGi_Funcs.Common.RandomColourLimited
local RetName = ChoGGi_Funcs.Common.RetName
local Translate = ChoGGi_Funcs.Common.Translate
local GetCityLabels = ChoGGi_Funcs.Common.GetCityLabels

local blacklist = ChoGGi.blacklist
local testing = ChoGGi.testing

local g_env = _G
local debug, io
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	blacklist = false
	g_env, debug, io = env, env.debug, env.io
end

local function SetCheatsMenuPos(pos)
	pos = pos or ChoGGi.UserSettings.KeepCheatsMenuPosition
	if pos then
		XShortcutsTarget:SetPos(pos)
	else
		if what_game == "Mars" then
			XShortcutsTarget:SetPos(GetSafeMargins():min())
		end
	end
end
ChoGGi_Funcs.Common.SetCheatsMenuPos = SetCheatsMenuPos

function ChoGGi_Funcs.Common.DraggableCheatsMenu(enable)
	local XShortcutsTarget = XShortcutsTarget

	-- always add the move control so we can re-pos for xbox
	if not XShortcutsTarget.idMoveControl then
		-- add move control to menu
		XShortcutsTarget.idMoveControl = g_Classes.XMoveControl:new({
			Id = "idMoveControl",
			MinHeight = 6,
			VAlign = "top",
		}, XShortcutsTarget)
	end

	if enable then
		-- add a bit of spacing above menu
		XShortcutsTarget.idMenuBar:SetPadding(box(0, 6, 0, 0))

		-- move the move control to the padding space we created above
		CreateRealTimeThread(function()
			WaitMsg("OnRender")
			-- needs a delay (cause we added the control?)
			local height = -XShortcutsTarget.idToolbar.box:maxy()
			XShortcutsTarget.idMoveControl:SetMargins(box(0, height, 0, 0))
		end)
	else
		-- remove my padding
		XShortcutsTarget.idMenuBar:SetPadding(box(0, 0, 0, 0))
		-- restore to original pos
		SetCheatsMenuPos()
	end

end

function ChoGGi_Funcs.Common.SetCommanderBonuses(name)
	local comm = GetCommanderProfile(g_CurrentMissionParams.idCommanderProfile)
	if not comm then
		return
	end
	local c = #comm

	local comms = ChoGGi.Tables.Commanders[name] or ""
	for i = 1, #comms do
		c = c + 1
		comm[c] = comms[i]
	end
end

function ChoGGi_Funcs.Common.SetSponsorBonuses(name)
	local CompareAmounts = ChoGGi_Funcs.Common.CompareAmounts

	local sponsor = GetMissionSponsor(g_CurrentMissionParams.idMissionSponsor)
	if not sponsor then
		return
	end
	local c = #sponsor

	local bonus = ChoGGi.Tables.Sponsors[name]

	-- bonuses multiple sponsors have (CompareAmounts returns equal or larger amount)
	if sponsor.cargo then
		sponsor.cargo = CompareAmounts(sponsor.cargo, bonus.cargo)
	end
	if sponsor.additional_research_points then
		sponsor.additional_research_points = CompareAmounts(sponsor.additional_research_points, bonus.additional_research_points)
	end

	-- add extra bonuses to current sponsor
	for i = 1, #bonus do
		c = c + 1
		sponsor[c] = bonus[i]
	end

	-- figure out how to add this as a loop?
	if name == "BlueSun" then
		sponsor.rocket_price = CompareAmounts(sponsor.rocket_price, bonus.rocket_price)
		sponsor.applicants_price = CompareAmounts(sponsor.applicants_price, bonus.applicants_price)
	elseif name == "ESA" then
		sponsor.funding_per_tech = CompareAmounts(sponsor.funding_per_tech, bonus.funding_per_tech)
		sponsor.funding_per_breakthrough = CompareAmounts(sponsor.funding_per_breakthrough, bonus.funding_per_breakthrough)
	elseif name == "SpaceY" then
		sponsor.modifier_name1 = CompareAmounts(sponsor.modifier_name1, bonus.modifier_name1)
		sponsor.modifier_value1 = CompareAmounts(sponsor.modifier_value1, bonus.modifier_value1)
		sponsor.modifier_name2 = CompareAmounts(sponsor.modifier_name2, bonus.bonusmodifier_name2)
		sponsor.modifier_value2 = CompareAmounts(sponsor.modifier_value2, bonus.modifier_value2)
		sponsor.modifier_name3 = CompareAmounts(sponsor.modifier_name3, bonus.modifier_name3)
		sponsor.modifier_value3 = CompareAmounts(sponsor.modifier_value3, bonus.modifier_value3)
	elseif name == "Roscosmos" then
		sponsor.modifier_name1 = CompareAmounts(sponsor.modifier_name1, bonus.modifier_name1)
		sponsor.modifier_value1 = CompareAmounts(sponsor.modifier_value1, bonus.modifier_value1)
	elseif name == "Paradox" then
		sponsor.applicants_per_breakthrough = CompareAmounts(sponsor.applicants_per_breakthrough, bonus.applicants_per_breakthrough)
		sponsor.anomaly_bonus_breakthrough = CompareAmounts(sponsor.anomaly_bonus_breakthrough, bonus.anomaly_bonus_breakthrough)
	end
end

function ChoGGi_Funcs.Common.GenerateScreenshotFilename(prefix, folder, ext, just_name, ...)
	if blacklist then
		return GenerateScreenshotFilename(prefix, folder, ext, just_name, ...)
	end
	prefix = prefix or ""
	ext = ext or "png"
	folder = folder or "AppData/"
	if not string.match(folder, "/$") and #folder > 0 then
		folder = folder .. "/"
	end
	local existing_files = io.listfiles(folder, prefix .. "*." .. ext, "non recursive")
	local index = 0
	for i = 1, #existing_files do
		index = Max(index, tonumber(string.match(existing_files[i], prefix .. "(%d+)" or 0)))
	end
	if just_name then
		return string.format("%s%04d", prefix, index + 1)
	end
	return string.format("%s%s%04d.%s", folder, prefix, index + 1, ext)
end

do -- DumpTableFunc
	local CmpLower = CmpLower

	local output_list = {}
	local c
	local level_limit

	local function SortTableFunc(a, b)
		if a.key and b.key then
			return CmpLower(
				RetName(a.key),
				RetName(b.key)
			)
		end
		return a.key and true or b.key and true
	end

	local function DumpTableFunc(obj, level, parent_name)
		if level == level_limit then
			return 0
		end

		if type(obj) == "table" then

			local obj_name = RetName(obj)

			c = c + 1
			output_list[c] = "\n\n------------------------- "
			if parent_name then
				c = c + 1
				output_list[c] = parent_name
				c = c + 1
				output_list[c] = " "
			end
			c = c + 1
			output_list[c] = obj_name
			c = c + 1
			output_list[c] = ":"
			c = c + 1
			output_list[c] = "\n"

			-- get all the key/values then sort the table
			local temp_list = {}
			local t_c = 0

			-- get all key/value pairs in the table
			for key, value in pairs(obj) do
				t_c = t_c + 1
				temp_list[t_c] = {
					key = key,
					value = value,
				}
			end
			table.sort(temp_list, SortTableFunc)

			-- now we can return an ordered list
			for i = 1, t_c do
				local item = temp_list[i]
				c = c + 1
				output_list[c] = "\n"
				c = c + 1
				output_list[c] = RetName(item.key)
				c = c + 1
				output_list[c] = ": "
				c = c + 1
				output_list[c] = RetName(item.value)
			end

			c = c + 1
			output_list[c] = "\n"

			-- go through once and dump any tables in the table
			for i = 1, t_c do
				local item = temp_list[i]
				if type(item.key) == "table" then
					DumpTableFunc(item.key, level+1, RetName(item.value))
				end
				if type(item.value) == "table" then
					DumpTableFunc(item.value, level+1, RetName(item.key))
				end
			end

		end
	end

	--[[
	mode = -1 to append or nil to overwrite (default: append)
	limit = how far down the rabbit hole (default 3)
	]]
	function ChoGGi_Funcs.Common.DumpTable(obj, mode, limit)
		if blacklist then
			ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.DumpTable")
			return
		end
		if type(obj) ~= "table" then
			MsgPopup(
				T(302535920000003--[[Can't dump nothing]]),
				T(302535920000004--[[Dump]])
			)
			return
		end
		local name = RetName(obj)

		level_limit = limit or 3

		-- make sure it's empty
		table.iclear(output_list)
		c = 0
		DumpTableFunc(obj, 0)

		if output_list[1] then
			local filename = "AppData/logs/DumpedTable.txt"
			g_env.AsyncStringToFile(filename, table.concat(output_list), mode or "-1")

			local msg = Translate(302535920000039--[[Dumped]]) .. ": " .. name
			-- print msg to first newline
			print(filename,"\n",msg:sub(1,msg:find("\n")))
			MsgPopup(
				msg,
				filename,
				{objects = obj}
			)
			return
		end

		local msg = Translate(302535920000003--[[Can't dump nothing]]) .. ": " .. name .. "\n" .. ValueToLuaCode(obj)
		print(msg)
		MsgPopup(
			msg,
			T(302535920000004--[[Dump]])
		)

	end
end --do

-- returns table with list of files without path or ext and path, or exclude ext to return all files
function ChoGGi_Funcs.Common.RetFilesInFolder(folder, ext)
	local err, files = g_env.AsyncListFiles(folder, ext and "*" .. ext or "*")
	if not err and #files > 0 then
		local table_path = {}
		local path = folder:sub(-1) == "/" and folder or folder .. "/"
		for i = 1, #files do
			local file = files[i]
			local name
			if ext then
				name = file:gsub(path, ""):gsub(ext, "")
			else
				name = file:gsub(path, "")
			end
			table_path[i] = {
				path = file,
				name = name,
			}
		end
		return table_path
	end
end

function ChoGGi_Funcs.Common.RetFoldersInFolder(folder)
	local err, folders = g_env.AsyncListFiles(folder, "*", "folders")
	if not err and #folders > 0 then
		local table_path = {}
		local path = folder .. "/"
		for i = 1, #folders do
			table_path[i] = {
				path = folders[i],
				name = folders[i]:gsub(path, ""),
			}
		end
		return table_path
	end
end

function ChoGGi_Funcs.Common.OpenInMonitorInfoDlg(list, parent)
	if type(list) ~= "table" then
		return
	end

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	return ChoGGi_DlgMonitorInfo:new({}, terminal.desktop, {
		obj = list,
		parent = parent,
		tables = list.tables,
		values = list.values,
	})
end

function ChoGGi_Funcs.Common.OpenInDTMSlotsDlg(parent)
	-- If fired from action menu
	if parent and (IsKindOf(parent, "XAction") or not IsKindOf(parent, "XWindow")) then
		parent = nil
	end

	return ChoGGi_DlgDTMSlots:new({}, terminal.desktop, {
		parent = parent,
	})
end

function ChoGGi_Funcs.Common.MonitorThreads()
	local table_list = {}
	local dlg = OpenExamineReturn(table_list, {
		has_params = true,
		auto_refresh = true,
		title = T(302535920000853--[[Monitor]]) .. ": ThreadsRegister",
	})

	local RetThreadInfo = ChoGGi_Funcs.Common.RetThreadInfo

	CreateRealTimeThread(function()
		-- stop when dialog is closed
		local ThreadsRegister = ThreadsRegister
		while IsValidXWin(dlg) do
			-- only update when it's our dlg sending the msg
			local _, msg_dlg = WaitMsg("ChoGGi_dlgs_examine_autorefresh")
			if msg_dlg == dlg then
				-- we use a "tags" tag to store a unique number (examine uses tags off for text, so we need to use on
				local c = 0
				table.clear(table_list)
				for thread in pairs(ThreadsRegister) do
					if blacklist then
						-- first func is always a C func (WaitMsg or Sleep), and we want a file name
						local info = RetThreadInfo(thread)[2]
						if info then
							c = c + 1
							table_list[info.func .. "<tags on " .. c .. ">"] = thread
						end
					else
						local info = debug.getinfo(thread, 1, "S")
						if info then
							c = c + 1
							table_list[info.source .. "(" .. info.linedefined .. ")<tags on " .. c .. ">"] = thread
						end
					end
				end
			end

		end
	end)
end

-- sortby: nil = table length, 1 = table names
-- skip_under: don't show any tables under this length (default 25)
--~ 	ChoGGi_Funcs.Common.MonitorTableLength(_G)
function ChoGGi_Funcs.Common.MonitorTableLength(obj, skip_under, sortby, title)
	obj = obj or g_env
	title = title or RetName(obj)
	skip_under = skip_under or 25
	local table_list = {}
	local dlg = OpenExamineReturn(table_list, {
		has_params = true,
		auto_refresh = true,
		title = title,
	})

	local PadNumWithZeros = ChoGGi_Funcs.Common.PadNumWithZeros

	CreateRealTimeThread(function()
		-- stop when dialog is closed
		while IsValidXWin(dlg) do
			-- only update when it's our dlg sending the msg
			local _,msg_dlg = WaitMsg("ChoGGi_dlgs_examine_autorefresh")
			if msg_dlg == dlg then
				table.clear(table_list)

				for key, value in pairs(obj) do
					if type(value) == "table" then
						-- tables can be index or associative or a mix
						local length = 0
						for _ in pairs(value) do
							length = length + 1
						end
						-- skip the tiny tables
						if length > skip_under then
							if not sortby then
								table_list[PadNumWithZeros(length) .. " " .. key] = value
							elseif sortby == 1 then
								table_list[key .. " " .. length] = value
							end
						end

					end
				end
			end

		end
	end)
end

function ChoGGi_Funcs.Common.SetParticles(obj)
	-- If fired from action menu
	if IsKindOf(obj, "XAction") then
		obj = ChoGGi_Funcs.Common.SelObject()
	else
		obj = obj or ChoGGi_Funcs.Common.SelObject()
	end

	local name = T(302535920000129--[[Set]]) .. " " .. T(302535920001184--[[Particles]])
	if not obj or obj and not obj:IsKindOf("FXObject") then
		MsgPopup(
			T(302535920000027--[[Nothing selected]]) .. ": " .. "FXObject",
			name
		)
		return
	end

	local PlayFX = PlayFX
	-- make a list of spot names for the obj, so we skip particles that need that spot
	local spots = {}
	local id_start, id_end = obj:GetAllSpots(obj:GetState())
	for i = id_start, id_end do
		spots[obj:GetSpotName(i)] = true
	end

	local default = T(1000121--[[Default]])

	local item_list = {
		{text = " " .. default, value = default},
	}
	local c = #item_list

	local dupes = {}

	local particles = FXLists.ActionFXParticles
	for i = 1, #particles do
		local p = particles[i]
		local name = p.Actor .. ", " .. p.Action .. ", " .. p.Moment
		if not dupes[name] then
			dupes[name] = true
			if spots[p.Spot] or p.Spot == "" then
				c = c + 1
				item_list[c] = {
					text = name,
					value = p.Actor,
					action = p.Action,
					moment = p.Moment,
					handle = p.handle,
					index = i,
					hint = "Actor: " .. p.Actor .. ", Action: " .. p.Action .. ", Moment: " .. p.Moment,
				}
			end
		end
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]
		local actor = choice.value
		local action = choice.action
		local moment = choice.moment

		-- If there's one playing then stop it
		if obj.ChoGGi_playing_fx then
			PlayFX(obj.ChoGGi_playing_fx, "end", obj)
			if obj.DestroyFX then
				obj:DestroyFX(obj, obj.ChoGGi_playing_fx)
			end
			obj.ChoGGi_playing_fx = nil
		end
		-- save fx id so we can stop it
		obj.ChoGGi_playing_fx = action

		if obj.fx_actor_class_ChoGGi_Orig == nil then
			obj.fx_actor_class_ChoGGi_Orig = obj.fx_actor_class
		end

		obj.fx_actor_class = actor

		particles[choice.index].Actor = "any"

		if actor == default then
			if obj.fx_actor_class_ChoGGi_Orig then
				obj.fx_actor_class = obj.fx_actor_class_ChoGGi_Orig
				obj.fx_actor_class_ChoGGi_Orig = nil
			end
			obj.ChoGGi_playing_fx = nil
		else
			PlayFX(action, moment, obj)
		end

		MsgPopup(action,name)
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = name,
		hint = T(302535920001421--[[Shows list of particles to quickly test out on objects.]]),
		custom_type = 7,
		skip_icons = true,
	}
end

-- Shows console when it's not visible (otherwise focuses on the console)
function ChoGGi_Funcs.Common.ShowConsole(show)
	local dlg = dlgConsole
	local visible = dlg and dlg:GetVisible()

	if IsKindOf(show, "XAction") then
		show = not visible
		if dlg and visible then
			dlg.idEdit:SetFocus()
			return
		end
	end

	ShowConsole(show or not visible)
	-- ShowConsole can reset the dlgConsole ref
	dlgConsole.idEdit:SetFocus()

-- maybe see about overriding focus from construct dlg
end

-- toggle visiblity of console log
function ChoGGi_Funcs.Common.ToggleConsoleLog()
	local log = dlgConsoleLog
	if log then
		if log:GetVisible() then
			log:SetVisible(false)
		else
			log:SetVisible(true)
		end
	else
		dlgConsoleLog = ConsoleLog:new({}, terminal.desktop)
	end
end

-- Any png files in AppData/Logos folder will be added to mod as converted logo files.
-- They have to be min of 8bit, and be resized to power of 2 (add transparent space).
-- This doesn't add anything to metadata/items lua, it only converts files.
--~ 	ChoGGi_Funcs.Common.ConvertImagesToLogoFiles("MOD_ID")
--~ 	ChoGGi_Funcs.Common.ConvertImagesToLogoFiles(Mods.MOD_ID, ".tga")
--~ ChoGGi_Funcs.Common.ConvertImagesToLogoFiles(Mods.ChoGGi_)
function ChoGGi_Funcs.Common.ConvertImagesToLogoFiles(mod, ext)
	if blacklist then
		ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.ConvertImagesToLogoFiles")
		return
	end
	--
	if not mod then
		mod = Mods.TESTING
	end
	if type(mod) == "string" then
		mod = Mods[mod]
	end
	--
	local images = ChoGGi_Funcs.Common.RetFilesInFolder("AppData/Logos", ext or ".png")
	if images then
		-- returns error msgs and prints in console
		local TGetID = TGetID
		local fake_ged_socket = {
			ShowMessage = function(msg, title)
				if TGetID(title) == 12061 then
					print("ShowMessage", Translate(title), msg, "\nCan probably ignore, check mod folder for images")
				end
			end,
		}

		local ModItemDecalEntity = ModItemDecalEntity
		local Import = ModItemDecalEntity.Import
		local ConvertToOSPath = ConvertToOSPath

--~ 		local ChoOrig_g_HgimgcvtPath = g_HgimgcvtPath
--~ 		if testing then
--~ 			-- help will return true under windows (if someone cares, I'll make it a saved setting).
--~ 			g_HgimgcvtPath = "help"
--~ 		end

		for i = 1, #images do
			local image = images[i]

			local filename = ConvertToOSPath(image.path)
			-- ModItemDecalEntity:Import(obj, prop_id, ged_socket)
			-- self/prop_id not used
			Import(nil,
				ModItemDecalEntity:new{
					entity_name = image.name,
					name = image.name,
--~ 					filename = filename:gsub("\\", "/"),
					filename = filename,
					mod = mod,
				},
				nil,
				fake_ged_socket
			)
			print(filename)
		end
		--
--~ 		g_HgimgcvtPath = ChoOrig_g_HgimgcvtPath
	end
end

do -- ConvertImagesToResEntities
	-- converts png images (512x512) to an entity you can use to replace deposit signs.
	local ConvertToOSPath = ConvertToOSPath
	local RetFilesInFolder = ChoGGi_Funcs.Common.RetFilesInFolder
--~ 	ModItemDecalEntity:Import
	local function ModItemDecalEntityImport(name, filename, mod)
		local output_dir = ConvertToOSPath(mod.content_path)

		local ent_dir = output_dir .. "Entities/"
		local ent_file = name .. ".ent"
		local ent_output = ent_dir .. ent_file

		local mtl_dir = output_dir .. "Entities/Materials/"
		local mtl_file = name .. "_mesh.mtl"
		local mtl_output = mtl_dir .. mtl_file

		local texture_dir = output_dir .. "Entities/Textures/"
		local texture_output = texture_dir .. name .. ".dds"

		local fallback_dir = texture_dir .. "Fallbacks/"
		local fallback_output = fallback_dir .. name .. ".dds"

		local err = g_env.AsyncCreatePath(ent_dir)
		if err then
			return err
		end
		err = g_env.AsyncCreatePath(mtl_dir)
		if err then
			return err
		end
		err = g_env.AsyncCreatePath(texture_dir)
		if err then
			return err
		end
		err = g_env.AsyncCreatePath(fallback_dir)
		if err then
			return err
		end

		err = g_env.AsyncStringToFile(ent_output, [[<?xml version="1.0" encoding="UTF-8"?>
<entity path="">
	<state id="idle">
		<mesh_ref ref="mesh"/>
	</state>
	<mesh_description id="mesh">
		<src file=""/>
		<mesh file="SignConcreteDeposit_mesh.hgm"/>
		<material file="]] .. mtl_file .. [["/>
		<bsphere value="0, 0, 50, 1301"/>
		<box min="-920, -920, 50" max="920, 920, 50"/>
	</mesh_description>
</entity>
]])

		if err then
			return
		end

		local cmdline = [["]] .. ConvertToOSPath(g_HgnvCompressPath) .. [[" -dds10 -24 bc1 -32 bc3 -srgb "]] .. filename .. [[" "]] .. texture_output .. [["]]
		err = g_env.AsyncExec(cmdline, "", true, false)
		if err then
			return err
		end
		cmdline = [["]] .. ConvertToOSPath(g_DdsTruncPath) .. [[" "]] .. texture_output .. [[" "]] .. fallback_output .. [[" "]] .. const.FallbackSize .. [["]]
		err = g_env.AsyncExec(cmdline, "", true, false)
		if err then
			return err
		end
--~ 			cmdline = [["]] .. ConvertToOSPath(g_HgimgcvtPath) .. [[" "]] .. texture_output .. [[" "]] .. ui_output .. [["]]
--~ 			err = g_env.AsyncExec(cmdline, "", true, false)
--~ 			if err then
--~ 				return err
--~ 			end

		err = g_env.AsyncStringToFile(mtl_output, [[<?xml version="1.0" encoding="UTF-8"?>
<Materials>
<Material>
	<BaseColorMap Name="]] .. name .. [[.dds" mc="0"/>
	<SIMap Name="BackLight.dds" mc="0"/>
	<Property Special="None"/>
	<Property AlphaBlend="Blend"/>
</Material>
</Materials>]])

		if err then
			return err
		end
	end

--~ 	ChoGGi_Funcs.Common.ConvertImagesToResEntities("ChoGGi_ExampleNewResIcon")
--~ 	ChoGGi_Funcs.Common.ConvertImagesToResEntities("MOD_ID")
--~ 	ChoGGi_Funcs.Common.ConvertImagesToResEntities(Mods.MOD_ID, ".tga")
	function ChoGGi_Funcs.Common.ConvertImagesToResEntities(mod, ext)
		if blacklist then
			ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.ConvertImagesToResEntities")
			return
		end
		mod = mod or Mods.ChoGGi_
		if type(mod) == "string" then
			mod = Mods[mod]
		end
		local images = RetFilesInFolder("AppData/Logos", ext or ".png")
		if images then
			for i = 1, #images do
				local filename = ConvertToOSPath(images[i].path)
				ModItemDecalEntityImport(
					images[i].name,
					filename:gsub("\\", "/"),
					mod
				)
				print(filename)
			end
		end

	end
end -- do



do -- DisplayObjectImages
	local CmpLower = CmpLower
	local getmetatable = getmetatable
	local images_table
	local ImageExts = ChoGGi_Funcs.Common.ImageExts

	-- grab any strings with the correct ext
	local function AddToList(c, key, value)
		if type(value) == "string" and ImageExts()[value:sub(-3):lower()] then
			local dupe_test = key .. value

			if not images_table.dupes[dupe_test] then
				c = c + 1
				images_table[c] = {
					name = key,
					path = value,
				}
				images_table.dupes[dupe_test] = true
			end
		end
		return c
	end

	function ChoGGi_Funcs.Common.DisplayObjectImages(obj, parent, images)
		images_table = images or {
			dupes = {},
		}
		if type(obj) ~= "table" then
			return #images_table > 0
		end
		local c = #images_table

		-- and images
		for key, value in pairs(obj) do
			c = AddToList(c, key, value)
		end
		-- any meta images
		local meta = getmetatable(obj)
		while meta do
			for key, value in pairs(meta) do
				c = AddToList(c, key, obj[key] or value)
			end
			meta = getmetatable(meta)
		end

		-- and sort
		if images_table[1] then
			ChoGGi_Funcs.Common.TableCleanDupes(images_table)
			table.sort(images_table, function(a, b)
				return CmpLower(a.name, b.name)
			end)
			ChoGGi_Funcs.Common.OpenInImageViewerDlg(images_table, parent)
			return true
		end
		return false

	end
end -- do

function ChoGGi_Funcs.Common.MoveObjToGround(obj)
	obj:SetZ(obj:GetPos():SetTerrainZ())
end

function ChoGGi_Funcs.Common.GetDesktopWindow(class)
	local desktop = terminal.desktop
	return desktop[table.find(desktop, "class", class)]
end

do -- DebugGetInfo
	local format_value = format_value

	-- this replaces the func added in my library mod (which is just a straight format_value)
	function ChoGGi_Funcs.Common.DebugGetInfo(obj)
		if not obj then
			return
		end
		if blacklist then
			return format_value(obj)
		else
			local info = debug.getinfo(obj)
			-- sub(2): removes @, Mars is ingame files, mods is mods...
			local src = info.source ~= "" and info.source or info.short_src
			return src:sub(2):gsub("Mars/", ""):gsub("AppData/Mods/", "")
				.. "(" .. info.linedefined .. ")"
		end
	end
end -- do

do -- ReturnTechAmount/GetResearchedTechValue
	local floatfloor = floatfloor
	--[[
	ReturnTechAmount(tech, prop)
	returns number from Object (so you know how much it changes)
	see: Data/Object.lua, or ex(Object)

	ReturnTechAmount("GeneralTraining", "NonSpecialistPerformancePenalty")
	^returns 10
	ReturnTechAmount("SupportiveCommunity", "LowSanityNegativeTraitChance")
	^ returns 0.7

	it returns percentages in decimal for ease of mathing (SM has no math. funcs)
	ie: SupportiveCommunity is -70 this returns it as 0.7
	it also returns negative amounts as positive (I prefer num - Amt, not num + NegAmt)
	]]
	local function ReturnTechAmount(tech, prop)
		local techdef = TechDef[tech]
		local idx = table.find(techdef, "Prop", prop)
		if idx then
			tech = techdef[idx]
			local number

			-- With enemies you know where they stand but with Neutrals, who knows?
			-- defaults for the objects have both percent/amount, so whoever isn't 0 means something
			if tech.Percent == 0 then
				if tech.Amount < 0 then
					number = -tech.Amount
				else
					number = tech.Amount
				end
			-- probably just have an else here instead...
			elseif tech.Amount == 0 then
				if tech.Percent < 0 then
					tech.Percent = -tech.Percent -- -50 > 50
				end
				number = (tech.Percent + 0.0) / 100 -- (50 > 50.0) > 0.50
			end

			return number
		end
	end
	ChoGGi_Funcs.Common.ReturnTechAmount = ReturnTechAmount

	function ChoGGi_Funcs.Common.GetResearchedTechValue(name, cls)
		local ChoGGi_Consts = ChoGGi.Consts
		local IsTechResearched = IsTechResearched

		-- cls
		if name == "RCTransportStorageCapacity" then
			local amount = cls == "RCConstructor" and ChoGGi_Consts.RCConstructorStorageCapacity or ChoGGi_Consts.RCTransportStorageCapacity

			if IsTechResearched("TransportOptimization") then
				local a = ReturnTechAmount("TransportOptimization", "max_shared_storage")
				return amount + (a * const.ResourceScale)
			end
			return amount
		end

		--
		if name == "DroneBatteryMax" then
			if IsTechResearched("BatteryOptimization") then
				local p = ReturnTechAmount("BatteryOptimization", "battery_max")
				return floatfloor(ChoGGi_Consts.DroneBatteryMax + (ChoGGi_Consts.DroneBatteryMax * p))
			end
			return ChoGGi_Consts.DroneBatteryMax
		end
		--
		if name == "SpeedDrone" then
			local move_speed = ChoGGi_Consts.SpeedDrone

			if IsTechResearched("LowGDrive") then
				local p = ReturnTechAmount("LowGDrive", "move_speed")
				move_speed = move_speed + (move_speed * p)
			end
			if IsTechResearched("AdvancedDroneDrive") then
				local p = ReturnTechAmount("AdvancedDroneDrive", "move_speed")
				move_speed = move_speed + (move_speed * p)
			end
			return floatfloor(move_speed)
		end
		--
		if name == "MaxColonistsPerRocket" then
			local per_rocket = ChoGGi_Consts.MaxColonistsPerRocket
			if IsTechResearched("CompactPassengerModule") then
				local a = ReturnTechAmount("CompactPassengerModule", "MaxColonistsPerRocket")
				per_rocket = per_rocket + a
			end
			if IsTechResearched("CryoSleep") then
				local a = ReturnTechAmount("CryoSleep", "MaxColonistsPerRocket")
				per_rocket = per_rocket + a
			end
			return per_rocket
		end
		--
		if name == "FuelRocket" then
			if IsTechResearched("AdvancedMartianEngines") then
				local a = ReturnTechAmount("AdvancedMartianEngines", "launch_fuel")
				return ChoGGi_Consts.LaunchFuelPerRocket - (a * const.ResourceScale)
			end
			return ChoGGi_Consts.LaunchFuelPerRocket
		end
		--
		if name == "SpeedRC" then
			if IsTechResearched("LowGDrive") then
				local p = ReturnTechAmount("LowGDrive", "move_speed")
				return floatfloor(ChoGGi_Consts.SpeedRC + (ChoGGi_Consts.SpeedRC * p))
			end
			return ChoGGi_Consts.SpeedRC
		end
		--
		if name == "CargoCapacity" then
			if IsTechResearched("FuelCompression") then
				local a = ReturnTechAmount("FuelCompression", "CargoCapacity")
				return ChoGGi_Consts.CargoCapacity + a
			end
			return ChoGGi_Consts.CargoCapacity
		end
		--
		if name == "CommandCenterMaxDrones" then
			if IsTechResearched("DroneSwarm") then
				local a = ReturnTechAmount("DroneSwarm", "CommandCenterMaxDrones")
				return ChoGGi_Consts.CommandCenterMaxDrones + a
			end
			return ChoGGi_Consts.CommandCenterMaxDrones
		end
		--
		if name == "DroneResourceCarryAmount" then
			if IsTechResearched("ArtificialMuscles") then
				local a = ReturnTechAmount("ArtificialMuscles", "DroneResourceCarryAmount")
				return ChoGGi_Consts.DroneResourceCarryAmount + a
			end
			return ChoGGi_Consts.DroneResourceCarryAmount
		end
		--
		if name == "LowSanityNegativeTraitChance" then
			if IsTechResearched("SupportiveCommunity") then
				local p = ReturnTechAmount("SupportiveCommunity", "LowSanityNegativeTraitChance")
				--[[
				LowSanityNegativeTraitChance = 30%
				SupportiveCommunity = -70%
				]]
				local LowSan = ChoGGi_Consts.LowSanityNegativeTraitChance + 0.0 --SM has no math.funcs so + 0.0
				return floatfloor((p * LowSan) / (100 * 100))
			end
			return ChoGGi_Consts.LowSanityNegativeTraitChance
		end
		--
		if name == "NonSpecialistPerformancePenalty" then
			if IsTechResearched("GeneralTraining") then
				local a = ReturnTechAmount("GeneralTraining", "NonSpecialistPerformancePenalty")
				return ChoGGi_Consts.NonSpecialistPerformancePenalty - a
			end
			return ChoGGi_Consts.NonSpecialistPerformancePenalty
		end
		--
		if name == "RCRoverMaxDrones" then
			if IsTechResearched("RoverCommandAI") then
				local a = ReturnTechAmount("RoverCommandAI", "RCRoverMaxDrones")
				return ChoGGi_Consts.RCRoverMaxDrones + a
			end
			return ChoGGi_Consts.RCRoverMaxDrones
		end
		--
		if name == "RCTransportGatherResourceWorkTime" then
			if IsTechResearched("TransportOptimization") then
				local p = ReturnTechAmount("TransportOptimization", "RCTransportGatherResourceWorkTime")
				return floatfloor(ChoGGi_Consts.RCTransportGatherResourceWorkTime * p)
			end
			return ChoGGi_Consts.RCTransportGatherResourceWorkTime
		end
		--
		if name == "TravelTimeEarthMars" then
			if IsTechResearched("PlasmaRocket") then
				local p = ReturnTechAmount("PlasmaRocket", "TravelTimeEarthMars")
				return floatfloor(ChoGGi_Consts.TravelTimeEarthMars * p)
			end
			return ChoGGi_Consts.TravelTimeEarthMars
		end
		--
		if name == "TravelTimeMarsEarth" then
			if IsTechResearched("PlasmaRocket") then
				local p = ReturnTechAmount("PlasmaRocket", "TravelTimeMarsEarth")
				return floatfloor(ChoGGi_Consts.TravelTimeMarsEarth * p)
			end
			return ChoGGi_Consts.TravelTimeMarsEarth
		end

	end
end -- do

function ChoGGi_Funcs.Common.RetBuildingPermissions(traits, settings)
	settings.restricttraits = settings.restricttraits or {}
	settings.blocktraits = settings.blocktraits or {}
	traits = traits or {}
	local block, restrict

	local rtotal = 0
	for _ in pairs(settings.restricttraits) do
		rtotal = rtotal + 1
	end

	local rcount = 0
	for trait in pairs(traits) do
		if settings.restricttraits[trait] then
			rcount = rcount + 1
		end
		if settings.blocktraits[trait] then
			block = true
		end
	end

	-- restrict is empty so allow all or since we're restricting then they need to be the same
	if not next(settings.restricttraits) or rcount == rtotal then
		restrict = true
	end

	return block, restrict
end

do -- ShowAnimDebug_Toggle
	local OText

	local function AnimDebug_Show(obj, colour)
		local text = OText:new()
		text:SetColor1(colour)

		-- so we can delete them easy
		text.ChoGGi_AnimDebug = true
		obj:Attach(text, 0)

		local obj_bbox = obj:GetObjectBBox():sizez()

		text:SetAttachOffset(point(0, 0, obj_bbox + 100))
		CreateGameTimeThread(function()
			while IsValid(text) do
				text:SetText(obj:GetAnimDebug())
				WaitNextFrame()
			end
		end)
	end

	local function AnimDebug_Hide(obj)
		obj:ForEachAttach("ChoGGi_OText", function(a)
			if a.ChoGGi_AnimDebug then
				a:delete()
			end
		end)
	end

	local function AnimDebug_ShowAll(cls, colour)
		local objs = ChoGGi_Funcs.Common.MapGet(cls)
		for i = 1, #objs do
			AnimDebug_Show(objs[i], colour)
		end
	end

	local function AnimDebug_HideAll(cls)
		local objs = ChoGGi_Funcs.Common.MapGet(cls)
		for i = 1, #objs do
			AnimDebug_Hide(objs[i])
		end
	end

	function ChoGGi_Funcs.Common.ShowAnimDebug_Toggle(obj, params)
		-- If fired from action menu
		if IsKindOf(obj, "XAction") then
			obj = ChoGGi_Funcs.Common.SelObject()
		else
			obj = obj or ChoGGi_Funcs.Common.SelObject()
		end
		if not OText then
			OText = ChoGGi_OText
		end
		params = params or {}
		params.colour = params.colour or RandomColourLimited()

		SuspendPassEdits("ChoGGi_Funcs.Common.ShowAnimDebug_Toggle")
		if IsValid(obj) then
			if not obj:GetAnimDebug() then
				return
			end

			if obj.ChoGGi_ShowAnimDebug then
				obj.ChoGGi_ShowAnimDebug = nil
				AnimDebug_Hide(obj)
			else
				obj.ChoGGi_ShowAnimDebug = true
				AnimDebug_Show(obj, params.colour)
			end
		else
			ChoGGi.Temp.ShowAnimDebug = not ChoGGi.Temp.ShowAnimDebug
			if ChoGGi.Temp.ShowAnimDebug then
				AnimDebug_ShowAll("Building", params.colour)
				AnimDebug_ShowAll("Unit", params.colour)
				AnimDebug_ShowAll("CargoShuttle", params.colour)
			else
				AnimDebug_HideAll("Building")
				AnimDebug_HideAll("Unit")
				AnimDebug_HideAll("CargoShuttle")
			end
		end
		ResumePassEdits("ChoGGi_Funcs.Common.ShowAnimDebug_Toggle")
	end
end -- do

do -- ChangeSurfaceSignsToMaterials
	local function ChangeEntity(cls, entity, random)
		MapForEach("map", cls, function(o)
			if random then
				o:ChangeEntity(entity .. Random(1, random))
			else
				o:ChangeEntity(entity)
			end
		end)
	end
	local function ResetEntity(cls)
		local entity = g_Classes[cls]:GetDefaultPropertyValue("entity")
		MapForEach("map", cls, function(o)
			o:ChangeEntity(entity)
		end)
	end

	function ChoGGi_Funcs.Common.ChangeSurfaceSignsToMaterials()

		local item_list = {
			{text = T(754117323318--[[Enable]]), value = true, hint = T(302535920001081--[[Changes signs to materials.]])},
			{text = T(251103844022--[[Disable]]), value = false, hint = T(302535920001082--[[Changes materials to signs.]])},
		}

		local function CallBackFunc(choice)
			if choice.nothing_selected then
				return
			end
			SuspendPassEdits("ChoGGi_Funcs.Common.ChangeSurfaceSignsToMaterials")
			if choice[1].value then
				ChangeEntity("SubsurfaceDepositWater", "DecSpider_01")
				ChangeEntity("SubsurfaceDepositMetals", "DecDebris_01")
				ChangeEntity("SubsurfaceDepositPreciousMetals", "DecSurfaceDepositConcrete_01")
				ChangeEntity("TerrainDepositConcrete", "DecDustDevils_0", 5)
				ChangeEntity("SubsurfaceAnomaly", "DebrisConcrete")
				ChangeEntity("SubsurfaceAnomaly_unlock", "DebrisMetal")
				ChangeEntity("SubsurfaceAnomaly_breakthrough", "DebrisPolymer")
			else
				ResetEntity("SubsurfaceDepositWater")
				ResetEntity("SubsurfaceDepositMetals")
				ResetEntity("SubsurfaceDepositPreciousMetals")
				ResetEntity("TerrainDepositConcrete")
				ResetEntity("SubsurfaceAnomaly")
				ResetEntity("SubsurfaceAnomaly_unlock")
				ResetEntity("SubsurfaceAnomaly_breakthrough")
				ResetEntity("SubsurfaceAnomaly_aliens")
				ResetEntity("SubsurfaceAnomaly_complete")
			end
			ResumePassEdits("ChoGGi_Funcs.Common.ChangeSurfaceSignsToMaterials")
		end

		ChoGGi_Funcs.Common.OpenInListChoice{
			callback = CallBackFunc,
			items = item_list,
			title = T(302535920001083--[[Change Surface Signs]]),
		}
	end
end -- do

function ChoGGi_Funcs.Common.UpdateServiceComfortBld(obj, service_stats)
	if not obj or not service_stats then
		return
	end

	-- check for type as some are boolean
	if type(service_stats.health_change) ~= "nil" then
		obj:SetBase("health_change", service_stats.health_change)
	end
	if type(service_stats.sanity_change) ~= "nil" then
		obj:SetBase("sanity_change", service_stats.sanity_change)
	end
	if type(service_stats.service_comfort) ~= "nil" then
		obj:SetBase("service_comfort", service_stats.service_comfort)
	end
	if type(service_stats.comfort_increase) ~= "nil" then
		obj:SetBase("comfort_increase", service_stats.comfort_increase)
	end

	if obj:IsKindOf("Service") then
		if type(service_stats.visit_duration) ~= "nil" then
			obj:SetBase("visit_duration", service_stats.visit_duration)
		end
		if type(service_stats.usable_by_children) ~= "nil" then
			obj.usable_by_children = service_stats.usable_by_children
		end
		if type(service_stats.children_only) ~= "nil" then
			obj.children_only = service_stats.children_only
		end
		for i = 1, 11 do
			local name = "interest" .. i
			if service_stats[name] ~= "" and type(service_stats[name]) ~= "nil" then
				obj[name] = service_stats[name]
			end
		end
	end

end

do -- ToggleFuncHook
	-- counts funcs calls, and keeps a table of func|line num
	-- call as is ToggleFuncHook()
	-- or with a path to lua files you want to monitor
	-- ChoGGi_Funcs.Common.ToggleFuncHook("@Mars/")
	-- ChoGGi_Funcs.Common.ToggleFuncHook("@CommonLua/")
	-- ChoGGi_Funcs.Common.ToggleFuncHook("@AppData/Mods/")
	-- default path:
	-- ChoGGi_Funcs.Common.ToggleFuncHook("")
	local func_table = {}
	local func_str_c = 0
	local func_str = {}

	function ChoGGi_Funcs.Common.ToggleFuncHook(path, line, mask, count)
		if blacklist then
			ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.ToggleFuncHook")
			return
		end

		if not ChoGGi.Temp.FunctionsHooked then
			ChoGGi.Temp.FunctionsHooked = true
			-- always start fresh
			table.clear(func_table)
			table.iclear(func_str)
			func_str_c = 0

			-- setup path
			path = path or ""
			local str_len = #path

			print(Translate(302535920000497--[[Hook Started]]), path, line, mask, count)
			MsgPopup(
				T(302535920000497--[[Hook Started]]),
				T(1000113--[[Debug]])
			)

			g_env.collectgarbage()
			local function hook_func(event)

				local i
				if event == "call" then
					i = debug.getinfo(2, "Sf")
				else
					i = debug.getinfo(2, "S")
				end

				if i.source:sub(1, str_len) == path and (not line or line and i.linedefined == line) then

					local lua_obj
					if event == "call" then
						lua_obj = i.func
					else
						lua_obj = i.source .. "|" .. i.linedefined
					end

					func_str_c = func_str_c + 1
					func_str[func_str_c] = lua_obj

					local c = func_table[lua_obj] or 1
					func_table[lua_obj] = c + 1
				end
			end
			-- start capture (c = func call, r = func ret, l = enters new line of code)
			debug.sethook(hook_func, mask or "c", count)
		else
			print(Translate(302535920000498--[[Hook Stopped]]), path, line, mask, count)
			MsgPopup(
				T(302535920000498--[[Hook Stopped]]),
				T(1000113--[[Debug]])
			)
			ChoGGi.Temp.FunctionsHooked = false

			-- stop capture
			debug.sethook()

			-- add stringed funcs call order text
			func_table["@@    list_func_call_order"] = {
				ChoGGi_AddHyperLink = true,
				name = Translate(302535920000234--[[Monitor Func Calls]]),
				hint = "Shows list of func calls in order of called.",
--~				func = function(self, button, obj, argument, hyperlink_box, pos)
				func = function()
					OpenExamine(func_str, nil, Translate(302535920000234--[[Monitor Func Calls]]))
				end,
			}

			-- view the results
			OpenExamine(func_table, nil, "Func call count (" .. func_str_c .. ")")

		end
	end
end -- do

do -- PrintToFunc_Add/PrintToFunc_Remove
	local ValueToLuaCode = ValueToLuaCode

	function ChoGGi_Funcs.Common.PrintToFunc_Remove(name, parent)
		name = tostring(name)
		local saved_name = name .. "_ChoGGi_savedfunc"

		local saved = parent[saved_name]
		if saved then
			parent[name] = parent[saved_name]
			parent[saved_name] = nil
		end

	end

	function ChoGGi_Funcs.Common.PrintToFunc_Add(func, name, parent, func_name, params)
		name = tostring(name)
		local saved_name = name .. "_ChoGGi_savedfunc"

		-- move orig to saved name (if it hasn't already been)
		local saved
		if parent == g_env then
			-- SM error spams console if you have the affront to try _G.NonExistingKey... (thanks autorun.lua)
			-- It works prefectly fine of course, but i like a clean log.
			-- In other words a workaround for "Attempt to use an undefined global '"
			saved = rawget(parent, saved_name)
			if not saved then
				rawset(parent, saved_name, func)
				saved = func
			end
		else
			saved = parent[saved_name]
			if not saved then
				parent[saved_name] = func
				saved = func
			end
		end

		local text_table = {}
		local cls_obj = g_Classes[parent.class]

		-- and replace the func reference
		parent[name] = function(...)
			if params then
				table.iclear(text_table)
				local c = 0

				local varargs = {...}
				for i = 1, #varargs do
					local arg = varargs[i]
					c = c + 1
					text_table[c] = "arg "
					c = c + 1
					text_table[c] = i
					c = c + 1
					text_table[c] = ": "

					-- If it's a cls obj the first arg is always the cls obj
					if i == 1 and cls_obj then
						c = c + 1
						text_table[c] = tostring(arg)
						c = c + 1
						text_table[c] = " ("
						c = c + 1
						text_table[c] = RetName(arg)
						c = c + 1
						text_table[c] = ")"
					else
						c = c + 1
						text_table[c] = ValueToLuaCode(arg)
					end

					c = c + 1
					text_table[c] = "\n "
				end
				print(func_name, "\n", table.concat(text_table))
			else
				-- no params
				print(func_name)
			end
			return saved(...)
		end

	end

end -- do

do -- TestLocaleFile
--~ ChoGGi_Funcs.Common.TestLocaleFile(Mods["bMPAkJP"].env.CurrentModPath .. "Locale/TraduzioneItaliano.csv", true)
	local my_locale = ChoGGi.library_path .. "Locales/English.csv"
	local csv_load_fields = {
		"id",
		"text",
		"translated",
		"translated_new",
		"gender"
	}

	local strings_failed, csv_failed
	local strings_count, csv_count

	local function ProcessLoadedTables(loaded_csv, language, out_table, out_gendertable)
		local order
		if language == "English" then
			order = {"translated_new", "text", "translated"}
		else
			order = {"translated_new", "translated", "text"}
		end

		local prev_str = T(1000231--[[Previous]])
		local next_str = T(1000232--[[Next]])
		local cur_str = T(302535920000106--[[Current]])

		for i = 1, #loaded_csv do
			local entry = loaded_csv[i]

			local translation
			local ord1, ord2 = entry[order[1]], entry[order[2]]
			if ord1 and ord1 ~= "" then
				translation = ord1
			elseif ord2 and ord2 ~= "" then
				translation = ord2
			else
				translation = entry[order[3]]
			end

			local id = tonumber(entry.id)

			if id and translation then
				out_table[id] = translation
				if out_gendertable then
					out_gendertable[id] = entry.gender
				end
			else
				strings_count = strings_count + 1
				strings_failed[strings_count] = {
					name = "index: " .. i,
					[cur_str .. " id"] = entry.id,
					[cur_str .. " text"] = entry.text,
					[cur_str .. " translated_new"] = entry.translated_new,
					[cur_str .. " translated"] = entry.translated,
				}
				-- add some context
				local eprev = loaded_csv[i-1]
				local enext = loaded_csv[i+1]
				local str = strings_failed[strings_count]
				if eprev then
					str[prev_str .. " id"] = eprev.id
					str[prev_str .. " text"] = eprev.text
					str[prev_str .. " translated_new"] = eprev.translated_new
					str[prev_str .. " translated"] = eprev.translated
				end
				if enext then
					str[next_str .. " id"] = enext.id
					str[next_str .. " text"] = enext.text
					str[next_str .. " translated_new"] = enext.translated_new
					str[next_str .. " translated"] = enext.translated
				end

			end
		end
	end

	local function TestCSV(filepath, column_limit)
		column_limit = filepath == my_locale and 4 or column_limit
		if not column_limit or column_limit == true or type(column_limit) ~= "number" then
			column_limit = 5
		end

		-- this is the LoadCSV func from CommonLua/Core/ParseCSV.lua with some DebugPrint added
		local omit_captions = "omit_captions"
		local err, str = g_env.AsyncFileToString(filepath)
		if err then
			print(Translate(302535920001125--[[Test Locale File]]), "ERROR:", err, "FILEPATH:", filepath)
			return
		end

		local rows, pos = {}, 1
		local rows_c = 0
		local Q = lpeg.P("\"")
		local quoted_value = Q * lpeg.Cs((1 - Q + Q * Q / "\"") ^ 0) * Q
		local raw_value = lpeg.C((1 - lpeg.S(", \t\r\n\"")) ^ 0)
		local field = (lpeg.P(" ") ^ 0 * quoted_value * lpeg.P(" ") ^ 0 + raw_value) * lpeg.Cp()
		local RemoveTrailingSpaces = RemoveTrailingSpaces

		-- remove any carr returns
		str = str:gsub("\r\n", "\n")
		local str_len = #str

		-- mostly LoadCSV()
		while pos < str_len do
			local row, col = {}, 1
			local lf = str:sub(pos, pos) == "\n"
--~ 				local crlf = str:sub(pos, pos + 1) == "\r\n"

--~ 				while pos < str_len and not lf and not crlf do
			while pos < str_len and not lf do

				local value, nextv = field:match(str, pos)
				value = RemoveTrailingSpaces(value)
				local f_remap_col = csv_load_fields[col]
				if f_remap_col then
					row[f_remap_col] = value
				end
				col = col + 1
				lf = str:sub(nextv, nextv) == "\n"
--~ 					crlf = str:sub(nextv, nextv + 1) == "\r\n"
				pos = nextv + 1

				-- only seems to happen on bad things
				if col > column_limit then
					csv_count = csv_count + 1
					csv_failed[csv_count] = {
						name = "ERROR row: " .. row.id,
						value = value,
						string_pos = pos,
						column = col,
						general_area = str:sub(pos-50, pos+50),
						row_gender = row.gender,
						row_text = row.text,
						row_id = row.id,
						row_translated = row.translated,
						row_translated_new = row.translated_new,
					}
				end

				-- stop inf loop from malformed csv
				if pos >= str_len then
					break
				end
			end -- while inner

--~ 				if crlf then
			if lf then
				pos = pos + 1
			end

			if not omit_captions then
				rows_c = rows_c + 1
				rows[rows_c] = row
			end
			omit_captions = false

			-- stop inf loop from malformed csv
			if pos >= str_len and not lf then
--~ 				if pos >= str_len and not crlf then
				break
			end
		end -- while outer

		return csv_failed, rows
	end

	function ChoGGi_Funcs.Common.TestLocaleFile(filepath, test_csv, language)
		if not filepath then
			if testing then
				local locale_path = ChoGGi.library_path .. "Locales/" .. ChoGGi.lang .. ".csv"
				if ChoGGi_Funcs.Common.FileExists(locale_path) then
					filepath = locale_path
				else
					filepath = my_locale
				end
			else
				print(Translate(302535920001125--[[Test Locale File]]), "FILEPATH ERROR:", filepath)
				return
			end
		end

		-- always reset to 0 for reporting (csv_count > 0)
		csv_count = 0
		csv_failed = {}
		local loaded_csv
		if test_csv then
			if blacklist then
				ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.TestLocaleFile(test_csv)")
			else
				test_csv, loaded_csv = TestCSV(filepath, test_csv)
			end
		end

		-- my TestCSV is the same as LoadCSV, but without an inf loop if it's a malformed csv file
		-- so we skip it for test_csv
		if not loaded_csv then
			loaded_csv = {}
			LoadCSV(
				filepath,
				loaded_csv,
				csv_load_fields,
				"omit_captions"
			)
		end

		strings_failed = {}

		if test_csv then
			strings_failed[-1] = T(302535920001571--[["The way I test the CSV file means there might be some ""non-error"" errors added here.
It's a tradeoff between erroneous errors and the game locking up."]])
		end

		strings_count = 0
		-- this can fail, so we pcall it (some results are better than none)
		local final_strings, final_gendertable = {}, {}
		pcall(function()
			ProcessLoadedTables(
				loaded_csv,
				language,
				final_strings,
				final_gendertable
			)
		end)

		local title
		if strings_count > 0 or csv_count > 0 then
			title = T(302535920001125--[[Test Locale File]]) .. ": " .. T(951--[[Failed to complete operation.]])
		else
			title = T(302535920001125--[[Test Locale File]]) .. ": " .. T(1000015--[[Success]])
		end
		local results = {
			loaded_csv = loaded_csv,
			strings_failed = strings_failed,
			final_strings = final_strings,
			final_gendertable = final_gendertable,
		}
		if test_csv and #csv_failed > 0 then
			results.csv_failed = test_csv
		end

		OpenExamine(results, nil, title)
	end
end -- do

do -- RetObjectCapAndGrid
	local IsFlagSet = IsFlagSet
	local visitors = {"Service", "TrainingBuilding"}

	-- mask is a combination of numbers. IsFlagSet(15, num) will match 1 2 4 8
	function ChoGGi_Funcs.Common.RetObjectCapAndGrid(obj, mask)
		if not IsValid(obj) then
			return
		end

		if IsFlagSet(mask, 1) and obj:IsKindOf("ElectricityStorage") then
			return "electricity", obj:GetClassValue("capacity"), obj.electricity

		elseif IsFlagSet(mask, 2) and obj:IsKindOf("AirStorage") then
			return "air", obj:GetClassValue("air_capacity"), obj.air

		elseif IsFlagSet(mask, 4) and obj:IsKindOf("WaterStorage") then
			return "water", obj:GetClassValue("water_capacity"), obj.water

		elseif IsFlagSet(mask, 8) and obj:IsKindOf("Residence") then
			return "colonist", obj:GetClassValue("capacity")

		elseif IsFlagSet(mask, 16) and obj:IsKindOf("Workplace") then
			return "workplace", obj:GetClassValue("max_workers")

		elseif IsFlagSet(mask, 32) and obj:IsKindOfClasses(visitors) then
			return "visitors", obj:GetClassValue("max_visitors")

		end
	end
end -- do

do -- SetLibraryToolTips
	local dlgs = {
		"ChoGGi_XText",
		"ChoGGi_XTextList",
		"ChoGGi_XMultiLineEdit",
		"ChoGGi_XMoveControl",
		"ChoGGi_XButtons",
		"ChoGGi_XImage",
		"ChoGGi_XComboButton",
		"ChoGGi_XCheckButton",
		"ChoGGi_XTextInput",
		"ChoGGi_XList",
		"ChoGGi_XListItem",
		"ChoGGi_XDialog",
		"ChoGGi_XDialogSection",
		"ChoGGi_XWindow",
	}
	function ChoGGi_Funcs.Common.SetLibraryToolTips()
		local g = g_env

		local tip = ChoGGi.UserSettings.EnableToolTips and "Rollover" or ""
		for i = 1, #dlgs do
			g[dlgs[i]].RolloverTemplate = tip
		end
	end
end -- do

do -- SetLoadingScreenLog
	local ChoOrig_WaitLoadingScreenClose = WaitLoadingScreenClose
	ChoGGi_Funcs.Common.AddToOriginal("WaitLoadingScreenClose")

	function ChoGGi_Funcs.Common.SetLoadingScreenLog()

		-- screws up speed buttons (and maybe other stuff)
		-- LoadingScreenOpen = empty_func
		-- LoadingScreenClose = empty_func
		if ChoGGi.UserSettings.LoadingScreenLog then
			WaitLoadingScreenClose = empty_func

			local cls = BaseLoadingScreen
			cls.HandleMouse = false
			cls.transparent = true
			cls.ZOrder = 0
		else
			WaitLoadingScreenClose = ChoOrig_WaitLoadingScreenClose

			local cls = BaseLoadingScreen
			cls.HandleMouse = true
			cls.transparent = false
			cls.ZOrder = 1000000000

			cls = BaseSavingScreen
			cls.HandleMouse = true
			cls.transparent = true
			cls.ZOrder = 1000000000
		end
	end
end -- do

-- MonitorFunc (shortcut name in AddedFunctions)
function ChoGGi_Funcs.Common.MonitorFunctionResults(func, ...)
	local varargs = {...}

	local results_list = {}
	local dlg = OpenExamineReturn(results_list, {
		has_params = true,
		auto_refresh = true,
		title = T(302535920000853--[[Monitor]]) .. " " .. T(302535920000110--[[Function Results]]),
	})

	CreateRealTimeThread(function()
		-- stop when dialog is closed
		while IsValidXWin(dlg) do
			-- only update when it's our dlg sending the msg
			local _, msg_dlg = WaitMsg("ChoGGi_dlgs_examine_autorefresh")
			if msg_dlg == dlg then
				table.iclear(results_list)
				local results = {func(table.unpack(varargs))}
				for i = 1, #results do
					results_list[i] = results[i]
				end
			end
		end
	end)
end

-- set UI transparency
function ChoGGi_Funcs.Common.SetDlgTrans(dlg, ...)
	if not dlg or dlg and not dlg.class then
		return dlg, ...
	end
	local t = ChoGGi.UserSettings.Transparency[dlg.class]
	if t then
		dlg:SetTransparency(t)
	end
	return dlg, ...
end

function ChoGGi_Funcs.Common.CheckForBorkedTransportPath(obj, list)
	CreateRealTimeThread(function()
		-- let it sleep for awhile
		Sleep(100)
		-- 0 means it's stopped, so anything above that and without a path means it's borked (probably)
		if obj:GetAnim() > 0 and obj:GetPathLen() == 0 then
			list[obj] = true
			obj:InterruptCommand()
			MsgPopup(
				Translate(302535920001267--[[%s at position: %s was stopped.]]):format(RetName(obj), obj:GetVisualPos()),
				T(302535920001266--[[Borked Transport Pathing]]),
				{objects = obj, image = "UI/Icons/IPButtons/transport_route.tga"}
			)
		end
	end)
end

do -- DisplayMonitorList
	local function AddGrid(city, name, info)
		local c = #info.tables
		for i = 1, #city[name] do
			c = c + 1
			info.tables[c] = city[name][i]
		end
	end

	function ChoGGi_Funcs.Common.DisplayMonitorList(value, parent)
		if value == "New" then
			ChoGGi_Funcs.Common.MsgWait(
				Translate(302535920000033--[[Post a request on Nexus or Github or send an email to: %s]]):format(ChoGGi.email),
				T(302535920000034--[[Request]])
			)
			return
		end

		local UICity = UICity
		local info
		--0=value, 1=#table, 2=list table values
		local info_grid = {
			tables = {},
			values = {
				{name="connectors", kind=1},
				{name="consumers", kind=1},
				{name="producers", kind=1},
				{name="storages", kind=1},
				{name="all_consumers_supplied", kind=0},
				{name="charge", kind=0},
				{name="discharge", kind=0},
				{name="current_consumption", kind=0},
				{name="current_production", kind=0},
				{name="current_reserve", kind=0},
				{name="current_storage", kind=0},
				{name="current_storage_change", kind=0},
				{name="current_throttled_production", kind=0},
				{name="current_waste", kind=0},
			}
		}
		if value == "Grids" then
			info = info_grid
			info_grid.title = T(302535920000035--[[Grids]])
			AddGrid(UICity, "air", info)
			AddGrid(UICity, "electricity", info)
			AddGrid(UICity, "water", info)
		elseif value == "Air" then
			info = info_grid
			info_grid.title = T(891--[[Air]])
			AddGrid(UICity, "air", info)
		elseif value == "Power" then
			info = info_grid
			info_grid.title = T(79--[[Power]])
			AddGrid(UICity, "electricity", info)
		elseif value == "Water" then
			info = info_grid
			info_grid.title = T(681--[[Water]])
			AddGrid(UICity, "water", info)
		elseif value == "Research" then
			info = {
				title = T(311--[[Research]]),
				listtype = "all",
				tables = {UIColony.tech_status},
				values = {
					researched = true
				}
			}
		elseif value == "Colonists" then
			info = {
				title = T(547--[[Colonists]]),
				tables = GetCityLabels("Colonist"),
				values = {
					{name="handle", kind=0},
					{name="command", kind=0},
					{name="goto_target", kind=0},
					{name="age", kind=0},
					{name="age_trait", kind=0},
					{name="death_age", kind=0},
					{name="race", kind=0},
					{name="gender", kind=0},
					{name="birthplace", kind=0},
					{name="specialist", kind=0},
					{name="sols", kind=0},
					--{name="workplace", kind=0},
					{name="workplace_shift", kind=0},
					--{name="residence", kind=0},
					--{name="current_dome", kind=0},
					{name="daily_interest", kind=0},
					{name="daily_interest_fail", kind=0},
					{name="dome_enter_fails", kind=0},
					{name="traits", kind=2},
				}
			}
		elseif value == "Rockets" then
			info = {
				title = T(5238--[[Rockets]]),
				tables = GetCityLabels("AllRockets"),
				values = {
					{name="name", kind=0},
					{name="handle", kind=0},
					{name="command", kind=0},
					{name="status", kind=0},
					{name="priority", kind=0},
					{name="working", kind=0},
					{name="charging_progress", kind=0},
					{name="charging_time_left", kind=0},
					{name="landed", kind=0},
					{name="drones", kind=1},
					--{name="units", kind=1},
					{name="unreachable_buildings", kind=0},
				}
			}
		elseif value == "City" then
			info = {
				title = T(302535920000042--[[City]]),
				tables = {UICity},
				values = {
					{name="rand_state", kind=0},
					{name="day", kind=0},
					{name="hour", kind=0},
					{name="minute", kind=0},
					{name="total_export", kind=0},
					{name="total_export_funding", kind=0},
					{name="funding", kind=0},
					{name="research_queue", kind=1},
					{name="consumption_resources_consumed_today", kind=2},
					{name="maintenance_resources_consumed_today", kind=2},
					{name="gathered_resources_today", kind=2},
					{name="consumption_resources_consumed_yesterday", kind=2},
					{name="maintenance_resources_consumed_yesterday", kind=2},
					{name="gathered_resources_yesterday", kind=2},
					 --{name="unlocked_upgrades", kind=2},
				}
			}
		end
		if info then
			if not IsKindOf(parent, "XWindow") then
				parent = nil
			end
			ChoGGi_Funcs.Common.OpenInMonitorInfoDlg(info, parent)
		end
	end
end -- do

function ChoGGi_Funcs.Common.RetLastLineFromStr(str, text)
	if not str then
		return
	end
	-- no text than return last line
	text = (text or "\n"):reverse()

	-- need to reverse string so it finds the last one, since find looks ltr
	local last = str:reverse():find(text, 1, true)
	if last then
		-- we need a neg number for sub + 1 to remove the slash
		return str:sub(-last + 1)
	end
	return ""
end

do -- RetLangTable
	local LoadCSV = LoadCSV
	local ProcessLoadedTables = ProcessLoadedTables

	local loaded = {}
	local translate_gen = {}
	local csv_load_fields = {
		[1] = "id",
		[2] = "text",
		[5] = "translated",
		[3] = "translated_new",
		[7] = "gender"
	}

	function ChoGGi_Funcs.Common.RetLangTable(filepath)
		table.iclear(loaded)
		table.iclear(translate_gen)
		LoadCSV(filepath, loaded, csv_load_fields, "omit_captions")
		local translate = {}
		ProcessLoadedTables(loaded, nil, translate, translate_gen)
		return translate, translate_gen
	end
end -- do

function ChoGGi_Funcs.Common.AttachSpireFrame(obj)
	local frame = SpireFrame:new()
	obj:Attach(frame)
	frame:ChangeEntity("TempleSpireFrame")
	-- copy from regular frame
	frame:SetAttachOffset(point(0, 0, 4280))
	return frame
end

function ChoGGi_Funcs.Common.AttachSpireFrameOffset(obj)
	if obj[1] then
		obj = obj[1]
	end
	local offset = obj:GetAttachOffset()
	obj:SetAttachOffset(point(0, 0, offset:z()))
end

--~ do -- ExpandModOptions
--~ 	local function UpdateProp(xtemplate)
--~ 		local idx = table.find(xtemplate, "MaxWidth", 400)
--~ 		if idx then
--~ 			xtemplate[idx].MaxWidth = 1000000
--~ 		end
--~ 	end

--~ 	local function AdjustNumber(self, direction)
--~ 		local slider = self.parent.idSlider
--~ 		if direction then
--~ 			slider:ScrollTo(slider.Scroll + slider.StepSize)
--~ 		else
--~ 			slider:ScrollTo(slider.Scroll - slider.StepSize)
--~ 		end
--~ 	end

--~ 	local function AddSliderButtons(xtemplate)
--~ 		local idx = table.find(xtemplate, "Id", "idSlider")
--~ 		if idx then
--~ 			local template_left = PlaceObj("XTemplateWindow", {
--~ 					"Id", "idButtonLower_ChoGGi",
--~ 					"__class", "XTextButton",
--~ 					"Text", T("[-]"),
--~ 					"FXMouseIn", "ActionButtonHover",
--~ 					"FXPress", "ActionButtonClick",
--~ 					"FXPressDisabled", "UIDisabledButtonPressed",
--~ 					"HAlign", "center",
--~ 					"RolloverZoom", 1100,
--~ 					"Background", 0,
--~ 					"FocusedBackground", 0,
--~ 					"RolloverBackground", 0,
--~ 					"PressedBackground", 0,
--~ 					"TextStyle", "MessageTitle",
--~ 					"MouseCursor", "UI/Cursors/Rollover.tga",
--~ 					"OnPress", function(self)
--~ 						AdjustNumber(self, false)
--~ 					end,
--~ 					"RolloverTemplate", "Rollover",
--~ 				})
--~ 			local template_right = PlaceObj("XTemplateWindow", {
--~ 					"__template", "PropName",
--~ 					"__class", "XTextButton",
--~ 					"Id", "idButtonHigher_ChoGGi",
--~ 					"Text", T("[+]"),
--~ 					"FXMouseIn", "ActionButtonHover",
--~ 					"FXPress", "ActionButtonClick",
--~ 					"FXPressDisabled", "UIDisabledButtonPressed",
--~ 					"HAlign", "center",
--~ 					"RolloverZoom", 1100,
--~ 					"Background", 0,
--~ 					"FocusedBackground", 0,
--~ 					"RolloverBackground", 0,
--~ 					"PressedBackground", 0,
--~ 					"TextStyle", "MessageTitle",
--~ 					"MouseCursor", "UI/Cursors/Rollover.tga",
--~ 					"OnPress", function(self)
--~ 						AdjustNumber(self, true)
--~ 					end,
--~ 					"RolloverTemplate", "Rollover",
--~ 				})
--~ 			table.insert(xtemplate, idx, template_left)
--~ 			table.insert(xtemplate, idx+2, template_right)
--~ 		end
--~ 	end

--~ 	function ChoGGi_Funcs.Common.ExpandModOptions(XTemplates_param)
--~ 		XTemplates_param = XTemplates_param or XTemplates

--~ 		local xtemplate = XTemplates_param.PropBool[1]
--~ 		if xtemplate.ChoGGi_ModOptionsExpanded then
--~ 			return
--~ 		end
--~ 		xtemplate.ChoGGi_ModOptionsExpanded = true

--~ 		UpdateProp(xtemplate)
--~ 		UpdateProp(XTemplates_param.PropChoiceOptions[1])
--~ 		xtemplate = XTemplates_param.PropNumber[1]
--~ 		UpdateProp(xtemplate)
--~ 		-- add buttons to number
--~ 		AddSliderButtons(xtemplate)

--~ 	end
--~ end -- do


do -- UnpublishParadoxMod
	local function PDX_GetModDetails(mod_title, os_type)
		local query = {
			Query = mod_title,
			Author = "",
			RequiredVersion = "",
			Tags = {},
			Page = 0,
			PageSize = 20,
			SortBy = "displayName",
			OrderBy = "asc",
			OSType = os_type
		}
		local err, results = g_env.AsyncOpWait(g_env.PopsAsyncOpTimeout, nil, "AsyncPopsModsSearch", query)
		if err then
			return err
		end
		-- to unpublish a mod we have to parse search results, instead of using the guid to look it up?
		for i = 1, #results do
			local entry = results[i]
			if entry.DisplayName == mod_title then
				return entry
			end
		end
		return "mod not found"
	end

	-- platform = "any" for pc/xbox, "windows" for only pc
	-- mod_title = name of mod on paradox platform
--~ ChoGGi_Funcs.Common.UnpublishParadoxMod("Fix Food Depot Centipede")
	function ChoGGi_Funcs.Common.UnpublishParadoxMod(mod_title, platform)
		if blacklist then
			ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_Funcs.Common.UnpublishParadoxMod")
			return
		end

		-- wait for paradox login



		if not mod_title then
			return
		end

		local function CallBackFunc(answer)
			if answer then
				ChoGGi_Funcs.Common.WaitForParadoxLogin()

				if not platform then
					platform = "any"
				end
				local result = PDX_GetModDetails(mod_title, platform)

				if type(result) == "table" then
					result = g_env.AsyncOpWait(g_env.PopsAsyncOpTimeout, nil, "AsyncPopsModsDeleteMod", result.ModID)
				end

				if type(result) == "string" then
					print("UnpublishParadoxMod<color ChoGGi_red>", Translate(6774--[[Error]]), result, "</color>", mod_title)
				else
					print("UnpublishParadoxMod<color ChoGGi_green>", Translate(1000015--[[Success]]), "</color>", mod_title)
				end
			end
		end
		ChoGGi_Funcs.Common.QuestionBox(
			T(6779--[[Warning]]) .. "!\n" .. T(672683736395--[[Unpublish from Paradox]]),
			CallBackFunc,
			mod_title
		)
	end
end -- do

function ChoGGi_Funcs.Common.VerticalCheatMenu_Toggle(toggle)
	if ChoGGi.what_game ~= "Mars" then
		return
	end


	local cheatmenu_id = "XShortcutsHost"
	if ChoGGi.what_game == "JA3" then
		cheatmenu_id = "DeveloperInterface"
	end

	local idx = table.find(terminal.desktop, "class", cheatmenu_id)

	if not idx then
		if testing then
			print("no idx VerticalCheatMenu_Toggle")
			ex(terminal.desktop)
		end
		return
	end

	local cheat_menu = terminal.desktop[idx]

	-- menu
	idx = table.find(cheat_menu, "class", "XMenuBar")

	-- menu buttons, there's no id so this'll hopefully work if someone else adds something here.
	local menubuttons
	for i = 1, #cheat_menu do
		local item = cheat_menu[i]
		if item[1] and item[1].ButtonTemplate == "EditorToolbarButton" then
			menubuttons = item[1]
			break
		end
	end

	idx = table.find(cheat_menu, "class", "XMenuBar")
	local menubar = cheat_menu[idx]

	if toggle then
		menubar:SetLayoutMethod("VList")
		menubuttons:SetLayoutMethod("VList")
	else
		menubar:SetLayoutMethod("HList")
		menubuttons:SetLayoutMethod("HList")
	end

	-- force update the menu
	menubar:SetUniformColumnWidth(true)
	menubar:SetUniformColumnWidth(false)
	menubuttons:SetUniformColumnWidth(true)
	menubuttons:SetUniformColumnWidth(false)
end

function ChoGGi_Funcs.Common.DisableBuildingsDie()
	local die = DisabledInEnvironment
	local blank_die = {"","","",""}
	local ct = ClassTemplates.Building
	local bt = BuildingTemplates
	for id, item in pairs(bt) do
		if die then
			die[id] = blank_die
		end
		item.disabled_in_environment1 = ""
		item.disabled_in_environment2 = ""
		item.disabled_in_environment3 = ""
		item.disabled_in_environment4 = ""
		item = ct[id]
		item.disabled_in_environment1 = ""
		item.disabled_in_environment2 = ""
		item.disabled_in_environment3 = ""
		item.disabled_in_environment4 = ""
	end

	ChoGGi_Funcs.Common.UpdateBuildMenu()
end

function ChoGGi_Funcs.Common.WaitForParadoxLogin()
	-- wait for paradox to login
	if not g_env.g_ParadoxAccountDetails then
		local wait_count = 0
		while true do
			if g_env.g_ParadoxAccountDetails then
				break
			end
			Sleep(250)

			wait_count = wait_count + 1
			if wait_count > 100 then
				print("ECM: Paradox account not logging in...")
				break
			end
			--
		end
	end
end

function ChoGGi_Funcs.Common.InfopanelToolbarConstrain_Toggle(toggle)
	if what_game ~= "Mars" then
		return
	end

	--[1][1][1]>[2]XFrame Image = "UI/CommonNew/ip.tga">[2]XWindow Padding = box(18, 4, 18, 23)
	local template = XTemplates.Infopanel[1][1][1][2][2]
	if toggle then
		-- HWrap moves overlap down to "next row"
		template.LayoutMethod = "HOverlappingList"
	else
		template.LayoutMethod = "HList"
	end
end
