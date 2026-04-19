# Low-Level Engineering Design — GolfBuddy MVP

**Authors:** Raj (Mobile) + Sofia (CV/ML)  ·  **Status:** Draft v0.1

## 1. Project layout

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── di.dart                 # Riverpod providers root
│   ├── logger.dart
│   ├── result.dart             # Result<T, E> type
│   └── theme/
├── data/
│   ├── db/
│   │   ├── database.dart       # Drift database
│   │   ├── tables/
│   │   │   ├── players.dart
│   │   │   ├── sessions.dart
│   │   │   ├── metrics.dart
│   │   │   └── phase_markers.dart
│   │   └── daos/
│   ├── files/
│   │   └── video_storage.dart  # path resolution, cleanup
│   └── repositories/
│       ├── player_repository.dart
│       ├── session_repository.dart
│       └── metric_repository.dart
├── domain/
│   ├── models/
│   │   ├── swing_analysis.dart
│   │   ├── pose_frame.dart
│   │   ├── phase.dart
│   │   └── metric.dart
│   └── usecases/
│       ├── analyze_swing.dart
│       ├── compare_swings.dart
│       └── adjust_phase.dart
├── services/
│   ├── camera/
│   │   ├── capture_controller.dart
│   │   └── fps_negotiator.dart
│   ├── video/
│   │   ├── trimmer.dart
│   │   ├── frame_extractor.dart
│   │   └── thumbnail_generator.dart
│   └── pose/
│       ├── pose_detector_service.dart
│       ├── phase_detector.dart
│       └── metrics/
│           ├── tempo.dart
│           ├── rotation.dart
│           └── head_stability.dart
└── features/
    ├── capture/
    │   ├── capture_screen.dart
    │   ├── trim_screen.dart
    │   └── tag_sheet.dart
    ├── analysis/
    │   ├── analysis_screen.dart
    │   ├── skeleton_overlay.dart   # CustomPainter
    │   ├── phase_scrubber.dart
    │   └── metric_cards/
    ├── history/
    │   ├── history_screen.dart
    │   ├── compare_screen.dart
    │   └── trend_chart.dart
    └── settings/
        ├── settings_screen.dart
        ├── players_screen.dart
        └── storage_screen.dart

test/
├── unit/
├── widget/
└── golden/
integration_test/
fixtures/
└── swings/                     # labeled corpus (small samples committed; full set in DVC)
```

## 2. Domain models

```dart
enum SwingPhase { address, top, impact, finish }

class PoseFrame {
  final int index;
  final int timestampMs;
  final Map<Joint, Vec2> joints;   // 33 BlazePose joints, normalized 0..1
  final double confidence;          // mean joint confidence
}

class PhaseMarker {
  final SwingPhase phase;
  final int frameIndex;
  final int timestampMs;
  final double confidence;
  final bool manuallyAdjusted;
}

class Metric {
  final String name;             // "tempo_ratio", "shoulder_turn_deg", ...
  final double value;
  final double confidence;
  final String? bandLabel;       // "good" | "fair" | "off"
}

class SwingAnalysis {
  final String sessionId;
  final List<PoseFrame> frames;        // sampled, not every frame
  final List<PhaseMarker> phases;
  final List<Metric> metrics;
  final AnalysisQuality quality;       // ok | partial | failed
}
```

## 3. Capture pipeline (Raj)

### State machine
```
idle → preview → countdown → recording → stopping → trimmed → tagged → saved
                                ↓
                            cancelled → idle
```

### FPS negotiation
- Query `CameraDescription.availableFrameRateRanges` (custom platform call)
- Try ladder: 240 → 120 → 60 → 30
- Persist last successful FPS per device in shared prefs to skip negotiation next launch
- Show actual FPS chip in UI

### Recording
- Hardware-encoded H.264, baseline profile, 720p (1280×720) — tradeoff between resolution and storage/processing speed
- Max duration enforced (configurable; default 8s) to prevent runaway
- Output: temp file `.tmp.mp4` until tagged-and-saved, then renamed to `{sessionId}.mp4`

## 4. Pose pipeline (Sofia)

### Frame extraction
- Use ffmpeg to extract frames at target rate (cap at 60fps even if recorded at 240fps to keep pose latency in budget)
- For a 2s swing at 60fps: 120 frames → ~3s of inference on Pixel 6a (measured baseline)
- Stream-process: don't hold all frames in memory; produce `PoseFrame` lazily

### Pose detection
- ML Kit `PoseDetector` in `accurate` mode, single-image streaming
- Reject frames with mean joint confidence < 0.4 from downstream metrics, but keep them in the playback buffer for visualization

### Phase detection algorithm (heuristic v0)

Operates on the wrist-midpoint trajectory across time. The dominant hand wrist for a right-handed golfer (or auto-detected from the first 5 frames where pose appears stable).

```
1. Smooth wrist Y trajectory with a 5-frame moving average
2. address = first frame where wrist Y stable (variance < ε) for 10+ consecutive frames
3. top    = frame with maximum wrist Y after address
4. impact = frame between top and finish where wrist Y velocity is maximum AND wrist X crosses the address X position
5. finish = first frame after impact where wrist Y stable again, or last frame if not found
```

Confidence per phase = function of trajectory smoothness around the detected frame. If any phase confidence < 0.6, the analysis is marked `partial` and the UI prompts for manual adjustment.

**Iteration plan:**
- v0: heuristic above
- v0.5: compare against Priya's labeled corpus, tune ε and velocity thresholds
- v1.1: if heuristic accuracy < 90% on corpus, train a small temporal classifier (1D-CNN over the 33-joint coordinates, ~50KB model)

### Metric calculators

All operate on `(frames, phases)` tuples and return `Metric` objects.

**Tempo ratio** — `(top.timestampMs - address.timestampMs) / (impact.timestampMs - top.timestampMs)`. Band: 2.8–3.2 = good, 2.5–3.5 = fair, else = off.

**Shoulder turn** — vector from `leftShoulder` to `rightShoulder` at address vs at top; angle in the camera plane (degrees). Band: ≥ 80° = good for amateur baseline.

**Hip turn** — same idea with `leftHip` to `rightHip`. Band: ≥ 40° = good.

**Head stability** — track `nose` position from address through impact. Compute max Euclidean displacement in normalized coords; convert to estimated cm using shoulder-width as a 40cm reference scale. Band: < 5cm = good, 5–10cm = fair, > 10cm = off.

All metrics include a `confidence` derived from the input frames' joint confidence at the relevant phase frames. UI hides metrics with confidence < 0.5 and shows "Couldn't measure reliably" instead.

## 5. Storage schema (Drift)

```dart
class Players extends Table {
  TextColumn  get id          => text()();
  TextColumn  get name        => text()();
  TextColumn  get avatarPath  => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn  get id         => text()();
  TextColumn  get playerId   => text().references(Players, #id)();
  TextColumn  get club       => text().nullable()();
  TextColumn  get videoPath  => text()();
  TextColumn  get thumbPath  => text()();
  DateTimeColumn get capturedAt => dateTime()();
  IntColumn   get durationMs => integer()();
  IntColumn   get fps        => integer()();
  TextColumn  get quality    => text()();   // ok | partial | failed
  @override Set<Column> get primaryKey => {id};
}

class PhaseMarkers extends Table {
  TextColumn  get sessionId  => text().references(Sessions, #id)();
  TextColumn  get phase      => text()();   // address | top | impact | finish
  IntColumn   get frameIndex => integer()();
  IntColumn   get timestampMs => integer()();
  RealColumn  get confidence => real()();
  BoolColumn  get manuallyAdjusted => boolean().withDefault(const Constant(false))();
  @override Set<Column> get primaryKey => {sessionId, phase};
}

class Metrics extends Table {
  TextColumn  get sessionId  => text().references(Sessions, #id)();
  TextColumn  get name       => text()();
  RealColumn  get value      => real()();
  RealColumn  get confidence => real()();
  TextColumn  get bandLabel  => text().nullable()();
  @override Set<Column> get primaryKey => {sessionId, name};
}
```

Indexes: `Sessions(playerId, capturedAt DESC)`, `Metrics(sessionId, name)`.

## 6. State management

- Each feature has a Riverpod `Notifier` that exposes immutable view models
- Long operations (analysis) are `AsyncNotifier` with explicit `loading / data / error` states the UI renders directly
- Repositories return `Stream` from Drift queries — UI rebuilds reactively on DB writes (covers e.g. saving a session showing up in History instantly)

## 7. Skeleton overlay rendering

- `CustomPainter` reads the current playback timestamp from `VideoPlayerController`
- Looks up the nearest `PoseFrame` (frames stored with timestamps; binary search)
- Paints lines between joint pairs and dots at joints, transformed to widget coordinates accounting for video aspect ratio
- Toggle off = `RepaintBoundary` short-circuits to nothing (no perf cost)

## 8. Comparison screen

- Two `VideoPlayerController` instances driven by a single `ScrubberController`
- Time normalization: align by phase, not raw timestamp. Each video maps its own [address..finish] timeline to a normalized [0..1], scrubber moves both at once.
- Metric diff table from `MetricDiff = (metricA, metricB, delta, deltaSign)` rendered with arrows

## 9. Migration & versioning

- Drift schema versioned; every schema change ships with `MigrationStrategy.onUpgrade`
- DB backup-to-file before each migration; restored on failure
- Video files referenced by relative path so app sandbox moves don't break references

## 10. Testing layers (handed to Priya for the master plan)

- **Unit:** metric calculators, phase detector (against fixture frames), use cases
- **Widget:** screen rendering snapshots, gesture handling
- **Golden:** skeleton overlay on a known frame
- **Integration:** end-to-end on emulator: import fixture video → see analysis
- **Device matrix:** see test plan

## 11. Performance instrumentation

- Trace events around: capture-stop, frame-extract, pose-detect-per-frame, phase-detect, metric-compute, render-first-frame
- Surfaced in a debug-only "Diagnostics" screen behind a Settings tap-7-times easter egg
- Aggregated p50/p95 logged to local SQLite for beta debugging

## 12. Open eng questions

- ML Kit on iOS vs MediaPipe Tasks (newer): if MLKit accuracy is insufficient, switch iOS to MediaPipe Tasks via platform channel. Decision after week 2 spike.
- ffmpeg vs native MediaCodec/AVFoundation for trim: spike both, pick smaller binary
- Should we cache pose results to disk, or recompute on each open? Cache. Storage cost ~50KB per swing.
