import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The hourglass cycle of the future card: geometry and tones measured off
/// the artwork's own pixels, plus the pure timing of the 6-second drain.
///
/// The painted artwork is the cycle's start (top pile full, bottom low).
/// Draining covers the top pile with synthesized empty glass down to the
/// falling surface and grows the bottom pile above its painted crest; the
/// rewind eases everything back and the cycle repeats. Like every motion
/// here, a frame is a pure function of the shared clock.

/// 0 = the painted artwork, 1 = drained. Linear drain, eased rewind.
double hourglassProgress(double t, {double drain = 6, double rewind = 0.75}) {
  final period = drain + rewind;
  final phase = t - (t / period).floorToDouble() * period;
  if (phase < drain) return phase / drain;
  final u = (phase - drain) / rewind;
  return 1 - u * u * (3 - 2 * u);
}

/// 0 outside the rewind, rising 0..1 across it — drives the warm shimmer.
double hourglassRewind(double t, {double drain = 6, double rewind = 0.75}) {
  final period = drain + rewind;
  final phase = t - (t / period).floorToDouble() * period;
  if (phase < drain) return 0;
  return (phase - drain) / rewind;
}

/// Linear interpolation over a table sampled uniformly on [v0, v1].
double sampleCurve(List<double> table, double v0, double v1, double v) {
  final f = (v.clamp(v0, v1) - v0) / (v1 - v0) * (table.length - 1);
  var i = f.floor();
  if (i > table.length - 2) i = table.length - 2;
  final w = f - i;
  return table[i] * (1 - w) + table[i + 1] * w;
}

/// Same, over flattened r,g,b triples.
Color sampleTone(List<double> rgb, double v0, double v1, double v) {
  final count = rgb.length ~/ 3;
  final f = (v.clamp(v0, v1) - v0) / (v1 - v0) * (count - 1);
  var i = f.floor();
  if (i > count - 2) i = count - 2;
  final w = f - i;
  Color at(int k) {
    return Color.fromARGB(
      255,
      rgb[k * 3].round(),
      rgb[k * 3 + 1].round(),
      rgb[k * 3 + 2].round(),
    );
  }

  return Color.lerp(at(i), at(i + 1), w)!;
}

/// Measured hourglass geometry, all in artwork pixels.
class FortuneHourglassGeometry {
  const FortuneHourglassGeometry({
    required this.topX0,
    required this.topX1,
    required this.topY0,
    required this.topY1,
    required this.botX0,
    required this.botX1,
    required this.neckX,
    required this.topCurve,
    required this.botCurve,
    required this.spanLeft,
    required this.spanRight,
    required this.bottomCrest,
    required this.glassTone,
    required this.aboveTone,
    required this.crestTone,
    required this.litSand,
    required this.shadeSand,
    this.drainSeconds = 6,
    this.rewindSeconds = 0.75,
  });

  /// Horizontal and vertical extent of the painted top pile.
  final double topX0;
  final double topX1;
  final double topY0;
  final double topY1;

  /// Horizontal extent of the painted bottom crest.
  final double botX0;
  final double botX1;

  /// Where the stream falls.
  final double neckX;

  /// Upper and lower boundary of the painted top pile, y(x).
  final List<double> topCurve;
  final List<double> botCurve;

  /// The pile's horizontal span at a level line, x(y).
  final List<double> spanLeft;
  final List<double> spanRight;

  /// The painted bottom crest, y(x).
  final List<double> bottomCrest;

  /// Empty-glass tone above the old surface, per column.
  final List<double> glassTone;

  /// Artwork tone right above the old surface (eases the fill's top edge).
  final List<double> aboveTone;

  /// Painted tone right below the bottom crest (eases the new sand's seam).
  final List<double> crestTone;

  /// Lit and shaded flanks of freshly landed sand.
  final Color litSand;
  final Color shadeSand;

  final double drainSeconds;
  final double rewindSeconds;

  double topAt(double x) => sampleCurve(topCurve, topX0, topX1, x);

  double botAt(double x) => sampleCurve(botCurve, topX0, topX1, x);

  double spanLeftAt(double y) => sampleCurve(spanLeft, topY0, topY1, y);

  double spanRightAt(double y) => sampleCurve(spanRight, topY0, topY1, y);

  double crestAt(double x) => sampleCurve(bottomCrest, botX0, botX1, x);

  /// The full-state crest the pile grows toward: the painted crest lifted,
  /// pinched to zero at its ends so the mound stays inside the glass.
  double fullCrestAt(double x) {
    final fadeIn = ((x - botX0) / 14).clamp(0.0, 1.0);
    final fadeOut = ((botX1 - x) / 14).clamp(0.0, 1.0);
    final fade = math.pow(fadeIn * fadeOut, 0.7).toDouble();
    final dx = (x - neckX) / 34;
    final lift = (13 + 17 * math.exp(-dx * dx)) * fade;
    final lifted = crestAt(x) - lift;
    return lifted < 301 ? 301 : lifted;
  }

  Color glassAt(double x) => sampleTone(glassTone, topX0, topX1, x);

  Color aboveAt(double x) => sampleTone(aboveTone, topX0, topX1, x);

  Color crestToneAt(double x) => sampleTone(crestTone, botX0, botX1, x);
}

/// The future card's hourglass. Tables were extracted from the artwork's
/// sand-region mask (warmth/brightness classification, row-chained), not
/// placed by eye; the replica renders and this data agree to under one
/// grey level on average.
const FortuneHourglassGeometry kFutureHourglass =
    FortuneHourglassGeometry(
  topX0: 262,
  topX1: 354,
  topY0: 185,
  topY1: 269,
  botX0: 246,
  botX1: 362,
  neckX: 314,
  topCurve: [
    195,
    195,
    195,
    195,
    195,
    195,
    195,
    195,
    195,
    195,
    195,
    195,
    194,
    192,
    191,
    190,
    189,
    188,
    187,
    186,
    186,
    185,
    184,
    186,
  ],
  botCurve: [
    199,
    207,
    212,
    217,
    221,
    226,
    230,
    234,
    238,
    242,
    247,
    252,
    260,
    272,
    254,
    248,
    243,
    239,
    235,
    231,
    226,
    201,
    201,
    200,
  ],
  spanLeft: [
    343,
    324,
    312,
    262,
    263,
    266,
    268,
    271,
    274,
    278,
    282,
    285,
    289,
    293,
    297,
    301,
    304,
    307,
    310,
    311,
    311,
    311,
  ],
  spanRight: [
    350,
    354,
    354,
    354,
    352,
    343,
    343,
    343,
    343,
    343,
    343,
    339,
    336,
    332,
    328,
    324,
    321,
    318,
    315,
    314,
    314,
    314,
  ],
  bottomCrest: [
    342.2,
    349.3,
    354,
    356.7,
    357.8,
    357.5,
    356.2,
    354.1,
    351.5,
    348.6,
    345.7,
    342.8,
    340.2,
    337.9,
    336.1,
    334.9,
    334.3,
    334.3,
    334.9,
    336.1,
    337.9,
    340.2,
    342.9,
    345.8,
    348.9,
    351.9,
    354.6,
    356.9,
    358.4,
    359,
  ],
  glassTone: [
    64,
    57,
    51,
    64,
    57,
    51,
    64,
    57,
    51,
    64,
    58,
    52,
    66,
    60,
    54,
    70,
    62,
    56,
    67,
    62,
    58,
    61,
    60,
    60,
    54,
    57,
    60,
    46,
    54,
    62,
    46,
    56,
    65,
    48,
    59,
    68,
    50,
    62,
    72,
  ],
  aboveTone: [
    96,
    93,
    87,
    89,
    90,
    87,
    78,
    79,
    75,
    71,
    74,
    73,
    64,
    69,
    71,
    60,
    67,
    70,
    57,
    65,
    68,
    54,
    63,
    67,
    53,
    62,
    66,
    60,
    69,
    72,
    70,
    80,
    80,
    74,
    83,
    80,
    77,
    86,
    81,
  ],
  crestTone: [
    77,
    60,
    44,
    133,
    109,
    79,
    192,
    161,
    115,
    218,
    198,
    145,
    239,
    226,
    166,
    234,
    225,
    167,
    234,
    227,
    170,
    234,
    219,
    156,
    232,
    203,
    142,
    224,
    186,
    131,
    205,
    161,
    117,
    188,
    144,
    115,
    180,
    140,
    118,
    181,
    142,
    119,
    186,
    147,
    120,
    189,
    152,
    120,
  ],
  litSand: Color(0xFFFAD991),
  shadeSand: Color(0xFFC08E6A),
);
