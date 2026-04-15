require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)
        local proteus_infinity = GlobalValue.Get("PROTEUS_INFINITY")
        self.leader_approach = false
        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        self.p_empire = Find_Player("Empire")
        self.p_warlords = Find_Player("Warlords")

        GlobalValue.Set("REGIME_INDEX", 2)

        self.p_empire.Lock_Tech(Find_Object_Type("Project_Ambition_Dummy"))
        self.p_empire.Lock_Tech(Find_Object_Type("Dummy_Regicide_CCoGM"))

        if self.active_planets["KALIST"] then
            if FindPlanet("KALIST").Get_Owner() == self.p_warlords then
                local spawn_list = {"Harrsk_Whirlwind"}
                SpawnList(spawn_list, FindPlanet("KALIST"), self.p_warlords, true, false)
            end
        end

        Story_Event("PROJECT_AMBITION_COMPLETED")

        if self.p_empire.Is_Human() then
            StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_ISARD_ERA", 15, nil, "Isard_Loop", 0)
        end

        if self.entry_time <= 5 then
            if not proteus_infinity then
                StoryUtil.SetPlanetRestricted("BYSS", 1)
                StoryUtil.SetPlanetRestricted("THE_MAW", 1)
                StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)
            end

            UnitUtil.SetLockList("EMPIRE", {
                "Praetor_II_Battlecruiser",
                "Eidolon",
                "TaggeCo_HQ",
                "PX10_Company",
                -- Historical-only units
                "Navy_Commando_Company"
            }, false)

            UnitUtil.SetLockList("EMPIRE", {
                "Vessery_Stranger_Location_Set",
                "Shadow_Squadron_Location_Set"
            })

            if self.p_empire.Is_Human() then
                Story_Event("ISARD_WELCOME")
            end

        else

            if not self.p_empire.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_ISARD_NONPLAYER", 15, nil, nil, 0, nil, {r = 255, g = 255, b = 100})
            end

            StoryUtil.SetPlanetRestricted("THYFERRA", 0)
            StoryUtil.SetPlanetRestricted("KESSEL", 0)

            UnitUtil.SetLockList("EMPIRE", {
                "Eidolon"
            }, false)

            UnitUtil.SetLockList("EMPIRE", {
                "Strike_Cruiser",
                "Vessery_Stranger_Location_Set",
            })

            UnitUtil.DespawnList{
                "Project_Ambition_Dummy",
            }

            --Leaving Pestage causes Fel/181st to exit; Phennir/181st and Fel/Gray to enter
            UnitUtil.SetLockList("EMPIRE", {
                "Soontir_Fel_181st_Location_Set"
            }, false)
            Upgrade_Fighter_Hero("SOONTIR_FEL_181ST_SQUADRON","TURR_PHENNIR_TIE_INTERCEPTOR_181ST_SQUADRON")
            Set_To_First_Extant_Host("TURR_PHENNIR_TIE_INTERCEPTOR_LOCATION_SET", self.p_empire, true)
            UnitUtil.SetLockList("EMPIRE", {
                "Turr_Phennir_TIE_Interceptor_Location_Set",
                "Vessery_Stranger_Location_Set"
            })
        end

        local starting_era = false
        if self.entry_time <= 5 then
            starting_era = true
        end
        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        for planet, herolist in pairs(self.Starting_Spawns["ISARD"]) do
            for _, hero_table in pairs(herolist) do
                if starting_era == false and hero_table.progress == false then
                    --this space intentionally left blank
                else
                    StoryUtil.SpawnAtSafePlanet(planet, self.p_empire, self.active_planets, {hero_table.object})
                end
            end
        end

        --Despawns of Pestage heroes must happen on entering Isard because on Pestage exit we don't know if Empire is going to Isard, CCOGM, or Dark Empire
        for planet, herolist in pairs(self.Starting_Spawns["PESTAGE"]) do
            for _, hero_table in pairs(herolist) do
                if hero_table.remove_isard == true then
                    local target_object = Find_First_Object(hero_table.object)
                    if hero_table.override then
                        target_object = Find_First_Object(hero_table.override)
                    end
                    if TestValid(target_object) then
                        if target_object.Get_Owner() == self.p_empire then
                            target_object.Despawn()
                        end
                    end
                end
            end
        end

        if not proteus_infinity then
            if self.active_planets["THYFERRA"] then
                local planet = FindPlanet("Thyferra")
                if planet.Get_Owner() ~= Find_Player("Neutral") then
                    ChangePlanetOwnerAndPopulate(planet, self.p_empire, 2000, self.p_empire, false)
                end
            end

            self.CCoGMSpawns = require("eawx-mod-icw/spawn-sets/EraTwoCCoGMProgressSetWarlord")
            for planet, spawnlist in pairs(self.CCoGMSpawns) do
                if self.active_planets[planet] then
                    SpawnList(spawnlist, FindPlanet(planet), self.p_warlords, true, false)
                end
            end
        end
    end,

    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time

        if self.progress ~= true then
            return
        end

        if self.current_time >= 60 and self.leader_approach == false then
            self.leader_approach = true
            if self.p_empire.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_THRAWN_CONTACT", 15, nil, "Thrawn_Loop", 0)

                local plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
                local regime_display_event = plot.Get_Event("Thrawn_Request_Dialog")

                regime_display_event.Add_Dialog_Text("TEXT_CAMPAIGN_EVENT_PROGRESS_THRAWN_HERO_LOSS")
                for planet, herolist in pairs(self.Starting_Spawns["ISARD"]) do
                    for _, hero_table in pairs(herolist) do
                        if hero_table.remove == true then
                            regime_display_event.Add_Dialog_Text("TEXT_BULLETED_LIST_ENTRY_VARIABLE", Find_Object_Type(hero_table.object))
                        end
                    end
                end

                Story_Event("THRAWN_REQUEST_STARTED")
                self.p_empire.Unlock_Tech(Find_Object_Type("Dummy_Regicide_Thrawn"))
            end
        end
    end,

    --NB: on_exit cannot access self-scoped variables declared in on_enter or on_update
    on_exit = function(self, state_context)
    end
}
