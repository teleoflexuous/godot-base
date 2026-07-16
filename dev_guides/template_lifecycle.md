# Template Lifecycle

The source repository is intentionally exempt from initialization checks. Repositories generated from the GitHub template are not: their first CI run fails until `tools/initialize_project.gd` records a deliberate release target.

- `none`: project validation runs; no deployment job is eligible.
- `itch`: `main` pushes require valid itch and GameAnalytics configuration before deployment.

This policy prevents a missing deployment flag from silently disabling required release validation.
