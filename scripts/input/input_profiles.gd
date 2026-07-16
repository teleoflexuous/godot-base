class_name InputProfiles
extends RefCounted

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "input"
const PROFILE_KEY: String = "profile"
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
		return PROFILE_IDS[0]
	var raw: Variant = config.get_value(SECTION, PROFILE_KEY, String(PROFILE_IDS[0]))
	var profile: StringName = StringName(str(raw))
	return profile if PROFILE_IDS.has(profile) else PROFILE_IDS[0]


static func set_active_profile(profile: StringName) -> bool:
	if not PROFILE_IDS.has(profile):
		return false
	var config: ConfigFile = ConfigFile.new()
	var _load_result: int = config.load(SETTINGS_PATH)
	config.set_value(SECTION, PROFILE_KEY, String(profile))
	return config.save(SETTINGS_PATH) == OK


static func is_character_profile(profile: StringName) -> bool:
	return profile != &"pointer_mouse_touch"
