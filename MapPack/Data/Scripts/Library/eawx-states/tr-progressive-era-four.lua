require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("eawx-util/ChangeOwnerUtilities")
require("PGStoryMode")
require("PGSpawnUnits")

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
        GlobalValue.Set("CURRENT_ERA", 4)
        local infinity = GlobalValue.Get("PROGRESSIVE_INFINITY")

        self.LegitimacyHeroes = require("LegitimacyHeroLibrary") --Uses a library of legitimacy heroes to determine who to keep / remove

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
            if not infinity then
                self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFourStartSet")
                for faction, herolist in pairs(self.Starting_Spawns) do
                    for planet, spawnlist in pairs(herolist) do
                        local safe_spawnlist = SanitizeSpawnList(self, faction, spawnlist) --Sanitize spawn list
                        if safe_spawnlist and table.getn(safe_spawnlist) > 0 then --make sure there are units to spawn after sanitization
                            StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, safe_spawnlist)
                        end
                    end
                end
            end

            if Find_Player("local") == Find_Player("Rebel") then
                StoryUtil.Multimedia("TEXT_CONQUEST_OPERATIONSHADOWHAND_NR_INTRO_TWO", 15, nil, "Mon_Mothma_Loop", 0)
                Story_Event("NEWREP_PALPATINE_STARTED")
            elseif Find_Player("local") == Find_Player("Pentastar") then
                StoryUtil.Multimedia("TEXT_CONQUEST_PENTASTAR_INTRO_E4", 15, nil, "Kaine_Loop", 0)
                Story_Event("PENTASTAR_ERAFOUR_STARTED")
            elseif Find_Player("local") == Find_Player("Eriadu_Authority") then
                StoryUtil.Multimedia("TEXT_CONQUEST_ERIADU_INTRO_E4", 15, nil, "Delvardus_Loop", 0)
                Story_Event("ERIADU_ERAFOUR_STARTED")
            elseif Find_Player("local") == Find_Player("Greater_Maldrood") then
                StoryUtil.Multimedia("TEXT_CONQUEST_MALDROOD_INTRO_E4", 15, nil, "Treuten_Teradoc_Loop", 0)
                Story_Event("MALDROOD_ERAFOUR_STARTED")
            elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EOTH_INTRO_E4", 15, nil, "Parck_Loop", 0)
                Story_Event("HAND_ERAFOUR_STARTED")
            elseif Find_Player("local") == Find_Player("Hapes_Consortium") then
                StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_TENENIEL_ONE", 15, nil, "Teneniel_Loop", 0)
                Story_Event("HAPES_TENENIEL_START")
            elseif Find_Player("local") == Find_Player("Corporate_Sector") then
                StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_ODUMIN", 15, nil, "Odumin_Loop", 0)
                Story_Event("CSA_ERAONE_STARTED")
			elseif Find_Player("local") == Find_Player("Hutt_Cartels") then
                StoryUtil.Multimedia("TEXT_CONQUEST_HUTTS_DURGA_DE_INTRO", 15, nil, "Durga_Loop", 0)
                Story_Event("HUTTS_DURGA_DE_STARTED")
            end

            self.AI_Active = false
        else
			if Find_First_Object("Custom_GC_Starter_Dummy") == nil then
				self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFourProgressSet")
				for faction, herolist in pairs(self.Starting_Spawns) do
                    for planet, spawnlist in pairs(herolist) do
                        local safe_spawnlist = SanitizeSpawnList(self, faction, spawnlist) --Sanitize spawn list
                        if safe_spawnlist and table.getn(safe_spawnlist) > 0 then --make sure there are units to spawn after sanitization
                            StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, safe_spawnlist)
                        end
                    end
				end
			end

            UnitUtil.ReplaceAtLocation("Ackbar_Home_One", "Ackbar_Galactic_Voyager")
            Transfer_Fighter_Hero("Ackbar_Home_One", "Ackbar_Galactic_Voyager")

            UnitUtil.DespawnList{
                "Mon_Mothma"
            }

            crossplot:publish("ERA_TRANSITION", 4)
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
            -- Subscribe to the Proteus Conquer Coruscant event, can expand with other events here
            --if GlobalValue.Get("PROTEUS_MAP_SETTINGS") then
                --crossplot:publish("PROTEUS_CONQUER_CORUSCANT", "empty")
            --end
            if not GlobalValue.Get("PROGRESSIVE_INFINITY") then
                crossplot:publish("INITIALIZE_AI", "empty")
            end
            self.AI_Active = true
        end
    end,

    on_exit = function(self, state_context)
    end
}