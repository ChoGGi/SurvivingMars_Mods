-- See LICENSE for terms

local IsKindOf = IsKindOf
local PlaceObj = PlaceObj
local T = T
local table = table

local mod_options = {
	PlaceObj("ModItemOptionNumber", {
		"name", "AutoPerformance",
		"DisplayName", T(0000, " Auto Performance"),
		"Help", T(0000, "Performance value when no colonists."),
		"DefaultValue", 100,
		"MinValue", 10,
		"MaxValue", 1000,
		"StepSize", 10,
	}),
}
local c = #mod_options

local g_Classes = g_Classes
local BuildingTemplates = BuildingTemplates

for id, item in pairs(BuildingTemplates) do
	local cls_obj = g_Classes[item.id or item.template_class]
	local is_factory = IsKindOf(cls_obj, "Factory")
	local is_farm = IsKindOf(cls_obj, "Farm") or IsKindOf(cls_obj, "FungalFarm")
	if is_factory or is_farm then
		local enable_auto = true
		if is_farm then
			enable_auto = false
		end

		c = c + 1
		mod_options[c] = PlaceObj("ModItemOptionToggle", {
			"name", id,
			"DisplayName", T(item.display_name),
			"Help", table.concat(T(item.description) .. "\n\n<image " .. item.display_icon .. ">"),
			"DefaultValue", enable_auto,
		})
	end
end

-- Custom buildings
local function AddBuilding(id)
	local item = BuildingTemplates[id]
	if item then
		c = c + 1
		mod_options[c] = PlaceObj("ModItemOptionToggle", {
			"name", id,
			"DisplayName", T(item.display_name),
			"Help", table.concat(T(item.description) .. "\n\n<image " .. item.display_icon .. ">"),
			"DefaultValue", false,
		})
	end
end
--
AddBuilding("DroneFactory")
-- No need to check for dlc, just check for nil in the func above
AddBuilding("ReconCenter")
-- Indoor Polymer Factory (reuploaded)
AddBuilding("Indoor_PolymerPlant")

local CmpLower = CmpLower
local _InternalTranslate = _InternalTranslate
table.sort(mod_options, function(a, b)
	return CmpLower(_InternalTranslate(a.DisplayName), _InternalTranslate(b.DisplayName))
end)

return mod_options
