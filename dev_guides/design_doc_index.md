# Design Doc Index

Use this file to map project-specific design docs to implementation owners.

| Topic | Design Doc | Components | Status |
|---|---|---|---|
| Base scaffold | `dev_guides/architecture.md` | Root scene, autoloads, examples | Current |
| Audio settings | `dev_guides/audio_settings.md` | Audio bus layout, `AudioSettings` autoload | Current |
| UI approach | `dev_guides/ui_architecture.md` | Root UI, future HUD/menu scenes | Current |
| Input profiles | `dev_guides/input_profiles.md` | G.U.I.D.E, InputMap, player scenes | Current |
| Template lifecycle | `dev_guides/template_lifecycle.md` | Initialization and GitHub Actions | Current |
| 2D shader library | `dev_guides/2d_shader_library.md` | `resources/shaders/` | Current on `2d` |
| ProperUI options | `dev_guides/properui_inventory.md` | Optional owned UI addons | Current |
| Release automation | `dev_guides/release_automation.md` | GitHub Actions, Godot export preset, itch deployment | Current |

## Rules

- Keep large design docs out of default agent context unless they are directly relevant.
- Add a row here when a new design doc controls implementation decisions.
- Remove stale docs or mark them `Archived` when systems are deleted.
