class_name ProperCameraShake2DCompat
extends Camera2D

## Camera2D-compatible wrapper for callers that only use shake(amplitude,
## duration, frequency). New rigs compose ProperCameraMotionEffects2D on an effect
## pivot instead, keeping authored camera state separate from motion.

@export_range(0.0, 1.0, 0.01) var motion_intensity: float = 1.0:
	set(value):
		motion_intensity = clampf(value, 0.0, 1.0)
		if is_instance_valid(_motion_effects):
			_motion_effects.motion_intensity = motion_intensity

var _motion_effects: ProperCameraMotionEffects2D


func _ready() -> void:
	_ensure_motion_effects()


func shake(amplitude: float, duration: float, frequency: float = 30.0) -> void:
	_ensure_motion_effects()
	_motion_effects.shake(amplitude, duration, frequency)


func add_impulse(
		translation_amplitude: Vector2,
		rotation_amplitude: float,
		duration: float,
		frequency_hz: float = 24.0,
		random_seed: int = 0
) -> void:
	_ensure_motion_effects()
	_motion_effects.add_impulse(
		translation_amplitude,
		rotation_amplitude,
		duration,
		frequency_hz,
		random_seed
	)


func start_noise(
		layer_id: StringName,
		translation_amplitude: Vector2,
		rotation_amplitude: float = 0.0,
		frequency_hz: float = 3.0,
		random_seed: int = 0
) -> void:
	_ensure_motion_effects()
	_motion_effects.start_noise(
		layer_id,
		translation_amplitude,
		rotation_amplitude,
		frequency_hz,
		random_seed
	)


func stop_noise(layer_id: StringName) -> void:
	_ensure_motion_effects()
	_motion_effects.stop_noise(layer_id)


func cancel_all() -> void:
	if is_instance_valid(_motion_effects):
		_motion_effects.cancel_all()


func _ensure_motion_effects() -> void:
	if is_instance_valid(_motion_effects):
		return
	_motion_effects = ProperCameraMotionEffects2D.new()
	_motion_effects.name = "ProperCameraMotionEffects2D"
	_motion_effects.target_pivot_path = NodePath("..")
	_motion_effects.motion_intensity = motion_intensity
	add_child(_motion_effects)
