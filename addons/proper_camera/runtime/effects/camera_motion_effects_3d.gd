class_name ProperCameraMotionEffects3D
extends Node

signal motion_updated(translation: Vector3, rotation: Vector3, fov_offset: float)
signal effects_finished

@export_range(0.0, 1.0, 0.01) var motion_intensity: float = 1.0:
	set(value):
		motion_intensity = clampf(value, 0.0, 1.0)
@export var deterministic_seed: int = 1337
@export var process_while_paused: bool = false

var _impulses: Array[Dictionary] = []
var _noise_enabled: bool = false
var _noise_translation: Vector3 = Vector3.ZERO
var _noise_rotation: Vector3 = Vector3.ZERO
var _noise_fov: float = 0.0
var _noise_frequency: float = 1.0
var _noise_seed: int = 0
var _noise_elapsed: float = 0.0
var _sample_translation: Vector3 = Vector3.ZERO
var _sample_rotation: Vector3 = Vector3.ZERO
var _sample_fov: float = 0.0


func _ready() -> void:
	process_priority = -10
	process_mode = Node.PROCESS_MODE_ALWAYS if process_while_paused else Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	advance(delta)


func add_impulse(
		translation_amplitude: Vector3,
		rotation_amplitude: Vector3 = Vector3.ZERO,
		fov_amplitude: float = 0.0,
		duration: float = 0.25,
		frequency: float = 20.0,
		seed_offset: int = 0
) -> void:
	var safe_duration: float = maxf(duration, 0.0)
	if safe_duration <= 0.0 or motion_intensity <= 0.0:
		return
	_impulses.append({
		"translation": translation_amplitude,
		"rotation": rotation_amplitude,
		"fov": fov_amplitude,
		"duration": safe_duration,
		"frequency": maxf(frequency, 0.001),
		"elapsed": 0.0,
		"seed": deterministic_seed + seed_offset,
	})


func shake(amplitude: float, duration: float, frequency: float = 30.0) -> void:
	add_impulse(
		Vector3(amplitude, amplitude * 0.75, amplitude * 0.25),
		Vector3(amplitude * 0.01, amplitude * 0.0075, amplitude * 0.005),
		0.0,
		duration,
		frequency
	)


func start_noise(
		translation_amplitude: Vector3,
		rotation_amplitude: Vector3 = Vector3.ZERO,
		fov_amplitude: float = 0.0,
		frequency: float = 1.0,
		seed_override: int = -1
) -> void:
	_noise_translation = translation_amplitude
	_noise_rotation = rotation_amplitude
	_noise_fov = fov_amplitude
	_noise_frequency = maxf(frequency, 0.001)
	_noise_seed = deterministic_seed if seed_override < 0 else seed_override
	_noise_elapsed = 0.0
	_noise_enabled = true


func stop_noise() -> void:
	_noise_enabled = false


func cancel_all() -> void:
	var had_effects: bool = has_active_effects()
	_impulses.clear()
	_noise_enabled = false
	_sample_translation = Vector3.ZERO
	_sample_rotation = Vector3.ZERO
	_sample_fov = 0.0
	motion_updated.emit(_sample_translation, _sample_rotation, _sample_fov)
	if had_effects:
		effects_finished.emit()


func has_active_effects() -> bool:
	return not _impulses.is_empty() or _noise_enabled


func has_active_motion() -> bool:
	return has_active_effects()


func get_current_translation() -> Vector3:
	return _sample_translation


func get_current_rotation() -> Vector3:
	return _sample_rotation


func get_current_fov_offset() -> float:
	return _sample_fov


func advance(delta: float) -> void:
	var had_effects: bool = has_active_effects()
	var translation: Vector3 = Vector3.ZERO
	var rotation_value: Vector3 = Vector3.ZERO
	var fov_value: float = 0.0
	var survivors: Array[Dictionary] = []
	for impulse: Dictionary in _impulses:
		var elapsed: float = float(impulse["elapsed"]) + maxf(delta, 0.0)
		var duration: float = float(impulse["duration"])
		var normalized_time: float = clampf(elapsed / duration, 0.0, 1.0)
		var envelope: float = 1.0 - normalized_time
		var frequency: float = float(impulse["frequency"])
		var seed_value: int = int(impulse["seed"])
		var wave: Vector3 = _wave3(elapsed * frequency, seed_value)
		translation += Vector3(impulse["translation"]) * wave * envelope
		rotation_value += Vector3(impulse["rotation"]) * _wave3(elapsed * frequency, seed_value + 19) * envelope
		fov_value += float(impulse["fov"]) * sin(elapsed * frequency * TAU + _phase(seed_value + 37)) * envelope
		if elapsed < duration:
			impulse["elapsed"] = elapsed
			survivors.append(impulse)
	_impulses = survivors
	if _noise_enabled:
		_noise_elapsed += maxf(delta, 0.0)
		var noise_time: float = _noise_elapsed * _noise_frequency
		translation += _noise_translation * _wave3(noise_time, _noise_seed)
		rotation_value += _noise_rotation * _wave3(noise_time, _noise_seed + 53)
		fov_value += _noise_fov * sin(noise_time * TAU + _phase(_noise_seed + 71))
	_sample_translation = translation * motion_intensity
	_sample_rotation = rotation_value * motion_intensity
	_sample_fov = fov_value * motion_intensity
	motion_updated.emit(_sample_translation, _sample_rotation, _sample_fov)
	if had_effects and not has_active_effects():
		effects_finished.emit()


func get_motion_sample() -> Dictionary:
	return {
		"translation": _sample_translation,
		"rotation": _sample_rotation,
		"fov_offset": _sample_fov,
	}


func _wave3(time_value: float, seed_value: int) -> Vector3:
	return Vector3(
		sin(time_value * TAU + _phase(seed_value)),
		sin(time_value * TAU * 1.371 + _phase(seed_value + 1)),
		sin(time_value * TAU * 1.917 + _phase(seed_value + 2))
	)


func _phase(seed_value: int) -> float:
	var wrapped: int = posmod(seed_value * 1103515245 + 12345, 65536)
	return float(wrapped) / 65536.0 * TAU
