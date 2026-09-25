import 'package:flutter/material.dart';

/// The Photographic Memory palette: a light, monochrome-first dashboard
/// theme with peach used only as a sparing accent (selected states,
/// progress highlights, key metrics) — never as a large fill.
///
/// Naming note: a handful of names below (`deepPlum`, `darkPlum`, `cream`,
/// `plumCard`, `plumBorder`, `softPeach`, `mutedRose`) are kept from the
/// previous dark theme purely so every screen file that already references
/// them keeps compiling unchanged. They now point at the new light values
/// for the *background/surface* roles they were always used for. The two
/// spots that historically used `deepPlum` as a *text/foreground* color
/// (button labels, the passage-reading color) were the one place that
/// distinction actually mattered, and those have been repointed at
/// `textPrimary` / `darkButtonText` directly rather than through an alias —
/// see app_text_styles.dart and app_widgets.dart.
class AppColors {
  AppColors._();

  // ---- New design-system tokens ----
  static const Color background = Color(0xFFF7F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5E7);
  static const Color primaryDark = Color(0xFF111111);
  static const Color darkButtonText = Color(0xFFFFFFFF);
  static const Color peachAccent = Color(0xFFFFB39F);
  static const Color lightPeach = Color(0xFFFFF0EB);

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9B9B9B);

  // ---- Legacy names, aliased to the light palette (background/surface
  // roles only — see class doc comment above) ----
  static const Color deepPlum = background;
  static const Color darkPlum = surface;
  static const Color plumCard = surface;
  static const Color plumBorder = border;
  static const Color peach = peachAccent;
  static const Color softPeach = lightPeach;
  static const Color cream = lightPeach;
  static const Color mutedRose = Color(0xFF8A8A8E);

  // Semantic colors — kept distinct from peach so status/error meaning
  // never gets confused with the accent color.
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFC98A2C);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF4C6FE0);

  // Error-category colors used consistently across Review, Results, Analytics.
  static const Color missing = Color(0xFFD64545);
  static const Color extra = Color(0xFF7A5CC7);
  static const Color substituted = Color(0xFFD98A3D);
  static const Color order = Color(0xFF3970C9);
  static const Color spelling = Color(0xFFA88418);

  // Difficulty badge colors (spec reference image color-codes these).
  static const Color difficultyEasy = Color(0xFF2E9E5B);
  static const Color difficultyMedium = Color(0xFFD98A3D);
  static const Color difficultyHard = Color(0xFFD64545);
  static const Color difficultyAdvanced = Color(0xFF7A5CC7);

  static const LinearGradient plumBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, background],
  );

  static const LinearGradient peachAction = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [peachAccent, lightPeach],
  );
}
