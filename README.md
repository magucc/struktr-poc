# struktr-poc

POC: **preview screenshots instead of preview deployments** for mobile apps.

Add the `simulator-screenshots` label to a PR and CI will:

1. Build the debug APK (with `MOCK_AUTH=true` — the app boots with a pre-filled demo session, no backend).
2. Boot a headless Android emulator (API 34, KVM-accelerated on a free `ubuntu-latest` runner, AVD snapshot cached).
3. Run the Maestro flow in [`.maestro/preview/login-flow.yaml`](.maestro/preview/login-flow.yaml), capturing a screenshot at each defined step (status bar pinned to demo mode for deterministic pixels).
4. Push the PNGs to the `screenshot-archive` branch and upsert a **gallery comment on the PR**.

The demo app is a two-screen Android app (login → home) that exists purely to be screenshotted.

## Scope / roadmap

- ✅ Android emulator leg (this repo, native Kotlin app)
- ✅ Reusable action — [`magucc/struktr`](https://github.com/magucc/struktr), hook any repo in
- ✅ React Native example + self-test — `examples/react-native` in the struktr repo
- ⏳ Interactive previews — Appetize-style emulator-in-browser (WebRTC via `google/android-emulator-container-scripts`), wired to per-PR preview backends; session URLs like `app-preview.<domain>/pr/{hash}/{device}`
- ⏳ GitHub App — full abstraction: install on repo, label triggers pickup, static config in `.struktr.yml`, no workflow YAML needed
- ⏳ Agent-driven capture — an agent on the runner reads the PR description/diff and generates the Maestro flow (what to screenshot / focus area); falls back to committed flows
- ⏳ Business-hours emulator VM pool (first deployment target: kju, on AWS credits)
- ⏳ iOS simulator leg — self-hosted runner on an EC2 Mac (same flow file, extra gallery column); interactive iOS later via Tapflow-style Mac agent

## Anatomy

| Piece | File |
|---|---|
| Pipeline | `.github/workflows/preview-screenshots.yml` |
| Gallery publisher | `.github/scripts/publish-screenshots.sh` |
| Flow definition | `.maestro/preview/login-flow.yaml` |
| Login mock | `MOCK_AUTH` buildConfigField in `app/build.gradle.kts` |
