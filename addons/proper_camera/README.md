# ProperCamera

ProperCamera provides reusable `ProperCameraRig2D` and `ProperCameraRig3D` scenes. They separate camera state, follow logic, input, effects, and native output; project scene roots own composition and target wiring.

## Quick start

1. Install the addon through Godot Asset Store or copy this folder to
   `res://addons/proper_camera/`. No plugin or autoload must be enabled.
2. Instance `scenes/camera_rig_2d.tscn` or `scenes/camera_rig_3d.tscn`.
3. Assign a resource from `presets/` or duplicate a preset for the game.
4. Call `set_follow_target(target, true)` from the owning scene.
5. Use direct commands or add `ProperCameraInputMapAdapter`. Enable `install_missing_actions` only for prototypes/examples.

`R` recenters, `F` toggles follow, and `V` toggles the character preset's first/third-person view. Positive zoom input always means zoom in. Normalized zoom is `0` at the close end and `1` at the far end.

## Optional integrations

The core has no required dependencies. G.U.I.D.E. input/remapping support is distributed as a separate companion integration, so installing ProperCamera never requires vendor files or an autoload. Phantom Camera is reflection-only and optional; select its output driver only after binding an explicitly authored PCam.

## Runtime contract

- `F` starts follow and immediately frames the assigned target. A second press
  releases follow without moving the current free shot.
- `R` clears a follow offset and reacquires/centers an assigned target. It
  preserves the current 3D yaw, pitch, and zoom.
- In 3D management/RTS controls, `W` and left-stick-up move toward the top of
  the current view; `S` and left-stick-down move back. Middle-mouse and touch
  drag retain grab-the-world semantics.
- Positive zoom input always moves toward the close end; normalized zoom is
  `0` at the close end and `1` at the far end.
- Native active occlusion latches an escape route while the authored centered
  route is blocked. The SpringArm remains the only final collision solver.
- The core has no required dependency. Phantom Camera is reflection-only;
  G.U.I.D.E. belongs in a project companion integration.

See `docs/contracts.md` for detailed follow, zoom, collision, fade, and
detail-band behavior. The included examples and tests are source material and
are not in Store archives.

Copyright (c) 2026 teleoflexuous. Licensed under the [MIT License](LICENSE.md).
