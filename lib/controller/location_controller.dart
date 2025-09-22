import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/models/location_model.dart';
import 'package:logistic/api_config.dart';

class LocationController extends GetxController {
  final isLoading = false.obs;
  final locations = <Location>[].obs;
  final error = ''.obs;
  final _client = http.Client();

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      error.value = '';
      isLoading.value = true;
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/location/search'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        locations.value = data.map((json) => Location.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load locations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar('Error', 'Failed to load locations');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addLocation(Location location) async {
    try {
      isLoading.value = true;
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/location/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(location.toJson()),
      );
      
      if (response.statusCode == 200) {
        await fetchLocations();
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to add location';
        Get.snackbar('Error', error.toString());
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add location: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateLocation(Location location) async {
    try {
      isLoading.value = true;
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/location/update/${location.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(location.toJson()),
      );
      
      if (response.statusCode == 200) {
        await fetchLocations();
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update location';
        Get.snackbar('Error', error.toString());
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update location: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/location/branches'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
