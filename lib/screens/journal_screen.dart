import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/journal/journal_editor_sheet.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool _loaded = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  static const List<String> _tagFilters = <String>['All', 'Prayer', 'Gratitude', 'Study', 'Sermon', 'Notes'];
  String _activeTag = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadJournalEntries();
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final all = provider.journalEntries;
      final filtered = _applyFilters(all);

      return Scaffold(
        appBar: AppBar(
          title: Text('Scripture Quest™ Journal', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'New Entry',
              icon: const Icon(Icons.note_add),
              onPressed: () => _openEditor(context),
            ),
            const HomeActionButton(),
          ],
        ),
        body: FadeSlideIn(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 10),
              _buildTagChips(context),
              const SizedBox(height: 10),
              Expanded(
                child: all.isEmpty
                    ? const EmptyState(message: 'No entries yet. Begin your story with God.')
                    : filtered.isEmpty
                        ? _buildFilteredEmptyState(context)
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final entry = filtered[index];
                              return _JournalCard(entry: entry);
                            },
                          ),
              ),
            ],
          ),
        ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.note_add),
          label: const Text('New Entry'),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) => const EmptyState(message: 'No entries yet. Begin your story with God.');

  Future<void> _openEditor(BuildContext context, {JournalEntry? entry}) async {
    // Signal toast system to avoid bottom placement while sheet is open
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return JournalEditorSheet(entry: entry);
      },
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  List<JournalEntry> _applyFilters(List<JournalEntry> all) {
    try {
      final q = _query.trim().toLowerCase();
      final tag = _activeTag;
      Iterable<JournalEntry> list = all;
      if (q.isNotEmpty) {
        list = list.where((e) {
          final t = (e.title ?? '').toLowerCase();
          final b = e.reflectionText.toLowerCase();
          return t.contains(q) || b.contains(q);
        });
      }
      if (tag != 'All') {
        list = list.where((e) => e.tags.map((s) => s.toLowerCase()).contains(tag.toLowerCase()));
      }
      final items = list.toList();
      // Sort: pinned first, then newest-first within groups
      items.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    } catch (e) {
      debugPrint('journal filter error: $e');
      return all;
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Search your journal…',
        prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildTagChips(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tagFilters.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = _tagFilters[index];
          final selected = _activeTag == t;
          return ChoiceChip(
            label: Text(t),
            selected: selected,
            onSelected: (_) => setState(() => _activeTag = t),
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: selected ? cs.onPrimary : theme.textTheme.labelSmall?.color,
            ),
            selectedColor: cs.primary,
            backgroundColor: cs.surfaceContainerHighest,
            side: BorderSide(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.25)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }

  Widget _buildFilteredEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('No entries match your search yet.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Try a different term or tag.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = _resolveTitle(entry);
    final preview = _resolvePreview(entry);
    return GestureDetector(
      onTap: () => _openEditorSheet(context, entry: entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (entry.isPinned) ...[
                  Icon(Icons.push_pin, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ],
            ),
            if (preview != null) ...[
              const SizedBox(height: 6),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if ((entry.linkedRef ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _linkChip(context, entry),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(_formatDate(entry.createdAt), style: theme.textTheme.labelMedium),
                const SizedBox(width: 12),
                if (entry.tags.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.tags.map((t) => _chip(context, t, cs.primary)).toList(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _linkChip(BuildContext context, JournalEntry e) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ref = e.linkedRef!.trim();
    final route = (e.linkedRefRoute ?? '/verses?ref=${Uri.encodeComponent(ref)}').trim();
    return InkWell(
      onTap: () {
        if (route.isNotEmpty) context.push(route);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(ref, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  String _resolveTitle(JournalEntry e) {
    if ((e.title ?? '').trim().isNotEmpty) return e.title!.trim();
    if ((e.questTitle ?? '').trim().isNotEmpty) return e.questTitle!.trim();
    final raw = e.reflectionText.trim();
    if (raw.isEmpty) return 'Untitled Entry';
    if (raw.length <= 48) return raw;
    return raw.substring(0, 48).trimRight() + '…';
  }

  // Returns a single-line preview of the body text, or null if empty.
  String? _resolvePreview(JournalEntry e) {
    final raw = e.reflectionText;
    if (raw.trim().isEmpty) return null;
    // Collapse newlines and excess whitespace into single spaces
    final collapsed = raw.replaceAll(RegExp(r"\s+"), ' ').trim();
    const maxLen = 96; // Truncation length chosen for balanced readability
    if (collapsed.length <= maxLen) return collapsed;
    return collapsed.substring(0, maxLen).trimRight() + '…';
  }

  Future<void> _openEditorSheet(BuildContext context, {required JournalEntry entry}) async {
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalEditorSheet(entry: entry),
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = months[dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }
}

String _formatDate(DateTime dt) {
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final m = months[dt.month - 1];
  return '$m ${dt.day}, ${dt.year}';
}
