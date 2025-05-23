-- See LICENSE for terms

local CreateRealTimeThread = CreateRealTimeThread
local WaitMsg = WaitMsg

local function RetGridType(obj)
	return obj:IsKindOf("ElectricityStorage") and "electricity"
		or obj:IsKindOf("AirStorage") and "air"
		or obj:IsKindOf("WaterStorage") and "water"
end

local function ToggleObj(obj, tank_type, max_charge, toggle)
	-- If charge rate is 0 than we're blocking tank from charging
	local grid_obj = obj[tank_type]
	local ret_toggle
	-- update selected obj
	if toggle == "init" then
		if grid_obj.max_charge == 0 then
			grid_obj.max_charge = max_charge
			ret_toggle = false
		else
			grid_obj.max_charge = 0
			ret_toggle = true
		end
	else
		-- update all
		if toggle then
			grid_obj.max_charge = 0
		else
			grid_obj.max_charge = max_charge
		end
	end

	CreateRealTimeThread(function()
		obj:ToggleWorking()
		WaitMsg("OnRender")
		obj:ToggleWorking()
	end)

	return ret_toggle
end

local function ToggleTanks(obj, all_objs)
	local bt = BuildingTemplates[obj.template_name]
	if not bt then
		return
	end
	local tank_type = RetGridType(obj)
	if not tank_type then
		return
	end

	local max_charge = bt["max_" .. tank_type .. "_charge"]

	-- updated selecte obj and get toggle status
	local toggle = ToggleObj(obj, tank_type, max_charge, "init")

	if all_objs then
		-- loop through all of type and set to same
		local objs = UIColony:GetCityLabels(obj.template_name)
		for i = 1, #objs do
			-- send toggle so we don't have to check each one
			ToggleObj(objs[i], tank_type, max_charge, toggle)
		end
	end

	return toggle
end

local function UpdateButton(self, context)
	local obj = context[RetGridType(context)]
	if obj and obj.max_charge == 0 then
		self:SetRolloverText(T(302535920011728, "Tank won't be filled by the grid."))
		self:SetIcon("UI/Icons/IPButtons/unload.tga")
	else
		self:SetRolloverText(T(302535920011729, "Tank will be filled by the grid."))
		self:SetIcon("UI/Icons/IPButtons/load.tga")
	end
end

function OnMsg.ClassesPostprocess()
	local xtemplate = XTemplates.ipBuilding[1]
	ChoGGi_Funcs.Common.RemoveXTemplateSections(xtemplate, "ChoGGi_Template_TankToggleDrainMode", true)

	table.insert(xtemplate, 2, PlaceObj("XTemplateTemplate", {
			"Id" , "ChoGGi_Template_TankToggleDrainMode",
			"ChoGGi_Template_TankToggleDrainMode", true,
			"__condition", function(_, context)
				return context:IsKindOf("ElectricityStorage") or context:IsKindOf("AirStorage") or context:IsKindOf("WaterStorage")
			end,
			"__template", "InfopanelButton",
			'OnContextUpdate', function(self, context)
				UpdateButton(self, context)
			end,

			"RolloverText", T(302535920011729, "Tank will be filled by the grid."),
			"RolloverTitle", T(302535920011730, "Toggle Drain Mode"),
			"RolloverHint", T(302535920011731, "<left_click> Toggle Building <right_click> Toggle All Of Type"),
			"Icon", "UI/Icons/IPButtons/unload.tga",

			"OnPress", function (self, gamepad)
				-- left click action
				ToggleTanks(self.context, not gamepad and IsMassUIModifierPressed())
				UpdateButton(self, self.context)
			end,
		})
	)
end
