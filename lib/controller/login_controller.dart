import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';

import 'package:logistic/api_config.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/controller/company_controller.dart';
import 'package:logistic/models/location_model.dart';
import 'package:logistic/config/company_config.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ipController = TextEditingController(text: ApiConfig.baseUrl);

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var userId = ''.obs;
  var companyId = ''.obs;
  var selectedCompany = CompanyConfig.getCompany();
  Location? selectedBranch;

  final _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // You could also check for saved IP here
    final savedIp = _box.read('backend_ip');
    if (savedIp != null) {
      ipController.text = savedIp;
      ApiConfig.baseUrl = savedIp;
    }
    // Set default company from config
    _setDefaultCompany();
  }

  void _setDefaultCompany() {
    // Set default company from CompanyConfig
    selectedCompany = CompanyConfig.getCompany();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validateIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the backend server URL';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> handleLogin() async {
    if (formKey.currentState?.validate() ?? false) {
      isLoading.value = true;
      final ip = ipController.text.trim();
      ApiConfig.baseUrl = ip;
      _box.write('backend_ip', ip); // Save the IP

      try {
        // Use the company from CompanyConfig (should always be set)
        final companyToUse = selectedCompany;
        if (companyToUse == null) {
          Fluttertoast.showToast(
            msg: 'Company configuration error. Please contact administrator.',
            backgroundColor: Colors.red,
          );
          return;
        }

        // Build query parameters
        final queryParams = {
          'userEmail': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'companyId': companyToUse.id.toString(),
        };

        // Add branchId only if selected (optional)
        if (selectedBranch != null) {
          queryParams['branchId'] = selectedBranch!.id.toString();
        }

        final uri = Uri.parse(
          '${ApiConfig.baseUrl}/profile/search?userEmail=${emailController.text.trim()}&password=${passwordController.text.trim()}&companyId=${companyToUse.id.toString()}',
        );

        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userData = data[0];

          // Debug: Log the received user data to verify company validation
          print('Login successful for user: ${userData['userEmail']}');
          print(
            'User companyId: ${userData['companyId']}, Requested companyId: ${companyToUse.id}',
          );

          final idController = Get.find<IdController>();
          idController.setAllUserData(userData);
          idController.setCompanyId(companyToUse.id.toString());
          if (selectedBranch != null) {
            idController.setBranchId(selectedBranch!.id.toString());
          }

          await _box.write('userData', userData);
          await _box.write('selectedCompany', companyToUse.toJson());
          if (selectedBranch != null) {
            await _box.write('selectedBranch', selectedBranch!.toJson());
          }

          Fluttertoast.showToast(msg: "Login Successful!");
          Get.offNamed(AppRoutes.home);
        } else {
          final errorData = jsonDecode(response.body);
          // Debug: Log error details
          print('Login failed with status ${response.statusCode}');
          print('Error message: ${errorData['error']}');

          Fluttertoast.showToast(
            msg: errorData['error'] ?? 'Invalid credentials',
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Failed to connect: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> logout() async {
    print('LOGOUT: Starting logout process');

    // Clear ALL stored data completely
    await _box.erase();
    print('LOGOUT: All storage erased using _box.erase()');

    // Clear controller data
    Get.find<IdController>().clearUserData();

    // Reset local controller state to config defaults
    selectedCompany = CompanyConfig.getCompany();
    selectedBranch = null;
    ipController.text = ApiConfig.baseUrl;

    print('LOGOUT: Local state reset. selectedCompany.id: ${selectedCompany.id}');

    // Navigate to login screen
    Get.offAllNamed(AppRoutes.login);
    print('LOGOUT: Navigation to login completed');
  }

  bool isLoggedIn() {
    return _box.hasData('userData');
  }

  void tryAutoLogin() {
    print('AUTO-LOGIN: Checking login status...');
    print('AUTO-LOGIN: isLoggedIn(): ${isLoggedIn()}');

    if (isLoggedIn()) {
      print('AUTO-LOGIN: User data found, attempting auto-login');
      final userData = _box.read('userData');
      final savedCompany = _box.read('selectedCompany');
      final savedBranch = _box.read('selectedBranch');

      print('AUTO-LOGIN: userData: ${userData != null ? "present" : "null"}');
      print(
        'AUTO-LOGIN: savedCompany: ${savedCompany != null ? "present" : "null"}',
      );
      print(
        'AUTO-LOGIN: savedBranch: ${savedBranch != null ? "present" : "null"}',
      );

      if (userData != null) {
        final idController = Get.find<IdController>();
        idController.setAllUserData(userData);
        if (savedCompany != null) {
          print('AUTO-LOGIN: Using saved company from storage');
          selectedCompany = Company.fromJson(savedCompany);
          idController.setCompanyId(selectedCompany.id.toString());
        } else {
          print('AUTO-LOGIN: Using company from config');
          selectedCompany = CompanyConfig.getCompany();
          idController.setCompanyId(selectedCompany.id.toString());
        }
        if (savedBranch != null) {
          selectedBranch = Location.fromJson(savedBranch);
          idController.setBranchId(selectedBranch!.id.toString());
        }
        print('AUTO-LOGIN: Navigating to home screen');
        Get.offNamed(AppRoutes.home);
      } else {
        print('AUTO-LOGIN: userData is null, going to login');
        Get.offNamed(AppRoutes.login);
      }
    } else {
      print('AUTO-LOGIN: No user data found, going to login screen');
      Get.offNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    // emailController.dispose(); // Controllers are managed by GetX, no need to dispose manually in most cases
    // passwordController.dispose();
    // ipController.dispose();
    super.onClose();
  }
}
