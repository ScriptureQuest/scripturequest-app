import 'package:flutter/material.dart';
import '../../theme/scripture_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

/// Compatibility scope for standalone V2 widgets/previews.
class ReadingDesign extends StatelessWidget {
  final Widget child;
  const ReadingDesign({super.key, required this.child});
  @override Widget build(BuildContext context) => Theme(data: ScriptureThemes.build(context.watch<SettingsProvider>().questThemeId), child: child);
}

class ReadingSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ReadingSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      );
}
