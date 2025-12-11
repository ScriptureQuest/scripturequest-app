import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/soul_avatar.dart';
import 'package:level_up_your_faith/config/build_flags.dart';

// Build flags are centralized in lib/config/build_flags.dart

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _busy = false;
  final TextEditingController _nameCtrl = TextEditingController();
  String? _pendingName; // apply just before final setup

  // Updated totals: 5 steps in beta, 4 in non-beta.
  int get _totalPages => kIsBetaBuild ? 5 : 4; // Beta adds one page

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Build pages list (shortened):
    // Beta: 5 steps => Welcome, Beta, Daily Rhythm (merged), Soul Avatar, Summary/Enter
    // Non-beta: 4 steps => Welcome, Daily Rhythm (merged), Soul Avatar, Summary/Enter
    final pages = <Widget>[
      _pageWelcome(context),
      if (kIsBetaBuild) _pageBeta(context),
      _pageRhythm(context),
      _pageSoulAvatar(context),
      _pageSetup(context),
    ];
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal top skip for future versions (hidden for v2.0 to keep focus)
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            _dots(theme, total: pages.length),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _dots(ThemeData theme, {int total = 3}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _pageWelcome(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('Welcome to Scripture Quest', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Build a daily rhythm in God\'s Word with reading, tasks, and gentle challenges.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(Icons.nightlight_round, color: cs.onPrimary),
            label: const Text('Begin'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Beta-only page; included when kIsBetaBuild == true.
  Widget _pageBeta(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('Welcome to the Scripture Quest Beta', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          _calmCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re helping shape the very first version of Scripture Quest.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Things may change, and some features are still in progress.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Thank you for testing, sharing feedback, and praying with us.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(Icons.chevron_right, color: cs.onPrimary),
            label: const Text('Continue'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _pageRhythm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('Your Daily Rhythm', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Grow step by step with a calm, clear rhythm.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _calmCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(theme, icon: Icons.auto_stories_rounded, text: 'Read the Bible with a calm reader.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.checklist_rounded, text: 'Complete Daily & Nightly Tasks.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.alt_route_rounded, text: 'Follow Questlines and Reading Plans.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.extension_rounded, text: 'Play games and practice verses in Play & Learn.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(Icons.chevron_right, color: cs.onPrimary),
            label: const Text('Continue'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _pageSoulAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('Your Soul Avatar', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'This is a simple way to track your journey with God inside Scripture Quest. You can adjust themes and reading preferences anytime in Settings.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Center(
            child: SoulAvatarViewV2(level: 1, faithPower: 1.0, size: SoulAvatarSize.large),
          ),
          const SizedBox(height: 20),
          _calmCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(theme, icon: Icons.workspace_premium_rounded, text: 'Equip artifacts you earn from reading and quests.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.local_fire_department_rounded, text: 'Your Faith Power grows as you stay consistent.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.favorite_rounded, text: 'It’s not about performance, it’s about your journey with God.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(Icons.chevron_right, color: cs.onPrimary),
            label: const Text('Continue'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _pageChooseName(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('What should we call you?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('This name will appear on your profile and journey.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Display name (optional)',
              hintText: 'e.g., Grace, Daniel, FaithSeeker',
            ),
            onSubmitted: (_) {
              _pendingName = _nameCtrl.text.trim();
              _next();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _pendingName = _nameCtrl.text.trim();
                    _next();
                  },
                  icon: Icon(Icons.check_rounded, color: cs.onPrimary),
                  label: const Text('Continue'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _next,
                child: const Text('Skip'),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _pageHowItWorks(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text('How Scripture Quest works', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Simple steps to help you grow.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          _calmCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(theme, icon: Icons.menu_book_rounded, text: 'Read the Bible with a calm reader.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.checklist_rounded, text: 'Complete Daily & Nightly Tasks.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.alt_route_rounded, text: 'Follow Questlines and Reading Plans.'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.school_rounded, text: 'Practice and memorize key verses.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(Icons.chevron_right, color: cs.onPrimary),
            label: const Text('Continue'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _pageSetup(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text("Let's Start Your Journey", style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          _calmCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(theme, icon: Icons.explore, text: 'Assigns your first Quest automatically'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.flag, text: 'Adds two starter tasks'),
                const SizedBox(height: 8),
                _line(theme, icon: Icons.auto_awesome, text: 'Grants a simple starter artifact + title'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      final app = context.read<AppProvider>();
                      // Apply optional name now so it appears in next flow too
                      final raw = (_pendingName ?? _nameCtrl.text).trim();
                      if (raw.isNotEmpty) {
                        try {
                          final user = app.currentUser ?? await app.userService.getCurrentUser();
                          final updated = user.copyWith(username: raw);
                          await app.userService.updateUser(updated);
                          await app.loadData();
                        } catch (e) {
                          debugPrint('onboarding name save error: $e');
                        }
                      }
                    } catch (_) {}
                    if (!mounted) return;
                    context.go('/onboarding/personalized');
                  },
            icon: Icon(Icons.check_circle, color: cs.onPrimary),
            label: _busy ? const Text('Preparing...') : const Text('Enter Scripture Quest'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _calmCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
      ),
      child: child,
    );
  }

  Widget _line(ThemeData theme, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
