import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';

/// Lightweight visuals model describing what is equipped around the avatar.
class EquippedAvatarVisuals {
  final String? handArtifactId;
  final String? chestArtifactId;
  final String? charmArtifactId;
  final String? headArtifactId;
  final String? artifactId; // legendary floating relic

  const EquippedAvatarVisuals({
    this.handArtifactId,
    this.chestArtifactId,
    this.charmArtifactId,
    this.headArtifactId,
    this.artifactId,
  });

  bool get hasAny =>
      handArtifactId != null ||
      chestArtifactId != null ||
      charmArtifactId != null ||
      headArtifactId != null ||
      artifactId != null;
}

/// A calm, glow-based spiritual Soul Avatar (v1.1).
/// - Peaceful, minimal: soft halo + blurred head/shoulders silhouette
/// - No floating particles or icon badges around the avatar
/// - Uses soft teal/lavender/white tones that scale gently with faith power
class SoulAvatarView extends StatefulWidget {
  final int level;
  final double faithPower; // use sum of SpiritualStats or similar
  final EquippedAvatarVisuals? equipped;
  final bool isLarge; // larger layout for Inventory spotlight

  const SoulAvatarView({
    super.key,
    required this.level,
    required this.faithPower,
    this.equipped,
    this.isLarge = false,
  });

  @override
  State<SoulAvatarView> createState() => _SoulAvatarViewState();
}

class _SoulAvatarViewState extends State<SoulAvatarView> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  double get _intensity {
    // Map level and faithPower to a 0.15 - 1.0 intensity range.
    final lvl = widget.level.clamp(1, 100);
    final fp = widget.faithPower.isNaN ? 0.0 : widget.faithPower;
    final normLevel = (lvl / 30.0).clamp(0.0, 1.0); // saturate around lvl 30
    final normPower = (fp / 30.0).clamp(0.0, 1.0); // 30 total stats feels strong
    final base = 0.15 + (normLevel * 0.35) + (normPower * 0.5);
    return base.clamp(0.15, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sizes per spec: Large 140-160dp, Mini 44-54dp
    final size = widget.isLarge ? 152.0 : 52.0;
    final haloSize = widget.isLarge ? 184.0 : 78.0;
    final glow = _intensity; // 0.15 - 1.0

    // Soft palette (avoid neon): teal/cyan/white mixes
    final softTeal = Colors.tealAccent.withValues(alpha: 0.8);
    final softCyan = Colors.cyanAccent.withValues(alpha: 0.75);
    final softWhite = Colors.white.withValues(alpha: 0.85);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.985 : 1.0,
        child: SizedBox(
          width: haloSize,
          height: haloSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Faint halo ring behind avatar
              Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12 + 0.06 * glow),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08 * glow),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Shoulders/torso silhouette (large oval, softly blurred via shadow)
              Transform.translate(
                offset: Offset(0, size * 0.08),
                child: Container(
                  width: size * 0.95,
                  height: size * 0.64,
                  decoration: BoxDecoration(
                    color: Color.lerp(softTeal, softWhite, 0.35)!.withValues(alpha: 0.22 + 0.18 * glow),
                    borderRadius: BorderRadius.circular(size),
                    boxShadow: [
                      BoxShadow(
                        color: softCyan.withValues(alpha: 0.18 * glow),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Head silhouette (smaller circle above)
              Transform.translate(
                offset: Offset(0, -size * 0.18),
                child: Container(
                  width: size * 0.44,
                  height: size * 0.44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(softCyan, softWhite, 0.5)!.withValues(alpha: 0.25 + 0.2 * glow),
                    boxShadow: [
                      BoxShadow(
                        color: softTeal.withValues(alpha: 0.16 * glow),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================
// Soul Avatar v2.0 — Full-body
// ================================

/// Two preset sizes used around the app.
enum SoulAvatarSize { mini, large }

/// Calm, glowing, gender/race-neutral full-body soul made of soft light.
/// - Head, torso, arms + hands, legs + feet
/// - Subtle breathing scale and glow pulse
/// - Colors derived from theme; avoids neon
class SoulAvatarViewV2 extends StatefulWidget {
  final int level;
  final double faithPower;
  final SoulAvatarSize size;

  const SoulAvatarViewV2({
    super.key,
    required this.level,
    required this.faithPower,
    required this.size,
  });

  bool get isLarge => size == SoulAvatarSize.large;

  @override
  State<SoulAvatarViewV2> createState() => _SoulAvatarViewV2State();
}

class _SoulAvatarViewV2State extends State<SoulAvatarViewV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _intensity {
    // Map level and faithPower to 0.2–1.0; mini is softer.
    final lvl = widget.level.clamp(1, 100);
    final fp = widget.faithPower.isNaN ? 0.0 : widget.faithPower;
    final normLevel = (lvl / 40.0).clamp(0.0, 1.0);
    final normPower = (fp / 40.0).clamp(0.0, 1.0);
    final base = 0.2 + (normLevel * 0.35) + (normPower * 0.45);
    final v = base.clamp(0.2, 1.0);
    // v2.1: mini avatar glow reduced by ~40% (keep it calmer)
    return widget.isLarge ? v : v * 0.60;
  }

  // v2.1 sizing per spec: Large ~168–180, Mini ~56–62
  double get _height => widget.size == SoulAvatarSize.large ? 176 : 60;

  @override
  Widget build(BuildContext context) {
    final height = _height;
    final haloSize = widget.isLarge ? height + 26 : height + 18;
    final intensity = _intensity; // 0.2–1.0 (scaled softer for mini)

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Breathing scale 1.00 → 1.03.
        final t = _ctrl.value; // 0..1
        final wave = (1 + math.sin(2 * math.pi * t)) * 0.5; // 0..1
        final amp = 0.015 + 0.015 * intensity; // 0.015..0.03
        final scale = 1.0 + amp * wave;
        final glowOpacity = 0.7 + 0.3 * wave; // 0.7..1.0

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: haloSize,
            height: haloSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft halo ring
                Container(
                  width: haloSize,
                  height: haloSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12 + 0.08 * intensity),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.12 * intensity),
                        blurRadius: widget.isLarge ? 28 : 18,
                        spreadRadius: widget.isLarge ? 2 : 1,
                      ),
                    ],
                  ),
                ),
                // Base PNG silhouette (use DecorationImage to avoid web fittedSizes issue)
                SizedBox(
                  width: height * 0.68,
                  height: height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/avatar/soul_avatar_base.png'),
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: 0.86 * intensity),
                          BlendMode.srcATop,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Soul Avatar v2.1 — unified, smooth silhouette using a single Path.
class SoulAvatarPainterV21 extends CustomPainter {
  final Color primary;
  final Color secondary;
  final double intensity; // 0.0–1.0
  final bool mini;

  const SoulAvatarPainterV21({
    required this.primary,
    required this.secondary,
    required this.intensity,
    required this.mini,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;

    // --------------------------------------------------
    // B) HALO behind silhouette (soft gradient circle — no blur mask to
    //    avoid CanvasKit issues on web)
    // --------------------------------------------------
    final haloCenter = Offset(centerX, h * 0.55);
    final haloRadius = w * 0.55;
    final haloOuter = Paint()
      ..color = Colors.white.withValues(alpha: 0.08 * (mini ? 0.8 : 1.0) * intensity)
      ..style = PaintingStyle.fill;
    final haloInner = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 * (mini ? 0.8 : 1.0) * intensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(haloCenter, haloRadius, haloOuter);
    canvas.drawCircle(haloCenter, haloRadius * 0.7, haloInner);

    // --------------------------------------------------
    // A) Proportions & unified path
    // --------------------------------------------------
    final headHeight = 0.18 * h;
    final torsoHeight = 0.32 * h;
    final legHeight = 0.38 * h;

    final bodyWidth = 0.38 * w;
    final shoulderWidth = 0.52 * w;
    final legWidth = 0.22 * w;
    final headRadius = headHeight * 0.5;

    final leftLegTop = headHeight + torsoHeight;
    final rightLegTop = leftLegTop;

    final p = Path();

    // HEAD (circle)
    p.addOval(Rect.fromCircle(
      center: Offset(centerX, headRadius),
      radius: headRadius,
    ));

    // NECK BRIDGE (tiny curve)
    p.moveTo(centerX - (headRadius * 0.4), headHeight);
    p.quadraticBezierTo(
      centerX, headHeight + (headRadius * 0.2),
      centerX + (headRadius * 0.4),
      headHeight,
    );

    // SHOULDERS + LEFT TORSO SIDE
    p.moveTo(centerX - (shoulderWidth / 2), headHeight);
    p.quadraticBezierTo(
      centerX - (shoulderWidth / 2) - 4, headHeight + 20,
      centerX - (bodyWidth / 2), headHeight + 40,
    );
    p.lineTo(centerX - (bodyWidth / 2), headHeight + torsoHeight - 20);

    // WAIST taper to center
    p.quadraticBezierTo(
      centerX - (bodyWidth / 2) + 12, headHeight + torsoHeight,
      centerX, headHeight + torsoHeight,
    );

    // RIGHT TORSO SIDE (mirror)
    p.quadraticBezierTo(
      centerX + (bodyWidth / 2) - 12, headHeight + torsoHeight,
      centerX + (bodyWidth / 2), headHeight + torsoHeight - 20,
    );
    p.lineTo(centerX + (bodyWidth / 2), headHeight + 40);
    p.quadraticBezierTo(
      centerX + (shoulderWidth / 2) + 4, headHeight + 20,
      centerX + (shoulderWidth / 2), headHeight,
    );
    // Close torso top via a subtle arc across shoulders
    p.quadraticBezierTo(centerX, headHeight - 6, centerX - (shoulderWidth / 2), headHeight);

    // LEGS mass added as smooth rounded block (outer separation is visual only)

    // Add a smooth combined legs mass as a rounded rect so the lower
    // body is filled (the inner separation will be painted with a soft
    // gradient overlay, not a hard line).
    final legsRect = Rect.fromCenter(
      center: Offset(centerX, leftLegTop + legHeight / 2),
      width: legWidth * 1.2,
      height: legHeight,
    );
    p.addRRect(RRect.fromRectAndRadius(legsRect, Radius.circular(h * 0.12)));

    // --------------------------------------------------
    // Body fill (solid soft light to avoid web gradient issues)
    // --------------------------------------------------
    final bodyColor = Color.lerp(primary, Colors.white, 0.8)!
        .withValues(alpha: (mini ? 0.28 : 0.34) * (0.9 + 0.1 * intensity));
    final fill = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Clip to path so inner shading stays within silhouette
    canvas.save();
    canvas.drawPath(p, fill);

    // Inner leg separation as translucent vertical gradient (not a line)
    final sepWidth = w * 0.08;
    final sepRect = Rect.fromCenter(
      center: Offset(centerX, leftLegTop + legHeight * 0.55),
      width: sepWidth,
      height: legHeight * 0.95,
    );
    canvas.save();
    canvas.clipPath(p);
    final sepPaint = Paint()
      ..color = Colors.white.withValues(alpha: (mini ? 0.05 : 0.08) * intensity)
      ..blendMode = BlendMode.srcOver;
    canvas.drawRRect(
      RRect.fromRectAndRadius(sepRect, Radius.circular(h * 0.08)),
      sepPaint,
    );
    canvas.restore();

    // --------------------------------------------------
    // Rim light stroke around silhouette
    // --------------------------------------------------
    final rimAlpha = (mini ? 0.06 : 0.10) * (0.9 + 0.1 * intensity);
    final rim = Paint()
      ..color = Colors.white.withValues(alpha: rimAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, rim);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SoulAvatarPainterV21 oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.intensity != intensity ||
        oldDelegate.mini != mini;
  }
}
