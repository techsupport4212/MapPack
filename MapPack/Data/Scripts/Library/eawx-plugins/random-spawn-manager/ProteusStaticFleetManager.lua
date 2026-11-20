-- TechSupport -> Abomination.lua (ProteusStaticFleetManager.lua)
require("eawx-util/PopulatePlanetUtilities")

ProteusStaticFleetManager = {}

function ProteusStaticFleetManager.GetPlanetScore(owner, planet)
	-- calculate a target fleet value from planet statistics.
	-- higher infrastructure, income, ground-base level, shipyard level, or
	-- GenericPlanetValue produces a stronger replacement fleet.
	local infrastructure = EvaluatePerception("Infrastructure_Score", owner, planet)
	local income = EvaluatePerception("PlanetBaseIncome", owner, planet)
	local groundbase = EvaluatePerception("MaxGroundbaseLevel", owner, planet)
	local shipyard = EvaluatePerception("Max_Shipyard_Level", owner, planet)
	local planet_value = EvaluatePerception("GenericPlanetValue", owner, planet)
	-- return the calculated value
	return (infrastructure * 500) + (income * 10) + (groundbase * 500) + (shipyard * 1500) + (planet_value * 3000)
end

function ProteusStaticFleetManager.CollectForces(planet, owner, category, remove)
	-- find every unit owned by this faction that belongs to the requested category.
	-- the category is used for both ground units and space units.
	local existing_power = 0
	local units = Find_All_Objects_Of_Type(owner, category) or {}

	for _, unit in pairs(units) do
		if TestValid(unit) then
			local unit_planet = unit.Get_Planet_Location()
			if TestValid(unit_planet) and unit_planet == planet then
				local unit_type = unit.Get_Type()
				if TestValid(unit_type) then
					existing_power = existing_power + unit_type.Get_Combat_Rating()
				end
				if remove then
					-- despawn the parent company instead of an individual
					-- member when the existing force belongs to a company.
					local relevant_object = unit
					if unit.Get_Parent_Object then
						local parent = unit.Get_Parent_Object()
						if TestValid(parent) and parent ~= unit and parent ~= planet then
							local parent_type = parent.Get_Type()
							if TestValid(parent_type)
								and parent_type ~= Find_Object_Type("Galactic_Fleet") then
								relevant_object = parent
							end
						end
					end
					if TestValid(relevant_object) then
						relevant_object.Despawn()
					end
				end
			end
		end
	end

	return existing_power
end

function ProteusStaticFleetManager.IsEntryAvailable(entry)
	local year = GlobalValue.Get("GALACTIC_YEAR") or 0
	return (entry.StartYear == nil or year >= entry.StartYear)
		and (entry.LastYear == nil or year <= entry.LastYear)
end

function ProteusStaticFleetManager.SpawnOneFromTable(spawn_table, planet, owner)
	-- choose and spawn one valid unit from a small custom table.
	local valid_entries = {}
	for _, entry in pairs(spawn_table or {}) do
		if ProteusStaticFleetManager.IsEntryAvailable(entry) then
			table.insert(valid_entries, entry)
		end
	end

	if table.getn(valid_entries) == 0 then
		return 0
	end

	local entry = valid_entries[GameRandom.Free_Random(1, table.getn(valid_entries))]
	local unit_type = Find_Object_Type(entry[1])
	if TestValid(unit_type) then
		SpawnList({entry[1]}, planet, owner, true, false)
		return unit_type.Get_Combat_Rating()
	end
	return 0
end

function ProteusStaticFleetManager.CountNamedUnits(planet, owner, unit_name)
	local count = 0
	for _, unit in pairs(Find_All_Objects_Of_Type(owner, unit_name) or {}) do
		if TestValid(unit) and unit.Get_Planet_Location() == planet then
			count = count + 1
		end
	end
	return count
end

function ProteusStaticFleetManager.Repopulate(planet, owner)
	if not planet or not owner or not TestValid(planet) then
		DebugMessage("%s -- Cannot repopulate Proteus planet without a planet and owner", tostring(Script))
		return
	end
	-- load the custom table
	local custom_table = require("eawx-mod-icw/spawn-sets/ProteusStaticUnitSet")

	-- despawn and repopulate ground and space forces
	ProteusStaticFleetManager.CollectForces(planet, owner, "Infantry | Vehicle | AirGunship | AirSpeeder", true)
	local existing_space_power = ProteusStaticFleetManager.CollectForces(planet, owner, "Capital | Frigate | Corvette | Fighter | Bomber | Gunship", false)
	local target_power = ProteusStaticFleetManager.GetPlanetScore(owner, planet)
	local ground_power = target_power * 0.25
	local target_space_power = target_power * 0.75
	local final_space_power = target_space_power + existing_space_power

	-- print details for troubleshooting.
	--DebugMessage(
		--"%s -- Static Fleet %s | owner=%s | target_total=%s | target_ground=%s | target_space=%s | existing_space=%s | final_space=%s",
		--tostring(Script),
		--tostring(planet.Get_Type().Get_Name()),
		--tostring(owner.Get_Faction_Name()),
		--tostring(target_power),
		--tostring(ground_power),
		--tostring(target_space_power),
		--tostring(existing_space_power),
		--tostring(final_space_power)
	--)
	if final_space_power >= 14000 then
		if ProteusStaticFleetManager.CountNamedUnits(planet, owner, "Executor_Star_Dreadnought") == 0 then
			local ssd_power = ProteusStaticFleetManager.SpawnOneFromTable(custom_table["SSD_Table"], planet, owner)
			-- print ze dbug msg
			--DebugMessage(
				--"%s -- Static Fleet %s | spawned SSD combat_power=%s",
				--tostring(Script),
				--tostring(planet.Get_Type().Get_Name()),
				--tostring(ssd_power)
			--)
		end
	end

	local general_power = target_space_power
	if general_power > 0 then
		Spawn_Random_Units(custom_table["General_Table"], planet, owner, general_power, nil)
	end

	local result_space_power = ProteusStaticFleetManager.CollectForces( planet, owner, "Capital | Frigate | Corvette | Fighter | Bomber | Gunship", false)
	--DebugMessage(
		--"%s -- Static Fleet %s | final fleet space combat_power=%s | SSD_count=%s | battlecruiser_count=%s",
		--tostring(Script),
		--tostring(planet.Get_Type().Get_Name()),
		--tostring(result_space_power),
		--tostring(ProteusStaticFleetManager.CountNamedUnits(planet, owner, "Executor_Star_Dreadnought")), -- these named units are here for testing reasons ONLY
		--tostring(ProteusStaticFleetManager.CountNamedUnits(planet, owner, "Allegiance_Battlecruiser")) -- DELETE before populating custom units as this will BREAJK
	--)

	if EvaluatePerception("MaxGroundbaseLevel", owner, planet) > 0 then
		Spawn_Random_Units(custom_table["Land_Unit_Table"], planet, owner, ground_power, 10)
	end
end

return ProteusStaticFleetManager
