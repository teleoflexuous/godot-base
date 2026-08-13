# Input Profiles

`addons/guide/` vendors G.U.I.D.E v0.14.0 and `GUIDE` is available as an autoload. The base keeps Godot InputMap actions as the portable gameplay contract. `InputSettings` stores an independent device-capability mask; `InputProfiles` remains a deprecated compatibility facade that migrates old IDs without adding devices.

| Capability bundle | Devices |
|---|---|
| `all` | Keyboard, mouse, gamepad, touch (template default) |
| `desktop` | Keyboard and mouse |
| `desktop_gamepad` | Keyboard, mouse, and gamepad |
| `mobile` | Touch and gamepad |
| `gamepad` | Gamepad only |
| `custom` | Any explicitly selected bitmask |

Camera genre/preset and devices are separate decisions. `ProperCameraGuideDefaultsBuilder` creates semantic actions and one mapping context per device family. The owning scene routes the saved mask into `ProperCameraGuideContextRouter`, selects only the active camera genre, and disables camera contexts for pause, menus, cutscenes, and inactive local cameras. The router never calls GUIDE's unrelated-context replacement APIs.

Mouse/touch deltas and keyboard/stick rates remain distinct at the adapter boundary. Touch pinch/twist actions are cumulative from gesture start and are fixed because GUIDE v0.14 cannot detect touch remaps. Button slots composing camera axes override action remapping metadata so keys and mouse-wheel buttons can be rebound. Prompt UI should use the active-context formatter and refresh on GUIDE mapping changes.

Both Godot pointing emulation directions are disabled. Use a dedicated development-only touch simulation option instead of enabling mouse and touch contexts over emulated events.
