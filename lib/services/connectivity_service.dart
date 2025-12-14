import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  bool get isOnline => _isOnline;

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    // Definir o que consideramos uma conexão "online"
    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    // Notificar os listeners apenas se o status de conexão mudar
    if (hasConnection != _isOnline) {
      _isOnline = hasConnection;
      notifyListeners();
      debugPrint('Connectivity status changed: ${results.toString()}, isOnline: $_isOnline');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
