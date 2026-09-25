import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/user_settings.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_widgets.dart';

const _lengthOptions = [90, 120, 150, 200, 300, 500];

/// Only the settings that meaningfully change training behavior (spec §36)
/// — deliberately no social/login/subscription noise.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await Services.settings.load();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _update(void Function(UserSettings) mutate) async {
    final settings = _settings;
    if (settings == null) return;
    mutate(settings);
    setState(() {});
    await Services.settings.save(settings);
    AppDataBus.instance.notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return GradientBackground(
      child: SafeArea(
        child: settings == null
            ? const LoadingView()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: AppTextStyles.h1),
                    const SizedBox(height: 20),
                    _sectionCard('Training', Icons.bolt, [
                      _lengthRow(settings),
                      const Divider(height: 26),
                      _difficultyRow(settings),
                      const Divider(height: 26),
                      _masteryRow(settings),
                      const Divider(height: 26),
                      _switchRow('Show corrections immediately', settings.showCorrectionsImmediately,
                          (v) => _update((s) => s.showCorrectionsImmediately = v)),
                      _switchRow('Require exact punctuation', settings.requireExactPunctuation,
                          (v) => _update((s) => s.requireExactPunctuation = v)),
                    ]),
                    const SizedBox(height: 16),
                    _sectionCard('Timing', Icons.timer, [
                      _switchRow('Reading timer', settings.readingTimerEnabled,
                          (v) => _update((s) => s.readingTimerEnabled = v)),
                      _switchRow('Recall timer', settings.recallTimerEnabled,
                          (v) => _update((s) => s.recallTimerEnabled = v)),
                    ]),
                    const SizedBox(height: 16),
                    _sectionCard('Retention Schedule', Icons.alarm, [_retentionRow(settings)]),
                    const SizedBox(height: 16),
                    _sectionCard('Sound', Icons.volume_up, [
                      _switchRow('Sound effects', settings.soundEnabled, (v) => _update((s) => s.soundEnabled = v)),
                    ]),
                    const SizedBox(height: 16),
                    _sectionCard('Appearance', Icons.palette_outlined, [
                      _row('Theme', const Text('Light & Peach', style: AppTextStyles.bodySecondary)),
                      const Divider(height: 26),
                      _fontSizeRow(settings),
                    ]),
                    const SizedBox(height: 16),
                    _sectionCard('Data', Icons.storage, [
                      _dataButton('Export backup', Icons.file_download, () async {
                        await Services.backup.exportBackup();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Backup saved to local app storage.')));
                      }),
                      const SizedBox(height: 10),
                      _dataButton('Restore from backup', Icons.file_upload, () async {
                        final ok = await Services.backup.restoreBackup();
                        AppDataBus.instance.notifyChanged();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Restored from the last local backup.' : 'No local backup found yet.'),
                        ));
                      }),
                      const SizedBox(height: 10),
                      _dataButton('Reset progress', Icons.delete_outline, _confirmReset, destructive: true),
                    ]),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset all progress?'),
        content: const Text(
          'This permanently deletes every session, attempt, and mastery record. Passages themselves are unaffected. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Services.backup.resetProgress();
      AppDataBus.instance.notifyChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress reset.')));
    }
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Expanded(child: Text(label, style: AppTextStyles.body)), trailing],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _row(label, Switch(value: value, onChanged: onChanged)),
    );
  }

  Widget _lengthRow(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default passage length', style: AppTextStyles.body),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _lengthOptions.map((len) {
            final selected = settings.defaultPassageLength == len;
            return ChoiceChip(
              label: Text('$len'),
              selected: selected,
              onSelected: (_) => _update((s) => s.defaultPassageLength = len),
              selectedColor: AppColors.primaryDark,
              labelStyle: TextStyle(color: selected ? AppColors.darkButtonText : AppColors.textSecondary),
              backgroundColor: AppColors.background,
              side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _difficultyRow(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty', style: AppTextStyles.body),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PassageDifficulty.values.map((d) {
            final selected = settings.defaultDifficulty == d;
            return ChoiceChip(
              label: Text(d.label),
              selected: selected,
              onSelected: (_) => _update((s) => s.defaultDifficulty = d),
              selectedColor: AppColors.primaryDark,
              labelStyle: TextStyle(color: selected ? AppColors.darkButtonText : AppColors.textSecondary),
              backgroundColor: AppColors.background,
              side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _masteryRow(UserSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Mastery threshold', Text('${(settings.masteryThreshold * 100).round()}%', style: AppTextStyles.body)),
        Slider(
          value: settings.masteryThreshold,
          min: 0.90,
          max: 1.0,
          divisions: 10,
          onChanged: (v) => _update((s) => s.masteryThreshold = v),
        ),
      ],
    );
  }

  Widget _retentionRow(UserSettings settings) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RetentionInterval.values.map((interval) {
        final selected = settings.retentionIntervals.contains(interval);
        return FilterChip(
          label: Text(interval.label),
          selected: selected,
          onSelected: (isOn) => _update((s) {
            if (isOn) {
              if (!s.retentionIntervals.contains(interval)) s.retentionIntervals.add(interval);
            } else {
              s.retentionIntervals.remove(interval);
            }
          }),
          selectedColor: AppColors.primaryDark,
          labelStyle: TextStyle(color: selected ? AppColors.darkButtonText : AppColors.textSecondary),
          backgroundColor: AppColors.background,
          side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _fontSizeRow(UserSettings settings) {
    const options = {'Small': 0.9, 'Medium': 1.0, 'Large': 1.15};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Font size', style: AppTextStyles.body),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: options.entries.map((e) {
            final selected = (settings.fontScale - e.value).abs() < 0.01;
            return ChoiceChip(
              label: Text(e.key),
              selected: selected,
              onSelected: (_) => _update((s) => s.fontScale = e.value),
              selectedColor: AppColors.primaryDark,
              labelStyle: TextStyle(color: selected ? AppColors.darkButtonText : AppColors.textSecondary),
              backgroundColor: AppColors.background,
              side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dataButton(String label, IconData icon, VoidCallback onTap, {bool destructive = false}) {
    final color = destructive ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: color))),
          ],
        ),
      ),
    );
  }
}
