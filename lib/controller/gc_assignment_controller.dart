import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:logistic/controller/id_controller.dart';

class GCAssignmentController extends GetxController {
  //Form controllers
  final userCtrl = TextEditingController();
  final fromGcCtrl = TextEditingController();
  final toGcCtrl = TextEditingController();
  final countCtrl = TextEditingController();
  final statusCtrl = TextEditingController();

  // Form state
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  // User data
  final users = <Map<String, dynamic>>[].obs;
  final selectedUser = Rxn<Map<String, dynamic>>();
  final filteredUsers = <Map<String, dynamic>>[].obs;
  final usersLoading = false.obs;
  final usersError = RxnString();

  // User range status
  final hasActiveRanges = false.obs;
  final checkingRangeStatus = false.obs;

  // User usage data
  final userUsageData = <Map<String, dynamic>>[].obs;
  final loadingUsage = false.obs;
  final usageError = RxnString();

  // From GC number validation
  final gcNumberValidating = false.obs;
  final gcNumberStatus = RxnString(); // 'available', 'active', 'queued', 'expired'
  final gcNumberMessage = RxnString();
  final gcNumberIsInUse = false.obs;

  // To GC number validation
  final toGcNumberValidating = false.obs;
  final toGcNumberStatus = RxnString(); // 'available', 'active', 'queued', 'expired'
  final toGcNumberMessage = RxnString();
  final toGcNumberIsInUse = false.obs;

  final IdController _idController = Get.find<IdController>();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    
    // Add listener to fromGcCtrl for real-time validation
    fromGcCtrl.addListener(_onFromGcChanged);
    
    // Add listeners to auto-calculate toGc
    fromGcCtrl.addListener(_calculateToGc);
    countCtrl.addListener(_calculateToGc);
  }

  @override
  void onClose() {
    fromGcCtrl.removeListener(_onFromGcChanged);
    fromGcCtrl.removeListener(_calculateToGc);
    countCtrl.removeListener(_calculateToGc);
    userCtrl.dispose();
    fromGcCtrl.dispose();
    toGcCtrl.dispose();
    countCtrl.dispose();
    statusCtrl.dispose();
    super.onClose();
  }

  // Fetch users from profile/user/search endpoint
  Future<void> fetchUsers() async {
    try {
      usersLoading.value = true;
      usersError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/profile/user/search')
          .replace(queryParameters: {
        'companyId': _idController.companyId.value,
      });
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        users.assignAll(decoded.cast<Map<String, dynamic>>());
        filteredUsers.assignAll(decoded.cast<Map<String, dynamic>>());

        if (users.isEmpty) {
          usersError.value = 'No users found';
        }
      } else {
        usersError.value = 'Failed to load users (${response.statusCode})';
      }
    } catch (e) {
      usersError.value = 'Failed to load users. Tap to retry.';
      print('Error fetching users: $e');
    } finally {
      usersLoading.value = false;
    }
  }

  // Filter users based on search query
  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.assignAll(users);
    } else {
      filteredUsers.assignAll(
        users.where((user) =>
        (user['userName'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
            (user['userEmail'] ?? '').toString().toLowerCase().contains(query.toLowerCase())
        ).toList(),
      );
    }
  }

  // Check if selected user has active or queued ranges
  Future<void> checkUserActiveRanges(int userId) async {
    try {
      checkingRangeStatus.value = true;
      
      // First check if user has any queued ranges
      await fetchUserUsage(userId);
      
      // Check if user has any queued ranges
      final hasQueuedRanges = userUsageData.any((range) => range['status'] == 'queued');
      
      if (hasQueuedRanges) {
        hasActiveRanges.value = true;
        statusCtrl.text = 'queued';
        Fluttertoast.showToast(
          msg: 'User has queued GC ranges. New assignment will also be queued.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }
      
      // If no queued ranges, check for active ranges
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      final url = Uri.parse('${ApiConfig.baseUrl}/gc-management/check-active-ranges/$userId')
          .replace(queryParameters: {
        'companyId': companyId,
        if (branchId.isNotEmpty) 'branchId': branchId,
      });
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bool hasActive = responseData['hasActiveRanges'] ?? false;
        hasActiveRanges.value = hasActive;

        // Show appropriate message
        if (hasActive) {
          Fluttertoast.showToast(
            msg: 'User has active GC ranges. Assignment will be queued.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
          statusCtrl.text = 'queued';
        } else {
          Fluttertoast.showToast(
            msg: 'No active or queued ranges found. Assignment will be active.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          statusCtrl.text = 'active';
        }
      } else {
        // Default to queued status if we can't determine
        hasActiveRanges.value = true;
        statusCtrl.text = 'queued';
        Fluttertoast.showToast(
          msg: 'Could not check user status. Defaulting to queued assignment.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error checking user ranges: $e');
      // Default to queued status if there's an error
      hasActiveRanges.value = true;
      statusCtrl.text = 'queued';
      Fluttertoast.showToast(
        msg: 'Error checking user status. Defaulting to queued assignment.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    } finally {
      checkingRangeStatus.value = false;
    }
  }

  // Fetch user usage data
  Future<void> fetchUserUsage(int userId) async {
    try {
      loadingUsage.value = true;
      usageError.value = null;
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      final url = Uri.parse('${ApiConfig.baseUrl}/gc-management/usage/$userId')
          .replace(queryParameters: {
        'companyId': companyId,
        if (branchId.isNotEmpty) 'branchId': branchId,
      });
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final rawData = responseData['data'];
          Iterable<Map<String, dynamic>> allData;

          if (rawData is List) {
            allData = rawData.whereType<Map<String, dynamic>>();
          } else if (rawData is Map) {
            allData = rawData.values
                .whereType<Map>()
                .map((value) => value.cast<String, dynamic>());
          } else {
            allData = const Iterable.empty();
          }

          // Filter only active and queued ranges
          final activeAndQueued = allData.where((item) =>
            item['status'] == 'active' || item['status'] == 'queued'
          ).toList();

          userUsageData.assignAll(activeAndQueued);
        } else {
          userUsageData.clear();
        }
      } else {
        usageError.value = 'Failed to load usage data';
        userUsageData.clear();
      }
    } catch (e) {
      print('Error fetching user usage: $e');
      usageError.value = 'Error loading usage data';
      userUsageData.clear();
    } finally {
      loadingUsage.value = false;
    }
  }

  // Submit GC assignment
  Future<void> submitAssignment() async {
    if (!formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: 'Please fill all required fields',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (selectedUser.value == null) {
      Fluttertoast.showToast(
        msg: 'Please select a user',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      isSubmitting.value = true;

      final assignmentData = {
        "userId": selectedUser.value!['userId'],
        "fromGC": int.parse(fromGcCtrl.text.trim()),
        "count": int.parse(countCtrl.text.trim()),
        "status": statusCtrl.text.trim(),
        "companyId": _idController.companyId.value,
        if (_idController.branchId.value.isNotEmpty)
          "branchId": _idController.branchId.value,
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/gc-management/ranges');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(assignmentData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'GC assignment created successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Clear form
        clearForm();
        Get.back();
      } else {
        final errorData = jsonDecode(response.body);
        Fluttertoast.showToast(
          msg: 'Failed to create assignment: ${errorData['message'] ?? 'Unknown error'}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error submitting assignment: $e');
      Fluttertoast.showToast(
        msg: 'Error creating assignment. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // Clear form
  void clearForm() {
    userCtrl.clear();
    fromGcCtrl.clear();
    countCtrl.clear();
    statusCtrl.clear();
    selectedUser.value = null;
    hasActiveRanges.value = false;
    userUsageData.clear();
    usageError.value = null;
  }

  // Validate form fields
  String? validateUser(String? value) {
    if (selectedUser.value == null) {
      return 'Please select a user';
    }
    return null;
  }

  String? validateFromGc(String? value) {
    if (value == null || value.isEmpty) {
      return 'From GC is required';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return 'Please enter a valid GC number';
    }
    return null;
  }

  String? validateCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Count is required';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return 'Please enter a valid count';
    }
    return null;
  }

  // Calculate To GC Number based on From GC and Count
  void _calculateToGc() {
    final fromGc = int.tryParse(fromGcCtrl.text.trim());
    final count = int.tryParse(countCtrl.text.trim());
    
    if (fromGc != null && count != null && count > 0) {
      final toGc = fromGc + count - 1;
      toGcCtrl.text = toGc.toString();
      
      // Trigger validation for To GC after calculation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (toGcCtrl.text == toGc.toString()) {
          checkToGCNumberAvailability(toGc.toString());
        }
      });
    } else {
      toGcCtrl.text = '';
      // Clear To GC validation when empty
      toGcNumberStatus.value = null;
      toGcNumberMessage.value = null;
      toGcNumberIsInUse.value = false;
    }
  }

  // Debounced listener for GC number validation
  void _onFromGcChanged() {
    final gcNumber = fromGcCtrl.text.trim();
    if (gcNumber.isEmpty) {
      gcNumberStatus.value = null;
      gcNumberMessage.value = null;
      gcNumberIsInUse.value = false;
      return;
    }
    
    // Only validate if it's a valid number
    final number = int.tryParse(gcNumber);
    if (number != null && number > 0) {
      // Debounce the validation call
      Future.delayed(const Duration(milliseconds: 500), () {
        if (fromGcCtrl.text.trim() == gcNumber) {
          checkGCNumberAvailability(gcNumber);
        }
      });
    }
  }

  // Check GC number availability
  Future<void> checkGCNumberAvailability(String gcNumber) async {
    try {
      gcNumberValidating.value = true;
      
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      
      // Parse GC number as integer
      final gcNumberInt = int.tryParse(gcNumber);
      if (gcNumberInt == null) {
        gcNumberStatus.value = null;
        gcNumberMessage.value = 'Invalid GC number';
        gcNumberIsInUse.value = false;
        gcNumberValidating.value = false;
        return;
      }
      
      final url = Uri.parse('${ApiConfig.baseUrl}/gc-management/check-fromGC')
          .replace(queryParameters: {
        'gcNumber': gcNumberInt.toString(),
        'companyId': companyId,
        if (branchId.isNotEmpty) 'branchId': branchId,
      });
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          gcNumberIsInUse.value = responseData['isInUse'] ?? false;
          gcNumberStatus.value = responseData['status'];
          gcNumberMessage.value = responseData['message'];
        } else {
          gcNumberStatus.value = null;
          gcNumberMessage.value = 'Failed to check GC number';
          gcNumberIsInUse.value = false;
        }
      } else {
        gcNumberStatus.value = null;
        gcNumberMessage.value = 'Error checking GC number';
        gcNumberIsInUse.value = false;
      }
    } catch (e) {
      print('Error checking GC number: $e');
      gcNumberStatus.value = null;
      gcNumberMessage.value = 'Connection error';
      gcNumberIsInUse.value = false;
    } finally {
      gcNumberValidating.value = false;
    }
  }

  // Check To GC number availability
  Future<void> checkToGCNumberAvailability(String gcNumber) async {
    try {
      toGcNumberValidating.value = true;
      
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      
      // Parse GC number as integer
      final gcNumberInt = int.tryParse(gcNumber);
      if (gcNumberInt == null) {
        toGcNumberStatus.value = null;
        toGcNumberMessage.value = 'Invalid To GC number';
        toGcNumberIsInUse.value = false;
        toGcNumberValidating.value = false;
        return;
      }
      
      final url = Uri.parse('${ApiConfig.baseUrl}/gc-management/check-toGC')
          .replace(queryParameters: {
        'gcNumber': gcNumberInt.toString(),
        'companyId': companyId,
        if (branchId.isNotEmpty) 'branchId': branchId,
      });
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          toGcNumberIsInUse.value = responseData['isInUse'] ?? false;
          toGcNumberStatus.value = responseData['status'];
          toGcNumberMessage.value = responseData['message'];
        } else {
          toGcNumberStatus.value = null;
          toGcNumberMessage.value = 'Failed to check To GC number';
          toGcNumberIsInUse.value = false;
        }
      } else {
        toGcNumberStatus.value = null;
        toGcNumberMessage.value = 'Error checking To GC number';
        toGcNumberIsInUse.value = false;
      }
    } catch (e) {
      print('Error checking To GC number: $e');
      toGcNumberStatus.value = null;
      toGcNumberMessage.value = 'Connection error';
      toGcNumberIsInUse.value = false;
    } finally {
      toGcNumberValidating.value = false;
    }
  }
}