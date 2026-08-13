class_name InputProfiles
extends RefCounted

## Deprecated profile-ID facade. New code should use InputCapabilities and the
## InputSettings autoload. The facade deliberately preserves exact legacy masks.
const InputCapabilityContract := preload("res://scripts/input/input_capabilities.gd")
const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "input"
const PROFILE_KEY: String = "profile"
const CAPABILITIES_KEY: String = "capability_mask"
const BUNDLE_KEY: String = "capability_bundle"
const PROFILE_IDS: Array[StringName] = [
	&"character_keyboard",
	&"character_keyboard_touch_gamepad",
	&"character_keyboard_mouse",
	&"character_keyboard_mouse_touch_gamepad",
	&"pointer_mouse_touch",
]


static func get_active_profile() -> StringName:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return InputCapabilityContract.legacy_profile_for_mask(InputCapabilityContract.ALL)
	if config.has_section_key(SECTION, CAPABILITIES_KEY):
		var raw_mask: Variant = config.get_value(SECTION, CAPABILITIES_KEY, InputCapabilityContract.ALL)
		var mask: int = raw_mask if raw_mask is int else InputCapabilityContract.ALL
		return InputCapabilityContract.legacy_profile_for_mask(mask)
	var raw: Variant = config.get_value(SECTION, PROFILE_KEY, String(PROFILE_IDS[0]))
	var profile: StringName = StringName(str(raw))
	if PROFILE_IDS.has(profile):
		return profile
	return InputCapabilityContract.legacy_profile_for_mask(InputCapabilityContract.ALL)


static func set_active_profile(profile: StringName) -> bool:
	if not PROFILE_IDS.has(profile):
		return false
	var config: ConfigFile = ConfigFile.new()
	var _load_result: int = config.load(SETTINGS_PATH)
	config.set_value(SECTION, PROFILE_KEY, String(profile))
	var mask: int = InputCapabilityContract.mask_for_legacy_profile(profile)
	config.set_value(SECTION, CAPABILITIES_KEY, mask)
	config.set_value(SECTION, BUNDLE_KEY, String(InputCapabilityContract.bundle_for_mask(mask)))
	return config.save(SETTINGS_PATH) == OK


static func is_character_profile(profile: StringName) -> bool:
	return profile != &"pointer_mouse_touch"


static func get_capability_mask() -> int:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK and config.has_section_key(SECTION, CAPABILITIES_KEY):
		var raw_mask: Variant = config.get_value(SECTION, CAPABILITIES_KEY, InputCapabilityContract.ALL)
		var mask: int = raw_mask if raw_mask is int else InputCapabilityContract.ALL
		return InputCapabilityContract.normalize(mask)
	return InputCapabilityContract.mask_for_legacy_profile(get_active_profile())
