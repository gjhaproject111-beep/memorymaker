import 'package:flutter/material.dart';

import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/nav_shell.dart';
import '../training/training_flow_screen.dart';

/// First-run experience (spec §44): a brief welcome, then a personal
/// baseline using unseen passages (spec §14) before landing on the
/// dashboard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _starting = false;

  Future<void> _beginBaseline() async {
    setState(() => _starting = true);
    final passages = await Services.passageSelector.pickBaselineSet(count: 3);
    for (final passage in passages) {
      if (!mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TrainingFlowScreen(passage: passage, isBaseline: true)));
    }
    await _finish(baselineCompleted: passages.isNotEmpty);
  }

  Future<void> _finish({required bool baselineCompleted}) async {
    final settings = await Services.settings.load();
    settings.hasSeenOnboarding = true;
    if (baselineCompleted) settings.hasCompletedBaseline = true;
    await Services.settings.save(settings);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootShell()));
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.psychology, color: AppColors.peach, size: 48),
              const SizedBox(height: 22),
              Text('Welcome to Photographic Memory', style: AppTextStyles.display),
              const SizedBox(height: 8),
              Text('Remember more. Recall precisely.', style: AppTextStyles.bodySecondary),
              const SizedBox(height: 28),
              AppCard(
                child: Text(
                  'Read a passage once. Recall it. Learn from your mistakes. Then test what remains.',
                  style: AppTextStyles.body,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We\'ll start with a short baseline — a few unseen passages — so future progress has something honest to compare against.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Begin Baseline',
                loading: _starting,
                onPressed: _starting ? null : _beginBaseline,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _starting ? null : () => _finish(baselineCompleted: false),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
