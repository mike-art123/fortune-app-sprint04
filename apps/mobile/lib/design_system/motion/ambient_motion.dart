import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The one clock every ambient card effect reads.
///
/// A single ticker drives all of the app's ambient motion: cards never own
/// controllers, they only paint from [elapsedSeconds]. That keeps a screen
/// full of living cards down to one frame source, gives the app a single
/// place to pause everything (background, reduced motion) — and, on purpose,
/// a tree *without* an [AmbientMotion] ancestor is completely still, so no
/// test that pumps a page ever meets an endless animation it did not ask for.
class AmbientMotionClock extends ChangeNotifier {
  double _elapsedSeconds = 0;

  /// Seconds since the clock started, monotonic across pauses.
  double get elapsedSeconds => _elapsedSeconds;

  void _advanceTo(double seconds) {
    _elapsedSeconds = seconds;
    notifyListeners();
  }
}

/// Hosts the clock. Installed once, at the app root.
class AmbientMotion extends StatefulWidget {
  const AmbientMotion({super.key, required this.child});

  final Widget child;

  /// The nearest clock, or null when none is above [context] — callers treat
  /// null as «paint one still frame».
  static AmbientMotionClock? maybeClockOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_AmbientMotionScope>();
    return scope?.notifier;
  }

  @override
  State<AmbientMotion> createState() => _AmbientMotionState();
}

class _AmbientMotionState extends State<AmbientMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final AmbientMotionClock _clock = AmbientMotionClock();
  late final Ticker _ticker;
  double _accumulated = 0;
  bool _reducedMotion = false;
  bool _lifecyclePaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecyclePaused = state != AppLifecycleState.resumed;
    _syncTicker();
  }

  void _onTick(Duration elapsed) {
    _clock._advanceTo(_accumulated + elapsed.inMicroseconds / 1e6);
  }

  void _syncTicker() {
    final running = !_reducedMotion && !_lifecyclePaused;
    if (running && !_ticker.isActive) {
      _ticker.start();
    } else if (!running && _ticker.isActive) {
      _accumulated = _clock.elapsedSeconds;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AmbientMotionScope(notifier: _clock, child: widget.child);
  }
}

class _AmbientMotionScope extends InheritedNotifier<AmbientMotionClock> {
  const _AmbientMotionScope({required super.notifier, required super.child});
}
