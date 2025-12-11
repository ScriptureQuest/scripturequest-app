import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';
import 'package:level_up_your_faith/services/bible_rendering_service.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class VerseDetailScreen extends StatelessWidget {
  final String verseId;

  const VerseDetailScreen({super.key, required this.verseId});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'faith':
        return GamerColors.neonCyan;
      case 'love':
        return GamerColors.neonPink;
      case 'strength':
        return GamerColors.neonPurple;
      case 'wisdom':
        return GamerColors.neonGreen;
      case 'courage':
        return const Color(0xFFFFAA00);
      default:
        return GamerColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final verse = provider.verses.firstWhere((v) => v.id == verseId, orElse: () => provider.verses.first);
        final categoryColor = _getCategoryColor(verse.category);
        final settings = context.watch<SettingsProvider>();
        final fontScale = settings.bibleFontScale;
        final themeData = BibleReaderStyles.themeFor(settings.bibleReaderTheme);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: GamerColors.darkSurface, // Ensure contrast against neon background
            elevation: 0,
            title: const Text(''),
            // Always render a visible back button; if the stack cannot pop (ShellRoute root),
            // fall back to a sensible route in the Bible flow.
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/verses');
                }
              },
            ),
            actions: const [HomeActionButton()],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    verse.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: categoryColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                Text(verse.reference, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: categoryColor)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BibleReaderStyles
                      .paperBackgroundDecoration(themeData)
                      .copyWith(
                        border: Border.all(color: categoryColor.withValues(alpha: 0.2), width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                  child: Builder(builder: (context) {
                    // Render verse text through global renderer so red-letter rules apply
                    return RichText(
                      text: TextSpan(
                        children: [
                          // Entire verse body is styled; verse number is not displayed on this screen
                          BibleRenderingService.buildVerseSpan(
                            context,
                            reference: verse.reference,
                            text: verse.text,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                if (!verse.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await provider.completeVerse(verseId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✨ +${verse.xpReward} XP earned!'),
                              backgroundColor: GamerColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: categoryColor,
                        foregroundColor: GamerColors.darkBackground,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 24),
                          const SizedBox(width: 12),
                          Text('COMPLETE (+${verse.xpReward} XP)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: GamerColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GamerColors.success.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: GamerColors.success, size: 28),
                        const SizedBox(width: 12),
                        Text('COMPLETED', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: GamerColors.success)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Personal Notes', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GamerColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
                  ),
                  child: TextField(
                    maxLines: 5,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts about this verse...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GamerColors.textTertiary),
                      border: InputBorder.none,
                    ),
                    controller: TextEditingController(text: verse.notes),
                    onChanged: (value) {
                      provider.verseService.saveNote(verseId, value);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
