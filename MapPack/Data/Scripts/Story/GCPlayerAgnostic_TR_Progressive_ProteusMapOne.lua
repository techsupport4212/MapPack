--TechSupport: Player-agnostic script for Proteus Map One, which applies the correct settings and starts the state machine based on the player's current tech level. 
require("PGStoryMode")

require("eawx-util/StoryUtil")
require("deepcore/std/deepcore")
require("deepcore-extensions/initialize")

require("eawx-statemachine/dsl/TransitionPolicyFactory")
require("eawx-statemachine/dsl/TransitionEffectBuilderFactory")

function Definitions()
    DebugMessage("%s -- In Definitions", tostring(Script))

    ServiceRate = 0.1

    StoryModeEvents = {Zoom_Zoom = Begin_GC}
end

function Begin_GC(message)
    if message == OnEnter then
        CONSTANTS = ModContentLoader.get("GameConstants")
        GameObjectLibrary = ModContentLoader.get("GameObjectLibrary")
        local plot = StoryUtil.GetPlayerAgnosticPlot()
        GlobalValue.Set("PROTEUS_MAP_SETTINGS", true)
        local message = "Proteus Map One state machine active" --temporary message, should be improved before release

        -- logic to set correct mode, potential to expand in future for more preselecable options
        if Find_Player("local").Get_Tech_Level() > 4 then
            GlobalValue.Set("CUSTOM_LEARNER_MODE", true)
            GlobalValue.Set("PROGRESS_REGIME", false)
        elseif Find_Player("local").Get_Tech_Level() > 3 then
            GlobalValue.Set("PROGRESS_REGIME", true)
        elseif Find_Player("local").Get_Tech_Level() > 2 then
            message = "Initialising Proteus Map One state machine (Era 1)"
            GlobalValue.Set("PROTEUS_INFINITY", true)
            GlobalValue.Set("PROGRESS_REGIME", false)
        else
            GlobalValue.Set("PROGRESSIVE_INFINITY", 1)
            GlobalValue.Set("PROGRESS_REGIME", false)
        end

        StoryUtil.ShowScreenText(message, 20)

        local era = 1

        local credits = Find_Player("local").Get_Credits()
        Find_Player("local").Give_Money(10000 - credits)

        local era_dummies = {
            "Era_One_Dummy",
            "Era_Two_Dummy",
            "Era_Three_Dummy",
            "Era_Four_Dummy",
            "Era_Five_Dummy",
            "Era_Six_Dummy",
            "Era_Seven_Dummy",
            "Era_Eight_Dummy",
            "Era_Nine_Dummy",
            "Era_Ten_Dummy",
            "Era_Eleven_Dummy",
            "Era_Twelve_Dummy",
            "Era_Thirteen_Dummy",
            "Era_Fourteen_Dummy",
        }

        for i, dummy in pairs(era_dummies) do
            local era_indicator = Find_First_Object(dummy)
            if era_indicator then
                era = i
                era_indicator.Despawn()
            end
        end

        GlobalValue.Set("CURRENT_ERA", era)
        GlobalValue.Set("REGIME_INDEX", era)

        local ccogm_dummy = Find_First_Object("CCoGM_Dummy")
        if ccogm_dummy then
            GlobalValue.Set("SELECTED_REGIME", 22)
            ccogm_dummy.Despawn()
        else
            GlobalValue.Set("SELECTED_REGIME", era)
        end

        local year_start = 4
        local month_start = 1
        if era == 2 then
            year_start = 6
        elseif era == 3 then
            year_start = 9
        elseif era == 4 then
            year_start = 10
        elseif era == 5 then
            year_start = 11
        elseif era == 6 then
            year_start = 11
            month_start = 7
        elseif era == 7 then
            year_start = 12
        end

        local plugin_list = ModContentLoader.get("InstalledPlugins")
        local context = {
            plot = plot,
            maxroutes = 6,
            id = "PROTEUS_MAP_ONE",
            year_start = year_start,
            month_start = month_start,
            unlocktech = true,
            is_generated = true,
            statemachine_dsl_config = {
                transition_policy_factory = EawXTransitionPolicyFactory,
                transition_effect_builder_factory = EawXTransitionEffectBuilderFactory
            }
        }

        ActiveMod = deepcore:galactic {
            context = context,
            plugins = plugin_list,
            plugin_folder = "eawx-plugins",
            planet_factory = function(planet_name)
                local Planet = require("deepcore-extensions/galaxy/Planet")
                return Planet(planet_name)
            end
        }

    elseif message == OnUpdate then
        ActiveMod:update()
    end
end
