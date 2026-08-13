class_name ProperCameraMotionEffects2D
extends Node

## Additive, deterministic camera motion. The target pivot remains the owner of
## its base transform; this component only adds its sampled offset each frame.

signal motion_offset_changed(translation: Vector2, rotation_radians: float)
signal motion_finished()


class Impulse2D:
	extends RefCounted

	var translation_amplitude: Vector2 = Vector2.ZERO
	var rotation_amplitude: float = 0.0
	var duration: float = 0.0
	var frequency_hz: float = 1.0
	var random_seed: int = 0
	var elapsed: float = 0.0


class NoiseLayer2D:
	extends RefCounted

	var layer_id: StringName = &"default"
	var translation_amplitude: Vector2 = Vector2.ZERO
	var rotation_amplitude: float = 0.0
	var frequency_hz: float = 1.0
	var random_seed: int = 0
	var elapsed: float = 0.0


@export_node_path("Node2D") var target_pivot_path: NodePath
@export_range(0.0, 1.0, 0.01) var motion_intensity: float = 1.0
@export var maximum_translation: Vector2 = Vector2(128.0, 128.0)
@export_range(0.0, 180.0, 0.1, "radians_as_degrees") var maximum_rotation: float = deg_to_rad(15.0)

var _target_pivot: Node2D
var _impulses: Array[Impulse2D] = []
var _noise_layers: Array[NoiseLayer2D] = []
var _base_position: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _last_translation: Vector2 = Vector2.ZERO
var _last_rotation: float = 0.0


func _ready() -> void:
	_resolve_target_pivot()
	_capture_base_transform()
	set_process(false)


func _exit_tree() -> void:
	_capture_base_transform()
	_restore_base_transform()


func _process(delta: float) -> void:
	if not is_instance_valid(_target_pivot):
		_resolve_target_pivot()
		if not is_instance_valid(_target_pivot):
			set_process(false)
			return

	# Accommodate intentional edits by another system while an effect is active.
	_base_position = _target_pivot.position - _last_translation
	_base_rotation = _target_pivot.rotation - _last_rotation

	var translation_sample: Vector2 = Vector2.ZERO
	var rotation_sample: float = 0.0
	for impulse: Impulse2D in _impulses:
		impulse.elapsed = minf(impulse.elapsed + delta, impulse.duration)
		var envelope: float = 1.0 - impulse.elapsed / maxf(impulse.duration, 0.0001)
		envelope *= envelope
		translation_sample += _sample_translation(
			impulse.elapsed,
			impulse.frequency_hz,
			impulse.random_seed
		) * impulse.translation_amplitude * envelope
		rotation_sample += _sample_wave(
			impulse.elapsed,
			impulse.frequency_hz,
			impulse.random_seed + 97
		) * impulse.rotation_amplitude * envelope

	for index: int in range(_impulses.size() - 1, -1, -1):
		if _impulses[index].elapsed >= _impulses[index].duration:
			_impulses.remove_at(index)

	for layer: NoiseLayer2D in _noise_layers:
		layer.elapsed += delta
		translation_sample += _sample_translation(
			layer.elapsed,
			layer.frequency_hz,
			layer.random_seed
		) * layer.translation_amplitude
		rotation_sample += _sample_wave(
			layer.elapsed,
			layer.frequency_hz,
			layer.random_seed + 97
		) * layer.rotation_amplitude

	_apply_offset(translation_sample * motion_intensity, rotation_sample * motion_intensity)
	if _impulses.is_empty() and _noise_layers.is_empty():
		_restore_base_transform()
		set_process(false)
		motion_finished.emit()


func add_impulse(
		translation_amplitude: Vector2,
		rotation_amplitude: float,
		duration: float,
		frequency_hz: float = 24.0,
		random_seed: int = 0
) -> void:
	if duration <= 0.0:
		return
	var impulse := Impulse2D.new()
	impulse.translation_amplitude = translation_amplitude.abs()
	impulse.rotation_amplitude = absf(rotation_amplitude)
	impulse.duration = duration
	impulse.frequency_hz = maxf(frequency_hz, 0.01)
	impulse.random_seed = random_seed
	_impulses.append(impulse)
	_activate()


## Compatibility entry point for the original CameraShake2D API.
func shake(amplitude: float, duration: float, frequency: float = 30.0) -> void:
	var safe_amplitude: float = maxf(amplitude, 0.0)
	add_impulse(Vector2.ONE * safe_amplitude, 0.0, duration, frequency, 0)


func start_noise(
		layer_id: StringName,
		translation_amplitude: Vector2,
		rotation_amplitude: float = 0.0,
		frequency_hz: float = 3.0,
		random_seed: int = 0
) -> void:
	stop_noise(layer_id, false)
	var layer := NoiseLayer2D.new()
	layer.layer_id = layer_id
	layer.translation_amplitude = translation_amplitude.abs()
	layer.rotation_amplitude = absf(rotation_amplitude)
	layer.frequency_hz = maxf(frequency_hz, 0.01)
	layer.random_seed = random_seed
	_noise_layers.append(layer)
	_activate()


func stop_noise(layer_id: StringName, restore_when_idle: bool = true) -> void:
	for index: int in range(_noise_layers.size() - 1, -1, -1):
		if _noise_layers[index].layer_id == layer_id:
			_noise_layers.remove_at(index)
	if restore_when_idle and _impulses.is_empty() and _noise_layers.is_empty():
		_capture_base_transform()
		_restore_base_transform()
		set_process(false)


func cancel_all(restore_base: bool = true) -> void:
	_capture_base_transform()
	_impulses.clear()
	_noise_layers.clear()
	if restore_base:
		_restore_base_transform()
	set_process(false)


func has_active_motion() -> bool:
	return not _impulses.is_empty() or not _noise_layers.is_empty()


func get_current_translation() -> Vector2:
	return _last_translation


func get_current_rotation() -> float:
	return _last_rotation


func _activate() -> void:
	if not is_instance_valid(_target_pivot):
		_resolve_target_pivot()
	if not is_instance_valid(_target_pivot):
		push_warning("ProperCameraMotionEffects2D needs a valid target_pivot_path.")
		return
	if not is_processing():
		_capture_base_transform()
	set_process(true)


func _resolve_target_pivot() -> void:
	_target_pivot = get_node_or_null(target_pivot_path) as Node2D


func _capture_base_transform() -> void:
	if not is_instance_valid(_target_pivot):
		return
	_base_position = _target_pivot.position - _last_translation
	_base_rotation = _target_pivot.rotation - _last_rotation


func _restore_base_transform() -> void:
	if is_instance_valid(_target_pivot):
		_target_pivot.position = _base_position
		_target_pivot.rotation = _base_rotation
	var changed: bool = not _last_translation.is_zero_approx() or not is_zero_approx(_last_rotation)
	_last_translation = Vector2.ZERO
	_last_rotation = 0.0
	if changed:
		motion_offset_changed.emit(Vector2.ZERO, 0.0)


func _apply_offset(translation_sample: Vector2, rotation_sample: float) -> void:
	var translation_limit: Vector2 = maximum_translation.abs()
	_last_translation = Vector2(
		clampf(translation_sample.x, -translation_limit.x, translation_limit.x),
		clampf(translation_sample.y, -translation_limit.y, translation_limit.y)
	)
	var rotation_limit: float = absf(maximum_rotation)
	_last_rotation = clampf(rotation_sample, -rotation_limit, rotation_limit)
	_target_pivot.position = _base_position + _last_translation
	_target_pivot.rotation = _base_rotation + _last_rotation
	motion_offset_changed.emit(_last_translation, _last_rotation)


func _sample_translation(time: float, frequency_hz: float, random_seed: int) -> Vector2:
	return Vector2(
		_sample_wave(time, frequency_hz, random_seed + 11),
		_sample_wave(time, frequency_hz * 1.137, random_seed + 53)
	)


func _sample_wave(time: float, frequency_hz: float, random_seed: int) -> float:
	var phase: float = float(posmod(random_seed * 16807, 104729)) / 104729.0 * TAU
	var primary: float = sin(time * frequency_hz * TAU + phase)
	var secondary: float = sin(time * frequency_hz * 0.437 * TAU + phase * 1.913)
	return primary * 0.72 + secondary * 0.28
