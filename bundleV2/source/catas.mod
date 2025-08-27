return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`catas` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("catas", {
			mod_script       = "scripts/mods/catas/catas",
			mod_data         = "scripts/mods/catas/catas_data",
			mod_localization = "scripts/mods/catas/catas_localization",
		})
	end,
	packages = {
		"resource_packages/catas/catas",
	},
}
