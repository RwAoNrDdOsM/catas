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

-- 900 Hero Power (will be removed if Sanctioned)
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

	--fassert(elements, "No terror event called '%s', exists. Make sure it is added to level %s terror event file if its supposed to be there.", event_name, level_key)
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

		--assert(PatrolFormationSettings[formation_name], "No such formation exists in PatrolFormationSettings")
		if PatrolFormationSettings[formation_name] == nil then
			mod:echo("No such formation exists in PatrolFormationSettings")
			return
		end

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

	--fassert(optional_data[volume_name] == nil, "Already started a volume challenge for volume_name=(%s)", volume_name)
	if optional_data[volume_name] ~= nil then
		mod:echo("Already started a volume challenge for volume_name=(%s)", volume_name)
		return
	end

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

-- Stagger Bonus Damage alterations (Stagger Number Override is currently not changeable) (All multiplier numbers can't be higher than their set values)
DifficultySettings.normal.stagger_damage_multiplier_ranged = 0.2
DifficultySettings.normal.stagger_number_override = 1
DifficultySettings.hard.stagger_damage_multiplier_ranged = 0.2
DifficultySettings.hard.stagger_number_override = 1
DifficultySettings.harder.stagger_damage_multiplier_ranged = 0.2
DifficultySettings.harder.stagger_number_override = 1
DifficultySettings.hardest.stagger_damage_multiplier_ranged = 0.2
DifficultySettings.hardest.stagger_number_override = 1
DifficultySettings.cataclysm.stagger_damage_multiplier_ranged = 0.2
DifficultySettings.cataclysm.stagger_number_override = 1
DifficultySettings.cataclysm_2.stagger_damage_multiplier_ranged = 0.3
DifficultySettings.cataclysm_2.stagger_number_override = 1
DifficultySettings.cataclysm_3.stagger_damage_multiplier_ranged = 0.5
DifficultySettings.cataclysm_3.stagger_number_override = 1

--Damage Utils Stuff
local BLACKBOARDS = BLACKBOARDS
local PLAYER_TARGET_ARMOR = 4
local unit_get_data = Unit.get_data
local function do_damage_calculation(attacker_unit, damage_source, original_power_level, damage_output, hit_zone_name, damage_profile, target_index, boost_curve, boost_damage_multiplier, is_critical_strike, backstab_multiplier, breed, is_dummy, dummy_unit_armor, dropoff_scalar, static_base_damage, is_player_friendly_fire, has_power_boost, difficulty_level, target_unit_armor, target_unit_primary_armor, has_crit_head_shot_killing_blow_perk, has_crit_backstab_killing_blow_perk, target_max_health)
	if damage_profile and damage_profile.no_damage then
		return 0
	end

	local difficulty_settings = DifficultySettings[difficulty_level]
	local power_boost_damage = 0
	local head_shot_boost_damage = 0
	local head_shot_min_damage = 1
	local power_boost_min_damage = 1
	local multiplier_type = DamageUtils.get_breed_damage_multiplier_type(breed, hit_zone_name, is_dummy)
	local is_finesse_hit = multiplier_type == "headshot" or multiplier_type == "weakspot" or multiplier_type == "protected_weakspot"

	if is_finesse_hit or is_critical_strike or has_power_boost or (boost_damage_multiplier and boost_damage_multiplier > 0) then
		local power_boost_armor = nil

		if target_unit_armor == 2 or target_unit_armor == 5 or target_unit_armor == 6 then
			power_boost_armor = 1
		else
			power_boost_armor = target_unit_armor
		end

		local power_boost_target_damages = damage_output[power_boost_armor] or (power_boost_armor == 0 and 0) or damage_output[1]
		local preliminary_boost_damage = nil

		if type(power_boost_target_damages) == "table" then
			local power_boost_damage_range = power_boost_target_damages.max - power_boost_target_damages.min
			local power_boost_attack_power, _ = ActionUtils.get_power_level_for_target(original_power_level, damage_profile, target_index, is_critical_strike, attacker_unit, hit_zone_name, power_boost_armor, damage_source, breed, dummy_unit_armor, dropoff_scalar, difficulty_level, target_unit_armor, target_unit_primary_armor)
			local power_boost_percentage = ActionUtils.get_power_level_percentage(power_boost_attack_power)
			preliminary_boost_damage = power_boost_target_damages.min + power_boost_damage_range * power_boost_percentage
		else
			preliminary_boost_damage = power_boost_target_damages
		end

		if is_finesse_hit then
			head_shot_min_damage = preliminary_boost_damage * 0.5
		end

		if is_critical_strike then
			head_shot_min_damage = preliminary_boost_damage * 0.5
		end

		if has_power_boost or (boost_damage_multiplier and boost_damage_multiplier > 0) then
			power_boost_damage = preliminary_boost_damage
		end
	end

	local damage, target_damages = nil
	target_damages = (static_base_damage and ((type(damage_output) == "table" and damage_output[1]) or damage_output)) or damage_output[target_unit_armor] or (target_unit_armor == 0 and 0) or damage_output[1]

	if type(target_damages) == "table" then
		local damage_range = target_damages.max - target_damages.min
		local percentage = 0

		if damage_profile then
			local attack_power, _ = ActionUtils.get_power_level_for_target(original_power_level, damage_profile, target_index, is_critical_strike, attacker_unit, hit_zone_name, nil, damage_source, breed, dummy_unit_armor, dropoff_scalar, difficulty_level, target_unit_armor, target_unit_primary_armor)
			percentage = ActionUtils.get_power_level_percentage(attack_power)
		end

		damage = target_damages.min + damage_range * percentage
	else
		damage = target_damages
	end

	local backstab_damage = nil

	if backstab_multiplier then
		backstab_damage = (power_boost_damage and damage < power_boost_damage and power_boost_damage * (backstab_multiplier - 1)) or damage * (backstab_multiplier - 1)
	end

	if not static_base_damage then
		local power_boost_amount = 0
		local head_shot_boost_amount = 0

		if has_power_boost then
			if target_unit_armor == 1 then
				power_boost_amount = power_boost_amount + 0.75
			elseif target_unit_armor == 2 then
				power_boost_amount = power_boost_amount + 0.6
			elseif target_unit_armor == 3 then
				power_boost_amount = power_boost_amount + 0.5
			elseif target_unit_armor == 4 then
				power_boost_amount = power_boost_amount + 0.5
			elseif target_unit_armor == 5 then
				power_boost_amount = power_boost_amount + 0.5
			elseif target_unit_armor == 6 then
				power_boost_amount = power_boost_amount + 0.3
			else
				power_boost_amount = power_boost_amount + 0.5
			end
		end

		if boost_damage_multiplier and boost_damage_multiplier > 0 then
			if target_unit_armor == 1 then
				power_boost_amount = power_boost_amount + 0.75
			elseif target_unit_armor == 2 then
				power_boost_amount = power_boost_amount + 0.3
			elseif target_unit_armor == 3 then
				power_boost_amount = power_boost_amount + 0.75
			elseif target_unit_armor == 4 then
				power_boost_amount = power_boost_amount + 0.5
			elseif target_unit_armor == 5 then
				power_boost_amount = power_boost_amount + 0.5
			elseif target_unit_armor == 6 then
				power_boost_amount = power_boost_amount + 0.2
			else
				power_boost_amount = power_boost_amount + 0.5
			end
		end

		local target_settings = damage_profile and ((damage_profile.targets and damage_profile.targets[target_index]) or damage_profile.default_target)

		if is_finesse_hit then
			if damage > 0 then
				if target_unit_armor == 3 then
					head_shot_boost_amount = head_shot_boost_amount + ((target_settings and (target_settings.headshot_boost_boss or target_settings.headshot_boost)) or 0.25)
				else
					head_shot_boost_amount = head_shot_boost_amount + ((target_settings and target_settings.headshot_boost) or 0.5)
				end
			elseif target_unit_primary_armor == 6 and damage == 0 then
				head_shot_boost_amount = head_shot_boost_amount + (target_settings and (target_settings.headshot_boost_heavy_armor or 0.25))
			elseif target_unit_armor == 2 and damage == 0 then
				head_shot_boost_amount = head_shot_boost_amount + ((target_settings and (target_settings.headshot_boost_armor or target_settings.headshot_boost)) or 0.5)
			end

			if multiplier_type == "protected_weakspot" then
				head_shot_boost_amount = head_shot_boost_amount * 0.25
			end
		end

		if multiplier_type == "protected_spot" then
			power_boost_amount = power_boost_amount - 0.5
			head_shot_boost_amount = head_shot_boost_amount - 0.5
		end

		if damage_profile and damage_profile.no_headshot_boost then
			head_shot_boost_amount = 0
		end

		local crit_boost = 0

		if is_critical_strike then
			crit_boost = damage_profile.crit_boost or 0.5

			if damage_profile.no_crit_boost then
				crit_boost = 0
			end
		end

		if boost_curve and (power_boost_amount > 0 or head_shot_boost_amount > 0 or crit_boost > 0) then
			local modified_boost_curve, modified_boost_curve_head_shot = nil
			local boost_coefficient = (target_settings and target_settings.boost_curve_coefficient) or DefaultBoostCurveCoefficient
			local boost_coefficient_headshot = (target_settings and target_settings.boost_curve_coefficient_headshot) or DefaultBoostCurveCoefficient

			if boost_damage_multiplier and boost_damage_multiplier > 0 then
				if breed and breed.boost_curve_multiplier_override then
					boost_damage_multiplier = math.clamp(boost_damage_multiplier, 0, breed.boost_curve_multiplier_override)
				end

				boost_coefficient = boost_coefficient * boost_damage_multiplier
				boost_coefficient_headshot = boost_coefficient_headshot * boost_damage_multiplier
			end

			if power_boost_amount > 0 then
				modified_boost_curve = DamageUtils.get_modified_boost_curve(boost_curve, boost_coefficient)
				power_boost_amount = math.clamp(power_boost_amount, 0, 1)
				local boost_multiplier = DamageUtils.get_boost_curve_multiplier(modified_boost_curve or boost_curve, power_boost_amount)
				power_boost_damage = math.max(math.max(power_boost_damage, damage), power_boost_min_damage) * boost_multiplier
			end

			if head_shot_boost_amount > 0 or crit_boost > 0 then
				local attacker_buff_extension = attacker_unit and ScriptUnit.has_extension(attacker_unit, "buff_system")
				modified_boost_curve_head_shot = DamageUtils.get_modified_boost_curve(boost_curve, boost_coefficient_headshot)
				head_shot_boost_amount = math.clamp(head_shot_boost_amount + crit_boost, 0, 1)
				local head_shot_boost_multiplier = DamageUtils.get_boost_curve_multiplier(modified_boost_curve_head_shot or boost_curve, head_shot_boost_amount)
				head_shot_boost_damage = math.max(math.max(power_boost_damage, damage), head_shot_min_damage) * head_shot_boost_multiplier

				if attacker_buff_extension and is_critical_strike then
					head_shot_boost_damage = head_shot_boost_damage * attacker_buff_extension:apply_buffs_to_value(1, "critical_strike_effectiveness")
				end

				if attacker_buff_extension and is_finesse_hit then
					head_shot_boost_damage = head_shot_boost_damage * attacker_buff_extension:apply_buffs_to_value(1, "headshot_multiplier")
				end
			end
		end

		if breed and breed.armored_boss_damage_reduction then
			damage = damage * 0.8
			power_boost_damage = power_boost_damage * 0.5
			backstab_damage = backstab_damage and backstab_damage * 0.75
		end

		if breed and breed.boss_damage_reduction then
			damage = damage * 0.45
			power_boost_damage = power_boost_damage * 0.5
			head_shot_boost_damage = head_shot_boost_damage * 0.5
			backstab_damage = backstab_damage and backstab_damage * 0.75
		end

		if breed and breed.lord_damage_reduction then
			damage = damage * 0.2
			power_boost_damage = power_boost_damage * 0.25
			head_shot_boost_damage = head_shot_boost_damage * 0.25
			backstab_damage = backstab_damage and backstab_damage * 0.5
		end

		damage = damage + power_boost_damage + head_shot_boost_damage

		if backstab_damage then
			damage = damage + backstab_damage
		end

		if is_critical_strike then
			local killing_blow_triggered = nil

			if hit_zone_name == "head" and has_crit_head_shot_killing_blow_perk then
				killing_blow_triggered = true
			elseif backstab_multiplier and backstab_multiplier > 1 and has_crit_backstab_killing_blow_perk then
				killing_blow_triggered = true
			end

			if killing_blow_triggered and breed then
				local boss = breed.boss
				local primary_armor = breed.primary_armor_category

				if not boss and not primary_armor then
					if target_max_health then
						damage = target_max_health
					else
						local breed_health_table = breed.max_health
						local difficulty_rank = difficulty_settings.rank
						local breed_health = breed_health_table[difficulty_rank]
						damage = breed_health
					end
				end
			end
		end
	end

	if is_player_friendly_fire then
		local friendly_fire_multiplier = difficulty_settings.friendly_fire_multiplier

		if friendly_fire_multiplier then
			damage = damage * friendly_fire_multiplier
		end
	end

	local heavy_armor_damage = false

	return damage, heavy_armor_damage
end
local function apply_buffs_to_stagger_damage(attacker_unit, target_unit, target_index, hit_zone, is_critical_strike, stagger_number)
	local attacker_buff_extension = ScriptUnit.has_extension(attacker_unit, "buff_system")
	local new_stagger_number = stagger_number

	if attacker_buff_extension then
		local finesse_perk = attacker_buff_extension:has_buff_perk("finesse_stagger_damage")
		local smiter_perk = attacker_buff_extension:has_buff_perk("smiter_stagger_damage")
		local mainstay_perk = attacker_buff_extension:has_buff_perk("linesman_stagger_damage")

		if mainstay_perk and new_stagger_number > 0 then
			new_stagger_number = new_stagger_number + 1
		elseif (is_critical_strike or hit_zone == "head" or hit_zone == "neck") and finesse_perk then
			new_stagger_number = 2
		elseif smiter_perk then
			if target_index and target_index <= 1 then
				new_stagger_number = math.max(1, new_stagger_number)
			else
				new_stagger_number = 0
			end
		end
	end

	return new_stagger_number
end
mod:hook(DamageUtils, "calculate_damage", function (func, damage_output, target_unit, attacker_unit, hit_zone_name, original_power_level, boost_curve, boost_damage_multiplier, is_critical_strike, damage_profile, target_index, backstab_multiplier, damage_source)
	local difficulty_settings = Managers.state.difficulty:get_difficulty_settings()
	local breed, dummy_unit_armor, is_dummy, unit_max_health = nil

	if target_unit then
		breed = AiUtils.unit_breed(target_unit)
		dummy_unit_armor = unit_get_data(target_unit, "armor")
		is_dummy = unit_get_data(target_unit, "is_dummy")
		local target_unit_health_extension = ScriptUnit.has_extension(target_unit, "health_system")
		local is_invincible = target_unit_health_extension and target_unit_health_extension:get_is_invincible() and not is_dummy

		if is_invincible then
			return 0
		end

		if target_unit_health_extension and not is_dummy then
			unit_max_health = target_unit_health_extension:get_max_health()
		elseif breed then
			local breed_health_table = breed.max_health
			local difficulty_rank = difficulty_settings.rank
			local breed_health = breed_health_table[difficulty_rank]
			unit_max_health = breed_health
		end
	end

	local attacker_breed = nil

	if attacker_unit then
		attacker_breed = Unit.get_data(attacker_unit, "breed")
	end

	local static_base_damage = not attacker_breed or not attacker_breed.is_hero
	local is_player_friendly_fire = not static_base_damage and Managers.state.side:is_player_friendly_fire(attacker_unit, target_unit)
	local target_is_hero = breed and breed.is_hero
	local dropoff_scalar = 0

	if damage_profile and not static_base_damage then
		local target_settings = (damage_profile.targets and damage_profile.targets[target_index]) or damage_profile.default_target
		dropoff_scalar = ActionUtils.get_dropoff_scalar(damage_profile, target_settings, attacker_unit, target_unit)
	end

	local buff_extension = attacker_unit and ScriptUnit.has_extension(attacker_unit, "buff_system")
	local has_power_boost = false
	local has_crit_head_shot_killing_blow_perk = false
	local has_crit_backstab_killing_blow_perk = false

	if buff_extension then
		has_power_boost = buff_extension:has_buff_type("armor penetration")
		has_crit_head_shot_killing_blow_perk = buff_extension:has_buff_perk("crit_headshot_killing_blow")
		has_crit_backstab_killing_blow_perk = buff_extension:has_buff_perk("crit_backstab_killing_blow")
	end

	local difficulty_level = Managers.state.difficulty:get_difficulty()
	local target_unit_armor, target_unit_primary_armor, _ = nil

	if target_is_hero then
		target_unit_armor = PLAYER_TARGET_ARMOR
	else
		target_unit_armor, _, target_unit_primary_armor, _ = ActionUtils.get_target_armor(hit_zone_name, breed, dummy_unit_armor)
	end

	local calculated_damage = do_damage_calculation(attacker_unit, damage_source, original_power_level, damage_output, hit_zone_name, damage_profile, target_index, boost_curve, boost_damage_multiplier, is_critical_strike, backstab_multiplier, breed, is_dummy, dummy_unit_armor, dropoff_scalar, static_base_damage, is_player_friendly_fire, has_power_boost, difficulty_level, target_unit_armor, target_unit_primary_armor, has_crit_head_shot_killing_blow_perk, has_crit_backstab_killing_blow_perk, unit_max_health)

	if damage_profile and not damage_profile.is_dot then
		local blackboard = BLACKBOARDS[target_unit]
		local stagger_number = 0

		if blackboard then
			local ignore_stagger_damage_reduction = damage_profile.no_stagger_damage_reduction or breed.no_stagger_damage_reduction
			local min_stagger_number = 0
			local max_stagger_number = 2

			if blackboard.is_climbing then
				stagger_number = 2
			else
				stagger_number = math.min(blackboard.stagger or min_stagger_number, max_stagger_number)
			end

			if damage_profile.no_stagger_damage_reduction_ranged then
				local stagger_number_override = difficulty_settings.stagger_number_override or 1
				stagger_number = math.max(stagger_number_override, stagger_number)
			end

			if not damage_profile.no_stagger_damage_reduction_ranged then
				stagger_number = apply_buffs_to_stagger_damage(attacker_unit, target_unit, target_index, hit_zone_name, is_critical_strike, stagger_number)
			end
		elseif dummy_unit_armor then
			local target_buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")
			stagger_number = target_buff_extension:apply_buffs_to_value(0, "dummy_stagger")

			if damage_profile.no_stagger_damage_reduction_ranged then
				local stagger_number_override = difficulty_settings.stagger_number_override or 1
				stagger_number = math.max(stagger_number_override, stagger_number)
			end

			if not damage_profile.no_stagger_damage_reduction_ranged then
				stagger_number = apply_buffs_to_stagger_damage(attacker_unit, target_unit, target_index, hit_zone_name, is_critical_strike, stagger_number)
			end
		end

		local min_stagger_damage_coefficient = difficulty_settings.min_stagger_damage_coefficient
		local stagger_damage_multiplier = difficulty_settings.stagger_damage_multiplier
		local stagger_damage_multiplier_ranged = difficulty_settings.stagger_damage_multiplier_ranged -- Added a ranged mutliplier

		if stagger_damage_multiplier then
			local bonus_damage_percentage = 0
			if damage_profile.no_stagger_damage_reduction_ranged and mod:get("stagger_ranged") then -- Implemented ranged multiplier
				bonus_damage_percentage = stagger_number * stagger_damage_multiplier_ranged
			else
				bonus_damage_percentage = stagger_number * stagger_damage_multiplier
			end
			local target_buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")

			if target_buff_extension then
				bonus_damage_percentage = target_buff_extension:apply_buffs_to_value(bonus_damage_percentage, "unbalanced_damage_taken")
			end

			local stagger_damage = calculated_damage * (min_stagger_damage_coefficient + bonus_damage_percentage)
			calculated_damage = stagger_damage
		end
	else -- if no stagger bonus is added, then use original fucntion (need to figure out as better way... Possibly use a function for this Fatshark?)
		return func(damage_output, target_unit, attacker_unit, hit_zone_name, original_power_level, boost_curve, boost_damage_multiplier, is_critical_strike, damage_profile, target_index, backstab_multiplier, damage_source)
	end

	local weave_manager = Managers.weave

	if target_is_hero and static_base_damage and weave_manager:get_active_weave() then
		local scaling_value = weave_manager:get_scaling_value("enemy_damage")
		calculated_damage = calculated_damage * (1 + scaling_value)
	end

	return calculated_damage
end)

-- Settings Implementation

-- Breed Tweaks Things
local health_step_multipliers = {
	1,
	1,
	1.5,
	2.2,
	3.3,
	4.5,
	6,
	7.5
}
local stagger_step_multipliers = {
	1,
	0.85,
	1.4,
	2.25,
	2.25,
	2.25,
	3.5,
	3.5
}
local elite_stagger_step_multipliers = {
	1,
	1,
	1.7,
	2.75,
	2.75,
	2.75,
	3.5,
	3.5
}
local mass_step_multipliers = {
	1,
	1,
	1.7,
	2.5,
	2.5,
	2.5,
	3.25,
	4.5
}
local elite_health_step_multipliers = {
	1,
	1,
	1.5,
	2.2,
	3.3,
	5.4,
	6.4,
	7.4
}
local elite_stagger_step_multipliers = {
	1,
	1,
	1.7,
	2.75,
	2.75,
	2.75,
	3.5,
	4
}
local elite_mass_step_multipliers = {
	1,
	1,
	1.7,
	2.5,
	2.5,
	2.5,
	3.25,
	4.5
}
local horde_health_step_multipliers = {
	1,
	1,
	1.5,
	2.2,
	3.3,
	4.2,
	5.1,
	6
}
local horde_stagger_step_multipliers = {
	1,
	1,
	1.5,
	2.25,
	2.25,
	2.25,
	3,
	3
}
local horde_mass_step_multipliers = {
	1,
	1,
	1.5,
	2,
	2,
	2,
	2.75,
	3
}
local boss_health_step_multipliers = {
	1,
	1,
	1.5,
	2,
	3,
	5,
	6.5,
	8
}

local function networkify_health(health_amount)
	health_amount = math.clamp(health_amount, 0, 8191.5)
	local decimal = health_amount % 1
	local rounded_decimal = math.round(decimal * 4) * 0.25

	return math.floor(health_amount) + rounded_decimal
end

local function health_steps(value, step_multipliers)
	local value_steps = {}

	for i = 1, 8, 1 do
		local step_value = value * step_multipliers[i]
		local networkifyed_health = networkify_health(step_value)
		value_steps[i] = networkifyed_health
	end

	return value_steps
end

local function steps(value, step_multipliers)
	local value_steps = {}

	for i = 1, 8, 1 do
		local raw_value = value * step_multipliers[i]
		local decimal = raw_value % 1
		local rounded_decimal = math.round(decimal * 4) * 0.25
		value_steps[i] = math.floor(raw_value) + rounded_decimal
	end

	return value_steps
end

local widget_settings = {
	["diff_stagger_resist.slave_rat"] = function()
		BreedTweaks.diff_stagger_resist.slave_rat = steps(1 * (mod:get("diff_stagger_resist.slave_rat") or 1), stagger_step_multipliers)
	end,
	["diff_stagger_resist.fanatic"] = function()
		BreedTweaks.diff_stagger_resist.fanatic = steps(1.4 * (mod:get("diff_stagger_resist.fanatic") or 1), stagger_step_multipliers)
	end,
	["diff_stagger_resist.ungor"] = function()
		BreedTweaks.diff_stagger_resist.ungor = steps(1.3 * (mod:get("diff_stagger_resist.ungor") or 1), stagger_step_multipliers)
	end,
	["diff_stagger_resist.clan_rat"] = function()
		BreedTweaks.diff_stagger_resist.clan_rat = steps(2.1 * (mod:get("diff_stagger_resist.clan_rat") or 1), stagger_step_multipliers)
	end,
	["diff_stagger_resist.gor"] = function()
		BreedTweaks.diff_stagger_resist.gor = steps(2.4 * (mod:get("diff_stagger_resist.gor") or 1), stagger_step_multipliers)
	end,
	["diff_stagger_resist.marauder"] = function()
		BreedTweaks.diff_stagger_resist.marauder = steps(2.65 * (mod:get("diff_stagger_resist.marauder") or 1), stagger_step_multipliers)
	end,
	["diff_stagger_resist.stormvermin"] = function()
		BreedTweaks.diff_stagger_resist.stormvermin = steps(2.25 * (mod:get("diff_stagger_resist.stormvermin") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.bestigor"] = function()
		BreedTweaks.diff_stagger_resist.bestigor = steps(3.25 * (mod:get("diff_stagger_resist.bestigor") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.raider"] = function()
		BreedTweaks.diff_stagger_resist.raider = steps(3 * (mod:get("diff_stagger_resist.raider") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.warrior"] = function()
		BreedTweaks.diff_stagger_resist.warrior = steps(4.8 * (mod:get("diff_stagger_resist.warrior") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.berzerker"] = function()
		BreedTweaks.diff_stagger_resist.berzerker = steps(2.7 * (mod:get("diff_stagger_resist.berzerker") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.plague_monk"] = function()
		BreedTweaks.diff_stagger_resist.plague_monk = steps(3 * (mod:get("diff_stagger_resist.plague_monk") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.packmaster"] = function()
		BreedTweaks.diff_stagger_resist.packmaster = steps(4 * (mod:get("diff_stagger_resist.packmaster") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.ratling_gunner"] = function()
		BreedTweaks.diff_stagger_resist.ratling_gunner = steps(2.5 * (mod:get("diff_stagger_resist.ratling_gunner") or 1), elite_stagger_step_multipliers)
	end,
	["diff_stagger_resist.sorcerer"] = function()
		BreedTweaks.diff_stagger_resist.sorcerer = steps(2.7 * (mod:get("diff_stagger_resist.sorcerer") or 1), elite_stagger_step_multipliers)
	end,
	["normal.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.normal.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 20) /100
	end,
	["hard.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.hard.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 20) /100
	end,
	["harder.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.harder.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 20) /100
	end,
	["hardest.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.hardest.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 20) /100
	end,
	["cataclysm.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.cataclysm.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 20) /100
	end,
	["cataclysm_2.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.cataclysm_2.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 30) /100
	end,
	["cataclysm_3.stagger_damage_multiplier_ranged"] = function ()
		DifficultySettings.cataclysm_3.stagger_damage_multiplier_ranged = (mod:get("normal.stagger_damage_multiplier_ranged") or 50) /100
	end,
	["normal.stagger_damage_multiplier"] = function ()
		DifficultySettings.normal.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 20) /100
	end,
	["hard.stagger_damage_multiplier"] = function ()
		DifficultySettings.hard.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 20) /100
	end,
	["harder.stagger_damage_multiplier"] = function ()
		DifficultySettings.harder.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 20) /100
	end,
	["hardest.stagger_damage_multiplier"] = function ()
		DifficultySettings.hardest.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 20) /100
	end,
	["cataclysm.stagger_damage_multiplier"] = function ()
		DifficultySettings.cataclysm.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 20) /100
	end,
	["cataclysm_2.stagger_damage_multiplier"] = function ()
		DifficultySettings.cataclysm_2.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 30) /100
	end,
	["cataclysm_3.stagger_damage_multiplier"] = function ()
		DifficultySettings.cataclysm_3.stagger_damage_multiplier = (mod:get("normal.stagger_damage_multiplier") or 50) /100
	end,
}

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