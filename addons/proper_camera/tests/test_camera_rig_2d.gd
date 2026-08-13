extends GutTest

const RIG_SCENE: PackedScene = preload("res://addons/proper_camera/scenes/camera_rig_2d.tscn")


class PhantomBridgeDouble:
	extends Node

	var applied_target: Node
	var applied_offset: Vector2 = Vector2.ZERO
	var applied_zoom: Vector2 = Vector2.ONE
	var applied_focus: Transform2D = Transform2D.IDENTITY

	func apply_2d(target: Node, follow_offset: Vector2, zoom: Vector2) -> bool:
		applied_target = target
		applied_offset = follow_offset
		applied_zoom = zoom
		return true

	func apply_focus_transform_2d(focus_transform: Transform2D) -> void:
		applied_focus = focus_transform


func test_scene_has_scene_first_camera_and_effect_pivots() -> void:
	var rig: ProperCameraRig2D = RIG_SCENE.instantiate() as ProperCameraRig2D
	add_child_autofree(rig)
	await get_tree().process_frame
	assert_not_null(rig.get_camera())
	assert_not_null(rig.get_effect_pivot())
	assert_eq(rig.get_camera().get_parent(), rig.get_effect_pivot())


func test_positive_zoom_steps_zoom_in_and_pointer_anchor_stays_fixed() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.bounds_enabled = false
	local_preset.zoom_enabled = true
	local_preset.zoom_anchor = ProperCameraRigTypes.ZoomAnchor.POINTER_WORLD_HIT
	rig.apply_preset(local_preset)
	rig.set_zoom_normalized(1.0, true)

	var pointer: Vector2 = rig.get_view_metrics()[&"viewport_size"] * 0.5 + Vector2(140.0, 70.0)
	rig.set_pointer_position(pointer)
	var world_before: Vector2 = rig.viewport_to_world(pointer)
	rig.zoom_by_steps(1.0)
	rig._process(1.0)
	var world_after: Vector2 = rig.viewport_to_world(pointer)

	assert_lt(rig.get_zoom_normalized(), 1.0, "Positive zoom input moves toward the close end.")
	assert_almost_eq(world_after.x, world_before.x, 0.01)
	assert_almost_eq(world_after.y, world_before.y, 0.01)


func test_bounds_include_the_visible_viewport_footprint() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.bounds_enabled = true
	local_preset.bounds = Rect2(Vector2.ZERO, Vector2(2000.0, 2000.0))
	local_preset.bounds_margin = Vector2(10.0, 20.0)
	rig.apply_preset(local_preset)
	rig.set_zoom_normalized(0.0, true)
	rig.set_focus_position(Vector2(-500.0, -500.0), true)

	var metrics: Dictionary = rig.get_view_metrics()
	var half_view: Vector2 = metrics[&"visible_world_size"] * 0.5
	var center: Vector2 = metrics[&"focus_position"]
	assert_almost_eq(center.x, half_view.x + 10.0, 0.01)
	assert_almost_eq(center.y, half_view.y + 20.0, 0.01)


func test_follow_interruption_policies_are_distinct() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.follow_smoothing_speed = 0.0
	local_preset.look_ahead_distance = Vector2.ZERO
	local_preset.dead_zone = Vector2.ZERO
	local_preset.pan_enabled = true
	local_preset.bounds_enabled = false
	rig.apply_preset(local_preset)
	var target := Node2D.new()
	target.global_position = Vector2(300.0, 200.0)
	add_child_autofree(target)

	local_preset.follow_interruption = ProperCameraRigTypes.FollowInterruption.OFFSET_WHILE_FOLLOWING
	rig.set_follow_target(target, true)
	rig.pan_by_world(Vector2(25.0, 0.0))
	rig._process(1.0 / 60.0)
	assert_true(rig.is_following())
	assert_almost_eq(rig.get_view_metrics()[&"focus_position"].x, 325.0, 0.01)

	local_preset.follow_interruption = ProperCameraRigTypes.FollowInterruption.HARD_LOCK
	rig.recenter()
	rig.snap_to_target()
	var before_hard_lock: Vector2 = rig.get_view_metrics()[&"focus_position"]
	rig.pan_by_world(Vector2(50.0, 0.0))
	rig._process(1.0 / 60.0)
	assert_eq(rig.get_view_metrics()[&"focus_position"], before_hard_lock)

	local_preset.follow_interruption = ProperCameraRigTypes.FollowInterruption.BREAK_ON_PAN
	rig.pan_by_world(Vector2(10.0, 0.0))
	assert_false(rig.is_following())


func test_recenter_reacquires_and_snaps_a_2d_follow_target() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.follow_interruption = ProperCameraRigTypes.FollowInterruption.BREAK_ON_PAN
	local_preset.follow_smoothing_speed = 10.0
	local_preset.look_ahead_distance = Vector2.ZERO
	local_preset.dead_zone = Vector2.ZERO
	local_preset.bounds_enabled = false
	rig.apply_preset(local_preset)
	var target: Node2D = Node2D.new()
	target.global_position = Vector2(320.0, -120.0)
	add_child_autofree(target)
	rig.set_follow_target(target, true)
	rig.pan_by_world(Vector2(90.0, 0.0))
	assert_false(rig.is_following())
	rig.recenter()
	assert_true(rig.is_following())
	assert_eq(rig.get_view_metrics()[&"focus_position"], target.global_position)


func test_toggle_follow_centers_then_tracks_a_moving_and_stationary_target() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.follow_enabled = false
	local_preset.follow_smoothing_speed = 0.0
	local_preset.look_ahead_distance = Vector2.ZERO
	local_preset.dead_zone = Vector2.ZERO
	local_preset.bounds_enabled = false
	rig.apply_preset(local_preset)
	var target := Node2D.new()
	target.global_position = Vector2(160.0, -90.0)
	add_child_autofree(target)
	rig.set_follow_target(target, false)
	rig.set_following(false)
	rig.set_focus_position(Vector2(-300.0, 240.0), true)

	# This is the same physical InputMap event used by the management demo.
	var adapter := ProperCameraInputMapAdapter.new()
	adapter.install_missing_actions = true
	adapter.camera_rig = rig
	add_child_autofree(adapter)
	await get_tree().process_frame
	var press: InputEventKey = InputMap.action_get_events(&"camera_follow_toggle")[0].duplicate() as InputEventKey
	press.pressed = true
	adapter._unhandled_input(press)
	var release: InputEventKey = press.duplicate() as InputEventKey
	release.pressed = false
	adapter._unhandled_input(release)

	assert_true(rig.is_following())
	assert_eq(rig.get_view_metrics()[&"focus_position"], target.global_position)
	target.global_position += Vector2(75.0, 40.0)
	rig._process(1.0 / 60.0)
	assert_eq(rig.get_view_metrics()[&"focus_position"], target.global_position)
	var parked_center: Vector2 = rig.get_view_metrics()[&"focus_position"]
	for _frame: int in range(120):
		rig._process(1.0 / 60.0)
	assert_eq(rig.get_view_metrics()[&"focus_position"], parked_center)


func test_lost_target_holds_the_last_view_and_emits() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.follow_smoothing_speed = 0.0
	local_preset.look_ahead_distance = Vector2.ZERO
	local_preset.dead_zone = Vector2.ZERO
	local_preset.bounds_enabled = false
	rig.apply_preset(local_preset)
	var target := Node2D.new()
	target.global_position = Vector2(420.0, -75.0)
	add_child(target)
	rig.set_follow_target(target, true)
	var held_center: Vector2 = rig.get_view_metrics()[&"focus_position"]
	watch_signals(rig)
	target.free()
	rig._process(1.0 / 60.0)

	assert_signal_emitted(rig, "target_lost")
	assert_false(rig.is_following())
	assert_eq(rig.get_view_metrics()[&"focus_position"], held_center)


func test_phantom_output_is_exclusive_and_receives_camera_intent() -> void:
	var rig: ProperCameraRig2D = await _create_rig()
	var local_preset: ProperCameraPreset2D = rig.preset.duplicate(true) as ProperCameraPreset2D
	local_preset.follow_interruption = ProperCameraRigTypes.FollowInterruption.OFFSET_WHILE_FOLLOWING
	rig.apply_preset(local_preset)
	var bridge := PhantomBridgeDouble.new()
	rig.add_child(bridge)
	rig.set_phantom_bridge(bridge)
	var target := Node2D.new()
	target.global_position = Vector2(180.0, 90.0)
	add_child_autofree(target)
	rig.set_follow_target(target, true)
	rig.pan_by_world(Vector2(15.0, 0.0))
	rig.set_output_driver(ProperCameraRigTypes.OutputDriver.PHANTOM)
	rig._process(0.0)

	assert_false(rig.get_camera().enabled)
	assert_eq(bridge.applied_target, target)
	assert_almost_eq(bridge.applied_offset.x, 15.0, 0.01)
	assert_eq(bridge.applied_zoom, rig.get_view_metrics()[&"actual_zoom"])
	assert_eq(bridge.applied_focus.origin, rig.get_view_metrics()[&"focus_position"])
	assert_eq(rig.get_motion_effects().process_mode, Node.PROCESS_MODE_DISABLED)

	rig.set_output_driver(ProperCameraRigTypes.OutputDriver.NATIVE)
	assert_true(rig.get_camera().enabled)
	assert_eq(rig.get_motion_effects().process_mode, Node.PROCESS_MODE_INHERIT)


func _create_rig() -> ProperCameraRig2D:
	var rig: ProperCameraRig2D = RIG_SCENE.instantiate() as ProperCameraRig2D
	add_child_autofree(rig)
	await get_tree().process_frame
	return rig
