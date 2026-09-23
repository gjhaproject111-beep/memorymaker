import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/passage.dart';
import '../../../core/models/user_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../widgets/app_widgets.dart';

/// Step 1: the passage is shown exactly once. No auto-scroll tricks, no way
/// back to it once the user presses "I'm Ready" — the interface here is
/// deliberately stable (spec §19, §34: no distraction during the test).
class ReadStep extends StatefulWidget {
  final Passage passage;
  final UserSettings settings;
  final DateTime readStart;
  final VoidCallback onReady;

  const ReadStep({
    super.key,
    required this.passage,
    required this.settings,
    required this.readStart,
    required this.onReady,
  });

  @override
  State<ReadStep> createState() => _ReadStepState();
}

class _ReadStepState extends State<ReadStep> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.settings.readingTimerEnabled) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed = DateTime.now().difference(widget.readStart));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passage = widget.passage;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1 of 4', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text('Read the passage carefully', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Take your time. You will see this passage only once. Try to remember as much as you can.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
            child: Text(passage.text, style: AppTextStyles.passageReading),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.short_text, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Word count: ${passage.wordCount}', style: AppTextStyles.caption),
              ]),
              if (widget.settings.readingTimerEnabled)
                Row(children: [
                  const Icon(Icons.timer, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(DateFormatting.duration(_elapsed), style: AppTextStyles.caption),
                ]),
            ],
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: "I'm Ready", onPressed: widget.onReady, trailingIcon: null),
        ],
      ),
    );
  }
}
