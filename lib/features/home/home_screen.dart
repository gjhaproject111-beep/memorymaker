import 'package:flutter/material.dart';

import '../../core/models/passage.dart';
import '../../core/models/training_session.dart';
import '../../core/repositories/progress_repository.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../widgets/app_widgets.dart';
import '../retention/retention_screen.dart';
import '../training/training_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

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

  Future<_HomeData> _load() async {
    final settings = await Services.settings.load();
    final summary = await Services.progress.homeSummary();
    final recoverable = await Services.sessions.findRecoverable();
    Passage? recoverablePassage;
    if (recoverable != null) recoverablePassage = await Services.passages.byId(recoverable.passageId);
    final dueTests = await Services.sessions.duePendingRetentionTests();
    return _HomeData(
      defaultLength: settings.defaultPassageLength,
      summary: summary,
      recoverableSession: recoverable,
      recoverablePassage: recoverablePassage,
      dueRetentionCount: dueTests.length,
    );
  }

  Future<void> _startTraining() async {
    final settings = await Services.settings.load();
    final result = await Services.passageSelector.pickNext(preferredDifficulty: settings.defaultDifficulty);
    if (result.passage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've trained on every passage in the built-in library — check the Library tab.")),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TrainingFlowScreen(passage: result.passage!)));
    _refresh();
  }

  Future<void> _resumeSession(TrainingSession session, Passage passage) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrainingFlowScreen(passage: passage, existingSession: session)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            final data = snapshot.data!;
            return RefreshIndicator(
              color: AppColors.peach,
              backgroundColor: AppColors.darkPlum,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${DateFormatting.greeting()},', style: AppTextStyles.h1),
                            const SizedBox(height: 4),
                            Text(
                              data.summary.currentStreakDays > 0
                                  ? 'Keep going! You have a ${data.summary.currentStreakDays}-day streak.'
                                  : 'Train your memory, one passage at a time.',
                              style: AppTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (data.recoverableSession != null && data.recoverablePassage != null) ...[
                    _ResumeBanner(
                      passageTitle: data.recoverablePassage!.title,
                      onDiscard: () async {
                        await Services.sessions.discard(data.recoverableSession!.id);
                        _refresh();
                      },
                      onResume: () => _resumeSession(data.recoverableSession!, data.recoverablePassage!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _todaySessionCard(data)),
                      const SizedBox(width: 14),
                      Expanded(child: _progressRingCard(data)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Quick Stats', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
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
                        value: data.summary.oneReadAccuracy == null
                            ? '—'
                            : '${(data.summary.oneReadAccuracy!.value * 100).round()}%',
                        delta: data.summary.oneReadAccuracy?.delta,
                      ),
                      StatTile(
                        label: 'Attempts to Mastery',
                        value: data.summary.attemptsToMastery == null
                            ? '—'
                            : data.summary.attemptsToMastery!.value.toStringAsFixed(1),
                        delta: data.summary.attemptsToMastery?.delta,
                        deltaIsGoodWhenPositive: false,
                        deltaIsPercentagePoints: false,
                      ),
                      StatTile(
                        label: '7-Day Retention',
                        value: data.summary.sevenDayRetention == null
                            ? '—'
                            : '${(data.summary.sevenDayRetention!.value * 100).round()}%',
                        delta: data.summary.sevenDayRetention?.delta,
                      ),
                    ],
                  ),
                  if (data.dueRetentionCount > 0) ...[
                    const SizedBox(height: 20),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.alarm, color: AppColors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Today's retention tests: ${data.dueRetentionCount} ready",
                              style: AppTextStyles.body,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RetentionScreen()));
                            },
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: AppColors.peach),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current streak', style: AppTextStyles.caption),
                              Text('${data.summary.currentStreakDays} day${data.summary.currentStreakDays == 1 ? '' : 's'}',
                                  style: AppTextStyles.h3),
                            ],
                          ),
                        ),
                        Text('${data.summary.totalPassagesMastered} mastered', style: AppTextStyles.bodySecondary),
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

  Widget _todaySessionCard(_HomeData data) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, color: AppColors.peach, size: 22),
          const SizedBox(height: 10),
          Text("Today's Session", style: AppTextStyles.h3),
          Text('Verbatim Memory', style: AppTextStyles.caption),
          const SizedBox(height: 10),
          Text('${data.defaultLength} words', style: AppTextStyles.statNumber.copyWith(fontSize: 20)),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Start Training', onPressed: _startTraining, expand: true),
        ],
      ),
    );
  }

  Widget _progressRingCard(_HomeData data) {
    final value = data.summary.oneReadAccuracy?.value ?? 0;
    final delta = data.summary.oneReadAccuracy?.delta;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text('Your Progress', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          AccuracyRing(
            value: value,
            size: 96,
            strokeFraction: 0.11,
            center: Text('${(value * 100).round()}%',
                style: AppTextStyles.statNumber.copyWith(fontSize: 18)),
          ),
          const SizedBox(height: 8),
          Text('Overall Accuracy', style: AppTextStyles.caption, textAlign: TextAlign.center),
          if (delta != null) ...[
            const SizedBox(height: 6),
            TrendChip(delta: delta),
          ],
        ],
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  final String passageTitle;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ResumeBanner({required this.passageTitle, required this.onResume, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history, color: AppColors.peach, size: 20),
            const SizedBox(width: 8),
            const Text('You have an unfinished session', style: AppTextStyles.h3),
          ]),
          const SizedBox(height: 6),
          Text('"$passageTitle" is still in progress.', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Discard', onPressed: onDiscard)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: PrimaryButton(label: 'Resume', onPressed: onResume)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  final int defaultLength;
  final HomeSummary summary;
  final TrainingSession? recoverableSession;
  final Passage? recoverablePassage;
  final int dueRetentionCount;

  const _HomeData({
    required this.defaultLength,
    required this.summary,
    required this.recoverableSession,
    required this.recoverablePassage,
    required this.dueRetentionCount,
  });
}
