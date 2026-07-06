extends GutTest

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const WORKFLOW_PATH := "res://.github/workflows/itch-deploy.yml"
const RELEASE_DOC_PATH := "res://dev_guides/release_automation.md"


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected file to exist: %s" % path)
	if file == null:
		return ""
	return file.get_as_text()


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
	assert_true(workflow_text.contains("uses: lihop/setup-godot@v3"))
	assert_true(workflow_text.contains("needs: validate_itch_setup"))
	assert_true(workflow_text.contains("godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit"))
	assert_true(workflow_text.contains('godot --headless --path . --export-release "$WEB_EXPORT_PRESET" "$WEB_BUILD_DIR/index.html"'))
	assert_true(workflow_text.contains('tee "$WEB_BUILD_DIR/export.log"'))
	assert_true(workflow_text.contains("Godot export reported script or extension errors."))
	assert_true(workflow_text.contains("ERROR: Failed to load script"))
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
	assert_true(doc_text.contains("workflow intentionally fails"))
	assert_true(doc_text.contains("project type to `HTML`"))
	assert_true(doc_text.contains("playable in browser"))
