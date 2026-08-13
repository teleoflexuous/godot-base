class_name ProperCameraRig3D
extends Node3D

signal target_changed(previous: Node3D, current: Node3D)
signal target_lost(last_position: Vector3)
signal follow_state_changed(is_following: bool)
signal view_mode_changed(previous: ProperCameraRigTypes.ViewMode3D, current: ProperCameraRigTypes.ViewMode3D)
signal heading_changed(yaw_radians: float)
signal zoom_changed(normalized_zoom: float)
signal view_metrics_changed(metrics: Dictionary)
signal occlusion_changed(is_occluded: bool, actual_distance: float)
signal occlusion_search_changed(yaw_offset_radians: float, shoulder_offset: float)
signal output_driver_changed(previous: ProperCameraRigTypes.OutputDriver, current: ProperCameraRigTypes.OutputDriver)
signal output_configuration_failed(message: String)

const _ANCHOR_RAY_LENGTH: float = 10000.0
const _METRIC_EPSILON: float = 0.0001
const _SEARCH_HYSTERESIS: float = 0.15
const _SEARCH_RECHECK_INTERVAL: float = 0.15
const _SEARCH_CLEAR_DELAY: float = 0.35

@export var preset: ProperCameraPreset3D:
	set(value):
		preset = value
		if is_node_ready():
			_configure_preset()
@export var active: bool = true:
	set(value):
		active = value
		_update_native_camera_state()
@export var output_driver: ProperCameraRigTypes.OutputDriver = ProperCameraRigTypes.OutputDriver.NATIVE:
	set(value):
		var previous: ProperCameraRigTypes.OutputDriver = output_driver
		output_driver = value
		_update_native_camera_state()
		if previous != value:
			output_driver_changed.emit(previous, value)
@export_range(0.0, 1.0, 0.001) var starting_zoom_normalized: float = 0.5
@export var use_interpolated_target_transform: bool = true
@export var first_person_anchor_path: NodePath
@export var third_person_anchor_path: NodePath
@export_node_path("Node") var phantom_bridge_path: NodePath

@onready var _focus_pivot: Node3D = %Focus
@onready var _yaw_pivot: Node3D = %Yaw
@onready var _pitch_pivot: Node3D = %Pitch
@onready var _shoulder_pivot: Node3D = %Shoulder
@onready var _spring_arm: SpringArm3D = %SpringArm3D
@onready var _camera: Camera3D = %Camera3D
@onready var _motion_effects: ProperCameraMotionEffects3D = %MotionEffects3D

var _input_enabled: bool = true
var _follow_target_ref: WeakRef
var _follow_active: bool = false
var _had_valid_follow_target: bool = false
var _selection_target_ref: WeakRef
var _zoom_anchor_provider_ref: WeakRef
var _first_person_anchor_ref: WeakRef
var _third_person_anchor_ref: WeakRef
var _last_target_position: Vector3 = Vector3.ZERO
var _focus_position: Vector3 = Vector3.ZERO
var _follow_offset: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = 0.0
var _zoom_normalized: float = 0.5
var _zoom_target: float = 0.5
var _pointer_position: Vector2 = Vector2.ZERO
var _pointer_hit: Vector3 = Vector3.ZERO
var _pointer_hit_valid: bool = false
var _view_mode: ProperCameraRigTypes.ViewMode3D = ProperCameraRigTypes.ViewMode3D.THIRD_PERSON
var _requested_toggle_mode: ProperCameraRigTypes.ViewMode3D = ProperCameraRigTypes.ViewMode3D.THIRD_PERSON
var _actual_distance: float = 0.0
var _last_occluded: bool = false
var _blocked_time: float = 0.0
var _search_yaw_offset: float = 0.0
var _search_shoulder_offset: float = 0.0
var _search_recheck_remaining: float = 0.0
var _search_clear_time: float = 0.0
var _search_center_route_blocked: bool = false
var _recovery_distance: float = 0.0
var _last_metrics: Dictionary = {}
var _last_effect_translation: Vector3 = Vector3.ZERO
var _terrain_adjustment: float = 0.0
var _phantom_bridge: Node
var _phantom_error_reported: bool = false
var _metric_projection: Camera3D.ProjectionType = Camera3D.PROJECTION_PERSPECTIVE
var _metric_fov: float = 75.0
var _metric_orthographic_size: float = 1.0
var _fov_override_enabled: bool = false
var _preferred_fov_degrees: float = 75.0
var _distance_override_enabled: bool = false
var _preferred_distance: float = 4.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_focus_position = _focus_pivot.global_position
	_zoom_normalized = clampf(starting_zoom_normalized, 0.0, 1.0)
	_zoom_target = _zoom_normalized
	if preset == null:
		preset = ProperCameraPreset3D.new()
	_resolve_phantom_bridge()
	_configure_preset()
	_resolve_scene_anchors()
	_update_native_camera_state()
	_apply_camera_state()


func _process(delta: float) -> void:
	if preset == null:
		return
	_update_follow(delta)
	_update_view_mode()
	var anchor_world: Variant = _get_zoom_anchor_world()
	var anchor_screen: Vector2 = _pointer_position
	if anchor_world is Vector3 and preset.zoom_anchor != ProperCameraRigTypes.ZoomAnchor.VIEW_CENTER:
		if not _camera.is_position_behind(anchor_world):
			anchor_screen = _camera.unproject_position(anchor_world)
	var previous_zoom: float = _zoom_normalized
	_zoom_normalized = _smooth_value(
		_zoom_normalized,
		_zoom_target,
		preset.zoom_smoothing_speed,
		delta
	)
	_apply_bounds()
	_apply_camera_state()
	if anchor_world is Vector3 and not is_equal_approx(previous_zoom, _zoom_normalized):
		_apply_zoom_anchor_correction(anchor_world, anchor_screen)
		_apply_bounds()
		_apply_camera_state()
	_update_actual_distance(delta)
	_apply_motion_effects()
	_emit_metrics_if_changed()
	if not is_equal_approx(previous_zoom, _zoom_normalized):
		zoom_changed.emit(_zoom_normalized)


func _physics_process(delta: float) -> void:
	if preset == null:
		return
	_update_pointer_hit()
	_update_terrain_adjustment()
	_update_occlusion_search(delta)


func apply_preset(next_preset: ProperCameraPreset3D) -> void:
	if next_preset == null:
		return
	preset = next_preset


func _configure_preset() -> void:
	if preset == null:
		return
	_yaw = deg_to_rad(preset.starting_yaw_degrees)
	_pitch = clampf(
		deg_to_rad(preset.starting_pitch_degrees),
		deg_to_rad(preset.min_pitch_degrees),
		deg_to_rad(preset.max_pitch_degrees)
	)
	if is_instance_valid(_spring_arm):
		_spring_arm.collision_mask = (
			preset.collision_mask
			if output_driver == ProperCameraRigTypes.OutputDriver.NATIVE
			and preset.occlusion_mode != ProperCameraRigTypes.OcclusionMode.DISABLED
			else 0
		)
		_spring_arm.margin = preset.collision_margin
	_refresh_collision_exclusions()
	_update_view_mode()
	_apply_camera_state()


func set_follow_target(target: Node3D, snap_immediately: bool = false) -> void:
	var previous: Node3D = get_follow_target()
	var was_following: bool = is_following()
	_follow_target_ref = weakref(target) if target != null else null
	_follow_active = target != null and preset != null and preset.follow_enabled
	_had_valid_follow_target = target != null
	_follow_offset = Vector3.ZERO
	if target != null:
		_last_target_position = _target_position_for_mode(target)
	if previous != target:
		target_changed.emit(previous, target)
	if was_following != _follow_active:
		follow_state_changed.emit(_follow_active)
	_refresh_collision_exclusions()
	if snap_immediately and target != null:
		snap_to_target()


func clear_follow_target() -> void:
	var previous: Node3D = get_follow_target()
	var was_following: bool = is_following()
	_follow_target_ref = null
	_follow_active = false
	_had_valid_follow_target = false
	_follow_offset = Vector3.ZERO
	if previous != null:
		target_changed.emit(previous, null)
	if was_following:
		follow_state_changed.emit(false)
	_refresh_collision_exclusions()


func get_follow_target() -> Node3D:
	if _follow_target_ref == null:
		return null
	var value: Variant = _follow_target_ref.get_ref()
	return value as Node3D


func set_follow_enabled(enabled: bool) -> void:
	var next_state: bool = enabled and get_follow_target() != null
	if next_state == _follow_active:
		return
	_follow_active = next_state
	follow_state_changed.emit(_follow_active)


func set_following(enabled: bool, snap_immediately: bool = false) -> void:
	set_follow_enabled(enabled)
	if _follow_active and snap_immediately:
		snap_to_target()


func is_following() -> bool:
	return _follow_active and get_follow_target() != null


func toggle_follow() -> void:
	if not _input_enabled:
		return
	set_follow_enabled(not _follow_active)
	if _follow_active:
		recenter()


func set_selection_target(target: Node3D) -> void:
	_selection_target_ref = weakref(target) if target != null else null


func set_zoom_anchor_provider(provider: Object) -> void:
	_zoom_anchor_provider_ref = weakref(provider) if provider != null else null


func set_view_anchors(first_person: Node3D, third_person: Node3D = null) -> void:
	_first_person_anchor_ref = weakref(first_person) if first_person != null else null
	_third_person_anchor_ref = weakref(third_person) if third_person != null else null


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func set_motion_intensity(intensity: float) -> void:
	if is_instance_valid(_motion_effects):
		_motion_effects.motion_intensity = clampf(intensity, 0.0, 1.0)


func set_user_preferences(preferences: ProperCameraUserPreferences) -> void:
	if preferences == null:
		_fov_override_enabled = false
		_distance_override_enabled = false
	else:
		preferences.sanitize()
		_fov_override_enabled = preferences.fov_override_enabled
		_preferred_fov_degrees = preferences.preferred_fov_degrees
		_distance_override_enabled = preferences.distance_override_enabled
		_preferred_distance = preferences.preferred_distance
	if is_node_ready():
		_apply_camera_state()
		_emit_metrics_if_changed()


func pan_direction(direction: Vector2, delta: float) -> void:
	if not _input_enabled or preset == null or not preset.pan_enabled:
		return
	var safe_direction: Vector2 = direction.limit_length(1.0)
	var right: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var forward: Vector3 = Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	# InputMap and GUIDE use Vector2.UP for W/left-stick-up. Camera forward is
	# Godot's local -Z, so vertical intent must be inverted at this boundary.
	_pan_world((right * safe_direction.x - forward * safe_direction.y) * preset.pan_speed * maxf(delta, 0.0))


func pan_by_screen(screen_delta: Vector2) -> void:
	if not _input_enabled or preset == null or not preset.pan_enabled:
		return
	var units_per_pixel: float = _calculate_world_units_per_pixel(_desired_distance())
	var right: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var forward: Vector3 = Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	_pan_world((right * -screen_delta.x + forward * -screen_delta.y) * units_per_pixel)


func pan_by_world(world_delta: Vector3) -> void:
	if not _input_enabled or preset == null or not preset.pan_enabled:
		return
	_pan_world(world_delta)


func orbit_direction(direction: Vector2, delta: float) -> void:
	if preset == null:
		return
	var radians_per_second: float = preset.look_sensitivity * 60.0
	orbit_by_radians(direction.limit_length(1.0) * radians_per_second * maxf(delta, 0.0))


func orbit_by_radians(radians_delta: Vector2) -> void:
	if not _input_enabled or preset == null or not preset.look_enabled:
		return
	var previous_yaw: float = _yaw
	_yaw = wrapf(_yaw - radians_delta.x, -PI, PI)
	_pitch = clampf(
		_pitch - radians_delta.y,
		deg_to_rad(preset.min_pitch_degrees),
		deg_to_rad(preset.max_pitch_degrees)
	)
	if not is_equal_approx(previous_yaw, _yaw):
		heading_changed.emit(_yaw)


func look_direction(direction: Vector2, delta: float) -> void:
	orbit_direction(direction, delta)


func look_by_delta(screen_delta: Vector2) -> void:
	if preset == null:
		return
	orbit_by_radians(screen_delta * preset.look_sensitivity)


func zoom_by_rate(amount: float, delta: float) -> void:
	if not _input_enabled or preset == null or not preset.zoom_enabled:
		return
	set_zoom_normalized(_zoom_target - amount * maxf(delta, 0.0))


func zoom_by_steps(amount: float) -> void:
	if not _input_enabled or preset == null or not preset.zoom_enabled:
		return
	set_zoom_normalized(_zoom_target - amount * preset.zoom_step_size)


func set_zoom_normalized(value: float, immediate: bool = false) -> void:
	_zoom_target = clampf(value, 0.0, 1.0)
	if immediate:
		_zoom_normalized = _zoom_target
		_update_view_mode()
		_apply_camera_state()
	_update_view_mode()


func get_zoom_normalized() -> float:
	return _zoom_normalized


func set_pointer_position(screen_position: Vector2) -> void:
	_pointer_position = screen_position


func set_focus_position(world_position: Vector3, immediate: bool = true) -> void:
	_focus_position = world_position
	_apply_bounds()
	if immediate and is_node_ready():
		_apply_camera_state()
		reset_physics_interpolation()


func get_focus_position() -> Vector3:
	return _focus_position


func recenter() -> void:
	_follow_offset = Vector3.ZERO
	var target: Node3D = get_follow_target()
	if target == null:
		return
	if not _follow_active:
		_follow_active = true
		follow_state_changed.emit(true)
	snap_to_target()


func snap_to_target() -> void:
	var target: Node3D = get_follow_target()
	if target == null:
		return
	_focus_position = _target_position_for_mode(target) + _follow_offset
	_focus_pivot.global_position = _focus_position
	reset_physics_interpolation()


func toggle_view_mode() -> void:
	if not _input_enabled or preset == null:
		return
	if preset.view_policy != ProperCameraRigTypes.ViewPolicy3D.TOGGLE:
		return
	_requested_toggle_mode = (
		ProperCameraRigTypes.ViewMode3D.FIRST_PERSON
		if _requested_toggle_mode == ProperCameraRigTypes.ViewMode3D.THIRD_PERSON
		else ProperCameraRigTypes.ViewMode3D.THIRD_PERSON
	)
	_set_view_mode(_requested_toggle_mode)


func set_view_mode(mode: ProperCameraRigTypes.ViewMode3D) -> void:
	_requested_toggle_mode = mode
	_set_view_mode(mode)


func get_view_mode() -> ProperCameraRigTypes.ViewMode3D:
	return _view_mode


func rotate_step(steps: float) -> void:
	if not _input_enabled or preset == null:
		return
	var previous_yaw: float = _yaw
	_yaw = wrapf(_yaw + steps * deg_to_rad(preset.rotation_step_degrees), -PI, PI)
	if not is_equal_approx(previous_yaw, _yaw):
		heading_changed.emit(_yaw)


func get_heading() -> float:
	return _yaw


func set_output_driver(driver: ProperCameraRigTypes.OutputDriver) -> void:
	output_driver = driver


func get_output_driver() -> ProperCameraRigTypes.OutputDriver:
	return output_driver


func set_phantom_bridge(bridge: Node) -> void:
	_phantom_bridge = bridge
	_phantom_error_reported = false
	if is_node_ready() and output_driver == ProperCameraRigTypes.OutputDriver.PHANTOM:
		_apply_camera_state()


func get_phantom_bridge() -> Node:
	return _phantom_bridge


func get_camera() -> Camera3D:
	return _camera


func get_motion_effects() -> ProperCameraMotionEffects3D:
	return _motion_effects


func get_view_metrics() -> Dictionary:
	var desired_distance: float = _desired_distance()
	return {
		&"zoom_normalized": _zoom_normalized,
		&"desired_distance": desired_distance,
		&"actual_distance": _actual_distance,
		&"fov": _metric_fov,
		&"orthographic_size": _metric_orthographic_size if _metric_projection == Camera3D.PROJECTION_ORTHOGONAL else 0.0,
		&"focus_position": _focus_position,
		&"desired_world_units_per_pixel": _calculate_world_units_per_pixel(desired_distance),
		&"actual_world_units_per_pixel": _calculate_world_units_per_pixel(_actual_distance),
	}


func get_occlusion_debug_state() -> Dictionary:
	return {
		&"center_route_blocked": _search_center_route_blocked,
		&"yaw_offset": _search_yaw_offset,
		&"shoulder_offset": _search_shoulder_offset,
		&"actual_distance": _actual_distance,
	}


func get_desired_output_state() -> Dictionary:
	return {
		&"focus_position": _focus_position,
		&"yaw_radians": _yaw,
		&"pitch_radians": _pitch,
		&"distance": _desired_distance(),
		&"projection": _metric_projection,
		&"fov": _metric_fov,
		&"orthographic_size": _metric_orthographic_size,
		&"view_mode": _view_mode,
	}


func _pan_world(movement: Vector3) -> void:
	if movement.is_zero_approx():
		return
	if is_following():
		match preset.follow_interruption:
			ProperCameraRigTypes.FollowInterruption.HARD_LOCK:
				return
			ProperCameraRigTypes.FollowInterruption.OFFSET_WHILE_FOLLOWING:
				_follow_offset += movement
			ProperCameraRigTypes.FollowInterruption.BREAK_ON_PAN:
				_follow_active = false
				_focus_position += movement
				follow_state_changed.emit(false)
	else:
		_focus_position += movement


func _update_follow(delta: float) -> void:
	if not _follow_active:
		return
	var target: Node3D = get_follow_target()
	if target == null:
		if _had_valid_follow_target:
			_had_valid_follow_target = false
			_follow_active = false
			_follow_target_ref = null
			target_lost.emit(_last_target_position)
			follow_state_changed.emit(false)
		return
	var target_position: Vector3 = _target_position_for_mode(target)
	_last_target_position = target_position
	var goal: Vector3 = target_position + _follow_offset
	_focus_position = _smooth_vector3(_focus_position, goal, preset.follow_smoothing_speed, delta)


func _target_position_for_mode(target: Node3D) -> Vector3:
	var explicit_anchor: Node3D = _get_mode_anchor(_view_mode)
	if explicit_anchor != null:
		return _interpolated_position(explicit_anchor)
	var target_position: Vector3 = _interpolated_position(target)
	return target_position + (
		preset.first_person_offset
		if _view_mode == ProperCameraRigTypes.ViewMode3D.FIRST_PERSON
		else preset.target_offset
	)


func _interpolated_position(node: Node3D) -> Vector3:
	if use_interpolated_target_transform and node.is_inside_tree():
		return node.get_global_transform_interpolated().origin
	return node.global_position


func _update_view_mode() -> void:
	if preset == null:
		return
	match preset.view_policy:
		ProperCameraRigTypes.ViewPolicy3D.THIRD_PERSON_ONLY:
			_set_view_mode(ProperCameraRigTypes.ViewMode3D.THIRD_PERSON)
		ProperCameraRigTypes.ViewPolicy3D.FIRST_PERSON_ONLY:
			_set_view_mode(ProperCameraRigTypes.ViewMode3D.FIRST_PERSON)
		ProperCameraRigTypes.ViewPolicy3D.TOGGLE:
			_set_view_mode(_requested_toggle_mode)
		ProperCameraRigTypes.ViewPolicy3D.ZOOM_BLEND:
			if _view_mode == ProperCameraRigTypes.ViewMode3D.THIRD_PERSON and _zoom_target <= preset.first_person_enter_zoom:
				_set_view_mode(ProperCameraRigTypes.ViewMode3D.FIRST_PERSON)
			elif _view_mode == ProperCameraRigTypes.ViewMode3D.FIRST_PERSON and _zoom_target >= preset.first_person_exit_zoom:
				_set_view_mode(ProperCameraRigTypes.ViewMode3D.THIRD_PERSON)


func _set_view_mode(mode: ProperCameraRigTypes.ViewMode3D) -> void:
	if mode == _view_mode:
		return
	var previous: ProperCameraRigTypes.ViewMode3D = _view_mode
	_view_mode = mode
	view_mode_changed.emit(previous, mode)


func _apply_camera_state() -> void:
	if not is_instance_valid(_camera) or preset == null:
		return
	_focus_pivot.global_position = _focus_position + Vector3.UP * _terrain_adjustment
	var applied_pitch: float = _pitch
	if preset.pitch_policy == ProperCameraRigTypes.PitchPolicy.ZOOM_CURVE:
		applied_pitch = deg_to_rad(_sample_curve_or_lerp(
			preset.pitch_over_zoom,
			_zoom_normalized,
			preset.max_pitch_degrees,
			preset.min_pitch_degrees
		))
	_yaw_pivot.rotation.y = _yaw + _search_yaw_offset
	_pitch_pivot.rotation.x = clampf(
		applied_pitch,
		deg_to_rad(preset.min_pitch_degrees),
		deg_to_rad(preset.max_pitch_degrees)
	)
	var height_offset: float = 0.0
	if preset.pivot_height_over_zoom != null:
		height_offset = preset.pivot_height_over_zoom.sample_baked(_zoom_normalized)
	_pitch_pivot.position.y = height_offset
	var desired_distance: float = _desired_distance()
	if _view_mode == ProperCameraRigTypes.ViewMode3D.FIRST_PERSON:
		desired_distance = preset.min_distance
	_metric_projection = Camera3D.PROJECTION_PERSPECTIVE
	_metric_fov = preset.max_fov
	_metric_orthographic_size = lerpf(
		preset.min_orthographic_size,
		preset.max_orthographic_size,
		_zoom_normalized
	)
	match preset.zoom_mechanism:
		ProperCameraRigTypes.ZoomMechanism3D.ORTHOGRAPHIC_SIZE:
			_metric_projection = Camera3D.PROJECTION_ORTHOGONAL
		ProperCameraRigTypes.ZoomMechanism3D.FOV:
			_metric_fov = lerpf(preset.min_fov, preset.max_fov, _zoom_normalized)
		ProperCameraRigTypes.ZoomMechanism3D.COMPOSITE:
			_metric_fov = _sample_curve_or_lerp(
				preset.fov_over_zoom,
				_zoom_normalized,
				preset.min_fov,
				preset.max_fov
			)
	if _fov_override_enabled and _metric_projection == Camera3D.PROJECTION_PERSPECTIVE:
		_metric_fov = clampf(_preferred_fov_degrees, preset.min_fov, preset.max_fov)
	if output_driver == ProperCameraRigTypes.OutputDriver.PHANTOM:
		_apply_phantom_output(desired_distance, applied_pitch)
		return
	_shoulder_pivot.position.x = _search_shoulder_offset
	if _recovery_distance > 0.0 and _recovery_distance < desired_distance:
		_spring_arm.spring_length = _recovery_distance
	else:
		_spring_arm.spring_length = desired_distance
	match preset.zoom_mechanism:
		ProperCameraRigTypes.ZoomMechanism3D.ORTHOGRAPHIC_SIZE:
			_camera.projection = _metric_projection
			_camera.size = _metric_orthographic_size
			_camera.fov = _metric_fov
		_:
			_camera.projection = _metric_projection
			_camera.fov = _metric_fov


func _desired_distance() -> float:
	if preset == null:
		return 0.0
	if _view_mode == ProperCameraRigTypes.ViewMode3D.FIRST_PERSON:
		return preset.min_distance
	if _distance_override_enabled:
		return clampf(_preferred_distance, preset.min_distance, preset.max_distance)
	match preset.zoom_mechanism:
		ProperCameraRigTypes.ZoomMechanism3D.FOV, ProperCameraRigTypes.ZoomMechanism3D.ORTHOGRAPHIC_SIZE:
			return preset.max_distance
		_:
			return lerpf(preset.min_distance, preset.max_distance, _zoom_normalized)


func _apply_motion_effects() -> void:
	if output_driver != ProperCameraRigTypes.OutputDriver.NATIVE or not is_instance_valid(_motion_effects):
		return
	var sample: Dictionary = _motion_effects.get_motion_sample()
	var translation: Vector3 = sample.get("translation", Vector3.ZERO)
	var rotation_value: Vector3 = sample.get("rotation", Vector3.ZERO)
	var fov_offset: float = float(sample.get("fov_offset", 0.0))
	var base_position: Vector3 = _camera.position - _last_effect_translation
	_camera.position = base_position + translation
	_camera.rotation = rotation_value
	_camera.fov = clampf(_camera.fov + fov_offset, 1.0, 179.0)
	_last_effect_translation = translation


func _update_actual_distance(delta: float) -> void:
	var desired_distance: float = _desired_distance()
	if output_driver == ProperCameraRigTypes.OutputDriver.PHANTOM:
		_actual_distance = desired_distance
		_last_occluded = false
		_recovery_distance = 0.0
		return
	var hit_length: float = _spring_arm.get_hit_length()
	var is_occluded: bool = hit_length + preset.collision_margin < _spring_arm.spring_length
	if _last_occluded and not is_occluded and _actual_distance < desired_distance:
		_recovery_distance = maxf(_actual_distance, preset.min_distance)
	if _recovery_distance > 0.0:
		_recovery_distance = _smooth_value(
			_recovery_distance,
			desired_distance,
			preset.collision_recovery_speed,
			delta
		)
		if absf(_recovery_distance - desired_distance) <= 0.001:
			_recovery_distance = 0.0
	_actual_distance = minf(hit_length, _spring_arm.spring_length)
	if is_occluded != _last_occluded:
		_last_occluded = is_occluded
		occlusion_changed.emit(is_occluded, _actual_distance)


func _update_occlusion_search(delta: float) -> void:
	if output_driver != ProperCameraRigTypes.OutputDriver.NATIVE:
		_search_yaw_offset = 0.0
		_search_shoulder_offset = 0.0
		_blocked_time = 0.0
		_search_recheck_remaining = 0.0
		_search_clear_time = 0.0
		_search_center_route_blocked = false
		return
	if preset.occlusion_mode != ProperCameraRigTypes.OcclusionMode.PULL_IN_AND_SEARCH:
		_return_search_to_center(delta)
		return
	var desired_distance: float = _desired_distance()
	# The final SpringArm follows the selected escape route. It will therefore
	# report clear once that route works, even though the authored centered shot
	# remains obstructed. Probe that authored route separately so an edge contact
	# cannot repeatedly clear, recenter, collide, and search again.
	var center_clearance: float = _probe_route_clearance(0.0, 0.0, desired_distance)
	_search_center_route_blocked = center_clearance + preset.collision_margin < desired_distance
	if not _search_center_route_blocked:
		_blocked_time = 0.0
		_search_recheck_remaining = 0.0
		_search_clear_time += maxf(delta, 0.0)
		if _search_clear_time >= _SEARCH_CLEAR_DELAY:
			_return_search_to_center(delta)
		return
	_search_clear_time = 0.0
	_blocked_time += maxf(delta, 0.0)
	if _blocked_time < preset.search_delay:
		return
	_search_recheck_remaining = maxf(_search_recheck_remaining - delta, 0.0)
	if _search_recheck_remaining > 0.0:
		return
	_search_recheck_remaining = _SEARCH_RECHECK_INTERVAL
	var result: Dictionary = _find_best_search_candidate(desired_distance)
	if result.is_empty():
		return
	var candidate_score: float = float(result["score"])
	var current_score: float = _score_search_candidate(
		_search_yaw_offset,
		_search_shoulder_offset,
		desired_distance
	)
	var current_clearance: float = _probe_route_clearance(
		_search_yaw_offset,
		_search_shoulder_offset,
		desired_distance
	)
	# Do not replace a viable escape route simply because a periodic requery has
	# a numerically different winner. A new route must materially improve the
	# score; the current route remains until clearance has been stable enough to
	# return to center.
	if current_clearance + preset.collision_margin < desired_distance \
			or candidate_score > current_score + _SEARCH_HYSTERESIS:
		var next_yaw: float = float(result["yaw"])
		var next_shoulder: float = float(result["shoulder"])
		if not is_equal_approx(next_yaw, _search_yaw_offset) or not is_equal_approx(next_shoulder, _search_shoulder_offset):
			_search_yaw_offset = next_yaw
			_search_shoulder_offset = next_shoulder
			occlusion_search_changed.emit(_search_yaw_offset, _search_shoulder_offset)


func _find_best_search_candidate(desired_distance: float) -> Dictionary:
	var max_yaw: float = deg_to_rad(preset.search_max_yaw_degrees)
	var shoulder: float = preset.search_shoulder_distance
	var candidates: Array[Vector2] = [
		Vector2(-max_yaw * 0.5, 0.0),
		Vector2(max_yaw * 0.5, 0.0),
		Vector2(-max_yaw, 0.0),
		Vector2(max_yaw, 0.0),
		Vector2(0.0, -shoulder),
		Vector2(0.0, shoulder),
		Vector2(-max_yaw * 0.5, -shoulder),
		Vector2(max_yaw * 0.5, shoulder),
	]
	var budget: int = mini(preset.search_query_budget, candidates.size())
	var best: Dictionary = {}
	var best_score: float = -INF
	for index: int in range(budget):
		var candidate: Vector2 = candidates[index]
		var score: float = _score_search_candidate(candidate.x, candidate.y, desired_distance)
		if score > best_score:
			best_score = score
			best = {"yaw": candidate.x, "shoulder": candidate.y, "score": score}
	return best


func _score_search_candidate(yaw_offset: float, shoulder_offset: float, desired_distance: float) -> float:
	var clearance: float = _probe_route_clearance(yaw_offset, shoulder_offset, desired_distance)
	var deviation_penalty: float = absf(yaw_offset) * 0.25 + absf(shoulder_offset) * 0.1
	var continuity_penalty: float = absf(yaw_offset - _search_yaw_offset) * 0.1
	return clearance - deviation_penalty - continuity_penalty


func _probe_route_clearance(yaw_offset: float, shoulder_offset: float, distance: float) -> float:
	if not is_inside_tree() or preset == null:
		return 0.0
	var basis: Basis = Basis.from_euler(Vector3(_pitch, _yaw + yaw_offset, 0.0))
	var from: Vector3 = _focus_pivot.global_position + basis * Vector3(shoulder_offset, 0.0, 0.0)
	var motion: Vector3 = basis * Vector3(0.0, 0.0, distance)
	var exclusions: Array[RID] = _get_collision_exclusion_rids()
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if _spring_arm.shape != null:
		var shape_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		shape_query.shape = _spring_arm.shape
		shape_query.transform = Transform3D(basis, from)
		shape_query.motion = motion
		shape_query.collision_mask = preset.collision_mask
		shape_query.exclude = exclusions
		var fractions: PackedFloat32Array = space_state.cast_motion(shape_query)
		if not fractions.is_empty():
			return maxf(distance * fractions[0] - preset.collision_margin, 0.0)
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from,
		from + motion,
		preset.collision_mask,
		exclusions
	)
	var hit: Dictionary = space_state.intersect_ray(ray_query)
	return from.distance_to(Vector3(hit["position"])) - preset.collision_margin if not hit.is_empty() else distance


func _return_search_to_center(delta: float) -> void:
	var previous_yaw: float = _search_yaw_offset
	var previous_shoulder: float = _search_shoulder_offset
	_search_yaw_offset = _smooth_value(_search_yaw_offset, 0.0, 8.0, delta)
	_search_shoulder_offset = _smooth_value(_search_shoulder_offset, 0.0, 8.0, delta)
	if absf(_search_yaw_offset) < 0.0001:
		_search_yaw_offset = 0.0
	if absf(_search_shoulder_offset) < 0.0001:
		_search_shoulder_offset = 0.0
	if not is_equal_approx(previous_yaw, _search_yaw_offset) or not is_equal_approx(previous_shoulder, _search_shoulder_offset):
		occlusion_search_changed.emit(_search_yaw_offset, _search_shoulder_offset)


func _update_pointer_hit() -> void:
	_pointer_hit_valid = false
	if not is_inside_tree() or not is_instance_valid(_camera):
		return
	var from: Vector3 = _camera.project_ray_origin(_pointer_position)
	var to: Vector3 = from + _camera.project_ray_normal(_pointer_position) * _ANCHOR_RAY_LENGTH
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from,
		to,
		preset.collision_mask,
		_get_collision_exclusion_rids()
	)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_pointer_hit = Vector3(hit["position"])
		_pointer_hit_valid = true
		return
	var fallback: Variant = _screen_to_horizontal_plane(_pointer_position, _focus_position.y)
	if fallback is Vector3:
		_pointer_hit = fallback
		_pointer_hit_valid = true


func _get_zoom_anchor_world() -> Variant:
	match preset.zoom_anchor:
		ProperCameraRigTypes.ZoomAnchor.VIEW_CENTER:
			return null
		ProperCameraRigTypes.ZoomAnchor.FOLLOW_TARGET:
			var target: Node3D = get_follow_target()
			return _target_position_for_mode(target) if target != null else _focus_position
		ProperCameraRigTypes.ZoomAnchor.SELECTION_TARGET:
			var selection: Node3D = _get_weak_node(_selection_target_ref)
			return _interpolated_position(selection) if selection != null else _focus_position
		ProperCameraRigTypes.ZoomAnchor.POINTER_WORLD_HIT:
			if _pointer_hit_valid:
				return _pointer_hit
			return _screen_to_horizontal_plane(_pointer_position, _focus_position.y)
		ProperCameraRigTypes.ZoomAnchor.CUSTOM_PROVIDER:
			var provider: Object = _get_weak_object(_zoom_anchor_provider_ref)
			if provider != null and provider.has_method("get_camera_zoom_anchor_3d"):
				var provided: Variant = provider.call("get_camera_zoom_anchor_3d", self)
				if provided is Vector3:
					return provided
	return null


func _apply_zoom_anchor_correction(anchor_world: Vector3, anchor_screen: Vector2) -> void:
	var projected: Variant = _screen_to_horizontal_plane(anchor_screen, anchor_world.y)
	if projected is Vector3:
		_focus_position += anchor_world - projected


func _screen_to_horizontal_plane(screen_position: Vector2, height: float) -> Variant:
	var origin: Vector3 = _camera.project_ray_origin(screen_position)
	var direction: Vector3 = _camera.project_ray_normal(screen_position)
	if absf(direction.y) <= 0.00001:
		return null
	var distance: float = (height - origin.y) / direction.y
	if distance < 0.0:
		return null
	return origin + direction * distance


func _update_terrain_adjustment() -> void:
	_terrain_adjustment = 0.0
	if not preset.terrain_clearance_enabled or not is_inside_tree():
		return
	var camera_position: Vector3 = _camera.global_position
	var from: Vector3 = camera_position + Vector3.UP * 1000.0
	var to: Vector3 = camera_position + Vector3.DOWN * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from,
		to,
		preset.collision_mask,
		_get_collision_exclusion_rids()
	)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var terrain_height: float = Vector3(hit["position"]).y
	var minimum_camera_height: float = terrain_height + preset.minimum_terrain_clearance
	_terrain_adjustment = maxf(minimum_camera_height - camera_position.y, 0.0)


func _apply_bounds() -> void:
	if preset == null or not preset.bounds_enabled:
		return
	var low: Vector3 = preset.bounds_min.min(preset.bounds_max)
	var high: Vector3 = preset.bounds_min.max(preset.bounds_max)
	_focus_position = _focus_position.clamp(low, high)


func _calculate_world_units_per_pixel(distance: float) -> float:
	var viewport_height: float = maxf(get_viewport().get_visible_rect().size.y, 1.0)
	if _metric_projection == Camera3D.PROJECTION_ORTHOGONAL:
		return _metric_orthographic_size / viewport_height
	return 2.0 * maxf(distance, 0.001) * tan(deg_to_rad(_metric_fov) * 0.5) / viewport_height


func _emit_metrics_if_changed() -> void:
	var metrics: Dictionary = get_view_metrics()
	if _metrics_differ(metrics, _last_metrics):
		_last_metrics = metrics.duplicate()
		view_metrics_changed.emit(metrics)


func _metrics_differ(left: Dictionary, right: Dictionary) -> bool:
	if right.is_empty():
		return true
	for key: Variant in left:
		var left_value: Variant = left[key]
		var right_value: Variant = right.get(key)
		if left_value is float:
			if absf(float(left_value) - float(right_value)) > _METRIC_EPSILON:
				return true
		elif left_value is Vector3:
			if not Vector3(left_value).is_equal_approx(Vector3(right_value)):
				return true
		elif left_value != right_value:
			return true
	return false


func _refresh_collision_exclusions() -> void:
	if not is_instance_valid(_spring_arm):
		return
	if _spring_arm.has_method("clear_excluded_objects"):
		_spring_arm.call("clear_excluded_objects")
	for rid: RID in _get_collision_exclusion_rids():
		_spring_arm.add_excluded_object(rid)


func _get_collision_exclusion_rids() -> Array[RID]:
	var result: Array[RID] = []
	var target: Node3D = get_follow_target()
	if target == null:
		return result
	_collect_collision_rids(target, result)
	return result


func _collect_collision_rids(node: Node, result: Array[RID]) -> void:
	if node is CollisionObject3D:
		result.append((node as CollisionObject3D).get_rid())
	for child: Node in node.get_children():
		_collect_collision_rids(child, result)


func _resolve_scene_anchors() -> void:
	if not first_person_anchor_path.is_empty():
		var first_anchor: Node3D = get_node_or_null(first_person_anchor_path) as Node3D
		_first_person_anchor_ref = weakref(first_anchor) if first_anchor != null else null
	if not third_person_anchor_path.is_empty():
		var third_anchor: Node3D = get_node_or_null(third_person_anchor_path) as Node3D
		_third_person_anchor_ref = weakref(third_anchor) if third_anchor != null else null


func _resolve_phantom_bridge() -> void:
	if phantom_bridge_path.is_empty():
		return
	set_phantom_bridge(get_node_or_null(phantom_bridge_path))


func _apply_phantom_output(desired_distance: float, applied_pitch: float) -> void:
	if not is_instance_valid(_phantom_bridge):
		_report_phantom_failure("ProperCameraRig3D is configured for PHANTOM output but no bridge is bound.")
		return
	if _phantom_bridge.has_method(&"validate_configuration"):
		var is_valid: bool = bool(_phantom_bridge.call(&"validate_configuration", false))
		if not is_valid:
			_report_phantom_failure("The bound Phantom Camera bridge failed capability or version validation.")
			return
	var target: Node3D = _focus_pivot
	var applied: bool = false
	if _view_mode == ProperCameraRigTypes.ViewMode3D.THIRD_PERSON and _phantom_bridge.has_method(&"apply_3d_third_person"):
		applied = bool(_phantom_bridge.call(
			&"apply_3d_third_person",
			target,
			Vector3(rad_to_deg(applied_pitch), rad_to_deg(_yaw), 0.0),
			desired_distance
		))
	elif _phantom_bridge.has_method(&"apply_3d_simple"):
		var target_position: Vector3 = _interpolated_position(target)
		var follow_offset: Vector3 = _focus_position - target_position
		var orientation: Quaternion = Basis.from_euler(Vector3(applied_pitch, _yaw, 0.0)).get_rotation_quaternion()
		applied = bool(_phantom_bridge.call(
			&"apply_3d_simple",
			target,
			follow_offset,
			orientation
		))
	if not applied:
		_report_phantom_failure("The bound Phantom Camera bridge could not apply the selected 3D mode.")
		return
	if not _phantom_bridge.has_method(&"apply_projection"):
		_report_phantom_failure("The bound Phantom Camera bridge does not expose projection output.")
		return
	var projection_applied: bool = bool(_phantom_bridge.call(
		&"apply_projection",
		_metric_projection,
		_metric_fov,
		_metric_orthographic_size
	))
	if not projection_applied:
		_report_phantom_failure("The bound Phantom Camera bridge could not apply the selected projection.")
		return
	_phantom_error_reported = false


func _report_phantom_failure(message: String) -> void:
	if _phantom_error_reported:
		return
	_phantom_error_reported = true
	output_configuration_failed.emit(message)
	push_error(message)


func _get_mode_anchor(mode: ProperCameraRigTypes.ViewMode3D) -> Node3D:
	return (
		_get_weak_node(_first_person_anchor_ref)
		if mode == ProperCameraRigTypes.ViewMode3D.FIRST_PERSON
		else _get_weak_node(_third_person_anchor_ref)
	)


func _get_weak_node(reference: WeakRef) -> Node3D:
	if reference == null:
		return null
	return reference.get_ref() as Node3D


func _get_weak_object(reference: WeakRef) -> Object:
	if reference == null:
		return null
	return reference.get_ref() as Object


func _update_native_camera_state() -> void:
	if not is_node_ready() or not is_instance_valid(_camera):
		return
	_camera.current = active and output_driver == ProperCameraRigTypes.OutputDriver.NATIVE
	if is_instance_valid(_spring_arm) and preset != null:
		_spring_arm.collision_mask = (
			preset.collision_mask
			if output_driver == ProperCameraRigTypes.OutputDriver.NATIVE
			and preset.occlusion_mode != ProperCameraRigTypes.OcclusionMode.DISABLED
			else 0
		)


func _sample_curve_or_lerp(curve: Curve, value: float, minimum: float, maximum: float) -> float:
	if curve == null:
		return lerpf(minimum, maximum, value)
	return curve.sample_baked(value)


func _smooth_value(current: float, target: float, speed: float, delta: float) -> float:
	if speed <= 0.0:
		return target
	return lerpf(current, target, 1.0 - exp(-speed * maxf(delta, 0.0)))


func _smooth_vector3(current: Vector3, target: Vector3, speed: float, delta: float) -> Vector3:
	if speed <= 0.0:
		return target
	return current.lerp(target, 1.0 - exp(-speed * maxf(delta, 0.0)))
