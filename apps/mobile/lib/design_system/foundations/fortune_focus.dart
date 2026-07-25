import 'package:flutter/widgets.dart';

/// Per-artwork focal alignment for BoxFit.cover crops. Vertical alignment only
/// affects wide frames (the 16:9 hero and 2:1 section cards), which crop
/// top/bottom; portrait cards crop left/right, where every subject here is
/// already horizontally centred. So only the ids that appear in a wide frame —
/// the hero and each theme's lead card — carry a focal hint, tuned against the
/// real render so each composition's subject stays in frame. No artwork is
/// modified; everything else defaults to [Alignment.center].
Alignment fortuneFocalAlignment(String id) {
  return _focus[id] ?? Alignment.center;
}

const Map<String, Alignment> _focus = {
  // Keep the flame + subject high in the frame.
  'hafez': Alignment(0, -0.12), // candle + open book near the top
  'marriage': Alignment(0, -0.12), // candle flame above the rings
  'yesno': Alignment(0, -0.06), // crystal ball sits a touch high
  'love': Alignment(0, -0.04), // symmetrical heart, near-centre
  // Keep the subject that sits low from being clipped.
  'job': Alignment(0, 0.06), // gold chest below centre
  'tea': Alignment(0, 0.06), // cup + saucer below centre
  // birthmonth: a centred circular zodiac wheel — default centre is optimal.
};
