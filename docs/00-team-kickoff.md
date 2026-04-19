# GolfBuddy — Team Kickoff & Decisions

## The team

| Role | Name | Owns |
|---|---|---|
| Product Manager | Jordan | PRD, user study, success metrics |
| UX Designer | Lin | UX proposal, prototypes, design system |
| Tech Lead | Maya | Architecture, HLD, tech decisions, tradeoffs |
| Engineer (Mobile) | Raj | Flutter app, camera, video pipeline, UI implementation |
| Engineer (CV/ML) | Sofia | Pose detection, swing-phase detection, metrics |
| QA | Priya | Test plan, accuracy validation, device matrix |

## Kickoff meeting — summary

**Jordan (PM):** Annie's a casual golfer at the driving range. Sometimes alone, sometimes with friends. She films swings and wants analysis. Her husband is a coach — that's a v2 wedge. We are NOT building a social network or coach marketplace. MVP is "film → understand → improve."

**Lin (UX):** Three constraints I want everyone to hold: (1) one-handed use at the range, (2) sun glare on screen, (3) gloved hands. This kills tiny tap targets and hover states. Also: she's switching between filming herself (tripod/phone-stand) and filming a friend. The "who swung this" tag has to be one tap, not a form.

**Maya (Tech Lead):** Decision — Flutter + on-device MediaPipe Pose. Reasons: (1) user's daily device is Android, backup is iPhone, dogfooding matters; (2) MediaPipe ships pose models for both via `google_mlkit_pose_detection`; (3) on-device = no cloud cost, works at outdoor ranges with poor signal, no PII leaves the phone. Trade: less native polish than two separate apps. Acceptable for MVP.

**Sofia (CV):** Pose model is solved. The hard part is **swing-phase detection** from a noisy pose stream — finding address, top of backswing, impact, follow-through reliably across body types, camera angles, and lighting. Plan: heuristic detector first (wrist trajectory + velocity zero-crossings), revisit with a small classifier in v1.1 if accuracy is below bar.

**Raj (Mobile):** Camera framerate matters. A driving-range swing takes ~1 second. At 30fps that's ~30 frames — barely enough. We need 60fps minimum, 120/240fps where the device supports it. I'll use `camera` plugin with platform-specific high-speed config.

**Priya (QA):** I need a labeled video corpus before I can call accuracy "good." Proposing: 50 swings across 3 camera angles (down-the-line, face-on, behind), 3 lighting conditions, 5 body types, with hand-labeled phase frames. We treat this as the regression set. Phase detection within ±2 frames of label = pass.

**Jordan:** Agreed. Locking MVP scope:
1. Record or upload swing video
2. Auto-detect 4 swing phases
3. Annotated slow-mo playback with skeleton
4. Metrics: tempo ratio, head stability, shoulder turn, hip turn
5. Local player profiles (no accounts), local session history
6. Swing-to-swing comparison

Out of scope: cloud sync, social, coaching tools, pro comparison library, watch app.

**Maya:** Milestones — 6-week MVP target.
- W1: Project setup, camera capture, video playback
- W2: Pose detection on captured frames
- W3: Swing-phase detection + metrics
- W4: Annotated playback + comparison UI
- W5: Player profiles + history
- W6: Polish, QA pass, beta build

## Open questions parked for later

1. Cloud backup — do we need it before v1 if the user changes phones? (Jordan to ask.)
2. Coach mode — how does Annie's husband want to use this? (Need a 30-min interview before v1.1 spec.)
3. iPad/tablet support — defer; small audience for MVP.
4. Internationalization — defer; English-only MVP.

## Document index

- `01-prd.md` — Product Requirements (Jordan)
- `02-ux-design.md` — UX Design Proposal (Lin)
- `03-eng-design-hld.md` — High-Level Engineering Design (Maya)
- `04-eng-design-lld.md` — Low-Level Engineering Design (Raj + Sofia)
- `05-user-study.md` — User Research Plan (Jordan + Lin)
- `06-test-plan.md` — Test Plan (Priya)
