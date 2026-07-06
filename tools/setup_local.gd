extends SceneTree

const EnvFile = preload("res://scripts/common/env_file.gd")

const OVERRIDE_CFG_PATH := "res://override.cfg"

const REQUIRED_KEYS := [
	"ITCH_DEPLOY_ENABLED",
	"ITCH_PROJECT",
	"BUTLER_API_KEY",
	"GAMEANALYTICS_GAME_KEY",
	"GAMEANALYTICS_SECRET_KEY"
]


func _init() -> void:
	var env := EnvFile.load()
	if env.is_empty():
		print("No .env file found at res://.env. Copy .env.example to .env and fill in values.")
		quit(1)
		return
	var missing: Array[String] = []
	for key in REQUIRED_KEYS:
		if not env.has(key) or str(env[key]).strip_edges() == "":
			missing.append(key)
	if not missing.is_empty():
		print("Missing required keys in .env: " + ", ".join(missing))
		quit(1)
		return
	if not EnvFile.write_override_cfg(env, OVERRIDE_CFG_PATH):
		print("Failed to write override.cfg.")
		quit(1)
		return
	print("Local setup complete.")
	print("  .env loaded with %d keys." % env.size())
	print("  override.cfg refreshed with analytics/game_key and analytics/secret_key.")
	quit(0)
