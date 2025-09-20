import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:logistic/api_config.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/controller/id_controller.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ipController = TextEditingController(text: ApiConfig.baseUrl);

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  // Observable variables to store user data (accessible globally via GetX)
  var userId = ''.obs;
  var companyId = ''.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validateIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the backend IP';
    }
    // Simple IPv4 validation
    // final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    // if (!ipRegex.hasMatch(value)) {
    //   return 'Enter a valid IP address';
    // }
    return null;
  }

  // Email validation method
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validation method
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    return null;
  }

  void handleSocialLogin(String provider) {
    // TODO: Implement social login logic based on the provider argument
    // For example, you can use Get.snackbar for demonstration:
    Get.snackbar('Social Login', 'Pressed: $provider');
  }

  Future<void> handleLogin() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }
    ApiConfig.baseUrl = ipController.text.trim();
    isLoading.value = true;

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/profile/search?userEmail=${emailController.text.trim()}&password=${passwordController.text.trim()}',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data[0];

        // Store all user data in IdController
        final idController = Get.find<IdController>();
        idController.setAllUserData(userData);

        // Also store in local variables for backward compatibility
        userId.value = userData['userId'].toString();
        companyId.value = userData['companyId'].toString();

        // Stop loading immediately before navigation
        isLoading.value = false;

        // Show success toast message
        Fluttertoast.showToast(
          msg: "Login Successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF4A90E2),
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Navigate to home screen
        Get.offNamed(AppRoutes.home);
      } else {
        isLoading.value = false;
        // Handle API errors with toast
        final errorData = jsonDecode(response.body);
        Fluttertoast.showToast(
          msg: errorData['error'] ?? 'Invalid credentials',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(
        msg: 'Failed to connect: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  void onClose() {
    // Intentionally do not dispose controllers here.
    // GetX may rebuild LoginScreen after navigation (e.g., from Register),
    // and disposing these controllers can lead to 'used after disposed' errors
    // if the same instance is reused by Get.
    // Rely on app shutdown or GetX cleanup to release them.
    super.onClose();
  }
}
