import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/login_controller.dart';
import 'package:logistic/services/network_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final NetworkService _networkService;
  Worker? _connectionWorker;
  bool _isDialogShown = false;
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();
    _networkService = Get.find<NetworkService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _setupConnectivityMonitoring() {
    _connectionWorker = ever<bool>(_networkService.isConnected, (connected) async {
      if (!mounted) return;
      _hasConnection = connected;
      if (!connected) {
        await _showNoConnectionDialog();
      } else {
        if (_isDialogShown && (Get.isDialogOpen ?? false)) {
          Get.back();
        }
        _navigateAfterConnection();
      }
    });

    _hasConnection = _networkService.isConnected.value;
    if (_hasConnection) {
      _navigateAfterConnection();
    } else {
      _showNoConnectionDialog();
    }
  }

  Future<void> _showNoConnectionDialog() async {
    if (_isDialogShown) return;
    _isDialogShown = true;

    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
            'Please turn on your internet connection to continue using the app.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final hasConnection = await _networkService.checkInitialConnection();
                if (hasConnection) {
                  _hasConnection = true;
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  _navigateAfterConnection();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    _isDialogShown = false;
  }

  void _navigateAfterConnection() {
    if (!_hasConnection) return;
    try {
      final loginController = Get.find<LoginController>();
      loginController.tryAutoLogin();
    } catch (_) {
      Get.offNamed('/login');
    }
  }

  @override
  void dispose() {
    _connectionWorker?.dispose();
    super.dispose();
  }
}
