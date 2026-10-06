import 'package:flutter/material.dart';

abstract final class KitoTypography {
  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      height: 1.1,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, height: 1.35),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}
