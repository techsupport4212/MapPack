require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)
        GlobalValue.Set("CURRENT_ERA", 5)
		local infinity = GlobalValue.Get("PROGRESSIVE_INFINITY")

        self.LeaderApproach = false
        self.ResearchFired = false

        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.AI_Active = true
        
        --TechSupport: Planet locks based on infinity mode
        local proteus_infinity = GlobalValue.Get("PROTEUS_INFINITY")

        if not proteus_infinity then
        StoryUtil.SetPlanetRestricted("DOORNIK", 1)
        StoryUtil.SetPlanetRestricted("ZFELL", 1)
        StoryUtil.SetPlanetRestricted("NZOTH", 1)
        StoryUtil.SetPlanetRestricted("JTPTAN", 1)
        StoryUtil.SetPlanetRestricted("POLNEYE", 1)
        StoryUtil.SetPlanetRestricted("PRILDAZ", 1)
        end

        if self.entry_time <= 5 then
            self.ResearchFired = true
            if Find_Player("local") == Find_Player("Rebel") then
                StoryUtil.Multimedia("TEXT_CONQUEST_NR_INTRO_E5", 15, nil, "Mon_Mothma_Loop", 0)
                Story_Event("NEWREP_JAX_STARTED")
            elseif Find_Player("local") == Find_Player("Pentastar") then
                StoryUtil.Multimedia("TEXT_CONQUEST_PENTASTAR_INTRO_E5", 15, nil, "Utoxx_Prentioch_Loop", 0)
                Story_Event("PENTASTAR_ERAFIVE_STARTED")
            elseif Find_Player("local") == Find_Player("Eriadu_Authority") then
                StoryUtil.Multimedia("TEXT_CONQUEST_ERIADU_INTRO_E5", 15, nil, "Delvardus_Loop", 0)
                Story_Event("ERIADU_ERAFIVE_STARTED")
            elseif Find_Player("local") == Find_Player("Greater_Maldrood") then
                StoryUtil.Multimedia("TEXT_CONQUEST_MALDROOD_INTRO_E5", 15, nil, "Kosh_Teradoc_Loop", 0)
                Story_Event("MALDROOD_ERAFIVE_STARTED")
            elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EOTH_INTRO_E5", 15, nil, "Parck_Loop", 0)
                Story_Event("HAND_ERAFIVE_STARTED")
            elseif Find_Player("local") == Find_Player("Hapes_Consortium") then
                StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_TENENIEL_ONE", 15, nil, "Teneniel_Loop2", 0)
                Story_Event("HAPES_TENENIEL_START")
            elseif Find_Player("local") == Find_Player("Corporate_Sector") then
                StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_ODUMIN", 15, nil, "Odumin_Loop", 0)
                Story_Event("CSA_ERAONE_STARTED")
			elseif Find_Player("local") == Find_Player("Hutt_Cartels") then
                StoryUtil.Multimedia("TEXT_CONQUEST_HUTTS_DURGA_INTRO", 15, nil, "Durga_Loop", 0)
                Story_Event("HUTTS_DURGA_STARTED")
            end

            if self.Active_Planets["BYSS"] then
                Destroy_Planet("Byss")
            end
            if self.Active_Planets["DA_SOOCHA"] then
                Destroy_Planet("Da_Soocha")
            end

            self.AI_Active = false
			if not infinity then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFiveStartSet")
				for faction, herolist in pairs(self.Starting_Spawns) do
					for planet, spawnlist in pairs(herolist) do
						StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)
					end
				end
			end
        else
			if Find_First_Object("Custom_GC_Starter_Dummy") == nil then
				self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFiveProgressSet")
				for faction, herolist in pairs(self.Starting_Spawns) do
					for planet, spawnlist in pairs(herolist) do
						StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)
					end
				end
			end

            crossplot:publish("ERA_TRANSITION", 5)
        end
    end,

    on_update = function(self, state_context)
        local current = GetCurrentTime() - self.entry_time
        if current >= 5 and self.ResearchFired == true then
            self.ResearchFired = false
            crossplot:publish("NCMP1_RESEARCH_FINISHED", "empty")
            crossplot:publish("REPUBLIC_STAR_DESTROYER_RESEARCH_FINISHED", "empty")
        end
        if current >= 8 and self.AI_Active == false then
            crossplot:publish("CONQUER_MANDALORE_NR", "empty")

			if not GlobalValue.Get("PROGRESSIVE_INFINITY") then
				crossplot:publish("INITIALIZE_AI", "empty")
			end
            self.AI_Active = true
        end
    end,

    on_exit = function(self, state_context)
    end
}