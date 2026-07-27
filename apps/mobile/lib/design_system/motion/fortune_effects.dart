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
enum FortuneEffectKind { steam, flame, sparkle, glow, mist }

/// One layer of ambient motion, anchored in image space.
class FortuneEffectLayerSpec {
  const FortuneEffectLayerSpec({
    required this.kind,
    required this.anchor,
    this.spread = const Offset(0.25, 0.25),
    this.color,
    this.intensity = 1,
    this.count = 0,
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

/// Phase 1: the ten cards of the home carousel. Anchors were read off the
/// real artwork, one image at a time — a wrong anchor is worse than no
/// effect, because steam rising from a saucer breaks the spell.
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
  // Moon halo breathing over drifting cloud-mist; faint stars.
  'dream': FortuneEffectSpec([
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.glow,
      anchor: Offset(0.55, 0.34),
      color: _paleMoon,
      intensity: 0.8,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.mist,
      anchor: Offset(0.5, 0.72),
      color: _violet,
      intensity: 0.7,
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
      anchor: Offset(0.6, 0.32),
      color: _smoke,
      intensity: 0.7,
    ),
    FortuneEffectLayerSpec(
      kind: FortuneEffectKind.sparkle,
      anchor: Offset(0.62, 0.55),
      spread: Offset(0.18, 0.15),
      color: _flame,
      intensity: 0.7,
      count: 6,
    ),
  ]),
};
