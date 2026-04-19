# User Study Plan — GolfBuddy MVP

**Authors:** Jordan (PM) + Lin (UX)  ·  **Status:** Draft v0.2 (post-P01 synthesis)

## 1. Research goals

We need to answer:

- **G1.** Is the swing-capture flow fast and natural enough for use between practice swings at the range?
- **G2.** Do users trust and understand the metrics we surface?
- **G3.** Does the analysis change what they do next (i.e., does it create a feedback loop)?
- **G4.** Where does the experience break down — physically (sun, gloves, stand), cognitively (jargon), or technically (failed analysis)?

## 2. Study phases

### Phase 1 — Discovery interviews (pre-build, week 0–1)

**Goal:** Validate the problem and pressure-test the MVP scope before any code.

- **Method:** 30-min remote interviews
- **Participants:** 6 **parent-coaches or hobby coaches** who regularly coach at least one person (child, spouse, friend, mentee). Mix of coaching frequency (daily to monthly) and student type (child vs. adult peer). Mix of Android/iOS.
- **Recruitment:** US Kids Golf parent communities, local junior golf programs, Reddit r/golf + r/juniorgolf, M's referrals. Avoid pure recreational golfers for this phase — Phase 1 is now coach-focused.
- **Screener:** `research/phase-1-discovery/screener-coach.md` (new). The prior `screener.md` is retained as a secondary/alt screener for a recreational-golfer pass if we decide to widen later.
- **Compensation:** $30 gift card
- **Script topics:**
  - Walk me through your last coaching block (who, where, how long)
  - How do you currently capture and organize swings — if at all?
  - How do you decide what to work on each session?
  - What do you wish you could annotate, compare, or track over time?
  - Show competitor: V1 Golf, Hudl Technique, Coach's Eye — what works, what doesn't?
- **Output:** Interview synthesis doc, 3–5 themes, scope adjustments to PRD. (P01 proxy synthesis already on file — re-verify with M directly.)

### Phase 2 — Concept testing (mid-build, week 3)

**Goal:** Validate flows and visual language before lock.

- **Method:** Moderated 45-min remote test using Figma clickable prototype
- **Participants:** 5 new golfers (different from Phase 1)
- **Tasks (think-aloud):**
  - "You just took a swing. Show me how you'd record it."
  - "Your friend hits next. Show me how you'd film their swing instead."
  - "You see your tempo is 2.5 to 1. What does that mean to you?"
  - "Compare today's swing to last Tuesday's."
- **Metrics:** Task completion rate, time on task, SUS at end, qualitative confusion points
- **Output:** UX iteration list, copy refinements

### Phase 3 — Field test (alpha, week 6–8)

**Goal:** Real coaching context, real conditions, real failure modes.

- **Method:** In-person visits to wherever the alpha users actually coach — backyard, home net, indoor sim, range, whatever's real. Researcher (Lin) present, observes, interviews after.
- **Participants:** 6 alpha users including M. Each runs a normal coaching block (typically 10–30 min) with the app installed.
- **Observation focus:**
  - Phone-stand setup time and reliability
  - Pre-capture "who are you filming" tap count
  - Time from end-of-block to first annotation (the review moment)
  - Library findability: can they re-find last week's session in ≤ 10s?
  - Tournament tagging: do they actually use it, or is it friction?
  - Did the coach change anything about next session based on the review?
- **Output:** Critical issue list (P0/P1/P2), photo/video documentation, post-session interview transcripts

### Phase 4 — Closed beta diary study (week 8–12)

**Goal:** Longitudinal — does it stick?

- **Method:** 30 beta users keep a 4-week light-touch diary (3 questions, 1x/week via in-app prompt)
- **Diary prompts:**
  - How many swings did you record this week? (slider)
  - Did the app tell you anything useful? (open text, max 200 chars)
  - One thing you wished worked differently? (open text)
- **Plus:** weekly anonymized usage metrics for those who opt in
- **Output:** Retention insight, feature priority list for v1.1

### Phase 5 — Post-launch continuous research (ongoing)

- In-app feedback button → typed response + optional video attachment → emails Jordan
- Quarterly 5-user re-test of any redesigned flow
- Quarterly review with Annie's husband (the coach) toward v1.1 coach mode spec

## 3. Special studies

### S1. Pose accuracy perception study
Run alongside Phase 2. Show users a video where the skeleton is intentionally slightly wrong and ask if they noticed and if they trust it. Calibrates what "good enough" means perceptually for the engineering team's accuracy target.

### S2. Coach interview (for v1.1 planning)
Single deep interview with Annie's husband and 2 other coaches. Topics: how they currently teach, what artifacts they share with students, what tools they use, what they'd pay for.

## 4. Recruitment screener (Phase 1)

Full screener lives at `research/phase-1-discovery/screener-coach.md`. Summary filter criteria:

1. Do you regularly coach anyone on their golf swing — child, spouse, friend, mentee? *(must be yes — frequency at least monthly)*
2. How often do you coach that person? *(want a spread, bias toward weekly+)*
3. Do you currently record video of their swings? *(want a mix of yes/no)*
4. If yes, where do those videos live today? *(open text; signal on pain)*
5. Is your student a child, an adult peer, or both? *(want a mix; bias toward "at least one child" since that's the validated persona)*
6. Smartphone OS *(want at least 2 Android, 2 iOS)*

The prior `screener.md` (recreational-golfer persona) is retained as a secondary pass if we need to widen the ICP in a later phase.

## 5. Ethics & consent

- Written consent before any session; recordings deleted within 90 days unless participant opts in to longer retention
- No video footage of children at the range — researcher avoids framing
- Compensation paid regardless of completion
- Beta participants can export and delete their data at any time

## 6. Reporting cadence

- After Phase 1: written synthesis + team workshop, scope decisions logged in `00-team-kickoff.md` open questions
- After Phase 2: quick-loop deck, design changes within the same week
- After Phase 3: P0 issues block beta launch; P1 issues block GA
- After Phase 4: monthly insight digest for the team

## 7. Success criteria for proceeding to GA

- Phase 3: ≥ 5 of 6 alpha users complete a record-tag-review loop without researcher intervention
- Phase 4: ≥ 60% of beta users record swings in week 4 (retention proxy)
- ≥ 4.0 average usefulness rating on diary prompts
- No unresolved P0 issues
