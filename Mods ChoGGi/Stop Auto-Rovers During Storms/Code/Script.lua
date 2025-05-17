-- See LICENSE for terms

local RetSpotPos = ChoGGi_Funcs.Common.RetSpotPos
local IsValid = IsValid
local FindNearestObject = FindNearestObject
local GetRealm = GetRealm

local mod_NearestLaser
local mod_NearestHub
local mod_ImmediateAbort

local function ModOptions(id)
	-- id is from ApplyModOptions
	if id and id ~= CurrentModId then
		return
	end

	mod_NearestLaser = CurrentModOptions:GetProperty("NearestLaser")
	mod_NearestHub = CurrentModOptions:GetProperty("NearestHub")
	mod_ImmediateAbort = CurrentModOptions:GetProperty("ImmediateAbort")
end
-- Load default/saved settings
OnMsg.ModsReloaded = ModOptions
-- Fired when Mod Options>Apply button is clicked
OnMsg.ApplyModOptions = ModOptions

function BaseRover:ChoGGi_IdleTime()
	self:SetState("idle")
	Sleep(5000)
	self:SetCommand("Idle")
end

local function IsWorking(obj)
	return obj.working
end

function BaseRover:ChoGGi_WaitItOut()
	local valid_obj, working_objs
	local labels = self.city.labels
	local realm = GetRealm(self)

	if mod_NearestLaser then
		-- try lasers first since towers are from mystery (usually)
		working_objs = realm:MapFilter(labels.MDSLaser or empty_table, IsWorking)
		valid_obj = FindNearestObject(working_objs, self)

		if not IsValid(valid_obj) then
			working_objs = realm:MapFilter(labels.DefenceTower or empty_table, IsWorking)
			valid_obj = FindNearestObject(working_objs, self)
		end
	end

	if mod_NearestHub and not IsValid(valid_obj) then
		working_objs = realm:MapFilter(labels.DroneHub or empty_table, IsWorking)
		valid_obj = FindNearestObject(working_objs, self)
	end

	-- make sure we don't keep looping through here
	self.ChoGGi_AutoRoversDuringStorms = valid_obj or true

	-- off we go
	if IsValid(valid_obj) then
		local pos = GetRealm(valid_obj):GetPassablePointNearby(
			RetSpotPos(self, valid_obj, "Workrover")
		)
		self:SetCommand("GotoFromUser", pos)
	else
		-- something messed up, or there's no buildings to hide around
		self:ChoGGi_IdleTime()
	end
end

function BaseRover:ChoGGi_Idle_Override(idle_func, ...)
	-- ignore underground/asteroids
	if self.city.map_id ~= MainMapID then
		return idle_func(self, ...)
	end

	-- use IsAutoModeEnabled for rovers without automode (modded ones)
	if AutoMode.IsAutoModeEnabled(self) and g_MeteorStorm then
		if (mod_NearestLaser or mod_NearestHub) and not self.ChoGGi_AutoRoversDuringStorms then
			self:ChoGGi_WaitItOut()
		else
			self:ChoGGi_IdleTime()
		end
	else
		if self.ChoGGi_AutoRoversDuringStorms then
			self.ChoGGi_AutoRoversDuringStorms = nil
		end
		return idle_func(self, ...)
	end
end

-- replace some idles
local classes = {
	"ExplorerRover",
	"RCTransport",
	"RCHarvester",
	"RCTerraformer",
}
local g = _G
for i = 1, #classes do
	local cls_obj = g[classes[i]]
	local ChoOrig_BaseRover_Idle = cls_obj.Idle
	function cls_obj:Idle(...)
		return self:ChoGGi_Idle_Override(ChoOrig_BaseRover_Idle, ...)
	end
end

function OnMsg.MeteorStorm()
	if mod_ImmediateAbort then
		local objs = MainCity.labels.Rover or ""
		for i = 1, #objs do
			local obj = objs[i]
			if IsValid(obj) and obj:IsKindOfClasses(classes) then
				obj:SetState("idle")
				obj:SetCommand("Idle")
			end
		end
	end
end
