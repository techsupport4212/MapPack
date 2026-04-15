require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
        GlobalValue.Set("CURRENT_ERA", 1)

        self.LeaderApproach = false

        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.AI_Active = true

        --TechSupport: Planet locks based on proteus mode (as nzoth is an IF world, not yevetha)
        local proteus_map_settings = GlobalValue.Get("PROTEUS_MAP_SETTINGS")
        if not proteus_map_settings then
        StoryUtil.SetPlanetRestricted("DOORNIK", 1)
        StoryUtil.SetPlanetRestricted("ZFELL", 1)
        StoryUtil.SetPlanetRestricted("NZOTH", 1)
        StoryUtil.SetPlanetRestricted("JTPTAN", 1)
        StoryUtil.SetPlanetRestricted("POLNEYE", 1)
        StoryUtil.SetPlanetRestricted("PRILDAZ", 1)
        end

        if Find_Player("local") == Find_Player("Pentastar") then
            StoryUtil.Multimedia("TEXT_CONQUEST_PENTASTAR_INTRO_E1", 15, nil, "Kaine_Loop", 0)
            Story_Event("PENTASTAR_ERAONE_STARTED")
        elseif Find_Player("local") == Find_Player("Eriadu_Authority") then
            StoryUtil.Multimedia("TEXT_CONQUEST_ERIADU_INTRO_E1", 15, nil, "Delvardus_Loop", 0)
            Story_Event("ERIADU_ERAONE_STARTED")
        elseif Find_Player("local") == Find_Player("Greater_Maldrood") then
            StoryUtil.Multimedia("TEXT_CONQUEST_MALDROOD_INTRO_E1", 15, nil, "Treuten_Teradoc_Loop", 0)
            Story_Event("MALDROOD_ERAONE_STARTED")
        elseif Find_Player("local") == Find_Player("Zsinj_Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_ZSINJ_INTRO_E1", 15, nil, "Zsinj_Loop", 0)
            Story_Event("ZSINJ_ERAONE_STARTED")
        end

        self.AI_Active = false
        self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraOneStartSet")
        for faction, herolist in pairs(self.Starting_Spawns) do
            for planet, spawnlist in pairs(herolist) do
                if faction ~= "WARLORDS" and faction ~= "INDEPENDENT_FORCES" then
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)
                end
            end
        end

        local endor = FindPlanet("Endor")
        if TestValid(endor) then
            local post_endor_fleet = require("eawx-mod-icw/spawn-sets/EndorFleet")
            local new_republic = Find_Player("Rebel")
            if Find_Player("local") == new_republic then
                SpawnList(post_endor_fleet["Normal"], endor, new_republic, true, false)
            else
                local difficulty = Find_Player("Rebel").Get_Difficulty()
                SpawnList(post_endor_fleet[difficulty], endor, new_republic, true, false)
            end
        end
    end,

    on_update = function(self, state_context)
        local current = GetCurrentTime() - self.entry_time
        if current >= 8 and self.AI_Active == false then
            crossplot:publish("CONQUER_CENTARES_ZSINJ", "empty")
            crossplot:publish("CONQUER_KASHYYYK_MALDROOD", "empty")
            crossplot:publish("CONQUER_MANDALORE_NR", "empty")
            --Subscribe to proteus-specific events if in proteus mode
            if GlobalValue.Get("PROTEUS_MAP_SETTINGS") then
                crossplot:publish("PROTEUS_CONQUER_CORUSCANT", "empty")
            end

			if not GlobalValue.Get("PROGRESSIVE_INFINITY") then
				crossplot:publish("INITIALIZE_AI", "empty")
			end
            self.AI_Active = true
        end
    end,

    on_exit = function(self, state_context)
    end
}
