-- See LICENSE for terms

local mod_ShowPolymers
local mod_ShowMetals
local mod_ShowScanProgress
local mod_TextOpacity
local mod_TextBackground
local mod_TextStyle
local mod_ShowDropped
local mod_InfoBoxDelay

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	local options = CurrentModOptions
	mod_ShowPolymers = options:GetProperty("ShowPolymers")
	mod_ShowMetals = options:GetProperty("ShowMetals")
	mod_ShowScanProgress = options:GetProperty("ShowScanProgress")
	mod_TextOpacity = options:GetProperty("TextOpacity")
	mod_TextBackground = options:GetProperty("TextBackground")
	mod_TextStyle = options:GetProperty("TextStyle")
	mod_ShowDropped = options:GetProperty("ShowDropped")
	mod_InfoBoxDelay = options:GetProperty("InfoBoxDelay") * 1000
end
-- Load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- Fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions

local pairs = pairs
local table = table
local IsValid = IsValid
local T = T
local MulDivRound = MulDivRound
local GetMapSectorXY = GetMapSectorXY

local black = black

-- try to centre the text a bit more
local padding_box = box(0, -3, -4, -5)
local margin_box = box(-25, -15, 0, 0)
-- dbl res
local margin_box_dbl = box(-25, -30, 0, 0)
local margin_box_trp = box(-25, -50, 0, 0)
-- box(left/x, top/y, right/w, bottom/h)

local style_lookup = {
	"EncyclopediaArticleTitle",
	"BugReportScreenshot",
	"CategoryTitle",
	"ConsoleLog",
	"DomeName",
	"GizmoText",
	"InfopanelResourceNoAccept",
	"ListItem1",
	"ModsUIItemStatusWarningBrawseConsole",
	"LandingPosNameAlt",
}

local text_table = {}
local sector_piles = {}

local sector_nums = {
 [1] = true,
 [2] = true,
 [3] = true,
 [4] = true,
 [5] = true,
 [6] = true,
 [7] = true,
 [8] = true,
 [9] = true,
 [10] = true,
}

local function AddIcons()
	local str_Metals = _InternalTranslate(T("<icon_Metals>")):gsub("1300", "2200")
	local str_Polymers = _InternalTranslate(T("<icon_Polymers>")):gsub("1300", "2200")

	local ResourceScale = const.ResourceScale
	local SectorDeepScanPoints = const.SectorDeepScanPoints
	local SectorScanPoints = const.SectorScanPoints

	-- parent dialog storage
	local parent = Dialogs.HUD
	if not parent.ChoGGi_TempOverviewInfo then
		parent.ChoGGi_TempOverviewInfo = XWindow:new({
			Id = "ChoGGi_TempOverviewInfo",
		}, parent)
	end
	parent = parent.ChoGGi_TempOverviewInfo
	parent:SetTransparency(mod_TextOpacity)

	local text_style = style_lookup[mod_TextStyle]
	local background = mod_TextBackground and black or XText.Background
	local deep = g_Consts.DeepScanAvailable ~= 0

	table.clear(sector_piles)
	if mod_ShowDropped then
		MapGet("map", "ResourceStockpile", function(pile)
			if not IsValid(pile.parent) and #(pile.command_centers or "") == 0 then
				-- maybe I'll add something to mark different stuff someday...
--~ 				sector_piles[GetMapSectorXY(pile:GetVisualPosXYZ()).id] = true
				local sector = GetMapSectorXY(UICity, pile:GetVisualPosXYZ()).id
				local list = sector_piles[sector]
				if not list then
					sector_piles[sector] = {}
					list = sector_piles[sector]
				end
				-- now add any res in pile to list
				if not list[pile.resource] then
					list[pile.resource] = 0
				end
				list[pile.resource] = list[pile.resource] + pile.stockpiled_amount
			end
		end)
	end
--~ 	ex(sector_piles)


	local sectors = UICity.MapSectors
	for sector in pairs(sectors) do
		-- skip 1-10
		if not sector_nums[sector] then

			-- count surface metals/poly in sector
			local metals_c = 0
			local polymers_c = 0
			local markers = sector.markers.surface
			for i = 1, #markers do
				local obj = markers[i].placed_obj
				-- placed_obj is removed from marker once it's empty
				if IsValid(obj) then
					if mod_ShowMetals and obj.resource == "Metals" then
						metals_c = metals_c + obj:GetAmount()
					elseif mod_ShowPolymers and obj.resource == "Polymers" then
						polymers_c = polymers_c + obj:GetAmount()
					end
				end
			end

			-- add text for found res
			table.iclear(text_table)
			local c = 0

			-- add scan info
			if mod_ShowScanProgress and sector.scan_progress > 0 then
				local target = deep and SectorDeepScanPoints or SectorScanPoints
				c = c + 1
				text_table[c] = T{4834, "<percentage>%",
					percentage = MulDivRound(sector.scan_progress, 100, target),
				}
			end

			-- add metal and/or poly info
			if metals_c > 0 then
				c = c + 1
				text_table[c] = str_Metals .. (metals_c/ResourceScale)
			end
			if polymers_c > 0 then
				c = c + 1
				text_table[c] = str_Polymers .. (polymers_c/ResourceScale)
			end

			-- add dropped res
			if sector_piles[sector.id] then
				c = c + 1
				text_table[c] = "<image UI/Icons/Sections/storage.tga>"
			end

			if c > 0 then
				local text_dlg = XText:new({
					TextStyle = text_style,
					Padding = padding_box,
					Margins = c == 3 and margin_box_trp or c == 2 and margin_box_dbl or margin_box,
					Background = background,
					Dock = "box",
					HAlign = "left",
					VAlign = "top",
					Clip = false,
					UseClipBox = false,
					HandleMouse = false,
				}, parent)

				text_dlg:SetText(table.concat(text_table, "\n"))

				text_dlg:AddDynamicPosModifier{
					id = "sector_info",
					target = sector,
				}
				text_dlg:SetVisible(true)
			end
		end
	end

end

local ChoOrig_OverviewModeDialog_Init = OverviewModeDialog.Init
function OverviewModeDialog.Init(...)
	Msg("ChoGGi_CentredHUD_SetMargin", false)
	AddIcons()
	return ChoOrig_OverviewModeDialog_Init(...)
end

local function ClearIcons()
	local parent = Dialogs.HUD.ChoGGi_TempOverviewInfo
	if not parent then
		return
	end

	for i = #parent, 1, -1 do
		parent[i]:Close()
	end
end

local ChoOrig_OverviewModeDialog_Close = OverviewModeDialog.Close
function OverviewModeDialog.Close(...)
	Msg("ChoGGi_CentredHUD_SetMargin", true)
	ClearIcons()
	return ChoOrig_OverviewModeDialog_Close(...)
end

-- We don't want them around for saves (I should check that they get saved I suppose...)
OnMsg.SaveGame = ClearIcons

local ChoOrig_GenerateSectorRolloverContext = OverviewModeDialog.GenerateSectorRolloverContext
function OverviewModeDialog:GenerateSectorRolloverContext(sector, ...)
	local ret1, ret2 = ChoOrig_GenerateSectorRolloverContext(self, sector, ...)

	-- append counts to sector tooltip
	local pile = sector_piles[sector.id]
	if pile then
		local ResourceScale = const.ResourceScale
		local roll = ret1.RolloverText

		roll = roll .. "<left>\n\n"
		for res, amount in pairs(pile) do
			roll = roll .. " " .. T("<icon_" .. res .. ">") .. ": " .. (amount / ResourceScale)
		end

		ret1.RolloverText = roll
	end

	return ret1, ret2
end


--~ local ChoOrig_OverviewModeDialog_CreateSectorRollover = OverviewModeDialog.CreateSectorRollover
--~ function OverviewModeDialog.CreateSectorRollover(...)
--~ 	CreateRealTimeThread(function(...)
--~ 		Sleep(mod_InfoBoxDelay)
--~ 		ChoOrig_OverviewModeDialog_CreateSectorRollover(...)
--~ 	end, ...)
--~ end
local ChoOrig_OverviewModeDialog_CreateSectorRollover = OverviewModeDialog.CreateSectorRollover
function OverviewModeDialog:CreateSectorRollover(sector, rollover_pos, forced, ...)
	CreateRealTimeThread(function(self, sector, rollover_pos, forced, ...)
		Sleep(mod_InfoBoxDelay)

		-- Copy pasta from OverviewModeDialog:GenerateSectorRolloverContext(sector, forced)
		if (not forced and CameraTransitionThread) or not sector or sector.id ~= self.sector_id then -- only refresh when called for the selected sector
			return
		end

		ChoOrig_OverviewModeDialog_CreateSectorRollover(self, sector, rollover_pos, forced, ...)
	end, self, sector, rollover_pos, forced, ...)
end
