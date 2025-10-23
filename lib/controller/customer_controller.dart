import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/models/customer_model.dart';
import 'package:logistic/api_config.dart';

class CustomerController extends GetxController {
  final isLoading = false.obs;
  final customers = <Customer>[].obs;
  final filteredCustomers = <Customer>[].obs;
  final error = ''.obs;
  final _client = http.Client();

  @override
  void onInit() {
    super.onInit();
    print('CustomerController initialized');
    fetchCustomers();
    // Initialize filtered list with all items
    ever(customers, (_) => filterCustomers(''));
  }

  Future<void> fetchCustomers() async {
    try {
      print('Fetching customers from: ${ApiConfig.baseUrl}/customer/search');
      isLoading.value = true;
      error.value = '';
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/customer/search'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Customers fetched successfully');
        final List<dynamic> data = jsonDecode(response.body);
        customers.value = data.map((json) => Customer.fromJson(json)).toList();
        filterCustomers('');
        print('Total customers: ${customers.length}');
      } else {
        final errorMessage = 'Failed to load customers. Status: ${response.statusCode}';
        error.value = errorMessage;
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Failed to load customers: ${e.toString()}';
      error.value = errorMessage;
      Get.snackbar('Error', errorMessage);
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
  
  void filterCustomers(String query) {
    if (query.isEmpty) {
      filteredCustomers.assignAll(customers);
    } else {
      final queryLower = query.toLowerCase();
      filteredCustomers.assignAll(customers.where((customer) {
        return customer.customerName.toLowerCase().contains(queryLower) ||
               customer.phoneNumber.contains(query) ||
               customer.mobileNumber.contains(query) ||
               customer.gst.toLowerCase().contains(queryLower) ||
               customer.address.toLowerCase().contains(queryLower);
      }).toList());
    }
  }

  Future<void> refreshCustomers() async {
    await fetchCustomers();
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
