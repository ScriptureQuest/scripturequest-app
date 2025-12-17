import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/config/build_flags.dart';

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

  // Reading comfort state (local until saved)
  String _selectedTheme = 'paper';
  double _selectedScale = 1.3;
  bool _redLetters = true;

  // Reading rhythm choice
  String? _rhythmChoice;

  int get _totalPages => kIsBetaBuild ? 6 : 5;

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize from current settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      setState(() {
        _selectedTheme = settings.settings.bibleReaderTheme;
        _selectedScale = settings.settings.bibleFontScale;
        _redLetters = settings.settings.redLettersEnabled;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pages = <Widget>[
      _pageWelcome(context),
      if (kIsBetaBuild) _pageBeta(context),
      _pageReadingComfort(context),
      _pageReadingRhythm(context),
      _pageIdentity(context),
      _pageGentleClose(context),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            _dots(theme, total: pages.length),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _dots(ThemeData theme, {required int total}) {
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

  // ─────────────────────────────────────────────────────────────────────────
  // 1) Welcome Screen - Purpose, not features
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageWelcome(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            'Welcome to Scripture Quest',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A gentle way to build a daily rhythm with Scripture.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Begin'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Beta page (only shown when kIsBetaBuild)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageBeta(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            'Welcome to the Beta',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You're helping shape the very first version of Scripture Quest. Things may change, and some features are still in progress.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you for testing and sharing feedback.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Continue'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2) Reading Comfort Setup - Essential only
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageReadingComfort(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Theme colors for preview
    Color bgColor;
    Color textColor;
    switch (_selectedTheme) {
      case 'sepia':
        bgColor = const Color(0xFFF5ECD7);
        textColor = const Color(0xFF3D3425);
        break;
      case 'night':
        bgColor = const Color(0xFF1A1A1A);
        textColor = const Color(0xFFE0E0E0);
        break;
      default:
        bgColor = const Color(0xFFFAFAFA);
        textColor = const Color(0xFF1A1A1A);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Comfort',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what feels easiest on your eyes. You can change this anytime.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Live preview - elevated scripture card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'For God so loved the world, that he gave his only Son, ',
                    style: TextStyle(color: textColor, fontSize: 16 * _selectedScale, height: 1.5),
                  ),
                  if (_redLetters)
                    TextSpan(
                      text: 'that whoever believes in him should not perish but have eternal life.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 16 * _selectedScale, height: 1.5),
                    )
                  else
                    TextSpan(
                      text: 'that whoever believes in him should not perish but have eternal life.',
                      style: TextStyle(color: textColor, fontSize: 16 * _selectedScale, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Theme selector
          Text('Reading Style', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              _themeChip('Paper', 'paper', const Color(0xFFFAFAFA), Colors.black87),
              const SizedBox(width: 8),
              _themeChip('Sepia', 'sepia', const Color(0xFFF5ECD7), const Color(0xFF3D3425)),
              const SizedBox(width: 8),
              _themeChip('Night', 'night', const Color(0xFF1A1A1A), Colors.white70),
            ],
          ),
          const SizedBox(height: 20),

          // Text size slider
          Row(
            children: [
              Text('Text Size', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              Text('${(_selectedScale * 100).round()}%', style: theme.textTheme.labelMedium),
            ],
          ),
          Slider(
            value: _selectedScale,
            min: 0.8,
            max: 1.6,
            divisions: 8,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _selectedScale = v);
            },
          ),
          const SizedBox(height: 8),

          // Red letters toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  "Show Jesus' words in red",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Switch(
                value: _redLetters,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _redLetters = v);
                },
              ),
            ],
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                // Save reading preferences
                final settings = context.read<SettingsProvider>();
                await settings.setBibleReaderTheme(_selectedTheme);
                await settings.setBibleFontScale(_selectedScale);
                await settings.setRedLettersEnabled(_redLetters);
                _next();
              },
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _themeChip(String label, String value, Color bg, Color fg) {
    final selected = _selectedTheme == value;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTheme = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3) Reading Rhythm - One question only
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageReadingRhythm(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            'Your Reading Rhythm',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This helps shape your quests. There's no wrong choice.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          _buildRhythmOption('daily', 'Daily'),
          const SizedBox(height: 12),
          _buildRhythmOption('fewTimes', 'A few times a week'),
          const SizedBox(height: 12),
          _buildRhythmOption('ownPace', "I'll explore at my own pace"),

          const SizedBox(height: 16),
          Text(
            'You can change this anytime.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),

          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rhythmChoice == null
                  ? null
                  : () async {
                      final settings = context.read<SettingsProvider>();
                      // Map to existing settings
                      switch (_rhythmChoice) {
                        case 'daily':
                          await settings.setBibleExperienceLevel('comfortable');
                          await settings.setDailyRhythmStyle('daily');
                          break;
                        case 'fewTimes':
                          await settings.setBibleExperienceLevel('gettingTheHang');
                          await settings.setDailyRhythmStyle('fewTimes');
                          break;
                        case 'ownPace':
                          await settings.setBibleExperienceLevel('beginner');
                          await settings.setDailyRhythmStyle('flexible');
                          break;
                      }
                      _next();
                    },
              child: const Text('Continue'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRhythmOption(String value, String label) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _rhythmChoice == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _rhythmChoice = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4) Identity - Name is required, no title preview
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageIdentity(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nameValid = _nameCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            'What should we call you?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your journey will be shown.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.name,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (nameValid) _saveNameAndContinue();
            },
          ),

          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_busy || !nameValid) ? null : _saveNameAndContinue,
              child: _busy ? const Text('Saving...') : const Text('Continue'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _saveNameAndContinue() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    try {
      final app = context.read<AppProvider>();
      final user = app.currentUser ?? await app.userService.getCurrentUser();
      final updated = user.copyWith(username: name);
      await app.userService.updateUser(updated);
      await app.loadData();
    } catch (e) {
      debugPrint('onboarding name save error: $e');
    }
    if (mounted) {
      setState(() => _busy = false);
      _next();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5) Gentle Close - No pressure CTA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageGentleClose(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            "You're Ready",
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your path is simple. Faithfulness grows in small steps.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        // Mark onboarding complete and run setup
                        await context.read<SettingsProvider>().onboardingPersonalizedComplete();
                        await context.read<AppProvider>().completeOnboardingSetup();
                      } catch (e) {
                        debugPrint('onboarding finalize error: $e');
                      }
                      if (!mounted) return;
                      context.go('/');
                    },
              child: _busy
                  ? const Text('Preparing...')
                  : const Text('Enter Quest Hub'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
