# Release Automation

## itch Deploy Flow

- `.github/workflows/itch-deploy.yml` runs on pull requests, pushes to `main`, and manual dispatch.
- The workflow intentionally fails until itch deployment is fully configured in GitHub.
- The default local GUT suite also fails until the same deploy and analytics settings are provided through `.env` (or exported in the shell) and `override.cfg` is regenerated from it.
- The workflow runs the default GUT suite before exporting `Web` from the committed `export_presets.cfg` preset.
- Every successful run uploads `builds/web/` as a GitHub artifact.
- Actual deployment to itch still only runs on pushes to `main` after configuration validation and export pass.

## Required GitHub Configuration

- Repository variable `ITCH_DEPLOY_ENABLED`: set to `true` to enable automatic deploys from `main`.
- Repository variable `ITCH_PROJECT`: itch target in `user/game` format.
- Repository secret `BUTLER_API_KEY`: a butler API key with access to that itch project.
- Repository secret `GAMEANALYTICS_GAME_KEY`: analytics key used to generate `override.cfg` in CI.
- Repository secret `GAMEANALYTICS_SECRET_KEY`: analytics secret used to generate `override.cfg` in CI.
- If any of these are missing or invalid, the workflow fails before the export job.

## Local Test Setup

- Copy `.env.example` to `.env` at the project root and fill in real values for all five keys.
- `.env` is intentionally ignored by git; never commit secrets.
- Running the default GUT suite loads `.env` and refreshes `override.cfg` from `GAMEANALYTICS_GAME_KEY` and `GAMEANALYTICS_SECRET_KEY`, so analytics keys live in one place.
- To refresh `override.cfg` without running tests (for example before opening the editor), run `godot --headless --path . -s res://tools/setup_local.gd`.
- Values in `.env` take precedence over shell environment variables locally; CI does not ship a `.env`, so GitHub secrets and variables still drive the workflow unchanged.
- As an alternative for CI-like shells, you can `export` the same five variables instead of using `.env`.
- `override.cfg` is intentionally ignored by git.

## Versioning

- itch uploads use `project.godot` `config/version` plus the GitHub run number and short commit SHA.
- Example: `0.1.0+42.a1b2c3d`

## Validation

- `tests/unit/test_release_automation.gd` checks that the committed web export preset, fail-fast GitHub workflow, and required setup docs stay in sync.
- The same test file also checks live runtime configuration so the default suite fails locally until itch and GameAnalytics settings are actually configured.
- A passing default GUT run plus a successful local `godot --headless --path . --export-release "Web" "builds/web/index.html"` smoke export is the expected pre-push signal that the repository can update itch once GitHub variables, secrets, and `override.cfg` are present.
- A green GitHub Actions run means the repository was configured, the build exported, and the deploy job was eligible to push on `main`.
- The export job also fails if Godot logs script parse/load errors or GDExtension load errors during export, or if the expected GameAnalytics web artifacts are missing.

## Web Export Notes

- Godot 4 web exports use the Compatibility renderer, while this base defaults to Forward Plus for desktop.
- Keep the base default as-is for native projects, but verify browser behavior before treating web export as a guaranteed shipping target.
- The committed web preset disables thread support so the default itch deployment path does not depend on cross-origin isolation headers.

## First itch Upload

- Create the itch project page before enabling deploys.
- After the first upload, set the itch project type to `HTML` and mark the uploaded file as playable in browser.
