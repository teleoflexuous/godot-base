# Testing Strategy

## Default GUT Scope

- `.gutconfig.json` includes project tests only:
- `res://tests/unit/`
- `res://tests/integration/`
- `res://tests/performance/`

## CI / Workflow Scope

- GitHub Actions (`.github/workflows/itch-deploy.yml`) and the local CI helper (`tools/run_ci_checks.ps1`) run only `res://tests/unit/` and `res://tests/integration/` via `-gdir`, and pass `-ginclude_subdirs`. Performance tests are excluded from workflow runs because tiered FPS budgets are not reliable on shared CI runners.
- Performance tests remain part of `.gutconfig.json`, so a local default run (`godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit`) still includes them. Run them on demand with the performance-only command below when changing real-time, rendering, or loading code.

## Test Split

- `tests/unit/`: pure scripts, autoload contracts, and formatting helpers.
- `tests/integration/`: scene loading, node wiring, and multi-system contracts.
- `tests/performance/`: startup, turn/update loops, loading, and rendering-adjacent budgets.
- Addon-local tests should live under `addons/<addon>/tests/` and be run directly when that addon changes.

## Recommended Commands

On Windows, prefer the Godot console executable for shell runs. The GUI executable can hide stdout/stderr, which makes GUT failures look like missing output. Use a unique `--log-file artifacts/<name>.log` per run, and do not run multiple Godot test processes in parallel because Godot's default user log rotation can collide under concurrent headless starts.

Run the local Godot CI validation with `pwsh -File tools/run_ci_checks.ps1`. It runs import, strict warning preflight, the unit and integration GUT suites (performance tests are excluded to match the GitHub workflow), then a release Web export into `artifacts/web-ci/`; it fails on the same script/extension export errors and required Web/GameAnalytics files as GitHub Actions. Set `GODOT_BIN` when Godot is not on `PATH`; on Windows the helper rejects a non-console executable instead of allowing a false local pass.

For import checks, set `APPDATA` and `LOCALAPPDATA` to fresh directories under `artifacts/` before launching Godot. This keeps editor settings writable and prevents stale editor layouts from loading addon docks during headless import.

### Before running tests: warnings/errors check

Run a warnings/errors check before the suite (and before committing). A non-zero exit or `SCRIPT ERROR` lines mean stop and fix first.

Whole-project import check (surfaces parse errors and GDScript warnings):

```text
$env:APPDATA = "$PWD/artifacts/appdata_import"
$env:LOCALAPPDATA = "$PWD/artifacts/localappdata_import"
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-import.log --path . --import
```

Strict project script warning preflight:

```text
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-preflight.log --path . -s res://tools/run_gdscript_warning_preflight.gd
```

Single-script parse check while iterating on one file:

```text
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-check.log --path . --check-only --script res://path/to/script.gd
```

GUT fails tests on errors by default: `failure_error_types` is pinned to `["engine", "gut", "push_error"]`, so engine errors, GUT-internal errors, and `push_error()` calls during a test fail that test. Do not add `-gerrors_do_not_cause_failure` or `-gno_error_tracking` unless intentionally suppressing.

`.gutconfig.json` also runs `res://tests/support/gdscript_warning_preflight_hook.gd` as `pre_run_script`. That hook reloads project scripts under `autoloads/`, `scenes/`, `scripts/`, and `tools/` with cache ignored and GDScript warnings as errors before normal tests run. This catches parser warnings such as native method signature conflicts even when GUT collection would otherwise load test scripts with warnings disabled.

GDScript warning levels live under `debug/gdscript/warnings/*` in project settings; inspect and manage them with GUT's warnings tool (`++` separates engine args from script args, see `addons/gut/cli/change_project_warnings.gd`):

```text
godot --headless --path . -s addons/gut/cli/change_project_warnings.gd ++ -print current
godot --headless --path . -s addons/gut/cli/change_project_warnings.gd ++ -diff current,all_warn
godot --headless --path . -s addons/gut/cli/change_project_warnings.gd ++ -apply all_warn
```

`-apply all_warn` writes `project.godot`; restart Godot after applying.

### GUT suites

Default project suite:

```text
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-gut-all.log --path . -s res://addons/gut/gut_cmdln.gd -gexit
```

Web export browser smoke test after exporting `builds/web/`:

```text
node tools/web_smoke_check.cjs builds/web
```

For the local CI helper output, run the same optional browser check against `artifacts/web-ci/` after installing Playwright and Chromium:

```text
node tools/web_smoke_check.cjs artifacts/web-ci
```

Unit tests only:

```text
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-gut-unit.log --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Integration tests only:

```text
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-gut-integration.log --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit
```

Performance tests only:

```text
Godot_v4.7-stable_win64_console.exe --headless --log-file artifacts/godot-gut-performance.log --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/performance -gexit
```

Performance tests should run small-to-large tiers inside each performance class. If the first tier fails, record the shared performance abort state and return before expensive tiers; later performance scripts should skip when that abort state is set.

## Coverage Expectations

- Every reusable autoload should have a unit contract test.
- Every sample scene should have a load/smoke integration test.
- Web release candidates should pass a real browser smoke test against the exported HTML build, not just a headless Godot export.
- Every project-specific runtime system should name its owning scene/script/test/docs in `component_index.md`.

## Doc Sync Checklist

When renaming scenes, nodes, scripts, or public exported paths:

- Update the owning runtime doc in `dev_guides/`.
- Update matching design intent in `design docs/` only when player-facing behavior or roadmap language changes.
- Update `dev_guides/component_index.md` for renamed components or test ownership.
- Update affected GUT integration tests in the same change.
