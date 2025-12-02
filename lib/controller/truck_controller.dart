import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:logistic/models/truck.dart';
import 'package:logistic/api_config.dart';
import 'package:file_picker/file_picker.dart';

class TruckController extends GetxController {
  final RxList<Truck> trucks = <Truck>[].obs;
  final RxList<Truck> filteredTrucks = <Truck>[].obs;
  // Trucks actually rendered in the list (supports pagination)
  final RxList<Truck> visibleTrucks = <Truck>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxInt uploadBytesSent = 0.obs;
  final RxInt uploadBytesTotal = 0.obs;
  final RxInt uploadTotalFiles = 0.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  // Simple client-side pagination
  final int pageSize = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final RxBool hasMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrucks();
  }

  void _resetPagination(List<Truck> source) {
    _currentPage = 1;
    if (source.isEmpty) {
      visibleTrucks.clear();
      hasMore.value = false;
      return;
    }

    final int end = source.length < pageSize ? source.length : pageSize;
    visibleTrucks.value = source.sublist(0, end);
    hasMore.value = source.length > end;
  }

  void loadMore() {
    if (_isLoadingMore || !hasMore.value) return;
    _isLoadingMore = true;

    try {
      final List<Truck> source = List<Truck>.from(filteredTrucks);
      _currentPage++;
      final int start = (pageSize * (_currentPage - 1));
      if (start >= source.length) {
        hasMore.value = false;
        return;
      }
      final int end = (start + pageSize) > source.length
          ? source.length
          : (start + pageSize);
      final nextPage = source.sublist(start, end);
      visibleTrucks.addAll(nextPage);
      hasMore.value = end < source.length;
    } finally {
      _isLoadingMore = false;
    }
  }

  // Refresh trucks list
  Future<void> refreshTrucks() async {
    await fetchTrucks();
  }

  Future<void> searchTrucks(String query) async {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredTrucks.value = List<Truck>.from(trucks);
      _resetPagination(filteredTrucks);
      return;
    }

    // Client-side search as fallback
    filteredTrucks.value = trucks.where((truck) {
      return truck.vechileNumber.toLowerCase().contains(query.toLowerCase()) ||
          (truck.ownerName?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (truck.engineeNumber?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();

    _resetPagination(filteredTrucks);

    // If no results found locally, try server-side search over all data
    if (filteredTrucks.isEmpty) {
      await _searchTrucksOnServer(query);
    }
  }

  Future<void> _searchTrucksOnServer(String query) async {
    try {
      isLoading.value = true;
      final url = '${ApiConfig.baseUrl}/truckmaster/search?query=$query';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Truck> serverResult = data
            .map((item) => Truck.fromJson(item as Map<String, dynamic>))
            .toList();

        // Only replace filtered list if server returned something
        if (serverResult.isNotEmpty) {
          filteredTrucks.value = serverResult;
          _resetPagination(filteredTrucks);
        }
      }
    } catch (e) {
      print('Error searching trucks: $e');
      // Keep existing list; just show a lightweight notification
      Get.snackbar(
        'Search Error',
        'Unable to search trucks right now',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  Future<void> fetchTrucks() async {
    try {
      print('🔄 Fetching trucks...');
      isLoading.value = true;
      error.value = '';

      final url = '${ApiConfig.baseUrl}/truckmaster/search';
      final headers = {'Content-Type': 'application/json'};

      print('🌐 Sending GET request to: $url');
      print('📝 Request headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('✅ Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      print('📋 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('📊 Received ${data.length} trucks');

        // Log the first truck for debugging
        if (data.isNotEmpty) {
          print('📝 Sample truck data: ${data.first}');
        }

        trucks.value = data
            .map((item) => Truck.fromJson(item as Map<String, dynamic>))
            .toList();
        filteredTrucks.value = List<Truck>.from(trucks);
        _resetPagination(filteredTrucks);
        print('✅ Successfully loaded ${trucks.length} trucks');
      } else {
        final error =
            '❌ Failed to load trucks. Status: ${response.statusCode}, Body: ${response.body}';
        print(error);
        throw Exception(error);
      }
    } catch (e) {
      error.value = 'Error fetching trucks: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to load trucks',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isUploading.value = false;
      uploadProgress.value = 0.0;
      uploadBytesSent.value = 0;
      uploadBytesTotal.value = 0;
      uploadTotalFiles.value = 0;
    }
  }

  Future<Truck?> getTruckByNumber(String vehicleNumber) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/truckmaster/search/number?vechileNumber=$vehicleNumber',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('🔍 Found ${data.length} trucks with number: $vehicleNumber');
        if (data.isNotEmpty) {
          final truckData = data.first as Map<String, dynamic>;
          print('📦 Truck data: $truckData');
          return Truck.fromJson(truckData);
        }
        return null;
      } else {
        final error =
            'Failed to load truck details. Status: ${response.statusCode}, Body: ${response.body}';
        print('❌ $error');
        throw Exception(error);
      }
    } catch (e) {
      error.value = 'Error fetching truck details: ${e.toString()}';
      return null;
    }
  }

  Future<bool> addTruck(Truck truck, {List<PlatformFile>? attachments}) async {
    try {
      print('➕ Adding new truck with vehicle number: ${truck.vechileNumber}');

      // Check if truck with this vehicle number already exists
      final existingTruck = await getTruckByNumber(truck.vechileNumber);
      if (existingTruck != null) {
        print(
          '❌ Truck with vehicle number ${truck.vechileNumber} already exists',
        );
        Get.snackbar(
          'Error',
          'Truck with this vehicle number already exists',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      isLoading.value = true;
      isUploading.value = true;
      uploadProgress.value = 0.0;
      uploadBytesSent.value = 0;
      uploadBytesTotal.value = 0;
      uploadTotalFiles.value = attachments?.length ?? 0;

      // Create a copy of the truck data to modify
      final truckData = Map<String, dynamic>.from(truck.toJson());
      truckData.remove('id');

      print(
        '🌐 Sending multipart POST request to: ${ApiConfig.baseUrl}/truckmaster/add',
      );
      print('📦 Form fields: $truckData');

      final dioClient = dio.Dio();
      final formData = dio.FormData();

      truckData.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          if (file.path != null && file.path!.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'attachments',
                await dio.MultipartFile.fromFile(file.path!),
              ),
            );
          }
        }
      }

      final response = await dioClient.post(
        '${ApiConfig.baseUrl}/truckmaster/add',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            uploadProgress.value = sent / total;
            uploadBytesSent.value = sent;
            uploadBytesTotal.value = total;
          }
        },
      );

      print('✅ Response status: ${response.statusCode}');
      print('📄 Response body: ${response.data}');

      if (response.statusCode == 200) {
        await fetchTrucks();
        return true;
      } else {
        throw Exception('Failed to add truck');
      }
    } catch (e) {
      error.value = 'Error adding truck: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to add truck',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTruck(
    Truck truck, {
    String? oldVehicleNumber,
    List<PlatformFile>? attachments,
  }) async {
    try {
      print('🚛 Updating truck with vehicle number: ${truck.vechileNumber}');
      print('📦 Truck data to update: ${truck.toJson()}');

      if (truck.vechileNumber.isEmpty) {
        final error = '❌ Vehicle number is required for update';
        print(error);
        throw Exception(error);
      }

      // Create a copy of the truck data to modify
      final truckData = Map<String, dynamic>.from(truck.toJson());

      // Ensure we're not sending null values that might cause issues
      truckData.removeWhere((key, value) => value == null);

      // Remove any fields that shouldn't be sent in the update
      truckData.remove('id');

      // Log the final data being sent
      print('🔍 Final data being sent (multipart fields): $truckData');

      // Use oldVehicleNumber in the URL if provided (so backend can find the
      // existing record even if the vehicle number is being changed)
      final pathVehicleNumber = oldVehicleNumber ?? truck.vechileNumber;

      isLoading.value = true;
      isUploading.value = true;
      uploadProgress.value = 0.0;
      uploadBytesSent.value = 0;
      uploadBytesTotal.value = 0;
      uploadTotalFiles.value = attachments?.length ?? 0;
      final url =
          '${ApiConfig.baseUrl}/truckmaster/update/${Uri.encodeComponent(pathVehicleNumber)}';
      print('🌐 Update URL (multipart): $url');
      final dioClient = dio.Dio();
      final formData = dio.FormData();

      truckData.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          if (file.path != null && file.path!.isNotEmpty) {
            formData.files.add(
              MapEntry(
                'attachments',
                await dio.MultipartFile.fromFile(file.path!),
              ),
            );
          }
        }
      }

      print('📝 Multipart fields: ${truckData.keys.toList()}');
      print('🗂️ Multipart files count: ${attachments?.length ?? 0}');

      final response = await dioClient.put(
        url,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            uploadProgress.value = sent / total;
            uploadBytesSent.value = sent;
            uploadBytesTotal.value = total;
          }
        },
      );

      print('✅ Response status: ${response.statusCode}');
      print('📄 Response body: ${response.data}');

      if (response.statusCode == 200) {
        print('🔄 Refreshing trucks list...');
        await fetchTrucks();
        return true;
      } else {
        // Try to parse the error message from the response
        String errorMessage = 'Failed to update truck';
        try {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            errorMessage = data['message'] ?? data['error'] ?? errorMessage;
          } else if (data is String) {
            errorMessage = data;
          }
        } catch (_) {
          // If we can't parse the error, use the raw response
          errorMessage =
              'Status: ${response.statusCode}, Body: ${response.data}';
        }

        // Extra detailed log so we can see the exact backend error
        print('❌ [Truck update] Backend returned non-200 status');
        print('   → Status code: ${response.statusCode}');
        print('   → Raw response data: ${response.data}');
        print('   → Parsed error message: $errorMessage');

        final error = '❌ $errorMessage';
        print(error);
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [Truck update] Exception while calling update API: $e');
      print('📋 Stack trace: $stackTrace');

      String errorMessage = 'Failed to update truck';

      // If this is a Dio error, log full HTTP details
      if (e is dio.DioError) {
        final res = e.response;
        print('❌ [Truck update] DioError details:');
        print('   → Type: ${e.type}');
        print('   → Message: ${e.message}');
        if (res != null) {
          print('   → Response status: ${res.statusCode}');
          print('   → Response data: ${res.data}');
          print('   → Response headers: ${res.headers}');
          errorMessage = 'Status: ${res.statusCode}, Body: ${res.data}';
        }
      } else if (e is http.ClientException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is FormatException) {
        errorMessage = 'Invalid data format';
      } else if (e is SocketException) {
        errorMessage = 'No internet connection: ${e.message}';
      }

      error.value = 'Error updating truck: $errorMessage';
      print('❌ [Truck update] Final error message: $errorMessage');
      Get.snackbar('Error', errorMessage, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTruck(String vechileNumber) async {
    try {
      isLoading.value = true;
      final encoded = Uri.encodeComponent(vechileNumber);
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/truckmaster/delete/$encoded'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchTrucks();
        Get.snackbar(
          'Success',
          'Truck deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else if (response.statusCode == 404) {
        Get.snackbar(
          'Not Found',
          'Truck not found',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      } else {
        String message = 'Failed to delete truck';
        try {
          final body = json.decode(response.body);
          message =
              body['error']?.toString() ??
              body['message']?.toString() ??
              message;
        } catch (_) {}
        Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      error.value = 'Error deleting truck: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to delete truck',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
