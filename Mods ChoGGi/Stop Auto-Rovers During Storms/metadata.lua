return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Stop Auto-Rovers During Storms",
	"id", "ChoGGi_StopAutoRoversDuringStorms",
	"steam_id", "1796377313",
	"pops_any_uuid", "047b4e7f-37d7-4c89-a600-598339e2d955",
	"lua_revision", 1007000, -- Picard
	"version", 9,
	"version_major", 0,
	"version_minor", 9,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"TagGameplay", true,
	"description", [[
Rovers will not do automated tasks when a meteor storm is active.
Such as collecting the goodies that just dropped from the sky.

They'll finish up whatever task they're on then aim for the nearest working laser/missile tower/drone hub (in that order)

Mod Options:
MDS Laser: Go to the nearest working laser/missile tower if rover is idle.
Drone Hub: Go to the nearest working drone hub if rover is idle.
Immediate Abort: As soon as storm starts rovers will flee/idle (default off).
]],
})
