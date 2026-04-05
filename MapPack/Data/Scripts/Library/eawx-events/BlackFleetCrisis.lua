require("deepcore/std/class")
require("eawx-util/StoryUtil")

---@class BlackFleetCrisis
BlackFleetCrisis = class()

function BlackFleetCrisis:new(gc)
	crossplot:subscribe("BLACK_FLEET_CRISIS", self.emerge, self)
end

function BlackFleetCrisis:emerge()
	--Logger:trace("entering BlackFleetCrisis:emerge")
	local Active_Planets = StoryUtil.GetSafePlanetTable()

	--TechSupport: Planet locks based on infinity mode
	local proteus_infinity = GlobalValue.Get("PROTEUS_INFINITY")
    if not proteus_infinity then
		StoryUtil.SetPlanetRestricted("DOORNIK", 0)
		StoryUtil.SetPlanetRestricted("ZFELL", 0)
		StoryUtil.SetPlanetRestricted("NZOTH", 0)
		StoryUtil.SetPlanetRestricted("JTPTAN", 0)
		StoryUtil.SetPlanetRestricted("POLNEYE", 0)
		StoryUtil.SetPlanetRestricted("PRILDAZ", 0)
		
		if Active_Planets["NZOTH"] then
			if Find_Player("local") ~= Find_Player("Yevetha") then
				StoryUtil.Multimedia("TEXT_CONQUEST_BFC_DL_INTRO_GENERIC", 15, nil, "NilSpaar_Loop", 0)
			end
		end
	end
end

return BlackFleetCrisis
