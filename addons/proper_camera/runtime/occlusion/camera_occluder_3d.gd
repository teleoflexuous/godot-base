class_name ProperCameraOccluder3D
extends Node

@export var visual_targets: Array[NodePath] = []
@export var fade_mode: ProperCameraFadeTypes.FadeMode = ProperCameraFadeTypes.FadeMode.AUTO
@export var shader_parameter: StringName = &"camera_fade"
@export_range(0.0, 1.0, 0.01) var maximum_transparency: float = 0.85
@export_range(0.0, 40.0, 0.1) var fade_in_speed: float = 10.0
@export_range(0.0, 40.0, 0.1) var fade_out_speed: float = 6.0

var _requests: Dictionary = {}
var _amount: float = 0.0
var _original_native: Dictionary = {}
var _original_shader: Dictionary = {}


func _ready() -> void:
	_capture_originals()


func _process(delta: float) -> void:
	var target_amount: float = 0.0
	for value: Variant in _requests.values():
		target_amount = maxf(target_amount, float(value))
	var speed: float = fade_in_speed if target_amount > _amount else fade_out_speed
	_amount = move_toward(_amount, target_amount, speed * delta)
	_apply_amount(_amount)
	if is_zero_approx(_amount) and is_zero_approx(target_amount):
		set_process(false)


func _exit_tree() -> void:
	restore_originals()


func request_fade(requester_id: int, amount: float = 1.0) -> void:
	_requests[requester_id] = clampf(amount, 0.0, 1.0)
	set_process(true)


func clear_fade(requester_id: int) -> void:
	_requests.erase(requester_id)
	set_process(true)


func clear_all_fades() -> void:
	_requests.clear()
	set_process(true)


func get_fade_amount() -> float:
	return _amount


func validate_configuration() -> PackedStringArray:
	var issues: PackedStringArray = []
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			issues.append("Visual target '%s' is not a GeometryInstance3D." % path)
		elif fade_mode == ProperCameraFadeTypes.FadeMode.INSTANCE_SHADER_PARAMETER and not _has_shader_parameter(target):
			issues.append("Visual target '%s' has no instance uniform '%s'." % [path, shader_parameter])
	return issues


func restore_originals() -> void:
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			continue
		var id: int = target.get_instance_id()
		if _original_native.has(id):
			target.transparency = float(_original_native[id])
		if _original_shader.has(id) and _has_shader_parameter(target):
			target.set_instance_shader_parameter(shader_parameter, _original_shader[id])


func _capture_originals() -> void:
	_original_native.clear()
	_original_shader.clear()
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			continue
		var id: int = target.get_instance_id()
		_original_native[id] = target.transparency
		if _has_shader_parameter(target):
			_original_shader[id] = target.get_instance_shader_parameter(shader_parameter)


func _apply_amount(amount: float) -> void:
	for path: NodePath in visual_targets:
		var target: GeometryInstance3D = get_node_or_null(path) as GeometryInstance3D
		if target == null:
			continue
		var id: int = target.get_instance_id()
		var use_shader: bool = fade_mode == ProperCameraFadeTypes.FadeMode.INSTANCE_SHADER_PARAMETER or (
			fade_mode == ProperCameraFadeTypes.FadeMode.AUTO and _has_shader_parameter(target)
		)
		if use_shader:
			target.set_instance_shader_parameter(shader_parameter, amount)
		elif _original_native.has(id):
			var original: float = float(_original_native[id])
			target.transparency = lerpf(original, maximum_transparency, amount)


func _has_shader_parameter(target: GeometryInstance3D) -> bool:
	for parameter: Dictionary in RenderingServer.instance_geometry_get_shader_parameter_list(target.get_instance()):
		if StringName(parameter.get(&"name", &"")) == shader_parameter:
			return true
	return false
