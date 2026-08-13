extends Node3D

const PHASE_DURATION_SECONDS: float = 2.0

@onready var _target: Node3D = $Character
@onready var _rig: ProperCameraRig3D = $ProperCameraRig3D
@onready var _status: Label = $UI/Status

var _phase_index: int = 0
var _phase_elapsed: float = 0.0
var _last_camera_position: Vector3 = Vector3.ZERO
var _maximum_idle_motion: float = 0.0
var _target_x_positions: Array[float] = [0.0, -0.25, 0.25]


func _ready() -> void:
	_rig.set_follow_target(_target, true)
	_rig.set_follow_enabled(true)
	_last_camera_position = _rig.get_camera().global_position
	$UI/Back.pressed.connect(_return_to_gallery)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_return_to_gallery()
		get_viewport().set_input_as_handled()


func _return_to_gallery() -> void:
	get_tree().change_scene_to_file("res://addons/proper_camera/examples/camera_gallery.tscn")


func _process(delta: float) -> void:
	_phase_elapsed += delta
	var camera_position: Vector3 = _rig.get_camera().global_position
	_maximum_idle_motion = maxf(_maximum_idle_motion, camera_position.distance_to(_last_camera_position))
	_last_camera_position = camera_position
	if _phase_elapsed >= PHASE_DURATION_SECONDS:
		_phase_elapsed = 0.0
		_phase_index = (_phase_index + 1) % _target_x_positions.size()
		_target.position.x = _target_x_positions[_phase_index]
		_maximum_idle_motion = 0.0
	var state: Dictionary = _rig.get_occlusion_debug_state()
	_status.text = (
		"Occlusion Stability Lab\n"
		+ "Phase: %s — stationary for %.1fs\n" % [_phase_name(), _phase_elapsed]
		+ "Centered route blocked: %s\n" % state[&"center_route_blocked"]
		+ "Escape yaw: %.2f° | shoulder: %.2f\n" % [rad_to_deg(float(state[&"yaw_offset"])), float(state[&"shoulder_offset"])]
		+ "Actual boom: %.3f | max frame motion: %.5f\n" % [float(state[&"actual_distance"]), _maximum_idle_motion]
		+ "Expected: after settling, the values above remain steady until the next phase."
	)


func _phase_name() -> String:
	return ["Centered edge", "Character left", "Character right"][_phase_index]
