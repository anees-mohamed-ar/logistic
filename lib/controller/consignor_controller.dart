import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/consignor.dart';
import '../api_config.dart';

class ConsignorController extends GetxController {
  final isLoading = false.obs;
  final consignors = <Consignor>[].obs;
  final filteredConsignors = <Consignor>[].obs;
  final TextEditingController searchController = TextEditingController();
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchConsignors();
    // Initialize filtered list with all consignors
    ever(consignors, (_) => filterConsignors(''));
    // Update filtered list when search text changes
    searchController.addListener(() => filterConsignors(searchController.text));
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void filterConsignors(String query) {
    if (query.isEmpty) {
      filteredConsignors.assignAll(consignors);
      return;
    }

    final searchLower = query.toLowerCase();
    filteredConsignors.assignAll(consignors.where((consignor) {
      return consignor.consignorName.toLowerCase().contains(searchLower) ||
          (consignor.mobileNumber?.toLowerCase().contains(searchLower) ?? false) ||
          (consignor.gst?.toLowerCase().contains(searchLower) ?? false) ||
          (consignor.location?.toLowerCase().contains(searchLower) ?? false) ||
          (consignor.state?.toLowerCase().contains(searchLower) ?? false) ||
          (consignor.email?.toLowerCase().contains(searchLower) ?? false);
    }));
  }

  Future<void> fetchConsignors() async {
    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/consignor/search'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        consignors.value = data.map((json) => Consignor.fromJson(json)).toList();
      } else {
        Get.snackbar('Error', 'Failed to load consignors');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addConsignor(Consignor consignor) async {
    try {
      isLoading(true);
      final companyId = storage.read('companyId') ?? '';
      final payload = consignor.copyWith(companyId: companyId).toJson();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/consignor/add'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        await fetchConsignors();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to add consignor';
        throw error;
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateConsignor(String consignorName, Consignor updatedConsignor) async {
    try {
      isLoading(true);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/consignor/update/$consignorName'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(updatedConsignor.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchConsignors();
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to update consignor';
        throw error;
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Consignor? getConsignorByName(String name) {
    try {
      return consignors.firstWhere((consignor) => consignor.consignorName == name);
    } catch (e) {
      return null;
    }
  }
}
