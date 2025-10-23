import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/consignee.dart';
import '../api_config.dart';

class ConsigneeController extends GetxController {
  final isLoading = false.obs;
  final consignees = <Consignee>[].obs;
  final filteredConsignees = <Consignee>[].obs;
  final searchController = TextEditingController();
  final storage = GetStorage();
  
  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    fetchConsignees();
  }

  Future<void> fetchConsignees() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/consignee/search'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        consignees.value = data.map((json) => Consignee.fromJson(json)).toList();
        filterConsignees(''); // Initialize filtered list with all consignees
      } else {
        Get.snackbar('Error', 'Failed to load consignees');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading(false);
    }
  }
  
  void filterConsignees(String query) {
    if (query.isEmpty) {
      filteredConsignees.assignAll(consignees);
    } else {
      final searchQuery = query.toLowerCase();
      filteredConsignees.assignAll(consignees.where((consignee) {
        return consignee.consigneeName.toLowerCase().contains(searchQuery) ||
               consignee.phoneNumber.toLowerCase().contains(searchQuery) ||
               consignee.mobileNumber.toLowerCase().contains(searchQuery) ||
               consignee.email.toLowerCase().contains(searchQuery) ||
               consignee.address.toLowerCase().contains(searchQuery) ||
               consignee.gst.toLowerCase().contains(searchQuery) ||
               consignee.panNumber.toLowerCase().contains(searchQuery);
      }).toList());
    }
  }

  Future<bool> addConsignee(Consignee consignee) async {
    try {
      isLoading(true);
      final companyId = storage.read('companyId') ?? '';
      final payload = consignee.copyWith(companyId: companyId).toJson();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/consignee/add'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        await fetchConsignees();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to add consignee';
        throw error;
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateConsignee(String consigneeName, Consignee updatedConsignee) async {
    try {
      isLoading(true);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/consignee/update/$consigneeName'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(updatedConsignee.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchConsignees();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to update consignee';
        throw error;
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Consignee? getConsigneeByName(String name) {
    try {
      return consignees.firstWhere((consignee) => consignee.consigneeName == name);
    } catch (e) {
      return null;
    }
  }
}
