return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Noticeable Salvage",
	"id", "ChoGGi_NoticeableSalvage",
	"steam_id", "1814312982",
	"pops_any_uuid", "d31d1b93-a913-4e4c-bd44-36997f56887d",
	"version", 3,
	"version_major", 0,
	"version_minor", 3,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"lua_revision", 1007000, -- Picard
	"code", {
		"Code/Script.lua",
	},
	"TagBuildings", true,
	"TagOther", true,
	"description", [[Changes buildings in the process of being salvaged/removed to have a black shade.
]],
})
