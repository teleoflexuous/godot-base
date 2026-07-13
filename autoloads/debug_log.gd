extends Node

const DEFAULT_CATEGORY: int = 0

func info(message: String) -> void:
	_write("INFO", message)


func warn(message: String) -> void:
	push_warning(message)
	_write("WARN", message)


func error(message: String) -> void:
	push_error(message)
	_write("ERROR", message)


func event(event_name: String, data: Dictionary = {}) -> void:
	_write("EVENT", "%s %s" % [event_name, JSON.stringify(data)])


func _write(level: String, message: String) -> void:
	var formatted: String = "[%s] %s" % [level, message]
	print(formatted)
	var logger: Node = get_node_or_null("/root/Log")
	if logger != null and logger.has_method("entry"):
		logger.call("entry", formatted, DEFAULT_CATEGORY)
