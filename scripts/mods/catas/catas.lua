local mod = get_mod("catas")
local mutator = mod:persistent_table("catas")

-- Display cata dispaly images for cata 2 & 3
DifficultySettings.cataclysm_2.display_image = "difficulty_option_6"
DifficultySettings.cataclysm_3.display_image = "difficulty_option_6"

mod:hook(LevelUnlockUtils, "completed_level_difficulty_index", function (func, statistics_db, player_stats_id, level_key)
	local difficulty_complete_index = func(statistics_db, player_stats_id, level_key)
	if difficulty_complete_index > 5 then -- Cata 2 & 3 are rank 7 & 8 respectivley. This makes sure it return the Legend rank
		return 5
	else
		return difficulty_complete_index
	end
end)

-- Cata 2&3 option
DefaultDifficulties = {
	"normal",
	"hard",
	"harder",
	"hardest",
	"cataclysm",
	"cataclysm_2",
	"cataclysm_3",
}
DifficultyMapping = {
	hardest = "legend",
	hard = "veteran",
	harder = "champion",
	cataclysm = "cataclysm",
	normal = "recruit",
	cataclysm_2 = "cataclysm_2",
	cataclysm_3 = "cataclysm_3",
}

-- Cata 1 patrols for Cata 2/3
PatrolFormationSettings.chaos_warrior_default.cataclysm_2 = PatrolFormationSettings.chaos_warrior_default.cataclysm
PatrolFormationSettings.storm_vermin_two_column.cataclysm_2 = PatrolFormationSettings.storm_vermin_two_column.cataclysm
PatrolFormationSettings.storm_vermin_shields_infront.cataclysm_2 = PatrolFormationSettings.storm_vermin_shields_infront.cataclysm
PatrolFormationSettings.beastmen_standard.cataclysm_2 = PatrolFormationSettings.beastmen_standard.cataclysm
PatrolFormationSettings.beastmen_archers.cataclysm_2 = PatrolFormationSettings.beastmen_standard.cataclysm
PatrolFormationSettings.chaos_warrior_default.cataclysm_3 = PatrolFormationSettings.chaos_warrior_default.cataclysm
PatrolFormationSettings.storm_vermin_two_column.cataclysm_3 = PatrolFormationSettings.storm_vermin_two_column.cataclysm
PatrolFormationSettings.storm_vermin_shields_infront.cataclysm_3 = PatrolFormationSettings.storm_vermin_shields_infront.cataclysm
PatrolFormationSettings.beastmen_standard.cataclysm_3 = PatrolFormationSettings.beastmen_standard.cataclysm
PatrolFormationSettings.beastmen_archers.cataclysm_3 = PatrolFormationSettings.beastmen_standard.cataclysm

-- Lists Cata 1-3 with proper spacing (Again I need to see if there is way to modify these functions without using hook_origin so it's more compatible)
local start_game_window_difficulty_definitions = local_require("scripts/ui/views/start_game_view/windows/definitions/start_game_window_difficulty_definitions")
local scenegraph_definition = start_game_window_difficulty_definitions.scenegraph_definition
local function create_difficulty_button(scenegraph_id, size, background_icon, background_icon_unlit, background_texture, dlc_locked, is_custom_size)
	local dynamic_font_size = true
	local icon_name = "difficulty_option_1"
	local icon_scale = 0.5
	local icon_settings = UIAtlasHelper.get_atlas_settings_by_texture_name(icon_name)
	local icon_size = {
		math.floor(icon_settings.size[1] * icon_scale),
		math.floor(icon_settings.size[2] * icon_scale)
	}
	local background_texture = background_texture or "button_bg_01"
	local background_texture_settings = UIAtlasHelper.get_atlas_settings_by_texture_name(background_texture)
	local frame_name = "menu_frame_08"
	local frame_settings = UIFrameSettings[frame_name]
	local frame_width = frame_settings.texture_sizes.corner[1]
	local new_frame_name = "frame_outer_glow_01"
	local new_frame_settings = UIFrameSettings[new_frame_name]
	local new_frame_width = new_frame_settings.texture_sizes.corner[1]
	local widget = {
		element = {
			passes = {
				{
					style_id = "background",
					pass_type = "hotspot",
					content_id = "button_hotspot"
				},
				{
					style_id = "background",
					pass_type = "texture_uv",
					content_id = "background"
				},
				{
					texture_id = "background_fade",
					style_id = "background_fade",
					pass_type = "texture"
				},
				{
					texture_id = "background_icon",
					style_id = "background_icon",
					pass_type = "texture",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return content.background_icon and (button_hotspot.is_hover or button_hotspot.is_selected)
					end
				},
				{
					texture_id = "background_icon_unlit",
					style_id = "background_icon_unlit",
					pass_type = "texture",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return content.background_icon_unlit and not button_hotspot.is_hover
					end
				},
				{
					texture_id = "dlc_locked_texture",
					style_id = "dlc_locked_texture",
					pass_type = "texture",
					content_check_function = function (content)
						return content.dlc_locked
					end
				},
				{
					texture_id = "frame",
					style_id = "frame",
					pass_type = "texture_frame"
				},
				{
					texture_id = "new_texture",
					style_id = "new_texture",
					pass_type = "texture",
					content_check_function = function (content)
						return content.new
					end
				},
				{
					texture_id = "icon",
					style_id = "icon",
					pass_type = "texture",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return not button_hotspot.disable_button
					end
				},
				{
					texture_id = "icon",
					style_id = "icon_disabled",
					pass_type = "texture",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return button_hotspot.disable_button
					end
				},
				{
					texture_id = "icon_frame",
					style_id = "icon_frame",
					pass_type = "texture"
				},
				{
					texture_id = "icon_glass",
					style_id = "icon_glass",
					pass_type = "texture"
				},
				{
					texture_id = "icon_bg_glow",
					style_id = "icon_bg_glow",
					pass_type = "texture"
				},
				{
					texture_id = "glass",
					style_id = "glass_top",
					pass_type = "texture"
				},
				{
					texture_id = "glass",
					style_id = "glass_bottom",
					pass_type = "texture"
				},
				{
					texture_id = "hover_glow",
					style_id = "hover_glow",
					pass_type = "texture"
				},
				{
					texture_id = "select_glow",
					style_id = "select_glow",
					pass_type = "texture"
				},
				{
					texture_id = "skull_select_glow",
					style_id = "skull_select_glow",
					pass_type = "texture"
				},
				{
					style_id = "title_text",
					pass_type = "text",
					text_id = "title_text",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return not button_hotspot.disable_button
					end
				},
				{
					style_id = "title_text_disabled",
					pass_type = "text",
					text_id = "title_text",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return button_hotspot.disable_button
					end
				},
				{
					style_id = "title_text_shadow",
					pass_type = "text",
					text_id = "title_text"
				},
				{
					pass_type = "rect",
					style_id = "button_clicked_rect"
				},
				{
					style_id = "button_disabled_rect",
					pass_type = "rect",
					content_check_function = function (content)
						local button_hotspot = content.button_hotspot

						return button_hotspot.disable_button
					end
				}
			}
		},
		content = {
			glass = "button_glass_02",
			title_text = "n/a",
			hover_glow = "button_state_default",
			icon_frame = "menu_options_button_bg",
			icon_bg_glow = "menu_options_button_glow_01",
			dlc_locked_texture = "hero_icon_locked",
			icon_glass = "menu_options_button_fg",
			new_texture = "list_item_tag_new",
			select_glow = "button_state_default_2",
			background_fade = "button_bg_fade",
			skull_select_glow = "menu_options_button_glow_03",
			background_icon = background_icon,
			background_icon_unlit = background_icon_unlit,
			icon = icon_name,
			frame = frame_settings.texture,
			button_hotspot = {},
			dlc_locked = dlc_locked,
			background = {
				uvs = {
					{
						0,
						1 - math.min(size[2] / background_texture_settings.size[2], 1)
					},
					{
						math.min(size[1] / background_texture_settings.size[1], 1),
						1
					}
				},
				texture_id = background_texture
			}
		},
		style = {
			background = {
				color = {
					255,
					200,
					200,
					200
				},
				offset = {
					0,
					0,
					0
				},
				size = size
			},
			background_fade = {
				color = {
					255,
					255,
					255,
					255
				},
				offset = {
					frame_width,
					frame_width,
					1
				},
				size = {
					size[1] - frame_width * 2,
					size[2] - frame_width * 2
				}
			},
			background_icon = {
				vertical_alignment = "center",
				saturated = false,
				horizontal_alignment = "right",
				color = {
					150,
					100,
					100,
					100
				},
				default_color = {
					150,
					100,
					100,
					100
				},
				texture_size = {
					350,
					108
				},
				offset = {
					frame_width,
					frame_width,
					3
                },
                size = {
					size[1] - frame_width * 2,
					size[2] - frame_width * 2
				}
			},
			background_icon_unlit = {
				vertical_alignment = "center",
				saturated = false,
				horizontal_alignment = "right",
				color = {
					150,
					100,
					100,
					100
				},
				default_color = {
					150,
					100,
					100,
					100
				},
				texture_size = {
					350,
					108
				},
				offset = {
					frame_width,
					frame_width,
					3
                },
                size = {
					size[1] - frame_width * 2,
					size[2] - frame_width * 2
				}
			},
			dlc_locked_texture = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				color = {
					204,
					255,
					255,
					255
				},
				texture_size = {
					60,
					70
				},
				offset = {
					-100,
					0,
					3
				}
			},
			hover_glow = {
				color = {
					0,
					255,
					255,
					255
				},
				offset = {
					0,
					5,
					2
				},
				size = size
			},
			select_glow = {
				color = {
					0,
					255,
					255,
					255
				},
				offset = {
					0,
					5,
					3
				},
				size = size
			},
			title_text = {
				font_size = 32,
				upper_case = true,
				word_wrap = true,
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_type = "hell_shark_header",
				dynamic_font_size = dynamic_font_size,
				text_color = Colors.get_color_table_with_alpha("font_button_normal", 255),
				default_text_color = Colors.get_color_table_with_alpha("font_button_normal", 255),
				select_text_color = Colors.get_color_table_with_alpha("white", 255),
				offset = {
					130,
					0,
					6
				},
				size = {
					size[1] - 140,
					size[2]
				}
			},
			title_text_disabled = {
				font_size = 32,
				upper_case = true,
				word_wrap = true,
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_type = "hell_shark_header",
				dynamic_font_size = dynamic_font_size,
				text_color = Colors.get_color_table_with_alpha("gray", 255),
				default_text_color = Colors.get_color_table_with_alpha("gray", 255),
				offset = {
					130,
					0,
					6
				},
				size = {
					size[1] - 140,
					size[2]
				}
			},
			title_text_shadow = {
				font_size = 32,
				upper_case = true,
				word_wrap = true,
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_type = "hell_shark_header",
				dynamic_font_size = dynamic_font_size,
				text_color = Colors.get_color_table_with_alpha("black", 255),
				default_text_color = Colors.get_color_table_with_alpha("black", 255),
				offset = {
					132,
					-2,
					5
				},
				size = {
					size[1] - 140,
					size[2]
				}
			},
			button_clicked_rect = {
				color = {
					0,
					0,
					0,
					0
				},
				offset = {
					0,
					0,
					7
				},
				size = size
			},
			button_disabled_rect = {
				color = {
					150,
					5,
					5,
					5
				},
				offset = {
					0,
					0,
					5
				},
				size = size
			},
			glass_top = {
				color = {
					255,
					255,
					255,
					255
				},
				offset = {
					0,
					size[2] - (frame_width + 9),
					6
				},
				size = {
					size[1],
					11
				}
			},
			glass_bottom = {
				color = {
					200,
					255,
					255,
					255
				},
				offset = {
					0,
					frame_width - 11,
					6
				},
				size = {
					size[1],
					11
				}
			},
			frame = {
				color = {
					255,
					255,
					255,
					255
				},
				offset = {
					0,
					0,
					10
				},
				size = size,
				texture_size = frame_settings.texture_size,
				texture_sizes = frame_settings.texture_sizes
			},
			new_texture = {
				color = {
					255,
					255,
					255,
					255
				},
				offset = {
					size[1] - 126,
					size[2] - 56,
					6
				},
				size = {
					126,
					51
				}
			},
			icon_frame = {
				color = {
					255,
					255,
					255,
					255
				},
				texture_size = {
					116,
					108
				},
				offset = {
					0,
					0,
					11
				}
			},
			icon_glass = {
				color = {
					255,
					255,
					255,
					255
				},
				texture_size = {
					116,
					108
				},
				offset = {
					0,
					0,
					15
				}
			},
			icon_bg_glow = {
				color = {
					0,
					255,
					255,
					255
				},
				texture_size = {
					116,
					108
				},
				offset = {
					0,
					0,
					11
				}
			},
			icon = {
				color = Colors.get_color_table_with_alpha("font_button_normal", 255),
				default_color = Colors.get_color_table_with_alpha("font_button_normal", 255),
				select_color = Colors.get_color_table_with_alpha("white", 255),
				texture_size = icon_size,
				offset = {
					54 - icon_size[1] / 2,
					54 - icon_size[2] / 2,
					12
				}
			},
			icon_disabled = {
				color = {
					255,
					40,
					40,
					40
				},
				default_color = {
					255,
					40,
					40,
					40
				},
				select_color = {
					255,
					40,
					40,
					40
				},
				texture_size = icon_size,
				offset = {
					54 - icon_size[1] / 2,
					54 - icon_size[2] / 2,
					12
				}
			},
			skull_select_glow = {
				color = {
					0,
					255,
					255,
					255
				},
				offset = {
					0,
					0,
					12
				},
				size = {
					28,
					size[2]
				}
			}
		},
		scenegraph_id = scenegraph_id,
		offset = {
			0,
			0,
			0
		}
	}

	return widget
end
local create_dlc_difficulty_divider = start_game_window_difficulty_definitions.create_dlc_difficulty_divider
local STARTING_DIFFICULTY_INDEX = 1
mod:hook_origin(StartGameWindowDifficulty, "_setup_difficulties", function (self)
	local difficulty_widgets = {}
	local dlc_difficulty_widgets = {}
	local difficulties = self:_get_difficulty_options()
	local widgets = self._widgets
	local widgets_by_name = self._widgets_by_name
	local widget_index_counter = 1
	local widget_prefix = "difficulty_option_"
	local spacing = 16
	local scenegraph_id = "difficulty_option"
	local size = scenegraph_definition[scenegraph_id].size
	local widget_definition = create_difficulty_button(scenegraph_id, size)
	local current_offset = 0
	local dlc_difficulties = {}

	for i = STARTING_DIFFICULTY_INDEX, #difficulties, 1 do
		local difficulty_key = difficulties[i]
		local difficulty_settings = DifficultySettings[difficulty_key]

		if difficulty_settings.dlc_requirement then
			dlc_difficulties[#dlc_difficulties + 1] = difficulty_key
		else
			local display_name = difficulty_settings.display_name
			local display_image = difficulty_settings.display_image
			local widget = UIWidget.init(widget_definition)
			local widget_name = widget_prefix .. widget_index_counter
			widgets_by_name[widget_name] = widget
			widgets[#widgets + 1] = widget
			difficulty_widgets[#difficulty_widgets + 1] = widget
			local offset = widget.offset
			local content = widget.content
			content.difficulty_key = difficulty_key
			content.title_text = Localize(display_name)
			content.icon = display_image
			offset[2] = current_offset
			current_offset = current_offset - (size[2] + spacing)
			widget_index_counter = widget_index_counter + 1
		end
	end

	self.ui_scenegraph.game_options_left_chain.size[2] = math.abs(current_offset) - spacing
	self.ui_scenegraph.game_options_right_chain.size[2] = math.abs(current_offset) - spacing

	if #dlc_difficulties > 0 then
		local scenegraph_id = "dlc_difficulty_divider"
		local difficulty_divider_widget = UIWidget.init(create_dlc_difficulty_divider("divider_01_top", scenegraph_id))
		widgets_by_name.dlc_difficulty_divider = difficulty_divider_widget
		widgets[#widgets + 1] = difficulty_divider_widget
		difficulty_divider_widget.style.texture_id.offset[2] = current_offset + size[2] * 0.5 + spacing * 1.5
        current_offset = current_offset - size[2] + spacing * 2
		local scenegraph_id = "difficulty_option"
        local size = scenegraph_definition[scenegraph_id].size
        local dlc_difficulties_size = {
            size[1] / 3 - 10,
            size[2],
        }
        local x_offset = 0
        local is_custom_size = true

		for _, difficulty_key in ipairs(dlc_difficulties) do
			local difficulty_settings = DifficultySettings[difficulty_key]
			local display_name = difficulty_settings.display_name
			local display_image = difficulty_settings.display_image
			local dlc_key = difficulty_settings.dlc_requirement
			local dlc_locked = not Managers.unlock:is_dlc_unlocked(dlc_key)
			local difficulty_button_textures = difficulty_settings.button_textures
			local widget_definition = create_difficulty_button(scenegraph_id, dlc_difficulties_size, difficulty_button_textures.lit_texture, difficulty_button_textures.unlit_texture, difficulty_button_textures.background, dlc_locked, is_custom_size)
			local widget = UIWidget.init(widget_definition)
			local widget_name = widget_prefix .. widget_index_counter
			widgets_by_name[widget_name] = widget
			widgets[#widgets + 1] = widget
			difficulty_widgets[#difficulty_widgets + 1] = widget
			local offset = widget.offset
			local content = widget.content
			content.difficulty_key = difficulty_key
			content.title_text = Localize(display_name)
            content.icon = display_image
            offset[1] = x_offset
            offset[2] = current_offset
			x_offset = x_offset + dlc_difficulties_size[1] + 10
		end
	end

	self._difficulty_widgets = difficulty_widgets
end)

-- Deathwish
local difficulty_start = 5 - 1 --Just change Legend and up values
local difficulties = 8 - difficulty_start --How many times to do

--Saving Original Values
if not mutator.data_saved then
	mutator.Breeds = table.clone(Breeds)
	mutator.BreedActions = table.clone(BreedActions)
	mutator.DifficultySettings = table.clone(DifficultySettings)
	mutator.burby_buff = table.clone(BuffTemplates.plague_wave_face_base.buffs[1])

	mutator.data_saved = true
	--mod:echo("Saved Values")
end

--below mutator code lifted from Grimalackt's Deathwish Mod

mutator.start = function()
	--Skaven
	--Below is the values for each taken by what the VT2 Endgame Community thinks works best.
	--diff_stagger_resist.skaven_slave 15
	--diff_stagger_resist.skaven_clan_rat 18.5
	--diff_stagger_resist.skaven_storm_vermin 35
	--diff_stagger_resist.skaven_storm_vermin_commander  35
	--diff_stagger_resist.skaven_plague_monk 35
	--diff_stagger_resist.skaven_pack_master 45
	--diff_stagger_resist.skaven_ratling_gunner 27
	--diff_stagger_resist.skaven_warpfire_thrower 27
	--diff_stagger_resist.skaven_storm_vermin_warlord 50
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_slave.diff_stagger_resist[i] = 15
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_clan_rat.diff_stagger_resist[i] = 18.5
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_clan_rat_with_shield.diff_stagger_resist[i] = 18.5
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin.diff_stagger_resist[i] = 35
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin_with_shield.diff_stagger_resist[i] = 35
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin_commander.diff_stagger_resist[i] = 35
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_plague_monk.diff_stagger_resist[i] = 35
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_pack_master.diff_stagger_resist[i] = 45
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_pack_master.diff_stagger_resist[i] = 27
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_ratling_gunner.diff_stagger_resist[i] = 27
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_warpfire_thrower.diff_stagger_resist[i] = 27
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[i] = 50
	end
	--Chaos
	--diff_stagger_resist.chaos_fanatic 20
	--diff_stagger_resist.chaos_marauder 28
	--diff_stagger_resist.chaos_raider 33
	--diff_stagger_resist.chaos_berzerker 35
	--diff_stagger_resist.chaos_warrior 45
	--diff_stagger_resist.chaos_sorcerers 30
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_fanatic.diff_stagger_resist[i] = 20
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_marauder.diff_stagger_resist[i] = 28
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_marauder_with_shield.diff_stagger_resist[i] = 28
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_raider.diff_stagger_resist[i] = 33
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_berzerker.diff_stagger_resist[i] = 35
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_warrior.diff_stagger_resist[i] = 45
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[i] = 30
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_mutator_sorcerer.diff_stagger_resist[i] = 30
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_plague_sorcerer.diff_stagger_resist[i] = 30
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_vortex_sorcerer.diff_stagger_resist[i] = 30
	end

	--Beastmen
	--diff_stagger_resist.beastmen_ungor 12
	--diff_stagger_resist.beastmen_ungor_archer 12
	--diff_stagger_resist.beastmen_gor 19.5
	--diff_stagger_resist.beastmen_bestigor 40
	--diff_stagger_resist.beastmen_standard_bearer 25
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_ungor.diff_stagger_resist[i] = 12
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_ungor_archer.diff_stagger_resist[i] = 12
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_gor.diff_stagger_resist[i] = 19.5
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_bestigor.diff_stagger_resist[i] = 40
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_standard_bearer.diff_stagger_resist[i] = 25
	end

	--Reduced stagger_damage_multiplier
	DifficultySettings.cataclysm_2.stagger_damage_multiplier = 0.2
	DifficultySettings.cataclysm_3.stagger_damage_multiplier = 0.2

	--Globadier increased values
	--skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage 15
	--skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage 22.5
	--skaven_poison_wind_globadier.suicide_run.aoe_init_damage 60
	--skaven_poison_wind_globadier.suicide_run.aoe_dot_damage 15
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage[i] = {15,0,0}
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[i] = {22.5,1,0}
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_dot_damage[i] = {60,0,0}
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_init_damage[i] = {15,1,0}
	end

	mutator.active = true
end

mutator.stop = function()
	--Skaven
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_slave.diff_stagger_resist[i] = mutator.Breeds.skaven_slave.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_clan_rat.diff_stagger_resist[i] = mutator.Breeds.skaven_clan_rat.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_clan_rat_with_shield.diff_stagger_resist[i] = mutator.Breeds.skaven_clan_rat_with_shield.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin_with_shield.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin_with_shield.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin_commander.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin_commander.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_plague_monk.diff_stagger_resist[i] = mutator.Breeds.skaven_plague_monk.diff_stagger_resist[i] 
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_pack_master.diff_stagger_resist[i] = mutator.Breeds.skaven_pack_master.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_pack_master.diff_stagger_resist[i] = mutator.Breeds.skaven_pack_master.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_ratling_gunner.diff_stagger_resist[i] = mutator.Breeds.skaven_ratling_gunner.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_warpfire_thrower.diff_stagger_resist[i] = mutator.Breeds.skaven_warpfire_thrower.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[i]
	end

	--Chaos
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_fanatic.diff_stagger_resist[i] = mutator.Breeds.chaos_fanatic.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_marauder.diff_stagger_resist[i] = mutator.Breeds.chaos_marauder.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_marauder_with_shield.diff_stagger_resist[i] = mutator.Breeds.chaos_marauder_with_shield.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_raider.diff_stagger_resist[i] = mutator.Breeds.chaos_raider.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_berzerker.diff_stagger_resist[i] = mutator.Breeds.chaos_berzerker.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_warrior.diff_stagger_resist[i] = mutator.Breeds.chaos_warrior.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_mutator_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_mutator_sorcerer.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_plague_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_plague_sorcerer.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_vortex_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_vortex_sorcerer.diff_stagger_resist[i]
	end

	--Beastmen
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_ungor.diff_stagger_resist[i] = mutator.Breeds.beastmen_ungor.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_ungor_archer.diff_stagger_resist[i] = mutator.Breeds.beastmen_ungor_archer.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_gor.diff_stagger_resist[i] = mutator.Breeds.beastmen_gor.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_bestigor.diff_stagger_resist[i] = mutator.Breeds.beastmen_bestigor.diff_stagger_resist[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_standard_bearer.diff_stagger_resist[i] = mutator.Breeds.beastmen_standard_bearer.diff_stagger_resist[i]
	end

	--stagger_damage_multiplier
	DifficultySettings.cataclysm_2.stagger_damage_multiplier = mutator.DifficultySettings.cataclysm_2.stagger_damage_multiplier
	DifficultySettings.cataclysm_3.stagger_damage_multiplier = mutator.DifficultySettings.cataclysm_3.stagger_damage_multiplier

	--Globadier values
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_dot_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_dot_damage[i]
	end
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_init_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_init_damage[i]
	end

	if Breeds.skaven_slave.diff_stagger_resist[5] ~= 2.25 then
		mod:chat_broadcast("Original Values not saved properly. Please Restart Game.\nIf this is repeated issue, please get in contact with RwAoNrDdOsM.")
	end
	mutator.active = false
end

mutator.toggle = function()
	if Managers.state.game_mode == nil or (Managers.state.game_mode._game_mode_key ~= "inn" and Managers.player.is_server) then
		mod:echo("You must be in the keep to do that!")
		return
	end

	if not mutator.active then
		if not Managers.player.is_server then
			mod:echo("You must be the host to activate this.")
			return
		end
		mutator.start()
		mod:chat_broadcast("Deathwish ENABLED.")
	else
		mutator.stop()
		mod:chat_broadcast("Deathwish DISABLED.")
	end
end

mod:command("deathwish", "Toggle Deathwish. Must be host and in the keep.", function() mutator.toggle() end)

--Easy way to change stuff when settings change
--Table that contains functions, strings or tables to do things when options are changed
local widget_settings = {
	burby = function()
		local setting = mod:get("burby") 
		if setting == "default" then
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_init_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_init_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_dot_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_dot_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_init_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_init_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_dot_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_dot_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_init_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_init_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_dot_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_dot_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_init_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_init_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_dot_damage[i] = mutator.BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_dot_damage[i]
			end
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm = mutator.burby_buff.difficulty_damage.cataclysm
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm_2 = mutator.burby_buff.difficulty_damage.cataclysm_2
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm_3 = mutator.burby_buff.difficulty_damage.cataclysm_3
		elseif setting == "legend" then
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_init_damage[i] = 10
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_dot_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_init_damage[i] = 10
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_dot_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_init_damage[i] = 10
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_dot_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_init_damage[i] = 10
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_dot_damage[i] = 15
			end
			local legend = BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.hardest or {1,1,0,6,1}
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm = legend
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm_2 = legend
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm_3 = legend
		elseif setting == "legend+" then
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_init_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_missile.aoe_dot_damage[i] = 20
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_init_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.cast_seeking_bomb_missile.aoe_dot_damage[i] = 20
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_init_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_magic_missile.aoe_dot_damage[i] = 20
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_init_damage[i] = 15
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.chaos_exalted_sorcerer.defensive_seeking_bomb.aoe_dot_damage[i] = 20
			end
			local legend = {1,1,0,8,1}
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm = legend
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm_2 = legend
			BuffTemplates.plague_wave_face_base.buffs[1].difficulty_damage.cataclysm_3 = legend
		end
	end,
	seer = function()
		local setting = mod:get("seer") 
		if setting == "default" then
			for i=1, 3 do 
				local i = i + 5
				BreedActions.skaven_grey_seer.cast_missile.aoe_init_damage[i] = mutator.BreedActions.skaven_grey_seer.cast_missile.aoe_init_damage[i]
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.skaven_grey_seer.cast_missile.aoe_dot_damage[i] = mutator.BreedActions.skaven_grey_seer.cast_missile.aoe_dot_damage[i]
			end
		elseif setting == "legend" then
			for i=1, 3 do 
				local i = i + 5
				BreedActions.skaven_grey_seer.cast_missile.aoe_init_damage[i] = {7,1,0}
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.skaven_grey_seer.cast_missile.aoe_dot_damage[i] = {10,0,0}
			end
		elseif setting == "legend+" then
			for i=1, 3 do 
				local i = i + 5
				BreedActions.skaven_grey_seer.cast_missile.aoe_init_damage[i] = {10,1,0}
			end
			for i=1, 3 do 
				local i = i + 5
				BreedActions.skaven_grey_seer.cast_missile.aoe_dot_damage[i] = {15,0,0}
			end
		end
	end,
	deathwish = function ()
		mutator.toggle()
	end
}

--function to make the widget_settings table do stuff
local function type_widget_setting(widget_setting, setting_id)
	if type(widget_setting) == "table" then
		if #widget_setting > 0 then
			for i=1, #widget_setting do
				local setting = widget_setting[i]
				type_widget_setting(setting)
			end
		else
			for widget, _widget in pairs(widget_setting) do
				type_widget_setting(widget_setting[widget])
			end
		end
	elseif type(widget_setting) == "string" then
		mod:pcall(function()
			widget_setting = mod:get(setting_id)
			return
		end)
	elseif type(widget_setting) == "function" then
		mod:pcall(function()
			widget_setting()
		end)
	end
end

mod.on_setting_changed = function(setting_id)
	if widget_settings[setting_id] then
		local widget_setting = widget_settings[setting_id]
		type_widget_setting(widget_setting, setting_id)
	end
end 

-- Set predetermined values when mod loads
local widget_setting_1 = widget_settings["burby"]
type_widget_setting(widget_setting_1, setting_id)
local widget_setting_2 = widget_settings["seer"]
type_widget_setting(widget_setting_2, setting_id)