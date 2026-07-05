# Testing Strategy

## Default GUT Scope

- `.gutconfig.json` includes project tests only:
- `res://tests/unit/`
- `res://tests/integration/`
- `res://tests/performance/`

## Test Split

- `tests/unit/`: pure scripts, autoload contracts, and formatting helpers.
- `tests/integration/`: scene loading, node wiring, and multi-system contracts.
- `tests/performance/`: startup, turn/update loops, loading, and rendering-adjacent budgets.
- Addon-local tests should live under `addons/<addon>/tests/` and be run directly when that addon changes.

## Recommended Commands

Default project suite:

```text
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit
```

Unit tests only:

```text
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Integration tests only:

```text
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit
```

Performance tests only:

```text
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/performance -gexit
```

## Coverage Expectations

- Every reusable autoload should have a unit contract test.
- Every sample scene should have a load/smoke integration test.
- Every project-specific runtime system should name its owning scene/script/test/docs in `component_index.md`.
