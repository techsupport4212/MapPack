require("PGStoryMode")
require("deepcore/crossplot/crossplot")
require("deepcore/std/class")
require("eawx-util/PopulatePlanetUtilities")
require("UnitSpawnerTables")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("FTGULibrary")
require("eawx-util/FTGUPopulate")
require("CustomLibrary")
require("SetFighterResearch")

function Definitions()
	DebugMessage("%s -- In Definitions", tostring(Script))

	StoryModeEvents = {
		Trigger_Custom_Init = State_Custom_Init,
		Trigger_Delayed_Initialize = State_Delayed_Initialize,
		Trigger_First_Conquest = State_First_Conquest
	}

	FTGU_Dummies = Get_FTGU_Dummies()

	Shortcut = false

	LocationType = ""
	RosterType = ""
	HeroType = ""
	StartType = ""
	PlanetModifier = ""

	CapStart = nil

	humanname = ""
	humanfaction = nil

	Bordering_Planets_List = nil

	StartingEra = nil

	Connected_Starting_Planet_List = {}
	Connected_Starting_Max = 1

	hero_lists = {{},{},{},{},{},{},{}}
	hero_list_perfaction = {}
	market_options = {}
	Proteans = {}
	Protean_Tech = {}
	
	AI_Tech_On = false
	AI_Tech_Dummy_Spawn = false
	AI_Picked_Heroes = {}
	AI_Settings_Locations = {}
	
	Pick_Everywhere_Roguelike = false

	crossplot:galactic()
	crossplot:subscribe("START_LOCATION_PICK", Location_Choice)
	crossplot:subscribe("ROSTER_PICK", Roster_Choice)
	crossplot:subscribe("HERO_PICK", Hero_Choice)
	crossplot:subscribe("STARTING_SIZE_PICK", Size_Choice)
	crossplot:subscribe("PLANET_MODIFIER_PICK", Modifier_Choice)
end

function find_Neutral_planet(space_only_ok)
	local allPlanets = FindPlanet.Get_All_Planets()

	local random = 0
	local planet = nil

	while table.getn(allPlanets) > 0 do
		random = GameRandom.Free_Random(1, table.getn(allPlanets))
		planet = allPlanets[random]
		table.remove(allPlanets, random)

		local base_level = EvaluatePerception("MaxGroundbaseLevel", Find_Player("Independent_Forces"), planet)
		if space_only_ok then
			base_level = 1
		end
		
		local unlocked = not StoryUtil.CheckPlanetRestricted(planet.Get_Type().Get_Name())

		if planet.Get_Owner() == Find_Player("Neutral") and base_level > 0 and unlocked then
			return planet
		end
	end
end

function find_connected_neutral_planet(start_planet, player)
	local iterations = 0
	while iterations <= 20 do
		local path = Find_Path(player, start_planet, find_Neutral_planet(true))
		local result = path[2]
		iterations = iterations + 1
		if result.Get_Owner() == Find_Player("Neutral") then
			return result
		end
	end
	return nil
end

function find_connected_starting_planet(start_planet, planetcount, spaceonly)
	for tryagain = 1, 2 do
		if tryagain == 2 then
			Connected_Starting_Max = Connected_Starting_Max + 1
		end
		local allPlanets = FindPlanet.Get_All_Planets()
		for _, test_planet in pairs(allPlanets) do
			local base_level = EvaluatePerception("MaxGroundbaseLevel", Find_Player("Independent_Forces"), test_planet)
			local oktocheck = not StoryUtil.CheckPlanetRestricted(test_planet.Get_Type().Get_Name())
			if base_level > 0 or spaceonly then
				for __, planet in pairs(Connected_Starting_Planet_List) do
					if test_planet == planet then
						oktocheck = false
						break
					end
				end
			else
				oktocheck = false
			end
			if oktocheck then
				local path = Find_Path(humanfaction, start_planet, test_planet)
				if table.getn(path) <= Connected_Starting_Max and table.getn(path) > 0 then --Note that including the starting planet in the path effectively drops the max by 1. And that planets without a path to the start will cause problems without the second case
					table.insert(Connected_Starting_Planet_List, test_planet)
					return test_planet
				end
			end
		end
	end
	local corenne = find_Neutral_planet(false)
	table.insert(Connected_Starting_Planet_List, corenne)
	return corenne
end

function find_distant_neutral_planet(start_planet)
	local iterations = 0
	local guess = nil
	while iterations <= 100 do
		guess = find_Neutral_planet(false)
		local path = Find_Path(humanfaction, start_planet, guess)
		iterations = iterations + 1
		if table.getn(path) > 6 then
			return guess
		end
	end
	return guess
end

function find_double_distant_neutral_planet(start_planet, start_planet2)
	local iterations = 0
	local guess = nil
	while iterations <= 100 do
		guess = find_Neutral_planet(false)
		local path = Find_Path(humanfaction, start_planet, guess)
		local path2 = Find_Path(humanfaction, start_planet2, guess)
		iterations = iterations + 1
		if table.getn(path) > 6 and table.getn(path2) > 4 then
			return guess
		end
	end
	return guess
end

function find_bordering_neutral_planet(player, perception)
	local random = 0
	local planet = nil

	local iterations = 0
	local max_its = table.getn(Bordering_Planets_List) * 2

	while table.getn(Bordering_Planets_List) > 0 do
		iterations = iterations + 1
		if iterations > max_its then
			return nil --find_Neutral_planet(true)
		end

		random = GameRandom.Free_Random(1, table.getn(Bordering_Planets_List))
		planet = Bordering_Planets_List[random]

		local dbug = EvaluatePerception(perception, player, planet)

		if dbug > 0 and planet.Get_Owner() == Find_Player("Neutral") and (not StoryUtil.CheckPlanetRestricted(planet.Get_Type().Get_Name())) then
			table.remove(Bordering_Planets_List, random)
			return planet
		end
	end
end

function State_Custom_Init(message)
	if message == OnEnter then
		StartingEra = GlobalValue.Get("CURRENT_ERA")
		Set_Tech()
	else
		crossplot:update()
	end
end

function get_value_per_era(array, year, nontable)
	if nontable and type(array) ~= "table" then
		return array
	end
	if nontable or type(array[1]) == "table" then
		local corenne = array[1]
		local maxevent = 0 --The order of evaluation is not guaranteed
		for event, data in pairs(array) do
			if year >= event and event > maxevent then
				maxevent = event
				corenne = data
			end
		end
		return corenne
	else
		return array
	end
end

function State_Delayed_Initialize(message)
	if message == OnEnter then
		local year = GlobalValue.Get("GALACTIC_YEAR")
		if year == nil then
			year = 1.0
		end
		local initial_proteus_lock_units = require("eawx-plugins/warlord-start/ProteusLocks")
		if type(initial_proteus_lock_units) == "table" then
			UnitUtil.SetLockList("IMPERIAL_PROTEUS", get_value_per_era(initial_proteus_lock_units, year), false)
		end
		if GlobalValue.Get("CUSTOM_LEARNER_MODE") then
			crossplot:publish("START_LOCATION_PICK", "CUSTOM_GC_LEARNER_MODE")
		else
			local options = {"LEARNER_MODE", "PICK_LOCATION", "PICK_ENEMY_LOCATION", "PICK_EVERYWHERE", "ROGUELIKE_FACTIONAL", "ROGUELIKE_ALL"}
			if TestValid(Find_First_Object("Custom_GC_Capital")) then
				table.insert(options, "PICK_NOAFFILS")
			end
			crossplot:publish("POPUPEVENT", "CUSTOM_GC", options, "START_LOCATION_PICK")
		end
	else
		crossplot:update()
	end
end

function Location_Choice(choice)
	LocationType = choice
	
	local despawn = LocationType ~= "CUSTOM_GC_PICK_EVERYWHERE" and LocationType ~= "CUSTOM_GC_ROGUELIKE_FACTIONAL" and LocationType ~= "CUSTOM_GC_ROGUELIKE_ALL"

	local caps = Find_All_Objects_Of_Type("Custom_GC_Capital")

	for factionid, info in pairs(FTGU_Dummies) do
		local player = Find_Player(factionid)

		if player.Is_Human() then
			humanname = factionid
			humanfaction = Find_Player(humanname)

			local humanDummies = Find_All_Objects_Of_Type(info.DummyUnit)
			for _, cap in pairs(caps) do
				local locale = cap.Get_Planet_Location()
				for _, humdum in pairs(humanDummies) do
					local locale2 = humdum.Get_Planet_Location()
					if locale == locale2 then
						CapStart = locale
						Pick_Everywhere_Roguelike = true
						break
					end
				end
				if CapStart ~= nil then
					break
				end
			end
		end

		if despawn then
			local dummies = Find_All_Objects_Of_Type(info.DummyUnit)
			for _, dummy in pairs(dummies) do
				dummy.Despawn()
			end
		end
		
		if LocationType == "CUSTOM_GC_PICK_NOAFFILS" then
			LocationType = "CUSTOM_GC_PICK_EVERYWHERE"
		end
		
		AI_Picked_Heroes[factionid] = {}
		Protean_Tech[factionid] = {}
		if info.Proteus_Library then
			local proteus_lib = require(info.Proteus_Library)
			Proteans[factionid] = {}

			for suffix, protdata in pairs(proteus_lib) do
				table.insert(Proteans[factionid], info.Proteus_Prefix .. suffix)

				if protdata.LockList then
					for _, unit in pairs(get_array_per_era(protdata.LockList)) do
						Protean_Tech[factionid][string.upper(unit)] = true
					end
				end
			end

			GlobalValue.Set(FTGU_Dummies[factionid].Proteus_Name_Variable, "Setup Placeholder")
			crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", factionid, "Setup Placeholder")
		end
	end

	if despawn then
		for _, cap in pairs(caps) do
			cap.Despawn()
		end
	end
	
	local Roguelike_Size = "CUSTOM_GC_SMALL_START"
	if GameRandom.Free_Random(0, 1) > 0 then
		Roguelike_Size = "CUSTOM_GC_FULL_START"
	end

	if choice == "CUSTOM_GC_LEARNER_MODE" then
		RosterType = "CUSTOM_GC_STANDARD_ROSTER"
		HeroType = "CUSTOM_GC_HERO_DEFAULT"
		crossplot:publish("STARTING_SIZE_PICK", "CUSTOM_GC_SMALL_START")
		PlanetModifier = "CUSTOM_GC_PLAYER_HALF"
		Shortcut = true
	elseif choice == "CUSTOM_GC_ROGUELIKE_FACTIONAL" then
		AI_Tech_On = true
		RosterType = "CUSTOM_GC_RANDOM_ROSTER"
		HeroType = "CUSTOM_GC_HERO_FACTIONAL_RANDOM"
		crossplot:publish("STARTING_SIZE_PICK", Roguelike_Size)
		PlanetModifier = "CUSTOM_GC_EQUAL"
		Shortcut = true
	elseif choice == "CUSTOM_GC_ROGUELIKE_ALL" then
		AI_Tech_On = true
		RosterType = "CUSTOM_GC_RANDOM_MAPS"
		HeroType = "CUSTOM_GC_HERO_ALL_RANDOM"
		crossplot:publish("STARTING_SIZE_PICK", Roguelike_Size)
		PlanetModifier = "CUSTOM_GC_EQUAL"
		Shortcut = true
	else
		crossplot:publish("POPUPEVENT", "CUSTOM_GC", {"STANDARD_ROSTER", "CUSTOM_ROSTER_ENABLE", "CUSTOM_ROSTER", "MAPPED_ROSTER", "RANDOM_ROSTER", "RANDOM_MAPS", "LOOTBOX_ROSTER", "AI_TECH"}, "ROSTER_PICK")
	end

end

function Roster_Choice(choice)
	if choice == "CUSTOM_GC_AI_TECH" then
		AI_Tech_On = true
		
		crossplot:publish("POPUPEVENT", "CUSTOM_GC", {"CUSTOM_ROSTER_ENABLE", "CUSTOM_ROSTER", "MAPPED_ROSTER", "RANDOM_ROSTER", "RANDOM_MAPS", "LOOTBOX_ROSTER"}, "ROSTER_PICK")
	else
		RosterType = choice

		crossplot:publish("POPUPEVENT", "CUSTOM_GC", {"HERO_DEFAULT", "HERO_NONE", "HERO_FACTIONAL", "HERO_ALL", "HERO_FACTIONAL_DEFAULT", "HERO_ALL_DEFAULT", "HERO_FACTIONAL_RANDOM", "HERO_ALL_RANDOM"}, "HERO_PICK")
	end
end

function Hero_Choice(choice)
	HeroType = choice

	crossplot:publish("POPUPEVENT", "CUSTOM_GC", {"FTGU", "SMALL_START", "FULL_START"}, "STARTING_SIZE_PICK")
end

function Modifier_Choice(choice)
	PlanetModifier = choice

	SpawnList({PlanetModifier}, Find_First_Object(LocationType).Get_Planet_Location(), humanfaction,false,false)
end

function Size_Choice(choice)
	if StartType ~= "" then
		StoryUtil.ShowScreenText("Multiinit", 20, nil, {r = 244, g = 244, b = 0})
		return
	end
	StartType = choice

	if not Shortcut and choice ~= "CUSTOM_GC_FTGU" and LocationType ~= "CUSTOM_GC_PICK_EVERYWHERE" then
		crossplot:publish("POPUPEVENT", "CUSTOM_GC", {"EQUAL", "PLAYER_EXTRA", "PLAYER_HALF", "PLAYER_FTGU_EXTREME", "PLAYER_OBSERVER"}, "PLANET_MODIFIER_PICK")
	end

	local primary_list = {"Custom_GC_Starter_Dummy_Team"}
	local secondary_list = {"Custom_GC_Random_Dummy","Custom_GC_Random_Dummy","Custom_GC_Random_Dummy","Custom_GC_Random_Dummy","Custom_GC_Random_Dummy"}
	local everywhere_list = {}
	local ai_settings_list = {}
	
	if AI_Tech_On and (RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" or RosterType == "CUSTOM_GC_CUSTOM_ROSTER" or RosterType == "CUSTOM_GC_MAPPED_ROSTER") then
		AI_Tech_Dummy_Spawn = true
	end

	local humaninfo = FTGU_Dummies[humanname]

	for factionid, info in pairs(FTGU_Dummies) do
		--if PlanetModifier ~= "CUSTOM_GC_PLAYER_OBSERVER" and factionid ~= humanname then --At present you can't select pick everywhere and observer mode at the same time
		table.insert(everywhere_list, info.DummyUnit)
		--end
		if not AI_Tech_Dummy_Spawn then
			if factionid ~= humanname and (not info.Nonplayable or LocationType == "CUSTOM_GC_PICK_EVERYWHERE") then
				table.insert(primary_list, info.DummyUnit)
				if HeroType == "CUSTOM_GC_HERO_ALL" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT" then
					table.insert(ai_settings_list, "Custom_GC_AI_Settings_Dummy")
				end
			end
		end
		if info.Angry_AI_Dummy and factionid ~= humanname then
			table.insert(primary_list, info.Angry_AI_Dummy)
		end
	end

	local start = CapStart
	if start == nil then
		for _, candidate in pairs(humaninfo.PlayerStart) do
			start = FindPlanet(candidate)
			if start ~= nil then
				break
			end
		end
	end
	if start == nil then
		start = find_Neutral_planet(false)
	end

	local maxperplanet = 33
	local planetcount = table.getn(FindPlanet.Get_All_Planets())
	Connected_Starting_Planet_List = {start}

	if LocationType == "CUSTOM_GC_LEARNER_MODE" then
		LocationType = "CUSTOM_GC_PICK_ENEMY_LOCATION"
		RosterType = "CUSTOM_GC_STANDARD_ROSTER"
		HeroType = "CUSTOM_GC_HERO_DEFAULT"
		StartType = "CUSTOM_GC_SMALL_START"
		PlanetModifier = "CUSTOM_GC_PLAYER_HALF"
		SpawnList(primary_list, start, humanfaction,false,false)
		SpawnList({"Placement_Dummy"}, start, humanfaction,false,false)
	elseif LocationType == "CUSTOM_GC_ROGUELIKE_FACTIONAL" or LocationType == "CUSTOM_GC_ROGUELIKE_ALL" then
		start = find_Neutral_planet(false)
		if LocationType == "CUSTOM_GC_ROGUELIKE_FACTIONAL" then
			RosterType = "CUSTOM_GC_RANDOM_ROSTER"
			HeroType = "CUSTOM_GC_HERO_FACTIONAL_RANDOM"
		else
			RosterType = "CUSTOM_GC_RANDOM_MAPS"
			HeroType = "CUSTOM_GC_HERO_ALL_RANDOM"
		end
		get_hero_lists(true)
		LocationType = "CUSTOM_GC_PICK_LOCATION"
		if Pick_Everywhere_Roguelike and GameRandom.Free_Random(0, 2) > 1 then
			LocationType = "CUSTOM_GC_PICK_EVERYWHERE"
		else
			Pick_Everywhere_Roguelike = false
			local caps = Find_All_Objects_Of_Type("Custom_GC_Capital")
			for _, cap in pairs(caps) do
				cap.Despawn()
			end

			for factionid, info in pairs(FTGU_Dummies) do
				local dummies = Find_All_Objects_Of_Type(info.DummyUnit)
				for _, dummy in pairs(dummies) do
					dummy.Despawn()
				end
			end
		end
		sizemods = {"CUSTOM_GC_EQUAL","CUSTOM_GC_PLAYER_EXTRA","CUSTOM_GC_PLAYER_HALF"}
		PlanetModifier = sizemods[GameRandom.Free_Random(1, 3)]
		local dummylist = {"Custom_GC_Starter_Dummy_Team"}
		if not Pick_Everywhere_Roguelike then
			for i = 1,GameRandom.Free_Random(2, 5) do
				table.insert(dummylist, "Custom_GC_Random_Dummy")
			end
		end
		SpawnList(dummylist, start, humanfaction,false,false)
		SpawnList({"Placement_Dummy"}, start, humanfaction,false,false)
	else
		StoryUtil.ShowScreenText("Pick your starting planet by conquering it with the GC Starter object", 20, nil, {r = 244, g = 244, b = 0})
		if LocationType == "CUSTOM_GC_PICK_LOCATION" then
			StoryUtil.ShowScreenText("Place the factions you wish to fight in the orbit of your choice before conquering", 20, nil, {r = 244, g = 244, b = 0})
			SpawnList(primary_list, start, humanfaction,false,false)
			SpawnList(secondary_list, start, humanfaction,false,false)

		elseif LocationType == "CUSTOM_GC_PICK_ENEMY_LOCATION" then
			StoryUtil.ShowScreenText("Place the enemy faction objects over planets you want them to own before conquering your choice. Default enemy markers are placed on their default locations", 20, nil, {r = 244, g = 244, b = 0})

			SpawnList(primary_list, start, humanfaction,false,false)
			SpawnList(secondary_list, start, humanfaction,false,false)
		elseif LocationType == "CUSTOM_GC_PICK_EVERYWHERE" then
			StoryUtil.ShowScreenText("Place the enemy faction objects over planets you want them to own before conquering your choice. Default enemy markers are placed on their default locations", 20, nil, {r = 244, g = 244, b = 0})

			SpawnList(primary_list, start, humanfaction,false,false)
			table.insert(everywhere_list, "Custom_GC_Capital")
			table.insert(everywhere_list, "Custom_GC_Planet_Lock")
			table.insert(everywhere_list, "Custom_GC_Planet_Destroy")
			for i = 1,planetcount-1 do
			   SpawnList(everywhere_list, start, humanfaction,false,false)
			end
		end
		
		if table.getn(ai_settings_list) > 0 then
			local dummydump = find_connected_starting_planet(start, planetcount, true)
			SpawnList(ai_settings_list, dummydump, humanfaction,false,false)
		end

		if HeroType == "CUSTOM_GC_HERO_DEFAULT" then
			if StartType == "CUSTOM_GC_SMALL_START" then
				local herodump = find_connected_starting_planet(start, planetcount)
				local herolist = get_alt_heroes()
				if herolist ~= nil then
					local spawns = {}
					for _, lists in pairs(herolist) do
						table.insert(spawns, lists[1])
					end
					SpawnList({"Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy"}, herodump, Find_Player("Neutral"),false,false)
					SpawnList(spawns, herodump, humanfaction,false,false)
					local forceorbit = Find_All_Objects_Of_Type("Placement_Dummy")
					for _, randomDummy in pairs(forceorbit) do
						randomDummy.Despawn()
					end
				end
			end
		else
			get_hero_lists(HeroType ~= "CUSTOM_GC_HERO_FACTIONAL" and HeroType ~= "CUSTOM_GC_HERO_FACTIONAL_DEFAULT")
			if HeroType == "CUSTOM_GC_HERO_FACTIONAL" or HeroType == "CUSTOM_GC_HERO_ALL" or HeroType == "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT" then
				for i=1,7 do
					local heroes = {}
					local itemsinlist = 0
					local totalobjects = table.getn(hero_lists[i])

					for _, name in pairs(hero_lists[i]) do
						table.insert(heroes, name)
						itemsinlist = itemsinlist + 1

						if itemsinlist >= maxperplanet or _ == totalobjects and itemsinlist > 0 then --Always need to spawn the list on the last entry, even if the last unit is not being spawned
							local empty_planet = find_connected_starting_planet(start, planetcount)
							--Fill up the ground so you don't conquer the planet and trigger a start
							SpawnList({"Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy"}, empty_planet, Find_Player("Neutral"),false,false)
							SpawnList(heroes, empty_planet, humanfaction,false,false)
							heroes = {}
							itemsinlist = 0

							local forceorbit = Find_All_Objects_Of_Type("Placement_Dummy")
							for _, randomDummy in pairs(forceorbit) do
								randomDummy.Despawn()
							end
						end
					end
				end
			end
			--categories for planet placement only, not type logic
			for _, name in pairs(hero_lists[5]) do --admin space = space
				table.insert(hero_lists[3], name)
			end
			hero_lists[5] = {}
			for _, name in pairs(hero_lists[7]) do --fold vehicle and infantry together
				table.insert(hero_lists[2], name)
			end
			hero_lists[7] = {}
		end

		for _, protdata in pairs(Proteans) do
			local sublist = {}
			local itemsinlist = 0
			local totalobjects = table.getn(protdata)

			for _, name in pairs(protdata) do
				table.insert(sublist, name)
				itemsinlist = itemsinlist + 1

				if itemsinlist >= maxperplanet or _ == totalobjects and itemsinlist > 0 then --Always need to spawn the list on the last entry, even if the last unit is not being spawned
					local empty_planet = find_connected_starting_planet(start, planetcount)
					--Fill up the ground so you don't conquer the planet and trigger a start
					SpawnList(sublist, empty_planet, humanfaction,false,false)
					sublist = {}
					itemsinlist = 0
				end
			end
		end
	end

	if RosterType ~= "CUSTOM_GC_STANDARD_ROSTER" then
		local market_library = require("ShipMarketOptions")
		for factionid, info in pairs(FTGU_Dummies) do
			market_options[factionid] = {}
			local playerlib = market_library[string.upper(factionid)]
			if playerlib ~= nil then
				for marketname, market in pairs(playerlib) do
					if market.list ~= nil then
						for shipname, irrelevant in pairs(market.list) do
							market_options[factionid][shipname] = marketname
						end
					end
				end
			end
		end
	end
	
	if RosterType == "CUSTOM_GC_CUSTOM_ROSTER" or RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" or RosterType == "CUSTOM_GC_MAPPED_ROSTER" then
		local spare_r2 = {}
		for factionid, info in pairs(FTGU_Dummies) do
			if info.RosterUnits then
				if (AI_Tech_Dummy_Spawn and factionid ~= humanname) or (factionid == humanname and RosterType ~= "CUSTOM_GC_MAPPED_ROSTER") then
					local faction_object = Find_Player(factionid)
					
					local custom = true
					if RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" then
						custom = false
					end
					local locked = {}
					local itemsinlist = 0
					local firstplanet = nil
					if factionid ~= humanname then
						table.insert(locked, "Custom_GC_AI_Settings_Dummy")
						itemsinlist = 2
					end
					local totalobjects = table.getn(info.RosterUnits)
					local nonespawned = true
					local restrictions = Get_Planet_Restrictions()
					for _, unit in pairs(info.RosterUnits) do
						if custom or market_options[factionid][string.upper(unit)] or Protean_Tech[factionid][string.upper(unit)] or Find_Object_Type(unit).Is_Build_Locked(faction_object) or Find_Object_Type(unit).Is_Obsolete(faction_object) then --it's market and proteus checks for some reason
							local planetok = true
							if restrictions[unit] ~= nil then
								planetok = false
								local planetlocked = ""
								for __, planet in pairs(restrictions[unit]) do
									if FindPlanet(planet) ~= nil then
										planetok = true
										if planetlocked == "" then
											planetlocked = planetlocked .. planet
										else
											planetlocked = planetlocked .. ", " .. planet
										end
									end
								end
								if planetok then
									StoryUtil.ShowScreenText(unit .. " can only be built on " .. planetlocked, 20, nil, {r = 200, g = 0, b = 200})
								end
							end
							if planetok then
								table.insert(locked, unit)
								itemsinlist = itemsinlist + 1
							end
						end
						if itemsinlist >= maxperplanet or _ == totalobjects and (factionid == humanname and itemsinlist > 0 or itemsinlist > 2) then --Always need to spawn the list on the last entry, even if the last unit is not being spawned
							local rosterspace = find_connected_starting_planet(start, planetcount)
							if firstplanet == nil then
								firstplanet = rosterspace
							end
							--Fill up the ground so you don't conquer the planet and trigger a start
							SpawnList({"Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy"}, rosterspace, Find_Player("Neutral"),false,false)
							SpawnList(locked, rosterspace, humanfaction,false,false)
							locked = {}
							itemsinlist = 0
							if factionid ~= humanname then
								table.insert(locked, info.DummyUnit)
								itemsinlist = 1
							end
							nonespawned = false
						end
					end
					if nonespawned then
						StoryUtil.ShowScreenText("No Roster Additions exist for " .. factionid, 10)
						if factionid ~= humanname then
							SpawnList({info.DummyUnit}, start, humanfaction,false,false)
							if HeroType == "CUSTOM_GC_HERO_ALL" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT" then
								table.insert(spare_r2, "Custom_GC_AI_Settings_Dummy")
							end
						end
					elseif firstplanet and factionid ~= humanname then
						SpawnList({info.DummyUnit}, firstplanet, humanfaction,false,false) --spawn last so the one with the AI_settings dummy is found first in Pick Enemy Location
					end

					local forceorbit = Find_All_Objects_Of_Type("Placement_Dummy")
					for _, randomDummy in pairs(forceorbit) do
						randomDummy.Despawn()
					end
				end
			else
				if ((HeroType == "CUSTOM_GC_HERO_ALL" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT") and LocationType == "CUSTOM_GC_PICK_EVERYWHERE") then
					table.insert(spare_r2, "Custom_GC_AI_Settings_Dummy")
				end
			end
		end
		if table.getn(spare_r2) >= 0 then --Spawn AI settings dummies for factions that don't have roster but might get custom hero setups
			SpawnList(spare_r2, find_connected_starting_planet(start, planetcount, true), humanfaction,false,false)
		end
	end

	if RosterType == "CUSTOM_GC_CUSTOM_ROSTER" or RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" then
		if RosterType == "CUSTOM_GC_CUSTOM_ROSTER" then
			StoryUtil.ShowScreenText("Place all units you wish to be able to build over your starting planet to enable. All others will be disabled", 20, nil, {r = 50, g = 244, b = 0})
		elseif RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" then
			StoryUtil.ShowScreenText("Place any extra units you wish to be able to build over your starting planet", 20, nil, {r = 50, g = 244, b = 0})
		end
	end
	if RosterType == "CUSTOM_GC_MAPPED_ROSTER" then
		--Mapped roster
		StoryUtil.ShowScreenText("Define units to replace roster units. Certain units cannot be replaced and are enabled by leaving them over the starting planet", 20, nil, {r = 50, g = 244, b = 0})

		local mapping = Get_Roster_Mapping()
		local bases = humaninfo.RosterMapBases
		SpawnList({"Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy"}, start, Find_Player("Neutral"),false,false)
		SpawnList(humaninfo.UnmappedRoster, start, humanfaction,false,false)
		local randoms = {}

		for _, map_definition in pairs(mapping) do
			for __, map_dummy in pairs(map_definition[1]) do
				if bases[map_dummy] then
					local mapplanet = find_connected_starting_planet(start, planetcount)
					SpawnList({"Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy","Placement_Dummy"}, mapplanet, Find_Player("Neutral"),false,false)
					SpawnList({map_dummy, bases[map_dummy]}, mapplanet, humanfaction,false,false)
					SpawnList(map_definition[2], mapplanet, humanfaction,false,false)
					table.insert(randoms, "Custom_GC_Random_Unit_Dummy")
				end
			end
		end
		SpawnList(randoms, start, humanfaction,false,false)
		local forceorbit = Find_All_Objects_Of_Type("Placement_Dummy")
		for _, randomDummy in pairs(forceorbit) do
			randomDummy.Despawn()
		end
	end
	local choicedump = find_distant_neutral_planet(start)
	if AI_Tech_On then
		SpawnList({"CUSTOM_GC_AI_TECH"}, choicedump, humanfaction,false,false)
	end
	SpawnList({LocationType, RosterType, HeroType, StartType}, choicedump, humanfaction,false,false)
end

function State_First_Conquest(message)
	if message == OnEnter then
		--The dummy for Learner mode and such shouldn't be deleted until the conquest has registered
		local forceorbit = Find_All_Objects_Of_Type("Placement_Dummy")
		for _, randomDummy in pairs(forceorbit) do
			randomDummy.Despawn()
		end
		local checkobject = Find_First_Object("Custom_GC_Starter_Dummy")
		if checkobject ~= nil then
			local startplanet = checkobject.Get_Planet_Location()
			local humaninfo = FTGU_Dummies[humanname]

			local infoobject = Find_First_Object(LocationType)
			if infoobject ~= nil then
				infoobject.Despawn()
			end
			infoobject = Find_First_Object(RosterType)
			if infoobject ~= nil then
				infoobject.Despawn()
			end
			infoobject = Find_First_Object(HeroType)
			if infoobject ~= nil then
				infoobject.Despawn()
			end
			infoobject = Find_First_Object(StartType)
			if infoobject ~= nil then
				infoobject.Despawn()
			end
			infoobject = Find_First_Object(PlanetModifier)
			if infoobject ~= nil then
				infoobject.Despawn()
			end
			infoobject = Find_First_Object("CUSTOM_GC_AI_TECH")
			if infoobject ~= nil then
				infoobject.Despawn()
			end
			
			for factionid, info in pairs(FTGU_Dummies) do
				if factionid ~= humanname then
					if info.Angry_AI_Dummy then
						local anger = Find_First_Object(info.Angry_AI_Dummy)
						local set_AI = false
						if anger ~= nil then
							if startplanet == anger.Get_Planet_Location() then
								set_AI = true
							end
							anger.Despawn()
						end
						
						if Shortcut or set_AI then
							crossplot:publish("OVERRIDE_AI_PLAYER","ALL_FACTIONS_AI", factionid, "GenericAI")
							crossplot:publish("OVERRIDE_AI_PLAYER","ALL_FACTIONS_CRUEL_AI", factionid, "SkynetAI")
							if info.Angry_AI_Types then
								for _, AI_Type in pairs(info.Angry_AI_Types) do
									crossplot:publish("OVERRIDE_AI_PLAYER",AI_Type, factionid, "GenericAI")
								end
							end
							if info.Angry_Skynet_Types then
								for _, AI_Type in pairs(info.Angry_Skynet_Types) do
									crossplot:publish("OVERRIDE_AI_PLAYER",AI_Type, factionid, "SkynetAI")
								end
							end
						end
					end
				end
			end
			
			if AI_Tech_Dummy_Spawn or HeroType == "CUSTOM_GC_HERO_ALL" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT" then
				local r2d2s = Find_All_Objects_Of_Type("Custom_GC_AI_Settings_Dummy")
				for factionid, info in pairs(FTGU_Dummies) do
					local dummies = Find_All_Objects_Of_Type(info.DummyUnit)
					local found_location = false
					
					for _, dummy in pairs(dummies) do
						local location = dummy.Get_Planet_Location()
						if startplanet ~= location then
							for _, ai_dummy in pairs(r2d2s) do
								if ai_dummy.Get_Planet_Location() == location then
									found_location = true
									AI_Settings_Locations[factionid] = location
									break
								end
							end
							if found_location then
								break
							end
						end
					end
				end
				for _, astro in pairs(r2d2s) do
					astro.Despawn()
				end
			end

			--Reset money after any nonsense with upkeep while the game was set up or sale of units
			humanfaction.Give_Money(8000 - humanfaction.Get_Credits())

			local altspawn = false
			local alttext = ""
			local altlist = {}

			if StartType == "CUSTOM_GC_SMALL_START" and HeroType == "CUSTOM_GC_HERO_DEFAULT" then
				local herolist = get_alt_heroes()
				if herolist ~= nil then
					local spawns = {}
					for idtext, lists in pairs(herolist) do
						local id_hero = lists[1]
						local heroestocheck = Find_All_Objects_Of_Type(id_hero)
						for _, hero in pairs(heroestocheck) do
							if not altspawn and hero.Get_Planet_Location() == startplanet then
								altspawn = true
								alttext = idtext
								altlist = lists
							end
							hero.Despawn()
						end
					end
				end
			end

			if HeroType == "CUSTOM_GC_HERO_FACTIONAL" or HeroType == "CUSTOM_GC_HERO_ALL" or HeroType == "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT" then
				local limit = 20

				local topick = {}
				for _, name in pairs(hero_lists[6]) do
					local setter = Find_First_Object(name)
					if setter then --if not sold
						local setterloc = setter.Get_Planet_Location()
						if setterloc ~= nil then
							for __, name2 in pairs(hero_lists[3]) do
								local ship = Find_First_Object(name2)
								if ship ~= nil then
									local shiploc = ship.Get_Planet_Location()
									if shiploc ~= nil and shiploc == setterloc then
										table.insert(topick, name2)
										local fighter_entry = Get_Hero_Entries(name)
										local Squadron = Get_Squadron_Name(fighter_entry, name)
										StoryUtil.ShowScreenText("Assigned " .. Squadron .. " to %s", 5, ship)
										Set_Fighter_Hero(Squadron, name2)
										break
									end
								else
									local squadron_check = Find_All_Objects_Of_Type(name2)
									if table.getn(squadron_check) <= 0 then --Squadrons will be detected with this, despite not being detected with Find_First_Object
										StoryUtil.ShowScreenText(name2 .. "Did not spawn. Panic! Then bother a dev", 20, nil, {r = 244, g = 244, b = 0})
									end
								end
							end

							for __, name2 in pairs(hero_lists[4]) do
								local ship = Find_First_Object(name2)
								if ship ~= nil then
									local shiploc = ship.Get_Planet_Location()
									if shiploc ~= nil and shiploc == setterloc then
										table.insert(topick, name2)
										local fighter_entry = Get_Hero_Entries(name)
										local Squadron = Get_Squadron_Name(fighter_entry, name)
										StoryUtil.ShowScreenText("Assigned " .. Squadron .. " to %s", 5, ship)
										Set_Fighter_Hero(Squadron, name2)
										break
									end
								else
									--SSDs probably aren't in squadrons
									StoryUtil.ShowScreenText(name2 .. "Did not spawn. Panic! Then bother a dev", 20, nil, {r = 244, g = 244, b = 0})
								end
							end
						end
						setter.Despawn()
					end
				end
				for _, name in pairs(topick) do
					local ship = Find_First_Object(name)
					if ship ~= nil then
						ship.Despawn()
						SpawnList({name},startplanet,humanfaction,true,false)
					end
				end
				for i=1,4 do
					for _, name in pairs(hero_lists[i]) do
						local heroestocheck = Find_All_Objects_Of_Type(name)
						for __, hero in pairs(heroestocheck) do
							local heroloc = hero.Get_Planet_Location()
							if limit > 0 and heroloc == startplanet then
								limit = limit - 1
							else
								for factionid, planet in pairs(AI_Settings_Locations) do
									if planet == heroloc then
										table.insert(AI_Picked_Heroes[factionid], name)
									end
								end
								hero.Despawn()
							end
						end
					end
				end
			end

			if HeroType == "CUSTOM_GC_HERO_FACTIONAL_RANDOM" or HeroType == "CUSTOM_GC_HERO_ALL_RANDOM" then
				for factionid, info in pairs(FTGU_Dummies) do
					if not info.Nonplayable then
						local targets = {0,0,0,0}

						local spawnlist = {}
						if StartType == "CUSTOM_GC_FTGU" then --A random hero of the three main types
							local heroindex = GameRandom.Free_Random(1, 3)
							targets[heroindex] = 1
						elseif StartType == "CUSTOM_GC_SMALL_START" then
							targets[1] = 1
							targets[2] = GameRandom.Free_Random(1, 2)
							targets[3] = GameRandom.Free_Random(1, 3)
						else --Full
							targets[1] = GameRandom.Free_Random(1, 3)
							targets[2] = GameRandom.Free_Random(2, 5)
							targets[3] = GameRandom.Free_Random(4, 7)
							if table.getn(hero_lists[4]) > 0 then
								local SSD_odds = 20
								targets[4] = GameRandom.Free_Random(1, SSD_odds)
								if targets[4] == SSD_odds then
									targets[4] = 1
									targets[3] = targets[3] - 2
								else
									targets[4] = 0
								end
							end
						end
						local total_target = targets[1] + targets[2] + targets[3] + targets[4]

						local workinglists = nil
						if HeroType == "CUSTOM_GC_HERO_FACTIONAL_RANDOM" then
							local factionobj = Find_Player(factionid)
							workinglists = {{},{},{},{},{},{}}
							for i=1,4 do
								for _, hero in pairs(hero_lists[i]) do
									local unittype = Find_Object_Type(hero)
									if unittype.Is_Affiliated_With(factionobj) or (hero_list_perfaction[factionid] and hero_list_perfaction[factionid][hero]) then
										table.insert(workinglists[i], hero)
									end
								end
							end
						else
							workinglists = hero_lists
						end
						while total_target > 0 do
							for i=1,4 do						
								if targets[i] > 0 then
									local listsize = table.getn(workinglists[i])
									if listsize == 0 then --If no heroes in this category, get another one in ground or space category instead
										targets[i] = targets[i] - 1
										if i >= 3 then
											if table.getn(workinglists[2]) > 0 then
												targets[2] = targets[2] + 1
											else
												total_target = total_target - 1 --Ground and space are empty, eco heroes are unlikely to still exist
											end
										else
											targets[i+1] = targets[i+1] + 1
										end
									else
										local choiceid = GameRandom.Free_Random(1, listsize)
										local choice = workinglists[i][choiceid]
										table.insert(spawnlist, choice)
										table.remove(workinglists[i], choiceid)
										if HeroType == "CUSTOM_GC_HERO_FACTIONAL_RANDOM" then
											local overid = 1
											for _, hero in pairs(hero_lists[i]) do
												if hero == choice then
													overid = _
													break
												end
											end
											table.remove(hero_lists[i], overid)
										end
										targets[i] = targets[i] - 1
										total_target = total_target - 1
									end
								end
							end
						end
						if factionid == humanname then
							SpawnList(spawnlist,startplanet,humanfaction,true,false)
						else
							AI_Picked_Heroes[factionid] = spawnlist
						end
					end
				end
			end

			for protfaction, protdata in pairs(Proteans) do
				local protchoice = nil
				factionlocs = {}
				for _, protname in pairs(protdata) do
					local protcheck = Find_First_Object(protname)
					if protcheck ~= nil then
						local protloc = protcheck.Get_Planet_Location()
						if protloc ~= nil then
							if protloc == startplanet then
								protchoice = protname
							else
								factionlocs[protloc.Get_Type().Get_Name()] = protname
							end
						end
						protcheck.Despawn()
					end
				end
				
				if not protchoice then
					factiondummies = Find_All_Objects_Of_Type(FTGU_Dummies[protfaction].DummyUnit)
					for _, dummy in pairs(factiondummies) do
						if dummy ~= nil then
							local protloc = dummy.Get_Planet_Location()
							if protloc ~= nil and protloc ~= startplanet then
								if factionlocs[protloc.Get_Type().Get_Name()] then
									protchoice = factionlocs[protloc.Get_Type().Get_Name()]
									break
								end
							end
						end
					end
				end

				if not protchoice then
					protchoice = protdata[GameRandom.Free_Random(1, table.getn(protdata))]
				end

				protchoice = string.gsub(protchoice, FTGU_Dummies[protfaction].Proteus_Prefix, "")

				local protchoicedata = require(FTGU_Dummies[protfaction].Proteus_Library)
				protchoicedata = protchoicedata[protchoice]
				Proteans[protfaction] = protchoicedata

				StoryUtil.ShowScreenText(protchoicedata.FriendlyName, 20, nil, {r = 244, g = 244, b = 0})

				if protchoicedata.LockList then
					UnitUtil.SetLockList(protfaction, get_array_per_era(protchoicedata.LockList), false)
				end
				if protchoicedata.UnlockList then
					UnitUtil.SetLockList(protfaction, get_array_per_era(protchoicedata.UnlockList))
				end

				GlobalValue.Set(FTGU_Dummies[protfaction].Proteus_Name_Variable, protchoicedata.FriendlyName)
				crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", protfaction, protchoicedata.FriendlyName)
				if protchoicedata.LeaderTable then
					crossplot:publish("INITIALIZE_PROTEUS_LEGITIMACY", protchoicedata.LeaderTable)
				end
				
				if protchoice == "WARLORD_CHOICE_KUAT" then
					crossplot:publish("PROTEUS_MARKET")
				end
			end
			
			local customname = require("../../CustomFactionName")
			if customname ~= "NoName" then
				crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", humanname, customname)
			end

			--Handle custom roster before any final spawns take place
			if RosterType == "CUSTOM_GC_RANDOM_ROSTER" or (AI_Tech_On and (RosterType == "CUSTOM_GC_RANDOM_MAPS" or RosterType == "CUSTOM_GC_LOOTBOX_ROSTER")) then
				for factionid, info in pairs(FTGU_Dummies) do
					if (factionid == humanname and RosterType == "CUSTOM_GC_RANDOM_ROSTER") or info.RosterUnits and (AI_Tech_On and factionid ~= humanname) then
						local totalobjects = table.getn(info.RosterUnits)
						local factionobj = Find_Player(factionid)
						local targetobjects = 0
						if RosterType == "CUSTOM_GC_LOOTBOX_ROSTER" then --For a more authentic lootbox experience, enable all units for AI
							targetobjects = totalobjects
						else
							for _, unit in pairs(info.RosterUnits) do
								if not (Find_Object_Type(unit).Is_Build_Locked(factionobj) or Find_Object_Type(unit).Is_Obsolete(factionobj)) then
									targetobjects = targetobjects + 1
								end
							end
						end
						for _, unit in pairs(info.RosterUnits) do
							techtype = Find_Object_Type(unit)
							if GameRandom.Free_Random(1, totalobjects) <= targetobjects then
								factionobj.Unlock_Tech(techtype)
							else
								factionobj.Lock_Tech(techtype)
							end
						end
					end
				end
			end
			if RosterType == "CUSTOM_GC_CUSTOM_ROSTER" or RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" or AI_Tech_Dummy_Spawn then
				local marketpush = {}
				for factionid, info in pairs(FTGU_Dummies) do
					if (factionid == humanname and RosterType ~= "CUSTOM_GC_MAPPED_ROSTER") or (AI_Tech_Dummy_Spawn and info.RosterUnits and AI_Settings_Locations[factionid]) then
						local techplanet = startplanet
						local factionobj = Find_Player(factionid)
						if AI_Settings_Locations[factionid] then
							techplanet = AI_Settings_Locations[factionid]
						end
						for _, unittype in pairs(info.RosterUnits) do
							local tech_keys = Find_All_Objects_Of_Type(unittype)
							local techtype = Find_Object_Type(unittype)
							local market = market_options[factionid][string.upper(unittype)]
							local tolock = true
							for __, tech_key in pairs(tech_keys) do
								if tech_key.Get_Planet_Location() == techplanet then
									if market then
										table.insert(marketpush, {string.upper(factionid),market,string.upper(unittype),9999,false})
									else
										factionobj.Unlock_Tech(techtype)
									end
									tolock = false
								end
							end
							if tolock and RosterType ~= "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" and market == nil then
								factionobj.Lock_Tech(techtype)
							end
						end
					end
				end

				if table.getn(marketpush) then
					crossplot:publish("ADJUST_MARKET_AMOUNT", marketpush)
				end
			end
			if RosterType == "CUSTOM_GC_MAPPED_ROSTER" or RosterType == "CUSTOM_GC_RANDOM_MAPS" or RosterType == "CUSTOM_GC_LOOTBOX_ROSTER" then
				local marketpush = {}
				--Mapped roster
				local plot = Get_Story_Plot("Conquests\\Custom\\Story_Custom_Container.xml")
				local event = plot.Get_Event("FtGU_Intro_Dialog_Chapter_2")
				event.Clear_Dialog_Text()
				event.Add_Dialog_Text("Units in the left column will be replaced with the right column when constructed")

				local mapping = Get_Roster_Mapping()
				local bases = humaninfo.RosterMapBases
				local sources = {}
				local destinations = {}

				--Lock all basic units
				for _, unittype in pairs(humaninfo.RosterUnits) do
					local market = market_options[humanname][string.upper(unittype)]
					if market == nil then
						humanfaction.Lock_Tech(Find_Object_Type(unittype))
					end
				end

				if humaninfo.UnmappedRoster ~= nil then
					for _, simple in humaninfo.UnmappedRoster do
						if RosterType == "CUSTOM_GC_RANDOM_MAPS" then
							local market = market_options[humanname][string.upper(simple)]
							if market then
								table.insert(marketpush, {string.upper(humanname),market,string.upper(simple),9999,false})
							else
								humanfaction.Unlock_Tech(Find_Object_Type(simple))
							end
						else
							local tech_keys = Find_All_Objects_Of_Type(simple)
							local techtype = Find_Object_Type(simple)

							for _, tech_key in pairs(tech_keys) do
								if tech_key.Get_Planet_Location() == startplanet then
									local market = market_options[humanname][string.upper(simple)]
									if market then
										table.insert(marketpush, {string.upper(humanname),market,string.upper(simple),9999,false})
									else
										humanfaction.Unlock_Tech(techtype)
									end
								end
								tech_key.Despawn()
							end
						end
					end
				end

				if RosterType == "CUSTOM_GC_LOOTBOX_ROSTER" then
					for _, map_definition in pairs(mapping) do
						--Grab the first base unit from every pool and assign the whole pool to it. Don't bother documenting that everything is a lootbox
						local source = bases[map_definition[1][1]]
						if source then
							local market = market_options[humanname][string.upper(source)]
							if market then
								table.insert(marketpush, {string.upper(humanname),market,string.upper(source),9999,false})
							else
								humanfaction.Unlock_Tech(Find_Object_Type(source))
							end
							table.insert(sources, string.upper(source))
							local dest = {}
							for ___, real_dummy in pairs(map_definition[2]) do
								table.insert(dest, string.upper(real_dummy))
							end
							table.insert(destinations, dest)
						end
					end
				elseif RosterType == "CUSTOM_GC_RANDOM_MAPS" then
					for _, map_definition in pairs(mapping) do
						for __, map_dummy in pairs(map_definition[1]) do
							local source = bases[map_dummy]
							if source then
								local market = market_options[humanname][string.upper(source)]
								if market then
									table.insert(marketpush, {string.upper(humanname),market,string.upper(source),9999,false})
								else
									humanfaction.Unlock_Tech(Find_Object_Type(source))
								end
								local rando = GameRandom.Free_Random(1, table.getn(map_definition[2]))
								local dest = map_definition[2][rando]
								event.Add_Dialog_Text(string.gsub(string.format("%-50s",source) .. dest, " ", "_")) --Do list that objects got randomly mapped to themselves even though this is not done for manual choices
								if source ~= dest then
									table.insert(sources, string.upper(source))
									table.insert(destinations, string.upper(dest))
								end
							end
						end
					end
				else
					local randoms = Find_All_Objects_Of_Type("Custom_GC_Random_Unit_Dummy")

					for _, map_definition in pairs(mapping) do
						for __, map_dummy in pairs(map_definition[1]) do
							local default = nil
							local dummyunit = Find_First_Object(map_dummy)
							if dummyunit ~= nil then
								local maplocale = dummyunit.Get_Planet_Location()
								if bases[map_dummy] then
									default = bases[map_dummy]
								end
								local mapped = false
								local source = nil
								local dest = nil
								local randommapped = false

								for ___, rando in pairs(randoms) do
									if rando.Get_Planet_Location() == maplocale then
										randommapped = true
										mapped = true
										dest = {}
										break
									end
								end

								for ___, real_dummy in pairs(map_definition[2]) do
									local unittype = Find_Object_Type(real_dummy)
									if unittype == nil then
										StoryUtil.ShowScreenText(real_dummy .. " does not exist. Complain to the devs", 20, nil, {r = 244, g = 244, b = 0})
									end
									if mapped == false or default == real_dummy or randommapped then
										local bases = nil
										if map_definition[3] ~= nil then
											bases = Find_All_Objects_Of_Type(map_definition[3][___])
										else
											bases = Find_All_Objects_Of_Type(real_dummy)
										end

										for _, base in pairs(bases) do
											if base.Get_Planet_Location() == maplocale then
												source = default
												if randommapped then
													table.insert(dest, string.upper(real_dummy))
												else
													dest = real_dummy
													mapped = true
													break
												end
											end
										end
									end
								end
								if mapped then
									local market = market_options[humanname][string.upper(source)]
									if market then
										if source ~= dest then --Only demarket if mapped. Power users can random map to a list of itself to circumvent
											table.insert(marketpush, {string.upper(humanname),market,string.upper(source),9999,false})
										end
									else
										humanfaction.Unlock_Tech(Find_Object_Type(source))
									end
									if source ~= dest then
										table.insert(sources, string.upper(source))

										if randommapped then
											table.insert(destinations, dest)
											event.Add_Dialog_Text(string.gsub(string.format("%-50s",source) .. "Randomized list (" .. tostring(table.getn(dest)) .. " units)", " ", "_"))
										else
											table.insert(destinations, string.upper(dest))
											event.Add_Dialog_Text(string.gsub(string.format("%-50s",source) .. dest, " ", "_"))
										end
									end
								end
							end
						end
					end
					--clean up dummies
					for _, map_definition in pairs(mapping) do
						for __, map_dummy in pairs(map_definition[1]) do
							UnitUtil.DespawnCompany(map_dummy)
							for ___, real_dummy in pairs(map_definition[2]) do
								UnitUtil.DespawnCompany(real_dummy)
							end
						end
					end
					for _, base in pairs(bases) do
						UnitUtil.DespawnCompany(base)
					end
					for _, rando in pairs(randoms) do
						rando.Despawn()
					end
				end
				GlobalValue.Set("ROSTER_MAPPING_SRC", sources)
				GlobalValue.Set("ROSTER_MAPPING_DEST", destinations)
				humanfaction.Unlock_Tech(Find_Object_Type("Option_Factional_Fighters"))
				if table.getn(marketpush) then
					crossplot:publish("ADJUST_MARKET_AMOUNT", marketpush)
				end
			end

			if RosterType == "CUSTOM_GC_CUSTOM_ROSTER" or RosterType == "CUSTOM_GC_CUSTOM_ROSTER_ENABLE" or AI_Tech_Dummy_Spawn then
				for factionid, info in pairs(FTGU_Dummies) do
					if factionid == humanname or (AI_Tech_Dummy_Spawn and info.RosterUnits) then
						for _, unittype in pairs(info.RosterUnits) do
							local tech_keys = Find_All_Objects_Of_Type(unittype)
							for __, tech_key in pairs(tech_keys) do
								UnitUtil.DespawnCompany(unittype)
							end
						end
					end
				end
			end

			checkobject.Despawn()
			spawn_human_start(startplanet, true)

			if PlanetModifier == "CUSTOM_GC_PLAYER_OBSERVER" then
				local allPlanets = FindPlanet.Get_All_Planets()
				for _, planet in pairs(allPlanets) do
					if planet ~= startplanet then --It's not ideal to defeat the player
						local path = Find_Path(humanfaction, startplanet, planet)
						if table.getn(path) <= 2 then
							ChangePlanetOwnerAndPopulate(planet, Find_Player("Independent_Forces"), 50000)
							local name = string.upper(planet.Get_Type().Get_Name())
							StoryUtil.SetPlanetRestricted(name, 1)
						end
					end
				end
			end

			local observerEverywhere = true
			if LocationType == "CUSTOM_GC_PICK_EVERYWHERE" then
				if StartType == "CUSTOM_GC_SMALL_START" and (HeroType == "CUSTOM_GC_HERO_DEFAULT" or HeroType == "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT") then
					if altspawn then
						StoryUtil.ShowScreenText("Selected alternate hero set " .. alttext, 10, nil, {r = 50, g = 244, b = 0})
						SpawnList(altlist,startplanet,humanfaction,true,false)
						crossplot:publish("CUSTOM_ALTSMALL", alttext)
					else
						spawn_small_heroes(humaninfo,startplanet,humanfaction,humanname)
					end
				end
				local caps = Find_All_Objects_Of_Type("Custom_GC_Capital")
				for _, cap in pairs(caps) do
					if cap.Get_Planet_Location() == startplanet then
						cap.Despawn()
					end
				end

				local observerlist = {}
				local allPlanets = FindPlanet.Get_All_Planets()
				for _, planet in pairs(allPlanets) do
					if planet ~= startplanet then
						local path = Find_Path(humanfaction, startplanet, planet)
						if table.getn(path) <= 2 then
							table.insert(observerlist, planet.Get_Type().Get_Name())
						end
					end
				end
				local locks = Find_All_Objects_Of_Type("Custom_GC_Planet_Lock")
				for _, lock in pairs(locks) do
					local loc = lock.Get_Planet_Location()
					if loc ~= nil and loc ~= startplanet then
						local planetname = loc.Get_Type().Get_Name()
						StoryUtil.SetPlanetRestricted(planetname, 1)
						for id, observe in pairs(observerlist) do
							if observe == planetname then
								table.remove(observerlist, id)
							end
						end
					end
					lock.Despawn()
				end
				local destructions = Find_All_Objects_Of_Type("Custom_GC_Planet_Destroy")
				for _, destruction in pairs(destructions) do
					local destroy = destruction.Get_Planet_Location()
					if destroy ~= nil and destroy ~= startplanet then
						Destroy_Planet(destroy.Get_Type().Get_Name())
					end
					destruction.Despawn()
				end
				if table.getn(observerlist) > 0 then
					observerEverywhere = false
				end
				for factionid, info in pairs(FTGU_Dummies) do
					local player = Find_Player(factionid)
					local factionDummies = Find_All_Objects_Of_Type(info.DummyUnit)
					local smallhero = 0
					local breakobserver = false
					if player == humanfaction then
						smallhero = 2
						breakobserver = true
					end

					for _, dummy in pairs(factionDummies) do
						local planet = dummy.Get_Planet_Location()
						if planet ~= nil then
							if planet.Get_Owner() == Find_Player("Neutral") then
								if breakobserver then
									observerEverywhere = false
								end
								caps = Find_All_Objects_Of_Type("Custom_GC_Capital")
								local frnocap = nil
								for _, cap in pairs(caps) do
									if cap.Get_Planet_Location() == planet then
										frnocap = info.Capital
										cap.Despawn()
										smallhero = smallhero + 1
										break
									end
								end
								populate_planet(planet,player,frnocap)
								if smallhero == 1 then
									if StartType == "CUSTOM_GC_SMALL_START" then
										spawn_small_heroes(info,planet,player,factionid)
									end
									smallhero = smallhero + 1
								else
									if frnocap ~= nil then
										player.Give_Money(8000)
									end
								end
							end
						end
						dummy.Despawn()
					end
				end

				caps = Find_All_Objects_Of_Type("Custom_GC_Capital")
				for _, cap in pairs(caps) do
					cap.Despawn()
				end
			else
				observerEverywhere = false
				local selected_factions = {humanname}
				local unselected_factions = {}
				local FTGU_starts = {}

				for factionid, info in pairs(FTGU_Dummies) do
					if factionid ~= humanname then
						local dummies = Find_All_Objects_Of_Type(info.DummyUnit)
						local spawnlocation = startplanet
						local picked = false
						for _, dummy in pairs(dummies) do
							if dummy ~= nil then
								checklocation = dummy.Get_Planet_Location()
								dummy.Despawn()

								if not picked then
									if LocationType == "CUSTOM_GC_PICK_LOCATION" then
										if checklocation == startplanet or AI_Settings_Locations[factionid] then
											picked = true
											spawnlocation = find_distant_neutral_planet(startplanet)
										end
									elseif LocationType == "CUSTOM_GC_PICK_ENEMY_LOCATION" then
										if checklocation ~= nil then --Apparently changing ownership under a dummy can put it in the shadow realm
											if checklocation.Get_Owner() == Find_Player("Neutral") then
												spawnlocation = checklocation
												picked = true
											end
										end
									end
								end
							end
						end

						if picked then
							local faction = Find_Player(factionid)
							table.insert(selected_factions, factionid)
							populate_planet(spawnlocation,faction,FTGU_Dummies[factionid].Capital)
							if StartType == "CUSTOM_GC_FTGU" then
								FTGU_starts[factionid] = spawnlocation
							end
							Sleep(0.001)
						else --If not picked add to rando pool unless it's nonplayable, flagged as an ally for your faction, or deleted. Unless it doesn't exist because this is a roguelike
							if not (FTGU_Dummies[factionid].Nonplayable or FTGU_Dummies[factionid].Ally == humanname or (not Shortcut and table.getn(dummies) == 0)) then
								table.insert(unselected_factions, factionid)
							end
						end
					end
				end

				local randomDummies = Find_All_Objects_Of_Type("Custom_GC_Random_Dummy")
				for _, randomDummy in pairs(randomDummies) do
					local checklocation = randomDummy.Get_Planet_Location()
					randomDummy.Despawn()

					local add_random = false
					if LocationType == "CUSTOM_GC_PICK_LOCATION" then
						if checklocation == startplanet then
							add_random = true
							checklocation = find_distant_neutral_planet(startplanet)
						end
					elseif LocationType == "CUSTOM_GC_PICK_ENEMY_LOCATION" then
						if checklocation ~= nil then
							if checklocation.Get_Owner() == Find_Player("Neutral") then
								add_random = true
							end
						end
					end

					if add_random then
						CONSTANTS = ModContentLoader.get("GameConstants")
						
						local options = table.getn(unselected_factions)
						if options > 0 then
							local uns = GameRandom.Free_Random(1, options)
							local factionid = unselected_factions[uns]
							StoryUtil.ShowScreenText("Selected random enemy: " .. factionid, 10, nil, CONSTANTS.FACTION_COLORS[factionid])
							local faction = Find_Player(factionid)
							table.insert(selected_factions, factionid)
							populate_planet(checklocation,faction,FTGU_Dummies[factionid].Capital)
							if StartType == "CUSTOM_GC_FTGU" then
								FTGU_starts[factionid] = checklocation
							end
							table.remove(unselected_factions, uns)
							Sleep(0.001)
						end
					end
				end

				if StartType == "CUSTOM_GC_FTGU" then
					for factionid, location in pairs(FTGU_starts) do
						local faction = Find_Player(factionid)
						FTGU_Enemy_Start(location,faction,startplanet)
					end
				else
					spawn_connected_territory(selected_factions,altspawn,altlist,alttext)
				end
			end

			spawn_IF(startplanet)
			spawn_full_heroes()
			spawn_AI_picked_heroes()

			if observerEverywhere or PlanetModifier == "CUSTOM_GC_PLAYER_OBSERVER" then
				StoryUtil.SpawnAtSafePlanet(nil,Find_Player("local"),{},{"Cheat_Dummy_Vision"},true,false)
			end
			
			crossplot:publish("COMMAND_STAFF_CENSUS", "empty")
			
			--Free up some memory that is no longer needed
			Bordering_Planets_List = nil
			Connected_Starting_Planet_List = nil
			hero_lists = nil
			market_options = nil
			Proteans = nil
			Protean_Tech = nil
			AI_Picked_Heroes = nil
			AI_Settings_Locations = nil
			hero_list_perfaction = nil
		end
	else
		crossplot:update()
	end
end

function FTGU_Enemy_Start(ai_start,ai_faction,human_start)
	local disjoint = GameRandom.Free_Random(1, 2)
	if disjoint == 2 then
		disjoint = true
	else
		disjoint = false
	end

	local next_planet = find_connected_neutral_planet(ai_start,ai_faction)
	if next_planet == nil then
		next_planet = find_Neutral_planet(true)
	end
	populate_planet(next_planet,ai_faction,nil)
	next_planet = find_connected_neutral_planet(ai_start,ai_faction)
	if next_planet == nil then
		next_planet = find_Neutral_planet(true)
	end
	populate_planet(next_planet,ai_faction,nil)
	if disjoint then
		next_planet = find_double_distant_neutral_planet(ai_start,human_start)
		populate_planet(next_planet,ai_faction,nil)
		local last_planet = find_connected_neutral_planet(next_planet,ai_faction)
		if last_planet == nil then
			last_planet = find_Neutral_planet(true)
		end
		populate_planet(last_planet,ai_faction,nil)
	else
		next_planet = find_connected_neutral_planet(ai_start,ai_faction)
		if next_planet == nil then
			next_planet = find_Neutral_planet(true)
		end
		populate_planet(next_planet,ai_faction,nil)
	end
end

function spawn_connected_territory(faction_list,altspawn,altlist,alttext)
	local planetcount =  table.getn(FindPlanet.Get_All_Planets())
	local factiontable = {}
	local perceptable = {}
	local planetstodo = {}
	local faction_modifier = 0
	local planet_multiplier = 1
	factioncount = table.getn(faction_list)
	if PlanetModifier == "CUSTOM_GC_PLAYER_EXTRA" then
		faction_modifier = 0.5
		planet_multiplier = 1.5
	elseif PlanetModifier == "CUSTOM_GC_PLAYER_HALF" then
		faction_modifier = -0.5
		planet_multiplier = 0.5
	elseif PlanetModifier == "CUSTOM_GC_PLAYER_FTGU_EXTREME" or PlanetModifier == "CUSTOM_GC_PLAYER_OBSERVER" then
		faction_modifier = -1
		planet_multiplier = 0
	end

	local planetsperplayer = 0
	if factioncount+faction_modifier > 0 then
		planetsperplayer = planetcount / (factioncount+faction_modifier) / 1.1 - 1 --Minus one for the starting planet
	end

	if StartType == "CUSTOM_GC_SMALL_START" and planetsperplayer > 5 then
		planetsperplayer = 5
	end

	for _, factionid in pairs(faction_list) do
		local factionobject = Find_Player(factionid)
		table.insert(factiontable,factionobject)
		table.insert(perceptable,FTGU_Dummies[factionid].Perception)
		table.insert(planetstodo,planetsperplayer)

		if StartType == "CUSTOM_GC_SMALL_START" then
			local data = FTGU_Dummies[factionid]
			local capitals = Find_All_Objects_Of_Type(data.Capital)
			local capital = nil
			for n, cap in pairs(capitals) do --handle factions with duplicate capitals
				if cap.Get_Owner() == factionobject then
					capital = cap
					break
				end
			end

			if (factionobject ~= humanfaction or HeroType == "CUSTOM_GC_HERO_DEFAULT" or HeroType == "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT") and capital ~= nil then
				if factionobject == humanfaction and altspawn then
					StoryUtil.ShowScreenText("Selected alternate hero set " .. alttext, 10, nil, {r = 50, g = 244, b = 0})
					SpawnList(altlist,capital.Get_Planet_Location(),humanfaction,true,false)
					crossplot:publish("CUSTOM_ALTSMALL", alttext)
				else
					spawn_small_heroes(data,capital.Get_Planet_Location(),factionobject,factionid)
				end
			end
		end
	end
	planetstodo[1] = (planetstodo[1] + 1) * planet_multiplier - 1 --Strange addition compensates for the starting planet not being included in the planets to do

	Bordering_Planets_List = FindPlanet.Get_All_Planets()

	local maxtodo = planetsperplayer

	for __=1,3 do --If the perceptions fail, try again a few times
		for planet=1,maxtodo do
			for i, faction in pairs(factiontable) do
				if planetstodo[i] > 0.99 then
					local newplanet = find_bordering_neutral_planet(faction, perceptable[i])
					if newplanet ~= nil then
						planetstodo[i] = planetstodo[i] - 1
						populate_planet(newplanet, faction, nil)
					end
				end
			end
			Sleep(0.001) --This not only looks cool to see the slow fill in, but helps the perceptions not randomly fail
		end
		maxtodo = 0
		for _, count in pairs(planetstodo) do
			if count > maxtodo then
				maxtodo = count
			end
		end
	end

	--Fill out anything that still failed or was boxed in and had no valid spots
	for planet=1,maxtodo do
		for i, faction in pairs(factiontable) do
			if planetstodo[i] > 0.99 then
				local newplanet = find_Neutral_planet(true)
				if newplanet ~= nil then
					planetstodo[i] = planetstodo[i] - 1
					populate_planet(newplanet, faction, nil)
				end
			end
		end
	end
end

function get_array_per_era(array)
	if type(array[1]) == "table" then
		local year = GlobalValue.Get("GALACTIC_YEAR")
		if year == nil then
			year = 1.0
		end

		local corenne = array[1]
		local maxevent = 0 --The order of evaluation is not guaranteed
		for event, data in pairs(array) do
			if year >= event and event > maxevent then
				maxevent = event
				corenne = data
			end
		end
		return corenne
	else
		return array
	end
end

function spawn_small_heroes(data,location,player,playername)
	if HeroType == "CUSTOM_GC_HERO_FACTIONAL_RANDOM" or HeroType == "CUSTOM_GC_HERO_ALL_RANDOM" or HeroType == "CUSTOM_GC_HERO_NONE" then
		return
	end
	if not (AI_Settings_Locations[playername] and HeroType == "CUSTOM_GC_HERO_ALL") and data.SmallHero then
		local heroes = {}

		if Proteans[playername] then
			heroes = get_array_per_era(Proteans[playername].HeroList)
		else
			local index = StartingEra
			if data.AlternateEraControl then
				index = GlobalValue.Get("SELECTED_REGIME")
			end
			heroes = data.SmallHero[index]
			if heroes == nil then
				heroes = data.SmallHero[1]
			end
			if type(heroes) == "number" then
				heroes = data.SmallHero[heroes]
			end
		end
		SpawnList(heroes,location,player,true,false)
	end
end

function get_alt_heroes()
	local humaninfo = FTGU_Dummies[humanname].AltSmall
	if humaninfo ~= nil then
		if type(humaninfo) == "string" then
			humaninfo = FTGU_Dummies[humaninfo].AltSmall
		end
	end
	return humaninfo
end

function get_hero_lists(all_factions)
	local full_list = require("HeroFreeStorePlacements")
	local library = require("HeroLibrary")
	local persistent_damage_library = require("hardpoint-lists/PersistentDamageLibrary")
	local fighters = Get_Hero_Entries()
	local exclusions = Get_Excluded_Heroes()
	local SSD_list = persistent_damage_library[1]
	local humanhero = {}
	
	--Read assorted Lua lists to find heroes associated with factions since space heroes had affiliations stripped for performance
	--Modify return list if picking factional heroes, save all finds to pass to the random function for random factional heroes
	if (not all_factions) or HeroType == "CUSTOM_GC_HERO_FACTIONAL_RANDOM" then
		local prefix, ProgSpawns = Get_Full_Hero_File(0)
		for factionid, info in pairs(FTGU_Dummies) do
			hero_list_perfaction[factionid] = {} --Make sure the list exists so it can be assumed later (mostly)
			
			if info.AffilatedHeroes then
				for _, hero in pairs(info.AffilatedHeroes) do
					if (not all_factions) then
						if factionid == humanname then
							humanhero[string.upper(hero)] = true
						end
					else
						hero_list_perfaction[factionid][string.upper(hero)] = true
					end
				end
			end
			
			local regimefile = false
			if info.RegimeSet then
				regimefile = info.RegimeSet
			end
			
			local secondaryregime = false
			if info.BlockingFighterFaction then
				if FTGU_Dummies[info.BlockingFighterFaction].RegimeSet then
					regimefile = FTGU_Dummies[info.BlockingFighterFaction].RegimeSet
					secondaryregime = true
				end
			end
			
			local blockedregimes = {
				["PESTAGE"] = true,
				["ISARD"] = true,
				["CCOGM"] = true,
				["THRAWN"] = true,
			}
			
			if regimefile then
				local Starting_Spawns = require(regimefile)
				for leader, regime in pairs(Starting_Spawns) do
					if not (secondaryregime and blockedregimes[leader]) then
						for planet, herolist in pairs(regime) do
							for _, hero_table in pairs(herolist) do
								if (not all_factions) then
									if factionid == humanname then
										humanhero[string.upper(hero_table.object)] = true
									end
								else
									hero_list_perfaction[factionid][string.upper(hero_table.object)] = true
								end
							end
						end
					end
				end
			end
			
			--Include all possible Proteus hero spawns. Can skip in factional pick when not playing them
			if info.Proteus_Library and (all_factions or factionid == humanname) then
				local proteus_lib = require(info.Proteus_Library)
				for protname, protdata in pairs(proteus_lib) do
					if protdata.HeroList then
						for _, hero in pairs(protdata.HeroList) do
							if type(hero) == "table" then
								for __, actualhero in pairs(hero) do
									if (not all_factions) then
										humanhero[string.upper(actualhero)] = true
									else
										hero_list_perfaction[factionid][string.upper(actualhero)] = true
									end
								end
							else
								if (not all_factions) then
									humanhero[string.upper(hero)] = true
								else
									hero_list_perfaction[factionid][string.upper(hero)] = true
								end
							end
						end
					end
				end
			end
		end
		
		--Parse progressive spawn sets
		for _, file in pairs(ProgSpawns) do
			if file ~= nil then
				local Starting_Spawns = require(prefix .. file)
				for faction, herolist in pairs(Starting_Spawns) do
					for planet, spawnlist in pairs(herolist) do
						for __, Hero in pairs(spawnlist) do
							if (not all_factions) then
								if faction == humanname then
									humanhero[string.upper(Hero)] = true
								end
							else
								if hero_list_perfaction[faction] == nil then --Need to not kill the script when non-library factions are in prog spawns (that is: Independent Forces and maybe some other edge cases)
									hero_list_perfaction[faction] = {}
								end
								hero_list_perfaction[faction][string.upper(Hero)] = true
							end
						end
					end
				end
			end
		end
		
		--Read upgrade/spawn dummies for hero upgrades (includes most SSD heroes), legitimacy, corporate hires... assume affiliations of heroes should follow the dummy that spawns them
		local A = require("UnitSwitcherLibrary")
		local B = require("UnitSwitcherMap")
		local switcher = {}
		for k, v in pairs(A) do
			switcher[k] = v
		end
		for k, v in pairs(B) do
			switcher[k] = v
		end

		for dummy, dummylist in pairs(switcher) do
			local dummytype = Find_Object_Type(dummy)
			if dummytype == nil then
				StoryUtil.ShowScreenText(dummy .. " does not exist. The upgrade cannot stand", 20, nil, {r = 244, g = 244, b = 0})
			else
				local objectlist = {}
				local heroestoadd = {}
				if dummylist[1] == nil then
					objectlist = dummylist[2]
				else
					objectlist = dummylist
				end
				--Check if objects are heroes, as many generic units are also in this library
				for _, object in pairs(objectlist) do
					local truth = object == true --The syntax checker doesn't like "not (object == true)", but object ~= true does not function. Need to compare actual equality with true, not the general truthiness
					if not truth then --Ignore some metadata where the index is important rather than the data
						local case = string.upper(object)
						if full_list[case] then
							table.insert(heroestoadd, case)
						end
					end
				end
				
				for factionid, info in pairs(FTGU_Dummies) do
					local player = Find_Player(factionid)
					if dummytype.Is_Affiliated_With(player) then
						for _, hero in pairs(heroestoadd) do
							if (not all_factions) then
								if factionid == humanname then
									humanhero[hero] = true
								end
							else
								hero_list_perfaction[factionid][hero] = true
							end
						end
					end
				end
			end
		end
		
		local favor = require("FavourRewards")
		for faction, factiondata in pairs(favor) do
			for subfaction, subfactiondata in pairs(factiondata) do
				if subfactiondata.spawned_rewards then
					for hero, dontcare in pairs(subfactiondata.spawned_rewards) do
						if (not all_factions) then
							if faction == humanname then
								humanhero[hero] = true
							end
						else
							hero_list_perfaction[faction][hero] = true
						end
					end
				end
			end
		end
		
		local hosts = Get_Hero_Entries()
		for setter, fighterdata in pairs(hosts) do
			if fighterdata.Options then
				for host, hostdata in pairs(fighterdata.Options) do
					if hostdata.Locations then
						local settertype = Find_Object_Type(setter)
						if settertype == nil then
							StoryUtil.ShowScreenText(setter .. " does not exist. So say we all", 20, nil, {r = 244, g = 244, b = 0})
						else
							for factionid, info in pairs(FTGU_Dummies) do
								local player = Find_Player(factionid)
								local blocked = false
								if info.BlockingFighterFaction then
									local blocker = Find_Player(info.BlockingFighterFaction)
									if settertype.Is_Affiliated_With(blocker) then
										blocked = true
									end
								end
								if (not blocked) and settertype.Is_Affiliated_With(player) then
									for _, hero in pairs(hostdata.Locations) do
										if (not all_factions) then
											if factionid == humanname then
												humanhero[hero] = true
											end
										else
											hero_list_perfaction[factionid][hero] = true
										end
									end
								end
							end
						end
					end
				end
			end
		end
		
	end
	
	for name, data in pairs(full_list) do
		if not exclusions[name] then
			local perception = data[1]
			local space = data[2]
			local ok = all_factions
			local unittype = Find_Object_Type(name)
			if unittype == nil then
				StoryUtil.ShowScreenText(name .. " does not exist. Complain to the devs", 20, nil, {r = 244, g = 244, b = 0})
				ok = false
			else
				if not all_factions then
					ok = unittype.Is_Affiliated_With(humanfaction)
					if humanhero[name] then
						ok = true
					end
				end
			end

			if perception ~= "Is_Convoy_Planet" and ok then
				local admincat = false
				local infcat = false
				if library[name] then
					if library[name].Company_Units then
						for __, unit in pairs(library[name].Company_Units) do
							if unit.CategoryMask then
								for ___, mask in pairs(unit.CategoryMask) do
									if mask == "NONCOMBATHERO" then
										admincat = true
										break
									end
									if mask == "INFANTRYHERO" then
										infcat = true
										break
									end
								end
							end
						end
					end
				end
				if SSD_list[name] ~= nil then
					table.insert(hero_lists[4], name)
				elseif perception == "Is_Production_Planet" or admincat then
					if space then
						table.insert(hero_lists[5], name)
					else
						table.insert(hero_lists[1], name)
					end
				elseif space then
					table.insert(hero_lists[3], name)
				else
					if infcat then
						table.insert(hero_lists[2], name)
					else
						table.insert(hero_lists[7], name)
					end
				end
			end
		end
	end

	for name, data in pairs(fighters) do
		local ok = all_factions
		if not ok then
			local unittype = Find_Object_Type(name)
			if unittype == nil then
				if data.Hero_Squadron then --If this doesn't exist it's a no rebuilding Brashin style and the unit is not supposed to exist
					StoryUtil.ShowScreenText(name .. " does not exist. Complain to the devs", 20, nil, {r = 244, g = 244, b = 0})
				end
			else
				ok = unittype.Is_Affiliated_With(humanfaction)
			end
		end

		if ok and data.Hero_Squadron then
			table.insert(hero_lists[6], name)
		end
	end
end

function spawn_AI_picked_heroes()
	if HeroType ~= "CUSTOM_GC_HERO_FACTIONAL" and HeroType ~= "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" then --Only do special hero spawns for the player in this mode
		local safes = StoryUtil.GetSafePlanetTable()
		for pickedFaction, _ in pairs(AI_Picked_Heroes) do
			local picked = Find_Player(pickedFaction)
			local capital = nil
			if AI_Settings_Locations[pickedFaction] then
				capital = AI_Settings_Locations[pickedFaction].Get_Type().Get_Name()
			end
			if FTGU_Dummies[pickedFaction].Capital then
				local capitals = Find_All_Objects_Of_Type(FTGU_Dummies[pickedFaction].Capital)
				for n, cap in pairs(capitals) do --handle factions with duplicate capitals
					if cap.Get_Owner() == picked then
						capital = string.upper(cap.Get_Planet_Location().Get_Type().Get_Name())
						break
					end
				end
			end
			
			StoryUtil.SpawnAtSafePlanet(capital, picked, safes, AI_Picked_Heroes[pickedFaction])
		end
	end
end

function spawn_full_heroes()
	if StartType == "CUSTOM_GC_FULL_START" then
		crossplot:publish("CUSTOM_FULL_HEROES",HeroType ~= "CUSTOM_GC_HERO_DEFAULT" and HeroType ~= "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" and HeroType ~= "CUSTOM_GC_HERO_ALL_DEFAULT")
		if HeroType == "CUSTOM_GC_HERO_FACTIONAL_RANDOM" or HeroType == "CUSTOM_GC_HERO_ALL_RANDOM" or HeroType == "CUSTOM_GC_HERO_NONE" then
			return
		end

		local safes = StoryUtil.GetSafePlanetTable()
		local file = Get_Full_Hero_File(StartingEra)

		if file ~= nil then
			local Starting_Spawns = require(file)
			for faction, herolist in pairs(Starting_Spawns) do
				local factionobj = Find_Player(faction)
				if HeroType == "CUSTOM_GC_HERO_DEFAULT" or HeroType == "CUSTOM_GC_HERO_FACTIONAL_DEFAULT" or HeroType == "CUSTOM_GC_HERO_ALL_DEFAULT" or (factionobj ~= humanfaction and (not (AI_Settings_Locations[faction] and HeroType == "CUSTOM_GC_HERO_ALL"))) then
					for planet, spawnlist in pairs(herolist) do
						StoryUtil.SpawnAtSafePlanet(planet, factionobj, safes, spawnlist)
					end
				end
			end
		end

		for protfaction, protdata in pairs(Proteans) do
			if not (AI_Settings_Locations[protfaction] and HeroType == "CUSTOM_GC_HERO_ALL") then
				local Capital = Find_First_Object(FTGU_Dummies[protfaction].Capital)
				if Capital ~= nil then --This strongly correlates with being on the map. The exception is pick everywhere without a capital, which doesn't trigger hero spawns in a small start and we'll generalize that to here
					if protdata.RemoveList then
						for _, hero in pairs(get_array_per_era(protdata.RemoveList)) do
							local exists = Find_All_Objects_Of_Type(hero)
							for __, object in pairs(exists) do
								if HeroType == "CUSTOM_GC_HERO_DEFAULT" or object.Get_Owner() ~= humanfaction then
									UnitUtil.DespawnCompany(hero)
								end
							end
						end
					end

					if protdata.HeroList then
						for _, hero in pairs(get_array_per_era(protdata.HeroList)) do
							local exists = Find_All_Objects_Of_Type(hero)
							for __, object in pairs(exists) do
								if HeroType == "CUSTOM_GC_HERO_DEFAULT" or object.Get_Owner() ~= humanfaction then
									UnitUtil.DespawnCompany(hero)
								end
							end
						end
						StoryUtil.SpawnAtSafePlanet(nil,Find_Player(protfaction),safes,get_array_per_era(protdata.HeroList),true,false)
					end
				end
			end
		end
	end
end

function spawn_human_start(start_planet, preowned)
	local humaninfo = FTGU_Dummies[humanname]

	if preowned then --If the planet is owned because it was picked by conquest, make sure a capital is spawned in case it is a low slot count
		SpawnList({humaninfo.Capital}, start_planet, humanfaction,false,false)
	end
	ChangePlanetOwnerAndPopulate(start_planet, humanfaction, 4500)
	if not preowned then --If the planet isn't owned, spawning a capital first doesn't work
		SpawnList({humaninfo.Capital}, start_planet, humanfaction,false,false)
	end
end

function populate_planet(start_planet, faction, capital)
	local scaled_combat_power = 800 * EvaluatePerception("GenericPlanetValue", humanfaction, start_planet)
	if capital ~= nil then
		scaled_combat_power = 4500
	end
	ChangePlanetOwnerAndPopulate(start_planet, faction, scaled_combat_power)
	if capital ~= nil then
		SpawnList({capital}, start_planet, faction,false,false)
	end
end

function spawn_IF(startplanet)
	local SSDs = nil
	if StartType ~= "CUSTOM_GC_FULL_START" then
		SSDs = Get_SSDS()
	end
	PopulateGalaxy(SSDs,startplanet)

	crossplot:publish("INITIALIZE_AI", "empty")
	Story_Event("FTGU_SPAWN_COMPLETE")

	if RosterType == "CUSTOM_GC_MAPPED_ROSTER" or RosterType == "CUSTOM_GC_RANDOM_MAPS" then
		Story_Event("CUSTOM_CHAPTER_2")
	end
end
