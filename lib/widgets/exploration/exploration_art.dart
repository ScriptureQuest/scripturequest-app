import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small native vector collection: morning light, sheltering hills, night study.
/// Lives outside Scripture surfaces. One scene key can later select a book/theme asset.
class ExplorationArt extends StatelessWidget {
  final String scene;
  final double height;
  final bool illustrated;
  const ExplorationArt(
      {super.key,
      required this.scene,
      this.height = 130,
      this.illustrated = true});
  @override
  Widget build(BuildContext context) => illustrated
      ? ExcludeSemantics(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: CustomPaint(
                      painter: _Landscape(scene,
                          Theme.of(context).brightness == Brightness.dark)))))
      : const SizedBox.shrink();
}

class _Landscape extends CustomPainter {
  final String scene;
  final bool dark;
  _Landscape(this.scene, this.dark);
  @override
  void paint(Canvas c, Size s) {
    final night = scene == 'night' || dark;
    final paint = Paint();
    c.drawRect(
        Offset.zero & s,
        paint
          ..color = night ? const Color(0xff153e45) : const Color(0xffe9dbb8));
    final sun = Offset(s.width * .76, s.height * .31);
    c.drawCircle(sun, s.height * .16, paint..color = const Color(0xfff5e8c4));
    if (night)
      c.drawCircle(sun + Offset(s.height * .09, -s.height * .055),
          s.height * .15, paint..color = const Color(0xff153e45));
    for (var i = 0; i < 3; i++) {
      final p = Path()..moveTo(0, s.height * (.63 + i * .11));
      p.cubicTo(s.width * .27, s.height * (.15 + i * .21), s.width * .58,
          s.height * (1.1 - i * .07), s.width, s.height * (.49 + i * .19));
      p.lineTo(s.width, s.height);
      p.lineTo(0, s.height);
      p.close();
      c.drawPath(
          p,
          paint
            ..color = [
              const Color(0xff8ba397),
              const Color(0xff49796e),
              const Color(0xff23564f)
            ][i]);
    }
    // The path belongs to the landscape, never a map of spiritual rank.
    final path = Path()
      ..moveTo(s.width * .4, s.height)
      ..quadraticBezierTo(
          s.width * .75, s.height * .75, s.width * .55, s.height * .65);
    c.drawPath(
        path,
        paint
          ..color = const Color(0xffe2c88b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    paint.style = PaintingStyle.fill;
    if (scene == 'light') {
      for (var i = 0; i < 7; i++) {
        final angle = math.pi * (i / 6);
        final v = Offset(math.cos(angle), -math.sin(angle));
        c.drawLine(
            sun + v * (s.height * .21),
            sun + v * (s.height * .26),
            paint
              ..color = const Color(0xffd0ad63)
              ..strokeWidth = 1.5);
      }
    }
    if (scene == 'night')
      for (final p in [
        const Offset(.15, .18),
        const Offset(.36, .3),
        const Offset(.51, .12)
      ]) {
        c.drawCircle(Offset(s.width * p.dx, s.height * p.dy), 1.6,
            paint..color = const Color(0xffe9d89c));
      }
  }

  @override
  bool shouldRepaint(_Landscape old) => old.scene != scene || old.dark != dark;
}

/// Related accomplishment marks: exploration, evidence, remembering.
class AccomplishmentMark extends StatelessWidget {
  final IconData icon;
  const AccomplishmentMark({super.key, required this.icon});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .94, end: 1),
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 320),
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                  color: Theme.of(context).colorScheme.primaryContainer),
              child: Icon(icon, size: 28))));
}
