import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'ambient_motion.dart';
import 'fortune_effects.dart';
import 'fortune_hourglass.dart';

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
        case FortuneEffectKind.hourglass:
          _paintHourglass(canvas, size, layer, t);
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

  /// Maps an artwork-pixel point through the cover crop, like every anchor.
  Offset _artPoint(Size size, double x, double y) {
    return mapCoverPoint(
      Offset(x / kFortuneArtSize.width, y / kFortuneArtSize.height),
      size,
      alignment,
    );
  }

  double _band01(double v, double aa) => (v / aa).clamp(0.0, 1.0);

  Color _shade(Color color, double factor) {
    return Color.fromARGB(
      255,
      (color.r * 255 * factor).clamp(0, 255).round(),
      (color.g * 255 * factor).clamp(0, 255).round(),
      (color.b * 255 * factor).clamp(0, 255).round(),
    );
  }

  // Hourglass palette, taken from the replica renders.
  static const int _sandColumns = 36;
  static const Color _sandWarmThroat = Color(0xFF966C42);
  static const Color _sandCoolStreak = Color(0xFFEBF0F8);
  static const Color _sandLipLit = Color(0xFFEED6A6);
  static const Color _sandCrestLit = Color(0xFFF6E1B0);
  static const Color _sandGrain = Color(0xFFF0DBAA);
  static const Color _sandImpact = Color(0xFFF6E2B4);
  static const Color _sandShimmer = Color(0xFFFFCD82);

  /// Six seconds of sand. The top pile drains to empty glass, the bottom
  /// pile grows above its painted crest, grains fall between them — and
  /// the rewind eases it all back under a warm shimmer.
  void _paintHourglass(
    Canvas canvas,
    Size size,
    FortuneEffectLayerSpec layer,
    double t,
  ) {
    final hg = layer.hourglass;
    if (hg == null) return;
    final drain = hg.drainSeconds;
    final rewind = hg.rewindSeconds;
    final p = hourglassProgress(t, drain: drain, rewind: rewind);
    final rewinding = hourglassRewind(t, drain: drain, rewind: rewind);
    if (p > 0.001) {
      _paintHourglassTop(canvas, size, hg, p);
      _paintHourglassBottom(canvas, size, hg, p);
    }
    _paintHourglassStream(canvas, size, hg, p, t, rewinding > 0);
    if (rewinding > 0) {
      final centre = _artPoint(size, hg.neckX, 280);
      final alpha = 0.14 * math.sin(math.pi * rewinding);
      _drawRadialGlow(
        canvas,
        centre,
        150 * coverScale(size),
        _sandShimmer,
        alpha,
      );
    }
  }

  /// The draining top pile: empty glass follows the falling surface.
  void _paintHourglassTop(
    Canvas canvas,
    Size size,
    FortuneHourglassGeometry hg,
    double p,
  ) {
    final edge = (hg.topY0 + 3) + ((hg.topY1 - 2) - (hg.topY0 + 3)) * p;
    final xl = hg.spanLeftAt(edge);
    final xr = hg.spanRightAt(edge);
    final dip = 9 - 5 * p;
    final step = (hg.topX1 - hg.topX0) / (_sandColumns - 1);
    final xs = List<double>.generate(
      _sandColumns,
      (i) => hg.topX0 + i * step,
    );
    final tops = [for (final x in xs) hg.topAt(x)];
    final bots = [for (final x in xs) hg.botAt(x)];

    double curAt(double x) {
      final su = ((x - xl) / math.max(xr - xl, 1e-6)).clamp(0.0, 1.0);
      return edge + dip * 4 * su * (1 - su);
    }

    double coverFactor(double x, double y) {
      final top = hg.topAt(x);
      final bot = hg.botAt(x);
      final inside = _band01(y - top, 1.3) * _band01(bot - y, 1.3);
      final inSpan = x >= xl - 0.5 && x <= xr + 0.5;
      final kept = inSpan ? _band01(y - curAt(x), 1.5) : 0.0;
      return inside * (1 - kept);
    }

    final curs = [for (final x in xs) curAt(x)];
    final covers = List<double>.generate(_sandColumns, (i) {
      final inSpan = xs[i] >= xl - 0.5 && xs[i] <= xr + 0.5;
      final floor = inSpan ? math.max(tops[i], curs[i]) : bots[i];
      return math.min(bots[i], floor);
    });

    final clipTop = [
      for (var i = 0; i < _sandColumns; i += 1)
        _artPoint(size, xs[i], tops[i]),
    ];
    final clipBot = [
      for (var i = 0; i < _sandColumns; i += 1)
        _artPoint(size, xs[i], bots[i]),
    ];
    final region = Path()..moveTo(clipTop.first.dx, clipTop.first.dy);
    for (final o in clipTop.skip(1)) {
      region.lineTo(o.dx, o.dy);
    }
    for (final o in clipBot.reversed) {
      region.lineTo(o.dx, o.dy);
    }
    region.close();
    canvas.save();
    canvas.clipPath(region);

    Color fillAt(double x, double y) {
      final depth = ((y - 190) / 80).clamp(0.0, 1.0);
      final base = _shade(hg.glassAt(x), 1 - 0.22 * depth);
      final dx = (x - hg.neckX) / 46;
      final throat = math.exp(-dx * dx) * ((y - 225) / 30).clamp(0.0, 1.0);
      return Color.lerp(base, _sandWarmThroat, throat * 0.45)!;
    }

    // the fill: an above-blend row easing out of the artwork, then the
    // deepening glass tone, as five stacked ribbons
    double rowY(int i, int k) {
      final blendEnd = math.min(tops[i] + 7, covers[i]);
      if (k == 0) return tops[i];
      if (k == 1) return blendEnd;
      return blendEnd + (covers[i] - blendEnd) * (k - 1) / 4;
    }

    final rowPts = List<List<Offset>>.generate(6, (k) {
      return [
        for (var i = 0; i < _sandColumns; i += 1)
          _artPoint(size, xs[i], rowY(i, k)),
      ];
    });
    final rowColors = List<List<Color>>.generate(6, (k) {
      return List<Color>.generate(_sandColumns, (i) {
        if (k == 0) return hg.aboveAt(xs[i]);
        return fillAt(xs[i], rowY(i, k));
      });
    });
    for (var k = 0; k < 5; k += 1) {
      _drawLidStrip(
        canvas,
        rowPts[k],
        rowPts[k + 1],
        rowColors[k],
        rowColors[k + 1],
        _lidPaint,
      );
    }

    // wall reflection streaks over the emptied glass
    const streakRows = 22;
    final rowStep = (hg.topY1 - hg.topY0) / (streakRows - 1);
    void streak({required bool left}) {
      final width = left ? 3.0 : 2.5;
      final alpha = left ? 0.20 : 0.09;
      final inner = <Offset>[];
      final centre = <Offset>[];
      final outer = <Offset>[];
      final peak = <Color>[];
      final none = <Color>[];
      for (var j = 0; j < streakRows; j += 1) {
        final y = hg.topY0 + j * rowStep;
        final wx = left ? hg.spanLeftAt(y) + 4 : hg.spanRightAt(y) - 4;
        final a = alpha * coverFactor(wx, y);
        inner.add(_artPoint(size, wx - width, y));
        centre.add(_artPoint(size, wx, y));
        outer.add(_artPoint(size, wx + width, y));
        peak.add(_sandCoolStreak.withValues(alpha: a));
        none.add(_sandCoolStreak.withValues(alpha: 0));
      }
      _drawLidStrip(canvas, inner, centre, none, peak, _lidPaint);
      _drawLidStrip(canvas, centre, outer, peak, none, _lidPaint);
    }

    streak(left: true);
    streak(left: false);

    // the descending surface: a bright lip with a soft shadow above it
    List<Offset> lipRow(double off) {
      return [
        for (var i = 0; i < _sandColumns; i += 1)
          _artPoint(size, xs[i], curs[i] + off),
      ];
    }

    final lipPeak = List<Color>.generate(_sandColumns, (i) {
      final w = 0.9 * coverFactor(xs[i], curs[i] + 1.4);
      return _sandLipLit.withValues(alpha: w);
    });
    final lipNone = List<Color>.filled(
      _sandColumns,
      _sandLipLit.withValues(alpha: 0),
    );
    _drawLidStrip(
      canvas,
      lipRow(1.4 - 2.8),
      lipRow(1.4),
      lipNone,
      lipPeak,
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      lipRow(1.4),
      lipRow(1.4 + 2.8),
      lipPeak,
      lipNone,
      _lidPaint,
    );
    final shadowPeak = List<Color>.generate(_sandColumns, (i) {
      final w = 0.35 * coverFactor(xs[i], curs[i] - 2.4);
      return Color.fromARGB((w * 255).round(), 0, 0, 0);
    });
    final shadowNone = List<Color>.filled(
      _sandColumns,
      const Color(0x00000000),
    );
    _drawLidStrip(
      canvas,
      lipRow(-2.4 - 2.0),
      lipRow(-2.4),
      shadowNone,
      shadowPeak,
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      lipRow(-2.4),
      lipRow(-0.4),
      shadowPeak,
      shadowNone,
      _lidPaint,
    );

    canvas.restore();
  }

  /// The growing bottom pile: fresh sand above the painted crest.
  void _paintHourglassBottom(
    Canvas canvas,
    Size size,
    FortuneHourglassGeometry hg,
    double p,
  ) {
    final step = (hg.botX1 - hg.botX0) / (_sandColumns - 1);
    final xs = List<double>.generate(
      _sandColumns,
      (i) => hg.botX0 + i * step,
    );
    final painted = [for (final x in xs) hg.crestAt(x)];
    final curs = [
      for (var i = 0; i < _sandColumns; i += 1)
        painted[i] + (hg.fullCrestAt(xs[i]) - painted[i]) * p,
    ];

    Color sideAt(double x) {
      final w = ((x - hg.neckX + 22) / 60).clamp(0.0, 1.0);
      return Color.lerp(hg.litSand, hg.shadeSand, w)!;
    }

    List<Offset> rowAt(double Function(int i) yOf) {
      return [
        for (var i = 0; i < _sandColumns; i += 1)
          _artPoint(size, xs[i], yOf(i)),
      ];
    }

    final sideColors = [for (final x in xs) sideAt(x)];
    final seamColors = List<Color>.generate(_sandColumns, (i) {
      return Color.lerp(sideColors[i], hg.crestToneAt(xs[i]), 0.85)!;
    });
    final crestRow = rowAt((i) => curs[i]);
    _drawLidStrip(
      canvas,
      crestRow,
      rowAt((i) => math.max(curs[i], painted[i] - 5)),
      sideColors,
      sideColors,
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      rowAt((i) => math.max(curs[i], painted[i] - 5)),
      rowAt((i) => painted[i] + 2),
      sideColors,
      seamColors,
      _lidPaint,
    );

    // crest light, strongest where the stream lands
    final crestPeak = List<Color>.generate(_sandColumns, (i) {
      final dx = (xs[i] - hg.neckX) / 42;
      final grown = _band01(painted[i] + 0.8 - curs[i], 3);
      final w = (0.3 + 0.5 * math.exp(-dx * dx)) * 0.8 * grown;
      return _sandCrestLit.withValues(alpha: w.clamp(0.0, 1.0));
    });
    final crestNone = List<Color>.filled(
      _sandColumns,
      _sandCrestLit.withValues(alpha: 0),
    );
    _drawLidStrip(
      canvas,
      rowAt((i) => curs[i] + 1.2 - 2.6),
      rowAt((i) => curs[i] + 1.2),
      crestNone,
      crestPeak,
      _lidPaint,
    );
    _drawLidStrip(
      canvas,
      rowAt((i) => curs[i] + 1.2),
      rowAt((i) => curs[i] + 1.2 + 2.6),
      crestPeak,
      crestNone,
      _lidPaint,
    );

    // the big glass reflections stay in front of the new sand
    void streak(double sx, double width, double alpha, double y0, double y1) {
      const rows = 14;
      final paintedHere = hg.crestAt(sx);
      final cur = paintedHere + (hg.fullCrestAt(sx) - paintedHere) * p;
      final inner = <Offset>[];
      final centre = <Offset>[];
      final outer = <Offset>[];
      final peak = <Color>[];
      final none = <Color>[];
      for (var j = 0; j < rows; j += 1) {
        final y = y0 + (y1 - y0) * j / (rows - 1);
        final ramp = _band01(y - y0, 6) * _band01(y1 - y, 6);
        final cover = _band01(y - cur, 1.5) * _band01(paintedHere + 2 - y, 3);
        final a = alpha * ramp * cover;
        inner.add(_artPoint(size, sx - width, y));
        centre.add(_artPoint(size, sx, y));
        outer.add(_artPoint(size, sx + width, y));
        peak.add(_sandCoolStreak.withValues(alpha: a));
        none.add(_sandCoolStreak.withValues(alpha: 0));
      }
      _drawLidStrip(canvas, inner, centre, none, peak, _lidPaint);
      _drawLidStrip(canvas, centre, outer, peak, none, _lidPaint);
    }

    streak(259, 6, 0.22, 300, 352);
    streak(352, 4, 0.12, 302, 345);
  }

  /// Falling grains between the neck and wherever the crest stands now.
  void _paintHourglassStream(
    Canvas canvas,
    Size size,
    FortuneHourglassGeometry hg,
    double p,
    double t,
    bool rewinding,
  ) {
    if (p >= 0.999) return;
    final paintedLand = hg.crestAt(hg.neckX);
    final land = paintedLand + (hg.fullCrestAt(hg.neckX) - paintedLand) * p;
    const streamTop = 272.0;
    final h = land - streamTop;
    if (h <= 4) return;
    final scale = coverScale(size);
    for (var g = 0; g < 14; g += 1) {
      final speed = 0.42 + 0.1 * ((g * 37 % 11) / 11);
      final phase = (g * 0.61803) % 1.0;
      var u = (t / speed + phase) % 1.0;
      if (rewinding) u = 1.0 - u;
      final gy = streamTop + u * h;
      final wobble = 0.9 * math.sin(g * 2.1) + 0.5 * math.sin(t * 9 + g);
      final gx = hg.neckX + wobble;
      final fade = math.min(1.0, (land - gy) / 6.0 + 0.3);
      final alpha = 0.4 * fade;
      if (alpha <= 0.01) continue;
      _dotPaint.color = _sandGrain.withValues(alpha: alpha);
      canvas.drawCircle(_artPoint(size, gx, gy), 1.15 * scale, _dotPaint);
    }
    final pulse = 0.16 + 0.07 * math.sin(t * 11);
    _dotPaint.color = _sandImpact.withValues(alpha: pulse);
    canvas.drawCircle(
      _artPoint(size, hg.neckX, land - 1.5),
      3 * scale,
      _dotPaint,
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
