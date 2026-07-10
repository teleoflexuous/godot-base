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
- Run `pwsh -File tools/run_ci_checks.ps1` as the expected local pre-push signal. It runs import, warning preflight, the unit and integration GUT suites (performance tests are skipped to match the GitHub workflow), then a clean Web export to `artifacts/web-ci/`; its export log scan and required-file checks match the GitHub workflow's Godot/export validation.
- After that export, run `node tools/web_smoke_check.cjs artifacts/web-ci` from a Node environment with Playwright + Chromium installed. The script serves the build with COOP/COEP headers, verifies `crossOriginIsolated`, opens the exported page in desktop and mobile Chromium contexts, and fails if the game never reports ready or if browser console/page errors occur.
- A green GitHub Actions run means the repository was configured, the build exported, and the deploy job was eligible to push on `main`.
- The export job also fails if Godot logs script parse/load errors or GDExtension load errors during export, if the expected GameAnalytics web artifacts are missing, or if the exported build cannot reach the runtime ready marker in real Chromium desktop + mobile browser runs.

## Web Export Notes

- Godot 4 web exports use the Compatibility renderer, while this base defaults to Forward Plus for desktop.
- Keep the base default as-is for native projects, but verify browser behavior before treating web export as a guaranteed shipping target.
- The committed web preset enables GameAnalytics on web through GDExtension (`variant/extensions_support=true`) and enables Godot web threads (`variant/thread_support=true`). The current GameAnalytics web side module expects shared WebAssembly memory, so the threaded/shared-memory export path is required for this build to start.
- Threaded web exports require cross-origin isolation. This build therefore depends on `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`, which itch exposes via the **SharedArrayBuffer support** embed setting.
- This configuration is the expected mobile-capable path for the current GameAnalytics binary as long as the host provides SharedArrayBuffer support. The browser smoke test covers both desktop and mobile Chromium contexts against the exported build.
- The obsolete `include_coi_service_worker` option was removed (Godot 4.7 replaced it with the Progressive Web App `ensure_cross_origin_isolation_headers` option). COI is delivered host-side via the itch.io checkbox instead. For non-itch hosts that you control, set COOP/COEP headers directly, or enable `progressive_web_app/enabled` with `progressive_web_app/ensure_cross_origin_isolation_headers` for a self-contained service-worker fallback.
- An inline boot monitor is injected through `html/head_include` on web exports. It records early browser errors, exposes a `window.__godotGameReady` marker for smoke tests, and replaces the silent full-progress hang with a visible startup timeout notice.
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
