-- See LICENSE for terms

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	if UIColony and CurrentModOptions:GetProperty("PinAllRockets") then
		local objs = UIColony:GetCityLabels("RocketBase")
		for i = 1, #objs do
			local rocket = objs[i]
			if rocket.command ~= "OnEarth" then
				rocket:SetPinned(true)
			end
		end
	end
end
--~ -- load default/saved settings
--~ OnMsg.ModsReloaded = ModOptions
-- fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions

function RocketBase.CanBeUnpinned()
	return true
end

RocketBase.show_pin_toggle = true

local function ShowPins()
	local objs = UIColony:GetCityLabels("RocketBase")
	for i = 1, #objs do
		objs[i].show_pin_toggle = true
	end
end

OnMsg.CityStart = ShowPins
OnMsg.LoadGame = ShowPins
-- something may reset it?
OnMsg.NewDay = ShowPins

-- They all use the same func, I'll leave the code in case something does a mod with it
local ChoOrig_RocketBase_SetPinned = RocketBase.SetPinned
local ChoOrig_SetPinned
local function fake_SetPinned(rocket)
	-- might help keep pin around?
	rocket.show_pin_toggle = true
end

local ChoOrig_RocketBase_UpdateStatus = RocketBase.UpdateStatus
function RocketBase:UpdateStatus(status, ...)
	-- it still needs to be pinned for other stuff (countdown is for  Ski's auto tourism mod)
	if status ~= "landing" or status ~= "landed" or status ~= "countdown" then
--~ 	if status ~= "landing" or status ~= "landed" then
		return ChoOrig_RocketBase_UpdateStatus(self, status, ...)
	end

	-- okay a bit overkill
	ChoOrig_SetPinned = self.SetPinned
	self.SetPinned = fake_SetPinned
	-- I do pcalls for safety when wanting to change back a global var
	pcall(ChoOrig_RocketBase_UpdateStatus, self, status, ...)
	self.SetPinned = ChoOrig_SetPinned or ChoOrig_RocketBase_SetPinned
	ChoOrig_SetPinned = nil
end
