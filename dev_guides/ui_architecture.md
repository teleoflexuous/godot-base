# UI Architecture

## Core Rule

- Permanent layout belongs to `Control` scenes and built-in containers.
- Scripts bind data, emit intents, and run transient animation only.
- Cross-system truth belongs in a session store or project-specific model, not individual views.

## Base UI

- `scenes/game/game_root.tscn` supplies a replaceable main-menu → game → pause → game-over/win flow plus settings and debug overlay.
- Projects should replace the game-host panel with their gameplay viewport, preserving the `GameManager` state boundary where useful.
- Keep UI examples small enough that deleting them is safe.

## ProperUI Decision Points

- Check `dev_guides/properui_inventory.md` before custom-building advanced tooltip, modal, toast, drawer, context menu, transition, or scale-selector behavior.
- Use built-in Godot controls when layout and behavior are simple.
- Use ProperUI when the project needs interaction behavior that would otherwise become a bespoke UI framework.

## Theme Rule

- Prefer theme types and theme variations over runtime stylebox duplication.
- Add theme requirements to `dev_guides/theme_component_contract.md` when introducing new reusable UI components.
- Keep placeholder themes simple until a project has visual direction.
