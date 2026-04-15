-- TechSupport: This is the new event handler for the Proteus GC Map.
require("deepcore/std/class")
-- require("eawx-events/GenericResearch")
-- require("eawx-events/GenericSwap")
require("eawx-events/GenericConquer")
-- require("eawx-events/GenericPopup")
require("eawx-events/FelChildren")
require("eawx-events/EmpireReborn")
require("eawx-events/BlackFleetCrisis")
require("eawx-events/DummyBuildExtras")

---@class EventManager
EventManager = class()
 
function EventManager:new(galactic_conquest)
    self.galactic_conquest = galactic_conquest
    self.warlord_start = false

    self.ConquerKashyyykMaldrood = GenericConquer(self.galactic_conquest,
        "CONQUER_KASHYYYK_MALDROOD",
        "KASHYYYK", {"Greater_Maldrood"},
        {"Syn_Silooth"}, false, "Syn_Loop", nil, nil, nil, {"IMPERIAL_PROTEUS"})
    -- Added Proteus specific event when they conquer Coruscant, will be used to reward the player. Reward TBD
    self.ProteusConquerCoruscant = GenericConquer(self.galactic_conquest,
        "PROTEUS_CONQUER_CORUSCANT",
        "CORUSCANT", {"IMPERIAL_PROTEUS"},
        nil, false, "Syn_Loop", nil, nil, {"PROTEUS_GENERIC_CONQUER"})
                    -- Uses Syn_Loop as a placeholder, should be replaced with a generic officer / moff loop
    self.ConquerCentaresZsinj = GenericConquer(self.galactic_conquest,
        "CONQUER_CENTARES_ZSINJ",
        "CENTARES", {"Zsinj_Empire"},
        {"Selit_Team"}, false)

    self.ConquerMandaloreNewRepublic = GenericConquer(self.galactic_conquest,
        "CONQUER_MANDALORE_NR",
        "MANDALORE", {"Rebel"},
        {"Fenn_Shysa_Team"}, false, "Boba_Fett_Loop")

    self.DummyBuildExtras = DummyBuildExtras(self.galactic_conquest)
    self.EmpireReborn = EmpireReborn(self.galactic_conquest)
    self.FelChildren = FelChildren(self.galactic_conquest)
    self.BlackFleetCrisis = BlackFleetCrisis(self.galactic_conquest)
end

function EventManager:update()
    if self.warlord_start == true then
        return
    end

    if GetCurrentTime() < 6 then
        return
    end
    message = "Warlord Selector Initialised" --temporary message, should be improved before release
    StoryUtil.ShowScreenText(message, 20)
    crossplot:publish("WARLORD_START")
    self.warlord_start = true
end

return EventManager
