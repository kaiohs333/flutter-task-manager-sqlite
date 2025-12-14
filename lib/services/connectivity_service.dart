import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  bool get isOnline =>
      _connectivityResult != ConnectivityResult.none &&
      _connectivityResult != ConnectivityResult.bluetooth;

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(result);
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    if (_connectivityResult != result) {
      _connectivityResult = result;
      notifyListeners();
      debugPrint(
          'Connectivity status changed: $_connectivityResult, isOnline: $isOnline');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

