# Camera Addon

`addons/proper_camera/` is an exact vendored snapshot of the reusable ProperCamera Asset Store addon. It owns one 2D scene, one 3D pivot/SpringArm scene, five data presets, InputMap adapters, optional detail/fade/view components, examples, and addon-local tests. Its source and version are recorded in `third_party/proper_camera.lock`; refresh only that payload with `tools/update_proper_camera.ps1`.

Scene roots own target assignment, pause/menu gating, selection targets, and optional project settings injection. The core addon never imports project scenes or autoloads. Base-only G.U.I.D.E. contexts, remapping controls, and `InputSettings`/`CameraSettings` autoload bindings live in `addons/proper_camera_guide/`; its `ProperCameraBaseSettingsBinder` is the project boundary.

Use the native output unless Phantom Camera is already the project's authored virtual-camera solution. The reflection-only bridge guarantees `0.11.0.3` and makes ownership exclusive; see the addon README and `docs/contracts.md` for setup and unsupported Phantom features.

The five examples under `addons/proper_camera/examples/` are learning/test material. The Web export excludes those scenes together with addon docs and tests while retaining runtime scenes, scripts, and presets.
