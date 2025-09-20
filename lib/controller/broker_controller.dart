import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/models/broker.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';

class BrokerController extends GetxController {
  final String baseUrl = '${ApiConfig.baseUrl}/broker';
  var brokers = <Broker>[].obs;
  var isLoading = false.obs;
  final idController = Get.find<IdController>();

  @override
  void onInit() {
    super.onInit();
    fetchBrokers();
  }

  Future<void> fetchBrokers() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        brokers.value = data.map((json) => Broker.fromJson(json)).toList();
      } else {
        Get.snackbar('Error', 'Failed to load brokers');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addBroker(Broker broker) async {
    try {
      isLoading(true);
      final brokerData = broker.toJson();
      print('Sending broker data: $brokerData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(brokerData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await fetchBrokers();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to add broker';
        Get.snackbar('Error', error);
        return false;
      }
    } catch (e, stackTrace) {
      print('Error in addBroker: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar('Error', 'An error occurred: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateBroker(Broker broker) async {
    try {
      if (broker.id == null) {
        Get.snackbar('Error', 'Cannot update broker: Missing ID');
        return false;
      }
      
      isLoading(true);
      final brokerData = broker.toJson();
      print('Updating broker with data: $brokerData');
      
      final response = await http.put(
        Uri.parse('$baseUrl/update/${broker.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(brokerData),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        await fetchBrokers();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to update broker';
        Get.snackbar('Error', error);
        return false;
      }
    } catch (e, stackTrace) {
      print('Error in updateBroker: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar('Error', 'An error occurred: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> deleteBroker(int id) async {
    try {
      isLoading(true);
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchBrokers();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to delete broker';
        Get.snackbar('Error', error);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }
}
