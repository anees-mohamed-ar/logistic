import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Flavor { cargo, carrying }

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final int companyId;
  final Color primaryColor;
  final String pdfGenerator;

  static FlavorConfig? _instance;

  factory FlavorConfig({
    required Flavor flavor,
    required String name,
    required int companyId,
    required Color primaryColor,
    required String pdfGenerator,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      name: name,
      companyId: companyId,
      primaryColor: primaryColor,
      pdfGenerator: pdfGenerator,
    );
    return _instance!;
  }

  FlavorConfig._internal({
    required this.flavor,
    required this.name,
    required this.companyId,
    required this.primaryColor,
    required this.pdfGenerator,
  });

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception('FlavorConfig not initialized');
    }
    return _instance!;
  }

  // Method to initialize flavor from native platform
  static Future<void> initFromPlatform() async {
    try {
      // Get company ID from platform
      const platform = MethodChannel('com.example.logistic/flavor');
      final companyId = await platform.invokeMethod<int>('getCompanyId') ?? 7;

      // Initialize flavor based on company ID
      if (companyId == 6) {
        FlavorConfig(
          flavor: Flavor.carrying,
          name: 'Sri Krishna Carrying Corporation',
          companyId: 6,
          primaryColor: const Color(0xFF1E2A44),
          pdfGenerator: 'gc_pdf_carrying.dart',
        );
      } else {
        FlavorConfig(
          flavor: Flavor.cargo,
          name: 'Sri Krishna Cargo Corporation',
          companyId: 7,
          primaryColor: const Color.fromARGB(255, 68, 42, 30),
          pdfGenerator: 'gc_pdf.dart',
        );
      }
    } catch (e) {
      // Default to cargo if there's an error
      FlavorConfig(
        flavor: Flavor.cargo,
        name: 'Sri Krishna Carrying Corporation',
        companyId: 6,
        primaryColor: const Color(0xFF1E2A44),
        pdfGenerator: 'gc_pdf_carrying.dart',
      );
    }
  }
}

