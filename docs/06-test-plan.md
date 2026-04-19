# Test Plan — GolfBuddy MVP

**Author:** Priya (QA)  ·  **Status:** Draft v0.2 (post-P01 synthesis)

## 1. Strategy

Three pillars, each with a clear bar:

1. **Functional correctness** — the app does what the PRD says, on supported devices.
2. **Pose & metric accuracy** — the analysis is trustworthy enough for users to act on. Validated against a labeled corpus.
3. **Field robustness** — the app survives real range conditions: bad lighting, gloved hands, phone-stand wobble, no signal.

## 2. Test layers

| Layer | Owner | Tooling | Coverage target |
|---|---|---|---|
| Unit | Engineers | `flutter test` | 80% on `domain/` and `services/pose/metrics/` |
| Widget | Engineers + Priya | `flutter test` widget tests | All screens render, key gestures handled |
| Golden | Priya | `flutter test --update-goldens` | Skeleton overlay, metric cards, charts |
| Integration | Priya | `integration_test` | 4 critical user journeys |
| Accuracy regression | Priya + Sofia | Custom harness over corpus | Phase F1 ≥ 0.9, metric MAE within bounds |
| Performance | Priya | Custom trace + manual | Meets perf budgets in HLD §7 |
| Manual exploratory | Priya | Hand-driven on devices | Per-release checklist |
| Field | Lin + Priya | Range visit | Per-release checklist |

## 3. Critical user journeys (integration tests)

**CUJ-1: First-time capture.**
Launch fresh install → grant camera → Capture tab → player chip "Ethan" preselected → tap record → wait 3s → tap stop → trim auto-confirms → confirm sheet one-tap save → session appears in Library + analysis screen renders metrics.

**CUJ-2: Capture a different person.**
From Library with 2 existing players → switch to Capture → tap chip row → pick "Friend Sam" (or add new) → record → save → swing appears under Sam in Library, not Ethan.

**CUJ-3: Upload existing video.**
Capture tab → upload → pick video → trim → confirm sheet → save → analysis renders.

**CUJ-4: Compare two swings.**
Library → open session → compare → pick another (same player default) → side-by-side scrubber works → metric deltas display.

**CUJ-5: Tag session under a tournament event.**
Settings → Tournaments → create "US Kids Spring Classic" (date range) → Capture a swing → confirm sheet → pick that tournament + relation "before" → save → open Tournaments → tournament detail → session appears under "Before."

**CUJ-6: Add a timestamp annotation to a session.**
Library → open session → Session review → scrubber at ~0.6s → "Add note" → type "hips open early" → save → marker appears on scrubber at 0.6s → tap marker → note text shown. Reload app → annotation persists.

**CUJ-7: Compare two sessions across a tournament boundary.**
Library → open a session tagged `before` a tournament → compare → sync mode "Align by tournament" → picker auto-suggests the closest `after` session for the same player → side-by-side renders → metric deltas display.

Each CUJ is automated and runs in CI on a Pixel 6 emulator with fixture video + seeded DB preloaded.

## 4. Pose & metric accuracy validation

### Labeled corpus

50 swing videos collected by Sofia + Priya in week 1, before product code lands. Each video hand-labeled with:

- Frame index for each of the 4 phases
- Ground-truth metric values measured manually (tempo from frame counting, rotations from on-screen protractor, head movement from a fixed reference marker in frame)

**Diversity matrix:**

| Dimension | Levels |
|---|---|
| Camera angle | down-the-line, face-on, behind-back |
| Lighting | indoor sim, outdoor sun, outdoor overcast |
| Body type | 5 distinct (height, build) |
| Handedness | right (40), left (10) |
| Club | driver (25), iron (15), wedge (10) |
| Phone position | tripod (35), handheld friend (15) |
| Camera FPS | 60 (25), 120 (15), 240 (10) |

Corpus is checked into the repo as a fixture index (file paths + labels JSON). Videos themselves stored in a private bucket due to size.

### Acceptance bars

| Check | Bar |
|---|---|
| Phase frame detection (per phase) | within ±2 frames of label, ≥ 90% of swings |
| Tempo ratio | mean absolute error ≤ 0.2 |
| Shoulder turn | MAE ≤ 8° |
| Hip turn | MAE ≤ 8° |
| Head stability | MAE ≤ 2cm |
| Pose detection success rate | ≥ 95% of frames have mean joint confidence ≥ 0.4 |

The accuracy harness runs nightly and on PRs that touch `services/pose/`. Results posted as a CI comment with a per-metric table and per-video drilldown.

### Failure protocol

Any swing in the corpus that fails after a code change requires either: (a) the change is reverted, or (b) Sofia documents why the new behavior is correct and updates the label.

## 5. Device matrix

### Supported (must pass full regression)

| Tier | Devices |
|---|---|
| Android primary | Pixel 8, Pixel 6a, Galaxy S23, Galaxy A54 |
| iOS primary | iPhone 14, iPhone 13, iPhone SE 3 |

### Best-effort (smoke only)

| Tier | Devices |
|---|---|
| Android low-end | Moto G Power, Galaxy A14 |
| iOS old | iPhone 11 |

OS versions: Android 11 minimum, iOS 15 minimum. Devices updated to latest patch level monthly.

## 6. Performance tests

| Metric | Budget | Test |
|---|---|---|
| Cold launch → camera ready | < 2s | Automated trace on Pixel 6a + iPhone 13 |
| Capture-stop → analysis screen | < 5s for 2s @ 60fps | Automated trace, fixture video |
| Skeleton overlay playback | sustained 60fps | Manual + GPU profiler |
| Battery drain in capture mode | < 8%/hour idle preview | 1-hour soak test |
| RAM peak during analysis | < 600MB | Profiler |
| APK / IPA size | < 80MB / < 120MB | CI gate |

## 7. Field test checklist

Run in a real backyard / home coaching setting before each beta release. M (or a stand-in coach) + Priya, ~60 minutes, during an actual 10-min block plus post-block review.

- [ ] Phone on stand: countdown long enough to walk to the hitting position
- [ ] Lock-record long-press works
- [ ] Pre-capture "who are you filming" chip: pre-selection is correct; switching to a different player is ≤ 2 taps
- [ ] Recording 5 swings in a row: no thermal throttle warnings, no app slowdown
- [ ] Post-block review: Library shows today's swings at the top, ordered by time
- [ ] Add a session-level annotation and a timestamp annotation: both persist; marker visible on scrubber
- [ ] Tag a session with a tournament + relation: tournament detail screen shows it grouped correctly
- [ ] Open last week's session: thumbnail loads instantly
- [ ] Compare two swings: scrubber sync works; Align-by-tournament pick is sensible
- [ ] Trend chart opens and renders with tournament markers
- [ ] Airplane mode: full app functional (simulate Wi-Fi blip during capture)
- [ ] Storage view: actual usage matches estimates

Any FAIL = release blocker until triaged.

## 8. Edge case & negative tests

- No camera permission → graceful prompt, no crash
- Permission revoked between launches → re-prompt
- Storage full mid-recording → save what was captured, friendly error
- Pose detection finds no person → "Couldn't see the golfer" UI, retake CTA
- Pose finds 2 people → use the largest bounding box, log telemetry
- Phase detection fails → analysis marked partial, manual adjust UI prominent
- App backgrounded during analysis → resume on return without losing video
- Force-quit during recording → on next launch, surface "recovered swing" with raw video for re-tag
- DB migration failure → restore backup, surface non-blocking error to log only
- Video file deleted out-of-band (user file manager) → orphaned DB row cleaned up on next launch with user notice

## 9. Accessibility tests

- Talkback + VoiceOver pass on all screens (every interactive has a label, focus order is logical)
- Dynamic type at 200%: no clipped text on key screens (Capture, Analysis, History)
- Color contrast checked with axe DevTools equivalent on every screen
- "Reduce motion" preference disables phase scrubbing animation

## 10. Release gates

| Build | Required to pass |
|---|---|
| Internal alpha (week 6) | Unit + widget green; CUJ-1 through CUJ-4 pass on Pixel 6a + iPhone 13; field checklist done once |
| Closed beta (week 8) | Above + accuracy bars met on full corpus; full device matrix smoke; field checklist clean |
| Public beta (week 12) | Above + 4 weeks of beta with crash-free ≥ 99% + no open P0 |
| GA (week 16) | Above + diary study green + Lin sign-off on UX + no open P0 or P1 |

## 11. Bug priority definitions

- **P0** — Data loss, crash on critical path, blocks core flow for any user
- **P1** — Core flow degraded but workaround exists; accuracy regression below bar
- **P2** — Polish, edge cases, secondary flow issues
- **P3** — Cosmetic, nice-to-have

## 12. Reporting

- Daily test status during release weeks: Slack `#golfbuddy-qa`
- Per-release test report: pass/fail per CUJ, accuracy table, device matrix grid, open-bug list, sign-off line for Maya + Jordan
- Accuracy dashboard: nightly auto-published from CI

## 13. Open QA questions

- Do we need an automated visual regression tool (Percy / Chromatic alternative for Flutter) in MVP, or are golden tests enough? Leaning golden + manual for MVP.
- Where do we host the labeled corpus videos? Need budget for ~5GB of private storage.
- Beta crash reporting opt-in default — on or off? (Privacy vs signal trade.) Recommend default-on with clear disclosure.
