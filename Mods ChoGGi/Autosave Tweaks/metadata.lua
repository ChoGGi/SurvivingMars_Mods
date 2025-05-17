return PlaceObj("ModDef", {
	"title", "Realtime Autosave",
	"id", "ChoGGi_RealtimeAutosave",
	"steam_id", "3421969296",
	"pops_any_uuid", "eaa6e5c6-d205-4153-9f9c-387a25c0eb18",
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
	"TagOther", true,
	"description", [[
See mod options to set autosave interval in minutes, savenames will use Autosave1, Autosave2, etc
This will save the game while paused.

This ignores autosave settings in options (probably best to disable that).


Requested by Coldaine.
]],
})
