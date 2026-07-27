import 'package:flutter/widgets.dart';

import '../foundations/fortune_focus.dart';
import 'ambient_motion.dart';
import 'fortune_effect_painter.dart';
import 'fortune_effects.dart';

/// The living layer over a fortune card's artwork.
///
/// Sits between the image and its scrim inside `FortuneArt`, so the text and
/// badges above never fight the motion. It draws only when the card has a
/// spec; without an [AmbientMotion] ancestor, or when the platform asks for
/// reduced motion, it paints one quiet still frame — never a ticker of its
/// own, so no existing screen or test gains an animation it did not order.
///
/// Cards whose spec warps the artwork itself (a steam cinemagraph) also
/// resolve the card's image here — from the same provider the card draws,
/// so the cached decode is reused. Until it arrives, the card stays still.
class FortuneEffectLayer extends StatefulWidget {
  const FortuneEffectLayer({
    super.key,
    required this.id,
    required this.accent,
  });

  final String id;
  final Color accent;

  @override
  State<FortuneEffectLayer> createState() => _FortuneEffectLayerState();
}

class _FortuneEffectLayerState extends State<FortuneEffectLayer> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _art;

  bool _isWarpKind(FortuneEffectKind kind) {
    return kind == FortuneEffectKind.steamWarp ||
        kind == FortuneEffectKind.swirlWarp;
  }

  bool _wantsArt(FortuneEffectSpec? spec) {
    if (spec == null) return false;
    for (final layer in spec.layers) {
      if (_isWarpKind(layer.kind)) return true;
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveArt();
  }

  @override
  void didUpdateWidget(FortuneEffectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _resolveArt();
  }

  void _resolveArt() {
    if (!_wantsArt(fortuneEffectSpec(widget.id))) {
      _dropStream();
      return;
    }
    final provider = AssetImage('assets/fortunes/${widget.id}.jpg');
    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _dropStream();
    _stream = stream;
    _listener = ImageStreamListener(_onArt, onError: _onArtError);
    stream.addListener(_listener!);
  }

  void _onArtError(Object error, StackTrace? stackTrace) {
    // Missing or undecodable art only means the cinemagraph stays still;
    // the card itself is untouched.
  }

  void _onArt(ImageInfo info, bool syncCall) {
    if (!mounted) {
      info.dispose();
      return;
    }
    _art?.dispose();
    _art = info;
    // A synchronous call means we are already mid-build; the frame being
    // built will pick the image up without another setState.
    if (!syncCall) setState(() {});
  }

  void _dropStream() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _dropStream();
    _art?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = fortuneEffectSpec(widget.id);
    if (spec == null) return const SizedBox.shrink();
    final media = MediaQuery.maybeOf(context);
    final reduced = media?.disableAnimations ?? false;
    final clock = reduced ? null : AmbientMotion.maybeClockOf(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: FortuneEffectPainter(
            spec: spec,
            accent: widget.accent,
            seed: effectSeedFor(widget.id),
            alignment: fortuneFocalAlignment(widget.id),
            clock: clock,
            artImage: _art?.image,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
