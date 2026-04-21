# Feature Requests

Running log of feature requests from real users. Add a new entry every time a user asks for something we haven't built. Status moves through:

- **proposed** — captured, not yet planned
- **planned** — accepted, on the roadmap
- **in progress** — being built right now
- **shipped** — landed on `claude/plan-golf-app-bTwdT`
- **deferred** — accepted in principle, parked for later
- **rejected** — explicitly out of scope

---

## FR-001 — Drawing tools (lines + circles) on the video

**Source:** M (husband, primary persona) — direct feedback after first use.
**Date raised:** 2026-04-21
**Status:** in progress

**What he wants:**
- Pause the video at a specific frame, draw circles around the head and lines along hands, waist, and legs, then play through the swing to see whether the body stays inside / aligned with the reference shapes.
- Coaching use case: visualize correct vs. incorrect movement against a static reference he draws himself.

**Why it matters:**
- It's the first request from a real coach using the app.
- Today he interprets the video by eye; references would let him show Ethan exactly what to fix.
- Pairs directly with the annotations feature already shipped — drawings are visual notes.

**Scope (v1 of this feature):**
- Tools: circle, straight line.
- Per-frame markup: each drawing pinned to a single timestamp.
- Playback: drawing visible when scrubber is within ±200 ms of its timestamp.
- Tap an existing drawing to delete it; long-press to enter draw mode at the current frame.
- Persists in DB, survives app relaunch.

**Out of scope (later):**
- Free-hand drawing.
- Color picker (single accent color for now).
- Drawings that auto-track joints during playback (would require pose-locked overlays).
- Animations / transitions.

---

## FR-002 — Behind-the-golfer camera support (3D pose)

**Source:** M.
**Date raised:** 2026-04-21
**Status:** deferred

**What he wants:**
- Film from behind the golfer (down the swing's depth axis) to see the upswing track.

**Why it matters:**
- Behind-view shows swing plane and club path — things you cannot see from the side.

**Why deferred:**
- Current 2D pose model loses the swing's depth motion in the projection. Wrist X-crossing for impact and 2D shoulder/hip angles all collapse to nothing meaningful.
- Real fix needs a 3D pose model (MediaPipe Pose 3D world landmarks or similar) plus rewriting the phase detector and metric calculators against 3D coords.
- Estimated cost: days of work + accuracy validation against a labeled corpus.

**Trigger to revisit:**
- Multiple coaches request it (currently n=1).
- Or M starts using it heavily and the side-on view stops being enough.

**Workaround today:**
- Hint added on the Capture screen telling the coach to film down-the-line or face-on for accurate metrics.

---

## How to add a new request

When a user asks for something:

1. Append a new `## FR-NNN — Short title` section here.
2. Fill in: Source · Date raised · Status · What they want · Why it matters · Scope or Why deferred.
3. If it's something we'll ship soon, link the commit(s) in the entry once landed.
4. If it's deferred, note the trigger condition that would reopen it.

Keep entries terse — this is a log, not a spec. Specs go in `docs/01-prd.md`.
