# Architecture

## Core Rule

- Permanent world and UI composition belongs in scenes.
- Runtime behavior lives in the smallest script attached to the node that owns that behavior.
- Cross-system communication uses signals first.
- Autoloads are reserved for settings, logging, analytics facades, and other truly global services.

## Runtime Layers

| Layer | Path | Responsibility |
|---|---|---|
| Root composition | `scenes/game/game_root.tscn` | Wires the replaceable gameplay host, menus, settings, and debug overlay |
| Autoload services | `autoloads/game_manager.gd`, `autoloads/scene_manager.tscn`, `autoloads/audio_manager.gd` | State, fades, and audio playback/settings |
| Logging | `autoloads/debug_log.gd`, `addons/GoLogger/` | Console logging by default; optional GoLogger file logging when a project enables/configures it |
| Analytics | `autoloads/analytics.gd`, `addons/GameAnalytics/` | Inert-by-default analytics facade; credentials are per project |
| Examples | `scenes/examples/2d/`, `scenes/examples/3d/` | Disposable reference scenes for future projects |
| Tests | `tests/unit/`, `tests/integration/`, `tests/performance/` | GUT coverage split by scope |

## Directory Boundaries

| Directory | Use |
|---|---|
| `addons/` | Third-party or internally packaged reusable plugins |
| `assets/` | Source/imported art, audio, fonts, and placeholders |
| `autoloads/` | Small global services only |
| `data/` | JSON, CSV, and balance/content data |
| `design docs/` | Project-specific design notes |
| `dev_guides/` | Engineering contracts and indexes |
| `resources/` | Shared `.tres`, themes, materials, and audio resources |
| `scenes/` | Authored scene composition |
| `scripts/` | Shared runtime code that is not scene-local |
| `tests/` | GUT tests |
| `tools/` | Dev-only scripts and probes |

## Example Scene Boundary

- `scenes/examples/2d/example_2d_scene.tscn` demonstrates a minimal `Node2D` scene with camera, static collision, and simple visuals.
- `scenes/examples/3d/example_3d_scene.tscn` demonstrates a minimal `Node3D` scene with environment, light, camera, static body collision, and a visible mesh.
- These examples are intentionally plain. Copy them only when they match the new project's direction.

## Settings Boundary

- `AudioSettings` persists master, music, and effects volume values to `user://settings.cfg`; see `dev_guides/audio_settings.md` for the bus-routing contract.
- `GraphicsSettings` persists a simple `low` / `balanced` / `high` quality value.
- `DevMode` defaults to `OS.is_debug_build()` and can hold project-local debug flags.

## Logging Boundary

- `DebugLog` prints to the Godot console in every project.
- `GoLogger` is included as an owned/default addon, but its editor plugin and `Log.tscn` autoload are not enabled by default because fresh headless projects need GoLogger user settings before file sessions can start safely.
- Projects that want file logging should configure GoLogger in the editor, enable `res://addons/GoLogger/plugin.cfg`, add `Log="*res://addons/GoLogger/Log.tscn"` to `[autoload]`, and keep `DebugLog` as the stable facade.

## Analytics Boundary

- `Analytics` never stores credentials in this base repository.
- Projects that ship analytics must define credentials, consent behavior, data retention policy, and event cardinality limits before enabling submission.
- Gameplay code should call `Analytics.track_event(...)` or a project-specific wrapper instead of talking to the SDK directly.
