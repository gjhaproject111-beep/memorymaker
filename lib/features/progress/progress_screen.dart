import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/progress_snapshot.dart';
import '../../core/repositories/progress_repository.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/trend_chart.dart';

enum _View { overview, oneRead, retention, attempts }

/// The Progress section (spec §13): trends over time, always derived live
/// from stored sessions — never a cached or hand-set number.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressData {
  final HomeSummary summary;
  final List<ProgressSnapshot> trend;
  final Map<RetentionInterval, double?> retention;
  const _ProgressData({required this.summary, required this.trend, required this.retention});
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<_ProgressData> _future;
  _View _view = _View.overview;

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

  Future<_ProgressData> _load() async {
    final summary = await Services.progress.homeSummary();
    final trend = await Services.progress.weeklyTrend(weeks: 8);
    final retention = <RetentionInterval, double?>{};
    for (final interval in RetentionInterval.values) {
      retention[interval] = await Services.progress.retentionAccuracyFor(interval);
    }
    return _ProgressData(summary: summary, trend: trend, retention: retention);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<_ProgressData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: AppTextStyles.h1),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _tab('Overview', _View.overview),
                      _tab('One-Read', _View.oneRead),
                      _tab('Retention', _View.retention),
                      _tab('Attempts', _View.attempts),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  _buildView(data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tab(String label, _View view) {
    final selected = _view == view;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _view = view),
        selectedColor: AppColors.primaryDark,
        labelStyle: TextStyle(
          color: selected ? AppColors.darkButtonText : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildView(_ProgressData data) {
    return switch (_view) {
      _View.overview => _overview(data),
      _View.oneRead => _oneRead(data),
      _View.retention => _retention(data),
      _View.attempts => _attempts(data),
    };
  }

  Widget _overview(_ProgressData data) {
    final summary = data.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall Accuracy', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              TrendLineChart(
                values: data.trend.map((s) => s.oneReadAccuracy).toList(),
                labels: data.trend.map((s) => DateFormatting.shortDate(s.bucketStart)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            StatTile(
              label: 'One-Read Accuracy',
              value: summary.oneReadAccuracy == null ? '—' : '${(summary.oneReadAccuracy!.value * 100).round()}%',
              delta: summary.oneReadAccuracy?.delta,
            ),
            StatTile(
              label: 'Attempts to Mastery',
              value: summary.attemptsToMastery == null ? '—' : summary.attemptsToMastery!.value.toStringAsFixed(1),
              delta: summary.attemptsToMastery?.delta,
              deltaIsGoodWhenPositive: false,
              deltaIsPercentagePoints: false,
            ),
            StatTile(
              label: '7-Day Retention',
              value: summary.sevenDayRetention == null ? '—' : '${(summary.sevenDayRetention!.value * 100).round()}%',
              delta: summary.sevenDayRetention?.delta,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.insights, color: AppColors.peach),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.totalSessionsStarted == 0
                      ? 'Start your first session to begin tracking progress.'
                      : '${summary.totalPassagesMastered} of ${summary.totalSessionsStarted} sessions mastered so far.',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _oneRead(_ProgressData data) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('One-Read Accuracy — Last 8 Weeks', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Accuracy on the very first recall attempt of each passage.', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          TrendLineChart(
            values: data.trend.map((s) => s.oneReadAccuracy).toList(),
            labels: data.trend.map((s) => DateFormatting.shortDate(s.bucketStart)).toList(),
            height: 200,
          ),
        ],
      ),
    );
  }

  Widget _retention(_ProgressData data) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Retention by Interval', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Average accuracy on completed retention checks.', style: AppTextStyles.caption),
          const SizedBox(height: 18),
          BarBreakdown(
            items: [
              for (final interval in RetentionInterval.values)
                (label: interval.label, value: data.retention[interval] ?? 0, color: AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attempts(_ProgressData data) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attempts to Mastery — Last 8 Weeks', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Lower is better: fewer tries needed to reach 100% recall.', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          TrendLineChart(
            values: data.trend.map((s) => s.averageAttemptsToMastery).toList(),
            labels: data.trend.map((s) => DateFormatting.shortDate(s.bucketStart)).toList(),
            color: AppColors.info,
            valueFormat: (v) => v.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}
