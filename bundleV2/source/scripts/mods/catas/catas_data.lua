local mod = get_mod("catas")

return {
	name = "Cata 3 & Deathwish",
	description = mod:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id  = "burby",
				type          = "dropdown",
				default_value = "legend",
				options = {
					{text = "default",   value = "default", show_widgets = {}},
					{text = "legend",   value = "legend", show_widgets = {}},
					{text = "legend+",   value = "legend+", show_widgets = {}},
				},
			},
			{
				setting_id  = "seer",
				type          = "dropdown",
				default_value = "legend",
				options = {
					{text = "default",   value = "default", show_widgets = {}},
					{text = "legend",   value = "legend", show_widgets = {}},
					{text = "legend+",   value = "legend+", show_widgets = {}},
				},
			},
		}
	},
}
