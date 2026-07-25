import 'package:flutter/widgets.dart';

/// Per-artwork focal alignment for BoxFit.cover crops. The fortune paintings
/// are landscape (~1.28); when a card is portrait or ultra-wide the crop must
/// keep each piece's subject in frame instead of always centring. Only assets
/// that need it are listed; everything else defaults to [Alignment.center].
///
/// These are layout hints for cropping only — no artwork is modified. Values
/// are refined against the live render, not guessed blindly.
Alignment fortuneFocalAlignment(String id) {
  return _focus[id] ?? Alignment.center;
}

const Map<String, Alignment> _focus = {
  // Subject sits high in the frame (moon, candle flame, headers).
  'hafez': Alignment(0, -0.15),
  'candle': Alignment(0, -0.25),
  'dream': Alignment(0, -0.20),
  'universe': Alignment(0, -0.20),
  'angel': Alignment(0, -0.15),
  // Subject sits low (cups, hands, open books, scrolls).
  'coffee': Alignment(0, 0.15),
  'friendship': Alignment(0, 0.20),
  'quran': Alignment(0, 0.10),
  'tasbih': Alignment(0, 0.15),
  // Centred emblems that read best dead-centre stay default (omitted).
};
