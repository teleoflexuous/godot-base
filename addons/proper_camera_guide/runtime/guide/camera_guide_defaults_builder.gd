class_name ProperCameraGuideDefaultsBuilder
extends RefCounted

const CATEGORY: String = "Camera"


static func build() -> ProperCameraGuideDefaults:
	var result: ProperCameraGuideDefaults = ProperCameraGuideDefaults.new()
	result.actions = _build_actions()
	result.keyboard_context = _build_keyboard_context(result.actions)
	result.mouse_context = _build_mouse_context(result.actions)
	result.gamepad_context = _build_gamepad_context(result.actions)
	result.touch_context = _build_touch_context(result.actions)
	result.context_set = ProperCameraGuideContextSet.new()
	result.context_set.keyboard_contexts = [result.keyboard_context]
	result.context_set.mouse_contexts = [result.mouse_context]
	result.context_set.gamepad_contexts = [result.gamepad_context]
	result.context_set.touch_contexts = [result.touch_context]
	return result


static func _build_actions() -> ProperCameraGuideActions:
	var actions: ProperCameraGuideActions = ProperCameraGuideActions.new()
	actions.pan_rate = _action(&"camera_pan_rate", GUIDEAction.GUIDEActionValueType.AXIS_2D, true, "Pan")
	actions.look_rate = _action(&"camera_look_rate", GUIDEAction.GUIDEActionValueType.AXIS_2D, true, "Look")
	actions.zoom_rate = _action(&"camera_zoom_rate", GUIDEAction.GUIDEActionValueType.AXIS_1D, true, "Continuous zoom")
	actions.pan_delta = _action(&"camera_pan_delta", GUIDEAction.GUIDEActionValueType.AXIS_2D, false, "Pointer pan")
	actions.touch_pan_delta = _action(&"camera_touch_pan_delta", GUIDEAction.GUIDEActionValueType.AXIS_2D, false, "Touch pan")
	actions.look_delta = _action(&"camera_look_delta", GUIDEAction.GUIDEActionValueType.AXIS_2D, false, "Pointer look")
	actions.pointer_position = _action(&"camera_pointer_position", GUIDEAction.GUIDEActionValueType.AXIS_2D, false, "Pointer")
	actions.touch_pointer_position = _action(
		&"camera_touch_pointer_position",
		GUIDEAction.GUIDEActionValueType.AXIS_2D,
		false,
		"Touch pointer"
	)
	actions.drag_pan = _action(&"camera_drag_pan", GUIDEAction.GUIDEActionValueType.BOOL, true, "Drag to pan")
	actions.drag_look = _action(&"camera_drag_look", GUIDEAction.GUIDEActionValueType.BOOL, true, "Drag to look")
	actions.pinch_ratio = _action(&"camera_pinch_ratio", GUIDEAction.GUIDEActionValueType.AXIS_1D, false, "Pinch zoom")
	actions.twist_angle = _action(&"camera_twist_angle", GUIDEAction.GUIDEActionValueType.AXIS_1D, false, "Twist")
	actions.zoom_step = _action(&"camera_zoom_step", GUIDEAction.GUIDEActionValueType.AXIS_1D, true, "Zoom step")
	actions.rotation_step = _action(&"camera_rotation_step", GUIDEAction.GUIDEActionValueType.AXIS_1D, true, "Rotate step")
	actions.fast_pan = _action(&"camera_fast_pan", GUIDEAction.GUIDEActionValueType.BOOL, true, "Fast pan")
	actions.recenter = _action(&"camera_recenter", GUIDEAction.GUIDEActionValueType.BOOL, true, "Recenter")
	actions.follow_toggle = _action(&"camera_follow_toggle", GUIDEAction.GUIDEActionValueType.BOOL, true, "Toggle follow")
	actions.view_toggle = _action(&"camera_view_toggle", GUIDEAction.GUIDEActionValueType.BOOL, true, "Toggle view")
	return actions


static func _build_keyboard_context(actions: ProperCameraGuideActions) -> GUIDEMappingContext:
	var context: GUIDEMappingContext = _context("Camera — Keyboard")
	context.mappings = [
		_action_mapping(actions.pan_rate, [
			_key_axis(KEY_A, Vector2.LEFT, "Pan left"),
			_key_axis(KEY_D, Vector2.RIGHT, "Pan right"),
			_key_axis(KEY_W, Vector2.UP, "Pan up"),
			_key_axis(KEY_S, Vector2.DOWN, "Pan down"),
		]),
		_action_mapping(actions.look_rate, [
			_key_axis(KEY_LEFT, Vector2.LEFT, "Look left"),
			_key_axis(KEY_RIGHT, Vector2.RIGHT, "Look right"),
			_key_axis(KEY_UP, Vector2.UP, "Look up"),
			_key_axis(KEY_DOWN, Vector2.DOWN, "Look down"),
		]),
		_action_mapping(actions.zoom_rate, [
			_key_axis_1d(KEY_Q, 1.0, "Zoom in"),
			_key_axis_1d(KEY_E, -1.0, "Zoom out"),
		]),
		_action_mapping(actions.fast_pan, [_key_button(KEY_SHIFT, "Fast pan")]),
		_action_mapping(actions.recenter, [_key_button(KEY_R, "Recenter")]),
		_action_mapping(actions.follow_toggle, [_key_button(KEY_F, "Toggle follow")]),
		_action_mapping(actions.view_toggle, [_key_button(KEY_V, "Toggle view")]),
		_action_mapping(actions.rotation_step, [
			_key_axis_1d(KEY_Z, -1.0, "Rotate left"),
			_key_axis_1d(KEY_C, 1.0, "Rotate right"),
		]),
	]
	return context


static func _build_mouse_context(actions: ProperCameraGuideActions) -> GUIDEMappingContext:
	var context: GUIDEMappingContext = _context("Camera — Mouse")
	var mouse_axis: GUIDEInputMouseAxis2D = GUIDEInputMouseAxis2D.new()
	var second_mouse_axis: GUIDEInputMouseAxis2D = GUIDEInputMouseAxis2D.new()
	context.mappings = [
		_action_mapping(actions.pan_delta, [_fixed_mapping(mouse_axis)]),
		_action_mapping(actions.look_delta, [_fixed_mapping(second_mouse_axis)]),
		_action_mapping(actions.pointer_position, [_fixed_mapping(GUIDEInputMousePosition.new())]),
		_action_mapping(actions.drag_pan, [
			_mouse_button(MOUSE_BUTTON_MIDDLE, "Drag to pan"),
		]),
		_action_mapping(actions.drag_look, [
			_mouse_button(MOUSE_BUTTON_RIGHT, "Drag to look"),
		]),
		_action_mapping(actions.zoom_step, [
			_mouse_axis_button(MOUSE_BUTTON_WHEEL_UP, 1.0, "Zoom in"),
			_mouse_axis_button(MOUSE_BUTTON_WHEEL_DOWN, -1.0, "Zoom out"),
		]),
	]
	return context


static func _build_gamepad_context(actions: ProperCameraGuideActions) -> GUIDEMappingContext:
	var context: GUIDEMappingContext = _context("Camera — Gamepad")
	var left_stick: GUIDEInputJoyAxis2D = GUIDEInputJoyAxis2D.new()
	left_stick.x = JOY_AXIS_LEFT_X
	left_stick.y = JOY_AXIS_LEFT_Y
	var right_stick: GUIDEInputJoyAxis2D = GUIDEInputJoyAxis2D.new()
	right_stick.x = JOY_AXIS_RIGHT_X
	right_stick.y = JOY_AXIS_RIGHT_Y
	context.mappings = [
		_action_mapping(actions.pan_rate, [_remappable_mapping(left_stick, "Pan")]),
		_action_mapping(actions.look_rate, [_remappable_mapping(right_stick, "Look")]),
		_action_mapping(actions.zoom_rate, [
			_joy_axis_1d(JOY_AXIS_TRIGGER_RIGHT, 1.0, "Zoom in"),
			_joy_axis_1d(JOY_AXIS_TRIGGER_LEFT, -1.0, "Zoom out"),
		]),
		_action_mapping(actions.recenter, [_joy_button(JOY_BUTTON_RIGHT_STICK, "Recenter")]),
		_action_mapping(actions.follow_toggle, [_joy_button(JOY_BUTTON_X, "Toggle follow")]),
		_action_mapping(actions.view_toggle, [_joy_button(JOY_BUTTON_Y, "Toggle view")]),
		_action_mapping(actions.rotation_step, [
			_joy_axis_button(JOY_BUTTON_LEFT_SHOULDER, -1.0, "Rotate left"),
			_joy_axis_button(JOY_BUTTON_RIGHT_SHOULDER, 1.0, "Rotate right"),
		]),
	]
	return context


static func _build_touch_context(actions: ProperCameraGuideActions) -> GUIDEMappingContext:
	var context: GUIDEMappingContext = _context("Camera — Touch")
	var pan: GUIDEInputTouchAxis2D = GUIDEInputTouchAxis2D.new()
	pan.finger_count = 1
	pan.finger_index = 0
	var pointer: GUIDEInputTouchPosition = GUIDEInputTouchPosition.new()
	pointer.finger_count = 1
	pointer.finger_index = 0
	var angle: GUIDEInputTouchAngle = GUIDEInputTouchAngle.new()
	angle.unit = GUIDEInputTouchAngle.AngleUnit.RADIANS
	context.mappings = [
		_action_mapping(actions.touch_pan_delta, [_fixed_mapping(pan)]),
		_action_mapping(actions.touch_pointer_position, [_fixed_mapping(pointer)]),
		_action_mapping(actions.pinch_ratio, [_fixed_mapping(GUIDEInputTouchDistance.new())]),
		_action_mapping(actions.twist_angle, [_fixed_mapping(angle)]),
	]
	return context


static func _action(
	name: StringName,
	value_type: GUIDEAction.GUIDEActionValueType,
	remappable: bool,
	display_name: String
) -> GUIDEAction:
	var action: GUIDEAction = GUIDEAction.new()
	action.name = name
	action.action_value_type = value_type
	action.block_lower_priority_actions = false
	action.is_remappable = remappable
	action.display_name = display_name
	action.display_category = CATEGORY
	return action


static func _context(display_name: String) -> GUIDEMappingContext:
	var context: GUIDEMappingContext = GUIDEMappingContext.new()
	context.display_name = display_name
	return context


static func _action_mapping(action: GUIDEAction, mappings: Array[GUIDEInputMapping]) -> GUIDEActionMapping:
	var mapping: GUIDEActionMapping = GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings = mappings
	return mapping


static func _key_button(key: Key, display_name: String) -> GUIDEInputMapping:
	var input: GUIDEInputKey = GUIDEInputKey.new()
	input.key = key
	return _remappable_mapping(input, display_name)


static func _key_axis(key: Key, direction: Vector2, display_name: String) -> GUIDEInputMapping:
	var mapping: GUIDEInputMapping = _key_button(key, display_name)
	mapping.modifiers = _axis_2d_modifiers(direction)
	return mapping


static func _key_axis_1d(key: Key, scale: float, display_name: String) -> GUIDEInputMapping:
	var mapping: GUIDEInputMapping = _key_button(key, display_name)
	mapping.modifiers = [_scale_modifier(Vector3(scale, 1.0, 1.0))]
	return mapping


static func _mouse_button(button: MouseButton, display_name: String) -> GUIDEInputMapping:
	var input: GUIDEInputMouseButton = GUIDEInputMouseButton.new()
	input.button = button
	return _remappable_mapping(input, display_name)


static func _mouse_axis_button(
	button: MouseButton,
	scale: float,
	display_name: String
) -> GUIDEInputMapping:
	var mapping: GUIDEInputMapping = _mouse_button(button, display_name)
	mapping.modifiers = [_scale_modifier(Vector3(scale, 1.0, 1.0))]
	return mapping


static func _joy_button(button: JoyButton, display_name: String) -> GUIDEInputMapping:
	var input: GUIDEInputJoyButton = GUIDEInputJoyButton.new()
	input.button = button
	return _remappable_mapping(input, display_name)


static func _joy_axis_button(
	button: JoyButton,
	scale: float,
	display_name: String
) -> GUIDEInputMapping:
	var mapping: GUIDEInputMapping = _joy_button(button, display_name)
	mapping.modifiers = [_scale_modifier(Vector3(scale, 1.0, 1.0))]
	return mapping


static func _joy_axis_1d(axis: JoyAxis, scale: float, display_name: String) -> GUIDEInputMapping:
	var input: GUIDEInputJoyAxis1D = GUIDEInputJoyAxis1D.new()
	input.axis = axis
	var mapping: GUIDEInputMapping = _remappable_mapping(input, display_name)
	mapping.modifiers = [_scale_modifier(Vector3(scale, 1.0, 1.0))]
	return mapping


static func _fixed_mapping(input: GUIDEInput) -> GUIDEInputMapping:
	var mapping: GUIDEInputMapping = GUIDEInputMapping.new()
	mapping.input = input
	mapping.override_action_settings = true
	mapping.is_remappable = false
	return mapping


static func _remappable_mapping(input: GUIDEInput, display_name: String) -> GUIDEInputMapping:
	var mapping: GUIDEInputMapping = GUIDEInputMapping.new()
	mapping.input = input
	mapping.override_action_settings = true
	mapping.is_remappable = true
	mapping.display_name = display_name
	mapping.display_category = CATEGORY
	return mapping


static func _axis_2d_modifiers(direction: Vector2) -> Array[GUIDEModifier]:
	var modifiers: Array[GUIDEModifier] = []
	if not is_zero_approx(direction.y):
		var swizzle: GUIDEModifierInputSwizzle = GUIDEModifierInputSwizzle.new()
		swizzle.order = GUIDEModifierInputSwizzle.GUIDEInputSwizzleOperation.YXZ
		modifiers.append(swizzle)
	modifiers.append(_scale_modifier(Vector3(direction.x, direction.y, 1.0)))
	return modifiers


static func _scale_modifier(scale: Vector3) -> GUIDEModifierScale:
	var modifier: GUIDEModifierScale = GUIDEModifierScale.new()
	modifier.scale = scale
	# ProperCameraInputAdapter applies delta to rate actions and never to device deltas.
	modifier.apply_delta_time = false
	return modifier
