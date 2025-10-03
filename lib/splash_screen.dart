import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/login_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // It's better to use a try-catch here in case the controller is not registered yet
    // Or ensure the LoginController is initialized before this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final loginController = Get.find<LoginController>();
        loginController.tryAutoLogin();
      } catch (e) {
        // If LoginController not found, it means something is wrong with GetX setup
        // For now, let's default to login screen
        Get.offNamed('/login');
      }
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
}
