import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/quest.dart' as board;
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class QuestBoardScreen extends StatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  State<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends State<QuestBoardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize and refresh when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      p.ensureQuestsInitialized();
      p.refreshQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final daily = provider.activeQuests.where((q) => q.type == 'daily').toList();
      final weekly = provider.activeQuests.where((q) => q.type == 'weekly').toList();
      final reflection = provider.activeQuests.where((q) => q.type == 'reflection').toList();
      final special = provider.activeQuests.where((q) => q.type == 'special').toList();

      return Scaffold(
        appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text('Task Board', style: Theme.of(context).textTheme.headlineSmall),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: GamerColors.accent),
              onPressed: () => provider.refreshQuests(),
              tooltip: 'Refresh Board',
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: GamerColors.accent),
              onPressed: () => context.push('/quests'),
              tooltip: 'Quests',
            ),
            const HomeActionButton(),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Section(
              title: 'Daily Tasks',
              icon: Icons.today,
              color: GamerColors.accent,
              children: daily.isEmpty
                  ? [
                      _emptyTile('No daily quests right now. Check back soon!'),
                    ]
                  : daily.map((q) => _QuestCard(quest: q)).toList(),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Weekly Tasks',
              icon: Icons.date_range,
              color: GamerColors.neonPurple,
              children: weekly.isEmpty
                  ? [
                      _emptyTile('No weekly challenge found.'),
                    ]
                  : weekly.map((q) => _QuestCard(quest: q)).toList(),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Reflection Tasks',
              icon: Icons.edit_note,
              color: GamerColors.neonCyan,
              children: reflection.isEmpty
                  ? [
                      _emptyTile('No reflection quest yet.'),
                    ]
                  : reflection.map((q) => _QuestCard(quest: q)).toList(),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Special Events',
              icon: Icons.local_activity,
              color: GamerColors.success,
              children: special.isEmpty
                  ? [
                      _emptyTile('No special events right now.'),
                    ]
                  : special.map((q) => _QuestCard(quest: q)).toList(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => context.push('/tasks/completed'),
                icon: const Icon(Icons.checklist, color: GamerColors.accent, size: 18),
                label: const Text('Completed'),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => context.push('/quests'),
                icon: const Icon(Icons.auto_awesome, color: GamerColors.accent, size: 18),
                label: const Text('Quests'),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyTile(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        ...children
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  final board.Quest quest;
  const _QuestCard({required this.quest});

  IconData _iconForType(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'reflection':
        return Icons.edit_note;
      case 'special':
      default:
        return Icons.local_activity;
    }
  }

  String _expiryText(board.Quest q) {
    if (q.expiresAt == null) return '';
    final dt = q.expiresAt!;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return 'Expires: $y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final ratio = quest.progressPercent;
    final isExpired = quest.isExpired;
    final isCompleted = quest.isCompleted;
    final canProgress = !isCompleted && !isExpired && quest.progress < quest.goal;
    final canComplete = !isCompleted && !isExpired && quest.progress >= quest.goal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (quest.isCompleted
                  ? GamerColors.success
                  : isExpired
                      ? GamerColors.danger
                      : GamerColors.accent)
              .withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconForType(quest.type), color: GamerColors.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(quest.description, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GamerColors.darkSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: GamerColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text('+${quest.xpReward} XP', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth * ratio;
                return Stack(
                  children: [
                    Container(height: 10, color: GamerColors.darkSurface),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 10,
                      width: barWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          GamerColors.neonCyan.withValues(alpha: 0.9),
                          GamerColors.neonPurple.withValues(alpha: 0.9),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${quest.progress}/${quest.goal}', style: Theme.of(context).textTheme.labelSmall),
              if (quest.expiresAt != null)
                Text(_expiryText(quest), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
              child: OutlinedButton.icon(
              onPressed: canComplete ? () => provider.completeQuest(quest.id) : null,
              icon: const Icon(Icons.check_circle, color: GamerColors.accent),
              label: const Text('Complete Task'),
            ),
          ),
        ],
      ),
    );
  }
}
