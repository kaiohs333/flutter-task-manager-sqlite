import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  ConnectivityService() {
    _initConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectivityStatus(results.first);
      }
    });
  }

  ConnectivityResult get connectivityResult => _connectivityResult;
  bool get isOnline => _connectivityResult != ConnectivityResult.none && _connectivityResult != ConnectivityResult.bluetooth;

  Future<void> _initConnectivity() async {
    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    if (result.isNotEmpty) {
      _updateConnectivityStatus(result.first);
    }
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    if (_connectivityResult != result) {
      _connectivityResult = result;
      notifyListeners();
      debugPrint('Connectivity status changed: $_connectivityResult, isOnline: $isOnline');
    }
  }
}
