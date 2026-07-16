# Godot Base

Godot 4.7 starter base with a UI shell, global services, G.U.I.D.E input profiles, and an optional 2D extension branch.

## Create a project

Use this GitHub repository as a template and select **Include all branches**. Start from `main` for the base or switch to `2d` for the shader library. A generated repository intentionally fails CI until initialized:

```powershell
godot --headless --path . -s res://tools/initialize_project.gd -- --name=MyGame --release-target=none
```

Use `--release-target=itch` only after configuring the required GitHub itch/GameAnalytics values. Commit the resulting `project.godot` and `template_project.cfg` changes.

`2d` is synchronized from `main` through reviewed automated pull requests in this source repository. Do not expect GitHub template-generated branches to share history with the source repository.
