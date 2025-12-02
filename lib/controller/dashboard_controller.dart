import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();

  final isLoading = false.obs;
  final error = ''.obs;

  // Dashboard data observables
  final totalGCs = 0.obs;
  final totalRevenue = 0.0.obs;
  final avgGCRevenue = 0.0.obs;
  final totalDrivers = 0.obs;
  final totalTrucks = 0.obs;
  final recentGCs = <Map<String, dynamic>>[].obs;
  final revenueTrend = <Map<String, dynamic>>[].obs;
  final lastUpdated = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      error.value = '';

      final idController = Get.find<IdController>();
      final companyId = idController.companyId.value;
      final branchId = idController.branchId.value;

      if (companyId.isEmpty) {
        error.value = 'Company ID not found';
        return;
      }

      // Build URL with query parameters
      String url = '${ApiConfig.baseUrl}/api/dashboard?companyId=$companyId';

      print('Dashboard: Fetching data from $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Dashboard: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final dashboardData = data['data'];

          // Update summary data
          final summary = dashboardData['summary'] ?? {};
          totalGCs.value = summary['totalGCs'] ?? 0;
          avgGCRevenue.value = _parseDouble(summary['avgGCRevenue']);

          // Update entities data
          final entities = dashboardData['entities'] ?? {};
          totalDrivers.value = entities['drivers'] ?? 0;
          totalTrucks.value = entities['trucks'] ?? 0;

          // Update recent activity
          final recentActivity = dashboardData['recentActivity'] ?? {};
          final rawRecentGCs = List<Map<String, dynamic>>.from(
            recentActivity['recentGCs'] ?? [],
          );

          // Clean up the recent GCs data
          recentGCs.value = rawRecentGCs.map((gc) {
            final cleanedGC = Map<String, dynamic>.from(gc);
            // Clean up consignor and consignee names by removing quotes
            if (cleanedGC['ConsignorName'] != null) {
              cleanedGC['ConsignorName'] = cleanedGC['ConsignorName']
                  .toString()
                  .replaceAll('"', '')
                  .trim();
            }
            if (cleanedGC['ConsigneeName'] != null) {
              cleanedGC['ConsigneeName'] = cleanedGC['ConsigneeName']
                  .toString()
                  .replaceAll('"', '')
                  .trim();
            }
            return cleanedGC;
          }).toList();

          // Update operations data
          final operations = dashboardData['operations'] ?? {};
          revenueTrend.value = List<Map<String, dynamic>>.from(
            operations['revenueTrend'] ?? [],
          );

          // Update last updated timestamp
          lastUpdated.value = data['lastUpdated'] ?? '';

          print('Dashboard: Data loaded successfully');
          print('Dashboard: Total GCs: ${totalGCs.value}');
          print('Dashboard: Total Drivers: ${totalDrivers.value}');
          print('Dashboard: Total Trucks: ${totalTrucks.value}');
        } else {
          error.value = data['error'] ?? 'Failed to load dashboard data';
        }
      } else {
        error.value =
            'Failed to load dashboard data. Status: ${response.statusCode}';
      }
    } catch (e) {
      error.value = 'Error fetching dashboard data: ${e.toString()}';
      print('Dashboard: Error - $e');
    } finally {
      isLoading.value = false;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  void refreshData() {
    fetchDashboardData();
  }

  // Get recent GC count
  int get recentGCCount {
    return recentGCs.length;
  }
}
