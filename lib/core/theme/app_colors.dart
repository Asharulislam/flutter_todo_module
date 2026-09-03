import 'package:flutter/material.dart';

/// Brand palette. Widgets should pull colours from `Theme.of(context)` where
/// possible; this is the single source those themes are built from.
class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF3B82F6);

  static const Color important = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
}
