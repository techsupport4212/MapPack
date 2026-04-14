require("PGStoryMode")
require("deepcore/crossplot/crossplot")
require("eawx-util/StoryUtil")

function Definitions()
	DebugMessage("%s -- In Definitions", tostring(Script))

	StoryModeEvents = {
		Trigger_Delayed_Initialize = State_Delayed_Initialize
	}

	warlord_selected = false

	crossplot:galactic()
end

function State_Delayed_Initialize(message)
	if not warlord_selected then
		if not Find_Player("Imperial_Proteus").Is_Human() then
			message = "Warlord Selector Initialised" --temporary message, should be improved before release
			StoryUtil.ShowScreenText(message, 20)
			crossplot:publish("WARLORD_START")
		end
		warlord_selected = true
	else
		crossplot:update()
	end
end

