class_name ProperCameraViewVisibility3D
extends Node

enum VisibilityMode {
	HIDE,
	NATIVE_TRANSPARENCY,
	INSTANCE_SHADER_PARAMETER,
	AUTO,
}

@export var camera_rig_path: NodePath
@export var visual_targets: Array[NodePath] = []
@export var visibility_mode: VisibilityMode = VisibilityMode.AUTO
@export var shader_parameter: StringName = &"camera_fade"
@export_range(0.0, 1.0, 0.01) var first_person_transparency: float = 1.0
@export_range(0.0, 40.0, 0.1) var transition_speed: float = 12.0

var _camera_rig: Node
var _amount: float = 0.0
var _target_amount: float = 0.0
var _originals: Dictionary = {}


func _ready() -> void:
	_capture_originals()
	if not camera_rig_path.is_empty():
		set_camera_rig(get_node_or_null(camera_rig_path))


func _process(delta: float) -> void:
	_amount = move_toward(_amount, _target_amount, transition_speed * delta)
	_apply_amount(_amount)
	if is_equal_approx(_amount, _target_amount):
		set_process(false)


func _exit_tree() -> void:
	_disconnect_camera_rig()
	restore_originals()


func set_camera_rig(camera_rig: Node) -> void:
	if _camera_rig == camera_rig:
		return
	_disconnect_camera_rig()
	_camera_rig = camera_rig
	if _camera_rig != null and _camera_rig.has_signal(&"view_mode_changed"):
		var result: Error = _camera_rig.connect(&"view_mode_changed", _on_view_mode_changed)
		if result != OK:
			push_warning("ProperCameraViewVisibility3D could not connect to view_mode_changed.")
	if _camera_rig != null and _camera_rig.has_method(&"get_view_mode"):
		apply_view_mode(int(_camera_rig.call(&"get_view_mode")))


func apply_view_mode(mode: int) -> void:
	_target_amount = 1.0 if mode == ProperCameraRigTypes.ViewMode3D.FIRST_PERSON else 0.0
	set_process(true)


func restore_originals() -> void:
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			continue
		var id: int = target.get_instance_id()
		if not _originals.has(id):
			continue
		var values: Dictionary = _originals[id] as Dictionary
		target.visible = bool(values[&"visible"])
		target.transparency = float(values[&"transparency"])
		if values.has(&"shader") and _has_shader_parameter(target):
			target.set_instance_shader_parameter(shader_parameter, values[&"shader"])


func _capture_originals() -> void:
	_originals.clear()
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			continue
		var values: Dictionary = {
			&"visible": target.visible,
			&"transparency": target.transparency,
		}
		if _has_shader_parameter(target):
			values[&"shader"] = target.get_instance_shader_parameter(shader_parameter)
		_originals[target.get_instance_id()] = values


func _apply_amount(amount: float) -> void:
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			continue
		var id: int = target.get_instance_id()
		if not _originals.has(id):
			continue
		var values: Dictionary = _originals[id] as Dictionary
		var use_shader: bool = visibility_mode == VisibilityMode.INSTANCE_SHADER_PARAMETER or (
			visibility_mode == VisibilityMode.AUTO and _has_shader_parameter(target)
		)
		if visibility_mode == VisibilityMode.HIDE:
			target.visible = bool(values[&"visible"]) and amount < 0.5
		elif use_shader:
			target.set_instance_shader_parameter(shader_parameter, amount)
		else:
			target.transparency = lerpf(float(values[&"transparency"]), first_person_transparency, amount)


func _on_view_mode_changed(_previous: int, current: int) -> void:
	apply_view_mode(current)


func _disconnect_camera_rig() -> void:
	if _camera_rig != null and is_instance_valid(_camera_rig):
		var callable: Callable = _on_view_mode_changed
		if _camera_rig.is_connected(&"view_mode_changed", callable):
			_camera_rig.disconnect(&"view_mode_changed", callable)
	_camera_rig = null


func _has_shader_parameter(target: GeometryInstance3D) -> bool:
	for parameter: Dictionary in RenderingServer.instance_geometry_get_shader_parameter_list(target.get_instance()):
		if StringName(parameter.get(&"name", &"")) == shader_parameter:
			return true
	return false
