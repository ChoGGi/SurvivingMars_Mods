-- See LICENSE for terms

return {
	PlaceObj("ModItemOptionToggle", {
		"name", "EnableMod",
		"DisplayName", T(302535920011303, "<color ChoGGi_yellow>Enable Mod</color>"),
		"Help", T(302535920011793, "Disable mod without having to see missing mod msg."),
		"DefaultValue", true,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "AutoPerformance",
		"DisplayName", T(0000, "Auto Performance"),
		"Help", T(0000, "Performance value when no colonists."),
		"DefaultValue", 100,
		"MinValue", 10,
		"MaxValue", 1000,
		"StepSize", 10,
	}),
}
