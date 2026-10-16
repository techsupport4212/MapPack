require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("PGSpawnUnits")
require("UnitSwitcherLibrary")
require("SetFighterResearch")

HeroSwap = class()

function HeroSwap:new(gc)
	self.gc = gc

	self.gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
end

function HeroSwap:on_production_finished(planet, object_type_name)
	--Logger:trace("entering HeroSwap:on_production_finished")

	local swap_entry = StoryUtil.Get_Swap_Entry(object_type_name)

	if swap_entry ~= nil then
		local old_unit = swap_entry[1]
		local new_unit = swap_entry[2]

		local SwapDummy = Find_First_Object(object_type_name)

		if SwapDummy == nil then
			return
		end

		local SwapOwner = SwapDummy.Get_Owner()
		local SwapLocation = SwapDummy.Get_Planet_Location()

		if old_unit == nil then
			SpawnList(new_unit, SwapLocation, SwapOwner,true,false)

			local unlocks = swap_entry.Unlocks
			if unlocks ~= nil then
				for _, unlock in pairs(unlocks) do
					SwapOwner.Unlock_Tech(Find_Object_Type(unlock))
				end
			end
		else
			local checkObject = nil

			if swap_entry.location_check then
				local checkArray = Find_All_Objects_Of_Type(old_unit)

				for _, checks in pairs(checkArray) do
					if checks.Get_Planet_Location() == SwapLocation then
						checkObject = checks
						break
					end
				end
			else
				checkObject = Find_First_Object(old_unit)
			end

			if TestValid(checkObject) or swap_entry.old_unit_optional then
				spawn_list_new = {new_unit}
				SpawnList(spawn_list_new, SwapLocation, SwapOwner,true,false)
				Transfer_Fighter_Hero(string.upper(old_unit), string.upper(new_unit))
			end

			if TestValid(checkObject) then
				checkObject.Despawn()
			end

		end

		SwapDummy.Despawn()
	end
end
