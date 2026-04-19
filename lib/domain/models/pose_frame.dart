// LLD §2 — PoseFrame. 33 BlazePose joints, normalized 0..1.

enum Joint {
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  // TODO: round out the BlazePose 33-joint set.
}

class Vec2 {
  const Vec2(this.x, this.y);
  final double x;
  final double y;
}

class PoseFrame {
  const PoseFrame({
    required this.index,
    required this.timestampMs,
    required this.joints,
    required this.confidence,
  });

  final int index;
  final int timestampMs;
  final Map<Joint, Vec2> joints;
  final double confidence;
}
