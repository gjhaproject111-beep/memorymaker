import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/passage.dart';
import '../../core/models/retention_test.dart';
import '../../core/models/training_session.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_format.dart';
import '../../widgets/app_widgets.dart';
import '../training/training_flow_screen.dart';

/// The delayed-retention timeline (spec §22): one card per mastered
/// passage, each showing its 10-minute / 24-hour / 3-day / 7-day / 30-day
/// checkpoints and whether they're pending, ready now, or already scored.
class RetentionScreen extends StatefulWidget {
  const RetentionScreen({super.key});

  @override
  State<RetentionScreen> createState() => _RetentionScreenState();
}

class _PassageRetention {
  final TrainingSession session;
  final Passage passage;
  const _PassageRetention({required this.session, required this.passage});
}

class _RetentionScreenState extends State<RetentionScreen> {
  late Future<List<_PassageRetention>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_PassageRetention>> _load() async {
    final sessions = await Services.sessions.masteredSessions();
    final out = <_PassageRetention>[];
    for (final s in sessions.reversed) {
      final passage = await Services.passages.byId(s.passageId);
      if (passage != null) out.add(_PassageRetention(session: s, passage: passage));
    }
    return out;
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _takeTest(TrainingSession session, Passage passage, RetentionTest test) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TrainingFlowScreen(passage: passage, existingSession: session, retentionTest: test),
    ));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<List<_PassageRetention>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            final items = snapshot.data!;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(children: [
                    Expanded(child: Text('Retention Tests', style: AppTextStyles.h1)),
                  ]),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState(
                          icon: Icons.alarm,
                          title: 'No retention tests yet',
                          message: 'Master a passage to start tracking how well you remember it over time.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: items.length,
                          itemBuilder: (context, i) =>
                              Padding(padding: const EdgeInsets.only(bottom: 14), child: _card(items[i])),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(_PassageRetention item) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.passage.title, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(item.passage.category.label, style: AppTextStyles.caption),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: item.session.retentionTests
                .map((t) => _intervalChip(item.session, item.passage, t))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _intervalChip(TrainingSession session, Passage passage, RetentionTest test) {
    final isDue = test.isDue;
    final isDone = test.isCompleted;
    Color color;
    String status;
    if (isDone) {
      color = AppColors.success;
      status = '${(test.accuracy! * 100).round()}%';
    } else if (isDue) {
      color = AppColors.peach;
      status = 'Ready';
    } else {
      color = AppColors.textMuted;
      status = DateFormatting.relativeToNow(test.scheduledAt);
    }
    return InkWell(
      onTap: isDue ? () => _takeTest(session, passage, test) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.darkPlum,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(test.interval.label, style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
