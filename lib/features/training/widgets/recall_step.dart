import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/user_settings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../widgets/app_widgets.dart';

/// Step 2: an empty text area, nothing else. The original passage is never
/// reachable from here (spec §4, §20).
class RecallStep extends StatefulWidget {
  final TextEditingController controller;
  final UserSettings settings;
  final bool submitting;
  final DateTime recallStart;
  final VoidCallback onSubmit;

  const RecallStep({
    super.key,
    required this.controller,
    required this.settings,
    required this.submitting,
    required this.recallStart,
    required this.onSubmit,
  });

  @override
  State<RecallStep> createState() => _RecallStepState();
}

class _RecallStepState extends State<RecallStep> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    if (widget.settings.recallTimerEnabled) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed = DateTime.now().difference(widget.recallStart));
      });
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _wordCount && mounted) setState(() => _wordCount = count);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2 of 4', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text('Recall the passage', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            "Write everything you remember, in the exact order. Don't worry if you're not sure — just do your best.",
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              expands: true,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTextStyles.body,
              decoration: const InputDecoration(hintText: 'Start typing your recall here…'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Word count: $_wordCount', style: AppTextStyles.caption),
              if (widget.settings.recallTimerEnabled)
                Text(DateFormatting.duration(_elapsed), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Clear',
                  onPressed: widget.controller.text.isEmpty ? null : () => widget.controller.clear(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Submit',
                  loading: widget.submitting,
                  trailingIcon: null,
                  onPressed: widget.controller.text.trim().isEmpty ? null : widget.onSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
