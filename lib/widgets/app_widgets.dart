import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../core/models/enums.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Shared building blocks used across every screen, so the app has one
/// consistent visual language instead of each screen inventing its own.

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: child,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: padding, child: child));
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h2, overflow: TextOverflow.ellipsis)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.darkButtonText),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(label, style: AppTextStyles.buttonLabel, overflow: TextOverflow.ellipsis)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 18, color: AppColors.darkButtonText),
              ],
            ],
          );
    final button = ElevatedButton(onPressed: loading ? null : onPressed, child: child);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.expand = true});

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A circular accuracy indicator — the app's signature visual, used on
/// Home, Results, and Mastery screens. Peach is the right accent here: a
/// key metric highlight is exactly what the design system reserves it for.
class AccuracyRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final double strokeFraction;
  final Widget? center;
  final Color color;

  const AccuracyRing({
    super.key,
    required this.value,
    this.size = 140,
    this.strokeFraction = 0.09,
    this.center,
    this.color = AppColors.peachAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value: value.clamp(0, 1), color: color, strokeFraction: strokeFraction),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeFraction;
  _RingPainter({required this.value, required this.color, required this.strokeFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * strokeFraction;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    if (value > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

/// A small "+6%" / "-0.6" pill, colored by whether the change is favorable.
class TrendChip extends StatelessWidget {
  final double delta;
  final bool goodWhenPositive;
  final bool isPercentagePoints;

  const TrendChip({
    super.key,
    required this.delta,
    this.goodWhenPositive = true,
    this.isPercentagePoints = true,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = goodWhenPositive ? delta >= 0 : delta <= 0;
    final color = isGood ? AppColors.success : AppColors.danger;
    final sign = delta >= 0 ? '+' : '';
    final text = isPercentagePoints ? '$sign${(delta * 100).round()}%' : '$sign${delta.toStringAsFixed(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final double? delta;
  final bool deltaIsGoodWhenPositive;
  final bool deltaIsPercentagePoints;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaIsGoodWhenPositive = true,
    this.deltaIsPercentagePoints = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(value, style: AppTextStyles.statNumber),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: TrendChip(
                    delta: delta!,
                    goodWhenPositive: deltaIsGoodWhenPositive,
                    isPercentagePoints: deltaIsPercentagePoints,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A difficulty badge, color-coded the way the reference design shows:
/// green for Easy, peach/orange for Medium, red for Hard, purple for
/// Advanced — a small extra touch of legibility over a single flat color.
class DifficultyPill extends StatelessWidget {
  final PassageDifficulty difficulty;
  const DifficultyPill({super.key, required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case PassageDifficulty.easy:
        return AppColors.difficultyEasy;
      case PassageDifficulty.medium:
        return AppColors.difficultyMedium;
      case PassageDifficulty.hard:
        return AppColors.difficultyHard;
      case PassageDifficulty.advanced:
        return AppColors.difficultyAdvanced;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(difficulty.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
}
