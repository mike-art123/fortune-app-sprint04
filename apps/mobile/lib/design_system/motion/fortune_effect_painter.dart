import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'ambient_motion.dart';
import 'fortune_effects.dart';

const double _tau = math.pi * 2;

/// Paints a card's ambient layers for one moment of the shared clock.
///
/// The painter is stateless on purpose: every particle is a pure function of
/// (seed, index, time), so nothing accumulates, a paused clock is simply a
/// held frame, and a test can ask for second 8 twice and get the same pixels.
/// With a [clock] it repaints on every tick; without one it paints a single
/// still frame at [stillSeconds] — chosen mid-loop, so screenshots and
/// reduced-motion readers still see the card alive, just quiet.
class FortuneEffectPainter extends CustomPainter {
  FortuneEffectPainter({
    required this.spec,
    required this.accent,
    required this.seed,
    required this.alignment,
    this.clock,
    this.stillSeconds = 8,
  }) : super(repaint: clock);

  final FortuneEffectSpec spec;
  final Color accent;
  final int seed;
  final Alignment alignment;
  final AmbientMotionClock? clock;
  final double stillSeconds;

  static const MaskFilter _softBlur = MaskFilter.blur(BlurStyle.normal, 5);

  static const MaskFilter _dotBlur = MaskFilter.blur(BlurStyle.normal, 1);

  final Paint _dotPaint = Paint()
    ..maskFilter = _dotBlur
    ..blendMode = BlendMode.plus;
  final Paint _wispPaint = Paint()
    ..maskFilter = _softBlur
    ..blendMode = BlendMode.plus;
  final Paint _glowPaint = Paint()..blendMode = BlendMode.plus;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = clock?.elapsedSeconds ?? stillSeconds;
    for (var i = 0; i < spec.layers.length; i += 1) {
      final layer = spec.layers[i];
      final layerSeed = seed + i * 131;
      switch (layer.kind) {
        case FortuneEffectKind.steam:
          _paintSteam(canvas, size, layer, layerSeed, t);
        case FortuneEffectKind.flame:
          _paintFlame(canvas, size, layer, layerSeed, t);
        case FortuneEffectKind.sparkle:
          _paintSparkle(canvas, size, layer, layerSeed, t);
        case FortuneEffectKind.glow:
          _paintGlow(canvas, size, layer, layerSeed, t);
      }
    }
  }

  /// A card-size factor so a particle keeps its weight from the small
  /// carousel tile to the wide hero.
  double _weight(Size size) {
    return (size.shortestSide / 300).clamp(0.6, 1.6).toDouble();
  }

  double _frac(double value) => value - value.floorToDouble();

  Color _tint(FortuneEffectLayerSpec layer) => layer.color ?? accent;

  /// Rising, swaying trail — steam from a cup, or smoke when tinted grey.
  void _paintSteam(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    int layerSeed,
    double t,
  ) {
    final anchor = mapCoverPoint(layer.anchor, size, alignment);
    final weight = _weight(size);
    final color = _tint(layer);
    final height = size.height * 0.34 * layer.intensity;
    final wisps = layer.count > 0 ? layer.count : 3;
    for (var w = 0; w < wisps; w += 1) {
      final rise = 6.5 + effectRandom(layerSeed, w, 11) * 2.5;
      final phase = effectRandom(layerSeed, w, 12);
      final swayPhase = effectRandom(layerSeed, w, 13) * _tau;
      final head = _frac(t / rise + phase);
      for (var j = 0; j < 9; j += 1) {
        final u = _frac(head - j * 0.05);
        final sway = size.shortestSide * 0.05 * (0.35 + 0.65 * u);
        final wave = math.sin(u * 5.2 + swayPhase);
        final ripple = math.sin(u * 11.7 + swayPhase * 2);
        final dx = (wave + ripple * 0.35) * sway;
        final position = Offset(anchor.dx + dx, anchor.dy - u * height);
        final fade = math.sin(math.pi * u) * (1 - 0.4 * u);
        final alpha = 0.12 * layer.intensity * fade;
        if (alpha <= 0.005) continue;
        _wispPaint.color = color.withValues(alpha: alpha);
        canvas.drawCircle(position, (1.5 + u * 7) * weight, _wispPaint);
      }
    }
  }

  /// Flicker halo with a bright core and a few embers letting go.
  void _paintFlame(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    int layerSeed,
    double t,
  ) {
    final anchor = mapCoverPoint(layer.anchor, size, alignment);
    final weight = _weight(size);
    final color = layer.color ?? const Color(0xFFFFC66B);
    final phaseA = effectRandom(layerSeed, 0, 21) * _tau;
    final phaseB = effectRandom(layerSeed, 0, 22) * _tau;
    var flicker = 0.78;
    flicker += 0.14 * math.sin(t * 6.8 + phaseA);
    flicker += 0.08 * math.sin(t * 11.4 + phaseB);
    final level = flicker.clamp(0.5, 1.1).toDouble();
    final radius = size.shortestSide * 0.11 * layer.intensity * level;
    _drawRadialGlow(canvas, anchor, radius, color, 0.22 * level);
    _drawRadialGlow(canvas, anchor, radius * 0.38, color, 0.34 * level);
    for (var e = 0; e < 4; e += 1) {
      final life = 2.6 + effectRandom(layerSeed, e, 23) * 1.8;
      final u = _frac(t / life + effectRandom(layerSeed, e, 24));
      final drift = (effectRandom(layerSeed, e, 25) - 0.5) * radius * 1.6;
      final position = Offset(
        anchor.dx + drift * (0.4 + 0.6 * u),
        anchor.dy - u * size.shortestSide * 0.18,
      );
      final alpha = 0.3 * layer.intensity * math.sin(math.pi * u);
      if (alpha <= 0.01) continue;
      _dotPaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(position, 1.2 * weight, _dotPaint);
    }
  }

  /// Slow-drifting motes that breathe in and out of brightness.
  void _paintSparkle(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    int layerSeed,
    double t,
  ) {
    final anchor = mapCoverPoint(layer.anchor, size, alignment);
    final weight = _weight(size);
    final color = _tint(layer);
    final scale = coverScale(size);
    final spreadX = layer.spread.dx * kFortuneArtSize.width * scale;
    final spreadY = layer.spread.dy * kFortuneArtSize.height * scale;
    final count = layer.count > 0 ? layer.count : 12;
    for (var i = 0; i < count; i += 1) {
      final jitterX = effectRandom(layerSeed, i, 1) * 2 - 1;
      final jitterY = effectRandom(layerSeed, i, 2) * 2 - 1;
      final orbit = _tau * (t / 24 + effectRandom(layerSeed, i, 3));
      final position = Offset(
        anchor.dx + jitterX * spreadX + math.cos(orbit) * 2.2 * weight,
        anchor.dy + jitterY * spreadY + math.sin(orbit) * 2.2 * weight,
      );
      final period = 2.2 + effectRandom(layerSeed, i, 4) * 2.6;
      final beat = t / period + effectRandom(layerSeed, i, 5);
      final twinkle = 0.5 + 0.5 * math.sin(_tau * beat);
      final alpha = layer.intensity * 0.4 * twinkle * twinkle;
      if (alpha <= 0.01) continue;
      final radius = (0.65 + effectRandom(layerSeed, i, 6) * 1.1) * weight;
      _dotPaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(position, radius, _dotPaint);
      if (i % 4 == 0) {
        _wispPaint.color = color.withValues(alpha: alpha * 0.12);
        canvas.drawCircle(position, radius * 2.4, _wispPaint);
      }
    }
  }

  /// A halo that breathes — hearts, moons, emblems, crystal light.
  void _paintGlow(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    int layerSeed,
    double t,
  ) {
    final anchor = mapCoverPoint(layer.anchor, size, alignment);
    final period = 4.5 + effectRandom(layerSeed, 0, 31) * 2;
    final beat = t / period + effectRandom(layerSeed, 0, 32);
    final breath = 0.5 + 0.5 * math.sin(_tau * beat);
    final reach = 0.9 + 0.12 * breath;
    final radius = size.shortestSide * 0.2 * layer.intensity * reach;
    final alpha = 0.14 * layer.intensity * (0.65 + 0.35 * breath);
    _drawRadialGlow(canvas, anchor, radius, _tint(layer), alpha);
  }

  void _drawRadialGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    if (radius <= 0 || alpha <= 0.005) return;
    _glowPaint.shader = ui.Gradient.radial(
      center,
      radius,
      [
        color.withValues(alpha: alpha),
        color.withValues(alpha: alpha * 0.45),
        color.withValues(alpha: 0),
      ],
      [0, 0.55, 1],
    );
    canvas.drawCircle(center, radius, _glowPaint);
  }

  @override
  bool shouldRepaint(FortuneEffectPainter oldDelegate) {
    return oldDelegate.spec != spec ||
        oldDelegate.accent != accent ||
        oldDelegate.seed != seed ||
        oldDelegate.alignment != alignment ||
        oldDelegate.clock != clock;
  }
}
