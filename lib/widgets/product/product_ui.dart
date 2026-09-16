import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/scripture_theme.dart';

class ProductWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ProductWidth({super.key, required this.child, this.maxWidth = 960});
  @override
  Widget build(BuildContext context) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth), child: child)));
}

class ActivityCard extends StatelessWidget {
  final String title, description, route;
  final IconData icon;
  final bool featured;
  const ActivityCard(
      {super.key,
      required this.title,
      required this.description,
      required this.route,
      required this.icon,
      this.featured = false});
  @override
  Widget build(BuildContext context) {
    final p = QuestPalette.of(context);
    return Card(
        elevation: 0,
        color: p.darkCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: featured
                    ? p.accent
                    : Theme.of(context).colorScheme.outlineVariant)),
        child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(route),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: p.accent.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(icon, color: p.accent, size: 28)),
                        const Spacer(),
                        Icon(Icons.arrow_forward, color: p.accent)
                      ]),
                      const SizedBox(height: 16),
                      Text(title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(description,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ]))));
  }
}

class ActivityShelf extends StatelessWidget {
  final List<Widget> children;
  const ActivityShelf({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, b) {
        final columns = b.maxWidth >= 800
            ? 3
            : b.maxWidth >= 560
                ? 2
                : 1;
        final width = (b.maxWidth - 16 * (columns - 1)) / columns;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final child in children) SizedBox(width: width, child: child)
        ]);
      });
}

class ProgressIdentity extends StatelessWidget {
  final bool linkToAchievements;
  const ProgressIdentity({super.key, this.linkToAchievements = true});
  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>().currentUser;
    if (u == null) return const SizedBox.shrink();
    final p = QuestPalette.of(context);
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
                colors: [p.darkCard, p.accent.withValues(alpha: .14)]),
            border: Border.all(color: p.accent.withValues(alpha: .35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.gold, width: 2)),
                child: Text('${u.currentLevel}',
                    style: Theme.of(context).textTheme.headlineMedium)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('LEVEL ${u.currentLevel}',
                      style: Theme.of(context).textTheme.labelLarge),
                  Text('${u.totalXP} XP earned',
                      style: Theme.of(context).textTheme.titleMedium)
                ]))
          ]),
          const SizedBox(height: 16),
          LinearProgressIndicator(
              value: u.xpProgress.clamp(0, 1),
              minHeight: 7,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          Text('${u.currentXP} / ${u.xpToNextLevel} XP toward your next level'),
          if (linkToAchievements)
            TextButton.icon(
                onPressed: () => context.push('/achievements'),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Explore accomplishments')),
        ]));
  }
}

class AppearanceChoices extends StatelessWidget {
  const AppearanceChoices({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    Future<void> apply(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Appearance could not be saved. Please try again.')));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final id in ScriptureThemes.ids)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<String>(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant)),
                value: id,
                groupValue: settings.questThemeId,
                onChanged: (_) => apply(() => settings.setQuestTheme(id)),
                title: Text(ScriptureThemes.label(id)),
                subtitle: Text(id == ScriptureThemes.scriptureLight
                    ? 'Warm paper, forest green, and quiet gold.'
                    : 'Layered midnight blue, soft teal, and warm gold.'),
                secondary: Icon(id == ScriptureThemes.scriptureLight
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined))),
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use app appearance in the Bible'),
          subtitle: const Text(
              'You can also choose paper, sepia, or night independently in the reader.'),
          value: settings.readerFollowsTheme,
          onChanged: (v) => apply(() => settings.setReaderFollowsTheme(v))),
    ]);
  }
}
