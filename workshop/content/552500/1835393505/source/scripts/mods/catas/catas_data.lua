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
		}
	},
}
