import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/utils/memorization_defaults.dart';

class MemorizationPracticeScreen extends StatefulWidget {
  final String verseKey; // expected DisplayBook:Chapter:Verse
  const MemorizationPracticeScreen({super.key, required this.verseKey});

  @override
  State<MemorizationPracticeScreen> createState() => _MemorizationPracticeScreenState();
}

class _MemorizationPracticeScreenState extends State<MemorizationPracticeScreen> {
  // Step 0: Study, Step 1: Recall, Step 2: Result
  int step = 0;
  String? verseText; // body only
  String? refLabel;
  bool loading = true;
  bool remembered = false; // result flag

  @override
  void initState() {
    super.initState();
    _load();
  }

  (String ref, String book, int ch, int v)? _parse() {
    try {
      final parts = widget.verseKey.split(':');
      if (parts.length != 3) return null;
      final book = parts[0];
      final ch = int.tryParse(parts[1]) ?? 0;
      final v = int.tryParse(parts[2]) ?? 0;
      if (book.trim().isEmpty || ch <= 0 || v <= 0) return null;
      final ref = '$book $ch:$v';
      return (ref, book, ch, v);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final parsed = _parse();
    if (parsed == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final app = context.read<AppProvider>();
    final ref = parsed.$1;
    final t = await app.loadKjvPassage(ref);
    final lines = t.split('\n');
    setState(() {
      refLabel = ref;
      verseText = (lines.length > 1 ? lines[1] : t).trim();
      loading = false;
      step = 0;
    });
  }

  String _masked(String s) {
    // Replace letters/digits with •, keep spaces and punctuation
    return s.replaceAll(RegExp(r'[A-Za-z0-9]'), '•');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final status = app.getMemorizationStatus(widget.verseKey);
    final learned = status == MemorizationStatus.learned;
    return Scaffold(
      appBar: AppBar(
        title: Text('Memorization Practice', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                onPressed: () => context.pop(),
              )
            : null,
        actions: const [HomeActionButton()],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: GamerColors.accent))
          : (verseText == null || refLabel == null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: GamerColors.danger),
                        const SizedBox(height: 8),
                        Text('This verse could not be loaded.', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, color: GamerColors.darkBackground),
                          label: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gentle hint only when using default curated set (no favorites yet)
                      Builder(builder: (context) {
                        final app = context.read<AppProvider>();
                        final usingDefaults = app.favoriteVerseKeys.isEmpty && MemorizationDefaults.isCuratedKey(widget.verseKey);
                        if (!usingDefaults) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                        );
                      }),
                      Row(
                        children: [
                          const Icon(Icons.menu_book, color: GamerColors.accent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(refLabel!, style: Theme.of(context).textTheme.titleLarge)),
                          if (learned)
                            Row(children: [
                              const Icon(Icons.check_circle, color: GamerColors.success, size: 18),
                              const SizedBox(width: 6),
                              Text('Mastered', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: GamerColors.success)),
                            ]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (step == 0) ...[
                        Text('Step 1 — Read slowly', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Text(verseText!, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.6)),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => step = 1),
                            icon: const Icon(Icons.arrow_forward, color: GamerColors.darkBackground),
                            label: const Text('Next'),
                          ),
                        ),
                      ] else if (step == 1) ...[
                        Text('Step 2 — Recall from memory', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Text(_masked(verseText!), style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.6)),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await context.read<AppProvider>().recordMemorizationFailure(widget.verseKey);
                                  if (!mounted) return;
                                  setState(() {
                                    remembered = false;
                                    step = 2;
                                  });
                                },
                                icon: const Icon(Icons.close, color: GamerColors.accent),
                                label: const Text('Not yet'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final xp = await context.read<AppProvider>().recordMemorizationSuccess(widget.verseKey);
                                  if (!mounted) return;
                                  setState(() {
                                    remembered = true;
                                    step = 2;
                                  });
                                  // Reward toast
                                  final subtitle = xp > 0 ? '+$xp XP' : null;
                                  RewardToast.showSuccess(context, title: 'Memorization saved!', subtitle: subtitle);
                                },
                                icon: const Icon(Icons.check, color: GamerColors.darkBackground),
                                label: const Text("I remembered it"),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Result state
                        Row(
                          children: [
                            Icon(remembered ? Icons.check_circle : Icons.hourglass_bottom, color: remembered ? GamerColors.success : GamerColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              remembered ? 'Great job — keep building your streak.' : 'Saved. Try again tomorrow, slowly and prayerfully.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, color: GamerColors.darkBackground),
                          label: const Text('Done'),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => setState(() => step = 0),
                          child: const Text('Start another round'),
                        )
                      ],
                    ],
                  ),
                ),
    );
  }
}
