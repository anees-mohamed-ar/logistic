import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/models/broker.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';

class BrokerController extends GetxController {
  String get baseUrl => '${ApiConfig.baseUrl}/broker';
  final brokers = <Broker>[].obs;
  final filteredBrokers = <Broker>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final idController = Get.find<IdController>();

  // For search functionality
  void filterBrokers(String query) {
    if (query.isEmpty) {
      filteredBrokers.assignAll(brokers);
      return;
    }

    final queryLower = query.toLowerCase();
    filteredBrokers.assignAll(
      brokers.where((broker) {
        return broker.brokerName.toLowerCase().contains(queryLower) ||
            (broker.phoneNumber?.toLowerCase().contains(queryLower) ?? false) ||
            (broker.email?.toLowerCase().contains(queryLower) ?? false);
      }),
    );
  }

  // Refresh brokers list
  Future<void> refreshBrokers() async {
    await fetchBrokers();
  }

  @override
  void onInit() {
    super.onInit();
    fetchBrokers();
  }

  Future<void> fetchBrokers() async {
    try {
      isLoading(true);
      error.value = '';
      final response = await http.get(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        brokers.assignAll(data.map((json) => Broker.fromJson(json)).toList());
        filteredBrokers.assignAll(brokers);
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['message'] ?? 'Failed to load brokers';
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addBroker(Broker broker) async {
    try {
      isLoading(true);
      error.value = '';
      final brokerData = broker.toJson();

      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(brokerData),
      );

      if (response.statusCode == 200) {
        await fetchBrokers();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to add broker';
        Get.snackbar('Error', error.value);
        return false;
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
      Get.snackbar('Error', error.value);
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateBroker(Broker broker) async {
    try {
      if (broker.id == null) {
        error.value = 'Cannot update broker: Missing ID';
        Get.snackbar('Error', error.value);
        return false;
      }

      isLoading(true);
      error.value = '';
      final brokerData = broker.toJson();

      final response = await http.put(
        Uri.parse('$baseUrl/update/${broker.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(brokerData),
      );

      if (response.statusCode == 200) {
        await fetchBrokers();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to update broker';
        Get.snackbar('Error', error.value);
        return false;
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
      Get.snackbar('Error', error.value);
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> deleteBroker(int id) async {
    try {
      isLoading(true);
      error.value = '';
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchBrokers();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to delete broker';
        Get.snackbar('Error', error.value);
        return false;
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
      Get.snackbar('Error', error.value);
      return false;
    } finally {
      isLoading(false);
    }
  }
}
