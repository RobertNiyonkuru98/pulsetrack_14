import 'package:flutter/material.dart';

/// Every colour in PulseTrack comes from here.
/// This is why the Flutter build matches the Figma design: if a colour changes
/// in Figma, it changes in exactly one file.
///
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF8A7BE8); // periwinkle
  static const Color primarySoft = Color(0xFFEEEBFB); // light lavender wash
  static const Color accent = Color(0xFF111111); // black: primary buttons
  static const Color pink = Color(0xFFF28AF5);
  static const Color sky = Color(0xFF7FCBFF);
  static const Color black = Color(0xFF111111);
  static const Color background = Color(0xFFF8F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color neutral = Color(0xFFEDEDED); // inputs, inactive cards
  static const Color border = Color(0xFFEDEDED);

  // Text
  static const Color ink = Color(0xFF111111);
  static const Color muted = Color(0xFF8A8A99);

  // SLA status, three values each:
  //   solid = charts, dots, progress bars
  //   Soft  = the pastel card / badge fill from the Figma frames
  //   Text  = readable text on top of the pastel fill
  static const Color onTrack = Color(0xFF35B97A);
  static const Color onTrackSoft = Color(0xFF86E3B0);
  static const Color onTrackText = Color(0xFF0B5D34);

  static const Color atRisk = Color(0xFFF2B01E);
  static const Color atRiskSoft = Color(0xFFFFD66B);
  static const Color atRiskText = Color(0xFF6B4A00);

  static const Color overdue = Color(0xFFE5484D);
  static const Color overdueSoft = Color(0xFFFF8A80);
  static const Color overdueText = Color(0xFF7A1410);

  static const Color completed = Color(0xFF9A9AAB);
  static const Color completedSoft = Color(0xFFEDEDED);
  static const Color completedText = Color(0xFF555555);


  static const List<Color> avatarPalette = <Color>[
    Color(0xFFF5C4B3),
    Color(0xFFB5D4F4),
    Color(0xFFC0DD97),
    Color(0xFFF4C0D1),
    Color(0xFFCECBF6),
  ];
}