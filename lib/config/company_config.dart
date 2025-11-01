// Company Configuration
// This file contains the global company settings for the application
//
// HOW TO CHANGE COMPANY:
// 1. Update companyId and companyName below
// 2. Update other company details as needed
// 3. Test the app to ensure all features work with new company
//
// NOTE: This app is designed for single-company use.
// For multi-company support, additional changes would be needed.

class CompanyConfig {
  // ========== COMPANY INFORMATION ==========
  // Change these values to switch to a different company
  static const int companyId = 6;
  static const String companyName = 'Sri Krishna Carrying Corporation';

  // ========== DISPLAY SETTINGS ==========
  static const int primaryColor = 0xFF1E2A44;
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
    return {
      'companyId': companyId,
      'companyName': companyName,
    };
  }

  static Map<String, dynamic> getDefaultBranchData() {
    return {
      ...getDefaultCompanyData(),
      'status': defaultBranchStatus,
    };
  }

  static Map<String, dynamic> getDefaultUserData() {
    return {
      ...getDefaultCompanyData(),
      'user_role': defaultUserRole,
    };
  }
}
