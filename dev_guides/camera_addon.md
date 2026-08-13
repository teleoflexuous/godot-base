# Camera Addon

`addons/camera_rigs/` is the reusable camera package. It owns one 2D scene, one 3D pivot/SpringArm scene, five data presets, semantic input adapters, settings/remapping reference controls, optional detail/fade/view components, examples, and addon-local tests.

Scene roots own target assignment, G.U.I.D.E. context activation, pause/menu gating, selection targets, and optional project settings injection. The addon never imports project scenes or autoloads. `CameraSettingsBinder` is the optional project boundary for the `InputSettings` and `CameraSettings` autoloads supplied by this base.

Use the native output unless Phantom Camera is already the project's authored virtual-camera solution. The reflection-only bridge guarantees `0.11.0.3` and makes ownership exclusive; see the addon README and `docs/contracts.md` for setup and unsupported Phantom features.

The five examples under `addons/camera_rigs/examples/` are learning/test material. The Web export excludes those scenes together with addon docs and tests while retaining runtime scenes, scripts, and presets.
