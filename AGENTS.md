# Agent Notes

## Start Here

- Check Godot 4.7 docs before and after implementing Godot behavior (Context7 library `/websites/godotengine_en_4_7`).
- Read the smallest relevant project guide through `dev_guides/design_doc_index.md`.
- Keep docs and tests minimal, current, and tied to the scenes/scripts they describe.
- Treat `scenes/examples/` as reference material, not required architecture.

## Working Rule

- Prefer scenes, nodes, signals, exported properties, and built-in Godot behavior over scripts.
- Use atomic node-local scripts only when a node needs behavior that cannot be represented clearly in the scene tree.
- Keep common scripts at the lowest shared directory depth for the scenes that use them.
- Put truly global scripts only under `autoloads/` or a documented global utility directory.
- Keep source assets in `assets/`, content data in `data/`, scene composition in `scenes/`, reusable resources in `resources/`, and dev-only helpers in `tools/`.
- `assets/placeholders/` and `scenes/examples/` are allowed in early projects, but production scenes should promote real assets and delete unused examples.

## Runtime Architecture

- Scene roots own composition and wire scene-local systems.
- Broad cross-system communication should use typed signals or a documented bus.
- Long-lived settings belong in small autoloads with clear save boundaries.
- Audio routing should use named buses from `default_bus_layout.tres`.
- Analytics is available through the `Analytics` autoload, but credentials and consent behavior must be configured per game before shipping.

## Documentation Index

- [`dev_guides/design_doc_index.md`](dev_guides/design_doc_index.md) maps project docs to systems and assets.
- [`dev_guides/architecture.md`](dev_guides/architecture.md) explains the reusable scene-first architecture.
- [`dev_guides/scene_node_guide.md`](dev_guides/scene_node_guide.md) lists preferred Godot nodes and scripting boundaries.
- [`dev_guides/ui_architecture.md`](dev_guides/ui_architecture.md) covers UI scene/script split and ProperUI decision points.
- [`dev_guides/component_index.md`](dev_guides/component_index.md) maps components to docs and tests.
- [`dev_guides/theme_component_contract.md`](dev_guides/theme_component_contract.md) defines baseline theme expectations.
- [`dev_guides/testing_strategy.md`](dev_guides/testing_strategy.md) gives GUT commands and test split.
- [`dev_guides/performance_budget.md`](dev_guides/performance_budget.md) gives starting performance targets.
- [`dev_guides/properui_inventory.md`](dev_guides/properui_inventory.md) documents owned ProperUI addons that can be copied into projects.
- [`dev_guides/addon_packaging.md`](dev_guides/addon_packaging.md) describes reusable addon layout conventions.

## Addon Decisions

- Included base addons are `gut`, `GoLogger`, and `GameAnalytics`.
- `gut` and `GameAnalytics` are enabled by default. `GoLogger` is included but disabled until a project configures its file logging singleton.
- ProperUI is owned and available, but intentionally not enabled by default. Check `dev_guides/properui_inventory.md` before building custom UI behavior that may already exist in ProperUI.
- Domain-specific Rome systems are not part of this base unless a future project explicitly promotes them.

## Testing

- Run a warnings/errors check before the suite (and before committing):
  - Whole-project import check; surfaces parse errors and GDScript warnings, a non-zero exit or `SCRIPT ERROR` lines mean stop and fix first: `godot --headless --path . --import`
  - Single-script parse check while iterating on one file: `godot --headless --path . --check-only --script res://path/to/script.gd`
- GUT fails tests on errors by default: `failure_error_types` is pinned to `["engine", "gut", "push_error"]`, so engine errors, GUT-internal errors, and `push_error()` calls during a test fail that test. Do not add `-gerrors_do_not_cause_failure` or `-gno_error_tracking` unless intentionally suppressing.
- GDScript warning levels live under `debug/gdscript/warnings/*` in project settings; inspect and manage them with GUT's warnings tool (`++` separates engine args from script args, see `addons/gut/cli/change_project_warnings.gd`):
  - Print current: `godot --headless --path . -s addons/gut/cli/change_project_warnings.gd ++ -print current`
  - Diff vs all-warn: `godot --headless --path . -s addons/gut/cli/change_project_warnings.gd ++ -diff current,all_warn`
  - Apply all-warn (writes `project.godot`; restart Godot after): `godot --headless --path . -s addons/gut/cli/change_project_warnings.gd ++ -apply all_warn`
- Default project suite: `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit`.
- Target unit tests while building: `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`.
- Target integration tests after scene wiring: `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit`.
- Target performance tests after real-time, rendering, or loading work: `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/performance -gexit`.
- Local pre-push CI validation: `pwsh -File tools/run_ci_checks.ps1` (runs import, warning preflight, unit+integration GUT, and a clean Web export matching the GitHub workflow).
