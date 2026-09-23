import 'package:flutter/material.dart';

import '../../core/models/comparison_result.dart';
import '../../core/models/enums.dart';
import '../../core/models/mastery_record.dart';
import '../../core/models/passage.dart';
import '../../core/models/recall_attempt.dart';
import '../../core/models/retention_test.dart';
import '../../core/models/training_session.dart';
import '../../core/models/user_settings.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/id_generator.dart';
import '../../widgets/app_widgets.dart';
import 'training_step.dart';
import 'widgets/read_step.dart';
import 'widgets/recall_step.dart';
import 'widgets/results_step.dart';
import 'widgets/review_step.dart';
import 'widgets/step_header.dart';

/// Orchestrates the whole Read → Recall → Results → Review → Repeat loop
/// (spec §3-10) for one passage, including delayed-retention checks, which
/// reuse the same Recall/Results machinery but skip straight to Recall.
class TrainingFlowScreen extends StatefulWidget {
  final Passage passage;
  final TrainingSession? existingSession;
  final bool isBaseline;
  final RetentionTest? retentionTest;

  const TrainingFlowScreen({
    super.key,
    required this.passage,
    this.existingSession,
    this.isBaseline = false,
    this.retentionTest,
  });

  @override
  State<TrainingFlowScreen> createState() => _TrainingFlowScreenState();
}

class _TrainingFlowScreenState extends State<TrainingFlowScreen> {
  late TrainingSession _session;
  late UserSettings _settings;
  bool _loading = true;

  TrainingStep _step = TrainingStep.read;
  DateTime? _readStart;
  DateTime? _readEnd;
  DateTime? _recallStart;
  final TextEditingController _recallController = TextEditingController();

  ComparisonResult? _lastComparison;
  RecallAttempt? _lastAttempt;
  bool _justMastered = false;
  bool _submitting = false;

  bool get _isRetentionFlow => widget.retentionTest != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _settings = await Services.settings.load();
    if (widget.existingSession != null) {
      _session = widget.existingSession!;
    } else {
      _session = TrainingSession(
        id: IdGenerator.next('session'),
        passageId: widget.passage.id,
        startedAt: DateTime.now(),
        status: SessionStatus.inProgress,
        isBaseline: widget.isBaseline,
      );
      await Services.sessions.save(_session);
    }

    if (_isRetentionFlow) {
      _step = TrainingStep.recall;
      _recallStart = DateTime.now();
    } else {
      _readStart = DateTime.now();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _recallController.dispose();
    super.dispose();
  }

  void _onReadyPressed() {
    setState(() {
      _readEnd = DateTime.now();
      _step = TrainingStep.recall;
      _recallStart = DateTime.now();
    });
  }

  Future<void> _onSubmitRecall() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final recallEnd = DateTime.now();
    final readingDuration =
        _isRetentionFlow ? Duration.zero : (_readEnd ?? DateTime.now()).difference(_readStart ?? DateTime.now());
    final recallDuration = recallEnd.difference(_recallStart ?? recallEnd);

    final comparison = Services.comparison.compare(
      widget.passage.text,
      _recallController.text,
      exactPunctuation: _settings.requireExactPunctuation,
    );

    final attempt = Services.scoring.buildAttempt(
      sessionId: _session.id,
      passageId: widget.passage.id,
      attemptNumber: _session.attempts.length + 1,
      isRetentionTest: _isRetentionFlow,
      readingDuration: readingDuration,
      recallDuration: recallDuration,
      comparison: comparison,
    );
    _session.attempts.add(attempt);

    var justMastered = false;
    if (_isRetentionFlow) {
      final test = widget.retentionTest!;
      test.completedAt = DateTime.now();
      test.accuracy = comparison.exactWordAccuracy;
      test.attemptId = attempt.id;
    } else if (!_session.isMastered && Services.scoring.reachedMastery(comparison, _settings.masteryThreshold)) {
      justMastered = true;
      final firstAccuracy = _session.attempts.first.exactWordAccuracy;
      final totalMs = _session.attempts.fold<int>(0, (sum, a) => sum + a.readingDurationMs + a.recallDurationMs);
      _session.status = SessionStatus.mastered;
      _session.masteryRecord = MasteryRecord(
        sessionId: _session.id,
        passageId: widget.passage.id,
        attemptsToMastery: _session.attempts.length,
        firstAttemptAccuracy: firstAccuracy,
        finalAttemptAccuracy: comparison.exactWordAccuracy,
        totalTrainingMs: totalMs,
        masteredAt: DateTime.now(),
      );
      _session.retentionTests.addAll(Services.retentionScheduler.scheduleFor(
        sessionId: _session.id,
        passageId: widget.passage.id,
        masteredAt: DateTime.now(),
        intervals: _settings.retentionIntervals,
      ));
    }

    await Services.sessions.save(_session);
    AppDataBus.instance.notifyChanged();

    if (!mounted) return;
    setState(() {
      _lastComparison = comparison;
      _lastAttempt = attempt;
      _justMastered = justMastered;
      _step = TrainingStep.results;
      _submitting = false;
    });
  }

  void _onTryAgain() {
    setState(() {
      _recallController.clear();
      _lastComparison = null;
      _lastAttempt = null;
      _step = TrainingStep.read;
      _readStart = DateTime.now();
      _readEnd = null;
    });
  }

  void _onReviewMistakes() => setState(() => _step = TrainingStep.review);
  void _onBackFromReview() => setState(() => _step = TrainingStep.results);
  void _onFinish() => Navigator.of(context).pop(true);

  Future<bool> _confirmExitDuringRecall() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.plumCard,
        title: const Text('Leave training?'),
        content: const Text(
          'Your progress on this attempt will be lost, but the session itself is saved and you can resume it later.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    return result ?? false;
  }

  String get _title {
    if (_isRetentionFlow) return 'Retention Test';
    return switch (_step) {
      TrainingStep.read || TrainingStep.recall => 'Verbatim Memory Trainer',
      TrainingStep.results => _justMastered ? 'Mastered' : 'Session Results',
      TrainingStep.review => 'Review & Analysis',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.deepPlum, body: LoadingView());
    }

    final showStepHeader = !_isRetentionFlow && (_step == TrainingStep.read || _step == TrainingStep.recall);

    return WillPopScope(
      onWillPop: () async {
        if (_step != TrainingStep.recall) return true;
        return _confirmExitDuringRecall();
      },
      child: Scaffold(
        backgroundColor: AppColors.deepPlum,
        appBar: AppBar(title: Text(_title)),
        body: SafeArea(
          child: Column(
            children: [
              if (showStepHeader)
                Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: StepHeader(current: _step)),
              Expanded(child: _buildStep()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      TrainingStep.read => ReadStep(
          passage: widget.passage,
          settings: _settings,
          readStart: _readStart!,
          onReady: _onReadyPressed,
        ),
      TrainingStep.recall => RecallStep(
          controller: _recallController,
          settings: _settings,
          submitting: _submitting,
          recallStart: _recallStart!,
          onSubmit: _onSubmitRecall,
        ),
      TrainingStep.results => ResultsStep(
          attempt: _lastAttempt!,
          comparison: _lastComparison!,
          session: _session,
          isMastered: _justMastered,
          isRetentionTest: _isRetentionFlow,
          onReviewMistakes: _onReviewMistakes,
          onTryAgain: _onTryAgain,
          onDone: _onFinish,
        ),
      TrainingStep.review => ReviewStep(
          comparison: _lastComparison!,
          onBack: _onBackFromReview,
          onTryAgain: _isRetentionFlow ? null : _onTryAgain,
        ),
    };
  }
}
