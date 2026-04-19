# GolfBuddy

A swing-analysis app for casual golfers at the driving range. Record your swing, get on-device pose-based analysis, track progress over time.

## Getting started

The repo currently holds the **app skeleton** plus planning artifacts. No swing
analysis, pose detection, or real camera capture is wired up yet.

### What is scaffolded

- `lib/` directory structure from [LLD §1](docs/04-eng-design-lld.md) — stub
  classes/widgets with TODOs pointing at the owning LLD section.
- Riverpod `ProviderScope` + `MaterialApp.router` + a `go_router`
  `StatefulShellRoute` with **Capture / History / Settings** tabs.
- Drift database (`lib/data/db/database.dart`) with the four tables from LLD §5
  (`players`, `sessions`, `phase_markers`, `metrics`) plus the two indexes.
  Schema version 1; migration hook is in place.
- `pubspec.yaml` with every dependency named in HLD §4 and LLD pinned to a
  recent stable version.
- `analysis_options.yaml` (flutter_lints + `prefer_single_quotes`).
- GitHub Actions CI (`.github/workflows/ci.yml`) runs `flutter analyze` and
  `flutter test` on every PR.
- Minimum Android + iOS platform files (manifest, Info.plist, activity/delegate)
  so `flutter run` has something to launch.

### What is NOT yet wired

- Camera capture, pose detection, metric calculation, phase detection — deferred
  until persona validation completes (see `research/`).
- Skeleton overlay painter, analysis screen, compare screen.
- Repositories / DAOs / use cases — stubs only; real queries TBD.
- Sentry DSN wiring in `main.dart`.

### Running locally

1. Install Flutter 3.19+ (`flutter --version`).
2. From the repo root:
   ```sh
   flutter create . --org app.golfbuddy --project-name golfbuddy --platforms=android,ios
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs   # generates database.g.dart
   flutter run
   ```
   `flutter create .` is safe to run on top of this skeleton — it fills in the
   platform-specific files we didn't hand-commit (gradle wrapper, Xcode
   project, launcher icons, etc.) without overwriting our `lib/` tree.
3. `flutter analyze` and `flutter test` should both pass.

> The `database.g.dart` file is intentionally not committed; it is produced by
> `build_runner` and is required before the app will compile.

This branch (`claude/plan-golf-app-bTwdT`) contains the skeleton and planning artifacts.

## Planning docs

| Doc | Owner | What it covers |
|---|---|---|
| [`docs/00-team-kickoff.md`](docs/00-team-kickoff.md) | Team | Roles, kickoff decisions, milestones, open questions |
| [`docs/01-prd.md`](docs/01-prd.md) | Jordan (PM) | Problem, persona, scope, success metrics |
| [`docs/02-ux-design.md`](docs/02-ux-design.md) | Lin (UX) | Principles, IA, flows, screen designs, a11y |
| [`docs/03-eng-design-hld.md`](docs/03-eng-design-hld.md) | Maya (Tech Lead) | Architecture, stack, components, NFRs |
| [`docs/04-eng-design-lld.md`](docs/04-eng-design-lld.md) | Raj + Sofia (Eng) | Project layout, models, pipelines, schema |
| [`docs/05-user-study.md`](docs/05-user-study.md) | Jordan + Lin | Discovery, concept, field, beta, longitudinal research |
| [`docs/06-test-plan.md`](docs/06-test-plan.md) | Priya (QA) | Test layers, accuracy corpus, device matrix, gates |

## MVP at a glance

- **Stack:** Flutter (Android + iOS), on-device MediaPipe Pose via ML Kit, Drift (SQLite)
- **Features:** capture/upload swing → auto-detect 4 phases → annotated slow-mo + metrics → local history & compare
- **Out of scope (v1.1+):** cloud sync, friend accounts, coach mode, social
- **Timeline:** 6-week MVP build, 4-week closed beta, GA at week 16
