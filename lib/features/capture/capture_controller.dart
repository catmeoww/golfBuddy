import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CaptureStage { idle, preview, countdown, recording, saving, done, error }

class CaptureState {
  const CaptureState({
    this.stage = CaptureStage.idle,
    this.countdownRemaining = 0,
    this.error,
    this.recordedFile,
  });

  final CaptureStage stage;
  final int countdownRemaining;
  final String? error;
  final File? recordedFile;

  CaptureState copyWith({
    CaptureStage? stage,
    int? countdownRemaining,
    String? error,
    File? recordedFile,
  }) =>
      CaptureState(
        stage: stage ?? this.stage,
        countdownRemaining: countdownRemaining ?? this.countdownRemaining,
        error: error,
        recordedFile: recordedFile ?? this.recordedFile,
      );
}

class CaptureController extends AutoDisposeNotifier<CaptureState> {
  CameraController? _camera;
  Timer? _countdownTimer;

  @override
  CaptureState build() {
    ref.onDispose(_dispose);
    return const CaptureState();
  }

  CameraController? get cameraController => _camera;

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          stage: CaptureStage.error,
          error: 'No camera available',
        );
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      _camera = controller;
      state = state.copyWith(stage: CaptureStage.preview);
    } catch (e) {
      state = state.copyWith(stage: CaptureStage.error, error: e.toString());
    }
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
    state = const CaptureState(stage: CaptureStage.preview);
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
