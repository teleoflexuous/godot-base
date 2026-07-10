extends GutTest

const Preflight := preload("res://tests/support/gdscript_warning_preflight.gd")

const GUT_CONFIG_PATH := "res://.gutconfig.json"
const PREFLIGHT_SCRIPT_PATH := "res://tests/support/gdscript_warning_preflight.gd"
const PREFLIGHT_HOOK_PATH := "res://tests/support/gdscript_warning_preflight_hook.gd"
const PREFLIGHT_RUNNER_PATH := "res://tools/run_gdscript_warning_preflight.gd"
const LOCAL_CI_RUNNER_PATH := "res://tools/run_ci_checks.ps1"
const TESTING_DOC_PATH := "res://dev_guides/testing_strategy.md"
const WORKFLOW_PATH := "res://.github/workflows/itch-deploy.yml"


func test_gut_config_runs_strict_warning_preflight() -> void:
	var config := _read_json(GUT_CONFIG_PATH)
	assert_eq(config.get("pre_run_script", ""), PREFLIGHT_HOOK_PATH)
	assert_eq(config.get("failure_error_types", []), ["engine", "gut", "push_error"])


func test_strict_warning_preflight_uses_static_project_scans() -> void:
	var source := FileAccess.get_file_as_string(PREFLIGHT_SCRIPT_PATH)
	assert_true(source.contains("WARNING_ERROR: int = 2"))
	assert_true(source.contains("PROJECT_ROOTS: Array[String]"))
	assert_false(source.contains("\"res://addons\""))
	assert_true(source.contains("_scan_static_warning_failures"))


func test_preflight_flags_node_get_path_signature_conflicts() -> void:
	var failures: Array[String] = Preflight._scan_static_warning_failures(
		"res://probe.gd",
		"extends Node\n\nfunc " + "get_path() -> int:\n\treturn 1\n"
	)
	assert_eq(failures.size(), 1)
	assert_true(failures[0].contains("Node.get_path() -> NodePath"))


func test_preflight_allows_exact_node_get_path_signature() -> void:
	var failures: Array[String] = Preflight._scan_static_warning_failures(
		"res://probe.gd",
		"extends Node\n\nfunc " + "get_path() -> NodePath:\n\treturn NodePath(\".\")\n"
	)
	assert_true(failures.is_empty())


func test_testing_strategy_documents_preflight_as_part_of_gut() -> void:
	var doc := FileAccess.get_file_as_string(TESTING_DOC_PATH)
	assert_true(doc.contains("pre_run_script"))
	assert_true(doc.contains("gdscript_warning_preflight_hook.gd"))
	assert_true(doc.contains("run_gdscript_warning_preflight.gd"))
	assert_true(doc.contains("warnings as errors"))


func test_ci_runs_preflight_before_gut() -> void:
	var workflow_text := FileAccess.get_file_as_string(WORKFLOW_PATH)
	var import_index := workflow_text.find("godot --headless --path . --import")
	var preflight_index := workflow_text.find("tools/run_gdscript_warning_preflight.gd")
	var gut_index := workflow_text.find("addons/gut/gut_cmdln.gd")
	assert_gt(import_index, -1)
	assert_gt(preflight_index, import_index)
	assert_gt(gut_index, preflight_index)


func test_preflight_runner_exists() -> void:
	assert_true(FileAccess.file_exists(PREFLIGHT_RUNNER_PATH))


func test_preflight_entry_points_preload_the_shared_implementation() -> void:
	for entry_point_path: String in [PREFLIGHT_HOOK_PATH, PREFLIGHT_RUNNER_PATH]:
		var source: String = FileAccess.get_file_as_string(entry_point_path)
		assert_true(source.contains('preload("res://tests/support/gdscript_warning_preflight.gd")'))


func test_local_ci_runner_requires_the_windows_console_binary() -> void:
	var source: String = FileAccess.get_file_as_string(LOCAL_CI_RUNNER_PATH)
	assert_true(source.contains('notlike "*_console"'))
	assert_true(source.contains('"--import"'))
	assert_true(source.contains("res://tools/run_gdscript_warning_preflight.gd"))
	assert_true(source.contains("res://addons/gut/gut_cmdln.gd"))
	assert_true(source.contains('"--export-release", "Web"'))
	assert_true(source.contains("godot-ci-web-export.log"))
	assert_true(source.contains("Godot web export reported script or extension errors."))
	assert_true(source.contains("GameAnalytics.js"))
	assert_true(source.contains("libGodotGameAnalytics.wasm"))


func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
