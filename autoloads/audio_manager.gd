extends Node

signal volume_changed(bus_name: StringName, linear_value: float)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "audio"
const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const EFFECTS_BUS: StringName = &"Effects"
const UI_BUS: StringName = &"UI"
const SETTING_BUSES: Array[StringName] = [MASTER_BUS, MUSIC_BUS, EFFECTS_BUS]

var volumes: Dictionary[StringName, float] = {}
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_apply_all()
	_music_player = _make_player(MUSIC_BUS)
	_sfx_players = [_make_player(EFFECTS_BUS), _make_player(EFFECTS_BUS)]
	_ui_players = [_make_player(UI_BUS), _make_player(UI_BUS)]


func set_master_volume(linear_value: float) -> void:
	_set_bus_volume(MASTER_BUS, linear_value)


func set_music_volume(linear_value: float) -> void:
	_set_bus_volume(MUSIC_BUS, linear_value)


func set_effects_volume(linear_value: float) -> void:
	_set_bus_volume(EFFECTS_BUS, linear_value)


func get_master_volume() -> float:
	return get_bus_volume(MASTER_BUS)


func get_music_volume() -> float:
	return get_bus_volume(MUSIC_BUS)


func get_effects_volume() -> float:
	return get_bus_volume(EFFECTS_BUS)


func get_bus_volume(bus_name: StringName) -> float:
	return volumes.get(bus_name, 1.0)


func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	_play_from_pool(_sfx_players, stream, volume_db)


func play_ui(stream: AudioStream, volume_db: float = 0.0) -> void:
	_play_from_pool(_ui_players, stream, volume_db)


func _make_player(bus_name: StringName) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


func _play_from_pool(pool: Array[AudioStreamPlayer], stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = pool[0]
	for candidate: AudioStreamPlayer in pool:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var clamped: float = clampf(linear_value, 0.0, 1.0)
	volumes[bus_name] = clamped
	_apply_bus(bus_name, clamped)
	_save()
	volume_changed.emit(bus_name, clamped)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		for bus_name: StringName in SETTING_BUSES:
			volumes[bus_name] = 1.0
		return
	for bus_name: StringName in SETTING_BUSES:
		var raw: Variant = config.get_value(SECTION, String(bus_name), 1.0)
		var value: float = 1.0
		if raw is float:
			var raw_float: float = raw
			value = raw_float
		elif raw is int:
			var raw_int: int = raw
			value = float(raw_int)
		volumes[bus_name] = clampf(value, 0.0, 1.0)


func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var _load_result: int = config.load(SETTINGS_PATH)
	for bus_name: StringName in SETTING_BUSES:
		config.set_value(SECTION, String(bus_name), volumes[bus_name])
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Failed to save audio settings to %s" % SETTINGS_PATH)


func _apply_all() -> void:
	for bus_name: StringName in SETTING_BUSES:
		_apply_bus(bus_name, volumes[bus_name])


func _apply_bus(bus_name: StringName, linear_value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.0001)))
	AudioServer.set_bus_mute(index, linear_value <= 0.0)
