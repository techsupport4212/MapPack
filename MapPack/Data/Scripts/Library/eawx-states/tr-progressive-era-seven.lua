require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

--Local function used to sanitize spawn lists for IF/Warlord factions in proteus mode, as they may contain heroes that are not meant to spawn in those modes
local function SanitizeSpawnList(self, faction, spawnlist)
    if faction ~= "WARLORDS" and faction ~= "INDEPENDENT_FORCES" then
        return spawnlist
    end
    if not GlobalValue.Get("PROTEUS_MAP_SETTINGS") then
        return spawnlist
    end
    local hero_set = {}
    for _, hero in ipairs(self.LegitimacyHeroes or {}) do
        hero_set[hero] = true
    end
    local sanitized = {}
    for _, unit in ipairs(spawnlist) do
        if not hero_set[unit] then
            table.insert(sanitized, unit)
        end
    end
    return sanitized
end

return {
    on_enter = function(self, state_context)
        GlobalValue.Set("CURRENT_ERA", 7)
		local infinity = GlobalValue.Get("PROGRESSIVE_INFINITY")

        self.LegitimacyHeroes = require("LegitimacyHeroLibrary") --Uses a library of legitimacy heroes to determine who to keep / remove
        self.LeaderApproach = false
        self.ResearchFired = false

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

        if self.entry_time <= 5 then
            self.ResearchFired = true
            if Find_Player("local") == Find_Player("Rebel") then
                StoryUtil.Multimedia("TEXT_CONQUEST_NR_INTRO_E7", 15, nil, "Leia_Loop", 0)
                Story_Event("NEWREP_PELLAEON_STARTED")
            elseif Find_Player("local") == Find_Player("Greater_Maldrood") then
                StoryUtil.Multimedia("TEXT_CONQUEST_MALDROOD_INTRO_E7", 15, nil, "Kosh_Teradoc_Loop", 0)
                Story_Event("MALDROOD_ERASEVEN_STARTED")
            elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EOTH_INTRO_E7", 15, nil, "Parck_Loop", 0)
                Story_Event("HAND_ERASEVEN_STARTED")
            elseif Find_Player("local") == Find_Player("Hapes_Consortium") then
                StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_TENENIEL_ONE", 15, nil, "Teneniel_Loop2", 0)
                Story_Event("HAPES_TENENIEL_START")
            elseif Find_Player("local") == Find_Player("Corporate_Sector") then
                StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_ODUMIN", 15, nil, "Odumin_Loop", 0)
                Story_Event("CSA_ERAONE_STARTED")
			elseif Find_Player("local") == Find_Player("Hutt_Cartels") then
                StoryUtil.Multimedia("TEXT_CONQUEST_HUTTS_BORGA_INTRO", 15, nil, "Jabba_Loop", 0)
                Story_Event("HUTTS_BORGA_STARTED")
            end

            self.AI_Active = false
			if not infinity then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSevenStartSet")
				for faction, herolist in pairs(self.Starting_Spawns) do
                    for planet, spawnlist in pairs(herolist) do
                        local safe_spawnlist = SanitizeSpawnList(self, faction, spawnlist) --Sanitize spawn list
                        if safe_spawnlist and table.getn(safe_spawnlist) > 0 then --make sure there are units to spawn after sanitization
                            StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, safe_spawnlist)
                        end
                    end
				end
			end

            if self.Active_Planets["BYSS"] then
                Destroy_Planet("Byss")
            end
            if self.Active_Planets["DA_SOOCHA"] then
                Destroy_Planet("Da_Soocha")
            end
            if self.Active_Planets["CARIDA"] then
                Destroy_Planet("Carida")
            end
            if self.Active_Planets["EOLSHA"] then
                Destroy_Planet("EolSha")
            end
        else
			if Find_First_Object("Custom_GC_Starter_Dummy") == nil then
				self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSevenProgressSet")
				for faction, herolist in pairs(self.Starting_Spawns) do
                    for planet, spawnlist in pairs(herolist) do
                        local safe_spawnlist = SanitizeSpawnList(self, faction, spawnlist) --Sanitize spawn list
                        if safe_spawnlist and table.getn(safe_spawnlist) > 0 then --make sure there are units to spawn after sanitization
                            StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, safe_spawnlist)
                        end
                    end
				end
			end

            crossplot:publish("CONQUER_NZOTH", "empty")
            crossplot:publish("ERA_TRANSITION", 7)
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
            crossplot:publish("CONQUER_NZOTH", "empty")
            -- Subscribe to the Proteus Conquer Coruscant event, can expand with other events here
            if GlobalValue.Get("PROTEUS_MAP_SETTINGS") then
                crossplot:publish("PROTEUS_CONQUER_CORUSCANT", "empty")
            end
            
            self.AI_Active = true
			if not GlobalValue.Get("PROGRESSIVE_INFINITY") then
				crossplot:publish("INITIALIZE_AI", "empty")
			end
        end
    end,

    on_exit = function(self, state_context)
    end
}