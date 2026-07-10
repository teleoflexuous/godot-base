extends GutHookScript

const Preflight := preload("res://tests/support/gdscript_warning_preflight.gd")


func run() -> void:
	var result: Dictionary = Preflight.run()
	if result["ok"]:
		return
	var failures: Array = result["failures"]
	var gut_logger: Variant = gut.get("logger")
	if gut_logger != null:
		gut_logger.call("error",
			"Strict GDScript warning preflight failed. Static warning contracts failed: "
			+ _join_strings(failures, ", ")
		)
	else:
		push_error(
		"Strict GDScript warning preflight failed. Static warning contracts failed: "
		+ _join_strings(failures, ", ")
	)
	set_exit_code(1)
	abort()


func _join_strings(values: Array, separator: String) -> String:
	var text: String = ""
	for index: int in range(values.size()):
		if index > 0:
			text += separator
		text += str(values[index])
	return text
