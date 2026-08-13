class_name InputCapabilities
extends RefCounted

## Device capabilities are independent flags: a game can enable any combination.
enum Device {
	KEYBOARD = 1,
	MOUSE = 2,
	GAMEPAD = 4,
	TOUCH = 8,
}

const NONE: int = 0
const ALL: int = Device.KEYBOARD | Device.MOUSE | Device.GAMEPAD | Device.TOUCH

const BUNDLE_ALL: StringName = &"all"
const BUNDLE_DESKTOP: StringName = &"desktop"
const BUNDLE_DESKTOP_GAMEPAD: StringName = &"desktop_gamepad"
const BUNDLE_MOBILE: StringName = &"mobile"
const BUNDLE_GAMEPAD: StringName = &"gamepad"
const BUNDLE_CUSTOM: StringName = &"custom"

const BUNDLE_IDS: Array[StringName] = [
	BUNDLE_ALL,
	BUNDLE_DESKTOP,
	BUNDLE_DESKTOP_GAMEPAD,
	BUNDLE_MOBILE,
	BUNDLE_GAMEPAD,
	BUNDLE_CUSTOM,
]

const _BUNDLE_MASKS: Dictionary[StringName, int] = {
	BUNDLE_ALL: ALL,
	BUNDLE_DESKTOP: Device.KEYBOARD | Device.MOUSE,
	BUNDLE_DESKTOP_GAMEPAD: Device.KEYBOARD | Device.MOUSE | Device.GAMEPAD,
	BUNDLE_MOBILE: Device.TOUCH | Device.GAMEPAD,
	BUNDLE_GAMEPAD: Device.GAMEPAD,
}

const _LEGACY_PROFILE_MASKS: Dictionary[StringName, int] = {
	&"character_keyboard": Device.KEYBOARD,
	&"character_keyboard_touch_gamepad": Device.KEYBOARD | Device.TOUCH | Device.GAMEPAD,
	&"character_keyboard_mouse": Device.KEYBOARD | Device.MOUSE,
	&"character_keyboard_mouse_touch_gamepad": ALL,
	&"pointer_mouse_touch": Device.MOUSE | Device.TOUCH,
}


static func normalize(mask: int) -> int:
	return mask & ALL


static func has_device(mask: int, device: Device) -> bool:
	return (normalize(mask) & int(device)) != 0


static func mask_for_bundle(bundle: StringName) -> int:
	return _BUNDLE_MASKS[bundle] if _BUNDLE_MASKS.has(bundle) else ALL


static func bundle_for_mask(mask: int) -> StringName:
	var normalized: int = normalize(mask)
	for bundle: StringName in _BUNDLE_MASKS:
		if _BUNDLE_MASKS[bundle] == normalized:
			return bundle
	return BUNDLE_CUSTOM


static func is_bundle(bundle: StringName) -> bool:
	return BUNDLE_IDS.has(bundle)


static func mask_for_legacy_profile(profile: StringName) -> int:
	return _LEGACY_PROFILE_MASKS[profile] if _LEGACY_PROFILE_MASKS.has(profile) else ALL


static func is_legacy_profile(profile: StringName) -> bool:
	return _LEGACY_PROFILE_MASKS.has(profile)


static func legacy_profile_for_mask(mask: int) -> StringName:
	var normalized: int = normalize(mask)
	for profile: StringName in _LEGACY_PROFILE_MASKS:
		if _LEGACY_PROFILE_MASKS[profile] == normalized:
			return profile
	return &"character_keyboard_mouse_touch_gamepad"


static func display_name(bundle: StringName) -> String:
	match bundle:
		BUNDLE_ALL:
			return "All devices"
		BUNDLE_DESKTOP:
			return "Desktop"
		BUNDLE_DESKTOP_GAMEPAD:
			return "Desktop + gamepad"
		BUNDLE_MOBILE:
			return "Mobile + gamepad"
		BUNDLE_GAMEPAD:
			return "Gamepad only"
		BUNDLE_CUSTOM:
			return "Custom"
		_:
			return "All devices"
