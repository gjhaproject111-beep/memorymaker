import 'package:flutter/material.dart';

/// The Photographic Memory palette: deep plum + warm peach.
/// Kept as a single source of truth so every screen stays consistent.
class AppColors {
  AppColors._();

  static const Color deepPlum = Color(0xFF1D1026);
  static const Color darkPlum = Color(0xFF281633);
  static const Color plumCard = Color(0xFF2F1B3D); // slightly lifted card tone
  static const Color plumBorder = Color(0x33F6B39D); // peach at low opacity

  static const Color peach = Color(0xFFF6B39D);
  static const Color softPeach = Color(0xFFFFD1C2);
  static const Color cream = Color(0xFFFFF5EF);
  static const Color mutedRose = Color(0xFFB987A7);

  // Semantic colors, chosen to stay in-family rather than clashing primaries.
  static const Color success = Color(0xFF8FD6A8);
  static const Color warning = Color(0xFFF6B39D);
  static const Color danger = Color(0xFFE58C8C);
  static const Color info = Color(0xFFB9A6E0);

  // Error-category colors used consistently across Review, Results, Analytics.
  static const Color missing = Color(0xFFE58C8C);
  static const Color extra = Color(0xFFB9A6E0);
  static const Color substituted = Color(0xFFF6B39D);
  static const Color order = Color(0xFF8FB8D6);
  static const Color spelling = Color(0xFFD6C98F);

  static const Color textPrimary = cream;
  static const Color textSecondary = Color(0xB3FFF5EF); // cream @ 70%
  static const Color textMuted = Color(0x80FFF5EF); // cream @ 50%

  static const LinearGradient plumBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepPlum, darkPlum],
  );

  static const LinearGradient peachAction = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [peach, softPeach],
  );
}
