require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)
        self.p_empire = Find_Player("Empire")
        self.regime_host_name = GlobalValue.Get("IMPERIAL_REGIME_HOST")
        self.p_regime_host = Find_Player(self.regime_host_name)

        self.active_planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        GlobalValue.Set("REGIME_INDEX", 7)

        local imperial_table = {
            "Empire",
            "Greater_Maldrood",
            "Zsinj_Empire",
            "Eriadu_Authority",
            "Pentastar",
            "Imperial_Proteus"
        }
        for _, faction in pairs(imperial_table) do
            Find_Player(faction).Lock_Tech(Find_Object_Type("Dummy_Regicide_Pellaeon"))
        end

        --Interim(?) edge case handling: if the regime host has no safe planets when Daala dies. ~Mord
        if not StoryUtil.FindFriendlyPlanet(self.p_regime_host) then
            if not self.entry_time <= 5 then
                GlobalValue.Set("GOV_EMP_DISABLE_MULTIMEDIA_HOLO", 1)
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_PELLAEON_EMPIRE_DEFEATED", 15, nil, "Pellaeon_Loop", 0, nil, {r = 255, g = 255, b = 100})
                return
            end
        end

        Story_Event("PELLAEON_REQUEST_COMPLETED")

        -- Historic GCs with Pellaeon tend to be more unique scripts (at least one of them). Should be redone longer-term.
        if self.progress == true then
            if self.p_regime_host.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_PELLAEON_ERA", 15, nil, "Pellaeon_Loop", 0)
            end
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
                "Rogriss_Dominion_Dummy",
                "Pellaeon_Megador_Dummy",
                "Patrol_Nebulon_B",
                "Crusader_Gunship",
                "Imperial_Dwarf_Spider_Droid_Company",
                -- Integrated factions
                "Crimson_Victory_II_Star_Destroyer",
                "Pellaeon_Reaper_Dummy",
            })

            if self.p_empire.Is_Human() then
                Story_Event("PELLAEON_WELCOME")
            end

            Set_To_First_Extant_Host("WEDGE_ROGUES_LOCATION_SET", Find_Player("Rebel"), true)

        else
            if not self.p_regime_host.Is_Human() then
                StoryUtil.Multimedia("TEXT_CONQUEST_REGIME_PELLAEON_NONPLAYER", 15, nil, nil, 0, nil, {r = 255, g = 255, b = 100})
            end

            --if you transition into Pellaeon regime by any route and Rogriss is alive:
            -- A) if Rogriss belongs to the regime host, it unlocks Rogriss_Dominion_Dummy
            -- A) if Rogriss belongs to a rival Imperial faction, he defects to the regime host, which unlocks Rogriss_Dominion_Dummy
            -- B) if Rogriss belongs to someone else (e.g. Hand), he stays there and the regime host unlocks buildable Dominion
            local rogriss_status = "absent"
            local obj_rogriss = Find_First_Object("Rogriss_Agonizer")
            if TestValid(obj_rogriss) then
                local rogriss_owner_name = obj_rogriss.Get_Owner().Get_Faction_Name()
                if rogriss_owner_name == self.regime_host_name then
                    rogriss_status = "regime_host"
                else
                    for _, faction_name in pairs(imperial_table) do
                        if rogriss_owner_name == string.upper(faction_name) then
                            rogriss_status = "rival"
                            break
                        end
                    end
                    if rogriss_status == "absent" then
                        rogriss_status = "other"
                    end
                end
            end

            if rogriss_status == "other" then
                UnitUtil.SetLockList(self.regime_host_name, {"Dominion"})
            else
                UnitUtil.SetLockList(self.regime_host_name, {"Rogriss_Dominion_Dummy"})
                if rogriss_status ~= "regime_host" then
                    StoryUtil.SpawnAtSafePlanet("BASTION", self.p_regime_host, self.active_planets, {"Rogriss_Agonizer"})
                    if rogriss_status == "rival" then
                        obj_rogriss.Despawn()
                    end
                end
            end

            --if you entered Pellaeon's regime voluntarily, spawn Daala_Scylla on Kampe
            if TestValid(Find_First_Object("Dummy_Regicide_Pellaeon")) then
                StoryUtil.SpawnAtSafePlanet("KAMPE", self.p_regime_host, self.active_planets, {"Daala_Scylla"})
            end

            UnitUtil.SetLockList(self.regime_host_name, {
                "Delta_JV7_Group",
                "Cygnus_HQ"
            }, false)

            UnitUtil.SetLockList(self.regime_host_name, {
                "Pellaeon_Megador_Dummy"
            })

            UnitUtil.DespawnList{
                "Dummy_Regicide_Pellaeon",
                "Daala_Knight_Hammer"
            }

        end

        --181st setup (default settings are Phennir Interceptor 181st, so Pellaeon regime needs override)
        UnitUtil.SetLockList("EMPIRE", {
            "Turr_Phennir_TIE_Interceptor_Location_Set"
        }, false)
        Upgrade_Fighter_Hero("TURR_PHENNIR_TIE_INTERCEPTOR_181ST_SQUADRON","TURR_PHENNIR_TIE_DEFENDER_181ST_SQUADRON")
        Set_To_First_Extant_Host("TURR_PHENNIR_TIE_DEFENDER_LOCATION_SET", self.p_empire, true)
        UnitUtil.SetLockList("EMPIRE", {
            "Turr_Phennir_TIE_Defender_Location_Set"
        })

        local starting_era = false
        if self.entry_time <= 5 then
            starting_era = true
        end
        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
        for planet, herolist in pairs(self.Starting_Spawns["PELLAEON"]) do
            for _, hero_table in pairs(herolist) do
                if (starting_era == false and hero_table.progress == false) then
                    --this space intentionally left blank
                else
                    StoryUtil.SpawnAtSafePlanet(planet, self.regime_host_name, self.active_planets, {hero_table.object})
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
