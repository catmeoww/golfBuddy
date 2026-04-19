# PRD — GolfBuddy MVP

**Author:** Jordan (PM)  ·  **Status:** Draft v0.2 (post-P01 synthesis)  ·  **Target ship:** 6 weeks

## 1. Problem

Hobby golf coaches who coach a child or a small circle of friends have no good way to organize and annotate swing video. They want to record short clips during a practice block, tag them by player and by tournament context, scribble a note or two, and later compare swings over time. Today that happens — if it happens at all — in the phone's default gallery, where golf footage is lost in a sea of family photos, can't be annotated, and can't be compared side-by-side. The friction is high enough that most of the video never gets recorded in the first place.

The core job isn't on-the-spot analysis. It's **organization and annotation**, after the practice block is over.

## 2. Target user

**Primary persona — "M", 40s, hobby golf coach (parent-coach)**
- Coaches his 7-year-old son Ethan ~5 days/week, 10 minutes/day, in the backyard with a net and launch-style tracker
- Runs a monthly informal 18-hole session with adult friends
- Lives in Los Altos, CA; Wi-Fi available wherever he coaches
- Ethan competes in US Kids tournaments; M plans each practice block against Ethan's last tournament performance
- Owns Android as daily driver
- Tech-comfortable; already uses a launch-monitor tracker and interprets its data himself
- Goal: *"Organized data so it's easy to give advice and learn about his improvement over time."*
- Frustration: *"Google Photos has all other videos/photos. It's hard to find all the golf videos and compare. And also we can't take notes on Google Photos."*

**Important distinction:** the coach is the USER. The student (Ethan or a friend) is the SUBJECT of the video, not the operator of the app. Review happens with the student after the 10-minute block, not during.

**Secondary (v1.1+):** any regular coach-student pair — private coaches, high-school assistant coaches, adult friends who mutually coach each other. Beta is the moment to test whether the product generalizes beyond parent-coach-of-young-competitor.

## 3. Goals

- **G1.** M can capture a swing during a 10-minute backyard block with near-zero friction (phone on stand, one tap to record, one tap to tag).
- **G2.** Every captured swing lands in a library organized by player, date, club, and tournament — no swing is ever "lost" the way Google Photos loses them.
- **G3.** M can annotate specific swings (overall note and frame-anchored notes) so that when he reviews with Ethan, he has his own coaching notes in front of him.
- **G4.** M can compare any two swings — today vs. last week, before vs. after a tournament — and see a trend over time.
- **G5.** Works reliably in a backyard environment on Wi-Fi; nothing leaves the phone in MVP.

## 4. Non-goals (MVP)

- Real-time, range-side analysis during the swing itself — review is post-block
- Social features, sharing feeds, follower graphs
- Coach/student marketplace, payments (M coaches for free)
- Cloud backup, multi-device sync (deferred to v1.1, not MVP — see §10)
- AI chat coach, natural-language feedback generation
- Pro-swing comparison library
- Wearables, club sensors, launch monitor integration (tracker import is v1.1)
- Apple/Google account login, server-side accounts
- A kid-facing mode where Ethan operates the app himself

## 5. User stories

| ID | As a... | I want to... | So that... |
|----|---------|--------------|------------|
| US-1 | coach running a 10-min backyard block | prop my phone on a stand and record Ethan's swing in one tap | I don't burn the block fiddling with the phone |
| US-2 | coach filming different people | pick who I'm filming (Ethan / named friend / custom) before I record | the clip lands in the right player's library |
| US-3 | coach reviewing after a block | find the swings I just recorded, and every swing before them, organized by player and date | I never lose a clip the way I lose them in Google Photos |
| US-4 | coach with a specific observation | add a text note to the whole session, and timestamp notes on specific moments of a swing | when I review with Ethan I have my coaching cues in front of me |
| US-5 | coach planning against tournaments | tag sessions as before / during / after a tournament event | I can see what we worked on going into a tournament and what changed after |
| US-6 | coach tracking progress | compare Ethan's swing today to his swing before the last tournament | I can tell whether our adjustments are sticking |
| US-7 | coach watching trends | see a per-player metric trend over weeks/months | I can spot real improvement (or regression) beyond any single session |

## 6. Functional requirements

### F1. Capture
- F1.1 Record swing using device camera at 60fps minimum, 240fps where supported
- F1.2 In-app countdown timer (3/5/10s) for hands-off recording from a stand
- F1.3 Auto-trim to swing window if detected; manual trim handles otherwise
- F1.4 Import video from device gallery (any orientation) for legacy footage
- F1.5 **Who are you filming?** required pre-capture choice — chip selector over the viewfinder (Ethan / named friend / + custom). Persists the last choice; tap to change.

### F2. Tagging
- F2.1 Local player profiles (name + optional avatar + `player_type`: self / child / friend / student). Default: seeded with "Ethan" on first run so M doesn't have to configure before the first clip
- F2.2 Player chosen pre-capture (see F1.5); editable post-capture if wrong
- F2.3 Optional club tag (Driver / Iron / Wedge / Putter)
- F2.4 Optional tournament tag (see F8)

### F3. Analysis
- F3.1 Pose skeleton overlaid on video playback
- F3.2 Auto-detect 4 phases: address, top of backswing, impact, finish
- F3.3 Compute metrics:
  - Tempo ratio (backswing duration : downswing duration), target 3:1
  - Shoulder rotation at top (degrees)
  - Hip rotation at top (degrees)
  - Head movement (max displacement from address position, cm estimate)
- F3.4 Metrics shown as numbers with concise band labels (good / fair / off). Plain-English coaching copy is secondary — the coach consumes raw data and explains it to the student himself

### F4. Playback
- F4.1 Full-speed and slow-motion (0.25x, 0.5x) playback
- F4.2 Frame-by-frame scrubbing
- F4.3 Jump to detected phase frames
- F4.4 Toggle skeleton overlay on/off
- F4.5 Annotation markers appear on the scrubber (see F7)

### F5. Library & Compare
- F5.1 **Library is the default/home screen.** Player chips at top; session grid with thumbnails; filters by player, club, tournament, date range
- F5.2 Side-by-side comparison of any two swings (same player or cross-player); align by phase OR align by tournament boundary
- F5.3 Metric trend chart: per-player, per-metric, scroll-zoomable over time; tournament events marked on the x-axis

### F6. Settings
- F6.1 Manage player profiles (add, rename, set player_type, delete)
- F6.2 Storage usage view + per-session delete
- F6.3 Camera FPS preference

### F7. Annotations (NEW)
- F7.1 Per-session text note — a single freeform field the coach can edit anytime
- F7.2 Time-anchored notes — tap a moment on the scrubber, type a note, it's pinned to that frame
- F7.3 Annotations render as markers on the scrubber; tap a marker to see the text
- F7.4 Annotations are text-only in MVP; audio notes are v1.1

### F8. Tournaments (NEW)
- F8.1 Create a tournament event: name, date (single or range), optional location, optional notes
- F8.2 Tag any session with a tournament + relation (`before` / `during` / `after`)
- F8.3 Tournament detail screen: all sessions grouped by relation, tournament-level notes
- F8.4 Tournament events appear as vertical lines on the trend chart (F5.3)

## 7. Success metrics

| Metric | Target (90 days post-launch) | Measurement |
|---|---|---|
| Sessions tagged (player + club) within 24h of capture | ≥ 85% | Local instrumentation |
| Sessions with at least one annotation | ≥ 40% | Local instrumentation |
| Trend chart opens per active week per user | ≥ 2 | Local opt-in analytics |
| First-swing-to-library time | p50 < 30s, p95 < 60s | Local instrumentation |
| Weekly active retention (W2 → W4) | 50% (coaches are more habitual than casual users) | Local opt-in analytics |
| Phase-detection acceptance | ≥ 90% swings not manually corrected | "Adjust phase" UI events |
| Crash-free sessions | ≥ 99.5% | Sentry / Crashlytics |
| App store rating | ≥ 4.3 | Store data |

## 8. Release plan

- **Alpha (week 6):** Internal — M + 4 other parent/hobby coaches, 2 weeks
- **Closed beta (week 8):** 30 users via TestFlight + Play Internal Testing, 4 weeks; actively recruit beyond parent-coaches to pressure-test ICP breadth
- **Public beta (week 12):** Open Play Store / TestFlight beta, gated invites
- **GA (week 16):** Both stores, free, no monetization yet

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Pose accuracy insufficient on typical backyard angles | Med | High | Sofia builds labeled corpus week 1; QA gates each phase |
| Low-end Android can't sustain 60fps | Med | Med | Graceful fallback to 30fps + warning UI |
| Storage fills up fast (videos are big, and coaches accumulate a lot over a year) | High | Med | Compress on save, show storage usage, suggest deletes, prioritize cloud backup in v1.1 |
| App store rejection (camera permissions) | Low | High | Clear permission rationale screens |
| **Small target audience — parent-coaches of competitive young golfers is a narrow ICP** | Med | High | Validate expansion to any regular coach-student pair in beta; recruit hobby coaches broadly (assistant coaches, adult peer-coaching, private instructors) to test generalization |
| Coach loses years of data if phone dies before we ship cloud backup | Med | High | Ship export-bundle (zip of videos + DB) in MVP as a manual-backup escape hatch; cloud backup in v1.1 |

## 10. Out-of-scope but tracked for v1.1+

- **Cloud backup** — promoted to top of v1.1 list. Backyard implies Wi-Fi and coaches accumulate irreplaceable footage of their kids over years. Manual export-bundle in MVP is the bridge.
- **Tracker data import** — M already uses a launch-style tracker; bridging video + tracker numbers is a natural next step. Scope depends on which tracker(s) we support (open question — see §11).
- **Audio annotations** — voice notes tied to a frame, since coaches often verbalize faster than they type.
- Coach-to-coach sharing (export-bundle v1.1 + import)
- Friend accounts and sharing
- Pro swing overlays
- Apple Watch capture trigger
- Kid-facing "watch yourself" mode — low-friction playback screen Ethan can operate post-block while M reviews

## 11. Open questions

- Does the student (Ethan) ever interact with the app directly, or is it coach-only for MVP? (Current assumption: coach-only.)
- Which tracker does M actually use, and which trackers should v1.1 import support?
- What's the minimum viable cloud backup story for v1.1? (Opaque encrypted blob vs. per-session sync vs. full replica.)
