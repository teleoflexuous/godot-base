extends Node

signal volume_changed(bus_name: StringName, linear_value: float)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "audio"
const DEFAULT_BUSES: Array[StringName] = [&"Master", &"Music", &"Effects", &"UI", &"World"]

var volumes: Dictionary[StringName, float] = {}

func _ready() -> void:
	_load()
	_apply_all()


func set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var clamped: float = clampf(linear_value, 0.0, 1.0)
	volumes[bus_name] = clamped
	_apply_bus(bus_name, clamped)
	_save()
	volume_changed.emit(bus_name, clamped)


func get_bus_volume(bus_name: StringName) -> float:
	return volumes.get(bus_name, 1.0)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		for bus_name: StringName in DEFAULT_BUSES:
			volumes[bus_name] = 1.0
		return
	for bus_name: StringName in DEFAULT_BUSES:
		var raw: Variant = config.get_value(SECTION, String(bus_name), 1.0)
		volumes[bus_name] = raw if raw is float else 1.0


func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var _previous_state_loaded: int = config.load(SETTINGS_PATH)
	for bus_name: StringName in volumes.keys():
		config.set_value(SECTION, String(bus_name), volumes[bus_name])
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Failed to save audio settings to %s" % SETTINGS_PATH)


func _apply_all() -> void:
	for bus_name: StringName in volumes.keys():
		_apply_bus(bus_name, volumes[bus_name])


func _apply_bus(bus_name: StringName, linear_value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.0001)))
	AudioServer.set_bus_mute(index, linear_value <= 0.0)
