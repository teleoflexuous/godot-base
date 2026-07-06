extends GutTest

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const OVERRIDE_CFG_PATH := "res://override.cfg"
const WORKFLOW_PATH := "res://.github/workflows/itch-deploy.yml"
const RELEASE_DOC_PATH := "res://dev_guides/release_automation.md"


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected file to exist: %s" % path)
	if file == null:
		return ""
	return file.get_as_text()


func _required_env(name: String, guidance: String) -> String:
	var value := OS.get_environment(name).strip_edges()
	assert_ne(value, "", guidance)
	return value


func _require_override_cfg() -> ConfigFile:
	var config := ConfigFile.new()
	var result := config.load(OVERRIDE_CFG_PATH)
	assert_eq(result, OK, "Create override.cfg in the project root or let CI generate it from GAMEANALYTICS_* secrets before running the default suite.")
	return config


func _setting_as_string(path: String) -> String:
	if not ProjectSettings.has_setting(path):
		return ""
	var value = ProjectSettings.get_setting_with_override(path)
	return "" if value == null else str(value)


func test_itch_deploy_enable_flag_is_configured() -> void:
	assert_eq(OS.get_environment("ITCH_DEPLOY_ENABLED").strip_edges(), "true", "Set ITCH_DEPLOY_ENABLED=true before running the default suite or configure the GitHub repository variable.")


func test_itch_project_is_configured() -> void:
	var project := _required_env("ITCH_PROJECT", "Set ITCH_PROJECT to lowercase user/game before running the default suite.")
	if project == "":
		return
	var regex := RegEx.new()
	assert_eq(regex.compile("^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$"), OK)
	assert_not_null(regex.search(project), "ITCH_PROJECT must use lowercase user/game format, for example studio-name/my-game.")


func test_butler_api_key_is_configured() -> void:
	_required_env("BUTLER_API_KEY", "Export BUTLER_API_KEY before running the default suite or configure the GitHub repository secret.")


func test_gameanalytics_game_key_is_configured() -> void:
	_required_env("GAMEANALYTICS_GAME_KEY", "Export GAMEANALYTICS_GAME_KEY before running the default suite or configure the GitHub repository secret.")


func test_gameanalytics_secret_key_is_configured() -> void:
	_required_env("GAMEANALYTICS_SECRET_KEY", "Export GAMEANALYTICS_SECRET_KEY before running the default suite or configure the GitHub repository secret.")


func test_override_cfg_exists_for_analytics_settings() -> void:
	_require_override_cfg()


func test_override_cfg_contains_gameanalytics_keys() -> void:
	var config := _require_override_cfg()
	if not FileAccess.file_exists(OVERRIDE_CFG_PATH):
		return
	assert_ne(str(config.get_value("analytics", "game_key", "")).strip_edges(), "", "Add analytics/game_key to override.cfg or let CI generate it from GAMEANALYTICS_GAME_KEY.")
	assert_ne(str(config.get_value("analytics", "secret_key", "")).strip_edges(), "", "Add analytics/secret_key to override.cfg or let CI generate it from GAMEANALYTICS_SECRET_KEY.")


func test_project_settings_pick_up_gameanalytics_override_values() -> void:
	var expected_game_key := OS.get_environment("GAMEANALYTICS_GAME_KEY").strip_edges()
	var expected_secret_key := OS.get_environment("GAMEANALYTICS_SECRET_KEY").strip_edges()
	if expected_game_key == "" or expected_secret_key == "":
		assert_true(true)
		return
	assert_eq(_setting_as_string("analytics/game_key"), expected_game_key, "analytics/game_key should come from override.cfg and match GAMEANALYTICS_GAME_KEY.")
	assert_eq(_setting_as_string("analytics/secret_key"), expected_secret_key, "analytics/secret_key should come from override.cfg and match GAMEANALYTICS_SECRET_KEY.")


func test_analytics_autoload_enables_gameanalytics_when_configured() -> void:
	if _setting_as_string("analytics/game_key") == "" or _setting_as_string("analytics/secret_key") == "":
		assert_true(true)
		return
	assert_true(Engine.has_singleton("GameAnalytics"), "GameAnalytics singleton should be available when the addon binaries are present for this platform.")
	assert_true(Analytics.enabled, "Analytics should enable itself once override.cfg provides analytics keys and the GameAnalytics singleton loads.")


func test_web_export_preset_is_committed_for_ci_exports() -> void:
	var preset_text := _read_text(EXPORT_PRESETS_PATH)
	assert_true(preset_text.contains('name="Web"'))
	assert_true(preset_text.contains('platform="Web"'))
	assert_true(preset_text.contains('export_path="builds/web/index.html"'))
	assert_true(preset_text.contains('variant/thread_support=false'))
	assert_true(preset_text.contains('exclude_filter=".github/*,.opencode/*,addons/GoLogger/*,addons/gut/*'))
	assert_true(preset_text.contains('tests/*'))


func test_itch_workflow_runs_tests_exports_web_and_deploys_from_main() -> void:
	var workflow_text := _read_text(WORKFLOW_PATH)
	assert_true(workflow_text.contains("validate_itch_setup:"))
	assert_true(workflow_text.contains("pull_request:"))
	assert_true(workflow_text.contains("push:"))
	assert_true(workflow_text.contains("- main"))
	assert_true(workflow_text.contains("ITCH_DEPLOY_ENABLED must be set to true for this workflow to pass."))
	assert_true(workflow_text.contains("Missing repository secret GAMEANALYTICS_GAME_KEY."))
	assert_true(workflow_text.contains("Missing repository secret GAMEANALYTICS_SECRET_KEY."))
	assert_true(workflow_text.contains("uses: lihop/setup-godot@v3"))
	assert_true(workflow_text.contains("needs: validate_itch_setup"))
	assert_true(workflow_text.contains("Write analytics override configuration"))
	assert_true(workflow_text.contains("cat <<EOF > override.cfg"))
	assert_true(workflow_text.contains("godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit"))
	assert_true(workflow_text.contains('godot --headless --path . --export-release "$WEB_EXPORT_PRESET" "$WEB_BUILD_DIR/index.html"'))
	assert_true(workflow_text.contains('tee "$WEB_BUILD_DIR/export.log"'))
	assert_true(workflow_text.contains("Godot export reported script or extension errors."))
	assert_true(workflow_text.contains("ERROR: Failed to load script"))
	assert_true(workflow_text.contains("Validate exported web files"))
	assert_true(workflow_text.contains("Missing GameAnalytics web artifact"))
	assert_true(workflow_text.contains("uses: actions/upload-artifact@v4"))
	assert_true(workflow_text.contains("Missing repository variable ITCH_PROJECT. Expected format: user/game"))
	assert_true(workflow_text.contains("Invalid ITCH_PROJECT value '$ITCH_PROJECT'. Expected lowercase user/game."))
	assert_true(workflow_text.contains("Missing repository secret BUTLER_API_KEY."))
	assert_true(workflow_text.contains("if: github.event_name == 'push' && github.ref == 'refs/heads/main'"))
	assert_true(workflow_text.contains('butler-bin/butler push "$WEB_BUILD_DIR" "$ITCH_PROJECT:web"'))
	assert_true(workflow_text.contains("--if-changed"))
	assert_true(workflow_text.contains("--userversion"))


func test_release_automation_doc_lists_required_setup() -> void:
	var doc_text := _read_text(RELEASE_DOC_PATH)
	assert_true(doc_text.contains("ITCH_DEPLOY_ENABLED"))
	assert_true(doc_text.contains("ITCH_PROJECT"))
	assert_true(doc_text.contains("BUTLER_API_KEY"))
	assert_true(doc_text.contains("GAMEANALYTICS_GAME_KEY"))
	assert_true(doc_text.contains("GAMEANALYTICS_SECRET_KEY"))
	assert_true(doc_text.contains("override.cfg"))
	assert_true(doc_text.contains("workflow intentionally fails"))
	assert_true(doc_text.contains("project type to `HTML`"))
	assert_true(doc_text.contains("playable in browser"))
