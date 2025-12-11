import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/utils/memorization_defaults.dart';

class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  // 0=All, 1=Learning, 2=Mastered
  int filter = 0;

  String _statusLabel(MemorizationStatus s) {
    switch (s) {
      case MemorizationStatus.learned:
        return 'Mastered';
      case MemorizationStatus.practicing:
      case MemorizationStatus.newItem:
      default:
        return 'Learning';
    }
  }

  Color _statusColor(MemorizationStatus s) {
    switch (s) {
      case MemorizationStatus.learned:
        return GamerColors.success;
      case MemorizationStatus.practicing:
      case MemorizationStatus.newItem:
      default:
        return GamerColors.neonCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final favs = app.favoriteVerseKeys;
      final usingDefaults = favs.isEmpty;
      final allKeys = usingDefaults ? MemorizationDefaults.curatedKeys : favs;
      List<String> filtered = allKeys;
      if (filter == 1) {
        filtered = allKeys.where((k) => app.getMemorizationStatus(k) != MemorizationStatus.learned).toList();
      } else if (filter == 2) {
        filtered = allKeys.where((k) => app.getMemorizationStatus(k) == MemorizationStatus.learned).toList();
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('Memorization', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                  onPressed: () => context.pop(),
                )
              : null,
          actions: const [HomeActionButton()],
        ),
        body: Column(
                children: [
                  if (usingDefaults)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MemorizationDefaults.hintTitle,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            MemorizationDefaults.hintBody,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  // Filters
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: filter == 0,
                          onSelected: (_) => setState(() => filter = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Learning'),
                          selected: filter == 1,
                          onSelected: (_) => setState(() => filter = 1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Mastered'),
                          selected: filter == 2,
                          onSelected: (_) => setState(() => filter = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final keyStr = filtered[idx];
                        final parts = keyStr.split(':');
                        final ref = (parts.length == 3) ? '${parts[0]} ${parts[1]}:${parts[2]}' : keyStr;
                        final status = app.getMemorizationStatus(keyStr);
                        final count = app.getMemorizationPracticeCount(keyStr);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: GamerColors.darkCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GamerColors.accent.withValues(alpha: 0.22), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.psychology_alt, color: GamerColors.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ref, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 6),
                                    FutureBuilder<String>(
                                      future: context.read<AppProvider>().loadKjvPassage(ref),
                                      builder: (context, snap) {
                                        final text = (snap.data ?? '').split('\n');
                                        final body = text.length > 1 ? text[1] : (snap.data ?? '');
                                        final snippet = body.trim().isEmpty ? '' : (body.trim().length > 90 ? body.trim().substring(0, 90) + '…' : body.trim());
                                        return Text(
                                          snippet.isEmpty ? ' ' : snippet,
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: _statusColor(status).withValues(alpha: 0.5), width: 1),
                                          ),
                                          child: Text(_statusLabel(status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _statusColor(status), fontWeight: FontWeight.w700)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Streak $count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/memorization-practice?key=${Uri.encodeComponent(keyStr)}'),
                                icon: const Icon(Icons.play_arrow, color: GamerColors.darkBackground),
                                label: const Text('Train'),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      );
    });
  }
}
