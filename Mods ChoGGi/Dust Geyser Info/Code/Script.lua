-- See LICENSE for terms

ChoGGi_Funcs.Common.AddParentToClass(DontBuildHere, "SelectableWithParticles")
ChoGGi_Funcs.Common.AddParentToClass(DontBuildHere, "InfopanelObj")
DontBuildHere.ip_template = "ipChoGGi_DustGeyserInfo"
DontBuildHere.DisplayName = T(302535920011957, "Dust Geyser")

function DontBuildHere:GetIPDescription()
	return T(302535920011958, [[Martian dust geysers spray dust...

Circle is radius of potential dust.

(min,max)
(time between dust) - (time it lasts):]])
		.. PrefabFeatureChar_Geyser:GetDescription(self):sub(7)
end

-- prevent an error msg in log
DontBuildHere.BuildWaypointChains = empty_func

function OnMsg.ClassesPostprocess()
	-- added to stuff spawned with object spawner
	if XTemplates.ipChoGGi_DustGeyserInfo then
		XTemplates.ipChoGGi_DustGeyserInfo:delete()
	end

	PlaceObj("XTemplate", {
		group = "Infopanel Sections",
		id = "ipChoGGi_DustGeyserInfo",
		PlaceObj("XTemplateTemplate", {
			"__context_of_kind", "DontBuildHere",
			"__template", "Infopanel",
		}, {
			PlaceObj("XTemplateTemplate", {
				"__template", "sectionCheats",
			}),
		}),
	})
end

function DontBuildHere:OnSelected()
	local geysers = {}
	GetRealm(self):MapGet("map", "GeyserWarmup", function(warmup)
		local geyser = warmup:GetMarker()
		if not geysers[geyser] then
			geysers[#geysers+1] = geyser
			geysers[geyser] = true
		end
	end)

	local geyser_count = #geysers
	if geyser_count == 0 then
		return
	end

	-- DontBuildHere is off-map, so cursor it is
	local sort_obj = GetCursorWorldPos()
	table.sort(geysers, function(a, b)
		return a:GetDist2D(sort_obj) < b:GetDist2D(sort_obj)
	end)

	local geyser = geysers[1]
	ChoGGi_Funcs.Common.Circle(geyser:GetPos(), geyser.FeatureRadius, white, 10000)
end
