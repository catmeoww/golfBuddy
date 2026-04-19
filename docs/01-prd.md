# PRD — GolfBuddy MVP

**Author:** Jordan (PM)  ·  **Status:** Draft v0.1  ·  **Target ship:** 6 weeks

## 1. Problem

Casual golfers practicing at the driving range want feedback on their swing but have no easy way to get it. Filming with the stock camera app gives them a video they can't usefully analyze — they can't see joint angles, can't measure tempo, and can't tell if they're improving session over session. Hiring a coach is expensive and infrequent.

## 2. Target user

**Primary persona — Annie, 34, recreational golfer**
- Plays once or twice a week, mostly driving range, occasional 9 holes
- Goes alone half the time, with 1–2 friends the other half
- Owns Android (Pixel 8) as daily, iPhone 14 as backup
- Tech-comfortable but not a power user
- Goal: "stop slicing, swing more consistently, see if I'm getting better"
- Frustration: phone videos look great but don't tell her what's wrong

**Secondary (v1.1+):** Annie's husband, a part-time golf coach, wants to use the same captured swings to give annotated feedback to his students.

## 3. Goals

- **G1.** Annie can capture or upload a swing and get readable analysis in under 30 seconds.
- **G2.** Analysis is accurate enough that Annie trusts and acts on it (qualitative bar from beta interviews).
- **G3.** Annie can see her progress over time (compare today's swing to last week's).
- **G4.** Works at an outdoor range with no/poor cell signal.

## 4. Non-goals (MVP)

- Social features, sharing feeds, follower graphs
- Coach/student marketplace, payments
- Cloud backup, multi-device sync
- AI chat coach, natural-language feedback generation
- Pro-swing comparison library
- Wearables, club sensors, launch monitor integration
- Apple/Google account login, server-side accounts

## 5. User stories

| ID | As a... | I want to... | So that... |
|----|---------|--------------|------------|
| US-1 | golfer alone at the range | prop my phone on a stand and record my swing | I can review it after | 
| US-2 | golfer with a friend | record my friend's swing and tag it as theirs | their swings don't pollute my history |
| US-3 | golfer who recorded a swing | see slow-mo playback with my body outlined | I can see what my body did |
| US-4 | golfer who recorded a swing | see specific numbers (tempo, head movement, etc.) | I have something concrete to work on |
| US-5 | golfer practicing weekly | compare today's swing to last week's | I can tell if I'm improving |
| US-6 | golfer with an existing video | upload it from gallery | I don't lose old footage |
| US-7 | golfer at a sunny range | use the app one-handed with gloves | I don't fight the UI |

## 6. Functional requirements

### F1. Capture
- F1.1 Record swing using device camera at 60fps minimum, 240fps where supported
- F1.2 In-app countdown timer (3/5/10s) for self-recording
- F1.3 Auto-trim to swing window if detected; manual trim handles otherwise
- F1.4 Import video from device gallery (any orientation)

### F2. Tagging
- F2.1 Local player profiles (name + optional avatar). Default: "Me"
- F2.2 Player picker shown post-capture, one tap to assign
- F2.3 Optional club tag (Driver / Iron / Wedge / Putter)

### F3. Analysis
- F3.1 Pose skeleton overlaid on video playback
- F3.2 Auto-detect 4 phases: address, top of backswing, impact, finish
- F3.3 Compute metrics:
  - Tempo ratio (backswing duration : downswing duration), target 3:1
  - Shoulder rotation at top (degrees)
  - Hip rotation at top (degrees)
  - Head movement (max displacement from address position, cm estimate)
- F3.4 Show metrics with plain-English context ("Your tempo was 2.5:1 — slightly fast")

### F4. Playback
- F4.1 Full-speed and slow-motion (0.25x, 0.5x) playback
- F4.2 Frame-by-frame scrubbing
- F4.3 Jump to detected phase frames
- F4.4 Toggle skeleton overlay on/off

### F5. History & Compare
- F5.1 Per-player session list, newest first
- F5.2 Side-by-side comparison of any two swings (same player or cross-player)
- F5.3 Metric trend chart: last 10 swings for a chosen metric

### F6. Settings
- F6.1 Manage player profiles (add, rename, delete)
- F6.2 Storage usage view + per-session delete
- F6.3 Camera FPS preference

## 7. Success metrics

| Metric | Target (90 days post-launch) | Measurement |
|---|---|---|
| First-swing-to-analysis time | p50 < 30s, p95 < 60s | Local instrumentation |
| Weekly active retention | 40% W2 → W4 | Local opt-in analytics |
| Swings per active user per week | ≥ 5 | Local opt-in analytics |
| Phase-detection acceptance | ≥ 90% swings not manually corrected | "Adjust phase" UI events |
| Crash-free sessions | ≥ 99.5% | Sentry / Crashlytics |
| App store rating | ≥ 4.3 | Store data |

## 8. Release plan

- **Alpha (week 6):** Internal — Annie + 5 hand-picked golfers, 2 weeks
- **Closed beta (week 8):** 30 users via TestFlight + Play Internal Testing, 4 weeks
- **Public beta (week 12):** Open Play Store / TestFlight beta, gated invites
- **GA (week 16):** Both stores, free, no monetization yet

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Pose accuracy insufficient at outdoor angles | Med | High | Sofia builds labeled corpus week 1; QA gates each phase |
| Low-end Android can't sustain 60fps | Med | Med | Graceful fallback to 30fps + warning UI |
| Users don't trust metrics | Med | High | Show plain-English context, not just numbers; user study validates wording |
| Storage fills up fast (videos are big) | High | Med | Compress on save, show storage usage, suggest deletes |
| App store rejection (camera permissions) | Low | High | Clear permission rationale screens |

## 10. Out-of-scope but tracked for v1.1+

- Coach mode (annotation, voice notes, share to student) — needs spec after husband interview
- Cloud backup
- Friend accounts and sharing
- Pro swing overlays
- Apple Watch capture trigger
