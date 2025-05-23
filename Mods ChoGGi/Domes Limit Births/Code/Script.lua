-- See LICENSE for terms

local ChoOrig_CalcBirth = Community.CalcBirth
function Community:CalcBirth(...)
	local amount = #(self.labels.Child or "")
	local limit = self.ChoGGi_DomeLimitBirths

	-- make sure it exists, isn't zero, and amount isn't at limit
	if limit and limit > 0 and amount >= limit then
		return
	end
	return ChoOrig_CalcBirth(self, ...)
end

local apply_to_all = false
-- currently selected dome
local current

-- make sure apply to all is always defaults to false (otherwise it'll could update when user doesn't expect)
function OnMsg.SelectionRemoved()
	current = false
	apply_to_all = false
end

function OnMsg.ClassesPostprocess()
	local dome = XTemplates.sectionDome[1]
	-- check for and remove existing template
	ChoGGi_Funcs.Common.RemoveXTemplateSections(dome, "ChoGGi_Template_DomeLimitBirths")
	-- try to stick it just below the colonist section
	local idx = table.find(dome,"Icon","UI/Icons/Sections/colonist.tga")

	-- status updates/radius slider
	table.insert(
		dome,
		idx and idx+1 or #dome+1,
		PlaceObj('XTemplateTemplate', {
			"ChoGGi_Template_DomeLimitBirths", true,
			"Id", "ChoGGi_DomeLimitBirths",
			"__template", "InfopanelSection",
			"Title", " ",
			"Icon", "UI/Icons/Sections/dome.tga",
			"RolloverTemplate", "Rollover",
			"RolloverTitle", T(302535920011410, "Apply To All?"),
		}, {
			PlaceObj("XTemplateTemplate", {
				"__template", "InfopanelSlider",
				"RolloverTemplate", "Rollover",
				"RolloverTitle", T(302535920011411, "Limit Dome Births"),
				"RolloverText", T(302535920011412, "Set birth limit."),
				"BindTo", "ChoGGi_DomeLimitBirths",
				-- about the size of mega dome
				"Max", 500,
				"Min", 0,
				"StepSize", 1,
				"Scroll", 0,
				"ContextUpdateOnOpen", true,
				"OnContextUpdate", function(self, context)
					--
					-- slider won't do anything if this isn't a number
					context.ChoGGi_DomeLimitBirths = context.ChoGGi_DomeLimitBirths or 0

					-- make the slider scroll to current amount
					self.Scroll = context.ChoGGi_DomeLimitBirths

					-- turn off apply to all when the dome changes
					if current ~= context then
						apply_to_all = false
						current = context
					end

					local pp = self.parent.parent
					-- update title
					pp.idSectionTitle:SetText(T{302535920011413,
						"Limit Dome Births: <amount>",
						amount = context.ChoGGi_DomeLimitBirths,
					})

					-- update all domes
					if apply_to_all then
						local domes = (self.city or UICity).labels.Dome or ""
						for i = 1, #domes do
							domes[i].ChoGGi_DomeLimitBirths = context.ChoGGi_DomeLimitBirths
						end
						pp:SetIcon("UI/Icons/Sections/Overpopulated.tga")
						pp:SetRolloverText(T(302535920011414, "Apply value to all domes!"))
						pp:SetRolloverHint(T(302535920011688, "<left_click> Apply to this dome only."))
					else
						pp:SetIcon("UI/Icons/Sections/dome.tga")
						pp:SetRolloverText(T(302535920011415, "Apply value to this dome only."))
						pp:SetRolloverHint(T(302535920011689, "<left_click> Apply to all domes!"))
					end
					--
				end,
			}),
			PlaceObj("XTemplateFunc", {
				"name", "OnActivate(self, context)",
				"parent", function(self)
					return self.parent
				end,
				"func", function(self, context)
					--
					apply_to_all = not apply_to_all
					ObjModified(context)
					--
				end
			}),
		})
	)
end
