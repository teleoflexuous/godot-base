# ProperUI Inventory

ProperUI is owned and can be copied from `rome-farm` when a project needs richer UI behavior. It is not enabled in this base by default so simple projects can stay close to built-in Godot controls.

## Available Addons

| Addon | Use When | Notes |
|---|---|---|
| `properUI_tooltip` | Rich text, arbitrary tooltip scenes, pinned tooltip chains, nested keyword explanations | Strong candidate for complex game UI |
| `properUI_modal` | Modal frames, page hosts, tagged navigation, multi-page choices | Use for structured dialogs rather than ad-hoc overlays |
| `properUI_toast` | Result notifications and stacked feedback | Useful for resource rewards, warnings, and event results |
| `properUI_context_menu` | Right-click/context menus with submenu chains and tooltip handoff | Use when actions are contextual and nested |
| `properUI_drawer` | Drawer-style panels | Use for side panels or persistent secondary surfaces |
| `properUI_transition` | Screen transition host and route registration | Use when transitions become a shared system |
| `properUI_scaleSelector` | Scale/spot selection UI | Specialized; copy only when the interaction fits |

## Decision Rule

- Start with built-in `Control` nodes for static layout.
- Consider ProperUI before creating custom rich tooltips, modal frameworks, toast stacks, context-menu chains, drawer managers, or transition routers.
- If copied, include the addon README and addon-local tests, and document autoload/plugin setup in `project.godot`.

## Source Reference

- Reference implementation: `farm-manager-game/rome-farm/addons/properUI_*`.
- Do not copy Rome project-specific UI scenes as part of the addon unless the addon README explicitly requires them.
