// Company Configuration
// This file contains the global company settings for the application
//
// MULTI-COMPANY SUPPORT:
// This file now uses FlavorConfig to dynamically select the company based on the build flavor
// The app can be built for different companies using different flavors

import 'package:flutter/material.dart';
import 'package:logistic/config/flavor_config.dart';
import 'package:logistic/controller/company_controller.dart';

class CompanyConfig {
  // ========== COMPANY INFORMATION ==========
  // These values are now dynamically set based on the flavor
  static int get companyId => FlavorConfig.instance.companyId;
  static String get companyName => FlavorConfig.instance.name;

  // ========== DISPLAY SETTINGS ==========
  static Color get primaryColor => FlavorConfig.instance.primaryColor;
  static const int secondaryColor = 0xFF4A90E2;

  // ========== CONTACT INFORMATION ==========
  // Optional company contact details
  static const String? address = null;
  static const String? phone = null;
  static const String? email = null;
  static const String? website = null;

  // ========== COMPANY LOGO/BRANDING ==========
  static const String? logoPath = null;

  // ========== DEFAULT VALUES ==========
  // Default values for new entities
  static const String defaultBranchStatus = 'Active';
  static const String defaultUserRole = 'user';

  // ========== API HELPERS ==========
  static String getCompanyIdParam() => 'companyId=$companyId';

  // ========== VALIDATION HELPERS ==========
  static bool isValidCompanyId(int id) => id == companyId;
  static bool isValidCompanyName(String name) => name == companyName;

  // ========== FORM HELPERS ==========
  static Map<String, dynamic> getDefaultCompanyData() {
    return {'companyId': companyId, 'companyName': companyName};
  }

  static Map<String, dynamic> getDefaultBranchData() {
    return {...getDefaultCompanyData(), 'status': defaultBranchStatus};
  }

  static Map<String, dynamic> getDefaultUserData() {
    return {...getDefaultCompanyData(), 'user_role': defaultUserRole};
  }

  // ========== COMPANY OBJECT ==========
  static Company getCompany() {
    return Company(
      id: companyId,
      companyName: companyName,
      address: address,
      phoneNumber: phone,
      email: email,
      website: website,
    );
  }
}
