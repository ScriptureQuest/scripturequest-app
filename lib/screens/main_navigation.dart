import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/utils/quick_tour_anchors.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/config/build_flags.dart';
// Removed unused gear detail import while Inventory UI is hidden for v1.0
import 'package:level_up_your_faith/models/reward_event.dart';
import 'package:level_up_your_faith/screens/reward/book_reward_modal.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _lastQuestProgressEvent = 0;
  bool _isShowingToast = false;
  int _lastAchievementEvent = 0;
  bool _showAchievementOverlay = false;
  int _lastQuestlineEvent = 0;
  bool _showQuestlineOverlay = false;
  int _lastNewArtifactEvent = 0;
  int _lastBookRewardEvent = 0;
  // Quick Tour
  bool _showQuickTour = false;
  int _quickTourStep = 0; // 0..3
  bool _armedQuickTour = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('MainNavigation: build start');
    // Listen to quest progress signals
    final app = context.watch<AppProvider>();

    // If a new quest progress event arrived, show a small floating snackbar
    if (app.questProgressEvent != 0 && app.questProgressEvent != _lastQuestProgressEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _lastQuestProgressEvent = app.questProgressEvent;
        // Avoid stacked toasts: replace current if visible
        final messenger = ScaffoldMessenger.of(context);
        if (_isShowingToast) {
          messenger.hideCurrentSnackBar();
        }
        _isShowingToast = true;
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text(app.questProgressMessage.isNotEmpty ? app.questProgressMessage : '+Quest Progress'),
            duration: const Duration(milliseconds: 1700),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), width: 1),
            ),
          ),
        );
        try {
          await controller.closed;
        } catch (_) {}
        if (mounted) {
          setState(() => _isShowingToast = false);
        }
        // Clear the signal so it does not re-trigger on rebuild
        try {
          if (mounted) context.read<AppProvider>().ackQuestProgressSignal();
        } catch (_) {}
      });
    }

    // Achievement unlock overlay trigger
    if (app.achievementUnlockEvent != 0 && app.achievementUnlockEvent != _lastAchievementEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _lastAchievementEvent = app.achievementUnlockEvent;
        if (!mounted) return;
        setState(() => _showAchievementOverlay = true);
        await Future.delayed(const Duration(milliseconds: 2700));
        if (!mounted) return;
        setState(() => _showAchievementOverlay = false);
        try {
          if (mounted) context.read<AppProvider>().ackAchievementUnlockSignal();
        } catch (_) {}
      });
    }

    // New Artifact acquired: use high-contrast RewardToast
    if (app.newArtifactEvent != 0 && app.newArtifactEvent != _lastNewArtifactEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _lastNewArtifactEvent = app.newArtifactEvent;
        // Replace any current toast to avoid stacking
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();

        // Show unified RewardToast with clear, readable styles
        RewardToast.showClaimed(
          context,
          title: 'New artifact acquired',
          subtitle: 'Check your Collection',
          icon: Icons.auto_awesome,
        );

        // Acknowledge the signal so it does not re-trigger on rebuild
        try {
          if (mounted) context.read<AppProvider>().ackNewArtifactSignal();
        } catch (_) {}
      });
    }

    // Book-specific reward reveals: open full-screen modal(s) in sequence
    if (app.bookRewardQueueEvent != 0 && app.bookRewardQueueEvent != _lastBookRewardEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _lastBookRewardEvent = app.bookRewardQueueEvent;
        await _presentBookRewardModals(context);
      });
    }

    // Questline completion overlay trigger
    if (app.questlineCompletionEvent != 0 && app.questlineCompletionEvent != _lastQuestlineEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _lastQuestlineEvent = app.questlineCompletionEvent;
        if (!mounted) return;
        setState(() => _showQuestlineOverlay = true);
        await Future.delayed(const Duration(milliseconds: 2600));
        if (!mounted) return;
        setState(() => _showQuestlineOverlay = false);
        try {
          if (mounted) context.read<AppProvider>().ackQuestlineCompletionSignal();
        } catch (_) {}
      });
    }

    // Quick Tour trigger: show when landing on Home and not completed
    final settings = context.watch<SettingsProvider>();
    final locationStr = GoRouterState.of(context).uri.toString();
    final onHome = locationStr == '/' || locationStr.startsWith('/home');
    // Dismiss Quick Tour immediately if user navigates away from Home while active (tab switch or route change)
    if (_showQuickTour && !onHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _showQuickTour = false);
        // Mark completed so it won't re-run unless onboarding is reset
        try {
          context.read<SettingsProvider>().setHasCompletedQuickTour(true);
        } catch (_) {}
      });
    }
    // Only arm Quick Tour on Home, after Personalized Setup completion, and if not already completed
    // Disable Quick Tour entirely for beta builds to avoid misaligned overlays.
    if (!kIsBetaBuild && onHome && settings.hasCompletedPersonalizedSetup && !settings.hasCompletedQuickTour && !_armedQuickTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _armedQuickTour = true;
          _showQuickTour = true;
          _quickTourStep = 0;
        });
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          // Lightweight achievement overlay
          if (_showAchievementOverlay && app.latestAchievementUnlock != null)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: GestureDetector(
                onTap: () {
                  setState(() => _showAchievementOverlay = false);
                  try {
                    context.read<AppProvider>().ackAchievementUnlockSignal();
                  } catch (_) {}
                },
                child: _AchievementUnlockCard(
                  achievement: app.latestAchievementUnlock!,
                  summary: app.latestAchievementSummary,
                ),
              ),
            ),
          // Questline completion overlay
          if (_showQuestlineOverlay && app.latestQuestlineCompletionTitle != null)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 16 + 84, // stack below achievement if both fire
              child: _QuestlineCompleteCard(
                title: app.latestQuestlineCompletionTitle!,
                summary: app.latestQuestlineRewardsSummary,
              ),
            ),
          // Quick Tour overlay (runs once)
          if (_showQuickTour) Positioned.fill(child: _QuickTourOverlay(
            step: _quickTourStep,
            onNext: () {
              if (_quickTourStep < 3) {
                setState(() => _quickTourStep += 1);
              } else {
                // Finish
                setState(() => _showQuickTour = false);
                context.read<SettingsProvider>().setHasCompletedQuickTour(true);
              }
            },
          )),
        ],
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }

  bool _bookModalOpen = false;

  Future<void> _presentBookRewardModals(BuildContext context) async {
    if (_bookModalOpen) return;
    _bookModalOpen = true;
    try {
      final app = context.read<AppProvider>();
      final total = app.pendingBookRewardsCount;
      if (total <= 0) return;
      for (int i = 1; i <= total; i++) {
        final ev = app.dequeueNextBookRewardEvent();
        if (ev == null) break;
        await Navigator.of(context).push(RewardFullScreenRoute(index: i, total: total, event: ev));
      }
    } catch (_) {} finally {
      _bookModalOpen = false;
    }
  }
}

class _BottomNavBar extends StatefulWidget {
  const _BottomNavBar();

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  int _lastNudgeEvent = 0;
  bool _nudgeActive = false;
  // Inventory UI hidden in v1.0 — no badge tracking needed

  void _triggerNudge() {
    if (_nudgeActive) return;
    setState(() => _nudgeActive = true);
    Future.delayed(const Duration(milliseconds: 340), () {
      if (!mounted) return;
      setState(() => _nudgeActive = false);
      // Acknowledge the signal to avoid repeated animations on rebuilds
      try {
        context.read<AppProvider>().ackQuestTabNudge();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = -1;
    // Map current route to 3-tab layout (beta simplicity):
    // 0: Quest Hub, 1: Bible, 2: Profile
    if (location == '/' || location.startsWith('/tasks')) {
      currentIndex = 0;
    } else if (location.startsWith('/bible') || location.startsWith('/verses') || location.startsWith('/scripture') || location.startsWith('/favorites')) {
      currentIndex = 1;
    } else if (location.startsWith('/profile') || location.startsWith('/player') || location.startsWith('/avatar') || location.startsWith('/equip') || location.startsWith('/inventory') || location.startsWith('/community') || location.startsWith('/friends') || location.startsWith('/leaderboards')) {
      currentIndex = 2;
    }
    // For home and root, don't highlight any tab (user may be on detail screens, quests, etc.)
    // This prevents incorrect highlighting when on non-tab screens

    // Nudge when a new event arrives
    if (app.questTabNudgeEvent != 0 && app.questTabNudgeEvent != _lastNudgeEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastNudgeEvent = app.questTabNudgeEvent;
        _triggerNudge();
      });
    }

    // Inventory badge removed (Inventory UI hidden)

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Quest Hub',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/'),
                scale: _nudgeActive ? 1.12 : 1.0,
              ),
              KeyedSubtree(
                key: QuickTourAnchors.bibleNavKey,
                child: _NavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Bible',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go('/bible'),
                ),
              ),
              KeyedSubtree(
                key: QuickTourAnchors.profileNavKey,
                child: _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.scale = 1.0,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: scale,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    icon,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 26,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        badge!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementUnlockCard extends StatelessWidget {
  final dynamic achievement; // AchievementModel
  final String? summary;

  const _AchievementUnlockCard({required this.achievement, this.summary});

  Color _rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.amber;
      case 'epic':
        return Colors.purpleAccent;
      case 'rare':
        return Colors.lightBlueAccent;
      case 'common':
      default:
        return Colors.grey;
    }
  }

  String _rarityLabel(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 'Legendary';
      case 'epic':
        return 'Epic';
      case 'rare':
        return 'Rare';
      case 'common':
      default:
        return 'Common';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rarity = (achievement.rarity ?? achievement.displayRarity ?? 'common').toString();
    final borderColor = _rarityColor(rarity).withValues(alpha: 0.6);
    final title = 'Achievement Unlocked';
    final achName = (achievement.name ?? achievement.title) as String? ?? 'Achievement';
    final achDesc = (achievement.description as String?) ?? '';

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: GamerColors.darkCard.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          _rarityLabel(rarity),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: borderColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (achDesc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      achDesc,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (summary != null && summary!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(summary!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestlineCompleteCard extends StatelessWidget {
  final String title;
  final String? summary;

  const _QuestlineCompleteCard({required this.title, this.summary});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: GamerColors.darkCard.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Quest Complete', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (summary != null && summary!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(summary!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Quick Tour overlay =================

class _QuickTourOverlay extends StatelessWidget {
  final int step; // 0..3
  final VoidCallback onNext;

  const _QuickTourOverlay({required this.step, required this.onNext});

  Rect? _rectFor(GlobalKey key) {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return null;
      final pos = box.localToGlobal(Offset.zero);
      return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Determine target rect
    Rect? target;
    String title;
    switch (step) {
      case 0:
        target = _rectFor(QuickTourAnchors.verseCardKey);
        title = "Today's Verse";
        break;
      case 1:
        target = _rectFor(QuickTourAnchors.tonightsQuestKey);
        title = "Tonight's Quest";
        break;
      case 2:
        target = _rectFor(QuickTourAnchors.bibleNavKey);
        title = "Bible";
        break;
      default:
        target = _rectFor(QuickTourAnchors.profileNavKey);
        title = "Profile";
        break;
    }

    // Fallback positions if anchors not resolved yet
    final size = MediaQuery.of(context).size;
    target ??= () {
      if (step == 0) {
        return Rect.fromLTWH(16, size.height * 0.22, size.width - 32, 140);
      } else if (step == 1) {
        return Rect.fromLTWH(16, size.height * 0.42, size.width - 32, 160);
      } else if (step == 2) {
        // 5-tab layout: Bible is index 2 (center)
        final w = size.width / 5.0;
        return Rect.fromLTWH(w * 2 + w * 0.1, size.height - 92, w * 0.8, 56);
      } else {
        // 5-tab layout: Profile is index 4 (last)
        final w = size.width / 5.0;
        return Rect.fromLTWH(w * 4 + w * 0.1, size.height - 92, w * 0.8, 56);
      }
    }();

    return Stack(
      children: [
        // Dim background
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        // Highlight border
        Positioned(
          left: target.left - 4,
          top: target.top - 4,
          width: target.width + 8,
          height: target.height + 8,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary, width: 2),
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        // Tooltip card
        Positioned(
          left: 16,
          right: 16,
          bottom: step < 2 ? 24 : (MediaQuery.of(context).padding.bottom + 100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onNext,
                  child: Text(step < 3 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
