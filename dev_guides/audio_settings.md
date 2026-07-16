# Audio Settings

`AudioSettings` is the persistent backend for the three player-facing volume controls. It stores normalized linear values from `0.0` to `1.0` in the `[audio]` section of `user://settings.cfg` and applies them when the autoload becomes ready.

## Bus Contract

- `Master` is the main volume and receives all audio.
- `Music` sends directly to `Master` and is controlled by `AudioSettings.set_music_volume(...)`.
- `Effects` sends directly to `Master` and is controlled by `AudioSettings.set_effects_volume(...)`.
- `UI` and `World` send to `Effects`; use them for interface feedback and world/gameplay sounds respectively, rather than giving them separate player settings.

Gameplay and UI nodes must assign their `AudioStreamPlayer` bus to `Music`, `UI`, or `World`. New sound categories should send to either `Music` or `Effects` unless the game deliberately adds a new player-facing setting.

## API

- `set_master_volume(value)`, `set_music_volume(value)`, and `set_effects_volume(value)` clamp `value` to `0.0` through `1.0`, apply it immediately, persist it, then emit `volume_changed`.
- `get_master_volume()`, `get_music_volume()`, and `get_effects_volume()` return the current normalized values.
- A value of `0.0` mutes its bus. Positive values are converted to decibels for Godot's audio server.
