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
- The committed web preset enables GDExtension support (`variant/extensions_support=true`) so GameAnalytics runs on web, and keeps thread support disabled (`variant/thread_support=false`). Godot 4.7 ships a matching `web_dlink_nothreads_release.zip` template, so no custom template build is required; the editor selects it automatically from those two flags.
- Thread support stays off on purpose. GameAnalytics does not need threads, and the single-threaded dlink template avoids thread-pool tuning and the extra compatibility headaches of pthreads on the web.
- Because extensions are enabled, the web build requires cross-origin isolation (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers, backed by `SharedArrayBuffer`). On itch.io this is provided by ticking **SharedArrayBuffer support** under Embed options (see "First itch Upload"); it is a one-time setting that persists across butler pushes. With extensions on, the GameAnalytics GDExtension loads and the `Analytics` autoload enables when keys are present (see `autoloads/analytics.gd`), and the earlier "GDExtension libraries are not supported" notice no longer appears.
- The obsolete `include_coi_service_worker` option was removed (Godot 4.7 replaced it with the Progressive Web App `ensure_cross_origin_isolation_headers` option). COI is delivered host-side via the itch.io checkbox instead. For non-itch hosts that you control, set COOP/COEP headers directly, or enable `progressive_web_app/enabled` with `progressive_web_app/ensure_cross_origin_isolation_headers` for a self-contained service-worker fallback.
- Butler only uploads files; it cannot set itch.io embed options such as viewport dimensions, mobile-friendly, orientation, auto-start, or fullscreen button. Those are configured once on the itch.io Edit game page (see "First itch Upload"). Local testing of this web build needs a COI-capable server (e.g. Godot's `serve.py` from the web export docs), because SharedArrayBuffer requires COOP/COEP headers even on `localhost`.

## First itch Upload

- Create the itch project page before enabling deploys.
- The deploy workflow pushes the web build to the `html` channel via `butler push "$ITCH_PROJECT:html"`.
- Butler cannot tag an HTML channel as playable in browser automatically. This is a documented itch.io limitation, unlike win/mac/linux channels where butler sets platform tags for you. The kind and embed flag must be set once on the project page after the first push.
- After the first successful push to the `html` channel, do this one-time setup on itch.io:
  1. Creator Dashboard -> Edit game.
  2. Set **Kind of project** to `HTML`.
  3. Under **Uploads**, tick **This file will be played in the web browser** on the `html` channel upload.
  4. Under **Embed options**, set viewport dimensions to match `project.godot` (`1280x720`).
  5. Under **Embed options**, tick **SharedArrayBuffer support**. Required: the web preset enables GDExtension (GameAnalytics), which needs cross-origin isolation headers that itch.io only sends when this is checked.
  6. Delete any leftover manual `.zip` upload; a non-butler upload is known to shadow the embedded butler build.
  7. Save.
- Once the `html` channel is marked playable in browser, every subsequent butler push to `html` automatically replaces the embedded build. No repeat manual step is needed for updates.
- Verify after pushing: open the project page in an incognito window; the build should run inline rather than offer a download.
