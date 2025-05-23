return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Terraformer (Obsolete)",
	"id", "ChoGGi_Terraformer",
	"steam_id", "1415296985",
	"pops_any_uuid", "0d6e7eed-312b-4f3e-822c-4a3ff6e92abf",
	"lua_revision", 1007000, -- Picard
	"version", 14,
	"version_major", 1,
	"version_minor", 4,
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"TagOther", true,
	"description", [[
Simple guide: https://steamcommunity.com/sharedfiles/filedetails/?id=1530394137

If you're feeling OCD about a perfect layout for your base then look no further.

Press Shift-F to begin, press Shift-F again to update buildable area.
Press Ctrl-Shift-1 to remove large rocks, Ctrl-Shift-2 for small ones (shows a confirmation before).
Ctrl-Shift-Alt-D to delete object under mouse (any object and there's no confirmation).

You can rebind keys with the in-game options (scroll to the bottom).


Known Issues:
Stay away from the edges of the map, the game doesn't really like you fiddling around there.
]],
})
