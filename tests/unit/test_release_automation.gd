extends GutTest

const CI_PATH: String = "res://.github/workflows/ci.yml"
const SYNC_PATH: String = "res://.github/workflows/sync-2d.yml"
const GUIDE_LOCK_PATH: String = "res://third_party/guide.lock"


func _read(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	return "" if file == null else file.get_as_text()


func test_template_ci_enforces_lifecycle_but_keeps_canonical_source_valid() -> void:
	var workflow: String = _read(CI_PATH)
	assert_true(workflow.contains("verify_template_lifecycle.gd"))
	assert_true(workflow.contains("release_readiness:"))
	assert_true(workflow.contains("Credential-free web export"))
	assert_false(workflow.contains("ITCH_DEPLOY_ENABLED"))


func test_maintenance_workflows_and_vendor_lock_exist() -> void:
	assert_true(_read(SYNC_PATH).contains("--base 2d --head main"))
	assert_true(_read(GUIDE_LOCK_PATH).contains("version=v0.14.0"))
	assert_true(FileAccess.file_exists("res://addons/guide/LICENSE.md"))
