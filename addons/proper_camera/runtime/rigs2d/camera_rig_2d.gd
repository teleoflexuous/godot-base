class_name ProperCameraRig2D
extends Node2D

## Input-agnostic 2D camera state machine. Input adapters call the semantic
## movement methods; games can use the direct setters for authored transitions.

signal target_changed(previous: Node2D, current: Node2D)
signal target_lost(last_position: Vector2)
signal follow_state_changed(is_following: bool)
signal zoom_changed(normalized: float)
signal view_metrics_changed(metrics: Dictionary)
signal heading_changed(heading_radians: float)
signal output_driver_changed(previous: ProperCameraRigTypes.OutputDriver, current: ProperCameraRigTypes.OutputDriver)
signal output_configuration_failed(message: String)

const INTERPOLATED_TRANSFORM_METHOD: StringName = &"get_global_transform_interpolated"
const CUSTOM_ANCHOR_METHOD: StringName = &"get_camera_zoom_anchor_2d"
const LEGACY_CUSTOM_ANCHOR_METHOD: StringName = &"get_zoom_anchor_2d"
const LOOK_AHEAD_FULL_SPEED: float = 240.0

@export var preset: ProperCameraPreset2D
@export_node_path("Camera2D") var camera_path: NodePath = ^"FocusPivot/EffectPivot/Camera2D"
@export_node_path("Node2D") var focus_pivot_path: NodePath = ^"FocusPivot"
@export_node_path("Node2D") var effect_pivot_path: NodePath = ^"FocusPivot/EffectPivot"
@export_node_path("Node") var motion_effects_path: NodePath = ^"MotionEffects"
@export_node_path("Node") var phantom_bridge_path: NodePath
@export_node_path("Node2D") var initial_follow_target_path: NodePath
@export var input_enabled: bool = true
@export var make_current_on_ready: bool = true
@export var output_driver: ProperCameraRigTypes.OutputDriver = ProperCameraRigTypes.OutputDriver.NATIVE:
	set(value):
		var previous: ProperCameraRigTypes.OutputDriver = output_driver
		output_driver = value
		if is_node_ready():
			_update_output_driver(previous)
@export var rotation_enabled: bool = false
@export_range(1.0, 180.0, 1.0, "radians_as_degrees") var rotation_step_radians: float = deg_to_rad(15.0)

var _camera: Camera2D
var _focus_pivot: Node2D
var _effect_pivot: Node2D
var _motion_effects: Node
var _phantom_bridge: Node
var _phantom_error_reported: bool = false
var _follow_target_ref: WeakRef
var _selection_target_ref: WeakRef
var _custom_zoom_anchor_provider: Node
var _following: bool = false

var _free_center: Vector2 = Vector2.ZERO
var _desired_center: Vector2 = Vector2.ZERO
var _current_center: Vector2 = Vector2.ZERO
var _output_center: Vector2 = Vector2.ZERO
var _follow_offset: Vector2 = Vector2.ZERO
var _dead_zone_center: Vector2 = Vector2.ZERO
var _dead_zone_initialized: bool = false
var _last_target_position: Vector2 = Vector2.ZERO
var _has_last_target_position: bool = false

var _look_ahead_offset: Vector2 = Vector2.ZERO
var _peek_direction: Vector2 = Vector2.ZERO
var _peek_offset: Vector2 = Vector2.ZERO

var _zoom_target: float = 1.0
var _zoom_current: float = 1.0
var _zoom_anchor_active: bool = false
var _zoom_anchor_snapshot: Vector2 = Vector2.ZERO
var _pointer_position: Vector2 = Vector2.ZERO
var _pointer_position_valid: bool = false

var _last_metrics_center: Vector2 = Vector2.INF
var _last_metrics_zoom: float = -1.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_resolve_scene_nodes()
	if preset == null:
		preset = ProperCameraPreset2D.new()
	_current_center = _focus_pivot.global_position if is_instance_valid(_focus_pivot) else global_position
	_desired_center = _current_center
	_free_center = _current_center
	_output_center = _current_center
	_initialize_zoom()
	_resolve_initial_follow_target()
	if is_instance_valid(_camera):
		_camera.position_smoothing_enabled = false
		_camera.zoom = Vector2.ONE * _zoom_current
	_update_output_driver(output_driver)
	_apply_output_transform()
	_apply_phantom_output()
	_emit_metrics_if_changed(true)


func _process(delta: float) -> void:
	if preset == null:
		return
	var target: Node2D = get_follow_target()
	if _follow_target_ref != null and target == null:
		_handle_lost_target()
		target = null

	_step_zoom(delta)
	_step_peek(delta)
	if _following and target != null:
		_step_follow(target, delta)
	else:
		_step_free_camera(delta)
	_apply_output_transform()
	_apply_phantom_output()
	_emit_metrics_if_changed()


func set_follow_target(target: Node2D, snap_immediately: bool = false) -> void:
	if target == null:
		clear_follow_target()
		return
	var previous: Node2D = get_follow_target()
	_follow_target_ref = weakref(target)
	_following = true
	_follow_offset = Vector2.ZERO
	_dead_zone_initialized = false
	_last_target_position = _get_interpolated_target_position(target)
	_has_last_target_position = true
	if previous != target:
		target_changed.emit(previous, target)
	follow_state_changed.emit(true)
	if snap_immediately:
		snap_to_target()


func clear_follow_target() -> void:
	var previous: Node2D = get_follow_target()
	_follow_target_ref = null
	_following = false
	_follow_offset = Vector2.ZERO
	_dead_zone_initialized = false
	_has_last_target_position = false
	_free_center = _current_center
	_desired_center = _current_center
	if previous != null:
		target_changed.emit(previous, null)
		follow_state_changed.emit(false)


func get_follow_target() -> Node2D:
	if _follow_target_ref == null:
		return null
	return _follow_target_ref.get_ref() as Node2D


func set_selection_target(target: Node2D) -> void:
	_selection_target_ref = weakref(target) if target != null else null


func get_selection_target() -> Node2D:
	if _selection_target_ref == null:
		return null
	return _selection_target_ref.get_ref() as Node2D


func set_zoom_anchor_provider(provider: Node) -> void:
	_custom_zoom_anchor_provider = provider


func set_following(enabled: bool, snap_immediately: bool = false) -> void:
	var next_state: bool = enabled and get_follow_target() != null
	if next_state == _following:
		return
	_following = next_state
	if _following:
		_follow_offset = _current_center - _last_target_position
		_dead_zone_initialized = false
		if snap_immediately:
			snap_to_target()
	else:
		_free_center = _current_center
		_desired_center = _current_center
	follow_state_changed.emit(_following)


func set_follow_enabled(enabled: bool) -> void:
	set_following(enabled)


func toggle_follow() -> void:
	if not input_enabled:
		return
	if _following:
		set_following(false)
		return
	# A player-initiated follow action is a request to frame the target, not
	# merely preserve the previous free-camera offset.
	recenter()


func is_following() -> bool:
	return _following and get_follow_target() != null


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not input_enabled:
		clear_look()


func set_motion_intensity(intensity: float) -> void:
	if is_instance_valid(_motion_effects):
		_motion_effects.set(&"motion_intensity", clampf(intensity, 0.0, 1.0))


func set_focus_position(world_position: Vector2, snap_immediately: bool = true) -> void:
	_following = false
	_free_center = world_position
	_desired_center = world_position
	if snap_immediately:
		_current_center = world_position
		_apply_output_transform()
		reset_physics_interpolation()
	follow_state_changed.emit(false)


func pan_by_world(world_delta: Vector2) -> void:
	if not _can_accept_pan() or world_delta.is_zero_approx():
		return
	if _following:
		match preset.follow_interruption:
			ProperCameraRigTypes.FollowInterruption.HARD_LOCK:
				return
			ProperCameraRigTypes.FollowInterruption.OFFSET_WHILE_FOLLOWING:
				_follow_offset += world_delta
				if _dead_zone_initialized:
					_dead_zone_center += world_delta
			ProperCameraRigTypes.FollowInterruption.BREAK_ON_PAN:
				_following = false
				_free_center = _current_center
				follow_state_changed.emit(false)
	if _following:
		_current_center += world_delta
		_desired_center += world_delta
	else:
		_free_center += world_delta
		_desired_center = _free_center + _peek_offset
		_current_center += world_delta
	_constrain_free_state()


## A drag delta in viewport pixels. Dragging content right moves the camera left.
func pan_by_screen(screen_delta: Vector2) -> void:
	var world_delta: Vector2 = (-screen_delta / maxf(_zoom_current, 0.0001)).rotated(global_rotation)
	pan_by_world(world_delta)


func pan_direction(direction: Vector2, delta: float) -> void:
	var clamped_direction: Vector2 = direction.limit_length(1.0)
	pan_by_world(clamped_direction * preset.pan_speed * maxf(delta, 0.0))


func look_direction(direction: Vector2, _delta: float = 0.0) -> void:
	if not input_enabled or not preset.look_enabled:
		return
	_peek_direction = direction.limit_length(1.0)


func look_by_screen(screen_delta: Vector2) -> void:
	if not input_enabled or not preset.look_enabled:
		return
	var scale: float = maxf(preset.peek_distance, 1.0)
	_peek_direction = (_peek_direction + screen_delta / scale).limit_length(1.0)


func look_by_delta(screen_delta: Vector2) -> void:
	look_by_screen(screen_delta)


func clear_look() -> void:
	_peek_direction = Vector2.ZERO


## Positive steps zoom in. Negative steps zoom out.
func zoom_by_steps(steps: float) -> void:
	if not input_enabled or not preset.zoom_enabled or is_zero_approx(steps):
		return
	var next_zoom: float = _zoom_target * exp(steps * preset.zoom_step_size)
	_set_zoom_target(next_zoom, false)


## Positive rate zooms in and is expressed in logical steps per second.
func zoom_by_rate(rate: float, delta: float) -> void:
	zoom_by_steps(rate * maxf(delta, 0.0))


func set_zoom_normalized(normalized: float, immediate: bool = false) -> void:
	var range_values: Vector2 = _get_zoom_range()
	var close_zoom: float = range_values.y
	var far_zoom: float = range_values.x
	var ratio: float = far_zoom / close_zoom
	var next_zoom: float = close_zoom * pow(ratio, clampf(normalized, 0.0, 1.0))
	_set_zoom_target(next_zoom, immediate)


func get_zoom_normalized() -> float:
	return _zoom_to_normalized(_zoom_current)


func set_pointer_position(viewport_position: Vector2) -> void:
	_pointer_position = viewport_position
	_pointer_position_valid = true


func clear_pointer_position() -> void:
	_pointer_position_valid = false


func recenter() -> void:
	var was_following: bool = _following
	_follow_offset = Vector2.ZERO
	_dead_zone_initialized = false
	_look_ahead_offset = Vector2.ZERO
	clear_look()
	if get_follow_target() != null:
		_following = true
		if not was_following:
			follow_state_changed.emit(true)
		snap_to_target()
	else:
		_free_center = _current_center


func snap_to_target() -> void:
	var target: Node2D = get_follow_target()
	if target == null:
		return
	var target_position: Vector2 = _get_interpolated_target_position(target)
	_last_target_position = target_position
	_has_last_target_position = true
	_dead_zone_center = target_position + _follow_offset
	_dead_zone_initialized = true
	_look_ahead_offset = Vector2.ZERO
	_peek_offset = _peek_direction * preset.peek_distance
	_current_center = _dead_zone_center + _peek_offset
	_desired_center = _current_center
	_apply_output_transform()
	reset_physics_interpolation()


func snap() -> void:
	if is_following():
		snap_to_target()
	else:
		_current_center = _free_center + _peek_offset
		_desired_center = _current_center
		_apply_output_transform()
		reset_physics_interpolation()


func set_heading(heading_radians: float) -> void:
	if is_equal_approx(rotation, heading_radians):
		return
	rotation = heading_radians
	heading_changed.emit(rotation)
	_apply_output_transform()


func get_heading() -> float:
	return rotation


func orbit_by_radians(radians_delta: Vector2) -> void:
	if not input_enabled or not rotation_enabled:
		return
	set_heading(rotation + radians_delta.x)


func orbit_direction(direction: Vector2, delta: float) -> void:
	orbit_by_radians(Vector2(direction.x * rotation_step_radians * 4.0 * maxf(delta, 0.0), 0.0))


func rotate_step(step_count: float) -> void:
	if not input_enabled or not rotation_enabled:
		return
	var step_radians: float = rotation_step_radians
	if preset != null:
		step_radians = deg_to_rad(preset.rotation_step_degrees)
	set_heading(rotation + step_count * step_radians)


func get_view_metrics() -> Dictionary:
	var desired_zoom: float = maxf(_zoom_target, 0.0001)
	var actual_zoom: float = maxf(_zoom_current, 0.0001)
	return {
		&"zoom_normalized": _zoom_to_normalized(_zoom_current),
		&"desired_zoom": Vector2.ONE * desired_zoom,
		&"actual_zoom": Vector2.ONE * actual_zoom,
		&"focus_position": _output_center,
		&"desired_focus_position": _desired_center,
		&"desired_world_units_per_pixel": 1.0 / desired_zoom,
		&"actual_world_units_per_pixel": 1.0 / actual_zoom,
		&"visible_world_size": _get_viewport_size() / actual_zoom,
		&"viewport_size": _get_viewport_size(),
		&"heading_radians": global_rotation,
	}


func get_camera() -> Camera2D:
	return _camera


func get_effect_pivot() -> Node2D:
	return _effect_pivot


func get_motion_effects() -> Node:
	return _motion_effects


func set_phantom_bridge(bridge: Node) -> void:
	_phantom_bridge = bridge
	_phantom_error_reported = false
	if output_driver == ProperCameraRigTypes.OutputDriver.PHANTOM:
		_apply_phantom_output()


func set_output_driver(driver: ProperCameraRigTypes.OutputDriver) -> void:
	output_driver = driver


func get_output_driver() -> ProperCameraRigTypes.OutputDriver:
	return output_driver


func viewport_to_world(viewport_position: Vector2) -> Vector2:
	var screen_offset: Vector2 = viewport_position - _get_viewport_size() * 0.5
	return _output_center + (screen_offset / maxf(_zoom_current, 0.0001)).rotated(global_rotation)


func world_to_viewport(world_position: Vector2) -> Vector2:
	var world_offset: Vector2 = (world_position - _output_center).rotated(-global_rotation)
	return _get_viewport_size() * 0.5 + world_offset * _zoom_current


func apply_preset(next_preset: ProperCameraPreset2D, preserve_position: bool = true) -> void:
	preset = next_preset if next_preset != null else ProperCameraPreset2D.new()
	var preserved_center: Vector2 = _current_center
	_zoom_target = _clamp_zoom(_zoom_target)
	_zoom_current = _clamp_zoom(_zoom_current)
	if not preserve_position:
		preserved_center = global_position
	_free_center = preserved_center
	_current_center = preserved_center
	_desired_center = preserved_center
	_dead_zone_initialized = false
	if is_instance_valid(_camera):
		_camera.zoom = Vector2.ONE * _zoom_current
	_apply_output_transform()


func _resolve_scene_nodes() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D
	_focus_pivot = get_node_or_null(focus_pivot_path) as Node2D
	_effect_pivot = get_node_or_null(effect_pivot_path) as Node2D
	_motion_effects = get_node_or_null(motion_effects_path)
	_phantom_bridge = get_node_or_null(phantom_bridge_path)
	if not is_instance_valid(_camera):
		push_error("ProperCameraRig2D requires a Camera2D at camera_path.")
	if not is_instance_valid(_focus_pivot):
		push_error("ProperCameraRig2D requires a Node2D at focus_pivot_path.")
	if not is_instance_valid(_effect_pivot):
		push_error("ProperCameraRig2D requires a Node2D at effect_pivot_path.")


func _resolve_initial_follow_target() -> void:
	if initial_follow_target_path.is_empty():
		return
	var target: Node2D = get_node_or_null(initial_follow_target_path) as Node2D
	if target != null:
		set_follow_target(target, true)
		if not preset.follow_enabled:
			set_following(false)


func _initialize_zoom() -> void:
	var initial_zoom: float = 1.0
	if is_instance_valid(_camera):
		initial_zoom = (_camera.zoom.x + _camera.zoom.y) * 0.5
	_zoom_current = _clamp_zoom(initial_zoom)
	_zoom_target = _zoom_current


func _step_zoom(delta: float) -> void:
	var previous_zoom: float = _zoom_current
	var weight: float = _exp_smoothing_weight(preset.zoom_smoothing_speed, delta)
	_zoom_current = lerpf(_zoom_current, _zoom_target, weight)
	if absf(_zoom_current - _zoom_target) <= 0.0001:
		_zoom_current = _zoom_target
	if not is_equal_approx(previous_zoom, _zoom_current):
		_shift_for_zoom(previous_zoom, _zoom_current)
		if is_instance_valid(_camera):
			_camera.zoom = Vector2.ONE * _zoom_current
		zoom_changed.emit(_zoom_to_normalized(_zoom_current))
	if is_equal_approx(_zoom_current, _zoom_target):
		_zoom_anchor_active = false


func _step_peek(delta: float) -> void:
	var peek_target: Vector2 = Vector2.ZERO
	if preset.look_enabled:
		peek_target = _peek_direction * preset.peek_distance
	var weight: float = _exp_smoothing_weight(preset.peek_smoothing_speed, delta)
	_peek_offset = _peek_offset.lerp(peek_target, weight)


func _step_follow(target: Node2D, delta: float) -> void:
	var target_position: Vector2 = _get_interpolated_target_position(target)
	var target_velocity: Vector2 = Vector2.ZERO
	if _has_last_target_position and delta > 0.0:
		target_velocity = (target_position - _last_target_position) / delta
	_last_target_position = target_position
	_has_last_target_position = true

	var look_ahead_ratio := Vector2(
		clampf(target_velocity.x / LOOK_AHEAD_FULL_SPEED, -1.0, 1.0),
		clampf(target_velocity.y / LOOK_AHEAD_FULL_SPEED, -1.0, 1.0)
	)
	var look_ahead_target: Vector2 = look_ahead_ratio * preset.look_ahead_distance
	var look_weight: float = _exp_smoothing_weight(preset.look_ahead_smoothing_speed, delta)
	_look_ahead_offset = _look_ahead_offset.lerp(look_ahead_target, look_weight)

	_update_dead_zone_center(target_position + _follow_offset)
	_desired_center = _dead_zone_center + _look_ahead_offset + _peek_offset
	var horizontal_speed: float = preset.horizontal_follow_smoothing_speed
	if horizontal_speed <= 0.0:
		horizontal_speed = preset.follow_smoothing_speed
	var vertical_speed: float = preset.vertical_follow_smoothing_speed
	if vertical_speed <= 0.0:
		vertical_speed = preset.follow_smoothing_speed
	_current_center.x = lerpf(
		_current_center.x,
		_desired_center.x,
		_exp_smoothing_weight(horizontal_speed, delta)
	)
	_current_center.y = lerpf(
		_current_center.y,
		_desired_center.y,
		_exp_smoothing_weight(vertical_speed, delta)
	)


func _step_free_camera(delta: float) -> void:
	var look_weight: float = _exp_smoothing_weight(preset.look_ahead_smoothing_speed, delta)
	_look_ahead_offset = _look_ahead_offset.lerp(Vector2.ZERO, look_weight)
	_desired_center = _free_center + _peek_offset
	_current_center = _desired_center
	_constrain_free_state()


func _update_dead_zone_center(target_center: Vector2) -> void:
	if not _dead_zone_initialized:
		_dead_zone_center = target_center
		_dead_zone_initialized = true
		return
	var half_zone: Vector2 = preset.dead_zone.abs() * 0.5
	if half_zone.x <= 0.0:
		_dead_zone_center.x = target_center.x
	else:
		_dead_zone_center.x = clampf(
			_dead_zone_center.x,
			target_center.x - half_zone.x,
			target_center.x + half_zone.x
		)
	if half_zone.y <= 0.0:
		_dead_zone_center.y = target_center.y
	else:
		_dead_zone_center.y = clampf(
			_dead_zone_center.y,
			target_center.y - half_zone.y,
			target_center.y + half_zone.y
		)


func _handle_lost_target() -> void:
	_follow_target_ref = null
	_following = false
	_follow_offset = Vector2.ZERO
	_dead_zone_initialized = false
	_has_last_target_position = false
	_free_center = _current_center
	_desired_center = _current_center
	_look_ahead_offset = Vector2.ZERO
	_peek_offset = Vector2.ZERO
	_peek_direction = Vector2.ZERO
	target_lost.emit(_last_target_position)
	follow_state_changed.emit(false)


func _get_interpolated_target_position(target: Node2D) -> Vector2:
	if target.is_inside_tree() and target.has_method(INTERPOLATED_TRANSFORM_METHOD):
		var interpolated_transform: Transform2D = target.call(INTERPOLATED_TRANSFORM_METHOD)
		return interpolated_transform.origin
	return target.global_position


func _set_zoom_target(next_zoom: float, immediate: bool) -> void:
	var clamped_zoom: float = _clamp_zoom(next_zoom)
	if is_equal_approx(clamped_zoom, _zoom_target) and not immediate:
		return
	_zoom_anchor_snapshot = _resolve_zoom_anchor()
	_zoom_anchor_active = preset.zoom_anchor != ProperCameraRigTypes.ZoomAnchor.VIEW_CENTER
	_zoom_target = clamped_zoom
	if immediate:
		var previous_zoom: float = _zoom_current
		_zoom_current = _zoom_target
		_shift_for_zoom(previous_zoom, _zoom_current)
		if is_instance_valid(_camera):
			_camera.zoom = Vector2.ONE * _zoom_current
		_zoom_anchor_active = false
		_apply_output_transform()
		zoom_changed.emit(_zoom_to_normalized(_zoom_current))


func _shift_for_zoom(previous_zoom: float, next_zoom: float) -> void:
	if not _zoom_anchor_active or previous_zoom <= 0.0 or next_zoom <= 0.0:
		return
	var anchor_position: Vector2 = _resolve_active_zoom_anchor()
	var shifted_center: Vector2 = anchor_position + (_current_center - anchor_position) * previous_zoom / next_zoom
	var center_delta: Vector2 = shifted_center - _current_center
	_current_center = shifted_center
	_desired_center += center_delta
	if _following:
		_follow_offset += center_delta
		if _dead_zone_initialized:
			_dead_zone_center += center_delta
	else:
		_free_center += center_delta


func _resolve_active_zoom_anchor() -> Vector2:
	match preset.zoom_anchor:
		ProperCameraRigTypes.ZoomAnchor.FOLLOW_TARGET:
			var follow_target: Node2D = get_follow_target()
			if follow_target != null:
				return _get_interpolated_target_position(follow_target)
		ProperCameraRigTypes.ZoomAnchor.SELECTION_TARGET:
			var selection_target: Node2D = get_selection_target()
			if selection_target != null:
				return _get_interpolated_target_position(selection_target)
		ProperCameraRigTypes.ZoomAnchor.CUSTOM_PROVIDER:
			var custom_anchor: Variant = _call_custom_anchor_provider()
			if custom_anchor is Vector2:
				return custom_anchor
	return _zoom_anchor_snapshot


func _resolve_zoom_anchor() -> Vector2:
	match preset.zoom_anchor:
		ProperCameraRigTypes.ZoomAnchor.FOLLOW_TARGET:
			var follow_target: Node2D = get_follow_target()
			if follow_target != null:
				return _get_interpolated_target_position(follow_target)
		ProperCameraRigTypes.ZoomAnchor.SELECTION_TARGET:
			var selection_target: Node2D = get_selection_target()
			if selection_target != null:
				return _get_interpolated_target_position(selection_target)
		ProperCameraRigTypes.ZoomAnchor.POINTER_WORLD_HIT:
			if _pointer_position_valid:
				return viewport_to_world(_pointer_position)
		ProperCameraRigTypes.ZoomAnchor.CUSTOM_PROVIDER:
			var custom_anchor: Variant = _call_custom_anchor_provider()
			if custom_anchor is Vector2:
				return custom_anchor
	return _output_center


func _call_custom_anchor_provider() -> Variant:
	if not is_instance_valid(_custom_zoom_anchor_provider):
		return null
	if _custom_zoom_anchor_provider.has_method(CUSTOM_ANCHOR_METHOD):
		return _custom_zoom_anchor_provider.call(CUSTOM_ANCHOR_METHOD, self)
	if _custom_zoom_anchor_provider.has_method(LEGACY_CUSTOM_ANCHOR_METHOD):
		return _custom_zoom_anchor_provider.call(LEGACY_CUSTOM_ANCHOR_METHOD, self)
	return null


func _apply_output_transform() -> void:
	_output_center = _clamp_center_to_bounds(_current_center, _zoom_current)
	if not _following:
		var correction: Vector2 = _output_center - _current_center
		_current_center = _output_center
		_desired_center += correction
		_free_center += correction
	if is_instance_valid(_focus_pivot):
		_focus_pivot.global_position = _output_center


func _update_output_driver(previous: ProperCameraRigTypes.OutputDriver) -> void:
	var native_output: bool = output_driver == ProperCameraRigTypes.OutputDriver.NATIVE
	if is_instance_valid(_camera):
		_camera.enabled = native_output and make_current_on_ready
		if _camera.enabled:
			_camera.make_current()
	if is_instance_valid(_motion_effects):
		if not native_output:
			if _motion_effects.has_method(&"cancel_all"):
				_motion_effects.call(&"cancel_all")
			_motion_effects.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			_motion_effects.process_mode = Node.PROCESS_MODE_INHERIT
	_phantom_error_reported = false
	if previous != output_driver:
		output_driver_changed.emit(previous, output_driver)
	if not native_output:
		_apply_phantom_output()


func _apply_phantom_output() -> void:
	if output_driver != ProperCameraRigTypes.OutputDriver.PHANTOM:
		return
	if not is_instance_valid(_phantom_bridge) or not _phantom_bridge.has_method(&"apply_2d"):
		_report_phantom_failure("ProperCameraRig2D PHANTOM output needs a bridge exposing apply_2d().")
		return
	var follow_target: Node2D = get_follow_target() if _following else null
	var phantom_target: Node = follow_target if follow_target != null else _focus_pivot
	var phantom_offset: Vector2 = Vector2.ZERO
	if follow_target != null:
		phantom_offset = _output_center - _get_interpolated_target_position(follow_target)
	var applied: Variant = _phantom_bridge.call(
		&"apply_2d",
		phantom_target,
		phantom_offset,
		Vector2.ONE * _zoom_current
	)
	if applied is bool and not applied:
		_report_phantom_failure("ProperCameraRig2D Phantom bridge rejected the current configuration.")
		return
	if _phantom_bridge.has_method(&"apply_focus_transform_2d"):
		var focus_transform: Transform2D = Transform2D(global_rotation, _output_center)
		_phantom_bridge.call(&"apply_focus_transform_2d", focus_transform)


func _report_phantom_failure(message: String) -> void:
	if _phantom_error_reported:
		return
	_phantom_error_reported = true
	output_configuration_failed.emit(message)
	push_warning(message)


func _constrain_free_state() -> void:
	if preset == null or not preset.bounds_enabled:
		return
	var clamped_center: Vector2 = _clamp_center_to_bounds(_current_center, _zoom_current)
	var correction: Vector2 = clamped_center - _current_center
	_current_center = clamped_center
	_desired_center += correction
	_free_center += correction


func _clamp_center_to_bounds(center: Vector2, zoom_value: float) -> Vector2:
	if preset == null or not preset.bounds_enabled:
		return center
	var half_view: Vector2 = _get_viewport_size() * 0.5 / maxf(zoom_value, 0.0001)
	var cosine: float = absf(cos(global_rotation))
	var sine: float = absf(sin(global_rotation))
	var rotated_half_view := Vector2(
		cosine * half_view.x + sine * half_view.y,
		sine * half_view.x + cosine * half_view.y
	)
	var margin: Vector2 = preset.bounds_margin.abs()
	var minimum_center: Vector2 = preset.bounds.position + margin + rotated_half_view
	var maximum_center: Vector2 = preset.bounds.position + preset.bounds.size - margin - rotated_half_view
	var bounds_midpoint: Vector2 = preset.bounds.position + preset.bounds.size * 0.5
	var result: Vector2 = center
	result.x = bounds_midpoint.x if minimum_center.x > maximum_center.x else clampf(
		center.x,
		minimum_center.x,
		maximum_center.x
	)
	result.y = bounds_midpoint.y if minimum_center.y > maximum_center.y else clampf(
		center.y,
		minimum_center.y,
		maximum_center.y
	)
	return result


func _get_zoom_range() -> Vector2:
	var minimum: float = maxf(minf(preset.min_zoom, preset.max_zoom), 0.01)
	var maximum: float = maxf(maxf(preset.min_zoom, preset.max_zoom), minimum)
	return Vector2(minimum, maximum)


func _clamp_zoom(value: float) -> float:
	var range_values: Vector2 = _get_zoom_range()
	return clampf(value, range_values.x, range_values.y)


func _zoom_to_normalized(value: float) -> float:
	var range_values: Vector2 = _get_zoom_range()
	if is_equal_approx(range_values.x, range_values.y):
		return 0.0
	var safe_value: float = clampf(value, range_values.x, range_values.y)
	return clampf(
		log(range_values.y / safe_value) / log(range_values.y / range_values.x),
		0.0,
		1.0
	)


func _can_accept_pan() -> bool:
	return input_enabled and preset != null and preset.pan_enabled


func _get_viewport_size() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	return get_viewport_rect().size


func _emit_metrics_if_changed(force: bool = false) -> void:
	var changed: bool = force
	changed = changed or not _last_metrics_center.is_equal_approx(_output_center)
	changed = changed or not is_equal_approx(_last_metrics_zoom, _zoom_current)
	if not changed:
		return
	_last_metrics_center = _output_center
	_last_metrics_zoom = _zoom_current
	view_metrics_changed.emit(get_view_metrics())


func _exp_smoothing_weight(speed: float, delta: float) -> float:
	if speed <= 0.0:
		return 1.0
	return 1.0 - exp(-speed * maxf(delta, 0.0))
