-- TechSupport: This is the new state machine for the Proteus GC Map, it is responsible for handling tech level progression and era changes. Currently a clone of the progressive state machine, will be expanded upon later

require("deepcore/statemachine/DeepCoreState")

---@param dsl dsl
return function(dsl)
    local policy = dsl.policy
    local effect = dsl.effect
    local owned_by = dsl.conditions.owned_by
    local is_ai = dsl.conditions.is_ai

    local initialize = DeepCoreState.with_empty_policy()
    local setup = DeepCoreState(require("eawx-states/regimes/regime-setup-state"))
    local pestage = DeepCoreState(require("eawx-states/regimes/regime-pestage-proteus"))
    local isard = DeepCoreState(require("eawx-states/regimes/regime-isard-proteus"))
    local ccogm = DeepCoreState(require("eawx-states/regimes/regime-ccogm-proteus"))
    local thrawn = DeepCoreState(require("eawx-states/regimes/regime-thrawn-proteus"))
    local interregnum = DeepCoreState(require("eawx-states/regimes/regime-interregnum-proteus"))
    local palpatine = DeepCoreState(require("eawx-states/regimes/regime-palpatine-proteus"))
    local jax = DeepCoreState(require("eawx-states/regimes/regime-jax-proteus"))
    local daala = DeepCoreState(require("eawx-states/regimes/regime-daala-proteus"))
    local pellaeon = DeepCoreState(require("eawx-states/regimes/regime-pellaeon-proteus"))

    -- Initial setup

    dsl.transition(initialize)
        :to(setup)
        :when(policy:timed(3))
        :end_()
    dsl.transition(setup)
        :to(pestage)
        :when(policy:selected_regime_index(1))
        :end_()
    dsl.transition(setup)
        :to(isard)
        :when(policy:selected_regime_index(2))
        :end_()
    dsl.transition(setup)
        :to(ccogm)
        :when(policy:selected_regime_index(22)) --Regime 2, in second set, therefore 22
        :end_()
    dsl.transition(setup)
        :to(thrawn)
        :when(policy:selected_regime_index(3))
        :end_()
    dsl.transition(setup)
        :to(palpatine)
        :when(policy:selected_regime_index(4))
        :end_()
    dsl.transition(setup)
        :to(jax)
        :when(policy:selected_regime_index(5))
        :end_()
    dsl.transition(setup)
        :to(daala)
        :when(policy:selected_regime_index(6))
        :end_()
    dsl.transition(setup)
        :to(pellaeon)
        :when(policy:selected_regime_index(7))
        :end_()


    -- Exiting Pestage

    dsl.transition(pestage)
        :to(isard)
        :when(policy:hero_dies("Pestage_Team"))
        :with_effects(
            effect:transfer_planets("KESSEL")
            :to_owner("Warlords")
            :if_(owned_by("Empire")),
            effect:transfer_planets("KALIST", "ABREGADO_RAE")
            :to_owner("Warlords")
            :if_(owned_by("Empire"))
        ):end_()
    dsl.transition(pestage)
        :to(isard)
        :when(policy:planet_lost("CORUSCANT","EMPIRE"))
        :with_effects(
            effect:transfer_planets("KESSEL")
            :to_owner("Warlords")
            :if_(owned_by("Empire")),
            effect:transfer_planets("KALIST", "ABREGADO_RAE")
            :to_owner("Warlords")
            :if_(owned_by("Empire"))
        ):end_()
    dsl.transition(pestage)
        :to(isard)
        :when(policy:object_constructed("Project_Ambition_Dummy"))
        :end_()
    dsl.transition(pestage)
        :to(isard)
        :when(
            policy:mtth(48, 40) --canonically lasts 24 months (x2)
            :if_(is_ai("Empire"))
        ):end_()
    dsl.transition(pestage)
        :to(ccogm)
        :when(policy:object_constructed("Dummy_Regicide_CCoGM"))
        :with_effects(
            effect:transfer_planets("THYFERRA")
            :to_owner("Warlords")
            :if_(owned_by("Empire"))
        ):end_()

    -- Exiting Isard/CCoGM

    dsl.transition(isard)
        :to(thrawn)
        :when(policy:hero_dies("Ysanne_Isard_Team"))
        :end_()
    dsl.transition(isard)
        :to(thrawn)
        :when(policy:hero_dies("Isard_Lusankya"))
        :end_()
    dsl.transition(isard)
        :to(thrawn)
        :when(policy:object_constructed("Dummy_Regicide_Thrawn"))
        :end_()
    dsl.transition(isard)
        :to(thrawn)
        :when(
            policy:mtth(72, 40) -- canonically lasts 36 months (x2)
            :if_(is_ai("Empire"))
        ):end_()
    dsl.transition(ccogm)
        :to(thrawn)
        :when(policy:hero_dies("Hissa_Moffship"))
        :end_()
    dsl.transition(ccogm)
        :to(thrawn)
        :when(policy:object_constructed("Dummy_Regicide_Thrawn"))
        :end_()
    dsl.transition(ccogm)
        :to(thrawn)
        :when(
            policy:mtth(72, 40) -- see above
            :if_(is_ai("Empire"))
        ):end_()

    --Exiting Thrawn
   
    dsl.transition(thrawn)
        :to(interregnum)
        :when(policy:hero_dies("Thrawn_Chimaera"))
        :with_effects(
            effect:transfer_planets("CIUTRIC", "VROSYNRI", "CORVIS_MINOR")
            :to_owner("Warlords")
            :if_(owned_by("Empire"))
        ):end_()

    -- Entering Dark Empire

    dsl.transition(pestage)
        :to(palpatine)
        :when(policy:crossplot_trigger("STATE_TRANSITION_DARK_EMPIRE"))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    dsl.transition(isard)
        :to(palpatine)
        :when(policy:crossplot_trigger("STATE_TRANSITION_DARK_EMPIRE"))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    dsl.transition(ccogm)
        :to(palpatine)
        :when(policy:crossplot_trigger("STATE_TRANSITION_DARK_EMPIRE"))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    dsl.transition(thrawn)
        :to(palpatine)
        :when(policy:crossplot_trigger("STATE_TRANSITION_DARK_EMPIRE"))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
   
    dsl.transition(interregnum)
        :to(palpatine)
        :when(policy:crossplot_trigger("STATE_TRANSITION_DARK_EMPIRE"))
        :with_effects(
            effect:eawx_set_tech_level(2)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    -- Exiting Dark Empire

    dsl.transition(palpatine)
        :to(jax)
        :when(policy:object_constructed("DUMMY_REGICIDE_JAX"))
        :end_()
    dsl.transition(palpatine)
        :to(jax)
        :when(policy:hero_dies("Emperor_Palpatine_Team"))
        :end_()
    dsl.transition(palpatine)
        :to(jax)
        :when(policy:hero_dies("Dark_Empire_Cloning_Facility"))
        :end_()

    -- Exiting Jax

    dsl.transition(jax)
        :to(daala)
        :when(policy:hero_dies("Carnor_Jax_Team"))
        :with_effects(
            effect:eawx_set_tech_level(3)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(jax)
        :to(daala)
        :when(policy:object_constructed("Dummy_Regicide_Daala"))
        :with_effects(
            effect:eawx_set_tech_level(3)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()
    dsl.transition(jax)
        :to(daala)
        :when(
            policy:mtth(24, 40) --canonically lasts 6 months (x4)
            :if_(is_ai("GLOBALVALUE@IMPERIAL_REGIME_HOST"))
        )
        :with_effects(
            effect:eawx_set_tech_level(3)
            :for_factions({"Rebel", "Empire", "Pentastar", "Eriadu_Authority", "Zsinj_Empire", "Greater_Maldrood", "EmpireoftheHand", "Corporate_Sector", "Hapes_Consortium", "Yevetha", "Hutt_Cartels","Imperial_Proteus"})
        ):end_()

    -- Exiting Daala

    dsl.transition(daala)
        :to(pellaeon)
        :when(policy:hero_dies("Daala_Gorgon"))
        :end_()
    dsl.transition(daala)
        :to(pellaeon)
        :when(policy:hero_dies("Daala_Knight_Hammer"))
        :end_()
    dsl.transition(daala)
        :to(pellaeon)
        :when(policy:object_constructed("Dummy_Regicide_Pellaeon"))
        :end_()
    dsl.transition(daala)
        :to(pellaeon)
        :when(
            policy:mtth(24, 40) --canonically lasts 6 months (x4)
            :if_(is_ai("GLOBALVALUE@IMPERIAL_REGIME_HOST"))
        ):end_()

    return initialize
end
