extends SceneTree

const CONFIG_PATH: String = "res://template_project.cfg"
const CANONICAL_REPOSITORY: String = "teleoflexuous/godot-base"


func _init() -> void:
	var source_repository: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--source-repository="):
			source_repository = argument.trim_prefix("--source-repository=")
	if source_repository == CANONICAL_REPOSITORY:
		quit(OK)
		return
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		push_error("Missing template_project.cfg. Run tools/initialize_project.gd in a generated repository.")
		quit(1)
		return
	var state: String = str(config.get_value("project", "state", "template"))
	var release_target: String = str(config.get_value("project", "release_target", "unconfigured"))
	if state != "configured" or not release_target in ["none", "itch"]:
		push_error("This generated repository must be initialized. Run tools/initialize_project.gd -- --name=YourGame --release-target=none|itch and commit template_project.cfg.")
		quit(1)
		return
	quit(OK)
