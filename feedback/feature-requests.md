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
**Status:** shipped on commit `2b52c71`

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

## FR-006 — Upload existing video for analysis

**Source:** Annie (and a prerequisite for Wen-Tai's FR-003).
**Date raised:** 2026-04-21
**Status:** planned (top priority after FR-001 ships)
**Priority:** P0

**What she wants:**
- A back-catalog of swing videos already lives in Google Photos / device gallery. Open the app → pick a video → tag it like a captured session → it lands in the Library and can be analyzed and annotated like anything else.

**Why it matters:**
- Without this, every session has to be filmed inside the app from scratch. Most coaches and golfers already have hundreds of clips elsewhere.
- This is also the prerequisite for FR-003 (pro-swing comparison) — the upload pipeline is the same, FR-003 just adds a `pro` player type on top.

**Proposed scope (v1):**
1. **Upload icon** on the Capture screen (top-left per UX §4 / PRD F1.4).
2. Tap → system video picker (Android `image_picker` plugin or `file_picker`).
3. Picked file is copied into the app's `swings/{sessionId}.mp4`. Re-use the existing `SaveSession` use case.
4. Same post-capture tag sheet (player / club / tournament).
5. Thumbnail generated on save (already implemented).
6. Available immediately to Analyze (already implemented for Android).

**Out of scope for v1:**
- Trimming the imported video before save (it stays at original length).
- Multi-select / bulk import (one at a time).
- Imports from cloud sources beyond what the system picker exposes.

**Notes:**
- Need to add a Flutter package: `image_picker` (or `file_picker`) for the gallery sheet.
- Android needs the `READ_MEDIA_VIDEO` permission (API 33+) declared in the manifest.

---

## FR-003 — Pro-swing comparison with time-warped playback

**Source:** Wen-Tai (husband / primary persona — name now known).
**Date raised:** 2026-04-21
**Status:** planned (depends on FR-006 for the upload pipeline)
**Priority:** P1

**What he wants:**
1. Upload golf-pro swing videos he finds online into the app.
2. Open side-by-side Compare with one of Ethan's swings on one side and the pro on the other.
3. Both videos play synced to the **same swing tempo** — if the pro swings faster, the pro side slows down so impact lines up with the student. The point is to compare the *path* (wrist angle, hip turn, etc.) without timing throwing off the visual.
4. See body-angle comparisons at matched moments — e.g., wrist angle at the top of backswing.

**Why it matters:**
- Reference golfers are how coaches teach. Watching Ethan vs. a pro at the same phase is the most intuitive teaching tool.
- Time-warping is the unlock — without it the videos drift apart and the path comparison is useless.

**Proposed scope (v1 of this feature):**

The MVP already has the bones — a Compare screen with side-by-side video and an "Align by phase" sync mode. Three pieces missing:

a. **Import-from-gallery on Capture.** Add the Upload icon (PRD F1.4 — never wired). Pick a video → trim → tag like any other session. Add `PlayerType.pro` so pros are filterable and visually distinct (gold-rim chip).
b. **Auto-tempo-match in Compare.** When both sides have analyzed phase markers, compute `(impact - address)` per side; apply `VideoPlayerController.setPlaybackSpeed(ratio)` to the faster side so both reach top / impact / finish at the same wall-clock moment when the user hits play. User can toggle off to play at native speed.
c. **Phase-anchored seek.** Tap "top of backswing" → both videos jump to their respective top frames, paused, for an at-rest body-angle comparison.

**Out of scope for v1 of this FR:**
- A built-in pro library (he supplies his own videos).
- Per-joint angle metrics (wrist, lead arm, knee) — see FR-004.
- Cropping, rotation, or speed editing at upload time — just trim.

**Updates to existing PRD:**
- The "Pro-swing comparison library" non-goal in PRD §4 is now narrowed: a *built-in* library is still out of scope, but user-uploaded references are in. Update §4 wording when this lands.

---

## FR-004 — Per-joint angle metrics (wrist, lead arm, knee, etc.)

**Source:** Wen-Tai (implicit in FR-003 — "the angle of wrist").
**Date raised:** 2026-04-21
**Status:** deferred

**What he'd want:**
- Numeric, side-by-side comparison of body angles between two swings — e.g., "wrist angle at impact: 168° vs 172°".

**Why deferred:**
- Shoulder turn and hip turn already exist; wrist / lead-arm / knee angles are similar to compute but each is a small unit of work.
- Best added once FR-003 ships and Wen-Tai can name the 2–3 angles he actually compares while teaching, instead of us computing every joint speculatively.

**Trigger to revisit:**
- Wen-Tai uses FR-003 for a couple of weeks and tells us which angles he keeps reaching for.

---

## FR-005 — Auto-detect swings + auto-clip continuous video

**Source:** Wen-Tai.
**Date raised:** 2026-04-21
**Status:** planned (queued behind FR-001 and FR-003)
**Priority:** P1

**What he wants:**
- Hit Record once at the start of a practice block. Keep recording while Ethan hits multiple swings in a row. The app automatically detects each swing in the long video and saves each one as its own session in the Library.
- Eliminates the manual start/stop friction between every swing.

**Why it matters:**
- Today's flow forces him to tap Record/Stop for every single ball. In a 10-min block of 10–20 balls that's 20–40 taps and a lot of missed swings.
- This is the difference between filming "every now and then" and filming the whole block, which is the unlock for trend tracking over time.

**Proposed scope (v1):**
1. **Continuous-record mode** on the Capture screen (toggle). When on, recording doesn't auto-stop; user taps Stop once at the end.
2. **Background swing-detection pass** after recording stops:
   - Run pose detection on a coarse downsample of the long video (e.g., 5–10 fps).
   - Use the same wrist-Y trajectory heuristic from `phase_detector.dart` to find swing windows: continuous arcs that include a clear top-of-backswing and impact, with quiet periods on either side.
   - For each detected swing, define a clip from `address - 0.5s` to `finish + 0.5s`.
3. **Auto-split the source video** into N session videos using ffmpeg trim (we have native MediaCodec on Android already; reuse the same path or add a trim method).
4. **Insert N session rows** in the DB, all sharing the same player / club / tournament tag chosen pre-capture. Show a "Detected 7 swings" toast that links to the new sessions.
5. Original long video is deleted after split (with a "keep original" toggle in Settings for v1.1).

**Open questions:**
- How many false positives is acceptable? Coach can delete bad clips from Storage screen.
- Run detection on-device vs. ask the user to wait? On-device is required (offline-first).
- Memory: a 10-min video at 720p is ~150 MB. Decode to 5fps frames keeps it manageable (~3000 frames), but pose detection on 3000 frames at ~80ms each is ~4 minutes of compute. Need a progress UI ("Splitting your block...") and run it on a background isolate so the user can leave the screen.

**Out of scope for v1 of this FR:**
- Auto-tagging each swing with which club it was (would need finer detection).
- Splitting in real time during recording (do it post-recording instead).
- Manual edit of the auto-split boundaries (delete/redo is enough for v1).

---

## How to add a new request

When a user asks for something:

1. Append a new `## FR-NNN — Short title` section here.
2. Fill in: Source · Date raised · Status · What they want · Why it matters · Scope or Why deferred.
3. If it's something we'll ship soon, link the commit(s) in the entry once landed.
4. If it's deferred, note the trigger condition that would reopen it.

Keep entries terse — this is a log, not a spec. Specs go in `docs/01-prd.md`.
