-- See LICENSE for terms

if not g_AvailableDlc.picard then
	print(CurrentModDef.title, ": Below & Beyond DLC not installed! Abort!")
	return
end

local mod_EnableMod

local table = table
local T = T
local _InternalTranslate = _InternalTranslate

local ChoOrig_MapSwitch_GetEntries = MapSwitch.GetEntries
function MapSwitch.GetEntries(...)
	if not mod_EnableMod then
		return ChoOrig_MapSwitch_GetEntries(...)
	end

	local realms = ChoOrig_MapSwitch_GetEntries(...)

	-- some of them fail, so if they do we can still show map buttons instead of hiding them
	local status, result = pcall(function()
		local g_ActiveOnScreenNotifications = g_ActiveOnScreenNotifications
		local OnScreenNotificationPresets = OnScreenNotificationPresets

		for i = 1, #realms do
			local realm = realms[i]

			local map_notifications = table.ifilter(g_ActiveOnScreenNotifications, function(_, v)
				return v[5] == realm.Map
			end)

			if #map_notifications > 0 then
				local notifs_text = {}

				for j = 1, #map_notifications do
					local params = map_notifications[j][3]

						local preset = OnScreenNotificationPresets[params.preset_id] or map_notifications[j].custom_preset
						if preset then
							local text_list = {}
							text_list[1] = T{preset.title, params}

							-- function OnScreenNotification:SetTexts(preset, params)
							local text = params and params.override_text or preset.text
							text = T{text, params}
							if params.additional_text then
								text = text .. T{params.additional_text, params}
							end
							text_list[2] = _InternalTranslate(T{text, params})
							-- merge it
							notifs_text[j] = table.concat(text_list, ": ")
						else
							-- fallback
							notifs_text[j] = tostring(map_notifications[j][1])
						end

				end
				notifs_text[2] = _InternalTranslate(notifs_text[2])
				realm.RolloverText = realm.RolloverText .. T("\n\n<yellow>") .. T(7582--[[Notifications]])
					.. T(":</yellow>\n") .. table.concat(notifs_text, "\n")
			end

		end
	end)
	-- errored out
	if not status then
		print("Show Map Notifications ERROR:", result)
	end

	return realms
end

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	mod_EnableMod = CurrentModOptions:GetProperty("EnableMod")
end
-- Load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- Fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions


--~ AddDisasterNotification("ColdWave2", {
--~ 	start_time = GameTime(),
--~ 	expiration = const.DayDuration * 6 + 432223,
--~ 	early_warning = GetEarlyWarningText(const.DayDuration * 3 + 343432),
--~ 	num_of_sensors = T{10979, "<tower_number> Sensor Towers", tower_number = 7}},
--~ nil, ActiveMapID)
