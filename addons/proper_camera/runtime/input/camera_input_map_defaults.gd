class_name ProperCameraInputMapDefaults
extends RefCounted

## Opt-in defaults for demos and small projects. Production projects normally
## declare these actions in project.godot and leave the adapter option off.

static func ensure_missing_actions(actions: ProperCameraInputMapActions = null) -> void:
	var surface: ProperCameraInputMapActions = actions if actions != null else ProperCameraInputMapActions.new()
	_add_key_action(surface.pan_left, KEY_A)
	_add_key_action(surface.pan_right, KEY_D)
	_add_key_action(surface.pan_up, KEY_W)
	_add_key_action(surface.pan_down, KEY_S)
	_add_key_action(surface.look_left, KEY_LEFT)
	_add_key_action(surface.look_right, KEY_RIGHT)
	_add_key_action(surface.look_up, KEY_UP)
	_add_key_action(surface.look_down, KEY_DOWN)
	_add_key_action(surface.zoom_in_rate, KEY_EQUAL)
	_add_key_action(surface.zoom_out_rate, KEY_MINUS)
	_add_key_action(surface.zoom_in_step, KEY_KP_ADD)
	_add_key_action(surface.zoom_out_step, KEY_KP_SUBTRACT)
	_add_key_action(surface.fast_pan, KEY_SHIFT)
	_add_key_action(surface.recenter, KEY_R)
	_add_key_action(surface.follow_toggle, KEY_F)
	_add_key_action(surface.view_toggle, KEY_V)
	_add_key_action(surface.rotate_left, KEY_Q)
	_add_key_action(surface.rotate_right, KEY_E)
	_add_mouse_action(surface.pan_drag, MOUSE_BUTTON_MIDDLE)
	_add_mouse_action(surface.look_drag, MOUSE_BUTTON_RIGHT)


static func _add_key_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


static func _add_mouse_action(action: StringName, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
