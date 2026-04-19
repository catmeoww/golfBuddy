# UX Design Proposal — GolfBuddy MVP

**Author:** Lin (UX)  ·  **Status:** Draft v0.1

## 1. Design principles

1. **Range-first ergonomics.** Designed for one-handed use with a glove on, in direct sun. Big tap targets (≥56dp), high-contrast type, minimum 16pt body.
2. **Capture in 2 taps.** From cold launch to recording: open → capture button. Tagging happens AFTER, never before.
3. **Show, don't tell.** Skeleton overlay, slow-mo, side-by-side. Numbers come with a plain sentence that says what they mean.
4. **Honest uncertainty.** If pose detection or phase detection is low-confidence, say so and let the user correct.
5. **Trust the data is hers.** Nothing leaves the phone in MVP. Privacy copy reinforces this.

## 2. Information architecture

```
Tab 1: Capture (default)
  └─ Camera viewfinder
     └─ Post-capture: Trim → Tag player/club → Save
        └─ Auto-route to Analysis screen

Tab 2: History
  └─ Player picker (chips)
     └─ Session list (newest first)
        └─ Analysis screen
           └─ Compare picker → Side-by-side analysis

Tab 3: Settings
  ├─ Players (add/edit/delete)
  ├─ Storage
  ├─ Camera (FPS preference)
  └─ About / Privacy
```

3 tabs only. Resist the urge to add a "Learn" or "Tips" tab in MVP.

## 3. Key flows

### Flow A: Capture own swing (alone, tripod)

1. **Launch → Capture tab.** Big red record button center-bottom. Countdown selector top-right (Off / 3s / 5s / 10s). Default 5s.
2. Tap record (or wait for countdown). Recording indicator + ring. Auto-stop after configurable max (default 8s).
3. **Trim screen.** Auto-trimmed window with handles. "Looks good" primary CTA, swipeable to adjust.
4. **Tag sheet.** Player chips: [Me] [+ Add]. Club row: [Driver] [Iron] [Wedge] [Putter] [Skip]. One tap each, "Done" or auto-advance.
5. **Analysis screen.** Skeleton + metrics rendered (loading state if still processing — should be < 3s on mid-tier device).

### Flow B: Capture friend's swing

Same as A, except in step 4 Annie taps a friend's chip instead of [Me]. If new friend, [+ Add] opens a one-field name dialog.

### Flow C: Upload existing video

1. Capture tab → small "Upload" icon top-left.
2. System picker → choose video.
3. Trim screen (mandatory — uploaded videos are usually too long).
4. Tag → Analysis. Same as Flow A from step 3.

### Flow D: Review history & compare

1. History tab → player chips at top, default to last-used player.
2. Vertical list of session cards: thumbnail + date + club + key metric headline ("Tempo 2.5:1").
3. Tap card → Analysis screen.
4. From Analysis, "Compare" button → list of other swings (same player default, can switch). Pick one → side-by-side.

## 4. Screen-by-screen highlights

### Capture screen
- Full-bleed camera preview
- Top bar: Upload (left), Countdown selector (right), Settings gear (far right)
- Bottom: Record button, FPS chip showing current (e.g. "60fps")
- Long-press record = lock recording (so she can put phone on stand and step away)

### Analysis screen
- Top half: video with skeleton overlay
- Phase scrubber strip below video: 4 dots labeled A · T · I · F (address, top, impact, finish). Tap to jump.
- Bottom half scroll:
  - Tempo card: visual ratio bar with target 3:1 marked
  - Shoulder turn card: dial showing degrees
  - Hip turn card: dial showing degrees
  - Head stability card: max-displacement number + "good / fair / off" label
- Each card has a "What does this mean?" expandable section
- "Adjust phases" button (low-confidence cases highlight this)

### Compare screen
- Two video strips side-by-side, synchronized scrubbing
- Phase markers aligned on a shared timeline
- Metrics table below: side-by-side numeric diff with up/down arrows

### Tag sheet (post-capture)
- Bottom sheet, swipe-up reveal
- Player row: horizontal-scrolling chips, current default first
- Club row: 4 fixed chips + Skip
- Save button bottom-right; chips auto-confirm so the button is often unnecessary

## 5. Visual design notes

- **Color:** dark UI by default (sun glare friendly + battery on OLED). Accent: a confident green (#2BB673) for primary actions and "good" metrics. Warning amber for "needs work." Avoid red except for record indicator.
- **Type:** Inter (or system) — 16pt body, 24pt H1, 14pt caption minimum. Tabular numerals for metrics.
- **Iconography:** Material Symbols, filled style.
- **Skeleton overlay:** semi-transparent white lines, 3pt; joint dots in accent green. High enough contrast to read against grass and sky.

## 6. Empty / error / edge states

| State | Treatment |
|---|---|
| First launch (no swings) | Capture tab opens directly to camera; History tab shows illustration + "Record your first swing" CTA |
| No camera permission | Inline rationale screen with explainer + "Open Settings" |
| Pose detection failed (no person in frame) | Banner: "Couldn't see the golfer — re-record from a wider angle" + retry CTA |
| Low-confidence phase detection | Phase dots show dashed outline; "Adjust phases" button is primary |
| Storage full | Pre-record warning sheet, with "Free up space" deep link to history |
| Slow processing (>5s) | Progress bar + "Analyzing your swing…" copy |

## 7. Accessibility

- All interactive elements ≥ 56dp tap target
- Color contrast WCAG AA minimum (AAA for body text)
- Dynamic Type / Text Scaling supported up to 200%
- VoiceOver / TalkBack labels on all controls; metric cards announce as "Tempo, 2.5 to 1, slightly fast"
- Reduce-motion users get a fade transition between phase frames instead of scrubbing animation
- Captions/labels never rely on color alone — pair with shape/icon

## 8. Prototype plan

- **Week 1:** Lo-fi wireframes for the 4 flows, review with team
- **Week 2:** Hi-fi Figma mocks for Capture + Analysis
- **Week 3:** Clickable prototype for moderated user test (5 users)
- **Week 4:** Iterate based on test findings, hand off to Raj

## 9. Open UX questions

- Should countdown auto-cancel if no motion detected after recording starts? (Avoids 5s of blank video.)
- Where does "Compare" live — Analysis screen button, or History screen action? (Leaning Analysis.)
- Default playback speed on first open of Analysis: full-speed or 0.5x slow-mo?
