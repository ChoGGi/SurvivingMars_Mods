return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 12,
			"version_minor", 6,
		}),
	},
	"title", "Construction Show Buildable Grid",
	"id", "ChoGGi_ConstructionShowHexBuildableGrid",
	"steam_id", "1743031290",
	"pops_any_uuid", "79aaafdd-712c-40f8-873b-3a4d59273f1f",
	"version", 5,
	"version_major", 0,
	"version_minor", 5,
	"lua_revision", 1007000, -- Picard
	"image", "Preview.jpg",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"description", [[
Show different colours for different types of hexes during construction (disable in mod options).
Press Numpad 0 to toggle grid anytime (rebind in game options).

Passable (drones/rovers can drive here), Buildable (buildings can be placed here)
Green = pass/build
Yellow = no pass/build
Blue = pass/no build
Red = no pass/no build
Shows blue for pipes, but you can build some stuff under them. The colours use the centre of the hex, so they could be off?


Mod Options:
Show during construction: If you don't want grids showing up during construction placement.
Grid Size: Set the size of the grid area.
Grid Opacity: Set opacity of grid icons.


Known Issues:
This is disabled for geoscape domes (or spires will give an uneven terrain error).
To fix the issue with flattened ground and uneven terrain: [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2721921772]Fix Bugs[/url]


[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1479851929]Show Hex Grid[/url]
]],
})
