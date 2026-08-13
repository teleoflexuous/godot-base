extends GutTest


class FakeRig:
	extends Node

	var calls: Array[Dictionary] = []
	var zoom_normalized: float = 0.6

	func look_direction(value: Vector2, delta: float) -> void:
		calls.append({"method": &"look_direction", "value": value, "delta": delta})

	func pan_by_screen(value: Vector2) -> void:
		calls.append({"method": &"pan_by_screen", "value": value})

	func zoom_by_steps(value: float) -> void:
		calls.append({"method": &"zoom_by_steps", "value": value})

	func set_zoom_normalized(value: float) -> void:
		zoom_normalized = value
		calls.append({"method": &"set_zoom_normalized", "value": value})

	func get_zoom_normalized() -> float:
		return zoom_normalized


func test_look_rate_forwards_zero_so_held_peek_can_clear() -> void:
	var adapter: ProperCameraInputAdapter = ProperCameraInputAdapter.new()
	var rig: FakeRig = FakeRig.new()
	adapter.camera_rig = rig
	adapter.submit_look_rate(Vector2.ZERO, 0.25)
	assert_eq(rig.calls.size(), 1)
	assert_eq(rig.calls[0]["method"], &"look_direction")
	assert_eq(rig.calls[0]["value"], Vector2.ZERO)
	adapter.free()
	rig.free()


func test_device_delta_is_not_multiplied_by_frame_delta() -> void:
	var adapter: ProperCameraInputAdapter = ProperCameraInputAdapter.new()
	var rig: FakeRig = FakeRig.new()
	adapter.camera_rig = rig
	adapter.submit_pan_delta(Vector2(12.0, -4.0))
	assert_eq(rig.calls[0]["value"], Vector2(12.0, -4.0))
	adapter.free()
	rig.free()


func test_input_map_drag_defaults_to_grab_the_world_semantics() -> void:
	var adapter: ProperCameraInputMapAdapter = ProperCameraInputMapAdapter.new()
	assert_false(adapter.invert_pointer_pan)
	adapter.free()


func test_preferences_scale_and_invert_semantic_values() -> void:
	var adapter: ProperCameraInputAdapter = ProperCameraInputAdapter.new()
	var rig: FakeRig = FakeRig.new()
	var prefs: ProperCameraUserPreferences = ProperCameraUserPreferences.new()
	prefs.horizontal_sensitivity = 2.0
	prefs.vertical_sensitivity = 3.0
	prefs.invert_vertical = true
	prefs.zoom_sensitivity = 0.5
	prefs.invert_zoom = true
	adapter.camera_rig = rig
	adapter.preferences = prefs
	adapter.submit_look_rate(Vector2.ONE, 0.1)
	adapter.submit_zoom_steps(2.0)
	assert_eq(rig.calls[0]["value"], Vector2(2.0, -3.0))
	assert_eq(rig.calls[1]["value"], -1.0)
	adapter.free()
	rig.free()


func test_pinch_uses_gesture_start_zoom_instead_of_accumulating() -> void:
	var adapter: ProperCameraInputAdapter = ProperCameraInputAdapter.new()
	var rig: FakeRig = FakeRig.new()
	adapter.camera_rig = rig
	adapter.pinch_normalized_scale = 0.25
	adapter.begin_pinch(1.0)
	adapter.update_pinch(2.0)
	var first_value: float = rig.zoom_normalized
	adapter.update_pinch(2.0)
	assert_almost_eq(rig.zoom_normalized, first_value, 0.00001)
	assert_lt(rig.zoom_normalized, 0.6, "Spreading fingers zooms in by default.")
	adapter.free()
	rig.free()


func test_camera_preferences_sanitize_accessibility_ranges() -> void:
	var prefs: ProperCameraUserPreferences = ProperCameraUserPreferences.new()
	prefs.horizontal_sensitivity = -10.0
	prefs.preferred_fov_degrees = 250.0
	prefs.motion_intensity = 2.0
	prefs.sanitize()
	assert_eq(prefs.horizontal_sensitivity, ProperCameraUserPreferences.MIN_SENSITIVITY)
	assert_eq(prefs.preferred_fov_degrees, 179.0)
	assert_eq(prefs.motion_intensity, 1.0)
