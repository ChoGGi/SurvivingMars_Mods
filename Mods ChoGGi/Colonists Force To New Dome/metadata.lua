return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Colonists Force To New Dome",
	"id", "ChoGGi_ColonistsForceToNewDome",
	"steam_id", "1432964482",
	"pops_any_uuid", "91bc1730-8406-463c-9efe-f0a138fdb26e",
	"lua_revision", 1007000, -- Picard
	"version", 8,
	"version_major", 0,
	"version_minor", 8,
	"author", "ChoGGi",
	"image", "Preview.jpg",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"description", [[
Adds a menu to the dome selection panel allowing you to force colonists to migrate to a new dome.
May have to do it a couple times to make sure they're all gone.
You can also move individual colonists (select and use menu).

Mod option to also remove invalid colonists stuck in dome.


Requested by BLAde (and probably a bunch of other people).
]],
})
