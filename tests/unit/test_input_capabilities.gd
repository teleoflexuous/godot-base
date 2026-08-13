extends GutTest

const InputSettingsScript := preload("res://autoloads/input_settings.gd")
const TEST_PATH: String = "user://test_input_capabilities.cfg"


func after_each() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute_path):
		var _remove_result: Error = DirAccess.remove_absolute(absolute_path)


func test_default_bundle_includes_every_device() -> void:
	assert_eq(InputCapabilities.ALL, 15)
	assert_eq(InputCapabilities.mask_for_bundle(&"all"), InputCapabilities.ALL)
	assert_true(InputCapabilities.has_device(InputCapabilities.ALL, InputCapabilities.Device.KEYBOARD))
	assert_true(InputCapabilities.has_device(InputCapabilities.ALL, InputCapabilities.Device.MOUSE))
	assert_true(InputCapabilities.has_device(InputCapabilities.ALL, InputCapabilities.Device.GAMEPAD))
	assert_true(InputCapabilities.has_device(InputCapabilities.ALL, InputCapabilities.Device.TOUCH))


func test_named_bundles_are_independent_capability_masks() -> void:
	assert_eq(
		InputCapabilities.mask_for_bundle(&"desktop"),
		InputCapabilities.Device.KEYBOARD | InputCapabilities.Device.MOUSE
	)
	assert_eq(
		InputCapabilities.mask_for_bundle(&"desktop_gamepad"),
		InputCapabilities.Device.KEYBOARD | InputCapabilities.Device.MOUSE | InputCapabilities.Device.GAMEPAD
	)
	assert_eq(
		InputCapabilities.mask_for_bundle(&"mobile"),
		InputCapabilities.Device.TOUCH | InputCapabilities.Device.GAMEPAD
	)
	assert_eq(InputCapabilities.mask_for_bundle(&"gamepad"), InputCapabilities.Device.GAMEPAD)
	assert_eq(
		InputCapabilities.bundle_for_mask(InputCapabilities.Device.KEYBOARD | InputCapabilities.Device.TOUCH),
		&"custom"
	)


func test_legacy_profiles_migrate_without_adding_devices() -> void:
	assert_eq(
		InputCapabilities.mask_for_legacy_profile(&"character_keyboard"),
		InputCapabilities.Device.KEYBOARD
	)
	assert_eq(
		InputCapabilities.mask_for_legacy_profile(&"character_keyboard_touch_gamepad"),
		InputCapabilities.Device.KEYBOARD | InputCapabilities.Device.TOUCH | InputCapabilities.Device.GAMEPAD
	)
	assert_eq(
		InputCapabilities.mask_for_legacy_profile(&"character_keyboard_mouse"),
		InputCapabilities.Device.KEYBOARD | InputCapabilities.Device.MOUSE
	)
	assert_eq(
		InputCapabilities.mask_for_legacy_profile(&"pointer_mouse_touch"),
		InputCapabilities.Device.MOUSE | InputCapabilities.Device.TOUCH
	)


func test_input_settings_loads_legacy_profile_and_persists_new_contract() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("input", "profile", "pointer_mouse_touch")
	assert_eq(config.save(TEST_PATH), OK)
	var settings: Node = InputSettingsScript.new()
	settings.call("load_settings", TEST_PATH)
	assert_eq(
		settings.get("capability_mask"),
		InputCapabilities.Device.MOUSE | InputCapabilities.Device.TOUCH
	)
	assert_eq(settings.get("capability_bundle"), &"custom")
	assert_true(bool(settings.call("save_settings", TEST_PATH)))
	var saved: ConfigFile = ConfigFile.new()
	assert_eq(saved.load(TEST_PATH), OK)
	assert_eq(
		saved.get_value("input", "capability_mask"),
		InputCapabilities.Device.MOUSE | InputCapabilities.Device.TOUCH
	)
	settings.free()
