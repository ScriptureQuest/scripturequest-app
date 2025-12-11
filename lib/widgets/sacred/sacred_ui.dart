import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';

// Sacred UI kit: shared widgets for consistent dark styling and micro-animations

class SacredCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderSide? borderSide;
  final double radius;
  final Color? background;
  final List<BoxShadow>? shadows;

  const SacredCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderSide,
    this.radius = 16,
    this.background,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: background ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (borderSide?.color ?? cs.outline.withValues(alpha: 0.18)),
          width: borderSide?.width ?? 1,
        ),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  const SectionHeader(this.title, {super.key, this.icon, this.padding = const EdgeInsets.only(bottom: 8)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final purple = theme.extension<PurpleUi>();
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: purple?.sectionTitle ?? cs.onSurfaceVariant,
      letterSpacing: 0.2,
    );
    final iconColor = purple?.sectionIcon ?? cs.onSurfaceVariant;
    // Add breathing room on top for Purple mode per spec
    final effectivePadding = (purple != null)
        ? EdgeInsets.only(top: 10, left: (padding as EdgeInsets?)?.left ?? 0, right: (padding as EdgeInsets?)?.right ?? 0, bottom: (padding as EdgeInsets?)?.bottom ?? 8)
        : padding;
    return Padding(
      padding: effectivePadding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: textStyle)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry padding;
  const EmptyState({super.key, required this.message, this.padding = const EdgeInsets.symmetric(vertical: 24)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double dy;
  const FadeSlideIn({super.key, required this.child, this.duration = const Duration(milliseconds: 260), this.curve = Curves.easeOut, this.dy = 8});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Interval(0.0, 1.0, curve: widget.curve));
    final slide = Tween<Offset>(begin: Offset(0, widget.dy / 100), end: Offset.zero).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}
