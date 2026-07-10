extends SceneTree

const Preflight := preload("res://tests/support/gdscript_warning_preflight.gd")


func _init() -> void:
	var result: Dictionary = Preflight.run()
	if result["ok"]:
		quit(0)
		return
	var failures: Array = result["failures"]
	printerr(
		"Strict GDScript warning preflight failed. Static warning contracts failed:\n"
		+ _join_strings(failures, "\n")
	)
	quit(1)


func _join_strings(values: Array, separator: String) -> String:
	var text: String = ""
	for index: int in range(values.size()):
		if index > 0:
			text += separator
		text += str(values[index])
	return text
