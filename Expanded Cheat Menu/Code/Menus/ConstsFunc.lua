-- See LICENSE for terms

if ChoGGi.what_game ~= "Mars" then
	return
end

local ChoGGi_Funcs = ChoGGi_Funcs
local MsgPopup = ChoGGi_Funcs.Common.MsgPopup
local T = T
local Translate = ChoGGi_Funcs.Common.Translate

-- Anything needed to be called after Consts updated
local function Req_Func_Updates(const_id, const_value)
	-- Forces an update of GetSolAtmosphereDecay()/SetAtmosphereDecay()
	if const_id == "Decay_AtmosphereSP_MagneticShield"
		or const_id == "Decay_AtmosphereTP_Max"
		or const_id == "Decay_AtmosphereTP_Min"
	then
		SavegameFixups.RestartAtmosphereDecayThread()
	end
end

function ChoGGi_Funcs.Menus.SetConstMenu(action)
	if not action then
		return
	end

	local ConstsUS = ChoGGi.UserSettings.Consts
	local ConstsC = ChoGGi.Consts

	local setting_scale = action.setting_scale
--~ 	printC(setting_scale, "setting_scale")
	-- see about using scale to setup the numbers

	local setting_id = action.setting_id
	local setting_name = action.setting_name
	local setting_desc = action.setting_desc
	local default_setting = action.setting_value

	local item_list = {
		{text = Translate(1000121--[[Default]]) .. ": " .. default_setting, value = default_setting},
		{text = 15, value = 15},
		{text = 20, value = 20},
		{text = 25, value = 25},
		{text = 50, value = 50},
		{text = 75, value = 75},
		{text = 100, value = 100},
		{text = 250, value = 250},
		{text = 500, value = 500},
		{text = 1000, value = 1000},
		{text = 10000, value = 10000},
		{text = 25000, value = 25000},
	}
	local previous = ChoGGi.UserSettings[setting_id]
	if previous then
		table.insert(item_list, 2, {
			text = Translate(1000231--[[Previous]]) .. ": " .. previous,
			value = previous,
			hint = T(302535920000213--[[Previously set in an ECM menu (meaning it's active and the setting here will override this value).]])
		})
	end

	local hint = default_setting
	if ConstsUS[setting_id] then
		hint = ConstsUS[setting_id]
	end

	local function CallBackFunc(choice)
		if choice.nothing_selected then
			return
		end
		choice = choice[1]
		local value = choice.value

		if type(value) == "number" then
			ChoGGi_Funcs.Common.SetConsts(setting_id, value)
			-- If setting is the same as the default then remove it
			if ConstsC[setting_id] == value then
				ConstsUS[setting_id] = nil
			else
				ConstsUS[setting_id] = value
			end

			Req_Func_Updates(setting_id, value)

			ChoGGi_Funcs.Settings.WriteSettings()
			MsgPopup(
				ChoGGi_Funcs.Common.SettingState(choice.text),
				setting_name
			)
		end
	end

	hint = T(302535920000106--[[Current]]) .. ": " .. hint .. "\n\n" .. setting_desc
	local scale = Presets.ConstDef.Scale[setting_scale]
	if scale then
		hint = hint .. "\n" .. T(1000081--[[Scale]]) .. ": "
			.. (scale.value or 1000) .. "("
			.. T(302535920000182--[[The scale this amount will be multipled by when used.]]) .. ")"
	end

	ChoGGi_Funcs.Common.OpenInListChoice{
		callback = CallBackFunc,
		items = item_list,
		title = setting_name,
		hint = hint,
		skip_sort = true,
	}
end
