import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/models/truck.dart';
import 'package:logistic/api_config.dart';

class TruckController extends GetxController {
  final RxList<Truck> trucks = <Truck>[].obs;
  final RxList<Truck> filteredTrucks = <Truck>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrucks();
  }

  Future<void> searchTrucks(String query) async {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredTrucks.value = List<Truck>.from(trucks);
      return;
    }
    
    // Client-side search as fallback
    filteredTrucks.value = trucks.where((truck) {
      return truck.vechileNumber.toLowerCase().contains(query.toLowerCase()) ||
             (truck.ownerName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
             (truck.engineeNumber?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
    
    // If no results found locally, try server-side search
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
        filteredTrucks.value = data.map((item) => Truck.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error searching trucks: $e');
      // Re-throw the error to be handled by the UI
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTrucks() async {
    try {
      print('🔄 Fetching trucks...');
      isLoading.value = true;
      
      final url = '${ApiConfig.baseUrl}/truckmaster/search';
      final headers = {'Content-Type': 'application/json'};
      
      print('🌐 Sending GET request to: $url');
      print('📝 Request headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

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
        
        trucks.value = data.map((item) => Truck.fromJson(item as Map<String, dynamic>)).toList();
        filteredTrucks.value = List<Truck>.from(trucks);
        print('✅ Successfully loaded ${trucks.length} trucks');
      } else {
        final error = '❌ Failed to load trucks. Status: ${response.statusCode}, Body: ${response.body}';
        print(error);
        throw Exception(error);
      }
    } catch (e) {
      error.value = 'Error fetching trucks: ${e.toString()}';
      Get.snackbar('Error', 'Failed to load trucks',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Truck?> getTruckByNumber(String vehicleNumber) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/truckmaster/search/number?vechileNumber=$vehicleNumber'),
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
        final error = 'Failed to load truck details. Status: ${response.statusCode}, Body: ${response.body}';
        print('❌ $error');
        throw Exception(error);
      }
    } catch (e) {
      error.value = 'Error fetching truck details: ${e.toString()}';
      return null;
    }
  }

  Future<bool> addTruck(Truck truck) async {
    try {
      print('➕ Adding new truck with vehicle number: ${truck.vechileNumber}');
      
      // Check if truck with this vehicle number already exists
      final existingTruck = await getTruckByNumber(truck.vechileNumber);
      if (existingTruck != null) {
        print('❌ Truck with vehicle number ${truck.vechileNumber} already exists');
        Get.snackbar('Error', 'Truck with this vehicle number already exists',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
      
      isLoading.value = true;
      
      // Create a copy of the truck data to modify
      final truckData = Map<String, dynamic>.from(truck.toJson());
      truckData.remove('id');
      
      print('🌐 Sending POST request to: ${ApiConfig.baseUrl}/truckmaster/add');
      print('📦 Request body: $truckData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/truckmaster/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(truckData),
      );

      if (response.statusCode == 200) {
        await fetchTrucks();
        Get.snackbar('Success', 'Truck added successfully',
            snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        throw Exception('Failed to add truck');
      }
    } catch (e) {
      error.value = 'Error adding truck: ${e.toString()}';
      Get.snackbar('Error', 'Failed to add truck',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTruck(Truck truck) async {
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
      truckData.remove('companyId');
      
      // Log the final data being sent
      print('🔍 Final data being sent: $truckData');
      
      isLoading.value = true;
      final url = '${ApiConfig.baseUrl}/truckmaster/update/${Uri.encodeComponent(truck.vechileNumber)}';
      print('🌐 Update URL: $url');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      print('🌐 Sending PUT request to: $url');
      print('📝 Request headers: $headers');
      print('📦 Request body: $truckData');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(truckData),
      );

      print('✅ Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      print('📋 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('🔄 Refreshing trucks list...');
        await fetchTrucks();
        Get.snackbar('Success', 'Truck updated successfully',
            snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        // Try to parse the error message from the response
        String errorMessage = 'Failed to update truck';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {
          // If we can't parse the error, use the raw response
          errorMessage = 'Status: ${response.statusCode}, Body: ${response.body}';
        }
        
        final error = '❌ $errorMessage';
        print(error);
        Get.snackbar('Error', errorMessage,
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Exception details: $e');
      print('📋 Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to update truck';
      if (e is http.ClientException) {
        errorMessage = 'Network error: ${e.message}';
      } else if (e is FormatException) {
        errorMessage = 'Invalid data format';
      }
      
      error.value = 'Error updating truck: $errorMessage';
      Get.snackbar('Error', errorMessage,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTruck(int id) async {
    try {
      isLoading.value = true;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/truckmaster/delete/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchTrucks();
        Get.snackbar('Success', 'Truck deleted successfully',
            snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        throw Exception('Failed to delete truck');
      }
    } catch (e) {
      error.value = 'Error deleting truck: ${e.toString()}';
      Get.snackbar('Error', 'Failed to delete truck',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

}
