extends RefCounted
class_name GDScriptWarningPreflight

const WARNING_ERROR: int = 2
const WARNING_PREFIX: String = "debug/gdscript/warnings/"
const WARNING_NAMES: Array[String] = [
	"assert_always_false",
	"assert_always_true",
	"confusable_identifier",
	"confusable_local_declaration",
	"confusable_local_usage",
	"constant_used_as_function",
	"deprecated_keyword",
	"empty_file",
	"function_used_as_property",
	"get_node_default_without_onready",
	"incompatible_ternary",
	"inference_on_variant",
	"inferred_declaration",
	"int_as_enum_without_cast",
	"int_as_enum_without_match",
	"integer_division",
	"narrowing_conversion",
	"native_method_override",
	"onready_with_export",
	"property_used_as_function",
	"redundant_await",
	"redundant_static_unload",
	"renamed_in_godot_4_hint",
	"return_value_discarded",
	"shadowed_global_identifier",
	"shadowed_variable",
	"shadowed_variable_base_class",
	"standalone_expression",
	"standalone_ternary",
	"static_called_on_instance",
	"unassigned_variable",
	"unassigned_variable_op_assign",
	"unreachable_code",
	"unreachable_pattern",
	"unsafe_call_argument",
	"unsafe_cast",
	"unsafe_method_access",
	"unsafe_property_access",
	"unsafe_void_return",
	"untyped_declaration",
	"unused_local_constant",
	"unused_parameter",
	"unused_private_class_variable",
	"unused_signal",
	"unused_variable",
]
const NODE_LIKE_BASES: Dictionary = {
	"CanvasItem": true,
	"CharacterBody2D": true,
	"Control": true,
	"GutTest": true,
	"Node": true,
	"Node2D": true,
	"SceneTree": true,
	"StaticBody2D": true,
}
const PROJECT_ROOTS: Array[String] = [
	"res://autoloads",
	"res://scenes",
	"res://scripts",
	"res://tools",
]
const KNOWN_INFERENCE_HOTSPOTS: Array[String] = []


static func run(roots: Array[String] = PROJECT_ROOTS) -> Dictionary:
	var warning_settings: Dictionary = _capture_warning_settings()
	var failures: Array[String] = []
	_apply_strict_warning_settings(warning_settings)
	for script_path: String in _collect_gdscript_paths(roots):
		var source: String = FileAccess.get_file_as_string(script_path)
		failures.append_array(_scan_static_warning_failures(script_path, source))
	_restore_warning_settings(warning_settings)
	return {
		"ok": failures.is_empty(),
		"failures": failures,
	}


static func _capture_warning_settings() -> Dictionary:
	var settings: Dictionary = {}
	for property: Dictionary in ProjectSettings.get_property_list():
		var property_name: Variant = property.get("name", "")
		var name: String = str(property_name)
		if name.begins_with(WARNING_PREFIX):
			settings[name] = ProjectSettings.get(name)
	var enable_path: String = WARNING_PREFIX + "enable"
	if not settings.has(enable_path) and ProjectSettings.has_setting(enable_path):
		settings[enable_path] = ProjectSettings.get(enable_path)
	for warning_name: String in WARNING_NAMES:
		var setting_path: String = WARNING_PREFIX + warning_name
		if not settings.has(setting_path) and ProjectSettings.has_setting(setting_path):
			settings[setting_path] = ProjectSettings.get(setting_path)
	return settings


static func _apply_strict_warning_settings(settings: Dictionary) -> void:
	for setting_path: String in settings:
		var value: Variant = settings[setting_path]
		if setting_path == WARNING_PREFIX + "enable":
			ProjectSettings.set(setting_path, true)
		elif typeof(value) == TYPE_INT:
			ProjectSettings.set(setting_path, WARNING_ERROR)


static func _restore_warning_settings(settings: Dictionary) -> void:
	for setting_path: String in settings:
		ProjectSettings.set(setting_path, settings[setting_path])


static func _collect_gdscript_paths(roots: Array[String]) -> Array[String]:
	var paths: Array[String] = []
	for root: String in roots:
		_collect_gdscript_paths_recursive(root, paths)
	paths.sort()
	return paths


static func _collect_gdscript_paths_recursive(path: String, paths: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	var list_result: Error = dir.list_dir_begin() as Error
	if list_result != OK:
		return
	var entry: String = dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full_path: String = path.path_join(entry)
		if dir.current_is_dir():
			_collect_gdscript_paths_recursive(full_path, paths)
		elif entry.ends_with(".gd"):
			paths.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


static func _scan_static_warning_failures(script_path: String, source: String) -> Array[String]:
	var failures: Array[String] = []
	var base_class: String = _get_extends_base(source)
	if NODE_LIKE_BASES.has(base_class):
		_scan_native_method_override_failures(script_path, source, failures)
	_scan_inference_hotspot_failures(script_path, source, failures)
	return failures


static func _get_extends_base(source: String) -> String:
	for line: String in source.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("extends "):
			return stripped.trim_prefix("extends ").split(" ")[0].strip_edges()
	return ""


static func _scan_native_method_override_failures(script_path: String, source: String, failures: Array[String]) -> void:
	var line_number: int = 0
	for line: String in source.split("\n"):
		line_number += 1
		var stripped: String = line.strip_edges()
		if not stripped.begins_with("func get_path("):
			continue
		if stripped == "func get_path() -> NodePath:":
			continue
		failures.append(
			"%s:%d defines get_path with a signature that conflicts with Node.get_path() -> NodePath."
			% [script_path, line_number]
		)


static func _scan_inference_hotspot_failures(script_path: String, source: String, failures: Array[String]) -> void:
	if KNOWN_INFERENCE_HOTSPOTS.is_empty():
		return
	var line_number: int = 0
	for line: String in source.split("\n"):
		line_number += 1
		for pattern: String in KNOWN_INFERENCE_HOTSPOTS:
			if line.contains(pattern):
				failures.append("%s:%d has a known fragile GDScript inference hotspot." % [script_path, line_number])
