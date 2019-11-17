local mod = get_mod("catas")

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

-- 900 Hero Power
local function magic_level_to_power_level(magic_level)
    local settings = PowerLevelFromMagicLevel

    return math.min(math.ceil(settings.starting_power_level + magic_level * settings.power_level_per_magic_level), settings.max_power_level)
end
local function career_magic_level_to_power_level(magic_level)
    local settings = PowerLevelFromMagicLevel

    return math.min(math.ceil(math.clamp(magic_level * settings.amulet_power_level_per_magic_level, 0, settings.power_level_per_magic_level)), settings.max_power_level)
end
local function get_average_power_level(self, career_name)
    local backend_manger = Managers.backend
    local backend_interface_weaves = backend_manger:get_interface("weaves")
    local magic_level = backend_interface_weaves:max_magic_level()
    local power_level = magic_level_to_power_level(magic_level)
    local sum = power_level + power_level
	local career_power_level = career_magic_level_to_power_level(magic_level)
	local result = math.ceil(sum * 0.5)

	if career_power_level then
		result = result + career_power_level
	end

	return result
end
MIN_POWER_LEVEL_CAP = MIN_POWER_LEVEL_CAP or 200 -- Incase it isn't a global for whatever reason
mod:hook(BackendUtils, "get_total_power_level", function (func, profile_name, career_name, optional_game_mode_key)
	if script_data.power_level_override then
		return script_data.power_level_override
	end

	local game_mode_manager = Managers.state.game_mode

	if game_mode_manager:has_activated_mutator("whiterun") then
		return MIN_POWER_LEVEL_CAP
	end

	if mod:get("hero_power") then
		local average_power_level = get_average_power_level(career_name)

		return average_power_level
	else
		return func(profile_name, career_name, optional_game_mode_key)
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

mod:hook(DifficultyManager, "get_difficulty_rank", function (func, self, check)
	local result = func(self)
	if result > 6 and check then
		return 6
	else
		return result
	end
end)

mod:hook(DifficultyManager, "get_difficulty", function (func, self, check)
	local result = func(self)
	if result == "cataclysm_2" or result == "cataclysm_3" then
		return "cataclysm"
	else
		return result
	end
	return self.difficulty
end)

-- Proper spawning for events (Need to see if there is way to modify these functions without using hook_origin so it's more compatible)
local function disable_elements_with_lower_difficulty(elements)
	local current_difficulty = Managers.state.difficulty:get_difficulty_rank(true)
	local num_elements = #elements

	for i = 1, num_elements, 1 do
		local element = elements[i]

		if element.difficulty_requirement then
			if current_difficulty < element.difficulty_requirement then -- This will work with the ranks of Cata 2 and Cata 3
				element.disabled = true
			elseif element.disabled then
				element.disabled = nil
			end
        elseif element.only_on_difficulty then
			if current_difficulty ~= element.only_on_difficulty then
				element.disabled = true
			elseif element.disabled then
				element.disabled = nil
			end
		end
	end
end
-- So I can hook into disable_elements_with_lower_difficulty function
mod:hook_origin(TerrorEventMixer, "start_event", function (event_name, data)
	if script_data.ai_terror_events_disabled then
		return
	end

	local active_events = TerrorEventMixer.active_events
	local level_transition_handler = Managers.state.game_mode.level_transition_handler
	local level_key = level_transition_handler:get_current_level_keys()
	local elements = TerrorEventBlueprints[level_key][event_name] or GenericTerrorEvents[event_name]

	fassert(elements, "No terror event called '%s', exists. Make sure it is added to level %s terror event file if its supposed to be there.", event_name, level_key)
	print("TerrorEventMixer.start_event:", event_name)
	disable_elements_with_lower_difficulty(elements)

	local new_event = {
		index = 1,
		ends_at = 0,
		name = event_name,
		elements = elements,
		data = data,
		max_active_enemies = math.huge
	}
	active_events[#active_events + 1] = new_event
	local t = Managers.time:time("game")
	local element = elements[1]
	local func_name = element[1]

	if not element.disabled then
		TerrorEventMixer.init_functions[func_name](new_event, element, t)
	end

	Managers.telemetry.events:terror_event_started(event_name)
end)
-- Fixed the issue with special spawns
mod:hook_origin(TerrorEventMixer.run_functions, "spawn_special", function (event, element, t, dt)
    local breed_name = nil
    local check_name = element.breed_name
    local num_to_spawn = element.amount or 1
    local num_to_spawn_scaled = element.difficulty_amount
    local conflict_director = Managers.state.conflict

    if num_to_spawn_scaled then
        local current_difficulty = Managers.state.difficulty:get_difficulty(true)
        local chosen_amount = num_to_spawn_scaled[current_difficulty]
        chosen_amount = chosen_amount or num_to_spawn_scaled.hardest

        if type(chosen_amount) == "table" then
            num_to_spawn = chosen_amount[Math.random(1, #chosen_amount)]
        else
            num_to_spawn = chosen_amount
        end
    elseif type(num_to_spawn) == "table" then
        num_to_spawn = num_to_spawn[Math.random(1, #num_to_spawn)]
    end

    if type(check_name) == "table" then
        breed_name = check_name[Math.random(1, #check_name)]
    else
        breed_name = check_name
    end

    for i = 1, num_to_spawn, 1 do
        local hidden_pos = conflict_director.specials_pacing:get_special_spawn_pos()

        conflict_director:spawn_one(Breeds[breed_name], hidden_pos)
    end

    return true
end)
mod:hook_origin(TerrorEventMixer.run_functions, "spawn_weave_special_event", function (event, element, t, dt)
    local breed_name = nil
    local check_name = element.breed_name
    local num_to_spawn = element.amount or 1
    local num_to_spawn_scaled = element.difficulty_amount
    local data = event.data
    local seed = data.seed
    local conflict_director = Managers.state.conflict

    if num_to_spawn_scaled then
        local current_difficulty = Managers.state.difficulty:get_difficulty(true)
        local chosen_amount = num_to_spawn_scaled[current_difficulty]
        chosen_amount = chosen_amount or num_to_spawn_scaled.hardest

        if type(chosen_amount) == "table" then
            local index = nil
            seed, index = Math.next_random(seed, 1, #chosen_amount)
            num_to_spawn = chosen_amount[index]
        else
            num_to_spawn = chosen_amount
        end
    elseif type(num_to_spawn) == "table" then
        local index = nil
        seed, index = Math.next_random(seed, 1, #num_to_spawn)
        num_to_spawn = num_to_spawn[index]
    end

    if type(check_name) == "table" then
        local index = nil
        seed, index = Math.next_random(seed, 1, #check_name)
        breed_name = check_name[index]
    else
        breed_name = check_name
    end

    for i = 1, num_to_spawn, 1 do
        local hidden_pos = conflict_director.specials_pacing:get_special_spawn_pos()

        conflict_director:spawn_one(Breeds[breed_name], hidden_pos)
    end

    data.seed = seed

    return true
end)
mod:hook_origin(TerrorEventMixer.run_functions, "spawn_patrol", function (event, element, t, dt)
	local data = event.data
	local position = data and data.optional_pos and data.optional_pos:unbox()
	local conflict_director = Managers.state.conflict
	local patrol_template = element.patrol_template
	local main_path_patrol = element.main_path_patrol
	local patrol_data = {}

	if main_path_patrol then
		local breed = Breeds[element.breed_name]
		patrol_data.breed = breed
		patrol_data.group_type = "main_path_patrol"
		patrol_data.side_id = element.side_id
		local side_id = element.side_id

		conflict_director:spawn_group(patrol_template, position, patrol_data)
	else
		local formations = (data and data.formations) or element.formations
		local num_formations = #formations
		local random_index = (num_formations > 1 and math.random(num_formations)) or 1
		local formation_name = formations[random_index]

		assert(PatrolFormationSettings[formation_name], "No such formation exists in PatrolFormationSettings")

		local spline_name = nil
		local splines = element.splines

		if splines then
			local num_splines = #splines
			local random_index = (num_splines > 1 and math.random(num_splines)) or 1
			spline_name = splines[random_index]
		else
			spline_name = data and data.spline_id
		end

		local spline_start_position = nil
		local difficulty = Managers.state.difficulty:get_difficulty(true)
		local formation = PatrolFormationSettings[formation_name][difficulty]
		local despawn_at_end = data.one_directional
		formation.settings = PatrolFormationSettings[formation_name].settings
		local spline_way_points = data and data.spline_way_points

		if not spline_way_points then
			local route_data, waypoints, start_pos, one_directional = conflict_director.level_analysis:get_waypoint_spline(spline_name)

			if route_data then
				spline_way_points = waypoints
				spline_start_position = start_pos
				despawn_at_end = one_directional
			end
		end

		local spline_type = (data and data.spline_type) or element.spline_type
		patrol_data.spline_name = spline_name
		patrol_data.formation = formation
		patrol_data.group_type = "spline_patrol"
		patrol_data.spline_way_points = spline_way_points
		patrol_data.spline_type = spline_type
		patrol_data.despawn_at_end = despawn_at_end
		patrol_data.spawn_all_at_same_position = true

		conflict_director:spawn_spline_group(patrol_template, spline_start_position, patrol_data)
	end

	return true
end)
mod:hook_origin(TerrorEventMixer.run_functions, "set_time_challenge", function (event, element, t, dt)
	local optional_data = TerrorEventMixer.optional_data
	local time_challenge_name = element.time_challenge_name
	local challenge_threshold = QuestSettings[time_challenge_name]
	local duration = t + challenge_threshold
	local current_difficulty = Managers.state.difficulty:get_difficulty(true)
	local allowed_difficulties = QuestSettings.allowed_difficulties[time_challenge_name]
	local allowed_difficulty = allowed_difficulties[current_difficulty]

	if allowed_difficulty and not optional_data[time_challenge_name] then
		optional_data[time_challenge_name] = duration
	end
end)
mod:hook_origin(TerrorEventMixer.run_functions, "do_volume_challenge", function (event, element, t, dt)
	local optional_data = TerrorEventMixer.optional_data
	local volume_name = element.volume_name

	fassert(optional_data[volume_name] == nil, "Already started a volume challenge for volume_name=(%s)", volume_name)

	local challenge_name = element.challenge_name
	local challenge_duration = QuestSettings[challenge_name]
	local allowed_difficulties = QuestSettings.allowed_difficulties[challenge_name]
	local difficulty = Managers.state.difficulty:get_difficulty(true)
	local on_allowed_difficulty = allowed_difficulties[difficulty]
	local terminate = not on_allowed_difficulty
	optional_data[volume_name] = {
		time_inside = 0,
		duration = challenge_duration,
		player_units = {},
		terminate = terminate
	}
end)


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