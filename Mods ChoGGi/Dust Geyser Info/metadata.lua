return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 8,
		}),
	},
	"title", "Dust Geyser Info",
	"id", "ChoGGi_DustGeyserInfo",
	"steam_id", "2522466305",
	"pops_any_uuid", "b49b376f-7947-4b6b-9200-591becb1d02a",
	"lua_revision", 1007000, -- Picard
	"version", 1,
	"version_major", 0,
	"version_minor", 1,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
--~ 	"has_options", true,
	"TagInterface", true,
	"description", [[
Select a dust geyser to see the damage radius.


They will add dust to outside buildings and domes that are built right next to it (one hex seems to be far away enough).
Drones will take dust damage driving over it while it ejects dust.
Colonists walking on it will take Sanity damage (Cowards take double dmg), unless they are Martianborn with Martianborn Strength tech researched.

The screenshot shows it with cables around the actual damage area, you can use my [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1743031290]Construction Show Buildable Grid[/url] mod to see the exact tiles.
]],
})
