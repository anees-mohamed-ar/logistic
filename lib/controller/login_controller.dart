import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  void handleSocialLogin(String provider) {
    // TODO: Implement social login logic based on the provider argument
    // For example, you can use Get.snackbar for demonstration:
    Get.snackbar('Social Login', 'Pressed: $provider');
  }

  Future<void> handleLogin() async {
    if (formKey.currentState!.validate()) {
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

        isLoading.value = false;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Extract userId and companyId from API response (adjust keys as needed)
          final String fetchedUserId = data[0]['userId'].toString();
          final String fetchedCompanyId = data[0]['companyId'].toString();

          // Store in GetX for global access
          userId.value = fetchedUserId;
          companyId.value = fetchedCompanyId;
          // Also store in IdController for global access
          final idController = Get.find<IdController>();
          idController.setUserId(fetchedUserId);
          idController.setCompanyId(fetchedCompanyId);

          // Show success message and navigate
          Get.snackbar(
            '',
            'Login Successful!',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4A90E2).withOpacity(0.9),
            colorText: Colors.white,
          );
          Get.offNamed(AppRoutes.home); // Navigate to home screen
        } else {
          // Handle API errors
          final errorData = jsonDecode(response.body);
          Get.snackbar(
            'Error',
            errorData['error'] ?? 'Invalid credentials',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Failed to connect: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    }
  }

  // Validators (unchanged)
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    // if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    ipController.dispose();
    super.onClose();
  }
}
