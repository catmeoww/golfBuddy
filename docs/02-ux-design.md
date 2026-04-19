# UX Design Proposal — GolfBuddy MVP

**Author:** Lin (UX)  ·  **Status:** Draft v0.2 (post-P01 synthesis)

## 1. Design principles

1. **Library-first.** The product is an organized video library for a coach. The first thing M sees when he opens the app is his library, not a camera. Capture is a tab, not the home.
2. **Capture in 2 taps.** From Capture tab to recording: pick player chip → tap record. The "who are you filming" choice is required but one-tap.
3. **Annotation is a first-class verb.** Notes (overall + frame-anchored) are not buried in a menu — they live on the session review screen alongside the video and metrics.
4. **Tournaments are a first-class grouping.** Sessions aren't just a flat list by date; they're optionally grouped by the tournament they lead into or follow.
5. **Show, don't tell.** Skeleton overlay, slow-mo, side-by-side. Numbers come with a band label (good / fair / off); long-form coaching copy is NOT the hero — the coach does his own translation.
6. **Honest uncertainty.** If pose or phase detection is low-confidence, say so and let the user correct.
7. **Trust the data is his.** Nothing leaves the phone in MVP. Privacy copy reinforces this. A years-of-Ethan library is precious; manual export-bundle exists as an escape hatch.

**What we explicitly dropped:** range-first ergonomics (sun glare, gloved hands, one-handed outdoor use). The primary context is indoor/backyard, Wi-Fi, phone on a stand. We keep big tap targets and high-contrast type because they're good practice, not because of sun.

## 2. Information architecture

```
Tab 1: Library (default)
  └─ Player chips + filters (club, tournament, date range)
     └─ Session grid (thumbnails)
        └─ Session review screen
           ├─ Player / tournament context banner
           ├─ Video + skeleton overlay
           ├─ Metrics
           ├─ Annotations panel (overall note + time-anchored notes)
           └─ Phase scrubber
              └─ Compare picker → Side-by-side
  └─ Tournaments entry point (top-right on Library)
     └─ Tournaments list → Tournament detail (sessions grouped before/during/after)

Tab 2: Capture
  └─ Player chip selector (required pre-capture)
     └─ Camera viewfinder + record
        └─ Post-capture: Trim → Confirm player/club/tournament → Save
           └─ Auto-route to Session review

Tab 3: Settings
  ├─ Players (add/edit/delete, set player_type)
  ├─ Tournaments (manage events)
  ├─ Storage (usage + export bundle)
  ├─ Camera (FPS preference)
  └─ About / Privacy
```

3 tabs only. Library is first and default. Capture moves to tab 2.

## 3. Key flows

### Flow A: 10-min backyard block — capture several swings

1. **Launch → Library tab** (shows last session at top for reassurance that everything is still there).
2. Tap **Capture tab**. Top of viewfinder shows a chip row: [Ethan] [+] — Ethan is pre-selected because he was last used.
3. Tap record (or wait for countdown). Recording indicator + ring. Auto-stop after configurable max (default 8s).
4. **Trim screen.** Auto-trimmed window with handles. "Looks good" primary CTA.
5. **Confirm sheet.** Player (already set), Club [Driver/Iron/Wedge/Putter/Skip], Tournament [none / pick event], Save. Every field has a default so "Save" is one tap in the common case.
6. Route to **Session review** — but only briefly; in a rapid-fire block M taps back to Capture in one tap. The saved session is already in the Library.

### Flow B: Capture a different person (friend, or Ethan's friend)

Same as A, except in step 2 M taps the player chip row, picks a different name, or taps [+] to add a new person. `player_type` defaults to `friend` for new additions from this flow.

### Flow C: Review after the block — annotate & discuss with Ethan

1. **Library tab** → tap today's Ethan chip to filter → today's session grid shows the clips just captured.
2. Tap a session → **Session review**.
3. Watch the swing. Tap the scrubber at a moment → **"Add note"** → type "hips open early" → save. Marker appears on scrubber.
4. Add an overall session note ("looked tired today, tournament weekend recovery").
5. Swipe back to Library, move on.

### Flow D: Compare across a tournament boundary

1. **Library tab** → open a session → **Compare** button.
2. Picker: defaults to "same player, sorted by date." Filter chip "around a tournament" — pick a tournament event → sessions are grouped before/during/after. Tap one on each side.
3. **Side-by-side.** Sync mode: Align by phase (default) OR Align by tournament (shows the closest before-tournament vs. closest after-tournament swings).

### Flow E: Create a tournament event

1. **Library → Tournaments entry point** OR **Settings → Tournaments**.
2. "+ New" → name, date or date range, optional location, optional notes → Save.
3. Tournament now appears in the tournament picker on the Confirm sheet (Flow A step 5) and in Library filters.

### Flow F: Upload existing video (legacy footage)

1. Capture tab → small "Upload" icon top-left.
2. System picker → choose video.
3. Trim (mandatory — uploaded videos are usually too long).
4. Confirm sheet → Save. Same as Flow A from step 4.

### Flow G: Trend view

1. **Library tab → any player chip → "Trend" button** (near filters).
2. Pick a metric (tempo / shoulder turn / hip turn / head stability).
3. Scroll-zoomable chart, tournament events marked as vertical lines, tap a point to jump to that session.

## 4. Screen-by-screen highlights

### Library screen (home)
- Top bar: App title, Tournaments entry (icon), Trend entry (icon), filter chip.
- Below: horizontal player chips — tap to filter; long-press to manage.
- Below: filter chips (Club, Tournament, Date range) that expand into modals.
- Grid of session cards: thumbnail + date + club + tournament tag (if any) + headline metric. Annotation-badge if the session has notes.
- Empty state (no sessions yet): illustration + "Record your first swing" CTA that deep-links into Capture.

### Capture screen
- Full-bleed camera preview.
- Top chip row: Player chips, last-used pre-selected. [+] at the end to add someone on the spot.
- Top bar: Upload (far left), Countdown selector (right), Settings gear (far right).
- Bottom: Record button, FPS chip showing current (e.g. "60fps").
- Long-press record = lock recording (so M can step away to the hitting position).

### Session review screen
- **Top banner:** Player name + avatar · date · club · tournament tag (tap to filter library by that tournament).
- **Video + skeleton:** main hero area, toggle overlay on/off.
- **Metrics strip:** tempo / shoulder / hip / head cards in a horizontal scroll. Each shows number + band label; tap to see the underlying data and phase frames used.
- **Annotations panel:** overall text note at top (inline-editable), then list of frame-anchored notes sorted by timestamp. Tap a note to jump scrubber.
- **Phase scrubber:** dots for A · T · I · F, plus annotation markers. Tap phase dot to jump; tap scrubber → "Add note" affordance.
- **Compare** button, **Adjust phases** button, **Delete** in overflow.

### Tournament detail screen
- Header: name, date(s), location, notes (editable).
- Sessions grouped into Before / During / After with thumbnails.
- "Trend during this tournament window" chart for any metric.

### Compare screen
- Two video strips side-by-side, synchronized scrubbing.
- Sync mode toggle: **Align by phase** (default) | **Align by tournament** (A is closest-before, B is closest-after).
- Metrics diff table below with up/down arrows.
- Annotations from both sessions listed as a combined timeline underneath.

### Trend screen
- Per-player, per-metric line chart.
- Tournament events render as vertical lines with labels.
- Scroll to zoom/pan time range. Tap a point → jump to that session.

### Confirm sheet (post-capture)
- Bottom sheet.
- Player row: pre-filled, shows chosen chip; tap to change.
- Club row: 4 fixed chips + Skip.
- Tournament row: "None" default + existing events + "+ New."
- Save button bottom-right; sensible defaults mean one tap.

## 5. Visual design notes

- **Color:** dark UI by default (battery on OLED; quiet for backyard twilight). Accent: a confident green (#2BB673) for primary actions and "good" metrics. Warning amber for "needs work." Avoid red except for record indicator.
- **Type:** Inter (or system) — 16pt body, 24pt H1, 14pt caption minimum. Tabular numerals for metrics.
- **Iconography:** Material Symbols, filled style.
- **Skeleton overlay:** semi-transparent white lines, 3pt; joint dots in accent green. Reads cleanly against indoor walls, net backgrounds, and grass.
- **Annotation markers:** small amber dot on the scrubber, with a connector line to the note bubble when selected.

## 6. Empty / error / edge states

| State | Treatment |
|---|---|
| First launch (no sessions) | Library shows illustration + "Record your first swing" CTA that deep-links to Capture; player "Ethan" is pre-seeded but editable |
| No camera permission | Inline rationale screen with explainer + "Open Settings" |
| Pose detection failed (no person in frame) | Banner: "Couldn't see the golfer — re-record from a wider angle" + retry CTA |
| Low-confidence phase detection | Phase dots show dashed outline; "Adjust phases" button is primary |
| Storage full | Pre-record warning sheet, with "Free up space" deep link to Library/Storage |
| Slow processing (>5s) | Progress bar + "Analyzing your swing…" copy |
| No tournaments created yet | Tournament picker shows "+ New tournament" only, no empty list card |

## 7. Accessibility

- All interactive elements ≥ 56dp tap target
- Color contrast WCAG AA minimum (AAA for body text)
- Dynamic Type / Text Scaling supported up to 200%
- VoiceOver / TalkBack labels on all controls; metric cards announce as "Tempo, 2.5 to 1, fair"
- Reduce-motion users get a fade transition between phase frames instead of scrubbing animation
- Captions/labels never rely on color alone — pair with shape/icon
- Annotation markers are announced by timestamp and preview text

## 8. Prototype plan

- **Week 1:** Lo-fi wireframes for Library, Capture, Session review, Tournament detail, Trend. Review with team.
- **Week 2:** Hi-fi Figma mocks for Library + Session review (incl. annotations) + Capture.
- **Week 3:** Clickable prototype for moderated test (5 hobby-coach recruits).
- **Week 4:** Iterate based on test findings, hand off to Raj.

## 9. Open UX questions

- Should countdown auto-cancel if no motion detected after recording starts? (Avoids 5s of blank video.)
- Where does "Compare" live — Session review button, Library multi-select, or both? (Leaning both: primary on Session review, secondary as Library multi-select.)
- Default playback speed on first open of Session review: full-speed or 0.5x slow-mo?
- **Does the kid ever interact with the app directly, or only the coach?** (Current assumption: coach-only for MVP. If yes later, there's a "watch yourself" mode to design.)
- Time-anchored annotations: tap to add vs. long-press to add? Tap is faster but risks accidental notes during scrubbing.
