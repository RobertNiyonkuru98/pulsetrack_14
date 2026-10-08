import 'package:flutter/material.dart';

/// Every colour in PulseTrack comes from here.
/// This is why the Flutter build matches the Figma design: if a colour changes
/// in Figma, it changes in exactly one file.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF1D3B8B); // deep navy
  static const Color accent = Color(0xFFF97316); // orange
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  // Text
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);

  // SLA status: solid = text + dot, soft = badge background
  static const Color onTrack = Color(0xFF12A150);
  static const Color onTrackSoft = Color(0xFFE6F6EC);
  static const Color atRisk = Color(0xFFE8A317);
  static const Color atRiskSoft = Color(0xFFFDF3E0);
  static const Color overdue = Color(0xFFD92D20);
  static const Color overdueSoft = Color(0xFFFDECEA);
  static const Color completed = Color(0xFF64748B);
  static const Color completedSoft = Color(0xFFEEF1F5);
}
