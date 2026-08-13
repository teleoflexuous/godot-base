class_name ProperCameraInputAdapter
extends Node

## Semantic input boundary shared by InputMap and G.U.I.D.E. drivers.
## Rates include delta; device deltas never do. Positive zoom means zoom in.
signal pan_rate_requested(direction: Vector2, delta: float)
signal pan_delta_requested(screen_delta: Vector2)
signal look_rate_requested(direction: Vector2, delta: float)
signal look_delta_requested(screen_delta: Vector2)
signal zoom_rate_requested(direction: float, delta: float)
signal zoom_steps_requested(steps: float)
signal pointer_position_changed(screen_position: Vector2)
signal recenter_requested()
signal follow_toggle_requested()
signal view_toggle_requested()
signal rotation_step_requested(steps: float)
signal gesture_zoom_requested(ratio_from_start: float, zoom_at_start: float)
signal gesture_twist_requested(angle_from_start: float, heading_at_start: float)
signal input_enabled_changed(is_enabled: bool)

@export var camera_rig: Node
@export var preferences: ProperCameraUserPreferences = ProperCameraUserPreferences.new()
@export var input_enabled: bool = true
@export var release_mouse_on_disable: bool = true
@export_range(0.001, 2.0, 0.001, "or_greater") var pinch_normalized_scale: float = 0.25

var _pinch_active: bool = false
var _pinch_start_ratio: float = 1.0
var _pinch_zoom_at_start: float = 0.5
var _twist_active: bool = false
var _twist_start_angle: float = 0.0
var _twist_last_angle: float = 0.0
var _twist_heading_at_start: float = 0.0
var _idle_seconds: float = 0.0
var _auto_recenter_fired: bool = false


func _ready() -> void:
	if preferences == null:
		preferences = ProperCameraUserPreferences.new()
	set_process(input_enabled)
	set_process_unhandled_input(input_enabled)
	_apply_motion_intensity()


func _physics_process(delta: float) -> void:
	if not input_enabled or preferences == null or not preferences.auto_recenter_enabled:
		return
	_idle_seconds += maxf(delta, 0.0)
	if not _auto_recenter_fired and _idle_seconds >= preferences.auto_recenter_delay:
		_auto_recenter_fired = true
		submit_recenter()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_input_state()
		if release_mouse_on_disable:
			release_mouse_capture()


func set_input_enabled(is_enabled: bool) -> void:
	if input_enabled == is_enabled:
		return
	input_enabled = is_enabled
	set_process(input_enabled)
	set_process_unhandled_input(input_enabled)
	if not input_enabled:
		clear_input_state()
		if release_mouse_on_disable:
			release_mouse_capture()
	if is_instance_valid(camera_rig) and camera_rig.has_method(&"set_input_enabled"):
		camera_rig.call(&"set_input_enabled", input_enabled)
	input_enabled_changed.emit(input_enabled)
	_mark_activity()


func set_preferences(next_preferences: ProperCameraUserPreferences) -> void:
	preferences = next_preferences if next_preferences != null else ProperCameraUserPreferences.new()
	preferences.sanitize()
	_apply_motion_intensity()
	_mark_activity()


func capture_mouse() -> void:
	if input_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func clear_input_state() -> void:
	end_pinch()
	end_twist()


func submit_pan_rate(direction: Vector2, delta: float) -> void:
	if not input_enabled or direction.is_zero_approx():
		return
	_mark_activity()
	pan_rate_requested.emit(direction, delta)
	_call_rig(&"pan_direction", [direction, delta])


func submit_pan_delta(screen_delta: Vector2) -> void:
	if not input_enabled or screen_delta.is_zero_approx():
		return
	_mark_activity()
	pan_delta_requested.emit(screen_delta)
	_call_rig(&"pan_by_screen", [screen_delta])


func submit_look_rate(direction: Vector2, delta: float) -> void:
	if not input_enabled:
		return
	if not direction.is_zero_approx():
		_mark_activity()
	var scaled: Vector2 = _scale_look(direction)
	if not scaled.is_zero_approx():
		look_rate_requested.emit(scaled, delta)
	if not _call_rig(&"look_direction", [scaled, delta]):
		_call_rig(&"orbit_direction", [scaled, delta])


func submit_look_delta(screen_delta: Vector2) -> void:
	if not input_enabled or screen_delta.is_zero_approx():
		return
	_mark_activity()
	var scaled: Vector2 = _scale_look(screen_delta)
	look_delta_requested.emit(scaled)
	if not _call_rig(&"look_by_delta", [scaled]):
		_call_rig(&"orbit_by_radians", [scaled])


func submit_zoom_rate(direction: float, delta: float) -> void:
	if not input_enabled or is_zero_approx(direction):
		return
	_mark_activity()
	var scaled: float = _scale_zoom(direction)
	zoom_rate_requested.emit(scaled, delta)
	_call_rig(&"zoom_by_rate", [scaled, delta])


func submit_zoom_steps(steps: float) -> void:
	if not input_enabled or is_zero_approx(steps):
		return
	_mark_activity()
	var scaled: float = _scale_zoom(steps)
	zoom_steps_requested.emit(scaled)
	_call_rig(&"zoom_by_steps", [scaled])


func submit_pointer_position(screen_position: Vector2) -> void:
	if not input_enabled or not screen_position.is_finite():
		return
	pointer_position_changed.emit(screen_position)
	_call_rig(&"set_pointer_position", [screen_position])


func submit_recenter() -> void:
	if not input_enabled:
		return
	recenter_requested.emit()
	_call_rig(&"recenter")


func submit_follow_toggle() -> void:
	if not input_enabled:
		return
	_mark_activity()
	follow_toggle_requested.emit()
	_call_rig(&"toggle_follow")


func submit_view_toggle() -> void:
	if not input_enabled:
		return
	_mark_activity()
	view_toggle_requested.emit()
	_call_rig(&"toggle_view_mode")


func submit_rotation_step(steps: float) -> void:
	if not input_enabled or is_zero_approx(steps):
		return
	_mark_activity()
	rotation_step_requested.emit(steps)
	_call_rig(&"rotate_step", [steps])


func begin_pinch(ratio: float = 1.0) -> void:
	if not input_enabled or not is_finite(ratio) or ratio <= 0.0:
		return
	_mark_activity()
	_pinch_active = true
	_pinch_start_ratio = ratio
	_pinch_zoom_at_start = _read_rig_float(&"get_zoom_normalized", 0.5)


func update_pinch(ratio: float) -> void:
	if not input_enabled or not is_finite(ratio) or ratio <= 0.0:
		return
	if not _pinch_active:
		begin_pinch(ratio)
	var relative_ratio: float = ratio / _pinch_start_ratio
	gesture_zoom_requested.emit(relative_ratio, _pinch_zoom_at_start)
	var zoom_direction: float = -1.0 if not preferences.invert_zoom else 1.0
	var target_zoom: float = clampf(
		_pinch_zoom_at_start
			+ log(relative_ratio) * pinch_normalized_scale * preferences.zoom_sensitivity * zoom_direction,
		0.0,
		1.0
	)
	_call_rig(&"set_zoom_normalized", [target_zoom])


func end_pinch() -> void:
	_pinch_active = false
	_pinch_start_ratio = 1.0


func begin_twist(angle_radians: float = 0.0) -> void:
	if not input_enabled or not is_finite(angle_radians):
		return
	_mark_activity()
	_twist_active = true
	_twist_start_angle = angle_radians
	_twist_last_angle = angle_radians
	_twist_heading_at_start = _read_rig_float(&"get_heading", 0.0)


func update_twist(angle_radians: float) -> void:
	if not input_enabled or not is_finite(angle_radians):
		return
	if not _twist_active:
		begin_twist(angle_radians)
	var from_start: float = wrapf(angle_radians - _twist_start_angle, -PI, PI)
	var frame_delta: float = wrapf(angle_radians - _twist_last_angle, -PI, PI)
	_twist_last_angle = angle_radians
	gesture_twist_requested.emit(from_start, _twist_heading_at_start)
	var scaled_delta: float = frame_delta * preferences.horizontal_sensitivity
	if preferences.invert_horizontal:
		scaled_delta = -scaled_delta
	if not _call_rig(&"orbit_by_radians", [Vector2(scaled_delta, 0.0)]):
		_call_rig(&"look_by_delta", [Vector2(scaled_delta, 0.0)])


func end_twist() -> void:
	_twist_active = false
	_twist_start_angle = 0.0
	_twist_last_angle = 0.0


func _scale_look(value: Vector2) -> Vector2:
	var multiplier: Vector2 = Vector2(
		preferences.horizontal_sensitivity,
		preferences.vertical_sensitivity
	)
	if preferences.invert_horizontal:
		multiplier.x = -multiplier.x
	if preferences.invert_vertical:
		multiplier.y = -multiplier.y
	return value * multiplier


func _scale_zoom(value: float) -> float:
	var result: float = value * preferences.zoom_sensitivity
	return -result if preferences.invert_zoom else result


func _call_rig(method: StringName, arguments: Array = []) -> bool:
	if not is_instance_valid(camera_rig) or not camera_rig.has_method(method):
		return false
	camera_rig.callv(method, arguments)
	return true


func _read_rig_float(method: StringName, fallback: float) -> float:
	if not is_instance_valid(camera_rig) or not camera_rig.has_method(method):
		return fallback
	var result: Variant = camera_rig.call(method)
	return float(result) if result is float or result is int else fallback


func _mark_activity() -> void:
	_idle_seconds = 0.0
	_auto_recenter_fired = false


func _apply_motion_intensity() -> void:
	if is_instance_valid(camera_rig) and camera_rig.has_method(&"set_motion_intensity"):
		camera_rig.call(&"set_motion_intensity", preferences.motion_intensity)
