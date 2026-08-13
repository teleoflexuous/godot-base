# Camera Rigs

Scene-first 2D and 3D cameras for Godot 4.7. The core rigs accept semantic commands and do not read hardware directly. InputMap and G.U.I.D.E. v0.14 adapters, camera preferences, LOD/detail bindings, occluder fading, motion effects, examples, and an optional Phantom Camera bridge are included as separate layers.

## Install and start

Copy `addons/camera_rigs/` into a Godot 4.7 project. No plugin or addon autoload is required.

1. Instance `scenes/camera_rig_2d.tscn` or `scenes/camera_rig_3d.tscn` below the gameplay scene root.
2. Assign one of the resources in `presets/`, or duplicate it for the game.
3. Assign a follow target with `set_follow_target()`. Losing that node holds the last view and emits `target_lost`.
4. Drive the rig directly, add `CameraInputMapAdapter`, or create ready-to-use G.U.I.D.E. actions and device contexts with `CameraGuideDefaultsBuilder.build()`.
5. Let the owning gameplay scene enable its camera contexts. Do not leave several genre contexts active at once.

Positive zoom input always means zoom in. `zoom_normalized` is `0` at the close end and `1` at the far end.

```gdscript
var defaults: CameraGuideDefaults = CameraGuideDefaultsBuilder.build()
$CameraGuideAdapter.actions = defaults.actions
$CameraGuideContextRouter.context_set = defaults.context_set
$CameraGuideContextRouter.set_device_mask(InputSettings.capability_mask)
$CameraRig3D.set_follow_target($Player, true)
```

## Presets

- `2d_management`: free/break-on-pan, drag/edge pan, pointer-anchored zoom and map bounds.
- `2d_platformer`: hard follow, dead zone, look-ahead, separately smoothed axes, peek, fixed player zoom.
- `3d_character`: target orbit, dolly zoom, first/third-person zoom transition, SpringArm pull-in and optional active angle search.
- `3d_management`: ground-focus pan/orbit, cursor-ground zoom, authored angle curve, bounds and terrain clearance.
- `3d_rts_moba`: fixed orientation, modest zoom, free/target-follow controls, fading-friendly occlusion policy.

All presets are starting values, not separate controller implementations.

## Public camera contract

Both rigs expose target assignment, input gating, pan/look commands, positive-in zoom rate/steps, normalized zoom, pointer position, recenter/snap, output-driver selection, and `get_view_metrics()`. The 3D rig additionally exposes orbit/view-mode APIs. Important signals cover target changes/loss, follow state, heading, zoom/view metrics, 3D view mode, occlusion, active-search offsets, and output errors.

The metrics dictionary contains desired and actual world-units-per-pixel. Detail components default to the desired value so a temporary SpringArm collision does not churn content detail.

## Input

`CameraInputMapAdapter` uses the portable `camera_*` actions added by this base. `CameraGuideDefaultsBuilder` constructs separate keyboard, mouse, gamepad, and touch contexts referencing one action set. The project owner activates only the selected device families through `CameraGuideContextRouter`; the router never disables unrelated contexts.

Mouse/touch deltas are per-frame values; keyboard/stick values are rates. Pinch and twist retain a gesture-start baseline. Touch gestures are fixed because G.U.I.D.E. v0.14 cannot detect touch remaps. The built-in remapping controller supports collision review, Swap/Replace/Cancel, persistence, reset, and active-context prompts for keyboard/mouse/gamepad inputs.

Disable camera contexts for pause, menus, cutscenes, and inactive local cameras. G.U.I.D.E. continues processing while the tree is paused. Mouse-to-touch and touch-to-mouse emulation should remain disabled when both contexts are active.

## Optional systems

- Motion: compose `CameraMotionEffects2D/3D` for seeded impulses/noise and accessibility intensity. The old `CameraShake2D.shake()` API is a compatibility wrapper.
- Fading: attach `CameraOccluder2D/3D` to collision content and use a tracker between focus and camera. Native transparency/modulate and validated `instance uniform float camera_fade` modes preserve original values.
- Detail: connect `CameraDetailCoordinator` to view metrics. Visibility/process bindings and the arbitrary-property mapper are opt-in and restore original state. Leave the coordinator absent or disabled to use only Godot's native mesh LOD.
- First person: `CameraViewVisibility3D` hides/fades explicitly assigned character geometry. Character movement and aim remain game-owned.
- Phantom: bind `PhantomCameraBridge` explicitly and select the PHANTOM output driver. Native camera, SpringArm collision, and native motion output are then disabled. The bridge is reflection-only and tested against Phantom Camera `0.11.0.3`; no Phantom files are shipped.

See `docs/contracts.md` for detailed input, LOD, occlusion, and Phantom ownership rules. The source-only gallery is `examples/camera_gallery.tscn`; examples/docs/tests are excluded from release exports by this base project.

## Tests

```text
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://addons/camera_rigs/tests -ginclude_subdirs -gexit
```

The addon depends on GUT only for tests and G.U.I.D.E. v0.14 only for the `runtime/input/guide/` layer. Core camera scenes remain directly scriptable without GUIDE. Phantom Camera is optional and never a package dependency.
