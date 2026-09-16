import '../theme/scripture_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/streak_indicator.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class ReadingStatsScreen extends StatelessWidget {
  const ReadingStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, app, _) {
      final totalChaptersRead = app.totalChaptersRead;
      final totalBooksCompleted = app.totalBooksCompleted;
      final currentStreak = app.currentBibleStreak;
      final longestStreak = app.longestBibleStreak;

      // Build per-book progress entries (only books with any progress)
      final List<_BookProgress> bookEntries = AppProvider.bookTotalChapters.entries
          .map((e) => _BookProgress(book: e.key, totalChapters: e.value, readChapters: app.chaptersReadForBook(e.key)))
          .where((bp) => bp.readChapters > 0)
          .toList()
        ..sort((a, b) {
          if (b.readChapters != a.readChapters) return b.readChapters.compareTo(a.readChapters);
          return a.book.toLowerCase().compareTo(b.book.toLowerCase());
        });

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: QuestPalette.of(context).textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/you'),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reading Stats', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 2),
              Text('Your Scripture journey so far.', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          actions: [HomeActionButton()],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            // A) SUMMARY SECTION
            _SummaryCard(
              totalChaptersRead: totalChaptersRead,
              totalBooksCompleted: totalBooksCompleted,
              currentStreak: currentStreak,
              longestStreak: longestStreak,
            ),

            SizedBox(height: 12),

            // A.1) QUIZ SUMMARY (secondary stat)
            _QuizSummaryCard(totalCompleted: app.totalCompletedQuizzes),

            SizedBox(height: 18),

            // B) RECENT ACTIVITY (Last 7 Days)
            _RecentActivity(),

            SizedBox(height: 18),

            // C) PER-BOOK PROGRESS
            _PerBookProgressList(entries: bookEntries),
          ],
        ),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalChaptersRead;
  final int totalBooksCompleted;
  final int currentStreak;
  final int longestStreak;

  _SummaryCard({
    required this.totalChaptersRead,
    required this.totalBooksCompleted,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.auto_stories, color: QuestPalette.of(context).accent), SizedBox(width: 8), Text('Summary', style: theme.textTheme.titleLarge)]),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat(icon: Icons.menu_book, label: 'Chapters Read', value: '$totalChaptersRead')),
              SizedBox(width: 8),
              Expanded(child: _MiniStat(icon: Icons.library_add_check, label: 'Books Completed', value: '$totalBooksCompleted')),
            ],
          ),
          SizedBox(height: 14),
          StreakIndicator(streakDays: currentStreak, longestStreak: longestStreak),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: QuestPalette.of(context).accent, size: 18), SizedBox(width: 6), Expanded(child: Text(label, style: Theme.of(context).textTheme.labelSmall))]),
          SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: QuestPalette.of(context).accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuizSummaryCard extends StatelessWidget {
  final int totalCompleted;
  _QuizSummaryCard({required this.totalCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAny = totalCompleted > 0;
    final subtitle = hasAny
        ? 'Short reflections you\'ve finished after reading key chapters'
        : 'Try a short quiz after John 3, Romans 8, Psalm 23, Proverbs 3, or Luke 2.';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: QuestPalette.of(context).accent),
              SizedBox(width: 8),
              Expanded(child: Text('Chapter Learning', style: theme.textTheme.titleLarge)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: QuestPalette.of(context).darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  '$totalCompleted',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: QuestPalette.of(context).accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  _RecentActivity();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final activity = app.getDailyReadingForLastNDays(7);
    final entries = activity.entries.toList(); // ordered oldest -> newest

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.calendar_today, color: QuestPalette.of(context).accent), SizedBox(width: 8), Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge)]),
          SizedBox(height: 12),
          _ActivityBars(entries: entries),
        ],
      ),
    );
  }
}

class _ActivityBars extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  _ActivityBars({required this.entries});

  String _weekdayLabel(DateTime d) {
    // Monday=1 ... Sunday=7
    switch (d.weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }

  DateTime? _parseYmd(String s) {
    try {
      final p = s.split('-');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxChaptersVisual = 5; // cap visual height around 5 chapters
    const maxBarHeight = 56.0;
    const barWidth = 16.0;
    const gap = 10.0;

    return SizedBox(
      height: maxBarHeight + 24, // include labels space
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final e in entries) ...[
            _Bar(
              value: e.value,
              label: _weekdayLabel(_parseYmd(e.key) ?? DateTime.now()),
              maxHeight: maxBarHeight,
              barWidth: barWidth,
              maxVisualUnits: maxChaptersVisual,
            ),
            if (e != entries.last) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final String label;
  final double maxHeight;
  final double barWidth;
  final int maxVisualUnits;
  _Bar({required this.value, required this.label, required this.maxHeight, required this.barWidth, required this.maxVisualUnits});

  @override
  Widget build(BuildContext context) {
    final v = value < 0 ? 0 : value;
    final capped = v > maxVisualUnits ? maxVisualUnits : v;
    final height = (capped / maxVisualUnits) * maxHeight;
    final hasAny = v > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: barWidth,
          height: height < 6 ? 6 : height, // keep a tiny stub even for 0 (very faint)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: hasAny
                ? LinearGradient(colors: [
                    QuestPalette.of(context).neonCyan.withValues(alpha: 0.85),
                    QuestPalette.of(context).neonPurple.withValues(alpha: 0.85),
                  ], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                : null,
            color: hasAny ? null : QuestPalette.of(context).accent.withValues(alpha: 0.08),
            boxShadow: hasAny
                ? [
                    BoxShadow(
                      color: QuestPalette.of(context).neonPurple.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: hasAny ? 0.12 : 0.06), width: 1),
          ),
        ),
        SizedBox(height: 6),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.labelSmall)),
      ],
    );
  }
}

class _PerBookProgressList extends StatelessWidget {
  final List<_BookProgress> entries;
  _PerBookProgressList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.menu_book, color: QuestPalette.of(context).accent), SizedBox(width: 8), Text('Progress by Book', style: Theme.of(context).textTheme.titleLarge)]),
          SizedBox(height: 8),
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('You haven’t started any books yet.', style: Theme.of(context).textTheme.labelMedium),
            )
          else ...[
            SizedBox(height: 6),
            ...entries.map((e) => _BookRow(entry: e)).toList(),
          ],
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final _BookProgress entry;
  _BookRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final pct = entry.totalChapters > 0 ? (entry.readChapters / entry.totalChapters).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QuestPalette.of(context).darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuestPalette.of(context).accent.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.book,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text('${entry.readChapters} / ${entry.totalChapters}', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: QuestPalette.of(context).darkCard),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [QuestPalette.of(context).neonCyan.withValues(alpha: 0.9), QuestPalette.of(context).neonPurple.withValues(alpha: 0.9)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookProgress {
  final String book;
  final int totalChapters;
  final int readChapters;
  _BookProgress({required this.book, required this.totalChapters, required this.readChapters});
}
