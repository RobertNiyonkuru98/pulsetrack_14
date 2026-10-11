import 'package:flutter/material.dart';

/// Every colour in PulseTrack comes from here.
///
/// The values are sampled straight out of the group's Figma file, so the
/// Flutter build and the design cannot drift apart: when a colour changes in
/// Figma it changes in exactly one file and every screen follows.
class AppColors {
  const AppColors._();

  // ------------------------------------------------------------------ brand
  /// Violet. The big dashboard tiles and the "next task" card.
  static const Color primary = Color(0xFF7566D0);

  /// Deeper indigo. The logo mark and the active pill in the navigation bar.
  static const Color primaryDark = Color(0xFF5B4BB5);

  /// Lavender wash. Behind the logo, the "+" button and other soft accents.
  static const Color primarySoft = Color(0xFFE5DEFF);

  /// Warm orange accent, kept for the floating action button.
  static const Color accent = Color(0xFFF97316);

  // --------------------------------------------------------------- surfaces
  /// The warm off-white page background from Figma - deliberately not a cold
  /// grey, which is what makes the white cards read as raised.
  static const Color background = Color(0xFFFCF9F8);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEDEBED);

  /// Near-black of the floating bottom navigation bar.
  static const Color navBackground = Color(0xFF121212);

  /// Grey used for the inactive items in that bar.
  static const Color navInactive = Color(0xFF8E8B99);

  // ------------------------------------------------------------------- text
  static const Color ink = Color(0xFF1C1B1B);
  static const Color muted = Color(0xFF8A8794);

  /// Text that sits on a dark or coloured fill.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // -------------------------------------------------------------- SLA status
  // Three tones per status, because the design uses each one for a different job:
  //   solid - readable on white: badge text, chart bars, leaderboards
  //   fill  - the bright block Figma puts behind the big dashboard tiles
  //   ink   - the dark tone that sits on that block and stays legible
  static const Color onTrack = Color(0xFF12A150);
  static const Color onTrackSoft = Color(0xFFECF6EF);
  static const Color onTrackFill = Color(0xFF86E3B0);
  static const Color onTrackInk = Color(0xFF1B6B42);

  static const Color atRisk = Color(0xFFE8A317);
  static const Color atRiskSoft = Color(0xFFFCF5E6);
  static const Color atRiskFill = Color(0xFFFFD66C);
  static const Color atRiskInk = Color(0xFF8A6410);

  static const Color overdue = Color(0xFFD92D20);
  static const Color overdueSoft = Color(0xFFFCEBE8);
  static const Color overdueFill = Color(0xFFFF8A80);
  static const Color overdueInk = Color(0xFF9A2B22);

  static const Color completed = Color(0xFF8A8794);
  static const Color completedSoft = Color(0xFFF1F0F5);
  static const Color completedFill = Color(0xFFC9C6D4);
  static const Color completedInk = Color(0xFF5A5764);

  // ----------------------------------------------------------------- alerts
  /// The red dot on the notification bell.
  static const Color danger = Color(0xFFBA1C1C);

  // ------------------------------------------- names Admire's screens use
  // His profile / activity / sign-in / team screens reference these. The four
  // *Text tones are deliberately the SAME values as the *Ink tones above - one
  // tone per status, just the name his files call it by.
  static const Color onTrackText = onTrackInk;
  static const Color atRiskText = atRiskInk;
  static const Color overdueText = overdueInk;
  static const Color completedText = completedInk;

  /// Near-black, used behind the primary buttons on his screens.
  static const Color black = Color(0xFF111111);

  /// Neutral grey for inputs and inactive cards.
  static const Color neutral = Color(0xFFEDEDED);

  /// Sky blue, used for the soft accents on his profile stat tiles.
  static const Color sky = Color(0xFF7FCBFF);

  /// Avatar tints, cycled by member so a column of people reads as distinct.
  static const List<Color> avatarPalette = <Color>[
    Color(0xFFF5C4B3),
    Color(0xFFB5D4F4),
    Color(0xFFC0DD97),
    Color(0xFFF4C0D1),
    Color(0xFFCECBF6),
  ];
}
