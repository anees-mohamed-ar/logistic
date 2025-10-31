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

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ipController = TextEditingController(text: ApiConfig.baseUrl);

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var userId = ''.obs;
  var companyId = ''.obs;
  var selectedCompany = Rx<Company?>(null);
  var selectedBranch = Rx<Location?>(null);

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
    // Set default company
    _setDefaultCompany();
  }

  void _setDefaultCompany() {
    // Set default company ID 6 (Sri Krishna Carrying Corporation)
    selectedCompany.value = Company(
      id: 6,
      companyName: 'Sri Krishna Carrying Corporation',
      address: null,
      phoneNumber: null,
      email: null,
      gst: null,
      state: null,
      country: null,
      website: null,
      contactPerson: null,
    );
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
        // Build query parameters
        final queryParams = {
          'userEmail': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'companyId': selectedCompany.value!.id.toString(),
        };

        // Add branchId only if selected (optional)
        if (selectedBranch.value != null) {
          queryParams['branchId'] = selectedBranch.value!.id.toString();
        }

        final uri = Uri.parse('${ApiConfig.baseUrl}/profile/search?userEmail=${emailController.text.trim()}&password=${passwordController.text.trim()}&companyId=${selectedCompany.value!.id.toString()}');

        final response = await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userData = data[0];

          final idController = Get.find<IdController>();
          idController.setAllUserData(userData);
          idController.setCompanyId(selectedCompany.value!.id.toString());
          if (selectedBranch.value != null) {
            idController.setBranchId(selectedBranch.value!.id.toString());
          }

          await _box.write('userData', userData);
          await _box.write('selectedCompany', selectedCompany.value!.toJson());
          if (selectedBranch.value != null) {
            await _box.write('selectedBranch', selectedBranch.value!.toJson());
          }

          Fluttertoast.showToast(msg: "Login Successful!");
          Get.offNamed(AppRoutes.home);

        } else {
          final errorData = jsonDecode(response.body);
          Fluttertoast.showToast(
              msg: errorData['error'] ?? 'Invalid credentials',
              backgroundColor: Colors.red);
        }
      } catch (e) {
        Fluttertoast.showToast(
            msg: 'Failed to connect: ${e.toString()}',
            backgroundColor: Colors.red);
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> logout() async {
    await _box.remove('userData');
    // Also clear the controllers
    // Get.find<IdController>().clearUserData();
    Get.offAllNamed(AppRoutes.login);
  }

  bool isLoggedIn() {
    return _box.hasData('userData');
  }

  void tryAutoLogin() {
    if (isLoggedIn()) {
      final userData = _box.read('userData');
      final savedCompany = _box.read('selectedCompany');
      final savedBranch = _box.read('selectedBranch');
      if (userData != null) {
        final idController = Get.find<IdController>();
        idController.setAllUserData(userData);
        if (savedCompany != null) {
          selectedCompany.value = Company.fromJson(savedCompany);
          idController.setCompanyId(selectedCompany.value!.id.toString());
        }
        if (savedBranch != null) {
          selectedBranch.value = Location.fromJson(savedBranch);
          idController.setBranchId(selectedBranch.value!.id.toString());
        }
        Get.offNamed(AppRoutes.home);
      }
    } else {
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