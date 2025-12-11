import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';

class XPBar extends StatefulWidget {
  final int currentXP;
  final int maxXP;
  final int level;

  const XPBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    required this.level,
  });

  @override
  State<XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<XPBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  int _lastHandledEvent = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _scale = Tween<double>(begin: 0.6, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeTriggerBurst(AppProvider provider) {
    if (_lastHandledEvent != provider.xpBurstEvent) {
      _lastHandledEvent = provider.xpBurstEvent;
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.maxXP > 0 ? widget.currentXP / widget.maxXP : 0.0;
    final purple = Theme.of(context).extension<PurpleUi>();

    return Consumer<AppProvider>(builder: (context, provider, _) {
      _maybeTriggerBurst(provider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${widget.level}', style: Theme.of(context).textTheme.titleMedium),
              Text('${widget.currentXP} / ${widget.maxXP} XP', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: purple?.progressTrack ?? Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(purple != null ? 8 : 6),
                  border: Border.all(color: (purple?.cardOutline ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(purple != null ? 7 : 5),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: purple == null
                                ? LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  )
                                : null,
                            color: purple?.progressFill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Subtle neon burst when XP gained
              Positioned(
                right: -6,
                top: -18,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: purple == null
                                ? LinearGradient(colors: [
                                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                                  ])
                                : null,
                            color: purple?.accent.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: (purple?.accent ?? Theme.of(context).colorScheme.primary).withValues(alpha: purple != null ? 0.25 : 0.5),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, size: 16, color: purple?.accent ?? Theme.of(context).colorScheme.onPrimary),
                              const SizedBox(width: 6),
                              Text(
                                '+${provider.xpBurstAmount} XP',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
