import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

import '../../domain/models/pose_frame.dart';
import '../video/frame_extractor.dart';

class PoseDetectorException implements Exception {
  PoseDetectorException(this.message);
  final String message;
  @override
  String toString() => 'PoseDetectorException: $message';
}

/// LLD §4 — ML Kit PoseDetector in accurate mode.
/// Downstream metrics ignore frames below [minConfidence]; overlay keeps them.
class PoseDetectorService {
  PoseDetectorService({this.minConfidence = 0.4});

  final double minConfidence;

  static const _jointMap = <Joint, mlkit.PoseLandmarkType>{
    Joint.nose: mlkit.PoseLandmarkType.nose,
    Joint.leftEye: mlkit.PoseLandmarkType.leftEye,
    Joint.rightEye: mlkit.PoseLandmarkType.rightEye,
    Joint.leftEar: mlkit.PoseLandmarkType.leftEar,
    Joint.rightEar: mlkit.PoseLandmarkType.rightEar,
    Joint.leftShoulder: mlkit.PoseLandmarkType.leftShoulder,
    Joint.rightShoulder: mlkit.PoseLandmarkType.rightShoulder,
    Joint.leftElbow: mlkit.PoseLandmarkType.leftElbow,
    Joint.rightElbow: mlkit.PoseLandmarkType.rightElbow,
    Joint.leftWrist: mlkit.PoseLandmarkType.leftWrist,
    Joint.rightWrist: mlkit.PoseLandmarkType.rightWrist,
    Joint.leftHip: mlkit.PoseLandmarkType.leftHip,
    Joint.rightHip: mlkit.PoseLandmarkType.rightHip,
    Joint.leftKnee: mlkit.PoseLandmarkType.leftKnee,
    Joint.rightKnee: mlkit.PoseLandmarkType.rightKnee,
    Joint.leftAnkle: mlkit.PoseLandmarkType.leftAnkle,
    Joint.rightAnkle: mlkit.PoseLandmarkType.rightAnkle,
  };

  Future<List<PoseFrame>> detect(List<ExtractedFrame> frames) async {
    final detector = mlkit.PoseDetector(
      options: mlkit.PoseDetectorOptions(
        mode: mlkit.PoseDetectionMode.single,
        model: mlkit.PoseDetectionModel.accurate,
      ),
    );
    try {
      final out = <PoseFrame>[];
      for (final f in frames) {
        final input = mlkit.InputImage.fromFilePath(f.filePath);
        final poses = await detector.processImage(input);
        if (poses.isEmpty) continue;
        final pose = poses.first;
        final joints = <Joint, Vec2>{};
        var likelihoodSum = 0.0;
        var likelihoodCount = 0;
        _jointMap.forEach((joint, mlkitType) {
          final lm = pose.landmarks[mlkitType];
          if (lm == null) return;
          joints[joint] = Vec2(lm.x, lm.y);
          likelihoodSum += lm.likelihood;
          likelihoodCount += 1;
        });
        final confidence =
            likelihoodCount == 0 ? 0.0 : likelihoodSum / likelihoodCount;
        out.add(
          PoseFrame(
            index: f.frameIndex,
            timestampMs: f.timestampMs,
            joints: joints,
            confidence: confidence,
          ),
        );
      }
      return out;
    } finally {
      await detector.close();
    }
  }
}
