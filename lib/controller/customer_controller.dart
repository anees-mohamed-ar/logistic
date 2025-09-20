import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/models/customer_model.dart';
import 'package:logistic/api_config.dart';

class CustomerController extends GetxController {
  final isLoading = false.obs;
  final customers = <Customer>[].obs;
  final _client = http.Client();

  @override
  void onInit() {
    super.onInit();
    print('CustomerController initialized');
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      print('Fetching customers from: ${ApiConfig.baseUrl}/customer/search');
      isLoading.value = true;
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/customer/search'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('Customers fetched successfully');
        final List<dynamic> data = jsonDecode(response.body);
        customers.value = data.map((json) => Customer.fromJson(json)).toList();
        print('Total customers: ${customers.length}');
        print('Successfully loaded ${customers.length} customers');
      } else {
        print('Failed to load customers. Status code: ${response.statusCode}');
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load customers');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      isLoading.value = true;
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/customer/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customer.toJson()),
      );
      
      if (response.statusCode == 200) {
        await fetchCustomers();
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to add customer';
        Get.snackbar('Error', error.toString());
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add customer: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      isLoading.value = true;
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/customer/update/${customer.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customer.toJson()),
      );
      
      if (response.statusCode == 200) {
        await fetchCustomers();
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to update customer';
        Get.snackbar('Error', error.toString());
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update customer: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
