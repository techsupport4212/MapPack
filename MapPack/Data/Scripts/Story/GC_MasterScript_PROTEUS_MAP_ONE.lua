require("PGStoryMode")
require("deepcore/crossplot/crossplot")
require("eawx-util/StoryUtil")

function Definitions()
	DebugMessage("%s -- In Definitions", tostring(Script))

	StoryModeEvents = {
		Trigger_Warlord_Start = State_Warlord_Start
	}

	warlord_selected = false

	crossplot:galactic()
end

function State_Warlord_Start(message)
	if not warlord_selected then
		message = "Warlord Selector Initialised" --temporary message, should be improved before release
		StoryUtil.ShowScreenText(message, 20)
		crossplot:publish("WARLORD_START")
		warlord_selected = true
	end
end

