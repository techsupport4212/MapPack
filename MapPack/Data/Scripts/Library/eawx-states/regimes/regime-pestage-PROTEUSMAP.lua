require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
        local proteus_infinity = GlobalValue.Get("PROTEUS_INFINITY")
        self.isard_approach = false
        self.hissa_approach = false
        self.progress_fired = false
        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        self.p_empire = Find_Player("Empire")

        GlobalValue.Set("REGIME_INDEX", 1)

        if self.p_empire.Is_Human() then
            StoryUtil.Multimedia("TEXT_CONQUEST_WARLORDS_GE_INTRO_PESTAGE", 15, nil, "Pestage_Loop", 0)
            Story_Event("PESTAGE_WELCOME")
        end

        --TechSupport: Planet locks based on infinity mode
        if not proteus_infinity then
            StoryUtil.SetPlanetRestricted("BYSS", 1)
            StoryUtil.SetPlanetRestricted("THE_MAW", 1)
            StoryUtil.SetPlanetRestricted("THYFERRA", 1)
            StoryUtil.SetPlanetRestricted("KESSEL", 1)
            StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)
        end
       
        UnitUtil.SetLockList("EMPIRE", {
            "Praetor_II_Battlecruiser",
            "Strike_Cruiser",
            "TaggeCo_HQ",
            "PX10_Company",
            "Imperial_AT_AT_Walker_Turbolaser_Refit_Company",
            "AT_ST_A_Company",
            -- Historical-only units
            "Navy_Commando_Company"
        }, false)

        local starting_era = false
        if self.entry_time <= 5 then
            starting_era = true
        end

        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        for planet, herolist in pairs(self.Starting_Spawns["PESTAGE"]) do
            for _, hero_table in pairs(herolist) do
                if starting_era == false and hero_table.progress == false then
                    -- do nothing
                else
                    StoryUtil.SpawnAtSafePlanet(planet, self.p_empire, self.active_planets, {hero_table.object})
                end
            end
        end

        --181st setup (default settings are Phennir 181st, Fel Nssis so Pestage regime needs override)
        UnitUtil.SetLockList("EMPIRE", {
            "Turr_Phennir_TIE_Interceptor_Location_Set"
        }, false)
        Clear_Fighter_Hero("TURR_PHENNIR_TIE_INTERCEPTOR_181ST_SQUADRON")

        UnitUtil.SetLockList("EMPIREOFTHEHAND", {
            "Soontir_Fel_Gray_Location_Set"
        }, false)
        Clear_Fighter_Hero("SOONTIR_FEL_GRAY_SQUADRON")

        UnitUtil.SetLockList("EMPIRE", {
            "Soontir_Fel_181st_Location_Set",
            "Shadow_Squadron_Location_Set"
        })
        Set_Fighter_Hero("SOONTIR_FEL_181ST_SQUADRON", "ROGRISS_AGONIZER")
    end,

    on_update = function(self, state_context)
        self.current_time = GetCurrentTime()

        if self.progress ~= true then
            return
        end

        if self.current_time >= 40 and self.isard_approach == false then
            self.isard_approach = true
            if self.p_empire.Is_Human() then
                StoryUtil.Multimedia("TEXT_STORY_GE_ERA_2_PROJECT_AMBITION", 15, nil, "Isard_Loop", 0)
            end
        end
        if self.current_time >= 60 and self.hissa_approach == false then
            self.hissa_approach = true
            if self.p_empire.Is_Human() then
                StoryUtil.Multimedia("TEXT_STORY_GE_ERA_2_CCOGM", 15, nil, "Hissa_Loop", 0)
            end
        end
        if self.current_time >= 80 and self.hissa_approach == true and self.progress_fired == false then
            self.progress_fired = true
            if self.p_empire.Is_Human() then

                local plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
                local regime_display_event = plot.Get_Event("Project_Ambition_Dialog")

                regime_display_event.Add_Dialog_Text("Supporting either new regime will result in the following heroes leaving:")

                for planet, herolist in pairs(self.Starting_Spawns["PESTAGE"]) do
                    for _, hero_table in pairs(herolist) do
                        if hero_table.remove_isard == true and hero_table.remove_ccogm == true then
                            regime_display_event.Add_Dialog_Text("TEXT_BULLETED_LIST_ENTRY_VARIABLE", Find_Object_Type(hero_table.object))
                        end
                    end
                end
                regime_display_event.Add_Dialog_Text("TEXT_NONE")
                regime_display_event.Add_Dialog_Text("Supporting the Central Committee will result in the following heroes leaving:")
                for planet, herolist in pairs(self.Starting_Spawns["PESTAGE"]) do
                    for _, hero_table in pairs(herolist) do
                        if hero_table.remove_isard == false and hero_table.remove_ccogm == true then
                            regime_display_event.Add_Dialog_Text("TEXT_BULLETED_LIST_ENTRY_VARIABLE", Find_Object_Type(hero_table.object))
                        end
                    end
                end

                Story_Event("PROJECT_AMBITION_STARTED")
                self.p_empire.Unlock_Tech(Find_Object_Type("Project_Ambition_Dummy"))
                self.p_empire.Unlock_Tech(Find_Object_Type("Dummy_Regicide_CCoGM"))
            end
        end
    end,

    --NB: on_exit cannot access self-scoped variables declared in on_enter or on_update
    on_exit = function(self, state_context)
    end
}
