local mod = get_mod("catas")

return {
	name = "Cata 3 & Deathwish",
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id      = "diff_stagger_resist.chaos_bulwark",
				type            = "checkbox",
				default_value   = false,
			},--]]
		}
	},
}
