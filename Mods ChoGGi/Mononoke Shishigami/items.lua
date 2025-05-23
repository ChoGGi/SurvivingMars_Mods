-- See LICENSE for terms

return {
	PlaceObj("ModItemOptionToggle", {
		"name", "ToggleShrubs",
		"DisplayName", T(302535920011434, "Toggle Shrubs"),
		"Help", T(302535920011506, "Show shrubs beneath mouse cursor."),
		"DefaultValue", true,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "SpawnDelay",
		"DisplayName", T(0000, "Spawn Delay"),
		"Help", T(0000, "Delay in ms between spawning next shrubbery."),
		"DefaultValue", 100,
		"MinValue", 10,
		"MaxValue", 1000,
		"StepSize", 10,
	}),
	PlaceObj("ModItemOptionToggle", {
		"name", "MousePosition",
		"DisplayName", T(0000, "Mouse Position"),
		"Help", T(0000, "Grow shrubs as you move the mouse."),
		"DefaultValue", true,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "DieOffDelay",
		"DisplayName", T(0000, "Die Off Delay"),
		"Help", T(0000, "Delay in ms for shrubbery die off (+ random amount)."),
		"DefaultValue", 100,
		"MinValue", 10,
		"MaxValue", 1000,
		"StepSize", 10,
	}),
}
