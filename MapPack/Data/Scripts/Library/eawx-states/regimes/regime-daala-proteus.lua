require("eawx-util/StoryUtil")
require("eawx-util/ChangeOwnerUtilities")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)
        self.leader_approach = false

        self.p_empire = Find_Player("Empire")
        self.regime_host_name = GlobalValue.Get("IMPERIAL_REGIME_HOST")
        self.p_regime_host = Find_Player(self.regime_host_name)

        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        GlobalValue.Set("REGIME_INDEX", 6)

        local imperial_table = {
            "Empire",
            "Greater_Maldrood",
            "Zsinj_Empire",
            "Eriadu_Authority",
            "Pentastar",
            "Imperial_Proteus"
        }
        for _, faction in pairs(imperial_table) do
            Find_Player(faction).Lock_Tech(Find_Object_Type("Dummy_Regicide_Daala"))
        end

        Story_Event("DAALA_REQUEST_COMPLETED")

        if self.p_regime_host.Is_Human() then
            StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_DAALA_ERA", 15, nil, "Daala_Loop", 0)
        end

        if self.entry_time <= 5 then

            UnitUtil.SetLockList("EMPIRE", {
                "Eidolon",
                "IPV1",
                "PX10_Company",
                "TaggeCo_HQ",
                -- Historical-only units
                "Navy_Commando_Company"
            }, false)

            UnitUtil.SetLockList("EMPIRE", {
                "Patrol_Nebulon_B",
                "Crusader_Gunship",
                "Delta_JV7_Group",
                "Imperial_Dwarf_Spider_Droid_Company",
                "Cygnus_HQ"
            })

            if self.p_empire.Is_Human() then
                Story_Event("DAALA_WELCOME")
            end

            Set_To_First_Extant_Host("WEDGE_ROGUES_LOCATION_SET", Find_Player("Rebel"), true)

        else

            if not self.p_regime_host.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_DAALA_NONPLAYER", 15, nil, nil, 0, nil, {r = 255, g = 255, b = 100})
            end

            StoryUtil.SetPlanetRestricted("THE_MAW", 0)

            UnitUtil.SetLockList("EMPIRE", {
                "IPV1"
            }, false)

            --Regular Imperial asset progression
            UnitUtil.SetLockList("EMPIRE", {
                "Executor_Star_Dreadnought",
                "Patrol_Nebulon_B",
                "Crusader_Gunship",
                "Imperial_Dwarf_Spider_Droid_Company"
            })

            if self.active_planets["THE_MAW"] then
                local planet = FindPlanet("The_Maw")
                if planet.Get_Owner() ~= Find_Player("Neutral") then
                    ChangePlanetOwnerAndRetreat(planet, self.p_regime_host)
                end
                local spawn_list_Daala = {
                    -- "Empire_Shipyard_Level_Three",
                    -- "Empire_Star_Base_4",
                    -- "Empire_Office",
                    -- "E_Ground_Barracks",
                    "Imperial_Stormtrooper_Company",
                    "Imperial_Stormtrooper_Company",
                    "Imperial_I_Star_Destroyer",
                    "Imperial_I_Star_Destroyer",
                    "Imperial_I_Star_Destroyer",
                    "Crusader_Gunship",
                    "Crusader_Gunship",
                    "Strike_Cruiser",
                    "Strike_Cruiser",
                    "Carrack_Cruiser",
                    "Carrack_Cruiser"
                }
                SpawnList(spawn_list_Daala, planet, self.p_regime_host, true, false)

            end

            self.DespawnList = {
                "Dummy_Regicide_Daala",
            }

            for _, object in pairs(self.DespawnList) do
                checkObject = Find_First_Object(object)
                if TestValid(checkObject) then
                    checkObject.Despawn()
                end
            end
        end

        Set_To_First_Extant_Host("TURR_PHENNIR_TIE_INTERCEPTOR_LOCATION_SET", self.p_empire, true)

        local starting_era = false
        if self.entry_time <= 5 then
            starting_era = true
        end
        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        for planet, herolist in pairs(self.Starting_Spawns["DAALA"]) do
            for _, hero_table in pairs(herolist) do
                if starting_era == false and hero_table.progress == false then

                else
                    StoryUtil.SpawnAtSafePlanet(planet, self.regime_host_name, self.active_planets, {hero_table.object})
                end
            end
        end
    end,

    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.leader_approach == false) and (self.progress == true) then
            self.leader_approach = true
            if self.p_regime_host.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_PELLAEON_CONTACT", 15, nil, "Daala_Loop", 0)

                local plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
                local regime_display_event = plot.Get_Event("Pellaeon_Request_Dialog")

                regime_display_event.Add_Dialog_Text("TEXT_CAMPAIGN_EVENT_PROGRESS_PELLAEON_LOSS_HERO")
                for planet, herolist in pairs(self.Starting_Spawns["DAALA"]) do
                    for _, hero_table in pairs(herolist) do
                        if hero_table.remove == true then
                            regime_display_event.Add_Dialog_Text("TEXT_BULLETED_LIST_ENTRY_VARIABLE", Find_Object_Type(hero_table.object))
                        end
                    end
                end

                Story_Event("PELLAEON_REQUEST_STARTED")
                self.p_regime_host.Unlock_Tech(Find_Object_Type("Dummy_Regicide_Pellaeon"))
            end
        end
    end,

    --NB: on_exit cannot access self-scoped variables declared in on_enter or on_update
    on_exit = function(self, state_context)
        local Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        local RegimeHostName = GlobalValue.Get("IMPERIAL_REGIME_HOST")
        local p_regime_host = Find_Player(RegimeHostName)

        --Despawns of Daala heroes are allowed to happen on leaving Daala because there is no progress option that allows them to remain
        for planet, herolist in pairs(Starting_Spawns["DAALA"]) do
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
    end
}
