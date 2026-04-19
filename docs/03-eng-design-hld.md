# High-Level Engineering Design — GolfBuddy MVP

**Author:** Maya (Tech Lead)  ·  **Status:** Draft v0.1

## 1. Goals & constraints

- Single codebase for Android (primary) + iOS (secondary)
- Fully on-device — no backend in MVP
- Mid-tier Android target: Pixel 6a / Galaxy A54 baseline
- Pose analysis must complete within 5s for a typical 2s swing video
- Footprint: APK < 80MB, RAM peak < 600MB during analysis

## 2. Architecture decision: Flutter + on-device ML

### Why Flutter
- One codebase covers both platforms; user dogfoods on Android
- `camera` plugin supports high-frame-rate capture on both platforms
- `google_mlkit_pose_detection` exposes the same MediaPipe model on iOS and Android
- `video_player` + custom shaders give us frame-accurate playback control
- Hot reload speeds iteration during a 6-week MVP

### Why not React Native
- Camera and video plugin ecosystem is more fragmented
- Skia rendering in Flutter gives us better overlay performance for the skeleton

### Why not native (Kotlin + Swift)
- Two codebases double our 6-week timeline
- Pose model is identical via MediaPipe regardless of host

### Why on-device, not cloud
- Outdoor ranges have poor signal — analysis must work offline
- No upload latency (great UX)
- No server costs, no compliance burden, no PII leaves the phone
- Pose models are small enough to bundle (≈10MB)

## 3. System diagram

```
┌──────────────────────────────────────────────────────┐
│                  Flutter App                         │
│                                                      │
│  ┌────────────┐   ┌────────────┐   ┌─────────────┐   │
│  │  Capture   │   │  Analysis  │   │   History   │   │
│  │   feature  │   │   feature  │   │   feature   │   │
│  └─────┬──────┘   └─────┬──────┘   └─────┬───────┘   │
│        │                │                │           │
│  ┌─────┴────────────────┴────────────────┴───────┐   │
│  │            Domain layer (use cases)           │   │
│  └─────┬────────────────┬────────────────┬───────┘   │
│        │                │                │           │
│  ┌─────┴──────┐  ┌──────┴──────┐  ┌─────┴───────┐    │
│  │   Video    │  │    Pose     │  │   Storage   │    │
│  │   service  │  │   pipeline  │  │  (Drift DB) │    │
│  └─────┬──────┘  └──────┬──────┘  └─────────────┘    │
│        │                │                            │
│  ┌─────┴────────────────┴────────────────────────┐   │
│  │  Platform channels                            │   │
│  │  - camera plugin (Camera2 / AVFoundation)     │   │
│  │  - ML Kit Pose Detection                      │   │
│  │  - file system (path_provider)                │   │
│  └───────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
              │                              │
              ▼                              ▼
       Device file system          Local SQLite (Drift)
       (videos, thumbnails)        (sessions, players, metrics)
```

## 4. Tech stack

| Layer | Choice | Reason |
|---|---|---|
| Framework | Flutter 3.x (Dart) | Cross-platform, mature, great for media UI |
| State mgmt | Riverpod | Compile-safe, testable, modern |
| Local DB | Drift (SQLite) | Type-safe, reactive queries, migrations |
| Camera | `camera` plugin + `flutter_high_speed_camera` (custom platform code if needed) | High FPS support |
| Pose detection | `google_mlkit_pose_detection` | MediaPipe BlazePose under the hood, both platforms |
| Video processing | `ffmpeg_kit_flutter` (min profile) | Trim, transcode, frame extraction |
| Charts | `fl_chart` | Lightweight, customizable for trend chart |
| Crash reporting | `sentry_flutter` | Free tier, both platforms |
| Local analytics | Custom event log to SQLite + opt-in upload later | No 3rd-party SDK in MVP |

## 5. Major components

### 5.1 Capture service (Raj)
Owns camera lifecycle, framerate negotiation, recording → file. Returns a `RawVideoFile` handle.

### 5.2 Video service (Raj)
- Trimming (ffmpeg)
- Thumbnail extraction
- Frame extraction at target FPS (input to pose pipeline)

### 5.3 Pose pipeline (Sofia)
- Frame iterator → ML Kit Pose Detection → `PoseFrame` stream
- Phase detector: heuristic algorithm operating on the frame stream
- Metric calculators: pure functions on annotated frames + phase markers
- Output: `SwingAnalysis` aggregate (frames, phases, metrics, confidence)

### 5.4 Storage layer (Raj)
- Drift schema for `players`, `sessions`, `metrics`, `phase_markers`
- Filesystem layer for video files (`{appDocs}/swings/{sessionId}.mp4`) and thumbnails
- Single source of truth: DB row references file path

### 5.5 Feature modules (Raj + Lin pairing)
- `capture/` — UI + capture state machine
- `analysis/` — playback, skeleton overlay shader, metric cards
- `history/` — list + filter + compare picker
- `settings/` — players, storage, preferences

### 5.6 Domain layer
Use-case classes (`AnalyzeSwing`, `CompareSwings`, `DeleteSession`) sit between UI and services. Keeps UI free of business logic, makes testing easier.

## 6. Data model (logical)

```
Player        sessions →  Session   metrics →  Metric
─────                     ──────                ──────
id PK                     id PK                 session_id FK
name                      player_id FK          name
avatar_path               club                  value
created_at                video_path            confidence
                          thumb_path            
                          captured_at           
                          duration_ms           
                          fps                   
                                                
                          phase_markers →  PhaseMarker
                                           ─────────────
                                           session_id FK
                                           phase (enum)
                                           frame_index
                                           timestamp_ms
                                           confidence
                                           manually_adjusted (bool)
```

## 7. Key non-functional concerns

### Performance budgets
- Cold launch to camera ready: < 2s
- Capture-stop to analysis screen: < 5s for 2s @ 60fps clip
- Skeleton overlay render: 60fps playback minimum
- Storage per swing: < 15MB (compress to H.264 720p where possible)

### Privacy
- Camera permission with clear rationale
- All data on-device; no analytics SDK that ships PII
- Settings → "Delete all my data" wipes DB + files

### Offline
- All MVP features must work airplane-mode
- No external font/image fetches at runtime

### Battery
- Stop camera preview when not in capture tab
- Pose pipeline runs once per swing, not continuously

### Crash & error handling
- Sentry for crashes (anonymized, opt-in)
- Pose pipeline failures fall back to "save raw video, retry analysis later" — never lose user footage

## 8. Build, CI, release

- **CI:** GitHub Actions — `flutter analyze`, `flutter test`, build APK + iOS archive on PR
- **Branching:** trunk-based with short-lived feature branches; release tags `v0.1.0-beta.N`
- **Distribution:** Play Internal Testing + TestFlight for closed beta; Play Open Beta for public

## 9. Tradeoffs & deferred decisions

- **Heuristic vs ML phase detector** — start heuristic; revisit with classifier in v1.1 once we have labeled corpus from real users
- **Drift vs Isar vs Hive** — chose Drift for SQL flexibility for trend queries
- **No remote config in MVP** — accept slower iteration in exchange for zero infra
- **No A/B test framework in MVP** — usage too small to be statistically meaningful

## 10. Risks the eng team owns

| Risk | Owner | Mitigation |
|---|---|---|
| High-FPS camera capture inconsistent across Android OEMs | Raj | Detect supported FPS at runtime; fallback ladder 240→120→60→30 with UI notice |
| ML Kit pose model accuracy drops at side-on angles | Sofia | Tune confidence threshold; reject low-confidence frames; ask Lin to design retake nudge |
| ffmpeg binary size pushes APK over 80MB | Raj | Use min profile build; consider native trim via MediaCodec/AVFoundation as alternative |
| Drift migrations break user data on upgrade | Raj | Migration tests in CI; back up DB before migration |
