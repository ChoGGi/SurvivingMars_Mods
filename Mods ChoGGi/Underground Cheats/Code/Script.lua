-- See LICENSE for terms

if not g_AvailableDlc.picard then
	print(CurrentModDef.title, ": Below & Beyond DLC not installed! Abort!")
	return
end

local table = table
local CmpLower = CmpLower
local _InternalTranslate = _InternalTranslate

local mod_EnableMod
local mod_LightTripodRadius
local mod_SupportStrutRadius
local mod_PinRockets
local mod_NoSanityLoss
local mod_SortElevatorPrefabs

local orig_const_BuriedWonders = table.icopy(const.BuriedWonders)
local fake_BuriedWonders_safe
local fake_BuriedWonders = {}
local fake_BuriedWonders_c = 0

local function UpdateObjs()
	if not mod_EnableMod or not UIColony then
		return
	end

	local labels = Cities[UIColony.underground_map_id].labels
	if not labels then
		return
	end

	-- Newly built struts
	SupportStruts.work_radius = mod_SupportStrutRadius
	-- Existing struts
	local struts = labels.SupportStruts or ""
	for i = 1, #struts do
		struts[i].work_radius = mod_SupportStrutRadius
	end

	-- New lights
	BuildingTemplates.LightTripod.reveal_range = mod_LightTripodRadius
	ClassTemplates.Building.LightTripod.reveal_range = mod_LightTripodRadius
	-- Existing
	local UpdateRevealObject = UnitRevealDarkness.UpdateRevealObject
	local tripods = labels.LightTripod or ""
	for i = 1, #tripods do
		local obj = tripods[i]
		obj.reveal_range = mod_LightTripodRadius
		-- Update visible range
		UpdateRevealObject(obj)
	end

	-- Pin any rockets
	if mod_PinRockets then
		local GameMaps = GameMaps
		local SortPins = SortPins
		local under_map_id = UIColony.underground_map_id

		local surface_pins = GameMaps[MainMapID].pinnables.pins
		for i = 1, #surface_pins do
			local obj = surface_pins[i]
			if obj:IsKindOf("SupplyRocket") then
				table.insert_unique(GameMaps[under_map_id].pinnables.pins, obj)
				SortPins(under_map_id)
			end
		end
	end

end

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end
	local options = CurrentModOptions

	fake_BuriedWonders_safe = table.icopy(orig_const_BuriedWonders)
	table.iclear(fake_BuriedWonders)
	fake_BuriedWonders_c = 0
	-- build list of wonders
	for i = 1, #orig_const_BuriedWonders do
		local id = orig_const_BuriedWonders[i]

		if options:GetProperty(id) then
			fake_BuriedWonders_c = fake_BuriedWonders_c + 1
			fake_BuriedWonders[fake_BuriedWonders_c] = id
			-- fake_BuriedWonders_safe has enabled wonders removed, so there's no dupes
			local idx = table.find(fake_BuriedWonders_safe, id)
			if idx then
				table.remove(fake_BuriedWonders_safe, idx)
			end
		end
	end

	mod_EnableMod = options:GetProperty("EnableMod")
	mod_LightTripodRadius = options:GetProperty("LightTripodRadius")
	mod_SupportStrutRadius = options:GetProperty("SupportStrutRadius")
	mod_PinRockets = options:GetProperty("PinRockets")
	mod_NoSanityLoss = options:GetProperty("NoSanityLoss")
	mod_SortElevatorPrefabs = options:GetProperty("SortElevatorPrefabs")

	UpdateObjs()
end
-- load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions

OnMsg.CityStart = UpdateObjs
OnMsg.LoadGame = UpdateObjs
-- switch between different maps
OnMsg.ChangeMapDone = UpdateObjs

-- pick wonders
local ChoOrig_RandomMapGen_PlaceArtefacts = RandomMapGen_PlaceArtefacts
function RandomMapGen_PlaceArtefacts(...)
	if not mod_EnableMod then
		return ChoOrig_RandomMapGen_PlaceArtefacts(...)
	end

	-- Add a random wonder (use the actual count, so we can rand each new game in a session)
	if fake_BuriedWonders_c == 1 then
		fake_BuriedWonders[2] = table.rand(fake_BuriedWonders_safe)
--~ 	elseif fake_BuriedWonders_c == 0 then
--~ 		fake_BuriedWonders = table.icopy(orig_const_BuriedWonders)
	end

	const.BuriedWonders = fake_BuriedWonders
	-- I do pcalls for safety when wanting to change back a global var
	pcall(ChoOrig_RandomMapGen_PlaceArtefacts, ...)
	const.BuriedWonders = table.icopy(orig_const_BuriedWonders)
end

-- SMR
function OnMsg.RandomMapGen_PlaceArtefacts(env)
end

--~ -- Call the pin rocket func a second time for underground when being pinned to surface map
--~ local ChoOrig_PinnableObject_TogglePin = PinnableObject.TogglePin
--~ function PinnableObject:TogglePin(force, map_id, ...)
--~ 	if not mod_EnableMod or not mod_PinRockets then
--~ 		return ChoOrig_PinnableObject_TogglePin(self, force, map_id, ...)
--~ 	end

--~ 	-- if we're on surface map then this is skipped and onmsg.ChangeMapDone will update the pins
--~ 	-- (we want TogglePin to fire for whatever map we're on)
--~ 	if force and not map_id or map_id and map_id == MainMapID
--~ 		and self:IsKindOf("SupplyRocket")
--~ 	then
--~ 		-- GameMaps[UIColony.underground_map_id].pinnables.pins
--~ 		local under_id = UIColony.underground_map_id
--~ 		local under_pins = GameMaps[under_id].pinnables.pins

--~ 		table.insert_unique(under_pins, self)
--~ 		SortPins(under_id)
--~ 		local pins_dlg = GetDialog("PinsDlg")
--~ 		if pins_dlg.map_id == under_id and not obj:IsPinned() then
--~ 			pins_dlg:Pin(self)
--~ 		end

--~ 	end

--~ 	return ChoOrig_PinnableObject_TogglePin(self, force, map_id, ...)
--~ end

local ChoOrig_Colonist_CheckLackOfLight = Colonist.CheckLackOfLight
function Colonist:CheckLackOfLight(...)
	if not mod_EnableMod or not mod_NoSanityLoss then
		return ChoOrig_Colonist_CheckLackOfLight(self, ...)
	end

--~   if ObjectIsInEnvironment(self, "Underground") and not self.traits.Android then
--~     local reason = g_Consts.LackOfLight > 0 and "lack of light" or "at home underground"
--~     self:ChangeSanity(-g_Consts.LackOfLight, reason)
--~   end
end


function OnMsg.ClassesPostprocess()
	local templates = {
		-- It seems like I only need to do this one, but they did add three of them for some reason?
		"customCaveInRubble",

		"CaveInRubble",
		"RubbleBase",
	}
	local XTemplates = XTemplates

	for i = 1, #templates do
		local xtemplate = XTemplates[templates[i]][1][1]
		if not xtemplate.ChoGGi_AddedToggleAllButton then
			xtemplate.OnPressParam = nil
			xtemplate.ChoGGi_AddedToggleAllButton = true

			xtemplate.RolloverHint = T(0000, [[<left_click> Activate
Ctrl + <left_click> Activate all]])

			-- OnPress
			xtemplate.OnPress = function(self, gamepad)
				local context = self.context
				context:ToggleRequestClear()
				ObjModified(context)
				-- left click action (second arg is if ctrl is being held down)
				if not gamepad and IsMassUIModifierPressed() then
					CreateRealTimeThread(function()
						local clear_func = "CancelClear"
						if context.clear_request then
							clear_func = "RequestClear"
						end

						local cls = context.class
						local handle = context.handle
						local objs = UICity.labels.CaveInRubble or ""
						for j = 1, #objs do
							local obj = objs[j]
							if obj.handle ~= handle
								and obj.class == cls
								and obj:CanBeCleared()
							then
								obj[clear_func](obj)
							end
						end
					end)
				end
			end -- OnPress
		end -- if

		xtemplate = XTemplates[templates[i]][2]
		-- status
		ChoGGi_Funcs.Common.RemoveXTemplateSections(xtemplate, "ChoGGi_Template_UndergroundRubble_ShowStatus", true)
		-- Add other tunnel info
		table.insert(xtemplate, 2,
			PlaceObj("XTemplateTemplate", {
				"Id" , "ChoGGi_Template_UndergroundRubble_ShowStatus",
				-- No need to add this (I use it for my RemoveXTemplateSections func)
				"ChoGGi_Template_UndergroundRubble_ShowStatus", true,
				-- Section style
				"__template", "InfopanelSection",
				-- It'll default to dome icon
				"Icon", "UI/Icons/Sections/drone.tga",
				-- Only show button when it meets the req
				"__condition", function()
					return mod_EnableMod
				end,
			}, {
				PlaceObj("XTemplateTemplate", {
					"__template", "InfopanelText",
					-- function ChoGGi_UndergroundTunnel:GetUIStatus() returns text
					"Text", T(0000, "<UIStatus>"),
				})
			})
		)
		-- status
	end
end

function RubbleBase:GetUIStatus()
	return self.clear_request and T(13948--[[Clearing Rubble]]) or T(13066--[[Cave-in]])
end

-- Sort cargo list so cargo/prefab show up as sorted in resupply menus (been a pet peeve for awhile now)
local bt, aid, bid
local ChoOrig_PresetSortLessCb = PresetSortLessCb
function PresetSortLessCb(a, b, ...)
	if not mod_EnableMod or not mod_SortElevatorPrefabs then
		return ChoOrig_PresetSortLessCb(a, b, ...)
	end

	if not bt then
		bt = BuildingTemplates
	end
	aid, bid = bt[a.id], bt[b.id]

	if aid and bid then
		return CmpLower(_InternalTranslate(aid.display_name), _InternalTranslate(bid.display_name))
	else
		-- RC Buildings
		return a.id < b.id
	end
end
