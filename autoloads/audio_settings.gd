extends Node

## Deprecated compatibility facade. Prefer the AudioManager autoload.


func set_master_volume(linear_value: float) -> void:
	AudioManager.set_master_volume(linear_value)


func set_music_volume(linear_value: float) -> void:
	AudioManager.set_music_volume(linear_value)


func set_effects_volume(linear_value: float) -> void:
	AudioManager.set_effects_volume(linear_value)


func get_master_volume() -> float:
	return AudioManager.get_master_volume()


func get_music_volume() -> float:
	return AudioManager.get_music_volume()


func get_effects_volume() -> float:
	return AudioManager.get_effects_volume()
