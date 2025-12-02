import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/models/weight_to_rate.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/login_controller.dart';

class WeightToRateController extends GetxController {
  static WeightToRateController get to => Get.find();

  String get baseUrl => '${ApiConfig.baseUrl}/weight_to_rate';

  var isLoading = true.obs;
  var weightRates = <WeightToRate>[].obs;
  var error = ''.obs;

  @override
  void onInit() {
    print('WeightToRateController: onInit called');
    super.onInit();
    // Delay API call until after auto-login is complete
    _delayedInit();
  }

  void _delayedInit() async {
    // Wait a bit for auto-login to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user is logged in before fetching data
    final loginController = Get.find<LoginController>();
    if (loginController.isLoggedIn()) {
      print('WeightToRateController: User logged in, fetching weight rates');
      fetchWeightRates();
    } else {
      print(
        'WeightToRateController: User not logged in, skipping initial fetch',
      );
    }
  }

  Future<void> fetchWeightRates() async {
    try {
      print('[WeightToRateController] Fetching weight rates from: $baseUrl');
      isLoading(true);
      error.value = '';
      final url = Uri.parse('$baseUrl/search');
      print('[WeightToRateController] Making request to $url');

      final response = await http.get(url);
      print(
        '[WeightToRateController] Fetch response status: ${response.statusCode}',
      );
      print('[WeightToRateController] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('WeightToRateController: Request successful');
        final responseData = json.decode(response.body);
        print('WeightToRateController: Decoded response: $responseData');

        // Handle both array and object with data property
        final List<dynamic> data = responseData is List
            ? responseData
            : (responseData['data'] as List? ?? []);

        print('WeightToRateController: Parsed ${data.length} weight rates');

        // Convert each item to WeightToRate and filter out any null values
        final rates = data
            .map((json) {
              try {
                return WeightToRate.fromJson(json);
              } catch (e) {
                print('Error parsing weight rate: $e');
                print('Problematic JSON: $json');
                return null;
              }
            })
            .whereType<WeightToRate>()
            .toList();

        weightRates.value = rates;
        print(
          'WeightToRateController: Successfully parsed ${rates.length} weight rates',
        );
      } else {
        error.value =
            'Failed to load weight rates: ${response.statusCode} - ${response.body}';
        print('WeightToRateController: Error - ${error.value}');
        Get.snackbar('Error', error.value);
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addWeightRate(WeightToRate weightRate) async {
    try {
      print(
        '[WeightToRateController] Starting to add weight rate: ${weightRate.toJson()}',
      );

      // Validate input
      if (weightRate.weight.isEmpty) {
        final error = 'Weight cannot be empty';
        print('[WeightToRateController] Validation failed: $error');
        throw error;
      }
      if (weightRate.below250 <= 0 || weightRate.above250 <= 0) {
        final error = 'Rates must be greater than 0';
        print('[WeightToRateController] Validation failed: $error');
        throw error;
      }

      isLoading(true);
      print('Adding weight rate: ${weightRate.toJson()}');

      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'weight': weightRate.weight,
          'below250': weightRate.below250,
          'above250': weightRate.above250,
        }),
      );

      print(
        'Add request body: ${json.encode({'weight': weightRate.weight, 'below250': weightRate.below250, 'above250': weightRate.above250})}',
      );

      print('Add response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Weight rate added successfully');
        await fetchWeightRates();
        return true;
      } else {
        final errorMsg = _parseErrorResponse(response);
        throw errorMsg;
      }
    } catch (e) {
      print('Error adding weight rate: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateWeightRate(WeightToRate weightRate) async {
    try {
      print(
        '[WeightToRateController] Starting to update weight rate: ${weightRate.toJson()}',
      );

      if (weightRate.id == null) {
        final error = 'Cannot update: Missing ID';
        print('[WeightToRateController] Update failed: $error');
        throw error;
      }

      // Validate input
      if (weightRate.weight.isEmpty) {
        throw 'Weight cannot be empty';
      }
      if (weightRate.below250 <= 0 || weightRate.above250 <= 0) {
        throw 'Rates must be greater than 0';
      }

      isLoading(true);
      print('Updating weight rate: ${weightRate.toJson()}');

      final updateData = weightRate.toJson()..remove('id');
      final response = await http.put(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': weightRate.id, ...updateData}),
      );

      print(
        'Update request body: ${json.encode({'id': weightRate.id, ...updateData})}',
      );

      print('Update response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Weight rate updated successfully');
        await fetchWeightRates();
        return true;
      } else {
        final errorMsg = _parseErrorResponse(response);
        throw errorMsg;
      }
    } catch (e) {
      print('Error updating weight rate: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> deleteWeightRate(int id) async {
    try {
      // Show confirmation dialog
      final confirm = await Get.defaultDialog<bool>(
        title: 'Confirm Delete',
        middleText: 'Are you sure you want to delete this weight rate?',
        textConfirm: 'Delete',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        cancelTextColor: Colors.black54,
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
      );

      if (confirm != true) return false;

      isLoading(true);
      print('Deleting weight rate with ID: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Delete response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Weight rate deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchWeightRates();
        return true;
      } else {
        final errorMsg = _parseErrorResponse(response);
        throw errorMsg;
      }
    } catch (e) {
      print('Error deleting weight rate: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  // Helper method to parse error responses from the API
  String _parseErrorResponse(http.Response response) {
    try {
      final responseBody = json.decode(response.body);
      if (responseBody is Map) {
        return responseBody['message'] ??
            responseBody['error'] ??
            'Failed with status: ${response.statusCode}';
      }
      return 'Failed with status: ${response.statusCode}';
    } catch (e) {
      return 'Failed to parse error response: ${e.toString()}';
    }
  }
}
