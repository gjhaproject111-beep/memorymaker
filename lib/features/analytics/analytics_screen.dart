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

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<_AnalyticsData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            final data = snapshot.data!;
            final hasAnyErrors = data.errors.omissionRate + data.errors.substitutionRate + data.errors.orderErrorRate +
                    data.errors.extraWordRate + data.errors.spellingErrorRate >
                0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: AppTextStyles.h1),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Error Type Trends', style: AppTextStyles.h3),
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
                          BarBreakdown(items: [
                            (label: 'Omission', value: data.errors.omissionRate, color: AppColors.missing),
                            (label: 'Substitution', value: data.errors.substitutionRate, color: AppColors.substituted),
                            (label: 'Wrong order', value: data.errors.orderErrorRate, color: AppColors.order),
                            (label: 'Extra words', value: data.errors.extraWordRate, color: AppColors.extra),
                            (label: 'Spelling', value: data.errors.spellingErrorRate, color: AppColors.spelling),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: AppColors.peach),
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
                            (label: d.label, value: data.byDifficulty[d] ?? 0, color: AppColors.mutedRose),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
