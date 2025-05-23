return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Delete Object",
	"id", "ChoGGi_DeleteObject",
	"steam_id", "2743285577",
	"pops_any_uuid", "881d7130-03b4-46c5-97e6-6ce07d2bfcb3",
	"lua_revision", 1007000, -- Picard
	"version", 2,
	"version_major", 0,
	"version_minor", 2,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"TagGameplay", true,
	"description", [[
Adds a button to forcefully delete the selected object.
Mod option to turn off the button.


Relatively requested by Ericus1
]],
})
