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
- Extension support is also disabled. Per the Godot 4.7 web export guide, both thread support and GDExtension extension support independently require cross-origin isolation (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers, backed by `SharedArrayBuffer`). With both off, the export runs single-threaded without `SharedArrayBuffer`, which is Godot's recommended and default web configuration and the most compatible with itch.io, Safari, and iOS.
- With extensions disabled, the GameAnalytics GDExtension does not load on web and the `Analytics` autoload stays `enabled = false` (see `autoloads/analytics.gd`). It no-ops safely, so the web build still runs. The export log may emit a "GDExtension libraries are not supported" notice; this is expected and harmless for the base template. GameAnalytics still works on native desktop and mobile exports.
- If a concrete game needs live analytics on web, switch the web preset to thread support and extension support, then enable the COI service worker (`include_coi_service_worker=true`) or rely on the itch.io "SharedArrayBuffer support" embed option, and accept the reduced Safari/iOS compatibility. That is a per-game decision, not the base default. Enabling extensions forces the dlink-enabled (threaded) template, so extensions and threads go together on web.
- Butler only uploads files; it cannot set itch.io embed options such as viewport dimensions, mobile-friendly, orientation, auto-start, fullscreen button, or the SharedArrayBuffer toggle. Those are configured once on the itch.io Edit game page (see "First itch Upload"). The SharedArrayBuffer option is not required for the single-threaded base build.

## First itch Upload

- Create the itch project page before enabling deploys.
- The deploy workflow pushes the web build to the `html` channel via `butler push "$ITCH_PROJECT:html"`.
- Butler cannot tag an HTML channel as playable in browser automatically. This is a documented itch.io limitation, unlike win/mac/linux channels where butler sets platform tags for you. The kind and embed flag must be set once on the project page after the first push.
- After the first successful push to the `html` channel, do this one-time setup on itch.io:
  1. Creator Dashboard -> Edit game.
  2. Set **Kind of project** to `HTML`.
  3. Under **Uploads**, tick **This file will be played in the web browser** on the `html` channel upload.
  4. Under **Embed options**, set viewport dimensions to match `project.godot` (`1280x720`).
  5. Delete any leftover manual `.zip` upload; a non-butler upload is known to shadow the embedded butler build.
  6. Save.
- Once the `html` channel is marked playable in browser, every subsequent butler push to `html` automatically replaces the embedded build. No repeat manual step is needed for updates.
- Verify after pushing: open the project page in an incognito window; the build should run inline rather than offer a download.
