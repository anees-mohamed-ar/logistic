import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  StreamSubscription<ConnectivityResult>? _subscription;

  static Future<NetworkService> init() async {
    final service = NetworkService();
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected.value = result != ConnectivityResult.none;
  }

  Future<bool> checkInitialConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
