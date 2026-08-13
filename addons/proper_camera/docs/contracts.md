# ProperCamera Contracts

## Follow, pan, and view

Follow interruption is explicit: hard lock rejects pan, offset-follow preserves the relationship to the target, and break-on-pan retains the current shot as a free camera. Target and selection/zoom-anchor targets are separate weak references. A freed follow target emits `target_lost`, clears follow, and keeps the last stable focus.

Manual camera smoothing uses exponential weights and runs in `_process`. Rigs disable inherited physics interpolation and read `get_global_transform_interpolated()` from followed Node2D/Node3D targets. After teleports, call `snap_to_target()` (or `snap()` in 2D) so the camera resets its interpolation history.

First-person transitions never take ownership of character heading or aim. Assign explicit first/third anchors where the character's authored rig differs from preset offsets; observe `view_mode_changed` and `heading_changed` from gameplay.

## Zoom and projection

All devices feed a positive-in semantic value. Two-dimensional scale is exponential. Three-dimensional zoom can be dolly, FOV, orthographic size, or a composite of distance, pitch, pivot height, and FOV curves.

Zoom anchors are view center, followed target, selection target, pointer world hit, or a provider implementing `get_camera_zoom_anchor_2d(rig)` / `get_camera_zoom_anchor_3d(rig)`. The 3D pointer ray uses the preset collision mask; on a miss it intersects the focus-height horizontal plane and then falls back to the view center.

Godot mesh LOD is screen-space aware. Distance-based HLOD does not react to FOV or orthographic-size changes. `ProperCameraDetailCoordinator` therefore consumes projection-neutral world-units-per-pixel and supplies optional stable bands for labels, effects, simulation intervals, visibility, processing, or another validated property. It does not change the viewport's global mesh LOD threshold.

## Native occlusion

`SpringArm3D` keeps `Camera3D` as its direct child so Godot uses the camera near-plane pyramid. The rig keeps desired zoom separate from collision-shortened actual distance, pulls inward immediately, and recovers outward using the preset recovery rate.

`PULL_IN_AND_SEARCH` begins only after sustained blockage. It evaluates no more than `search_query_budget` yaw/shoulder candidates and penalizes discontinuity so the view does not oscillate. Character cameras may enable it; management and RTS presets keep it off to protect spatial orientation. Collision masks, margins, and target exclusions are preset-controlled.

Occluder fading is separate from camera-body collision. Trackers ray through multiple collision objects and issue reference-counted requests to explicit content components. Native 3D transparency moves geometry into the transparent pipeline; prefer the per-instance shader parameter mode for production materials where that tradeoff matters.

## Device and UI behavior

`ProperCameraInputMapAdapter` is the self-contained fallback. It consumes named `camera_*` actions and can install defaults for prototypes when `install_missing_actions` is enabled. Production projects should declare those actions themselves so camera commands coexist predictably with their own gameplay controls.

G.U.I.D.E. contexts, prompts, and remapping live in an optional companion integration. Install it only when the project already uses G.U.I.D.E.; the core addon deliberately contains no G.U.I.D.E. classes or autoload assumptions. GUI gets first refusal before pointer input; set edge scroll's UI/drag blocking flags while the pointer is over world-blocking UI or a selection drag is active.

## Phantom Camera ownership

The optional bridge never imports, preloads, exports, or type-hints Phantom classes. Bind an explicit preconfigured PhantomCamera2D/3D node. In PHANTOM mode, Phantom exclusively owns the final Camera, host lifecycle, priority/blending, SpringArm collision, and noise. The camera rig supplies target/focus, yaw/pitch, desired zoom/projection, constraints, metrics, and optional search intent.

Use separate preconfigured PCams for SIMPLE and THIRD_PERSON or first/third-person behaviors. The bridge does not alter Phantom follow/look-at enum modes, create Camera3D resources, register a manager, or implement group/path framing. Editor validation accepts exactly `0.11.0.3`; `allow_untested_version` permits capability-probed operation with a warning. Missing or invalid Phantom produces one actionable error and does not fall back to native output.
