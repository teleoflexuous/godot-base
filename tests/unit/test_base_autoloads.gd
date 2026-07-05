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


func test_audio_settings_exposes_named_bus_defaults() -> void:
	assert_eq(AudioSettings.get_bus_volume(&"Master"), 1.0)
	assert_eq(AudioSettings.get_bus_volume(&"Music"), 1.0)
