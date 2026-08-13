class_name CameraSettingsBinder
extends Node

## Optional project boundary: injects project-owned autoload values into the
## reusable adapter/router without making either depend on those autoloads.
@export var input_adapter: CameraInputAdapter
## Deliberately untyped: this core boundary must load when the optional
## G.U.I.D.E. integration is not installed.
@export var guide_context_router: Node
@export var edge_scroll: CameraEdgeScroll
@export var camera_rig: Node
@export var input_settings_path: NodePath = NodePath("/root/InputSettings")
@export var camera_settings_path: NodePath = NodePath("/root/CameraSettings")

var _input_settings: Node
var _camera_settings: Node


func _ready() -> void:
	_input_settings = get_node_or_null(input_settings_path)
	_camera_settings = get_node_or_null(camera_settings_path)
	if _input_settings != null:
		_apply_capabilities(int(_input_settings.get("capability_mask")), StringName())
		if _input_settings.has_signal("capabilities_changed"):
			_input_settings.connect("capabilities_changed", _apply_capabilities)
	if _camera_settings != null:
		var stored_preferences: Variant = _camera_settings.get("preferences")
		if stored_preferences is CameraUserPreferences:
			_apply_preferences(stored_preferences as CameraUserPreferences)
		if _camera_settings.has_signal("preferences_changed"):
			_camera_settings.connect("preferences_changed", _apply_preferences)


func _exit_tree() -> void:
	if _input_settings != null and _input_settings.is_connected("capabilities_changed", _apply_capabilities):
		_input_settings.disconnect("capabilities_changed", _apply_capabilities)
	if _camera_settings != null and _camera_settings.is_connected("preferences_changed", _apply_preferences):
		_camera_settings.disconnect("preferences_changed", _apply_preferences)


func _apply_capabilities(mask: int, _bundle: StringName) -> void:
	if guide_context_router != null and guide_context_router.has_method(&"set_device_mask"):
		guide_context_router.call(&"set_device_mask", mask)


func _apply_preferences(next_preferences: CameraUserPreferences) -> void:
	if input_adapter != null:
		input_adapter.set_preferences(next_preferences)
	if edge_scroll != null:
		edge_scroll.enabled = next_preferences.edge_pan_enabled
	if camera_rig != null and camera_rig.has_method(&"set_user_preferences"):
		camera_rig.call(&"set_user_preferences", next_preferences)
