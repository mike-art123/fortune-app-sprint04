import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity is a HINT, not proof of reachability (doc 51 §30).
/// The app must never block solely because this reports offline.
abstract interface class NetworkInfo {
  Future<bool> get isLikelyOnline;
  Stream<bool> get onLikelyOnlineChanged;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  ConnectivityNetworkInfo([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();
  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.every((e) => e == ConnectivityResult.none);

  @override
  Future<bool> get isLikelyOnline async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onLikelyOnlineChanged =>
      _connectivity.onConnectivityChanged.map(_online);
}
