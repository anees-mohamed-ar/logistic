import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/models/branch.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/config/company_config.dart';

class BranchController extends GetxController {
  String get baseUrl => '${ApiConfig.baseUrl}/branch';
  final branches = <Branch>[].obs;
  final filteredBranches = <Branch>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final idController = Get.find<IdController>();

  // For search functionality
  void filterBranches(String query) {
    if (query.isEmpty) {
      filteredBranches.assignAll(branches);
      return;
    }

    final queryLower = query.toLowerCase();
    filteredBranches.assignAll(
      branches.where((branch) {
        return branch.branchName.toLowerCase().contains(queryLower) ||
            (branch.branchCode?.toLowerCase().contains(queryLower) ?? false) ||
            (branch.address?.toLowerCase().contains(queryLower) ?? false) ||
            (branch.phone?.toLowerCase().contains(queryLower) ?? false);
      }),
    );
  }

  // Refresh branches list
  Future<void> refreshBranches() async {
    await fetchBranches();
  }

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading(true);
      error.value = '';

      final companyId = idController.companyId.value;
      if (companyId.isEmpty) {
        error.value = 'Company ID not found';
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/company/$companyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        branches.assignAll(data.map((json) => Branch.fromJson(json)).toList());
        filteredBranches.assignAll(branches);
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to load branches';
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addBranch(Branch branch) async {
    try {
      isLoading(true);
      error.value = '';
      final branchData = branch.toJson();
      // Remove status from add operation as backend doesn't handle it
      branchData.remove('status');

      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(branchData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBranches();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to add branch';
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

  Future<bool> updateBranch(Branch branch) async {
    try {
      if (branch.branchId == null) {
        error.value = 'Cannot update branch: Missing ID';
        Get.snackbar('Error', error.value);
        return false;
      }

      isLoading(true);
      error.value = '';
      final branchData = branch.toJson();

      final response = await http.put(
        Uri.parse('$baseUrl/update/${branch.branchId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(branchData),
      );

      if (response.statusCode == 200) {
        await fetchBranches();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to update branch';
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

  Future<bool> deleteBranch(int id) async {
    try {
      isLoading(true);
      error.value = '';
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchBranches();
        return true;
      } else {
        final errorData = json.decode(response.body);
        error.value = errorData['error'] ?? 'Failed to delete branch';
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
