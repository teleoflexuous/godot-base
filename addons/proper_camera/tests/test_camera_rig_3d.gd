extends GutTest

const RIG_SCENE: PackedScene = preload("res://addons/proper_camera/scenes/camera_rig_3d.tscn")

class PhantomBridgeDouble:
	extends Node

	var third_person_calls: int = 0
	var projection_calls: int = 0

	func validate_configuration(_report_error: bool = false) -> bool:
		return true

	func apply_3d_third_person(
			_target: Node,
			_rotation_degrees: Vector3,
			_spring_length: float
	) -> bool:
		third_person_calls += 1
		return true

	func apply_projection(
			_projection: Camera3D.ProjectionType,
			_fov: float,
			_size: float
	) -> bool:
		projection_calls += 1
		return true


func test_scene_uses_pivot_boom_hierarchy_and_direct_camera_child() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var camera: Camera3D = rig.get_camera()
	assert_not_null(camera)
	assert_true(camera.get_parent() is SpringArm3D)
	assert_eq(camera.get_parent().get_parent().name, &"Shoulder")
	assert_eq(camera.get_parent().get_parent().get_parent().name, &"Pitch")
	assert_eq(camera.get_parent().get_parent().get_parent().get_parent().name, &"Yaw")


func test_positive_zoom_steps_move_toward_close_end() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.zoom_enabled = true
	local_preset.zoom_smoothing_speed = 0.0
	local_preset.zoom_step_size = 0.1
	rig.apply_preset(local_preset)
	rig.set_zoom_normalized(0.8, true)
	rig.zoom_by_steps(1.0)
	rig._process(1.0 / 60.0)
	assert_almost_eq(rig.get_zoom_normalized(), 0.7, 0.0001)


func test_pitch_clamps_and_discrete_rotation_works_when_free_look_is_disabled() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.look_enabled = true
	local_preset.min_pitch_degrees = -60.0
	local_preset.max_pitch_degrees = -10.0
	rig.apply_preset(local_preset)
	rig.orbit_by_radians(Vector2(0.0, 100.0))
	var pitch: Node3D = rig.get_node("Focus/Yaw/Pitch") as Node3D
	rig._process(0.0)
	assert_almost_eq(pitch.rotation.x, deg_to_rad(-60.0), 0.0001)

	local_preset.look_enabled = false
	var previous_heading: float = rig.get_heading()
	rig.rotate_step(1.0)
	assert_almost_eq(rig.get_heading(), previous_heading + deg_to_rad(15.0), 0.0001)


func test_follow_loss_holds_last_focus_and_emits_target_lost() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.follow_smoothing_speed = 0.0
	local_preset.target_offset = Vector3.ZERO
	local_preset.bounds_enabled = false
	rig.apply_preset(local_preset)
	var target := Node3D.new()
	add_child(target)
	target.global_position = Vector3(8.0, 3.0, -5.0)
	rig.set_follow_target(target, true)
	var held_focus: Vector3 = rig.get_focus_position()
	watch_signals(rig)
	target.free()
	rig._process(1.0 / 60.0)

	assert_signal_emitted(rig, "target_lost")
	assert_false(rig.is_following())
	assert_eq(rig.get_focus_position(), held_focus)


func test_zoom_blend_view_policy_has_hysteresis_and_two_argument_signal() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.view_policy = ProperCameraRigTypes.ViewPolicy3D.ZOOM_BLEND
	local_preset.first_person_enter_zoom = 0.1
	local_preset.first_person_exit_zoom = 0.2
	rig.apply_preset(local_preset)
	watch_signals(rig)
	rig.set_zoom_normalized(0.05, true)
	assert_eq(rig.get_view_mode(), ProperCameraRigTypes.ViewMode3D.FIRST_PERSON)
	assert_signal_emitted_with_parameters(
		rig,
		"view_mode_changed",
		[ProperCameraRigTypes.ViewMode3D.THIRD_PERSON, ProperCameraRigTypes.ViewMode3D.FIRST_PERSON]
	)
	rig.set_zoom_normalized(0.15, true)
	assert_eq(rig.get_view_mode(), ProperCameraRigTypes.ViewMode3D.FIRST_PERSON)
	rig.set_zoom_normalized(0.25, true)
	assert_eq(rig.get_view_mode(), ProperCameraRigTypes.ViewMode3D.THIRD_PERSON)


func test_metrics_are_projection_neutral_and_driver_disables_native_camera() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	rig.set_zoom_normalized(0.75, true)
	rig._process(1.0 / 60.0)
	var metrics: Dictionary = rig.get_view_metrics()
	assert_gt(float(metrics[&"desired_world_units_per_pixel"]), 0.0)
	assert_gt(float(metrics[&"actual_world_units_per_pixel"]), 0.0)
	var bridge := PhantomBridgeDouble.new()
	rig.add_child(bridge)
	rig.set_phantom_bridge(bridge)
	rig.set_output_driver(ProperCameraRigTypes.OutputDriver.PHANTOM)
	assert_false(rig.get_camera().current)
	rig._process(1.0 / 60.0)
	assert_gt(bridge.third_person_calls, 0)
	assert_gt(bridge.projection_calls, 0)
	rig.set_output_driver(ProperCameraRigTypes.OutputDriver.NATIVE)
	assert_true(rig.get_camera().current)


func test_bounds_clamp_focus_position() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.bounds_enabled = true
	local_preset.bounds_min = Vector3(-2.0, -1.0, -3.0)
	local_preset.bounds_max = Vector3(4.0, 5.0, 6.0)
	rig.apply_preset(local_preset)
	rig.set_focus_position(Vector3(50.0, -10.0, 20.0))
	assert_eq(rig.get_focus_position(), Vector3(4.0, -1.0, 6.0))


func test_pan_up_uses_view_forward_and_recenter_reacquires_follow() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.pan_enabled = true
	local_preset.pan_speed = 10.0
	local_preset.look_enabled = true
	local_preset.starting_yaw_degrees = 0.0
	local_preset.follow_interruption = ProperCameraRigTypes.FollowInterruption.BREAK_ON_PAN
	rig.apply_preset(local_preset)
	rig.set_focus_position(Vector3.ZERO)
	rig.pan_direction(Vector2.UP, 1.0)
	assert_lt(rig.get_focus_position().z, 0.0, "W/left-stick-up must move along camera forward at yaw 0.")

	local_preset.starting_yaw_degrees = 90.0
	rig.apply_preset(local_preset)
	rig.set_focus_position(Vector3.ZERO)
	rig.pan_direction(Vector2.UP, 1.0)
	assert_lt(rig.get_focus_position().x, 0.0, "W/left-stick-up must rotate with the view basis.")

	var target := Node3D.new()
	add_child_autofree(target)
	target.global_position = Vector3(25.0, 0.0, -12.0)
	rig.set_follow_target(target, true)
	rig.pan_by_world(Vector3(4.0, 0.0, 0.0))
	assert_false(rig.is_following())
	rig.recenter()
	assert_true(rig.is_following())
	assert_eq(rig.get_focus_position(), target.global_position + local_preset.target_offset)


func test_player_fov_and_distance_overrides_respect_preset_limits() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.min_distance = 2.0
	local_preset.max_distance = 12.0
	local_preset.min_fov = 45.0
	local_preset.max_fov = 90.0
	rig.apply_preset(local_preset)
	var preferences: ProperCameraUserPreferences = ProperCameraUserPreferences.new()
	preferences.distance_override_enabled = true
	preferences.preferred_distance = 20.0
	preferences.fov_override_enabled = true
	preferences.preferred_fov_degrees = 30.0
	rig.set_user_preferences(preferences)
	var metrics: Dictionary = rig.get_view_metrics()
	assert_true(is_equal_approx(float(metrics[&"desired_distance"]), 12.0))
	assert_true(is_equal_approx(float(metrics[&"fov"]), 45.0))


func test_native_spring_arm_compresses_for_an_obstacle_and_recovers() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.zoom_mechanism = ProperCameraRigTypes.ZoomMechanism3D.DOLLY
	local_preset.min_distance = 2.0
	local_preset.max_distance = 10.0
	local_preset.starting_pitch_degrees = 0.0
	local_preset.min_pitch_degrees = -1.0
	local_preset.max_pitch_degrees = 1.0
	local_preset.occlusion_mode = ProperCameraRigTypes.OcclusionMode.PULL_IN
	local_preset.collision_mask = 1
	local_preset.collision_recovery_speed = 4.0
	rig.apply_preset(local_preset)
	rig.set_zoom_normalized(1.0, true)
	var obstacle: StaticBody3D = StaticBody3D.new()
	obstacle.position = Vector3(0.0, 0.0, 5.0)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4.0, 4.0, 1.0)
	collision.shape = shape
	obstacle.add_child(collision)
	add_child_autofree(obstacle)
	await get_tree().physics_frame
	await get_tree().physics_frame
	rig._process(1.0 / 60.0)
	var compressed_distance: float = float(rig.get_view_metrics()[&"actual_distance"])
	assert_lt(compressed_distance, 10.0)

	obstacle.free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	for iteration: int in range(120):
		rig._process(1.0 / 60.0)
	assert_gt(float(rig.get_view_metrics()[&"actual_distance"]), compressed_distance)


func test_active_occlusion_search_stays_stable_at_a_character_occlusion_edge() -> void:
	var rig: ProperCameraRig3D = await _create_rig()
	var local_preset: ProperCameraPreset3D = rig.preset.duplicate(true) as ProperCameraPreset3D
	local_preset.zoom_mechanism = ProperCameraRigTypes.ZoomMechanism3D.DOLLY
	local_preset.min_distance = 2.0
	local_preset.max_distance = 10.0
	local_preset.starting_pitch_degrees = 0.0
	local_preset.min_pitch_degrees = -1.0
	local_preset.max_pitch_degrees = 1.0
	local_preset.occlusion_mode = ProperCameraRigTypes.OcclusionMode.PULL_IN_AND_SEARCH
	local_preset.search_delay = 0.0
	local_preset.search_query_budget = 4
	local_preset.search_max_yaw_degrees = 35.0
	local_preset.collision_mask = 1
	local_preset.follow_enabled = true
	local_preset.follow_smoothing_speed = 0.0
	local_preset.target_offset = Vector3.ZERO
	rig.apply_preset(local_preset)
	rig.set_zoom_normalized(1.0, true)
	var target := Node3D.new()
	add_child_autofree(target)
	rig.set_follow_target(target, true)
	var obstacle: StaticBody3D = StaticBody3D.new()
	obstacle.position = Vector3(0.0, 0.0, 5.0)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.0, 4.0, 1.0)
	collision.shape = shape
	obstacle.add_child(collision)
	add_child_autofree(obstacle)
	await _wait_for_camera(rig, 2.0)
	var state: Dictionary = rig.get_occlusion_debug_state()
	assert_true(bool(state[&"center_route_blocked"]), "The authored centered route must remain blocked.")
	assert_gt(absf(float(state[&"yaw_offset"])) + absf(float(state[&"shoulder_offset"])), 0.001)

	var transitions: Array[Vector2] = []
	rig.occlusion_search_changed.connect(func(yaw: float, shoulder: float) -> void:
		transitions.append(Vector2(yaw, shoulder))
	)
	await _assert_idle_shot_is_stable(rig, 2.0)
	assert_eq(transitions.size(), 0, "An idle edge shot must not search again.")

	target.global_position.x = -0.25
	await _wait_for_camera(rig, 2.0)
	transitions.clear()
	await _assert_idle_shot_is_stable(rig, 2.0)
	assert_eq(transitions.size(), 0, "The left edge shot must settle without route churn.")

	target.global_position.x = 0.25
	await _wait_for_camera(rig, 2.0)
	transitions.clear()
	await _assert_idle_shot_is_stable(rig, 2.0)
	assert_eq(transitions.size(), 0, "The right edge shot must settle without route churn.")


func _wait_for_camera(_rig: ProperCameraRig3D, seconds: float) -> void:
	for _frame: int in range(roundi(seconds * 60.0)):
		await get_tree().physics_frame
		await get_tree().process_frame


func _assert_idle_shot_is_stable(rig: ProperCameraRig3D, seconds: float) -> void:
	var camera_position: Vector3 = rig.get_camera().global_position
	var actual_distance: float = float(rig.get_view_metrics()[&"actual_distance"])
	await _wait_for_camera(rig, seconds)
	assert_true(rig.get_camera().global_position.is_equal_approx(camera_position))
	assert_almost_eq(float(rig.get_view_metrics()[&"actual_distance"]), actual_distance, 0.001)


func _create_rig() -> ProperCameraRig3D:
	var rig: ProperCameraRig3D = RIG_SCENE.instantiate() as ProperCameraRig3D
	add_child_autofree(rig)
	await get_tree().process_frame
	return rig
