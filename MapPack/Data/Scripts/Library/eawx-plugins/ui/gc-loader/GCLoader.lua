--******************************************************************************
--     _______ __
--    |_     _|  |--.----.---.-.--.--.--.-----.-----.
--      |   | |     |   _|  _  |  |  |  |     |__ --|
--      |___| |__|__|__| |___._|________|__|__|_____|
--     ______
--    |   __ \.-----.--.--.-----.-----.-----.-----.
--    |      <|  -__|  |  |  -__|     |  _  |  -__|
--    |___|__||_____|\___/|_____|__|__|___  |_____|
--                                    |_____|
--*   @Author:              [TR]Pox <Pox>
--*   @Date:                2018-01-13T11:47:17+01:00
--*   @Project:             Imperial Civil War
--*   @Filename:            GCLoader.lua
--*   @Last modified by:    [TR]Pox
--*   @Last modified time:  2018-03-27T03:41:19+02:00
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************

require("PGSpawnUnits")
require("deepcore/std/class")
CONSTANTS = ModContentLoader.get("GameConstants")

---@class GCLoader
GCLoader = class()

function GCLoader:new()
    local all_planets = FindPlanet.Get_All_Planets()

    self.planet_name = nil
    for _, planet in ipairs(all_planets) do
        self.planet_name = planet.Get_Type().Get_Name()
    end

    self.faction_index = 0
    self.faction_name = "REBEL"
    for faction, id in pairs(CONSTANTS.LIVE_FACTION_TABLE) do
        if Find_Player(faction).Is_Human() then
        self.faction_index = id
        self.faction_name = faction
        break
        end
    end

    self.chosen_era = nil
    self.era_list = {"1", "2", "3", "4", "5", "6", "7"}
    self.initial_popup = false

    if self.planet_name == "FROMTHEGROUNDUP" or self.planet_name == "ALSAKAN" then
        self.initial_popup = true
        return --Infinities have their own loader

    elseif self.planet_name == "BORDERLANDS" then
        if Find_Player("Zsinj_Empire").Is_Human() then
            self.era_list = {"1", "2", "3"}
        elseif Find_Player("Corporate_Sector").Is_Human() then
            self.era_list = {"1","3", "4", "5", "6", "7"}
        elseif Find_Player("Empire").Is_Human() then
            self.era_list = {"1", "2", "3","5", "6", "7"}
        end

    elseif self.planet_name == "ETTI" then
        if Find_Player("Zsinj_Empire").Is_Human() then
            self.era_list = {"1", "2", "3"}
        elseif Find_Player("Empire").Is_Human() then
            self.era_list = {"1", "3", "4"}
        elseif Find_Player("Greater_Maldrood").Is_Human() then
            self.era_list = {"3"}
        elseif Find_Player("Hutt_Cartels").Is_Human() then
            self.era_list = {"7"}
        end
        self.planet_name = "CorporateAcquisitions"

    elseif self.planet_name == "KAMPE" then
        if Find_Player("Eriadu_Authority").Is_Human() then
            self.era_list = {"3", "4", "6"}
        else
            self.era_list = {"1", "3", "4", "6"}
        end
        self.planet_name = "DeepCoreConflict"

    elseif self.planet_name == "EMPIRES_AT_WAR" then
        self.era_list = {"1", "2", "3"}

    --TechSupport: specify eras for proteus map
    elseif self.planet_name == "PROTEUS_MAP_ONE" then
        self.era_list = {"1", "7"}

    elseif self.planet_name == "STARS_ALIGN" then
        if Find_Player("Pentastar").Is_Human() then
            self.era_list = {"1", "3", "4", "5", "6"}
        else
            self.era_list = {"1", "3", "4", "5", "6", "7"}
        end

    elseif self.planet_name == "WESTERNREACHES" then
        self.era_list = {"1", "2"}

    else
        -- Main progressives
        if Find_Player("Corporate_Sector").Is_Human() then
            self.era_list = {"1", "3", "4", "5", "6", "7"}
        elseif Find_Player("Pentastar").Is_Human() then
            self.era_list = {"1", "2", "3", "4", "5", "6"}
        elseif Find_Player("Eriadu_Authority").Is_Human() then
            self.era_list = {"1", "2", "3", "4", "5", "6"}
        elseif Find_Player("Zsinj_Empire").Is_Human() then
            if self.planet_name == "KNOWNMEDIUM" or self.planet_name == "KNOWNLARGE" or self.planet_name == "FULLLARGE"  then
                self.era_list = {"1", "2", "3"}
            else
                self.era_list = {"1", "2"}
            end
        end
    end

    self.name = self.planet_name.."_Era_"..tostring(era).."_"..self.faction_name

    crossplot:subscribe("PROGRESSIVE_START_OPTION", self.Handle_Input, self)
    crossplot:subscribe("REGIME_CHOICE_OPTION", self.Load_GC, self)
end

function GCLoader:update()
    if self.initial_popup == false and GetCurrentTime() > 3 then
        self.initial_popup = true

        if string.find(self.planet_name, "EMPIREREGIMEPICKER") then
            self.planet_name = string.gsub(self.planet_name, "EMPIREREGIMEPICKER", "")
            self.chosen_era = "2"
            self:Regime_Choice()
        else
            self:Initialize()
        end
    end
end

function GCLoader:Initialize()
    GenericPopup("PROGRESSIVE_START", self.era_list, "PROGRESSIVE_START_OPTION")
end

function GCLoader:Handle_Input(choice)
    if not choice then
        return
    end

    self.chosen_era = string.gsub(choice, "PROGRESSIVE_START_", "")

    if (string.find(string.upper(self.planet_name), "KNOWN") or string.find(string.upper(self.planet_name), "FULL") or string.find(string.upper(self.planet_name), "AT_WAR") or string.find(string.upper(self.planet_name), "WESTERNREACHES") or string.find(string.upper(self.planet_name), "BORDERLANDS") or string.find(string.upper(self.planet_name), "STARS_ALIGN")) and self.chosen_era == "2" and self.faction_name == "EMPIRE" then
        self:Regime_Choice()
    else
        self:Load_GC()
    end
end

function GCLoader:Regime_Choice()
    GenericPopup("REGIME_CHOICE", {"ISARD", "CCOGM"}, "REGIME_CHOICE_OPTION")
end

function GCLoader:Load_GC(regime_choice)
    self.name = self.planet_name.."_Era_"..self.chosen_era.."_"..self.faction_name

    if regime_choice then
        if regime_choice == "REGIME_CHOICE_CCOGM" then
            self.name = self.name.."_CCoGM"
        end
    end

    local difficulty = Find_Player("Empire").Get_Difficulty()
    if self.faction_name == "EMPIRE" then
        difficulty = Find_Player("Rebel").Get_Difficulty()
    end
    local difficulty_index = 1
    if difficulty == "Easy" then
        difficulty_index = 0
    elseif difficulty == "Hard" then
        difficulty_index = 2
    end

    StoryUtil.LoadCampaign(self.name, self.faction_index, difficulty_index)
end

return GCLoader
