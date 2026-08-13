# ProperCamera G.U.I.D.E. Companion

This is `godot-base` project glue for the vendored `proper_camera` addon. It
owns G.U.I.D.E. v0.14 contexts, remapping controls, and bindings to the base
`InputSettings` and `CameraSettings` autoloads. It is not part of the
ProperCamera Asset Store package.

The owning gameplay scene creates `ProperCameraGuideDefaults`, enables only
the required contexts through `ProperCameraGuideContextRouter`, and binds the
adapter to a `ProperCameraRig2D` or `ProperCameraRig3D`. Disable those contexts
for menus, pause, cutscenes, and inactive cameras. The router does not replace
unrelated G.U.I.D.E. contexts.

`ProperCameraBaseSettingsBinder` connects the base preference services to a
core `ProperCameraInputAdapter`, optional guide router, edge scroll, and rig.
It is intentionally base-only because it refers to the base autoload paths.
