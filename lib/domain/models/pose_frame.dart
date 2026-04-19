// LLD §2 — PoseFrame. Subset of BlazePose joints used by metrics + overlay.

import 'dart:convert';
import 'dart:math' as math;

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
  rightAnkle;

  static Joint? parse(String raw) {
    for (final j in Joint.values) {
      if (j.name == raw) return j;
    }
    return null;
  }
}

class Vec2 {
  const Vec2(this.x, this.y);
  final double x;
  final double y;

  double distanceTo(Vec2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Map<String, double> toJson() => {'x': x, 'y': y};

  static Vec2 fromJson(Map<String, dynamic> json) =>
      Vec2((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
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

  String jointsToJson() {
    final map = <String, dynamic>{};
    joints.forEach((k, v) {
      map[k.name] = v.toJson();
    });
    return jsonEncode(map);
  }

  static Map<Joint, Vec2> jointsFromJson(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final out = <Joint, Vec2>{};
    decoded.forEach((k, v) {
      final joint = Joint.parse(k);
      if (joint != null && v is Map<String, dynamic>) {
        out[joint] = Vec2.fromJson(v);
      }
    });
    return out;
  }
}
