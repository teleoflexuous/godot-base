class_name ProperCameraPhantomBridge
extends Node

signal configuration_failed(message: String)
signal active_changed(active: bool)

const SUPPORTED_VERSION: String = "0.11.0.3"
const PLUGIN_CONFIG_PATH: String = "res://addons/phantom_camera/plugin.cfg"

@export var enabled: bool = false:
	set(value):
		enabled = value
		if is_inside_tree() and enabled:
			validate_configuration(true)
@export var phantom_camera_path: NodePath
@export var allow_untested_version: bool = false

var _phantom_camera: Node
var _is_phantom_active: bool = false
var _reported_failure: bool = false


func _ready() -> void:
	if not phantom_camera_path.is_empty():
		bind_phantom_camera(get_node_or_null(phantom_camera_path))
	if enabled:
		validate_configuration(true)


func _exit_tree() -> void:
	_disconnect_activation_signals()


func bind_phantom_camera(phantom_camera: Node) -> void:
	if _phantom_camera == phantom_camera:
		return
	_disconnect_activation_signals()
	_phantom_camera = phantom_camera
	_reported_failure = false
	_connect_activation_signals()


func get_bound_phantom_camera() -> Node:
	return _phantom_camera


func is_phantom_active() -> bool:
	return enabled and _is_phantom_active and is_instance_valid(_phantom_camera)


func validate_bound_camera() -> PackedStringArray:
	var issues: PackedStringArray = []
	if _phantom_camera == null or not is_instance_valid(_phantom_camera):
		issues.append("Bind an explicit PhantomCamera2D or PhantomCamera3D node.")
		return issues
	var class_name_value: String = _phantom_camera.get_class()
	var looks_like_2d: bool = class_name_value == "PhantomCamera2D" or (
		_phantom_camera.has_method(&"set_zoom") and _phantom_camera.has_method(&"set_follow_target")
	)
	var looks_like_3d: bool = class_name_value == "PhantomCamera3D" or (
		_phantom_camera.has_method(&"set_spring_length") or _phantom_camera.has_method(&"set_third_person_rotation_degrees")
	)
	if not looks_like_2d and not looks_like_3d:
		issues.append("The bound node does not expose the supported Phantom Camera capabilities.")
	return issues


func validate_configuration(report_error: bool = false) -> bool:
	var issues: PackedStringArray = validate_bound_camera()
	# Editor plugins may expose the manager as either an engine singleton or a
	# project autoload. Capability-probe both without importing Phantom types.
	var has_manager: bool = Engine.has_singleton("PhantomCameraManager") \
		or get_node_or_null("/root/PhantomCameraManager") != null
	if not has_manager:
		issues.append("PhantomCameraManager is not registered; enable the Phantom Camera plugin and configure its Host.")
	var detected_version: String = get_installed_version()
	if not detected_version.is_empty() and detected_version != SUPPORTED_VERSION and not allow_untested_version:
		issues.append(
			"Phantom Camera %s is untested; expected %s. Enable allow_untested_version to use capability probing."
			% [detected_version, SUPPORTED_VERSION]
		)
	if issues.is_empty():
		_reported_failure = false
		return true
	if report_error and not _reported_failure:
		_reported_failure = true
		var message: String = " ".join(issues)
		configuration_failed.emit(message)
		push_error(message)
	return false


func get_installed_version() -> String:
	if not FileAccess.file_exists(PLUGIN_CONFIG_PATH):
		return ""
	var config: ConfigFile = ConfigFile.new()
	if config.load(PLUGIN_CONFIG_PATH) != OK:
		return ""
	return str(config.get_value("plugin", "version", ""))


func apply_2d(target: Node, follow_offset: Vector2, zoom: Vector2) -> bool:
	if not enabled or not validate_configuration(false):
		return false
	_call_if_supported(&"set_follow_target", [target])
	_call_if_supported(&"set_follow_offset", [follow_offset])
	return _call_if_supported(&"set_zoom", [zoom])


func apply_3d_simple(target: Node, follow_offset: Vector3, orientation: Quaternion) -> bool:
	if not enabled or not validate_configuration(false):
		return false
	_call_if_supported(&"set_follow_target", [target])
	_call_if_supported(&"set_follow_offset", [follow_offset])
	if _phantom_camera is Node3D:
		var node_3d: Node3D = _phantom_camera as Node3D
		node_3d.quaternion = orientation
	return true


func apply_3d_third_person(target: Node, rotation_degrees: Vector3, spring_length: float) -> bool:
	if not enabled or not validate_configuration(false):
		return false
	_call_if_supported(&"set_follow_target", [target])
	var rotation_applied: bool = _call_if_supported(&"set_third_person_rotation_degrees", [rotation_degrees])
	var length_applied: bool = _call_if_supported(&"set_spring_length", [spring_length])
	return rotation_applied and length_applied


func apply_projection(projection: Camera3D.ProjectionType, fov: float, size: float) -> bool:
	if not enabled or not validate_configuration(false):
		return false
	var applied: bool = _call_if_supported(&"set_projection", [projection])
	if projection == Camera3D.PROJECTION_PERSPECTIVE:
		applied = _call_if_supported(&"set_fov", [fov]) and applied
	else:
		applied = _call_if_supported(&"set_size", [size]) and applied
	return applied


func _call_if_supported(method: StringName, arguments: Array) -> bool:
	if _phantom_camera == null or not _phantom_camera.has_method(method):
		return false
	_phantom_camera.callv(method, arguments)
	return true


func _connect_activation_signals() -> void:
	if _phantom_camera == null:
		return
	if _phantom_camera.has_signal(&"became_active"):
		var active_result: Error = _phantom_camera.connect(&"became_active", _on_became_active)
		if active_result != OK:
			push_warning("Could not observe Phantom Camera activation.")
	if _phantom_camera.has_signal(&"became_inactive"):
		var inactive_result: Error = _phantom_camera.connect(&"became_inactive", _on_became_inactive)
		if inactive_result != OK:
			push_warning("Could not observe Phantom Camera deactivation.")


func _disconnect_activation_signals() -> void:
	if _phantom_camera == null or not is_instance_valid(_phantom_camera):
		return
	var active_callable: Callable = _on_became_active
	var inactive_callable: Callable = _on_became_inactive
	if _phantom_camera.has_signal(&"became_active") and _phantom_camera.is_connected(
		&"became_active", active_callable
	):
		_phantom_camera.disconnect(&"became_active", active_callable)
	if _phantom_camera.has_signal(&"became_inactive") and _phantom_camera.is_connected(
		&"became_inactive", inactive_callable
	):
		_phantom_camera.disconnect(&"became_inactive", inactive_callable)


func _on_became_active() -> void:
	_is_phantom_active = true
	active_changed.emit(true)


func _on_became_inactive() -> void:
	_is_phantom_active = false
	active_changed.emit(false)
