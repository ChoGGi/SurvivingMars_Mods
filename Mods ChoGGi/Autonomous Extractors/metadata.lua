return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 8,
		}),
	},
	"title", "Autonomous Extractors",
	"id", "ChoGGi_AutonomousExtractors",
	"steam_id", "2792357619",
	"pops_any_uuid", "686c784c-87fd-407f-a75d-719221f75f52",
	"lua_revision", 1007000, -- Picard
	"version", 5,
	"version_major", 0,
	"version_minor", 5,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"TagBuildings", true,
	"description", [[
Makes the rare/metal extractors colonist-free for people that don't want to build domes everywhere?
I know it's not really autonomous, but close enough...

Mod Options:
Auto Performance: Performance value when no colonists.


Requested by a few people.
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=2854948983]Autonomous Factories[/url]
]],
})
