import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/api_config.dart';

class FeatureFlagController extends GetxController {
  static FeatureFlagController get to => Get.find();

  final RxBool isGcHistoryEnabled = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFeatureFlags();
  }

  Future<void> fetchFeatureFlags() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/features'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        isGcHistoryEnabled.value = data['data']?['gcHistoryEnabled'] ?? false;
      } else {
        errorMessage.value = 'Failed to load feature flags';
        isGcHistoryEnabled.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
      isGcHistoryEnabled.value = false;
    } finally {
      isLoading.value = false;
    }
  }
}
