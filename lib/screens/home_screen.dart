import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/task_card.dart';
import 'package:level_up_your_faith/models/user_model.dart';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/widgets/journal/journal_editor_sheet.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loadedJournal = false;
  bool _onboardingChecked = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedJournal) {
      final provider = Provider.of<AppProvider?>(context, listen: false);
      // Guard against calling before AppProvider.initialize() wires services.
      if (provider != null && provider.isInitialized) {
        provider.loadJournalEntries();
        _loadedJournal = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: build start');
    final appProvider = Provider.of<AppProvider?>(context, listen: true);

    // If the provider isn't mounted yet, show a lightweight loading UI
    if (appProvider == null || (appProvider.isLoading)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: GamerColors.accent)),
      );
    }

    final user = appProvider.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Error loading user')));
    }

    // Redirect to onboarding on first app open
    if (!_onboardingChecked && appProvider.shouldShowOnboarding) {
      _onboardingChecked = true;
      // push replacement to onboarding after first frame to avoid build-cycle nav
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/onboarding');
      });
    }

    // Welcome Back logic — evaluate before we touch lastOpenedAt
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final showWelcomeBanner = appProvider.shouldShowWelcomeBackBanner(todayOnly);
    // Persist welcome-shown (if applicable) and always refresh lastOpenedAt after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (showWelcomeBanner) {
          await appProvider.markWelcomeBackShown(todayOnly);
        }
        await appProvider.updateLastOpenedNow();
      } catch (_) {}
    });

    // Verse of the Day: gets today's verse (rotates daily, stable within the day)
    final votdRef = appProvider.getVerseOfTheDay();
    String featuredRef = votdRef;
    String featuredText = 'For God so loved the world that he gave his one and only Son...'; // fallback
    
    // Try to find the full verse text from available verses
    if (appProvider.verses.isNotEmpty) {
      try {
        final verse = appProvider.verses.firstWhere((v) => v.reference == votdRef);
        featuredText = verse.text.isNotEmpty ? verse.text : featuredText;
      } catch (_) {
        // Verse not found in local collection, use fallback text
        // Could also load from Bible service if needed
      }
    }

    final latestEntry = appProvider.journalEntries.isNotEmpty ? appProvider.journalEntries.first : null;

    final showOnboardingWelcome = appProvider.consumeOnboardingWelcomeFlag();

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional onboarding welcome banner (kept, but lighter touch)
            if (showOnboardingWelcome) ...[
              _SectionFadeSlide(delayMs: 20, child: _onboardingWelcomeBanner(context)),
              const SizedBox(height: 12),
            ],

            // 1) Hero Greeting / Header
            _SectionFadeSlide(delayMs: 0, child: _heroHeaderCard(context, user)),
            const SizedBox(height: 16),

            // 1a) Streak Card (only show if streak >= 1)
            if (appProvider.currentBibleStreak >= 1) ...[
              _SectionFadeSlide(delayMs: 30, child: _streakCard(context, appProvider)),
              const SizedBox(height: 16),
            ],

            // 1b) Today's Verse (featured) — placed before Today's Tasks
            const SectionHeader('Today\'s Verse', icon: Icons.menu_book_outlined),
            _SectionFadeSlide(
              delayMs: 40,
              child: _featuredVerseCard(context, featuredRef, featuredText),
            ),
            const SizedBox(height: 20),

            // 2) Today’s Tasks
            const SectionHeader('Today\'s Tasks', icon: Icons.check_circle_outline),
            _SectionFadeSlide(delayMs: 80, child: _todaysTasksSummaryCard(context, appProvider)),
            const SizedBox(height: 20),

            // 3) Continue Reading
            const SectionHeader('Continue Reading', icon: Icons.menu_book_outlined),
            _SectionFadeSlide(delayMs: 120, child: _continueReadingCard(context, appProvider, featuredRef: featuredRef)),
            const SizedBox(height: 20),

            // 4) Your Journey
            const SectionHeader('Your Journey', icon: Icons.explore_outlined),
            _SectionFadeSlide(delayMs: 160, child: _yourJourneyTiles(context)),
            const SizedBox(height: 20),

            // Memorization teaser removed to keep Home uncluttered; access via Play & Learn hub
          ],
        ),
      ),
    );
    debugPrint('HomeScreen: build end');
    return scaffold;
  }

  // ===================== Sections =====================
  bool _shouldShowGuidedStart(AppProvider app) {
    final allDone = app.hasCompletedFirstReading && app.hasCompletedFirstJournal && app.hasVisitedQuestlines;
    return !app.hasSeenGuidedStart || !allDone;
  }

  Widget _guidedStartCard(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final visible = _shouldShowGuidedStart(app);

    // When first becomes visible, mark as seen
    if (visible && !app.hasSeenGuidedStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => app.markGuidedStartSeen());
    }

    if (!visible) return const SizedBox.shrink();

    final step1Done = app.hasCompletedFirstReading;
    final step2Done = app.hasCompletedFirstJournal;
    final step3Done = app.hasVisitedQuestlines;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.flag, color: GamerColors.accent),
            const SizedBox(width: 8),
            Text('Start your journey', style: theme.textTheme.titleLarge),
          ]),
          const SizedBox(height: 6),
          Text('Try this simple rhythm: read a passage, write one thought, explore a quest.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _guidedStepRow(
            context,
            done: step1Done,
            index: 1,
            label: 'Read a passage',
            buttonLabel: 'Open Bible',
            icon: Icons.menu_book,
            onPressed: () async {
              final ref = Uri.encodeComponent('John 1');
              context.go('/verses?ref=$ref');
              await app.markFirstReadingDone();
            },
          ),
          const SizedBox(height: 8),
          _guidedStepRow(
            context,
            done: step2Done,
            index: 2,
            label: 'Write one thought',
            buttonLabel: 'Open Journal',
            icon: Icons.edit_note,
            onPressed: () async {
              RewardToast.setBottomSheetOpen(true);
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) {
                  return const JournalEditorSheet();
                },
              );
              RewardToast.setBottomSheetOpen(false);
            },
          ),
          const SizedBox(height: 8),
          _guidedStepRow(
            context,
            done: step3Done,
            index: 3,
            label: 'Explore a quest',
            buttonLabel: 'Browse Quests',
            icon: Icons.explore,
            onPressed: () async {
              context.push('/quests');
              await app.markQuestlinesVisited();
            },
          ),
          if (step1Done && step2Done && step3Done) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.check_circle, color: cs.primary, size: 18),
              const SizedBox(width: 6),
              Text("You're all set!", style: theme.textTheme.labelMedium),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _guidedStepRow(
    BuildContext context, {
    required bool done,
    required int index,
    required String label,
    required String buttonLabel,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? cs.primary : GamerColors.textTertiary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('$index. $label', style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: done ? null : onPressed,
          icon: Icon(icon, color: done ? GamerColors.textSecondary : cs.primary),
          label: Text(buttonLabel),
        ),
      ],
    );
  }

  // ===================== Welcome Back Banner =====================
  Widget _onboardingWelcomeBanner(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = Provider.of<AppProvider?>(context, listen: false);
    final user = app?.currentUser;
    final name = ((user?.username ?? '').trim());
    final headline = name.isNotEmpty ? 'Welcome, $name' : 'Welcome!';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, color: GamerColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text("Your first quest and tasks are ready.", style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: () => context.push('/quests'), child: const Text('Open Quests')),
        ],
      ),
    );
  }

  Widget _welcomeBackBanner(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final active = app.getActiveQuest();
    final next = active == null ? null : app.getNextStepForQuest(active.questline.id);

    String subtitle;
    if (active != null && next != null) {
      subtitle = "Let's continue your quest: ${active.questline.title}.";
    } else if (app.currentBibleStreak >= 3) {
      subtitle = "You've been here ${app.currentBibleStreak} days in a row. Keep going.";
    } else {
      subtitle = "Ready for tonight's journey?";
    }

    void onTap() {
      if (active != null && next != null) {
        context.push('/quest/${active.questline.id}');
      } else {
        final ref = app.lastBibleReference ?? 'John 1';
        final encoded = Uri.encodeComponent(ref);
        context.go('/verses?ref=$encoded');
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: GamerColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: GamerColors.textSecondary),
          ],
        ),
      ),
    );
  }
  

  // ===================== New Home Sections (Calm Hub) =====================
  Widget _heroHeaderCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final raw = (user.username).trim();
    final title = raw.isNotEmpty ? 'Welcome back, $raw' : 'Welcome back, Warrior';
    return SacredCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  "Let's take one more step today.",
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final streak = app.currentBibleStreak;
    return SacredCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GamerColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GamerColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.local_fire_department, color: GamerColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak: $streak ${streak == 1 ? 'day' : 'days'}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Don\'t break it—complete today\'s reading.',
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todaysTasksSummaryCard(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    int remainingDaily = 0;
    int remainingNightly = 0;
    try {
      remainingDaily = app.getDailyTasksForToday().where((q) => !q.isCompleted && !q.isExpired).length;
      remainingNightly = app.getNightlyTasksForToday().where((q) => !q.isCompleted && !q.isExpired).length;
    } catch (e) {
      debugPrint('Home: tasks count error: $e');
    }
    final total = remainingDaily + remainingNightly;
    final message = total > 0 ? '$total tasks waiting for you.' : 'Check your Daily & Nightly Tasks.';
    return SacredCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.checklist_rtl, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily and Nightly tasks help you build rhythm.',
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context.push('/tasks'),
            icon: Icon(Icons.open_in_new, color: cs.onPrimary),
            label: const Text('Open Tasks'),
          ),
        ],
      ),
    );
  }

  Widget _continueReadingCard(BuildContext context, AppProvider app, {required String featuredRef}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final last = (app.lastBibleReference ?? '').trim();
    final ref = last.isNotEmpty ? last : (featuredRef.isNotEmpty ? featuredRef : 'John 1');

    String _friendlyTitle(String r) {
      try {
        if (r.contains(':')) {
          final base = r.split(':').first;
          return base;
        }
        return r;
      } catch (_) {
        return r;
      }
    }
    final title = _friendlyTitle(ref);

    return SacredCard(
      onTap: () {
        final encoded = Uri.encodeComponent(ref);
        context.go('/verses?ref=$encoded');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.menu_book, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue in $title', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Tap to return to your last reading spot.',
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _yourJourneyTiles(BuildContext context) {
    return Column(
      children: [
        _smallActionCard(
          context,
          icon: Icons.explore_outlined,
          title: 'Quests',
          subtitle: 'Follow guided journeys.',
          onTap: () => context.push('/quests'),
        ),
        const SizedBox(height: 12),
        _smallActionCard(
          context,
          icon: Icons.menu_book_outlined,
          title: 'Reading Plans',
          subtitle: 'Explore reading plans.',
          onTap: () => context.push('/reading-plans'),
        ),
        const SizedBox(height: 12),
        _smallActionCard(
          context,
          icon: Icons.extension_outlined,
          title: 'Play & Learn',
          subtitle: 'Play games to grow.',
          onTap: () => context.push('/play-learn'),
        ),
      ],
    );
  }

  Widget _smallActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SacredCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  

  Widget _todayReadingPlanCard(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plan = app.activeReadingPlan;
    if (plan == null) return const SizedBox.shrink();
    final pct = app.getPlanProgressPercent();
    final step = app.getCurrentPlanStep();
    final completed = step == null;
    String todayShortLabel = completed ? 'All readings complete' : _todayLabel(step);
    final daysDone = plan.days.where((s) => app.isPlanStepCompleted(plan, s.stepIndex)).length;
    final daysLabel = '$daysDone / ${plan.totalDays} days complete';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(plan.title, style: theme.textTheme.titleMedium)),
              Text('${(pct * 100).round()}%', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Today: $todayShortLabel', style: theme.textTheme.bodyMedium)),
              if (completed) Icon(Icons.check_circle, color: cs.primary, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(daysLabel, style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Row(children: [
            ElevatedButton.icon(
              onPressed: completed
                  ? null
                  : () {
                      final ref = app.getFirstUnreadReferenceForCurrentStep();
                      if (ref != null) {
                        final encoded = Uri.encodeComponent(ref);
                        context.go('/verses?ref=$encoded');
                      }
                    },
              icon: Icon(Icons.play_arrow, color: cs.onPrimary),
              label: const Text('Continue reading'),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => context.push('/reading-plans'), child: const Text('Open Plans')),
          ]),
        ],
      ),
    );
  }

  // Small helper to condense a step's references to a short label
  String _todayLabel(dynamic step) {
    try {
      if (step == null) return 'All readings complete';
      final refs = (step.referenceList as List).cast<String>();
      if (refs.isEmpty) return '(Rest)';
      final first = refs.first;
      final last = refs.last;
      String bookA = first.split(' ').first;
      String bookB = last.split(' ').first;
      int? chA = int.tryParse(first.split(' ').last);
      int? chB = int.tryParse(last.split(' ').last);
      if (bookA == bookB && chA != null && chB != null && refs.length > 1) {
        return '$bookA $chA–$chB';
      }
      if (refs.length == 1) return refs.first;
      return refs.take(2).join(', ');
    } catch (_) {
      // Fallback to friendly label if shape changes
      try {
        return (step.friendlyLabel as String);
      } catch (_) {
        return 'Today\'s reading';
      }
    }
  }

  Widget _featuredVerseCard(BuildContext context, String reference, String snippet) {
    return GestureDetector(
      onTap: () {
        final focus = _extractVerseNumber(reference);
        final uri = Uri(path: '/verses', queryParameters: {
          'ref': reference,
          if (focus != null) 'focus': '$focus',
        });
        context.go(uri.toString());
      },
      child: _VerseCardDecor(
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiet subtitle
                  Text("Today's Verse", style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Text(reference, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: GamerColors.neonCyan)),
                  const SizedBox(height: 12),
                  Text(
                    snippet,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Gentle top gradient overlay (sacred purple -> transparent)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        GamerColors.neonPurple.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _extractVerseNumber(String reference) {
    try {
      final m = RegExp(r':(\d+)').firstMatch(reference);
      if (m != null) return int.tryParse(m.group(1) ?? '');
      return null;
    } catch (_) {
      return null;
    }
  }

  // ===================== Tonight's Quest =====================
  Widget _tonightsQuestCard(BuildContext context, AppProvider app) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final active = app.getActiveQuest();
    if (active == null) {
      return _QuestGlow(
        active: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GamerColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.nights_stay, color: GamerColors.accent),
                const SizedBox(width: 8),
                Text('Begin a Quest', style: theme.textTheme.titleLarge),
              ]),
              const SizedBox(height: 6),
              Text('Start a guided journey through Scripture.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/quests'),
                style: ElevatedButton.styleFrom(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: Icon(Icons.explore, color: cs.onPrimary),
                label: const Text('Browse Quests'),
              ),
            ],
          ),
        ),
      );
    }

    final ql = active.questline;
    final total = active.totalSteps;
    final done = active.completedSteps;
    final next = app.getNextStepForQuest(ql.id);
    if (next == null) {
      // Fallback: treat as empty
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: GamerColors.accent),
              const SizedBox(width: 8),
              Text("Tonight's Quest", style: theme.textTheme.titleLarge),
            ]),
            const SizedBox(height: 6),
            Text('You finished your current quest. Browse more to continue.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/quests'),
              icon: Icon(Icons.explore, color: cs.onPrimary),
              label: const Text('Browse Quests'),
            ),
          ],
        ),
      );
    }

    final meta = _parseQuestTemplate(next.questId);
    final stepTitle = next.titleOverride ?? _deriveQuestStepTitle(next);
    final pct = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return _QuestGlow(
      active: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.nights_stay, color: GamerColors.accent),
                const SizedBox(width: 8),
                Expanded(child: Text("Tonight's Quest", style: theme.textTheme.titleLarge)),
                if ((ql.themeTag ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: GamerColors.darkSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: GamerColors.neonPurple.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Text(ql.themeTag!, style: theme.textTheme.labelSmall),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(ql.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: GamerColors.textTertiary.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(GamerColors.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text('Step ${done + 1} of $total', style: theme.textTheme.labelSmall),
            const SizedBox(height: 10),
            Text(stepTitle, style: theme.textTheme.bodyLarge),
            if ((meta['ref'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 14, color: GamerColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(meta['ref'] as String, style: theme.textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_primaryIconFor(meta['type'] as String), color: cs.onPrimary),
                    label: const Text('Do this step'),
                    onPressed: () async {
                    final type = meta['type'] as String;
                    final appProv = context.read<AppProvider>();
                    if (type == 'read' || type == 'readChapter') {
                      final ref = meta['ref'] as String;
                      if (ref.isNotEmpty) {
                        // Integrity guardrail: record that passage was opened
                        appProv.recordQuestStepInteraction(ql.id, next.id, 'readOpened');
                        final encoded = Uri.encodeComponent(ref);
                        if (context.mounted) context.go('/verses?ref=$encoded');
                      } else {
                        if (context.mounted) context.push('/quest/${ql.id}');
                      }
                    } else if (type == 'reflection') {
                      RewardToast.setBottomSheetOpen(true);
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) {
                          return JournalEditorSheet(
                            initialTitle: 'Reflection — ${ql.title}',
                            initialBody: (next.descriptionOverride ?? '').isNotEmpty
                                ? next.descriptionOverride!
                                : 'What did God highlight to you?',
                            initialTags: const ['Quest'],
                            // Pass quest context so saving auto-completes the step
                            questlineId: ql.id,
                            stepId: next.id,
                          );
                        },
                      );
                      RewardToast.setBottomSheetOpen(false);
                    } else if (type == 'memorize') {
                      // Integrity guardrail: record memorization opened
                      appProv.recordQuestStepInteraction(ql.id, next.id, 'memorizeOpened');
                      if (context.mounted) context.push('/memorization');
                    } else if (type == 'pray') {
                      // Quiet prayer flow and auto-complete on Amen
                      appProv.recordQuestStepInteraction(ql.id, next.id, 'prayerOpened');
                      await _openPrayerGuide(context, title: ql.title, onDone: () async {
                        await context.read<AppProvider>().markQuestlineStepDone(ql.id, next.id, stepXp: 25);
                        if (mounted) RewardToast.showSuccess(context, title: 'Well done on completing your quest!', subtitle: '+25 XP');
                      });
                    } else {
                      if (context.mounted) context.push('/quest/${ql.id}');
                    }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => context.push('/quest/${ql.id}'),
                  child: const Text('View full Quest'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (meta['type'] == 'read' || meta['type'] == 'readChapter')
              Text('Mark as done from the Quest screen.', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  IconData _primaryIconFor(String type) {
    switch (type) {
      case 'read':
      case 'readChapter':
        return Icons.play_arrow;
      case 'reflection':
        return Icons.edit_note;
      case 'memorize':
        return Icons.psychology_alt;
      default:
        return Icons.play_arrow;
    }
  }

  String _deriveQuestStepTitle(dynamic s) {
    // Accept QuestlineStep or compatible object with questId/titleOverride
    try {
      final String questId = (s.questId as String);
      final String? override = (s.titleOverride as String?);
      if (override != null && override.trim().isNotEmpty) return override;
      if (questId.startsWith('tpl:')) {
        final parts = questId.split(':');
        final kind = parts.length > 1 ? parts[1] : '';
        final payload = parts.length > 2 ? questId.substring('tpl:$kind:'.length) : '';
        switch (kind) {
          case 'read':
          case 'readChapter':
            return 'Read $payload';
          case 'reflection':
            return 'Write a Reflection';
          case 'memorize':
            return payload.isNotEmpty ? 'Memorize $payload' : 'Memorize a verse';
        }
      }
      return 'Quest Step';
    } catch (_) {
      return 'Quest Step';
    }
  }

  Map<String, String> _parseQuestTemplate(String questId) {
    try {
      if (!questId.startsWith('tpl:')) return const {'type': '', 'ref': ''};
      final parts = questId.split(':');
      final kind = parts.length > 1 ? parts[1] : '';
      final payload = parts.length > 2 ? questId.substring('tpl:$kind:'.length) : '';
      if (kind == 'read' || kind == 'readChapter') return {'type': kind, 'ref': payload};
      if (kind == 'reflection') return {'type': 'reflection', 'ref': ''};
      if (kind == 'memorize') return {'type': 'memorize', 'ref': payload};
      return {'type': kind, 'ref': payload};
    } catch (_) {
      return const {'type': '', 'ref': ''};
    }
  }

  Widget _emptyStateCard(BuildContext context,
      {required String message, required String primaryActionLabel, required VoidCallback onPrimaryAction}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onPrimaryAction, child: Text(primaryActionLabel)),
        ],
      ),
    );
  }

  Widget _latestJournalCard(BuildContext context, JournalEntry entry) {
    return GestureDetector(
      onTap: () => _openJournalDetails(context, entry),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: GamerColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(_formatDate(entry.createdAt), style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                if ((entry.questType ?? '').isNotEmpty) _chip(context, _typeLabel(entry.questType!), _typeColor(entry.questType!)),
                if ((entry.spiritualFocus ?? '').isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _chip(context, entry.spiritualFocus!, GamerColors.accent),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if ((entry.questTitle ?? '').isNotEmpty)
              Text(entry.questTitle!, style: Theme.of(context).textTheme.titleMedium),
            if ((entry.scriptureReference ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 14, color: GamerColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(entry.scriptureReference!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textTertiary)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(entry.reflectionText, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => context.go('/journal'),
                child: const Text('Open Journal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementsOverviewTile(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: true);
    final total = provider.achievements.length;
    final unlocked = provider.unlockedAchievements.length;
    return GestureDetector(
      onTap: () => context.push('/achievements'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: GamerColors.accent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$unlocked / $total achievements unlocked', style: Theme.of(context).textTheme.titleMedium),
            ),
            const Icon(Icons.chevron_right, color: GamerColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ===================== Helpers =====================
  VerseModel? _pickFeaturedVerse(AppProvider provider) {
    // Try to pick a verse referenced by an active quest
    final withRef = provider.quests
        .where((q) => !q.isCompleted && !q.isExpired && (q.scriptureReference ?? '').isNotEmpty)
        .toList();
    if (withRef.isNotEmpty) {
      final ref = withRef.first.scriptureReference!;
      try {
        final match = provider.verses.firstWhere((v) => v.reference == ref);
        return match;
      } catch (_) {
        return provider.verses.first;
      }
    }
    return provider.verses.isNotEmpty ? provider.verses.first : null;
  }

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary)),
    );
  }

  String _typeLabel(String raw) {
    switch (raw) {
      case 'prayer':
        return 'Prayer';
      case 'reflection':
        return 'Reflection';
      case 'service':
        return 'Service';
      case 'community':
        return 'Community';
      default:
        return 'Reading';
    }
  }

  Color _typeColor(String raw) {
    switch (raw) {
      case 'prayer':
        return GamerColors.accentSecondary;
      case 'reflection':
        return GamerColors.textSecondary;
      case 'service':
        return GamerColors.success;
      case 'community':
        return GamerColors.danger;
      default:
        return GamerColors.accent;
    }
  }

  Future<void> _openJournalDetails(BuildContext context, JournalEntry entry) async {
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: GamerColors.accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Journal Entry', style: Theme.of(ctx).textTheme.titleLarge)),
                  Text(_formatDate(entry.createdAt), style: Theme.of(ctx).textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 8),
              if ((entry.questTitle ?? '').isNotEmpty)
                Text(entry.questTitle!, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if ((entry.questType ?? '').isNotEmpty) _chip(ctx, _typeLabel(entry.questType!), _typeColor(entry.questType!)),
                if ((entry.spiritualFocus ?? '').isNotEmpty) _chip(ctx, entry.spiritualFocus!, GamerColors.accent),
              ]),
              if ((entry.scriptureReference ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.menu_book, size: 16, color: GamerColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.scriptureReference!,
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: GamerColors.textTertiary)),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Scripture'),
                    onPressed: () {
                      final ref = Uri.encodeComponent(entry.scriptureReference!);
                      Navigator.of(ctx).pop();
                      context.go('/verses?ref=$ref');
                    },
                  ),
                ]),
              ],
              const SizedBox(height: 14),
              Text('Reflection', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(entry.reflectionText, style: Theme.of(ctx).textTheme.bodyMedium),
            ],
          ),
        );
      },
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  Future<void> _openPrayerGuide(BuildContext context, {required String title, required Future<void> Function() onDone}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Prayer — $title', style: theme.textTheme.titleLarge)),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Take a quiet moment. Breathe. Speak to God about what you\'re reading and how it touches your life today. Close with “Amen.”',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check, color: cs.onPrimary),
                  label: const Text('Amen'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await onDone();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reuse date format helper
String _formatDate(DateTime dt) {
  // e.g., Jan 5, 2025
  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final m = months[dt.month - 1];
  return '$m ${dt.day}, ${dt.year}';
}

// ===================== UI Helpers for polish =====================

class _SectionFadeSlide extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _SectionFadeSlide({required this.child, this.delayMs = 0});

  @override
  State<_SectionFadeSlide> createState() => _SectionFadeSlideState();
}

class _SectionFadeSlideState extends State<_SectionFadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Decor wrapper for Today's Verse with consistent border and subtle styling
class _VerseCardDecor extends StatelessWidget {
  final Widget child;
  const _VerseCardDecor({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.neonCyan.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: GamerColors.neonPurple.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Adds a very soft glowing accent around the quest card and animates elevation
class _QuestGlow extends StatelessWidget {
  final Widget child;
  final bool active;
  const _QuestGlow({required this.child, required this.active});

  @override
  Widget build(BuildContext context) {
    final glowColor = GamerColors.accent.withValues(alpha: active ? 0.12 : 0.06);
    return Stack(
      children: [
        // Faint glow
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: active ? 28 : 20,
                    spreadRadius: active ? 2 : 1,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Card with subtle animated elevation
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            elevation: active ? 3 : 1,
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
        ),
      ],
    );
  }
}
