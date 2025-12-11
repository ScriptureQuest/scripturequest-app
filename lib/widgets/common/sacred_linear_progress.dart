import 'package:flutter/material.dart';

class SacredLinearProgress extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double minHeight;
  final Color? fillColor;
  final BorderRadius borderRadius;

  const SacredLinearProgress({
    super.key,
    required this.value,
    this.minHeight = 6,
    this.fillColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: minHeight,
        backgroundColor: cs.surface,
        valueColor: AlwaysStoppedAnimation<Color>(fillColor ?? cs.primary),
      ),
    );
  }
}
