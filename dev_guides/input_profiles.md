# Input Profiles

`addons/guide/` vendors G.U.I.D.E v0.14.0 and `GUIDE` is available as an autoload. The base keeps Godot InputMap actions as the portable gameplay contract and stores the selected profile through `InputProfiles`.

| Profile | Intended devices |
|---|---|
| `character_keyboard` | Keyboard character movement |
| `character_keyboard_touch_gamepad` | Keyboard plus touch controls and generic gamepad |
| `character_keyboard_mouse` | Keyboard/mouse character controls |
| `character_keyboard_mouse_touch_gamepad` | All character inputs |
| `pointer_mouse_touch` | Mouse/touch RTS or management controls |

Touch controls must be represented by project UI scenes; Godot's InputMap does not turn screen touches into movement on its own. Use G.U.I.D.E mapping contexts when a project needs runtime rebinding, prompts, or input-source arbitration.
