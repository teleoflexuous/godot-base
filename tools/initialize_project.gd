extends SceneTree

const CONFIG_PATH: String = "res://template_project.cfg"
const INPUT_CAPABILITIES: Array[String] = [
	"all",
	"desktop",
	"desktop_gamepad",
	"mobile",
	"gamepad",
	"custom",
]


func _init() -> void:
	var project_name: String = ""
	var release_target: String = ""
	var input_capability: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--name="):
			project_name = argument.trim_prefix("--name=")
		elif argument.begins_with("--release-target="):
			release_target = argument.trim_prefix("--release-target=")
		elif argument.begins_with("--input-capability="):
			input_capability = argument.trim_prefix("--input-capability=")
	if (
		project_name.is_empty()
		or not release_target in ["none", "itch"]
		or not input_capability in INPUT_CAPABILITIES
	):
		push_error(
			"Usage: godot --headless --path . -s res://tools/initialize_project.gd -- "
			+ "--name=YourGame --release-target=none|itch "
			+ "--input-capability=all|desktop|desktop_gamepad|mobile|gamepad|custom"
		)
		quit(1)
		return
	ProjectSettings.set_setting("application/config/name", project_name)
	var save_result: Error = ProjectSettings.save()
	if save_result != OK:
		push_error("Could not update project.godot")
		quit(1)
		return
	var config: ConfigFile = ConfigFile.new()
	config.set_value("project", "state", "configured")
	config.set_value("project", "release_target", release_target)
	config.set_value("project", "input_capability_set", true)
	config.set_value("project", "input_capability", input_capability)
	if config.save(CONFIG_PATH) != OK:
		push_error("Could not update template_project.cfg")
		quit(1)
		return
	print(
		"Initialized %s with release target %s and input capability %s. Commit project.godot and template_project.cfg."
		% [project_name, release_target, input_capability]
	)
	quit(OK)
