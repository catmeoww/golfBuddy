# GolfBuddy

A swing-analysis app for casual golfers at the driving range. Record your swing, get on-device pose-based analysis, track progress over time.

This branch (`claude/plan-golf-app-bTwdT`) contains planning artifacts only — no app code yet.

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
