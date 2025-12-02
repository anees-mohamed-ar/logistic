import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/api_config.dart';

class FeatureFlagController extends GetxController {
  static FeatureFlagController get to => Get.find();

  // Feature flags - all default to false
  final RxBool isGcHistoryEnabled = false.obs;
  final RxBool isLocationEnabled = false.obs;
  final RxBool isKmManagementEnabled = false.obs;
  final RxBool isCustomerManagementEnabled = false.obs;
  final RxBool isSupplierManagementEnabled = false.obs;
  final RxBool isWeightManagementEnabled = false.obs;
  final RxBool isGstEnabled = false.obs;

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
        final featureData = data['data'] ?? {};

        // Update all feature flags from API response
        isGcHistoryEnabled.value = featureData['gcHistoryEnabled'] ?? false;
        isLocationEnabled.value = featureData['locationEnabled'] ?? false;
        isKmManagementEnabled.value =
            featureData['kmManagementEnabled'] ?? false;
        isCustomerManagementEnabled.value =
            featureData['customerManagementEnabled'] ?? false;
        isSupplierManagementEnabled.value =
            featureData['supplierManagementEnabled'] ?? false;
        isWeightManagementEnabled.value =
            featureData['weightManagementEnabled'] ?? false;
        isGstEnabled.value = featureData['gstEnabled'] ?? false;

        print(
          'Feature flags loaded: gcHistory=${isGcHistoryEnabled.value}, location=${isLocationEnabled.value}',
        );
      } else {
        errorMessage.value = 'Failed to load feature flags';
        _resetAllFlags();
      }
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
      _resetAllFlags();
    } finally {
      isLoading.value = false;
    }
  }

  void _resetAllFlags() {
    // Reset all flags to default (false) state
    isGcHistoryEnabled.value = false;
    isLocationEnabled.value = false;
    isKmManagementEnabled.value = false;
    isCustomerManagementEnabled.value = false;
    isSupplierManagementEnabled.value = false;
    isWeightManagementEnabled.value = false;
    isGstEnabled.value = false;
  }
}
