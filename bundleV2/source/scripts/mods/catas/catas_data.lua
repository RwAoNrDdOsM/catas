local mod = get_mod("catas")

return {
	name = "Cata 3 & Deathwish",
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id      = "diff_stagger_resist.chaos_bulwark",
				type            = "numeric",
				default_value   = Breeds.chaos_bulwark.diff_stagger_resist[8],
				range           = {1, 100},
				decimals_number = 2,
			},--]]
			{
				setting_id      = "shield_block_threshold",
				type            = "numeric",
				default_value   = 4,
				range           = {1, 10},
				decimals_number = 0,
			},--]]
			{
				setting_id      = "shield_open_stagger_threshold",
				type            = "numeric",
				default_value   = 12,
				range           = {1, 20},
				decimals_number = 0,
			},--]]
			{
				setting_id      = "stagger_regen_rate_1",
				type            = "numeric",
				default_value   = 2,
				range           = {1, 5},
				decimals_number = 1,
			},--]]
			{
				setting_id      = "stagger_regen_rate_2",
				type            = "numeric",
				default_value   = 1,
				range           = {1, 5},
				decimals_number = 1,
			},--]]
			{
				setting_id      = "heavy",
				type            = "numeric",
				default_value   = 3,
				range           = {1, 20},
				decimals_number = 1,
			},--]]
			{
				setting_id      = "shield_block_stagger",
				type            = "numeric",
				default_value   = 10,
				range           = {1, 20},
				decimals_number = 1,
			},--]]
			{
				setting_id      = "shield_open_stagger",
				type            = "numeric",
				default_value   = 11,
				range           = {1, 20},
				decimals_number = 1,
			},--]]
		}
	},
}
