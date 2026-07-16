extends GutTest

func test_base_autoloads_are_registered() -> void:
	assert_not_null(get_node_or_null("/root/DebugLog"), "DebugLog autoload should be registered.")
	assert_not_null(get_node_or_null("/root/DevMode"), "DevMode autoload should be registered.")
	assert_not_null(get_node_or_null("/root/AudioSettings"), "AudioSettings autoload should be registered.")
	assert_not_null(get_node_or_null("/root/GraphicsSettings"), "GraphicsSettings autoload should be registered.")
	assert_not_null(get_node_or_null("/root/Analytics"), "Analytics autoload should be registered.")


func test_graphics_quality_values_are_validated() -> void:
	assert_true(GraphicsQualityTiers.is_valid_quality(&"low"))
	assert_true(GraphicsQualityTiers.is_valid_quality(&"balanced"))
	assert_true(GraphicsQualityTiers.is_valid_quality(&"high"))
	assert_false(GraphicsQualityTiers.is_valid_quality(&"ultra"))


func test_audio_settings_exposes_player_facing_volume_controls() -> void:
	assert_true(is_equal_approx(clampf(AudioSettings.get_master_volume(), 0.0, 1.0), AudioSettings.get_master_volume()))
	assert_true(is_equal_approx(clampf(AudioSettings.get_music_volume(), 0.0, 1.0), AudioSettings.get_music_volume()))
	assert_true(is_equal_approx(clampf(AudioSettings.get_effects_volume(), 0.0, 1.0), AudioSettings.get_effects_volume()))


func test_audio_bus_layout_routes_sound_categories_through_their_player_controls() -> void:
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"Music")), &"Master")
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"Effects")), &"Master")
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"UI")), &"Effects")
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"World")), &"Effects")
