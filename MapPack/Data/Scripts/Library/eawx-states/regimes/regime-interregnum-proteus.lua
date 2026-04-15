require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()

        self.p_empire = Find_Player("Empire")
        self.p_warlords = Find_Player("Warlords")

        if self.active_planets["CIUTRIC"] then
            if FindPlanet("CIUTRIC").Get_Owner() == self.p_warlords then
                local check_list = {"Krennel_Warlord","Phulik_Binder","Darron_Direption","Brothic_Team"}
                local spawn_list = {}

                for i, check_object in pairs(check_list) do
                    if not Find_First_Object(check_object) then
                        table.insert(spawn_list,check_object)
                    end
                end

                SpawnList(spawn_list,FindPlanet("CIUTRIC"),self.p_warlords,true,false)
            end
        end

        UnitUtil.SetLockList("EMPIRE", {
            "Imperial_Boarding_Shuttle",
            "Noghri_Assassin_Company",
            "Phennir_Location_Set"
        }, false)

        if self.p_empire.Is_Human() then
            StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_THRAWN_DEATH", 15, nil, "Imperial_Naval_Officer_Loop", 0)
        else
            StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_INTERREGNUM_NONPLAYER", 15, nil, nil, 0, nil, {r = 255, g = 255, b = 100})
        end

        Set_To_First_Extant_Host("TURR_PHENNIR_TIE_INTERCEPTOR_LOCATION_SET", self.p_empire, true)

        --Despawns of Thrawn heroes must happen on entering Interregnum because on Thrawn exit we don't know if Empire is going to Interregnum or Dark Empire
        local Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        for planet, herolist in pairs(Starting_Spawns["THRAWN"]) do
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
