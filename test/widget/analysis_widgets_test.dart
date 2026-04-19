import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/domain/models/metric.dart';
import 'package:golfbuddy/domain/models/pose_frame.dart';
import 'package:golfbuddy/features/analysis/metric_cards/head_stability_card.dart';
import 'package:golfbuddy/features/analysis/metric_cards/hip_turn_card.dart';
import 'package:golfbuddy/features/analysis/metric_cards/shoulder_turn_card.dart';
import 'package:golfbuddy/features/analysis/metric_cards/tempo_card.dart';
import 'package:golfbuddy/features/analysis/skeleton_overlay.dart';

void main() {
  testWidgets('SkeletonOverlay paints when pose frames exist',
      (tester) async {
    final frames = [
      PoseFrame(
        index: 0,
        timestampMs: 0,
        confidence: 0.9,
        joints: {
          Joint.leftShoulder: const Vec2(0.3, 0.3),
          Joint.rightShoulder: const Vec2(0.7, 0.3),
          Joint.leftHip: const Vec2(0.4, 0.7),
          Joint.rightHip: const Vec2(0.6, 0.7),
        },
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter:
                  SkeletonOverlay(frames: frames, positionMs: 0),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Metric cards render values + band labels', (tester) async {
    final metrics = [
      const Metric(
          name: 'tempo_ratio',
          value: 3.0,
          confidence: 0.9,
          bandLabel: 'good'),
      const Metric(
          name: 'shoulder_turn_deg',
          value: 85,
          confidence: 0.9,
          bandLabel: 'good'),
      const Metric(
          name: 'hip_turn_deg',
          value: 42,
          confidence: 0.9,
          bandLabel: 'good'),
      const Metric(
          name: 'head_stability_cm',
          value: 3.5,
          confidence: 0.9,
          bandLabel: 'good'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TempoCard(metric: metrics[0]),
            ShoulderTurnCard(metric: metrics[1]),
            HipTurnCard(metric: metrics[2]),
            HeadStabilityCard(metric: metrics[3]),
          ],
        ),
      ),
    ));
    expect(find.text('Tempo ratio'), findsOneWidget);
    expect(find.text('3.00'), findsOneWidget);
    expect(find.text('Shoulder turn'), findsOneWidget);
    expect(find.text('85°'), findsOneWidget);
    expect(find.text('Hip turn'), findsOneWidget);
    expect(find.text('42°'), findsOneWidget);
    expect(find.text('Head stability'), findsOneWidget);
    expect(find.text('3.5 cm'), findsOneWidget);
    expect(find.text('good'), findsNWidgets(4));
  });
}
