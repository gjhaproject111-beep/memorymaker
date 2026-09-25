import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../training_step.dart';

/// The "1 Read · 2 Recall · 3 Review · 4 Repeat" progress indicator shown
/// above the Read and Recall screens (spec §19-20).
class StepHeader extends StatelessWidget {
  final TrainingStep current;
  const StepHeader({super.key, required this.current});

  static const _labels = ['Read', 'Recall', 'Review', 'Repeat'];

  @override
  Widget build(BuildContext context) {
    final activeIndex = current == TrainingStep.recall ? 1 : 0;
    return Row(
      children: List.generate(_labels.length, (i) {
        final active = i == activeIndex;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: active ? AppColors.peachAccent : AppColors.border,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primaryDark : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.primaryDark : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
