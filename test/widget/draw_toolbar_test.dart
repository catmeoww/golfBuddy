import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/domain/models/markup.dart';
import 'package:golfbuddy/features/session_detail/session_detail_screen.dart';

void main() {
  testWidgets('DrawToolbar renders the 5 FR-007 color swatches and calls onPickColor',
      (tester) async {
    const presets = <Color>[
      Color(0xFFFFC107),
      Color(0xFF2BB673),
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFFFFFFFF),
    ];
    Color picked = presets.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DrawToolbar(
              activeTool: MarkupKind.circle,
              onPickTool: (_) {},
              activeColor: picked,
              colorPresets: presets,
              onPickColor: (c) => setState(() => picked = c),
              onDone: () {},
            ),
          ),
        ),
      ),
    );

    // 5 circle-shaped swatch Containers rendered.
    final circles = tester.widgetList<Container>(find.byType(Container)).where(
      (c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      },
    );
    expect(circles.length, 5);

    // Tap the green swatch (index 1) and verify the callback fired.
    await tester.tap(find.byType(InkWell).at(1));
    await tester.pump();
    expect(picked, presets[1]);
  });
}
