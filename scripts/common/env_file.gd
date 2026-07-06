extends RefCounted

const DEFAULT_ENV_PATH := "res://.env"
const DEFAULT_OVERRIDE_CFG_PATH := "res://override.cfg"


static func load(path: String = DEFAULT_ENV_PATH) -> Dictionary:
	var result := {}
	if not FileAccess.file_exists(path):
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	while not file.eof_reached():
		var raw_line := file.get_line()
		var line := raw_line.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line.begins_with("export "):
			line = line.substr("export ".length()).strip_edges()
		var eq := line.find("=")
		if eq < 0:
			continue
		var key := line.substr(0, eq).strip_edges()
		var value := line.substr(eq + 1).strip_edges()
		if value.length() >= 2:
			var first := value[0]
			var last := value[value.length() - 1]
			if (first == "\"" and last == "\"") or (first == "'" and last == "'"):
				value = value.substr(1, value.length() - 2)
		if key != "":
			result[key] = value
	return result


static func get_value(name: String, cache: Dictionary = {}) -> String:
	if cache.has(name):
		return str(cache[name])
	return OS.get_environment(name).strip_edges()


static func write_override_cfg(cache: Dictionary, path: String = DEFAULT_OVERRIDE_CFG_PATH) -> bool:
	if cache.is_empty():
		return false
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("analytics", "game_key", str(cache.get("GAMEANALYTICS_GAME_KEY", "")))
	config.set_value("analytics", "secret_key", str(cache.get("GAMEANALYTICS_SECRET_KEY", "")))
	var err := config.save(path)
	return err == OK
