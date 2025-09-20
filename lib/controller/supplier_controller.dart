import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/models/supplier_model.dart';
import 'package:logistic/api_config.dart';

class SupplierController extends GetxController {
  final isLoading = false.obs;
  final suppliers = <Supplier>[].obs;
  final _client = http.Client();

  @override
  void onInit() {
    super.onInit();
    print('SupplierController initialized');
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    try {
      print('Fetching suppliers from: ${ApiConfig.baseUrl}/supplier/search');
      isLoading.value = true;
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/supplier/search'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('Suppliers fetched successfully');
        final List<dynamic> data = jsonDecode(response.body);
        suppliers.value = data.map((json) => Supplier.fromJson(json)).toList();
        print('Total suppliers: ${suppliers.length}');
      } else {
        print('Failed to load suppliers. Status code: ${response.statusCode}');
        throw Exception('Failed to load suppliers');
      }
    } catch (e) {
      print('Error fetching suppliers: $e');
      Get.snackbar('Error', 'Failed to load suppliers');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/supplier/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(supplier.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchSuppliers();
        return true;
      } else {
        Get.snackbar('Error', 'Failed to add supplier');
        return false;
      }
    } catch (e) {
      print('Error adding supplier: $e');
      Get.snackbar('Error', 'Failed to add supplier');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      isLoading.value = true;
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/supplier/update/${supplier.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(supplier.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchSuppliers();
        return true;
      } else {
        Get.snackbar('Error', 'Failed to update supplier');
        return false;
      }
    } catch (e) {
      print('Error updating supplier: $e');
      Get.snackbar('Error', 'Failed to update supplier');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      isLoading.value = true;
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/supplier/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchSuppliers();
        return true;
      } else {
        Get.snackbar('Error', 'Failed to delete supplier');
        return false;
      }
    } catch (e) {
      print('Error deleting supplier: $e');
      Get.snackbar('Error', 'Failed to delete supplier');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
