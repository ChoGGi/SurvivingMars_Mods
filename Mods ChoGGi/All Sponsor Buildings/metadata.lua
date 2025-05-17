return PlaceObj("ModDef", {
	"title", "All Sponsor Buildings",
	"id", "ChoGGi_AllSponsorBuildings",
	"pops_any_uuid", "da41f738-8ed0-4574-8539-9c7430477b58",
	"steam_id", "1568521664",
	"lua_revision", 1007000, -- Picard
	"version", 24,
	"version_major", 2,
	"version_minor", 4,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"has_options", true,
	"code", {
		"Code/Script.lua",
	},
	"description", [[
Removes sponsor limit placed on certain buildings/vehicles (Space Race DLC).
Some buildings can be locked behind tech: Advanced Stirling Generator, Jumper ShuttleHub, and Low-G Lab.

Mod Options:
You need to research tech to unlock certain buildings (reload game to take effect).
See mod options to disable any buildings you find cheaty (or if you just want one or two unlocked).

You need to research Robotics>Rover Printing to build rovers.


Known Issues:
Surviving the Sponsors mod adds a bugged template for the Metals Refinery (Not my issue but enough people have brought it up in the comments).
]],
})
