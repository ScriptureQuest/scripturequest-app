import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';

class PersonalizedSetupFlow extends StatefulWidget {
  const PersonalizedSetupFlow({super.key});

  @override
  State<PersonalizedSetupFlow> createState() => _PersonalizedSetupFlowState();
}

class _PersonalizedSetupFlowState extends State<PersonalizedSetupFlow> {
  int _step = 0; // 0..5 (5 questions, then summary)
  bool _busy = false;
  final TextEditingController _nameCtrl = TextEditingController();
  String? _pendingName;

  void _next() => setState(() => _step = (_step + 1).clamp(0, 5));
  void _back() => setState(() => _step = (_step - 1).clamp(0, 5));

  Widget _calmCard(Widget child) {
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

  Widget _choiceButton({required String label, required IconData icon, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: cs.onPrimary),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    // Five calm, high-value questions before the summary screen
    final stepsTotal = 5;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Personalized Setup'),
        leading: _step > 0
            ? IconButton(
                onPressed: _busy ? null : _back,
                icon: Icon(Icons.chevron_left, color: cs.onSurface),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step < stepsTotal)
                Row(
                  children: [
                    Text('Step ${_step + 1} of $stepsTotal',
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    const Spacer(),
                  ],
                ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStep(context, settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Widget _buildStep(BuildContext context, SettingsProvider settings) {
    switch (_step) {
      // 0) Name (TextField, skip permitted) → saves via UserService/AppProvider
      case 0:
        return _question(
          title: "What's your name?",
          children: [
            _calmCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.name,
                      maxLength: 30,
                    onSubmitted: (_) async => await _saveNameAndNext(),
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                        helperText: 'You can change this later in your profile.',
                        border: OutlineInputBorder(),
                      ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  await _saveNameAndNext();
                                },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Continue'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                _next();
                              },
                          child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      // 1) Bible reading rhythm (maps to bibleExperienceLevel)
      case 1:
        return _question(
          title: 'How often do you usually read the Bible?',
          children: [
            _choiceButton(
              label: "I'm just starting",
              icon: Icons.flag_outlined,
              onTap: () async {
                await settings.setBibleExperienceLevel('beginner');
                _next();
              },
            ),
            _choiceButton(
              label: 'A few times a week',
              icon: Icons.calendar_view_week,
              onTap: () async {
                await settings.setBibleExperienceLevel('gettingTheHang');
                _next();
              },
            ),
            _choiceButton(
              label: 'Almost every day',
              icon: Icons.event_available,
              onTap: () async {
                await settings.setBibleExperienceLevel('comfortable');
                _next();
              },
            ),
            _choiceButton(
              label: 'Every day',
              icon: Icons.check_circle_outline,
              onTap: () async {
                await settings.setBibleExperienceLevel('comfortable');
                _next();
              },
            ),
          ],
        );
      // 2) Time of day (maps to preferredReminderTime)
      case 2:
        return _question(
          title: 'When do you most like to spend time in Scripture?',
          children: [
            _choiceButton(
              label: 'Morning',
              icon: Icons.wb_sunny_outlined,
              onTap: () async {
                await settings.setPreferredReminderTime('morning');
                _next();
              },
            ),
            _choiceButton(
              label: 'Afternoon',
              icon: Icons.wb_cloudy_outlined,
              onTap: () async {
                await settings.setPreferredReminderTime('afternoon');
                _next();
              },
            ),
            _choiceButton(
              label: 'Evening',
              icon: Icons.nightlight_round,
              onTap: () async {
                await settings.setPreferredReminderTime('evening');
                _next();
              },
            ),
            TextButton(
              onPressed: () async {
                await settings.setPreferredReminderTime('none');
                _next();
              },
              child: const Text('It changes'),
            ),
          ],
        );
      // 3) Main focus (maps to mainGoal)
      case 3:
        return _question(
          title: 'What do you most want help with right now?',
          children: [
            _choiceButton(
              label: 'Building a daily rhythm',
              icon: Icons.local_fire_department_outlined,
              onTap: () async {
                await settings.setMainGoal('consistency');
                _next();
              },
            ),
            _choiceButton(
              label: 'Understanding Scripture',
              icon: Icons.menu_book_outlined,
              onTap: () async {
                await settings.setMainGoal('learning');
                _next();
              },
            ),
            _choiceButton(
              label: 'Memorizing verses',
              icon: Icons.bookmark_border,
              onTap: () async {
                // Map to existing learning goal for now
                await settings.setMainGoal('learning');
                _next();
              },
            ),
            _choiceButton(
              label: 'Encouragement & peace',
              icon: Icons.favorite_border,
              onTap: () async {
                await settings.setMainGoal('peace');
                _next();
              },
            ),
          ],
        );
      // 4) Challenge level (maps to guidanceLevel)
      case 4:
        return _question(
          title: 'How gentle or challenging should Scripture Quest feel?',
          children: [
            _choiceButton(
              label: 'Very gentle',
              icon: Icons.spa_outlined,
              onTap: () async {
                await settings.setGuidanceLevel('gentle');
                _next();
              },
            ),
            _choiceButton(
              label: 'Normal',
              icon: Icons.tune,
              onTap: () async {
                await settings.setGuidanceLevel('someStructure');
                _next();
              },
            ),
            _choiceButton(
              label: 'Challenge me',
              icon: Icons.flag_rounded,
              onTap: () async {
                await settings.setGuidanceLevel('fullGuidance');
                _next();
              },
            ),
          ],
        );
      default:
        return _finalStep(context);
    }
  }

  Widget _finalStep(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text("You're all set — Let's begin!", style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        _calmCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rocket_launch_outlined, color: GamerColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We tuned your experience based on your choices.',
                      style: theme.textTheme.titleMedium,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You can change these anytime in Settings.',
                style: theme.textTheme.bodyMedium,
                softWrap: true,
              ),
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
                    // Mark personalized flow complete and run onboarding setup
                    await context.read<SettingsProvider>().onboardingPersonalizedComplete();
                    await context.read<AppProvider>().completeOnboardingSetup();
                  } catch (e) {
                    debugPrint('personalized setup finalize error: $e');
                  }
                  if (!mounted) return;
                  context.go('/home');
                },
          icon: Icon(Icons.check_circle, color: cs.onPrimary),
          label: _busy ? const Text('Preparing...') : const Text('Enter Scripture Quest'),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _question({required String title, String? subtitle, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(title, style: theme.textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.labelSmall),
        ],
        const SizedBox(height: 16),
        ...children.expand((w) => [w, const SizedBox(height: 12)]),
        const Spacer(),
      ],
    );
  }

  Future<void> _saveNameAndNext() async {
    try {
      setState(() => _busy = true);
      final app = context.read<AppProvider>();
      final raw = (_pendingName ?? _nameCtrl.text).trim();
      if (raw.isNotEmpty) {
        try {
          final user = app.currentUser ?? await app.userService.getCurrentUser();
          final updated = user.copyWith(username: raw);
          await app.userService.updateUser(updated);
          await app.loadData();
        } catch (e) {
          debugPrint('personalized name save error: $e');
        }
      }
      if (mounted) {
        setState(() => _busy = false);
        _next();
      }
    } catch (e) {
      debugPrint('_saveNameAndNext error: $e');
      if (mounted) {
        setState(() => _busy = false);
        _next();
      }
    }
  }
}
