local mod = get_mod("catas")

return {
	name = "Cata 2 & 3 in Adventure Maps",
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id    = "hero_power",
				type          = "checkbox",
				default_value = false,
			},
			{
				setting_id  = "stats",
				type          = "dropdown",
				default_value = "custom",
				options = {
					{text = "custom",   value = "custom", show_widgets = {1, 2, 3}},
					{text = "dw-lite",   value = "dw-lite", show_widgets = {}},
				},
				sub_widgets = {
					{
						setting_id  = "diff_stagger_resist",
						type        = "group",
						sub_widgets = {
							{
								setting_id      = "diff_stagger_resist.skaven_slave",
								type            = "numeric",
								
								default_value   = Breeds.skaven_slave.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_clan_rat",
								type            = "numeric",
								
								default_value   = Breeds.skaven_clan_rat.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_storm_vermin",
								type            = "numeric",
								
								default_value   = Breeds.skaven_storm_vermin.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_storm_vermin_commander",
								type            = "numeric",
								
								default_value   = Breeds.skaven_storm_vermin_commander.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_plague_monk",
								type            = "numeric",
								
								default_value   = Breeds.skaven_plague_monk.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_pack_master",
								type            = "numeric",
								
								default_value   = Breeds.skaven_pack_master.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_ratling_gunner",
								type            = "numeric",
								
								default_value   = Breeds.skaven_ratling_gunner.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_warpfire_thrower",
								type            = "numeric",
								
								default_value   = Breeds.skaven_warpfire_thrower.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.skaven_storm_vermin_warlord",
								type            = "numeric",
								
								default_value   = Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							
							{
								setting_id      = "diff_stagger_resist.chaos_fanatic",
								type            = "numeric",
								
								default_value   = Breeds.chaos_fanatic.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.chaos_marauder",
								type            = "numeric",
								
								default_value   = Breeds.chaos_marauder.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.chaos_raider",
								type            = "numeric",
								
								default_value   = Breeds.chaos_raider.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.chaos_berzerker",
								type            = "numeric",
								
								default_value   = Breeds.chaos_berzerker.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.chaos_warrior",
								type            = "numeric",
								
								default_value   = Breeds.chaos_warrior.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.chaos_sorcerers",
								type            = "numeric",
								
								default_value   = Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},


							{
								setting_id      = "diff_stagger_resist.beastmen_ungor",
								type            = "numeric",
								
								default_value   = Breeds.beastmen_ungor.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.beastmen_ungor_archer",
								type            = "numeric",
								
								default_value   = Breeds.beastmen_ungor_archer.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.beastmen_gor",
								type            = "numeric",
								
								default_value   = Breeds.beastmen_gor.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.beastmen_bestigor",
								type            = "numeric",
								
								default_value   = Breeds.beastmen_bestigor.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.beastmen_standard_bearer",
								type            = "numeric",
								
								default_value   = Breeds.beastmen_standard_bearer.diff_stagger_resist[8],
								range           = {1, 50},
								decimals_number = 3,
							},
						}
					},
					{
						setting_id  = "stagger",
						type        = "group",
						sub_widgets = {
							{
								setting_id      = "normal.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 20,
								range           = {0, 20},
								decimals_number = 2,
							},
							{
								setting_id      = "hard.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 20,
								range           = {0, 20},
								decimals_number = 2,
							},
							{
								setting_id      = "harder.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 20,
								range           = {0, 20},
								decimals_number = 2,
							},
							{
								setting_id      = "hardest.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 20,
								range           = {0, 20},
								decimals_number = 2,
							},
							{
								setting_id      = "cataclysm.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 20,
								range           = {0, 20},
								decimals_number = 2,
							},
							{
								setting_id      = "cataclysm_2.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 30,
								range           = {0, 30},
								decimals_number = 2,
							},
							{
								setting_id      = "cataclysm_3.stagger_damage_multiplier",
								type            = "numeric",
								unit_text       = "percent",
								default_value   = 50,
								range           = {0, 50},
								decimals_number = 2,
							},
						},
					},
					{
						setting_id  = "skaven_poison_wind_globadier_poison",
						type        = "group",
						sub_widgets = {
							{
								setting_id      = "skaven_poison_wind_globadier.throw_poison_globe_init_damage",
								type            = "numeric",
								default_value   = 10,
								range           = {0, 50},
								decimals_number = 1,
							},
							{
								setting_id      = "skaven_poison_wind_globadier.throw_poison_globe_dot",
								type            = "numeric",
								default_value   = 15,
								range           = {0, 50},
								decimals_number = 1,
							},
							{
								setting_id      = "skaven_poison_wind_globadier.suicide_run_init_damage",
								type            = "numeric",
								default_value   = 40,
								range           = {0, 100},
								decimals_number = 1,
							},
							{
								setting_id      = "skaven_poison_wind_globadier.suicide_run_dot",
								type            = "numeric",
								default_value   = 10,
								range           = {0, 50},
								decimals_number = 1,
							},
						},
					},
				}
			}, --]]
		}
	},
}
