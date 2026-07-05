# Addon Packaging

Use this layout when promoting reusable project code into an addon.

```text
addons/<addon_name>/
  README.md
  plugin.cfg              # only if editor/runtime plugin registration is needed
  runtime/                # runtime scripts and scenes
  tests/                  # addon-local GUT tests
  tools/                  # optional validation or export helpers
  docs/                   # optional detailed contracts
  <addon>_package_manifest.json
```

## Rules

- Keep addon runtime code independent from project scenes unless the dependency is documented.
- Add addon-local tests under `addons/<addon_name>/tests/` when the addon can be validated outside the project test suite.
- Keep project tests in `tests/` focused on integration with the current game.
- Write a README before treating project code as reusable.

## Manifest Fields

Suggested package manifest keys:

```json
{
  "name": "example_addon",
  "version": "0.1.0",
  "runtime": ["runtime/example.gd"],
  "tests": ["tests/runtime/test_example.gd"],
  "docs": ["README.md"]
}
```

## Promotion Checklist

- Runtime does not rely on project-specific data paths.
- README explains setup, API, and examples.
- Tests can run directly through GUT.
- Any autoload or plugin registration is documented.
- Project-specific systems import the addon instead of the addon importing the project.
