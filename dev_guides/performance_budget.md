# Performance Budget

## Starting Targets

| Area | Starting Budget |
|---|---|
| Main scene load in headless tests | Under 2 seconds |
| Direct UI interaction handler | Under 16 ms |
| Per-frame gameplay work | Under 8 ms before rendering |
| 2D scene smoke load | Under 1 second |
| 3D scene smoke load | Under 1 second in headless tests |

## Rules

- Add performance tests only for behavior that has a real budget or regression risk.
- Prefer signals and cached references over repeated tree searches in hot paths.
- Avoid per-frame allocations in frequently updated actors.
- If a performance test fails, investigate once, report the likely cause, and avoid blind iterative tuning.

## Rendering Notes

- `project.godot` defaults to Forward Plus and D3D12 on Windows.
- `GraphicsSettings` exposes low, balanced, and high tiers as a small starting point.
- Projects should define their own quality tiers before shipping 3D-heavy scenes.
