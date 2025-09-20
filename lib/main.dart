import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/update_transit_page.dart';
import 'routes.dart';
import 'gc_list_page.dart';
import 'login_screen.dart';
import 'home_page.dart';
import 'gc_form_screen.dart';
import 'gc_report_page.dart';
import 'controller/id_controller.dart';
import 'controller/location_controller.dart';
import 'controller/customer_controller.dart';
import 'controller/weight_to_rate_controller.dart';

void main() {
  Get.put(IdController());
  Get.put(LocationController());
  Get.put(CustomerController());
  Get.put(WeightToRateController());
  runApp(const LogisticsGCApp());
}

class LogisticsGCApp extends StatelessWidget {
  const LogisticsGCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Logistics GC',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E2A44),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF1E2A44),
          secondary: const Color(0xFF4A90E2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
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
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
