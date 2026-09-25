import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/mastery_record.dart';
import '../../core/models/passage.dart';
import '../../core/models/recall_attempt.dart';
import '../../core/models/training_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_widgets.dart';
import '../training/training_flow_screen.dart';

/// A single passage's detail and history (spec §23: "allow the user to
/// open completed history").
class PassageDetailScreen extends StatelessWidget {
  final Passage passage;
  final TrainingSession? session;

  const PassageDetailScreen({super.key, required this.passage, this.session});

  @override
  Widget build(BuildContext context) {
    final currentSession = session;
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: Text(passage.title, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      DifficultyPill(difficulty: passage.difficulty),
                      const SizedBox(width: 8),
                      Text(passage.category.label, style: AppTextStyles.caption),
                      const Spacer(),
                      Text('${passage.wordCount} words', style: AppTextStyles.caption),
                    ]),
                    const SizedBox(height: 16),
                    AppCard(child: Text(passage.text, style: AppTextStyles.body)),
                    const SizedBox(height: 20),
                    if (currentSession != null) ...[
                      Text('History', style: AppTextStyles.h3),
                      const SizedBox(height: 10),
                      AppCard(
                        child: Column(
                          children: [
                            for (final a in currentSession.attempts) _attemptRow(a),
                            if (currentSession.masteryRecord != null) ...[
                              const Divider(height: 22),
                              _masteryRow(currentSession.masteryRecord!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    PrimaryButton(
                      label: currentSession == null
                          ? 'Start Training'
                          : (currentSession.isMastered ? 'Practice Again' : 'Resume Training'),
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TrainingFlowScreen(
                            passage: passage,
                            existingSession:
                                (currentSession != null && !currentSession.isMastered) ? currentSession : null,
                          ),
                        ));
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attemptRow(RecallAttempt a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a.isRetentionTest ? 'Retention check' : 'Attempt ${a.attemptNumber}', style: AppTextStyles.bodySecondary),
          Text('${(a.exactWordAccuracy * 100).round()}%', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _masteryRow(MasteryRecord m) {
    return Row(children: [
      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text('Mastered in ${m.attemptsToMastery} attempts', style: AppTextStyles.bodySecondary)),
    ]);
  }
}
