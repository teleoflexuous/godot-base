class_name CameraShake2D
extends Camera2D

var _remaining: float = 0.0
var _amplitude: float = 0.0
var _frequency: float = 0.0
var _origin_offset: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0


func shake(amplitude: float, duration: float, frequency: float = 30.0) -> void:
	_origin_offset = offset
	_amplitude = maxf(amplitude, 0.0)
	_remaining = maxf(duration, 0.0)
	_frequency = maxf(frequency, 1.0)
	_elapsed = 0.0


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining -= delta
	_elapsed += delta
	var falloff: float = clampf(_remaining / maxf(_remaining + delta, 0.001), 0.0, 1.0)
	var angle: float = _elapsed * _frequency * TAU
	offset = _origin_offset + Vector2(sin(angle), cos(angle * 1.618)) * _amplitude * falloff
	if _remaining <= 0.0:
		offset = _origin_offset
