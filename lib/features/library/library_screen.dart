import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/passage.dart';
import '../../core/models/training_session.dart';
import '../../core/state/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_widgets.dart';
import 'passage_detail_screen.dart';

class _LibraryEntry {
  final Passage passage;
  final TrainingSession? session;
  const _LibraryEntry({required this.passage, this.session});

  bool get isMastered => session?.isMastered ?? false;
  bool get isInProgress => session != null && !isMastered;
}

/// The personal passage library (spec §23): browse by category, see
/// mastery/retention status at a glance, and open a passage's history.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<_LibraryEntry>> _future;
  PassageCategory? _filter;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
    AppDataBus.instance.addListener(_refresh);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    AppDataBus.instance.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _future = _load());
  }

  Future<List<_LibraryEntry>> _load() async {
    final passages = await Services.passages.loadAll();
    final sessions = await Services.sessions.loadAll();
    final byPassage = <String, TrainingSession>{};
    for (final s in sessions) {
      final existing = byPassage[s.passageId];
      if (existing == null) {
        byPassage[s.passageId] = s;
        continue;
      }
      final existingScore = existing.isMastered ? 1 : 0;
      final newScore = s.isMastered ? 1 : 0;
      if (newScore > existingScore || (newScore == existingScore && s.startedAt.isAfter(existing.startedAt))) {
        byPassage[s.passageId] = s;
      }
    }
    return passages.map((p) => _LibraryEntry(passage: p, session: byPassage[p.id])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: FutureBuilder<List<_LibraryEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LoadingView();
            var entries = snapshot.data!;
            if (_filter != null) entries = entries.where((e) => e.passage.category == _filter).toList();
            if (_query.isNotEmpty) {
              entries = entries.where((e) => e.passage.title.toLowerCase().contains(_query)).toList();
            }
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(children: [Expanded(child: Text('Library', style: AppTextStyles.h1))]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search passages...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                              onPressed: () => _searchController.clear(),
                            ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', null),
                        for (final c in PassageCategory.values) _filterChip(c.label, c),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: entries.isEmpty
                      ? EmptyState(
                          icon: Icons.menu_book,
                          title: 'No passages',
                          message: _query.isNotEmpty ? 'No titles match "$_query".' : 'Nothing in this category yet.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: entries.length,
                          itemBuilder: (context, i) =>
                              Padding(padding: const EdgeInsets.only(bottom: 12), child: _entryCard(entries[i])),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(String label, PassageCategory? category) {
    final selected = _filter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = category),
        selectedColor: AppColors.primaryDark,
        labelStyle: TextStyle(
          color: selected ? AppColors.darkButtonText : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
        showCheckmark: false,
      ),
    );
  }

  Widget _entryCard(_LibraryEntry entry) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PassageDetailScreen(passage: entry.passage, session: entry.session),
        ));
        _refresh();
      },
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.passage.title, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Flexible(child: Text(entry.passage.category.label, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 10),
                    Text('${entry.passage.wordCount} words', style: AppTextStyles.caption),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      DifficultyPill(difficulty: entry.passage.difficulty),
                      _statusPill(entry),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(_LibraryEntry entry) {
    String label;
    Color color;
    if (entry.isMastered) {
      label = 'Mastered';
      color = AppColors.success;
    } else if (entry.isInProgress) {
      label = 'In progress';
      color = AppColors.peachAccent;
    } else {
      label = 'Unseen';
      color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
