import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();

  final isLoading = false.obs;
  final error = ''.obs;

  IO.Socket? _socket;

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
    _initSocket();
  }

  void _initSocket() {
    try {
      final idController = Get.find<IdController>();
      final companyId = idController.companyId.value;
      final branchId = idController.branchId.value;

      if (companyId.isEmpty) {
        return;
      }

      _socket = IO.io(
        ApiConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _socket!.emit('dashboard:subscribe', {
          'companyId': companyId,
          'branchId': branchId,
        });
      });

      _socket!.on('dashboard:update', (data) {
        try {
          if (data is Map) {
            _updateFromPayload(Map<String, dynamic>.from(data));
          }
        } catch (e) {
          // swallow parsing errors to avoid breaking the stream
        }
      });

      _socket!.on('dashboard:error', (data) {
        if (data is Map && data['error'] != null) {
          error.value = data['error'].toString();
        }
      });
    } catch (_) {
      // If socket setup fails, we still have HTTP fallback.
    }
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
          _updateFromPayload(Map<String, dynamic>.from(data));
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

  void _updateFromPayload(Map<String, dynamic> payload) {
    // Payload can be a full HTTP response or a socket event payload.
    final dashboardData =
        payload['data'] ?? payload['dashboardData'] ?? payload;

    // Summary
    final summary = dashboardData['summary'] ?? {};
    totalGCs.value = summary['totalGCs'] ?? 0;
    avgGCRevenue.value = _parseDouble(summary['avgGCRevenue']);

    // Entities
    final entities = dashboardData['entities'] ?? {};
    totalDrivers.value = entities['drivers'] ?? 0;
    totalTrucks.value = entities['trucks'] ?? 0;

    // Recent activity
    final recentActivity = dashboardData['recentActivity'] ?? {};
    final rawRecentGCs = List<Map<String, dynamic>>.from(
      recentActivity['recentGCs'] ?? [],
    );

    recentGCs.value = rawRecentGCs.map((gc) {
      final cleanedGC = Map<String, dynamic>.from(gc);
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

    // Operations
    final operations = dashboardData['operations'] ?? {};
    revenueTrend.value = List<Map<String, dynamic>>.from(
      operations['revenueTrend'] ?? [],
    );

    // Last updated timestamp
    lastUpdated.value =
        payload['lastUpdated']?.toString() ??
        dashboardData['lastUpdated']?.toString() ??
        '';
  }

  void refreshData() {
    fetchDashboardData();
    final idController = Get.find<IdController>();
    final companyId = idController.companyId.value;
    final branchId = idController.branchId.value;

    if (_socket != null && companyId.isNotEmpty) {
      _socket!.emit('dashboard:subscribe', {
        'companyId': companyId,
        'branchId': branchId,
      });
    }
  }

  // Get recent GC count
  int get recentGCCount {
    return recentGCs.length;
  }

  @override
  void onClose() {
    _socket?.dispose();
    super.onClose();
  }
}
