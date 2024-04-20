local mod = get_mod("catas")

-- Fix Throw Poision Globe
BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[8] = 10

-- Display cata display images for cata 2 & 3
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

mod:hook(LevelUnlockUtils, "completed_journey_difficulty_index", function (func, statistics_db, player_stats_id, journey_name)
	local difficulty_index = func(statistics_db, player_stats_id, journey_name)
	if difficulty_index > 5 then -- Cata 2 & 3 are rank 7 & 8 respectivley. This makes sure it return the Legend rank
		return 5
	else
		return difficulty_index
	end
end)

-- Modify Save Data to avoid crash in official
mod:hook(PopupManager, "query_result", function (func, self, popup_id)
	local result, params = func(self, popup_id)
	if result == "end_game" then
		Managers.save:auto_save(SaveFileName, SaveData, nil, nil, true)
	end

	return result, params
end)
mod:hook(SaveManager, "auto_save", function (func, self, file_name, data, callback, force_local_save, exit_game)
	if exit_game then
		local id = (rawget(_G, "Steam") and Steam.user_id()) or "local_save"
		local _player_data = data.player_data
		local _player_id = _player_data[id]
		local _mission_selection = _player_id.mission_selection
		if _mission_selection.custom ~= nil then
			if _mission_selection.custom.difficulty_key == "cataclysm_2" or  _mission_selection.custom.difficulty_key == "cataclysm_3" then
				_mission_selection.custom.difficulty_key = "cataclysm"
				mod:info("Changed custom mission selection difficulty key to cataclysm")
			end
		end
		if _mission_selection.deus_custom ~= nil then
			if _mission_selection.deus_custom.difficulty_key == "cataclysm_2" or  _mission_selection.deus_custom.difficulty_key == "cataclysm_3" then
				_mission_selection.deus_custom.difficulty_key = "cataclysm"
				mod:info("Changed deus_custom mission selection difficulty key to cataclysm")
			end
		end
		if _mission_selection.twitch ~= nil then
			if _mission_selection.twitch.difficulty_key == "cataclysm_2" or  _mission_selection.twitch.difficulty_key == "cataclysm_3" then
				_mission_selection.twitch.difficulty_key = "cataclysm"
				mod:info("Changed twitch mission selection difficulty key to cataclysm")
			end
		end
		if _mission_selection.adventure ~= nil then
			if _mission_selection.adventure.difficulty_key == "cataclysm_2" or  _mission_selection.adventure.difficulty_key == "cataclysm_3" then
				_mission_selection.adventure.difficulty_key = "cataclysm"
				mod:info("Changed adventure mission selection difficulty key to cataclysm")
			end
		end
		if _mission_selection.event ~= nil then
			if _mission_selection.event.difficulty_key == "cataclysm_2" or  _mission_selection.event.difficulty_key == "cataclysm_3" then
				_mission_selection.event.difficulty_key = "cataclysm"
				mod:info("Changed event mission selection difficulty key to cataclysm")
			end
		end
		
	end

	return func(self, file_name, data, callback, force_local_save)
end)

-- Custom stagger options for Chaos Bulwark
mod.custom_stagger_types = {
	explosion = 6,
	heavy = 3,
	medium = 2,
	none = 0,
	pulling = 9,
	ranged_medium = 5,
	ranged_weak = 4,
	shield_block_stagger = 10,
	shield_open_stagger = 11,
	weak = 1,
	weakspot = 8,
}

Breeds.chaos_bulwark.before_stagger_enter_function = function (unit, blackboard, attacker_unit, is_push, stagger_value_to_add, predicted_damage)
	local ai_shield_extension = ScriptUnit.extension(unit, "ai_shield_system")
	local t = Managers.time:time("game")
	local breed = blackboard.breed
	local stagger_modifier = breed.stagger_modifiers[blackboard.latest_hit_charge_value] or breed.stagger_modifiers.default

	blackboard.stagger_level = blackboard.stagger_level or mod.custom_stagger_types.none

	local difficulty_manager = Managers.state.difficulty
	local difficulty_rank = difficulty_manager:get_difficulty_rank()
	local difficulty_tweaks = breed.stagger_difficulty_tweak_index[difficulty_rank]
	local shield_open_stagger_threshold = difficulty_tweaks.shield_open_stagger_threshold
	local shield_block_threshold = difficulty_tweaks.shield_block_threshold
	local stagger_regen_rate = difficulty_tweaks.stagger_regen_rate
	local weakspot_stagger

	if blackboard.weakspot_hit and not blackboard.weakspot_exploded and not ai_shield_extension.is_blocking then
		weakspot_stagger = true
		blackboard.weakspot_exploded = true
	end

	predicted_damage = predicted_damage or 0.1

	local normalizing_value = {
		0,
		10,
	}
	local normalized_predicted_damage = (predicted_damage - normalizing_value[1]) / (normalizing_value[2] - normalizing_value[1])
	local final_stagger_to_add = (stagger_value_to_add + normalized_predicted_damage) * stagger_modifier
	local regen_rate = math.lerp(stagger_regen_rate[1], stagger_regen_rate[2], (blackboard.cached_stagger or 0.1) / shield_open_stagger_threshold)
	local regen = math.clamp(t - (blackboard.shield_regen_time_stamp or t), 0, math.huge) * regen_rate

	blackboard.stagger = math.clamp((blackboard.cached_stagger or 0) - regen, 0, math.huge) + final_stagger_to_add
	blackboard.shield_regen_time_stamp = t

	local shield_block_stagger_activated = shield_block_threshold <= final_stagger_to_add
	local shield_open_stagger_reached = shield_open_stagger_threshold <= blackboard.stagger

	blackboard.override_stagger = blackboard.max_stagger_reached and not weakspot_stagger

	if blackboard.stagger_level == mod.custom_stagger_types.shield_open_stagger or weakspot_stagger then
		blackboard.stagger_level = mod.custom_stagger_types.heavy
	elseif shield_open_stagger_reached then
		blackboard.stagger_level = mod.custom_stagger_types.shield_open_stagger
	elseif shield_block_stagger_activated then
		blackboard.stagger_level = mod.custom_stagger_types.shield_block_stagger
	else
		blackboard.override_stagger = true
	end

	if blackboard.override_stagger then
		blackboard.staggering_id = blackboard.stagger
	else
		blackboard.stagger_activated = true
	end

	blackboard.cached_stagger = blackboard.stagger

	if not blackboard.max_stagger_reached and blackboard.stagger_level ~= mod.custom_stagger_types.heavy then
		ai_shield_extension:play_shield_hit_sfx(blackboard.stagger_level == mod.custom_stagger_types.shield_open_stagger, blackboard.cached_stagger, shield_open_stagger_threshold)
	end
end

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

-- Chaos Wastes

-- Stupidness
local function readonlytable(table)
	return setmetatable(table, {})
end

readonlytable(DeusStarterWeaponPowerLevels)
readonlytable(DeusDropPowerlevelRanges)

GameModeSettings.deus.difficulties = DefaultDifficulties
DeusStarterWeaponPowerLevels.cataclysm_2 = DeusStarterWeaponPowerLevels.cataclysm
DeusStarterWeaponPowerLevels.cataclysm_3 = DeusStarterWeaponPowerLevels.cataclysm
DeusDropPowerlevelRanges.cataclysm_2 = DeusDropPowerlevelRanges.cataclysm
DeusDropPowerlevelRanges.cataclysm_3 = DeusDropPowerlevelRanges.cataclysm

local mutator = require("scripts/settings/mutators/mutator_curse_corrupted_flesh")
local difficulty_data = {
	normal = {
		mark_chance = 0.3,
		max_marked_enemies = 2
	},
	hard = {
		mark_chance = 0.3,
		max_marked_enemies = 3
	},
	harder = {
		mark_chance = 0.3,
		max_marked_enemies = 3
	},
	hardest = {
		mark_chance = 0.3,
		max_marked_enemies = 3
	},
	cataclysm = {
		mark_chance = 0.3,
		max_marked_enemies = 3
	},
}
mutator.server_start_function = function (context, data)
	local difficulty = Managers.state.difficulty:get_difficulty()
	if difficulty == "cataclysm_2" or difficulty == "cataclysm_3" then
		difficulty = "cataclysm"
	end
	data.max_marked_enemies = difficulty_data[difficulty].max_marked_enemies
	data.mark_chance = difficulty_data[difficulty].mark_chance
	data.enemies_to_be_marked = {}
	data.marked_enemies = {}
	data.seed = Managers.mechanism:get_level_seed("mutator")
end
local mutator = require("scripts/settings/mutators/mutator_curse_greed_pinata")
local difficulty_data = {
	normal = {
		mark_chance = 1,
		max_marked_enemies = 2
	},
	hard = {
		mark_chance = 1,
		max_marked_enemies = 2
	},
	harder = {
		mark_chance = 1,
		max_marked_enemies = 2
	},
	hardest = {
		mark_chance = 1,
		max_marked_enemies = 2
	},
	cataclysm = {
		mark_chance = 1,
		max_marked_enemies = 2
	}
}
mutator.server_start_function = function (context, data)
	local difficulty = Managers.state.difficulty:get_difficulty()
	if difficulty == "cataclysm_2" or difficulty == "cataclysm_3" then
		difficulty = "cataclysm"
	end
	data.max_marked_enemies = difficulty_data[difficulty].max_marked_enemies
	data.mark_chance = difficulty_data[difficulty].mark_chance
	data.enemies_to_be_marked = {}
	data.marked_enemies = {}
	data.seed = Managers.mechanism:get_level_seed("mutator")
end
local mutator = require("scripts/settings/mutators/mutator_curse_khorne_champions")
local difficulty_data = {
	normal = {
		mark_chance = 1,
		max_marked_enemies = 2
	},
	hard = {
		mark_chance = 1,
		max_marked_enemies = 3
	},
	harder = {
		mark_chance = 1,
		max_marked_enemies = 4
	},
	hardest = {
		mark_chance = 1,
		max_marked_enemies = 5
	},
	cataclysm = {
		mark_chance = 1,
		max_marked_enemies = 6
	}
}
mutator.server_start_function = function (context, data)
	local difficulty = Managers.state.difficulty:get_difficulty()
	if difficulty == "cataclysm_2" or difficulty == "cataclysm_3" then
		difficulty = "cataclysm"
	end
	data.max_marked_enemies = difficulty_data[difficulty].max_marked_enemies
	data.mark_chance = difficulty_data[difficulty].mark_chance
	data.enemies_to_be_marked = {}
	data.marked_enemies = {}
	data.seed = Managers.mechanism:get_level_seed("mutator")
end

local base_skulking_sorcerer = require("scripts/settings/mutators/mutator_skulking_sorcerer")
local curse_skulking_sorcerer = require("scripts/settings/mutators/mutator_curse_skulking_sorcerer")
local NORMAL = 2
local HARD = 3
local HARDER = 4
local HARDEST = 5
local CATACLYSM = 6
local CATACLYSM_2 = 6
local CATACLYSM_3 = 7
local VERSUS_BASE = 8
local RESPAWN_TIME = {
	[NORMAL] = 30,
	[HARD] = 30,
	[HARDER] = 30,
	[HARDEST] = 30,
	[CATACLYSM] = 30,
	[VERSUS_BASE] = 30
}
local MAX_HEALTH = {
	[NORMAL] = 20,
	[HARD] = 30,
	[HARDER] = 44,
	[HARDEST] = 66,
	[CATACLYSM] = 90,
	[CATACLYSM_2] = 120,
	[CATACLYSM_3] = 150,
	[VERSUS_BASE] = 150,
}
curse_skulking_sorcerer.server_initialize_function = function (context, data)
	MutatorUtils.store_breed_and_action_settings(context, data)

	Breeds.curse_mutator_sorcerer.max_health = MAX_HEALTH
end

curse_skulking_sorcerer.server_start_function = function (context, data)
	base_skulking_sorcerer.server_start_function(context, data)

	local difficulty_rank = Managers.state.difficulty:get_difficulty_rank()
	local respawn_time = RESPAWN_TIME[difficulty_rank] or RESPAWN_TIME[NORMAL]
	data.respawn_times = {
		respawn_time,
		respawn_time + 1
	}
	data.breed_name = "curse_mutator_sorcerer"
end

-- FOW Cata 2/3
mod.plaza_c2 = function()
	mod:pcall(function()
		local vote_data = {
			private_game = true,
			mission_id = "plaza",
			strict_matchmaking = false,
			always_host = true,
			matchmaking_type = "event",
			mechanism = "adventure",
			quick_game = false,
			difficulty = "cataclysm_2",
			event_data = {}
		}
		
		local local_player_unit = Managers.player:local_player().player_unit
		local interaction_player = Managers.player:owner(local_player_unit)

		Managers.state.voting:request_vote("game_settings_vote", vote_data, interaction_player.peer_id)
	end)
end

mod:command("FOW2", mod:localize("FOW2_level_command_description"), function() mod.plaza_c2() end)

mod.plaza_c3 = function()
	mod:pcall(function()
		local vote_data = {
			private_game = true,
			mission_id = "plaza",
			strict_matchmaking = false,
			always_host = true,
			matchmaking_type = "event",
			mechanism = "adventure",
			quick_game = false,
			difficulty = "cataclysm_3",
			event_data = {}
		}
		
		local local_player_unit = Managers.player:local_player().player_unit
		local interaction_player = Managers.player:owner(local_player_unit)

		Managers.state.voting:request_vote("game_settings_vote", vote_data, interaction_player.peer_id)
	end)
end

mod:command("FOW3", mod:localize("FOW3_level_command_description"), function() mod.plaza_c3() end)

-- Cata 1 patrols for Cata 2/3
PatrolFormationSettings.chaos_warrior_default.cataclysm_2 = PatrolFormationSettings.chaos_warrior_default.cataclysm
PatrolFormationSettings.storm_vermin_two_column.cataclysm_2 = PatrolFormationSettings.storm_vermin_two_column.cataclysm
PatrolFormationSettings.storm_vermin_shields_infront.cataclysm_2 = PatrolFormationSettings.storm_vermin_shields_infront.cataclysm
PatrolFormationSettings.small_stormvermins.cataclysm_2 = PatrolFormationSettings.small_stormvermins.cataclysm
PatrolFormationSettings.small_stormvermins_long.cataclysm_2 = PatrolFormationSettings.small_stormvermins_long.cataclysm
PatrolFormationSettings.medium_stormvermins.cataclysm_2 = PatrolFormationSettings.medium_stormvermins.cataclysm
PatrolFormationSettings.medium_stormvermins_wide.cataclysm_2 = PatrolFormationSettings.medium_stormvermins_wide.cataclysm
PatrolFormationSettings.chaos_warrior_small.cataclysm_2 = PatrolFormationSettings.chaos_warrior_small.cataclysm
PatrolFormationSettings.chaos_warrior_long.cataclysm_2 = PatrolFormationSettings.chaos_warrior_long.cataclysm
PatrolFormationSettings.chaos_warrior_wide.cataclysm_2 = PatrolFormationSettings.chaos_warrior_wide.cataclysm
PatrolFormationSettings.beastmen_standard.cataclysm_2 = PatrolFormationSettings.beastmen_standard.cataclysm
PatrolFormationSettings.beastmen_archers.cataclysm_2 = PatrolFormationSettings.beastmen_archers.cataclysm

PatrolFormationSettings.chaos_warrior_default.cataclysm_3 = PatrolFormationSettings.chaos_warrior_default.cataclysm
PatrolFormationSettings.storm_vermin_two_column.cataclysm_3 = PatrolFormationSettings.storm_vermin_two_column.cataclysm
PatrolFormationSettings.storm_vermin_shields_infront.cataclysm_3 = PatrolFormationSettings.storm_vermin_shields_infront.cataclysm
PatrolFormationSettings.small_stormvermins.cataclysm_3 = PatrolFormationSettings.small_stormvermins.cataclysm
PatrolFormationSettings.small_stormvermins_long.cataclysm_3 = PatrolFormationSettings.small_stormvermins_long.cataclysm
PatrolFormationSettings.medium_stormvermins.cataclysm_3 = PatrolFormationSettings.medium_stormvermins.cataclysm
PatrolFormationSettings.medium_stormvermins_wide.cataclysm_3 = PatrolFormationSettings.medium_stormvermins_wide.cataclysm
PatrolFormationSettings.chaos_warrior_small.cataclysm_3 = PatrolFormationSettings.chaos_warrior_small.cataclysm
PatrolFormationSettings.chaos_warrior_long.cataclysm_3 = PatrolFormationSettings.chaos_warrior_long.cataclysm
PatrolFormationSettings.chaos_warrior_wide.cataclysm_2 = PatrolFormationSettings.chaos_warrior_wide.cataclysm
PatrolFormationSettings.beastmen_standard.cataclysm_3 = PatrolFormationSettings.beastmen_standard.cataclysm
PatrolFormationSettings.beastmen_archers.cataclysm_3 = PatrolFormationSettings.beastmen_archers.cataclysm

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
local mutator = mod:persistent_table("catas")
local difficulty_start = 5 - 1 --Just change Legend and up values
local difficulties = 8 - difficulty_start --How many times to do

if mutator.data_saved then
	if not mutator.reset1 then
		mutator.data_saved = false
		mutator.reset1 = true
	end
end

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
	--Below is the values for each taken by what the VT2 Endgame Community thinks works best.
	--Skaven
	for i=1, difficulties do
		local i = i + difficulty_start
		Breeds.skaven_slave.diff_stagger_resist[i] = 15
		Breeds.skaven_clan_rat.diff_stagger_resist[i] = 18.5
		Breeds.skaven_clan_rat_with_shield.diff_stagger_resist[i] = 18.5
		Breeds.skaven_storm_vermin.diff_stagger_resist[i] = 35
		Breeds.skaven_storm_vermin_with_shield.diff_stagger_resist[i] = 35
		Breeds.skaven_storm_vermin_commander.diff_stagger_resist[i] = 35
		Breeds.skaven_plague_monk.diff_stagger_resist[i] = 35
		Breeds.skaven_pack_master.diff_stagger_resist[i] = 27
		Breeds.skaven_ratling_gunner.diff_stagger_resist[i] = 27
		Breeds.skaven_warpfire_thrower.diff_stagger_resist[i] = 27
		Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[i] = 50
	end
	--Chaos
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_fanatic.diff_stagger_resist[i] = 20
		Breeds.chaos_marauder.diff_stagger_resist[i] = 28
		Breeds.chaos_marauder_with_shield.diff_stagger_resist[i] = 28
		Breeds.chaos_raider.diff_stagger_resist[i] = 33
		Breeds.chaos_berzerker.diff_stagger_resist[i] = 35
		Breeds.chaos_warrior.diff_stagger_resist[i] = 45
		--Breeds.chaos_bulwark.diff_stagger_resist[i] = 45
		Breeds.chaos_bulwark.diff_stagger_resist[i] = mod:get("diff_stagger_resist.chaos_bulwark")
		Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[i] = 30
		Breeds.chaos_mutator_sorcerer.diff_stagger_resist[i] = 30
		Breeds.curse_mutator_sorcerer.diff_stagger_resist[i] = 30
		Breeds.chaos_plague_sorcerer.diff_stagger_resist[i] = 30
		Breeds.chaos_vortex_sorcerer.diff_stagger_resist[i] = 30
	end
	-- Beastmen
	for i=1, difficulties do
		local i = i + difficulty_start
		Breeds.beastmen_ungor.diff_stagger_resist[i] = 12
		Breeds.beastmen_ungor_archer.diff_stagger_resist[i] = 12
		Breeds.beastmen_gor.diff_stagger_resist[i] = 19.5
		Breeds.beastmen_bestigor.diff_stagger_resist[i] = 40
		Breeds.beastmen_standard_bearer.diff_stagger_resist[i] = 25
	end

	--Reduced stagger_damage_multiplier
	DifficultySettings.cataclysm_2.stagger_damage_multiplier = 0.2
	DifficultySettings.cataclysm_3.stagger_damage_multiplier = 0.2

	--Globadier increased values
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[i] = 15
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage[i] = 22.5
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_init_damage[i] = 60
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_dot_damage[i] = 15
	end
	mutator.active = true
end

mutator.stop = function()
	--Skaven
	for i=1, difficulties do
		local i = i + difficulty_start
		Breeds.skaven_slave.diff_stagger_resist[i] = mutator.Breeds.skaven_slave.diff_stagger_resist[i]
		Breeds.skaven_clan_rat.diff_stagger_resist[i] = mutator.Breeds.skaven_clan_rat.diff_stagger_resist[i]
		Breeds.skaven_clan_rat_with_shield.diff_stagger_resist[i] = mutator.Breeds.skaven_clan_rat_with_shield.diff_stagger_resist[i]
		Breeds.skaven_storm_vermin.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin.diff_stagger_resist[i]
		Breeds.skaven_storm_vermin_with_shield.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin_with_shield.diff_stagger_resist[i]
		Breeds.skaven_storm_vermin_commander.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin_commander.diff_stagger_resist[i]
		Breeds.skaven_plague_monk.diff_stagger_resist[i] = mutator.Breeds.skaven_plague_monk.diff_stagger_resist[i]
		Breeds.skaven_pack_master.diff_stagger_resist[i] = mutator.Breeds.skaven_pack_master.diff_stagger_resist[i]
		Breeds.skaven_pack_master.diff_stagger_resist[i] = mutator.Breeds.skaven_pack_master.diff_stagger_resist[i]
		Breeds.skaven_ratling_gunner.diff_stagger_resist[i] = mutator.Breeds.skaven_ratling_gunner.diff_stagger_resist[i]
		Breeds.skaven_warpfire_thrower.diff_stagger_resist[i] = mutator.Breeds.skaven_warpfire_thrower.diff_stagger_resist[i]
		Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[i] = mutator.Breeds.skaven_storm_vermin_warlord.diff_stagger_resist[i]
	end
	--Chaos
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.chaos_fanatic.diff_stagger_resist[i] = mutator.Breeds.chaos_fanatic.diff_stagger_resist[i]
		Breeds.chaos_marauder.diff_stagger_resist[i] = mutator.Breeds.chaos_marauder.diff_stagger_resist[i]
		Breeds.chaos_marauder_with_shield.diff_stagger_resist[i] = mutator.Breeds.chaos_marauder_with_shield.diff_stagger_resist[i]
		Breeds.chaos_raider.diff_stagger_resist[i] = mutator.Breeds.chaos_raider.diff_stagger_resist[i]
		Breeds.chaos_berzerker.diff_stagger_resist[i] = mutator.Breeds.chaos_berzerker.diff_stagger_resist[i]
		Breeds.chaos_warrior.diff_stagger_resist[i] = mutator.Breeds.chaos_warrior.diff_stagger_resist[i]
		Breeds.chaos_bulwark.diff_stagger_resist[i] = mutator.Breeds.chaos_bulwark.diff_stagger_resist[i]
		Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_corruptor_sorcerer.diff_stagger_resist[i]
		Breeds.chaos_mutator_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_mutator_sorcerer.diff_stagger_resist[i]
		Breeds.curse_mutator_sorcerer.diff_stagger_resist[i] = mutator.Breeds.curse_mutator_sorcerer.diff_stagger_resist[i]
		Breeds.chaos_plague_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_plague_sorcerer.diff_stagger_resist[i]
		Breeds.chaos_vortex_sorcerer.diff_stagger_resist[i] = mutator.Breeds.chaos_vortex_sorcerer.diff_stagger_resist[i]
	end
	--Beastmen
	for i=1, difficulties do 
		local i = i + difficulty_start
		Breeds.beastmen_ungor.diff_stagger_resist[i] = mutator.Breeds.beastmen_ungor.diff_stagger_resist[i]
		Breeds.beastmen_ungor_archer.diff_stagger_resist[i] = mutator.Breeds.beastmen_ungor_archer.diff_stagger_resist[i]
		Breeds.beastmen_gor.diff_stagger_resist[i] = mutator.Breeds.beastmen_gor.diff_stagger_resist[i]
		Breeds.beastmen_bestigor.diff_stagger_resist[i] = mutator.Breeds.beastmen_bestigor.diff_stagger_resist[i]
		Breeds.beastmen_standard_bearer.diff_stagger_resist[i] = mutator.Breeds.beastmen_standard_bearer.diff_stagger_resist[i]
	end
	-- Stagger_damage_multiplier
	DifficultySettings.cataclysm_2.stagger_damage_multiplier = mutator.DifficultySettings.cataclysm_2.stagger_damage_multiplier
	DifficultySettings.cataclysm_3.stagger_damage_multiplier = mutator.DifficultySettings.cataclysm_3.stagger_damage_multiplier

	--Globadier values
	for i=1, difficulties do 
		local i = i + difficulty_start
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_dot_damage[i]
		BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.throw_poison_globe.aoe_init_damage[i]
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_dot_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_dot_damage[i]
		BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_init_damage[i] = mutator.BreedActions.skaven_poison_wind_globadier.suicide_run.aoe_init_damage[i]
	end

	if Breeds.skaven_slave.diff_stagger_resist[5] ~= 2.25 then
		mod:chat_broadcast("Original Values not saved properly. Please Restart Game.\nIf this is repeated issue, please get in contact with RwAoNrDdOsM.")
	end
	mutator.active = false
end

mod:network_register("rpc_activate_catas", function(sender, enable)
    if enable ~= mutator.active then    
        if enable then
            -- if enable == true then: enable loader
            mutator.start()
            mod:echo("Deathwish ENABLED")
        else
            -- if enable == false then: disable loader
            mutator.stop()
            mod:echo("Deathwish DISABLED")
        end
    end
end)

mutator.toggle = function()
	if Managers.matchmaking:_matchmaking_status() ~= "idle" then
        mod:echo("You must cancel matchmaking before toggling this.")
        return
    end
	if Managers.player.is_server and Managers.state.game_mode._game_mode_key == "inn_deus" then
        mod:network_send("rpc_activate_catas", "all", not mutator.active)
    elseif Managers.player.is_server and Managers.state.game_mode._game_mode_key == "inn" then
        if not mutator.active then
            mutator.start()
            mod:chat_broadcast("Deathwish ENABLED.")
        else
            mutator.stop()
            mod:chat_broadcast("Deathwish DISABLED.")
        end
    else
        mod:echo("You must be the host and in Taal's Horn Keep or the Pilgrimage Chamber to do that")
    end
end

mutator.toggle_nomatch = function()
	if Managers.player.is_server and Managers.state.game_mode._game_mode_key == "inn_deus" then
        mod:network_send("rpc_activate_catas", "all", not mutator.active)
    elseif Managers.player.is_server and Managers.state.game_mode._game_mode_key == "inn" then
        if not mutator.active then
            mutator.start()
            mod:chat_broadcast("Deathwish ENABLED.")
        else
            mutator.stop()
            mod:chat_broadcast("Deathwish DISABLED.")
        end
    else
        mod:echo("You must be the host and in Taal's Horn Keep or the Pilgrimage Chamber to do that")
    end
end

mod.on_user_joined = function(player)
    if mutator.active and ((Managers.state.game_mode._game_mode_key == "inn_deus") or (Managers.state.game_mode._game_mode_key == "deus") or (Managers.state.game_mode._game_mode_key == "map_deus")) then
        mod:network_send("rpc_activate_catas", player.peer_id, mutator.active)
    end
end

mod:command("deathwish", "Toggle Deathwish. Must be host and in the Taal's Horn Keep or Pilgrimage Chamber.", function() mutator.toggle() end)

--Easy way to change stuff when settings change
--Table that contains functions, strings or tables to do things when options are changed
local widget_settings = {
	["diff_stagger_resist.chaos_bulwark"] = function()
		for i=1, difficulties do 
			local i = i + difficulty_start
			Breeds.chaos_bulwark.diff_stagger_resist[i] = mod:get("diff_stagger_resist.chaos_bulwark")
		end
	end,--]]
	shield_block_threshold = function()
		for i=1, difficulties do 
			local i = i + difficulty_start
			Breeds.chaos_bulwark.stagger_difficulty_tweak_index[i].shield_block_threshold = mod:get("shield_block_threshold")
		end
	end,--]]
	shield_open_stagger_threshold = function()
		for i=1, difficulties do 
			local i = i + difficulty_start
			Breeds.chaos_bulwark.stagger_difficulty_tweak_index[i].shield_open_stagger_threshold = mod:get("shield_open_stagger_threshold")
		end
	end,--]]
	stagger_regen_rate_1 = function()
		for i=1, difficulties do 
			local i = i + difficulty_start
			Breeds.chaos_bulwark.stagger_difficulty_tweak_index[i].stagger_regen_rate = {
				mod:get("stagger_regen_rate_1"),
				mod:get("stagger_regen_rate_2")
			}
		end
	end,--]]
	stagger_regen_rate_2 = function()
		for i=1, difficulties do 
			local i = i + difficulty_start
			Breeds.chaos_bulwark.stagger_difficulty_tweak_index[i].stagger_regen_rate = {
				mod:get("stagger_regen_rate_1"),
				mod:get("stagger_regen_rate_2")
			}
		end
	end,--]]
	heavy = function()
		mod.custom_stagger_types.heavy = mod:get("heavy")
	end,--]]
	shield_block_stagger = function()
		mod.custom_stagger_types.shield_block_stagger = mod:get("shield_block_stagger")
	end,--]]
	shield_open_stagger = function()
		mod.custom_stagger_types.shield_open_stagger = mod:get("shield_open_stagger")
	end,--]]
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
local widget_setting = widget_settings["diff_stagger_resist.chaos_bulwark"]
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.shield_block_threshold
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.shield_open_stagger_threshold
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.stagger_regen_rate_1
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.stagger_regen_rate_2
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.heavy
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.shield_block_stagger
type_widget_setting(widget_setting, setting_id)
local widget_setting = widget_settings.shield_open_stagger
type_widget_setting(widget_setting, setting_id)