class_name ProperCameraInputMapAdapter
extends ProperCameraInputAdapter

const INPUT_MAP_DEFAULTS: Script = preload("res://addons/proper_camera/runtime/input/camera_input_map_defaults.gd")

@export var actions: ProperCameraInputMapActions = ProperCameraInputMapActions.new()
## Useful for the included examples or a small standalone prototype. Keep off
## in projects that declare their own portable InputMap contract.
@export var install_missing_actions: bool = false
@export_range(1.0, 10.0, 0.1) var fast_pan_multiplier: float = 2.0
## Rigs interpret raw pointer drag as grabbing the world (drag right moves the
## camera left). Enable only for projects that want scroll-style panning.
@export var invert_pointer_pan: bool = false
@export var captured_mouse_looks_without_hold: bool = true
@export_range(0.01, 100.0, 0.01) var trackpad_pan_scale: float = 8.0

var _touch_positions: Dictionary = {}


func _ready() -> void:
	if install_missing_actions:
		INPUT_MAP_DEFAULTS.ensure_missing_actions(actions)
	super._ready()


func _process(delta: float) -> void:
	if not input_enabled or actions == null:
		return
	var pan: Vector2 = _read_vector(
		actions.pan_left,
		actions.pan_right,
		actions.pan_up,
		actions.pan_down
	)
	if _is_pressed(actions.fast_pan):
		pan *= fast_pan_multiplier
	submit_pan_rate(pan, delta)
	var look: Vector2 = _read_vector(
		actions.look_left,
		actions.look_right,
		actions.look_up,
		actions.look_down
	)
	submit_look_rate(look, delta)
	submit_zoom_rate(
		_strength(actions.zoom_in_rate) - _strength(actions.zoom_out_rate),
		delta
	)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or actions == null:
		return
	if event.is_action_pressed(actions.zoom_in_step):
		submit_zoom_steps(1.0)
	if event.is_action_pressed(actions.zoom_out_step):
		submit_zoom_steps(-1.0)
	if event.is_action_pressed(actions.recenter):
		submit_recenter()
	if event.is_action_pressed(actions.follow_toggle):
		submit_follow_toggle()
	if event.is_action_pressed(actions.view_toggle):
		submit_view_toggle()
	if event.is_action_pressed(actions.rotate_left):
		submit_rotation_step(-1.0)
	if event.is_action_pressed(actions.rotate_right):
		submit_rotation_step(1.0)
	if event is InputEventMouse:
		var mouse_event: InputEventMouse = event
		submit_pointer_position(mouse_event.position)
	if event is InputEventMouseMotion:
		var mouse_motion: InputEventMouseMotion = event
		if _is_pressed(actions.look_drag) \
				or (captured_mouse_looks_without_hold and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
			submit_look_delta(mouse_motion.screen_relative)
		elif _is_pressed(actions.pan_drag):
			var pan_delta: Vector2 = mouse_motion.screen_relative
			if invert_pointer_pan:
				pan_delta = -pan_delta
			submit_pan_delta(pan_delta)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif event is InputEventPanGesture:
		var pan_gesture: InputEventPanGesture = event
		var gesture_delta: Vector2 = pan_gesture.delta * trackpad_pan_scale
		if invert_pointer_pan:
			gesture_delta = -gesture_delta
		submit_pan_delta(gesture_delta)
	elif event is InputEventMagnifyGesture:
		var magnify: InputEventMagnifyGesture = event
		begin_pinch(1.0)
		update_pinch(magnify.factor)
		end_pinch()


func clear_input_state() -> void:
	super.clear_input_state()
	_touch_positions.clear()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_positions[event.index] = event.position
		submit_pointer_position(event.position)
		if _touch_positions.size() == 2:
			_start_touch_gesture()
	else:
		var had_gesture: bool = _touch_positions.size() >= 2
		_touch_positions.erase(event.index)
		if had_gesture:
			end_pinch()
			end_twist()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	_touch_positions[event.index] = event.position
	submit_pointer_position(event.position)
	if _touch_positions.size() >= 2:
		_update_touch_gesture()
	else:
		var pan_delta: Vector2 = event.screen_relative
		if invert_pointer_pan:
			pan_delta = -pan_delta
		submit_pan_delta(pan_delta)


func _start_touch_gesture() -> void:
	var pair: Array[Vector2] = _first_two_touch_positions()
	if pair.size() != 2:
		return
	begin_pinch(pair[0].distance_to(pair[1]))
	begin_twist((pair[1] - pair[0]).angle())


func _update_touch_gesture() -> void:
	var pair: Array[Vector2] = _first_two_touch_positions()
	if pair.size() != 2:
		return
	update_pinch(pair[0].distance_to(pair[1]))
	update_twist((pair[1] - pair[0]).angle())


func _first_two_touch_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for touch_index: int in _touch_positions:
		result.append(_touch_positions[touch_index] as Vector2)
		if result.size() == 2:
			break
	return result


func _read_vector(left: StringName, right: StringName, up: StringName, down: StringName) -> Vector2:
	return Vector2(_strength(right) - _strength(left), _strength(down) - _strength(up)).limit_length()


func _strength(action: StringName) -> float:
	return Input.get_action_strength(action) if _has_action(action) else 0.0


func _is_pressed(action: StringName) -> bool:
	return _has_action(action) and Input.is_action_pressed(action)


func _just_pressed(action: StringName) -> bool:
	return _has_action(action) and Input.is_action_just_pressed(action)


func _has_action(action: StringName) -> bool:
	return not action.is_empty() and InputMap.has_action(action)
