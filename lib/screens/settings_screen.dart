import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/models/quiz_difficulty.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final s = sp.settings;
        // Watch AppProvider for theme mode updates
        final app = context.watch<AppProvider>();
        final appThemeMode = app.themeMode;
        return Scaffold(
            appBar: AppBar(
            leading: context.canPop()
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            centerTitle: true,
            actions: const [HomeActionButton()],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Notifications',
                children: [
                  _NeonSwitchTile(
                    title: 'Enable Notifications',
                    subtitle: 'Allow Scripture Quest™ to send notifications',
                    value: s.notificationsEnabled,
                    icon: Icons.notifications_active,
                    onChanged: (v) => sp.setNotificationsEnabled(v),
                  ),
                  const SizedBox(height: 8),
                  _NeonSwitchTile(
                    title: 'Weekly Summary',
                    subtitle: 'Receive weekly progress reports',
                    value: s.weeklySummaryEnabled,
                    icon: Icons.summarize,
                    onChanged: (v) => sp.setWeeklySummaryEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ============ Quiz preferences (light) ============
              _Section(
                title: 'Quiz preferences',
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<QuizDifficulty>(
                          value: QuizDifficulty.quick,
                          groupValue: sp.preferredQuizDifficulty,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Quick (3 questions)'),
                          secondary: const Icon(Icons.bolt, color: GamerColors.accent),
                          onChanged: (v) async {
                            if (v != null) await sp.setPreferredQuizDifficulty(v);
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                        RadioListTile<QuizDifficulty>(
                          value: QuizDifficulty.standard,
                          groupValue: sp.preferredQuizDifficulty,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Standard (5 questions)'),
                          secondary: const Icon(Icons.terrain, color: GamerColors.accent),
                          onChanged: (v) async {
                            if (v != null) await sp.setPreferredQuizDifficulty(v);
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                        RadioListTile<QuizDifficulty>(
                          value: QuizDifficulty.deep,
                          groupValue: sp.preferredQuizDifficulty,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Deep (7 questions)'),
                          secondary: const Icon(Icons.local_florist, color: GamerColors.accent),
                          onChanged: (v) async {
                            if (v != null) await sp.setPreferredQuizDifficulty(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Reminders',
                children: [
                  _NeonSwitchTile(
                    title: 'Daily Reminder',
                    subtitle: 'Get a reminder to read and reflect',
                    value: s.dailyReminderEnabled,
                    icon: Icons.alarm,
                    onChanged: (v) => sp.setDailyReminderEnabled(v),
                  ),
                  if (s.dailyReminderEnabled) ...[
                    const SizedBox(height: 12),
                    _TimeRow(
                      hour: s.dailyReminderHour,
                      minute: s.dailyReminderMinute,
                      onChanged: (h, m) => sp.setDailyReminderTime(hour: h, minute: m),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _NeonSwitchTile(
                    title: 'Streak Protection Reminder',
                    subtitle: 'Last-call alert to keep your streak alive',
                    value: s.streakProtectionReminderEnabled,
                    icon: Icons.local_fire_department,
                    onChanged: (v) => sp.setStreakProtectionReminderEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Scripture',
                children: [
                  _NeonSwitchTile(
                    title: 'Scripture Popups',
                    subtitle: 'Show verse previews and quick actions',
                    value: s.scripturePopupsEnabled,
                    icon: Icons.auto_stories,
                    onChanged: (v) => sp.setScripturePopupsEnabled(v),
                  ),
                  const SizedBox(height: 8),
                  _NeonSwitchTile(
                    title: 'Show Jesus\' Words in Red',
                    subtitle: 'Apply respectful red-letter styling in Gospels + Acts 1 (KJV)',
                    value: s.redLettersEnabled,
                    icon: Icons.format_color_text,
                    onChanged: (v) => sp.setRedLettersEnabled(v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ============ Theme Packs ============
              _Section(
                title: 'Theme',
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.sacredDark,
                          groupValue: appThemeMode,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Sacred Dark'),
                          subtitle: const Text('Original Scripture Quest™ look.'),
                          onChanged: (m) async {
                            await context.read<AppProvider>().setThemeMode(AppThemeMode.sacredDark);
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.bedtimeCalm,
                          groupValue: appThemeMode,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Bedtime Calm'),
                          subtitle: const Text('Softer tones for late-night reading.'),
                          onChanged: (m) async {
                            await context.read<AppProvider>().setThemeMode(AppThemeMode.bedtimeCalm);
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.oliveDawn,
                          groupValue: appThemeMode,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Olive Dawn'),
                          subtitle: const Text('Warm, earthy manuscript feel.'),
                          onChanged: (m) async {
                            await context.read<AppProvider>().setThemeMode(AppThemeMode.oliveDawn);
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                        RadioListTile<AppThemeMode>(
                          value: AppThemeMode.oceanDeep,
                          groupValue: appThemeMode,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: const Text('Ocean Deep'),
                          subtitle: const Text('Cool, modern blue tones.'),
                          onChanged: (m) async {
                            await context.read<AppProvider>().setThemeMode(AppThemeMode.oceanDeep);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ============ Support & Feedback ============
              _Section(
                title: 'Support & Feedback',
                children: [
                  // Support Scripture Quest
                  Text(
                    'If you\'d like to help support ongoing development and keep Scripture Quest free, you can give here.',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://www.gofundme.com/f/help-build-scripture-quest-a-gamified-bible-app');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open link')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open GoFundMe'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Send Feedback / Report a Bug
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final appProvider = context.read<AppProvider>();
                          final deviceInfo = await appProvider.getDeviceInfoForFeedback();
                          final subject = Uri.encodeComponent('Scripture Quest Feedback');
                          final body = Uri.encodeComponent('Hi! I have some feedback:\n\n\n---\n\n${deviceInfo['summary']}');
                          final uri = Uri.parse('mailto:feedback@scripturequest.app?subject=$subject&body=$body');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open email client')),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint('Send feedback error: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not prepare feedback email')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.feedback_outlined),
                      label: const Text('Send Feedback / Report a Bug'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _NeonSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _NeonSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Theme.of(context).colorScheme.onPrimary,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  const _TimeRow({required this.hour, required this.minute, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    List<int> minutes = List.generate(12, (i) => i * 5); // 0..55 step 5
    return Row(
      children: [
        Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('Reminder time', style: Theme.of(context).textTheme.labelLarge),
        const Spacer(),
        _DropdownPill<int>(
          value: hour,
          items: List.generate(24, (i) => i),
          labelBuilder: (h) => h.toString().padLeft(2, '0'),
          onChanged: (h) => onChanged(h!, minute),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(':', style: TextStyle(color: GamerColors.textSecondary, fontWeight: FontWeight.bold)),
        ),
        _DropdownPill<int>(
          value: minute,
          items: minutes,
          labelBuilder: (m) => m.toString().padLeft(2, '0'),
          onChanged: (m) => onChanged(hour, m!),
        ),
      ],
    );
  }
}

class _DropdownPill<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _DropdownPill({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: DropdownButton<T>(
        value: value,
        dropdownColor: Theme.of(context).colorScheme.surface,
        underline: const SizedBox.shrink(),
        style: Theme.of(context).textTheme.labelLarge,
        items: items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(labelBuilder(e)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Old _ThemeSelector removed in favor of AppThemeMode radio options
