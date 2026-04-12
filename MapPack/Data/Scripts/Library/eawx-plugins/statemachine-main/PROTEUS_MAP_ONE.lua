-- TechSupport: This is the new state machine for the Proteus GC Map, it is responsible for handling tech level progression and era changes. Currently a clone of the progressive state machine, will be expanded upon later
require("deepcore/statemachine/DeepCoreState")

---@param dsl dsl
return function(dsl)
    local policy = dsl.policy
    local effect = dsl.effect
    local owned_by = dsl.conditions.owned_by

    local initialize = DeepCoreState.with_empty_policy()
    local setup = DeepCoreState(require("eawx-states/tr-setup-state"))
    local era_one = DeepCoreState(require("eawx-states/tr-progressive-era-one"))
    local era_two = DeepCoreState(require("eawx-states/tr-progressive-era-two"))
    local era_three = DeepCoreState(require("eawx-states/tr-progressive-era-three"))
    local era_four = DeepCoreState(require("eawx-states/tr-progressive-era-four"))
    local era_five = DeepCoreState(require("eawx-states/tr-progressive-era-five"))
    local era_six = DeepCoreState(require("eawx-states/tr-progressive-era-six"))
    local era_seven = DeepCoreState(require("eawx-states/tr-progressive-era-seven"))

    dsl.transition(initialize)
        :to(setup)
        :when(policy:timed(3))
        :end_()

    dsl.transition(setup)
        :to(era_one)
        :when(policy:global_era(1))
        :with_effects(
            effect:eawx_set_tech_level(1)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(setup)
        :to(era_two)
        :when(policy:global_era(2))
        :with_effects(
            effect:eawx_set_tech_level(1)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(setup)
        :to(era_three)
        :when(policy:global_era(3))
        :with_effects(
            effect:eawx_set_tech_level(1)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(setup)
        :to(era_four)
        :when(policy:global_era(4))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(setup)
        :to(era_five)
        :when(policy:global_era(5))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(setup)
        :to(era_six)
        :when(policy:global_era(6))
        :with_effects(
            effect:eawx_set_tech_level(3)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(setup)
        :to(era_seven)
        :when(policy:global_era(7))
        :with_effects(
            effect:eawx_set_tech_level(3)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    dsl.transition(era_one)
        :to(era_two)
        :when(policy:timed(960))
        :end_()

    dsl.transition(era_two)
        :to(era_three)
        :when(policy:timed(1440))
        :end_()

    dsl.transition(era_three)
        :to(era_four)
        :when(policy:timed(480))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    dsl.transition(era_four)
        :to(era_five)
        :when(policy:timed(480))
        :end_()

    dsl.transition(era_five)
        :to(era_six)
        :when(policy:timed(240))
        :with_effects(
            effect:eawx_set_tech_level(3)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    dsl.transition(era_six)
        :to(era_seven)
        :when(policy:timed(240))
        :end_()

    return initialize
end
