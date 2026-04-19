# User Study Plan — GolfBuddy MVP

**Authors:** Jordan (PM) + Lin (UX)  ·  **Status:** Draft v0.1

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
- **Participants:** 6 recreational golfers — mix of solo + with-friends preference, age 25–55, mix of Android/iOS
- **Recruitment:** Local driving range bulletin board + Reddit r/golf + Annie's network (3 from each)
- **Compensation:** $30 gift card
- **Script topics:**
  - Walk me through your last range session
  - Have you ever filmed yourself? What did you do with the video?
  - What do you wish you knew about your swing?
  - Show competitor: SwingU, Zepp, V1 Golf — what works, what doesn't?
- **Output:** Interview synthesis doc, 3–5 themes, scope adjustments to PRD

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

**Goal:** Real range, real conditions, real failure modes.

- **Method:** In-person at 2 driving ranges. Researcher (Lin) present, observes, interviews after.
- **Participants:** 6 alpha users including Annie. Each does a normal 30-min range session with the app installed.
- **Observation focus:**
  - Phone-stand setup time and reliability
  - One-handed glove use
  - Sun/glare on screen
  - Time between hitting a ball and reviewing the analysis
  - Did they actually change anything based on the feedback?
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

## 4. Recruitment screener (Phase 1 example)

1. Do you play golf at least once a month? *(must be yes)*
2. Have you been to a driving range in the last 60 days? *(must be yes)*
3. Self-assessed handicap or skill level *(want a spread)*
4. Do you sometimes go alone, with friends, or both? *(want a mix; bias toward "both")*
5. Smartphone OS *(want at least 2 Android, 2 iOS)*
6. Have you ever used a swing-analysis app? *(want a mix)*

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
