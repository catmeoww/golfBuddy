import 'package:flutter/material.dart';

// TODO: populate from UX design tokens (docs/02-ux-design.md).
class AppTheme {
  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      );
}
