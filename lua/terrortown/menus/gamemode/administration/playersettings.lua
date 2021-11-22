-- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 93
CLGAMEMODESUBMENU.title = "submenu_administration_playersettings_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_playersettings_plyspawn")

	form:MakeHelp({
		label = "help_ply_spawn"
	})

	form:MakeSlider({
		serverConvar = "ttt_armor_on_spawn",
		label = "label_armor_on_spawn",
		min = 0,
		max = 250,
		decimal = 0
	})

	local form2 = vgui.CreateTTT2Form(parent, "header_playersettings_armor")

	form2:MakeHelp({
		label = "help_armor_balancing"
	})

	form2:MakeCheckBox({
		serverConvar = "ttt_item_armor_block_headshots",
		label = "label_armor_block_headshots"
	})

	form2:MakeCheckBox({
		serverConvar = "ttt_item_armor_block_blastdmg",
		label = "label_armor_block_blastdmg"
	})

	form2:MakeHelp({
		label = "help_item_armor_classic"
	})

	local enbDyn = form2:MakeCheckBox({
		serverConvar = "ttt_armor_dynamic",
		label = "label_armor_dynamic"
	})

	form2:MakeHelp({
		label = "help_item_armor_dynamic"
	})

	form2:MakeSlider({
		serverConvar = "ttt_armor_damage_block_pct",
		label = "label_armor_damage_block_pct",
		min = 0,
		max = 1,
		decimal = 2,
		master = enbDyn
	})

	form2:MakeSlider({
		serverConvar = "ttt_armor_damage_health_pct",
		label = "label_armor_damage_health_pct",
		min = 0,
		max = 1,
		decimal = 2,
		master = enbDyn
	})

	local enbReInf = form2:MakeCheckBox({
		serverConvar = "ttt_armor_enable_reinforced",
		label = "label_armor_enable_reinforced",
		master = enbDyn
	})

	form2:MakeSlider({
		serverConvar = "ttt_armor_threshold_for_reinforced",
		label = "label_armor_threshold_for_reinforced",
		min = 0,
		max = 100,
		decimal = 0,
		master = enbReInf
	})
end
