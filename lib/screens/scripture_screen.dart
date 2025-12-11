import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/widgets/verse_card.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class ScriptureScreen extends StatefulWidget {
  const ScriptureScreen({super.key});

  @override
  State<ScriptureScreen> createState() => _ScriptureScreenState();
}

class _ScriptureScreenState extends State<ScriptureScreen> {
  String _selectedCategory = 'all';

  final List<_CategoryDef> _categories = const [
    _CategoryDef(key: 'all', label: 'All', color: GamerColors.accent),
    _CategoryDef(key: 'faith', label: 'Faith', color: GamerColors.neonCyan),
    _CategoryDef(key: 'love', label: 'Love', color: GamerColors.neonPink),
    _CategoryDef(key: 'strength', label: 'Strength', color: GamerColors.neonPurple),
    _CategoryDef(key: 'wisdom', label: 'Wisdom', color: GamerColors.neonGreen),
    _CategoryDef(key: 'courage', label: 'Courage', color: Color(0xFFFFAA00)),
  ];

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider?>(context);

    if (app == null || app.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: GamerColors.accent)),
      );
    }

    final List<VerseModel> verses = app.getVersesByCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text('Scripture', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Open Scripture Quest™ Bible',
            onPressed: () => context.go('/verses'),
            icon: const Icon(Icons.menu_book, color: GamerColors.accent),
          ),
          // Reader settings moved into the Bible Menu on the Verses screen
          const HomeActionButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryChips(context),
          const SizedBox(height: 12),
          Expanded(
            child: verses.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final v = verses[index];
                      return VerseCard(
                        verse: v,
                        onTap: () => context.go('/verse/${v.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: _categories
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _chip(
                    context,
                    text: c.label,
                    color: c.color,
                    selected: _selectedCategory == c.key,
                    onTap: () => setState(() => _selectedCategory = c.key),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String text, required Color color, required bool selected, required VoidCallback onTap}) {
    final bg = selected ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.10);
    final bd = selected ? color.withValues(alpha: 0.55) : color.withValues(alpha: 0.25);
    final fg = selected ? GamerColors.textPrimary : GamerColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bd, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label, size: 14, color: color),
            const SizedBox(width: 6),
            Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No verses in this category yet.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/verses'),
              icon: const Icon(Icons.menu_book, color: GamerColors.accent),
              label: const Text('Open Scripture Quest™ Bible'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDef {
  final String key;
  final String label;
  final Color color;
  const _CategoryDef({required this.key, required this.label, required this.color});
}

// (Old _ReaderSettingsSheet removed; control lives in the Verses → Bible Menu.)
