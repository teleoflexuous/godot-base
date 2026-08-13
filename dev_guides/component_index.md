# Component Index

Keep this table in parity with scene/script/test changes. Update it when adding, removing, or renaming components.

| Component | Scene | Script | Docs | Tests | Completion |
|---|---|---|---|---|---|
| Game shell | `scenes/game/game_root.tscn` | `scenes/game/game_root.gd` | `architecture.md`, `ui_architecture.md` | `tests/integration/test_example_scenes.gd` | Implemented |
| Game manager | n/a | `autoloads/game_manager.gd` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Implemented |
| Scene manager | `autoloads/scene_manager.tscn` | `autoloads/scene_manager.gd` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Implemented |
| Audio manager | n/a | `autoloads/audio_manager.gd` | `audio_settings.md` | `tests/unit/test_base_autoloads.gd` | Implemented |
| 2D starters | `scenes/characters/`, `scenes/components/` | node-local scripts | `input_profiles.md` | `tests/integration/test_example_scenes.gd` | Implemented |
| Example 2D scene | `scenes/examples/2d/example_2d_scene.tscn` | n/a | `architecture.md`, `scene_node_guide.md` | `tests/integration/test_example_scenes.gd` | Example |
| Example 3D scene | `scenes/examples/3d/example_3d_scene.tscn` | n/a | `architecture.md`, `scene_node_guide.md` | `tests/integration/test_example_scenes.gd` | Example |
| Camera rigs | `addons/camera_rigs/scenes/` | `addons/camera_rigs/runtime/` | `camera_addon.md`, addon README | `addons/camera_rigs/tests/` | Implemented |
| Input capability settings | n/a | `autoloads/input_settings.gd`, `scripts/input/input_capabilities.gd` | `input_profiles.md`, `template_lifecycle.md` | `tests/unit/test_input_capabilities.gd` | Implemented |
| Camera preferences | n/a | `autoloads/camera_settings.gd` | `camera_addon.md` | addon settings tests | Implemented |
| Debug logging | n/a | `autoloads/debug_log.gd`, optional `addons/GoLogger/Log.tscn` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Stubbed |
| Dev mode | n/a | `autoloads/dev_mode.gd` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Stubbed |
| Audio settings | n/a | `autoloads/audio_settings.gd` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Stubbed |
| Graphics settings | n/a | `autoloads/graphics_settings.gd`, `scripts/common/graphics_quality_tiers.gd` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Stubbed |
| Analytics facade | n/a | `autoloads/analytics.gd`, `addons/GameAnalytics/` | `architecture.md` | `tests/unit/test_base_autoloads.gd` | Stubbed |
| Release automation | n/a | `.github/workflows/ci.yml`, `export_presets.cfg` | `release_automation.md` | `tests/unit/test_release_automation.gd` | Verified |
| Test framework | n/a | `addons/gut/` | `testing_strategy.md` | self-hosted GUT commands | Verified by run |

Completion values are `Stubbed`, `Implemented`, `Verified`, `Example`, or `Deferred`.
