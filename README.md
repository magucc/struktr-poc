# struktr-poc

POC: **preview screenshots instead of preview deployments** for mobile apps.

Add the `simulator-screenshots` label to a PR and CI will:

1. Build the debug APK (with `MOCK_AUTH=true` — the app boots with a pre-filled demo session, no backend).
2. Boot a headless Android emulator (API 34, KVM-accelerated on a free `ubuntu-latest` runner, AVD snapshot cached).
3. Run the Maestro flow in [`.maestro/preview/login-flow.yaml`](.maestro/preview/login-flow.yaml), capturing a screenshot at each defined step (status bar pinned to demo mode for deterministic pixels).
4. Push the PNGs to the `screenshot-archive` branch and upsert a **gallery comment on the PR**.

The demo app is a two-screen Android app (login → home) that exists purely to be screenshotted.

## Scope

- ✅ Android emulator leg (this repo)
- ⏳ iOS simulator leg — later, via a self-hosted runner on an EC2 Mac (same Maestro flow, extra column in the gallery)

## Anatomy

| Piece | File |
|---|---|
| Pipeline | `.github/workflows/preview-screenshots.yml` |
| Gallery publisher | `.github/scripts/publish-screenshots.sh` |
| Flow definition | `.maestro/preview/login-flow.yaml` |
| Login mock | `MOCK_AUTH` buildConfigField in `app/build.gradle.kts` |
