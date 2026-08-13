extends GutTest

const CameraSettingsScript := preload("res://autoloads/camera_settings.gd")
const TEST_PATH: String = "user://test_camera_input_settings.cfg"


func after_each() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute_path):
		var _remove_result: Error = DirAccess.remove_absolute(absolute_path)


func test_camera_preferences_round_trip_player_accessibility_settings() -> void:
	var writer: Node = CameraSettingsScript.new()
	var values: Dictionary = {
		"horizontal_sensitivity": 2.5,
		"vertical_sensitivity": 0.75,
		"zoom_sensitivity": 1.5,
		"invert_vertical": true,
		"edge_pan_enabled": false,
		"auto_recenter_enabled": true,
		"fov_override_enabled": true,
		"preferred_fov_degrees": 92.0,
		"distance_override_enabled": true,
		"preferred_distance": 7.5,
		"motion_intensity": 0.25,
	}
	assert_true(bool(writer.call("update_values", values, false)))
	assert_true(bool(writer.call("save_settings", TEST_PATH)))
	var reader: Node = CameraSettingsScript.new()
	reader.call("load_settings", TEST_PATH)
	var prefs: CameraUserPreferences = reader.get("preferences") as CameraUserPreferences
	assert_eq(prefs.horizontal_sensitivity, 2.5)
	assert_eq(prefs.vertical_sensitivity, 0.75)
	assert_eq(prefs.zoom_sensitivity, 1.5)
	assert_true(prefs.invert_vertical)
	assert_false(prefs.edge_pan_enabled)
	assert_true(prefs.auto_recenter_enabled)
	assert_true(prefs.fov_override_enabled)
	assert_eq(prefs.preferred_fov_degrees, 92.0)
	assert_true(prefs.distance_override_enabled)
	assert_eq(prefs.preferred_distance, 7.5)
	assert_eq(prefs.motion_intensity, 0.25)
	writer.free()
	reader.free()


func test_reset_defaults_restores_full_motion_and_allows_edge_pan() -> void:
	var settings: Node = CameraSettingsScript.new()
	settings.call("update_values", {"motion_intensity": 0.0, "edge_pan_enabled": false}, false)
	assert_true(bool(settings.call("reset_defaults", false)))
	var prefs: CameraUserPreferences = settings.get("preferences") as CameraUserPreferences
	assert_eq(prefs.motion_intensity, 1.0)
	assert_true(prefs.edge_pan_enabled)
	settings.free()
