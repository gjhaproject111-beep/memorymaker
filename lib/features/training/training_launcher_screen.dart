import 'package:flutter/material.dart';

import '../../core/models/passage.dart';
import '../../core/models/training_session.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_widgets.dart';
import 'training_flow_screen.dart';

/// The "Training" tab: a focused launch point for starting a fresh session
/// or resuming one left unfinished (spec §30 session recovery), independent
/// of the Home dashboard's own "Start Training" shortcut.
class TrainingLauncherScreen extends StatefulWidget {
  const TrainingLauncherScreen({super.key});

  @override
  State<TrainingLauncherScreen> createState() => _TrainingLauncherScreenState();
}

class _TrainingLauncherScreenState extends State<TrainingLauncherScreen> {
  late Future<_LauncherData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    AppDataBus.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppDataBus.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() => _future = _load());
  }

  Future<_LauncherData> _load() async {
    final settings = await Services.settings.load();
    final recoverable = await Services.sessions.findRecoverable();
    Passage? recoverablePassage;
    if (recoverable != null) {
      recoverablePassage = await Services.passages.byId(recoverable.passageId);
    }
    final due = await Services.sessions.duePendingRetentionTests();
    return _LauncherData(
      defaultLength: settings.defaultPassageLength,
      recoverableSession: recoverable,
      recoverablePassage: recoverablePassage,
      dueRetentionCount: due.length,
    );
  }

  Future<void> _startNewSession() async {
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrainingFlowScreen(passage: result.passage!)),
    );
    _onDataChanged();
  }

  Future<void> _resumeSession(TrainingSession session, Passage passage) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrainingFlowScreen(passage: passage, existingSession: session)),
    );
    _onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<_LauncherData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('One focused pass at a time.', style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 24),
                  if (data.recoverableSession != null && data.recoverablePassage != null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.history, color: AppColors.peach, size: 20),
                            const SizedBox(width: 8),
                            Text('Unfinished session', style: AppTextStyles.h3),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            'You have an unfinished session on "${data.recoverablePassage!.title}".',
                            style: AppTextStyles.bodySecondary,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: 'Discard',
                                  onPressed: () async {
                                    await Services.sessions.discard(data.recoverableSession!.id);
                                    _onDataChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: PrimaryButton(
                                  label: 'Resume',
                                  onPressed: () => _resumeSession(data.recoverableSession!, data.recoverablePassage!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Session', style: AppTextStyles.h3),
                        const SizedBox(height: 6),
                        Text('${data.defaultLength} words · an unseen passage', style: AppTextStyles.bodySecondary),
                        const SizedBox(height: 18),
                        PrimaryButton(label: 'Start Training', onPressed: _startNewSession),
                      ],
                    ),
                  ),
                  if (data.dueRetentionCount > 0) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.alarm, color: AppColors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${data.dueRetentionCount} retention test${data.dueRetentionCount == 1 ? '' : 's'} ready',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LauncherData {
  final int defaultLength;
  final TrainingSession? recoverableSession;
  final Passage? recoverablePassage;
  final int dueRetentionCount;

  const _LauncherData({
    required this.defaultLength,
    required this.recoverableSession,
    required this.recoverablePassage,
    required this.dueRetentionCount,
  });
}
