return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Standing Unlocks Sponsor Buildings",
	"id", "ChoGGi_StandingUnlocksSponsorBuildings",
	"lua_revision", 1007000, -- Picard
	"steam_id", "1569118695",
	"pops_any_uuid", "118d2bb6-8210-4fda-b0d8-125713fe1ee9",
	"version", 7,
	"version_major", 0,
	"version_minor", 7,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"description", [[
If your standing with a rival colony is excellent (min 61), you will be able to build any buildings locked to that sponsor.
This is a slightly less cheaty version of All Sponsor Buildings. Shows a notification when unlocked buildings have changed.


Mod Options:
Show Notification: Show a notification when unlocked buildings have changed.
Minimum Standing: Your standing needs to be at or above this to unlock buildings.

Known Issues:
You'll need to restart the game to reset unlocked buildings between different saves.

Requested by ve2dmn/veryinky.
]],
})
