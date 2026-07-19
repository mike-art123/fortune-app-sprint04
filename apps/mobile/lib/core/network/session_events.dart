import 'dart:async';

/// Broadcast channel for "the backend said 401" (Sprint 04 / doc 53).
///
/// Networking cannot depend on the auth feature (layering), and the auth
/// feature cannot be constructed inside an interceptor — so the interceptor
/// emits here and the session controller listens.
class SessionEvents {
  final _unauthorized = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorized.stream;

  void notifyUnauthorized() {
    if (!_unauthorized.isClosed) _unauthorized.add(null);
  }

  void dispose() {
    _unauthorized.close();
  }
}
