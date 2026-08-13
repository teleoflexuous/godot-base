extends GutTest

const PLUGIN_PATH: String = "res://addons/phantom_camera/plugin.cfg"
const PCAM_2D_PATH: String = "res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_2d.gd"
const PCAM_3D_PATH: String = "res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd"


func test_staged_official_phantom_surface_matches_the_pinned_bridge() -> void:
	if not FileAccess.file_exists(PLUGIN_PATH):
		pass_test("Phantom Camera is optional; official compatibility is exercised in its dedicated CI job.")
		return
	var config: ConfigFile = ConfigFile.new()
	assert_eq(config.load(PLUGIN_PATH), OK)
	assert_eq(str(config.get_value("plugin", "version", "")), ProperCameraPhantomBridge.SUPPORTED_VERSION)
	var source_2d: String = FileAccess.get_file_as_string(PCAM_2D_PATH)
	var source_3d: String = FileAccess.get_file_as_string(PCAM_3D_PATH)
	assert_true(source_2d.contains("set_follow_target"))
	assert_true(source_2d.contains("set_zoom"))
	assert_true(source_3d.contains("set_follow_target"))
	assert_true(source_3d.contains("set_third_person_rotation_degrees"))
	assert_true(source_3d.contains("set_spring_length"))
	assert_true(source_3d.contains("set_fov"))
	assert_true(source_3d.contains("set_size"))
