import 'dart:math' as math;

import 'package:flutter/painting.dart';

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
enum FortuneEffectKind { steam, flame, sparkle, glow, blink }

/// One layer of ambient motion, anchored in image space.
class FortuneEffectLayerSpec {
  const FortuneEffectLayerSpec({
    required this.kind,
    required this.anchor,
    this.spread = const Offset(0.25, 0.25),
    this.color,
    this.intensity = 1,
    this.count = 0,
    this.eye,
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

  /// Eye-opening geometry; only [FortuneEffectKind.blink] layers carry one.
  final FortuneEyeGeometry? eye;
}

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
  ]),
  // Two little candles over the golden shoes; soft gold dust.
  'child': FortuneEffectSpec([
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
  ]),
  // The red thread between two hands, in gentle haze.
  'friendship': FortuneEffectSpec([
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
  // The hourglass sand glows; stars hold still around it.
  'future': FortuneEffectSpec([
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
  ]),
  // The orb in cupped hands breathes; intent drifts upward.
  'intention': FortuneEffectSpec([
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
  ]),
  // The galaxy’s heart breathes; violet stars drift.
  'universe': FortuneEffectSpec([
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
  ]),
};
