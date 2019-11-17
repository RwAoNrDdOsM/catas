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
				type        = "group",
				sub_widgets = {
					{
						setting_id  = "diff_stagger_resist",
						type        = "group",
						sub_widgets = {
							{
								setting_id      = "diff_stagger_resist.slave_rat",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.fanatic",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.ungor",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.clan_rat",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.gor",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.marauder",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.stormvermin",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.bestigor",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.raider",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.warrior",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.berzerker",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.plague_monk",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.packmaster",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.ratling_gunner",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
								range           = {1, 50},
								decimals_number = 3,
							},
							{
								setting_id      = "diff_stagger_resist.sorcerer",
								type            = "numeric",
								unit_text       = "times",
								default_value   = 1,
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
								setting_id  = "stagger_melee",
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
								setting_id    = "stagger_ranged",
								type          = "checkbox",
								default_value = false,
								sub_widgets = {
									{
										setting_id      = "normal.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 20,
										range           = {0, 20},
										decimals_number = 2,
									},
									{
										setting_id      = "hard.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 20,
										range           = {0, 20},
										decimals_number = 2,
									},
									{
										setting_id      = "harder.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 20,
										range           = {0, 20},
										decimals_number = 2,
									},
									{
										setting_id      = "hardest.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 20,
										range           = {0, 20},
										decimals_number = 2,
									},
									{
										setting_id      = "cataclysm.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 20,
										range           = {0, 20},
										decimals_number = 2,
									},
									{
										setting_id      = "cataclysm_2.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 30,
										range           = {0, 30},
										decimals_number = 2,
									},
									{
										setting_id      = "cataclysm_3.stagger_damage_multiplier_ranged",
										type            = "numeric",
										unit_text       = "percent",
										default_value   = 50,
										range           = {0, 50},
										decimals_number = 2,
									},
								}
							},
						}
					},
				}
			},
		}
	},
}
