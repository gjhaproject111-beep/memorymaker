import 'package:flutter/material.dart';

import '../../../core/models/comparison_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/app_widgets.dart';

/// Step 3b (spec §8): the categorized error review — Missing / Extra /
/// Substituted / Order / Spelling — always derived live from the current
/// [ComparisonResult], never a stale cached copy.
class ReviewStep extends StatefulWidget {
  final ComparisonResult comparison;
  final VoidCallback onBack;
  final VoidCallback? onTryAgain; // null for a retention test (one-shot, no loop)

  const ReviewStep({super.key, required this.comparison, required this.onBack, this.onTryAgain});

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _CategoryTab {
  final String label;
  final int count;
  final Color color;
  const _CategoryTab(this.label, this.count, this.color);
}

class _ReviewStepState extends State<ReviewStep> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.comparison;
    final categories = [
      _CategoryTab('Missing', c.missingWords.length, AppColors.missing),
      _CategoryTab('Extra', c.extraWords.length, AppColors.extra),
      _CategoryTab('Substituted', c.substitutions.length, AppColors.substituted),
      _CategoryTab('Order', c.orderErrors.length, AppColors.order),
      _CategoryTab('Spelling', c.spellingErrors.length, AppColors.spelling),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (i) {
                final tab = categories[i];
                final selected = _selected == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${tab.label} (${tab.count})'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selected = i),
                    selectedColor: tab.color.withOpacity(0.25),
                    labelStyle: TextStyle(
                      color: selected ? tab.color : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppColors.darkPlum,
                    side: BorderSide(color: selected ? tab.color : AppColors.plumBorder),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: _buildCategoryContent(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Back', onPressed: widget.onBack)),
              if (widget.onTryAgain != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(label: 'Try Again', onPressed: widget.onTryAgain, trailingIcon: null),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent() {
    final c = widget.comparison;
    switch (_selected) {
      case 0:
        return _wordList(c.missingWords, AppColors.missing,
            emptyText: 'No missing words — every word from the original made it into your recall.');
      case 1:
        return _wordList(c.extraWords, AppColors.extra, emptyText: 'No extra words.');
      case 2:
        return _pairList(c.substitutions, AppColors.substituted, emptyText: 'No substituted words.');
      case 3:
        return _pairList(c.orderErrors, AppColors.order, emptyText: 'No order errors.', isOrder: true);
      default:
        return _pairList(c.spellingErrors, AppColors.spelling, emptyText: 'No spelling errors.');
    }
  }

  Widget _wordList(List<String> words, Color color, {required String emptyText}) {
    if (words.isEmpty) {
      return EmptyState(icon: Icons.check_circle_outline, title: 'Clean', message: emptyText);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: words.map((w) => _bullet(w, color)).toList(),
    );
  }

  Widget _pairList(List<WordPair> pairs, Color color, {required String emptyText, bool isOrder = false}) {
    if (pairs.isEmpty) {
      return EmptyState(icon: Icons.check_circle_outline, title: 'Clean', message: emptyText);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in pairs) Padding(padding: const EdgeInsets.only(bottom: 10), child: _pairCard(p, color, isOrder)),
      ],
    );
  }

  Widget _pairCard(WordPair p, Color color, bool isOrder) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOrder ? 'Expected here' : 'Original', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  p.original,
                  style: AppTextStyles.body
                      .copyWith(decoration: TextDecoration.lineThrough, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOrder ? 'You wrote here' : 'Your answer', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(p.recalled, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String word, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(word, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
