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
    this.size = 168,
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
    // Two coronas, always in the same order, cross-faded by intensity: a
    // steady one that burns down as the reading begins and a taller, quicker
    // one that rises through it.
    _corona(
      canvas,
      center,
      r,
      phase: slow,
      beatA: 28,
      beatB: 17,
      count: 15,
      reach: 0.20,
      alpha: 1.0 - 0.45 * intensity,
    );
    _corona(
      canvas,
      center,
      r,
      phase: fast,
      beatA: 16,
      beatB: 11,
      count: 21,
      reach: 0.34,
      alpha: intensity,
    );
    _ring(canvas, center, r * 0.78, slow, 1.4, _gold(0.55));
    if (intensity > 0.01) {
      _ring(canvas, center, r * 0.88, fast, 2.0, _goldHi(0.85 * intensity));
    }
    _ticks(canvas, center, r);
    _core(canvas, center, r);
    _sparks(canvas, center, r);
  }

  /// A ring of tongues standing off the core.
  ///
  /// The whole corona is one path, so a crowded frame costs a single blur and
  /// a single draw instead of twenty-one of each — this runs on a phone
  /// inside Telegram, sixty times a second, behind a full-bleed photograph.
  ///
  /// [beatA] and [beatB] are whole numbers of flickers per turn of the clock
  /// driving them. Whole, deliberately: a fractional rate would jump the
  /// instant the controller wraps from one back to zero. Two coprime rates
  /// beat against each other, which is what stops the flames pulsing in time
  /// with one another like a machine.
  void _corona(
    Canvas canvas,
    Offset center,
    double r, {
    required double phase,
    required int beatA,
    required int beatB,
    required int count,
    required double reach,
    required double alpha,
  }) {
    if (alpha <= 0.01) return;
    final base = r * 0.33;
    final half = r * 0.055;
    final path = Path();
    for (var i = 0; i < count; i++) {
      final wa = math.sin((phase * beatA + i * 0.381) * math.pi * 2);
      final wb = math.sin((phase * beatB + i * 0.117) * math.pi * 2);
      final swell = (wa * 0.6 + wb * 0.4) * 0.5 + 0.5;
      final len = r * reach * (0.45 + 0.55 * swell);
      _addTongue(
        path,
        i * math.pi * 2 / count,
        base,
        len,
        half,
        (wa - wb) * 0.09,
      );
    }
    // Additive: where tongues overlap they brighten, the way light does and
    // paint does not. The gradient is built around the origin so it survives
    // the translate below unmoved — a radial gradient is indifferent to it.
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2)
      ..shader = RadialGradient(
        colors: [
          AppPalette.goldHi.withValues(alpha: 0.80 * alpha),
          accent.withValues(alpha: 0.50 * alpha),
          accent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset.zero, radius: base + r * reach),
      );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// One tongue, built already rotated so it can join the shared path. The
  /// points are turned by hand rather than by a canvas transform, because a
  /// transform would have to be pushed and popped for every single flame.
  void _addTongue(
    Path path,
    double angle,
    double base,
    double len,
    double half,
    double lean,
  ) {
    final ca = math.cos(angle);
    final sa = math.sin(angle);
    Offset at(double x, double y) => Offset(x * ca - y * sa, x * sa + y * ca);

    final tip = base + len;
    final mid = base + len * 0.55;
    final sway = lean * len;
    final root = at(base, -half);
    final belly1 = at(mid, -half * 1.15 + sway);
    final crown = at(tip, sway);
    final belly2 = at(mid, half * 1.15 + sway);
    final heel = at(base, half);
    path.moveTo(root.dx, root.dy);
    path.quadraticBezierTo(belly1.dx, belly1.dy, crown.dx, crown.dy);
    path.quadraticBezierTo(belly2.dx, belly2.dy, heel.dx, heel.dy);
    path.close();
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
      canvas.drawCircle(at, 2.0 + 1.4 * intensity, paint);
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
