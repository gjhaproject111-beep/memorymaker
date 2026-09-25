import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/repositories/progress_repository.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/trend_chart.dart';

/// Answers "is my memory actually improving?" (spec §24) with error-type
/// trends, reading speed, and performance broken down by passage difficulty
/// — deliberately not duplicating Progress's accuracy-over-time view.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsData {
  final ErrorRateBreakdown errors;
  final double? avgWpm;
  final Map<PassageDifficulty, double?> byDifficulty;
  const _AnalyticsData({required this.errors, required this.avgWpm, required this.byDifficulty});
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<_AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    AppDataBus.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppDataBus.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _future = _load());
  }

  Future<_AnalyticsData> _load() async {
    final errors = await Services.progress.errorRateBreakdown();
    final wpm = await Services.progress.averageReadingWpm();
    final byDifficulty = await Services.progress.accuracyByDifficulty();
    return _AnalyticsData(errors: errors, avgWpm: wpm, byDifficulty: byDifficulty);
  }

  Color _difficultyColor(PassageDifficulty d) {
    switch (d) {
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

  /// The weakest difficulty with enough data to say something about — used
  /// only for the tip card's wording, never for the bars/percentages
  /// themselves, which always come straight from [Services.progress].
  PassageDifficulty? _weakestDifficulty(Map<PassageDifficulty, double?> byDifficulty) {
    PassageDifficulty? weakest;
    double? weakestValue;
    for (final entry in byDifficulty.entries) {
      if (entry.value == null) continue;
      if (weakestValue == null || entry.value! < weakestValue) {
        weakest = entry.key;
        weakestValue = entry.value;
      }
    }
    return weakest;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<_AnalyticsData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            final data = snapshot.data!;
            final errorItems = [
              (label: 'Omission', value: data.errors.omissionRate, color: AppColors.missing),
              (label: 'Substitution', value: data.errors.substitutionRate, color: AppColors.substituted),
              (label: 'Wrong order', value: data.errors.orderErrorRate, color: AppColors.order),
              (label: 'Extra words', value: data.errors.extraWordRate, color: AppColors.extra),
              (label: 'Spelling', value: data.errors.spellingErrorRate, color: AppColors.spelling),
            ];
            final hasAnyErrors = errorItems.fold<double>(0, (sum, i) => sum + i.value) > 0;
            final topError = hasAnyErrors
                ? errorItems.reduce((a, b) => a.value >= b.value ? a : b)
                : null;
            final weakest = _weakestDifficulty(data.byDifficulty);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('Your performance in detail.', style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Common Mistakes', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('Share of original words affected, across every attempt.', style: AppTextStyles.caption),
                        const SizedBox(height: 18),
                        if (!hasAnyErrors)
                          const EmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'No errors recorded yet',
                            message: 'Complete a few recall attempts to see your error breakdown.',
                          )
                        else
                          DonutBreakdown(
                            items: errorItems,
                            centerValue: '${(topError!.value * 100).toStringAsFixed(1)}%',
                            centerLabel: topError.label,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration:
                              BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.speed, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reading Speed', style: AppTextStyles.caption),
                              Text(
                                data.avgWpm == null ? '—' : '${data.avgWpm!.round()} words / minute',
                                style: AppTextStyles.h3,
                              ),
                              if (data.avgWpm != null)
                                Text('Average across all attempts', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Performance by Difficulty', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('One-read accuracy, grouped by passage difficulty.', style: AppTextStyles.caption),
                        const SizedBox(height: 18),
                        BarBreakdown(items: [
                          for (final d in PassageDifficulty.values)
                            (label: d.label, value: data.byDifficulty[d] ?? 0, color: _difficultyColor(d)),
                        ]),
                      ],
                    ),
                  ),
                  if (weakest != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: AppColors.lightPeach, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.lightbulb_outline, color: AppColors.peachAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Focus more on ${weakest.label} passages — that level needs the most improvement right now.',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
