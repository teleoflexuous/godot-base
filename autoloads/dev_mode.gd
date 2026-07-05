extends Node

var enabled := false
var flags: Dictionary = {}

func _ready() -> void:
	enabled = OS.is_debug_build()


func set_flag(flag_name: StringName, value: Variant = true) -> void:
	flags[flag_name] = value


func get_flag(flag_name: StringName, default_value: Variant = false) -> Variant:
	return flags.get(flag_name, default_value)


func is_enabled(flag_name: StringName = &"") -> bool:
	if flag_name == &"":
		return enabled
	return enabled and bool(flags.get(flag_name, false))
