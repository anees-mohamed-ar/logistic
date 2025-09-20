import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/models/gst_model.dart';
import 'package:logistic/api_config.dart';

class GstController extends GetxController {
  final gstList = <GstModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  
  String get _baseUrl => ApiConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    fetchGstList();
  }

  Future<void> fetchGstList() async {
    try {
      isLoading(true);
      error('');
      final response = await http.get(
        Uri.parse('$_baseUrl/gst/search'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        gstList.assignAll(data.map((item) => GstModel.fromJson(item)).toList());
      } else {
        throw Exception('Failed to load GST list: ${response.statusCode}');
      }
    } catch (e) {
      error('Error: ${e.toString()}');
      Get.snackbar('Error', 'Failed to fetch GST list');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addGst(GstModel gst) async {
    try {
      isLoading(true);
      error('');
      final response = await http.post(
        Uri.parse('$_baseUrl/gst/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gst.toJson()),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'GST added successfully') {
          await fetchGstList();
          return true;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to add GST');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add GST');
      }
    } catch (e) {
      error('Error: ${e.toString()}');
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateGst(GstModel gst) async {
    try {
      isLoading(true);
      error('');
      final response = await http.put(
        Uri.parse('$_baseUrl/gst/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(gst.toJson()),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'GST updated successfully') {
          await fetchGstList();
          return true;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to update GST');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update GST');
      }
    } catch (e) {
      error('Error: ${e.toString()}');
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshGstList() async {
    await fetchGstList();
  }
}
