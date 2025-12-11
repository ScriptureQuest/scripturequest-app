import 'package:flutter/material.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/sacred/sacred_ui.dart';

class SoulAvatarEquipScreen extends StatefulWidget {
  const SoulAvatarEquipScreen({super.key});

  @override
  State<SoulAvatarEquipScreen> createState() => _SoulAvatarEquipScreenState();
}

class _SoulAvatarEquipScreenState extends State<SoulAvatarEquipScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Soul Avatar', style: theme.textTheme.headlineSmall),
        centerTitle: true,
        actions: const [HomeActionButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FadeSlideIn(
              dy: 6,
              child: SacredCard(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.self_improvement_outlined, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Soul Avatar',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A new way to express your spiritual journey — coming soon.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outline.withValues(alpha: 0.18), height: 1),
                    const SizedBox(height: 16),
                    // Optional bullets
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Bullet(text: 'Gentle customization to express your walk'),
                          _Bullet(text: 'Celebrate milestones along the way'),
                          _Bullet(text: 'Optional looks and frames to unlock'),
                          _Bullet(text: 'Thoughtfully designed for a calm, sacred feel'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
