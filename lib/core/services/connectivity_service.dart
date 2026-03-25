import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final List<ConnectivityResult> current = await _connectivity
        .checkConnectivity();
    return !_containsNone(current);
  }

  Stream<bool> onStatusChanged() {
    return _connectivity.onConnectivityChanged.map(
      (List<ConnectivityResult> results) => !_containsNone(results),
    );
  }

  bool _containsNone(List<ConnectivityResult> results) {
    return results.length == 1 && results.first == ConnectivityResult.none;
  }
}
