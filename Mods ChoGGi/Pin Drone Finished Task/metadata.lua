return PlaceObj("ModDef", {
	"title", "Pin Drone Finished Task",
	"id", "ChoGGi_PinDroneFinishedTask",
	"steam_id", "2087572485",
	"pops_any_uuid", "711ad49a-96d0-4837-aba8-5ebd06b84dc5",
	"lua_revision", 1007000, -- Picard
	"version", 3,
	"version_major", 0,
	"version_minor", 3,
	"image", "Preview.png",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"TagGameplay", true,
	"description", [[
When a drone has finished it's current task and is about to head home then it'll get pinned.


Mod Options:
Pin Drone: Pin drone when task is finished.
Pin Drone Idle: Pin drone when idle.
Unpin Selected Drone: Unpin drone when selected.
Pause Game: Pause game when drone task is finished.
Pause Game Idle: Pause game when drone is idle.


Requested by Yaser.
]],
})
