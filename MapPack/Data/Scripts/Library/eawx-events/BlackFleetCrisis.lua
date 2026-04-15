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

	--TechSupport: Planets are not locked if we are in the Proteus GC, so dont need to unlock them.
	local proteus_map_settings = GlobalValue.Get("PROTEUS_MAP_SETTINGS")
    if not proteus_map_settings then
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
