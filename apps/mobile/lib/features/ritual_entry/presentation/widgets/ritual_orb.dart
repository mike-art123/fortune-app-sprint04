import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../design_system/foundations/app_colors.dart';

/// The anchor at the head of every ritual: a painted orb that is alive before
/// you speak and transfigured while it listens.
///
/// It replaces a flat disc and a photograph of a light bulb. Both read as
/// placeholders — the disc because nothing in a divination app should sit
/// perfectly still, the photograph because a JPEG cannot take the fortune's
/// own accent colour and cannot pick up when the reading begins.
///
/// Nothing here is an asset. The whole thing is drawn, so it inherits
/// [accent] from the registry and every fortune gets an orb in its own colour
/// without another forty images in the bundle.
class RitualOrb extends StatefulWidget {
  const RitualOrb({
    super.key,
    required this.accent,
    this.sealing = false,
    this.size = 120,
  });

  /// The fortune's own colour, from the registry.
  final Color accent;

  /// True from the moment the intention is sealed until the reading arrives.
  final bool sealing;

  final double size;

  @override
  State<RitualOrb> createState() => _RitualOrbState();
}

class _RitualOrbState extends State<RitualOrb> with TickerProviderStateMixin {
  // Three separate clocks rather than one clock at a variable rate. A single
  // controller sped up mid-cycle jumps the moment its value wraps past one;
  // two rings at fixed speeds, cross-faded by intensity, read as acceleration
  // and cannot tear.
  late final AnimationController _slow;
  late final AnimationController _fast;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _slow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _fast = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Started here rather than in initState because the answer depends on
    // MediaQuery, which initState cannot read.
    _syncMotion(context.reduceMotion);
  }

  /// The app's motion contract, which FortuneFadeIn already keeps: when the
  /// reader has asked their device for less movement, the orb holds still. It
  /// stays lit and stays the fortune's colour — only the turning stops.
  void _syncMotion(bool still) {
    if (still) {
      _slow.stop();
      _fast.stop();
      _breath.stop();
      return;
    }
    if (!_slow.isAnimating) _slow.repeat();
    if (!_fast.isAnimating) _fast.repeat();
    if (!_breath.isAnimating) _breath.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slow.dispose();
    _fast.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sealing is eased in over most of a second instead of switched, so the
    // orb catches light the way a flame does rather than blinking on.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: widget.sealing ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, intensity, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([_slow, _fast, _breath]),
          builder: (context, __) {
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _OrbPainter(
                slow: _slow.value,
                fast: _fast.value,
                breath: Curves.easeInOut.transform(_breath.value),
                intensity: intensity,
                accent: widget.accent,
              ),
            );
          },
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.slow,
    required this.fast,
    required this.breath,
    required this.intensity,
    required this.accent,
  });

  /// All three are 0..1 phases, not angles — the painter decides what a turn
  /// means so the widget never has to think in radians.
  final double slow;
  final double fast;
  final double breath;

  /// 0 at rest, 1 while the reading is being sealed.
  final double intensity;

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    _aura(canvas, center, r);
    _ring(canvas, center, r * 0.78, slow, 1.4, _gold(0.55));
    if (intensity > 0.01) {
      _ring(canvas, center, r * 0.88, fast, 2.0, _goldHi(0.85 * intensity));
    }
    _ticks(canvas, center, r);
    _core(canvas, center, r);
    _sparks(canvas, center, r);
  }

  Color _gold(double alpha) => AppPalette.goldMid.withValues(alpha: alpha);

  Color _goldHi(double alpha) => AppPalette.goldHi.withValues(alpha: alpha);

  /// The breath: a wide halo that swells and settles, brighter while sealing.
  void _aura(Canvas canvas, Offset center, double r) {
    final radius = r * (0.92 + 0.08 * breath + 0.06 * intensity);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.34 + 0.26 * intensity),
          accent.withValues(alpha: 0.10 + 0.10 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  /// One turning arc of light. The canvas is rotated rather than the gradient,
  /// which keeps this to APIs that cannot be got subtly wrong.
  void _ring(
    Canvas canvas,
    Offset center,
    double radius,
    double phase,
    double width,
    Color color,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = SweepGradient(
        colors: [Colors.transparent, color, Colors.transparent, color],
        stops: const [0.0, 0.16, 0.44, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(phase * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }

  /// Twelve marks turning the other way — the astrolabe note the backdrop
  /// artwork already strikes, so the orb belongs to the same drawing.
  void _ticks(Canvas canvas, Offset center, double r) {
    const count = 12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = _gold(0.30 + 0.35 * intensity);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-slow * math.pi * 2);
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count;
      final inner = r * 0.62;
      final outer = r * (i.isEven ? 0.72 : 0.675);
      canvas.drawLine(
        Offset(math.cos(a) * inner, math.sin(a) * inner),
        Offset(math.cos(a) * outer, math.sin(a) * outer),
        paint,
      );
    }
    canvas.restore();
  }

  /// The pearl itself: a blurred bloom, a lit sphere, a hairline rim.
  void _core(Canvas canvas, Offset center, double r) {
    final radius = r * 0.34;
    final bloom = Paint()
      ..color = accent.withValues(alpha: 0.45 + 0.35 * intensity)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        10.0 + 10.0 * intensity,
      );
    canvas.drawCircle(center, radius * 1.05, bloom);

    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.42),
        radius: 0.95,
        colors: [
          Color.lerp(AppPalette.goldHi, Colors.white, intensity * 0.6)!,
          accent,
          Color.lerp(accent, AppPalette.nightDeep, 0.55)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sphere);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _goldHi(0.35 + 0.40 * intensity);
    canvas.drawCircle(center, radius, rim);
  }

  /// Motes in orbit. Half ride the slow clock and half the fast one, so the
  /// ring never looks like a machine turning at one speed.
  void _sparks(Canvas canvas, Offset center, double r) {
    const count = 6;
    for (var i = 0; i < count; i++) {
      final lane = 0.74 + (i % 3) * 0.07;
      final a = ((i.isEven ? fast : slow) + i / count) * math.pi * 2;
      final d = r * lane;
      final at = center + Offset(math.cos(a) * d, math.sin(a) * d);
      final paint = Paint()
        ..color = _goldHi((0.25 + 0.55 * intensity) * (i.isEven ? 1.0 : 0.7))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
      canvas.drawCircle(at, 1.6 + 1.2 * intensity, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) {
    return old.slow != slow ||
        old.fast != fast ||
        old.breath != breath ||
        old.intensity != intensity ||
        old.accent != accent;
  }
}
