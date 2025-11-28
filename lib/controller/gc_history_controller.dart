import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';

class GCHistoryController extends GetxController {
  final IdController _idController = Get.find<IdController>();

  // Raw data from backend
  final _allRanges = <Map<String, dynamic>>[].obs;

  // UI state
  final isLoading = false.obs;
  final error = RxnString();

  // Filters
  final statusFilter = 'all'.obs;
  final searchQuery = ''.obs;

  // Pagination
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final totalItems = 0.obs;

  List<Map<String, dynamic>> get visibleRanges {
    final query = searchQuery.value.trim().toLowerCase();
    return _allRanges
        .where((range) {
          if (statusFilter.value != 'all' &&
              (range['status'] ?? '').toString().toLowerCase() !=
                  statusFilter.value) {
            return false;
          }

          if (query.isEmpty) return true;

          final userName = (range['userName'] ?? '').toString().toLowerCase();
          final fromGC = (range['fromGC'] ?? '').toString().toLowerCase();
          final toGC = (range['toGC'] ?? '').toString().toLowerCase();
          final currentGC = (range['currentGC'] ?? '').toString().toLowerCase();

          return userName.contains(query) ||
              fromGC.contains(query) ||
              toGC.contains(query) ||
              currentGC.contains(query);
        })
        .toList(growable: false);
  }

  // Get all ranges sorted by fromGC
  List<Map<String, dynamic>> get sortedRanges {
    final ranges = List<Map<String, dynamic>>.from(_allRanges);
    ranges.sort((a, b) {
      final fromA = int.tryParse(a['fromGC']?.toString() ?? '0') ?? 0;
      final fromB = int.tryParse(b['fromGC']?.toString() ?? '0') ?? 0;
      return fromA.compareTo(fromB);
    });
    return ranges;
  }

  // Get complete picture: allocated + available ranges
  List<Map<String, dynamic>> get completeRangeMap {
    final sorted = sortedRanges;
    final result = <Map<String, dynamic>>[];

    if (sorted.isEmpty) return result;

    // Add first range
    result.add({...sorted[0], 'isAllocated': true});

    // Check gaps between ranges
    for (int i = 0; i < sorted.length - 1; i++) {
      final currentTo = int.tryParse(sorted[i]['toGC']?.toString() ?? '0') ?? 0;
      final nextFrom =
          int.tryParse(sorted[i + 1]['fromGC']?.toString() ?? '0') ?? 0;

      if (nextFrom > currentTo + 1) {
        // Available gap
        result.add({
          'isAllocated': false,
          'fromGC': (currentTo + 1).toString(),
          'toGC': (nextFrom - 1).toString(),
          'totalGCs': nextFrom - currentTo - 1,
          'status': 'available',
        });
      }

      result.add({...sorted[i + 1], 'isAllocated': true});
    }

    return result;
  }

  // Alias used by GC history page for visual timeline
  List<Map<String, dynamic>> get rangesWithGaps => completeRangeMap;

  // Get next available ranges (for suggestions)
  List<Map<String, dynamic>> get availableRanges {
    return completeRangeMap.where((r) => r['isAllocated'] == false).toList();
  }

  // Get highest used GC number
  int get highestUsedGC {
    if (sortedRanges.isEmpty) return 0;
    final last = sortedRanges.last;
    return int.tryParse(last['toGC']?.toString() ?? '0') ?? 0;
  }

  Future<void> fetchHistory({int page = 1}) async {
    final companyId = _idController.companyId.value;
    if (companyId.isEmpty) {
      error.value = 'Company not selected';
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;

      final uri = Uri.parse('${ApiConfig.baseUrl}/gc-management/history')
          .replace(
            queryParameters: {
              'companyId': companyId,
              'page': page.toString(),
              'limit': '20',
              if (statusFilter.value != 'all') 'status': statusFilter.value,
            },
          );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final list = (decoded['data'] as List?) ?? const [];
          final pagination =
              (decoded['pagination'] as Map<String, dynamic>? ?? const {});

          _allRanges.assignAll(
            list
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList(),
          );

          currentPage.value = (pagination['page'] as int?) ?? page;
          totalPages.value = (pagination['totalPages'] as int?) ?? 1;
          totalItems.value = (pagination['total'] as int?) ?? _allRanges.length;
        } else {
          error.value =
              decoded['message']?.toString() ?? 'Failed to load GC history';
        }
      } else {
        error.value =
            'Failed to load GC history (${response.statusCode.toString()})';
      }
    } catch (e) {
      error.value = 'Error loading GC history: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void setStatusFilter(String status) {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    fetchHistory(page: 1);
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'queued':
        return Colors.orange;
      case 'expired':
        return Colors.red.shade400;
      case 'available':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_circle_fill_rounded;
      case 'queued':
        return Icons.schedule_rounded;
      case 'expired':
        return Icons.block_rounded;
      case 'available':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}
