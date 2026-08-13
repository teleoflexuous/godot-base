class_name CameraGuideAdapter
extends CameraInputAdapter

@export var actions: CameraGuideActions
@export_range(1.0, 10.0, 0.1) var fast_pan_multiplier: float = 2.0

var _button_states: Dictionary = {}


func _process(delta: float) -> void:
	if not input_enabled or actions == null:
		return
	var pan: Vector2 = _axis_2d(actions.pan_rate)
	if _bool_value(actions.fast_pan):
		pan *= fast_pan_multiplier
	submit_pan_rate(pan, delta)
	submit_look_rate(_axis_2d(actions.look_rate), delta)
	submit_zoom_rate(_axis_1d(actions.zoom_rate), delta)

	var pan_delta: Vector2 = _axis_2d(actions.pan_delta)
	if actions.drag_pan == null or _bool_value(actions.drag_pan):
		submit_pan_delta(pan_delta)
	submit_pan_delta(_axis_2d(actions.touch_pan_delta))
	var look_delta: Vector2 = _axis_2d(actions.look_delta)
	if actions.drag_look == null or _bool_value(actions.drag_look):
		submit_look_delta(look_delta)
	var touch_pointer: Vector2 = _axis_2d(actions.touch_pointer_position)
	var pointer: Vector2 = touch_pointer if touch_pointer.is_finite() else _axis_2d(actions.pointer_position)
	if pointer.is_finite():
		submit_pointer_position(pointer)

	_poll_pinch()
	_poll_twist()
	if _rising(actions.zoom_step):
		submit_zoom_steps(_axis_1d(actions.zoom_step))
	if _rising(actions.rotation_step):
		submit_rotation_step(_axis_1d(actions.rotation_step))
	if _rising(actions.recenter):
		submit_recenter()
	if _rising(actions.follow_toggle):
		submit_follow_toggle()
	if _rising(actions.view_toggle):
		submit_view_toggle()


func clear_input_state() -> void:
	super.clear_input_state()
	_button_states.clear()


func _poll_pinch() -> void:
	var action: GUIDEAction = actions.pinch_ratio
	var ratio: float = _axis_1d(action)
	if is_finite(ratio) and ratio > 0.0:
		if not _pinch_active:
			begin_pinch(ratio)
		update_pinch(ratio)
	elif _pinch_active:
		end_pinch()


func _poll_twist() -> void:
	var action: GUIDEAction = actions.twist_angle
	if _pinch_active and action != null and is_finite(_axis_1d(action)):
		var angle: float = _axis_1d(action)
		if not _twist_active:
			begin_twist(angle)
		update_twist(angle)
	elif _twist_active:
		end_twist()


func _rising(action: GUIDEAction) -> bool:
	if action == null:
		return false
	var key: int = action.get_instance_id()
	var active: bool = _bool_value(action)
	var previous: bool = bool(_button_states.get(key, false))
	_button_states[key] = active
	return active and not previous


func _bool_value(action: GUIDEAction) -> bool:
	return action != null and action.value_bool


func _axis_1d(action: GUIDEAction) -> float:
	return action.value_axis_1d if action != null else 0.0


func _axis_2d(action: GUIDEAction) -> Vector2:
	return action.value_axis_2d if action != null else Vector2.ZERO
