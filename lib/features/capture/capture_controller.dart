import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CaptureStage { idle, preview, countdown, recording, saving, done, error }

class CaptureState {
  const CaptureState({
    this.stage = CaptureStage.idle,
    this.countdownRemaining = 0,
    this.lensDirection = CameraLensDirection.back,
    this.error,
    this.recordedFile,
    this.longRecord = false,
  });

  final CaptureStage stage;
  final int countdownRemaining;
  final CameraLensDirection lensDirection;
  final String? error;
  final File? recordedFile;
  // When true, the usual max-duration cap is bypassed (FR-005).
  final bool longRecord;

  CaptureState copyWith({
    CaptureStage? stage,
    int? countdownRemaining,
    CameraLensDirection? lensDirection,
    String? error,
    File? recordedFile,
    bool? longRecord,
  }) =>
      CaptureState(
        stage: stage ?? this.stage,
        countdownRemaining: countdownRemaining ?? this.countdownRemaining,
        lensDirection: lensDirection ?? this.lensDirection,
        error: error,
        recordedFile: recordedFile ?? this.recordedFile,
        longRecord: longRecord ?? this.longRecord,
      );
}

class CaptureController extends AutoDisposeNotifier<CaptureState> {
  CameraController? _camera;
  List<CameraDescription> _available = const [];
  Timer? _countdownTimer;

  @override
  CaptureState build() {
    ref.onDispose(_dispose);
    return const CaptureState();
  }

  CameraController? get cameraController => _camera;

  bool get hasMultipleLenses {
    final lenses =
        _available.map((c) => c.lensDirection).toSet();
    return lenses.length > 1;
  }

  Future<void> initCamera() async {
    try {
      _available = await availableCameras();
      if (_available.isEmpty) {
        state = state.copyWith(
          stage: CaptureStage.error,
          error: 'No camera available',
        );
        return;
      }
      await _switchTo(state.lensDirection);
    } catch (e) {
      state = state.copyWith(stage: CaptureStage.error, error: e.toString());
    }
  }

  Future<void> flipCamera() async {
    if (!hasMultipleLenses) return;
    if (state.stage == CaptureStage.recording ||
        state.stage == CaptureStage.countdown) {
      return;
    }
    final next = state.lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _switchTo(next);
  }

  Future<void> _switchTo(CameraLensDirection lens) async {
    final target = _available.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => _available.first,
    );
    final old = _camera;
    _camera = null;
    await old?.dispose();
    final controller = CameraController(
      target,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    _camera = controller;
    state = state.copyWith(
      stage: CaptureStage.preview,
      lensDirection: target.lensDirection,
    );
  }

  Future<void> startCountdown(int seconds) async {
    if (seconds <= 0) {
      await startRecording();
      return;
    }
    state = state.copyWith(
      stage: CaptureStage.countdown,
      countdownRemaining: seconds,
    );
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = state.countdownRemaining - 1;
      if (remaining <= 0) {
        t.cancel();
        startRecording();
      } else {
        state = state.copyWith(countdownRemaining: remaining);
      }
    });
  }

  Future<void> startRecording() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    try {
      await cam.startVideoRecording();
      state = state.copyWith(stage: CaptureStage.recording);
    } catch (e) {
      state = state.copyWith(stage: CaptureStage.error, error: e.toString());
    }
  }

  Future<File?> stopRecording() async {
    final cam = _camera;
    if (cam == null || !cam.value.isRecordingVideo) return null;
    try {
      state = state.copyWith(stage: CaptureStage.saving);
      final xfile = await cam.stopVideoRecording();
      final file = File(xfile.path);
      state = state.copyWith(
        stage: CaptureStage.done,
        recordedFile: file,
      );
      return file;
    } catch (e) {
      state = state.copyWith(stage: CaptureStage.error, error: e.toString());
      return null;
    }
  }

  void reset() {
    _countdownTimer?.cancel();
    state = state.copyWith(stage: CaptureStage.preview);
  }

  /// Toggle long-record mode (FR-005). Disables any max-duration cap.
  void setLongRecord(bool value) {
    if (state.stage == CaptureStage.recording ||
        state.stage == CaptureStage.countdown) {
      return;
    }
    state = state.copyWith(longRecord: value);
  }

  void _dispose() {
    _countdownTimer?.cancel();
    _camera?.dispose();
    _camera = null;
  }
}

final captureControllerProvider =
    AutoDisposeNotifierProvider<CaptureController, CaptureState>(
        CaptureController.new);
