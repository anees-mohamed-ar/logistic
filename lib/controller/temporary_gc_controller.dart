import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/models/temporary_gc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TemporaryGCController extends GetxController {
  final IdController _idController = Get.find<IdController>();

  final isLoading = false.obs;
  final temporaryGCs = <TemporaryGC>[].obs;
  final selectedTempGC = Rxn<TemporaryGC>();
  final isLocking = false.obs;
  final isConverting = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString currentFilter = 'all'.obs; // 'all', 'available', 'in_use'
  final RxList<TemporaryGC> filteredGCs = <TemporaryGC>[].obs;

  HttpClient? _sseClient;
  StreamSubscription<String>? _sseSub;
  bool _sseClosing = false;

  // Check if current user is admin
  bool get isAdmin => _idController.userRole.value == 'admin';

  // Check if user has access to GC ranges (either active or queued)
  Future<bool> checkGCAccess() async {
    try {
      final userId = _idController.userId.value;
      if (userId.isEmpty) {
        print('No user ID, denying access');
        return false; // Deny access if no user ID
      }
      
      print('Checking GC access for user: $userId');
      
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/gc-management/usage/$userId'),
        );
        
        print('GC access check response: ${response.statusCode}');
        
        // Parse the response body
        final responseBody = jsonDecode(response.body);
        
        // If we get a 200 response with success: true
        if (response.statusCode == 200 && responseBody['success'] == true) {
          final List<dynamic> gcRanges = responseBody['data'] ?? [];
          
          // Check if any range has status 'active' or 'queued'
          final hasValidRange = gcRanges.any((range) => 
            range['status'] == 'active' || range['status'] == 'queued'
          );
          
          if (hasValidRange) {
            print('Access granted - User has active/queued GC ranges');
            return true;
          } else {
            print('Access denied - No active or queued GC ranges found');
            print('Available ranges: ${gcRanges.map((r) => '${r['fromGC']}-${r['toGC']} (${r['status']})').toList()}');
            return false;
          }
        } 
        // Handle case when no GC ranges found for user
        else if (response.statusCode == 200 && 
                responseBody['success'] == false &&
                responseBody['message'] == 'No GC ranges found for user') {
          print('Access denied - No GC ranges found for user');
          return false;
        }
        
        // For any other case, log the response and deny access
        print('GC usage check returned status: ${response.statusCode} - ${response.body}');
        print('Denying access due to unexpected response');
        return false;
        
      } catch (e) {
        print('Error checking GC access, denying access: $e');
        // On any error, deny access to be safe
        return false;
      }
      
    } catch (e) {
      print('Unexpected error in checkGCAccess, denying access: $e');
      // Default to false to be safe if there's any error
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchTemporaryGCs().then((_) => _connectToLiveUpdates());
  }

  @override
  void onClose() {
    _disconnectFromLiveUpdates();
    super.onClose();
  }

  // Apply search and filters to the temporary GCs list
  void _applyFilters() {
    var result = temporaryGCs.toList();
    
    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((gc) {
        return (gc.tempGcNumber?.toLowerCase().contains(query) ?? false) ||
               (gc.truckFrom?.toLowerCase().contains(query) ?? false) ||
               (gc.truckTo?.toLowerCase().contains(query) ?? false) ||
               (gc.consignorName?.toLowerCase().contains(query) ?? false) ||
               (gc.consigneeName?.toLowerCase().contains(query) ?? false) ||
               (gc.vechileNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply status filter
    if (currentFilter.value == 'available') {
      result = result.where((gc) => !gc.isLocked).toList();
    } else if (currentFilter.value == 'in_use') {
      result = result.where((gc) => gc.isLocked).toList();
    }
    
    filteredGCs.value = result;
  }
  
  // Update search query and apply filters
  void updateSearchQuery(String query) {
    searchQuery.value = query.trim();
    _applyFilters();
  }
  
  // Update filter and apply
  void updateFilter(String filter) {
    currentFilter.value = filter;
    _applyFilters();
  }

  // Fetch all available temporary GCs
  Future<void> fetchTemporaryGCs() async {
    try {
      isLoading.value = true;
      final companyId = _idController.companyId.value;

      if (companyId.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Company ID not found',
          backgroundColor: Colors.red,
        );
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/list?companyId=$companyId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> gcList = data['data'];
          temporaryGCs.value = gcList.map((json) => TemporaryGC.fromJson(json)).toList();
          _applyFilters();
        } else {
          Fluttertoast.showToast(
            msg: data['message'] ?? 'Failed to fetch temporary GCs',
            backgroundColor: Colors.red,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Server error: ${response.statusCode}',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Error fetching temporary GCs: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get single temporary GC
  Future<TemporaryGC?> getTemporaryGC(String tempGcNumber) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/get/$tempGcNumber');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TemporaryGC.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting temporary GC: $e');
      return null;
    }
  }

  // Lock temporary GC before editing
  Future<bool> lockTemporaryGC(String tempGcNumber) async {
    try {
      isLocking.value = true;
      final userId = _idController.userId.value;

      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/lock/$tempGcNumber');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Temporary GC locked successfully',
          backgroundColor: Colors.green,
        );
        return true;
      } else if (response.statusCode == 423) {
        // Locked by another user
        Fluttertoast.showToast(
          msg: data['message'] ?? 'This GC is being edited by another user',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Failed to lock temporary GC',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      print('Error locking temporary GC: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isLocking.value = false;
    }
  }

  // Unlock temporary GC
  Future<void> unlockTemporaryGC(String tempGcNumber) async {
    try {
      final userId = _idController.userId.value;

      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/unlock/$tempGcNumber');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Temporary GC unlocked successfully');
        }
      }
    } catch (e) {
      print('Error unlocking temporary GC: $e');
    }
  }

  // Connect to SSE for live updates using HttpClient (no external deps)
  Future<void> _connectToLiveUpdates() async {
    try {
      final companyId = _idController.companyId.value;
      if (companyId.isEmpty) return;

      _disconnectFromLiveUpdates();

      _sseClient = HttpClient();
      _sseClient!.connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/stream?companyId=$companyId');
      final req = await _sseClient!.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      final resp = await req.close();

      if (resp.statusCode != 200) {
        print('SSE connect failed: ${resp.statusCode}');
        _scheduleReconnect();
        return;
      }

      String? currentEvent;
      final dataBuf = StringBuffer();

      _sseSub = resp
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.isEmpty) {
          if (dataBuf.isNotEmpty) {
            final raw = dataBuf.toString().trimRight();
            dataBuf.clear();
            try {
              final parsed = json.decode(raw);
              _dispatchSseEvent(currentEvent, parsed);
            } catch (e) {
              print('SSE data parse error: $e');
            }
          }
          currentEvent = null;
          return;
        }
        if (line.startsWith(':')) return; // comment/heartbeat
        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
          return;
        }
        if (line.startsWith('data:')) {
          dataBuf.writeln(line.substring(5).trimLeft());
          return;
        }
      }, onDone: () {
        if (!_sseClosing) _scheduleReconnect();
      }, onError: (e) {
        print('SSE error: $e');
        if (!_sseClosing) _scheduleReconnect();
      }, cancelOnError: true);
    } catch (e) {
      print('Error connecting to SSE: $e');
      _scheduleReconnect();
    }
  }

  void _dispatchSseEvent(String? event, dynamic data) {
    switch (event) {
      case 'temp_gc_snapshot':
        _handleGCSnapshot(data);
        break;
      case 'temp_gc_created':
        _handleGCCreated(data);
        break;
      case 'temp_gc_locked':
        _handleGCLocked(data);
        break;
      case 'temp_gc_unlocked':
        _handleGCUnlocked(data);
        break;
      case 'temp_gc_converted':
      case 'temp_gc_deleted':
        _handleGCRemoved(data);
        break;
      default:
        break;
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!Get.isRegistered<TemporaryGCController>()) return;
      _connectToLiveUpdates();
    });
  }

  void _disconnectFromLiveUpdates() {
    _sseClosing = true;
    _sseSub?.cancel();
    _sseSub = null;
    try {
      _sseClient?.close(force: true);
    } catch (_) {}
    _sseClient = null;
    _sseClosing = false;
  }

  void _handleGCSnapshot(dynamic data) {
    try {
      final items = (data['items'] as List)
          .map((e) => TemporaryGC.fromJson(e))
          .toList();
      temporaryGCs.value = items;
    } catch (e) {
      print('Error processing snapshot: $e');
    }
  }

  void _handleGCCreated(dynamic data) async {
    try {
      final gc = await getTemporaryGC(data['temp_gc_number']);
      if (gc != null) {
        temporaryGCs.insert(0, gc);
      }
    } catch (e) {
      print('Error handling GC created: $e');
    }
  }

  void _handleGCLocked(dynamic data) {
    try {
      final tempGcNumber = data['temp_gc_number'];
      final lockedByUserId = data['locked_by_user_id'];
      final index = temporaryGCs.indexWhere((g) => g.tempGcNumber == tempGcNumber);
      if (index >= 0) {
        final updated = temporaryGCs[index].copyWith(
          isLocked: true,
          lockedByUserId: lockedByUserId,
          lockedAt: DateTime.now(),
        );
        temporaryGCs[index] = updated;
        temporaryGCs.refresh();
      }
    } catch (e) {
      print('Error handling GC locked: $e');
    }
  }

  void _handleGCUnlocked(dynamic data) {
    try {
      final tempGcNumber = data['temp_gc_number'];
      final index = temporaryGCs.indexWhere((g) => g.tempGcNumber == tempGcNumber);
      if (index >= 0) {
        final updated = temporaryGCs[index].copyWith(
          isLocked: false,
          lockedByUserId: null,
          lockedAt: null,
        );
        temporaryGCs[index] = updated;
        temporaryGCs.refresh();
      }
    } catch (e) {
      print('Error handling GC unlocked: $e');
    }
  }

  void _handleGCRemoved(dynamic data) {
    try {
      final tempGcNumber = data['temp_gc_number'];
      temporaryGCs.removeWhere((g) => g.tempGcNumber == tempGcNumber);
    } catch (e) {
      print('Error handling GC removed: $e');
    }
  }

  // Mark a GC number as used for the current user
  Future<bool> _markGCNumberAsUsed(String gcNumber) async {
    try {
      final userId = _idController.userId.value;
      final url = Uri.parse('${ApiConfig.baseUrl}/api/gc-management/submit-gc');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'gcNumber': gcNumber,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to mark GC number as used: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error marking GC number as used: $e');
      return false;
    }
  }

  // Convert temporary GC to actual GC
  Future<bool> convertTemporaryGC({
    required String tempGcNumber,
    required String actualGcNumber,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      isConverting.value = true;
      final userId = _idController.userId.value;

      // First convert the temporary GC to a real GC
      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/convert/$tempGcNumber');
      final body = {
        'userId': userId,
        'actualGcNumber': actualGcNumber,
        ...additionalData,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mark the GC number as used for the current user
        final gcMarked = await _markGCNumberAsUsed(actualGcNumber);
        
        if (!gcMarked) {
          // Log the error but don't fail the operation
          print('Warning: Failed to mark GC number as used, but conversion was successful');
        }
        
        Fluttertoast.showToast(
          msg: 'GC created successfully!',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        
        // The list will be updated automatically via SSE
        return true;
      } else if (response.statusCode == 409) {
        // GC number already exists
        Fluttertoast.showToast(
          msg: data['message'] ?? 'This GC number already exists. Another user may have filled this temporary GC.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Failed to convert temporary GC',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      print('Error converting temporary GC: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isConverting.value = false;
    }
  }

  // Create temporary GC (Admin only)
  Future<bool> createTemporaryGC(Map<String, dynamic> gcData) async {
    try {
      if (!isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only admins can create temporary GCs',
          backgroundColor: Colors.red,
        );
        return false;
      }

      isLoading.value = true;
      final userId = _idController.userId.value;

      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/create');
      final body = {
        'userId': userId,
        ...gcData,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Temporary GC created successfully!\nGC Number: ${data['data']['temp_gc_number']}',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        
        // Refresh the list
        await fetchTemporaryGCs();
        return true;
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Failed to create temporary GC',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      print('Error creating temporary GC: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update temporary GC (Admin only)
  Future<bool> updateTemporaryGC(String tempGcNumber, Map<String, dynamic> updateData) async {
    try {
      if (!isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only admins can update temporary GCs',
          backgroundColor: Colors.red,
        );
        return false;
      }

      isLoading.value = true;
      final userId = _idController.userId.value;

      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/update/$tempGcNumber');
      final body = {
        'userId': userId,
        ...updateData,
      };

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Temporary GC updated successfully!',
          backgroundColor: Colors.green,
        );
        
        // Refresh the list
        await fetchTemporaryGCs();
        return true;
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Failed to update temporary GC',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      print('Error updating temporary GC: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete temporary GC (Admin only)
  Future<bool> deleteTemporaryGC(String tempGcNumber) async {
    try {
      if (!isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only admins can delete temporary GCs',
          backgroundColor: Colors.red,
        );
        return false;
      }

      isLoading.value = true;
      final userId = _idController.userId.value;

      final url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/delete/$tempGcNumber');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Temporary GC deleted successfully!',
          backgroundColor: Colors.green,
        );
        
        // Refresh the list
        await fetchTemporaryGCs();
        return true;
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? 'Failed to delete temporary GC',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      print('Error deleting temporary GC: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Check if user can edit a GC (for admin bypass)
  Future<Map<String, dynamic>> canEditGC(String gcNumber) async {
    try {
      final userId = _idController.userId.value;
      final companyId = _idController.companyId.value;

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/temporary-gc/can-edit/$gcNumber?companyId=$companyId&userId=$userId'
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return {'success': false, 'canEdit': false};
    } catch (e) {
      print('Error checking edit permission: $e');
      return {'success': false, 'canEdit': false};
    }
  }
}
