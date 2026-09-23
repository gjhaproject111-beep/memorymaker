import 'package:flutter/material.dart';

import '../../../core/models/comparison_result.dart';
import '../../../core/models/recall_attempt.dart';
import '../../../core/models/training_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../widgets/app_widgets.dart';

/// Step 3: either a per-attempt scorecard (spec §21), or — the moment
/// mastery is reached — the distinct "Mastered" summary (spec §9). A
/// retention test gets its own simpler variant (spec §10).
class ResultsStep extends StatelessWidget {
  final RecallAttempt attempt;
  final ComparisonResult comparison;
  final TrainingSession session;
  final bool isMastered;
  final bool isRetentionTest;
  final VoidCallback onReviewMistakes;
  final VoidCallback onTryAgain;
  final VoidCallback onDone;

  const ResultsStep({
    super.key,
    required this.attempt,
    required this.comparison,
    required this.session,
    required this.isMastered,
    required this.isRetentionTest,
    required this.onReviewMistakes,
    required this.onTryAgain,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    if (isRetentionTest) return _buildRetentionResult();
    if (isMastered) return _buildMasteryResult();
    return _buildAttemptResult();
  }

  Widget _buildAttemptResult() {
    final accuracy = attempt.exactWordAccuracy;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          AccuracyRing(
            value: accuracy,
            size: 150,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(accuracy * 100).round()}%', style: AppTextStyles.display),
                Text('Attempt ${attempt.attemptNumber} Accuracy',
                    style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detailed Breakdown', style: AppTextStyles.h3),
                const SizedBox(height: 14),
                _row('Correct words', '${attempt.correctWordCount} / ${attempt.originalWordCount}', AppColors.success),
                _row('Missing', '${attempt.missingCount}', AppColors.missing),
                _row('Extra words', '${attempt.extraCount}', AppColors.extra),
                _row('Substituted', '${attempt.substitutionCount}', AppColors.substituted),
                _row('Wrong order', '${attempt.orderErrorCount}', AppColors.order),
                _row('Spelling', '${attempt.spellingErrorCount}', AppColors.spelling),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Review Mistakes', onPressed: onReviewMistakes)),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'Try Again', onPressed: onTryAgain, trailingIcon: null)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryResult() {
    final record = session.masteryRecord!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 46),
          const SizedBox(height: 12),
          Text('Mastered', style: AppTextStyles.display),
          const SizedBox(height: 4),
          Text('${(record.finalAttemptAccuracy * 100).round()}% Exact Word Accuracy', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 24),
          AppCard(
            child: Row(
              children: [
                Expanded(child: _statColumn('Attempts', '${record.attemptsToMastery}')),
                Expanded(child: _statColumn('First Attempt', '${(record.firstAttemptAccuracy * 100).round()}%')),
                Expanded(child: _statColumn('Final Attempt', '${(record.finalAttemptAccuracy * 100).round()}%')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: _statColumn('Total Time', DateFormatting.duration(Duration(milliseconds: record.totalTrainingMs))),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Next Passage', onPressed: onDone),
        ],
      ),
    );
  }

  Widget _buildRetentionResult() {
    final accuracy = attempt.exactWordAccuracy;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          AccuracyRing(
            value: accuracy,
            size: 150,
            color: AppColors.info,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(accuracy * 100).round()}%', style: AppTextStyles.display),
                const Text('Retention Accuracy', style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            accuracy >= 0.9
                ? 'Strong retention — this one has stuck.'
                : 'Your retention was recorded. Some fading between reviews is normal.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Review Mistakes', onPressed: onReviewMistakes)),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'Done', onPressed: onDone, trailingIcon: null)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color dot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.bodySecondary),
          ]),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.statNumber),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }
}
