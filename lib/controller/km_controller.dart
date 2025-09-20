import 'package:get/get.dart';
import 'package:logistic/models/km_location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:logistic/api_config.dart';

class KMController extends GetxController {
  final isLoading = false.obs;
  final kmList = <KMLocation>[].obs;
  final box = GetStorage();
  final String baseUrl = '${ApiConfig.baseUrl}/km';

  @override
  void onInit() {
    super.onInit();
    fetchKMList();
  }

  Future<void> fetchKMList() async {
    try {
      isLoading(true);
      final response = await http.get(Uri.parse('$baseUrl/search'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        kmList.value = data.map((item) => KMLocation.fromJson(item)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch KM data');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addKM(String from, String to, String km) async {
    try {
      isLoading(true);
      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'from': from, 
          'to': to, 
          'km': km
        }),
      );
      
      if (response.statusCode == 200) {
        await fetchKMList();
        Get.back();
        Get.snackbar('Success', 'KM added successfully');
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to add KM');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateKM(int id, String from, String to, String km) async {
    try {
      isLoading(true);
      final response = await http.put(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'from': from, 
          'to': to, 
          'km': km
        }),
      );
      
      if (response.statusCode == 200) {
        await fetchKMList();
        Get.back();
        Get.snackbar('Success', 'KM updated successfully');
      } else if (response.statusCode == 404) {
        throw Exception('No record found with the given ID');
      } else {
        final error = json.decode(response.body)['error'];
        throw Exception(error ?? 'Failed to update KM');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }
}
