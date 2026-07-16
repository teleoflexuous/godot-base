# Audio Settings

`AudioManager` is the persistent backend for the three player-facing volume controls and owns small music/SFX/UI player pools. It stores normalized linear values from `0.0` to `1.0` in the `[audio]` section of `user://settings.cfg`. `AudioSettings` remains a compatibility facade for existing projects.

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
- Use `AudioManager.play_music(...)`, `play_sfx(...)`, and `play_ui(...)` for simple global playback; scene-local players remain appropriate for authored ambience and diegetic sound.
