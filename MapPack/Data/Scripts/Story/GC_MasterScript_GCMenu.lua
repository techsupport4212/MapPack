require("PGStoryMode")
require("deepcore/crossplot/crossplot")
require("eawx-util/StoryUtil")
require("eawx-util/StringUtil")
require("eawx-events/GenericPopup")
CONSTANTS = ModContentLoader.get("GameConstants")

function Definitions()
	DebugMessage("%s -- In Definitions", tostring(Script))

	StoryModeEvents = {
		Trigger_Load_GC_Selector = State_Load_GC_Selector,
		faction_01_click = clicked_faction_01,
		faction_02_click = clicked_faction_02,
		faction_03_click = clicked_faction_03,
		faction_04_click = clicked_faction_04,
		faction_05_click = clicked_faction_05,
		faction_06_click = clicked_faction_06,
		faction_07_click = clicked_faction_07,
		faction_08_click = clicked_faction_08,
		faction_09_click = clicked_faction_09,
		faction_10_click = clicked_faction_10,
		faction_11_click = clicked_faction_11,
		faction_12_click = clicked_faction_12,
		faction_13_click = clicked_faction_13,
		faction_14_click = clicked_faction_14,
		faction_15_click = clicked_faction_15,
		faction_16_click = clicked_faction_16,
		--faction_17_click = clicked_faction_17, function on line 376 is disabled
		era_01_click = clicked_era_01,
		era_02_click = clicked_era_02,
		era_03_click = clicked_era_03,
		era_04_click = clicked_era_04,
		era_05_click = clicked_era_05,
		era_06_click = clicked_era_06,
		era_07_click = clicked_era_07,
		era_08_click = clicked_era_08,
		era_09_click = clicked_era_09,
		era_10_click = clicked_era_10,
		era_11_click = clicked_era_11,
		Minor_Warlords_Faction_Selected = Enable_Protean,
		Minor_Warlords_Faction_Unselected = Disable_Protean,
		prog_map_01_click = clicked_prog_map_01,
		prog_map_02_click = clicked_prog_map_02,
		prog_map_03_click = clicked_prog_map_03,
		prog_map_04_click = clicked_prog_map_04,
		prog_map_05_click = clicked_prog_map_05,
		prog_map_06_click = clicked_prog_map_06,
		reg_map_01_click = clicked_reg_map_01,
		reg_map_02_click = clicked_reg_map_02,
		reg_map_03_click = clicked_reg_map_03,
		reg_map_04_click = clicked_reg_map_04,
		reg_map_05_click = clicked_reg_map_05,
		hist_map_01_click = clicked_hist_map_01,
		hist_map_02_click = clicked_hist_map_02,
		hist_map_03_click = clicked_hist_map_03,
		hist_map_04_click = clicked_hist_map_04,
		hist_map_05_click = clicked_hist_map_05,
		hist_map_06_click = clicked_hist_map_06,
		hist_map_07_click = clicked_hist_map_07,
		hist_map_08_click = clicked_hist_map_08,
		hist_map_09_click = clicked_hist_map_09,
		hist_map_10_click = clicked_hist_map_10,
		inf_map_01_click = clicked_inf_map_01,
		inf_map_02_click = clicked_inf_map_02,
		inf_map_03_click = clicked_inf_map_03,
		inf_map_04_click = clicked_inf_map_04,
		inf_map_05_click = clicked_inf_map_05,
		inf_map_06_click = clicked_inf_map_06,
		inf_map_07_click = clicked_inf_map_07,
		--TechSupport: Added in new map clicking function thingy
		inf_map_08_click = clicked_inf_map_08,
		Historicals_Selected = Selected_Historicals,
		Progressives_Selected = Selected_Progressives,
		Regionals_Selected = Selected_Regionals,
		Infinities_Selected = Selected_Infinities,
		difficulty_select_easy_click = clicked_difficulty_select_easy,
		difficulty_select_med_click = clicked_difficulty_select_med,
		difficulty_select_hard_click = clicked_difficulty_select_hard,
		Start_GC_Click = Clicked_Start_GC,
		reset_map_click = clicked_reset_map,
		reset_era_click = clicked_reset_era,
		reset_faction_click = clicked_reset_faction,
		reset_all_click = clicked_reset_all
	}

	crossplot:galactic()
	crossplot:subscribe("REGIME_CHOICE_OPTION", Load_GC)
	crossplot:subscribe("PROGRESSIVE_CHOICE_OPTION", Progressive_Choice_Wrapper)
end

function State_Load_GC_Selector(message)
	if message == OnEnter then
		Map_Selected = "KnownSmall"
		Era_Selected = "4ABY"
		Faction_Selected = "REBEL"

		Translator_Table = {}
		Translator_Table = require("GCMenuTranslator")

		Map_Text = {}
		Map_Text = require("GCMenu_MapText")

		Era_Text = {}
		Era_Text = require("GCMenu_EraText")

		MenuText = {}
		MenuText = require("GCMenu_DescriptionText")

		Faction_By_MapEra = {}
		Faction_By_MapEra = require("GCMenu_FactionsbyMapEra")
		Proteus_By_MapEra = {}
		Proteus_By_MapEra = require("GCMenu_ProteusbyMapEra")

		-- local plot = Get_Story_Plot("Conquests\\Story_GCMenu.xml")
		-- local disable_button_event = plot.Get_Event("DISABLE_BUTTON")
		-- local i = 18
		-- while i <= 36 do
			-- disable_button_event.Set_Reward_Parameter(1, "faction_"..tostring(i))
			-- Story_Event("DISABLE_BUTTON_EVENT")
			-- i = i + 1
		-- end

		Enable_and_Visible_Button("s_shield_24", 0, 0)
		Enable_and_Visible_Button("s_shield_41", 0, 0)
		Enable_and_Visible_Button("s_shield_47", 0, 0)

		plot = Get_Story_Plot("Conquests\\Story_GCMenu.xml")
		force_click_button_event = plot.Get_Event("FORCE_CLICK_BUTTON")
		enable_button_event = plot.Get_Event("ENABLE_BUTTON")
		disable_button_event = plot.Get_Event("DISABLE_BUTTON")

		-- Sleep(3)

		-- local i = 1
		-- while i <= 9 do
			-- force_click_button_event.Set_Reward_Parameter(0, "disabled_era_".."0"..tostring(i))
			-- Story_Event("FORCE_CLICK_BUTTON_EVENT")
			-- i = i + 1
		-- end

		-- local i = 10
		-- while i <= 11 do
			-- force_click_button_event.Set_Reward_Parameter(0, "disabled_era_"..tostring(i))
			-- Story_Event("FORCE_CLICK_BUTTON_EVENT")
			-- i = i + 1
		-- end

		-- Sleep(3)
		-- local i = 1
		-- while i <= 9 do
			-- force_click_button_event.Set_Reward_Parameter(0, "disabled_faction_".."0"..tostring(i))
			-- Story_Event("FORCE_CLICK_BUTTON_EVENT")
			-- i = i + 1
		-- end

		-- local i = 10
		-- while i <= 17 do
			-- force_click_button_event.Set_Reward_Parameter(0, "disabled_faction_"..tostring(i))
			-- Story_Event("FORCE_CLICK_BUTTON_EVENT")
			-- i = i + 1
		-- end

		local function table_length(t)
		local count = 0
			for _ in pairs(t) do
				count = count + 1
			end
			return count
		end

		local eras = Translator_Table["ProgressiveEras"]
		Eracount = table_length(eras)
		
		Eracount_valid = 7

		local progressivemaps = Translator_Table["ProgressiveMaps"]
		Progressivemapcount = table_length(progressivemaps)

		local regionalmaps = Translator_Table["RegionalMaps"]
		Regionalmapcount = table_length(regionalmaps)

		local historicalmaps = Translator_Table["HistoricalMaps"]
		Historicalmapcount = table_length(historicalmaps)

		local custommaps = Translator_Table["CustomMaps"]
		Custommapcount = table_length(custommaps)

		local factions = Translator_Table["AllFactions"]
		local factionscount = table_length(factions)

		local proteusfactions = Translator_Table["ProteusFactions"]
		local proteuscount = table_length(proteusfactions)

		Lastfactionnumber = factionscount
		Firstproteusnumber = factionscount + 1
		Lastproteusnumber = factionscount + proteuscount

		difficulty = "Medium"
		force_click_button_event.Set_Reward_Parameter(0, "difficulty_select_med")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		-- disable_button_event.Set_Reward_Parameter(1, "Start_GC")
		-- Story_Event("DISABLE_BUTTON_EVENT")
		-- disable_button_event.Set_Reward_Parameter(1, "era_01")
		-- Story_Event("DISABLE_BUTTON_EVENT")
		force_click_button_event.Set_Reward_Parameter(0, "Prog_Text")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		Selected_Progressives(OnEnter)
		
		force_click_button_event.Set_Reward_Parameter(0, "faction_01")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		clicked_faction_01(OnEnter)
		
		force_click_button_event.Set_Reward_Parameter(0, "era_01")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		clicked_era_01(OnEnter)
		
		force_click_button_event.Set_Reward_Parameter(0, "prog_map_04")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		clicked_prog_map_04(OnEnter)

		StoryUtil.UnlockAllControls()
		
	elseif message == OnUpdate then
		crossplot:update()
	end
end

-- Faction Text
function clicked_faction_01(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("REBEL",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_02(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("EMPIRE",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_03(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("EMPIREOFTHEHAND",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_04(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("PENTASTAR",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_05(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("ERIADU_AUTHORITY",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_06(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("GREATER_MALDROOD",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_07(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("ZSINJ_EMPIRE",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_08(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("CORPORATE_SECTOR",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_09(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("YEVETHA",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_10(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("HAPES_CONSORTIUM",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_11(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("CHISS",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_12(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("CORELLIA",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_13(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("HUTT_CARTELS",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_14(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("KILLIK_HIVES",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_15(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("SSIRUUVI_IMPERIUM",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_faction_16(message)
	if message == OnEnter then
		Faction_Selected = Toggle_Check("UNDERWORLD",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

-- function clicked_faction_17(message)
	-- if message == OnEnter then
		-- Faction_Selected = Toggle_Check("PROTEUS",Faction_Selected)
		-- Setup_Faction_Text(Faction_Selected)
	-- end
-- end

function clicked_reset_faction(message)
	if message == OnEnter then
		Faction_Selected = ""
		Setup_Faction_Text(Faction_Selected)
		force_click_button_event.Set_Reward_Parameter(0, "Reset_Faction")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function Enable_Protean(message)
	if message == OnEnter then
		GUI_Component_Visibility("s_shield_41", false)
		GUI_Component_Enable("s_shield_41", false)
		GUI_Component_Visibility("s_shield_42", true)
		GUI_Component_Enable("s_shield_42", true)

		Faction_Selected = Toggle_Check("IMPERIAL_PROTEUS",Faction_Selected)
		Setup_Faction_Text(Faction_Selected)

	elseif message == OnUpdate then

		crossplot:update()

	end
end

function Disable_Protean(message)
	if message == OnEnter then
		GUI_Component_Visibility("s_shield_42", false)
		GUI_Component_Enable("s_shield_42", false)
		GUI_Component_Visibility("s_shield_41", true)
		GUI_Component_Enable("s_shield_41", true)

		-- clicked_reset_faction(OnEnter)
		-- force_click_button_event.Set_Reward_Parameter(0, "Reset_Faction")
		-- Story_Event("FORCE_CLICK_BUTTON_EVENT")
		-- Faction_Selected = Toggle_Check("PROTEUS",Faction_Selected)
		-- Setup_Faction_Text(Faction_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_01(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("4ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_02(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("6ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_03(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("9ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_04(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("10ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_05(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("11ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_06(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("11.5ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_07(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("12ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_08(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("25ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_09(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("27ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_10(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("35ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_era_11(message)
	if message == OnEnter then
		Era_Selected = Toggle_Check("40ABY",Era_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reset_era(message)
	if message == OnEnter then
		Era_Selected = ""
		Setup_Era_Text(Era_Selected)
		force_click_button_event.Set_Reward_Parameter(0, "Reset_Era")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_prog_map_01(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("FullLarge",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_prog_map_02(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("FullMedium",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_prog_map_03(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("FullSmall",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_prog_map_04(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("KnownLarge",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_prog_map_05(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("KnownMedium",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_prog_map_06(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("KnownSmall",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reg_map_01(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("WesternReaches",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reg_map_02(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Borderlands",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reg_map_03(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Stars_Align",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reg_map_04(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("CorporateAcquisitions",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reg_map_05(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("DeepCoreConflict",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_01(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Lambda",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_02(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("BactaWar",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_03(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Thrawn",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_04(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("IsardsRevenge",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_05(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("ShadowHand",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_06(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("CrimsonEmpire",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_07(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Reunification",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_08(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Orinda",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_09(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("FIP",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_hist_map_10(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Caamas",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_01(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Empires_At_War",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_02(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("FTGU",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_03(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Custom_Small",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_04(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Custom_Medium",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_05(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Custom_Large",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_06(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Custom_FTGU",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_inf_map_07(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Custom_Influencers",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end
--TechSupport: Added in new map clicking function thingy
function clicked_inf_map_08(message)
	if message == OnEnter then
		Map_Selected = Toggle_Check("Proteus_Map_One",Map_Selected)
		Setup_Map_Text(Map_Selected)
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reset_map(message)
	if message == OnEnter then
		Map_Selected = ""
		Setup_Map_Text(Map_Selected)
		force_click_button_event.Set_Reward_Parameter(0, "Reset_Map")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_difficulty_select_easy(message)
	if message == OnEnter then
		difficulty = "Easy"
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_difficulty_select_med(message)
	if message == OnEnter then
		difficulty = "Med"
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_difficulty_select_hard(message)
	if message == OnEnter then
		difficulty = "Hard"
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function clicked_reset_all(message)
	if message == OnEnter then
		clicked_reset_map(OnEnter)
		clicked_reset_era(OnEnter)
		clicked_reset_faction(OnEnter)

		force_click_button_event.Set_Reward_Parameter(0, "Reset_All")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")

		Map_Selected = ""
		if Map_Group == Translator_Table["HistoricalMaps"] then
			Era_Selected = "Historical"
		else
			Era_Selected = ""
		end
		Faction_Selected = ""

		Setup_Map_Text(Map_Selected)
		Setup_Faction_Text(Faction_Selected)
		Setup_Era_Text(Era_Selected)
	elseif message == OnUpdate then
		crossplot:update()
	end
end

function Setup_Map_Text(map)

	Refresh_Text()

	Set_Button_Availability(map, "", "")
	Difficulty_Update()
end

function Setup_Era_Text(era)

	Refresh_Text()

	Set_Button_Availability("", era, "")
	Difficulty_Update()
end

function Setup_Faction_Text(faction)

	Refresh_Text()

	Set_Button_Availability("", "", faction)
	Difficulty_Update()
end

function Refresh_Text()

	Map_Name = ""
	Map_Description = ""

	Faction_Name = ""
	Era_Name = ""
	Era_Description = ""
	Faction_Description = ""

	if Map_Selected ~= "" and Map_Selected ~= nil then
		if MenuText.Map_Text[Map_Selected].Description then
	
			Map_Description = MenuText.Map_Text[Map_Selected].Description
			Map_Name = MenuText.Map_Text[Map_Selected].Title

		end
	end

	if Faction_Selected ~= nil and Faction_Selected ~= "" then


		Faction_Name = MenuText.Default_Faction_Text[Faction_Selected].Titles["DEFAULT"]
		Faction_Description = MenuText.Default_Faction_Text[Faction_Selected].Overviews["DEFAULT"]
		-- Take era-based name overrides first, then check for specific GC overrides.
		if Era_Selected ~= nil and Era_Selected ~= "" then
			if MenuText.Default_Faction_Text[Faction_Selected].Titles[Era_Selected] then
				Faction_Name = MenuText.Default_Faction_Text[Faction_Selected].Titles[Era_Selected]
			end
			if MenuText.Default_Faction_Text[Faction_Selected].Overviews[Era_Selected] then
				Faction_Description = MenuText.Default_Faction_Text[Faction_Selected].Overviews[Era_Selected]
			end
		end
		if Map_Selected ~= "" and Map_Selected ~= nil then
			if MenuText.Map_Text[Map_Selected].FactionOverrideTitles then
				if MenuText.Map_Text[Map_Selected].FactionOverrideTitles[Faction_Selected] then
					Faction_Name = MenuText.Map_Text[Map_Selected].FactionOverrideTitles[Faction_Selected] 
				end
			end
			if MenuText.Map_Text[Map_Selected].FactionOverrideOverviews then
				if MenuText.Map_Text[Map_Selected].FactionOverrideOverviews[Faction_Selected] then
					Faction_Description = MenuText.Map_Text[Map_Selected].FactionOverrideOverviews[Faction_Selected] 
				end
			end
		end
	end

	if Era_Selected ~= nil and Era_Selected ~= "" then
		if Era_Selected ~= "Historical" then
			Era_Name = MenuText.Default_Era_Text[Era_Selected].Title
			Era_Description = MenuText.Default_Era_Text[Era_Selected].Overview
		end
		if Map_Selected ~= "" and Map_Selected ~= nil then
			if MenuText.Map_Text[Map_Selected].DateOverride then
				Era_Name = MenuText.Map_Text[Map_Selected].DateOverride
			end
			if MenuText.Map_Text[Map_Selected].EraTextOverride then
				Era_Description = MenuText.Map_Text[Map_Selected].EraTextOverride["DEFAULT"]
				if MenuText.Map_Text[Map_Selected].EraTextOverride[Era_Selected] then
					Era_Description = MenuText.Map_Text[Map_Selected].EraTextOverride[Era_Selected]
				end
			end
		end
	end

	-- Begin display
	Enable_and_Visible_Button("s_shield_25",Map_Name,0)


	Trimmed_Map_Description_Table = Create_Linebreak(Map_Description, 73)
	Unroll_Table(Trimmed_Map_Description_Table,"s_shield_",28, 3)

	Era_Faction_Header = Fill_With_Spaces(Era_Name,Faction_Name,60)
	Enable_and_Visible_Button("s_shield_26",Era_Faction_Header,0)

	Trimmed_Era_Description_Table = Create_Linebreak(Era_Description, 73)
	Unroll_Table(Trimmed_Era_Description_Table,"s_shield_",31, 5)

	Trimmed_Faction_Description_Table = Create_Linebreak(Faction_Description, 73)
	Unroll_Table(Trimmed_Faction_Description_Table,"s_shield_",36, 5)
	
end

function Toggle_Check(new_val, stored_val)
	if new_val == stored_val then
		stored_val = new_val
		-- stored_val = ""
	else
		stored_val = new_val
	end

	return stored_val
end

function Difficulty_Update()

end

function Enable_and_Visible_Button(button_name, text, icon)
	if button_name ~= 0 and button_name ~= nil then
		GUI_Component_Visibility(button_name, true)
		GUI_Component_Enable(button_name, true)

		if text ~= 0 and text ~= nil then
			GUI_Component_Text(button_name, text)
		end

		if icon ~= 0 and icon ~= nil then
			GUI_Button_Icon(button_name, icon..".tga", 1, 1, 1, 1)
		end
	end
end

function Disable_and_Hide_Button(button_name)
	GUI_Component_Visibility(button_name, false)
	GUI_Component_Enable(button_name, false)
end

function Selected_Historicals(message)
	if message == OnEnter then

		Enable_and_Visible_Button("s_shield_43",0,0)
		Enable_and_Visible_Button("s_shield_44",0,0)
		Enable_and_Visible_Button("s_shield_45",0,0)
		Enable_and_Visible_Button("s_shield_46",0,0)
		Enable_and_Visible_Button("s_shield_26","",0)
		
		clicked_reset_era(OnEnter)
		clicked_reset_map(OnEnter)
		
		Era_Selected = "Historical"
		Map_Selected = ""
		
		Setup_Faction_Text(Faction_Selected)
		
		Button_Cycle(Translator_Table["HistoricalMaps"], {Era_Selected}, {Faction_Selected})

		if next(Valid_Button_Table) == nil then
			 clicked_reset_faction(OnEnter)
			 Disable_Protean(OnEnter)
		elseif Faction_Selected ~= "" then
			force_click_button_event.Set_Reward_Parameter(0, Translator_Table[Faction_Selected])
			Story_Event("FORCE_CLICK_BUTTON_EVENT")
		end

		-- Setup_Faction_Text(Faction_Selected)
		Disable_and_Hide_Button("s_shield_44")
		Disable_and_Hide_Button("s_shield_45")
		Disable_and_Hide_Button("s_shield_46")
		Disable_and_Hide_Button("s_shield_47")
		
		Map_Group = Translator_Table["HistoricalMaps"]

		-- Setup_Faction_Text(Faction_Selected)
		Set_Button_Availability(Map_Group, {Era_Selected}, {Faction_Selected})
		Disable_Protean(OnEnter)
		-- Setup_Map_Text("")
		Valid_Button_Table = {}
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function Selected_Progressives(message)
	if message == OnEnter then
		Enable_and_Visible_Button("s_shield_47", 0, 0)
		Enable_and_Visible_Button("s_shield_43",0,0)
		Enable_and_Visible_Button("s_shield_44",0,0)
		Enable_and_Visible_Button("s_shield_45",0,0)
		Enable_and_Visible_Button("s_shield_46",0,0)
		
		Map_Group = Translator_Table["ProgressiveMaps"]
		clicked_reset_map(OnEnter)

		if Era_Selected == "Historical" or Era_Selected == "Custom" or Era_Selected == "" then
			Era_Selected = ""
			Era_Input = Translator_Table["ProgressiveEras"]
		else
			Era_Input = {Era_Selected}
		end

		Button_Cycle(Translator_Table["ProgressiveMaps"], Era_Input, {Faction_Selected})

		if next(Valid_Button_Table) == nil then
			 clicked_reset_faction(OnEnter)
			 Disable_Protean(OnEnter)
		elseif Faction_Selected ~= "" then
			force_click_button_event.Set_Reward_Parameter(0, Translator_Table[Faction_Selected])
			Story_Event("FORCE_CLICK_BUTTON_EVENT")
		end
		
		Set_Button_Availability(Map_Group, Era_Input, {Faction_Selected})
		Disable_Protean(OnEnter)
		
		Disable_and_Hide_Button("s_shield_43")
		Disable_and_Hide_Button("s_shield_45")
		Disable_and_Hide_Button("s_shield_46")

		Valid_Button_Table = {}
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function Selected_Regionals(message)
	if message == OnEnter then
		
		Enable_and_Visible_Button("s_shield_47", 0, 0)
		Enable_and_Visible_Button("s_shield_43",0,0)
		Enable_and_Visible_Button("s_shield_44",0,0)
		Enable_and_Visible_Button("s_shield_45",0,0)
		Enable_and_Visible_Button("s_shield_46",0,0)
		
		clicked_reset_map(OnEnter)

		if Era_Selected == "Historical" or Era_Selected == "Custom" or Era_Selected == "" then
			Era_Selected = ""
			Era_Input = Translator_Table["ProgressiveEras"]
		else
			Era_Input = {Era_Selected}
		end

		Button_Cycle(Translator_Table["RegionalMaps"], Era_Input, {Faction_Selected})

		if next(Valid_Button_Table) == nil then
			 clicked_reset_faction(OnEnter)
			  Disable_Protean(OnEnter)
		elseif Faction_Selected ~= "" then
			force_click_button_event.Set_Reward_Parameter(0, Translator_Table[Faction_Selected])
			Story_Event("FORCE_CLICK_BUTTON_EVENT")
		end
		
		Map_Group = Translator_Table["RegionalMaps"]
		
		Set_Button_Availability(Map_Group, Era_Input, {Faction_Selected})
		Disable_Protean(OnEnter)
		Disable_and_Hide_Button("s_shield_43")
		Disable_and_Hide_Button("s_shield_44")
		Disable_and_Hide_Button("s_shield_46")

		Valid_Button_Table = {}
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function Selected_Infinities(message)
	if message == OnEnter then
		
		Enable_and_Visible_Button("s_shield_42",0,0)
		Enable_and_Visible_Button("s_shield_43",0,0)
		Enable_and_Visible_Button("s_shield_44",0,0)
		Enable_and_Visible_Button("s_shield_45",0,0)
		Enable_and_Visible_Button("s_shield_46",0,0)
		Enable_and_Visible_Button("s_shield_47",0,0)
		
		clicked_reset_map(OnEnter)

		if Era_Selected == "Historical" or Era_Selected == "Custom" or Era_Selected == "" then
			Era_Selected = ""
			Era_Input = Translator_Table["ProgressiveEras"]
		else
			Era_Input = {Era_Selected}
		end
		
		Button_Cycle(Translator_Table["CustomMaps"], Era_Input, {Faction_Selected})

		if next(Valid_Button_Table) == nil then
			 clicked_reset_faction(OnEnter)
		elseif Faction_Selected ~= "" then
			force_click_button_event.Set_Reward_Parameter(0, Translator_Table[Faction_Selected])
			Story_Event("FORCE_CLICK_BUTTON_EVENT")
		end
		
		Map_Group = Translator_Table["CustomMaps"]
		
		Set_Button_Availability(Map_Group, Era_Input, {Faction_Selected})
		Disable_Protean(OnEnter)
		
		Disable_and_Hide_Button("s_shield_43")
		Disable_and_Hide_Button("s_shield_44")
		Disable_and_Hide_Button("s_shield_45")

		Valid_Button_Table = {}
		Difficulty_Update()
	elseif message == OnUpdate then

		crossplot:update()

	end
end

function Set_Button_Availability(map_in, era_in, faction_in)
	-- if map == "" then
		-- Force_Click_Set(1, 6, "disabled_prog_map")
		-- Force_Click_Set(1, 11, "disabled_hist_map")
		-- Force_Click_Set(1, 4, "disabled_reg_map")
		-- Force_Click_Set(1, 2, "disabled_inf_map")
		-- Force_Click_Set(1, 6, "enabled_prog_map")
		-- Force_Click_Set(1, 11, "enabled_hist_map")
		-- Force_Click_Set(1, 4, "enabled_reg_map")
		-- Force_Click_Set(1, 2, "enabled_inf_map")
		-- Force_Click_Set(1, 6, "disabled_prog_map")
		-- Force_Click_Set(1, 11, "disabled_hist_map")
		-- Force_Click_Set(1, 4, "disabled_reg_map")
		-- Force_Click_Set(1, 2, "disabled_inf_map")
	-- end

	-- if era == "" then
		-- Force_Click_Set(1, 11, "disabled_era")
		-- Force_Click_Set(1, 11, "enabled_era")
		-- Force_Click_Set(1, 11, "disabled_era")
	-- end

	-- if faction == "" then
		-- Force_Click_Set(1, 17, "disabled_faction")
		-- Force_Click_Set(1, 17, "enabled_faction")
		-- Force_Click_Set(1, 17, "disabled_faction")
	-- end

	-- if ((Map_Selected == "") or (Era_Selected == "") or (Faction_Selected == "") == true) then
		-- Force_Click_Set(1, 6, "enabled_prog_map")
		-- Force_Click_Set(1, 11, "enabled_hist_map")
		-- Force_Click_Set(1, 4, "enabled_reg_map")
		-- Force_Click_Set(1, 2, "enabled_inf_map")
		-- Force_Click_Set(1, 11, "enabled_era")
		-- Force_Click_Set(1, 17, "enabled_faction")
	-- end

	-- if map == "" then
	-- Force_Click_Set(1, 6, "disabled_prog_map")
	-- Force_Click_Set(1, 11, "disabled_hist_map")
	-- Force_Click_Set(1, 4, "disabled_reg_map")
	-- Force_Click_Set(1, 2, "disabled_inf_map")
	-- Force_Click_Set(1, 6, "enabled_prog_map")
	-- Force_Click_Set(1, 11, "enabled_hist_map")
	-- Force_Click_Set(1, 4, "enabled_reg_map")
	-- Force_Click_Set(1, 2, "enabled_inf_map")
	-- Force_Click_Set(1, 6, "disabled_prog_map")
	-- Force_Click_Set(1, 11, "disabled_hist_map")
	-- Force_Click_Set(1, 4, "disabled_reg_map")
	-- Force_Click_Set(1, 2, "disabled_inf_map")
	-- Force_Click_Set(1, 11, "disabled_era")
	-- Force_Click_Set(1, 11, "enabled_era")
	-- Force_Click_Set(1, 11, "disabled_era")
	-- Force_Click_Set(1, 17, "disabled_faction")
	-- Force_Click_Set(1, 17, "enabled_faction")
	-- Force_Click_Set(1, 17, "disabled_faction")

	Map_Table = {}
	Map_Table = {Map_Selected}
	Map_Table = Translator_Table["AllMaps"]

	Era_Table = {}
	Era_Table = {Era_Selected}
	Era_Table = Translator_Table["AllEras"]

	Faction_Table = {}
	Faction_Table = {Faction_Selected}
	Faction_Table = Translator_Table["AllFactions"]

	Valid_Button_Table = {}
	Valid_Proteus_Table = {}
	
	if type(map_in) ~= "string" then
		Map_Set = map_in
	elseif string.len(map_in) > 0 then
		Map_Set = {map_in}
	else	
		Map_Set = {Map_Selected}
	end
	
	if type(era_in) ~= "string" then
		Era_Set = era_in
	elseif string.len(era_in) > 0 then
		Era_Set = {era_in}
	else	
		Era_Set = {Era_Selected}
	end
	
	if type(faction_in) ~= "string" then
		Faction_Set = faction_in
	elseif string.len(faction_in) > 0 then
		Faction_Set = {faction_in}
	else	
		Faction_Set = {Faction_Selected}
	end

	if Map_Selected ~= "" and Era_Selected ~="" and Faction_Selected =="" then
		if Map_Selected ~= "" then
			Force_Click_Set(1, Eracount, "era","disabled")
			Force_Click_Set(1, Eracount, "era","enabled")
			Force_Click_Set(1, Eracount, "era","disabled")

			Button_Cycle(Map_Set, Translator_Table["AllEras"], Translator_Table["AllFactions"])
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		end
		if Era_Selected ~= "" then
			Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
			Force_Click_Set(1, Custommapcount, "inf_map","disabled")
			Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
			Force_Click_Set(1, Custommapcount, "inf_map","enabled")
			Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
			Force_Click_Set(1, Custommapcount, "inf_map","disabled")

			Button_Cycle(Map_Group, Era_Set, Translator_Table["AllFactions"])
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		end

		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

		Button_Cycle(Map_Set, Era_Set, Translator_Table["AllFactions"])
		Unlock_Table(Valid_Button_Table)
		Highlight_Table(Valid_Proteus_Table)
	end

	if Map_Selected ~= "" and Era_Selected =="" and Faction_Selected ~="" then
		if Map_Selected ~= "" then
			Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
			Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
			Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
			Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

			Button_Cycle(Map_Set, Translator_Table["AllEras"], Translator_Table["AllFactions"])
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		end
		if Faction_Selected ~= "" then
			Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
			Force_Click_Set(1, Custommapcount, "inf_map","disabled")
			Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
			Force_Click_Set(1, Custommapcount, "inf_map","enabled")
			Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
			Force_Click_Set(1, Custommapcount, "inf_map","disabled")

			Button_Cycle(Map_Group, Translator_Table["AllEras"], Faction_Set)
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		end

		Force_Click_Set(1, Eracount, "era","disabled")
		Force_Click_Set(1, Eracount, "era","enabled")
		Force_Click_Set(1, Eracount, "era","disabled")
		Button_Cycle(Map_Set, Translator_Table["AllEras"], Faction_Set)
		Unlock_Table(Valid_Button_Table)
		Highlight_Table(Valid_Proteus_Table)
	end

	if Map_Selected == "" and Era_Selected ~= "" and Faction_Selected ~="" then
		if Era_Selected ~= "" then
			Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
			Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
			Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
			Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

			Button_Cycle(Map_Group, Era_Set, Translator_Table["AllFactions"])
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		end
		if Faction_Selected ~= "" then
			Force_Click_Set(1, Eracount, "era","disabled")
			Force_Click_Set(1, Eracount, "era","enabled")
			Force_Click_Set(1, Eracount, "era","disabled")

			Button_Cycle(Map_Group, Translator_Table["AllEras"], Faction_Set)
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		end

		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
		Force_Click_Set(1, Custommapcount, "inf_map","enabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")

		Button_Cycle(Map_Group, Era_Set, Faction_Set)
		Unlock_Table(Valid_Button_Table)
		Highlight_Table(Valid_Proteus_Table)
	end

	if Map_Selected ~= "" and Era_Selected == "" and Faction_Selected == "" then
		Force_Click_Set(1, Eracount, "era","disabled")
		Force_Click_Set(1, Eracount, "era","enabled")
		Force_Click_Set(1, Eracount, "era","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

		Button_Cycle(Map_Set, Translator_Table["AllEras"], Translator_Table["AllFactions"])
		Unlock_Table(Valid_Button_Table)
		Highlight_Table(Valid_Proteus_Table)

		Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
		Force_Click_Set(1, Custommapcount, "inf_map","enabled")
	end

	if Map_Selected == "" and Era_Selected ~= "" and Faction_Selected == "" then
		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
		Force_Click_Set(1, Custommapcount, "inf_map","enabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

		Button_Cycle(Map_Group, Era_Set, Translator_Table["AllFactions"])
		Unlock_Table(Valid_Button_Table)
		Highlight_Table(Valid_Proteus_Table)
		Force_Click_Set(1, Eracount_valid, "era","enabled")
	end

	if Map_Selected == "" and Era_Selected == "" and Faction_Selected ~= "" then
		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
		Force_Click_Set(1, Custommapcount, "inf_map","enabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Eracount, "era","disabled")
		Force_Click_Set(1, Eracount, "era","enabled")
		Force_Click_Set(1, Eracount, "era","disabled")

		Button_Cycle(Map_Group, Translator_Table["AllEras"], Faction_Set)
		Unlock_Table(Valid_Button_Table)
		Highlight_Table(Valid_Proteus_Table)
		Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
	end

	if Map_Selected == "" and Era_Selected == "" and Faction_Selected == "" then
		--if map_in ~= "" then
			Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
			Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
			Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
			Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

			Force_Click_Set(1, Eracount, "era","disabled")
			Force_Click_Set(1, Eracount, "era","enabled")
			Force_Click_Set(1, Eracount, "era","disabled")

			Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
			Force_Click_Set(1, Custommapcount, "inf_map","disabled")
			Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
			Force_Click_Set(1, Custommapcount, "inf_map","enabled")
			Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
			Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
			Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
			Force_Click_Set(1, Custommapcount, "inf_map","disabled")

			Button_Cycle(Map_Group, Translator_Table["AllEras"], Translator_Table["AllFactions"])
			Unlock_Table(Valid_Button_Table)
			Highlight_Table(Valid_Proteus_Table)
		--end
	end

	if Map_Selected ~= "" and Era_Selected ~="" and Faction_Selected ~="" then
		enable_button_event = plot.Get_Event("ENABLE_BUTTON")
		enable_button_event.Set_Reward_Parameter(1, "Start_GC")
		Story_Event("ENABLE_BUTTON_EVENT")
		force_click_button_event.Set_Reward_Parameter(0, "enabled_Start_GC")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")

		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","enabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","enabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","enabled")
		Force_Click_Set(1, Custommapcount, "inf_map","enabled")
		Force_Click_Set(1, Progressivemapcount, "prog_map","disabled")
		Force_Click_Set(1, Historicalmapcount, "hist_map","disabled")
		Force_Click_Set(1, Regionalmapcount, "reg_map","disabled")
		Force_Click_Set(1, Custommapcount, "inf_map","disabled")
		Force_Click_Set(1, Eracount, "era","disabled")
		Force_Click_Set(1, Eracount, "era","enabled")
		Force_Click_Set(1, Eracount, "era","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","enabled")
		Force_Click_Set(1, Lastfactionnumber, "faction","disabled")
		Force_Click_Set(Firstproteusnumber, Lastproteusnumber, "faction","disabled")

		Button_Cycle(Map_Group, {Era_Selected}, {Faction_Selected})
		Button_Cycle({Map_Selected}, Translator_Table["AllEras"], {Faction_Selected})
		Button_Cycle({Map_Selected}, {Era_Selected}, Translator_Table["AllFactions"])
		Unlock_Table(Valid_Button_Table)
		Valid_Proteus_Table = {}
		Button_Cycle({Map_Selected}, {Era_Selected}, {Faction_Selected})
		Highlight_Table(Valid_Proteus_Table)
	else
		disable_button_event = plot.Get_Event("DISABLE_BUTTON")
		disable_button_event.Set_Reward_Parameter(1, "Start_GC")
		Story_Event("DISABLE_BUTTON_EVENT")
		force_click_button_event.Set_Reward_Parameter(0, "disabled_Start_GC")
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
	end
end

function Force_Click_Set(button_lower_range, button_upper_range, button_set, button_toggle_type)
	plot = Get_Story_Plot("Conquests\\Story_GCMenu.xml")
	force_click_button_event = plot.Get_Event("FORCE_CLICK_BUTTON")
	disable_button_event = plot.Get_Event("DISABLE_BUTTON")
	enable_button_event = plot.Get_Event("ENABLE_BUTTON")

	if button_upper_range < 9 then
		first_end_num = button_upper_range
	else
		first_end_num = 9
	end

	if button_lower_range > 10 then
		second_start_num = button_lower_range
	else
		second_start_num = 10
	end

	local i = button_lower_range
	while i <= first_end_num do
		force_click_button_event.Set_Reward_Parameter(0, button_toggle_type.."_"..button_set.."_0"..tostring(i))
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		if button_toggle_type == "enabled" then
		enable_button_event.Set_Reward_Parameter(1, button_set.."_0"..tostring(i))
		Story_Event("ENABLE_BUTTON_EVENT")
		elseif button_toggle_type == "disabled" then
		disable_button_event.Set_Reward_Parameter(1, button_set.."_0"..tostring(i))
		Story_Event("DISABLE_BUTTON_EVENT")
		end

		i = i + 1
	end

	local j = second_start_num
	while j <= button_upper_range do
		force_click_button_event.Set_Reward_Parameter(0, button_toggle_type.."_"..button_set.."_"..tostring(j))
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		if button_toggle_type == "enabled" then
			enable_button_event.Set_Reward_Parameter(1, button_set.."_"..tostring(j))
			Story_Event("ENABLE_BUTTON_EVENT")
		elseif button_toggle_type == "disabled" then
			disable_button_event.Set_Reward_Parameter(1, button_set.."_"..tostring(j))
			Story_Event("DISABLE_BUTTON_EVENT")
		end

		j = j + 1
	end
end

function Button_Cycle(Map_Table, Era_Table, Faction_Table)
	for i,map in pairs(Map_Table) do
		if Faction_By_MapEra[map] ~= nil then
			for j,era in pairs(Era_Table) do
				if Faction_By_MapEra[map][era] ~= nil then
					for k,faction in pairs(Faction_Table) do
						if Faction_By_MapEra[map][era][faction] ~= nil then
							if Faction_By_MapEra[map][era][faction] == true then
								Valid_Button_Table[map] = map
								Valid_Button_Table[era] = era
								Valid_Button_Table[faction] = faction
								if faction == "IMPERIAL_PROTEUS" then
									for l,subfaction in pairs(Translator_Table["ProteusFactions"]) do
										if Proteus_By_MapEra[subfaction] ~= nil then
											if Proteus_By_MapEra[subfaction][map] ~= nil then
												if Proteus_By_MapEra[subfaction][map][era] ~= nil then
													Valid_Proteus_Table[subfaction] = subfaction
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function Unlock_Table(sent_table)
	for i,item in pairs(sent_table) do
		translated_item = Translator_Table[item]
		force_click_button_event.Set_Reward_Parameter(0, "enabled_"..translated_item)
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		enable_button_event.Set_Reward_Parameter(1, translated_item)
		Story_Event("ENABLE_BUTTON_EVENT")
	end

	Valid_Button_Table = {}
end

function Highlight_Table(sent_table)
	for i,item in pairs(sent_table) do
		translated_item = Translator_Table[item]
		enable_button_event.Set_Reward_Parameter(1, translated_item)
		Story_Event("ENABLE_BUTTON_EVENT")
		force_click_button_event.Set_Reward_Parameter(0, translated_item)
		Story_Event("FORCE_CLICK_BUTTON_EVENT")
		-- disable_button_event.Set_Reward_Parameter(1, "enabled_"..translated_item)
		-- Story_Event("DISABLE_BUTTON_EVENT")
		-- disable_button_event.Set_Reward_Parameter(1, translated_item)
		-- Story_Event("DISABLE_BUTTON_EVENT")
		disable_button_event.Set_Reward_Parameter(1, "disabled_"..translated_item)
		Story_Event("DISABLE_BUTTON_EVENT")
	end

	Valid_Proteus_Table = {}
end

function Clicked_Start_GC(message)
	if message == OnEnter then
		Disable_and_Hide_Button("s_shield_24")
		Disable_and_Hide_Button("s_shield_25")
		Disable_and_Hide_Button("s_shield_26")
		Disable_and_Hide_Button("s_shield_27")
		Disable_and_Hide_Button("s_shield_28")
		Disable_and_Hide_Button("s_shield_29")
		Disable_and_Hide_Button("s_shield_30")
		Disable_and_Hide_Button("s_shield_31")
		Disable_and_Hide_Button("s_shield_32")
		Disable_and_Hide_Button("s_shield_33")
		Disable_and_Hide_Button("s_shield_34")
		Disable_and_Hide_Button("s_shield_35")
		Disable_and_Hide_Button("s_shield_36")
		Disable_and_Hide_Button("s_shield_37")
		Disable_and_Hide_Button("s_shield_38")
		Disable_and_Hide_Button("s_shield_39")
		Disable_and_Hide_Button("s_shield_40")
		Disable_and_Hide_Button("s_shield_41")
		Disable_and_Hide_Button("s_shield_42")
		Disable_and_Hide_Button("s_shield_43")
		Disable_and_Hide_Button("s_shield_44")
		Disable_and_Hide_Button("s_shield_45")
		Disable_and_Hide_Button("s_shield_46")
		Disable_and_Hide_Button("s_shield_47")

		if (string.find(string.upper(Map_Selected), "KNOWN") or string.find(string.upper(Map_Selected), "FULL") or string.find(string.upper(Map_Selected), "AT_WAR")  or string.find(string.upper(Map_Selected), "WESTERNREACHES") or string.find(string.upper(Map_Selected), "BORDERLANDS") or string.find(string.upper(Map_Selected), "STARS_ALIGN")) and Era_Selected == "6ABY" and Faction_Selected == "EMPIRE" then
			Regime_Choice()
		elseif string.find(string.upper(Map_Selected), "FTGU") or string.find(string.upper(Map_Selected), "CUSTOM") or (string.find(string.upper(Map_Selected), "PROTEUS_MAP") and Era_Selected == "4ABY") then
			Infinity_Progression_Choice()
		else
			Load_GC()
		end
	elseif message == OnUpdate then
		crossplot:update()
	end
end

function Regime_Choice()
	GenericPopup("REGIME_CHOICE", {"ISARD", "CCOGM"}, "REGIME_CHOICE_OPTION")
end

function Infinity_Progression_Choice()
	local options = {"STATIC_ERA", "PROGRESSIVE_ERA"}
	if string.find(string.upper(Map_Selected), "PROTEUS_MAP") then --TechSupport: I know this is jank but it was the only way I could think to differentiate between the two without adding more variables or changing a lot of code. If anyone has suggestions on how to make this better please let me know.
		options = {"STATIC_ERA_PROTEUS", "PROGRESSIVE_ERA_PROTEUS"}
	end
	if string.find(string.upper(Map_Selected), "CUSTOM") then
		options = {"LEARNER_MODE", "STATIC_ERA", "PROGRESSIVE_ERA"}
	end

	GenericPopup("CUSTOM_GC", options, "PROGRESSIVE_CHOICE_OPTION")
end

function Progressive_Choice_Wrapper(progressive_choice)
	Progressive_Choice = progressive_choice
	if Era_Selected == "6ABY" and Faction_Selected == "EMPIRE" then
		Regime_Choice()
	else
		Load_GC("")
	end
end

function Load_GC(regime_choice)

		Enable_and_Visible_Button("s_shield_24", 0, 0)
		Enable_and_Visible_Button("s_shield_41", 0, 0)
		Enable_and_Visible_Button("s_shield_47", 0, 0)

	if Era_Selected == "Historical" or Era_Selected == "Custom" then
		campaign_name = Map_Selected.."_"..Faction_Selected
	else
		Translated_Era = Translator_Table["Era_XML_Nums"][Era_Selected]
		campaign_name = Map_Selected.."_"..Translated_Era.."_"..Faction_Selected
	end
	
	if regime_choice then
		if regime_choice == "REGIME_CHOICE_CCOGM" then
			campaign_name = campaign_name.."_CCoGM"
		end
	end

	local loadEvent = plot.Get_Event("Load_Another_GC")
	loadEvent.Set_Reward_Parameter(0, campaign_name)
	loadEvent.Set_Reward_Parameter(1, CONSTANTS.LIVE_FACTION_TABLE[Faction_Selected])

	local difficulty_index = 1
	if difficulty == "Easy" then
		difficulty_index = 0
	elseif difficulty == "Hard" then
		difficulty_index = 2
	end
	loadEvent.Set_Reward_Parameter(2, difficulty_index)
	
	if Progressive_Choice then --TechSupport: Set tech levels to match the options selected
		-- for the proteus map settings: 5 = static, 4 = progressive, leaving the rest up for grabs
		if Progressive_Choice == "CUSTOM_GC_STATIC_ERA_PROTEUS" then
			loadEvent.Set_Reward_Parameter(3, 5)
		end
		if Progressive_Choice == "CUSTOM_GC_PROGRESSIVE_ERA_PROTEUS" then
			loadEvent.Set_Reward_Parameter(3, 4)
		end
		if Progressive_Choice == "CUSTOM_GC_PROGRESSIVE_ERA" then
			loadEvent.Set_Reward_Parameter(3, 4)
		end
		if Progressive_Choice == "CUSTOM_GC_LEARNER_MODE" then
			loadEvent.Set_Reward_Parameter(3, 5)
		end
	end

	Story_Event("LOAD_CAMPAIGN_EVENT")

end


