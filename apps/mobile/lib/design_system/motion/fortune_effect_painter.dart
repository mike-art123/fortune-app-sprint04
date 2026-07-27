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
  final Paint _lidPaint = Paint()..color = const Color(0xFFFFFFFF);
  final Paint _lidAddPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..blendMode = BlendMode.plus;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = clock?.elapsedSeconds ?? stillSeconds;
    final blink = _blinkClosureAt(t);
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
          _paintGlow(canvas, size, layer, layerSeed, t, dim: blink);
        case FortuneEffectKind.blink:
          _paintBlink(canvas, size, layer, blink);
      }
    }
  }

  /// How shut this card's eye is right now — 0 on cards that never blink.
  double _blinkClosureAt(double t) {
    for (final layer in spec.layers) {
      final eye = layer.eye;
      if (layer.kind == FortuneEffectKind.blink && eye != null) {
        return blinkClosure(seed, t, period: eye.blinkPeriod);
      }
    }
    return 0;
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
  ///
  /// [dim] is the card's blink closure: an amulet's light falls while its
  /// lids are shut, and comes back as they open.
  void _paintGlow(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    int layerSeed,
    double t, {
    double dim = 0,
  }) {
    final anchor = mapCoverPoint(layer.anchor, size, alignment);
    final period = 4.5 + effectRandom(layerSeed, 0, 31) * 2;
    final beat = t / period + effectRandom(layerSeed, 0, 32);
    final breath = 0.5 + 0.5 * math.sin(_tau * beat);
    final reach = 0.9 + 0.12 * breath;
    final intensity = layer.intensity * (1 - 0.55 * dim);
    final radius = size.shortestSide * 0.2 * intensity * reach;
    final alpha = 0.14 * intensity * (0.65 + 0.35 * breath);
    _drawRadialGlow(canvas, anchor, radius, _tint(layer), alpha);
  }

  // Lid geometry in artwork pixels: front-edge overlap past the closure
  // line so the shut seam never leaks eyeball, seam and catch-light bands
  // hugging the moving edge, and the shadow the lid throws on the eye.
  static const double _lidOverlapPx = 2.5;
  static const double _lidSeamPx = 3;
  static const double _lidCatchPx = 4.4;
  static const double _lidCatchHalfPx = 1.5;
  static const double _lidShadowPx = 10;
  static const int _lidSamples = 48;

  // Lid palette: warm skin-bronze — attachment, lit belly, seam shadow.
  // The upper belly carries the folded-in sheen peak; the lower lid sits
  // deeper in the frame's shadow.
  static const List<double> _lidTopRgb = [104, 76, 50];
  static const List<double> _lidMidUpperRgb = [169, 131, 91];
  static const List<double> _lidMidLowerRgb = [164, 126, 86];
  static const List<double> _lidSeamRgb = [50, 33, 20];
  static const List<double> _lidCatchRgb = [196, 152, 92];

  /// Two lids slide over the fixed eyeball and meet at the closure line.
  ///
  /// Geometry runs in artwork space and maps through the same cover crop as
  /// every anchor; shading runs as per-vertex colour strips, so it follows
  /// the curved lids exactly. Between blinks this paints nothing at all.
  void _paintBlink(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    double closure,
  ) {
    final eye = layer.eye;
    if (eye == null || closure <= 0.005) return;

    final columns = List<_LidColumn>.generate(_lidSamples, (i) {
      final u = i / (_lidSamples - 1);
      final top = eye.upperY(u);
      final bottom = math.max(eye.lowerY(u), top);
      final meet = top + eye.closureDepth * (bottom - top);
      return _LidColumn(
        u: u,
        x: eye.xLeft + u * (eye.xRight - eye.xLeft),
        top: top,
        bottom: bottom,
        upperFront: top + closure * (meet - top + _lidOverlapPx),
        lowerFront: bottom - closure * (bottom - meet + _lidOverlapPx),
      );
    });

    Offset mapArt(double x, double y) {
      return mapCoverPoint(
        Offset(x / kFortuneArtSize.width, y / kFortuneArtSize.height),
        size,
        alignment,
      );
    }

    List<Offset> row(double Function(_LidColumn c) y) {
      return [for (final c in columns) mapArt(c.x, y(c))];
    }

    double vignette(double u) => 0.72 + 0.28 * math.sin(u * math.pi);

    List<Color> tones(List<double> rgb, double shade) {
      return [
        for (final c in columns) _lidTone(rgb, shade * vignette(c.u)),
      ];
    }

    List<Color> flat(Color color) => List<Color>.filled(_lidSamples, color);

    final topRow = row((c) => c.top);
    final bottomRow = row((c) => c.bottom);
    final upperFrontRow = row((c) => c.upperFront);
    final lowerFrontRow = row((c) => c.lowerFront);
    final upperMidRow = row((c) => c.top + 0.55 * (c.upperFront - c.top));
    final lowerMidRow = row(
      (c) => c.bottom - 0.55 * (c.bottom - c.lowerFront),
    );

    final opening = Path()..moveTo(topRow.first.dx, topRow.first.dy);
    for (final p in topRow.skip(1)) {
      opening.lineTo(p.dx, p.dy);
    }
    for (final p in bottomRow.reversed) {
      opening.lineTo(p.dx, p.dy);
    }
    opening.close();

    const upShade = 0.88;
    const loShade = 0.82;
    const clear = Color(0x00000000);
    const seamInk = Color(0x8C000000);
    final shadowInk = Color.fromARGB((closure * 0.45 * 255).round(), 0, 0, 0);
    final catchPeak = flat(_lidTone(_lidCatchRgb, 1, 0.15));
    final catchNone = flat(_lidTone(_lidCatchRgb, 1, 0));

    canvas.save();
    canvas.clipPath(opening);

    // The upper lid throws a soft shadow ahead of itself onto the eyeball.
    _drawLidStrip(
      canvas,
      upperFrontRow,
      row((c) => c.upperFront + _lidShadowPx),
      flat(shadowInk),
      flat(clear),
      _lidPaint,
    );

    // Upper lid: attachment -> lit belly -> seam shadow, then the dark
    // front-edge seam and the thin catch-light riding just inside it.
    _drawLidStrip(
      canvas,
      topRow,
      upperMidRow,
      tones(_lidTopRgb, upShade),
      tones(_lidMidUpperRgb, upShade),
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      upperMidRow,
      upperFrontRow,
      tones(_lidMidUpperRgb, upShade),
      tones(_lidSeamRgb, upShade),
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      row((c) => c.upperFront - _lidSeamPx),
      upperFrontRow,
      flat(clear),
      flat(seamInk),
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      row((c) => c.upperFront - _lidCatchPx - _lidCatchHalfPx),
      row((c) => c.upperFront - _lidCatchPx),
      catchNone,
      catchPeak,
      _lidAddPaint,
    );
    _drawLidStrip(
      canvas,
      row((c) => c.upperFront - _lidCatchPx),
      row((c) => c.upperFront - _lidCatchPx + _lidCatchHalfPx),
      catchPeak,
      catchNone,
      _lidAddPaint,
    );

    // Lower lid, mirrored: it travels less and sits deeper in shadow.
    _drawLidStrip(
      canvas,
      bottomRow,
      lowerMidRow,
      tones(_lidTopRgb, loShade),
      tones(_lidMidLowerRgb, loShade),
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      lowerMidRow,
      lowerFrontRow,
      tones(_lidMidLowerRgb, loShade),
      tones(_lidSeamRgb, loShade),
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      lowerFrontRow,
      row((c) => c.lowerFront + _lidSeamPx),
      flat(seamInk),
      flat(clear),
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      row((c) => c.lowerFront + _lidCatchPx - _lidCatchHalfPx),
      row((c) => c.lowerFront + _lidCatchPx),
      catchNone,
      catchPeak,
      _lidAddPaint,
    );
    _drawLidStrip(
      canvas,
      row((c) => c.lowerFront + _lidCatchPx),
      row((c) => c.lowerFront + _lidCatchPx + _lidCatchHalfPx),
      catchPeak,
      catchNone,
      _lidAddPaint,
    );

    canvas.restore();
  }

  /// One curved ribbon of the lid, coloured per vertex so the gradient
  /// follows the lid's own depth, column by column.
  void _drawLidStrip(
    Canvas canvas,
    List<Offset> top,
    List<Offset> bottom,
    List<Color> topColors,
    List<Color> bottomColors,
    Paint paint,
  ) {
    final positions = <Offset>[];
    final colors = <Color>[];
    for (var i = 0; i < top.length; i += 1) {
      positions
        ..add(top[i])
        ..add(bottom[i]);
      colors
        ..add(topColors[i])
        ..add(bottomColors[i]);
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangleStrip,
      positions,
      colors: colors,
    );
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
  }

  Color _lidTone(List<double> rgb, double factor, [double opacity = 1]) {
    return Color.fromARGB(
      (opacity * 255).round(),
      (rgb[0] * factor).clamp(0, 255).round(),
      (rgb[1] * factor).clamp(0, 255).round(),
      (rgb[2] * factor).clamp(0, 255).round(),
    );
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

/// One sampled column of a blinking eye, artwork space.
class _LidColumn {
  const _LidColumn({
    required this.u,
    required this.x,
    required this.top,
    required this.bottom,
    required this.upperFront,
    required this.lowerFront,
  });

  final double u;
  final double x;
  final double top;
  final double bottom;
  final double upperFront;
  final double lowerFront;
}
