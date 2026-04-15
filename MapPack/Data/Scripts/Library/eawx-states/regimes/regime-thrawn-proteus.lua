require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
        local proteus_infinity = GlobalValue.Get("PROTEUS_INFINITY")
        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()

        self.p_empire = Find_Player("Empire")

        GlobalValue.Set("REGIME_INDEX", 3)

        self.p_empire.Lock_Tech(Find_Object_Type("Dummy_Regicide_Thrawn"))

        Story_Event("THRAWN_REQUEST_COMPLETED")
        if self.active_planets["CORUSCANT"] then
            Story_Event("DELTA_SOURCE_INIT")
        end
        if self.active_planets["KATANA_SPACE"] then
            Story_Event("AI_NOTIF_BEGIN_PLOT_KATANA_GALACTIC")
        end

        Story_Event("THRAWN_REQUEST_COMPLETED")

        if self.p_empire.Is_Human() then
            StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_THRAWN_ERA", 15, nil, "Thrawn_Loop", 0)
        else
            StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_THRAWN_NONPLAYER", 15, nil, nil, 0, nil, {r = 255, g = 255, b = 100})
        end

        if self.entry_time <= 5 then
            --TechSupport: Planet locks based on infinity mode
            if not proteus_infinity then
                StoryUtil.SetPlanetRestricted("BYSS", 1)
                StoryUtil.SetPlanetRestricted("THE_MAW", 1)
                StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)
            end
            UnitUtil.SetLockList("EMPIRE", {
                "Executor_Star_Dreadnought",
                "Praetor_II_Battlecruiser",
                "Eidolon",
                "TaggeCo_HQ",
                "PX10_Company",
                -- Historical-only units
                "Navy_Commando_Company"
            }, false)

            UnitUtil.SetLockList("EMPIRE", {
                "Imperial_Boarding_Shuttle",
                "Noghri_Assassin_Company"
            })

            if self.p_empire.Is_Human() then
                Story_Event("THRAWN_WELCOME")
            end

        else
            if not self.p_empire.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_THRAWN_NONPLAYER", 15, nil, nil, 0, nil, {r = 255, g = 255, b = 100})
            end

            UnitUtil.SetLockList("EMPIRE", {
                "Executor_Star_Dreadnought",
                "YE_4_Group",
                "PX10_Company",
                "Imperial_TNT_Company",
                "Vessery_Stranger_Location_Set",
                "Shadow_Squadron_Location_Set",
                "Scimitar_Squadron_Location_Set",
                "Rebuild_Brashin"
            }, false)

            UnitUtil.SetLockList("EMPIRE", {
                "Imperial_Boarding_Shuttle",
                "Beta_ETR_3_Group",
                "Noghri_Assassin_Company",
                "Imperial_AT_PT_Company"
            })

            Clear_Fighter_Hero("VESSERY_STRANGER_SQUADRON")
            Clear_Fighter_Hero("RHYMER_SCIMITAR_SQUADRON")
            Clear_Fighter_Hero("BROADSIDE_SHADOW_SQUADRON")

            --Thrawn departure message for human Hand player
            if Find_Player("local").Get_Faction_Name() == "EMPIREOFTHEHAND" then
                local obj_thrawn_grey_wolf = Find_First_Object("Thrawn_Grey_Wolf")
                if TestValid(obj_thrawn_grey_wolf) then
                    local obj_parck = Find_First_Object("Parck_Strikefast")
                    if TestValid(obj_parck) then
                        StoryUtil.Multimedia("TEXT_THRAWN_LEAVES_HAND_PARCK_ALIVE", 15, nil, "Thrawn_Loop", 0)
                    else
                        StoryUtil.Multimedia("TEXT_THRAWN_LEAVES_HAND_PARCK_DEAD", 15, nil, "Thrawn_Loop", 0)
                    end
                end
            end
            UnitUtil.SetLockList("EMPIREOFTHEHAND", {"Parck_Chaf_Destroyer_Upgrade"})

            UnitUtil.DespawnList{
                "Dummy_Regicide_Thrawn",
                "Isard_Lusankya",
                "Thrawn_Grey_Wolf"
            }

            Clear_Fighter_Hero("VESSERY_STRANGER_SQUADRON")
            Clear_Fighter_Hero("RHYMER_SCIMITAR_SQUADRON")
            Clear_Fighter_Hero("BROADSIDE_SHADOW_SQUADRON")

            crossplot:publish("THRAWN_CLONE_START", "empty")

        end

        Set_To_First_Extant_Host("TURR_PHENNIR_TIE_INTERCEPTOR_LOCATION_SET", self.p_empire, true)

        local starting_era = false
        if self.entry_time <= 5 then
            starting_era = true
        end
        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        for planet, herolist in pairs(self.Starting_Spawns["THRAWN"]) do
            for _, hero_table in pairs(herolist) do
                if starting_era == false and hero_table.progress == false then
                    -- keep this empty for now
                else
                    StoryUtil.SpawnAtSafePlanet(planet, self.p_empire, self.active_planets, {hero_table.object})
                end
            end
        end

        --NB: Despawns of Isard & CCOGM heroes must happen on entering Thrawn because when leaving their regimes we don't know if Empire is going to Thrawn or Dark Empire
        for planet, herolist in pairs(self.Starting_Spawns["CCOGM"]) do
            for _, hero_table in pairs(herolist) do
                if hero_table.remove == true then
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

        for planet, herolist in pairs(self.Starting_Spawns["ISARD"]) do
            for _, hero_table in pairs(herolist) do
                if hero_table.remove == true then
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
    end,

    on_update = function(self, state_context)
    end,

    --NB: on_exit cannot access self-scoped variables declared in on_enter or on_update
    on_exit = function(self, state_context)
    end
}
