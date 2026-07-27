import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'fortune_hourglass.dart';

part 'fortune_motion_data.dart';

/// The ambient-effect vocabulary and the per-card map (scope: living cards).
///
/// Every fortune card may carry a few effect layers — steam over a cup,
/// flame flicker on a candle, sparkles over gilt — each anchored to a point
/// *of the artwork itself*, expressed as fractions of the source image. The
/// painter maps those anchors through the same BoxFit.cover + focal-alignment
/// crop the artwork is drawn with, so the steam rises from the cup's mouth in
/// every card shape, not from a coordinate that happened to fit one layout.
///
/// Everything here is pure data and pure math: a particle's place is a
/// function of (seed, index, time), never of stored state, so a frame can be
/// tested exactly and two renders of the same moment are identical.

/// Intrinsic size shared by every `assets/fortunes/<id>.jpg` (verified across
/// the set); anchor fractions below are read against this geometry.
const Size kFortuneArtSize = Size(640, 498);

/// What a layer paints. Kinds are deliberately few; cards differ by anchor,
/// colour and intensity, not by bespoke code.
enum FortuneEffectKind {
  steam,
  flame,
  sparkle,
  glow,
  blink,
  hourglass,
  steamWarp,
  swirlWarp,
  apparition,
}

/// One layer of ambient motion, anchored in image space.
class FortuneEffectLayerSpec {
  const FortuneEffectLayerSpec({
    required this.kind,
    required this.anchor,
    this.spread = const Offset(0.25, 0.25),
    this.color,
    this.intensity = 1,
    this.count = 0,
    this.periodSeconds,
    this.eye,
    this.hourglass,
    this.warp,
    this.swirl,
    this.apparition,
  });

  final FortuneEffectKind kind;

  /// Anchor point, as fractions of [kFortuneArtSize].
  final Offset anchor;

  /// Half-extents of the particle field around [anchor], image fractions.
  final Offset spread;

  /// Layer colour; null falls back to the card's accent.
  final Color? color;

  /// 0..~1.2 — scales alpha, radius and reach together.
  final double intensity;

  /// Particle count; 0 means the kind's default.
  final int count;

  /// Fixed breathing period for [FortuneEffectKind.glow] layers — a
  /// heartbeat, a pulsing seal. Null lets the seed pick one (4.5–6.5s).
  final double? periodSeconds;

  /// Eye-opening geometry; only [FortuneEffectKind.blink] layers carry one.
  final FortuneEyeGeometry? eye;

  /// Hourglass geometry; only [FortuneEffectKind.hourglass] layers carry
  /// one.
  final FortuneHourglassGeometry? hourglass;

  /// Warp-region geometry; only [FortuneEffectKind.steamWarp] layers
  /// carry one.
  final FortuneWarpGeometry? warp;

  /// Swirl geometry; only [FortuneEffectKind.swirlWarp] layers carry one.
  final FortuneSwirlGeometry? swirl;

  /// Apparition geometry; only [FortuneEffectKind.apparition] layers
  /// carry one.
  final FortuneApparitionGeometry? apparition;
}

/// A momentary apparition in the glass: a hooded shade that gathers,
/// opens two burning eyes, and dissolves again. Artwork pixels.
class FortuneApparitionGeometry {
  const FortuneApparitionGeometry({
    required this.centerX,
    required this.headY,
    this.period = 7,
  });

  /// Where the shade stands.
  final double centerX;
  final double headY;

  /// Seconds between visits.
  final double period;
}

/// How present the shade's body is at second [t] — 0 gone, 1 fully there.
double ghostBody(double t, {double period = 7}) {
  final s = t - (t / period).floorToDouble() * period;
  if (s < 0.9) return _smoothstep(s / 0.9);
  if (s < 2.5) return 1;
  if (s < 4.3) return 1 - _smoothstep((s - 2.5) / 1.8);
  return 0;
}

/// The eyes open late, burn while the body holds, and die a little first.
double ghostEyes(double t, {double period = 7}) {
  final s = t - (t / period).floorToDouble() * period;
  if (s < 0.6) return 0;
  if (s < 1.1) return _smoothstep((s - 0.6) / 0.5);
  if (s < 2.5) return 1;
  if (s < 4.0) return 1 - _smoothstep((s - 2.5) / 1.5);
  return 0;
}

/// How far through its visit the shade is — it drifts upward as it goes.
double ghostProgress(double t, {double period = 7}) {
  final s = t - (t / period).floorToDouble() * period;
  final p = s / 4.3;
  return p < 1 ? p : 1;
}

double _smoothstep(double u) {
  final v = u.clamp(0.0, 1.0);
  return v * v * (3 - 2 * v);
}

/// A disc of the artwork that stirs: differential rotation around a
/// centre — strongest at the core, zero from [fadeRadius] outward — with
/// a whisper of radial breathing. The glass sheen and rim around it never
/// move. Artwork pixels; loops exactly every [loopSeconds].
class FortuneSwirlGeometry {
  const FortuneSwirlGeometry({
    required this.centerX,
    required this.centerY,
    this.fadeRadius = 96,
    this.falloff = 60,
    this.maxAngle = 0.13,
    this.breath = 0.012,
    this.loopSeconds = 6.5,
    this.lagFactor = 1,
  });

  /// The stirring centre — the galaxy's core.
  final double centerX;
  final double centerY;

  /// The envelope is zero at this radius and beyond.
  final double fadeRadius;

  /// How quickly the envelope fades approaching [fadeRadius].
  final double falloff;

  /// Rotation at the very core, radians.
  final double maxAngle;

  /// Radial in/out, as a fraction of the radius.
  final double breath;

  /// The pattern repeats exactly this often.
  final double loopSeconds;

  /// Scales how much the wave's phase trails with radius. 1 stirs like a
  /// liquid; 0 turns the whole disc as one rigid piece (an emblem).
  final double lagFactor;

  /// 1 at the core, 0 at [fadeRadius] and beyond.
  double envelope(double r) {
    final e = ((fadeRadius - r) / falloff).clamp(0.0, 1.0);
    return math.pow(e, 1.4).toDouble();
  }

  /// Where the artwork point (x, y) sits at second [t], minus where it
  /// rests — the mesh displacement.
  Offset swirlDelta(double x, double y, double t) {
    final dx = x - centerX;
    final dy = y - centerY;
    final r = math.sqrt(dx * dx + dy * dy);
    final env = envelope(r);
    if (env <= 0) return Offset.zero;
    final ph1 = _tau * t / loopSeconds;
    final ph2 = _tau * t / (loopSeconds / 2);
    final wa = 0.75 * math.sin(ph1 - r * 0.045 * lagFactor);
    final wb = 0.35 * math.sin(ph2 - r * 0.03 * lagFactor + 1.3);
    final theta = maxAngle * env * (wa + wb);
    final scale = 1 + breath * env * math.sin(ph1 - r * 0.02 + 2.0);
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);
    final nx = centerX + (dx * cosT - dy * sinT) * scale;
    final ny = centerY + (dx * sinT + dy * cosT) * scale;
    return Offset(nx - x, ny - y);
  }
}

/// A region of the artwork that billows: a traveling wave rises through
/// it, so the painted steam itself undulates — a cinemagraph, not a
/// particle. Everything below [pinY] and every box edge holds perfectly
/// still; amplitude grows with height. Artwork pixels throughout.
class FortuneWarpGeometry {
  const FortuneWarpGeometry({
    required this.x0,
    required this.x1,
    required this.y0,
    required this.y1,
    this.pinY = 170,
    this.reach = 130,
    this.maxAmplitude = 7,
    this.loopSeconds = 5,
    this.invert = false,
  });

  /// The warped box.
  final double x0;
  final double x1;
  final double y0;
  final double y1;

  /// Below this row nothing moves — the plume stays attached to its cup.
  final double pinY;

  /// Rows over which the amplitude grows from the pin toward full.
  final double reach;

  /// Peak envelope, artwork pixels (waves may sum to 1.1x briefly).
  final double maxAmplitude;

  /// The wave pattern repeats exactly this often.
  final double loopSeconds;

  /// False: pinned below [pinY], moving above (steam, smoke, clouds).
  /// True: pinned above [pinY], moving below (a reflection, a hanging
  /// thread).
  final bool invert;

  /// Displacement envelope at (x, y): zero on every box edge and at the
  /// pin, rising away from it.
  double amplitude(double x, double y) {
    var h = invert
        ? ((y - pinY) / reach).clamp(0.0, 1.0)
        : ((pinY - y) / reach).clamp(0.0, 1.0);
    h = math.pow(h, 1.25).toDouble();
    h *= invert
        ? ((y1 - y) / 12).clamp(0.0, 1.0)
        : ((y - y0) / 12).clamp(0.0, 1.0);
    final sideL = ((x - x0) / 25).clamp(0.0, 1.0);
    final sideR = ((x1 - x) / 25).clamp(0.0, 1.0);
    return maxAmplitude * h * sideL * sideR;
  }

  /// Horizontal displacement at second [t] — two waves traveling upward.
  double warpDx(double x, double y, double t) {
    final ph1 = _tau * t / loopSeconds;
    final ph2 = _tau * t / (loopSeconds / 2);
    final a = 0.75 * math.sin(ph1 - y * 0.030 + x * 0.010 + 0.8);
    final b = 0.35 * math.sin(ph2 - y * 0.017 + x * 0.006 + 2.1);
    return amplitude(x, y) * (a + b);
  }

  /// Vertical displacement at second [t] — gentler than the sway.
  double warpDy(double x, double y, double t) {
    final ph1 = _tau * t / loopSeconds;
    final ph2 = _tau * t / (loopSeconds / 2);
    final a = 0.7 * math.sin(ph1 - y * 0.026 + x * 0.008 + 2.9);
    final b = 0.3 * math.sin(ph2 - y * 0.021 + 5.0);
    return 0.55 * amplitude(x, y) * (a + b);
  }
}

const double _tau = math.pi * 2;

/// The eye opening of a card that blinks, measured in artwork pixels.
///
/// The lid edges are quartic fits y(u) over u = (x - xLeft) / (xRight -
/// xLeft), read off the real artwork the way anchors are. The eyeball never
/// moves; two lid surfaces slide over it and meet at [closureDepth] of the
/// opening's height — the upper lid travels the long way, like a real blink.
class FortuneEyeGeometry {
  const FortuneEyeGeometry({
    required this.xLeft,
    required this.xRight,
    required this.upperCoeffs,
    required this.lowerCoeffs,
    this.closureDepth = 0.62,
    this.blinkPeriod = 2,
  });

  /// Horizontal extent of the opening, artwork pixels.
  final double xLeft;
  final double xRight;

  /// Quartic coefficients of the lid edges y(u), highest power first.
  final List<double> upperCoeffs;
  final List<double> lowerCoeffs;

  /// Where the lids meet, as a fraction of the opening's height.
  final double closureDepth;

  /// Seconds between blinks.
  final double blinkPeriod;

  /// Artwork y of the upper lid edge at u in 0..1.
  double upperY(double u) => _evalPoly(upperCoeffs, u);

  /// Artwork y of the lower lid edge at u in 0..1.
  double lowerY(double u) => _evalPoly(lowerCoeffs, u);
}

double _evalPoly(List<double> coeffs, double u) {
  var y = 0.0;
  for (final c in coeffs) {
    y = y * u + c;
  }
  return y;
}

/// How shut a blinking eye is at second [t] — 0 open, 1 shut.
///
/// Once per [period] the lid drops fast (~110ms), rests shut a beat and
/// releases slower (~180ms); the start jitters a little per cycle so the
/// rhythm never turns metronomic. Pure function of (seed, t), like every
/// other motion here.
double blinkClosure(int seed, double t, {double period = 2}) {
  const close = 0.11;
  const hold = 0.05;
  const open = 0.18;
  final cycle = (t / period).floor();
  final offset = 0.5 + effectRandom(seed, cycle, 71) * 0.45;
  final s = t - cycle * period - offset;
  if (s < 0 || s > close + hold + open) return 0;
  if (s < close) {
    final u = s / close;
    return u * u;
  }
  if (s < close + hold) return 1;
  final u = (s - close - hold) / open;
  return (1 - u) * (1 - u);
}

/// The full effect of one card: a short list of layers, painted in order.
class FortuneEffectSpec {
  const FortuneEffectSpec(this.layers);

  final List<FortuneEffectLayerSpec> layers;
}

/// The spec for a fortune id, or null while that artwork is still still.
FortuneEffectSpec? fortuneEffectSpec(String id) => _effects[id];

/// Stable seed for a card's particle field — same id, same field, every run
/// and every platform (String.hashCode promises neither).
int effectSeedFor(String id) {
  var seed = 0;
  for (final code in id.codeUnits) {
    seed = (seed * 31 + code) % 0x7FFFFFFF;
  }
  return seed + 1;
}

/// Deterministic 0..1 value for particle [index] of a field. [salt] picks
/// independent channels (x, y, phase…). Uses a small Lehmer chain kept under
/// 2^47 so the arithmetic is exact on the web's doubles too.
double effectRandom(int seed, int index, [int salt = 0]) {
  var state = (seed + index * 7919 + salt * 104729) % 0x7FFFFFFF;
  if (state <= 0) state += 0x7FFFFFFE;
  state = (state * 48271) % 0x7FFFFFFF;
  state = (state * 48271) % 0x7FFFFFFF;
  return state / 0x7FFFFFFF;
}

/// The cover-crop scale the artwork is drawn with in a [size] frame.
double coverScale(Size size) {
  return math.max(
    size.width / kFortuneArtSize.width,
    size.height / kFortuneArtSize.height,
  );
}

/// Maps a point given as fractions of the artwork onto widget coordinates,
/// under BoxFit.cover with [alignment] — the exact crop `Image` applies.
Offset mapCoverPoint(Offset fraction, Size size, Alignment alignment) {
  final scale = coverScale(size);
  final scaledWidth = kFortuneArtSize.width * scale;
  final scaledHeight = kFortuneArtSize.height * scale;
  final dx = (size.width - scaledWidth) * (alignment.x + 1) / 2;
  final dy = (size.height - scaledHeight) * (alignment.y + 1) / 2;
  return Offset(
    dx + fraction.dx * scaledWidth,
    dy + fraction.dy * scaledHeight,
  );
}

// Layer colours. Explicit rather than accent-derived where the artwork has
// its own temperature: steam is warm white on every cup, no matter the card.
const Color _gold = Color(0xFFEFC97F);
const Color _warmWhite = Color(0xFFF2E9DA);
const Color _flame = Color(0xFFFFC66B);
const Color _smoke = Color(0xFFB9AFA4);
const Color _rose = Color(0xFFFF9FB0);
const Color _violet = Color(0xFFC5A0FF);
const Color _paleMoon = Color(0xFFF4EBCF);
const Color _teal = Color(0xFF7FE0D8);

/// The tea card's steam plume, measured off the artwork: the box the wave
/// lives in; the cup rim it stays pinned to comes with the defaults.
const FortuneWarpGeometry _teaSteamWarp = FortuneWarpGeometry(
  x0: 215,
  x1: 415,
  y0: 22,
  y1: 175,
);

/// The crystal ball's galaxy: core located at the artwork's brightest
/// interior blob; the envelope dies out well inside the glass sheen.
const FortuneSwirlGeometry _ballSwirl = FortuneSwirlGeometry(
  centerX: 316,
  centerY: 235,
);

/// The talisman's eye opening, fitted on the artwork's inner gold rims
/// (max residual under 1.5px against the measured edge points).
const FortuneEyeGeometry _talismanEye = FortuneEyeGeometry(
  xLeft: 212,
  xRight: 433,
  upperCoeffs: [224.3407, -454.1082, 462.1742, -231.079, 249.4362],
  lowerCoeffs: [315.5714, -683.4197, 296.5842, 71.6733, 250.3278],
);

/// All forty cards of the catalog. Anchors were read off the real artwork,
/// one image at a time — a wrong anchor is worse than no effect, because
/// steam rising from a saucer breaks the spell.
const Map<String, FortuneEffectSpec> _effects = {
  // Candle upper-left; gold dust breathes over the open book.
  'hafez': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.203, 0.243),
      warp: _hafezWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.185, 0.15),
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.58),
      spread: Offset(0.3, 0.2),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
  ]),
  // The sun card's crown glints; star-dust drifts across the spread.
  'tarot': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.14),
      color: _gold,
      intensity: 0.5,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.27, 0.3),
      color: _gold,
      count: 14,
    ),
  ]),
  // Steam from the cup's mouth; the coffee's own light breathes softly.
  'coffee': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steam,
      anchor: Offset(0.5, 0.4),
      color: _warmWhite,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.47),
      color: _flame,
      intensity: 0.35,
    ),
  ]),
  // The filigree heart breathes; rose sparks rest on the petals.
  'love': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.52, 0.42),
      color: _rose,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.55),
      spread: Offset(0.3, 0.22),
      color: _rose,
      intensity: 0.8,
      count: 10,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.494, 0.438),
      color: _teal,
      intensity: 0.55,
      periodSeconds: 1.15,
    ),
  ]),
  // Moon halo breathing over the cloudbank; faint stars.
  'dream': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.55, 0.34),
      color: _paleMoon,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.45, 0.35),
      spread: Offset(0.3, 0.25),
      color: _paleMoon,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The quill's tip glints; glyph-dust hangs over the scroll.
  'abjad': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.795, 0.472),
      warp: _abjadWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.53, 0.79),
      color: _gold,
      intensity: 0.45,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.42, 0.45),
      spread: Offset(0.25, 0.28),
      color: _gold,
      intensity: 0.7,
      count: 9,
    ),
  ]),
  // The sun-and-moon medallion breathes; sparks orbit its rim.
  'daily': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.5),
      color: _gold,
      intensity: 0.65,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.5),
      spread: Offset(0.28, 0.28),
      color: _gold,
      count: 12,
    ),
  ]),
  // The radiant emblem breathes light; gold motes rise gently.
  'quran': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.52, 0.47),
      color: _flame,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.52, 0.55),
      spread: Offset(0.22, 0.2),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The crystal ball's galaxy shimmers inside a breathing violet halo.
  'yesno': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.swirlWarp,
      anchor: Offset(0.494, 0.472),
      swirl: _ballSwirl,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.47),
      color: _violet,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.47),
      spread: Offset(0.16, 0.16),
      color: _violet,
      count: 10,
    ),
  ]),
  // Mike's example, in full: flame flicker, curling smoke, warm embers.
  'candle': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.377, 0.244),
      warp: _candleWarpA,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.576, 0.336),
      warp: _candleWarpB,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.489, 0.345),
      warp: _candleWarpC,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.635, 0.45),
      intensity: 1.15,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steam,
      anchor: Offset(0.615, 0.34),
      color: _smoke,
      intensity: 0.45,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.62, 0.55),
      spread: Offset(0.18, 0.15),
      color: _flame,
      intensity: 0.5,
      count: 6,
    ),
  ]),
  // Rings under a small flame; rose petals rest around them.
  'marriage': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.508, 0.225),
      warp: _marriageWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.27, 0.16),
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.6),
      spread: Offset(0.28, 0.2),
      color: _rose,
      intensity: 0.7,
      count: 8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.505, 0.257),
      intensity: 0.5,
    ),
  ]),
  // Two little candles over the golden shoes; soft gold dust.
  'child': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.43, 0.563),
      warp: _childWarpA,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.545, 0.565),
      warp: _childWarpB,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.42, 0.16),
      intensity: 0.5,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.58, 0.16),
      intensity: 0.5,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.55),
      spread: Offset(0.24, 0.18),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.431, 0.566),
      intensity: 0.4,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.545, 0.57),
      intensity: 0.4,
    ),
  ]),
  // The red thread between two hands, in gentle haze.
  'friendship': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.331, 0.639),
      warp: _friendshipWarpA,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.531, 0.716),
      warp: _friendshipWarpB,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.3, 0.25),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
  ]),
  // A dark candle over the broken heart — quiet, not dramatic.
  'separation': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.494, 0.296),
      warp: _separationWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.52, 0.11),
      intensity: 0.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.55),
      spread: Offset(0.22, 0.18),
      color: _gold,
      intensity: 0.5,
      count: 6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.494, 0.301),
      intensity: 0.45,
    ),
  ]),
  // The dove breathes light inside its golden ring.
  'reconcile': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.52, 0.38),
      color: _paleMoon,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.5),
      spread: Offset(0.26, 0.22),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // A flame over the parchment; the emblem keeps a soft glint.
  'name': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.517, 0.213),
      warp: _nameWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.52, 0.13),
      intensity: 0.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.45, 0.55),
      spread: Offset(0.25, 0.2),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.516, 0.215),
      intensity: 0.45,
    ),
  ]),
  // The chest’s rays breathe; work-worn gold sparks.
  'job': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.38),
      color: _flame,
      intensity: 0.75,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.26, 0.24),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
  ]),
  // Gold dust rises from the pouch; the coins keep their shine.
  'money': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.4),
      spread: Offset(0.2, 0.28),
      color: _gold,
      intensity: 0.9,
      count: 14,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.55, 0.62),
      color: _flame,
      intensity: 0.5,
    ),
  ]),
  // The little lamp burns beside the map.
  'travel': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.418, 0.148),
      warp: _travelWarpA,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.771, 0.803),
      warp: _travelWarpB,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.63, 0.83),
      intensity: 0.5,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.42, 0.45),
      spread: Offset(0.26, 0.22),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The hourglass runs: six seconds of falling sand, a warm shimmer as
  // time turns back, and the cycle begins again.
  'future': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.hourglass,
      anchor: Offset(0.491, 0.562),
      hourglass: kFutureHourglass,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.68, 0.55),
      color: _flame,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.45, 0.35),
      spread: Offset(0.28, 0.22),
      color: _paleMoon,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The sealed letter radiates; something is on its way.
  'message': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.41, 0.52),
      color: _flame,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.4),
      spread: Offset(0.26, 0.22),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.495, 0.568),
      color: _flame,
      intensity: 0.6,
      periodSeconds: 2.6,
    ),
  ]),
  // The orb in cupped hands breathes; intent drifts upward.
  'intention': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.486, 0.564),
      warp: _intentionWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.47, 0.62),
      color: _flame,
      intensity: 0.85,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.47, 0.4),
      spread: Offset(0.18, 0.2),
      color: _gold,
      intensity: 0.7,
      count: 8,
    ),
  ]),
  // The number breathes inside its seal.
  'luckynumber': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.5),
      color: _gold,
      intensity: 0.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.26, 0.24),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
  ]),
  // Gem glints across the fan of colours.
  'luckycolor': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.5),
      spread: Offset(0.3, 0.25),
      color: _warmWhite,
      intensity: 0.8,
      count: 14,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.55, 0.65),
      color: _violet,
      intensity: 0.5,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.834, 0.424),
      color: _warmWhite,
      intensity: 0.28,
      periodSeconds: 2,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.527, 0.205),
      color: _warmWhite,
      intensity: 0.28,
      periodSeconds: 2.3,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.463, 0.193),
      color: _warmWhite,
      intensity: 0.28,
      periodSeconds: 2.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.391, 0.215),
      color: _warmWhite,
      intensity: 0.28,
      periodSeconds: 2.9,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.258, 0.552),
      color: _warmWhite,
      intensity: 0.28,
      periodSeconds: 3.2,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.489, 0.785),
      color: _warmWhite,
      intensity: 0.28,
      periodSeconds: 3.5,
    ),
  ]),
  // The crystals hum violet; facets catch light.
  'luckystone': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.5),
      color: _violet,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.24, 0.22),
      color: _warmWhite,
      intensity: 0.8,
      count: 12,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.378, 0.237),
      color: _violet,
      intensity: 0.35,
      periodSeconds: 2.4,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.577, 0.345),
      color: _warmWhite,
      intensity: 0.3,
      periodSeconds: 2.9,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.483, 0.707),
      color: _violet,
      intensity: 0.35,
      periodSeconds: 3.4,
    ),
  ]),
  // The lotus glows over its own reflection.
  'luckyflower': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.42),
      color: _paleMoon,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.35),
      spread: Offset(0.26, 0.2),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The amulet’s eye holds a steady, breathing light — and blinks, every
  // couple of seconds, the glow dimming for the beat the lids are shut.
  'dailytalisman': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.blink,
      anchor: Offset(0.503, 0.504),
      eye: _talismanEye,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.4),
      color: _violet,
      intensity: 0.55,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.42),
      spread: Offset(0.24, 0.24),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
  ]),
  // Gold dust over the dice — chance, mid-air.
  'lots': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.5),
      spread: Offset(0.28, 0.24),
      color: _gold,
      intensity: 0.8,
      count: 12,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.47, 0.42),
      color: _flame,
      intensity: 0.5,
    ),
  ]),
  // The zodiac wheel breathes; signs glint in turn.
  'birthmonth': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.42),
      color: _gold,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.27, 0.27),
      color: _gold,
      intensity: 0.7,
      count: 12,
    ),
  ]),
  // Four medallions glint; the fire one actually flickers.
  'elements': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.5),
      spread: Offset(0.3, 0.3),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.72, 0.28),
      intensity: 0.5,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.384, 0.261),
      color: _gold,
      intensity: 0.3,
      periodSeconds: 3.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.644, 0.255),
      color: _gold,
      intensity: 0.45,
      periodSeconds: 2.4,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.384, 0.683),
      color: _gold,
      intensity: 0.3,
      periodSeconds: 4.2,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.644, 0.669),
      color: _gold,
      intensity: 0.3,
      periodSeconds: 3,
    ),
  ]),
  // The galaxy’s heart breathes; violet stars drift.
  'universe': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.swirlWarp,
      anchor: Offset(0.547, 0.506),
      swirl: _universeSwirl,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.552, 0.507),
      warp: _universeWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.47, 0.47),
      color: _paleMoon,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.4),
      spread: Offset(0.28, 0.26),
      color: _violet,
      intensity: 0.7,
      count: 12,
    ),
  ]),
  // Steam from the cup’s mouth — the example this began with.
  'tea': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.46, 0.2),
      warp: _teaSteamWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steam,
      anchor: Offset(0.46, 0.4),
      color: _warmWhite,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.47, 0.52),
      color: _flame,
      intensity: 0.4,
    ),
  ]),
  // The glass holds a pale, breathing light.
  'mirror': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.swirlWarp,
      anchor: Offset(0.519, 0.317),
      swirl: _mirrorSwirl,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.apparition,
      anchor: Offset(0.519, 0.285),
      apparition: _mirrorGhost,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.35),
      color: _paleMoon,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.4),
      spread: Offset(0.22, 0.22),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The candle over the spread; the cards keep a low glint.
  'lenormand': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.488, 0.215),
      warp: _lenormandWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.55, 0.21),
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.62),
      spread: Offset(0.3, 0.18),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // The runes burn amber in the standing stone.
  'rune': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.55, 0.5),
      color: _flame,
      intensity: 0.75,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.4),
      spread: Offset(0.24, 0.2),
      color: _gold,
      intensity: 0.5,
      count: 6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.491, 0.321),
      color: _gold,
      intensity: 0.35,
      periodSeconds: 2.2,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.486, 0.482),
      color: _gold,
      intensity: 0.35,
      periodSeconds: 2.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.489, 0.689),
      color: _gold,
      intensity: 0.35,
      periodSeconds: 3.1,
    ),
  ]),
  // The oracle backs glint along their gilded edges.
  'cards': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.5),
      spread: Offset(0.3, 0.22),
      color: _gold,
      intensity: 0.7,
      count: 10,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.55),
      color: _gold,
      intensity: 0.5,
    ),
  ]),
  // The beads keep a devotional shimmer.
  'tasbih': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.47, 0.5),
      color: _gold,
      intensity: 0.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.26, 0.22),
      color: _gold,
      intensity: 0.6,
      count: 8,
    ),
  ]),
  // Light between the wings; a feather’s worth of sparks.
  'angel': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.steamWarp,
      anchor: Offset(0.498, 0.653),
      warp: _angelWarp,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.42),
      color: _paleMoon,
      intensity: 0.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.45),
      spread: Offset(0.28, 0.25),
      color: _paleMoon,
      intensity: 0.7,
      count: 10,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.506, 0.637),
      intensity: 0.5,
    ),
  ]),
  // The wolf’s ring glows in the night; a few far stars.
  'spiritanimal': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.42),
      color: _paleMoon,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.4),
      spread: Offset(0.24, 0.22),
      color: _gold,
      intensity: 0.5,
      count: 6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.484, 0.353),
      color: _gold,
      intensity: 0.35,
      periodSeconds: 3,
    ),
  ]),
  // The crown breathes; the chakra line sparks; base candles burn.
  'meditation': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.5, 0.28),
      color: _violet,
      intensity: 0.6,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.5, 0.55),
      spread: Offset(0.12, 0.25),
      color: _flame,
      intensity: 0.7,
      count: 8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.3, 0.77),
      intensity: 0.4,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.419, 0.622),
      intensity: 0.35,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.flame,
      anchor: Offset(0.58, 0.627),
      intensity: 0.35,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.497, 0.482),
      color: _gold,
      intensity: 0.5,
      periodSeconds: 3.2,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.497, 0.301),
      color: _gold,
      intensity: 0.4,
      periodSeconds: 4.1,
    ),
  ]),
};
