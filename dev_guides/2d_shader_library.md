# 2D Shader Library

The `2d` branch adds focused CanvasItem shaders with neutral defaults. Each effect is opt-in; screen FX is one full-screen pass and all expensive settings default to zero.

| Shader | Use |
|---|---|
| `sprite_outline` | Contrast/readability around sprites |
| `hit_flash` | Damage feedback (also available in `main`) |
| `dissolve` | Spawns, deaths, and pickups; supply a noise texture |
| `palette_recolor` | Lightweight variants without duplicate art |
| `hologram_ui` | Opt-in neon/glitch presentation; standard themes remain shader-free |
| `water`, `fog_overlay`, `foliage_sway` | Environment motion/atmosphere |
| `shader_wipe` | Stylized scene/UI transition alternative to the base fade |
| `screen_fx` | Vignette, CRT, and shockwave in a single pass |

Prefer Godot's built-in `PointLight2D`, `Parallax2D`, theme outlines/shadows, and `SceneManager` fades for their respective jobs. The gallery scene is `scenes/examples/2d/shader_gallery.tscn`.
