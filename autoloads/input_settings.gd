extends Node

signal capabilities_changed(mask: int, bundle: StringName)

const InputCapabilityContract := preload("res://scripts/input/input_capabilities.gd")
const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "input"
const CAPABILITIES_KEY: String = "capability_mask"
const BUNDLE_KEY: String = "capability_bundle"
const LEGACY_PROFILE_KEY: String = "profile"

var capability_mask: int = InputCapabilityContract.ALL
var capability_bundle: StringName = InputCapabilityContract.BUNDLE_ALL


func _ready() -> void:
	load_settings()


func set_bundle(bundle: StringName) -> bool:
	if not InputCapabilityContract.is_bundle(bundle) or bundle == InputCapabilityContract.BUNDLE_CUSTOM:
		return false
	return set_capabilities(InputCapabilityContract.mask_for_bundle(bundle), bundle)


func set_capabilities(mask: int, bundle: StringName = &"") -> bool:
	var normalized: int = InputCapabilityContract.normalize(mask)
	var resolved_bundle: StringName = bundle
	if resolved_bundle.is_empty() or resolved_bundle == InputCapabilityContract.BUNDLE_CUSTOM:
		resolved_bundle = InputCapabilityContract.bundle_for_mask(normalized)
	elif not InputCapabilityContract.is_bundle(resolved_bundle):
		return false
	elif InputCapabilityContract.mask_for_bundle(resolved_bundle) != normalized:
		resolved_bundle = InputCapabilityContract.BUNDLE_CUSTOM
	if capability_mask == normalized and capability_bundle == resolved_bundle:
		return true
	capability_mask = normalized
	capability_bundle = resolved_bundle
	if not save_settings():
		return false
	capabilities_changed.emit(capability_mask, capability_bundle)
	return true


func has_device(device: InputCapabilityContract.Device) -> bool:
	return InputCapabilityContract.has_device(capability_mask, device)


func load_settings(path: String = SETTINGS_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		capability_mask = InputCapabilityContract.ALL
		capability_bundle = InputCapabilityContract.BUNDLE_ALL
		return
	if config.has_section_key(SECTION, CAPABILITIES_KEY):
		var raw_mask: Variant = config.get_value(SECTION, CAPABILITIES_KEY, InputCapabilityContract.ALL)
		var stored_mask: int = raw_mask if raw_mask is int else InputCapabilityContract.ALL
		capability_mask = InputCapabilityContract.normalize(
			stored_mask
		)
		var raw_bundle: Variant = config.get_value(SECTION, BUNDLE_KEY, "")
		var stored_bundle: StringName = StringName(str(raw_bundle))
		capability_bundle = InputCapabilityContract.bundle_for_mask(capability_mask)
		if InputCapabilityContract.is_bundle(stored_bundle) \
				and stored_bundle != InputCapabilityContract.BUNDLE_CUSTOM \
				and InputCapabilityContract.mask_for_bundle(stored_bundle) == capability_mask:
			capability_bundle = stored_bundle
		return
	var legacy_raw: Variant = config.get_value(SECTION, LEGACY_PROFILE_KEY, "")
	var legacy_profile: StringName = StringName(str(legacy_raw))
	capability_mask = InputCapabilityContract.mask_for_legacy_profile(legacy_profile)
	capability_bundle = InputCapabilityContract.bundle_for_mask(capability_mask)
	var _migration_saved: bool = save_settings(path)


func save_settings(path: String = SETTINGS_PATH) -> bool:
	var config: ConfigFile = ConfigFile.new()
	var _load_result: Error = config.load(path)
	config.set_value(SECTION, CAPABILITIES_KEY, capability_mask)
	config.set_value(SECTION, BUNDLE_KEY, String(capability_bundle))
	config.set_value(
		SECTION,
		LEGACY_PROFILE_KEY,
		String(InputCapabilityContract.legacy_profile_for_mask(capability_mask))
	)
	return config.save(path) == OK
