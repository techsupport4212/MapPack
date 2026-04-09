require("eawx-util/StoryUtil")
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
        GlobalValue.Set("CURRENT_ERA", 1)
		local infinity = GlobalValue.Get("PROGRESSIVE_INFINITY")

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

        if Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_WARLORDS_NR_INTRO_MOTHMA", 15, nil, "Mon_Mothma_Loop", 0)
            Story_Event("NEWREP_PESTAGE_STARTED")
        elseif Find_Player("local") == Find_Player("Pentastar") then
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
        elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EOTH_INTRO_E1", 15, nil, "Thrawn_Loop", 0)
            Story_Event("HAND_ERAONE_STARTED")
        elseif Find_Player("local") == Find_Player("Hapes_Consortium") then
            StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_TAA_ONE", 15, nil, "TaaChume_Loop", 0)
            Story_Event("HAPES_TAA_START")
        elseif Find_Player("local") == Find_Player("Corporate_Sector") then
            StoryUtil.Multimedia("TEXT_CONQUEST_INTRO_ODUMIN", 15, nil, "Odumin_Loop", 0)
            Story_Event("CSA_ERAONE_STARTED")
		elseif Find_Player("local") == Find_Player("Hutt_Cartels") then
                StoryUtil.Multimedia("TEXT_CONQUEST_HUTTS_DURGA_INTRO", 15, nil, "Durga_Loop", 0)
                Story_Event("HUTTS_DURGA_STARTED")
        end

        self.AI_Active = false
		if not infinity then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraOneStartSet")
            self.LegitimacyHeroes = require("LegitimacyHeroLibrary") --Uses a library of legitimacy heroes to determine who to keep / remove
			for faction, herolist in pairs(self.Starting_Spawns) do
				for planet, spawnlist in pairs(herolist) do
                    local safe_spawnlist = SanitizeSpawnList(self, faction, spawnlist) --Sanitize spawn list
                    if safe_spawnlist and table.getn(safe_spawnlist) > 0 then --make sure there are units to spawn after sanitization
                        StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, safe_spawnlist)
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
