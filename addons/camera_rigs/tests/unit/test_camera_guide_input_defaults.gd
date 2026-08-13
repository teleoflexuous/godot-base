extends GutTest


class PointerRig:
	extends Node

	var pointer: Vector2 = Vector2.INF

	func set_pointer_position(value: Vector2) -> void:
		pointer = value


func test_builder_creates_mergeable_device_contexts_and_typed_actions() -> void:
	var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
	assert_not_null(defaults.actions)
	assert_eq(defaults.all_contexts().size(), 4)
	assert_eq(
		defaults.actions.pan_rate.action_value_type,
		GUIDEAction.GUIDEActionValueType.AXIS_2D
	)
	assert_eq(
		defaults.actions.zoom_rate.action_value_type,
		GUIDEAction.GUIDEActionValueType.AXIS_1D
	)
	assert_eq(defaults.actions.recenter.action_value_type, GUIDEAction.GUIDEActionValueType.BOOL)
	for action: GUIDEAction in defaults.actions.all_actions():
		assert_false(action.block_lower_priority_actions)


func test_keyboard_button_composed_axes_have_remapping_overrides() -> void:
	var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
	var pan_mapping: GUIDEActionMapping = _find_mapping(defaults.keyboard_context, defaults.actions.pan_rate)
	assert_not_null(pan_mapping)
	assert_eq(pan_mapping.input_mappings.size(), 4)
	for input_mapping: GUIDEInputMapping in pan_mapping.input_mappings:
		assert_true(input_mapping.override_action_settings)
		assert_true(input_mapping.is_remappable)
		assert_false(input_mapping.display_name.is_empty())
		assert_eq(input_mapping.display_category, "Camera")
		for modifier: GUIDEModifier in input_mapping.modifiers:
			if modifier is GUIDEModifierScale:
				assert_false((modifier as GUIDEModifierScale).apply_delta_time)


func test_mouse_wheel_axis_directions_are_individually_remappable() -> void:
	var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
	var zoom_mapping: GUIDEActionMapping = _find_mapping(defaults.mouse_context, defaults.actions.zoom_step)
	assert_not_null(zoom_mapping)
	assert_eq(zoom_mapping.input_mappings.size(), 2)
	for input_mapping: GUIDEInputMapping in zoom_mapping.input_mappings:
		assert_true(input_mapping.input is GUIDEInputMouseButton)
		assert_true(input_mapping.override_action_settings)
		assert_true(input_mapping.is_remappable)


func test_touch_gestures_are_present_but_fixed() -> void:
	var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
	assert_not_null(_find_mapping(defaults.touch_context, defaults.actions.touch_pan_delta))
	assert_not_null(_find_mapping(defaults.touch_context, defaults.actions.pinch_ratio))
	assert_not_null(_find_mapping(defaults.touch_context, defaults.actions.twist_angle))
	assert_not_null(_find_mapping(defaults.touch_context, defaults.actions.touch_pointer_position))
	for action_mapping: GUIDEActionMapping in defaults.touch_context.mappings:
		for input_mapping: GUIDEInputMapping in action_mapping.input_mappings:
			assert_true(input_mapping.override_action_settings)
			assert_false(input_mapping.is_remappable)


func test_context_set_selects_all_enabled_device_families() -> void:
	var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
	var desktop_contexts: Array[GUIDEMappingContext] = defaults.context_set.contexts_for_mask(
		CameraGuideContextSet.KEYBOARD | CameraGuideContextSet.MOUSE
	)
	assert_eq(desktop_contexts.size(), 2)
	assert_true(desktop_contexts.has(defaults.keyboard_context))
	assert_true(desktop_contexts.has(defaults.mouse_context))
	assert_eq(defaults.context_set.contexts_for_mask(CameraGuideContextSet.TOUCH).size(), 1)


func test_remapper_exposes_player_bindings_but_not_fixed_touch_gestures() -> void:
	var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
	var remapper: GUIDERemapper = GUIDERemapper.new()
	remapper.initialize(defaults.all_contexts(), GUIDERemappingConfig.new())
	var items: Array[GUIDERemapper.ConfigItem] = remapper.get_remappable_items()
	assert_gt(items.size(), 0)
	for item: GUIDERemapper.ConfigItem in items:
		assert_ne(item.context, defaults.touch_context)


func test_guide_adapter_gives_active_touch_pointer_ownership() -> void:
	var actions: CameraGuideActions = CameraGuideActions.new()
	actions.pointer_position = GUIDEAction.new()
	actions.pointer_position.action_value_type = GUIDEAction.GUIDEActionValueType.AXIS_2D
	actions.touch_pointer_position = GUIDEAction.new()
	actions.touch_pointer_position.action_value_type = GUIDEAction.GUIDEActionValueType.AXIS_2D
	actions.pointer_position._update_value(Vector3(100.0, 50.0, 0.0))
	actions.touch_pointer_position._update_value(Vector3.INF)
	var adapter: CameraGuideAdapter = CameraGuideAdapter.new()
	var rig: PointerRig = PointerRig.new()
	adapter.actions = actions
	adapter.camera_rig = rig
	adapter._process(0.016)
	assert_eq(rig.pointer, Vector2(100.0, 50.0))
	actions.touch_pointer_position._update_value(Vector3(20.0, 30.0, 0.0))
	adapter._process(0.016)
	assert_eq(rig.pointer, Vector2(20.0, 30.0))
	adapter.free()
	rig.free()


func _find_mapping(context: GUIDEMappingContext, action: GUIDEAction) -> GUIDEActionMapping:
	for mapping: GUIDEActionMapping in context.mappings:
		if mapping.action == action:
			return mapping
	return null
