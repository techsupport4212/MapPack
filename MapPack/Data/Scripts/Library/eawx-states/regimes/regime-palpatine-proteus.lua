require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("eawx-util/PopulatePlanetUtilities")
require("UnitSpawnerTables")
require("PGStoryMode")
require("PGSpawnUnits")
CONSTANTS = ModContentLoader.get("GameConstants")

return {
    on_enter = function(self, state_context)
        local proteus_infinity = GlobalValue.Get("PROTEUS_INFINITY")
        self.leader_approach = false

        self.p_empire = Find_Player("Empire")
        self.regime_host_name = GlobalValue.Get("IMPERIAL_REGIME_HOST")
        self.p_regime_host = Find_Player(self.regime_host_name)

        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.DarkEmpireUnits =  {
            "Eclipse_Star_Dreadnought",
            "Sovereign_Star_Dreadnought",
            "MTC_Sensor",
            "MTC_Support",
            "TaggeCo_HQ",
            "Hunter_Killer_Probot",
            "XR85_Company",
            "Imperial_Chrysalide_Company",
            "Imperial_Dark_Jedi_Company",
            "Dark_Stormtrooper_Company",
            "Compforce_Assault_Company",
            "Xecr_Nist_Dark_Side_Location_Set"
            }

        GlobalValue.Set("REGIME_INDEX", 4)

        if self.p_regime_host == self.p_empire then
            self.p_empire.Lock_Tech(Find_Object_Type("Dummy_Regicide_Thrawn"))
            self.p_empire.Lock_Tech(Find_Object_Type("Project_Ambition_Dummy"))
            self.p_empire.Lock_Tech(Find_Object_Type("Dummy_Regicide_CCoGM"))
        end

        Story_Event("PALPATINE_REQUEST_COMPLETED")
        Story_Event("GC_CORUSCANT_EVAC_LONG")

        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")

        if self.entry_time <= 5 then

            crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", "EMPIRE", "Dark Empire")

            --only play the generic welcome message if starting as Dark Empire; transitions to Dark Empire have their own welcome text handled elsewhere
            if self.p_regime_host.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_PALPATINE_ERA", 15, nil, "Palpatine_Reborn_Loop", 0)
                Story_Event("PALPATINE_WELCOME")
            end
            --TechSupport: Planet locks based on infinity mode
            if not proteus_infinity then
                StoryUtil.SetPlanetRestricted("THE_MAW", 1)
            end
            UnitUtil.SetLockList("EMPIRE", {
                "Executor_Star_Dreadnought",
                "Eidolon",
                "PX10_Company",
                  -- Historical-only units
                "Navy_Commando_Company"
            }, false)

            Set_To_First_Extant_Host("TURR_PHENNIR_TIE_INTERCEPTOR_LOCATION_SET", self.p_empire, true)
            Set_To_First_Extant_Host("WEDGE_ROGUES_LOCATION_SET", Find_Player("Rebel"), true)

        else
            StoryUtil.SetPlanetRestricted("BYSS", 0)
            StoryUtil.SetPlanetRestricted("THYFERRA", 0)
            StoryUtil.SetPlanetRestricted("KESSEL", 0)
            StoryUtil.SetPlanetRestricted("KATANA_SPACE", 0)

            UnitUtil.SetLockList("EMPIRE", {"Praetor_II_Battlecruiser"})
            UnitUtil.SetLockList(self.regime_host_name, self.DarkEmpireUnits)

            local de_home_object = nil
            if self.active_planets["BYSS"] then
                de_home_object = FindPlanet("Byss")
            elseif EvaluatePerception("Planet_Ownership", self.p_regime_host) > 0 then
                de_home_object = StoryUtil.FindTargetPlanet(self.regime_host_name, false, true, 1, nil, nil, self.regime_host_name)
            elseif EvaluatePerception("Planet_Ownership", Find_Player("Warlords")) > 0 then
                de_home_object = StoryUtil.FindTargetPlanet(self.regime_host_name, false, true, 1, nil, nil, "Warlords")
            else
                de_home_object = StoryUtil.FindTargetPlanet(self.regime_host_name, false, true, 1, nil, nil, Find_Player("local").Get_Faction_Name())
            end

            if de_home_object.Get_Owner() ~= self.p_regime_host then
                ChangePlanetOwnerAndRetreat(de_home_object, self.p_regime_host)
            else
                ChangePlanetOwnerAndRetreat(de_home_object, Find_Player("Neutral"))
                ChangePlanetOwnerAndRetreat(de_home_object, self.p_regime_host)
            end

            --byss spawn structures
            local de_home_structures = {
                "Golan_Colony_Two",
            }

            local total_spawn_table = DefineUnitTable(self.regime_host_name)
            SpawnStarBase(self.p_regime_host, de_home_object, total_spawn_table["Starbase_Table"], false)
            SpawnShipyard(self.p_regime_host, de_home_object, total_spawn_table["Shipyard_Table"], total_spawn_table["Defenses_Table"])

            --if the regime host already has a capital, move it to Byss and replace with Barracks; except Zsinj
            local RegimeHostCapitalStructureName = CONSTANTS.ALL_FACTIONS_CAPITALS[self.regime_host_name].STRUCTURE
            if RegimeHostCapitalStructureName ~= "RANCOR_BASE" then
                local RegimeHostCapitalInstance = Find_First_Object(RegimeHostCapitalStructureName)
                if RegimeHostCapitalInstance then
                    local FormerCapitalPlanet = RegimeHostCapitalInstance.Get_Planet_Location()
                    RegimeHostCapitalInstance.Despawn()
                    Spawn_Unit(Find_Object_Type(total_spawn_table.Groundbase_Table[1]),FormerCapitalPlanet,self.p_regime_host)
                end
                table.insert(de_home_structures,RegimeHostCapitalStructureName)
            else
                table.insert(de_home_structures,total_spawn_table.Groundbase_Table[1])
            end

            local open_slot_count = EvaluatePerception("Open_Ground_Structure_Slots", self.p_regime_host, de_home_object) - 1
            if open_slot_count > 0 then
                local structures_queue = {}
                structures_queue[1] = total_spawn_table.Government_Building
                structures_queue[2] = total_spawn_table.Groundbase_Table[1]
                structures_queue[3] = total_spawn_table.Groundbase_Table[5]
                structures_queue[4] = total_spawn_table.Groundbase_Table[5]

                for i, structure in pairs(structures_queue) do
                    table.insert(de_home_structures,structures_queue[i])
                    open_slot_count = open_slot_count - 1

                    if open_slot_count == 0 then
                        break
                    end
                end
            end

            SpawnList(de_home_structures, de_home_object, self.p_regime_host, true, false)

            --Dark Empire Planet spawn fleet & army
            local power_to_spawn = 1000
            if not self.p_regime_host.Is_Human() then
                local de_power = 0
                local most_powerful = 0
                for _,faction_name in pairs(CONSTANTS.PLAYABLE_FACTIONS) do
                    local power = EvaluatePerception("Total_Friendly_Forces", Find_Player(faction_name))
                    if faction_name == self.regime_host_name then
                        de_power = power
                    end
                    if power > most_powerful then
                        most_powerful = power
                    end
                end

                if de_power + power_to_spawn * 1.25 < most_powerful then
                    --NB: remember the ground forces are added on top of this as 1/4 specified power amount
                    power_to_spawn = (most_powerful - de_power) * 0.8
                end

                --Cap DE spawns at ~1,000 pop. Space CP/pop = 100; ground is inconsistent.
                local cp_cap = 1000 * 100 * 0.93
                if power_to_spawn > cp_cap then
                    power_to_spawn = cp_cap
                end

                --AI DE gets free Eclipse if there's enough CP. This also reduces ground spawns by 25% of Eclipse's CP, but this is ok for now.
                local eclipse_power = Find_Object_Type("Eclipse_Star_Dreadnought").Get_Combat_Rating()
                if power_to_spawn >= eclipse_power then
                    power_to_spawn = power_to_spawn - eclipse_power
                    if power_to_spawn < 1000 then
                        power_to_spawn = 1000
                    end
                    SpawnList({"Eclipse_Star_Dreadnought"}, de_home_object, self.p_regime_host, true, false)
                    UnitUtil.SetLockList(self.regime_host_name, {"Eclipse_Star_Dreadnought"}, false)
                end
            end

            ChangePlanetOwnerAndPopulate(de_home_object, self.p_regime_host, power_to_spawn, "DARK_EMPIRE", nil, true, "unlimited")
        end

        local starting_era = false
        if self.entry_time <= 5 then
            starting_era = true
        end
        for planet, herolist in pairs(self.Starting_Spawns["PALPATINE"]) do
            for _, hero_table in pairs(herolist) do
                if starting_era == false and hero_table.progress == false then

                else
                    StoryUtil.SpawnAtSafePlanet(planet, self.regime_host_name, self.active_planets, {hero_table.object})
                end
            end
        end

        local DECloningFacility = Find_First_Object("Dark_Empire_Cloning_Facility")
        if DECloningFacility ~= nil then
            local DESpot = DECloningFacility.Get_Planet_Location()
            local buildings = Find_All_Objects_Of_Type("InBase", self.p_regime_host)
            local extras = {}
            for _, building in pairs(buildings) do
                if building.Get_Planet_Location() == DESpot and building ~= DECloningFacility then
                    local name = building.Get_Type().Get_Name()
                    if string.find(name, "CAPITAL") == nil and string.find(name, "OFFICE") == nil then
                        table.insert(extras, building)
                    end
                end
            end
            local extracount = table.getn(extras)
            if EvaluatePerception("MaxGroundbaseLevel", self.p_regime_host, DESpot) < extracount + 3 then
                extras[GameRandom.Free_Random(1, extracount)].Despawn()
            end
        end

        local Grath = Find_First_Object("Grath_Stormtrooper")
        if TestValid(Grath) then
            if self.p_regime_host == Grath.Get_Owner() then
                UnitUtil.ReplaceAtLocation("Grath_Stormtrooper", "Grath_Dark_Stormtrooper_Team")
            end
        end

        local Veers = Find_First_Object("Veers_AT_AT_Walker")
        if TestValid(Veers) then
            if self.p_regime_host == Veers.Get_Owner() then
                UnitUtil.ReplaceAtLocation("Veers_AT_AT_Walker", "Veers_Chariot_Team")
            end
        end
    end,

    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if self.current_time >= 60 and self.leader_approach == false and self.current_time - self.entry_time <= 402 then
            self.leader_approach = true
            local legitimacy_winner = GlobalValue.Get("LEGITIMACY_WINNER")
            if self.p_regime_host.Is_Human() or legitimacy_winner then
                local plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
                local regime_display_event

                if self.p_regime_host.Is_Human() then
                    StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_JAX_CONTACT", 15, nil, nil, 0)
                    regime_display_event = plot.Get_Event("Jax_Request_Dialog")
                    for planet, herolist in pairs(self.Starting_Spawns["PALPATINE"]) do
                        for _, hero_table in pairs(herolist) do
                            if hero_table.remove == true then
                                regime_display_event.Add_Dialog_Text("TEXT_BULLETED_LIST_ENTRY_VARIABLE", Find_Object_Type(hero_table.object))
                            end
                        end
                    end
                    Story_Event("JAX_REQUEST_STARTED")
                    self.p_regime_host.Unlock_Tech(Find_Object_Type("Dummy_Regicide_Jax"))
                else
                    StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_JAX_CONTACT_OUTSIDE", 15, nil, nil, 0)
                    regime_display_event = plot.Get_Event("Jax_Request_Outside_Dialog")
                    for planet, herolist in pairs(self.Starting_Spawns["PALPATINE"]) do
                        for _, hero_table in pairs(herolist) do
                            if hero_table.remove == true then
                                regime_display_event.Add_Dialog_Text("TEXT_BULLETED_LIST_ENTRY_VARIABLE", Find_Object_Type(hero_table.object))
                            end
                        end
                    end
                    Story_Event("JAX_REQUEST_OUTSIDE_STARTED")
                end
            end
        end
    end,

    --NB: on_exit cannot access self-scoped variables declared in on_enter or on_update
    on_exit = function(self, state_context)
        local Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        local RegimeHostName = GlobalValue.Get("IMPERIAL_REGIME_HOST")
        local p_regime_host = Find_Player(RegimeHostName)

        --Despawns of Dark Empire heroes are allowed to happen on leaving Dark Empire because there is no progress option that allows them to remain
        for planet, herolist in pairs(Starting_Spawns["PALPATINE"]) do
            for _, hero_table in pairs(herolist) do
                if hero_table.remove == true then
                    local target_object = Find_First_Object(hero_table.object)
                    if hero_table.override then
                        target_object = Find_First_Object(hero_table.override)
                    end
                    if TestValid(target_object) then
                        if target_object.Get_Owner() == p_regime_host then
                            target_object.Despawn()
                        end
                    end
                end
            end
        end

        --in case Klev has upgraded from his original Destroyer form
        local despawn_list = {
            "Klev_Silencer_7_Battlecruiser"
        }

        local checkobject = nil
        for _, object in pairs(despawn_list) do
            checkObject = Find_First_Object(object)
            if TestValid(checkObject) then
                if checkObject.Get_Owner() == p_regime_host then
                    checkObject.Despawn()
                end
            end
        end

        UnitUtil.SetLockList(RegimeHostName, {
            "Eclipse_Star_Dreadnought",
            "Sovereign_Star_Dreadnought",
            "TaggeCo_HQ",
            "Hunter_Killer_Probot",
            "Imperial_Dark_Jedi_Company",
            "Imperial_Chrysalide_Company",
            "Dark_Stormtrooper_Company",
            "Compforce_Assault_Company",
            "Xecr_Nist_Dark_Side_Location_Set"
        }, false)

        Clear_Fighter_Hero("XECR_NIST_DARK_SIDE_SQUADRON")


        local legitimacy_winner = GlobalValue.Get("LEGITIMACY_WINNER")
        local proteus_initial_display_name = GlobalValue.Get("PROTEUS_INITIAL_DISPLAY_NAME")

        if legitimacy_winner then
            if GlobalValue.Get("DARK_EMPIRE_EX_NIHILO") then
                crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", RegimeHostName, "Dark Empire Remnants")
                if RegimeHostName == "IMPERIAL_PROTEUS" then
                    GlobalValue.Set("PROTEUS_CURRENT_DISPLAY_NAME","Dark Empire Remnants")
                end
            elseif RegimeHostName == "EMPIRE" then
                crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", "EMPIRE", "Ruling Council")
            elseif RegimeHostName == "IMPERIAL_PROTEUS" then
                crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", "IMPERIAL_PROTEUS", proteus_initial_display_name)
            else
                crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", RegimeHostName, p_regime_host.Get_Name())
            end
            crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", legitimacy_winner, "Galactic Empire")
            GlobalValue.Set("IMPERIAL_REGIME_HOST",legitimacy_winner)
            GlobalValue.Set("LEGITIMACY_WINNER",nil)
        else
            crossplot:publish("FACTION_DISPLAY_NAME_CHANGE", RegimeHostName, "Galactic Empire")
        end
    end
}
