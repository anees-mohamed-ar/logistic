import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logistic/splash_screen.dart';
import 'package:logistic/services/network_service.dart';
import 'package:logistic/config/flavor_config.dart';
import 'package:logistic/config/company_config.dart';

import 'routes.dart';
import 'controller/id_controller.dart';
import 'controller/location_controller.dart';
import 'controller/customer_controller.dart';
import 'controller/weight_to_rate_controller.dart';
import 'controller/login_controller.dart';
import 'controller/branch_controller.dart';
import 'controller/temporary_gc_controller.dart';
import 'controller/broker_controller.dart';
import 'controller/feature_flag_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize flavor configuration
  await FlavorConfig.initFromPlatform();
  print(
    'Running app with company: ${CompanyConfig.companyName} (ID: ${CompanyConfig.companyId})',
  );

  await Get.putAsync<NetworkService>(() => NetworkService.init());
  await _initializeApp();

  runApp(const LogisticsGCApp());
}

Future<void> _initializeApp() async {
  Get.put(IdController());
  Get.put(LocationController());
  Get.put(CustomerController());
  Get.put(WeightToRateController());
  Get.put(LoginController());
  Get.put(BranchController());
  Get.put(BrokerController());
  Get.put(TemporaryGCController());
  Get.put(FeatureFlagController());
}

class LogisticsGCApp extends StatelessWidget {
  const LogisticsGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: CompanyConfig.companyName,
      theme: ThemeData(
        primaryColor: CompanyConfig.primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: CompanyConfig.primaryColor,
          secondary: CompanyConfig.primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: CompanyConfig.primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CompanyConfig.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2A44),
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ),
      initialRoute: AppRoutes.splash, // Set initial route to splash screen
      getPages: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
