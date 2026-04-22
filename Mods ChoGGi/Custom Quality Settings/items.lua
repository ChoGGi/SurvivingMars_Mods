-- See LICENSE for terms

return {
	PlaceObj("ModItemOptionToggle", {
		"name", "SmokeParticles",
		"DisplayName", T(0000, "Smoke Particles"),
		"Help", T(0000, [[Use this to turn off Smoke Particles from GHG/etc.

If in-game you need to toggle working state of smoking buildings.]]),
		"DefaultValue", true,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "LightsRadiusModifier",
		"DisplayName", T(302535920011675, "Lights Radius"),
		"Help", T(302535920011676, [[The "Light" option in video settings. Low is 90, Medium is 95, High is 100
0 = Use in-game setting (needs restart),
1 = 10,
2 = 25,
3 = 50,
4 = 75,
5 = 100,
6 = 150,
7 = 200,
8 = 400,
9 = 600,
10 = 1000,
11 = 10000, Laggy]]),
		"DefaultValue", 0,
		"MinValue", 0,
		"MaxValue", 11,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "TR_MaxChunks",
		"DisplayName", T(302535920011677, "Geometry Detail"),
		"Help", T(302535920011678, [[Better looking hills.
0 = Use in-game setting (needs restart),
1 = 10,
2 = 25,
3 = 50,
4 = 75,
5 = 100, Low/High (don't ask)
6 = 150, Medium
7 = 200, Ultra
8 = 400,
9 = 600,
10 = 800,
11 = 1000, Above 1000 will add a long delay to loading (and might crash).]]),
		"DefaultValue", 0,
		"MinValue", 0,
		"MaxValue", 11,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "DTM_VideoMemory",
		"DisplayName", T(302535920011679, "Video Memory"),
		"Help", T(302535920011680, [[How much vram the game can use?
0 = Use in-game setting (needs restart),
1 = 8,
2 = 16,
3 = 32,
4 = 64,
5 = 128,
6 = 256, Low
7 = 512, Medium
8 = 1536, High
9 = 2048, Ultra
10 = 4096,
11 = 8192,
12 = 16384,
13 = 32768,]]),
		"DefaultValue", 0,
		"MinValue", 0,
		"MaxValue", 13,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "ShadowmapSize",
		"DisplayName", T(302535920011681, "Shadow Resolution"),
		"Help", T(302535920011682, [[Higher number means crisper shadows (8192+ may cause crashing on low vram cards!).
0 = Use in-game setting (needs restart),
1 = 8,
2 = 16,
3 = 32,
4 = 64,
5 = 128,
6 = 256,
7 = 512,
8 = 1536, Low
9 = 2048, Medium
10 = 4096, High
11 = 8192,
12 = 16384,
13 = 32768,]]),
		"DefaultValue", 0,
		"MinValue", 0,
		"MaxValue", 13,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "LODDistanceModifier",
		"DisplayName", T(302535920011683, "LOD Distance"),
		"Help", T(302535920011684, [[See more detail when zoomed out.
0 = Use in-game setting (needs restart),
1 = 15,
2 = 30,
3 = 60,
4 = 120, Default
5 = 240,
6 = 360,
7 = 480, Minimal FPS hit on large base ^
8 = 600,
9 = 720, Small FPS hit on large base ^
10 = 840,
11 = 960,
12 = 1080,
13 = 1200,
14 = 1320,
15 = 1440,
16 = 1560, FPS hit ^]]),
		"DefaultValue", 0,
		"MinValue", 0,
		"MaxValue", 16,
	}),
	PlaceObj("ModItemOptionNumber", {
		"name", "ShadowRangeOverride",
		"DisplayName", T(302535920011685, "Shadow Range"),
		"Help", T(302535920011686, [[How far you can see the shadow when zoomed out (only useful above default if you've increased zoom out range).
0 = Use in-game setting (needs restart),
1 = 15625,
2 = 31250,
3 = 62500,
4 = 125000,
5 = 250000,
6 = 500000,
7 = 1000000, Default shadow fade out.
8 = 2000000,
9 = 5000000,
10 = -1, No shadow fade out when zooming]]),
		"DefaultValue", 0,
		"MinValue", 0,
		"MaxValue", 10,
	}),
}
